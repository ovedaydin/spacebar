import SpacebarCore
import SwiftUI

struct OverviewView: View {
    @EnvironmentObject private var model: AppModel
    @EnvironmentObject private var explorer: ExplorerModel
    @Binding var route: Route?
    @State private var pending: PendingClean?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if model.needsMoveToApplications {
                    Banner(icon: "folder.badge.questionmark", tint: .orange, title: "Move Spacebar to Applications",
                           message: "Spacebar is running from a disk image or a quarantined folder, so macOS may block its permissions. Drag it to your Applications folder and open it from there.") {}
                }
                if model.fullDiskAccess != true {
                    Banner(icon: "lock.shield", tint: .blue,
                           title: model.accessCheckFailed ? "Full Disk Access isn't active yet" : "Optional: grant Full Disk Access",
                           message: model.accessCheckFailed
                               ? "If you just turned Spacebar on in Privacy & Security › Full Disk Access, macOS applies it after Spacebar restarts. Click Quit & Reopen. If it's still not active afterwards, remove Spacebar from the list with the – button and add it again with +."
                               : "Without it, Spacebar can't see your Trash, Mail attachments, iPhone backups, or sandboxed app caches. Turn on Spacebar under Privacy & Security › Full Disk Access.") {
                        Button("Open System Settings") {
                            FullDiskAccess.openSettings()
                            model.watchForFullDiskAccess()
                        }
                        if model.accessCheckFailed {
                            Button("Quit & Reopen") { model.relaunch() }
                                .buttonStyle(.borderedProminent)
                        } else {
                            Button("Check Again") { model.checkFullDiskAccessAgain() }
                        }
                    }
                }

                if !model.lastTrashed.isEmpty {
                    Banner(icon: "arrow.uturn.backward.circle", tint: .orange,
                           title: "Your last clean moved \(ByteFormat.string(model.lastTrashedBytes)) to the Trash",
                           message: "That space isn't free until it's deleted from the Trash. Put it back if you removed something by mistake.") {
                        Button("Delete Now") { model.deleteTrashed() }
                            .disabled(model.cleaning)
                        Button("Put Back") { model.putBackLastClean() }
                            .disabled(model.cleaning)
                    }
                }

                DiskUsageCard(open: { url in
                    explorer.show(url)
                    route = .explorer
                }, openGroup: { title, roots in
                    explorer.showGroup(title, roots: roots)
                    route = .explorer
                })

                if !model.snapshots.isEmpty {
                    Banner(icon: "clock.arrow.circlepath", tint: .purple,
                           title: "\(model.snapshots.count) Time Machine local snapshot\(model.snapshots.count == 1 ? "" : "s")",
                           message: "These count as purgeable space. macOS deletes them automatically when it needs the space, and after 24 hours. To remove them now, run `tmutil thinlocalsnapshots / 999999999999 4` in Terminal.") {}
                }

                summary

