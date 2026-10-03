import Foundation

/// Result of measuring one root (a file or a directory tree).
public struct SizeTotals: Sendable, Equatable, Codable {
    /// Bytes allocated on disk ("size on disk"), hard links counted once.
    public var allocated: Int64 = 0
    public var files: Int = 0
    public var directories: Int = 0
    /// iCloud / File Provider placeholders that are not stored locally (not counted in `allocated`).
    public var cloudOnlyFiles: Int = 0
    /// Directories or entries that could not be read (permissions, TCC, errors).
    public var unreadable: Int = 0
    /// Newest modification time of anything in the tree (seconds since 1970, 0 if unknown).
    /// A proxy for "last used": access times aren't reliable on APFS.
    public var newestModification: TimeInterval = 0

    public var lastModified: Date? {
        newestModification > 0 ? Date(timeIntervalSince1970: newestModification) : nil
    }

    public init() {}

    public mutating func add(_ other: SizeTotals) {
        allocated += other.allocated
        files += other.files
        directories += other.directories
        cloudOnlyFiles += other.cloudOnlyFiles
        unreadable += other.unreadable
        newestModification = max(newestModification, other.newestModification)
    }
}

/// Cooperative cancellation flag that can be shared with scanner threads.
public final class CancelToken: @unchecked Sendable {
    private let lock = NSLock()
    private var cancelled = false
    public init() {}
    public var isCancelled: Bool { lock.lock(); defer { lock.unlock() }; return cancelled }
    public func cancel() { lock.lock(); cancelled = true; lock.unlock() }
}

public protocol SizeEngine: Sendable {
    var name: String { get }
    /// Measures each root independently. Blocking: call off the main thread.
    func measure(_ roots: [URL], cancel: CancelToken?) -> [SizeTotals]
}

public extension SizeEngine {
    func measure(_ root: URL, cancel: CancelToken? = nil) -> SizeTotals {
        measure([root], cancel: cancel)[0]
    }
}

public enum ByteFormat {
    public static func string(_ bytes: Int64) -> String {
        ByteCountFormatter.string(fromByteCount: bytes, countStyle: .file)
    }
}

/// Process-wide I/O policies that make scanning safe and cheap.
public enum IOPolicy {
    /// Call once at startup, before any scanning:
    /// - never download iCloud/File Provider placeholders just because we looked at them
    /// - don't update access times while walking the disk
    public static func configureForScanning() {
        _ = setiopolicy_np(IOPOL_TYPE_VFS_MATERIALIZE_DATALESS_FILES, IOPOL_SCOPE_PROCESS, IOPOL_MATERIALIZE_DATALESS_FILES_OFF)
        _ = setiopolicy_np(IOPOL_TYPE_VFS_ATIME_UPDATES, IOPOL_SCOPE_PROCESS, IOPOL_ATIME_UPDATES_OFF)
    }
}
