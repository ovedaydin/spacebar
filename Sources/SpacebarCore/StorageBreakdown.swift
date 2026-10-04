import Foundation

/// One slice of the startup disk, e.g. "Developer: 92 GB".
public struct StorageSegment: Codable, Sendable, Identifiable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case macOS, apps, documents, media, developer, appData, iCloud, mail, trash, shared, systemData
    }

    /// A labelled piece of a slice, shown in its tooltip.
    public struct Part: Codable, Sendable, Equatable {
        public let name: String
        public let bytes: Int64
    }

    public var id: Kind { kind }
    public let kind: Kind
    public var bytes: Int64
    /// Folder to open in Space Explorer, if the slice maps to one.
    public let explorePath: String?
    public var parts: [Part] = []
    /// Every folder counted in this slice (for opening them together in Space Explorer).
    public var roots: [String]?

    public init(kind: Kind, bytes: Int64, explorePath: String?, parts: [Part] = [], roots: [String]? = nil) {
        self.kind = kind
        self.bytes = bytes
        self.explorePath = explorePath
        self.parts = parts
        self.roots = roots
    }

    public var name: String { kind.name }

    public var explanation: String {
        switch kind {
        case .macOS: return String(localized: "macOS itself, its startup, recovery, update and swap volumes, and assets it downloads (voices, simulator runtimes, models). Managed by macOS.")
        case .apps: return String(localized: "Apps in /Applications and ~/Applications.")
        case .documents: return String(localized: "Documents, Desktop, Downloads and your other folders.")
        case .media: return String(localized: "Pictures (including the Photos library), Music and Movies.")
        case .developer: return String(localized: "Xcode data and simulators, Homebrew, and tool folders like .npm, .gradle and .cache in your home folder.")
        case .appData: return String(localized: "What apps keep in ~/Library: settings, caches, databases, containers.")
        case .iCloud: return String(localized: "iCloud Drive and cloud-storage files downloaded to this Mac.")
        case .mail: return String(localized: "Mail and Messages, including attachments.")
        case .trash: return String(localized: "Items in your Trash.")
        case .shared: return String(localized: "/Users/Shared, which every account can use. Games and some apps keep large content here.")
        case .systemData: return String(localized: "Everything else: system-wide app support in /Library, temporary files and logs, Spotlight's index, snapshots, and folders Spacebar can't read without Full Disk Access.")
        }
    }
}

public extension StorageSegment.Kind {
    var name: String {
        switch self {
        case .macOS: return String(localized: "macOS")
        case .apps: return String(localized: "Apps", comment: "Storage breakdown slice name")
        case .documents: return String(localized: "Documents", comment: "Storage breakdown slice name")
        case .media: return String(localized: "Photos, Music & Movies")
        case .developer: return String(localized: "Developer", comment: "Storage breakdown slice name")
        case .appData: return String(localized: "App Data")
        case .iCloud: return String(localized: "iCloud Drive")
        case .mail: return String(localized: "Mail & Messages")
        case .trash: return String(localized: "Trash")
        case .shared: return String(localized: "Shared Folder")
        case .systemData: return String(localized: "System Data")
        }
    }
}

public struct StorageBreakdown: Codable, Sendable {
    public var total: Int64
    public var free: Int64
    public var purgeable: Int64
    /// In display order. While measuring, only finished slices are present.
    public var segments: [StorageSegment]
    public var measuredAt: Date
    public var complete: Bool
    /// The slice being measured right now.
    public var measuring: StorageSegment.Kind?
    /// Size of every folder measured for the breakdown (display paths), for growth history.
    public var folderSizes: [String: Int64]?

    public init(total: Int64, free: Int64, purgeable: Int64, segments: [StorageSegment],
                measuredAt: Date, complete: Bool, measuring: StorageSegment.Kind?) {
        self.total = total
        self.free = free
        self.purgeable = purgeable
        self.segments = segments
        self.measuredAt = measuredAt
        self.complete = complete
        self.measuring = measuring
    }
}

