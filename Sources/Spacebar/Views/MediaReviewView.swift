import AppKit
import Quartz
import SpacebarCore
import SwiftUI

/// Your largest videos and photos, one at a time: Keep or Trash. Nothing is removed until you
/// confirm at the end.
struct MediaReviewView: View {
    @EnvironmentObject private var model: AppModel
    @State private var items: [MediaReview.Item] = []
    @State private var loading = false
    @State private var index: Int?
    @State private var toTrash: [MediaReview.Item] = []
    @State private var includeLibrary = PhotosLibrary.status == .authorized

    var body: some View {
        Group {
            if loading {
                ProgressView("Finding your largest videos and photos…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let index, items.indices.contains(index) {
                reviewing(items[index], at: index)
            } else if index != nil {
                finished
            } else {
                intro
            }
        }
        .navigationTitle("Media Review")
        .task { if items.isEmpty { await load() } }
    }

    @MainActor private func load() async {
        loading = true
        let library = includeLibrary
        let found = await Task.detached(priority: .userInitiated) { () -> [MediaReview.Item] in
            var all = MediaReview.files()
            if library { all += MediaReview.libraryVideos() }
            return all.sorted { $0.bytes > $1.bytes }
        }.value
        items = found.filter { !Exclusions.matches($0.url, model.exclusions) }
        loading = false
    }

    // MARK: Start

    private var intro: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("\(items.count) videos and photos, \(ByteFormat.string(items.reduce(0) { $0 + $1.bytes }))")
                .font(.title2.weight(.semibold))
            Text("Your largest media in Movies, Pictures, Documents, Downloads and on the Desktop: videos over 50 MB and photos over 15 MB. See each one and decide: Keep or Trash. Nothing is removed until you confirm at the end.")
                .foregroundStyle(.secondary)
            Toggle("Include videos in the Photos library", isOn: $includeLibrary)
                .onChange(of: includeLibrary) { on in
                    Task {
                        if on { _ = await Task.detached { PhotosLibrary.requestAccess() }.value }
                        await load()
                    }
                }
            HStack {
                Button("Start Review") { toTrash = []; index = 0 }
                    .keyboardShortcut(.defaultAction)
                    .disabled(items.isEmpty)
                Button("Find Again") { Task { await load() } }
            }
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(items.prefix(50).enumerated()), id: \.element.id) { offset, item in
                        HStack {
                            Image(systemName: item.isVideo ? "film" : "photo").foregroundStyle(.secondary).frame(width: 20)
                            Text(item.name).lineLimit(1)
                            Text(item.place).foregroundStyle(.secondary).lineLimit(1).truncationMode(.middle)
                            Spacer()
                            Text(ByteFormat.string(item.bytes)).monospacedDigit().foregroundStyle(.secondary)
                        }
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(offset.isMultiple(of: 2) ? Color.clear : Color.secondary.opacity(0.06))
                    }
                }
            }
            .background(Color(nsColor: .controlBackgroundColor), in: RoundedRectangle(cornerRadius: 8))
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    // MARK: One at a time

    private func reviewing(_ item: MediaReview.Item, at position: Int) -> some View {
        VStack(spacing: 12) {
            HStack {
                Text("\(position + 1) of \(items.count)").foregroundStyle(.secondary).monospacedDigit()
                Spacer()
                Text("To the Trash: \(toTrash.count) · \(ByteFormat.string(toTrash.reduce(0) { $0 + $1.bytes }))")
                    .foregroundStyle(.secondary).monospacedDigit()
                Button("Finish") { index = items.count }
            }
            MediaPreview(item: item)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.85), in: RoundedRectangle(cornerRadius: 10))
            VStack(spacing: 2) {
                Text(item.name).font(.headline).lineLimit(1)
                Text("\(ByteFormat.string(item.bytes)) · \(item.place)\(item.date.map { " · " + $0.formatted(date: .abbreviated, time: .omitted) } ?? "")")
                    .foregroundStyle(.secondary).lineLimit(1)
            }
            HStack(spacing: 12) {
                Button { back() } label: { Label("Back", systemImage: "arrow.uturn.backward") }
                    .keyboardShortcut(.leftArrow, modifiers: [])
                    .disabled(position == 0)
                Spacer()
                Button { decide(item, trash: true) } label: {
                    Label("Trash", systemImage: "trash").frame(minWidth: 110)
                }
                .keyboardShortcut(.delete, modifiers: [])
                .help("Delete key")
                Button { decide(item, trash: false) } label: {
                    Label("Keep", systemImage: "checkmark").frame(minWidth: 110)
                }
                .keyboardShortcut(.rightArrow, modifiers: [])
                .buttonStyle(.borderedProminent)
                .help("Right arrow")
            }
            .controlSize(.large)
        }
        .padding(20)
    }

    private func decide(_ item: MediaReview.Item, trash: Bool) {
        toTrash.removeAll { $0.id == item.id }
        if trash { toTrash.append(item) }
        index = (index ?? 0) + 1
    }

    private func back() {
        guard let index, index > 0 else { return }
        self.index = index - 1
    }

    // MARK: Confirm

    private var finished: some View {
        VStack(spacing: 14) {
            Image(systemName: toTrash.isEmpty ? "checkmark.circle" : "trash.circle").font(.system(size: 44)).foregroundStyle(.secondary)
            if toTrash.isEmpty {
                Text("Nothing marked for the Trash").font(.title3.weight(.semibold))
            } else {
                Text("Move \(toTrash.count) items (\(ByteFormat.string(toTrash.reduce(0) { $0 + $1.bytes }))) to the Trash?")
                    .font(.title3.weight(.semibold))
                Text("Files go to the Trash and library videos to Recently Deleted in Photos, so you can still get them back. They're also listed in History.")
                    .foregroundStyle(.secondary).multilineTextAlignment(.center).frame(maxWidth: 420)
            }
            HStack {
                Button("Review Again") { index = 0 }
                if !toTrash.isEmpty {
                    Button(model.dryRun ? "Simulate" : "Move to Trash") {
                        model.trashMedia(toTrash)
                        let removed = Set(toTrash.map(\.id))
                        items.removeAll { removed.contains($0.id) }
                        toTrash = []
                        index = nil
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(model.cleaning)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Quick Look for files (videos play); a large thumbnail for Photos library items.
private struct MediaPreview: View {
    let item: MediaReview.Item
    @State private var thumbnail: NSImage?

    var body: some View {
        if let identifier = item.photoIdentifier {
            Group {
                if let thumbnail { Image(nsImage: thumbnail).resizable().scaledToFit() } else { ProgressView() }
            }
            .task(id: identifier) {
                thumbnail = nil
                PhotosLibrary.thumbnail(identifier, size: 1200) { image in
                    DispatchQueue.main.async { thumbnail = image }
                }
            }
        } else {
            QuickLookPreview(url: item.url)
        }
    }
}

private struct QuickLookPreview: NSViewRepresentable {
    let url: URL

    func makeNSView(context: Context) -> QLPreviewView {
        let view = QLPreviewView(frame: .zero, style: .normal)!
        view.autostarts = false // no surprise sound: videos play when asked
        return view
    }

    func updateNSView(_ view: QLPreviewView, context: Context) {
        if (view.previewItem as? URL) != url { view.previewItem = url as NSURL }
    }
}