                if model.hasScanned {
                    categoryList("Cleanup", model.categories.filter { $0.group == .cleanup })
                    categoryList("Find Space", model.categories.filter { $0.group == .findSpace })
                }
            }
            .padding(24)
            .frame(maxWidth: 900, alignment: .leading)
        }
        .navigationTitle("Overview")
        .cleanConfirmation($pending, model: model)
    }

    private func categoryList(_ title: String, _ categories: [CleanCategory]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline)
            VStack(spacing: 0) {
                ForEach(categories) { category in
                    CategoryRow(category: category) { route = .category(category.id) }
                    if category.id != categories.last?.id { Divider() }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    @ViewBuilder private var summary: some View {
        HStack(alignment: .center) {
            if model.hasScanned {
                VStack(alignment: .leading, spacing: 2) {
                    Text(ByteFormat.string(model.totalSelectedSize))
                        .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    Text("selected to clean").foregroundStyle(.secondary)
                    if model.isScanning {
                        Text("Updating…").font(.caption).foregroundStyle(.secondary)
                    } else if let lastScan = model.lastScan {
                        Text("Last scanned \(lastScan.formatted(.relative(presentation: .named)))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                Spacer()
                if model.isScanning { ProgressView().controlSize(.small).padding(.trailing, 8) }
                Button {
                    debugLog("Overview: Clean button pressed → showing confirmation")
                    pending = PendingClean(pairs: model.allSelected)
                } label: {
                    Text(model.dryRun ? "Simulate Clean" : "Clean Selected").frame(minWidth: 120)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(model.allSelected.isEmpty || model.cleaning || model.isScanning)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Find out what's using your disk").font(.title2.weight(.semibold))
                    Text("Spacebar looks for caches, logs, build data, and leftovers. Nothing is removed until you review it and confirm.")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    model.scanAll()
                } label: {
                    Text(model.isScanning ? "Scanning…" : "Scan").frame(minWidth: 100)
                }
                .controlSize(.large)
                .buttonStyle(.borderedProminent)
                .disabled(model.isScanning)
            }
        }
    }
}

private struct DiskUsageCard: View {
    @EnvironmentObject private var model: AppModel
    @State private var confirmEmptyTrash = false
    let open: (URL) -> Void
    let openGroup: (String, [URL]) -> Void

    var body: some View {
        if let space = model.space {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Macintosh HD").font(.headline)
                    Spacer()
                    Text("\(ByteFormat.string(space.available)) available of \(ByteFormat.string(space.total))")
                        .foregroundStyle(.secondary)
                }
                if let storage = model.storage {
                    breakdown(storage)
                } else {
                    simpleBar(space)
                }
                if Double(space.available) / Double(max(space.total, 1)) < 0.05 {
                    Label("Your disk is almost full. macOS needs free space to run smoothly and install updates.",
                          systemImage: "exclamationmark.triangle.fill")
                        .font(.callout)
                        .foregroundStyle(.red)
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 10))
        }
    }

    private func breakdown(_ storage: StorageBreakdown) -> some View {
        let segments = storage.segments.filter { $0.bytes > 0 }
        return VStack(alignment: .leading, spacing: 10) {
            GeometryReader { geo in
                let gaps = CGFloat(segments.count) * 2
                let scale = max(0, geo.size.width - gaps) / CGFloat(max(storage.total, 1))
                HStack(spacing: 2) {
                    ForEach(segments) { segment in
                        Rectangle()
                            .fill(segment.kind.color)
                            .frame(width: max(1, CGFloat(segment.bytes) * scale))
                            .help("\(segment.name): \(ByteFormat.string(segment.bytes))")
                    }
                    Rectangle().fill(Color.secondary.opacity(0.15))
                        .help("Free: \(ByteFormat.string(storage.free))")
                }
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 18)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 16, alignment: .leading)],
                      alignment: .leading, spacing: 6) {
                ForEach(segments) { segment in
                    Button {
                        openSegment(segment)
                    } label: {
                        legendRow(segment.kind.color, segment.name, segment.bytes,
                                  clickable: segment.explorePath != nil || !(segment.roots ?? []).isEmpty)
                    }
                    .buttonStyle(.plain)
                    .help(tooltip(segment))
                }
                legendRow(Color.secondary.opacity(0.3), "Free", storage.free, clickable: false)
                    .help(storage.purgeable > 0
                          ? "Includes nothing purgeable. macOS can also free \(ByteFormat.string(storage.purgeable)) of purgeable space on its own."
                          : "Space not used by anything.")
            }
            .font(.callout)

            HStack {
                Group {
                    if let measuring = model.measuringStorage {
                        Text("Measuring \(measuring.name)…")
                    } else {
                        Text("Measured \(storage.measuredAt.formatted(.relative(presentation: .named))). Click a category to explore it.")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
                Spacer()
                if (model.trashBytes ?? 0) > 0 || model.fullDiskAccess != true {
                    Button(model.trashBytes.map { $0 > 0 ? "Empty Trash (\(ByteFormat.string($0)))…" : "Empty Trash…" } ?? "Empty Trash…") {
                        confirmEmptyTrash = true
                    }
                    .controlSize(.small)
                    .disabled(model.cleaning)
                }
            }
            .confirmationDialog(model.dryRun ? "Simulate emptying the Trash?" : "Permanently delete everything in the Trash?",
                                isPresented: $confirmEmptyTrash, titleVisibility: .visible) {
                Button(model.dryRun ? "Simulate" : "Empty Trash", role: model.dryRun ? nil : .destructive) { model.emptyTrash() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text(model.dryRun ? "Dry run is on: nothing will be deleted."
                     : "This can't be undone. Without Full Disk Access, Spacebar asks Finder to empty the Trash.")
            }
        }
    }

    /// A slice made of several folders opens them all together, so the total matches the bar.
    private func openSegment(_ segment: StorageSegment) {
        if let roots = segment.roots, roots.count > 1 {
            openGroup(segment.name, roots.map { URL(fileURLWithPath: $0) })
        } else if let path = segment.roots?.first ?? segment.explorePath {
            open(URL(fileURLWithPath: path))
        }
    }

    private func legendRow(_ color: Color, _ name: String, _ bytes: Int64, clickable: Bool) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 10, height: 10)
            Text(name)
            Spacer(minLength: 4)
            Text(ByteFormat.string(bytes)).monospacedDigit().foregroundStyle(.secondary)
            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.tertiary).opacity(clickable ? 1 : 0)
        }
        .contentShape(Rectangle())
    }

    private func tooltip(_ segment: StorageSegment) -> String {
        var lines = [segment.explanation]
        lines += segment.parts.map { "• \($0.name): \(ByteFormat.string($0.bytes))" }
        if model.fullDiskAccess != true && (segment.kind == .systemData || segment.kind == .trash) {
            lines.append("Without Full Disk Access, the Trash can't be measured, so what's in it is counted in System Data.")
        }
        return lines.joined(separator: "\n")
    }

    /// Shown until the first breakdown is measured.
    private func simpleBar(_ space: VolumeSpace) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                Rectangle().fill(Color.secondary.opacity(0.15))
                    .overlay(alignment: .leading) {
                        Rectangle().fill(Color.secondary.opacity(0.5))
                            .frame(width: geo.size.width * Double(space.used) / Double(max(space.total, 1)))
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .frame(height: 18)
            Text(model.measuringStorage == nil ? "Scan to see what's using your disk."
                 : "Measuring what's using your disk…")
                .font(.caption).foregroundStyle(.secondary)
        }
    }
}