public extension StorageBreakdown {
    /// Moves `bytes` out of the slice `path` belongs to: into Trash if it was trashed
    /// (same disk, so no space is freed), otherwise into free space.
    mutating func recordRemoval(path: String, bytes: Int64, trashed: Bool) {
        let source = StorageAnalyzer.kind(forPath: path)
        if let index = segments.firstIndex(where: { $0.kind == source }) {
            segments[index].bytes = max(0, segments[index].bytes - bytes)
        }
        if trashed {
            if let index = segments.firstIndex(where: { $0.kind == .trash }) {
                segments[index].bytes += bytes
            } else {
                let position = segments.firstIndex { $0.kind == .shared || $0.kind == .systemData } ?? segments.count
                segments.insert(StorageSegment(kind: .trash, bytes: bytes,
                                               explorePath: FileManager.default.homeDirectoryForCurrentUser
                                                   .appendingPathComponent(".Trash").path), at: position)
            }
        } else {
            free += bytes
        }
    }
}

public extension StorageBreakdown {
    /// Applies new sizes for some measured folders: each folder's slice changes by the difference,
    /// free space is updated, and System Data absorbs the rest so the bar still adds up.
    mutating func update(folders newSizes: [String: Int64], free newFree: Int64?) {
        var sizes = folderSizes ?? [:]
        for (path, bytes) in newSizes {
            let delta = bytes - (sizes[path] ?? 0)
            sizes[path] = bytes
            let kind = StorageAnalyzer.kind(forPath: path)
            if let index = segments.firstIndex(where: { $0.kind == kind }) {
                segments[index].bytes = max(0, segments[index].bytes + delta)
            }
        }
        folderSizes = sizes
        if let newFree { free = newFree }
        if let system = segments.firstIndex(where: { $0.kind == .systemData }) {
            let others = segments.enumerated().filter { $0.offset != system }.reduce(Int64(0)) { $0 + $1.element.bytes }
            segments[system].bytes = max(0, total - free - others)
        }
    }

    /// The reverse of trashing: `bytes` leave the Trash slice and return to the one `path` is in.
    mutating func recordRestore(path: String, bytes: Int64) {
        if let trash = segments.firstIndex(where: { $0.kind == .trash }) {
            segments[trash].bytes = max(0, segments[trash].bytes - bytes)
        }
        let target = StorageAnalyzer.kind(forPath: path)
        if let index = segments.firstIndex(where: { $0.kind == target }) {
            segments[index].bytes += bytes
        }
    }
}

public enum StorageAnalyzer {
    /// The path to measure for a display path: through the data volume, like `analyze` does.
    public static func measurablePath(_ display: String) -> String {
        let data = "/System/Volumes/Data" + display
        return FileManager.default.fileExists(atPath: data) ? data : display
    }

