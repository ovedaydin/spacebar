import AppKit
import Foundation
import SpacebarCore

/// The only code in Spacebar that removes files. Every item is re-validated right before removal.
enum Cleaner {
    struct Request: Sendable {
        let item: CleanItem
        let mode: RemovalMode
    }

    struct Report: Identifiable {
        let id = UUID()
        var dryRun: Bool
        var deletedBytes: Int64 = 0
        var trashedBytes: Int64 = 0
        var removed: [URL] = []
        /// What was removed, its size, and whether it went to the Trash (so no space was freed yet).
        var removedItems: [(path: String, bytes: Int64, trashed: Bool)] = []
        var skipped: [(name: String, reason: String)] = []
        /// Where trashed items ended up (and came from), so "Delete Now" and "Put Back" act on
        /// exactly those and nothing else.
        var trashedItems: [TrashedItem] = []
        /// Items moved back out of the Trash by "Put Back".
        var restoredItems: [TrashedItem] = []
        /// This report is for deleting items from the Trash.
        var emptiedTrash = false
        /// Library photos moved to Recently Deleted in Photos.
        var photosCount = 0
        var photosBytes: Int64 = 0
    }

    struct TrashedItem: Sendable {
        /// Location in the Trash.
        let url: URL
        /// Where it was before cleaning.
        let original: URL
        let bytes: Int64
    }

    static let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/Spacebar/operations.log")

    /// `history`: where the clean came from, to keep it in the cleaning history (nil: don't record).
    static func run(_ requests: [Request], dryRun: Bool, history: CleaningRecord.Source? = nil) -> Report {
        var report = Report(dryRun: dryRun)
        var recorded: [CleaningRecord.Item] = []
        let running = RunningApps.bundleIDs()
        let trash = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path + "/"
        var log: [String] = []
        var installedApps: InstalledAppsIndex?
        // Library photos are deleted together, so macOS asks for confirmation once.
        var photos: [(identifier: String, item: CleanItem)] = []

        for request in requests {
            let item = request.item
            let url = item.url
            if let reason = PathRules.reasonNotDeletable(url, kind: item.kind) {
                report.skipped.append((item.name, String(localized: "Protected: \(reason)")))
                continue
            }
            if let reason = item.lockedReason {
                report.skipped.append((item.name, reason))
                continue
            }
            if let owner = item.owner, running.contains(owner) {
                report.skipped.append((item.name, String(localized: "\(appName(owner)) is running. Quit it first.")))
                continue
            }
            if item.kind == .appLeftover {
                // The app may have been reinstalled since the scan.
                if installedApps == nil { installedApps = InstalledAppsIndex.current() }
                if installedApps?.isOrphan(url.lastPathComponent) == false {
                    report.skipped.append((item.name, String(localized: "Its app is installed again")))
                    continue
                }
            }
            if case .photoAsset(let identifier) = item.kind {
                photos.append((identifier, item))
                continue
            }
            let action = Action(item: item, requested: request.mode, trashPrefix: trash)

            if dryRun {
                log.append(entry("DRY-RUN-\(action.label)", item))
                if action.freesNow { report.deletedBytes += item.size } else { report.trashedBytes += item.size }
                continue
            }
            do {
                let landed = try action.perform(url)
                for (index, move) in landed.enumerated() {
                    report.trashedItems.append(TrashedItem(url: move.landed, original: move.original,
                                                           bytes: index == 0 ? item.size : 0))
                }
                if action.freesNow { report.deletedBytes += item.size } else { report.trashedBytes += item.size }
                report.removed.append(url)
                report.removedItems.append((url.path, item.size, !action.freesNow))
                recorded.append(.init(name: item.name, original: url.path,
                                      trashed: action.freesNow ? nil : landed.first?.landed.path, bytes: item.size))
                log.append(entry(action.label, item))
            } catch {
                report.skipped.append((item.name, error.localizedDescription))
                log.append(entry("FAILED", item) + "\t\(error.localizedDescription)")
            }
        }
        if !photos.isEmpty {
            let bytes = photos.reduce(Int64(0)) { $0 + $1.item.size }
            if dryRun {
                photos.forEach { log.append(entry("DRY-RUN-PHOTOS-RECENTLY-DELETED", $0.item)) }
                report.photosBytes = bytes
                report.photosCount = photos.count
            } else {
                do {
                    try PhotosLibrary.delete(photos.map(\.identifier))
                    report.photosBytes = bytes
                    report.photosCount = photos.count
                    report.removed += photos.map(\.item.url)
                    photos.forEach { log.append(entry("PHOTOS-RECENTLY-DELETED", $0.item)) }
                } catch {
                    // Includes the user choosing Don't Allow in the Photos confirmation.
                    report.skipped.append((String(localized: "\(photos.count) photos"), error.localizedDescription))
                }
            }
        }
        appendToLog(log)
        if let history, !dryRun, !recorded.isEmpty || report.photosCount > 0 {
            CleaningHistory.append(CleaningRecord(date: Date(), source: history, freedBytes: report.deletedBytes,
                                                  trashedBytes: report.trashedBytes, photos: report.photosCount,
                                                  items: recorded))
        }
        return report
    }

