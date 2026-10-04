import AppKit
import SpacebarCore
import SwiftUI

/// macOS settings that decide how much space things take: which are on, what's involved, and
/// where to change them. Spacebar only reads them.
struct SpaceSettingsView: View {
    @State private var items: [SpaceSettings.Item] = SpaceSettings.check()
    @State private var sizes: [String: Int64] = [:]
    @State private var loading = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                Text("A few macOS settings decide how much space your files, photos, messages and the Trash take. Spacebar only reads them; the buttons take you to where you can change them.")
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: 640, alignment: .leading)
                ForEach(items) { item in row(item) }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .topLeading)
        }
        .navigationTitle("Space-Saving Settings")
        .task { await load() }
    }

    @MainActor private func load() async {
        loading = true
        // One at a time, smallest folders first in practice: each shows as soon as it's measured.
        for item in items {
            let id = item.id
            if let bytes = await Task.detached(priority: .userInitiated, operation: { SpaceSettings.size(of: id, engine: BulkScanner()) }).value {
                sizes[id] = bytes
            }
        }
        loading = false
    }

    private func row(_ item: SpaceSettings.Item) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon(item.status)).font(.title3).foregroundStyle(color(item.status)).frame(width: 24)
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text(item.title).fontWeight(.medium)
                    Text(label(item.status)).font(.caption).foregroundStyle(color(item.status))
                }
                Text(item.detail).foregroundStyle(.secondary)
                Text(item.whereToFind).font(.caption).foregroundStyle(.tertiary)
            }
            Spacer(minLength: 12)
            VStack(alignment: .trailing, spacing: 6) {
                if let bytes = sizes[item.id] {
                    Text(ByteFormat.string(bytes)).monospacedDigit().foregroundStyle(.secondary)
                } else if loading && SpaceSettings.folders[item.id] != nil {
                    ProgressView().controlSize(.small)
                }
                Button("Open") { NSWorkspace.shared.open(item.open) }
                    .help(item.whereToFind)
            }
        }
        .padding(12)
        .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }

    private func icon(_ status: SpaceSettings.Status) -> String {
        switch status {
        case .saving: return "checkmark.circle.fill"
        case .couldSave: return "exclamationmark.circle"
        case .unknown: return "questionmark.circle"
        }
    }

    private func color(_ status: SpaceSettings.Status) -> Color {
        switch status {
        case .saving: return .green
        case .couldSave: return .orange
        case .unknown: return .secondary
        }
    }

    private func label(_ status: SpaceSettings.Status) -> LocalizedStringKey {
        switch status {
        case .saving: return "On"
        case .couldSave: return "Could save space"
        case .unknown: return "Check in the app"
        }
    }
}
