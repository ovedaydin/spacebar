import AppKit
import SpacebarCore
import Sparkle
import SwiftUI
import UserNotifications

/// Sparkle's standard updater: daily background checks plus "Check for Updates…".
/// Inactive when the app isn't a bundle with a feed (e.g. `swift run`).
@MainActor
final class Updates: ObservableObject {
    static let shared = Updates()
    let controller: SPUStandardUpdaterController?

    private init() {
        let configured = Bundle.main.object(forInfoDictionaryKey: "SUFeedURL") != nil
        controller = configured
            ? SPUStandardUpdaterController(startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil)
            : nil
    }

    var available: Bool { controller != nil }
    func check() { controller?.checkForUpdates(nil) }
}

@main
struct SpacebarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var delegate
    @StateObject private var model = AppModel()
    @StateObject private var explorer = ExplorerModel()
    @AppStorage(Preferences.showMenuBar) private var showMenuBar = true
    @AppStorage(Preferences.menuBarShowsSpace) private var menuBarShowsSpace = false

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
                .environmentObject(model)
                .environmentObject(explorer)
                .frame(minWidth: 920, minHeight: 600)
        }
        .commands {
            CommandGroup(after: .newItem) {
                Button("Scan") { model.scanAll() }
                    .keyboardShortcut("r")
            }
            CommandGroup(after: .undoRedo) {
                Button("Undo Last Clean (Put Back)") { model.putBackLastClean() }
                    .keyboardShortcut("z", modifiers: [.command, .option])
                    .disabled(model.lastTrashed.isEmpty || model.cleaning)
            }
            CommandGroup(after: .appInfo) {
                Button("Check for Updates…") { Updates.shared.check() }
                    .disabled(!Updates.shared.available)
            }
        }

        MenuBarExtra(isInserted: $showMenuBar) {
            MenuBarPanel().environmentObject(model)
        } label: {
            // Icon only by default: on Macs with a notch, wide items are the first to be hidden.
            if menuBarShowsSpace, let space = model.space {
                HStack(spacing: 4) {
                    Image(nsImage: MenuBarIcon.image)
                    Text(ByteFormat.string(space.available))
                }
            } else {
                Image(nsImage: MenuBarIcon.image)
            }
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView().environmentObject(model)
        }
    }
}

/// Monochrome version of the app icon's three bars, as a template image so the menu bar
/// tints it for light and dark appearances.
enum MenuBarIcon {
    static let image: NSImage = {
        let image = NSImage(size: NSSize(width: 16, height: 16), flipped: true) { rect in
            NSColor.black.setFill()
            let widths: [CGFloat] = [12, 12, 6.5]
            for (index, width) in widths.enumerated() {
                let bar = NSRect(x: 2, y: 2.5 + CGFloat(index) * 4.25, width: width, height: 2.75)
                NSBezierPath(roundedRect: bar, xRadius: 1.375, yRadius: 1.375).fill()
            }
            // The sparkle next to the short bar.
            let center = NSPoint(x: 12.25, y: 11.9)
            let star = NSBezierPath()
            star.move(to: NSPoint(x: center.x, y: center.y - 2.6))
            star.curve(to: NSPoint(x: center.x + 2.6, y: center.y), controlPoint1: NSPoint(x: center.x + 0.3, y: center.y - 0.3),
                       controlPoint2: NSPoint(x: center.x + 0.3, y: center.y - 0.3))
            star.curve(to: NSPoint(x: center.x, y: center.y + 2.6), controlPoint1: NSPoint(x: center.x + 0.3, y: center.y + 0.3),
                       controlPoint2: NSPoint(x: center.x + 0.3, y: center.y + 0.3))
            star.curve(to: NSPoint(x: center.x - 2.6, y: center.y), controlPoint1: NSPoint(x: center.x - 0.3, y: center.y + 0.3),
                       controlPoint2: NSPoint(x: center.x - 0.3, y: center.y + 0.3))
            star.curve(to: NSPoint(x: center.x, y: center.y - 2.6), controlPoint1: NSPoint(x: center.x - 0.3, y: center.y - 0.3),
                       controlPoint2: NSPoint(x: center.x - 0.3, y: center.y - 0.3))
            star.fill()
            return true
        }
        image.isTemplate = true
        return image
    }()
}

/// UserDefaults keys.
enum Preferences {
    static let showMenuBar = "showMenuBar"
    static let menuBarShowsSpace = "menuBarShowsSpace"
    static let lowDiskAlerts = "lowDiskAlerts"
    static let lowDiskThresholdGB = "lowDiskThresholdGB"
    static let lastLowDiskAlert = "lastLowDiskAlert"
    static let onboardingDone = "onboardingDone"
    static let onboardingPage = "onboardingPage"

