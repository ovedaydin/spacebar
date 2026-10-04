import AppKit
import CryptoKit
import Darwin
import Foundation
import SQLite3

private let fm = FileManager.default

private func children(_ url: URL) -> [URL] {
    (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil, options: [])) ?? []
}

private func modified(_ url: URL) -> Date? {
    var st = stat()
    guard lstat(url.path, &st) == 0 else { return nil }
    return Date(timeIntervalSince1970: TimeInterval(st.st_mtimespec.tv_sec))
}

private func relative(_ date: Date?) -> String {
    guard let date else { return "never" }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

private func daysAgo(_ days: Double) -> Date { Date().addingTimeInterval(-days * 24 * 3600) }

/// Runs a system tool (absolute path, clean environment) and returns its output, or nil on failure.
func runCommand(_ path: String, _ arguments: [String], timeout: TimeInterval = 30) -> Data? {
    guard let result = Tools.run(path, arguments, timeout: timeout), result.status == 0 else { return nil }
    return result.output
}

// MARK: - Installed apps

/// Every installed app, found via Spotlight plus the standard Applications folders.
public struct InstalledAppsIndex: Sendable {
    public struct App: Sendable {
        public let url: URL
        public let bundleID: String
        public let name: String
    }

    public let apps: [App]
    let bundleIDs: Set<String>
    let vendors: Set<String>
    let names: [String]

    public static func current() -> InstalledAppsIndex {
        var urls = Set<URL>()
        if let data = runCommand("/usr/bin/mdfind", ["kMDItemContentType == 'com.apple.application-bundle'"], timeout: 15) {
            for line in String(decoding: data, as: UTF8.self).split(separator: "\n") where line.hasSuffix(".app") {
                urls.insert(URL(fileURLWithPath: String(line)))
            }
        }
        for url in standardAppURLs() { urls.insert(url) }

        var apps: [App] = []
        for url in urls where !url.path.contains("/.Trash/") {
            guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else { continue }
            let name = (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String) ?? url.deletingPathExtension().lastPathComponent
            apps.append(App(url: url, bundleID: id, name: name))
        }
        return InstalledAppsIndex(apps: apps)
    }

    init(apps: [App]) {
        self.apps = apps
        bundleIDs = Set(apps.map { $0.bundleID.lowercased() })
        vendors = Set(apps.compactMap { Self.vendor($0.bundleID) })
        names = apps.flatMap { [$0.name, $0.url.deletingPathExtension().lastPathComponent] }.map(Self.squash)
    }

    /// Apps in /Applications (and one folder deep), ~/Applications.
    static func standardAppURLs() -> [URL] {
        let roots = [URL(fileURLWithPath: "/Applications"), fm.homeDirectoryForCurrentUser.appendingPathComponent("Applications")]
        var result: [URL] = []
        for root in roots {
            for entry in children(root) {
                if entry.pathExtension == "app" {
                    result.append(entry)
                } else if (try? entry.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                    result += children(entry).filter { $0.pathExtension == "app" }
                }
            }
        }
        return result
    }

    static func vendor(_ bundleID: String) -> String? {
        let parts = bundleID.lowercased().split(separator: ".")
        return parts.count >= 3 ? parts.prefix(2).joined(separator: ".") : nil
    }

    static func squash(_ name: String) -> String { name.lowercased().filter { $0.isLetter || $0.isNumber } }

    static func looksLikeBundleID(_ name: String) -> Bool {
        name.split(separator: ".").count >= 3 && !name.contains(" ")
    }

    /// Folder names in Application Support and similar that belong to macOS or are shared, not to one app.
    static let systemNames: Set<String> = [
        "caches", "syncservices", "animoji", "webpush", "electron", "addressbook", "callhistorydb",
        "callhistorytransactions", "clouddocs", "crashreporter", "diskimages", "fileprovider", "knowledge",
        "mobilesync", "icloud", "dock", "facetime", "familycircle", "quicklook", "controlcenter",
        "applemediaservices", "differentialprivacy", "coreparsec", "cloudkit", "accounts", "wallpaper",
        "maps", "siri", "spotlight", "networkserviceproxy", "dmd", "homeenergyd", "storeassetd", "app store",
        "launchservices", "safari", "webkit", "plugins", "internet plug-ins", "screensavers", "audio", "fonts",
        "colorpickers", "services", "scripts", "workflows", "bluetooth", "contextstore", "metadata",
    ]

    /// The installed app a downloaded installer or archive is for, e.g. "Docker.dmg" → "Docker".
    public func appMatching(fileName: String) -> String? {
        var base = (fileName as NSString).deletingPathExtension.lowercased()
        for noise in ["installer", "install", "setup", "macos", "osx", "darwin", "universal", "arm64", "x64",
                      "x86_64", "intel", "apple", "silicon", "mac", "-", "_", " "] {
            base = base.replacingOccurrences(of: noise, with: " ")
        }
        let key = base.filter(\.isLetter)
        guard key.count >= 4 else { return nil }
        return apps.first { app in
            let name = app.name.lowercased().filter(\.isLetter)
            return name.count >= 4 && (key.hasPrefix(name) || name.hasPrefix(key))
        }?.name
    }

    /// True when a folder named `name` (bundle ID or app name) belongs to no installed app.
    /// Conservative: a bundle ID counts as installed if any app from the same vendor is.
    public func isOrphan(_ name: String) -> Bool {
        let lower = name.lowercased()
        if lower.hasPrefix("com.apple.") || lower.hasPrefix("group.") { return false }
        if Self.looksLikeBundleID(name) {
            var id = lower
            for suffix in [".savedstate", ".binarycookies", ".plist"] where id.hasSuffix(suffix) { id.removeLast(suffix.count) }
            if bundleIDs.contains(id) || bundleIDs.contains(where: { id.hasPrefix($0 + ".") }) { return false }
            if let vendor = Self.vendor(id), vendors.contains(vendor) { return false }
            return true
        }
        if Self.systemNames.contains(lower) { return false }
        let key = Self.squash(name)
        guard key.count >= 3 else { return false }
        return !names.contains { $0.contains(key) || key.contains($0) && $0.count >= 4 }
    }
}

// MARK: - Duplicates

public enum DuplicateFinder {
    struct File {
        let url: URL
        let size: Int64
        let created: Date?
    }

    /// Bytes that deleting this file would actually free. APFS clones share blocks
    /// with other files, so deleting one frees only its private blocks.
    static func reclaimableBytes(_ path: String, allocated: Int64) -> Int64 {
        var request = attrlist()
        request.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        request.commonattr = 0x8000_0000 // ATTR_CMN_RETURNED_ATTRS
        request.forkattr = 0x0000_0008 | 0x0000_0200 // ATTR_CMNEXT_PRIVATESIZE | ATTR_CMNEXT_EXT_FLAGS
        var buffer = [UInt8](repeating: 0, count: 64)
        let options = UInt32(FSOPT_NOFOLLOW) | 0x0000_0020 // FSOPT_ATTR_CMN_EXTENDED
        let result = buffer.withUnsafeMutableBytes { raw in
            getattrlist(path, &request, raw.baseAddress, raw.count, options)
        }
        guard result == 0 else { return allocated }
        return buffer.withUnsafeBytes { raw in
            var offset = 4
            let returned = raw.loadUnaligned(fromByteOffset: offset, as: attribute_set_t.self)
            offset += MemoryLayout<attribute_set_t>.size
            var privateSize: Int64?
            if returned.forkattr & 0x8 != 0 {
                privateSize = raw.loadUnaligned(fromByteOffset: offset, as: Int64.self)
                offset += 8
            }
            var flags: UInt64 = 0
            if returned.forkattr & 0x200 != 0 { flags = raw.loadUnaligned(fromByteOffset: offset, as: UInt64.self) }
            let maySharedBlocks = flags & 0x1 != 0 // EF_MAY_SHARE_BLOCKS
            return maySharedBlocks ? min(privateSize ?? allocated, allocated) : allocated
        }
    }

    static func hash(_ url: URL, partial: Bool) -> Data? {
        guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
        defer { try? handle.close() }
        var hasher = SHA256()
        let chunk = 1 << 20
        if partial {
            guard let head = try? handle.read(upToCount: 64 * 1024) else { return nil }
            hasher.update(data: head)
            if let end = try? handle.seekToEnd(), end > 128 * 1024 {
                try? handle.seek(toOffset: end - 64 * 1024)
                if let tail = try? handle.read(upToCount: 64 * 1024) { hasher.update(data: tail) }
            }
        } else {
            while let data = try? handle.read(upToCount: chunk), !data.isEmpty {
                hasher.update(data: data)
            }
        }
        return Data(hasher.finalize())
    }

    /// Answers "is this file inside a git working tree?", caching per folder.
    struct RepositoryLookup {
        private var cache: [String: Bool] = [:]

        mutating func contains(_ url: URL) -> Bool { inRepository(url.deletingLastPathComponent().path) }

        private mutating func inRepository(_ folder: String) -> Bool {
            if let known = cache[folder] { return known }
            let result: Bool
            if folder == "/" || folder == NSHomeDirectory() {
                result = false
            } else if fm.fileExists(atPath: folder + "/.git") {
                result = true
            } else {
                result = inRepository((folder as NSString).deletingLastPathComponent)
            }
            cache[folder] = result
            return result
        }
    }

    /// Ranks which copy to keep: not in Downloads, shallowest path, then oldest.
    static func keeperScore(_ file: File, home: String) -> (Int, Int, Date) {
        let inDownloads = file.url.path.hasPrefix(home + "/Downloads/") ? 1 : 0
        return (inDownloads, file.url.pathComponents.count, file.created ?? .distantFuture)
    }

    static func find(home: URL, minSize: Int64, cancel: CancelToken?) -> [(keep: File, copies: [File])] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey, .isDirectoryKey, .isPackageKey,
                                          .fileResourceIdentifierKey, .creationDateKey]
        // Build output and dependencies: copies there are expected and deleting them breaks builds.
        let skippedFolders: Set<String> = ["node_modules", ".git", "Library", ".Trash", "Pods", "DerivedData",
                                           "platforms", "target", "build", ".build", "dist", "vendor", "venv",
                                           ".venv", "bower_components", "site-packages"]
        let skippedExtensions: Set<String> = ["framework", "xcframework", "bundle", "xcarchive", "lproj"]
        guard let walker = fm.enumerator(at: home, includingPropertiesForKeys: Array(keys),
                                         options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                         errorHandler: { _, _ in true }) else { return [] }
        var bySize: [Int64: [File]] = [:]
        var seenInodes = Set<NSObject>()
        while let url = walker.nextObject() as? URL {
            if cancel?.isCancelled == true { return [] }
            guard let values = try? url.resourceValues(forKeys: keys) else { continue }
            if values.isDirectory == true {
                if skippedFolders.contains(url.lastPathComponent) || skippedExtensions.contains(url.pathExtension) {
                    walker.skipDescendants()
                }
                continue
            }
            guard values.isRegularFile == true, let size = values.fileSize, Int64(size) >= minSize else { continue }
            // Hard links are the same file, not a duplicate.
            if let id = values.fileResourceIdentifier as? NSObject, !seenInodes.insert(id).inserted { continue }
            var st = stat()
            guard lstat(url.path, &st) == 0, st.st_flags & 0x4000_0000 == 0 else { continue } // skip iCloud-only
            bySize[Int64(size), default: []].append(File(url: url, size: Int64(st.st_blocks) * 512, created: values.creationDate))
        }

        var repositories = RepositoryLookup()
        var groups: [(keep: File, copies: [File])] = []
        for (_, files) in bySize where files.count > 1 {
            if cancel?.isCancelled == true { return [] }
            for partialGroup in Dictionary(grouping: files, by: { hash($0.url, partial: true) }).values
            where partialGroup.count > 1 {
                for group in Dictionary(grouping: partialGroup, by: { hash($0.url, partial: false) }).values
                where group.count > 1 {
                    let sorted = group.sorted { keeperScore($0, home: home.path) < keeperScore($1, home: home.path) }
                    // Files in a code repository belong to that project: never offer them for deletion.
                    let copies = sorted.dropFirst().filter { !repositories.contains($0.url) }
                    if !copies.isEmpty { groups.append((sorted[0], Array(copies))) }
                }
            }
        }
        return groups
    }
}

