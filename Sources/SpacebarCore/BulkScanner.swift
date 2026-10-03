import Darwin
import Foundation

/// Fast size engine built on `getattrlistbulk(2)`, which returns metadata for many
/// directory entries per syscall (readdir + stat in one).
///
/// - Counts allocated size, so sparse and compressed files are measured correctly.
/// - Counts hard-linked files once per measurement.
/// - Doesn't follow symlinks, cross mount points or descend into firmlinks.
/// - Skips dataless iCloud placeholders without materializing them.
/// - Uses a flat work queue: one directory is finished before the next is opened
///   (nested iteration loops forever on SMB in macOS 15).
public final class BulkScanner: SizeEngine, @unchecked Sendable {
    public let name = "getattrlistbulk"
    public let workers: Int
    public let bufferSize: Int
    /// Visit folders in the order found (a queue) instead of most-recent-first (a stack).
    public let breadthFirst: Bool
    /// Count blocks shared by APFS clones once (costs a lookup per clone).
    public let cloneAware: Bool

    public init(workers: Int = min(max(ProcessInfo.processInfo.activeProcessorCount, 4), 16),
                bufferSize: Int = 128 * 1024, breadthFirst: Bool = false, cloneAware: Bool = true) {
        self.workers = workers
        self.bufferSize = bufferSize
        self.breadthFirst = breadthFirst
        self.cloneAware = cloneAware
    }

    // sys/attr.h, sys/stat.h. Defined here because some don't import into Swift as UInt32.
    private static let cmnReturnedAttrs: UInt32 = 0x8000_0000
    private static let cmnName: UInt32 = 0x0000_0001
    private static let cmnDevID: UInt32 = 0x0000_0002
    private static let cmnObjType: UInt32 = 0x0000_0008
    private static let cmnModTime: UInt32 = 0x0000_0400
    private static let cmnFlags: UInt32 = 0x0004_0000
    private static let cmnFileID: UInt32 = 0x0200_0000
    private static let cmnError: UInt32 = 0x2000_0000
    private static let fileLinkCount: UInt32 = 0x0000_0001
    private static let fileAllocSize: UInt32 = 0x0000_0004
    private static let objTypeReg: UInt32 = 1 // VREG
    private static let objTypeDir: UInt32 = 2 // VDIR
    private static let cmnExtFlags: UInt32 = 0x0000_0200 // ATTR_CMNEXT_EXT_FLAGS (forkattr + FSOPT_ATTR_CMN_EXTENDED)
    private static let cmnExtPrivateSize: UInt32 = 0x0000_0008
    private static let cmnExtCloneID: UInt32 = 0x0000_0100
    private static let optionExtended: UInt64 = 0x0000_0020 // FSOPT_ATTR_CMN_EXTENDED
    private static let efMayShareBlocks: UInt64 = 0x1
    private static let sfFirmlink: UInt32 = 0x0080_0000
    private static let sfDataless: UInt32 = 0x4000_0000

    private struct WorkItem {
        let path: String
        /// Index of the totals this directory's contents are added to.
        var node: Int
        let device: Int32
        /// Depth below the measured root.
        let depth: Int
    }

    private struct LinkKey: Hashable {
        let device: Int32
        let inode: UInt64
    }

    /// An APFS clone family: files sharing the same blocks.
    private struct CloneKey: Hashable {
        let device: Int32
        let cloneID: UInt64
    }

    private final class Job {
        let cond = NSCondition()
        var stack: [WorkItem] = []
        /// Front of the queue in breadth-first mode.
        var head = 0
        var active = 0

        func next(breadthFirst: Bool) -> WorkItem? {
            guard head < stack.count else { return nil }
            guard breadthFirst else { return stack.popLast() }
            let item = stack[head]
            head += 1
            if head > 4096 && head * 2 > stack.count {
                stack.removeFirst(head)
                head = 0
            }
            return item
        }
        /// One entry per node: the measured roots first, then subdirectories recorded by `measureTree`.
        var totals: [SizeTotals]
        var paths: [String]
        var parents: [Int]
        let maxDepth: Int
        var seenLinks = Set<LinkKey>()
        var seenClones = Set<CloneKey>()

        init(roots: [URL], maxDepth: Int) {
            totals = Array(repeating: SizeTotals(), count: roots.count)
            paths = roots.map(\.path)
            parents = Array(repeating: -1, count: roots.count)
            self.maxDepth = maxDepth
        }
    }

    public func measure(_ roots: [URL], cancel: CancelToken? = nil) -> [SizeTotals] {
        let job = run(roots, maxDepth: 0, cancel: cancel)
        return Array(job.totals.prefix(roots.count))
    }

    /// Measures `root` and, in the same pass, every subdirectory up to `depth` levels below it.
    /// Keys are paths; values include everything beneath each folder.
    public func measureTree(_ root: URL, depth: Int, cancel: CancelToken? = nil) -> [String: SizeTotals] {
        let job = run([root], maxDepth: depth, cancel: cancel)
        return Dictionary(zip(job.paths, job.totals), uniquingKeysWith: { first, _ in first })
    }

