@testable import SpacebarCore
import XCTest

final class PathRulesTests: XCTestCase {
    let home = NSHomeDirectory()

    private func allowed(_ path: String, _ kind: ItemKind = .file) -> Bool {
        let full = path.hasPrefix("/") ? path : "\(home)/\(path)"
        return PathRules.isDeletable(URL(fileURLWithPath: full), kind: kind)
    }

    func testProtectedFoldersAreRefused() {
        for path in ["Documents", "Desktop", "Downloads", "Library", "Library/Caches", "Library/Application Support",
                     "Library/Keychains/login.keychain-db", "Library/Mail/V10/x", "Library/Messages/chat.db",
                     "Library/Mobile Documents/com~apple~CloudDocs/a.pdf", "Library/Group Containers/x/y",
                     "Library/Preferences/com.example.plist", ".ssh/config", ".ollama/models/llama"] {
            XCTAssertFalse(allowed(path), path)
        }
    }

    func testOrdinaryCachesAreAllowed() {
        for path in ["Library/Caches/pip", "Library/Logs/Some App", "Library/Developer/Xcode/DerivedData/App-abc",
                     ".npm/_cacache", "Library/Containers/com.example/Data/Library/Caches/x", "Documents/report.pdf"] {
            XCTAssertTrue(allowed(path), path)
        }
    }

    func testWholeAppContainersAreRefusedAsFiles() {
        XCTAssertFalse(allowed("Library/Containers/com.example.app"))
        XCTAssertFalse(allowed("Library/Containers/com.example.app/Data"))
    }

    func testSecurityFilesAndShellConfigAreLocked() {
        XCTAssertFalse(allowed("q2_id_ed25519"))
        XCTAssertFalse(allowed("Documents/certs/server.pem"))
        XCTAssertFalse(allowed(".zshrc"))
        XCTAssertFalse(allowed(".gitconfig"))
        XCTAssertTrue(allowed("Documents/zshrc-notes.txt"))
    }

    func testOutsideHome() {
        XCTAssertFalse(allowed("/System/Library"))
        XCTAssertFalse(allowed("/Library/Preferences"))
        XCTAssertFalse(allowed("/Users/Shared"))
        XCTAssertTrue(allowed("/Users/Shared/Epic Games"))
        XCTAssertTrue(allowed("/Applications/Install macOS Tahoe.app"))
        XCTAssertFalse(allowed("/Applications/Utilities"))
    }

    func testUnusualPathsAreRefused() {
        XCTAssertFalse(allowed("Library/Caches/../../Documents"))
        XCTAssertFalse(allowed("Library/Caches/bad\u{1}name"))
    }

    func testKinds() {
        XCTAssertFalse(allowed("/Applications/Safari.app", .application), "Apple apps")
        XCTAssertFalse(allowed("Downloads/Some.app", .application), "apps outside Applications")
        XCTAssertTrue(allowed("Library/Containers/com.example.gone", .appLeftover))
        XCTAssertFalse(allowed("Library/Containers/com.apple.Notes", .appLeftover))
        XCTAssertFalse(allowed("Documents/stuff", .appLeftover))
        XCTAssertTrue(allowed("Library/Developer/CoreSimulator/Devices/ABC", .simulatorDevice(udid: "ABC")))
        XCTAssertFalse(allowed("Library/Caches/ABC", .simulatorDevice(udid: "ABC")))
        XCTAssertTrue(allowed("Library/Mail/V10/0A1B2C3D-0000-0000-0000-000000000000", .mailAttachments))
        XCTAssertFalse(allowed("Library/Mail/V10/0A1B2C3D-0000-0000-0000-000000000000/INBOX.mbox", .mailAttachments))
    }

    func testActiveDeveloperToolsAreProtected() throws {
        let developer = try XCTUnwrap(PathRules.activeDeveloperApp, "no xcode-select app on this machine")
        XCTAssertFalse(PathRules.isDeletable(URL(fileURLWithPath: developer)))
        XCTAssertFalse(PathRules.isDeletable(URL(fileURLWithPath: developer), kind: .application))
    }
}

final class DrivePathRulesTests: XCTestCase {
    func testOtherDrives() {
        func reason(_ path: String) -> String? { PathRules.reasonNotDeletable(URL(fileURLWithPath: path)) }
        XCTAssertEqual(reason("/Volumes/Backup Disk"), "The drive itself")
        XCTAssertNotNil(reason("/Volumes/Backup Disk/.Spotlight-V100"))
        XCTAssertNotNil(reason("/Volumes/Backup Disk/.Trashes"))
        XCTAssertNotNil(reason("/Volumes/Backup Disk/Backups.backupdb/Mac/2024-01-01"), "Time Machine")
        XCTAssertNil(reason("/Volumes/Backup Disk/Videos/clip.mov"))
    }
}

