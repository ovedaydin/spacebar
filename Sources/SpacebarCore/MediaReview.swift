import Foundation
import Photos
import UniformTypeIdentifiers

/// The largest videos and photos, for reviewing one by one.
public enum MediaReview {
    public struct Item: Sendable, Identifiable, Hashable {
        public var id: URL { url }
        /// A file URL, or a photos:// URL for a Photos library item.
        public let url: URL
        public let name: String
        public let bytes: Int64
        public let date: Date?
        public let isVideo: Bool
        /// Where it is, for display ("~/Movies", "Photos library").
        public let place: String

        public var photoIdentifier: String? { PhotosLibrary.identifier(from: url) }
    }

    public static let minimumVideo: Int64 = 50_000_000
    public static let minimumPhoto: Int64 = 15_000_000
    /// Folders searched, relative to home. Packages (like the Photos library) aren't entered.
    public static let folders = ["Movies", "Desktop", "Downloads", "Pictures", "Documents"]

    /// Large media files in the usual folders, largest first. Hidden folders and packages are skipped.
    public static func files(home: URL = FileManager.default.homeDirectoryForCurrentUser, limit: Int = 300,
                             cancel: CancelToken? = nil) -> [Item] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .contentModificationDateKey,
                                         .contentTypeKey]
        var found: [Item] = []
        for folder in folders {
            let root = home.appendingPathComponent(folder)
            guard let walker = FileManager.default.enumerator(at: root, includingPropertiesForKeys: Array(keys),
                                                              options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                                              errorHandler: { _, _ in true }) else { continue }
            while let url = walker.nextObject() as? URL {
                if cancel?.isCancelled == true { return found }
                guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true,
                      let type = values.contentType, let size = values.totalFileAllocatedSize else { continue }
                let isVideo = type.conforms(to: .movie) || type.conforms(to: .video)
                let isPhoto = type.conforms(to: .image)
                guard (isVideo && Int64(size) >= minimumVideo) || (isPhoto && Int64(size) >= minimumPhoto) else { continue }
                let parent = url.deletingLastPathComponent().path.replacingOccurrences(of: home.path, with: "~")
                found.append(Item(url: url, name: url.lastPathComponent, bytes: Int64(size),
                                  date: values.contentModificationDate, isVideo: isVideo, place: parent))
            }
        }
        return Array(found.sorted { $0.bytes > $1.bytes }.prefix(limit))
    }

    /// Large videos in the Photos library, if Spacebar has access (it doesn't ask here).
    public static func libraryVideos(limit: Int = 100) -> [Item] {
        guard PhotosLibrary.status == .authorized || PhotosLibrary.status == .limited else { return [] }
        let assets = PHAsset.fetchAssets(with: .video, options: nil)
        var found: [Item] = []
        assets.enumerateObjects { asset, _, _ in
            let bytes = PhotosLibrary.bytes(asset)
            guard bytes >= minimumVideo else { return }
            found.append(Item(url: PhotosLibrary.url(for: asset.localIdentifier), name: PhotosLibrary.name(asset),
                              bytes: bytes, date: asset.creationDate, isVideo: true,
                              place: String(localized: "Photos library")))
        }
        return Array(found.sorted { $0.bytes > $1.bytes }.prefix(limit))
    }
}