    private func run(_ roots: [URL], maxDepth: Int, cancel: CancelToken?) -> Job {
        let job = Job(roots: roots, maxDepth: maxDepth)

        for (bucket, url) in roots.enumerated() {
            var st = stat()
            guard lstat(url.path, &st) == 0 else {
                job.totals[bucket].unreadable += 1
                continue
            }
            job.totals[bucket].newestModification = Self.seconds(st.st_mtimespec)
            switch st.st_mode & S_IFMT {
            case S_IFDIR:
                job.totals[bucket].directories += 1
                job.stack.append(WorkItem(path: url.path, node: bucket, device: st.st_dev, depth: 0))
            case S_IFREG:
                job.totals[bucket].files += 1
                if st.st_flags & Self.sfDataless != 0 {
                    job.totals[bucket].cloudOnlyFiles += 1
                } else if st.st_nlink > 1 {
                    if job.seenLinks.insert(LinkKey(device: st.st_dev, inode: st.st_ino)).inserted {
                        job.totals[bucket].allocated += Int64(st.st_blocks) * 512
                    }
                } else {
                    job.totals[bucket].allocated += Int64(st.st_blocks) * 512
                }
            default:
                break // symlinks, sockets, devices: no meaningful space
            }
        }

        guard !job.stack.isEmpty else { return job }

        let done = DispatchGroup()
        for _ in 0..<workers {
            done.enter()
            let thread = Thread { [self] in
                self.work(job, cancel: cancel)
                done.leave()
            }
            thread.qualityOfService = .userInitiated
            thread.start()
        }
        done.wait()

        // Children are always created after their parent, so a reverse pass rolls totals up.
        for node in stride(from: job.totals.count - 1, through: roots.count, by: -1) {
            job.totals[job.parents[node]].add(job.totals[node])
        }
        return job
    }

    private func work(_ job: Job, cancel: CancelToken?) {
        let buffer = UnsafeMutableRawPointer.allocate(byteCount: bufferSize, alignment: 16)
        defer { buffer.deallocate() }

        job.cond.lock()
        while true {
            if cancel?.isCancelled == true {
                job.stack.removeAll()
                job.head = 0
            }
            if let item = job.next(breadthFirst: breadthFirst) {
                job.active += 1
                job.cond.unlock()

                var local = SizeTotals()
                var subdirs: [WorkItem] = []
                var links: [(LinkKey, Int64)] = []
                var clones: [(CloneKey, Int64)] = []
                scanDirectory(item, buffer: buffer, totals: &local, subdirs: &subdirs, links: &links, clones: &clones)

                job.cond.lock()
                for (key, bytes) in links where job.seenLinks.insert(key).inserted {
                    local.allocated += bytes
                }
                // Blocks shared within a clone family count once.
                for (key, shared) in clones where job.seenClones.insert(key).inserted {
                    local.allocated += shared
                }
                job.totals[item.node].add(local)
                for var subdir in subdirs {
                    if subdir.depth <= job.maxDepth {
                        job.totals.append(SizeTotals())
                        job.paths.append(subdir.path)
                        job.parents.append(subdir.node)
                        subdir.node = job.totals.count - 1
                    }
                    job.stack.append(subdir)
                }
                job.active -= 1
                if !subdirs.isEmpty || job.active == 0 {
                    job.cond.broadcast()
                }
            } else if job.active == 0 {
                job.cond.broadcast()
                break
            } else {
                job.cond.wait()
            }
        }
        job.cond.unlock()
    }

    /// Private size and clone family of a file that may share blocks. Only asked for flagged
    /// files: computing private size costs extra I/O.
    private static func cloneInfo(_ path: String) -> (privateSize: Int64, cloneID: UInt64)? {
        var request = attrlist()
        request.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        request.commonattr = cmnReturnedAttrs
        request.forkattr = cmnExtPrivateSize | cmnExtCloneID
        var buffer = [UInt8](repeating: 0, count: 64)
        let result = buffer.withUnsafeMutableBytes {
            getattrlist(path, &request, $0.baseAddress, $0.count, UInt32(FSOPT_NOFOLLOW) | UInt32(optionExtended))
        }
        guard result == 0 else { return nil }
        return buffer.withUnsafeBytes { raw in
            var offset = 4
            let returned = raw.loadUnaligned(fromByteOffset: offset, as: attribute_set_t.self)
            offset += MemoryLayout<attribute_set_t>.size
            guard returned.forkattr & cmnExtPrivateSize != 0 else { return nil }
            let privateSize = raw.loadUnaligned(fromByteOffset: offset, as: Int64.self)
            offset += 8
            let cloneID = returned.forkattr & cmnExtCloneID != 0
                ? raw.loadUnaligned(fromByteOffset: offset, as: UInt64.self) : 0
            return (privateSize, cloneID)
        }
    }

    private static func seconds(_ time: timespec) -> TimeInterval {
        TimeInterval(time.tv_sec) + TimeInterval(time.tv_nsec) / 1e9
    }

