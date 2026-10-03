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
        /// Where trashed items ended up, so "Delete Now" can remove exactly those and nothing else.
        var trashedItems: [(url: URL, bytes: Int64)] = []
        /// This report is for deleting items from the Trash.
        var emptiedTrash = false
    }

    static let logURL = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Logs/Spacebar/operations.log")

    static func run(_ requests: [Request], dryRun: Bool) -> Report {
        var report = Report(dryRun: dryRun)
        let running = RunningApps.bundleIDs()
        let trash = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".Trash").path + "/"
        var log: [String] = []
        var installedApps: InstalledAppsIndex?

        for request in requests {
            let item = request.item
            let url = item.url
            if let reason = PathRules.reasonNotDeletable(url, kind: item.kind) {
                report.skipped.append((item.name, "Protected: \(reason)"))
                continue
            }
            if let reason = item.lockedReason {
                report.skipped.append((item.name, reason))
                continue
            }
            if let owner = item.owner, running.contains(owner) {
                report.skipped.append((item.name, "\(appName(owner)) is running. Quit it first."))
                continue
            }
            if item.kind == .appLeftover {
                // The app may have been reinstalled since the scan.
                if installedApps == nil { installedApps = InstalledAppsIndex.current() }
                if installedApps?.isOrphan(url.lastPathComponent) == false {
                    report.skipped.append((item.name, "Its app is installed again"))
                    continue
                }
            }
            let action = Action(item: item, requested: request.mode, trashPrefix: trash)

            if dryRun {
                log.append(entry("DRY-RUN-\(action.label)", item))
                if action.freesNow { report.deletedBytes += item.size } else { report.trashedBytes += item.size }
                continue
            }
            do {
                let landed = try action.perform(url)
                for (index, location) in landed.enumerated() {
                    report.trashedItems.append((location, index == 0 ? item.size : 0))
                }
                if action.freesNow { report.deletedBytes += item.size } else { report.trashedBytes += item.size }
                report.removed.append(url)
                report.removedItems.append((url.path, item.size, !action.freesNow))
                log.append(entry(action.label, item))
            } catch {
                report.skipped.append((item.name, error.localizedDescription))
                log.append(entry("FAILED", item) + "\t\(error.localizedDescription)")
            }
        }
        appendToLog(log)
        return report
    }

    /// What removing one item means, depending on its kind.
    private enum Action {
        case delete
        case trash
        case recycleApp
        case simctl([String])
        case trashMailAttachments

        init(item: CleanItem, requested: RemovalMode, trashPrefix: String) {
            switch item.kind {
            case .simulatorDevice(let udid): self = .simctl(["delete", udid])
            case .simulatorRuntime(let id): self = .simctl(["runtime", "delete", id])
            case .application: self = .recycleApp
            case .mailAttachments: self = .trashMailAttachments
            case .appLeftover: self = .trash
            case .file:
                // Items already in the Trash can only be deleted.
                self = item.url.path.hasPrefix(trashPrefix) || requested == .permanent ? .delete : .trash
            }
        }

        var freesNow: Bool {
            switch self {
            case .delete, .simctl: return true
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
            }
        }

        /// Performs the removal; returns where trashed items landed in the Trash.
        func perform(_ url: URL) throws -> [URL] {
            switch self {
            case .delete:
                try Cleaner.removePermanently(url)
                return []
            case .trash:
                return [try Cleaner.trash(url)]
            case .recycleApp:
                // Like Finder: asks for an administrator password if the app needs one.
                return try Cleaner.recycle(url)
            case .simctl(let arguments):
                try Cleaner.simctl(arguments)
                return []
            case .trashMailAttachments:
                return try MailAccounts.attachmentFolders(in: url).map(Cleaner.trash)
            }
        }
    }

    private static func trash(_ url: URL) throws -> URL {
        var landed: NSURL?
        try FileManager.default.trashItem(at: url, resultingItemURL: &landed)
        return (landed as URL?) ?? url
    }

    private static func recycle(_ url: URL) throws -> [URL] {
        let done = DispatchSemaphore(value: 0)
        var failure: Error?
        var landed: [URL] = []
        NSWorkspace.shared.recycle([url]) { newURLs, error in
            failure = error
            landed = Array(newURLs.values)
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
    static func deleteFromTrash(_ items: [(url: URL, bytes: Int64)], dryRun: Bool) -> Report {
        var report = Report(dryRun: dryRun)
        report.emptiedTrash = true
        var log: [String] = []
        for (url, bytes) in items {
            let item = CleanItem(url: url, name: url.lastPathComponent, size: bytes, date: nil, detail: nil, owner: nil)
            guard isInTrash(url) else {
                report.skipped.append((url.lastPathComponent, "Not in the Trash"))
                continue
            }
            guard FileManager.default.fileExists(atPath: url.path) || (try? url.checkResourceIsReachable()) == true else {
                report.skipped.append((url.lastPathComponent, "No longer in the Trash"))
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
        return error.map { ($0[NSAppleScript.errorMessage] as? String) ?? "Finder couldn't empty the Trash" }
    }

    private static func simctl(_ arguments: [String]) throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = ["simctl"] + arguments
        let errors = Pipe()
        process.standardError = errors
        process.standardOutput = FileHandle.nullDevice
        try process.run()
        process.waitUntilExit()
        guard process.terminationStatus == 0 else {
            let message = String(decoding: errors.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            throw NSError(domain: "Spacebar", code: Int(process.terminationStatus), userInfo: [
                NSLocalizedDescriptionKey: message.isEmpty ? "simctl failed" : message.trimmingCharacters(in: .whitespacesAndNewlines),
            ])
        }
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
