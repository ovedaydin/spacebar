import AppKit
import SpacebarCore
import SwiftUI

/// The panel that opens from Spacebar's menu bar item.
struct MenuBarPanel: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.openWindow) private var openWindow
    @State private var confirming: Action?

    enum Action { case clean, emptyTrash }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            header
            if let storage = model.storage { bar(storage) }
            Divider()
            if let confirming {
                confirmation(confirming)
            } else {
                actions
            }
            Divider()
            HStack {
                Button("Open Spacebar") { openMain() }
                Spacer()
                if Updates.shared.available {
                    Button("Updates…") { Updates.shared.check() }
                }
                Button("Settings…") { openSettings() }
                Button("Quit") { NSApp.terminate(nil) }
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .frame(width: 320)
        .onAppear { model.refreshSystem() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 26, height: 26)
                Text("Spacebar").font(.headline)
                Spacer()
                if model.cleaning || model.isScanning { ProgressView().controlSize(.small) }
            }
            VStack(alignment: .leading, spacing: 2) {
                Group {
                    if let space = model.space {
                        Text("\(ByteFormat.string(space.available)) available")
                    } else {
                        Text("Measuring…")
                    }
                }
                .font(.title3.weight(.semibold))
                if let space = model.space {
                    Text("of \(ByteFormat.string(space.total)) on Macintosh HD").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
    }

    private func bar(_ storage: StorageBreakdown) -> some View {
        GeometryReader { geo in
            let segments = storage.segments.filter { $0.bytes > 0 }
            let scale = max(0, geo.size.width - CGFloat(segments.count) * 2) / CGFloat(max(storage.total, 1))
            HStack(spacing: 2) {
                ForEach(segments) { segment in
                    Rectangle().fill(segment.kind.color)
                        .frame(width: max(1, CGFloat(segment.bytes) * scale))
                        .help("\(segment.name): \(ByteFormat.string(segment.bytes))")
                }
                Rectangle().fill(Color.secondary.opacity(0.15))
            }
            .clipShape(RoundedRectangle(cornerRadius: 3))
        }
        .frame(height: 10)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Disk usage"))
        .accessibilityValue(Text(storage.segments.filter { $0.bytes > 0 }.prefix(4)
            .map { "\($0.name) \(ByteFormat.string($0.bytes))" }.joined(separator: ", ")))
    }

    @ViewBuilder private var actions: some View {
        let quick = model.quickCleanItems
        let quickSize = quick.reduce(Int64(0)) { $0 + $1.0.size }
        VStack(alignment: .leading, spacing: 8) {
            Button {
                confirming = .clean
            } label: {
                Label(quickCleanTitle(isEmpty: quick.isEmpty, size: quickSize), systemImage: "sparkles")
            }
            .disabled(quick.isEmpty || model.cleaning)
            if let trash = model.trashBytes, trash > 0 {
                Button { confirming = .emptyTrash } label: {
                    Label("Empty Trash (\(ByteFormat.string(trash)))…", systemImage: "trash")
                }
                .disabled(model.cleaning)
            }
            Button { model.scanAll() } label: { Label("Scan Again", systemImage: "arrow.clockwise") }
                .disabled(model.isScanning)
            if let report = model.report {
                Text(report.message.components(separatedBy: "\n").first ?? "")
                    .font(.caption).foregroundStyle(.secondary)
            }
        }
        .buttonStyle(.borderless)
    }

    private func confirmation(_ action: Action) -> some View {
        let quickSize = model.quickCleanItems.reduce(Int64(0)) { $0 + $1.0.size }
        return VStack(alignment: .leading, spacing: 8) {
            Text(confirmationTitle(action, size: quickSize))
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)
            Text(model.dryRun ? "Dry run is on: nothing will be deleted."
                 : action == .clean ? "Apps rebuild these. Items of running apps are skipped." : "This can't be undone.")
                .font(.caption).foregroundStyle(.secondary)
            HStack {
                Button("Cancel") { confirming = nil }
                Spacer()
                Button(model.dryRun ? "Simulate" : (action == .clean ? "Clean" : "Empty Trash")) {
                    if action == .clean { model.clean(model.quickCleanItems) } else { model.emptyTrash() }
                    confirming = nil
                }
                .buttonStyle(.borderedProminent)
                .tint(model.dryRun ? .accentColor : .red)
            }
        }
    }

    private func quickCleanTitle(isEmpty: Bool, size: Int64) -> LocalizedStringKey {
        if isEmpty { return model.hasScanned ? "Nothing suggested to clean" : "Scan to find what to clean" }
        let size = ByteFormat.string(size)
        return model.dryRun ? "Simulate cleaning \(size) of caches and logs…" : "Clean \(size) of caches and logs…"
    }

    private func confirmationTitle(_ action: Action, size: Int64) -> LocalizedStringKey {
        let size = ByteFormat.string(size)
        switch action {
        case .clean:
            return model.dryRun ? "Simulate cleaning \(size) of suggested caches, logs and build data?"
                : "Delete \(size) of suggested caches, logs and build data?"
        case .emptyTrash:
            return model.dryRun ? "Simulate emptying the Trash?" : "Permanently delete everything in the Trash?"
        }
    }

    private func openMain() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.canBecomeMain && $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            openWindow(id: "main")
        }
    }

    private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        if #available(macOS 14, *) {
            NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        } else {
            NSApp.sendAction(Selector(("showPreferencesWindow:")), to: nil, from: nil)
        }
    }
}

