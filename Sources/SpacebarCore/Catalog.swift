import AppKit
import Foundation

public enum Safety: String, Sendable {
    /// Regenerated automatically; preselected.
    case safe
    /// May be user data; never preselected.
    case review
}

public enum RemovalMode: String, Sendable {
    /// Delete immediately: frees space now. Used for caches and logs.
    case permanent
    /// Move to the Trash: recoverable; frees space only when the Trash is emptied.
    case trash
}

/// How an item is removed. Anything but `.file` gets its own validation and removal path.
public enum ItemKind: Hashable, Sendable, Codable {
    /// A file or folder in an allowed location.
    case file
    /// An application bundle in /Applications or ~/Applications.
    case application
    /// Data folder of an app that is no longer installed (may be a whole app container).
    case appLeftover
    /// A simulator device, removed with `xcrun simctl delete`.
    case simulatorDevice(udid: String)
    /// A simulator runtime, removed with `xcrun simctl runtime delete`.
    case simulatorRuntime(identifier: String)
    /// A Mail account folder: only the cached "Attachments" folders inside it are removed.
    case mailAttachments
    /// Space inside Docker, freed with `docker <arguments>` (e.g. builder prune).
    case dockerPrune(arguments: [String])
    /// Time Machine local snapshots on the startup disk, removed with `tmutil deletelocalsnapshots /`.
    case timeMachineSnapshots
    /// A photo in the Photos library, moved to Recently Deleted through Photos.
    case photoAsset(identifier: String)
    /// Data an app keeps in ~/Library (for uninstalling it): only entries named for that app.
    case appData(bundleID: String, appName: String)
    /// A downloaded iCloud Drive file: its local copy is removed, it stays in iCloud.
    case iCloudEvict
    /// An Android emulator: its .avd folder plus the .ini file that registers it.
    case androidEmulator(ini: String)
    /// An old Homebrew version in the Cellar that is no longer linked.
    case homebrewKeg
    /// A downloaded AI model folder (LM Studio).
    case aiModel
    /// A git repository to compact: `git gc` runs in Terminal, outside Spacebar's permissions.
    case gitCompact
    /// Messages attachments from one year, older than `days` (moved to the Trash file by file).
    case messagesAttachments(year: Int, olderThanDays: Int)
    /// A Mail account's cached attachments not touched in `days` (Mail downloads them again).
    case mailAttachmentsOlderThan(days: Int)
}

public struct CleanItem: Identifiable, Hashable, Sendable, Codable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public var size: Int64
    public let date: Date?
    public var detail: String?
    /// Bundle ID of the app that owns this item, if known.
    public let owner: String?
    /// Set when `owner` was running at scan time.
    public var inUse: Bool = false
    /// Newest modification inside the item: when an app last wrote to it.
    public var lastUsed: Date?
    /// False when `owner` looks like an app's bundle ID but no such app is installed.
    public var ownerInstalled: Bool?
    public var kind: ItemKind = .file
    /// Overrides the category's suggestion rule for this item (e.g. unusable simulators).
    public var suggested: Bool?
    /// Can't be selected, with the reason shown to the user (e.g. "Stored only on this Mac").
    public var lockedReason: String?
    /// For duplicates: the copy that is kept.
    public var duplicateOf: URL?

    /// Whether the item may be selected for cleaning.
    public var isSelectable: Bool { !inUse && lockedReason == nil }

    /// What "Never Show in Cleanup" remembers: the path, or the full URL for non-file items.
    public var exclusionKey: String { Exclusions.key(for: url) }

    public init(url: URL, name: String, size: Int64, date: Date?, detail: String?, owner: String?) {
        self.url = url
        self.name = name
        self.size = size
        self.date = date
        self.detail = detail
        self.owner = owner
    }
}

/// "Never Show in Cleanup": excluded paths hide themselves and everything inside them.
public enum Exclusions {
    public static func key(for url: URL) -> String {
        url.isFileURL ? url.standardizedFileURL.path : url.absoluteString
    }

    public static func matches(_ url: URL, _ excluded: [String]) -> Bool {
        let key = key(for: url)
        return excluded.contains { key == $0 || key.hasPrefix($0.hasSuffix("/") ? $0 : $0 + "/") }
    }
}

