import AppKit
import Foundation

public struct VolumeSpace: Sendable {
    public let total: Int64
    /// Truly free right now (statfs).
    public let free: Int64
    /// What Finder shows as "available": free + purgeable.
    public let available: Int64

    public var purgeable: Int64 { max(0, available - free) }
    public var used: Int64 { max(0, total - free) }

    /// The volume holding the user's home folder (the APFS Data volume on modern macOS).
    public static func home() -> VolumeSpace? {
        let url = FileManager.default.homeDirectoryForCurrentUser
        guard let values = try? url.resourceValues(forKeys: [
            .volumeTotalCapacityKey, .volumeAvailableCapacityKey, .volumeAvailableCapacityForImportantUsageKey,
        ]), let total = values.volumeTotalCapacity, let free = values.volumeAvailableCapacity else { return nil }
        // "Important usage" is APFS-only; fall back to statfs elsewhere.
        let important = values.volumeAvailableCapacityForImportantUsage ?? 0
        return VolumeSpace(total: Int64(total), free: Int64(free), available: max(Int64(free), important))
    }
}

public enum FullDiskAccess {
    /// There is no API for this. Try to list folders that only Full Disk Access unlocks.
    /// Returns nil when no probe folder exists to decide.
    public static func isGranted() -> Bool? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let probes = ["Library/Containers/com.apple.stocks", "Library/Safari", "Library/Mail", ".Trash"]
        for probe in probes {
            let url = home.appendingPathComponent(probe)
            do {
                _ = try FileManager.default.contentsOfDirectory(atPath: url.path)
                return true
            } catch let error as CocoaError where error.code == .fileReadNoPermission {
                return false
            } catch let error as NSError where error.domain == NSPOSIXErrorDomain
                && (error.code == Int(EPERM) || error.code == Int(EACCES)) {
                return false
            } catch {
                continue // missing folder: try the next probe
            }
        }
        return nil
    }

    /// Opens System Settings at Privacy & Security → Full Disk Access.
    public static func openSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_AllFiles",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles",
        ]
        for string in candidates {
            if let url = URL(string: string), NSWorkspace.shared.open(url) { return }
        }
    }
}

public enum LocalSnapshots {
    /// Time Machine local snapshots on the startup disk. They show up as "purgeable"
    /// and macOS removes them when space is needed. OS update snapshots are excluded.
    public static func list() -> [String] {
        guard let data = Tools.run("/usr/bin/tmutil", ["listlocalsnapshots", "/"], timeout: 20)?.output else { return [] }
        return String(decoding: data, as: UTF8.self)
            .split(separator: "\n")
            .map(String.init)
            .filter { $0.hasPrefix("com.apple.TimeMachine.") }
    }
}

public enum RunningApps {
    public static func bundleIDs() -> Set<String> {
        Set(NSWorkspace.shared.runningApplications.compactMap(\.bundleIdentifier))
    }
}
