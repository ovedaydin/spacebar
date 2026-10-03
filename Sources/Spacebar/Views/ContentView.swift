import AppKit
import SpacebarCore
import SwiftUI

enum Route: Hashable {
    case overview
    case explorer
    case category(String)
}

struct ContentView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var explorer: ExplorerModel
    @State private var route: Route? = ContentView.initialRoute

    /// SPACEBAR_ROUTE=explorer|<category id> opens a specific page (development aid).
    private static var initialRoute: Route {
        switch ProcessInfo.processInfo.environment["SPACEBAR_ROUTE"] {
        case nil, "overview": return .overview
        case "explorer": return .explorer
        case let id?: return .category(id)
        }
    }

    var body: some View {
        NavigationSplitView {
            List(selection: $route) {
                Section {
                    Label("Overview", systemImage: "internaldrive").tag(Route.overview)
                    Label("Space Explorer", systemImage: "chart.bar.doc.horizontal").tag(Route.explorer)
                }
                Section("Cleanup") {
                    ForEach(model.categories.filter { $0.group == .cleanup }) { category in
                        SidebarRow(category: category).tag(Route.category(category.id))
                    }
                }
                Section("Find Space") {
                    ForEach(model.categories.filter { $0.group == .findSpace }) { category in
                        SidebarRow(category: category).tag(Route.category(category.id))
                    }
                }
            }
            .navigationSplitViewColumnWidth(min: 230, ideal: 250)
        } detail: {
            switch route ?? .overview {
            case .overview: OverviewView(route: $route)
            case .explorer: ExplorerView()
            case .category(let id): CategoryView(category: model.category(id)!)
            }
        }
        .toolbar {
            ToolbarItemGroup {
                Toggle(isOn: $model.dryRun) {
                    Label("Dry Run", systemImage: model.dryRun ? "eye" : "eye.slash")
                }
                .help("Dry run: show what would be removed without deleting anything")
                Button {
                    model.scanAll()
                } label: {
                    Label("Scan", systemImage: "arrow.clockwise")
                }
                .disabled(model.isScanning)
                .help("Scan again (⌘R)")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: DebugSnapshot.routeNotification)) { note in
            guard let id = note.object as? String else { return }
            route = id == "overview" ? .overview : id == "explorer" ? .explorer : .category(id)
        }
        .onReceive(NotificationCenter.default.publisher(for: DebugSnapshot.dumpNotification)) { note in
            let window = NSApp.windows.first(where: \.isVisible)
            if let report = model.report {
                let skipped = report.skipped.map { "\($0.name): \($0.reason)" }.joined(separator: " | ")
                FileHandle.standardError.write(Data(("[report] dryRun=\(report.dryRun) deleted=\(report.deletedBytes) "
                    + "trashed=\(report.trashedBytes) removed=\(report.removed.count) skipped=\(report.skipped.count) [\(skipped)]\n"
                    + "[report-title] \(report.title)\n[report-message] \(report.message.replacingOccurrences(of: "\n", with: " / "))\n").utf8))
            }
            let selectedBytes = model.allSelected.reduce(Int64(0)) { $0 + $1.0.size }
            FileHandle.standardError.write(Data("[selection] items=\(model.allSelected.count) bytes=\(selectedBytes) dryRun=\(model.dryRun) cleaning=\(model.cleaning) scanning=\(model.isScanning)\n".utf8))
            if note.object as? String == "paths" {
                for (item, category) in model.allSelected {
                    FileHandle.standardError.write(Data("[path] \(category.mode.rawValue)\t\(item.size)\t\(item.url.path)\n".utf8))
                }
            }
            let state = "[state] \(note.object ?? "") route=\(String(describing: route)) selected=\(model.selection.count) folder=\(explorer.current.path) "
                + "visible=\(window?.occlusionState.contains(.visible) == true) key=\(window?.isKeyWindow == true)\n"
            FileHandle.standardError.write(Data(state.utf8))
            if note.object as? String == "explorer" {
                let rows = explorer.ordered.prefix(12).map { "\($0.name)=\(ByteFormat.string(explorer.sizes[$0.url]?.allocated ?? -1))" }
                FileHandle.standardError.write(Data("[explorer] group=\(explorer.group?.title ?? "-") atGroup=\(explorer.atGroupLevel) entries=\(explorer.entries.count) total=\(ByteFormat.string(explorer.currentTotal)) measuring=\(explorer.progress.map { "\($0.done)/\($0.total)" } ?? "done")\n  \(rows.joined(separator: "\n  "))\n".utf8))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: DebugSnapshot.segmentNotification)) { note in
            if let action = note.object as? String, action.hasPrefix("action:") {
                if action == "action:fdacheck" {
                    model.checkFullDiskAccessAgain()
                    FileHandle.standardError.write(Data("[fda] granted=\(String(describing: model.fullDiskAccess)) checkFailed=\(model.accessCheckFailed)\n".utf8))
                } else {
                    model.relaunch()
                }
                return
            }
            // Same as clicking a slice in the disk breakdown legend.
            guard let raw = note.object as? String, let kind = StorageSegment.Kind(rawValue: raw),
                  let segment = model.storage?.segments.first(where: { $0.kind == kind }) else { return }
            FileHandle.standardError.write(Data("[segment] \(segment.name) \(segment.bytes) roots=\(segment.roots ?? [])\n".utf8))
            if let roots = segment.roots, roots.count > 1 {
                explorer.showGroup(segment.name, roots: roots.map { URL(fileURLWithPath: $0) })
            } else if let path = segment.roots?.first ?? segment.explorePath {
                explorer.show(URL(fileURLWithPath: path))
            }
            route = .explorer
        }
        .onReceive(NotificationCenter.default.publisher(for: DebugSnapshot.simulateNotification)) { _ in
            // Debug-only path, and it refuses to run unless Dry Run is on.
            guard model.dryRun else {
                FileHandle.standardError.write(Data("[simulate] REFUSED: Dry Run is off\n".utf8))
                return
            }
            model.clean(model.allSelected)
        }
        .onReceive(NotificationCenter.default.publisher(for: DebugSnapshot.toggleNotification)) { note in
            guard let id = note.object as? String else { return }
            let items = model.items(id)
            model.setSelected(model.selectedItems(id).isEmpty, items: items)
        }
        .onAppear {
            // Cached results are on screen already; measure again in the background.
            if model.showingCachedResults || ProcessInfo.processInfo.environment["SPACEBAR_AUTOSCAN"] != nil {
                model.scanAll()
            }
        }
        .alert(model.report?.title ?? "", isPresented: Binding(get: { model.report != nil },
                                                                set: { if !$0 { model.report = nil } }),
               presenting: model.report) { report in
            let trashed = report.trashedItems.reduce(Int64(0)) { $0 + $1.bytes }
            if !report.dryRun && !report.trashedItems.isEmpty {
                Button("Delete Now (\(ByteFormat.string(trashed)))", role: .destructive) { model.deleteTrashed(report) }
                Button("Keep in Trash", role: .cancel) {}
            } else {
                Button("OK", role: .cancel) {}
            }
        } message: { report in
            Text(report.message)
        }
    }
}