    static func register() {
        UserDefaults.standard.register(defaults: [showMenuBar: true, lowDiskAlerts: true, lowDiskThresholdGB: 10])
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        Preferences.register()
        IOPolicy.configureForScanning()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Clicking the low-disk notification brings Spacebar forward.
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
        completionHandler()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lets `swift run Spacebar` show a normal app window too.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        DebugSnapshot.scheduleIfRequested()
    }

    /// With the menu bar item on, Spacebar keeps running after its window closes.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        !UserDefaults.standard.bool(forKey: Preferences.showMenuBar)
    }
}

/// Development aid. SPACEBAR_SCRIPT drives the UI and captures the app's own window
/// (no Screen Recording permission needed), e.g.
///   SPACEBAR_SCRIPT="wait:6;snap:/tmp/a.png;route:xcode;wait:1;snap:/tmp/b.png;toggle:xcode"
/// Logs to stderr during scripted debug runs only.
func debugLog(_ message: @autoclosure () -> String) {
    guard ProcessInfo.processInfo.environment["SPACEBAR_SCRIPT"] != nil else { return }
    FileHandle.standardError.write(Data("[trace] \(String(format: "%.2f", ProcessInfo.processInfo.systemUptime)) \(message())\n".utf8))
}

enum DebugSnapshot {
    static let routeNotification = Notification.Name("SpacebarDebugRoute")
    static let toggleNotification = Notification.Name("SpacebarDebugToggle")
    static let dumpNotification = Notification.Name("SpacebarDebugDump")
    static let simulateNotification = Notification.Name("SpacebarDebugSimulate")
    static let segmentNotification = Notification.Name("SpacebarDebugSegment")
    private static var activity: NSObjectProtocol?

