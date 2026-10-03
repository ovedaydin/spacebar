@testable import SpacebarCore
import XCTest

final class SuggestionTests: XCTestCase {
    private func item(daysAgo: Double?, inUse: Bool = false, installed: Bool? = nil) -> CleanItem {
        var item = CleanItem(url: URL(fileURLWithPath: "/tmp/x"), name: "x", size: 1, date: nil, detail: nil, owner: nil)
        item.lastUsed = daysAgo.map { Date(timeIntervalSinceNow: -$0 * 86400) }
        item.inUse = inUse
        item.ownerInstalled = installed
        return item
    }

    func testAgeBasedCaches() {
        let caches = CleanCategory.appCaches
        XCTAssertTrue(Suggestion.isSuggested(item(daysAgo: 40), in: caches, staleDays: 30))
        XCTAssertFalse(Suggestion.isSuggested(item(daysAgo: 10), in: caches, staleDays: 30))
        XCTAssertTrue(Suggestion.isSuggested(item(daysAgo: 10), in: caches, staleDays: 7))
        XCTAssertFalse(Suggestion.isSuggested(item(daysAgo: nil), in: caches), "unknown age is never suggested")
        XCTAssertTrue(Suggestion.isSuggested(item(daysAgo: 10, installed: false), in: caches, staleDays: 30), "orphans after 7 days")
        XCTAssertFalse(Suggestion.isSuggested(item(daysAgo: 400, inUse: true), in: caches), "running apps never")
    }

    func testReviewCategoriesNeedAnExplicitSuggestion() {
        var candidate = item(daysAgo: 400)
        XCTAssertFalse(Suggestion.isSuggested(candidate, in: .largeFiles))
        candidate.suggested = true
        XCTAssertTrue(Suggestion.isSuggested(candidate, in: .largeFiles))
        candidate.lockedReason = "Stored only on this Mac"
        XCTAssertFalse(Suggestion.isSuggested(candidate, in: .largeFiles), "locked beats suggested")
    }
}

final class StorageTests: XCTestCase {
    func testKinds() {
        let home = NSHomeDirectory()
        let expected: [String: StorageSegment.Kind] = [
            "/Users/Shared/Epic Games": .shared, "/System/Volumes/Data/Users/Shared/x": .shared,
            "\(home)/.Trash/a": .trash, "/Applications/Stats.app": .apps, "\(home)/Library/Developer/Xcode": .developer,
            "\(home)/.npm/_cacache": .developer, "\(home)/Library/Caches/pip": .appData, "\(home)/Library/Mail/V10": .mail,
            "\(home)/Documents/x.pdf": .documents, "\(home)/Pictures/Photos Library.photoslibrary": .media,
            "/Library/Developer/CoreSimulator": .developer, "/Library/Audio": .systemData, "/opt/homebrew": .developer,
        ]
        for (path, kind) in expected { XCTAssertEqual(StorageAnalyzer.kind(forPath: path), kind, path) }
    }

    func testTrashThenDeleteThenRestore() {
        var breakdown = StorageBreakdown(total: 100, free: 10, purgeable: 0,
                                         segments: [StorageSegment(kind: .shared, bytes: 60, explorePath: nil),
                                                    StorageSegment(kind: .systemData, bytes: 30, explorePath: nil)],
                                         measuredAt: Date(), complete: true, measuring: nil)
        breakdown.recordRemoval(path: "/Users/Shared/Game", bytes: 50, trashed: true)
        XCTAssertEqual(breakdown.segments.first { $0.kind == .shared }?.bytes, 10)
        XCTAssertEqual(breakdown.segments.first { $0.kind == .trash }?.bytes, 50)
        XCTAssertEqual(breakdown.free, 10, "trashing frees nothing")
        breakdown.recordRestore(path: "/Users/Shared/Game", bytes: 20)
        XCTAssertEqual(breakdown.segments.first { $0.kind == .shared }?.bytes, 30)
        XCTAssertEqual(breakdown.segments.first { $0.kind == .trash }?.bytes, 30)
        breakdown.recordRemoval(path: NSHomeDirectory() + "/.Trash/Game", bytes: 30, trashed: false)
        XCTAssertEqual(breakdown.segments.first { $0.kind == .trash }?.bytes, 0)
        XCTAssertEqual(breakdown.free, 40)
    }
}