/// Decides which items Spacebar suggests (preselects). A cache that an app wrote to
/// recently will just be rebuilt, so only stale ones are worth removing.
public enum Suggestion {
    public static let defaultStaleDays = 30
    /// Leftovers of uninstalled apps are suggested sooner.
    public static let orphanStaleDays = 7

    public static func isSuggested(_ item: CleanItem, in category: CleanCategory,
                                   staleDays: Int = defaultStaleDays, now: Date = Date()) -> Bool {
        guard item.isSelectable else { return false }
        if let suggested = item.suggested { return suggested }
        guard category.safety == .safe else { return false }
        guard category.ageBased else { return true }
        guard let lastUsed = item.lastUsed else { return false }
        let days = item.ownerInstalled == false ? min(staleDays, orphanStaleDays) : staleDays
        return lastUsed < now.addingTimeInterval(-Double(days) * 24 * 3600)
    }
}

public enum InstalledApps {
    /// Whether an app with this bundle ID (or a parent ID, e.g. com.microsoft.VSCode for
    /// com.microsoft.VSCode.ShipIt) is installed. nil when the name doesn't look like an app ID.
    public static func isInstalled(_ bundleID: String) -> Bool? {
        var parts = bundleID.split(separator: ".").map(String.init)
        guard parts.count >= 3, !bundleID.contains(" ") else { return nil }
        while parts.count >= 2 {
            if NSWorkspace.shared.urlForApplication(withBundleIdentifier: parts.joined(separator: ".")) != nil {
                return true
            }
            if parts.count == 2 { break }
            parts.removeLast()
        }
        // Also true for caches of command-line tools (e.g. org.swift.swiftpm), so this only
        // shortens the staleness threshold and is labelled "no matching app", never "uninstalled".
        return false
    }
}

public struct ScanContext: Sendable {
    public let home: URL
    public let engine: SizeEngine
    public let runningApps: Set<String>
    public let fullDiskAccess: Bool
    public let cancel: CancelToken?
    /// Paths (and their contents) the user never wants offered.
    public let excluded: [String]

    public init(engine: SizeEngine, runningApps: Set<String>, fullDiskAccess: Bool, cancel: CancelToken? = nil,
                excluded: [String] = []) {
        self.home = FileManager.default.homeDirectoryForCurrentUser
        self.engine = engine
        self.runningApps = runningApps
        self.fullDiskAccess = fullDiskAccess
        self.cancel = cancel
        self.excluded = excluded
    }

    func path(_ relative: String) -> URL { home.appendingPathComponent(relative) }
}

public struct CleanCategory: Identifiable, Sendable {
    public let id: String
    public let name: String
    public let icon: String
    public let summary: String
    public let safety: Safety
    public let mode: RemovalMode
    public let needsFullDiskAccess: Bool
    /// Not part of the default scan: it reads Desktop/Documents/Downloads, which triggers privacy prompts.
    public let onDemand: Bool
    /// Apps that should be quit before cleaning this category.
    public let owners: [String]
    /// Suggest only items that haven't been modified for a while (see `Suggestion`).
    public var ageBased: Bool { ["caches", "xcode", "devcaches"].contains(id) }

    public enum Group: Sendable { case cleanup, findSpace, rules }
    public enum SortOrder: Sendable { case largestFirst, oldestFirst }
    public var group: Group { id.hasPrefix("rule-") ? .rules : Self.findSpaceIDs.contains(id) ? .findSpace : .cleanup }
    public var sortOrder: SortOrder { id == "apps" ? .oldestFirst : .largestFirst }
    static let findSpaceIDs: Set<String> = ["forgotten", "icloud", "devtools", "messages", "duplicates", "apps", "leftovers", "simulators", "docker",
                                            "snapshots", "projects", "mail", "photos"]
    /// For a user's rule: the folder it looks in (see `isAffected`).
    var watchedFolder: String? = nil
    let collect: @Sendable (ScanContext) -> [Candidate]

