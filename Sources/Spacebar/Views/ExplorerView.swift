import AppKit
import SpacebarCore
import SwiftUI

struct ExplorerView: View {
    @EnvironmentObject private var explorer: ExplorerModel
    @EnvironmentObject private var model: AppModel
    @State private var pendingTrash: ExplorerModel.Entry?
    @AppStorage("explorerShowsMap") private var showsMap = false

    var body: some View {
        VStack(spacing: 0) {
            toolbar
            Divider()
            if showsMap {
                TreemapView().id(explorer.listID)
            } else {
            List(explorer.ordered) { entry in
                HStack(spacing: 8) {
                    Button {
                        if entry.isFolder { explorer.open(entry) }
                    } label: {
                        EntryRow(entry: entry, totals: explorer.sizes[entry.url], largest: explorer.largest,
                             growth: explorer.growth(entry.url))
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .help(entry.isFolder ? "Open \(entry.name)" : entry.name)
                    TrashButton(entry: entry) { pendingTrash = entry }
                }
                .contextMenu {
                    if entry.isFolder { Button("Open") { explorer.open(entry) } }
                    Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([entry.url]) }
                    Divider()
                    if let reason = PathRules.reasonNotDeletable(entry.url, kind: entry.removalKind) {
                        Button("Can't Remove: \(reason)") {}.disabled(true)
                    } else {
                        Button("Move to Trash…") { pendingTrash = entry }
                    }
                }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            // A new list per folder, so it starts scrolled to the top.
            .id(explorer.listID)
            }
        }
        .navigationTitle("Space Explorer")
        .onAppear { if !explorer.loaded { explorer.load() } }
        .confirmationDialog(
            "\(model.dryRun ? "Simulate moving" : "Move") “\(pendingTrash?.name ?? "")” to the Trash?",
            isPresented: Binding(get: { pendingTrash != nil }, set: { if !$0 { pendingTrash = nil } }),
            titleVisibility: .visible, presenting: pendingTrash
        ) { entry in
            Button(model.dryRun ? "Simulate" : "Move to Trash", role: model.dryRun ? nil : .destructive) { trash(entry) }
            Button("Cancel", role: .cancel) {}
        } message: { entry in
            Text(model.dryRun
                 ? "Dry run is on: nothing will be moved."
                 : "\(ByteFormat.string(explorer.sizes[entry.url]?.allocated ?? 0)). You can restore it from the Trash.")
        }
    }

    private var toolbar: some View {
        HStack(spacing: 4) {
            if let group = explorer.group {
                Button(group.title) { explorer.jump(to: -1) }
                    .buttonStyle(.borderless)
                    .fontWeight(explorer.atGroupLevel ? .semibold : .regular)
                    .help("\(group.roots.count) folders counted as \(group.title)")
            }
            ForEach(Array(explorer.trail.enumerated()), id: \.offset) { index, url in
                if index > 0 || explorer.group != nil {
                    Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
                }
                Button(index == 0 && url.path == NSHomeDirectory() ? "Home" : url.lastPathComponent) {
                    explorer.jump(to: index)
                }
                .buttonStyle(.borderless)
                .fontWeight(index == explorer.trail.count - 1 ? .semibold : .regular)
            }
            Spacer()
            if let progress = explorer.progress {
                ProgressView().controlSize(.small)
                Text("Measuring \(progress.done) of \(progress.total)…")
                    .font(.callout).foregroundStyle(.secondary).monospacedDigit()
            } else if let since = explorer.cachedSince {
                Text("Sizes from \(since.formatted(.relative(presentation: .named)))")
                    .font(.callout).foregroundStyle(.secondary)
            }
            Text(ByteFormat.string(explorer.currentTotal)).monospacedDigit().foregroundStyle(.secondary)
            Button { explorer.load(force: true) } label: { Image(systemName: "arrow.clockwise") }
                .help("Measure again")
            Picker("Sort", selection: $explorer.sortByGrowth) {
                Text("Size").tag(false)
                Text("Growth").tag(true)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .help("Sort by size, or by how much each item grew since it was last measured")
            .disabled(showsMap)
            Picker("View", selection: $showsMap) {
                Image(systemName: "list.bullet").tag(false).help("List")
                Image(systemName: "square.grid.3x3.square").tag(true).help("Map")
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            Button("Choose Folder…") { explorer.chooseFolder() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func trash(_ entry: ExplorerModel.Entry) {
        var item = CleanItem(url: entry.url, name: entry.name, size: explorer.sizes[entry.url]?.allocated ?? 0,
                             date: nil, detail: nil, owner: Bundle(url: entry.url)?.bundleIdentifier)
        item.kind = entry.removalKind
        let dryRun = model.dryRun
        Task.detached {
            let report = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: dryRun)
            await MainActor.run {
                if !report.removed.isEmpty { explorer.didRemove(report.removed) }
                model.applyRemovals(report)
                model.report = report
            }
        }
    }
}

extension ExplorerModel.Entry {
    /// Apps are validated and removed like apps (Apple apps refused, password asked when needed).
    var removalKind: ItemKind {
        url.pathExtension == "app" && (url.path.hasPrefix("/Applications/") || url.path.hasPrefix(NSHomeDirectory() + "/Applications/"))
            ? .application : .file
    }
}

/// Trash button at the end of each row, or a lock explaining why the item is protected.
private struct TrashButton: View {
    let entry: ExplorerModel.Entry
    let action: () -> Void
    @State private var hovering = false

    var body: some View {
        if let reason = PathRules.reasonNotDeletable(entry.url, kind: entry.removalKind) {
            Image(systemName: "lock")
                .foregroundStyle(.tertiary)
                .frame(width: 24, height: 24)
                .help("Can't be removed: \(reason)")
        } else {
            Button(action: action) {
                Image(systemName: "trash")
                    .foregroundStyle(hovering ? Color.red : Color.secondary)
                    .frame(width: 24, height: 24)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .onHover { hovering = $0 }
            .help("Move \(entry.name) to the Trash")
        }
    }
}

private struct EntryRow: View {
    let entry: ExplorerModel.Entry
    let totals: SizeTotals?
    let largest: Int64
    var growth: (bytes: Int64, since: Date)?

    var body: some View {
        HStack(spacing: 10) {
            FileIcon(url: entry.url)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(entry.name).lineLimit(1).truncationMode(.middle)
                    if let totals, totals.cloudOnlyFiles > 0 {
                        Label("\(totals.cloudOnlyFiles) in iCloud only", systemImage: "icloud")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    if let totals, totals.unreadable > 0 {
                        Image(systemName: "lock").font(.caption).foregroundStyle(.secondary)
                            .help("Some items couldn't be read. Grant Full Disk Access for a complete total.")
                    }
                }
                GeometryReader { geo in
                    let fraction = largest > 0 ? Double(totals?.allocated ?? 0) / Double(largest) : 0
                    Capsule().fill(Color.accentColor.opacity(0.7))
                        .frame(width: max(2, geo.size.width * fraction))
                }
                .frame(height: 5)
                .opacity(totals == nil ? 0 : 1)
            }
            Spacer(minLength: 12)
            if let growth, abs(growth.bytes) >= 50_000_000 {
                Label(ByteFormat.string(abs(growth.bytes)), systemImage: growth.bytes > 0 ? "arrow.up" : "arrow.down")
                    .font(.caption.monospacedDigit())
                    .foregroundStyle(.secondary)
                    .help("\(growth.bytes > 0 ? "Grew" : "Shrank") by \(ByteFormat.string(abs(growth.bytes))) since \(growth.since.formatted(.relative(presentation: .named)))")
            }
            Group {
                if let totals {
                    Text(ByteFormat.string(totals.allocated)).monospacedDigit()
                } else {
                    ProgressView().controlSize(.small)
                }
            }
            .frame(minWidth: 80, alignment: .trailing)
            if entry.isFolder {
                Image(systemName: "chevron.right").foregroundStyle(.tertiary)
            } else {
                Image(systemName: "chevron.right").hidden()
            }
        }
        .padding(.vertical, 3)
    }
}