    /// What removing one item means, depending on its kind.
    private enum Action {
        case delete
        case trash
        case recycleApp
        case simctl([String])
        case trashMailAttachments
        case docker([String])
        case deleteSnapshots
        case evict
        case trashEmulator(ini: String)
        case gitGCInTerminal
        case trashMessages(year: Int, days: Int)
        case trashOldMailAttachments(days: Int)

        init(item: CleanItem, requested: RemovalMode, trashPrefix: String) {
            switch item.kind {
            case .simulatorDevice(let udid): self = .simctl(["delete", udid])
            case .simulatorRuntime(let id): self = .simctl(["runtime", "delete", id])
            case .application: self = .recycleApp
            case .mailAttachments: self = .trashMailAttachments
            case .appLeftover, .photoAsset, .appData: self = .trash
            case .iCloudEvict: self = .evict
            case .androidEmulator(let ini): self = .trashEmulator(ini: ini)
            case .homebrewKeg: self = .delete
            case .aiModel: self = .trash
            case .gitCompact: self = .gitGCInTerminal
            case .messagesAttachments(let year, let days): self = .trashMessages(year: year, days: days)
            case .mailAttachmentsOlderThan(let days): self = .trashOldMailAttachments(days: days)
            case .dockerPrune(let arguments): self = .docker(arguments)
            case .timeMachineSnapshots: self = .deleteSnapshots
            case .file:
                // Items already in the Trash can only be deleted.
                self = item.url.path.hasPrefix(trashPrefix) || requested == .permanent ? .delete : .trash
            }
        }

        var freesNow: Bool {
            switch self {
            case .delete, .simctl, .docker, .deleteSnapshots, .evict, .gitGCInTerminal: return true
            case .trashEmulator, .trashMessages, .trashOldMailAttachments: return false
            case .trash, .recycleApp, .trashMailAttachments: return false
            }
        }

        var label: String {
            switch self {
            case .delete: return "PERMANENT"
            case .trash: return "TRASH"
            case .recycleApp: return "TRASH-APP"
            case .simctl(let args): return "SIMCTL-" + args.dropLast().joined(separator: "-").uppercased()
            case .trashMailAttachments: return "TRASH-MAIL-ATTACHMENTS"
            case .docker(let args): return "DOCKER-" + args.prefix(2).joined(separator: "-").uppercased()
            case .deleteSnapshots: return "TMUTIL-DELETE-LOCAL-SNAPSHOTS"
            case .evict: return "ICLOUD-REMOVE-DOWNLOAD"
            case .trashEmulator: return "TRASH-ANDROID-EMULATOR"
            case .gitGCInTerminal: return "GIT-GC-IN-TERMINAL"
            case .trashMessages: return "TRASH-MESSAGES-ATTACHMENTS"
            case .trashOldMailAttachments: return "TRASH-OLD-MAIL-ATTACHMENTS"
            }
        }

        /// Performs the removal; returns what moved to the Trash and from where.
        func perform(_ url: URL) throws -> [(original: URL, landed: URL)] {
            switch self {
            case .delete:
                try Cleaner.removePermanently(url)
                return []
            case .trash:
                return [(url, try Cleaner.trash(url))]
            case .recycleApp:
                // Like Finder: asks for an administrator password if the app needs one.
                return try Cleaner.recycle(url)
            case .simctl(let arguments):
                try Cleaner.simctl(arguments)
                return []
            case .trashMailAttachments:
                return try MailAccounts.attachmentFolders(in: url).map { ($0, try Cleaner.trash($0)) }
            case .docker(let arguments):
                guard let docker = DockerCLI.path, !arguments.isEmpty else { throw Cleaner.failure(String(localized: "Docker isn't available")) }
                try Cleaner.runTool(docker, arguments, environment: DockerCLI.environment)
                return []
            case .deleteSnapshots:
                try Cleaner.runTool("/usr/bin/tmutil", ["deletelocalsnapshots", "/"])
                return []
            case .evict:
                // Removes only the local copy; the file stays in the cloud. Checked again now:
                // a file with changes not yet uploaded keeps its local copy.
                let values = try url.resourceValues(forKeys: [.ubiquitousItemIsUploadedKey, .ubiquitousItemIsUploadingKey])
                guard values.ubiquitousItemIsUploaded == true, values.ubiquitousItemIsUploading != true else {
                    throw Cleaner.failure(String(localized: "It has changes that aren't uploaded yet"))
                }
                try FileManager.default.evictUbiquitousItem(at: url)
                return []
            case .trashEmulator(let ini):
                let folder = (url, try Cleaner.trash(url))
                let registration = FileManager.default.fileExists(atPath: ini)
                    ? [(URL(fileURLWithPath: ini), try Cleaner.trash(URL(fileURLWithPath: ini)))] : []
                return [folder] + registration
            case .trashMessages(let year, let days):
                // Found again now, and only inside ~/Library/Messages/Attachments.
                let root = MessagesAttachments.root().standardizedFileURL.path + "/"
                return try (MessagesAttachments.byYear(olderThanDays: days)[year] ?? [])
                    .filter { $0.url.standardizedFileURL.path.hasPrefix(root) }
                    .map { ($0.url, try Cleaner.trash($0.url)) }
            case .trashOldMailAttachments(let days):
                return try MailAccounts.attachments(in: url.deletingLastPathComponent(), olderThanDays: days)
                    .map { ($0, try Cleaner.trash($0)) }
            case .gitGCInTerminal:
                // Runs in Terminal, outside Spacebar's Full Disk Access: a repository's own config can run commands.
                try Cleaner.runInTerminal(directory: url.deletingLastPathComponent(), command: "git gc")
                return []
            }
        }
    }