// MARK: - Categories

public extension CleanCategory {
    static let iCloudDownloads = CleanCategory(
        id: "icloud", name: "Keep in iCloud Only", icon: "icloud.and.arrow.down",
        summary: "Large iCloud Drive files that are also stored on this Mac. Removing the local copy frees the space right away; the file stays in iCloud and downloads again when you open it. Nothing is deleted. Files you haven't opened in 90 days are suggested; files with changes not yet uploaded are left alone.",
        safety: .review, mode: .permanent, needsFullDiskAccess: false, onDemand: true, owners: []
    ) { context in
        let root = context.path("Library/Mobile Documents")
        let keys: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey, .isUbiquitousItemKey,
                                      .ubiquitousItemDownloadingStatusKey, .ubiquitousItemIsUploadedKey,
                                      .ubiquitousItemIsUploadingKey, .contentModificationDateKey]
        guard let walker = fm.enumerator(at: root, includingPropertiesForKeys: keys, options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                         errorHandler: { _, _ in true }) else { return [] }
        let minimum: Int64 = 20 * 1_000_000
        var result: [Candidate] = []
        while let url = walker.nextObject() as? URL {
            if context.cancel?.isCancelled == true { break }
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true,
                  values.isUbiquitousItem == true, values.ubiquitousItemDownloadingStatus == .current,
                  values.ubiquitousItemIsUploaded == true, values.ubiquitousItemIsUploading != true,
                  let size = values.totalFileAllocatedSize, Int64(size) >= minimum else { continue }
            let opened = NSMetadataItem(url: url)?.value(forAttribute: "kMDItemLastUsedDate") as? Date
            let lastActivity = [opened, values.contentModificationDate].compactMap { $0 }.max()
            let stale = (lastActivity ?? .distantPast) < daysAgo(90)
            let place = url.deletingLastPathComponent().path
                .replacingOccurrences(of: root.path + "/com~apple~CloudDocs", with: "iCloud Drive")
                .replacingOccurrences(of: root.path, with: "iCloud")
            result.append(Candidate(url: url, date: lastActivity,
                                    detail: "\(place) · \(opened.map { "opened \(relative($0))" } ?? "no open recorded")",
                                    knownSize: Int64(size), kind: .iCloudEvict, lastUsed: lastActivity,
                                    suggested: stale ? true : nil))
        }
        return result
    }

    static let developerTools = CleanCategory(
        id: "devtools", name: "Developer Tools", icon: "wrench.and.screwdriver",
        summary: "Android system images no emulator uses, old Android build-tools and emulators, extra Xcode copies, older JetBrains IDE data, downloaded AI models, old Homebrew versions, and git repositories worth compacting. The Xcode you're using and the Homebrew versions in use are never offered. git gc runs in Terminal, not inside Spacebar.",
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        DeveloperTools.candidates(home: context.home, cancel: context.cancel)
    }

    static let forgottenFiles = CleanCategory(
        id: "forgotten", name: "Forgotten Files", icon: "tray.full",
        summary: "Things in Downloads and on the Desktop you haven't opened in a long time. \"Opened\" comes from Spotlight, which records opens through Finder and apps (files dragged straight into an app may not show). Suggested: installers for apps you already have, archives already unzipped next to themselves, and installers or archives with no open recorded in 6 months. Photos, videos, music and documents are never suggested, and neither is anything on the Desktop.",
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: true, owners: []
    ) { context in
        let installed = InstalledAppsIndex.current()
        let installerTypes: Set<String> = ["dmg", "pkg", "mpkg", "xip"]
        let archiveTypes: Set<String> = ["zip", "xip", "rar", "7z", "tgz", "gz", "tar", "bz2", "xz"]
        // Only throwaway types are suggested for age alone; photos, videos, music and documents never are.
        let throwawayTypes = installerTypes.union(archiveTypes).union(["iso", "img", "torrent", "exe", "msi", "deb",
                                                                       "rpm", "apk", "crdownload", "download", "part"])
        let keys: Set<URLResourceKey> = [.addedToDirectoryDateKey, .contentModificationDateKey, .isDirectoryKey]
        var result: [Candidate] = []

        for (folder, minDays, suggests) in [("Downloads", 30.0, true), ("Desktop", 90.0, false)] {
            let entries = (try? fm.contentsOfDirectory(at: context.path(folder), includingPropertiesForKeys: Array(keys))) ?? []
            let names = Set(entries.map { $0.lastPathComponent })
            for url in entries where !url.lastPathComponent.hasPrefix(".") {
                let values = try? url.resourceValues(forKeys: keys)
                let added = values?.addedToDirectoryDate ?? values?.contentModificationDate
                let opened = NSMetadataItem(url: url)?.value(forAttribute: "kMDItemLastUsedDate") as? Date
                let lastActivity = [added, opened, values?.isDirectory == true ? values?.contentModificationDate : nil]
                    .compactMap { $0 }.max()
                guard let lastActivity, lastActivity < daysAgo(minDays) else { continue }

                let type = url.pathExtension.lowercased()
                var stem = (url.lastPathComponent as NSString).deletingPathExtension
                if stem.lowercased().hasSuffix(".tar") { stem = (stem as NSString).deletingPathExtension }
                var reasons: [String] = []
                var suggested = false
                if installerTypes.contains(type), let app = installed.appMatching(fileName: url.lastPathComponent) {
                    reasons.append("Installer for \(app), which is installed")
                    suggested = suggests && lastActivity < daysAgo(7)
                } else if archiveTypes.contains(type), names.contains(stem) {
                    reasons.append("Already unzipped into “\(stem)”")
                    suggested = suggests && lastActivity < daysAgo(7)
                }
                if let opened {
                    reasons.append("last opened \(relative(opened))")
                } else {
                    reasons.append("no open recorded")
                    if suggests && throwawayTypes.contains(type) && (added ?? .distantFuture) < daysAgo(180) { suggested = true }
                }
                reasons.append("\(folder == "Downloads" ? "downloaded" : "added") \(relative(added))")
                result.append(Candidate(url: url, date: added, detail: "\(folder) · " + reasons.joined(separator: " · "),
                                        lastUsed: opened ?? added, suggested: suggested ? true : nil))
            }
        }
        return result
    }

    static let duplicates = CleanCategory(
        id: "duplicates", name: "Duplicate Files", icon: "doc.on.doc",
        summary: "Files over 1 MB with identical content in your home folder (outside Library). For each set, one copy is kept: the one outside Downloads with the shortest path. Right-click a copy to keep it instead. Copies that already share disk space (APFS clones) are left out, because deleting them frees nothing.",
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: true, owners: []
    ) { context in
        let home = context.home.path
        func short(_ url: URL) -> String { url.path.replacingOccurrences(of: home, with: "~") }
        return DuplicateFinder.find(home: context.home, minSize: 1 << 20, cancel: context.cancel).flatMap { group in
            group.copies.compactMap { copy -> Candidate? in
                let freed = DuplicateFinder.reclaimableBytes(copy.url.path, allocated: copy.size)
                guard freed >= 64 * 1024 else { return nil } // a clone: deleting frees nothing
                return Candidate(url: copy.url, date: modified(copy.url),
                                 detail: "In \(short(copy.url.deletingLastPathComponent())) · same as \(short(group.keep.url))", knownSize: freed,
                                 duplicateOf: group.keep.url)
            }
        }
    }

    static let unusedApps = CleanCategory(
        id: "apps", name: "Unused Apps", icon: "square.grid.2x2",
        summary: "Your apps, least recently used first. \"Last used\" combines Spotlight's record with traces apps leave when they run (settings, caches, saved windows). Apps from Apple and apps that are running can't be removed here.",
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        let library = context.path("Library")
        return InstalledAppsIndex.standardAppURLs().compactMap { url -> Candidate? in
            guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier,
                  !id.hasPrefix("com.apple."), id != Bundle.main.bundleIdentifier else { return nil }
            var dates: [Date] = []
            if let spotlight = NSMetadataItem(url: url)?.value(forAttribute: "kMDItemLastUsedDate") as? Date { dates.append(spotlight) }
            for trace in ["Preferences/\(id).plist", "Saved Application State/\(id).savedState", "Caches/\(id)",
                          "HTTPStorages/\(id)", "Containers/\(id)", "Application Support/\(id)"] {
                if let date = modified(library.appendingPathComponent(trace)) { dates.append(date) }
            }
            let lastUsed = dates.max()
            let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
                ?? url.deletingPathExtension().lastPathComponent
            return Candidate(url: url, name: name,
                             detail: lastUsed.map { "Last used \(relative($0))" } ?? "No recent use recorded",
                             owner: id, kind: .application, lastUsed: lastUsed ?? .distantPast)
        }
    }

    static let appLeftovers = CleanCategory(
        id: "leftovers", name: "App Leftovers", icon: "shippingbox.and.arrow.backward",
        summary: "Data left behind by apps that are no longer installed. Suggested: folders whose bundle ID matches no installed app, if they're web data or window state, or haven't changed in 90 days. Folders matched only by name (they can hold documents or saved games, or belong to an app on another drive) and recently changed ones are left for you to review. Everything goes to the Trash.",
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        let index = InstalledAppsIndex.current()
        let library = context.path("Library")
        var sources = ["Application Support", "Saved Application State", "HTTPStorages", "WebKit"]
        // Reading other apps' containers prompts for each one without Full Disk Access.
        if context.fullDiskAccess { sources.append("Containers") }
        var result: [Candidate] = []
        for source in sources {
            for entry in children(library.appendingPathComponent(source)) {
                let name = entry.lastPathComponent
                guard !name.hasPrefix("."), index.isOrphan(name) else { continue }
                let isBundleID = InstalledAppsIndex.looksLikeBundleID(name)
                // App-name folders are matched loosely, so also require them to be long unused.
                if !isBundleID {
                    guard name.first?.isUppercase == true, let date = modified(entry), date < daysAgo(90) else { continue }
                }
                // Suggest only confident matches: a bundle ID (not a loosely matched name) whose data is
                // either disposable web/window state, or hasn't changed in 90 days.
                let lastChange = modified(entry)
                let disposable = ["Saved Application State", "HTTPStorages", "WebKit"].contains(source)
                let suggested = isBundleID && (disposable || (lastChange ?? .distantFuture) < daysAgo(90))
                let why = !isBundleID ? "matched by name only, so review it"
                    : suggested ? "no installed app has this ID" : "changed recently, so review it"
                result.append(Candidate(url: entry, name: name, date: lastChange,
                                        detail: "\(source) · \(why)", owner: isBundleID ? name : nil,
                                        kind: .appLeftover, suggested: suggested ? true : nil))
            }
        }
        return result
    }

    static let simulators = CleanCategory(
        id: "simulators", name: "Old Simulators", icon: "iphone.gen3",
        summary: "iOS, watchOS and other simulator devices and runtimes. Devices whose runtime is no longer installed can't be used at all and are suggested. Others are listed if unused for 90 days. Removal goes through `xcrun simctl`, the same as Xcode.",
        safety: .review, mode: .permanent, needsFullDiskAccess: false, onDemand: false,
        owners: ["com.apple.iphonesimulator", "com.apple.dt.Xcode"]
    ) { context in
        var result: [Candidate] = []
        let cutoff = daysAgo(90)
        let iso = ISO8601DateFormatter()

        if let simctl = Tools.simctl,
           let data = Tools.run(simctl, ["list", "devices", "-j"], timeout: 30, extraEnvironment: Tools.developerDirectory)?.output,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let byRuntime = json["devices"] as? [String: [[String: Any]]] {
            for (runtime, devices) in byRuntime {
                // com.apple.CoreSimulator.SimRuntime.iOS-18-3 → "iOS 18.3"
                let parts = (runtime.split(separator: ".").last.map(String.init) ?? runtime).split(separator: "-")
                let runtimeName = parts.count > 1 ? "\(parts[0]) \(parts.dropFirst().joined(separator: "."))" : runtime
                for device in devices {
                    guard let udid = device["udid"] as? String, let dataPath = device["dataPath"] as? String else { continue }
                    let available = device["isAvailable"] as? Bool ?? true
                    let booted = (device["state"] as? String) == "Booted"
                    let lastBooted = (device["lastBootedAt"] as? String).flatMap(iso.date(from:))
                    let stale = (lastBooted ?? .distantPast) < cutoff
                    guard !available || stale else { continue }
                    let folder = URL(fileURLWithPath: dataPath).deletingLastPathComponent()
                    let size = (device["dataPathSize"] as? NSNumber)?.int64Value
                    let detail = !available ? "\(runtimeName) · runtime no longer installed"
                        : "\(runtimeName) · \(lastBooted.map { "last booted \(relative($0))" } ?? "never booted")"
                    result.append(Candidate(url: folder, name: device["name"] as? String ?? udid, date: lastBooted,
                                            detail: detail, knownSize: size, kind: .simulatorDevice(udid: udid),
                                            lastUsed: lastBooted, suggested: !available ? true : nil,
                                            lockedReason: booted ? "Running" : nil))
                }
            }
        }

        if let simctl = Tools.simctl,
           let data = Tools.run(simctl, ["runtime", "list", "-j"], timeout: 30, extraEnvironment: Tools.developerDirectory)?.output,
           let runtimes = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] {
            for runtime in runtimes.values {
                guard let id = runtime["identifier"] as? String, runtime["deletable"] as? Bool == true else { continue }
                let lastUsed = (runtime["lastUsedAt"] as? String).flatMap(iso.date(from:))
                guard (lastUsed ?? .distantPast) < cutoff else { continue }
                let platforms = ["iphonesimulator": "iOS", "watchsimulator": "watchOS", "appletvsimulator": "tvOS", "xrsimulator": "visionOS"]
                let platformID = (runtime["platformIdentifier"] as? String)?.split(separator: ".").last.map(String.init) ?? ""
                let platform = platforms[platformID] ?? "Simulator"
                let version = runtime["version"] as? String ?? ""
                let path = runtime["path"] as? String ?? "/Library/Developer/CoreSimulator/Images/\(id).dmg"
                result.append(Candidate(url: URL(fileURLWithPath: path), name: "\(platform) \(version) runtime",
                                        date: lastUsed, detail: "Runtime · last used \(relative(lastUsed))",
                                        knownSize: (runtime["sizeBytes"] as? NSNumber)?.int64Value,
                                        kind: .simulatorRuntime(identifier: id), lastUsed: lastUsed))
            }
        }
        return result
    }

    static let projectBuildFiles = CleanCategory(
        id: "projects", name: "Project Build Files", icon: "hammer.circle",
        summary: "Dependencies and build output inside your projects (node_modules, target, build, Pods, .venv…). They're recreated by the project's install or build command. Projects untouched for 90 days are suggested.",
        safety: .review, mode: .permanent, needsFullDiskAccess: false, onDemand: true, owners: []
    ) { context in
        /// Artifact folder → files that must sit next to it, so a random "build" folder isn't mistaken for one.
        let artifacts: [String: [String]] = [
            "node_modules": ["package.json"], "target": ["Cargo.toml"], "Pods": ["Podfile"],
            "build": ["build.gradle", "build.gradle.kts", "pubspec.yaml"], ".gradle": ["build.gradle", "build.gradle.kts", "settings.gradle", "settings.gradle.kts"],
            ".build": ["Package.swift"], ".venv": ["pyproject.toml", "requirements.txt", "setup.py"], "venv": ["pyproject.toml", "requirements.txt", "setup.py"],
            ".next": ["next.config.js", "next.config.mjs", "next.config.ts"], ".dart_tool": ["pubspec.yaml"],
        ]
        let allowedHidden: Set<String> = [".gradle", ".build", ".venv", ".next", ".dart_tool"]
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey]
        guard let walker = fm.enumerator(at: context.home, includingPropertiesForKeys: keys,
                                         options: [.skipsPackageDescendants], errorHandler: { _, _ in true }) else { return [] }
        let home = context.home.path
        var result: [Candidate] = []
        while let url = walker.nextObject() as? URL {
            if context.cancel?.isCancelled == true { break }
            let name = url.lastPathComponent
            guard (try? url.resourceValues(forKeys: Set(keys)))?.isDirectory == true else { continue }
            if walker.level == 1 && (name == "Library" || name == ".Trash") { walker.skipDescendants(); continue }
            if name.hasPrefix(".") && !allowedHidden.contains(name) { walker.skipDescendants(); continue }
            guard let markers = artifacts[name] else { continue }
            let project = url.deletingLastPathComponent()
            guard markers.contains(where: { fm.fileExists(atPath: project.appendingPathComponent($0).path) }) else { continue }
            walker.skipDescendants()

            // Project activity: newest change among its own top-level entries and git index.
            var latest = modified(project.appendingPathComponent(".git/index"))
            for entry in children(project) where artifacts[entry.lastPathComponent] == nil {
                if let date = modified(entry), date > (latest ?? .distantPast) { latest = date }
            }
            let inactive = (latest ?? .distantPast) < daysAgo(90)
            let projectPath = project.path.replacingOccurrences(of: home, with: "~")
            result.append(Candidate(url: url, name: "\(project.lastPathComponent) › \(name)",
                                    detail: "\(projectPath) · project changed \(relative(latest))",
                                    lastUsed: latest, suggested: inactive ? true : nil))
        }
        return result
    }

    static let mail = CleanCategory(
        id: "mail", name: "Mail", icon: "envelope",
        summary: "Local copies Mail keeps that the server can restore: attachments you opened, and cached attachments of IMAP, Exchange, Gmail and iCloud accounts (Mail downloads them again when you open a message). Your messages are never touched, and nothing is removed for POP or \"On My Mac\" mailboxes, whose mail exists only on this Mac. Quit Mail first.",
        safety: .review, mode: .trash, needsFullDiskAccess: true, onDemand: false, owners: ["com.apple.mail"]
    ) { context in
        var result = children(context.path("Library/Containers/com.apple.mail/Data/Library/Mail Downloads")).map {
            Candidate(url: $0, date: modified($0), detail: "Opened attachment")
        }
        let accounts = MailAccounts.load(home: context.home)
        for version in children(context.path("Library/Mail")) where version.lastPathComponent.hasPrefix("V") {
            for accountFolder in children(version) where accountFolder.lastPathComponent.count == 36 {
                let account = accounts[accountFolder.lastPathComponent.uppercased()]
                let attachments = MailAccounts.attachmentFolders(in: accountFolder)
                let size = attachments.reduce(Int64(0)) { $0 + context.engine.measure($1).allocated }
                guard size > 0 else { continue }
                let label = account?.label ?? "Unknown account"
                let locked = account?.isServerBacked == true ? nil
                    : account == nil ? "Account type unknown, so it's kept"
                    : "Stored only on this Mac (\(account?.typeName ?? "local"))"
                result.append(Candidate(url: accountFolder, name: "Cached attachments · \(label)",
                                        detail: "\(attachments.count) attachment folders", knownSize: size,
                                        kind: .mailAttachments, lockedReason: locked))
                // The same, limited to attachments not opened in a year.
                let old = MailAccounts.attachments(in: accountFolder, olderThanDays: 365)
                let oldSize = old.reduce(Int64(0)) { $0 + context.engine.measure($1).allocated }
                if oldSize > 0 && oldSize < size {
                    result.append(Candidate(url: accountFolder.appendingPathComponent("older-than-a-year", isDirectory: false),
                                            name: "Cached attachments older than a year · \(label)",
                                            detail: "\(old.count) messages' attachments", knownSize: oldSize,
                                            kind: .mailAttachmentsOlderThan(days: 365), lockedReason: locked))
                }
            }
        }
        return result
    }
}