final class DockerTests: XCTestCase {
    func testParseSizes() {
        XCTAssertEqual(DockerCLI.parseSize("1.2GB"), 1_200_000_000)
        XCTAssertEqual(DockerCLI.parseSize("512.5MB"), 512_500_000)
        XCTAssertEqual(DockerCLI.parseSize("3.5kB"), 3_500)
        XCTAssertEqual(DockerCLI.parseSize("0B"), 0)
        XCTAssertEqual(DockerCLI.parseSize("garbage"), 0)
    }

    func testParseSystemDF() {
        let output = """
        {"Active":"2","Reclaimable":"4.5GB (60%)","Size":"7.5GB","TotalCount":"9","Type":"Images"}
        {"Active":"1","Reclaimable":"0B (0%)","Size":"10MB","TotalCount":"1","Type":"Containers"}
        {"Active":"0","Reclaimable":"1.2GB","Size":"1.2GB","TotalCount":"40","Type":"Build Cache"}
        not json
        """
        let usage = DockerCLI.parseSystemDF(output)
        XCTAssertEqual(usage.count, 3)
        XCTAssertEqual(usage.first { $0.type == "Images" }, DockerCLI.Usage(type: "Images", reclaimable: 4_500_000_000, total: 9, active: 2))
        XCTAssertEqual(usage.first { $0.type == "Build Cache" }?.reclaimable, 1_200_000_000)
    }
}

final class LeftoverTests: XCTestCase {
    func testOrphanMatching() {
        let index = InstalledAppsIndex(apps: [
            .init(url: URL(fileURLWithPath: "/Applications/Google Chrome.app"), bundleID: "com.google.Chrome", name: "Google Chrome"),
            .init(url: URL(fileURLWithPath: "/Applications/Visual Studio Code.app"), bundleID: "com.microsoft.VSCode", name: "Code"),
        ])
        XCTAssertFalse(index.isOrphan("com.google.Chrome"))
        XCTAssertFalse(index.isOrphan("com.google.Keystone"), "same vendor counts as installed")
        XCTAssertFalse(index.isOrphan("com.microsoft.VSCode.ShipIt"), "helper of an installed app")
        XCTAssertTrue(index.isOrphan("com.example.gone"))
        XCTAssertTrue(index.isOrphan("com.example.gone.savedState"))
        XCTAssertFalse(index.isOrphan("com.apple.Notes"), "Apple is never an orphan")
        XCTAssertFalse(index.isOrphan("Google"), "matched by name")
        XCTAssertTrue(index.isOrphan("Firaxis Games"))
        XCTAssertFalse(index.isOrphan("Caches"), "generic system name")
        XCTAssertEqual(index.appMatching(fileName: "googlechrome-universal.dmg"), "Google Chrome")
        XCTAssertNil(index.appMatching(fileName: "report.dmg"))
    }
}

final class DuplicateTests: XCTestCase {
    func testFindsCopiesButNotBuildOutputOrRepoFiles() throws {
        let fixture = try Fixture("spacebar-home")
        let original = try fixture.file("Documents/photo.jpg", bytes: 200_000, byte: 1)
        try fixture.file("Downloads/photo (1).jpg", bytes: 200_000, byte: 1)
        try fixture.file("Documents/other.jpg", bytes: 200_000, byte: 2)          // same size, other content
        try fixture.file("project/node_modules/photo.jpg", bytes: 200_000, byte: 1) // build output: skipped
        _ = try fixture.folder("repo/.git")
        try fixture.file("repo/assets/photo.jpg", bytes: 200_000, byte: 1)        // inside a git repo: never offered

        let groups = DuplicateFinder.find(home: fixture.root, minSize: 100_000, cancel: nil)
        XCTAssertEqual(groups.count, 1)
        let group = try XCTUnwrap(groups.first)
        XCTAssertEqual(group.keep.url.resolvingSymlinksInPath(), original.resolvingSymlinksInPath(), "keeps the copy outside Downloads")
        XCTAssertEqual(group.copies.map { $0.url.lastPathComponent }, ["photo (1).jpg"])
    }

