@testable import SpacebarCore
import XCTest

final class UninstallTests: XCTestCase {
    func testFindsOnlyThisAppsData() throws {
        let fixture = try Fixture("spacebar-home")
        let mine = [
            "Library/Application Support/com.example.app/db.sqlite", "Library/Application Support/Example/state.json",
            "Library/Caches/com.example.app/cache.bin", "Library/Containers/com.example.app/Data/x",
            "Library/Preferences/com.example.app.plist", "Library/Preferences/ByHost/com.example.app.0F00.plist",
            "Library/Saved Application State/com.example.app.savedState/data", "Library/HTTPStorages/com.example.app.binarycookies",
            "Library/Logs/Example/log.txt", "Library/LaunchAgents/com.example.app.helper.plist",
            "Library/Group Containers/ABCDE12345.com.example.app/shared",
        ]
        let others = [
            "Library/Caches/com.example.application/x", "Library/Preferences/com.other.app.plist",
            "Library/Application Support/Examples/x", "Library/Caches/Example/x",
        ]
        for path in mine + others { try fixture.file(path, bytes: 10) }
        let app = AppFootprint.App(url: URL(fileURLWithPath: "/Applications/Example.app"), bundleID: "com.example.app",
                                   name: "Example", version: "1.0")
        let parts = AppFootprint.locate(app, home: fixture.root)
        let found = Set(parts.map { part -> String in
            let path = part.url.path
            return String(path[path.range(of: "/Library/")!.lowerBound...].dropFirst())
        })
        XCTAssertEqual(found, Set(mine.map { path -> String in
            let components = path.split(separator: "/").map(String.init)
            let depth = path.contains("/ByHost/") ? 4 : 3
            return components.prefix(depth).joined(separator: "/")
        }))
        XCTAssertEqual(parts.first { $0.url.path.contains("Group Containers") }?.selectedByDefault, false,
                       "shared containers aren't preselected")
        XCTAssertTrue(AppFootprint.locate(AppFootprint.App(url: app.url, bundleID: "com.apple.Notes", name: "Notes", version: nil),
                                          home: fixture.root).isEmpty, "Apple's apps are never uninstalled")
    }

    func testDeletionRules() {
        let home = NSHomeDirectory()
        let kind = ItemKind.appData(bundleID: "com.example.app", appName: "Example")
        func allowed(_ path: String) -> Bool { PathRules.isDeletable(URL(fileURLWithPath: "\(home)/\(path)"), kind: kind) }
        XCTAssertTrue(allowed("Library/Preferences/com.example.app.plist"))
        XCTAssertTrue(allowed("Library/Preferences/ByHost/com.example.app.0F00.plist"))
        XCTAssertTrue(allowed("Library/Containers/com.example.app"))
        XCTAssertTrue(allowed("Library/Application Support/Example"))
        XCTAssertFalse(allowed("Library/Preferences/com.other.app.plist"), "another app's settings")
        XCTAssertFalse(allowed("Library/Caches/Example"), "name matches only in App Support and Logs")
        XCTAssertFalse(allowed("Library/Keychains/com.example.app"), "not an app-data folder")
        XCTAssertFalse(allowed("Documents/com.example.app"))
        XCTAssertFalse(PathRules.isDeletable(URL(fileURLWithPath: "\(home)/Library/Preferences/com.apple.Notes.plist"),
                                             kind: .appData(bundleID: "com.apple.Notes", appName: "Notes")))
    }
}

final class ICloudTests: XCTestCase {
    func testEvictOnlyInsideICloudDrive() {
        let home = NSHomeDirectory()
        XCTAssertTrue(PathRules.isDeletable(URL(fileURLWithPath: "\(home)/Library/Mobile Documents/com~apple~CloudDocs/Movies/trip.mov"),
                                            kind: .iCloudEvict))
        XCTAssertFalse(PathRules.isDeletable(URL(fileURLWithPath: "\(home)/Documents/trip.mov"), kind: .iCloudEvict))
        XCTAssertFalse(PathRules.isDeletable(URL(fileURLWithPath: "\(home)/Library/Mobile Documents/com~apple~CloudDocs/x"), kind: .file),
                       "as a file, iCloud Drive stays protected")
    }
}
