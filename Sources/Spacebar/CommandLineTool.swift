import AppKit
import Foundation
import SpacebarCore

/// `spacebar …` in a terminal. It's the app's own binary (Homebrew links it as `spacebar`), so it
/// cleans with exactly the same rules and safety checks as the window.
enum CommandLineTool {
    static let usage = """
    Spacebar: see what takes up space on your Mac and clean it up.

    USAGE
      spacebar status                    Free space on your startup disk
      spacebar categories                List the categories and their IDs
      spacebar scan [ID…] [--json]       Scan categories (all by default) and show what Spacebar suggests
      spacebar clean --safe [OPTIONS]    Remove caches and logs nobody used recently (as automatic cleaning does)
      spacebar clean ID… [OPTIONS]       Remove Spacebar's suggestions in these categories
      spacebar show PATH                 Open a folder in Space Explorer

    CLEAN OPTIONS
      --dry-run    Only list what would be removed
      --yes        Don't ask for confirmation (required when not run interactively)
      --json       Print the result as JSON

    Only what Spacebar suggests is removed, the same items it preselects in the app. Your
    Dry Run setting, Exclusions and "unused for" days apply here too.
    """

    private static let commands: Set<String> = ["status", "categories", "scan", "clean", "show",
                                                "help", "--help", "-h", "version", "--version"]

    /// Whether to run as the command-line tool rather than the app: when called by the name
    /// `spacebar` (the app itself is always started as `Spacebar`), or with a known command.
    static func isRequested(_ arguments: [String]) -> Bool {
        guard let name = arguments.first.map({ URL(fileURLWithPath: $0).lastPathComponent }) else { return false }
        return name == "spacebar" || (arguments.count > 1 && commands.contains(arguments[1]))
    }

    static func run(_ arguments: [String]) -> Never {
        // Same as the app: background disk priority, and never download iCloud files to measure them.
        IOPolicy.configureForScanning()
        // Work happens on its own thread; the main queue stays free for AppKit callbacks
        // (moving apps to the Trash completes there).
        Thread.detachNewThread {
            let code = execute(Array(arguments.dropFirst()))
            fflush(stdout)
            exit(code)
        }
        dispatchMain()
    }

    private struct UsageError: Error { let message: String }

    private static func execute(_ arguments: [String]) -> Int32 {
        var flags = Set(arguments.filter { $0.hasPrefix("-") })
        let words = arguments.filter { !$0.hasPrefix("-") }
        let command = words.first ?? "help"
        let rest = Array(words.dropFirst())
        if flags.remove("--help") != nil || flags.remove("-h") != nil || command == "help" {
            print(usage)
            return 0
        }
        do {
            switch command {
            case "version": print(version)
            case "status": status()
            case "categories": categories()
            case "scan": try scan(rest, flags: flags)
            case "clean": return try clean(rest, flags: flags)
            case "show": try show(rest)
            default: throw UsageError(message: "Unknown command “\(command)”.")
            }
            return 0
        } catch let error as UsageError {
            printError("\(error.message)\nRun “spacebar help” for usage.")
            return 2
        } catch {
            printError(error.localizedDescription)
            return 1
        }
    }

    // MARK: Commands

    private static func status() {
        guard let space = VolumeSpace.home() else {
            printError("Couldn't read the startup disk's size.")
            return
        }
        let percent = space.total > 0 ? Int((Double(space.available) / Double(space.total) * 100).rounded()) : 0
        print("\(ByteFormat.string(space.available)) available of \(ByteFormat.string(space.total)) (\(percent)% free)")
        if space.purgeable > 0 {
            print("Includes \(ByteFormat.string(space.purgeable)) macOS can free on its own when needed (purgeable).")
        }
    }

    private static func categories() {
        let rows = Headless.allCategories.map { category in
            [category.id, category.name, category.group == .cleanup ? "Cleanup" : category.group == .rules ? "Your Rules" : "Find Space",
             Headless.safeCategories.contains { $0.id == category.id } ? "yes" : ""]
        }
        printTable(["ID", "NAME", "GROUP", "IN --safe"], rows)
    }

