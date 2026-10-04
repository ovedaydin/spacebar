@testable import SpacebarCore
import XCTest

final class CleanupRuleTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("rules-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    /// Rules compare against the later of "modified" and "added to its folder"; files made by the
    /// test were added just now, so the tests look from 60 days in the future.
    private let now = Date().addingTimeInterval(60 * 86400)

    /// Creates a file (or folder) dated `daysOld` before `now`, and dates its new parent folders the same.
    @discardableResult
    private func make(_ path: String, daysOld: Double, folder: Bool = false) throws -> URL {
        let url = root.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: folder ? url : url.deletingLastPathComponent(), withIntermediateDirectories: true)
        if !folder { try Data(repeating: 1, count: 5000).write(to: url) }
        let date = now.addingTimeInterval(-daysOld * 86400)
        var current = url
        while current.path.count > root.path.count {
            let existing = (try? FileManager.default.attributesOfItem(atPath: current.path)[.modificationDate] as? Date) ?? .distantPast
            // A folder keeps the date of its newest content.
            if current == url || existing < date || existing > Date().addingTimeInterval(-60) {
                try FileManager.default.setAttributes([.modificationDate: max(date, current == url ? date : min(existing, date))],
                                                      ofItemAtPath: current.path)
            }
            current = current.deletingLastPathComponent()
        }
        return url
    }

    func testPatternsAreCaseInsensitiveWildcards() {
        XCTAssertTrue(CleanupRules.matches("Installer.DMG", ["*.dmg"]))
        XCTAssertTrue(CleanupRules.matches("Screenshot 2026-01-01 at 10.00.png", ["Screen Shot*", "screenshot*"]))
        XCTAssertFalse(CleanupRules.matches("notes.dmg.txt", ["*.dmg"]))
        XCTAssertFalse(CleanupRules.matches("anything", ["", "  "]))
    }

    func testFindsOnlyOldMatchesWithinDepth() throws {
        try make("old.dmg", daysOld: 40)
        try make("new.dmg", daysOld: 2)
        try make("old.txt", daysOld: 40)
        try make("sub/deep.dmg", daysOld: 40)
        let rule = CleanupRule(name: "t", folder: root.path, patterns: ["*.dmg"], olderThanDays: 30)
        var names = Set(CleanupRules.find(rule, engine: BulkScanner(), cancel: nil, now: now).map(\.url.lastPathComponent))
        XCTAssertEqual(names, ["old.dmg"])

        var deeper = rule
        deeper.depth = 2
        names = Set(CleanupRules.find(deeper, engine: BulkScanner(), cancel: nil, now: now).map(\.url.lastPathComponent))
        XCTAssertEqual(names, ["old.dmg", "deep.dmg"])
    }

    func testMatchingFolderIsOneItemAgedByItsNewestFile() throws {
        try make("idle/node_modules/a/index.js", daysOld: 120)
        try make("busy/node_modules/b/index.js", daysOld: 120)
        try make("busy/node_modules/b/fresh.js", daysOld: 1)
        let rule = CleanupRule(name: "t", folder: root.path, patterns: ["node_modules"], olderThanDays: 90, depth: 3)
        let found = CleanupRules.find(rule, engine: BulkScanner(), cancel: nil, now: now)
        XCTAssertEqual(found.map { $0.url.deletingLastPathComponent().lastPathComponent }, ["idle"])
        XCTAssertEqual(found.first?.suggested, true)
        XCTAssertGreaterThan(found.first?.knownSize ?? 0, 0)
    }

    func testRulesThatMatchEverythingAreRefused() {
        var rule = CleanupRule(name: "All", folder: root.path, patterns: ["*"], olderThanDays: 30)
        XCTAssertNotNil(rule.problem)
        rule.patterns = ["*.*"]
        XCTAssertNotNil(rule.problem)
        rule.patterns = ["*.dmg"]
        XCTAssertNil(rule.problem)
        rule.folder = "/no/such/folder"
        XCTAssertNotNil(rule.problem)
    }

    func testCategoryIDIsStableAndGrouped() {
        let rule = CleanupRule(name: "t", folder: "~/Downloads", patterns: ["*.zip"], olderThanDays: 30)
        let category = CleanCategory.rule(rule)
        XCTAssertEqual(category.id, rule.categoryID)
        XCTAssertEqual(category.group, .rules)
        XCTAssertEqual(category.mode, .trash)
        XCTAssertEqual(rule.folderURL.path, FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").path)
    }
}
