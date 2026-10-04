import CryptoKit
import Foundation

/// Whole folders that are copies of each other (old project copies, "Photos (1)", backups of
/// backups). Fingerprints are built bottom-up from names, sizes and subfolders; candidates are then
/// checked file by file, and only space that deleting would really free counts (APFS clones don't).
enum DuplicateFolders {
    struct Group {
        let keep: URL
        let copies: [(url: URL, freed: Int64)]
    }

    static let skipped: Set<String> = ["Library", "node_modules", ".git", "Pods", "DerivedData", ".build", "build", "target"]

    static func find(home: URL, minSize: Int64 = 50_000_000, cancel: CancelToken? = nil) -> [Group] {
        var bySignature: [Data: [(url: URL, size: Int64)]] = [:]
        // Post-order walk: a folder's fingerprint covers its files (name and size) and its
        // subfolders' fingerprints, so equal fingerprints mean equal trees.
        func fingerprint(_ folder: URL, depth: Int) -> (Data, Int64)? {
            if cancel?.isCancelled == true { return nil }
            let keys: Set<URLResourceKey> = [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .fileSizeKey]
            guard let children = try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: Array(keys),
                                                                               options: [.skipsHiddenFiles]) else { return nil }
            var hasher = SHA256()
            var total: Int64 = 0
            for child in children.sorted(by: { $0.lastPathComponent < $1.lastPathComponent }) {
                guard let values = try? child.resourceValues(forKeys: keys), values.isSymbolicLink != true else { continue }
                let name = child.lastPathComponent
                if values.isDirectory == true && values.isPackage != true {
                    if depth == 0 && name == "Library" || skipped.contains(name) { continue }
                    guard let (sub, size) = fingerprint(child, depth: depth + 1) else { continue }
                    hasher.update(data: Data("d:\(name):".utf8)); hasher.update(data: sub)
                    total += size
                } else if values.isDirectory != true {
                    let size = Int64(values.fileSize ?? 0)
                    hasher.update(data: Data("f:\(name):\(size);".utf8))
                    total += size
                }
            }
            let signature = Data(hasher.finalize())
            if depth > 0 && total >= minSize { bySignature[signature, default: []].append((folder, total)) }
            return (signature, total)
        }
        _ = fingerprint(home, depth: 0)

        let homePath = home.path
        var groups: [Group] = []
        var reported: [String] = []
        // Largest first, so a duplicate folder's subfolders aren't reported again.
        for members in bySignature.values.filter({ $0.count > 1 }).sorted(by: { $0[0].size > $1[0].size }) {
            if cancel?.isCancelled == true { break }
            let fresh = members.filter { member in !reported.contains { member.url.path.hasPrefix($0 + "/") || member.url.path == $0 } }
            guard fresh.count > 1 else { continue }
            // Same names and sizes can still differ in content: split into truly identical clusters.
            var clusters: [[URL]] = []
            for member in fresh {
                if let index = clusters.firstIndex(where: { sameContents($0[0], member.url) }) {
                    clusters[index].append(member.url)
                } else {
                    clusters.append([member.url])
                }
            }
            for cluster in clusters where cluster.count > 1 {
                let ranked = cluster.sorted { score($0, home: homePath) < score($1, home: homePath) }
                let copies = ranked.dropFirst().compactMap { url -> (url: URL, freed: Int64)? in
                    let freed = reclaimable(url)
                    return freed >= minSize / 2 ? (url, freed) : nil // mostly clones: deleting frees little
                }
                guard !copies.isEmpty else { continue }
                groups.append(Group(keep: ranked[0], copies: copies))
                reported += [ranked[0].path] + copies.map(\.url.path)
            }
        }
        return groups
    }

    /// Which copy to keep: not in Downloads, shallowest, then the one without "copy" or "(1)" in its name.
    static func score(_ url: URL, home: String) -> (Int, Int, Int) {
        let inDownloads = url.path.hasPrefix(home + "/Downloads/") ? 1 : 0
        let name = url.lastPathComponent.lowercased()
        let looksLikeCopy = name.contains("copy") || name.contains("kopya") || name.contains("kopie") || name.contains("copia")
            || name.range(of: #"\(\d+\)$|\s\d+$"#, options: .regularExpression) != nil ? 1 : 0
        return (inDownloads, url.pathComponents.count, looksLikeCopy)
    }

    /// Every file with the same relative path has the same sampled contents (head, tail and size).
    static func sameContents(_ a: URL, _ b: URL) -> Bool {
        guard let files = FileManager.default.subpaths(atPath: a.path) else { return false }
        for relative in files where !relative.split(separator: "/").contains(where: { $0.hasPrefix(".") }) {
            let left = a.appendingPathComponent(relative), right = b.appendingPathComponent(relative)
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: left.path, isDirectory: &isDirectory) else { continue }
            if isDirectory.boolValue { continue }
            guard let x = DuplicateFinder.hash(left, partial: true), let y = DuplicateFinder.hash(right, partial: true), x == y else {
                return false
            }
        }
        return true
    }

    /// What deleting the folder would free: each file's private blocks (clones share theirs).
    static func reclaimable(_ folder: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .totalFileAllocatedSizeKey]
        guard let walker = FileManager.default.enumerator(at: folder, includingPropertiesForKeys: Array(keys)) else { return 0 }
        var total: Int64 = 0
        while let url = walker.nextObject() as? URL {
            guard let values = try? url.resourceValues(forKeys: keys), values.isRegularFile == true else { continue }
            total += DuplicateFinder.reclaimableBytes(url.path, allocated: Int64(values.totalFileAllocatedSize ?? 0))
        }
        return total
    }
}