final class AppCacheRulesTests: XCTestCase {
    func testAppCacheFoldersAreClearable() {
        let library = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library")
        for path in ["Caches/Google/Chrome", "Caches/com.tinyspeck.slackmacgap",
                     "Containers/com.example.app/Data/Library/Caches"] {
            XCTAssertNil(PathRules.reasonNotDeletable(library.appendingPathComponent(path), kind: .file), path)
        }
    }
}

final class BrowserRulesTests: XCTestCase {
    private let home = FileManager.default.homeDirectoryForCurrentUser

    func testBrowserCachesAreClearable() {
        for path in ["Library/Caches/Google/Chrome/Default", "Library/Application Support/Google/Chrome/Default/GPUCache",
                     "Library/Application Support/Google/Chrome/Profile 3/Service Worker/CacheStorage",
                     "Library/Application Support/Google/GoogleUpdater/crx_cache"] {
            XCTAssertNil(PathRules.reasonNotDeletable(home.appendingPathComponent(path), kind: .file), path)
        }
    }

    func testOnlyRealProfileFoldersCanBeRemovedAsProfiles() {
        let support = "Library/Application Support/"
        XCTAssertNil(PathRules.reasonNotDeletable(home.appendingPathComponent(support + "Google/Chrome/Profile 6"), kind: .browserProfile))
        XCTAssertNil(PathRules.reasonNotDeletable(home.appendingPathComponent(support + "Arc/User Data/Default"), kind: .browserProfile))
        for path in [support + "Google/Chrome", support + "Google/Chrome/Profile 6/Bookmarks", support + "Google/Profile 6",
                     support + "Unknown/Profile 1", "Documents/Profile 1"] {
            XCTAssertNotNil(PathRules.reasonNotDeletable(home.appendingPathComponent(path), kind: .browserProfile), path)
        }
    }

    func testReadsProfileNamesAndLastActivityFromLocalState() throws {
        let data = FileManager.default.temporaryDirectory.appendingPathComponent("chrome-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: data.appendingPathComponent("Profile 2"), withIntermediateDirectories: true)
        let old = Date().addingTimeInterval(-400 * 86400).timeIntervalSince1970
        let state: [String: Any] = ["profile": ["last_used": "Default",
                                                "info_cache": ["Profile 2": ["name": "Old", "active_time": old]]]]
        try JSONSerialization.data(withJSONObject: state).write(to: data.appendingPathComponent("Local State"))
        defer { try? FileManager.default.removeItem(at: data) }
        let parsed = BrowserData.localState(data)
        XCTAssertEqual(parsed.names["Profile 2"], "Old")
        XCTAssertEqual(parsed.lastUsed, "Default")
        XCTAssertEqual(parsed.lastActive["Profile 2"]?.timeIntervalSince1970 ?? 0, old, accuracy: 1)
    }
}

final class DriveCleanupTests: XCTestCase {
    func testOnlyMacOSClutterOnThatDrive() {
        let drive = URL(fileURLWithPath: "/Volumes/USB")
        for path in ["/Volumes/USB/.DS_Store", "/Volumes/USB/Photos/._IMG_1.jpg", "/Volumes/USB/.Trashes",
                     "/Volumes/USB/.Spotlight-V100", "/Volumes/USB/Photos/.DS_Store"] {
            XCTAssertTrue(DriveCleanup.isClutter(URL(fileURLWithPath: path), on: drive), path)
        }
        for path in ["/Volumes/USB/Photos/IMG_1.jpg", "/Volumes/USB/Photos/.Trashes", "/Volumes/USB/._",
                     "/Volumes/Other/.DS_Store", "/Users/me/.DS_Store", "/Volumes/USB/.git"] {
            XCTAssertFalse(DriveCleanup.isClutter(URL(fileURLWithPath: path), on: drive), path)
        }
    }

    func testMacFormattedDrivesAreLeftAlone() {
        XCTAssertFalse(DriveCleanup.applies(to: URL(fileURLWithPath: "/")), "APFS")
    }
}

final class GitLFSRuleTests: XCTestCase {
    func testOnlyARepositorysLFSFolder() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        XCTAssertNil(PathRules.reasonNotDeletable(home.appendingPathComponent("Documents/app/.git/lfs"), kind: .gitLFSPrune))
        XCTAssertNotNil(PathRules.reasonNotDeletable(home.appendingPathComponent("Documents/app/lfs"), kind: .gitLFSPrune))
        XCTAssertNotNil(PathRules.reasonNotDeletable(home.appendingPathComponent("Documents/app/.git"), kind: .gitLFSPrune))
    }
}