struct SettingsView: View {
    @EnvironmentObject private var model: AppModel
    @AppStorage(Preferences.showMenuBar) private var showMenuBar = true
    @AppStorage(Preferences.menuBarShowsSpace) private var menuBarShowsSpace = false
    @AppStorage(Preferences.lowDiskAlerts) private var lowDiskAlerts = true
    @AppStorage(Preferences.lowDiskThresholdGB) private var threshold = 10
    @AppStorage(Preferences.autoClean) private var autoClean = false
    @AppStorage(Preferences.autoEmptyTrashed) private var autoEmptyTrashed = false
    @AppStorage(Preferences.forgottenReminders) private var forgottenReminders = true

    var body: some View {
        Form {
            Section("Menu bar") {
                Toggle("Show Spacebar in the menu bar", isOn: $showMenuBar)
                Toggle("Show available space next to the icon", isOn: $menuBarShowsSpace)
                    .disabled(!showMenuBar)
                Text("Spacebar keeps running in the menu bar after you close its window. On Macs with a notch, macOS hides menu bar items that don't fit. If you can't see Spacebar's icon, hold ⌘ and drag it (or other icons) to rearrange, or quit apps you don't need in the menu bar.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Alerts") {
                Toggle("Notify me when the disk is almost full", isOn: $lowDiskAlerts)
                Picker("When less than", selection: $threshold) {
                    ForEach([5, 10, 20, 50], id: \.self) { Text("\($0) GB available").tag($0) }
                }
                .disabled(!lowDiskAlerts)
                Toggle("Ask about big files left in Downloads or on the Desktop", isOn: $forgottenReminders)
                Text("At most once a week: a file over 500 MB you haven't opened in 2 months, with Keep and Move to Trash buttons. Nothing is removed unless you click Move to Trash.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Section("Automatic") {
                Toggle("Clean safe items once a week", isOn: $autoClean)
                Text("Only suggested caches, logs and build data, with the same rules as a manual clean: exclusions, running apps and Dry Run apply. You get a notification with what was freed.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Empty items Spacebar moved to the Trash after 7 days", isOn: $autoEmptyTrashed)
                Text("Only what Spacebar put in the Trash. Anything else in your Trash is left alone.")
                    .font(.caption).foregroundStyle(.secondary)
                Toggle("Open Spacebar at login", isOn: Binding(get: { LoginItem.isEnabled }, set: { LoginItem.set($0) }))
            }
            Section("Cleaning") {
                Picker("Suggest caches not used in", selection: $model.staleDays) {
                    Text("1 week").tag(7)
                    Text("1 month").tag(30)
                    Text("3 months").tag(90)
                    Text("6 months").tag(180)
                }
                Toggle("Dry run: only show what would be removed", isOn: $model.dryRun)
            }
            Section("Exclusions") {
                if model.exclusions.isEmpty {
                    Text("Nothing excluded. Right-click any item and choose Never Show in Cleanup.")
                        .font(.caption).foregroundStyle(.secondary)
                } else {
                    ForEach(model.exclusions, id: \.self) { key in
                        HStack {
                            Text(key.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                                .lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Button { model.removeExclusion(key) } label: { Image(systemName: "minus.circle") }
                                .buttonStyle(.borderless)
                                .help("Show this in cleanup lists again")
                        }
                    }
                }
                Button("Add Folder…") {
                    let panel = NSOpenPanel()
                    panel.canChooseDirectories = true
                    panel.canChooseFiles = true
                    panel.allowsMultipleSelection = true
                    panel.prompt = String(localized: "Exclude")
                    if panel.runModal() == .OK {
                        for url in panel.urls { model.exclude(Exclusions.key(for: url)) }
                    }
                }
            }
            Section("Updates") {
                LabeledContent("Version", value: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev")
                Button("Check for Updates…") { Updates.shared.check() }
                    .disabled(!Updates.shared.available)
            }
            Section("Permissions") {
                LabeledContent("Full Disk Access", value: model.fullDiskAccess == true ? String(localized: "Granted") : String(localized: "Not granted"))
                Button("Open Privacy & Security…") { FullDiskAccess.openSettings() }
            }
        }
        .formStyle(.grouped)
        .frame(width: 500, height: 640)
    }
}
