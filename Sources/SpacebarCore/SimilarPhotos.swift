import AppKit
import Foundation
import ImageIO
import Photos
import Vision

/// Near-duplicate photos: bursts and repeated shots, found with Vision's on-device image feature prints.
public enum SimilarImages {
    /// Feature-print distance below which two images count as near-duplicates. Measured on photos:
    /// re-saved copies 0.01–0.04, 5% crops 0.10–0.29, different photos 0.74 and up.
    public static let threshold: Float = 0.45
    /// Only photos taken this close together are compared, like a burst or a few tries of one shot.
    public static let window: TimeInterval = 60

    public struct Shot: Sendable {
        public let id: String
        public let name: String
        public let date: Date
        public let pixels: Int
        public let favorite: Bool
        public let bytes: Int64

        public init(id: String, name: String, date: Date, pixels: Int, favorite: Bool, bytes: Int64) {
            self.id = id
            self.name = name
            self.date = date
            self.pixels = pixels
            self.favorite = favorite
            self.bytes = bytes
        }
    }

    public static func featurePrint(_ image: CGImage) -> VNFeaturePrintObservation? {
        let request = VNGenerateImageFeaturePrintRequest()
        try? VNImageRequestHandler(cgImage: image).perform([request])
        return request.results?.first as? VNFeaturePrintObservation
    }

    public static func distance(_ a: VNFeaturePrintObservation, _ b: VNFeaturePrintObservation) -> Float {
        var value = Float.infinity
        try? a.computeDistance(&value, to: b)
        return value
    }

    /// Groups of similar shots. Shots are split into runs taken within `window` of each other;
    /// only those are analyzed (`print` is called lazily), then clustered by feature-print distance.
    public static func groups(_ shots: [Shot], cancel: CancelToken? = nil,
                              print: (Shot) -> VNFeaturePrintObservation?) -> [[Shot]] {
        let sorted = shots.sorted { $0.date < $1.date }
        var runs: [[Shot]] = []
        for shot in sorted {
            if let last = runs.last?.last, shot.date.timeIntervalSince(last.date) <= window {
                runs[runs.count - 1].append(shot)
            } else {
                runs.append([shot])
            }
        }
        var result: [[Shot]] = []
        for run in runs where run.count > 1 {
            if cancel?.isCancelled == true { break }
            // Each cluster is compared against its first shot.
            var clusters: [(print: VNFeaturePrintObservation, shots: [Shot])] = []
            for shot in run {
                guard let observation = print(shot) else { continue }
                if let index = clusters.firstIndex(where: { distance($0.print, observation) < threshold }) {
                    clusters[index].shots.append(shot)
                } else {
                    clusters.append((observation, [shot]))
                }
            }
            result += clusters.map(\.shots).filter { $0.count > 1 }
        }
        return result
    }

    /// The shot to keep: a favorite, then the highest resolution, then the largest file.
    public static func keeper(_ group: [Shot]) -> Shot {
        group.max { a, b in
            (a.favorite ? 1 : 0, a.pixels, a.bytes) < (b.favorite ? 1 : 0, b.pixels, b.bytes)
        }!
    }

    // MARK: Image files

    /// Capture date from the image's metadata (EXIF), or nil.
    public static func captureDate(_ url: URL) -> Date? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
              let exif = properties[kCGImagePropertyExifDictionary] as? [CFString: Any],
              let text = exif[kCGImagePropertyExifDateTimeOriginal] as? String else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy:MM:dd HH:mm:ss"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter.date(from: text)
    }

    public static func thumbnail(_ url: URL, maxPixels: Int = 512) -> CGImage? {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        let options: [CFString: Any] = [kCGImageSourceCreateThumbnailFromImageAlways: true,
                                        kCGImageSourceThumbnailMaxPixelSize: maxPixels,
                                        kCGImageSourceCreateThumbnailWithTransform: true]
        return CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
    }

    static func pixelCount(_ url: URL) -> Int {
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
              let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] else { return 0 }
        return ((properties[kCGImagePropertyPixelWidth] as? Int) ?? 0) * ((properties[kCGImagePropertyPixelHeight] as? Int) ?? 0)
    }

    static let imageTypes: Set<String> = ["jpg", "jpeg", "heic", "heif", "png", "tif", "tiff", "dng", "cr2", "cr3", "nef", "arw", "raf", "orf"]

    /// Similar image files (not in the Photos library) under `folders`.
    public static func fileGroups(in folders: [URL], cancel: CancelToken? = nil) -> [[Shot]] {
        var shots: [Shot] = []
        for folder in folders {
            guard let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: [.totalFileAllocatedSizeKey],
                                                             options: [.skipsHiddenFiles, .skipsPackageDescendants],
                                                             errorHandler: { _, _ in true }) else { continue }
            while let url = walker.nextObject() as? URL {
                if cancel?.isCancelled == true { return [] }
                guard imageTypes.contains(url.pathExtension.lowercased()), let date = captureDate(url) else { continue }
                let bytes = Int64((try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]).totalFileAllocatedSize) ?? 0)
                shots.append(Shot(id: url.path, name: url.lastPathComponent, date: date,
                                  pixels: pixelCount(url), favorite: false, bytes: bytes))
            }
        }
        return groups(shots, cancel: cancel) { shot in thumbnail(URL(fileURLWithPath: shot.id)).flatMap(featurePrint) }
    }
}

// MARK: - Photos library

public enum PhotosLibrary {
    public static var status: PHAuthorizationStatus { PHPhotoLibrary.authorizationStatus(for: .readWrite) }

