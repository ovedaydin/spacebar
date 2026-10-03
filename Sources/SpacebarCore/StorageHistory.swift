import Foundation

/// Folder sizes from past disk measurements, to show what grew.
public struct StorageHistory: Codable, Sendable {
    public struct Entry: Codable, Sendable {
        public let date: Date
        public let folders: [String: Int64]
    }

    public struct Growth: Sendable, Equatable {
        public let path: String
        public let before: Int64?
        public let after: Int64
        public var delta: Int64 { after - (before ?? 0) }
        public var isNew: Bool { before == nil }
    }

    public var entries: [Entry] = []

    public init() {}

    /// Adds a measurement. Keeps at most one entry per `minInterval` (the newest wins)
    /// and about two months of history.
    public mutating func record(_ folders: [String: Int64], at date: Date = Date(),
                                minInterval: TimeInterval = 6 * 3600, keep: Int = 240) {
        guard !folders.isEmpty else { return }
        if let last = entries.last, date.timeIntervalSince(last.date) < minInterval {
            entries.removeLast()
        }
        entries.append(Entry(date: date, folders: folders))
        if entries.count > keep { entries.removeFirst(entries.count - keep) }
    }

    /// The measurement to compare against: the newest one at least `window` old,
    /// or else the oldest one that is at least `minimumAge` old.
    public func baseline(window: TimeInterval = 7 * 86400, minimumAge: TimeInterval = 12 * 3600,
                         now: Date = Date()) -> Entry? {
        let candidates = entries.dropLast()
        if let weekOld = candidates.last(where: { now.timeIntervalSince($0.date) >= window }) { return weekOld }
        return candidates.first(where: { now.timeIntervalSince($0.date) >= minimumAge })
    }

    /// Folders that grew by at least `threshold` since the baseline, largest growth first.
    public func growth(threshold: Int64 = 200_000_000, window: TimeInterval = 7 * 86400,
                       now: Date = Date()) -> (since: Date, items: [Growth])? {
        guard let latest = entries.last, let base = baseline(window: window, now: now) else { return nil }
        let items = latest.folders.compactMap { path, after -> Growth? in
            let growth = Growth(path: path, before: base.folders[path], after: after)
            return growth.delta >= threshold ? growth : nil
        }
        .sorted { $0.delta > $1.delta }
        return (base.date, items)
    }
}
