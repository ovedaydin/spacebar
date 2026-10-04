import AppKit
import Quartz
import SpacebarCore
import SwiftUI

struct ExplorerView: View {
    @EnvironmentObject private var explorer: ExplorerModel
    @EnvironmentObject private var model: AppModel
    @State private var pendingTrash: [ExplorerModel.Entry] = []
    @AppStorage("explorerShowsMap") private var showsMap = false
    @State private var search = ""
    @State private var typeFilter: TileKind?
    @State private var selection: Set<URL> = []
    /// The row the keyboard acts on (moves with ↑/↓).
    @State private var focus: URL?
    @State private var keyMonitor: Any?
    @FocusState private var searchFocused: Bool

    /// Rows after search and type filter, in display order.
    private var visible: [ExplorerModel.Entry] {
        explorer.ordered.filter { entry in
            (search.isEmpty || entry.name.localizedCaseInsensitiveContains(search))
                && (typeFilter == nil || TileKind.of(entry) == typeFilter)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            pathBar
            controls
            Divider()
            if showsMap {
                TreemapView().id(explorer.listID)
            } else {
                list
            }
        }
        .navigationTitle("Space Explorer")
        .onAppear {
            if !explorer.loaded { explorer.load() }
            installKeyboard()
        }
        .onDisappear { removeKeyboard() }
        .onReceive(NotificationCenter.default.publisher(for: DebugSnapshot.dumpNotification)) { _ in
            let names = { (urls: [URL]) in urls.map(\.lastPathComponent).sorted().joined(separator: ",") }
            FileHandle.standardError.write(Data(("[explorer-ui] folder=\(explorer.current.lastPathComponent) search=\(search) "
                + "visible=\(visible.count)/\(explorer.entries.count) focus=\(focus?.lastPathComponent ?? "-") "
                + "selection=[\(names(Array(selection)))] trash=\(pendingTrash.count) quicklook=\(QuickLook.shared.isVisible)\n").utf8))
        }
        .onChange(of: explorer.listID) { _ in
            selection = []
            focus = nil
        }
        .confirmationDialog(trashTitle, isPresented: Binding(get: { !pendingTrash.isEmpty }, set: { if !$0 { pendingTrash = [] } }),
                            titleVisibility: .visible) {
            Button(model.dryRun ? "Simulate" : "Move to Trash", role: model.dryRun ? nil : .destructive) { trash(pendingTrash) }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(model.dryRun
                 ? "Dry run is on: nothing will be moved."
                 : "\(ByteFormat.string(pendingTrash.reduce(0) { $0 + (explorer.sizes[$1.url]?.allocated ?? 0) })). You can put it back from the Trash.")
        }
    }

    // MARK: List