    /// Whether changes at `paths` (from FSEvents) can change this category's results, so it must
    /// be scanned again. Categories that read many places, apps or tools always say yes.
    public func isAffected(by paths: [String], home: String) -> Bool {
        func under(_ folder: String) -> (String) -> Bool {
            let root = folder.hasPrefix("/") ? folder : home + "/" + folder
            return { $0 == root || $0.hasPrefix(root + "/") }
        }
        // Large files, duplicates and projects walk the home folder but skip Library, the Trash
        // and hidden folders, where most changes happen.
        // They also skip hidden folders anywhere (projects keep a few build ones, like .venv).
        let projectHidden: Set<String> = [".gradle", ".build", ".venv", ".next", ".dart_tool"]
        func visibleHome(allowing hidden: Set<String>) -> (String) -> Bool {
            { path in
                guard path.hasPrefix(home + "/") else { return false }
                let parts = path.dropFirst(home.count + 1).split(separator: "/").map(String.init)
                guard let first = parts.first, first != "Library" else { return false }
                return !parts.contains { $0.hasPrefix(".") && !hidden.contains($0) }
            }
        }
        let tests: [(String) -> Bool]
        switch id {
        case "logs": tests = [under("Library/Logs")]
        case "xcode": tests = [under("Library/Developer/Xcode")]
        case "trash": tests = [under(".Trash")]
        case "archives": tests = [under("Library/Developer/Xcode/Archives")]
        case "backups": tests = [under("Library/Application Support/MobileSync")]
        case "installers": tests = [under("/Applications")]
        case "large", "duplicates": tests = [visibleHome(allowing: [])]
        case "projects": tests = [visibleHome(allowing: projectHidden)]
        case "forgotten": tests = [under("Downloads"), under("Desktop"), under("/Applications")]
        case "icloud": tests = [under("Library/Mobile Documents"), under("Library/CloudStorage")]
        case "simulators": tests = [under("Library/Developer/CoreSimulator")]
        case "mail": tests = [under("Library/Mail")]
        case "messages": tests = [under("Library/Messages")]
        case "photos": tests = [under("Pictures"), under("Desktop"), under("Downloads")]
        default:
            guard let watchedFolder else { return true }
            tests = [under(watchedFolder)]
        }
        return paths.contains { path in tests.contains { $0(path) } }
    }

    struct Candidate {
        let url: URL
        var name: String? = nil
        var date: Date? = nil
        var detail: String? = nil
        var owner: String? = nil
        var knownSize: Int64? = nil
        var kind: ItemKind = .file
        /// Overrides the measured "newest modification" (e.g. an app's last launch).
        var lastUsed: Date? = nil
        var suggested: Bool? = nil
        var lockedReason: String? = nil
        var duplicateOf: URL? = nil
    }

    /// Finds and measures this category's items. Blocking: call off the main thread.
    public func scan(_ context: ScanContext) -> [CleanItem] {
        let candidates = collect(context).filter {
            PathRules.isDeletable($0.url, kind: $0.kind) && !Exclusions.matches($0.url, context.excluded)
        }
        let unsized = candidates.filter { $0.knownSize == nil }.map(\.url)
        let measured = Dictionary(uniqueKeysWithValues: zip(unsized, context.engine.measure(unsized, cancel: context.cancel)))

        return candidates.compactMap { candidate in
            let size = candidate.knownSize ?? measured[candidate.url]?.allocated ?? 0
            guard size > 0 else { return nil }
            let owner = candidate.owner ?? (owners.first { context.runningApps.contains($0) })
            var item = CleanItem(url: candidate.url, name: candidate.name ?? candidate.url.lastPathComponent,
                                 size: size, date: candidate.date, detail: candidate.detail, owner: owner)
            item.inUse = owner.map(context.runningApps.contains) ?? false
            item.lastUsed = candidate.lastUsed ?? measured[candidate.url]?.lastModified ?? candidate.date
            if ageBased, let owner = candidate.owner {
                item.ownerInstalled = InstalledApps.isInstalled(owner)
            }
            item.kind = candidate.kind
            item.suggested = candidate.suggested
            item.lockedReason = candidate.lockedReason
            item.duplicateOf = candidate.duplicateOf
            return item
        }
        .sorted(by: sortOrder == .oldestFirst
                ? { ($0.lastUsed ?? .distantPast) < ($1.lastUsed ?? .distantPast) }
                : { $0.size > $1.size })
    }
}

// MARK: - Helpers

private let fm = FileManager.default

private func children(_ url: URL, keys: [URLResourceKey] = []) -> [URL] {
    (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: keys, options: [])) ?? []
}

private func modified(_ url: URL) -> Date? {
    try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate
}

private func exists(_ url: URL) -> Bool { fm.fileExists(atPath: url.path) }

