import AppKit
import SpacebarCore
import SwiftUI

/// Move big files you rarely open to an external drive, safely, and bring them back later.
struct OffloadView: View {
    @EnvironmentObject private var model: AppModel
    @State private var drives: [Drive] = []
    @State private var driveID: URL?
    @State private var chosen: [URL] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Move big files you rarely open, like old videos, finished projects and archives, to an external drive. Spacebar copies each one, checks the copy byte for byte, and only then moves the original to the Trash. Anything that doesn't check out stays where it was.")
                .foregroundStyle(.secondary)
                .frame(maxWidth: 640, alignment: .leading)

            if drives.isEmpty {
                Label("Connect an external drive to offload files to it.", systemImage: "externaldrive.badge.exclamationmark")
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    Picker("Drive", selection: $driveID) {
                        ForEach(drives) { drive in
                            Text("\(drive.name) (\(ByteFormat.string(drive.available)) free)").tag(Optional(drive.url))
                        }
                    }
                    .fixedSize()
                    Button("Choose Files…") { choose() }
                }
                if !chosen.isEmpty, let drive = drives.first(where: { $0.url == driveID }) {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(chosen, id: \.self) { url in
                            Text(abbreviated(url.path)).lineLimit(1).truncationMode(.middle).foregroundStyle(.secondary)
                        }
                    }
                    HStack {
                        Button(model.dryRun ? "Simulate Offload" : "Offload \(chosen.count) Items to \(drive.name)") {
                            model.offload(chosen, to: drive)
                            chosen = []
                        }
                        .keyboardShortcut(.defaultAction)
                        .disabled(model.offloadProgress != nil)
                        Button("Clear") { chosen = [] }
                    }
                }
            }
            if let progress = model.offloadProgress {
                ProgressView(value: Double(progress.done), total: Double(max(progress.total, 1))) {
                    Text("Copying and checking \(progress.current)…").lineLimit(1)
                }
                .frame(maxWidth: 480)
            }

            Divider()
            Text("Offloaded").font(.headline)
            if model.offloads.isEmpty {
                Text("Nothing yet.").foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(model.offloads) { record in row(record) }
                    }
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .navigationTitle("Offload")
        .onAppear(perform: refreshDrives)
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didMountNotification)) { _ in refreshDrives() }
        .onReceive(NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didUnmountNotification)) { _ in refreshDrives() }
    }

    private func row(_ record: Offload.Record) -> some View {
        let onDrive = FileManager.default.fileExists(atPath: record.destination)
        return HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(URL(fileURLWithPath: record.original).lastPathComponent).lineLimit(1)
                Text("From \(abbreviated(URL(fileURLWithPath: record.original).deletingLastPathComponent().path)) to \(record.drive) · \(record.date.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
            }
            Spacer()
            Text(ByteFormat.string(record.bytes)).monospacedDigit().foregroundStyle(.secondary)
            if record.broughtBack != nil {
                Text("Brought back").font(.caption).foregroundStyle(.secondary)
            } else if onDrive {
                Button("Show") { NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: record.destination)]) }
                Button("Bring Back") { model.bringBack(record) }
                    .disabled(model.offloadProgress != nil)
                    .help("Copies it back to where it was and checks the copy. The drive keeps its copy.")
            } else {
                Text("Connect \(record.drive)").font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    private func refreshDrives() {
        drives = model.offloadDrives
        if driveID == nil || !drives.contains(where: { $0.url == driveID }) { driveID = drives.first?.url }
    }

    private func choose() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        panel.directoryURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Movies")
        panel.prompt = String(localized: "Choose")
        panel.message = String(localized: "Choose files or folders to move to the drive.")
        if panel.runModal() == .OK { chosen = panel.urls }
    }

    private func abbreviated(_ path: String) -> String {
        let home = NSHomeDirectory()
        return path.hasPrefix(home + "/") ? "~" + path.dropFirst(home.count) : path
    }
}
