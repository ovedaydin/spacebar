import AppKit
import Combine
import SpacebarCore
import SwiftUI
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    let categories = CleanCategory.all
    private let engine = BulkScanner()

    @Published private(set) var results: [String: [CleanItem]] = [:]
    @Published private(set) var scanning: Set<String> = []
    @Published var selection: Set<URL> = []
    @Published private(set) var space: VolumeSpace? = .home()
    @Published private(set) var snapshots: [String] = []
    @Published private(set) var fullDiskAccess: Bool? = FullDiskAccess.isGranted()
    @Published private(set) var cleaning = false
    @Published var report: Cleaner.Report?
    /// When the cleanup results shown were last measured (possibly in a previous launch).
    @Published private(set) var lastScan: Date?
    /// True when the results shown come from the cache of a previous launch.
    @Published private(set) var showingCachedResults = false
    /// What the startup disk is used for. Kept from the last complete measurement while a new one runs.
    @Published private(set) var storage: StorageBreakdown? = ScanCache.loadStorage()
    @Published private(set) var measuringStorage: StorageSegment.Kind?
    /// Folder sizes from past measurements, for "What grew".
    @Published private(set) var history: StorageHistory = ScanCache.loadHistory() ?? StorageHistory()
    private var storageRunning = false
    /// When on, cleaning only simulates and logs what it would remove.
    @Published var dryRun: Bool {
        didSet { UserDefaults.standard.set(dryRun, forKey: "dryRun") }
    }

    /// Age-based categories only suggest items not modified for this many days.
    @Published var staleDays: Int {
        didSet {
            UserDefaults.standard.set(staleDays, forKey: "staleDays")
            for category in categories where category.ageBased { selectSuggested(category) }
        }
    }

    // MARK: Drives

    @Published private(set) var drives: [Drive] = Drive.mounted()
    /// nil = the startup disk.
    @Published private(set) var selectedDrive: Drive?
    @Published private(set) var driveBreakdown: DriveBreakdown?
    private var driveToken: CancelToken?

    func refreshDrives() {
        drives = Drive.mounted()
        if let selected = selectedDrive, !drives.contains(where: { $0.url == selected.url }) { selectDrive(nil) }
    }

    func selectDrive(_ drive: Drive?) {
        driveToken?.cancel()
        selectedDrive = drive?.isStartup == true ? nil : drive
        driveBreakdown = nil
        guard let drive = selectedDrive else { return }
        let token = CancelToken()
        driveToken = token
        Task.detached(priority: .userInitiated) {
            _ = DriveBreakdown.analyze(drive, engine: BulkScanner(), cancel: token) { partial in
                Task { @MainActor in
                    if !token.isCancelled && self.selectedDrive?.url == drive.url { self.driveBreakdown = partial }
                }
            }
        }
    }

    func eject(_ drive: Drive) {
        selectDrive(nil)
        Task.detached {
            do {
                try NSWorkspace.shared.unmountAndEjectDevice(at: drive.url)
            } catch {
                await MainActor.run {
                    var report = Cleaner.Report(dryRun: false)
                    report.skipped.append((drive.name, "Couldn't eject: \(error.localizedDescription)"))
                    self.report = report
                }
            }
            await MainActor.run { self.refreshDrives() }
        }
    }

    /// "Never Show in Cleanup" paths.
    @Published private(set) var exclusions: [String] = UserDefaults.standard.stringArray(forKey: "exclusions") ?? []

    /// Hides `key` (and everything inside it) from every cleanup list, right away and in future scans.
    func exclude(_ key: String) {
        guard !exclusions.contains(key) else { return }
        exclusions.append(key)
        UserDefaults.standard.set(exclusions, forKey: "exclusions")
        for id in results.keys {
            let hidden = results[id]?.filter { Exclusions.matches($0.url, [key]) } ?? []
            selection.subtract(hidden.map(\.url))
            results[id]?.removeAll { Exclusions.matches($0.url, [key]) }
        }
        saveResults()
    }

    func removeExclusion(_ key: String) {
        exclusions.removeAll { $0 == key }
        UserDefaults.standard.set(exclusions, forKey: "exclusions")
        scanAll() // bring its items back
    }

    private var observers: [AnyCancellable] = []

    init() {
        dryRun = UserDefaults.standard.bool(forKey: "dryRun")
        let savedStaleDays = UserDefaults.standard.integer(forKey: "staleDays")
        staleDays = savedStaleDays > 0 ? savedStaleDays : Suggestion.defaultStaleDays
        restoreCachedResults()
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.refreshSystem() }
            .store(in: &observers)
        for name in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification, NSWorkspace.didRenameVolumeNotification] {
            NSWorkspace.shared.notificationCenter.publisher(for: name)
                .sink { [weak self] _ in self?.refreshDrives() }
                .store(in: &observers)
        }
        // Keep the menu bar figure current and watch for low disk space.
        Timer.publish(every: 60, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                self?.space = .home()
                self?.checkLowDisk()
            }
            .store(in: &observers)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) { [weak self] in self?.checkLowDisk() }
    }

    var hasScanned: Bool { !results.isEmpty }
    var isScanning: Bool { !scanning.isEmpty }

    /// Running from a DMG or quarantined Downloads folder (App Translocation) breaks permissions.
    var needsMoveToApplications: Bool {
        let path = Bundle.main.bundlePath
        return path.contains("/AppTranslocation/") || path.hasPrefix("/Volumes/")
    }

    func category(_ id: String) -> CleanCategory? { categories.first { $0.id == id } }
    func items(_ id: String) -> [CleanItem] { results[id] ?? [] }
    func total(_ id: String) -> Int64 { items(id).reduce(0) { $0 + $1.size } }
    func selectedItems(_ id: String) -> [CleanItem] { items(id).filter { selection.contains($0.url) } }
    func selectedSize(_ id: String) -> Int64 { selectedItems(id).reduce(0) { $0 + $1.size } }
    /// Everything selected, without duplicates or items inside another selected item
    /// (e.g. a file that is both an old download and a large file).
    var allSelected: [(CleanItem, CleanCategory)] {
        Self.withoutOverlaps(categories.flatMap { category in selectedItems(category.id).map { ($0, category) } })
    }

    nonisolated static func withoutOverlaps(_ pairs: [(CleanItem, CleanCategory)]) -> [(CleanItem, CleanCategory)] {
        let paths = Set(pairs.map { $0.0.url.path })
        var seen = Set<String>()
        return pairs.filter { pair in
            let path = pair.0.url.path
            var parent = (path as NSString).deletingLastPathComponent
            while parent.count > 1 {
                if paths.contains(parent) { return false }
                parent = (parent as NSString).deletingLastPathComponent
            }
            return seen.insert(path).inserted
        }
    }
    var totalSelectedSize: Int64 { allSelected.reduce(0) { $0 + $1.0.size } }

    /// Set after "Check Again" found no access: a grant made while Spacebar runs
    /// usually only takes effect after it restarts.
    @Published var accessCheckFailed = false
    private var accessPoll: Timer?

    /// After opening System Settings, re-check every few seconds for two minutes.
    func watchForFullDiskAccess() {
        accessPoll?.invalidate()
        var remaining = 40
        accessPoll = Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { [weak self] timer in
            Task { @MainActor in
                guard let self else { return timer.invalidate() }
                remaining -= 1
                if FullDiskAccess.isGranted() == true {
                    self.fullDiskAccess = true
                    timer.invalidate()
                    self.scanAll()
                } else if remaining <= 0 {
                    timer.invalidate()
                }
            }
        }
    }

    func checkFullDiskAccessAgain() {
        refreshSystem()
        accessCheckFailed = fullDiskAccess != true
        if fullDiskAccess == true { scanAll() }
    }

    /// Restarts Spacebar so macOS applies a Full Disk Access grant.
    func relaunch() {
        let path = Bundle.main.bundlePath
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "sleep 1; /usr/bin/open \"$0\"", path]
        // Never pass development variables on: a restarted copy must start clean.
        process.environment = ProcessInfo.processInfo.environment.filter { !$0.key.hasPrefix("SPACEBAR_") }
        try? process.run()
        NSApp.terminate(nil)
    }

    func refreshSystem() {
        space = .home()
        fullDiskAccess = FullDiskAccess.isGranted()
        Task.detached(priority: .utility) {
            let snapshots = LocalSnapshots.list()
            await MainActor.run { self.snapshots = snapshots }
        }
    }

    func scanAll() {
        refreshSystem()
        refreshStorage()
        // On-demand scans read Desktop/Documents/Downloads; with Full Disk Access that shows no prompts.
        let includeOnDemand = fullDiskAccess == true
        for category in categories where !category.onDemand || includeOnDemand || results[category.id] != nil {
            scan(category)
        }
    }

    /// What the last clean moved to the Trash: can still be put back or deleted for good.
    @Published private(set) var lastTrashed: [Cleaner.TrashedItem] = []
    var lastTrashedBytes: Int64 { lastTrashed.reduce(0) { $0 + $1.bytes } }

    /// Permanently deletes what the last clean moved to the Trash, and nothing else in the Trash.
    func deleteTrashed(_ report: Cleaner.Report? = nil) {
        let items = (report?.trashedItems ?? lastTrashed).map { (url: $0.url, bytes: $0.bytes) }
        guard !items.isEmpty else { return }
        lastTrashed = []
        runTrashDeletion { Cleaner.deleteFromTrash(items, dryRun: $0) }
    }

    /// Space Explorer removals can be put back too.
    func rememberTrashed(_ items: [Cleaner.TrashedItem]) { lastTrashed = items }

    /// Undo: moves what the last clean trashed back to where it was.
    func putBackLastClean() {
        let items = lastTrashed
        guard !items.isEmpty, !cleaning else { return }
        cleaning = true
        let dryRun = dryRun
        Task.detached(priority: .userInitiated) {
            let report = Cleaner.putBack(items, dryRun: dryRun)
            await MainActor.run {
                self.cleaning = false
                if !dryRun {
                    let restored = Set(report.restoredItems.map(\.url))
                    self.lastTrashed.removeAll { restored.contains($0.url) }
                    if var storage = self.storage {
                        for item in report.restoredItems { storage.recordRestore(path: item.original.path, bytes: item.bytes) }
                        self.storage = storage
                    }
                }
                self.report = report
                self.scanAll() // restored items show up again in their categories
            }
        }
    }

    /// Empties the whole Trash. With Full Disk Access Spacebar does it (and knows the size);
    /// without, it asks Finder.
    func emptyTrash() {
        if !dryRun { lastTrashed = [] }
        runTrashDeletion { dryRun in
            if let contents = Cleaner.trashContents() {
                return Cleaner.deleteFromTrash(contents, dryRun: dryRun)
            }
            var report = Cleaner.Report(dryRun: dryRun)
            report.emptiedTrash = true
            if !dryRun, let error = Cleaner.emptyTrashWithFinder() {
                report.skipped.append(("Trash", error))
            }
            return report
        }
    }

    private func runTrashDeletion(_ work: @escaping @Sendable (Bool) -> Cleaner.Report) {
        guard !cleaning else { return }
        cleaning = true
        let dryRun = dryRun
        Task.detached(priority: .userInitiated) {
            let report = work(dryRun)
            await MainActor.run {
                self.cleaning = false
                self.applyRemovals(report)
                if report.emptiedTrash && !report.dryRun && report.removedItems.isEmpty && report.skipped.isEmpty,
                   var storage = self.storage, let index = storage.segments.firstIndex(where: { $0.kind == .trash }) {
                    // Emptied by Finder: the whole Trash slice became free space.
                    storage.free += storage.segments[index].bytes
                    storage.segments[index].bytes = 0
                    self.storage = storage
                }
                self.report = report
            }
        }
    }

    /// Notifies once a day while available space is under the threshold from Settings.
    func checkLowDisk() {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: Preferences.lowDiskAlerts), let space else { return }
        let threshold = Int64(defaults.integer(forKey: Preferences.lowDiskThresholdGB)) * 1_000_000_000
        guard space.available < threshold else { return }
        if let last = defaults.object(forKey: Preferences.lastLowDiskAlert) as? Date,
           Date().timeIntervalSince(last) < 24 * 3600 { return }
        defaults.set(Date(), forKey: Preferences.lastLowDiskAlert)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Your disk is almost full"
            content.body = "\(ByteFormat.string(space.available)) left. Open Spacebar to see what's using space."
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "low-disk", content: content, trigger: nil))
        }
    }

    /// Spacebar's suggestions in the safe Cleanup categories: what "Clean" in the menu bar removes.
    var quickCleanItems: [(CleanItem, CleanCategory)] {
        Self.withoutOverlaps(categories.filter { $0.group == .cleanup && $0.safety == .safe }.flatMap { category in
            items(category.id).filter { isSuggested($0, in: category) }.map { ($0, category) }
        })
    }

    /// Bytes in the Trash, if known.
    var trashBytes: Int64? { storage?.segments.first { $0.kind == .trash }?.bytes }

    /// Reflects removals right away: free space, and the disk breakdown (size moves to Trash or Free).
    func applyRemovals(_ report: Cleaner.Report) {
        guard !report.removedItems.isEmpty else { return }
        if var storage {
            for item in report.removedItems {
                storage.recordRemoval(path: item.path, bytes: item.bytes, trashed: item.trashed)
            }
            storage.free = max(storage.free, VolumeSpace.home()?.free ?? storage.free)
            self.storage = storage
            if storage.complete { ScanCache.save(storage) }
        }
        refreshSystem()
    }

    func refreshStorage() {
        guard !storageRunning else { return }
        storageRunning = true
        let hadComplete = storage?.complete == true
        let activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "Measuring disk usage")
        Task.detached(priority: .utility) {
            let result = StorageAnalyzer.analyze(engine: BulkScanner()) { partial in
                Task { @MainActor in
                    self.measuringStorage = partial.measuring ?? (partial.complete ? nil : self.measuringStorage)
                    if !hadComplete || partial.complete {
                        self.storage = partial
                    } else if var current = self.storage {
                        // Update each slice as soon as it's measured again. macOS and System Data
                        // are only final at the end.
                        for segment in partial.segments where segment.kind != .macOS {
                            if let index = current.segments.firstIndex(where: { $0.kind == segment.kind }) {
                                current.segments[index] = segment
                            }
                        }
                        current.free = partial.free
                        self.storage = current
                    }
                }
            }
            ProcessInfo.processInfo.endActivity(activity)
            await MainActor.run {
                self.storageRunning = false
                self.measuringStorage = nil
                if let result {
                    ScanCache.save(result)
                    self.history.record(result.folderSizes ?? [:], at: result.measuredAt)
                    ScanCache.save(self.history)
                }
            }
        }
    }

    func scan(_ category: CleanCategory) {
        guard !scanning.contains(category.id) else { return }
        scanning.insert(category.id)
        // Keep scanning at full speed while Spacebar is in the background (App Nap).
        let activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "Scanning \(category.name)")
        let context = ScanContext(engine: engine, runningApps: RunningApps.bundleIDs(),
                                  fullDiskAccess: fullDiskAccess ?? false, excluded: exclusions)
        Task.detached(priority: .userInitiated) {
            let items = category.scan(context)
            ProcessInfo.processInfo.endActivity(activity)
            await MainActor.run {
                self.results[category.id] = items
                self.selectSuggested(category)
                self.scanning.remove(category.id)
                if self.scanning.isEmpty {
                    self.lastScan = Date()
                    self.showingCachedResults = false
                    self.saveResults()
                }
            }
        }
    }

    func isSuggested(_ item: CleanItem, in category: CleanCategory) -> Bool {
        Suggestion.isSuggested(item, in: category, staleDays: staleDays)
    }

    func suggestedItems(_ category: CleanCategory) -> [CleanItem] {
        items(category.id).filter { isSuggested($0, in: category) }
    }

    /// Resets the category's selection to what Spacebar suggests.
    func selectSuggested(_ category: CleanCategory) {
        let items = items(category.id)
        selection.subtract(items.map(\.url))
        selection.formUnion(items.filter { isSuggested($0, in: category) }.map(\.url))
    }

    /// Shows the previous launch's results right away. Items that no longer exist are dropped,
    /// and "in use" is re-checked against the apps running now.
    private func restoreCachedResults() {
        guard let cache = ScanCache.loadCatalog() else { return }
        let running = RunningApps.bundleIDs()
        let known = Set(categories.map(\.id))
        for (id, items) in cache.results where known.contains(id) {
            results[id] = items.compactMap { item in
                guard !Exclusions.matches(item.url, exclusions) else { return nil }
                guard !item.url.isFileURL || FileManager.default.fileExists(atPath: item.url.path) else { return nil }
                var item = item
                item.inUse = item.owner.map(running.contains) ?? false
                return item
            }
        }
        for category in categories { selectSuggested(category) }
        lastScan = cache.date
        showingCachedResults = true
    }

    private func saveResults() {
        guard let lastScan else { return }
        ScanCache.save(ScanCache.Catalog(date: lastScan, results: results))
    }

    /// For duplicates: keep `item` and offer the copy that was going to be kept instead.
    func keepInstead(_ item: CleanItem) {
        guard let keeper = item.duplicateOf, var items = results["duplicates"] else { return }
        let home = NSHomeDirectory()
        func short(_ url: URL) -> String { url.path.replacingOccurrences(of: home, with: "~") }
        items.removeAll { $0.url == item.url }
        for index in items.indices where items[index].duplicateOf == keeper {
            items[index].duplicateOf = item.url
            items[index].detail = "In \(short(items[index].url.deletingLastPathComponent())) · same as \(short(item.url))"
        }
        var previous = CleanItem(url: keeper, name: keeper.lastPathComponent, size: item.size, date: nil,
                                 detail: "In \(short(keeper.deletingLastPathComponent())) · same as \(short(item.url))", owner: nil)
        previous.duplicateOf = item.url
        items.append(previous)
        selection.remove(item.url)
        results["duplicates"] = items.sorted { $0.size > $1.size }
        saveResults()
    }

    func setSelected(_ selected: Bool, items: [CleanItem]) {
        let urls = items.filter(\.isSelectable).map(\.url)
        if selected { selection.formUnion(urls) } else { selection.subtract(urls) }
    }

    func clean(_ pairs: [(CleanItem, CleanCategory)]) {
        let pairs = Self.withoutOverlaps(pairs)
        debugLog("clean() called: \(pairs.count) items, dryRun=\(dryRun)")
        guard !cleaning, !pairs.isEmpty else { return }
        cleaning = true
        let requests = pairs.map { Cleaner.Request(item: $0.0, mode: $0.1.mode) }
        let dryRun = dryRun
        Task.detached(priority: .userInitiated) {
            let report = Cleaner.run(requests, dryRun: dryRun)
            await MainActor.run {
                let removed = Set(report.removed)
                for id in self.results.keys {
                    self.results[id]?.removeAll { removed.contains($0.url) }
                }
                self.selection.subtract(removed)
                self.saveResults()
                self.cleaning = false
                self.applyRemovals(report)
                if !report.trashedItems.isEmpty { self.lastTrashed = report.trashedItems }
                self.report = report
            }
        }
    }
}