    /// Asks for access if it hasn't been decided yet. Blocking: call off the main thread.
    public static func requestAccess() -> Bool {
        if status == .notDetermined {
            let done = DispatchSemaphore(value: 0)
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in done.signal() }
            done.wait()
        }
        return status == .authorized || status == .limited
    }

    public static func url(for identifier: String) -> URL {
        var components = URLComponents()
        components.scheme = "photos"
        components.host = "asset"
        components.queryItems = [URLQueryItem(name: "id", value: identifier)]
        return components.url!
    }

    public static func identifier(from url: URL) -> String? {
        guard url.scheme == "photos" else { return nil }
        return URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "id" }?.value
    }

    static func bytes(_ asset: PHAsset) -> Int64 {
        PHAssetResource.assetResources(for: asset).reduce(Int64(0)) { total, resource in
            total + ((resource.value(forKey: "fileSize") as? NSNumber)?.int64Value ?? 0)
        }
    }

    /// The file name of a library photo, for display.
    public static func displayName(_ identifier: String) -> String? {
        PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject.map(name)
    }

    static func name(_ asset: PHAsset) -> String {
        PHAssetResource.assetResources(for: asset).first?.originalFilename ?? "Photo"
    }

    /// Similar photos in the library. Uses only thumbnails already on this Mac (never downloads from iCloud).
    static func groups(cancel: CancelToken?) -> (groups: [[SimilarImages.Shot]], assets: [String: PHAsset]) {
        let options = PHFetchOptions()
        options.includeAllBurstAssets = true
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        let fetch = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [String: PHAsset] = [:]
        var shots: [SimilarImages.Shot] = []
        fetch.enumerateObjects { asset, _, _ in
            guard let date = asset.creationDate else { return }
            assets[asset.localIdentifier] = asset
            shots.append(SimilarImages.Shot(id: asset.localIdentifier, name: "", date: date,
                                            pixels: asset.pixelWidth * asset.pixelHeight, favorite: asset.isFavorite, bytes: 0))
        }
        let request = PHImageRequestOptions()
        request.isSynchronous = true
        request.deliveryMode = .highQualityFormat
        request.isNetworkAccessAllowed = false
        let manager = PHImageManager.default()
        let groups = SimilarImages.groups(shots, cancel: cancel) { shot in
            guard let asset = assets[shot.id] else { return nil }
            var image: NSImage?
            manager.requestImage(for: asset, targetSize: CGSize(width: 512, height: 512), contentMode: .aspectFit,
                                 options: request) { result, _ in image = result }
            return image?.cgImage(forProposedRect: nil, context: nil, hints: nil).flatMap(SimilarImages.featurePrint)
        }
        // Names and sizes only for the photos that matter.
        let named = groups.map { group in
            group.map { shot -> SimilarImages.Shot in
                guard let asset = assets[shot.id] else { return shot }
                return SimilarImages.Shot(id: shot.id, name: name(asset), date: shot.date, pixels: shot.pixels,
                                          favorite: shot.favorite, bytes: bytes(asset))
            }
        }
        return (named, assets)
    }

    /// Moves photos to Recently Deleted (macOS asks the user to confirm). Blocking.
    public static func delete(_ identifiers: [String]) throws {
        let assets = PHAsset.fetchAssets(withLocalIdentifiers: identifiers, options: nil)
        try PHPhotoLibrary.shared().performChangesAndWait {
            PHAssetChangeRequest.deleteAssets(assets)
        }
    }

    /// A thumbnail for a photo in the list.
    public static func thumbnail(_ identifier: String, size: CGFloat, completion: @escaping (NSImage?) -> Void) {
        guard let asset = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil).firstObject else {
            return completion(nil)
        }
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = false
        PHImageManager.default().requestImage(for: asset, targetSize: CGSize(width: size * 2, height: size * 2),
                                              contentMode: .aspectFill, options: options) { image, _ in completion(image) }
    }
}

// MARK: - Category

public extension CleanCategory {
    static let similarPhotos = CleanCategory(
        id: "photos", name: "Similar Photos", icon: "photo.on.rectangle.angled",
        summary: "Bursts and repeated shots: photos taken within a minute of each other that look nearly the same, found with on-device image analysis. In each group the favorite, or else the highest-resolution shot, is kept. Library photos go to Recently Deleted in Photos (30 days); image files go to the Trash. Photos stored only in iCloud aren't downloaded or analyzed.",
        safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: true, owners: []
    ) { context in
        var result: [Candidate] = []
        func add(_ groups: [[SimilarImages.Shot]], url: (SimilarImages.Shot) -> URL, kind: (SimilarImages.Shot) -> ItemKind) {
            for group in groups {
                let keep = SimilarImages.keeper(group)
                for shot in group where shot.id != keep.id {
                    let seconds = Int(abs(shot.date.timeIntervalSince(keep.date)).rounded())
                    result.append(Candidate(url: url(shot), name: shot.name, date: shot.date,
                                            detail: "Similar to \(keep.name) · \(seconds == 0 ? "same second" : "\(seconds) s apart")",
                                            knownSize: max(shot.bytes, 1), kind: kind(shot), duplicateOf: url(keep)))
                }
            }
        }
        if PhotosLibrary.requestAccess() {
            let library = PhotosLibrary.groups(cancel: context.cancel)
            add(library.groups, url: { PhotosLibrary.url(for: $0.id) }, kind: { .photoAsset(identifier: $0.id) })
        }
        let folders = ["Pictures", "Desktop", "Downloads"].map(context.path)
        add(SimilarImages.fileGroups(in: folders, cancel: context.cancel),
            url: { URL(fileURLWithPath: $0.id) }, kind: { _ in .file })
        return result
    }
}