// MARK: - Docker

public enum DockerCLI {
    /// Docker Desktop's command-line tool, only if it's genuinely signed by Docker Inc.
    /// (Spacebar's Full Disk Access passes to tools it runs, so an unverified `docker` is never run.)
    public static var path: String? {
        let candidates = ["/usr/local/bin/docker", "/Applications/Docker.app/Contents/Resources/bin/docker",
                          "\(NSHomeDirectory())/.docker/bin/docker", "/opt/homebrew/bin/docker"]
        for candidate in candidates where FileManager.default.isExecutableFile(atPath: candidate) {
            let resolved = URL(fileURLWithPath: candidate).resolvingSymlinksInPath().path
            if Tools.isTrusted(resolved, requirement: dockerRequirement) { return resolved }
        }
        return nil
    }

    /// Docker, Inc.'s Developer ID team.
    static let dockerRequirement = "anchor apple generic and certificate leaf[subject.OU] = \"9BNSXJN65R\""

    /// True if a docker command exists but isn't Docker's signed one (e.g. from Homebrew).
    public static var unverifiedPresent: Bool {
        path == nil && ["/usr/local/bin/docker", "/opt/homebrew/bin/docker", "\(NSHomeDirectory())/.docker/bin/docker"]
            .contains { FileManager.default.isExecutableFile(atPath: $0) }
    }

