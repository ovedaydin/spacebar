import Foundation

/// Baseline engine using `FileManager.enumerator` with prefetched resource keys.
/// Slower than `BulkScanner`; kept for benchmarking and as a correctness reference.
public final class FileManagerScanner: SizeEngine, @unchecked Sendable {
    public let name = "FileManager"

    public init() {}

    private static let keys: [URLResourceKey] = [
        .isRegularFileKey, .totalFileAllocatedSizeKey, .linkCountKey, .fileResourceIdentifierKey,
        .contentModificationDateKey,
    ]

    public func measure(_ roots: [URL], cancel: CancelToken? = nil) -> [SizeTotals] {
        var results = Array(repeating: SizeTotals(), count: roots.count)
        let lock = NSLock()
        var seenLinks = Set<NSObject>()

        DispatchQueue.concurrentPerform(iterations: roots.count) { index in
            let totals = measureOne(roots[index], cancel: cancel) { identifier in
                lock.lock(); defer { lock.unlock() }
                return seenLinks.insert(identifier).inserted
            }
            lock.lock()
            results[index] = totals
            lock.unlock()
        }
        return results
    }

    private func measureOne(_ root: URL, cancel: CancelToken?, firstLink: (NSObject) -> Bool) -> SizeTotals {
        var totals = SizeTotals()
        let keySet = Set(Self.keys)

        func count(_ values: URLResourceValues) {
            if let date = values.contentModificationDate {
                totals.newestModification = max(totals.newestModification, date.timeIntervalSince1970)
            }
            guard values.isRegularFile == true else { return }
            totals.files += 1
            let bytes = Int64(values.totalFileAllocatedSize ?? 0)
            if let links = values.linkCount, links > 1,
               let identifier = values.fileResourceIdentifier as? NSObject {
                if firstLink(identifier) { totals.allocated += bytes }
            } else {
                totals.allocated += bytes
            }
        }

        guard let rootValues = try? root.resourceValues(forKeys: keySet.union([.isDirectoryKey, .isSymbolicLinkKey])) else {
            totals.unreadable += 1
            return totals
        }
        guard rootValues.isDirectory == true, rootValues.isSymbolicLink != true else {
            count(rootValues)
            return totals
        }
        totals.directories += 1

        let enumerator = FileManager.default.enumerator(
            at: root, includingPropertiesForKeys: Self.keys + [.isDirectoryKey], options: [],
            errorHandler: { _, _ in totals.unreadable += 1; return true })
        while let url = enumerator?.nextObject() as? URL {
            if cancel?.isCancelled == true { break }
            guard let values = try? url.resourceValues(forKeys: keySet.union([.isDirectoryKey])) else { continue }
            if values.isDirectory == true { totals.directories += 1 }
            count(values)
        }
        return totals
    }
}
