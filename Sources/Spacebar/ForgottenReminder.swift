import AppKit
import SpacebarCore
import UserNotifications

/// Once a week at most: "Xcode.dmg (4 GB) has been sitting in Downloads for 2 months. Keep it?"
/// with Move to Trash and Keep buttons. Nothing is removed unless the button is clicked, and the
/// file is checked again at that moment.
enum ForgottenReminder {
    static let category = "spacebar.forgotten"
    static let trashAction = "trash"
    static let keepAction = "keep"
    /// Only files at least this big, not opened for this long.
    static let minimumBytes: Int64 = 500_000_000
    static let minimumDays = 60

    /// Files the user chose to keep; never asked about again.
    private static let keptKey = "forgottenReminderKept"
    private static let lastKey = "lastForgottenReminder"

    static func registerActions() {
        let trash = UNNotificationAction(identifier: trashAction, title: String(localized: "Move to Trash"), options: [.destructive])
        let keep = UNNotificationAction(identifier: keepAction, title: String(localized: "Keep"), options: [])
        let rescue = UNNotificationAction(identifier: AppModel.rescueAction, title: String(localized: "Free Space Now"), options: [])
        UNUserNotificationCenter.current().setNotificationCategories([
            UNNotificationCategory(identifier: category, actions: [trash, keep], intentIdentifiers: [], options: []),
            UNNotificationCategory(identifier: AppModel.lowDiskCategory, actions: [rescue], intentIdentifiers: [], options: []),
        ])
    }

    /// Picks the largest forgotten file worth asking about, if a week has passed. Blocking.
    static func candidate(context: ScanContext, now: Date = Date(), ignoringSchedule: Bool = false) -> CleanItem? {
        let defaults = UserDefaults.standard
        if !ignoringSchedule, let last = defaults.object(forKey: lastKey) as? Date, now.timeIntervalSince(last) < 7 * 86400 { return nil }
        guard let forgotten = CleanCategory.all.first(where: { $0.id == "forgotten" }) else { return nil }
        let kept = Set(defaults.stringArray(forKey: keptKey) ?? [])
        let cutoff = now.addingTimeInterval(-Double(minimumDays) * 86400)
        return forgotten.scan(context)
            .filter { $0.isSelectable && $0.size >= minimumBytes && !kept.contains($0.url.path)
                && ($0.lastUsed ?? now) < cutoff }
            .max { $0.size < $1.size }
    }

    static func ask(about item: CleanItem, now: Date = Date()) {
        UserDefaults.standard.set(now, forKey: lastKey)
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            let folder = FileManager.default.displayName(atPath: item.url.deletingLastPathComponent().path)
            content.title = String(localized: "Still need \(item.name)?")
            let age = item.lastUsed.map { RelativeDateTimeFormatter().localizedString(for: $0, relativeTo: now) }
            content.body = age.map { String(localized: "\(ByteFormat.string(item.size)) in \(folder), last opened \($0).") }
                ?? String(localized: "\(ByteFormat.string(item.size)) in \(folder).")
            content.categoryIdentifier = category
            content.userInfo = ["path": item.url.path, "bytes": item.size]
            UNUserNotificationCenter.current().add(UNNotificationRequest(identifier: "forgotten-\(item.url.path)",
                                                                         content: content, trigger: nil))
        }
    }

    /// Handles a click on the notification or one of its buttons.
    static func handle(action: String, userInfo: [AnyHashable: Any]) {
        guard let path = userInfo["path"] as? String else { return }
        let url = URL(fileURLWithPath: path)
        switch action {
        case keepAction:
            var kept = UserDefaults.standard.stringArray(forKey: keptKey) ?? []
            if !kept.contains(path) { kept.append(path) }
            UserDefaults.standard.set(kept, forKey: keptKey)
        case trashAction:
            Task.detached(priority: .userInitiated) { moveToTrash(url, bytes: userInfo["bytes"] as? Int64 ?? 0) }
        default:
            // Clicking the notification: show the file's folder in Space Explorer.
            Task { @MainActor in FinderIntegration.request(url.deletingLastPathComponent()) }
        }
    }

    /// Checks again that it's the same untouched file in Downloads or on the Desktop, then trashes it
    /// (recorded in History, so it can be put back). Respects Dry Run.
    static func moveToTrash(_ url: URL, bytes: Int64) {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let allowed = ["Downloads", "Desktop"].map { home.appendingPathComponent($0).path + "/" }
        guard allowed.contains(where: { url.path.hasPrefix($0) }), FileManager.default.fileExists(atPath: url.path),
              let values = try? url.resourceValues(forKeys: [.contentModificationDateKey]),
              (values.contentModificationDate ?? .distantFuture) < Date().addingTimeInterval(-Double(minimumDays) * 86400)
        else { return }
        let item = CleanItem(url: url, name: url.lastPathComponent, size: bytes, date: nil, detail: nil, owner: nil)
        let report = Cleaner.run([Cleaner.Request(item: item, mode: .trash)], dryRun: Headless.Settings.current().dryRun,
                                 history: .reminder)
        if !report.dryRun { TrashLedger.record(report.trashedItems) }
        DispatchQueue.main.async { NotificationCenter.default.post(name: Headless.cleanedNotification, object: nil) }
    }
}
