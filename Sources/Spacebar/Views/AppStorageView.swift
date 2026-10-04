import AppKit
import SpacebarCore
import SwiftUI

/// What each app really takes: the app plus its data, caches and settings in ~/Library.
struct AppStorageView: View {
    @EnvironmentObject private var model: AppModel
    @State private var expanded: Set<String> = []

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            List {
                ForEach(model.appUsage) { usage in row(usage) }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            .overlay {
                if model.appUsage.isEmpty && model.measuringApps {
                    ProgressView("Measuring apps…")
                }
            }
        }
        .navigationTitle("App Storage")
        .onAppear { model.measureApps() }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("\(ByteFormat.string(model.appUsage.reduce(0) { $0 + $1.total })) in \(model.appUsage.count) apps")
                    .font(.headline)
                Text("Each app with its data, caches and settings in your Library. Caches are rebuilt when needed, so clearing them is safe.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Spacer()
            if model.measuringApps {
                ProgressView().controlSize(.small)
                Text(model.appUsage.isEmpty ? "Measuring…" : "Updating…").font(.caption).foregroundStyle(.secondary)
            } else if let at = model.appUsageMeasuredAt {
                Text("Measured \(at.formatted(.relative(presentation: .named)))").font(.caption).foregroundStyle(.secondary)
            }
            Button { model.measureApps(force: true) } label: { Label("Measure Again", systemImage: "arrow.clockwise") }
                .disabled(model.measuringApps)
        }
        .padding(12)
    }

    private func row(_ usage: AppUsage) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 10) {
                Button {
                    if expanded.contains(usage.id) { expanded.remove(usage.id) } else { expanded.insert(usage.id) }
                } label: {
                    Image(systemName: expanded.contains(usage.id) ? "chevron.down" : "chevron.right").frame(width: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(expanded.contains(usage.id) ? "Hide details" : "Show details"))
                Image(nsImage: NSWorkspace.shared.icon(forFile: usage.url.path)).resizable().frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text(usage.name).fontWeight(.medium)
                    Text("App \(ByteFormat.string(usage.appBytes)) · Data \(ByteFormat.string(usage.dataBytes - usage.cacheBytes)) · Caches \(ByteFormat.string(usage.cacheBytes))")
                        .font(.caption).foregroundStyle(.secondary).monospacedDigit()
                }
                Spacer()
                if usage.cacheBytes >= 10_000_000 {
                    Button("Clear Cache") { model.clearCache(usage) }
                        .disabled(model.cleaning)
                        .help("Deletes \(ByteFormat.string(usage.cacheBytes)) of caches. \(usage.name) rebuilds them when needed; quit it first.")
                }
                if !usage.bundleID.hasPrefix("com.apple.") {
                    Button("Uninstall…") { model.uninstall(usage.url) }
                }
                Text(ByteFormat.string(usage.total)).monospacedDigit().fontWeight(.medium).frame(minWidth: 80, alignment: .trailing)
            }
            if expanded.contains(usage.id) {
                ForEach(Array(usage.pieces.enumerated()), id: \.offset) { _, piece in
                    HStack {
                        Text(piece.label)
                        Text(abbreviated(piece.url.path)).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                        Spacer()
                        Text(ByteFormat.string(piece.bytes)).monospacedDigit().foregroundStyle(.secondary)
                    }
                    .font(.caption)
                    .padding(.leading, 60)
                }
            }
        }
        .padding(.vertical, 3)
        .accessibilityElement(children: .contain)
    }

    private func abbreviated(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }
}
