@testable import Spacebar
@testable import SpacebarCore
import XCTest

final class TreemapTests: XCTestCase {
    func testAreasAreProportionalAndInBounds() {
        let rect = CGRect(x: 0, y: 0, width: 800, height: 500)
        let values: [Double] = [500, 250, 100, 80, 40, 20, 10]
        let frames = squarify(values, in: rect)
        XCTAssertEqual(frames.count, values.count)
        let total = values.reduce(0, +)
        for (value, frame) in zip(values, frames) {
            XCTAssertEqual(frame.width * frame.height, value / total * rect.width * rect.height, accuracy: 0.5)
            XCTAssertTrue(rect.insetBy(dx: -0.01, dy: -0.01).contains(frame))
        }
        XCTAssertEqual(squarify([], in: rect).count, 0)
        XCTAssertEqual(squarify([0, 0], in: rect), [.zero, .zero])
    }
}

final class CleanerTests: XCTestCase {
    private let caches = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches")

    private func fixture(bytes: Int = 4096) throws -> CleanItem {
        let url = caches.appendingPathComponent("spacebar-tests-\(UUID().uuidString).bin")
        try Data(repeating: 3, count: bytes).write(to: url)
        return CleanItem(url: url, name: url.lastPathComponent, size: Int64(bytes), date: nil, detail: nil, owner: nil)
    }

    func testDryRunTouchesNothing() throws {
        let item = try fixture()
        defer { try? FileManager.default.removeItem(at: item.url) }
        let report = Cleaner.run([Cleaner.Request(item: item, mode: .permanent)], dryRun: true)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.url.path))
        XCTAssertEqual(report.deletedBytes, item.size)
        XCTAssertTrue(report.removed.isEmpty)
    }

    func testProtectedAndLockedItemsAreSkipped() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        var locked = CleanItem(url: caches.appendingPathComponent("x"), name: "x", size: 1, date: nil, detail: nil, owner: nil)
        locked.lockedReason = "Stored only on this Mac"
        let documents = CleanItem(url: home.appendingPathComponent("Documents"), name: "Documents", size: 1, date: nil, detail: nil, owner: nil)
        let report = Cleaner.run([Cleaner.Request(item: documents, mode: .trash), Cleaner.Request(item: locked, mode: .permanent)], dryRun: true)
        XCTAssertEqual(report.skipped.count, 2)
        XCTAssertEqual(report.deletedBytes + report.trashedBytes, 0)
    }

    func testTrashPutBackAndDeleteNow() throws {
        let item = try fixture()
        defer { try? FileManager.default.removeItem(at: item.url) }
        let trashed = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: false)
        guard let landed = trashed.trashedItems.first else { throw XCTSkip("no Trash available: \(trashed.skipped)") }
        XCTAssertFalse(FileManager.default.fileExists(atPath: item.url.path))
        XCTAssertEqual(landed.original, item.url)

        let back = Cleaner.putBack(trashed.trashedItems, dryRun: false)
        XCTAssertEqual(back.restoredItems.count, 1)
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.url.path))

        let again = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: false)
        FileManager.default.createFile(atPath: item.url.path, contents: Data("new".utf8))
        let blocked = Cleaner.putBack(again.trashedItems, dryRun: false)
        XCTAssertTrue(blocked.restoredItems.isEmpty, "never overwrites")
        XCTAssertEqual(try String(contentsOf: item.url, encoding: .utf8), "new")

        let deleted = Cleaner.deleteFromTrash(again.trashedItems.map { ($0.url, $0.bytes) }, dryRun: false)
        XCTAssertEqual(deleted.deletedBytes, item.size)
        XCTAssertFalse(FileManager.default.fileExists(atPath: again.trashedItems[0].url.path))
    }

    func testDeleteFromTrashRefusesEverythingElse() throws {
        let item = try fixture()
        defer { try? FileManager.default.removeItem(at: item.url) }
        let report = Cleaner.deleteFromTrash([(item.url, item.size)], dryRun: false)
        XCTAssertEqual(report.skipped.first?.reason, "Not in the Trash")
        XCTAssertTrue(FileManager.default.fileExists(atPath: item.url.path))
    }

    func testOverlapsAreRemoved() {
        let category = CleanCategory.appCaches
        func pair(_ path: String) -> (CleanItem, CleanCategory) {
            (CleanItem(url: URL(fileURLWithPath: path), name: path, size: 1, date: nil, detail: nil, owner: nil), category)
        }
        let kept = AppModel.withoutOverlaps([pair("/a/pip"), pair("/a/pip/http"), pair("/a/pip"), pair("/a/pipx")])
        XCTAssertEqual(kept.map { $0.0.url.path }, ["/a/pip", "/a/pipx"])
    }
}

final class FinderIntegrationTests: XCTestCase {
    func testLinksOnlyShowExistingFolders() throws {
        let base = FileManager.default.temporaryDirectory.appendingPathComponent("sb-links-\(UUID().uuidString)")
        let folder = base.appendingPathComponent("My Folder & ü #1")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: base) }
        let file = folder.appendingPathComponent("a.txt")
        try Data("x".utf8).write(to: file)

        // Round trip, including spaces and characters that need escaping.
        let link = try XCTUnwrap(FinderIntegration.showURL(for: folder))
        XCTAssertEqual(FinderIntegration.folder(from: link)?.path, folder.path)
        // A file shows the folder it's in.
        XCTAssertEqual(FinderIntegration.folder(from: try XCTUnwrap(FinderIntegration.showURL(for: file)))?.path, folder.path)

        for rejected in ["spacebar://clean?path=/tmp", "spacebar://show?path=relative/path", "spacebar://show",
                         "spacebar://show?path=/no/such/folder/\(UUID().uuidString)", "https://show?path=/tmp"] {
            XCTAssertNil(FinderIntegration.folder(from: try XCTUnwrap(URL(string: rejected))), rejected)
        }
    }
}
