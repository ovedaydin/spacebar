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

/// One binary: the app, or the `spacebar` command when run with a command (see CommandLineTool).
@main
enum Main {
    static func main() {
        if CommandLineTool.isRequested(CommandLine.arguments) { CommandLineTool.run(CommandLine.arguments) }
        SpacebarApp.main()
    }
}

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
            CommandGroup(after: .newItem) {
                Button("Uninstall App…") { model.chooseAppToUninstall() }
                    .keyboardShortcut("u", modifiers: [.command, .shift])
                Divider()
                Button("Export Disk Report as PDF…") { DiskReport.export(model: model, pdf: true) }
                    .keyboardShortcut("e", modifiers: [.command])
                Button("Export Disk Report as HTML…") { DiskReport.export(model: model, pdf: false) }
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
            MenuBarLabel(space: menuBarShowsSpace ? model.space : nil)
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
    static let autoClean = "autoClean"
    static let autoEmptyTrashed = "autoEmptyTrashed"
    static let lastAutoClean = "lastAutoClean"
    static let onboardingPage = "onboardingPage"
    static let forgottenReminders = "forgottenReminders"
    static let weeklySummary = "weeklySummary"

    static func register() {
        UserDefaults.standard.register(defaults: [showMenuBar: true, lowDiskAlerts: true, lowDiskThresholdGB: 10,
                                                  forgottenReminders: true])
    }
}

/// The menu bar item. It also lends its `openWindow` to Finder requests, since it's
/// around even when the main window is closed.
private struct MenuBarLabel: View {
    let space: VolumeSpace?
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        // Icon only by default: on Macs with a notch, wide items are the first to be hidden.
        Group {
            if let space {
                HStack(spacing: 4) {
                    Image(nsImage: MenuBarIcon.image)
                    Text(ByteFormat.string(space.available))
                }
            } else {
                Image(nsImage: MenuBarIcon.image)
            }
        }
        .onAppear { FinderIntegration.openMainWindow = { openWindow(id: "main") } }
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    private let services = ServiceProvider()

    func applicationWillFinishLaunching(_ notification: Notification) {
        Preferences.register()
        IOPolicy.configureForScanning()
        handleLinks()
        UNUserNotificationCenter.current().delegate = self
        ForgottenReminder.registerActions()
    }

    /// Clicking the low-disk notification brings Spacebar forward.
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse,
                                            withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        if content.categoryIdentifier == AppModel.lowDiskCategory, response.actionIdentifier == AppModel.rescueAction {
            completionHandler()
            DispatchQueue.main.async { NotificationCenter.default.post(name: AppModel.rescueRequested, object: nil) }
            return
        }
        if content.categoryIdentifier == ForgottenReminder.category {
            ForgottenReminder.handle(action: response.actionIdentifier, userInfo: content.userInfo)
            completionHandler()
            return
        }
        completionHandler()
        Task { @MainActor in
            NSApp.activate(ignoringOtherApps: true)
            NSApp.windows.first { $0.canBecomeMain }?.makeKeyAndOrderFront(nil)
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lets `swift run Spacebar` show a normal app window too.
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
        handleLinks()   // again, in case SwiftUI installed its own handler meanwhile
        // With its window closed Spacebar still lives in the menu bar. Without this, macOS treats a
        // windowless app as quit: links and Finder requests then fail ("Connection is invalid").
        ProcessInfo.processInfo.automaticTerminationSupportEnabled = false
        NSApp.servicesProvider = services
        NSUpdateDynamicServices()
        DebugSnapshot.scheduleIfRequested()
    }

    /// spacebar://show?path=… links, including the Finder service's. Handled here rather than
    /// with onOpenURL: SwiftUI only delivers those to new windows, not to the one already open.
    private func handleLinks() {
        NSAppleEventManager.shared().setEventHandler(self, andSelector: #selector(handleLink(_:reply:)),
                                                     forEventClass: AEEventClass(kInternetEventClass),
                                                     andEventID: AEEventID(kAEGetURL))
    }

