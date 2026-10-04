import Foundation

/// The hidden files macOS leaves on drives it doesn't own (FAT, exFAT, NTFS): ._ copies of every
/// file, .DS_Store, the drive's Trash, and Spotlight and FSEvents data. Clutter on a USB stick
/// shared with Windows, a TV or a camera. Mac-formatted drives are left alone.
public enum DriveCleanup {
    public struct Found: Sendable {
        public var files: [URL] = []
        public var bytes: Int64 = 0
        /// Files whose ._ companion macOS keeps out of sight (it shows them as extended attributes);
        /// removed with Apple's dot_clean.
        public var appleDouble = 0
        public var count: Int { files.count + appleDouble }
    }

    /// Folders macOS makes at the top of a drive.
    static let rootFolders: Set<String> = [".Trashes", ".Spotlight-V100", ".fseventsd", ".TemporaryItems", ".DocumentRevisions-V100"]
    static let rootFiles: Set<String> = [".apdisk", ".VolumeIcon.icns"]

    /// File systems where these files are clutter.
    public static func applies(to volume: URL) -> Bool {
        var info = statfs()
        guard statfs(volume.path, &info) == 0 else { return false }
        let type = withUnsafeBytes(of: info.f_fstypename) { String(decoding: $0.prefix { $0 != 0 }, as: UTF8.self) }
        return ["msdos", "exfat", "ntfs", "fusefs", "lifs"].contains(type.lowercased())
    }

    /// Whether `url` is one of the hidden files this removes, on `volume`.
    public static func isClutter(_ url: URL, on volume: URL) -> Bool {
        let root = volume.standardizedFileURL.path
        let path = url.standardizedFileURL.path
        guard path.hasPrefix(root + "/") else { return false }
        let name = url.lastPathComponent
        let atRoot = url.deletingLastPathComponent().standardizedFileURL.path == root
        if atRoot && (rootFolders.contains(name) || rootFiles.contains(name)) { return true }
        return name == ".DS_Store" || (name.hasPrefix("._") && name.count > 2)
    }

    /// Finds the clutter on `volume`. Blocking.
    public static func find(on volume: URL, cancel: CancelToken? = nil) -> Found {
        var found = Found()
        let fm = FileManager.default
        func size(_ url: URL) -> Int64 {
            if let walker = fm.enumerator(at: url, includingPropertiesForKeys: [.totalFileAllocatedSizeKey]),
               (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true {
                var total: Int64 = 0
                while let item = walker.nextObject() as? URL {
                    total += Int64((try? item.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
                }
                return total
            }
            return Int64((try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
        }
        guard let walker = fm.enumerator(at: volume, includingPropertiesForKeys: [.isDirectoryKey], options: [],
                                         errorHandler: { _, _ in true }) else { return found }
        while let url = walker.nextObject() as? URL {
            if cancel?.isCancelled == true { break }
            guard isClutter(url, on: volume) else {
                // Extra data (tags, Finder info) lives in a hidden ._ file on these drives.
                if listxattr(url.path, nil, 0, XATTR_NOFOLLOW) > 0 {
                    found.appleDouble += 1
                    found.bytes += 4096
                }
                continue
            }
            found.files.append(url)
            found.bytes += size(url)
            if (try? url.resourceValues(forKeys: [.isDirectoryKey]))?.isDirectory == true { walker.skipDescendants() }
        }
        return found
    }

    /// Deletes what `find` found, checking each item again, then has Apple's dot_clean remove the
    /// hidden ._ files. Returns bytes freed (the ._ files counted as found).
    @discardableResult
    public static func remove(_ found: Found, on volume: URL) -> Int64 {
        guard applies(to: volume) else { return 0 }
        var freed: Int64 = 0
        for url in found.files where isClutter(url, on: volume) {
            let bytes = Int64((try? url.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
            if (try? FileManager.default.removeItem(at: url)) != nil { freed += bytes }
        }
        // -m: always delete ._ files (this drive can't keep the data anyway outside a Mac).
        let dotClean = "/usr/sbin/dot_clean"
        if found.appleDouble > 0, Tools.isRootProtected(dotClean), Tools.isTrusted(dotClean, requirement: "anchor apple"),
           Tools.run(dotClean, ["-m", volume.path], timeout: 600)?.status == 0 {
            freed += Int64(found.appleDouble) * 4096
        }
        return freed
    }
}