// MARK: - Catalog

public extension CleanCategory {
    static let all: [CleanCategory] = [
        appCaches, logs, xcode, developerCaches, trash,
        xcodeArchives, iosBackups, installers, largeFiles,
        forgottenFiles, iCloudDownloads, unusedApps, simulators, developerTools, docker, snapshots, appLeftovers, mail, messages,
        duplicates, similarPhotos,
        projectBuildFiles,
    ]

    static let appCaches = CleanCategory(
        id: "caches", name: String(localized: "App Caches"), icon: "archivebox",
        summary: String(localized: "Temporary files apps rebuild automatically. Most Apple system caches are left alone because some of them hold state."),
        safety: .safe, mode: .permanent, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        var result = children(context.path("Library/Caches"))
            .filter { CachePolicy.isCleanable($0.lastPathComponent) }
            .map { Candidate(url: $0, owner: CachePolicy.ownerBundleID(for: $0.lastPathComponent)) }

        // Sandboxed apps keep caches inside their container. Reading other apps' containers
        // prompts for every app without Full Disk Access, so only look with it.
        if context.fullDiskAccess {
            for container in children(context.path("Library/Containers")) {
                let bundleID = container.lastPathComponent
                guard CachePolicy.isCleanable(bundleID) || bundleID.hasPrefix("com.apple.") else { continue }
                for cache in children(container.appendingPathComponent("Data/Library/Caches"))
                where !cache.lastPathComponent.hasPrefix(".") {
                    result.append(Candidate(url: cache, name: "\(bundleID) › \(cache.lastPathComponent)", owner: bundleID))
                }
            }
        }
        return result
    }

    static let logs = CleanCategory(
        id: "logs", name: String(localized: "Logs & Crash Reports"), icon: "doc.text.magnifyingglass",
        summary: String(localized: "Diagnostic logs and crash reports written by apps and macOS."),
        safety: .safe, mode: .permanent, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        children(context.path("Library/Logs"))
            .filter { !$0.lastPathComponent.hasPrefix(".") && $0.lastPathComponent != "Spacebar" }
            .map { Candidate(url: $0) }
    }

    static let xcode = CleanCategory(
        id: "xcode", name: String(localized: "Xcode Build Data"), icon: "hammer",
        summary: String(localized: "DerivedData, build products, simulator caches, and old device support files. The newest two device support versions per platform are kept."),
        safety: .safe, mode: .permanent, needsFullDiskAccess: false, onDemand: false,
        owners: ["com.apple.dt.Xcode", "com.apple.iphonesimulator"]
    ) { context in
        var result: [Candidate] = []
        let dev = context.path("Library/Developer")
        for derived in children(dev.appendingPathComponent("Xcode/DerivedData")) {
            result.append(Candidate(url: derived, name: "DerivedData › \(derived.lastPathComponent)", date: modified(derived)))
        }
        for path in ["Xcode/Products", "CoreSimulator/Caches"] where exists(dev.appendingPathComponent(path)) {
            result.append(Candidate(url: dev.appendingPathComponent(path), name: path))
        }
        let xcodeCache = context.path("Library/Caches/com.apple.dt.Xcode")
        if exists(xcodeCache) { result.append(Candidate(url: xcodeCache, name: String(localized: "Xcode cache"))) }

        for platform in ["iOS", "watchOS", "tvOS", "visionOS"] {
            let folder = dev.appendingPathComponent("Xcode/\(platform) DeviceSupport")
            let versions = children(folder)
                .map { ($0, modified($0) ?? .distantPast) }
                .sorted { $0.1 > $1.1 }
            for (url, date) in versions.dropFirst(2) {
                result.append(Candidate(url: url, name: "\(platform) DeviceSupport › \(url.lastPathComponent)", date: date))
            }
        }
        return result
    }

