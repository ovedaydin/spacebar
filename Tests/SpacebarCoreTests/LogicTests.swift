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

final class LiveUpdateTests: XCTestCase {
    func testOwningRoot() {
        let roots = ["/Users/a/Library/Caches/Google", "/Users/a/Library/Caches", "/Applications"]
        XCTAssertEqual(FileWatcher.owningRoot(of: "/Users/a/Library/Caches/Google/Chrome/x", in: roots), "/Users/a/Library/Caches/Google")
        XCTAssertEqual(FileWatcher.owningRoot(of: "/Users/a/Library/Caches/pip", in: roots), "/Users/a/Library/Caches")
        XCTAssertNil(FileWatcher.owningRoot(of: "/Users/a/Library/CachesX", in: roots))
    }

    func testUpdateKeepsTheBarAddingUp() {
        var breakdown = StorageBreakdown(total: 100, free: 20, purgeable: 0,
                                         segments: [StorageSegment(kind: .macOS, bytes: 10, explorePath: nil),
                                                    StorageSegment(kind: .apps, bytes: 30, explorePath: nil),
                                                    StorageSegment(kind: .systemData, bytes: 40, explorePath: nil)],
                                         measuredAt: Date(), complete: true, measuring: nil)
        breakdown.folderSizes = ["/Applications": 30]
        breakdown.update(folders: ["/Applications": 45], free: 5)
        XCTAssertEqual(breakdown.segments.first { $0.kind == .apps }?.bytes, 45)
        XCTAssertEqual(breakdown.segments.reduce(0) { $0 + $1.bytes } + breakdown.free, 100)
    }

    func testWatcherReportsChanges() throws {
        let fixture = try Fixture("spacebar-watch")
        let folder = try fixture.folder("watched/inner")
        let seen = expectation(description: "change reported")
        seen.assertForOverFulfill = false
        let watcher = FileWatcher(paths: [fixture.root.path], latency: 0.2) { paths, _ in
            if paths.contains(where: { $0.hasSuffix("watched/inner") }) { seen.fulfill() }
        }
        XCTAssertTrue(watcher.start())
        // The watcher ignores this process's own changes, so let another process write.
        let touch = Process()
        touch.executableURL = URL(fileURLWithPath: "/usr/bin/touch")
        touch.arguments = [folder.appendingPathComponent("new.txt").path]
        try touch.run()
        touch.waitUntilExit()
        wait(for: [seen], timeout: 10)
        watcher.stop()
    }
}

final class ToolsTests: XCTestCase {
    func testChildProcessesGetACleanEnvironment() throws {
        setenv("DEVELOPER_DIR", "/tmp/evil", 1)
        setenv("DYLD_INSERT_LIBRARIES", "/tmp/evil.dylib", 1)
        defer { unsetenv("DEVELOPER_DIR"); unsetenv("DYLD_INSERT_LIBRARIES") }
        let result = try XCTUnwrap(Tools.run("/usr/bin/env", []))
        let environment = String(decoding: result.output, as: UTF8.self)
        XCTAssertFalse(environment.contains("DEVELOPER_DIR"))
        XCTAssertFalse(environment.contains("DYLD_"))
        XCTAssertTrue(environment.contains("PATH=/usr/bin:/bin:/usr/sbin:/sbin"))
        XCTAssertNil(Tools.run("relative/tool", []), "relative paths are refused")
    }

    func testUnsignedToolsFailTheSignatureCheck() throws {
        let fixture = try Fixture()
        let fake = try fixture.file("docker", bytes: 0)
        try "#!/bin/sh\necho pwned\n".write(to: fake, atomically: true, encoding: .utf8)
        XCTAssertFalse(Tools.isTrusted(fake.path, requirement: "anchor apple generic"))
        XCTAssertTrue(Tools.isTrusted("/bin/ls", requirement: "anchor apple"))
        XCTAssertFalse(Tools.isTrusted("/bin/ls", requirement: DockerCLI.dockerRequirement), "Apple's ls isn't Docker's")
    }

