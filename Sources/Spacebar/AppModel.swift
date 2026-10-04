import AppKit
import Combine
import SpacebarCore
import SwiftUI
import UserNotifications

@MainActor
final class AppModel: ObservableObject {
    /// Spacebar's categories, then the user's rules.
    @Published private(set) var categories = Headless.allCategories
    /// The rule editor sheet: a rule being created (new) or edited.
    struct RuleEditing: Identifiable { let rule: CleanupRule; let isNew: Bool; var id: UUID { rule.id } }
    @Published var editingRule: RuleEditing?

    func newRule() {
        editingRule = RuleEditing(rule: CleanupRule(name: "", folder: "~/Downloads", patterns: [], olderThanDays: 30), isNew: true)
    }

    func editRule(categoryID: String) {
        if let rule = rules.first(where: { $0.categoryID == categoryID }) { editingRule = RuleEditing(rule: rule, isNew: false) }
    }

    /// The user's cleanup rules (saved with the app's settings, which the `spacebar` command reads too).
    @Published var rules: [CleanupRule] = CleanupRules.load(from: AppDefaults.shared) {
        didSet {
            guard rules != oldValue else { return }
            CleanupRules.save(rules, to: AppDefaults.shared)
            categories = CleanCategory.all + rules.map(CleanCategory.rule)
            let kept = Set(rules.map(\.categoryID))
            for removed in oldValue where !kept.contains(removed.categoryID) {
                results[removed.categoryID] = nil
            }
            // New or edited rules are scanned right away.
            for rule in rules where !oldValue.contains(rule) {
                if let category = category(rule.categoryID) { scan(category) }
            }
        }
    }
    private let engine = BulkScanner()

    @Published private(set) var results: [String: [CleanItem]] = [:]
    @Published private(set) var scanning: Set<String> = []
    @Published var selection: Set<URL> = []
    @Published private(set) var space: VolumeSpace? = .home() {
        didSet { if let space { recordSpace(space) } }
    }
    /// Available space over time, and what it says about when the disk fills up.
    private(set) var spaceLog: SpaceForecast = ScanCache.loadSpaceLog()
    @Published private(set) var forecast: SpaceForecast.Result?

    /// Debug hook: 30 days of made-up samples in memory (never saved), to look at the timeline.
    func debugDemoTimeline() {
        guard DebugSnapshot.enabled, let space else { return }
        var log = SpaceForecast()
        let now = Date()
        for hour in stride(from: 30 * 24, through: 0, by: -1) {
            var available = space.available + Int64(hour) * 25_000_000
            if hour < 12 * 24 { available -= 18_000_000_000 }   // an 18 GB download 12 days ago
            if hour < 4 * 24 { available += 9_000_000_000 }     // a 9 GB clean 4 days ago
            log.samples.append(.init(date: now.addingTimeInterval(-Double(hour) * 3600), available: available))
        }
        spaceLog = log
        cleaningHistory.insert(CleaningRecord(date: now.addingTimeInterval(-4 * 86400), source: .app,
                                              freedBytes: 9_000_000_000, trashedBytes: 0, photos: 0, items: []), at: 0)
        objectWillChange.send()
    }

