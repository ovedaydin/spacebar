import Foundation

/// macOS settings that decide how much space things take. Read only: Spacebar shows them and
/// opens the right place to change them, it never changes them itself.
public enum SpaceSettings {
    public enum Status: Sendable, Equatable {
        /// Already set to save space.
        case saving
        /// Could save space if changed.
        case couldSave
        /// macOS doesn't let apps read it; check it yourself.
        case unknown
    }

    public struct Item: Sendable, Identifiable {
        public let id: String
        public let title: String
        public let detail: String
        public let status: Status
        /// The space it's about (measured), if any.
        public let bytes: Int64?
        /// Where to change it: an app to open, or a System Settings URL.
        public let open: URL
        /// Where the switch is, once there.
        public let whereToFind: String
    }

    /// The folder each setting is about, relative to home (measured separately, since that's slow).
    public static let folders: [String: [String]] = [
        "icloud": ["Library/Mobile Documents"], "trash30": [".Trash"], "messages": ["Library/Messages"],
        "photos": ["Pictures/Photos Library.photoslibrary"], "music": ["Music/Music/Media.localized", "Music/Music/Media"],
        "mail": ["Library/Mail"],
    ]

    /// Size of the folder a setting is about (blocking), if it exists.
    public static func size(of id: String, home: URL = FileManager.default.homeDirectoryForCurrentUser, engine: SizeEngine) -> Int64? {
        for path in folders[id] ?? [] {
            let url = home.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            let total = engine.measure(url, cancel: nil).allocated
            if total > 0 { return total }
        }
        return nil
    }

    /// Reads the settings (instant); sizes come from `sizes`.
    public static func check() -> [Item] {
        func defaults(_ domain: String) -> UserDefaults? { UserDefaults(suiteName: domain) }
        func size(_ relative: String) -> Int64? { nil }
        let app = { (path: String) in URL(fileURLWithPath: path) }
        var items: [Item] = []

        // iCloud Drive: keep files in iCloud when space is low.
        let optimize = defaults("com.apple.bird")?.object(forKey: "optimize-storage") as? Bool
        items.append(Item(id: "icloud", title: String(localized: "Optimize Mac Storage (iCloud Drive)"),
                          detail: String(localized: "When space runs low, macOS keeps older iCloud Drive files only in iCloud and downloads them when you open them."),
                          status: optimize == true ? .saving : optimize == false ? .couldSave : .unknown,
                          bytes: size("Library/Mobile Documents"),
                          open: URL(string: "x-apple.systempreferences:com.apple.systempreferences.AppleIDSettings")!,
                          whereToFind: String(localized: "System Settings › your name › iCloud › Drive")))

        // Finder: empty the Trash after 30 days.
        let removeOld = defaults("com.apple.finder")?.bool(forKey: "FXRemoveOldTrashItems") ?? false
        items.append(Item(id: "trash30", title: String(localized: "Remove items from the Trash after 30 days"),
                          detail: String(localized: "Finder deletes what's been in the Trash for 30 days, so it doesn't quietly fill up."),
                          status: removeOld ? .saving : .couldSave, bytes: size(".Trash"),
                          open: app("/System/Library/CoreServices/Finder.app"),
                          whereToFind: String(localized: "Finder › Settings › Advanced")))

        // Messages: how long to keep messages (and their attachments).
        let keepDays = defaults("com.apple.MobileSMS")?.integer(forKey: "KeepMessageForDays") ?? 0
        items.append(Item(id: "messages", title: String(localized: "Keep messages"),
                          detail: keepDays > 0
                              ? String(localized: "Messages deletes messages and their attachments after \(keepDays) days.")
                              : String(localized: "Messages keeps every message and attachment forever. Choosing 1 year deletes older ones."),
                          status: keepDays > 0 ? .saving : .couldSave, bytes: size("Library/Messages"),
                          open: app("/System/Applications/Messages.app"),
                          whereToFind: String(localized: "Messages › Settings › General › Keep messages")))

        // These are stored inside the apps' own databases, which apps can't read.
        items.append(Item(id: "photos", title: String(localized: "Optimize Mac Storage (Photos)"),
                          detail: String(localized: "With iCloud Photos, keeps smaller versions on this Mac and full-size originals in iCloud."),
                          status: .unknown, bytes: size("Pictures/Photos Library.photoslibrary"),
                          open: app("/System/Applications/Photos.app"),
                          whereToFind: String(localized: "Photos › Settings › iCloud")))
        items.append(Item(id: "music", title: String(localized: "Automatic downloads (Music)"),
                          detail: String(localized: "Music can download everything you add to your library. Turning it off keeps songs streaming instead."),
                          status: .unknown, bytes: size("Music/Music/Media.localized") ?? size("Music/Music/Media"),
                          open: app("/System/Applications/Music.app"),
                          whereToFind: String(localized: "Music › Settings › General › Automatic downloads")))
        items.append(Item(id: "mail", title: String(localized: "Download attachments (Mail)"),
                          detail: String(localized: "Mail can download every attachment. \"Recent\" or \"None\" keeps older ones on the server until you open them."),
                          status: .unknown, bytes: size("Library/Mail"),
                          open: app("/System/Applications/Mail.app"),
                          whereToFind: String(localized: "Mail › Settings › Accounts › Account Information › Download Attachments")))
        return items
    }
}