    private static func trash(_ url: URL) throws -> URL {
        var landed: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &landed)
        return (landed as URL?) ?? url
    }

    private static func recycle(_ url: URL) throws -> [(original: URL, landed: URL)] {
        let done = DispatchSemaphore(value: 0)
        var failure: Error?
        var landed: [(original: URL, landed: URL)] = []
        NSWorkspace.shared.recycle([url]) { newURLs, error in
            failure = error
            landed = newURLs.map { ($0.key, $0.value) }
            done.signal()
        }
        done.wait()
        if let failure { throw failure }
        return landed
    }

    /// True for paths inside a Trash: ~/.Trash or a volume's .Trashes.
    static func isInTrash(_ url: URL) -> Bool {
        let path = url.standardizedFileURL.path
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return path.hasPrefix(home + "/.Trash/") || (path.hasPrefix("/Volumes/") && path.contains("/.Trashes/"))
    }

    /// Permanently deletes items that are in the Trash. Anything not in a Trash is refused.
    /// Moves trashed items back to where they were, like Finder's Put Back.
    /// Never overwrites: if something now exists at the original path, that item is skipped.
    static func putBack(_ items: [TrashedItem], dryRun: Bool) -> Report {
        var report = Report(dryRun: dryRun)
        var log: [String] = []
        let fm = FileManager.default
        for trashed in items {
            let item = CleanItem(url: trashed.original, name: trashed.original.lastPathComponent, size: trashed.bytes,
                                 date: nil, detail: nil, owner: nil)
            guard isInTrash(trashed.url), fm.fileExists(atPath: trashed.url.path) else {
                report.skipped.append((item.name, String(localized: "No longer in the Trash")))
                continue
            }
            guard !fm.fileExists(atPath: trashed.original.path) else {
                report.skipped.append((item.name, String(localized: "Something else is at its original location now")))
                continue
            }
            if dryRun {
                log.append(entry("DRY-RUN-PUT-BACK", item))
                continue
            }
            do {
                try fm.createDirectory(at: trashed.original.deletingLastPathComponent(), withIntermediateDirectories: true)
                try fm.moveItem(at: trashed.url, to: trashed.original)
                report.restoredItems.append(trashed)
                log.append(entry("PUT-BACK", item))
            } catch {
                report.skipped.append((item.name, error.localizedDescription))
                log.append(entry("FAILED", item) + "\t\(error.localizedDescription)")
            }
        }
        appendToLog(log)
        return report
    }

    static func deleteFromTrash(_ items: [(url: URL, bytes: Int64)], dryRun: Bool) -> Report {
        var report = Report(dryRun: dryRun)
        report.emptiedTrash = true
        var log: [String] = []
        for (url, bytes) in items {
            let item = CleanItem(url: url, name: url.lastPathComponent, size: bytes, date: nil, detail: nil, owner: nil)
            guard isInTrash(url) else {
                report.skipped.append((url.lastPathComponent, String(localized: "Not in the Trash")))
                continue
            }
            guard FileManager.default.fileExists(atPath: url.path) || (try? url.checkResourceIsReachable()) == true else {
                report.skipped.append((url.lastPathComponent, String(localized: "No longer in the Trash")))
                continue
            }
            if dryRun {
                log.append(entry("DRY-RUN-EMPTY-TRASH", item))
                report.deletedBytes += bytes
                continue
            }
            do {
                try removePermanently(url)
                report.deletedBytes += bytes
                report.removed.append(url)
                report.removedItems.append((url.path, bytes, false))
                log.append(entry("EMPTY-TRASH", item))
            } catch {
                report.skipped.append((url.lastPathComponent, error.localizedDescription))
                log.append(entry("FAILED", item) + "\t\(error.localizedDescription)")
            }
        }
        appendToLog(log)
        return report
    }

    /// Everything in ~/.Trash with its size. Needs Full Disk Access; nil without it.
    static func trashContents() -> [(url: URL, bytes: Int64)]? {
        let trash = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash")
        guard let urls = try? FileManager.default.contentsOfDirectory(at: trash, includingPropertiesForKeys: nil) else {
            return nil
        }
        let items = urls.filter { $0.lastPathComponent != ".DS_Store" }
        let sizes = BulkScanner().measure(items, cancel: nil)
        return zip(items, sizes).map { ($0, $1.allocated) }
    }

    /// Without Full Disk Access Spacebar can't see into the Trash, so it asks Finder to empty it.
    static func emptyTrashWithFinder() -> String? {
        var error: NSDictionary?
        NSAppleScript(source: "tell application \"Finder\" to empty trash")?.executeAndReturnError(&error)
        return error.map { ($0[NSAppleScript.errorMessage] as? String) ?? String(localized: "Finder couldn't empty the Trash") }
    }

    /// Opens Terminal in `directory` and runs `command` there.
    static func runInTerminal(directory: URL, command: String) throws {
        let path = directory.path.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
        let script = """
        tell application "Terminal"
            activate
            do script "cd " & quoted form of "\(path)" & " && \(command)"
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error { throw failure((error[NSAppleScript.errorMessage] as? String) ?? String(localized: "Couldn't open Terminal")) }
    }

    static func failure(_ message: String) -> NSError {
        NSError(domain: "Spacebar", code: 1, userInfo: [NSLocalizedDescriptionKey: message])
    }

    /// Runs a command-line tool (absolute path, clean environment); throws its error output if it fails.
    static func runTool(_ path: String, _ arguments: [String], environment: [String: String] = [:]) throws {
        guard let result = Tools.run(path, arguments, timeout: 600, extraEnvironment: environment) else {
            throw failure(String(localized: "\((path as NSString).lastPathComponent) couldn't start"))
        }
        guard result.status == 0 else {
            throw failure(result.errors.isEmpty ? String(localized: "\((path as NSString).lastPathComponent) failed") : result.errors)
        }
    }

    /// Apple's simctl, verified (see Tools.simctl).
    private static func simctl(_ arguments: [String]) throws {
        guard let simctl = Tools.simctl else { throw failure(String(localized: "Apple's simctl isn't available or couldn't be verified")) }
        try runTool(simctl, arguments, environment: Tools.developerDirectory)
    }

    private static func removePermanently(_ url: URL) throws {
        do {
            try FileManager.default.removeItem(at: url)
        } catch let error as CocoaError where error.code == .fileWriteNoPermission {
            // Read-only trees (e.g. Go's module cache) can't be emptied until their folders are writable.
            makeFoldersWritable(url)
            try FileManager.default.removeItem(at: url)
        }
    }

    private static func makeFoldersWritable(_ url: URL) {
        let fm = FileManager.default
        func addWrite(_ path: String) {
            guard let attrs = try? fm.attributesOfItem(atPath: path),
                  attrs[.type] as? FileAttributeType == .typeDirectory,
                  let perms = attrs[.posixPermissions] as? Int else { return }
            try? fm.setAttributes([.posixPermissions: perms | 0o200], ofItemAtPath: path)
        }
        addWrite(url.path)
        let walker = fm.enumerator(at: url, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey], options: [])
        while let child = walker?.nextObject() as? URL {
            let values = try? child.resourceValues(forKeys: [.isDirectoryKey, .isSymbolicLinkKey])
            if values?.isDirectory == true && values?.isSymbolicLink != true { addWrite(child.path) }
        }
    }

    static func appName(_ bundleID: String) -> String {
        NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first?.localizedName ?? bundleID
    }

    private static func entry(_ action: String, _ item: CleanItem) -> String {
        "\(ISO8601DateFormatter().string(from: Date()))\t\(action)\t\(item.size)\t\(item.url.path)"
    }

    private static func appendToLog(_ lines: [String]) {
        guard !lines.isEmpty else { return }
        let fm = FileManager.default
        try? fm.createDirectory(at: logURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = Data((lines.joined(separator: "\n") + "\n").utf8)
        if let handle = try? FileHandle(forWritingTo: logURL) {
            handle.seekToEndOfFile()
            handle.write(data)
            try? handle.close()
        } else {
            try? data.write(to: logURL)
        }
    }
}