    private func recordSpace(_ space: VolumeSpace) {
        let count = spaceLog.samples.count
        spaceLog.record(available: space.available)
        guard spaceLog.samples.count != count else { return }
        ScanCache.save(spaceLog)
        forecast = spaceLog.forecast()
    }
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
            await ResourceBudget.heavy {
                _ = DriveBreakdown.analyze(drive, engine: BulkScanner(), cancel: token) { partial in
                    Task { @MainActor in
                        if !token.isCancelled && self.selectedDrive?.url == drive.url { self.driveBreakdown = partial }
                    }
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
                    report.skipped.append((drive.name, String(localized: "Couldn't eject: \(error.localizedDescription)")))
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
        forecast = spaceLog.forecast()
        dryRun = UserDefaults.standard.bool(forKey: "dryRun")
        let savedStaleDays = UserDefaults.standard.integer(forKey: "staleDays")
        staleDays = savedStaleDays > 0 ? savedStaleDays : Suggestion.defaultStaleDays
        restoreCachedResults()
        NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                self?.refreshSystem()
                self?.applyStorageChanges() // changes queued while in the background
            }
            .store(in: &observers)
        // The history file is shared with the `spacebar` command, so also re-read it on activation.
        NotificationCenter.default.publisher(for: CleaningHistory.changed)
            .merge(with: NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.reloadCleaningHistory() }
            .store(in: &observers)
        // A Shortcuts clean ran in this process: show fresh results.
        NotificationCenter.default.publisher(for: Headless.cleanedNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refreshSystem()
                self?.scanAll()
            }
            .store(in: &observers)
        startLiveUpdates()
        for name in [NSWorkspace.didMountNotification, NSWorkspace.didUnmountNotification, NSWorkspace.didRenameVolumeNotification] {
            NSWorkspace.shared.notificationCenter.publisher(for: name)
                .sink { [weak self] _ in self?.refreshDrives() }
                .store(in: &observers)
        }
        // Weekly clean and "empty after 7 days", if turned on.
        Timer.publish(every: 3600, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in self?.runAutomaticTasks() }
            .store(in: &observers)
        DispatchQueue.main.asyncAfter(deadline: .now() + 120) { [weak self] in self?.runAutomaticTasks() }
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
        // A restarted copy starts with a clean environment.
        process.environment = Tools.cleanEnvironment
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

    /// `fullStorage: false` (at launch): when the saved breakdown can be caught up from the changes
    /// made since (see `startLiveUpdates`), skip measuring the whole disk again.
    func scanAll(fullStorage: Bool = true) {
        refreshSystem()
        if fullStorage || !catchingUpStorage { refreshStorage() }
        // On-demand scans read Desktop/Documents/Downloads; with Full Disk Access that shows no prompts.
        let includeOnDemand = fullDiskAccess == true
        let wanted = categories.filter { !$0.onDemand || includeOnDemand || results[$0.id] != nil }
        // Changes made after this point are replayed next launch.
        catalogEventID = FileWatcher.currentEventID
        if !fullStorage, let since = cachedCatalogEventID, let full = lastFullCatalogScan,
           Date().timeIntervalSince(full) < Self.fullMeasurementInterval {
            rescanChanged(wanted, since: since)
        } else {
            catalogScanIsFull = true
            wanted.forEach(scan)
        }
    }

    /// Replays what changed since the last scan and scans only the categories it affects. The others
    /// keep their saved results (already re-checked by restoreCachedResults).
    private func rescanChanged(_ wanted: [CleanCategory], since: UInt64) {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        var changed: Set<String> = []
        var everything = false
        var decided = false
        func decide() {
            guard !decided else { return }
            decided = true
            catalogWatcher?.stop()
            catalogWatcher = nil
            let rescan = wanted.filter { everything || results[$0.id] == nil || $0.isAffected(by: Array(changed), home: home) }
            storageTrace("categories: \(changed.count) changed folders, rescanning \(rescan.count) of \(wanted.count): \(rescan.map(\.id).joined(separator: ", "))")
            if rescan.isEmpty {
                lastScan = Date()
                showingCachedResults = false
                saveResults()
            } else {
                rescan.forEach(scan)
            }
        }
        catalogWatcher = FileWatcher(paths: [home, "/Applications"], latency: 0.5, since: since) { paths, rescanAll in
            Task { @MainActor in
                changed.formUnion(paths)
                everything = everything || rescanAll
            }
        } progress: { _, historyDone in
            if historyDone { Task { @MainActor in decide() } }
        }
        catalogWatcher?.start()
        // If the replay never finishes, scan everything.
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) {
            everything = true
            decide()
        }
    }

    private var catalogWatcher: FileWatcher?
    private var catalogEventID: UInt64?
    private var catalogScanIsFull = false
    private var cachedCatalogEventID: UInt64?
    private var lastFullCatalogScan: Date?