    /// Docker finds its engine socket through HOME; nothing else is passed on.
    public static var environment: [String: String] { [:] }

    public struct Usage: Equatable {
        public let type: String
        public let reclaimable: Int64
        public let total: Int
        public let active: Int
    }

    /// Parses `docker system df --format '{{json .}}'` (one JSON object per line).
    public static func parseSystemDF(_ output: String) -> [Usage] {
        output.split(separator: "\n").compactMap { line in
            guard let data = line.data(using: .utf8),
                  let row = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let type = row["Type"] as? String else { return nil }
            let reclaimable = (row["Reclaimable"] as? String).map { parseSize(String($0.split(separator: " ").first ?? "")) } ?? 0
            return Usage(type: type, reclaimable: reclaimable,
                         total: Int(row["TotalCount"] as? String ?? "") ?? 0, active: Int(row["Active"] as? String ?? "") ?? 0)
        }
    }

    /// "1.2GB", "512.3MB", "0B", "3.5kB": Docker's decimal units.
    public static func parseSize(_ text: String) -> Int64 {
        let units: [(String, Double)] = [("TB", 1e12), ("GB", 1e9), ("MB", 1e6), ("kB", 1e3), ("KB", 1e3), ("B", 1)]
        for (suffix, factor) in units where text.hasSuffix(suffix) {
            return Int64((Double(text.dropLast(suffix.count)) ?? 0) * factor)
        }
        return 0
    }