    private static func scan(_ ids: [String], flags: Set<String>) throws {
        try checkFlags(flags, allowed: ["--json"])
        let settings = Headless.Settings.current()
        let categories = try resolve(ids, default: Headless.allCategories.filter { !$0.onDemand })
        let results = Headless.scan(categories, settings: settings, progress: progress)
        clearProgress()
        let plans = results.map { ($0, Headless.plan([$0], settings: settings)) }
        if flags.contains("--json") {
            printJSON(plans.map { result, plan in
                ["id": result.category.id, "name": result.category.name,
                 "bytes": result.items.reduce(0) { $0 + $1.size }, "items": result.items.count,
                 "suggestedBytes": plan.bytes, "suggestedItems": plan.pairs.count] as [String: Any]
            })
            return
        }
        printTable(["CATEGORY", "FOUND", "ITEMS", "SUGGESTED"], plans.map { result, plan in
            [result.category.name, ByteFormat.string(result.items.reduce(0) { $0 + $1.size }),
             String(result.items.count), plan.pairs.isEmpty ? "–" : ByteFormat.string(plan.bytes)]
        }, rightAligned: [1, 2, 3])
        let total = plans.reduce(Int64(0)) { $0 + $1.1.bytes }
        print("\nSuggested to clean: \(ByteFormat.string(total))")
        noteMissingAccess()
    }

    private static func clean(_ ids: [String], flags: Set<String>) throws -> Int32 {
        try checkFlags(flags, allowed: ["--safe", "--dry-run", "--yes", "-y", "--json"])
        let safe = flags.contains("--safe")
        guard safe != !ids.isEmpty else {
            throw UsageError(message: safe ? "Use either --safe or category IDs, not both."
                                           : "Say what to clean: --safe, or one or more category IDs.")
        }
        let settings = Headless.Settings.current()
        let json = flags.contains("--json")
        var dryRun = flags.contains("--dry-run")
        if settings.dryRun && !dryRun {
            printError("Dry Run is on in Spacebar's settings, so nothing will be removed.")
            dryRun = true
        }
        let categories = safe ? Headless.safeCategories : try resolve(ids, default: [])
        let results = Headless.scan(categories, settings: settings, progress: progress)
        clearProgress()
        let plan = Headless.plan(results, settings: settings)
        guard !plan.pairs.isEmpty else {
            if json { printJSON(["dryRun": dryRun, "freedBytes": 0, "trashedBytes": 0, "planned": [], "removed": [], "skipped": []] as [String: Any]) }
            else { print("Nothing to clean: Spacebar has no suggestions in \(safe ? "caches and logs" : "these categories").") }
            return 0
        }

        if !json {
            print("\(dryRun ? "Would remove" : "Removing") \(plan.pairs.count) items, \(ByteFormat.string(plan.bytes)):")
            let shown = plan.pairs.sorted { $0.item.size > $1.item.size }.prefix(15)
            printTable(["", "", ""], shown.map { ["  " + $0.category.name, display($0.item), ByteFormat.string($0.item.size)] },
                       rightAligned: [2], header: false)
            if plan.pairs.count > shown.count { print("  … and \(plan.pairs.count - shown.count) more") }
        }
        if !dryRun && !flags.contains("--yes") && !flags.contains("-y") {
            guard isatty(STDIN_FILENO) == 1 else {
                printError("Not cleaning without confirmation. Add --yes to clean from a script.")
                return 2
            }
            FileHandle.standardError.write(Data("Continue? [y/N] ".utf8))
            guard let answer = readLine()?.lowercased(), ["y", "yes"].contains(answer) else {
                print("Cancelled. Nothing was removed.")
                return 0
            }
        }

        let report = Headless.clean(plan, dryRun: dryRun, source: .commandLine)
        if json {
            printJSON(["dryRun": report.dryRun, "freedBytes": report.deletedBytes, "trashedBytes": report.trashedBytes,
                       "planned": plan.pairs.map { ["category": $0.category.id, "name": $0.item.name,
                                                    "path": $0.item.url.isFileURL ? $0.item.url.path : $0.item.url.absoluteString,
                                                    "bytes": $0.item.size] as [String: Any] },
                       "removed": report.removedItems.map { ["path": $0.path, "bytes": $0.bytes, "trashed": $0.trashed] },
                       "skipped": report.skipped.map { ["name": $0.name, "reason": $0.reason] }] as [String: Any])
            return report.skipped.isEmpty ? 0 : 1
        }
        if report.dryRun {
            var parts: [String] = []
            if report.deletedBytes > 0 { parts.append("free \(ByteFormat.string(report.deletedBytes))") }
            if report.trashedBytes > 0 { parts.append("move \(ByteFormat.string(report.trashedBytes)) to the Trash") }
            print("\nDry run: nothing was removed. Spacebar would \(parts.isEmpty ? "remove nothing" : parts.joined(separator: " and ")).")
        } else {
            var line = "\nFreed \(ByteFormat.string(report.deletedBytes))."
            if report.trashedBytes > 0 {
                line += " Moved \(ByteFormat.string(report.trashedBytes)) to the Trash (put it back from Finder or with Undo in Spacebar)."
            }
            print(line)
        }
        if !report.skipped.isEmpty {
            print("Skipped \(report.skipped.count):")
            for skipped in report.skipped.prefix(10) { print("  \(skipped.name): \(skipped.reason)") }
        }
        return report.skipped.isEmpty ? 0 : 1
    }