    func testClonesFreeNothing() throws {
        let fixture = try Fixture()
        let original = try fixture.file("a.bin", bytes: 1 << 20)
        let clone = fixture.root.appendingPathComponent("b.bin")
        guard clonefile(original.path, clone.path, 0) == 0 else { throw XCTSkip("no clone support") }
        let copy = try fixture.file("c.bin", bytes: 1 << 20)
        XCTAssertLessThan(DuplicateFinder.reclaimableBytes(clone.path, allocated: 1 << 20), 64 * 1024)
        XCTAssertEqual(DuplicateFinder.reclaimableBytes(copy.path, allocated: 1 << 20), 1 << 20)
    }
}

final class HistoryTests: XCTestCase {
    private let day: TimeInterval = 86400

    func testRecordKeepsOnePerInterval() {
        var history = StorageHistory()
        let start = Date(timeIntervalSince1970: 1_000_000)
        history.record(["/a": 1], at: start)
        history.record(["/a": 2], at: start.addingTimeInterval(3600))      // within 6 h: replaces
        history.record(["/a": 3], at: start.addingTimeInterval(7 * 3600))  // new entry
        XCTAssertEqual(history.entries.map { $0.folders["/a"] }, [2, 3])
        history.record([:], at: start.addingTimeInterval(20 * 3600))       // empty: ignored
        XCTAssertEqual(history.entries.count, 2)
    }

    func testGrowthAgainstAWeekAgo() {
        var history = StorageHistory()
        let now = Date()
        history.record(["/lib": 10_000_000_000, "/docs": 5_000_000_000], at: now.addingTimeInterval(-10 * day))
        history.record(["/lib": 12_000_000_000, "/docs": 5_000_000_000], at: now.addingTimeInterval(-8 * day))
        history.record(["/lib": 20_000_000_000, "/docs": 5_100_000_000, "/new": 900_000_000], at: now)
        let growth = try? XCTUnwrap(history.growth(now: now))
        XCTAssertEqual(growth?.since, history.entries[1].date, "newest entry at least a week old")
        XCTAssertEqual(growth?.items.map(\.path), ["/lib", "/new"], "docs grew under the threshold")
        XCTAssertEqual(growth?.items.first?.delta, 8_000_000_000)
        XCTAssertEqual(growth?.items.last?.isNew, true)
    }

    func testNeedsAnOlderMeasurement() {
        var history = StorageHistory()
        let now = Date()
        history.record(["/a": 1], at: now)
        XCTAssertNil(history.growth(now: now), "a single measurement can't show growth")
        history = StorageHistory()
        history.record(["/a": 1], at: now.addingTimeInterval(-2 * 3600))
        history.record(["/a": 900_000_000], at: now)
        XCTAssertNil(history.growth(now: now), "baseline must be at least 12 hours old")
        history = StorageHistory()
        history.record(["/a": 1], at: now.addingTimeInterval(-2 * day))
        history.record(["/a": 900_000_000], at: now)
        XCTAssertEqual(history.growth(now: now)?.items.first?.delta, 899_999_999, "falls back to the oldest entry")
    }
}

final class ExclusionTests: XCTestCase {
    func testMatching() {
        let excluded = ["/a/pip", "docker://build-cache"]
        XCTAssertTrue(Exclusions.matches(URL(fileURLWithPath: "/a/pip"), excluded))
        XCTAssertTrue(Exclusions.matches(URL(fileURLWithPath: "/a/pip/http/x"), excluded), "contents too")
        XCTAssertFalse(Exclusions.matches(URL(fileURLWithPath: "/a/pipx"), excluded), "not a sibling with the same prefix")
        XCTAssertTrue(Exclusions.matches(URL(string: "docker://build-cache")!, excluded))
        XCTAssertFalse(Exclusions.matches(URL(string: "docker://images")!, excluded))
    }

    func testScanLeavesOutExcludedFolders() {
        let logs = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Logs").path
        let context = ScanContext(engine: BulkScanner(), runningApps: [], fullDiskAccess: false, excluded: [logs])
        XCTAssertTrue(CleanCategory.logs.scan(context).isEmpty)
    }
}
