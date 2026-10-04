import AppKit
import SpacebarCore
import SwiftUI

struct CategoryView: View {
    @EnvironmentObject private var model: AppModel
    let category: CleanCategory
    @State private var pending: PendingClean?
    /// Files in the last Time Machine backup (checked off the main thread when the list changes).
    @State private var backedUp: Set<URL> = []
    @State private var lastBackup: Date?

    var body: some View {
        let items = model.items(category.id)
        VStack(spacing: 0) {
            header(items)
            Divider()
            if model.results[category.id] == nil {
                placeholder
            } else if items.isEmpty {
                empty
            } else {
                List(items) { item in
                    ItemRow(item: item, selected: binding(item), showsAge: category.ageBased,
                            suggested: model.isSuggested(item, in: category),
                            backedUp: backedUp.contains(item.url) ? lastBackup : nil)
                        .contextMenu {
                            if item.kind == .application || (category.id == "apps") {
                                Button("Uninstall \(item.name)…") { model.uninstall(item.url) }
                                Divider()
                            }
                            if item.duplicateOf != nil {
                                Button("Keep This Copy Instead") { model.keepInstead(item) }
                                Button("Reveal Kept Copy in Finder") {
                                    NSWorkspace.shared.activateFileViewerSelecting([item.duplicateOf!])
                                }
                                Divider()
                            }
                            Button("Reveal in Finder") { NSWorkspace.shared.activateFileViewerSelecting([item.url]) }
                                .disabled(!item.url.isFileURL)
                            Button("Never Show in Cleanup") { model.exclude(item.exclusionKey) }
                                .help("Hide this item from cleanup lists. Undo in Settings › Exclusions.")
                            Button("Copy Path") {
                                NSPasteboard.general.clearContents()
                                NSPasteboard.general.setString(item.url.path, forType: .string)
                            }
                        }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
                Divider()
                footer
            }
        }
        .navigationTitle(category.name)
        .task(id: items.map(\.url)) { await checkBackups(items) }
        .toolbar {
            if category.group == .rules {
                ToolbarItem {
                    Button { model.editRule(categoryID: category.id) } label: {
                        Label("Edit Rule…", systemImage: "slider.horizontal.3")
                    }
                    .help("Edit Rule…")
                }
            }
        }
        .cleanConfirmation($pending, model: model)
    }

    /// Only where people delete their own files: large, forgotten, duplicates and rules.
    @MainActor private func checkBackups(_ items: [CleanItem]) async {
        guard ["large", "forgotten", "duplicates"].contains(category.id) || category.group == .rules else { return }
        let files = items.filter { $0.kind == .file && $0.url.isFileURL }.map(\.url)
        let result = await Task.detached(priority: .utility) { () -> (Date?, Set<URL>) in
            guard let last = TimeMachine.lastBackup() else { return (nil, []) }
            let backed = files.filter { url in
                let modified = (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
                return TimeMachine.isBackedUp(modified: modified, excluded: TimeMachine.isExcluded(url), lastBackup: last)
            }
            return (last, Set(backed))
        }.value
        lastBackup = result.0
        backedUp = result.1
    }

    private func binding(_ item: CleanItem) -> Binding<Bool> {
        Binding(get: { model.selection.contains(item.url) },
                set: { model.setSelected($0, items: [item]) })
    }

    private func header(_ items: [CleanItem]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: category.icon)
                    .font(.system(size: 26))
                    .foregroundStyle(Color.accentColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(category.name).font(.title2.weight(.semibold))
                        SafetyTag(safety: category.safety)
                    }
                    Text(category.summary).foregroundStyle(.secondary)
                        .lineLimit(3)
                    Text(category.mode == .permanent
                         ? "Cleaning deletes these immediately."
                         : "Cleaning moves these to the Trash.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                if model.scanning.contains(category.id) {
                    ProgressView().controlSize(.small)
                } else if model.results[category.id] != nil {
                    Text(ByteFormat.string(model.total(category.id)))
                        .font(.title3.monospacedDigit())
                }
            }
            if category.ageBased && model.results[category.id] != nil {
                HStack(spacing: 8) {
                    Image(systemName: "clock.arrow.circlepath").foregroundStyle(.secondary)
                    Text("Suggest items not used in")
                    Picker("", selection: $model.staleDays) {
                        Text("1 week").tag(7)
                        Text("1 month").tag(30)
                        Text("3 months").tag(90)
                        Text("6 months").tag(180)
                    }
                    .labelsHidden()
                    .fixedSize()
                    let suggested = model.suggestedItems(category)
                    Text("· \(suggested.count) of \(items.count) items, \(ByteFormat.string(suggested.reduce(0) { $0 + $1.size }))")
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                    Spacer()
                }
                .font(.callout)
                Text("Caches an app wrote to recently will just be rebuilt, so removing them frees little space for long.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if category.needsFullDiskAccess && model.fullDiskAccess != true {
                Banner(icon: "lock.shield", tint: .blue, title: "Full Disk Access required",
                       message: "macOS hides this location from apps without Full Disk Access.") {
                    Button("Open System Settings") { FullDiskAccess.openSettings() }
                }
            }
            let running = Set(items.filter(\.inUse).compactMap(\.owner))
            if !running.isEmpty {
                Banner(icon: "exclamationmark.triangle", tint: .orange, title: "Some apps are running",
                       message: "Their items are skipped. Quit \(appList(running)) and scan again to clean them.") {
                    Button("Scan Again") { model.scan(category) }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func appList(_ bundleIDs: Set<String>) -> String {
        let names = bundleIDs.map(Cleaner.appName).sorted()
        switch names.count {
        case 0, 1: return names.first ?? ""
        case 2: return String(localized: "\(names[0]) and \(names[1])")
        default: return String(localized: "\(names.prefix(2).joined(separator: ", ")) and \(names.count - 2) more")
        }
    }

    private var placeholder: some View {
        VStack(spacing: 12) {
            Spacer()
            if model.scanning.contains(category.id) {
                ProgressView("Scanning…")
            } else {
                Image(systemName: category.icon).font(.system(size: 40)).foregroundStyle(.secondary)
                Text(category.onDemand
                     ? "This scan reads your personal folders, so macOS may ask for permission."
                     : "Run a scan to see what can be cleaned.")
                    .foregroundStyle(.secondary)
                Button("Scan \(category.name)") { model.scan(category) }
                    .buttonStyle(.borderedProminent)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var empty: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(systemName: "checkmark.circle").font(.system(size: 40)).foregroundStyle(.green)
            Text("Nothing to clean here").foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }

    private var footer: some View {
        let selected = model.selectedItems(category.id)
        let items = model.items(category.id)
        return HStack {
            if category.ageBased || category.safety == .safe {
                Button("Select Suggested") { model.selectSuggested(category) }
            }
            Button("Select All") { model.setSelected(true, items: items) }
            Button("Select None") { model.setSelected(false, items: items) }
            Spacer()
            Text("\(selected.count) selected · \(ByteFormat.string(model.selectedSize(category.id)))")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Button(model.dryRun ? "Simulate Clean" : "Clean") {
                pending = PendingClean(pairs: selected.map { ($0, category) })
            }
            .buttonStyle(.borderedProminent)
            .disabled(selected.isEmpty || model.cleaning)
        }
        .padding(12)
    }
}

private struct ItemRow: View {
    let item: CleanItem
    @Binding var selected: Bool
    var showsAge = false
    var suggested = false
    /// The date of the Time Machine backup this file is in, if it is.
    var backedUp: Date? = nil

    var body: some View {
        HStack(spacing: 10) {
            Toggle("", isOn: $selected)
                .toggleStyle(.checkbox)
                .labelsHidden()
                .disabled(!item.isSelectable)
                .accessibilityLabel(Text("Select \(item.name)"))
                .accessibilityValue(Text(ByteFormat.string(item.size)))
            FileIcon(url: item.url)
            VStack(alignment: .leading, spacing: 1) {
                Text(item.name).lineLimit(1).truncationMode(.middle)
                Text(secondary).font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            if item.inUse {
                Tag(text: "In use", color: .orange)
            } else if let reason = item.lockedReason {
                Tag(text: "Locked", color: .secondary).help(reason)
            } else if showsAge && !suggested {
                Tag(text: "Recently used", color: .secondary)
            }
            if showsAge && item.ownerInstalled == false {
                Tag(text: "No matching app", color: .purple)
                    .help("No installed app matches this name. It may be left over from an app you removed, or belong to a command-line tool.")
            }
            if let backedUp {
                Tag(text: "Backed up", color: .green)
                    .help("In your Time Machine backup from \(backedUp.formatted(date: .abbreviated, time: .shortened)), and unchanged since.")
            }
            Text(ByteFormat.string(item.size)).monospacedDigit().frame(minWidth: 80, alignment: .trailing)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
        .onTapGesture { if item.isSelectable { selected.toggle() } }
        // VoiceOver reads the row as one item: name, size, details; activating it toggles the checkbox.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(item.isSelectable ? .isButton : [])
        .accessibilityHint(item.isSelectable ? Text(selected ? "Selected. Activate to deselect." : "Activate to select.")
                                             : item.lockedReason.map { Text($0) } ?? Text("In use"))
        .opacity(item.isSelectable ? 1 : 0.6)
    }

    private var secondary: String {
        var parts: [String] = []
        if let detail = item.detail { parts.append(detail) }
        if let reason = item.lockedReason { parts.append(reason) }
        if showsAge, let lastUsed = item.lastUsed {
            parts.append(String(localized: "Last used \(relativeDate.localizedString(for: lastUsed, relativeTo: Date()))"))
        } else if let date = item.date {
            parts.append(shortDate.string(from: date))
        }
        if parts.isEmpty { parts.append(item.url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~")) }
        return parts.joined(separator: " · ")
    }
}

private struct Tag: View {
    let text: LocalizedStringKey
    let color: Color

    var body: some View {
        Text(text).font(.caption).padding(.horizontal, 6).padding(.vertical, 1)
            .background(color.opacity(0.15), in: Capsule())
            .foregroundStyle(color)
    }
}

private let relativeDate: RelativeDateTimeFormatter = {
    let f = RelativeDateTimeFormatter()
    f.unitsStyle = .full
    return f
}()