    func testSimctlIsAppleSignedAndRootOwned() throws {
        guard FileManager.default.fileExists(atPath: "/Library/Developer/PrivateFrameworks/CoreSimulator.framework") else {
            throw XCTSkip("no CoreSimulator on this Mac")
        }
        let simctl = try XCTUnwrap(Tools.simctl)
        XCTAssertTrue(simctl.hasPrefix("/Library/Developer/PrivateFrameworks/"))
    }
}

final class SpaceForecastTests: XCTestCase {
    private let start = Date(timeIntervalSince1970: 1_800_000_000)

    func testSteadyGrowthForecastsDaysLeft() throws {
        var forecast = SpaceForecast()
        // 100 GB free, losing 2 GB a day, sampled every 6 hours for 10 days.
        for hour in stride(from: 0, through: 240, by: 6) {
            forecast.record(available: 100_000_000_000 - Int64(hour) * 2_000_000_000 / 24,
                            at: start.addingTimeInterval(Double(hour) * 3600))
        }
        let result = try XCTUnwrap(forecast.forecast(now: start.addingTimeInterval(240 * 3600)))
        XCTAssertEqual(result.bytesPerDay, 2_000_000_000, accuracy: 10_000_000)
        // 80 GB left minus a 2 GB reserve at 2 GB/day.
        XCTAssertEqual(result.days, 39, accuracy: 0.5)
    }

    func testOneBigCleanDoesntHideTheTrend() throws {
        var forecast = SpaceForecast()
        for hour in stride(from: 0, through: 240, by: 6) {
            var available = 100_000_000_000 - Int64(hour) * 2_000_000_000 / 24
            if hour >= 120 { available += 30_000_000_000 } // cleaned 30 GB on day 5
            forecast.record(available: available, at: start.addingTimeInterval(Double(hour) * 3600))
        }
        let result = try XCTUnwrap(forecast.forecast(now: start.addingTimeInterval(240 * 3600)))
        XCTAssertEqual(result.bytesPerDay, 2_000_000_000, accuracy: 300_000_000)
    }

    func testNoForecastWhenStableOrTooLittleData() {
        var forecast = SpaceForecast()
        for hour in stride(from: 0, through: 240, by: 6) {
            forecast.record(available: 100_000_000_000 + Int64(hour % 12) * 1_000_000, at: start.addingTimeInterval(Double(hour) * 3600))
        }
        XCTAssertNil(forecast.forecast(now: start.addingTimeInterval(240 * 3600)))
        var short = SpaceForecast()
        for hour in 0..<20 { short.record(available: 100_000_000_000 - Int64(hour) * 1_000_000_000, at: start.addingTimeInterval(Double(hour) * 3600)) }
        XCTAssertNil(short.forecast(now: start.addingTimeInterval(20 * 3600)), "needs at least 3 days")
    }
}

final class IncrementalScanTests: XCTestCase {
    private let home = "/Users/test"
    private func category(_ id: String) -> CleanCategory { CleanCategory.all.first { $0.id == id }! }

    func testOnlyRelevantChangesTriggerARescan() {
        let cacheChurn = ["/Users/test/Library/Caches/com.example", "/Users/test/.npm/_cacache"]
        XCTAssertFalse(category("large").isAffected(by: cacheChurn, home: home))
        XCTAssertFalse(category("forgotten").isAffected(by: cacheChurn, home: home))
        XCTAssertFalse(category("logs").isAffected(by: cacheChurn, home: home))
        XCTAssertTrue(category("caches").isAffected(by: cacheChurn, home: home), "categories without a map always rescan")

        XCTAssertTrue(category("large").isAffected(by: ["/Users/test/Documents/Video"], home: home))
        XCTAssertTrue(category("forgotten").isAffected(by: ["/Users/test/Downloads"], home: home))
        XCTAssertTrue(category("forgotten").isAffected(by: ["/Applications/Some.app"], home: home))
        XCTAssertFalse(category("logs").isAffected(by: ["/Users/test/Library/LogsArchive"], home: home), "prefix must be a folder")
        // Hidden folders (build output, git) are skipped by these scans, so their churn doesn't count.
        XCTAssertFalse(category("large").isAffected(by: ["/Users/test/Documents/app/.build/debug"], home: home))
        XCTAssertFalse(category("duplicates").isAffected(by: ["/Users/test/Documents/app/.git/objects"], home: home))
        XCTAssertTrue(category("projects").isAffected(by: ["/Users/test/Documents/app/.venv/lib"], home: home))
    }