    private var list: some View {
        ScrollViewReader { proxy in
            List(visible) { entry in
                HStack(spacing: 8) {
                    EntryRow(entry: entry, totals: explorer.sizes[entry.url], largest: explorer.largest,
                             growth: explorer.growth(entry.url))
                        .contentShape(Rectangle())
                        .onTapGesture { click(entry) }
                        .help(entry.isFolder ? String(localized: "Open \(entry.name) (⌘-click to select)") : entry.name)
                        .accessibilityElement(children: .combine)
                        .accessibilityAddTraits(entry.isFolder ? .isButton : [])
                        .accessibilityAddTraits(selection.contains(entry.url) ? .isSelected : [])
                        .accessibilityAction(named: Text("Quick Look")) { QuickLook.shared.toggle([entry.url]) }
                    TrashButton(entry: entry) { pendingTrash = [entry] }
                }
                .padding(.horizontal, 4)
                .background(RoundedRectangle(cornerRadius: 6)
                    .fill(Color.accentColor.opacity(selection.contains(entry.url) ? 0.22 : 0)))
                .overlay(RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.accentColor.opacity(focus == entry.url ? 0.7 : 0), lineWidth: 1))
                .id(entry.url)
                .contextMenu { contextMenu(for: entry) }
            }
            .listStyle(.inset(alternatesRowBackgrounds: true))
            // A new list per folder, so it starts scrolled to the top.
            .id(explorer.listID)
            .onChange(of: focus) { url in
                if let url { withAnimation(.easeOut(duration: 0.1)) { proxy.scrollTo(url) } }
            }
            .overlay {
                if visible.isEmpty && !explorer.entries.isEmpty {
                    Text("No matches").foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder private func contextMenu(for entry: ExplorerModel.Entry) -> some View {
        let targets = selection.contains(entry.url) && selection.count > 1
            ? visible.filter { selection.contains($0.url) } : [entry]
        if entry.isFolder && targets.count == 1 { Button("Open") { explorer.open(entry) } }
        Button("Quick Look") { QuickLook.shared.toggle(targets.map(\.url)) }
        Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting(targets.map(\.url)) }
        Button("Never Show in Cleanup") {
            for target in targets { model.exclude(Exclusions.key(for: target.url)) }
        }
        Divider()
        let removable = targets.filter { PathRules.isDeletable($0.url, kind: $0.removalKind) }
        if removable.isEmpty, let reason = PathRules.reasonNotDeletable(entry.url, kind: entry.removalKind) {
            Button("Can't Remove: \(reason)") {}.disabled(true)
        } else {
            Button(removable.count > 1 ? "Move \(removable.count) Items to Trash…" : "Move to Trash…") {
                pendingTrash = removable
            }
        }
    }

    /// Click opens a folder (as before). ⌘-click toggles selection, ⇧-click selects a range.
    private func click(_ entry: ExplorerModel.Entry) {
        let flags = NSEvent.modifierFlags
        if flags.contains(.command) {
            if selection.contains(entry.url) { selection.remove(entry.url) } else { selection.insert(entry.url) }
            focus = entry.url
        } else if flags.contains(.shift), let anchor = focus,
                  let from = visible.firstIndex(where: { $0.url == anchor }),
                  let to = visible.firstIndex(where: { $0.url == entry.url }) {
            selection = Set(visible[min(from, to)...max(from, to)].map(\.url))
        } else {
            focus = entry.url
            selection = [entry.url]
            if entry.isFolder { explorer.open(entry) }
        }
    }

    // MARK: Keyboard

    private func installKeyboard() {
        guard keyMonitor == nil else { return }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKey(event) ? nil : event
        }
    }

    private func removeKeyboard() {
        if let keyMonitor { NSEvent.removeMonitor(keyMonitor) }
        keyMonitor = nil
    }

    /// Returns true when the key was handled.
    private func handleKey(_ event: NSEvent) -> Bool {
        let command = event.modifierFlags.contains(.command)
        let shift = event.modifierFlags.contains(.shift)
        // Typing in the search field (or any text field) belongs to that field, except Esc and ↓.
        let typing = NSApp.keyWindow?.firstResponder is NSText
        if command && event.charactersIgnoringModifiers == "f" {
            searchFocused = true
            return true
        }
        if typing {
            if event.keyCode == 53 { search = ""; searchFocused = false; return true }   // Esc
            if event.keyCode == 125 { searchFocused = false; moveFocus(by: 1, extend: false); return true }
            return false
        }
        // Only for the main window (or Quick Look opened from it), not Settings or the menu bar panel.
        let key = NSApp.keyWindow
        let isMain = key?.identifier?.rawValue.hasPrefix("main") == true
        guard isMain || key is QLPreviewPanel else { return false }
        switch event.keyCode {
        case 125: moveFocus(by: 1, extend: shift); return true                    // ↓
        case 126 where command: goUp(); return true                               // ⌘↑
        case 126: moveFocus(by: -1, extend: shift); return true                   // ↑
        case 36, 76, 124:                                                         // Return, Enter, →
            if let entry = focusedEntry, entry.isFolder { explorer.open(entry) }
            return true
        case 123: goUp(); return true                                             // ←
        case 49:                                                                  // Space
            QuickLook.shared.toggle(selectedOrFocused.map(\.url))
            return true
        case 51 where command, 117 where command:                                 // ⌘⌫
            let removable = selectedOrFocused.filter { PathRules.isDeletable($0.url, kind: $0.removalKind) }
            if !removable.isEmpty { pendingTrash = removable }
            return true
        case 0 where command:                                                     // ⌘A
            selection = Set(visible.map(\.url))
            return true
        case 53:                                                                  // Esc
            if QuickLook.shared.isVisible { QuickLook.shared.toggle([]) } else { selection = []; search = "" }
            return true
        default:
            return false
        }
    }

    private var focusedEntry: ExplorerModel.Entry? { visible.first { $0.url == focus } }

    private var selectedOrFocused: [ExplorerModel.Entry] {
        let selected = visible.filter { selection.contains($0.url) }
        return selected.isEmpty ? focusedEntry.map { [$0] } ?? [] : selected
    }

    private func moveFocus(by step: Int, extend: Bool) {
        guard !visible.isEmpty else { return }
        let current = visible.firstIndex { $0.url == focus }
        let next = current.map { min(max($0 + step, 0), visible.count - 1) } ?? 0
        let url = visible[next].url
        if extend { selection.insert(url) } else { selection = [url] }
        focus = url
        if QuickLook.shared.isVisible { QuickLook.shared.toggle([]); QuickLook.shared.toggle([url]) }
    }

    private func goUp() {
        if explorer.trail.count >= 2 { explorer.jump(to: explorer.trail.count - 2) }
        else if explorer.group != nil && !explorer.trail.isEmpty { explorer.jump(to: -1) }
    }

    // MARK: Bars

    private var pathBar: some View {
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
                Button(index == 0 && url.path == NSHomeDirectory() ? String(localized: "Home") : url.lastPathComponent) {
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
            } else if let live = explorer.liveUpdatedAt {
                Label("Live", systemImage: "dot.radiowaves.left.and.right")
                    .font(.callout).foregroundStyle(.secondary)
                    .help("Updated automatically \(live.formatted(.relative(presentation: .named)))")
            } else if let since = explorer.cachedSince {
                Text("Sizes from \(since.formatted(.relative(presentation: .named)))")
                    .font(.callout).foregroundStyle(.secondary)
            }
            if !selection.isEmpty {
                Text("\(selection.count) selected · \(ByteFormat.string(selectedOrFocused.reduce(0) { $0 + (explorer.sizes[$1.url]?.allocated ?? 0) })) ·")
                    .font(.callout).foregroundStyle(.secondary).monospacedDigit().lineLimit(1).fixedSize()
            }
            Text(ByteFormat.string(explorer.currentTotal)).monospacedDigit().foregroundStyle(.secondary)
            Button { explorer.load(force: true) } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
                .help("Measure again")
                .accessibilityLabel(Text("Measure again"))
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 6)
    }