    private func scanDirectory(_ item: WorkItem,
                               buffer: UnsafeMutableRawPointer,
                               totals: inout SizeTotals,
                               subdirs: inout [WorkItem],
                               links: inout [(LinkKey, Int64)],
                               clones: inout [(CloneKey, Int64)]) {
        let fd = open(item.path, O_RDONLY | O_DIRECTORY | O_NOFOLLOW | O_CLOEXEC)
        guard fd >= 0 else {
            totals.unreadable += 1
            return
        }
        defer { close(fd) }

        var request = attrlist()
        request.bitmapcount = u_short(ATTR_BIT_MAP_COUNT)
        request.commonattr = Self.cmnReturnedAttrs | Self.cmnName | Self.cmnError | Self.cmnDevID
            | Self.cmnObjType | Self.cmnModTime | Self.cmnFlags | Self.cmnFileID
        request.fileattr = Self.fileLinkCount | Self.fileAllocSize
        request.forkattr = cloneAware ? Self.cmnExtFlags : 0

        let parent = item.path.hasSuffix("/") ? item.path : item.path + "/"

        while true {
            let count = getattrlistbulk(fd, &request, buffer, bufferSize,
                                        UInt64(FSOPT_NOFOLLOW) | (cloneAware ? Self.optionExtended : 0))
            if count == 0 { break }
            if count < 0 {
                if errno == EINTR { continue }
                totals.unreadable += 1 // includes EDEADLK for dataless (cloud-only) directories
                break
            }

            var entry = buffer
            for _ in 0..<Int(count) {
                let length = Int(entry.load(as: UInt32.self))
                defer { entry += length }

                var field = entry + 4
                let returned = field.loadUnaligned(as: attribute_set_t.self)
                field += MemoryLayout<attribute_set_t>.size
                let common = returned.commonattr

                // ATTR_CMN_ERROR comes immediately after the returned-attributes set.
                if common & Self.cmnError != 0 {
                    let error = field.loadUnaligned(as: UInt32.self)
                    field += 4
                    if error != 0 {
                        totals.unreadable += 1
                        continue
                    }
                }

                var namePointer: UnsafeMutableRawPointer?
                if common & Self.cmnName != 0 {
                    let offset = field.loadUnaligned(as: Int32.self)
                    namePointer = field + Int(offset)
                    field += MemoryLayout<attrreference_t>.size
                }
                var device = item.device
                if common & Self.cmnDevID != 0 {
                    device = field.loadUnaligned(as: Int32.self)
                    field += 4
                }
                var type: UInt32 = 0
                if common & Self.cmnObjType != 0 {
                    type = field.loadUnaligned(as: UInt32.self)
                    field += 4
                }
                if common & Self.cmnModTime != 0 {
                    let modified = Self.seconds(field.loadUnaligned(as: timespec.self))
                    if modified > totals.newestModification { totals.newestModification = modified }
                    field += MemoryLayout<timespec>.size
                }
                var flags: UInt32 = 0
                if common & Self.cmnFlags != 0 {
                    flags = field.loadUnaligned(as: UInt32.self)
                    field += 4
                }
                var inode: UInt64 = 0
                if common & Self.cmnFileID != 0 {
                    inode = field.loadUnaligned(as: UInt64.self)
                    field += 8
                }
                var linkCount: UInt32 = 1
                if returned.fileattr & Self.fileLinkCount != 0 {
                    linkCount = field.loadUnaligned(as: UInt32.self)
                    field += 4
                }
                var allocated: Int64 = 0
                if returned.fileattr & Self.fileAllocSize != 0 {
                    allocated = field.loadUnaligned(as: Int64.self)
                    field += 8
                }
                var extFlags: UInt64 = 0
                if returned.forkattr & Self.cmnExtFlags != 0 {
                    extFlags = field.loadUnaligned(as: UInt64.self)
                    field += 8
                }

                switch type {
                case Self.objTypeDir:
                    // Mount points and firmlinks lead to other volumes or to the Data volume twice.
                    guard device == item.device, flags & Self.sfFirmlink == 0,
                          let namePointer else { continue }
                    totals.directories += 1
                    let name = String(cString: namePointer.assumingMemoryBound(to: CChar.self))
                    subdirs.append(WorkItem(path: parent + name, node: item.node, device: device, depth: item.depth + 1))
                case Self.objTypeReg:
                    totals.files += 1
                    if flags & Self.sfDataless != 0 {
                        totals.cloudOnlyFiles += 1
                    } else if linkCount > 1 {
                        links.append((LinkKey(device: device, inode: inode), allocated))
                    } else if extFlags & Self.efMayShareBlocks != 0, let namePointer,
                              let clone = Self.cloneInfo(parent + String(cString: namePointer.assumingMemoryBound(to: CChar.self))) {
                        // APFS clone: its private blocks are its own; the shared ones count once per family.
                        let privateBytes = min(clone.privateSize, allocated)
                        totals.allocated += privateBytes
                        clones.append((CloneKey(device: device, cloneID: clone.cloneID), allocated - privateBytes))
                    } else {
                        totals.allocated += allocated
                    }
                default:
                    break
                }
            }
        }
    }
}
