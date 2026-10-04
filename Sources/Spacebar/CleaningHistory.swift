import Foundation

/// One clean Spacebar did (never dry runs), kept so it can be put back later.
struct CleaningRecord: Codable, Identifiable, Sendable {
    enum Source: String, Codable, Sendable {
        case app, explorer, automatic, uninstall, commandLine, shortcuts, reminder
    }

    struct Item: Codable, Sendable {
        let name: String
        let original: String
        /// Where it went in the Trash; nil when it was deleted right away.
        let trashed: String?
        let bytes: Int64
    }

    var id = UUID()
    let date: Date
    let source: Source
    let freedBytes: Int64
    let trashedBytes: Int64
    let photos: Int
    let items: [Item]

    /// Items that are still in the Trash, so Put Back can restore them.
    var restorable: [Cleaner.TrashedItem] {
        items.compactMap { item in
            guard let trashed = item.trashed, FileManager.default.fileExists(atPath: trashed),
                  !FileManager.default.fileExists(atPath: item.original) else { return nil }
            return Cleaner.TrashedItem(url: URL(fileURLWithPath: trashed), original: URL(fileURLWithPath: item.original),
                                       bytes: item.bytes)
        }
    }
}

/// Every clean, newest first, in Application Support (shared by the app and the `spacebar` command).
enum CleaningHistory {
    static let changed = Notification.Name("Spacebar.cleaningHistoryChanged")
    /// Older cleans are forgotten; their items have long left the Trash anyway.
    static let limit = 200
    private static let queue = DispatchQueue(label: "Spacebar.CleaningHistory")

    static var url: URL { ScanCache.supportDirectory.appendingPathComponent("cleaning-history.json") }

    static func load() -> [CleaningRecord] {
        queue.sync {
            guard let data = try? Data(contentsOf: url) else { return [] }
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            return (try? decoder.decode([CleaningRecord].self, from: data)) ?? []
        }
    }

    static func append(_ record: CleaningRecord) {
        queue.sync {
            var records = (try? Data(contentsOf: url)).flatMap { data -> [CleaningRecord]? in
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                return try? decoder.decode([CleaningRecord].self, from: data)
            } ?? []
            records.insert(record, at: 0)
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            try? FileManager.default.createDirectory(at: ScanCache.supportDirectory, withIntermediateDirectories: true)
            try? encoder.encode(Array(records.prefix(limit))).write(to: url, options: .atomic)
        }
        DispatchQueue.main.async { NotificationCenter.default.post(name: changed, object: nil) }
    }

    /// Removes one record (the debug self-test cleans up after itself).
    static func remove(_ id: UUID) {
        queue.sync {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            guard let data = try? Data(contentsOf: url),
                  var records = try? decoder.decode([CleaningRecord].self, from: data) else { return }
            records.removeAll { $0.id == id }
            try? encoder.encode(records).write(to: url, options: .atomic)
        }
        DispatchQueue.main.async { NotificationCenter.default.post(name: changed, object: nil) }
    }
}