    /// What the last clean moved to the Trash: can still be put back or deleted for good.
    @Published private(set) var lastTrashed: [Cleaner.TrashedItem] = []
    /// Every clean, newest first (see CleaningHistory).
    @Published private(set) var cleaningHistory: [CleaningRecord] = CleaningHistory.load()

    func reloadCleaningHistory() { cleaningHistory = CleaningHistory.load() }
    var lastTrashedBytes: Int64 { lastTrashed.reduce(0) { $0 + $1.bytes } }

    /// Permanently deletes what the last clean moved to the Trash, and nothing else in the Trash.
    func deleteTrashed(_ report: Cleaner.Report? = nil) {
        let items = (report?.trashedItems ?? lastTrashed).map { (url: $0.url, bytes: $0.bytes) }
        guard !items.isEmpty else { return }
        lastTrashed = []
        runTrashDeletion { Cleaner.deleteFromTrash(items, dryRun: $0) }
    }

    /// The app being uninstalled (shows the uninstall sheet).
    @Published var uninstalling: AppFootprint.App?

    /// Opens the uninstall sheet for the app at `url`.
    // MARK: Storage by app

    /// Each app with everything it keeps, largest first (measured when the page opens).
    /// Shown right away from the last measurement, then refreshed.
    @Published private(set) var appUsage: [AppUsage] = ScanCache.loadApps()?.apps ?? []
    @Published private(set) var measuringApps = false
    @Published private(set) var appUsageMeasuredAt: Date? = ScanCache.loadApps()?.date
    /// Measured in this session (the cached list is refreshed once on first open).
    private var appUsageFresh = false

    func measureApps(force: Bool = false) {
        guard !measuringApps else { return }
        if !force, appUsageFresh, let at = appUsageMeasuredAt, Date().timeIntervalSince(at) < 600 { return }
        measuringApps = true
        // App bundles the Unused Apps scan already measured.
        let known = Dictionary(items("apps").map { ($0.url, $0.size) }, uniquingKeysWith: max)
        // Someone opened the page and is waiting: not queued behind background scans (it still
        // shares their pool of scanner threads, so the Mac stays responsive).
        let started = Date()
        Task.detached(priority: .userInitiated) {
            let result = AppUsageAnalyzer.measure(engine: BulkScanner(), knownSizes: known) { partial in
                Task { @MainActor in self.appUsage = partial }
            }
            await MainActor.run {
                self.appUsage = result
                self.appUsageMeasuredAt = Date()
                self.appUsageFresh = true
                self.storageTrace("apps: measured \(result.count) in \(String(format: "%.1f", Date().timeIntervalSince(started))) s, \(known.count) bundle sizes reused")
                self.measuringApps = false
                ScanCache.save(ScanCache.Apps(date: Date(), apps: result))
            }
        }
    }

    /// Deletes an app's caches (it rebuilds them). Skipped while the app is running.
    func clearCache(_ usage: AppUsage) {
        guard !cleaning, !usage.caches.isEmpty else { return }
        cleaning = true
        let requests = usage.caches.map { piece in
            Cleaner.Request(item: CleanItem(url: piece.url, name: "\(usage.name): \(piece.label)", size: piece.bytes,
                                            date: nil, detail: nil, owner: usage.bundleID), mode: .permanent)
        }
        let dryRun = dryRun
        Task.detached(priority: .userInitiated) {
            let report = Cleaner.run(requests, dryRun: dryRun, history: .app)
            await MainActor.run {
                self.cleaning = false
                self.applyRemovals(report)
                self.report = report
                self.measureApps(force: true)
            }
        }
    }

    func uninstall(_ url: URL) {
        guard url.pathExtension == "app", let app = AppFootprint.app(at: url) else { return }
        uninstalling = app
    }

    /// Lets the user pick an app to uninstall.
    func chooseAppToUninstall() {
        let panel = NSOpenPanel()
        panel.directoryURL = URL(fileURLWithPath: "/Applications")
        panel.allowedContentTypes = [.application]
        panel.prompt = String(localized: "Uninstall…")
        if panel.runModal() == .OK, let url = panel.url { uninstall(url) }
    }

