import Foundation

/// Available space over time, sampled about hourly, to forecast when the disk fills up.
public struct SpaceForecast: Codable, Sendable {
    public struct Sample: Codable, Sendable, Equatable {
        public let date: Date
        public let available: Int64

        public init(date: Date, available: Int64) {
            self.date = date
            self.available = available
        }
    }

    public struct Result: Sendable, Equatable {
        /// Bytes per day the disk is filling at (positive).
        public let bytesPerDay: Double
        /// Days until available space reaches the reserve.
        public let days: Double
    }

    public var samples: [Sample] = []
    public init() {}

    /// Keeps at most one sample per `minInterval` and `keepDays` of history.
    public mutating func record(available: Int64, at date: Date = Date(),
                                minInterval: TimeInterval = 3600, keepDays: Double = 90) {
        if let last = samples.last, date.timeIntervalSince(last.date) < minInterval { return }
        samples.append(Sample(date: date, available: available))
        samples.removeAll { date.timeIntervalSince($0.date) > keepDays * 86400 }
    }

    /// The trend over the last `window`: the median of the slopes between pairs of samples
    /// (Theil–Sen), after taking out space that suddenly came back (cleans).
    /// nil without at least `minimumSpan` of data, or when the disk isn't filling up.
    public func forecast(now: Date = Date(), window: TimeInterval = 14 * 86400, minimumSpan: TimeInterval = 3 * 86400,
                         reserve: Int64 = 2_000_000_000) -> Result? {
        let recent = samples.filter { now.timeIntervalSince($0.date) <= window }
        guard recent.count >= 6, let first = recent.first, let last = recent.last,
              last.date.timeIntervalSince(first.date) >= minimumSpan else { return nil }
        // Space that suddenly came back (a clean, an emptied Trash) is a step, not the trend:
        // take it out, so what's left is how fast the disk fills.
        var adjusted: [Sample] = []
        var returned: Int64 = 0
        for (index, sample) in recent.enumerated() {
            if index > 0 {
                let jump = sample.available - recent[index - 1].available
                if jump > 1_000_000_000 { returned += jump }
            }
            adjusted.append(Sample(date: sample.date, available: sample.available - returned))
        }
        // Pairs at least 6 hours apart; thin out long histories to keep it cheap.
        let step = max(1, adjusted.count / 150)
        let points = stride(from: 0, to: adjusted.count, by: step).map { adjusted[$0] }
        var slopes: [Double] = []
        for i in points.indices {
            for j in points.indices where j > i {
                let seconds = points[j].date.timeIntervalSince(points[i].date)
                guard seconds >= 6 * 3600 else { continue }
                slopes.append(Double(points[j].available - points[i].available) / seconds * 86400)
            }
        }
        guard !slopes.isEmpty else { return nil }
        slopes.sort()
        let perDay = slopes[slopes.count / 2]
        // Losing less than 100 MB a day isn't filling up in any useful sense.
        guard perDay < -100_000_000 else { return nil }
        let room = Double(max(0, last.available - reserve))
        return Result(bytesPerDay: -perDay, days: room / -perDay)
    }
}