    /// nil when docker isn't installed, isn't verified, or its engine isn't running.
    static func systemDF() -> [Usage]? {
        guard let path, let result = Tools.run(path, ["system", "df", "--format", "{{json .}}"], timeout: 20),
              result.status == 0 else { return nil }
        return parseSystemDF(String(decoding: result.output, as: UTF8.self))
    }
}

public extension CleanCategory {
    static let docker = CleanCategory(
        id: "docker", name: "Docker", icon: "shippingbox.circle",
        summary: "Space inside Docker: build cache, unused images, stopped containers and unused volumes, removed with Docker's own prune commands. Build cache is suggested. Volumes are never suggested because they can hold databases. Docker returns freed space to macOS shortly afterwards.",
        safety: .review, mode: .permanent, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        guard DockerCLI.path != nil else {
            // A docker command we can't verify is never run; say so instead of hiding the category.
            guard DockerCLI.unverifiedPresent else { return [] }
            return [Candidate(url: URL(string: "docker://unverified")!, name: "Docker",
                              detail: "Only Docker Desktop's signed docker command is used", knownSize: 1,
                              kind: .dockerPrune(arguments: []),
                              lockedReason: "This docker command isn't signed by Docker, so Spacebar won't run it")]
        }
        let image = context.path("Library/Containers/com.docker.docker/Data/vms/0/data/Docker.raw")
        var st = stat()
        let imageBytes = lstat(image.path, &st) == 0 ? Int64(st.st_blocks) * 512 : 0
        let imageNote = imageBytes > 0 ? "Docker's disk image uses \(ByteFormat.string(imageBytes))" : nil

        guard let usage = DockerCLI.systemDF() else {
            // Engine not running: show the disk image, but nothing can be pruned.
            guard imageBytes > 0 else { return [] }
            return [Candidate(url: image, name: "Docker disk image", detail: imageNote, knownSize: imageBytes,
                              kind: .dockerPrune(arguments: []),
                              lockedReason: "Start Docker to see what can be pruned")]
        }
        let plans: [String: (name: String, arguments: [String], suggested: Bool?, detail: String)] = [
            "Build Cache": ("Build cache", ["builder", "prune", "--all", "--force"], true, "Rebuilt automatically when you build"),
            "Images": ("Unused images", ["image", "prune", "--all", "--force"], nil, "Images no container uses; downloaded again when needed"),
            "Containers": ("Stopped containers", ["container", "prune", "--force"], nil, "Containers that aren't running, and their files"),
            "Local Volumes": ("Unused volumes", ["volume", "prune", "--all", "--force"], false, "Volumes no container uses. They can hold databases and other data"),
        ]
        return usage.compactMap { row in
            guard let plan = plans[row.type], row.reclaimable > 0 else { return nil }
            let slug = row.type.lowercased().replacingOccurrences(of: " ", with: "-")
            return Candidate(url: URL(string: "docker://\(slug)")!, name: plan.name,
                             detail: ([plan.detail, "\(row.total) total, \(row.active) in use"] + [imageNote].compactMap { $0 })
                                .joined(separator: " · "),
                             knownSize: row.reclaimable, kind: .dockerPrune(arguments: plan.arguments),
                             suggested: plan.suggested)
        }
    }

