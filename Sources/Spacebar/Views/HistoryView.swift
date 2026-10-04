import SpacebarCore
import SwiftUI

/// Every clean Spacebar did, newest first, with Put Back while the items are still in the Trash.
struct HistoryView: View {
    @EnvironmentObject private var model: AppModel
    /// What each clean can still put back. File checks run off the main thread.
    @State private var restorable: [UUID: [Cleaner.TrashedItem]] = [:]
    @State private var expanded: Set<UUID> = []

    var body: some View {
        Group {
            if model.cleaningHistory.isEmpty {
                ContentUnavailable(title: "No cleans yet",
                                   message: "Everything Spacebar removes shows up here, so you can put it back while it's in the Trash.")
            } else {
                List {
                    ForEach(model.cleaningHistory) { record in
                        recordRow(record)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .navigationTitle("History")
        .task(id: model.cleaningHistory.map(\.id)) { await refresh() }
        .onChange(of: model.cleaning) { cleaning in
            if !cleaning { Task { await refresh() } }
        }
    }

    private func refresh() async {
        let records = model.cleaningHistory
        restorable = await Task.detached(priority: .utility) {
            Dictionary(uniqueKeysWithValues: records.map { ($0.id, $0.restorable) })
        }.value
    }

    private func recordRow(_ record: CleaningRecord) -> some View {
        let back = restorable[record.id] ?? []
        return VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Button {
                    if expanded.contains(record.id) { expanded.remove(record.id) } else { expanded.insert(record.id) }
                } label: {
                    Image(systemName: expanded.contains(record.id) ? "chevron.down" : "chevron.right")
                        .frame(width: 12)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(expanded.contains(record.id) ? "Hide items" : "Show items"))
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary(record)).fontWeight(.medium)
                    HStack(spacing: 6) {
                        Text(record.date, format: .dateTime.day().month().year().hour().minute())
                        Text("·")
                        Text(source(record.source))
                    }
                    .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if !back.isEmpty {
                    Button("Put Back \(back.count) Items") { model.putBack(back) }
                        .disabled(model.cleaning)
                        .help("Moves them from the Trash to where they were")
                } else if record.trashedBytes > 0 {
                    Text("No longer in the Trash").font(.caption).foregroundStyle(.tertiary)
                }
            }
            if expanded.contains(record.id) {
                ForEach(Array(record.items.enumerated()), id: \.offset) { _, item in
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(item.name).lineLimit(1)
                            Text(abbreviated(item.original)).font(.caption).foregroundStyle(.secondary)
                                .lineLimit(1).truncationMode(.middle)
                        }
                        Spacer()
                        Text(status(item, restorable: back)).font(.caption).foregroundStyle(.secondary)
                        Text(ByteFormat.string(item.bytes)).monospacedDigit().foregroundStyle(.secondary)
                            .frame(minWidth: 70, alignment: .trailing)
                    }
                    .padding(.leading, 22)
                }
                if record.photos > 0 {
                    Text("\(record.photos) photos moved to Recently Deleted in Photos")
                        .font(.caption).foregroundStyle(.secondary).padding(.leading, 22)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private func summary(_ record: CleaningRecord) -> String {
        let count = record.items.count + record.photos
        if record.freedBytes > 0 && record.trashedBytes > 0 {
            return String(localized: "Freed \(ByteFormat.string(record.freedBytes)), moved \(ByteFormat.string(record.trashedBytes)) to the Trash · \(count) items")
        } else if record.trashedBytes > 0 {
            return String(localized: "Moved \(ByteFormat.string(record.trashedBytes)) to the Trash · \(count) items")
        }
        return String(localized: "Freed \(ByteFormat.string(record.freedBytes)) · \(count) items")
    }

    private func source(_ source: CleaningRecord.Source) -> String {
        switch source {
        case .app: return String(localized: "Cleanup")
        case .explorer: return String(localized: "Space Explorer")
        case .automatic: return String(localized: "Automatic cleaning")
        case .uninstall: return String(localized: "Uninstall")
        case .commandLine: return String(localized: "Command line")
        case .shortcuts: return String(localized: "Shortcuts")
        case .reminder: return String(localized: "Forgotten file reminder")
        }
    }

    private func status(_ item: CleaningRecord.Item, restorable: [Cleaner.TrashedItem]) -> String {
        guard let trashed = item.trashed else { return String(localized: "Deleted") }
        if restorable.contains(where: { $0.url.path == trashed }) { return String(localized: "In the Trash") }
        return FileManager.default.fileExists(atPath: item.original)
            ? String(localized: "Put back") : String(localized: "Emptied from the Trash")
    }

    private func abbreviated(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }
}

/// An empty-state message (ContentUnavailableView needs macOS 14).
struct ContentUnavailable: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.arrow.circlepath").font(.system(size: 36)).foregroundStyle(.tertiary)
            Text(title).font(.title3.weight(.semibold))
            Text(message).foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 380)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