    func runUninstall(_ requests: [Cleaner.Request]) {
        guard !cleaning, !requests.isEmpty else { return }
        cleaning = true
        let dryRun = dryRun
        Task.detached(priority: .userInitiated) {
            let report = Cleaner.run(requests, dryRun: dryRun, history: .uninstall)
            await MainActor.run {
                self.cleaning = false
                self.applyRemovals(report)
                if !report.trashedItems.isEmpty { self.lastTrashed = report.trashedItems }
                let removed = Set(report.removed)
                for id in self.results.keys { self.results[id]?.removeAll { removed.contains($0.url) } }
                self.report = report
            }
        }
    }

    /// Space Explorer removals can be put back too.
    func rememberTrashed(_ items: [Cleaner.TrashedItem]) { lastTrashed = items }

    /// Undo: moves what the last clean trashed back to where it was.
    func putBackLastClean() { putBack(lastTrashed) }

    /// Moves `items` out of the Trash to where they were (from the last clean or the cleaning history).
    func putBack(_ items: [Cleaner.TrashedItem]) {
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
                report.skipped.append((String(localized: "Trash"), error))
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
        warnBeforeFull()
        let threshold = Int64(defaults.integer(forKey: Preferences.lowDiskThresholdGB)) * 1_000_000_000
        guard space.available < threshold else { return }
        if let last = defaults.object(forKey: Preferences.lastLowDiskAlert) as? Date,
           Date().timeIntervalSince(last) < 24 * 3600 { return }
        defaults.set(Date(), forKey: Preferences.lastLowDiskAlert)

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = String(localized: "Your disk is almost full")
            content.body = String(localized: "\(ByteFormat.string(space.available)) left. Open Spacebar to see what's using space.")
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "low-disk", content: content, trigger: nil))
        }
    }

    /// "Your disk will be full in about 10 days", at most weekly, when it's two weeks away or less.
    private func warnBeforeFull() {
        let defaults = UserDefaults.standard
        guard let forecast, forecast.days < 14 else { return }
        if let last = defaults.object(forKey: "lastForecastAlert") as? Date, Date().timeIntervalSince(last) < 7 * 86400 { return }
        defaults.set(Date(), forKey: "lastForecastAlert")
        let rate = ByteFormat.string(Int64(forecast.bytesPerDay))
        var body = String(localized: "It's filling up by about \(rate) a day.")
        if let top = history.growth()?.items.first {
            let home = NSHomeDirectory()
            let path = top.path.hasPrefix(home) ? "~" + top.path.dropFirst(home.count) : top.path
            body += " " + String(localized: "Biggest growth: \(path) (+\(ByteFormat.string(top.delta))).")
        }
        notify(title: Self.forecastTitle(days: forecast.days), body: body)
    }

    static func forecastTitle(days: Double) -> String {
        let days = Int(days.rounded())
        return days <= 1 ? String(localized: "Your disk will be full in about a day")
            : String(localized: "Your disk will be full in about \(days) days")
    }

    /// "in about 5 weeks", for the Overview.
    static func forecastPhrase(days: Double) -> String {
        switch days {
        case ..<1.5: return String(localized: "in about a day")
        case ..<14: return String(localized: "in about \(Int(days.rounded())) days")
        case ..<60: return String(localized: "in about \(Int((days / 7).rounded())) weeks")
        default: return String(localized: "in about \(Int((days / 30).rounded())) months")
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

    // MARK: Automatic cleaning

    /// Weekly safe clean and "empty after 7 days", if turned on in Settings. Checked hourly.
    func runAutomaticTasks() {
        let defaults = UserDefaults.standard
        if defaults.bool(forKey: Preferences.autoEmptyTrashed) { emptyOldTrashed() }
        // Forgotten files read Downloads and the Desktop: only with Full Disk Access, so no prompts.
        if defaults.bool(forKey: Preferences.forgottenReminders), fullDiskAccess == true, !isScanning {
            let context = ScanContext(engine: BulkScanner(), runningApps: RunningApps.bundleIDs(),
                                      fullDiskAccess: true, excluded: exclusions)
            Task.detached(priority: .utility) {
                if let item = await ResourceBudget.heavy({ ForgottenReminder.candidate(context: context) }) {
                    ForgottenReminder.ask(about: item)
                }
            }
        }
        guard defaults.bool(forKey: Preferences.autoClean), !cleaning, !isScanning else { return }
        if let last = defaults.object(forKey: Preferences.lastAutoClean) as? Date,
           Date().timeIntervalSince(last) < 7 * 86400 { return }
        defaults.set(Date(), forKey: Preferences.lastAutoClean)

        let categories = Headless.safeCategories + Headless.automaticRuleCategories
        let context = ScanContext(engine: BulkScanner(), runningApps: RunningApps.bundleIDs(),
                                  fullDiskAccess: fullDiskAccess ?? false, excluded: exclusions)
        let staleDays = staleDays
        let dryRun = dryRun
        Task.detached(priority: .utility) {
            var requests: [Cleaner.Request] = []
            for category in categories {
                for item in await ResourceBudget.heavy({ category.scan(context) }) where Suggestion.isSuggested(item, in: category, staleDays: staleDays) {
                    requests.append(Cleaner.Request(item: item, mode: category.mode))
                }
            }
            let report = Cleaner.run(requests, dryRun: dryRun, history: .automatic)
            await MainActor.run {
                self.applyRemovals(report)
                let freed = report.deletedBytes
                guard freed > 0 else { return }
                let size = ByteFormat.string(freed)
                self.notify(title: dryRun ? String(localized: "Automatic clean (dry run)") : String(localized: "Spacebar cleaned up"),
                            body: dryRun ? String(localized: "Would have freed \(size) of caches and logs nobody used recently.")
                                : String(localized: "Freed \(size) of caches and logs nobody used recently."))
                self.scanAll()
            }
        }
    }

    /// Permanently deletes items Spacebar moved to the Trash more than 7 days ago (only those).
    func emptyOldTrashed() {
        var ledger = ScanCache.loadLedger()
        let cutoff = Date().addingTimeInterval(-7 * 86400)
        let due = ledger.entries.filter { $0.date < cutoff }
        guard !due.isEmpty, !cleaning else { return }
        ledger.entries.removeAll { $0.date < cutoff }
        ScanCache.save(ledger)
        let items = due.map { (url: URL(fileURLWithPath: $0.path), bytes: $0.bytes) }
        let dryRun = dryRun
        Task.detached(priority: .utility) {
            // deleteFromTrash refuses anything that isn't inside a Trash.
            let report = Cleaner.deleteFromTrash(items, dryRun: dryRun)
            await MainActor.run {
                self.applyRemovals(report)
                if report.deletedBytes > 0 {
                    self.notify(title: String(localized: "Trash emptied"),
                                body: String(localized: "Deleted \(ByteFormat.string(report.deletedBytes)) that Spacebar moved to the Trash a week ago."))
                }
            }
        }
    }

    func notify(title: String, body: String) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil))
        }
    }

    /// Reflects removals right away: free space, and the disk breakdown (size moves to Trash or Free).
    func applyRemovals(_ report: Cleaner.Report) {
        if !report.dryRun { TrashLedger.record(report.trashedItems) }
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

    // MARK: Live updates of the breakdown

    private var storageWatcher: FileWatcher?
    private var storageChanges: Set<String> = []
    private var storageRescan = false
    private var storageChangeTask: Task<Void, Never>?
    /// When the breakdown last updated itself from file-system changes.
    @Published private(set) var liveUpdatedAt: Date?

    /// Watches the folders behind the breakdown. Changes are collected and applied every ~20 s
    /// while Spacebar is active (and when it becomes active again).
    /// A full measurement is redone at least this often, even when changes could be replayed.
    static let fullMeasurementInterval: TimeInterval = 7 * 86400

    /// Watches for changes. At launch it first replays what changed since the saved breakdown was
    /// measured (macOS keeps that history), so only those folders are measured again.
    func startLiveUpdates() {
        guard storageWatcher == nil else { return }
        var since: UInt64?
        if let storage, storage.complete, let eventID = storage.eventID,
           Date().timeIntervalSince(storage.measuredAt) < Self.fullMeasurementInterval {
            since = eventID
            catchingUpStorage = true
        }
        storageWatcher = FileWatcher(paths: StorageAnalyzer.watchedFolders, latency: 5, since: since) { [weak self] changed, rescan in
            Task { @MainActor in self?.noteStorageChanges(changed, rescan: rescan) }
        } progress: { [weak self] lastEventID, historyDone in
            Task { @MainActor in
                guard let self else { return }
                self.lastStorageEventID = lastEventID
                if historyDone && self.catchingUpStorage {
                    self.catchingUpStorage = false
                    self.storageTrace("storage: caught up from history, \(self.storageChanges.count) changed paths, rescan=\(self.storageRescan)")
                    self.applyStorageChanges() // right away, not after the usual pause
                }
            }
        }
        storageWatcher?.start()
        if catchingUpStorage {
            // If the replay never finishes, measure everything instead.
            DispatchQueue.main.asyncAfter(deadline: .now() + 60) { [weak self] in
                guard let self, self.catchingUpStorage else { return }
                self.catchingUpStorage = false
                self.refreshStorage()
            }
        }
    }

    private func storageTrace(_ message: String) {
        guard DebugSnapshot.enabled else { return }
        FileHandle.standardError.write(Data("[\(Date())] \(message)\n".utf8))
    }

    /// Replaying changes made while Spacebar wasn't running.
    private var catchingUpStorage = false
    /// The newest change the watcher delivered (saved with the breakdown once applied).
    private var lastStorageEventID: UInt64?

    private func noteStorageChanges(_ changed: [String], rescan: Bool) {
        storageChanges.formUnion(changed.map(StorageAnalyzer.displayPath))
        storageRescan = storageRescan || rescan
        guard NSApp.isActive, storageChangeTask == nil, !catchingUpStorage else { return }
        storageChangeTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 20_000_000_000)
            self.storageChangeTask = nil
            self.applyStorageChanges()
        }
    }

    /// Re-measures only the folders that changed and updates their slices in place.
    func applyStorageChanges() {
        guard !storageRunning, let storage, storage.complete,
              !storageChanges.isEmpty || storageRescan else { return }
        if storageRescan {
            storageRescan = false
            storageChanges = []
            refreshStorage()
            return
        }
        let roots = storage.folderSizes.map { Array($0.keys) } ?? []
        let affected = Set(storageChanges.compactMap { FileWatcher.owningRoot(of: $0, in: roots) })
        storageChanges = []
        // Every change up to here is in `affected`, so the saved breakdown can resume after it.
        let eventID = lastStorageEventID
        guard !affected.isEmpty else {
            if let eventID, var current = self.storage { current.eventID = eventID; self.storage = current; ScanCache.save(current) }
            return
        }
        let paths = Array(affected)
        let started = Date()
        Task.detached(priority: .utility) {
            let sizes = BulkScanner().measure(paths.map { URL(fileURLWithPath: StorageAnalyzer.measurablePath($0)) }, cancel: nil)
            let free = VolumeSpace.home()?.free
            await MainActor.run {
                guard var current = self.storage, !self.storageRunning else { return }
                current.update(folders: Dictionary(uniqueKeysWithValues: zip(paths, sizes.map(\.allocated))), free: free)
                if let eventID { current.eventID = eventID }
                self.storageTrace("storage: re-measured \(paths.count) changed folders in \(String(format: "%.1f", Date().timeIntervalSince(started))) s")
                self.storage = current
                self.space = .home()
                self.liveUpdatedAt = Date()
                ScanCache.save(current)
            }
        }
    }

    func refreshStorage() {
        guard !storageRunning else { return }
        storageTrace("storage: full measurement")
        storageRunning = true
        let hadComplete = storage?.complete == true
        let activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "Measuring disk usage")
        Task.detached(priority: .utility) {
            // Waits for a free slot like category scans do (see ResourceBudget).
            let result = await ResourceBudget.heavy { StorageAnalyzer.analyze(engine: BulkScanner()) { partial in
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
            } }
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
            // At most two categories scan at once, so a full scan leaves room for everything else.
            let items = await ResourceBudget.heavy { category.scan(context) }
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
                // The cache file could have been edited: only items the rules allow come back.
                guard PathRules.isDeletable(item.url, kind: item.kind) else { return nil }
                var item = item
                item.inUse = item.owner.map(running.contains) ?? false
                return item
            }
        }
        for category in categories { selectSuggested(category) }
        lastScan = cache.date
        cachedCatalogEventID = cache.eventID
        lastFullCatalogScan = cache.fullScan
        showingCachedResults = true
    }

    private func saveResults() {
        guard let lastScan else { return }
        if catalogScanIsFull { lastFullCatalogScan = lastScan }
        catalogScanIsFull = false
        ScanCache.save(ScanCache.Catalog(date: lastScan, results: results, eventID: catalogEventID,
                                         fullScan: lastFullCatalogScan))
    }

    /// For duplicates and similar photos: keep `item` and offer the copy that was going to be kept instead.
    func keepInstead(_ item: CleanItem) {
        guard let keeper = item.duplicateOf,
              let categoryID = results.first(where: { $0.value.contains { $0.url == item.url } })?.key,
              var items = results[categoryID] else { return }
        let home = NSHomeDirectory()
        func short(_ url: URL) -> String { url.path.replacingOccurrences(of: home, with: "~") }
        items.removeAll { $0.url == item.url }
        for index in items.indices where items[index].duplicateOf == keeper {
            items[index].duplicateOf = item.url
            items[index].detail = String(localized: "In \(short(items[index].url.deletingLastPathComponent())) · same as \(short(item.url))")
        }
        let photo = PhotosLibrary.identifier(from: keeper)
        var previous = CleanItem(url: keeper, name: photo.flatMap(PhotosLibrary.displayName) ?? keeper.lastPathComponent,
                                 size: item.size, date: nil,
                                 detail: photo != nil ? String(localized: "Similar to \(item.name)")
                                     : String(localized: "In \(short(keeper.deletingLastPathComponent())) · same as \(short(item.url))"),
                                 owner: nil)
        previous.duplicateOf = item.url
        if let photo { previous.kind = .photoAsset(identifier: photo) }
        items.append(previous)
        selection.remove(item.url)
        results[categoryID] = items.sorted { $0.size > $1.size }
        saveResults()
    }

    func setSelected(_ selected: Bool, items: [CleanItem]) {
        let urls = items.filter(\.isSelectable).map(\.url)
        if selected { selection.formUnion(urls) } else { selection.subtract(urls) }
    }

    func clean(_ pairs: [(CleanItem, CleanCategory)]) {
        // Results restored from the cache file are only shown, never acted on: the file lives in
        // ~/Library/Caches, where another program could have edited it.
        guard !showingCachedResults else {
            var report = Cleaner.Report(dryRun: dryRun)
            report.skipped.append((String(localized: "Cleanup"),
                                    String(localized: "Spacebar is still checking the results from last time. Try again in a moment.")))
            self.report = report
            return
        }
        let pairs = Self.withoutOverlaps(pairs)
        debugLog("clean() called: \(pairs.count) items, dryRun=\(dryRun)")
        guard !cleaning, !pairs.isEmpty else { return }
        cleaning = true
        let requests = pairs.map { Cleaner.Request(item: $0.0, mode: $0.1.mode) }
        let dryRun = dryRun
        Task.detached(priority: .userInitiated) {
            let report = Cleaner.run(requests, dryRun: dryRun, history: .app)
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
