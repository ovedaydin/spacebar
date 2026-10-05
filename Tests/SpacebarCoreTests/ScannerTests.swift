import Darwin
@testable import SpacebarCore
import XCTest

final class ScannerTests: XCTestCase {
    func testMatchesDuWithHardLinksAndSymlinks() throws {
        let fixture = try Fixture()
        let big = try fixture.file("a/big.bin", bytes: 1 << 20)
        try fixture.file("a/b/small.bin", bytes: 300_000)
        try fixture.file("c/d/e/deep.bin", bytes: 50_000)
        try FileManager.default.linkItem(at: big, to: fixture.root.appendingPathComponent("hardlink.bin"))
        let outside = try Fixture("spacebar-outside")
        let target = try outside.file("target.bin", bytes: 2 << 20)
        try FileManager.default.createSymbolicLink(at: fixture.root.appendingPathComponent("link"), withDestinationURL: target)

        let bulk = BulkScanner().measure(fixture.root)
        XCTAssertEqual(bulk.allocated, Fixture.du(fixture.root), "same as du (hard link once, symlink not followed)")
        XCTAssertEqual(bulk.files, 4, "hard link is still a file entry")
        XCTAssertEqual(FileManagerScanner().measure(fixture.root).allocated, bulk.allocated)
    }

    func testTreeTotalsMatchSeparateScans() throws {
        let fixture = try Fixture()
        try fixture.file("x/1.bin", bytes: 100_000)
        try fixture.file("x/y/2.bin", bytes: 200_000)
        try fixture.file("z/3.bin", bytes: 300_000)
        let scanner = BulkScanner()
        let tree = scanner.measureTree(fixture.root, depth: 2)
        for folder in ["x", "x/y", "z"] {
            let url = fixture.root.appendingPathComponent(folder)
            XCTAssertEqual(tree[url.path]?.allocated, scanner.measure(url).allocated, folder)
        }
        XCTAssertEqual(tree[fixture.root.path]?.allocated, scanner.measure(fixture.root).allocated)
    }

    func testPureClonesCountOnce() throws {
        let fixture = try Fixture()
        let original = try fixture.file("original.bin", bytes: 4 << 20)
        let alone = BulkScanner().measure(fixture.root).allocated
        let clone = fixture.root.appendingPathComponent("clone.bin")
        guard clonefile(original.path, clone.path, 0) == 0 else { throw XCTSkip("volume doesn't support clones") }
        XCTAssertEqual(BulkScanner().measure(fixture.root).allocated, alone, "a pure clone adds no space")
        XCTAssertEqual(FileManagerScanner().measure(fixture.root).allocated, alone * 2, "baseline counts it twice")
    }

    func testNewestModification() throws {
        let fixture = try Fixture()
        let file = try fixture.file("old/f.bin", bytes: 10)
        let newer = try fixture.file("new/g.bin", bytes: 10)
        let past = Date(timeIntervalSinceNow: -400 * 86400)
        try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: file.path)
        try FileManager.default.setAttributes([.modificationDate: past], ofItemAtPath: file.deletingLastPathComponent().path)
        let oldFolder = BulkScanner().measure(file.deletingLastPathComponent())
        XCTAssertEqual(oldFolder.lastModified?.timeIntervalSince1970 ?? 0, past.timeIntervalSince1970, accuracy: 1)
        let whole = BulkScanner().measure(fixture.root)
        XCTAssertGreaterThan(whole.lastModified ?? .distantPast, past)
        _ = newer
    }
}

final class MeasurementMemoTests: XCTestCase {
    func testRemembersSubfoldersAndForgetsChangedOnes() throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("memo-\(UUID().uuidString)")
        let sub = root.appendingPathComponent("a/b")
        try FileManager.default.createDirectory(at: sub, withIntermediateDirectories: true)
        try Data(count: 100_000).write(to: sub.appendingPathComponent("f.bin"))
        defer { try? FileManager.default.removeItem(at: root); MeasurementMemo.shared.clear() }

        let scanner = BulkScanner(sharesMeasurements: true)
        let total = scanner.measureRemembering([root], depth: 3)[0]
        let resolved = root.resolvingSymlinksInPath().path
        let remembered = MeasurementMemo.shared.lookup(resolved + "/a/b") ?? MeasurementMemo.shared.lookup(sub.path)
        XCTAssertNotNil(remembered, "subfolder sizes are remembered")
        XCTAssertEqual(remembered?.allocated, total.allocated)

        // A change inside forgets the folder and everything above it, but not unrelated ones.
        MeasurementMemo.shared.store(["/elsewhere": total])
        MeasurementMemo.shared.invalidate([sub.path + "/new.bin", resolved + "/a/b/new.bin"])
        XCTAssertNil(MeasurementMemo.shared.lookup(sub.path))
        XCTAssertNil(MeasurementMemo.shared.lookup(resolved + "/a"))
        XCTAssertNotNil(MeasurementMemo.shared.lookup("/elsewhere"))
        XCTAssertNil(MeasurementMemo.shared.lookup("/elsewhere", now: Date().addingTimeInterval(MeasurementMemo.lifetime + 1)), "expires")
    }
}
