import Darwin
import Foundation
import SpacebarCore

private let sfDataless: UInt32 = 0x4000_0000
private let sfFirmlink: UInt32 = 0x0080_0000

/// Classic single-threaded walk with fts(3) and lstat data (like du).
final class FTSScanner: SizeEngine, @unchecked Sendable {
    let name = "fts"

    func measure(_ roots: [URL], cancel: CancelToken?) -> [SizeTotals] {
        roots.map { measureOne($0) }
    }

    private func measureOne(_ root: URL) -> SizeTotals {
        var totals = SizeTotals()
        var seen = Set<UInt64>()
        let path = strdup(root.path)
        defer { free(path) }
        var argv: [UnsafeMutablePointer<CChar>?] = [path, nil]
        guard let fts = fts_open(&argv, FTS_PHYSICAL | FTS_XDEV | FTS_NOCHDIR, nil) else { return totals }
        defer { fts_close(fts) }
        while let entry = fts_read(fts) {
            let info = Int32(entry.pointee.fts_info)
            switch info {
            case FTS_D:
                totals.directories += 1
                if let st = entry.pointee.fts_statp, st.pointee.st_flags & sfFirmlink != 0 { fts_set(fts, entry, FTS_SKIP) }
            case FTS_F:
                guard let st = entry.pointee.fts_statp?.pointee else { continue }
                totals.files += 1
                if st.st_flags & sfDataless != 0 { totals.cloudOnlyFiles += 1; continue }
                if st.st_nlink > 1 && !seen.insert(st.st_ino).inserted { continue }
                totals.allocated += Int64(st.st_blocks) * 512
            case FTS_DNR, FTS_ERR, FTS_NS:
                totals.unreadable += 1
            default:
                break
            }
        }
        return totals
    }
}

/// Multithreaded readdir + fstatat: one stat call per entry.
final class ParallelStatScanner: SizeEngine, @unchecked Sendable {
    let name = "readdir+fstatat"
    let workers: Int

    init(workers: Int = 8) { self.workers = workers }

    func measure(_ roots: [URL], cancel: CancelToken?) -> [SizeTotals] {
        roots.map { measureOne($0) }
    }

    private func measureOne(_ root: URL) -> SizeTotals {
        var rootStat = stat()
        guard lstat(root.path, &rootStat) == 0 else { return SizeTotals() }
        let device = rootStat.st_dev
        let cond = NSCondition()
        var queue: [String] = [root.path]
        var active = 0
        var totals = SizeTotals()
        var seen = Set<UInt64>()
        let group = DispatchGroup()

        for _ in 0..<workers {
            group.enter()
            Thread {
                cond.lock()
                while true {
                    if let dir = queue.popLast() {
                        active += 1
                        cond.unlock()
                        var local = SizeTotals()
                        var subdirs: [String] = []
                        var links: [(UInt64, Int64)] = []
                        if let handle = opendir(dir) {
                            let fd = dirfd(handle)
                            while let entry = readdir(handle) {
                                let name = withUnsafePointer(to: entry.pointee.d_name) {
                                    $0.withMemoryRebound(to: CChar.self, capacity: 1024) { String(cString: $0) }
                                }
                                if name == "." || name == ".." { continue }
                                var st = stat()
                                guard fstatat(fd, name, &st, AT_SYMLINK_NOFOLLOW) == 0 else { local.unreadable += 1; continue }
                                switch st.st_mode & S_IFMT {
                                case S_IFDIR:
                                    if st.st_dev == device && st.st_flags & sfFirmlink == 0 {
                                        local.directories += 1
                                        subdirs.append(dir + "/" + name)
                                    }
                                case S_IFREG:
                                    local.files += 1
                                    if st.st_flags & sfDataless != 0 { local.cloudOnlyFiles += 1 }
                                    else if st.st_nlink > 1 { links.append((st.st_ino, Int64(st.st_blocks) * 512)) }
                                    else { local.allocated += Int64(st.st_blocks) * 512 }
                                default: break
                                }
                            }
                            closedir(handle)
                        } else {
                            local.unreadable += 1
                        }
                        cond.lock()
                        for (inode, bytes) in links where seen.insert(inode).inserted { local.allocated += bytes }
                        totals.add(local)
                        queue.append(contentsOf: subdirs)
                        active -= 1
                        cond.broadcast()
                    } else if active == 0 {
                        break
                    } else {
                        cond.wait()
                    }
                }
                cond.unlock()
                group.leave()
            }.start()
        }
        group.wait()
        totals.directories += 1
        return totals
    }
}
