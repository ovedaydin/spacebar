import CoreServices
import Foundation

/// Reports which folders change under some paths, using FSEvents (the same change feed
/// Spotlight and Time Machine use). Events caused by Spacebar itself are ignored.
public final class FileWatcher: @unchecked Sendable {
    /// `paths` are folders whose contents changed. `rescanAll` means events were dropped
    /// or coalesced and everything under the watched paths should be treated as changed.
    public typealias Handler = @Sendable (_ paths: [String], _ rescanAll: Bool) -> Void
    /// The newest event delivered so far, and whether the replay of past changes (`since:`) is done.
    public typealias ProgressHandler = @Sendable (_ lastEventID: UInt64, _ historyDone: Bool) -> Void

    private var stream: FSEventStreamRef?
    private let queue = DispatchQueue(label: "Spacebar.FileWatcher")
    private let paths: [String]
    private let latency: TimeInterval
    private let handler: Handler
    private let since: UInt64?
    private let progress: ProgressHandler?

    /// `since`: also replay changes made after this event ID (e.g. while Spacebar wasn't running).
    public init(paths: [String], latency: TimeInterval = 2, since: UInt64? = nil,
                handler: @escaping Handler, progress: ProgressHandler? = nil) {
        self.paths = paths
        self.latency = latency
        self.since = since
        self.handler = handler
        self.progress = progress
    }

    /// The system's current change position, to save with a measurement.
    public static var currentEventID: UInt64 { FSEventsGetCurrentEventId() }

    deinit { stop() }

    @discardableResult
    public func start() -> Bool {
        guard stream == nil, !paths.isEmpty else { return stream != nil }
        var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                           retain: nil, release: nil, copyDescription: nil)
        let callback: FSEventStreamCallback = { _, info, count, eventPaths, eventFlags, eventIDs in
            guard let info else { return }
            let watcher = Unmanaged<FileWatcher>.fromOpaque(info).takeUnretainedValue()
            let array = unsafeBitCast(eventPaths, to: NSArray.self)
            var changed: [String] = []
            var rescan = false
            var historyDone = false
            var newest: UInt64 = 0
            let mustRescan = FSEventStreamEventFlags(kFSEventStreamEventFlagMustScanSubDirs | kFSEventStreamEventFlagUserDropped
                                                     | kFSEventStreamEventFlagKernelDropped | kFSEventStreamEventFlagRootChanged)
            for index in 0..<count {
                newest = max(newest, eventIDs[index])
                if eventFlags[index] & FSEventStreamEventFlags(kFSEventStreamEventFlagHistoryDone) != 0 {
                    historyDone = true
                    continue // a marker, not a change
                }
                if eventFlags[index] & mustRescan != 0 { rescan = true }
                if let path = array[index] as? String { changed.append(path.hasSuffix("/") ? String(path.dropLast()) : path) }
            }
            if !changed.isEmpty || rescan { watcher.handler(changed, rescan) }
            watcher.progress?(newest, historyDone)
        }
        let flags = FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagIgnoreSelf
                                             | kFSEventStreamCreateFlagWatchRoot)
        guard let created = FSEventStreamCreate(nil, callback, &context, paths as CFArray,
                                                since ?? FSEventStreamEventId(kFSEventStreamEventIdSinceNow), latency, flags) else {
            return false
        }
        FSEventStreamSetDispatchQueue(created, queue)
        guard FSEventStreamStart(created) else {
            FSEventStreamInvalidate(created)
            FSEventStreamRelease(created)
            return false
        }
        stream = created
        return true
    }

    public func stop() {
        guard let stream else { return }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
    }

    /// The deepest of `roots` that contains `path` (or is it), if any.
    public static func owningRoot(of path: String, in roots: [String]) -> String? {
        roots.filter { path == $0 || path.hasPrefix($0 + "/") }.max { $0.count < $1.count }
    }
}
