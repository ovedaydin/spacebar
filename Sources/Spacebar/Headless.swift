import Foundation
import SpacebarCore

/// Scanning and cleaning without the window, for the `spacebar` command and Shortcuts.
/// Follows the app's settings: Dry Run, Exclusions and how long items must go unused.
enum Headless {
    struct Settings {
        var dryRun: Bool
        var staleDays: Int
        var exclusions: [String]

        static func current() -> Settings {
            let defaults = AppDefaults.shared
            let stale = defaults.integer(forKey: "staleDays")
            return Settings(dryRun: defaults.bool(forKey: "dryRun"),
                            staleDays: stale > 0 ? stale : Suggestion.defaultStaleDays,
                            exclusions: defaults.stringArray(forKey: "exclusions") ?? [])
        }
    }

    struct Plan {
        var pairs: [(item: CleanItem, category: CleanCategory)]
        var bytes: Int64 { pairs.reduce(0) { $0 + $1.item.size } }
    }

    /// Spacebar's categories plus the user's rules.
    static var allCategories: [CleanCategory] {
        CleanCategory.all + CleanupRules.load(from: AppDefaults.shared).map(CleanCategory.rule)
    }

    /// Rules the user included in automatic cleaning.
    static var automaticRuleCategories: [CleanCategory] {
        CleanupRules.load(from: AppDefaults.shared).filter(\.automatic).map(CleanCategory.rule)
    }

    /// What a safe clean covers: caches and logs. Same as automatic cleaning (the Trash is left alone).
    static var safeCategories: [CleanCategory] {
        CleanCategory.all.filter { $0.group == .cleanup && $0.safety == .safe && $0.id != "trash" }
    }

    static func context(_ settings: Settings) -> ScanContext {
        ScanContext(engine: BulkScanner(), runningApps: RunningApps.bundleIDs(),
                    fullDiskAccess: FullDiskAccess.isGranted() ?? false, excluded: settings.exclusions)
    }

    /// Scans `categories` (fresh, never from the cache) and returns every item found.
    static func scan(_ categories: [CleanCategory], settings: Settings,
                     progress: (CleanCategory) -> Void = { _ in }) -> [(category: CleanCategory, items: [CleanItem])] {
        let context = context(settings)
        return categories.map { category in
            progress(category)
            return (category, category.scan(context))
        }
    }

    /// Spacebar's suggestions in the scanned categories: what the app would preselect.
    static func plan(_ results: [(category: CleanCategory, items: [CleanItem])], settings: Settings) -> Plan {
        let pairs = results.flatMap { result in
            result.items.filter { $0.isSelectable && Suggestion.isSuggested($0, in: result.category, staleDays: settings.staleDays) }
                .map { ($0, result.category) }
        }
        return Plan(pairs: AppModel.withoutOverlaps(pairs).map { (item: $0.0, category: $0.1) })
    }

    /// Cleans `plan`. Items moved to the Trash are remembered for "empty after 7 days".
    static func clean(_ plan: Plan, dryRun: Bool, source: CleaningRecord.Source) -> Cleaner.Report {
        let report = Cleaner.run(plan.pairs.map { Cleaner.Request(item: $0.item, mode: $0.category.mode) }, dryRun: dryRun,
                                 history: source)
        if !report.dryRun { TrashLedger.record(report.trashedItems) }
        NotificationCenter.default.post(name: cleanedNotification, object: nil)
        return report
    }

    /// Posted after a headless clean in the app's own process (Shortcuts), so the window refreshes.
    static let cleanedNotification = Notification.Name("Spacebar.headlessClean")
}

/// The app's settings, also when this binary runs as the `spacebar` command outside the bundle.
enum AppDefaults {
    static let bundleID = "io.github.ovedaydin.spacebar"
    static let shared: UserDefaults = Bundle.main.bundleIdentifier == bundleID
        ? .standard : UserDefaults(suiteName: bundleID) ?? .standard
}

enum TrashLedger {
    static func record(_ items: [Cleaner.TrashedItem]) {
        guard !items.isEmpty else { return }
        var ledger = ScanCache.loadLedger()
        ledger.entries += items.map { .init(path: $0.url.path, bytes: $0.bytes, date: Date()) }
        ScanCache.save(ledger)
    }
}