    @objc private func handleLink(_ event: NSAppleEventDescriptor, reply: NSAppleEventDescriptor) {
        guard let string = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue,
              let url = URL(string: string) else { return }
        debugLog("open url \(string)")
        guard let folder = FinderIntegration.folder(from: url) else { return }
        FinderIntegration.request(folder)
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
    guard DebugSnapshot.enabled, ProcessInfo.processInfo.environment["SPACEBAR_SCRIPT"] != nil else { return }
    FileHandle.standardError.write(Data("[trace] \(String(format: "%.2f", ProcessInfo.processInfo.systemUptime)) \(message())\n".utf8))
}

enum DebugSnapshot {
    /// Test hooks exist only in local test builds (`DEBUG_HOOKS=1 scripts/build-app.sh`), never in releases:
    /// an app with Full Disk Access must not be drivable through environment variables.
    static var enabled: Bool {
        #if SPACEBAR_DEBUG_HOOKS
        return true
        #else
        return false
        #endif
    }

    /// An environment variable for test builds; always nil in releases.
    static func environment(_ name: String) -> String? {
        enabled ? ProcessInfo.processInfo.environment[name] : nil
    }

    static let routeNotification = Notification.Name("SpacebarDebugRoute")
    static let toggleNotification = Notification.Name("SpacebarDebugToggle")
    static let dumpNotification = Notification.Name("SpacebarDebugDump")
    static let simulateNotification = Notification.Name("SpacebarDebugSimulate")
    static let segmentNotification = Notification.Name("SpacebarDebugSegment")
    private static var activity: NSObjectProtocol?