    func testRulesWatchTheirFolder() {
        let rule = CleanupRule(name: "t", folder: "/Users/test/Downloads", patterns: ["*.dmg"], olderThanDays: 30)
        XCTAssertTrue(CleanCategory.rule(rule).isAffected(by: ["/Users/test/Downloads/sub"], home: home))
        XCTAssertFalse(CleanCategory.rule(rule).isAffected(by: ["/Users/test/Desktop"], home: home))
    }
}

final class TimeMachineTests: XCTestCase {
    func testLastBackupIsTheNewestSnapshotOfAnyDestination() throws {
        let old = Date(timeIntervalSince1970: 1_800_000_000), new = old.addingTimeInterval(86400)
        let plist: [String: Any] = ["Destinations": [["SnapshotDates": [old]], ["SnapshotDates": [old, new]]]]
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("tm-\(UUID().uuidString).plist")
        try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }
        XCTAssertEqual(TimeMachine.lastBackup(settings: url), new)

        let empty = FileManager.default.temporaryDirectory.appendingPathComponent("tm-\(UUID().uuidString).plist")
        try PropertyListSerialization.data(fromPropertyList: ["AutoBackup": false], format: .xml, options: 0).write(to: empty)
        defer { try? FileManager.default.removeItem(at: empty) }
        XCTAssertNil(TimeMachine.lastBackup(settings: empty), "not set up: no badge")
    }

    func testBackedUpOnlyWhenIncludedAndUnchangedSince() {
        let backup = Date(timeIntervalSince1970: 1_800_000_000)
        XCTAssertTrue(TimeMachine.isBackedUp(modified: backup.addingTimeInterval(-60), excluded: false, lastBackup: backup))
        XCTAssertFalse(TimeMachine.isBackedUp(modified: backup.addingTimeInterval(60), excluded: false, lastBackup: backup))
        XCTAssertFalse(TimeMachine.isBackedUp(modified: backup.addingTimeInterval(-60), excluded: true, lastBackup: backup))
        XCTAssertFalse(TimeMachine.isBackedUp(modified: backup.addingTimeInterval(-60), excluded: false, lastBackup: nil))
    }
}

final class SpaceTimelineTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_800_000_000)
    private let total: Int64 = 500_000_000_000

    func testThinsPointsAndFindsJumpsWithTheirFolders() {
        var samples: [SpaceForecast.Sample] = []
        for hour in 0...(30 * 24) {
            var available: Int64 = 200_000_000_000 - Int64(hour) * 10_000_000
            if hour >= 20 * 24 { available -= 20_000_000_000 } // a 20 GB download on day 20
            samples.append(.init(date: now.addingTimeInterval(Double(hour - 30 * 24) * 3600), available: available))
        }
        var history = StorageHistory()
        history.record(["~/Movies": 1_000_000_000], at: now.addingTimeInterval(-11 * 86400))
        history.record(["~/Movies": 21_000_000_000], at: now.addingTimeInterval(-9 * 86400))
        let timeline = SpaceTimeline.build(samples: samples, total: total, days: 30, now: now, history: history)
        XCTAssertLessThanOrEqual(timeline.points.count, 181)
        XCTAssertEqual(timeline.points.last?.used, total - samples.last!.available)
        let jumps = timeline.events.filter { $0.kind == .jump }
        XCTAssertEqual(jumps.count, 1)
        XCTAssertEqual(jumps.first?.delta ?? 0, 20_000_000_000, accuracy: 1_000_000_000)
        XCTAssertEqual(jumps.first?.folders.first?.path, "~/Movies")
    }

    func testCleansAreEventsAndExplainTheDrop() {
        var samples: [SpaceForecast.Sample] = []
        for hour in 0...48 {
            let available: Int64 = hour >= 24 ? 150_000_000_000 : 140_000_000_000
            samples.append(.init(date: now.addingTimeInterval(Double(hour - 48) * 3600), available: available))
        }
        let timeline = SpaceTimeline.build(samples: samples, total: total, days: 7, now: now,
                                           cleans: [(date: now.addingTimeInterval(-24 * 3600), freed: 10_000_000_000)])
        XCTAssertEqual(timeline.events.map(\.kind), [.clean], "the clean explains the drop; no separate jump")
    }
}