    static func scheduleIfRequested() {
        guard let script = ProcessInfo.processInfo.environment["SPACEBAR_SCRIPT"] else { return }
        // Read once; don't let anything this process launches inherit it.
        unsetenv("SPACEBAR_SCRIPT")
        // Scripted runs happen in a background window; App Nap would delay steps and redraws.
        activity = ProcessInfo.processInfo.beginActivity(options: [.userInitiated, .latencyCritical], reason: "Debug script")
        var delay = 0.0
        for step in script.split(separator: ";") {
            let parts = step.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            if parts[0] == "wait" {
                delay += Double(parts[1]) ?? 1
                continue
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                debugLog("step \(step)")
                switch parts[0] {
                case "snap": snapshot(to: parts[1])
                case "route": NotificationCenter.default.post(name: routeNotification, object: parts[1])
                case "toggle": NotificationCenter.default.post(name: toggleNotification, object: parts[1])
                case "click": click(parts[1])
                case "selftest": cleanerSelfTest()
                case "trashtest": trashSelfTest()
                case "menubar": clickMenuBarItem()
                case "fdacheck", "relaunch":
                    NotificationCenter.default.post(name: segmentNotification, object: "action:" + parts[0])
                case "statusframe":
                    for window in NSApp.windows where String(describing: type(of: window)).contains("StatusBar") {
                        let screen = NSScreen.main
                        FileHandle.standardError.write(Data(("[status] frame=\(window.frame) visible=\(window.isVisible) onScreen=\(window.occlusionState.contains(.visible)) "
                            + "screen=\(screen?.frame ?? .zero) notchLeft=\(screen?.auxiliaryTopLeftArea ?? .zero) notchRight=\(screen?.auxiliaryTopRightArea ?? .zero)\n").utf8))
                    }
                case "snappanel": snapshot(to: parts[1], panel: true)
                case "snapstatus": snapshot(to: parts[1], status: true)
                case "snapsheet": snapshot(to: parts[1], sheet: true)
                case "iconpng":
                    // Renders the menu bar icon at 8× (black on white) to check its shape.
                    let size = NSSize(width: 128, height: 128)
                    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 128, pixelsHigh: 128, bitsPerSample: 8,
                                               samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
                                               colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
                    NSGraphicsContext.saveGraphicsState()
                    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
                    NSColor.white.setFill(); NSRect(origin: .zero, size: size).fill()
                    MenuBarIcon.image.draw(in: NSRect(origin: .zero, size: size))
                    NSGraphicsContext.restoreGraphicsState()
                    try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: parts[1]))
                case "segment": NotificationCenter.default.post(name: segmentNotification, object: parts[1])
                case "simulate": NotificationCenter.default.post(name: simulateNotification, object: parts[1])
                case "key": key(parts[1])
                case "dump": NotificationCenter.default.post(name: dumpNotification, object: parts[1])
                case "activate":
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first(where: \.isVisible)?.makeKeyAndOrderFront(nil)
                case "quit": NSApp.terminate(nil)
                default: break
                }
            }
        }
    }

    /// Sends a real mouse down/up into the window. "x,y" in points from the window's top-left.
    private static func click(_ spec: String) {
        let xy = spec.split(separator: ",").compactMap { Double($0) }
        guard xy.count == 2, let window = NSApp.windows.first(where: \.isVisible) else { return }
        let location = NSPoint(x: xy[0], y: window.frame.height - xy[1])
        func event(_ type: NSEvent.EventType) -> NSEvent? {
            NSEvent.mouseEvent(with: type, location: location, modifierFlags: [],
                               timestamp: ProcessInfo.processInfo.systemUptime,
                               windowNumber: window.windowNumber, context: nil,
                               eventNumber: 0, clickCount: 1, pressure: 1)
        }
        guard let down = event(.leftMouseDown), let up = event(.leftMouseUp) else { return }
        // AppKit buttons track the mouse by pulling events from the queue until mouse-up,
        // so the mouse-up must already be queued when the mouse-down is delivered.
        NSApp.postEvent(up, atStart: false)
        window.sendEvent(down)
    }

    /// Sends a key press to the key window (e.g. a confirmation dialog). "return" or "escape".
    private static func key(_ name: String) {
        let main = NSApp.windows.first { $0.isVisible && $0.sheetParent == nil }
        guard let window = main?.attachedSheet ?? NSApp.keyWindow ?? main else { return }
        FileHandle.standardError.write(Data("[key] \(name) → \(type(of: window)) sheet=\(main?.attachedSheet != nil)\n".utf8))
        let (chars, code): (String, UInt16) = name == "escape" ? ("\u{1b}", 53) : ("\r", 36)
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            if let event = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: [],
                                            timestamp: ProcessInfo.processInfo.systemUptime,
                                            windowNumber: window.windowNumber, context: nil, characters: chars,
                                            charactersIgnoringModifiers: chars, isARepeat: false, keyCode: code) {
                window.sendEvent(event)
            }
        }
    }

    /// Exercises Cleaner's rules on hand-picked items. Always a dry run: nothing is touched.
    private static func cleanerSelfTest() {
        let home = FileManager.default.homeDirectoryForCurrentUser
        func item(_ relative: String, size: Int64 = 1, owner: String? = nil) -> CleanItem {
            let url = relative.hasPrefix("/") ? URL(fileURLWithPath: relative) : home.appendingPathComponent(relative)
            return CleanItem(url: url, name: relative, size: size, date: nil, detail: nil, owner: owner)
        }
        func kinded(_ relative: String, _ kind: ItemKind, owner: String? = nil) -> CleanItem {
            var value = item(relative, size: 5, owner: owner)
            value.kind = kind
            return value
        }
        let kindCases: [(String, CleanItem, RemovalMode)] = [
            ("third-party app", kinded("/Applications/Stats.app", .application), .trash),
            ("Apple app", kinded("/Applications/Safari.app", .application), .trash),
            ("app outside Applications", kinded("Downloads/Xcode.app", .application), .trash),
            ("active Xcode as a file", item("Downloads/Xcode.app"), .trash),
            ("folder containing active Xcode", item("Downloads"), .trash),
            ("leftover container", kinded("Library/Containers/com.example.gone", .appLeftover), .trash),
            ("Apple container as leftover", kinded("Library/Containers/com.apple.Notes", .appLeftover), .trash),
            ("leftover outside data folders", kinded("Documents/stuff", .appLeftover), .trash),
            ("simulator device", kinded("Library/Developer/CoreSimulator/Devices/ABC", .simulatorDevice(udid: "ABC")), .permanent),
            ("simulator kind on wrong path", kinded("Library/Caches/ABC", .simulatorDevice(udid: "ABC")), .permanent),
            ("simulator runtime", kinded("/Library/Developer/CoreSimulator/Images/X.dmg", .simulatorRuntime(identifier: "X")), .permanent),
            ("mail account", kinded("Library/Mail/V10/0A1B2C3D-0000-0000-0000-000000000000", .mailAttachments), .trash),
            ("mail kind on mailbox folder", kinded("Library/Mail/V10/0A1B2C3D-0000-0000-0000-000000000000/INBOX.mbox", .mailAttachments), .trash),
            ("plain file inside Mail", item("Library/Mail/V10/x"), .trash),
            ("inside /Users/Shared", item("/Users/Shared/Epic Games/UE_5.1"), .trash),
            ("/Users/Shared itself", item("/Users/Shared"), .trash),
            ("folder inside /Applications", item("/Applications/Utilities"), .trash),
            ("SSH key", item(".ssh/id_ed25519"), .trash),
        ]
        var lockedItem = item("Library/Caches/pip")
        lockedItem.lockedReason = "Stored only on this Mac"
        let cases: [(String, CleanItem, RemovalMode)] = kindCases + [("locked item", lockedItem, .permanent)] + [
            ("protected top-level folder", item("Documents"), .trash),
            ("protected Library folder", item("Library/Caches"), .permanent),
            ("keychains", item("Library/Keychains/login.keychain-db"), .permanent),
            ("outside home", item("/System/Library"), .permanent),
            ("owner running", item("Library/Caches/com.microsoft.VSCode.ShipIt", size: 10, owner: "com.microsoft.VSCode"), .permanent),
            ("trash item asked to trash", item(".Trash/example", size: 100), .trash),
            ("normal cache", item("Library/Caches/pip", size: 1000), .permanent),
            ("review item", item("Library/Developer/Xcode/Archives/x.xcarchive", size: 10000), .trash),
        ]
        for (label, item, mode) in cases {
            let report = Cleaner.run([Cleaner.Request(item: item, mode: mode)], dryRun: true)
            let outcome = report.skipped.first.map { "SKIPPED (\($0.reason))" }
                ?? (report.deletedBytes > 0 ? "would DELETE \(report.deletedBytes)" : "would TRASH \(report.trashedBytes)")
            FileHandle.standardError.write(Data("[selftest] \(label): \(outcome) removed=\(report.removed.count)\n".utf8))
        }
        let h = home.path
        let kinds = ["/Users/Shared/Epic Games", "/System/Volumes/Data/Users/Shared/x", "\(h)/.Trash/a", "/Applications/Stats.app",
                     "\(h)/Library/Developer/Xcode", "\(h)/.npm/_cacache", "\(h)/Library/Caches/pip", "\(h)/Library/Mail/V10",
                     "\(h)/Documents/x.pdf", "\(h)/Pictures/Photos Library.photoslibrary", "/Library/Developer/CoreSimulator",
                     "/Library/Audio", "/private/var/folders/x", "/opt/homebrew"]
            .map { "\($0.replacingOccurrences(of: h, with: "~")) → \(StorageAnalyzer.kind(forPath: $0).rawValue)" }
        FileHandle.standardError.write(Data("[selftest] storage kinds: \(kinds.joined(separator: " | "))\n".utf8))
        var breakdown = StorageBreakdown(total: 100, free: 10, purgeable: 0,
                                         segments: [StorageSegment(kind: .shared, bytes: 60, explorePath: nil),
                                                    StorageSegment(kind: .systemData, bytes: 30, explorePath: nil)],
                                         measuredAt: Date(), complete: true, measuring: nil)
        breakdown.recordRemoval(path: "/Users/Shared/Epic Games", bytes: 50, trashed: true)
        breakdown.recordRemoval(path: "\(h)/.Trash/Epic Games", bytes: 50, trashed: false)
        FileHandle.standardError.write(Data("[selftest] trash then empty: \(breakdown.segments.map { "\($0.kind.rawValue)=\($0.bytes)" }) free=\(breakdown.free)\n".utf8))
        let cat = CleanCategory.appCaches
        let nested = AppModel.withoutOverlaps([
            (item("Library/Caches/pip"), cat), (item("Library/Caches/pip/http"), cat),
            (item("Library/Caches/pip"), cat), (item("Library/Caches/pipx"), cat),
        ]).map { $0.0.url.path.replacingOccurrences(of: home.path, with: "~") }
        FileHandle.standardError.write(Data("[selftest] overlap filter kept: \(nested)\n".utf8))
    }

    /// Real (not dry-run) test of Trash → Delete Now, on a throwaway file this test creates.
    private static func trashSelfTest() {
        func say(_ s: String) { FileHandle.standardError.write(Data("[trashtest] \(s)\n".utf8)) }
        let caches = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/Caches")
        let fixture = caches.appendingPathComponent("spacebar-selftest-\(UUID().uuidString).txt")
        guard fixture.lastPathComponent.hasPrefix("spacebar-selftest-") else { return }
        FileManager.default.createFile(atPath: fixture.path, contents: Data(repeating: 7, count: 1 << 20))
        let size = BulkScanner().measure(fixture).allocated
        let item = CleanItem(url: fixture, name: fixture.lastPathComponent, size: size, date: nil, detail: nil, owner: nil)
        let trashed = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: false)
        say("trash: removed=\(trashed.removed.count) trashedBytes=\(trashed.trashedBytes) landed=\(trashed.trashedItems.map { $0.url.path.replacingOccurrences(of: NSHomeDirectory(), with: "~") }) skipped=\(trashed.skipped.map(\.reason))")
        say("original still exists: \(FileManager.default.fileExists(atPath: fixture.path))")
        let outside = Cleaner.deleteFromTrash([(caches.appendingPathComponent("pip"), 1)], dryRun: false)
        say("delete outside Trash refused: \(outside.skipped.map(\.reason))")
        let deleted = Cleaner.deleteFromTrash(trashed.trashedItems.map { ($0.url, $0.bytes) }, dryRun: false)
        say("delete now: deletedBytes=\(deleted.deletedBytes) removed=\(deleted.removed.count) skipped=\(deleted.skipped.map(\.reason))")
        if let landed = trashed.trashedItems.first?.url {
            say("trashed copy still exists: \(FileManager.default.fileExists(atPath: landed.path))")
        }

        // Put Back: restores to the original path…
        func makeFixture() -> CleanItem {
            let url = caches.appendingPathComponent("spacebar-selftest-\(UUID().uuidString).txt")
            FileManager.default.createFile(atPath: url.path, contents: Data(repeating: 1, count: 4096))
            return CleanItem(url: url, name: url.lastPathComponent, size: 4096, date: nil, detail: nil, owner: nil)
        }
        let first = makeFixture()
        let firstTrash = Cleaner.run([Cleaner.Request(item: first, mode: .trash)], dryRun: false)
        let back = Cleaner.putBack(firstTrash.trashedItems, dryRun: false)
        say("put back: restored=\(back.restoredItems.count) atOriginal=\(FileManager.default.fileExists(atPath: first.url.path)) inTrash=\(FileManager.default.fileExists(atPath: firstTrash.trashedItems[0].url.path)) skipped=\(back.skipped.map(\.reason))")
        // …and never overwrites something new at that path.
        let second = makeFixture()
        let secondTrash = Cleaner.run([Cleaner.Request(item: second, mode: .trash)], dryRun: false)
        FileManager.default.createFile(atPath: second.url.path, contents: Data("new".utf8))
        let blocked = Cleaner.putBack(secondTrash.trashedItems, dryRun: false)
        say("put back onto existing file: restored=\(blocked.restoredItems.count) skipped=\(blocked.skipped.map(\.reason)) newFileIntact=\((try? String(contentsOf: second.url, encoding: .utf8)) == "new")")
        // Clean up this test's own files only.
        _ = Cleaner.deleteFromTrash(secondTrash.trashedItems.map { ($0.url, $0.bytes) }, dryRun: false)
        let cleanup = Cleaner.run([Cleaner.Request(item: first, mode: .permanent), Cleaner.Request(item: second, mode: .permanent)], dryRun: false)
        say("cleanup: removed=\(cleanup.removed.count)")
    }

    /// Clicks Spacebar's own menu bar item (opens its panel).
    private static func clickMenuBarItem() {
        for window in NSApp.windows where String(describing: type(of: window)).contains("StatusBar") {
            func findButton(_ view: NSView?) -> NSStatusBarButton? {
                guard let view else { return nil }
                if let button = view as? NSStatusBarButton { return button }
                return view.subviews.lazy.compactMap(findButton).first
            }
            findButton(window.contentView)?.performClick(nil)
        }
    }

    private static func snapshot(to path: String, panel: Bool = false, status: Bool = false, sheet: Bool = false) {
        let candidates = NSApp.windows.filter(\.isVisible)
        let chosen = panel ? candidates.first { String(describing: type(of: $0)).contains("MenuBarExtra") }
            : status ? candidates.first { String(describing: type(of: $0)).contains("StatusBar") }
            : sheet ? candidates.compactMap(\.attachedSheet).first
            : candidates.first
        FileHandle.standardError.write(Data("[windows] \(candidates.map { "\(type(of: $0)) level=\($0.level.rawValue)" })\n".utf8))
        guard let window = chosen,
              let image = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber),
                                                  [.boundsIgnoreFraming, .bestResolution]) else { return }
        let rep = NSBitmapImageRep(cgImage: image)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}