    static func scheduleIfRequested() {
        guard enabled, let script = ProcessInfo.processInfo.environment["SPACEBAR_SCRIPT"] else { return }
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
                case "fdacheck", "relaunch", "applylive":
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
                case "explore": NotificationCenter.default.post(name: segmentNotification, object: "explore:" + parts[1])
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
                case "appkey": appKey(parts[1])
                case "drive": NotificationCenter.default.post(name: segmentNotification, object: "drive:" + parts[1])
                case "drivetest": driveSelfTest(parts[1])
                case "axdump":
                    // What VoiceOver sees in the main window.
                    func walk(_ element: Any, depth: Int, into lines: inout [String]) {
                        guard depth < 60, lines.count < 600, let object = element as? NSObject else { return }
                        func call(_ name: String) -> Any? {
                            let selector = NSSelectorFromString(name)
                            guard object.responds(to: selector) else { return nil }
                            return object.perform(selector)?.takeUnretainedValue()
                        }
                        let role = (call("accessibilityRole") as? String) ?? ""
                        let label = (call("accessibilityLabel") as? String) ?? ""
                        let value = (call("accessibilityValue") as? NSObject)?.description ?? ""
                        if !label.isEmpty || !value.isEmpty { lines.append("\(role) | \(label) | \(value)") }
                        for child in (call("accessibilityChildren") as? [Any]) ?? [] {
                            walk(child, depth: depth + 1, into: &lines)
                        }
                    }
                    var lines: [String] = []
                    if let window = NSApp.windows.first(where: { $0.isVisible && $0.identifier?.rawValue.hasPrefix("main") == true }) {
                        walk(window, depth: 0, into: &lines)
                    }
                    FileHandle.standardError.write(Data(lines.map { "[ax] " + $0 }.joined(separator: "\n").appending("\n").utf8))
                case "autotest": NotificationCenter.default.post(name: segmentNotification, object: "action:autotest")
                case "uninstall": NotificationCenter.default.post(name: segmentNotification, object: "uninstall:" + parts[1])
                case "dump": NotificationCenter.default.post(name: dumpNotification, object: parts[1])
                case "activate":
                    NSApp.activate(ignoringOtherApps: true)
                    NSApp.windows.first(where: \.isVisible)?.makeKeyAndOrderFront(nil)
                case "historytest": historySelfTest(phase: parts[1])
                case "remindertest": reminderSelfTest()
                case "scroll":
                    // Scrolls the main window's largest scroll view down by this many points.
                    func scrollViews(_ view: NSView) -> [NSScrollView] {
                        (view as? NSScrollView).map { [$0] } ?? view.subviews.flatMap(scrollViews)
                    }
                    let window = NSApp.windows.first { $0.isVisible && $0.canBecomeMain }
                    if let content = window?.contentView,
                       let scroll = scrollViews(content).max(by: {
                           $0.convert($0.bounds, to: nil).minX < $1.convert($1.bounds, to: nil).minX }) {
                        scroll.contentView.scroll(to: NSPoint(x: 0, y: Double(parts[1]) ?? 0))
                        scroll.reflectScrolledClipView(scroll.contentView)
                    }
                case "front":
                    // Floats the window above others so it draws (covered windows aren't redrawn).
                    if let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) {
                        window.level = .floating
                        window.orderFrontRegardless()
                    }
                case "offloadtest": NotificationCenter.default.post(name: offloadTestNotification, object: parts[1])
                case "drivecleantest":
                    let volume = URL(fileURLWithPath: "/Volumes/\(parts[1])")
                    let found = DriveCleanup.find(on: volume)
                    FileHandle.standardError.write(Data("[drivecleantest] applies=\(DriveCleanup.applies(to: volume)) found=\(found.files.map(\.lastPathComponent).sorted()) appleDouble=\(found.appleDouble)\n".utf8))
                    let freed = DriveCleanup.remove(found, on: volume)
                    let left = (try? FileManager.default.subpathsOfDirectory(atPath: volume.path)) ?? []
                    FileHandle.standardError.write(Data("[drivecleantest] freed=\(freed) left=\(left.sorted())\n".utf8))
                case "rescue": NotificationCenter.default.post(name: AppModel.rescueRequested, object: nil)
                case "report": NotificationCenter.default.post(name: reportNotification, object: parts[1])
                case "freeup": NotificationCenter.default.post(name: freeUpNotification, object: nil)
                case "timelinedemo": NotificationCenter.default.post(name: timelineDemoNotification, object: nil)
                case "cloudlist":
                    // Read-only: what Keep in the Cloud Only finds, per drive. Nothing is evicted.
                    Task.detached {
                        let context = ScanContext(engine: BulkScanner(), runningApps: [], fullDiskAccess: true)
                        let items = CleanCategory.all.first { $0.id == "icloud" }?.scan(context) ?? []
                        let drives = (try? FileManager.default.contentsOfDirectory(atPath: NSHomeDirectory() + "/Library/CloudStorage")) ?? []
                        FileHandle.standardError.write(Data("[cloudlist] drives=\(drives) items=\(items.count) suggested=\(items.filter { $0.suggested == true }.count)\n".utf8))
                        for item in items.prefix(5) {
                            FileHandle.standardError.write(Data("[cloudlist] \(ByteFormat.string(item.size)) \(item.detail ?? "")\n".utf8))
                        }
                    }
                case "newrule": NotificationCenter.default.post(name: newRuleNotification, object: Int(parts[1]))
                case "closewin": NSApp.windows.filter { $0.canBecomeMain }.forEach { $0.close() }
                case "windows":
                    let titles = NSApp.windows.filter { $0.canBecomeMain && $0.isVisible }.map(\.title)
                    FileHandle.standardError.write(Data("[windows] \(parts[1]) \(titles)\n".utf8))
                case "quit": NSApp.terminate(nil)
                default: break
                }
            }
        }
    }

    /// Sends a real mouse down/up into the window. "x,y" in points from the window's top-left.
    private static func click(_ spec: String) {
        let xy = spec.split(separator: ",").compactMap { Double($0) }
        guard xy.count == 2, let window = NSApp.windows.first(where: { $0.isVisible && $0.canBecomeMain }) else { return }
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

    /// Forgotten-file reminder: which real file it would ask about (read-only), then Keep and
    /// Move to Trash on a fixture of our own in Downloads, put back and removed afterwards.
    private static func reminderSelfTest() {
        func say(_ s: String) { FileHandle.standardError.write(Data("[remindertest] \(s)\n".utf8)) }
        let context = ScanContext(engine: BulkScanner(), runningApps: RunningApps.bundleIDs(), fullDiskAccess: true)
        Task.detached {
            let real = ForgottenReminder.candidate(context: context, ignoringSchedule: true)
            say("would ask about: \(real.map { "\($0.url.path) \(ByteFormat.string($0.size)) last used \($0.lastUsed.map(String.init(describing:)) ?? "?")" } ?? "nothing")")
            let fm = FileManager.default
            let fixture = fm.homeDirectoryForCurrentUser.appendingPathComponent("Downloads/spacebar-selftest-\(UUID().uuidString.prefix(6)).bin")
            fm.createFile(atPath: fixture.path, contents: Data(repeating: 3, count: 16384))
            try? fm.setAttributes([.modificationDate: Date().addingTimeInterval(-90 * 86400)], ofItemAtPath: fixture.path)
            ForgottenReminder.handle(action: ForgottenReminder.keepAction, userInfo: ["path": fixture.path, "bytes": Int64(16384)])
            let kept = UserDefaults.standard.stringArray(forKey: "forgottenReminderKept") ?? []
            say("keep remembered: \(kept.contains(fixture.path))")
            UserDefaults.standard.set(kept.filter { $0 != fixture.path }, forKey: "forgottenReminderKept")
            ForgottenReminder.moveToTrash(fixture, bytes: 16384)
            say("after Move to Trash: at original=\(fm.fileExists(atPath: fixture.path))")
            guard let record = CleaningHistory.load().first(where: { $0.items.contains { $0.original == fixture.path } }) else {
                say("FAIL: no history record"); return
            }
            say("history source=\(record.source.rawValue) restorable=\(record.restorable.count)")
            let back = Cleaner.putBack(record.restorable, dryRun: false)
            say("put back=\(back.restoredItems.count) at original=\(fm.fileExists(atPath: fixture.path))")
            try? fm.removeItem(at: fixture)
            CleaningHistory.remove(record.id)
            say("cleaned up: fixture-gone=\(!fm.fileExists(atPath: fixture.path))")
        }
    }

    static let reportNotification = Notification.Name("Spacebar.debugReport")
    static let freeUpNotification = Notification.Name("Spacebar.debugFreeUp")
    static let offloadTestNotification = Notification.Name("Spacebar.debugOffloadTest")
    static let timelineDemoNotification = Notification.Name("Spacebar.debugTimelineDemo")
    static let newRuleNotification = Notification.Name("Spacebar.debugNewRule")
    private static var historyFixture: URL?

    /// Cleaning history on a fixture of our own: "clean" trashes it with history on, "putback"
    /// restores it from its history record, then removes the fixture and the record.
    private static func historySelfTest(phase: String) {
        func say(_ s: String) { FileHandle.standardError.write(Data("[historytest] \(s)\n".utf8)) }
        let fm = FileManager.default
        if phase == "clean" {
            let fixture = fm.homeDirectoryForCurrentUser
                .appendingPathComponent("Library/Caches/spacebar-selftest-\(UUID().uuidString.prefix(8)).txt")
            fm.createFile(atPath: fixture.path, contents: Data(repeating: 7, count: 8192))
            historyFixture = fixture
            let item = CleanItem(url: fixture, name: fixture.lastPathComponent, size: 8192, date: nil, detail: nil, owner: nil)
            let report = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: false, history: .app)
            say("trashed=\(report.trashedItems.count) exists-at-original=\(fm.fileExists(atPath: fixture.path))")
            return
        }
        guard let fixture = historyFixture,
              let record = CleaningHistory.load().first(where: { $0.items.contains { $0.original == fixture.path } }) else {
            say("FAIL: no history record for the fixture"); return
        }
        let back = record.restorable
        say("record source=\(record.source.rawValue) items=\(record.items.count) restorable=\(back.count)")
        let report = Cleaner.putBack(back, dryRun: false)
        say("restored=\(report.restoredItems.count) back-at-original=\(fm.fileExists(atPath: fixture.path)) restorable-after=\(record.restorable.count)")
        try? fm.removeItem(at: fixture)
        CleaningHistory.remove(record.id)
        say("cleaned up: fixture-gone=\(!fm.fileExists(atPath: fixture.path)) record-gone=\(!CleaningHistory.load().contains { $0.id == record.id })")
    }

    /// Path rules and a real Trash → Put Back on a test drive mounted at /Volumes/<name>.
    private static func driveSelfTest(_ name: String) {
        func say(_ s: String) { FileHandle.standardError.write(Data("[drivetest] \(s)\n".utf8)) }
        let root = URL(fileURLWithPath: "/Volumes/\(name)")
        for path in ["", ".Spotlight-V100", ".Trashes", "Videos", "Videos/clip.mov"] {
            let url = path.isEmpty ? root : root.appendingPathComponent(path)
            say("\(path.isEmpty ? "(drive root)" : path): \(PathRules.reasonNotDeletable(url) ?? "allowed")")
        }
        let file = root.appendingPathComponent("Projects/old-export.zip")
        let item = CleanItem(url: file, name: file.lastPathComponent, size: 1, date: nil, detail: nil, owner: nil)
        let trashed = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: false)
        say("trash: landed=\(trashed.trashedItems.map { $0.url.path }) skipped=\(trashed.skipped.map(\.reason)) inTrash=\(trashed.trashedItems.first.map { Cleaner.isInTrash($0.url) } ?? false)")
        let back = Cleaner.putBack(trashed.trashedItems, dryRun: false)
        say("put back: restored=\(back.restoredItems.count) exists=\(FileManager.default.fileExists(atPath: file.path))")
    }

    /// Posts a key press through the app's event queue (so local monitors see it), e.g. "125" or "51+cmd".
    private static func appKey(_ spec: String) {
        let parts = spec.split(separator: "+")
        guard let code = UInt16(parts[0]), let window = NSApp.keyWindow ?? NSApp.windows.first(where: \.isVisible) else { return }
        var flags: NSEvent.ModifierFlags = []
        if parts.contains("cmd") { flags.insert(.command) }
        if parts.contains("shift") { flags.insert(.shift) }
        let chars = code == 3 ? "f" : code == 0 ? "a" : code == 49 ? " " : ""
        for type in [NSEvent.EventType.keyDown, .keyUp] {
            if let event = NSEvent.keyEvent(with: type, location: .zero, modifierFlags: flags,
                                            timestamp: ProcessInfo.processInfo.systemUptime, windowNumber: window.windowNumber,
                                            context: nil, characters: chars, charactersIgnoringModifiers: chars,
                                            isARepeat: false, keyCode: code) {
                NSApp.postEvent(event, atStart: false)
            }
        }
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
            : candidates.first(where: \.canBecomeMain) ?? candidates.first
        FileHandle.standardError.write(Data("[windows] \(candidates.map { "\(type(of: $0)) level=\($0.level.rawValue)" })\n".utf8))
        guard let window = chosen,
              let image = CGWindowListCreateImage(.null, .optionIncludingWindow, CGWindowID(window.windowNumber),
                                                  [.boundsIgnoreFraming, .bestResolution]) else { return }
        let rep = NSBitmapImageRep(cgImage: image)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
    }
}