final class OffloadTests: XCTestCase {
    private var root: URL!

    override func setUpWithError() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("offload-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root.appendingPathComponent("drive"), withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: root.appendingPathComponent("project/sub"), withIntermediateDirectories: true)
        try Data((0..<3_000_000).map { UInt8($0 % 251) }).write(to: root.appendingPathComponent("project/video.mov"))
        try Data("notes".utf8).write(to: root.appendingPathComponent("project/sub/notes.txt"))
    }

    override func tearDownWithError() throws { try? FileManager.default.removeItem(at: root) }

    func testCopiesAndVerifiesFoldersAndFiles() throws {
        let copy = try Offload.copyAndVerify(root.appendingPathComponent("project"), into: root.appendingPathComponent("drive"))
        XCTAssertEqual(copy.lastPathComponent, "project")
        XCTAssertTrue(FileManager.default.fileExists(atPath: copy.appendingPathComponent("sub/notes.txt").path))
        // A second copy gets a new name instead of overwriting.
        let again = try Offload.copyAndVerify(root.appendingPathComponent("project/video.mov"), into: copy)
        XCTAssertEqual(again.lastPathComponent, "video 2.mov")
    }

    func testVerifyCatchesAnyDifference() throws {
        let original = root.appendingPathComponent("project")
        let copy = try Offload.copyAndVerify(original, into: root.appendingPathComponent("drive"))
        // One byte changed in the middle of a large file.
        let handle = try FileHandle(forWritingTo: copy.appendingPathComponent("video.mov"))
        try handle.seek(toOffset: 1_500_000)
        try handle.write(contentsOf: Data([0xFF]))
        try handle.close()
        XCTAssertThrowsError(try Offload.verify(original, copy))
        // A missing file.
        try FileManager.default.removeItem(at: copy.appendingPathComponent("video.mov"))
        XCTAssertThrowsError(try Offload.verify(original, copy))
    }

    func testRefusesTheSameDrive() {
        XCTAssertThrowsError(try Offload.check([(root.appendingPathComponent("project"), 10)], to: root.appendingPathComponent("drive"))) {
            XCTAssertEqual($0 as? Offload.Failure, .sameDrive)
        }
    }
}

final class NewestChangeTests: XCTestCase {
    func testAncestorsKnowTheNewestChangeBelowThem() {
        let newest = FileWatcher.newestChange(under: [("/Users/me/Movies/a", 10), ("/Users/me/Documents", 30), ("/Users/me/Movies", 20)])
        XCTAssertEqual(newest["/Users/me/Movies/a"], 10)
        XCTAssertEqual(newest["/Users/me/Movies"], 20)
        XCTAssertEqual(newest["/Users/me"], 30)
        XCTAssertEqual(newest["/"], 30)
        XCTAssertNil(newest["/Users/me/Pictures"], "untouched folders have no change")
    }
}

final class FolderGuideTests: XCTestCase {
    private func entry(_ match: [String], _ title: String, _ safety: FolderGuide.Safety = .regenerates) -> FolderGuide.Entry {
        FolderGuide.Entry(match: match, title: ["en": title], what: ["en": title], by: "x", safety: safety, category: nil)
    }