private struct SidebarRow: View {
    let category: CleanCategory

    var body: some View {
        HStack {
            Label(category.name, systemImage: category.icon)
            Spacer()
            SidebarSize(category: category)
        }
    }
}

private struct SidebarSize: View {
    @EnvironmentObject private var model: AppModel
    let category: CleanCategory

    var body: some View {
        if model.results[category.id] != nil {
            Text(ByteFormat.string(model.total(category.id)))
                .font(.callout.monospacedDigit())
                .foregroundStyle(.secondary)
                .opacity(model.scanning.contains(category.id) ? 0.5 : 1)
        } else if model.scanning.contains(category.id) {
            ProgressView().controlSize(.small)
        }
    }
}

extension Cleaner.Report {
    var title: String {
        if dryRun { return "Dry run: nothing was deleted" }
        if emptiedTrash { return skipped.isEmpty ? "Deleted from the Trash" : "Some items couldn't be deleted" }
        return skipped.isEmpty ? "Cleanup complete" : "Cleanup finished with some items skipped"
    }

    var message: String {
        var lines: [String] = []
        let verb = dryRun ? "Would" : ""
        if deletedBytes > 0 { lines.append("\(verb.isEmpty ? "Freed" : "Would free") \(ByteFormat.string(deletedBytes)).") }
        if trashedBytes > 0 {
            lines.append("\(verb.isEmpty ? "Moved" : "Would move") \(ByteFormat.string(trashedBytes)) to the Trash, so that space isn't free yet."
                + (dryRun ? "" : " Delete Now permanently deletes just these items; nothing else in your Trash is touched."))
        }
        if emptiedTrash && deletedBytes == 0 && !dryRun && skipped.isEmpty {
            lines.append("Finder emptied the Trash.")
        }
        if !skipped.isEmpty {
            lines.append("Skipped \(skipped.count):")
            lines += skipped.prefix(5).map { "• \($0.name): \($0.reason)" }
            if skipped.count > 5 { lines.append("…and \(skipped.count - 5) more") }
        }
        lines.append("Details: ~/Library/Logs/Spacebar/operations.log")
        return lines.joined(separator: "\n")
    }
}
