import Foundation
import SpacebarCore

/// Remembers scan results between launches in ~/Library/Caches/<bundle id>/.
///
/// Cached results are shown immediately and then measured again: a folder's size can
/// change deep inside it without the folder's own modification date changing, so the
/// cache is never trusted as the final answer.
enum ScanCache {
    static let version = 2

    struct Catalog: Codable {
        var version = ScanCache.version
        var date: Date
        var results: [String: [CleanItem]]
        /// FSEvents position when the scan started: changes after it are replayed at launch.
        var eventID: UInt64? = nil
        /// When every category was last scanned (not just the changed ones).
        var fullScan: Date? = nil
    }

    struct Explorer: Codable {
        struct Entry: Codable {
            var totals: SizeTotals
            var measured: Date
            /// The measurement before this one, for "grew recently".
            var previous: Int64?
            var previousMeasured: Date?
            /// FSEvents position just before it was measured (see ExplorerModel.catchUp).
            var eventID: UInt64? = nil
        }

        var version = ScanCache.version
        var entries: [String: Entry]
    }

    /// Keeps the explorer cache file small; the largest folders are the useful ones.
    static let maxExplorerEntries = 50_000

    static var directory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(AppDefaults.bundleID, isDirectory: true)
    }

    static func loadCatalog() -> Catalog? {
        guard let catalog: Catalog = read("catalog.json"), catalog.version == version else { return nil }
        return catalog
    }

    static func loadExplorer() -> Explorer? {
        guard let explorer: Explorer = read("explorer.json"), explorer.version == version else { return nil }
        return explorer
    }

    static func save(_ catalog: Catalog) { write(catalog, to: "catalog.json") }

    static func loadStorage() -> StorageBreakdown? {
        guard let storage: StorageBreakdown = read("storage.json"), storage.complete else { return nil }
        return storage
    }

    static func save(_ storage: StorageBreakdown) { write(storage, to: "storage.json") }

    /// What Spacebar moved to the Trash, and when, for "empty after 7 days".
    /// Lives in Application Support (not Caches, which cleaners empty).
    struct TrashLedger: Codable {
        struct Entry: Codable {
            let path: String
            let bytes: Int64
            let date: Date
        }
        var entries: [Entry] = []
    }

    static var supportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(AppDefaults.bundleID, isDirectory: true)
    }

    static func loadLedger() -> TrashLedger {
        guard let data = try? Data(contentsOf: supportDirectory.appendingPathComponent("trash-ledger.json")),
              let ledger = try? JSONDecoder().decode(TrashLedger.self, from: data) else { return TrashLedger() }
        return ledger
    }

    static func save(_ ledger: TrashLedger) {
        let url = supportDirectory.appendingPathComponent("trash-ledger.json")
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        try? JSONEncoder().encode(ledger).write(to: url, options: .atomic)
    }

    static func loadSpaceLog() -> SpaceForecast {
        guard let data = try? Data(contentsOf: supportDirectory.appendingPathComponent("space-log.json")),
              let log = try? JSONDecoder().decode(SpaceForecast.self, from: data) else { return SpaceForecast() }
        return log
    }

    static func save(_ log: SpaceForecast) {
        try? FileManager.default.createDirectory(at: supportDirectory, withIntermediateDirectories: true)
        try? JSONEncoder().encode(log).write(to: supportDirectory.appendingPathComponent("space-log.json"), options: .atomic)
    }

    struct Apps: Codable { var date: Date; var apps: [AppUsage] }
    static func loadApps() -> Apps? { read("apps.json") }
    static func save(_ apps: Apps) { write(apps, to: "apps.json") }

    static func loadHistory() -> StorageHistory? { read("history.json") }
    static func save(_ history: StorageHistory) { write(history, to: "history.json") }

    static func save(_ explorer: Explorer) {
        var explorer = explorer
        if explorer.entries.count > maxExplorerEntries {
            let kept = explorer.entries.sorted { $0.value.totals.allocated > $1.value.totals.allocated }
                .prefix(maxExplorerEntries)
            explorer.entries = Dictionary(uniqueKeysWithValues: kept.map { ($0.key, $0.value) })
        }
        write(explorer, to: "explorer.json")
    }

    private static func read<T: Decodable>(_ name: String) -> T? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(name)) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    private static func write<T: Encodable & Sendable>(_ value: T, to name: String) {
        let url = directory.appendingPathComponent(name)
        Task.detached(priority: .utility) {
            guard let data = try? JSONEncoder().encode(value) else { return }
            try? FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try? data.write(to: url, options: .atomic)
        }
    }
}