    func testMostSpecificEntryAndNearestParent() {
        let entries = [entry(["~/Library/Caches"], "Caches"), entry(["~/Library/Caches/*"], "An app's cache"),
                       entry(["~/Library/Caches/Homebrew"], "Homebrew"), entry(["*/node_modules"], "Packages"),
                       entry(["~/.gradle"], "Gradle")]
        let home = "/Users/me"
        func title(_ path: String) -> String? { FolderGuide.lookup(path, home: home, entries: entries).map { $0.entry.title["en"]! } }
        XCTAssertEqual(title("/Users/me/Library/Caches"), "Caches")
        XCTAssertEqual(title("/Users/me/Library/Caches/Homebrew"), "Homebrew", "exact beats wildcard")
        XCTAssertEqual(title("/Users/me/Library/Caches/com.example"), "An app's cache")
        XCTAssertEqual(title("/Users/me/Documents/app/node_modules"), "Packages")
        XCTAssertEqual(FolderGuide.lookup("/Users/me/.gradle/caches/8.1", home: home, entries: entries)?.inside, true)
        XCTAssertNil(title("/Users/me/Documents/Taxes"))
        XCTAssertEqual(title("/System/Volumes/Data/Users/me/.gradle"), "Gradle")
    }
}

final class ShippedGuideTests: XCTestCase {
    func testShippedGuideDecodesAndKnowsTheBasics() {
        XCTAssertGreaterThan(FolderGuide.entries.count, 200)
        let home = "/Users/me"
        func safety(_ path: String) -> FolderGuide.Safety? { FolderGuide.lookup(path, home: home)?.entry.safety }
        XCTAssertEqual(safety("/Users/me/.npm"), .regenerates)
        XCTAssertEqual(safety("/Users/me/.ssh"), .keep)
        XCTAssertEqual(safety("/Users/me/Documents"), .keep)
        XCTAssertEqual(safety("/Users/me/Library/Developer/Xcode/DerivedData"), .regenerates)
        XCTAssertEqual(FolderGuide.lookup("/Users/me/.gradle/caches", home: home)?.entry.category, "devcaches")
        // Every entry is translated, and nothing personal is called removable.
        for entry in FolderGuide.entries {
            for language in ["en", "tr", "es", "de"] {
                XCTAssertFalse(entry.title(language).isEmpty, "\(entry.match) \(language)")
                XCTAssertFalse(entry.what(language).isEmpty, "\(entry.match) \(language)")
            }
        }
        for personal in ["Documents", "Desktop", "Pictures", "Movies", "Music", ".ssh", "Library/Keychains", "Library/Mail"] {
            let safety = safety("/Users/me/\(personal)")
            XCTAssertTrue(safety == .keep || safety == .review, "\(personal): \(String(describing: safety))")
        }
    }
}

final class DuplicateFolderTests: XCTestCase {
    func testFindsTopmostCopyAndIgnoresDifferentFolders() throws {
        let home = FileManager.default.temporaryDirectory.appendingPathComponent("dupfolders-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: home) }
        func write(_ path: String, _ bytes: Int, seed: UInt8) throws {
            let url = home.appendingPathComponent(path)
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data((0..<bytes).map { UInt8(($0 + Int(seed)) % 251) }).write(to: url)
        }
        // A project and a real (non-clone) copy of it, with a subfolder.
        for root in ["Documents/Project", "Documents/Project copy"] {
            try write("\(root)/video.mov", 600_000, seed: 1)
            try write("\(root)/assets/a.bin", 300_000, seed: 2)
        }
        // Same names and sizes, different contents: not a duplicate.
        try write("Desktop/Lookalike/video.mov", 600_000, seed: 9)
        try write("Desktop/Lookalike/assets/a.bin", 300_000, seed: 2)

        let groups = DuplicateFolders.find(home: home, minSize: 500_000)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.keep.lastPathComponent, "Project")
        XCTAssertEqual(groups.first?.copies.map(\.url.lastPathComponent), ["Project copy"], "the subfolders aren't reported again")
    }
}