    static let snapshots = CleanCategory(
        id: "snapshots", name: "Time Machine Snapshots", icon: "clock.arrow.circlepath",
        summary: "Local Time Machine snapshots on your startup disk. macOS keeps them for 24 hours and removes them by itself when it needs space; you can remove them now. Their exact size isn't reported, so the figure is macOS's purgeable space, which also includes some caches. Snapshots macOS makes for updates (com.apple.os.update) can't be removed.",
        safety: .review, mode: .permanent, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { _ in
        let snapshots = LocalSnapshots.list()
        guard !snapshots.isEmpty else { return [] }
        let dates = snapshots.compactMap { name -> Date? in
            // com.apple.TimeMachine.2026-10-02-101530.local
            let parts = name.split(separator: ".")
            guard parts.count >= 4 else { return nil }
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HHmmss"
            return formatter.date(from: String(parts[3]))
        }
        let purgeable = VolumeSpace.home()?.purgeable ?? 0
        return [Candidate(url: URL(string: "tmsnapshot://local")!, name: "\(snapshots.count) local snapshot\(snapshots.count == 1 ? "" : "s")",
                          date: dates.min(),
                          detail: "Oldest \(relative(dates.min())) · up to \(ByteFormat.string(purgeable)) purgeable",
                          knownSize: max(purgeable, 1), kind: .timeMachineSnapshots)]
    }
}

// MARK: - Messages attachments

public enum MessagesAttachments {
    public static func root(home: URL = FileManager.default.homeDirectoryForCurrentUser) -> URL {
        home.appendingPathComponent("Library/Messages/Attachments")
    }

