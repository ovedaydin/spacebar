import Foundation

/// A mounted drive Spacebar can measure.
public struct Drive: Identifiable, Hashable, Sendable {
    public var id: URL { url }
    public let url: URL
    public let name: String
    public let total: Int64
    public let available: Int64
    public let isStartup: Bool
    public let isRemovable: Bool

    /// The startup disk first, then other local drives by name.
    public static func mounted() -> [Drive] {
        let keys: [URLResourceKey] = [.volumeLocalizedNameKey, .volumeTotalCapacityKey, .volumeAvailableCapacityKey,
                                      .volumeIsBrowsableKey, .volumeIsLocalKey, .volumeIsRemovableKey,
                                      .volumeIsEjectableKey, .volumeIsRootFileSystemKey]
        let urls = FileManager.default.mountedVolumeURLs(includingResourceValuesForKeys: keys, options: [.skipHiddenVolumes]) ?? []
        return urls.compactMap { url -> Drive? in
            guard let values = try? url.resourceValues(forKeys: Set(keys)), values.volumeIsBrowsable == true,
                  values.volumeIsLocal == true || values.volumeIsRemovable == true else { return nil }
            // Skip the system's own mounts (/System/Volumes/…) and Time Machine destinations.
            if url.path.hasPrefix("/System/") || url.path.hasPrefix("/Volumes/.timemachine") { return nil }
            let isStartup = values.volumeIsRootFileSystem == true || url.path == "/"
            return Drive(url: url, name: values.volumeLocalizedName ?? url.lastPathComponent,
                         total: Int64(values.volumeTotalCapacity ?? 0), available: Int64(values.volumeAvailableCapacity ?? 0),
                         isStartup: isStartup, isRemovable: values.volumeIsEjectable == true || values.volumeIsRemovable == true)
        }
        .sorted { ($0.isStartup ? 0 : 1, $0.name) < ($1.isStartup ? 0 : 1, $1.name) }
    }
}

/// What a non-startup drive is used for: its largest top-level folders.
public struct DriveBreakdown: Sendable {
    public struct Folder: Sendable, Identifiable {
        public var id: String { path }
        public let path: String
        public let name: String
        public let bytes: Int64
    }

    public let drive: Drive
    /// Largest folders and files at the top level, largest first.
    public var folders: [Folder]
    /// Everything else at the top level.
    public var other: Int64
    /// Hidden system folders (.Spotlight-V100, .fseventsd, .Trashes…) and unreadable space.
    public var system: Int64
    public var free: Int64 { drive.available }
    public var complete: Bool

    /// How many folders get their own color; the rest are "Other".
    public static let shownFolders = 7

    public static func analyze(_ drive: Drive, engine: BulkScanner, cancel: CancelToken? = nil,
                               progress: @escaping (DriveBreakdown) -> Void) -> DriveBreakdown {
        let entries = (try? FileManager.default.contentsOfDirectory(at: drive.url, includingPropertiesForKeys: nil)) ?? []
        let visible = entries.filter { !$0.lastPathComponent.hasPrefix(".") }
        var result = DriveBreakdown(drive: drive, folders: [], other: 0, system: 0, complete: false)
        var measured: [Folder] = []
        for url in visible {
            if cancel?.isCancelled == true { break }
            measured.append(Folder(path: url.path, name: url.lastPathComponent, bytes: engine.measure(url, cancel: cancel).allocated))
            measured.sort { $0.bytes > $1.bytes }
            result.folders = Array(measured.prefix(shownFolders))
            result.other = measured.dropFirst(shownFolders).reduce(0) { $0 + $1.bytes }
            progress(result)
        }
        let used = max(0, drive.total - drive.available)
        result.system = max(0, used - measured.reduce(0) { $0 + $1.bytes })
        result.complete = true
        progress(result)
        return result
    }
}
