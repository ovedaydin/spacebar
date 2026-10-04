import Foundation

/// Used space over time for the Overview's timeline, with what explains the big moves.
public struct SpaceTimeline: Sendable {
    public struct Point: Sendable, Identifiable, Equatable {
        public var id: Date { date }
        public let date: Date
        public let used: Int64
    }

    public struct Event: Sendable, Identifiable {
        public enum Kind: Sendable { case clean, jump }
        public var id: String { "\(kind)-\(date.timeIntervalSince1970)" }
        public let date: Date
        public let kind: Kind
        /// Change in used space: negative when space came back.
        public let delta: Int64
        /// For jumps: the folders that grew or shrank most in that period, when measured.
        public let folders: [StorageHistory.Growth]
    }

    public let points: [Point]
    public let events: [Event]

    /// `samples` are free-space samples; `total` the disk's size. Points are thinned to about
    /// `maxPoints` (the last sample in each slot). Jumps are moves of at least `jumpThreshold`
    /// between neighboring points.
    public static func build(samples: [SpaceForecast.Sample], total: Int64, days: Double, now: Date = Date(),
                             cleans: [(date: Date, freed: Int64)] = [], history: StorageHistory? = nil,
                             maxPoints: Int = 180, jumpThreshold: Int64 = 3_000_000_000) -> SpaceTimeline {
        let start = now.addingTimeInterval(-days * 86400)
        let recent = samples.filter { $0.date >= start && $0.date <= now }
        guard !recent.isEmpty else { return SpaceTimeline(points: [], events: []) }
        let slot = max(3600, days * 86400 / Double(maxPoints))
        var bySlot: [Int: SpaceForecast.Sample] = [:]
        for sample in recent { bySlot[Int(sample.date.timeIntervalSince(start) / slot)] = sample }
        let points = bySlot.keys.sorted().compactMap { bySlot[$0] }
            .map { Point(date: $0.date, used: max(0, total - $0.available)) }

        var events: [Event] = cleans.filter { $0.date >= start && $0.freed > 0 }
            .map { Event(date: $0.date, kind: .clean, delta: -$0.freed, folders: []) }
        for (before, after) in zip(points, points.dropFirst()) {
            let delta = after.used - before.used
            guard abs(delta) >= jumpThreshold else { continue }
            // A clean already explains space coming back around then.
            if delta < 0, events.contains(where: { $0.kind == .clean && abs($0.date.timeIntervalSince(after.date)) < slot * 2 }) {
                continue
            }
            events.append(Event(date: after.date, kind: .jump, delta: delta,
                                folders: history.map { changes(in: $0, from: before.date, to: after.date) } ?? []))
        }
        return SpaceTimeline(points: points, events: events.sorted { $0.date < $1.date })
    }

    /// Folders that changed most between the measurements around `from` and `to`.
    static func changes(in history: StorageHistory, from: Date, to: Date, limit: Int = 3) -> [StorageHistory.Growth] {
        guard let before = history.entries.last(where: { $0.date <= from }) ?? history.entries.first,
              let after = history.entries.first(where: { $0.date >= to }) ?? history.entries.last,
              after.date > before.date else { return [] }
        let paths = Set(before.folders.keys).union(after.folders.keys)
        let all: [StorageHistory.Growth] = paths.map { path in
            StorageHistory.Growth(path: path, before: before.folders[path], after: after.folders[path] ?? 0)
        }
        let big: [StorageHistory.Growth] = all.filter { abs($0.delta) >= 500_000_000 }
        return Array(big.sorted { abs($0.delta) > abs($1.delta) }.prefix(limit))
    }
}
