import Charts
import SpacebarCore
import SwiftUI

/// Used space over the last week, month or three months, with cleans and big jumps marked.
/// Hovering shows the day, how much was used, and what changed.
struct TimelineCard: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage("timelineDays") private var days = 30
    @State private var hovered: SpaceTimeline.Point?

    /// The app's validated folder blue (same as the treemap), one step per appearance.
    private let lineColor = Color.dynamic(light: 0x2A78D6, dark: 0x3987E5)

    var body: some View {
        let timeline = makeTimeline()
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Label("Used space", systemImage: "chart.xyaxis.line").font(.headline)
                Spacer()
                Picker("Range", selection: $days) {
                    Text("7 days").tag(7)
                    Text("30 days").tag(30)
                    Text("90 days").tag(90)
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .fixedSize()
            }
            if timeline.points.count < 3 {
                Text("The timeline fills in as Spacebar runs: it notes free space every hour. Check back tomorrow.")
                    .font(.callout).foregroundStyle(.secondary)
            } else {
                chart(timeline)
                    .frame(height: 160)
                    .accessibilityElement()
                    .accessibilityLabel(Text("Used space over the last \(days) days"))
                    .accessibilityValue(Text(summary(timeline)))
                legendNote(timeline)
            }
        }
        .padding(16)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
    }

    private func makeTimeline() -> SpaceTimeline {
        SpaceTimeline.build(samples: model.spaceLog.samples, total: model.space?.total ?? 0, days: Double(days),
                            cleans: model.cleaningHistory.map { (date: $0.date, freed: $0.freedBytes + $0.trashedBytes) },
                            history: model.history)
    }

    private func chart(_ timeline: SpaceTimeline) -> some View {
        let values = timeline.points.map(\.used)
        let low = values.min() ?? 0, high = values.max() ?? 0
        let pad = max(Int64(1_000_000_000), (high - low) / 6)
        return Chart {
            ForEach(timeline.points) { point in
                LineMark(x: .value("Date", point.date), y: .value("Used", point.used))
                    .foregroundStyle(lineColor)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .interpolationMethod(.monotone)
            }
            ForEach(timeline.events) { event in
                if let point = nearest(to: event.date, in: timeline.points) {
                    PointMark(x: .value("Date", point.date), y: .value("Used", point.used))
                        .symbol(event.kind == .clean ? .circle : .diamond)
                        .symbolSize(70)
                        .foregroundStyle(Color(nsColor: .controlBackgroundColor)) // 2px surface ring
                    PointMark(x: .value("Date", point.date), y: .value("Used", point.used))
                        .symbol(event.kind == .clean ? .circle : .diamond)
                        .symbolSize(36)
                        .foregroundStyle(event.kind == .clean ? Color.secondary : lineColor)
                }
            }
            if let hovered {
                RuleMark(x: .value("Date", hovered.date))
                    .foregroundStyle(Color.secondary.opacity(0.5))
                    .lineStyle(StrokeStyle(lineWidth: 1))
                PointMark(x: .value("Date", hovered.date), y: .value("Used", hovered.used))
                    .foregroundStyle(lineColor)
                    .symbolSize(50)
            }
        }
        .chartYScale(domain: max(0, low - pad)...(high + pad))
        .chartYAxis {
            AxisMarks(position: .trailing, values: .automatic(desiredCount: 3)) { value in
                AxisGridLine().foregroundStyle(Color.secondary.opacity(0.15))
                AxisValueLabel { if let bytes = value.as(Int64.self) { Text(ByteFormat.string(bytes)) } }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .chartOverlay { proxy in
            GeometryReader { geometry in
                Rectangle().fill(.clear).contentShape(Rectangle())
                    .onContinuousHover { phase in
                        switch phase {
                        case .active(let location):
                            let origin = geometry[proxy.plotAreaFrame].origin
                            if let date: Date = proxy.value(atX: location.x - origin.x) {
                                hovered = nearest(to: date, in: timeline.points)
                            }
                        case .ended:
                            hovered = nil
                        }
                    }
                if let hovered, let x = proxy.position(forX: hovered.date) {
                    tooltip(hovered, timeline)
                        .fixedSize()
                        .position(x: min(max(x + geometry[proxy.plotAreaFrame].origin.x, 110), geometry.size.width - 110), y: 34)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private func tooltip(_ point: SpaceTimeline.Point, _ timeline: SpaceTimeline) -> some View {
        let dayBefore = nearest(to: point.date.addingTimeInterval(-86400), in: timeline.points)
        let change = dayBefore.map { point.used - $0.used }
        let slot = Double(days) * 86400 / 180 * 2
        let events = timeline.events.filter { abs($0.date.timeIntervalSince(point.date)) <= max(slot, 3 * 3600) }
        return VStack(alignment: .leading, spacing: 3) {
            Text(point.date, format: .dateTime.weekday(.abbreviated).month(.abbreviated).day().hour().minute())
                .font(.caption).foregroundStyle(.secondary)
            Text("\(ByteFormat.string(point.used)) used").font(.callout.weight(.semibold)).monospacedDigit()
            if let change, abs(change) >= 100_000_000, dayBefore?.date != point.date {
                Text("\(change > 0 ? "+" : "−")\(ByteFormat.string(abs(change))) in a day")
                    .font(.caption).foregroundStyle(.secondary).monospacedDigit()
            }
            ForEach(events) { event in
                switch event.kind {
                case .clean:
                    Label("Cleaned \(ByteFormat.string(abs(event.delta)))", systemImage: "circle").font(.caption)
                case .jump:
                    Label("\(event.delta > 0 ? "+" : "−")\(ByteFormat.string(abs(event.delta)))", systemImage: "diamond")
                        .font(.caption)
                    ForEach(event.folders, id: \.path) { folder in
                        Text("\(folder.path) \(folder.delta > 0 ? "+" : "−")\(ByteFormat.string(abs(folder.delta)))")
                            .font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.secondary.opacity(0.2)))
    }

    private func legendNote(_ timeline: SpaceTimeline) -> some View {
        HStack(spacing: 14) {
            if timeline.events.contains(where: { $0.kind == .clean }) {
                Label("Clean", systemImage: "circle").foregroundStyle(.secondary)
            }
            if timeline.events.contains(where: { $0.kind == .jump }) {
                Label("Big change", systemImage: "diamond").foregroundStyle(.secondary)
            }
            Spacer()
            Text("Hover for details").foregroundStyle(.tertiary)
        }
        .font(.caption)
    }

    private func summary(_ timeline: SpaceTimeline) -> String {
        guard let first = timeline.points.first, let last = timeline.points.last else { return "" }
        let cleans = timeline.events.filter { $0.kind == .clean }.count
        return String(localized: "From \(ByteFormat.string(first.used)) to \(ByteFormat.string(last.used)) used. \(cleans) cleans.")
    }

    private func nearest(to date: Date, in points: [SpaceTimeline.Point]) -> SpaceTimeline.Point? {
        points.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
    }
}