    /// Attachment files older than `days`, grouped by the year they were received.
    public static func byYear(olderThanDays days: Int, home: URL = FileManager.default.homeDirectoryForCurrentUser,
                              minimumBytes: Int64 = 0) -> [Int: [(url: URL, bytes: Int64)]] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .contentModificationDateKey, .totalFileAllocatedSizeKey]
        guard let walker = fm.enumerator(at: root(home: home), includingPropertiesForKeys: Array(keys),
                                         options: [.skipsPackageDescendants], errorHandler: { _, _ in true }) else { return [:] }
        var groups: [Int: [(url: URL, bytes: Int64)]] = [:]
        while let url = walker.nextObject() as? URL {
            guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true,
                  let date = values.contentModificationDate, date < cutoff else { continue }
            let bytes = Int64(values.totalFileAllocatedSize ?? 0)
            guard bytes >= minimumBytes else { continue }
            groups[Calendar.current.component(.year, from: date), default: []].append((url, bytes))
        }
        return groups
    }

    public static func url(year: Int) -> URL { URL(string: "messages://attachments/\(year)")! }
}

public extension CleanCategory {
    static let messages = CleanCategory(
        id: "messages", name: "Messages Attachments", icon: "message",
        summary: "Photos, videos and files received in Messages more than a year ago, grouped by year. They go to the Trash, so Put Back works. If Messages in iCloud is on, they stay in iCloud; otherwise this is the only copy, so review them. Quit Messages first.",
        safety: .review, mode: .trash, needsFullDiskAccess: true, onDemand: false, owners: ["com.apple.MobileSMS"]
    ) { context in
        MessagesAttachments.byYear(olderThanDays: 365, home: context.home).sorted { $0.key > $1.key }.map { year, files in
            Candidate(url: MessagesAttachments.url(year: year), name: "Attachments from \(year)",
                      detail: "\(files.count) file\(files.count == 1 ? "" : "s") received in \(year)",
                      knownSize: files.reduce(0) { $0 + $1.bytes }, kind: .messagesAttachments(year: year, olderThanDays: 365))
        }
    }
}

