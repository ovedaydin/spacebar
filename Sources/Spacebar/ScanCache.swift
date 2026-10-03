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
    }

    struct Explorer: Codable {
        struct Entry: Codable {
            var totals: SizeTotals
            var measured: Date
        }

        var version = ScanCache.version
        var entries: [String: Entry]
    }

    /// Keeps the explorer cache file small; the largest folders are the useful ones.
    static let maxExplorerEntries = 50_000

    static var directory: URL {
        FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(Bundle.main.bundleIdentifier ?? "Spacebar", isDirectory: true)
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
