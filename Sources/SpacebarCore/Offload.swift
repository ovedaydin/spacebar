import Foundation

/// Moving files to another drive without risk: copy, compare every byte, and only then is the
/// original removed (by the caller, through the Cleaner). A copy that doesn't match is deleted
/// again and the original is left alone.
public enum Offload {
    public struct Record: Codable, Sendable, Identifiable, Equatable {
        public var id = UUID()
        public let date: Date
        public let original: String
        public let destination: String
        public let bytes: Int64
        public let drive: String
        /// Set when it was brought back.
        public var broughtBack: Date?

        public init(date: Date, original: String, destination: String, bytes: Int64, drive: String) {
            self.date = date
            self.original = original
            self.destination = destination
            self.bytes = bytes
            self.drive = drive
        }
    }

    public enum Failure: LocalizedError, Equatable {
        case sameDrive
        case notEnoughSpace(needed: Int64)
        case notWritable
        case mismatch(String)

        public var errorDescription: String? {
            switch self {
            case .sameDrive: return String(localized: "It's already on that drive")
            case .notEnoughSpace(let needed): return String(localized: "Not enough space on the drive (needs \(ByteFormat.string(needed)))")
            case .notWritable: return String(localized: "Spacebar can't write to that drive")
            case .mismatch(let path): return String(localized: "The copy didn't match the original (\(path)); the copy was removed")
            }
        }
    }

    /// Room left on the destination after copying, so the drive never ends up completely full.
    public static let margin: Int64 = 1_000_000_000

    /// Checks that `items` (with their sizes) can go to `folder`.
    public static func check(_ items: [(url: URL, bytes: Int64)], to folder: URL) throws {
        func volume(_ url: URL) -> String? {
            (try? url.resourceValues(forKeys: [.volumeIdentifierKey]))?.volumeIdentifier.map { "\($0)" }
        }
        let destination = volume(folder)
        if items.contains(where: { volume($0.url) == destination }) { throw Failure.sameDrive }
        guard FileManager.default.isWritableFile(atPath: folder.path) else { throw Failure.notWritable }
        let needed = items.reduce(0) { $0 + $1.bytes } + margin
        let available = (try? folder.resourceValues(forKeys: [.volumeAvailableCapacityKey]))?.volumeAvailableCapacity ?? 0
        if Int64(available) < needed { throw Failure.notEnoughSpace(needed: needed) }
    }

    /// Copies `source` into `folder` (a new name if something is already there) and verifies the copy
    /// byte for byte. Returns where the copy is. On any problem the partial copy is removed.
    public static func copyAndVerify(_ source: URL, into folder: URL) throws -> URL {
        let destination = freeName(for: source.lastPathComponent, in: folder)
        do {
            try FileManager.default.copyItem(at: source, to: destination)
            try verify(source, destination)
            return destination
        } catch {
            // Only ever removes what this call just created.
            try? FileManager.default.removeItem(at: destination)
            throw error
        }
    }

    /// Throws `.mismatch` unless both trees have the same files with the same bytes.
    public static func verify(_ original: URL, _ copy: URL) throws {
        let fm = FileManager.default
        var isFolder: ObjCBool = false
        guard fm.fileExists(atPath: original.path, isDirectory: &isFolder) else { throw Failure.mismatch(original.lastPathComponent) }
        if !isFolder.boolValue {
            guard try sameBytes(original, copy) else { throw Failure.mismatch(original.lastPathComponent) }
            return
        }
        // Relative paths straight from the file system, whatever form the roots' paths take.
        func listing(_ root: URL) -> [String: Bool] {
            var entries: [String: Bool] = [:]
            for relative in (try? fm.subpathsOfDirectory(atPath: root.path)) ?? [] {
                var isDirectory: ObjCBool = false
                let path = root.appendingPathComponent(relative).path
                // Symlinks count as files (compared by target below), not followed.
                let isLink = (try? fm.attributesOfItem(atPath: path)[.type] as? FileAttributeType) == .typeSymbolicLink
                entries[relative] = !isLink && fm.fileExists(atPath: path, isDirectory: &isDirectory) && isDirectory.boolValue
            }
            return entries
        }
        let a = listing(original), b = listing(copy)
        guard a == b else {
            let missing = Set(a.keys).symmetricDifference(b.keys).sorted().first ?? ""
            throw Failure.mismatch(missing)
        }
        for (relative, isDirectory) in a where !isDirectory {
            let left = original.appendingPathComponent(relative), right = copy.appendingPathComponent(relative)
            if (try? left.resourceValues(forKeys: [.isSymbolicLinkKey]))?.isSymbolicLink == true {
                guard (try? fm.destinationOfSymbolicLink(atPath: left.path)) == (try? fm.destinationOfSymbolicLink(atPath: right.path))
                else { throw Failure.mismatch(relative) }
                continue
            }
            guard try sameBytes(left, right) else { throw Failure.mismatch(relative) }
        }
    }

    /// Streams both files in 1 MB chunks.
    static func sameBytes(_ a: URL, _ b: URL) throws -> Bool {
        let sizeA = try a.resourceValues(forKeys: [.fileSizeKey]).fileSize
        let sizeB = try b.resourceValues(forKeys: [.fileSizeKey]).fileSize
        guard sizeA == sizeB else { return false }
        let left = try FileHandle(forReadingFrom: a), right = try FileHandle(forReadingFrom: b)
        defer { try? left.close(); try? right.close() }
        while true {
            let chunkA = try left.read(upToCount: 1 << 20) ?? Data()
            let chunkB = try right.read(upToCount: 1 << 20) ?? Data()
            if chunkA != chunkB { return false }
            if chunkA.isEmpty { return true }
        }
    }

    /// "Video.mov", or "Video 2.mov" if that's taken.
    static func freeName(for name: String, in folder: URL) -> URL {
        var candidate = folder.appendingPathComponent(name)
        let base = (name as NSString).deletingPathExtension, ext = (name as NSString).pathExtension
        var number = 2
        while FileManager.default.fileExists(atPath: candidate.path) {
            candidate = folder.appendingPathComponent(ext.isEmpty ? "\(base) \(number)" : "\(base) \(number).\(ext)")
            number += 1
        }
        return candidate
    }
}
