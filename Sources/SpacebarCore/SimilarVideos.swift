import AVFoundation
import Foundation
import Vision

/// The same clip saved twice (exported again, re-encoded, at another resolution): videos of the
/// same length whose frames at 20%, 50% and 80% look alike, using the same on-device image
/// fingerprints as Similar Photos.
enum SimilarVideos {
    struct Video {
        let url: URL
        let bytes: Int64
        let seconds: Double
        let pixels: Int
        let prints: [VNFeaturePrintObservation]
    }

    static let minimumBytes: Int64 = 20_000_000
    /// Average distance between the frames' fingerprints below which two videos count as the same.
    static let threshold: Float = 0.4

    static func groups(in folders: [URL], minimumBytes: Int64 = minimumBytes, cancel: CancelToken? = nil) -> [(keep: Video, copies: [Video])] {
        let files = videos(in: folders, minimumBytes: minimumBytes, cancel: cancel)
        // Only lengths that match are compared, so fingerprints are made for few videos.
        let byLength = Dictionary(grouping: files) { Int(($0.seconds / 1.5).rounded()) }
        var result: [(keep: Video, copies: [Video])] = []
        for (_, sameLength) in byLength where sameLength.count > 1 {
            if cancel?.isCancelled == true { break }
            let analyzed = sameLength.compactMap(analyze)
            var clusters: [[Video]] = []
            for video in analyzed {
                if let index = clusters.firstIndex(where: { similar($0[0], video) }) {
                    clusters[index].append(video)
                } else {
                    clusters.append([video])
                }
            }
            for cluster in clusters where cluster.count > 1 {
                // Keep the sharpest, then the largest file.
                let ranked = cluster.sorted { ($0.pixels, $0.bytes) > ($1.pixels, $1.bytes) }
                result.append((ranked[0], Array(ranked.dropFirst())))
            }
        }
        return result
    }

    /// Runs async AVFoundation loading from this background thread and waits for it.
    private static func wait<T>(_ work: @escaping @Sendable () async throws -> T) -> T? {
        let done = DispatchSemaphore(value: 0)
        let box = Box<T>()
        Task.detached {
            box.value = try? await work()
            done.signal()
        }
        done.wait()
        return box.value
    }

    private final class Box<T>: @unchecked Sendable { var value: T? }

    private static func videos(in folders: [URL], minimumBytes: Int64, cancel: CancelToken?) -> [(url: URL, bytes: Int64, seconds: Double)] {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey, .contentTypeKey]
        var found: [(url: URL, bytes: Int64, seconds: Double)] = []
        for folder in folders {
            guard let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: Array(keys),
                                                              options: [.skipsHiddenFiles, .skipsPackageDescendants]) else { continue }
            while let url = walker.nextObject() as? URL {
                if cancel?.isCancelled == true { return found }
                guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true,
                      values.contentType?.conforms(to: .movie) == true,
                      let size = values.totalFileAllocatedSize, Int64(size) >= minimumBytes else { continue }
                let asset = AVURLAsset(url: url)
                guard let duration = wait({ try await asset.load(.duration) }) else { continue }
                let seconds = CMTimeGetSeconds(duration)
                if seconds.isFinite, seconds >= 3 { found.append((url, Int64(size), seconds)) }
            }
        }
        return found
    }

    private static func analyze(_ file: (url: URL, bytes: Int64, seconds: Double)) -> Video? {
        let asset = AVURLAsset(url: file.url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.maximumSize = CGSize(width: 512, height: 512)
        generator.requestedTimeToleranceBefore = CMTime(seconds: 1, preferredTimescale: 600)
        generator.requestedTimeToleranceAfter = CMTime(seconds: 1, preferredTimescale: 600)
        let prints = [0.2, 0.5, 0.8].compactMap { fraction -> VNFeaturePrintObservation? in
            let time = CMTime(seconds: file.seconds * fraction, preferredTimescale: 600)
            guard let frame = wait({ try await generator.image(at: time).image }) else { return nil }
            return SimilarImages.featurePrint(frame)
        }
        guard prints.count == 3 else { return nil }
        let size: CGSize = wait({
            guard let track = try await asset.loadTracks(withMediaType: .video).first else { return CGSize.zero }
            let (natural, transform) = try await track.load(.naturalSize, .preferredTransform)
            return natural.applying(transform)
        }) ?? .zero
        return Video(url: file.url, bytes: file.bytes, seconds: file.seconds, pixels: Int(abs(size.width * size.height)), prints: prints)
    }

    static func similar(_ a: Video, _ b: Video) -> Bool {
        guard abs(a.seconds - b.seconds) <= 1.5 else { return false }
        let distances = zip(a.prints, b.prints).map { SimilarImages.distance($0, $1) }
        return distances.reduce(0, +) / Float(distances.count) < threshold
    }
}
