import CoreServices
import Foundation

/// Whether a file is in the last Time Machine backup, so it's safer to delete.
public enum TimeMachine {
    /// When the most recent backup finished, from Time Machine's settings (readable without an
    /// administrator). nil when Time Machine isn't set up or has never backed up.
    public static func lastBackup(settings: URL = URL(fileURLWithPath: "/Library/Preferences/com.apple.TimeMachine.plist")) -> Date? {
        guard let data = try? Data(contentsOf: settings),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let destinations = plist["Destinations"] as? [[String: Any]] else { return nil }
        return destinations.flatMap { destination -> [Date] in
            (destination["SnapshotDates"] as? [Date] ?? []) + [destination["ReferenceLocalSnapshotDate"] as? Date].compactMap { $0 }
        }.max()
    }

    /// Whether Time Machine skips this item (the user excluded it, or it's a standard exclusion
    /// such as caches).
    public static func isExcluded(_ url: URL) -> Bool {
        var byPath: DarwinBoolean = false
        return CSBackupIsItemExcluded(url as CFURL, &byPath)
    }

    /// The file is in the backup if Time Machine includes it and it hasn't changed since.
    public static func isBackedUp(modified: Date?, excluded: Bool, lastBackup: Date?) -> Bool {
        guard let lastBackup, let modified, !excluded else { return false }
        return modified < lastBackup
    }
}