// MARK: - Mail accounts

public enum MailAccounts {
    struct Account {
        let label: String
        let typeName: String
        let isServerBacked: Bool
    }

    /// Account types whose mail lives on a server, so local copies can be downloaded again.
    static let serverBacked = ["imap", "exchange", "google", "gmail", "icloud", "appleaccount", "yahoo", "aol", "outlook", "hotmail"]

    /// Reads ~/Library/Accounts/Accounts4.sqlite read-only (needs Full Disk Access).
    static func load(home: URL) -> [String: Account] {
        let path = home.appendingPathComponent("Library/Accounts/Accounts4.sqlite").path
        var db: OpaquePointer?
        guard sqlite3_open_v2("file:\(path)?immutable=1", &db, SQLITE_OPEN_READONLY | SQLITE_OPEN_URI, nil) == SQLITE_OK else {
            sqlite3_close(db)
            return [:]
        }
        defer { sqlite3_close(db) }
        let query = """
            SELECT a.ZIDENTIFIER, COALESCE(a.ZACCOUNTDESCRIPTION, a.ZUSERNAME, ''), COALESCE(t.ZIDENTIFIER, '')
            FROM ZACCOUNT a LEFT JOIN ZACCOUNTTYPE t ON a.ZACCOUNTTYPE = t.Z_PK
            """
        var statement: OpaquePointer?
        guard sqlite3_prepare_v2(db, query, -1, &statement, nil) == SQLITE_OK else { return [:] }
        defer { sqlite3_finalize(statement) }
        var accounts: [String: Account] = [:]
        while sqlite3_step(statement) == SQLITE_ROW {
            func text(_ column: Int32) -> String {
                sqlite3_column_text(statement, column).map { String(cString: $0) } ?? ""
            }
            let type = text(2).lowercased()
            let typeName = type.split(separator: ".").last.map(String.init) ?? type
            let backed = !type.contains("pop") && serverBacked.contains { type.contains($0) }
            accounts[text(0).uppercased()] = Account(label: text(1).isEmpty ? typeName : text(1),
                                                     typeName: typeName, isServerBacked: backed)
        }
        return accounts
    }

    /// Per-message attachment folders (Attachments/<message>) whose newest file is older than `days`.
    public static func attachments(in account: URL, olderThanDays days: Int) -> [URL] {
        let cutoff = Date().addingTimeInterval(-Double(days) * 86400)
        return attachmentFolders(in: account).flatMap { folder in
            ((try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []).filter { message in
                let newest = BulkScanner().measure(message).lastModified ?? .distantFuture
                return newest < cutoff
            }
        }
    }

    /// The "Attachments" folders Mail creates inside an account's mailboxes.
    public static func attachmentFolders(in account: URL) -> [URL] {
        guard let walker = fm.enumerator(at: account, includingPropertiesForKeys: [.isDirectoryKey],
                                         options: [.skipsHiddenFiles], errorHandler: { _, _ in true }) else { return [] }
        var folders: [URL] = []
        while let url = walker.nextObject() as? URL {
            if url.lastPathComponent == "Attachments",
               (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                folders.append(url)
                walker.skipDescendants()
            }
        }
        return folders
    }
}
