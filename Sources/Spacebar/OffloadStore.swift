import Foundation
import SpacebarCore

/// Where offloaded files went, in Application Support.
enum OffloadStore {
    static var url: URL { ScanCache.supportDirectory.appendingPathComponent("offloads.json") }

    static func load() -> [Offload.Record] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return (try? decoder.decode([Offload.Record].self, from: data)) ?? []
    }

    static func save(_ records: [Offload.Record]) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        try? FileManager.default.createDirectory(at: ScanCache.supportDirectory, withIntermediateDirectories: true)
        try? encoder.encode(records).write(to: url, options: .atomic)
    }
}