extension StorageSegment.Kind {
    /// Categorical slots in fixed order (validated for color-vision deficiency, light and dark);
    /// macOS and System Data are neutral so system space doesn't read as a category of your own.
    var color: Color {
        switch self {
        case .macOS: return .dynamic(light: 0x8A8985, dark: 0x8F8E88)
        case .apps: return .dynamic(light: 0x2A78D6, dark: 0x3987E5)
        case .documents: return .dynamic(light: 0xEB6834, dark: 0xD95926)
        case .media: return .dynamic(light: 0x1BAF7A, dark: 0x199E70)
        case .developer: return .dynamic(light: 0xEDA100, dark: 0xC98500)
        case .appData: return .dynamic(light: 0xE87BA4, dark: 0xD55181)
        case .iCloud: return .dynamic(light: 0x008300, dark: 0x008300)
        case .mail: return .dynamic(light: 0x4A3AA7, dark: 0x9085E9)
        case .trash: return .dynamic(light: 0xE34948, dark: 0xE66767)
        case .shared: return .dynamic(light: 0x5D5C58, dark: 0xB8B7B0)
        case .systemData: return .dynamic(light: 0xC4C3BD, dark: 0x5B5A56)
        }
    }
}

extension Color {
    static func dynamic(light: UInt32, dark: UInt32) -> Color {
        func color(_ hex: UInt32) -> NSColor {
            NSColor(srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                    blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
        return Color(nsColor: NSColor(name: nil) { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? color(dark) : color(light)
        })
    }
}

private struct CategoryRow: View {
    @EnvironmentObject private var model: AppModel
    let category: CleanCategory
    let open: () -> Void

    var body: some View {
        let items = model.items(category.id)
        let selectable = items.filter(\.isSelectable)
        let selectedCount = model.selectedItems(category.id).count

        HStack(spacing: 12) {
            Button {
                // Anything selected → clear. Nothing selected → Spacebar's suggestions
                // (or everything, for review categories that have no suggestions).
                if selectedCount > 0 {
                    model.setSelected(false, items: items)
                } else if model.suggestedItems(category).isEmpty {
                    model.setSelected(true, items: items)
                } else {
                    model.selectSuggested(category)
                }
            } label: {
                Image(systemName: selectedCount == 0 ? "square"
                      : selectedCount == selectable.count ? "checkmark.square.fill" : "minus.square.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(selectedCount == 0 ? Color.secondary : Color.accentColor)
                    .frame(width: 22, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .disabled(selectable.isEmpty)
            .help(selectedCount > 0 ? "Deselect all" : "Select suggested items")
            Image(systemName: category.icon)
                .frame(width: 24)
                .foregroundStyle(Color.accentColor)
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(category.name).font(.body.weight(.medium))
                    if category.safety == .review { SafetyTag(safety: .review) }
                }
                Text(subtitle(items: items, selectedCount: selectedCount))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if model.scanning.contains(category.id) && model.results[category.id] == nil {
                ProgressView().controlSize(.small)
            } else {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(ByteFormat.string(model.total(category.id))).monospacedDigit()
                    if selectedCount > 0 && selectedCount < items.count {
                        Text("\(ByteFormat.string(model.selectedSize(category.id))) selected")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            Button(action: open) { Image(systemName: "chevron.right") }
                .buttonStyle(.borderless)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
        .onTapGesture(perform: open)
    }

    private func subtitle(items: [CleanItem], selectedCount: Int) -> String {
        if category.onDemand && model.results[category.id] == nil { return "Not scanned yet. Open to scan." }
        if category.needsFullDiskAccess && model.fullDiskAccess != true { return "Needs Full Disk Access" }
        if items.isEmpty { return "Nothing found" }
        return "\(items.count) item\(items.count == 1 ? "" : "s") · \(selectedCount) selected"
    }
}
