import AppKit
import SpacebarCore
import SwiftUI

/// Uninstall an app together with everything it keeps in ~/Library.
struct UninstallView: View {
    @EnvironmentObject private var model: AppModel
    @Environment(\.dismiss) private var dismiss
    let app: AppFootprint.App

    @State private var parts: [AppFootprint.Part] = []
    @State private var sizes: [URL: Int64] = [:]
    @State private var selected: Set<URL> = []
    @State private var running = false

    private var refusal: String? {
        if app.bundleID.hasPrefix("com.apple.") && app.bundleID != "com.apple.dt.Xcode" { return "Apps that come with macOS can't be removed." }
        if app.bundleID == Bundle.main.bundleIdentifier { return "That's Spacebar." }
        return nil
    }

    private var total: Int64 {
        (selected.contains(app.url) ? sizes[app.url] ?? 0 : 0)
            + parts.filter { selected.contains($0.url) }.reduce(0) { $0 + (sizes[$1.url] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(nsImage: NSWorkspace.shared.icon(forFile: app.url.path)).resizable().frame(width: 48, height: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Uninstall \(app.name)").font(.title2.weight(.semibold))
                    Text([app.version.map { "Version \($0)" }, app.url.deletingLastPathComponent().path]
                        .compactMap { $0 }.joined(separator: " · "))
                        .font(.callout).foregroundStyle(.secondary)
                }
            }
            if let refusal {
                Label(refusal, systemImage: "lock").foregroundStyle(.secondary)
            } else {
                if running {
                    HStack {
                        Label("\(app.name) is running. Quit it before uninstalling.", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(.orange)
                        Spacer()
                        Button("Quit \(app.name)") {
                            NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID).forEach { $0.terminate() }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { refreshRunning() }
                        }
                    }
                }
                List {
                    row(app.url, label: "The app", name: app.url.lastPathComponent)
                    ForEach(parts) { part in
                        row(part.url, label: part.label, name: part.url.lastPathComponent)
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                .frame(minHeight: 220)
                Text(parts.isEmpty ? "No other data found for this app."
                     : "Shared containers are left unchecked: other apps from the same developer may use them.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                if refusal == nil {
                    Text("\(selected.count) selected · \(ByteFormat.string(total))").foregroundStyle(.secondary).monospacedDigit()
                }
                Spacer()
                Button("Cancel", role: .cancel) { dismiss() }
                    .keyboardShortcut(.cancelAction)
                if refusal == nil {
                    Button(model.dryRun ? "Simulate Uninstall" : "Move to Trash") {
                        uninstall()
                        dismiss()
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(selected.isEmpty || running)
                }
            }
        }
        .padding(20)
        .frame(width: 600, height: 480)
        .onAppear(perform: load)
    }

    private func row(_ url: URL, label: String, name: String) -> some View {
        HStack(spacing: 10) {
            Toggle("", isOn: Binding(get: { selected.contains(url) },
                                     set: { if $0 { selected.insert(url) } else { selected.remove(url) } }))
                .toggleStyle(.checkbox).labelsHidden()
                .accessibilityLabel("Remove \(name)")
            FileIcon(url: url)
            VStack(alignment: .leading, spacing: 1) {
                Text(name).lineLimit(1).truncationMode(.middle)
                Text(label + " · " + url.deletingLastPathComponent().path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Text(sizes[url].map(ByteFormat.string) ?? "…").monospacedDigit().foregroundStyle(.secondary)
        }
        .contentShape(Rectangle())
        .onTapGesture { if selected.contains(url) { selected.remove(url) } else { selected.insert(url) } }
    }

    private func refreshRunning() {
        running = !NSRunningApplication.runningApplications(withBundleIdentifier: app.bundleID).isEmpty
    }

    private func load() {
        refreshRunning()
        parts = AppFootprint.locate(app)
        selected = Set([app.url] + parts.filter(\.selectedByDefault).map(\.url))
        let urls = [app.url] + parts.map(\.url)
        Task.detached(priority: .userInitiated) {
            let measured = BulkScanner().measure(urls, cancel: nil)
            await MainActor.run {
                sizes = Dictionary(uniqueKeysWithValues: zip(urls, measured.map(\.allocated)))
            }
        }
    }

    private func uninstall() {
        var requests: [Cleaner.Request] = []
        if selected.contains(app.url) {
            var item = CleanItem(url: app.url, name: app.name, size: sizes[app.url] ?? 0, date: nil, detail: nil, owner: app.bundleID)
            item.kind = app.url.path.hasPrefix("/Applications/") || app.url.path.hasPrefix(NSHomeDirectory() + "/Applications/")
                ? .application : .file
            requests.append(Cleaner.Request(item: item, mode: .trash))
        }
        for part in parts where selected.contains(part.url) {
            var item = CleanItem(url: part.url, name: part.url.lastPathComponent, size: sizes[part.url] ?? 0,
                                 date: nil, detail: nil, owner: app.bundleID)
            item.kind = .appData(bundleID: app.bundleID, appName: app.name)
            requests.append(Cleaner.Request(item: item, mode: .trash))
        }
        model.runUninstall(requests)
    }
}