    private static func show(_ paths: [String]) throws {
        guard paths.count == 1 else { throw UsageError(message: "Give one folder to show.") }
        let folder = URL(fileURLWithPath: paths[0], relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath))
            .standardizedFileURL
        guard let link = FinderIntegration.showURL(for: folder), FinderIntegration.folder(from: link) != nil else {
            throw UsageError(message: "No such folder: \(paths[0])")
        }
        let configuration = NSWorkspace.OpenConfiguration()
        if let app = appBundle {
            NSWorkspace.shared.open([link], withApplicationAt: app, configuration: configuration)
        } else {
            NSWorkspace.shared.open(link)
        }
        Thread.sleep(forTimeInterval: 1) // let Launch Services hand it over before exiting
    }

    // MARK: Helpers

    /// The Spacebar.app this binary is in (through Homebrew's symlink), if any.
    private static var appBundle: URL? {
        var size = UInt32(PATH_MAX)
        var buffer = [CChar](repeating: 0, count: Int(size))
        guard _NSGetExecutablePath(&buffer, &size) == 0 else { return nil }
        let executable = URL(fileURLWithPath: String(cString: buffer)).resolvingSymlinksInPath()
        let app = executable.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        return app.pathExtension == "app" ? app : nil
    }

    private static var version: String {
        let bundle = appBundle.flatMap(Bundle.init(url:))
        return "Spacebar " + ((bundle?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String) ?? "(development build)")
    }

    private static func resolve(_ ids: [String], default all: [CleanCategory]) throws -> [CleanCategory] {
        guard !ids.isEmpty else { return all }
        return try ids.map { id in
            guard let category = Headless.allCategories.first(where: { $0.id.lowercased() == id.lowercased() }) else {
                throw UsageError(message: "No category “\(id)”. See “spacebar categories”.")
            }
            return category
        }
    }

    private static func checkFlags(_ flags: Set<String>, allowed: Set<String>) throws {
        if let unknown = flags.subtracting(allowed).sorted().first { throw UsageError(message: "Unknown option \(unknown).") }
    }

    private static func display(_ item: CleanItem) -> String {
        guard item.url.isFileURL else { return item.name }
        let home = NSHomeDirectory()
        let path = item.url.path
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }

    private static let showsProgress = isatty(STDERR_FILENO) == 1

    private static func progress(_ category: CleanCategory) {
        guard showsProgress else { return }
        FileHandle.standardError.write(Data("\r\u{1B}[KScanning \(category.name)…".utf8))
    }

    private static func clearProgress() {
        guard showsProgress else { return }
        FileHandle.standardError.write(Data("\r\u{1B}[K".utf8))
    }

    private static func noteMissingAccess() {
        if FullDiskAccess.isGranted() == false {
            print("Note: this terminal doesn't have Full Disk Access, so some places (like Mail) weren't scanned.")
        }
    }

    private static func printTable(_ headers: [String], _ rows: [[String]], rightAligned: Set<Int> = [], header: Bool = true) {
        let all = header ? [headers] + rows : rows
        let widths = headers.indices.map { column in all.map { $0[column].count }.max() ?? 0 }
        for row in all {
            let cells = row.enumerated().map { column, text in
                let pad = String(repeating: " ", count: widths[column] - text.count)
                return rightAligned.contains(column) ? pad + text : text + pad
            }
            var line = cells.joined(separator: "  ")
            while line.hasSuffix(" ") { line.removeLast() }
            print(line)
        }
    }

    private static func printJSON(_ value: Any) {
        guard let data = try? JSONSerialization.data(withJSONObject: value, options: [.prettyPrinted, .sortedKeys]) else { return }
        print(String(decoding: data, as: UTF8.self))
    }

    private static func printError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
