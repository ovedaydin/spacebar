@testable import SpacebarCore
import XCTest

final class DeveloperToolsTests: XCTestCase {
    func testAndroidImagesAndEmulators() throws {
        let fixture = try Fixture("spacebar-home")
        let home = fixture.root
        let avd = try fixture.folder(".android/avd/Phone.avd")
        try "avd.ini.displayname=My Phone\nimage.sysdir.1=system-images/android-36.1/google_apis/arm64-v8a/\n"
            .write(to: avd.appendingPathComponent("config.ini"), atomically: true, encoding: .utf8)
        try "path=\(avd.path)\n".write(to: home.appendingPathComponent(".android/avd/Phone_API_36.1.ini"), atomically: true, encoding: .utf8)
        try fixture.file("Library/Android/sdk/system-images/android-36.1/google_apis/arm64-v8a/system.img", bytes: 10)
        try fixture.file("Library/Android/sdk/system-images/android-35/google_apis/arm64-v8a/system.img", bytes: 10)
        for version in ["30.0.3", "36.1.0", "34.0.0"] {
            try fixture.file("Library/Android/sdk/build-tools/\(version)/aapt", bytes: 10)
        }
        let found = DeveloperTools.android(home: home)
        let emulator = try XCTUnwrap(found.first { $0.name == "My Phone" })
        if case .androidEmulator(let ini) = emulator.kind { XCTAssertTrue(ini.hasSuffix("Phone_API_36.1.ini")) } else { XCTFail() }
        let used = try XCTUnwrap(found.first { $0.name?.contains("android-36.1") == true })
        XCTAssertNotNil(used.lockedReason, "an emulator's image is locked")
        XCTAssertEqual(found.first { $0.name?.contains("android-35") == true }?.suggested, true, "unused image is suggested")
        XCTAssertEqual(Set(found.compactMap(\.name).filter { $0.hasPrefix("Android build-tools") }),
                       ["Android build-tools 34.0.0", "Android build-tools 30.0.3"], "newest build-tools kept")
    }

    func testJetBrainsVersionParsing() {
        XCTAssertEqual(DeveloperTools.productVersion("PyCharmCE2022.3")?.product, "PyCharmCE")
        XCTAssertEqual(DeveloperTools.productVersion("IntelliJIdea2024.10")?.version, "2024.10")
        XCTAssertNil(DeveloperTools.productVersion("consentOptions"))
    }

    func testPathRules() {
        let home = NSHomeDirectory()
        func allowed(_ path: String, _ kind: ItemKind) -> Bool {
            PathRules.isDeletable(URL(fileURLWithPath: path.hasPrefix("/") ? path : "\(home)/\(path)"), kind: kind)
        }
        XCTAssertTrue(allowed(".lmstudio/models/publisher/model", .aiModel))
        XCTAssertFalse(allowed(".lmstudio/models/publisher", .aiModel), "a whole publisher folder isn't a model")
        XCTAssertFalse(allowed(".ollama/models/blobs", .aiModel))
        XCTAssertTrue(allowed(".android/avd/Phone.avd", .androidEmulator(ini: "\(home)/.android/avd/Phone.ini")))
        XCTAssertFalse(allowed("Documents/Phone.avd", .androidEmulator(ini: "\(home)/.android/avd/Phone.ini")))
        XCTAssertFalse(allowed("/opt/homebrew/Cellar/ruby", .homebrewKeg), "a whole formula isn't a version")
        XCTAssertFalse(allowed("/opt/homebrew/Cellar/../bin/x/y", .homebrewKeg))
        XCTAssertTrue(allowed("Documents/repo/.git", .gitCompact))
        XCTAssertFalse(allowed("Documents/repo", .gitCompact))
        if let linked = try? FileManager.default.destinationOfSymbolicLink(atPath: "/opt/homebrew/opt/ruby") {
            let version = URL(fileURLWithPath: linked).lastPathComponent
            XCTAssertFalse(allowed("/opt/homebrew/Cellar/ruby/\(version)", .homebrewKeg), "the linked version is protected")
        }
    }
}