    private var controls: some View {
        HStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                TextField("Search (⌘F)", text: $search)
                    .textFieldStyle(.plain)
                    .focused($searchFocused)
                if !search.isEmpty {
                    Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(Color(nsColor: .textBackgroundColor), in: RoundedRectangle(cornerRadius: 6))
            .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(Color.secondary.opacity(0.25)))
            .frame(width: 190)

            Menu {
                Button("All Types") { typeFilter = nil }
                Divider()
                ForEach(TileKind.allCases, id: \.self) { kind in
                    Button(kind.name) { typeFilter = kind }
                }
            } label: {
                Label(typeFilter?.name ?? String(localized: "All Types"), systemImage: "line.3.horizontal.decrease.circle")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            Spacer()
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
                Image(systemName: "list.bullet").tag(false).help("List").accessibilityLabel(Text("List"))
                Image(systemName: "square.grid.3x3.square").tag(true).help("Map").accessibilityLabel(Text("Map"))
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            Menu {
                ForEach(model.drives) { drive in
                    Button(drive.isStartup ? String(localized: "\(drive.name) (Home)") : drive.name) {
                        explorer.show(drive.isStartup ? FileManager.default.homeDirectoryForCurrentUser : drive.url)
                    }
                }
                Divider()
                Button("Choose Folder…") { explorer.chooseFolder() }
            } label: {
                Image(systemName: "externaldrive")
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
            .help("Explore another drive or folder")
            .accessibilityLabel(Text("Drives and folders"))
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 10)
    }

    // MARK: Trash

    private var trashTitle: String {
        if pendingTrash.count == 1 {
            let name = pendingTrash[0].name
            return model.dryRun ? String(localized: "Simulate moving “\(name)” to the Trash?")
                : String(localized: "Move “\(name)” to the Trash?")
        }
        return model.dryRun ? String(localized: "Simulate moving \(pendingTrash.count) items to the Trash?")
            : String(localized: "Move \(pendingTrash.count) items to the Trash?")
    }

    private func trash(_ entries: [ExplorerModel.Entry]) {
        let requests = entries.map { entry -> Cleaner.Request in
            var item = CleanItem(url: entry.url, name: entry.name, size: explorer.sizes[entry.url]?.allocated ?? 0,
                                 date: nil, detail: nil, owner: Bundle(url: entry.url)?.bundleIdentifier)
            item.kind = entry.removalKind
            return Cleaner.Request(item: item, mode: .trash)
        }
        let dryRun = model.dryRun
        selection = []
        Task.detached {
            let report = Cleaner.run(requests, dryRun: dryRun, history: .explorer)
            await MainActor.run {
                if !report.removed.isEmpty { explorer.didRemove(report.removed) }
                model.applyRemovals(report)
                if !report.trashedItems.isEmpty && !dryRun { model.rememberTrashed(report.trashedItems) }
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
                .accessibilityLabel(Text("Protected: \(reason)"))
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
            .accessibilityLabel(Text("Move \(entry.name) to the Trash"))
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
                    .help(growthHelp(growth))
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

    private func growthHelp(_ growth: (bytes: Int64, since: Date)) -> String {
        let size = ByteFormat.string(abs(growth.bytes))
        let since = growth.since.formatted(.relative(presentation: .named))
        return growth.bytes > 0 ? String(localized: "Grew by \(size) since \(since)")
            : String(localized: "Shrank by \(size) since \(since)")
    }
}
