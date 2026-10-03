import AppKit
import ImageIO
@testable import SpacebarCore
import UniformTypeIdentifiers
import XCTest

final class SimilarPhotosTests: XCTestCase {
    /// A reproducible "photo": a gradient sky, ground and a few shapes, drawn from `seed`.
    private func scene(_ seed: UInt64, width: Int = 1200, height: Int = 900) -> CGImage {
        var state = seed
        func random() -> CGFloat {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return CGFloat((state >> 33) % 10_000) / 10_000
        }
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: 0,
                                space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let sky = CGGradient(colorsSpace: nil, colors: [CGColor(red: random(), green: random(), blue: 1, alpha: 1),
                                                        CGColor(red: 1, green: random(), blue: random(), alpha: 1)] as CFArray,
                             locations: nil)!
        context.drawLinearGradient(sky, start: .zero, end: CGPoint(x: 0, y: height), options: [])
        context.setFillColor(CGColor(red: random() * 0.5, green: random(), blue: random() * 0.3, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: Int(CGFloat(height) * (0.2 + random() * 0.3))))
        for _ in 0..<12 {
            context.setFillColor(CGColor(red: random(), green: random(), blue: random(), alpha: 1))
            let rect = CGRect(x: random() * CGFloat(width), y: random() * CGFloat(height),
                              width: 60 + random() * 300, height: 60 + random() * 300)
            if random() > 0.5 { context.fillEllipse(in: rect) } else { context.fill(rect) }
        }
        return context.makeImage()!
    }

    private func save(_ image: CGImage, to url: URL, taken: String?) throws {
        let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
        var properties: [CFString: Any] = [kCGImageDestinationLossyCompressionQuality: 0.8]
        if let taken { properties[kCGImagePropertyExifDictionary] = [kCGImagePropertyExifDateTimeOriginal: taken] }
        CGImageDestinationAddImage(destination, image, properties as CFDictionary)
        XCTAssertTrue(CGImageDestinationFinalize(destination))
    }

    func testDistancesSeparateSimilarFromDifferent() throws {
        let a = scene(1), b = scene(2)
        let crop = try XCTUnwrap(a.cropping(to: CGRect(x: 60, y: 45, width: 1080, height: 810)))
        let printA = try XCTUnwrap(SimilarImages.featurePrint(a))
        XCTAssertLessThan(SimilarImages.distance(printA, try XCTUnwrap(SimilarImages.featurePrint(crop))), SimilarImages.threshold)
        XCTAssertGreaterThan(SimilarImages.distance(printA, try XCTUnwrap(SimilarImages.featurePrint(b))), SimilarImages.threshold)
    }

    func testFileGroupsUseCaptureTimeAndSimilarity() throws {
        let fixture = try Fixture("spacebar-photos")
        let folder = try fixture.folder("Pictures")
        let a = scene(1)
        try save(a, to: folder.appendingPathComponent("IMG_0001.jpg"), taken: "2026:01:01 10:00:00")
        try save(a.cropping(to: CGRect(x: 60, y: 45, width: 1080, height: 810))!,
                 to: folder.appendingPathComponent("IMG_0002.jpg"), taken: "2026:01:01 10:00:05")
        try save(scene(2), to: folder.appendingPathComponent("IMG_0003.jpg"), taken: "2026:01:01 10:00:10")
        try save(a, to: folder.appendingPathComponent("IMG_0100.jpg"), taken: "2026:01:01 15:00:00")
        try save(a, to: folder.appendingPathComponent("no-date.jpg"), taken: nil)

        let groups = SimilarImages.fileGroups(in: [folder])
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(Set(groups[0].map(\.name)), ["IMG_0001.jpg", "IMG_0002.jpg"])
        XCTAssertEqual(SimilarImages.keeper(groups[0]).name, "IMG_0001.jpg", "keeps the full-resolution shot")
    }

    func testKeeperPrefersFavorites() {
        let date = Date()
        let big = SimilarImages.Shot(id: "1", name: "big", date: date, pixels: 4000, favorite: false, bytes: 10)
        let favorite = SimilarImages.Shot(id: "2", name: "fav", date: date, pixels: 1000, favorite: true, bytes: 5)
        XCTAssertEqual(SimilarImages.keeper([big, favorite]).name, "fav")
        XCTAssertEqual(SimilarImages.keeper([big, SimilarImages.Shot(id: "3", name: "small", date: date, pixels: 10, favorite: false, bytes: 1)]).name, "big")
    }

    func testPhotoURLsRoundTrip() {
        let identifier = "3A1B-77C2/L0/001"
        XCTAssertEqual(PhotosLibrary.identifier(from: PhotosLibrary.url(for: identifier)), identifier)
        XCTAssertNil(PhotosLibrary.identifier(from: URL(fileURLWithPath: "/tmp/x.jpg")))
    }
}