final class SimilarVideoTests: XCTestCase {
    /// A macOS sample clip, its 640×480 re-encode (same video), and a different clip.
    func testReEncodedClipIsSimilarAndDifferentClipIsNot() throws {
        let fm = FileManager.default
        let clip = "/System/Library/ExtensionKit/Extensions/MouseExtension.appex/Contents/Resources/Mouse.mov"
        let other = "/System/Library/CoreServices/Setup Assistant.app/Contents/Resources/trackpad_placeholder.mov"
        try XCTSkipUnless(fm.fileExists(atPath: clip) && fm.fileExists(atPath: other) && fm.fileExists(atPath: "/usr/bin/avconvert"),
                          "sample clips not on this macOS")
        let folder = fm.temporaryDirectory.appendingPathComponent("videos-\(UUID().uuidString)")
        try fm.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: folder) }
        try fm.copyItem(atPath: clip, toPath: folder.appendingPathComponent("clip.mov").path)
        try fm.copyItem(atPath: other, toPath: folder.appendingPathComponent("other.mov").path)
        let convert = Process()
        convert.executableURL = URL(fileURLWithPath: "/usr/bin/avconvert")
        convert.arguments = ["-s", folder.appendingPathComponent("clip.mov").path, "-o", folder.appendingPathComponent("clip-small.mp4").path,
                             "-p", "Preset640x480"]
        try convert.run()
        convert.waitUntilExit()
        try XCTSkipUnless(fm.fileExists(atPath: folder.appendingPathComponent("clip-small.mp4").path), "avconvert couldn't re-encode")

        let groups = SimilarVideos.groups(in: [folder], minimumBytes: 1)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups.first?.keep.url.lastPathComponent, "clip.mov", "the higher resolution is kept")
        XCTAssertEqual(groups.first?.copies.map(\.url.lastPathComponent), ["clip-small.mp4"])
    }
}

final class DockerItemTests: XCTestCase {
    func testParsesImagesAndVolumes() throws {
        let json = #"{"Images":[{"Containers":"0","CreatedSince":"2 hours ago","ID":"sha256:6c5aa4a8d5344d7b0996c54623136e244db2b1b2163113da888620ebeff67cd8","Repository":"<none>","Tag":"<none>","UniqueSize":"873.4MB"},{"Containers":"1","CreatedSince":"3 days ago","ID":"sha256:01b7801ac585ef6a78e86cc49c0eb961a5e2f873267e457f52442a1b0688ee33","Repository":"postgres","Tag":"16","UniqueSize":"1.2GB"}],"Volumes":[{"Name":"shop_db","Links":"0","Size":"512MB","Labels":"com.docker.compose.project=shop,com.docker.compose.volume=db"}]}"#
        let parsed = try XCTUnwrap(DockerCLI.parseVerbose(json))
        XCTAssertEqual(parsed.images.count, 2)
        XCTAssertNil(parsed.images[0].name)
        XCTAssertEqual(parsed.images[0].unique, 873_400_000)
        XCTAssertEqual(parsed.images[1].name, "postgres:16")
        XCTAssertEqual(parsed.images[1].containers, 1)
        XCTAssertEqual(parsed.volumes.first?.project, "shop")
        XCTAssertEqual(parsed.volumes.first?.size, 512_000_000)
    }

    func testOnlyKnownDockerCommandsAreAllowed() {
        let id = "sha256:" + String(repeating: "a", count: 64)
        XCTAssertTrue(DockerCLI.isAllowed(["image", "rm", id]))
        XCTAssertTrue(DockerCLI.isAllowed(["volume", "rm", "shop_db"]))
        XCTAssertTrue(DockerCLI.isAllowed(["builder", "prune", "--all", "--force"]))
        for bad in [["image", "rm", "postgres"], ["image", "rm", id, "--force"], ["volume", "rm", "--all"], ["volume", "rm", "a b"],
                    ["system", "prune", "-af"], ["run", "alpine"], ["container", "rm", "x"]] {
            XCTAssertFalse(DockerCLI.isAllowed(bad), "\(bad)")
        }
        XCTAssertNotNil(PathRules.reasonNotDeletable(URL(string: "docker://x")!, kind: .dockerPrune(arguments: ["system", "prune", "-af"])))
    }
}