    /// Folders to watch for live updates of the breakdown.
    public static var watchedFolders: [String] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return [home, "/Applications", "/Users/Shared", "/opt", "/usr/local", "/Library/Developer"]
            .filter { FileManager.default.fileExists(atPath: $0) }
    }

    /// "/System/Volumes/Data/opt" → "/opt": the path people know.
    public static func displayPath(_ path: String) -> String {
        path.hasPrefix("/System/Volumes/Data/") ? String(path.dropFirst("/System/Volumes/Data".count)) : path
    }

    /// Which slice a path is counted in. Mirrors the roots measured by `analyze`.
    public static func kind(forPath rawPath: String) -> StorageSegment.Kind {
        var path = rawPath
        if path.hasPrefix("/System/Volumes/Data/") { path.removeFirst("/System/Volumes/Data".count) }
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        func under(_ prefix: String) -> Bool { path == prefix || path.hasPrefix(prefix + "/") }

        if under(home + "/.Trash") { return .trash }
        if under("/Users/Shared") { return .shared }
        if under("/Applications") || under(home + "/Applications") { return .apps }
        if under("/opt") || under("/usr/local") || under("/Library/Developer") || under(home + "/Library/Developer") {
            return .developer
        }
        if under("/System") { return .macOS }
        if under(home + "/Library/Mobile Documents") || under(home + "/Library/CloudStorage") { return .iCloud }
        if under(home + "/Library/Mail") || under(home + "/Library/Messages")
            || under(home + "/Library/Containers/com.apple.mail") { return .mail }
        if under(home + "/Library") { return .appData }
        if under(home + "/Pictures") || under(home + "/Music") || under(home + "/Movies") { return .media }
        if path.hasPrefix(home + "/") {
            let first = path.dropFirst(home.count + 1).split(separator: "/").first.map(String.init) ?? ""
            return first.hasPrefix(".") ? .developer : .documents
        }
        return .systemData
    }

    struct Volumes {
        let total: Int64
        let free: Int64
        let macOS: Int64
        let data: Int64
    }

    /// Reads the APFS container holding the startup disk from `diskutil apfs list -plist`.
    static func volumes() -> Volumes? {
        guard let data = runCommand("/usr/sbin/diskutil", ["apfs", "list", "-plist"], timeout: 15),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let containers = plist["Containers"] as? [[String: Any]] else { return nil }
        for container in containers {
            let volumes = container["Volumes"] as? [[String: Any]] ?? []
            func roles(_ volume: [String: Any]) -> [String] { volume["Roles"] as? [String] ?? [] }
            func used(_ volume: [String: Any]) -> Int64 { (volume["CapacityInUse"] as? NSNumber)?.int64Value ?? 0 }
            guard let dataVolume = volumes.first(where: { roles($0).contains("Data") }),
                  volumes.contains(where: { roles($0).contains("System") }) else { continue }
            let systemRoles: Set<String> = ["System", "Preboot", "Recovery", "Update", "VM"]
            let macOS = volumes.filter { !systemRoles.isDisjoint(with: roles($0)) }.reduce(Int64(0)) { $0 + used($1) }
            return Volumes(total: (container["CapacityCeiling"] as? NSNumber)?.int64Value ?? 0,
                           free: (container["CapacityFree"] as? NSNumber)?.int64Value ?? 0,
                           macOS: macOS, data: used(dataVolume))
        }
        return nil
    }

    /// Measures every slice. Blocking; calls `progress` after each slice.
    public static func analyze(engine: BulkScanner, cancel: CancelToken? = nil,
                               progress: @escaping (StorageBreakdown) -> Void) -> StorageBreakdown? {
        guard let volumes = volumes() else { return nil }
        let fm = FileManager.default
        let home = fm.homeDirectoryForCurrentUser
        let data = "/System/Volumes/Data"
        func inHome(_ path: String) -> URL { home.appendingPathComponent(path) }
        func list(_ url: URL) -> [URL] { (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? [] }

        let homeEntries = list(home)
        let mediaNames: Set<String> = ["Pictures", "Music", "Movies"]
        let skippedHome: Set<String> = ["Library", ".Trash", "Applications"]
        let libraryElsewhere: Set<String> = ["Developer", "Mobile Documents", "CloudStorage", "Mail", "Messages"]

        let slices: [(StorageSegment.Kind, [URL], String?)] = [
            (.apps, [URL(fileURLWithPath: "\(data)/Applications"), inHome("Applications")], "/Applications"),
            (.documents, homeEntries.filter {
                let name = $0.lastPathComponent
                return !name.hasPrefix(".") && !mediaNames.contains(name) && !skippedHome.contains(name)
            }, inHome("Documents").path),
            (.media, mediaNames.sorted().map(inHome), inHome("Pictures").path),
            (.developer, [inHome("Library/Developer"), URL(fileURLWithPath: "\(data)/opt"),
                          URL(fileURLWithPath: "\(data)/usr/local"), URL(fileURLWithPath: "\(data)/Library/Developer")]
                + homeEntries.filter { $0.lastPathComponent.hasPrefix(".") && !skippedHome.contains($0.lastPathComponent) },
             inHome("Library/Developer").path),
            (.appData, list(inHome("Library")).filter { !libraryElsewhere.contains($0.lastPathComponent) }
                .flatMap { $0.lastPathComponent == "Containers"
                    ? list($0).filter { $0.lastPathComponent != "com.apple.mail" } : [$0] },
             inHome("Library").path),
            (.iCloud, [inHome("Library/Mobile Documents"), inHome("Library/CloudStorage")], inHome("Library/Mobile Documents").path),
            (.mail, [inHome("Library/Mail"), inHome("Library/Messages"), inHome("Library/Containers/com.apple.mail")],
             inHome("Library/Mail").path),
            (.trash, [inHome(".Trash")], inHome(".Trash").path),
            (.shared, [URL(fileURLWithPath: "\(data)/Users/Shared")], "/Users/Shared"),
        ]

        let purgeable = VolumeSpace.home()?.purgeable ?? 0
        var breakdown = StorageBreakdown(total: volumes.total, free: volumes.free, purgeable: purgeable,
                                         segments: [StorageSegment(kind: .macOS, bytes: volumes.macOS, explorePath: nil)],
                                         measuredAt: Date(), complete: false, measuring: slices.first?.0)
        progress(breakdown)

        var measured: Int64 = 0
        for (index, slice) in slices.enumerated() {
            if cancel?.isCancelled == true { return nil }
            let roots = slice.1.filter { fm.fileExists(atPath: $0.path) }
            let sizes = engine.measure(roots, cancel: cancel)
            let bytes = sizes.reduce(Int64(0)) { $0 + $1.allocated }
            var folders = breakdown.folderSizes ?? [:]
            for (root, size) in zip(roots, sizes) { folders[displayPath(root.path)] = size.allocated }
            breakdown.folderSizes = folders
            measured += bytes
            breakdown.segments.append(StorageSegment(kind: slice.0, bytes: bytes, explorePath: slice.2,
                                                     roots: roots.map { displayPath($0.path) }))
            breakdown.measuring = index + 1 < slices.count ? slices[index + 1].0 : nil
            progress(breakdown)
        }
        // macOS-managed downloads on the data volume belong with macOS.
        let assets = engine.measure(URL(fileURLWithPath: "\(data)/System"), cancel: cancel).allocated
        breakdown.segments[0].bytes += assets
        breakdown.segments[0].parts = [.init(name: String(localized: "System and support volumes"), bytes: volumes.macOS),
                                       .init(name: String(localized: "Downloaded system assets"), bytes: assets)]
        measured += assets

        // System Data is the remainder; itemize what can be measured.
        let libraryRoots = list(URL(fileURLWithPath: "\(data)/Library"))
            .filter { $0.lastPathComponent != "Developer" && $0.lastPathComponent != "Updates" }
        // A downloaded macOS update waiting to install.
        let updates = engine.measure([URL(fileURLWithPath: "\(data)/Library/Updates"),
                                      URL(fileURLWithPath: "\(data)/MobileSoftwareUpdate")]
                                         .filter { fm.fileExists(atPath: $0.path) }, cancel: cancel)
            .reduce(Int64(0)) { $0 + $1.allocated }
        let updateSnapshots = (runCommand("/usr/bin/tmutil", ["listlocalsnapshots", "/"]).map { String(decoding: $0, as: UTF8.self) } ?? "")
            .split(separator: "\n").filter { $0.hasPrefix("com.apple.os.update-") }.count
        let library = engine.measure(libraryRoots, cancel: cancel).reduce(Int64(0)) { $0 + $1.allocated }
        let privateFiles = engine.measure(URL(fileURLWithPath: "\(data)/private"), cancel: cancel).allocated
        let remainder = max(0, volumes.data - measured)
        var systemData = StorageSegment(kind: .systemData, bytes: remainder, explorePath: "/Library",
                                        roots: (libraryRoots.map(\.path) + ["\(data)/private"]).map(displayPath))
        let other = max(0, remainder - library - privateFiles - updates)
        systemData.parts = [.init(name: String(localized: "System-wide app support (/Library)"), bytes: min(library, remainder)),
                            .init(name: String(localized: "Temporary files, logs and system databases"), bytes: min(privateFiles, remainder)),
                            .init(name: String(localized: "macOS update downloaded, waiting to install"), bytes: min(updates, remainder)),
                            .init(name: updateSnapshots > 0
                                  ? String(localized: "Snapshots (\(updateSnapshots) made by macOS updates, removed by macOS), indexes and unreadable folders")
                                  : String(localized: "Snapshots, indexes and unreadable folders"), bytes: other)]
        breakdown.segments.append(systemData)
        breakdown.complete = true
        breakdown.measuredAt = Date()
        progress(breakdown)
        return breakdown
    }
}