    static let developerCaches = CleanCategory(
        id: "devcaches", name: String(localized: "Developer Caches"), icon: "shippingbox",
        summary: String(localized: "Package-manager download caches (npm, Yarn, pnpm, Bun, Cargo, Gradle, SwiftPM, uv, and more). They are re-downloaded when needed. Model weights and dependency repositories are never touched."),
        safety: .safe, mode: .permanent, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        let paths = [
            ".npm/_cacache", ".npm/_npx", ".npm/_logs", ".yarn/berry/cache", ".bun/install/cache",
            ".cargo/registry/cache", ".gradle/caches/build-cache-1", ".gradle/daemon",
            ".android/build-cache", ".android/cache", ".cache/swift-package-manager", ".cache/uv",
            ".cache/puppeteer", ".cache/node-gyp", ".cache/prisma", ".cache/vite", ".cache/webpack",
            ".cache/ruff", ".cache/mypy", ".cache/pre-commit", ".cache/bazel", ".docker/buildx/cache",
            ".cocoapods/repos/trunk",
        ]
        return paths.map { context.path($0) }.filter(exists).map {
            Candidate(url: $0, name: "~/" + $0.path.dropFirst(context.home.path.count + 1))
        }
    }

    static let trash = CleanCategory(
        id: "trash", name: String(localized: "Trash"), icon: "trash",
        summary: String(localized: "Items already in your Trash. Emptying it is permanent."),
        safety: .safe, mode: .permanent, needsFullDiskAccess: true, onDemand: false, owners: []
    ) { context in
        children(context.path(".Trash"))
            .filter { $0.lastPathComponent != ".DS_Store" }
            .map { Candidate(url: $0) }
    }

    static let xcodeArchives = CleanCategory(
        id: "archives", name: String(localized: "Xcode Archives"), icon: "archivebox.circle",
        summary: String(localized: "App archives from Product › Archive. They contain the debug symbols needed to read crash reports for shipped builds, so keep the ones you still support."),
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: false, owners: ["com.apple.dt.Xcode"]
    ) { context in
        children(context.path("Library/Developer/Xcode/Archives")).flatMap { day in
            children(day).filter { $0.pathExtension == "xcarchive" }.map {
                Candidate(url: $0, name: $0.deletingPathExtension().lastPathComponent, date: modified($0), detail: day.lastPathComponent)
            }
        }
    }

    static let iosBackups = CleanCategory(
        id: "backups", name: String(localized: "iPhone & iPad Backups"), icon: "iphone",
        summary: String(localized: "Local device backups made by Finder. Delete only backups you no longer need."),
        safety: .review, mode: .trash, needsFullDiskAccess: true, onDemand: false, owners: []
    ) { context in
        children(context.path("Library/Application Support/MobileSync/Backup")).map { backup in
            let info = NSDictionary(contentsOf: backup.appendingPathComponent("Info.plist"))
            return Candidate(url: backup,
                             name: (info?["Device Name"] as? String) ?? backup.lastPathComponent,
                             date: (info?["Last Backup Date"] as? Date) ?? modified(backup),
                             detail: info?["Product Name"] as? String)
        }
    }

    static let installers = CleanCategory(
        id: "installers", name: String(localized: "macOS Installers"), icon: "arrow.down.app",
        summary: String(localized: "Downloaded \"Install macOS\" apps. You can download them again from Apple."),
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { _ in
        children(URL(fileURLWithPath: "/Applications"))
            .filter { $0.lastPathComponent.hasPrefix("Install macOS") && $0.pathExtension == "app" }
            .map { Candidate(url: $0, date: modified($0)) }
    }

    static let largeFiles = CleanCategory(
        id: "large", name: String(localized: "Large Files"), icon: "doc.badge.ellipsis",
        summary: String(localized: "Files over 500 MB in your home folder (outside Library). Review each one carefully."),
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: true, owners: []
    ) { context in
        let threshold: Int64 = 500 * 1024 * 1024
        let keys: [URLResourceKey] = [.isRegularFileKey, .totalFileAllocatedSizeKey, .contentModificationDateKey]
        guard let walker = fm.enumerator(at: context.home, includingPropertiesForKeys: keys,
                                         options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                         errorHandler: { _, _ in true }) else { return [] }
        var found: [Candidate] = []
        while let url = walker.nextObject() as? URL {
            if context.cancel?.isCancelled == true { break }
            if walker.level == 1 && url.lastPathComponent == "Library" {
                walker.skipDescendants()
                continue
            }
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.isRegularFile == true,
                  let size = values.totalFileAllocatedSize, Int64(size) >= threshold else { continue }
            let folder = url.deletingLastPathComponent().path.replacingOccurrences(of: context.home.path, with: "~")
            found.append(Candidate(url: url, date: values.contentModificationDate, detail: folder, knownSize: Int64(size)))
        }
        return found
    }
}
