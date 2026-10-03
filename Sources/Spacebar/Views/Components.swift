import AppKit
import SpacebarCore
import SwiftUI

struct FileIcon: View {
    let url: URL
    var size: CGFloat = 20

    /// Looking icons up is slow enough to matter when a list re-renders on every size update.
    private static let cache = NSCache<NSString, NSImage>()

    @State private var photo: NSImage?

    var body: some View {
        if let identifier = PhotosLibrary.identifier(from: url) {
            // A Photos library photo: show its thumbnail.
            Group {
                if let photo {
                    Image(nsImage: photo).resizable().aspectRatio(contentMode: .fill)
                } else {
                    Image(systemName: "photo").foregroundStyle(.secondary)
                }
            }
            .frame(width: size, height: size)
            .clipShape(RoundedRectangle(cornerRadius: 3))
            .onAppear {
                PhotosLibrary.thumbnail(identifier, size: size) { image in
                    DispatchQueue.main.async { photo = image }
                }
            }
        } else {
            Image(nsImage: Self.icon(for: url))
                .resizable()
                .frame(width: size, height: size)
        }
    }

    private static func icon(for url: URL) -> NSImage {
        let key = url.path as NSString
        if let cached = cache.object(forKey: key) { return cached }
        let icon = NSWorkspace.shared.icon(forFile: url.path)
        cache.setObject(icon, forKey: key)
        return icon
    }
}

struct Banner<Actions: View>: View {
    let icon: String
    let tint: Color
    let title: String
    let message: String
    @ViewBuilder var actions: Actions

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(message).font(.callout).foregroundStyle(.secondary)
                HStack { actions }.padding(.top, 4)
            }
            Spacer(minLength: 0)
        }
        .padding(14)
        .background(tint.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(tint.opacity(0.25)))
    }
}

struct SafetyTag: View {
    let safety: Safety

    var body: some View {
        Text(safety == .safe ? "Safe to clean" : "Review first")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 7)
            .padding(.vertical, 2)
            .background((safety == .safe ? Color.green : Color.orange).opacity(0.15), in: Capsule())
            .foregroundStyle(safety == .safe ? Color.green : Color.orange)
    }
}

/// Confirmation shown before removing anything.
struct PendingClean: Identifiable {
    let id = UUID()
    let pairs: [(CleanItem, CleanCategory)]

    var size: Int64 { pairs.reduce(0) { $0 + $1.0.size } }
    var trashSize: Int64 { pairs.filter { $0.1.mode == .trash }.reduce(0) { $0 + $1.0.size } }
    var deleteSize: Int64 { size - trashSize }

    func title(dryRun: Bool) -> String {
        "\(dryRun ? "Simulate cleaning" : "Clean") \(pairs.count) item\(pairs.count == 1 ? "" : "s") (\(ByteFormat.string(size)))?"
    }

    func message(dryRun: Bool) -> String {
        var lines: [String] = []
        if dryRun { lines.append("Dry run is on: nothing will be deleted. Spacebar will only report and log what it would remove.") }
        if deleteSize > 0 { lines.append("\(ByteFormat.string(deleteSize)) of caches and logs will be deleted right away. Apps recreate them as needed.") }
        if trashSize > 0 { lines.append("\(ByteFormat.string(trashSize)) will be moved to the Trash, so you can still restore it.") }
        lines.append("Items owned by apps that are running are skipped.")
        return lines.joined(separator: "\n\n")
    }
}

extension View {
    func cleanConfirmation(_ pending: Binding<PendingClean?>, model: AppModel) -> some View {
        confirmationDialog(pending.wrappedValue?.title(dryRun: model.dryRun) ?? "",
                           isPresented: Binding(get: { pending.wrappedValue != nil }, set: { if !$0 { pending.wrappedValue = nil } }),
                           titleVisibility: .visible, presenting: pending.wrappedValue) { request in
            Button(model.dryRun ? "Simulate" : "Clean", role: model.dryRun ? nil : .destructive) {
                debugLog("confirmation dialog: confirm button pressed")
                model.clean(request.pairs)
            }
            Button("Cancel", role: .cancel) {}
        } message: { request in
            Text(request.message(dryRun: model.dryRun))
        }
    }
}

let shortDate: DateFormatter = {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .none
    return f
}()
