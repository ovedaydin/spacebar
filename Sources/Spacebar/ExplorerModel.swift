import AppKit
import SpacebarCore
import SwiftUI

@MainActor
final class ExplorerModel: ObservableObject {
    struct Entry: Identifiable, Hashable {
        var id: URL { url }
        let url: URL
        let name: String
        let isFolder: Bool
    }

    /// Measuring a folder also records its subfolders this many levels down,
    /// so opening them afterwards is instant.
    nonisolated private static let treeDepth = 2

    private let engine = BulkScanner()
    private var token: CancelToken?
    private let sessionStart = Date()
    private var measured: [URL: Date] = [:]
    /// The size before the latest measurement (from an earlier session), for "grew recently".
    private(set) var previous: [URL: (bytes: Int64, date: Date)] = [:]

    /// How much `url` grew since its previous measurement, if known.
    func growth(_ url: URL) -> (bytes: Int64, since: Date)? {
        guard let before = previous[url], let now = sizes[url]?.allocated else { return nil }
        return (now - before.bytes, before.date)
    }

    @Published var sortByGrowth = UserDefaults.standard.bool(forKey: "explorerSortByGrowth") {
        didSet {
            UserDefaults.standard.set(sortByGrowth, forKey: "explorerSortByGrowth")
            sortEntries()
        }
    }

    @Published private(set) var trail: [URL] = [FileManager.default.homeDirectoryForCurrentUser]
    @Published private(set) var entries: [Entry] = []
    /// Entries in display order. Re-sorted only when measuring finishes, so rows don't jump around.
    @Published private(set) var ordered: [Entry] = []
    @Published private(set) var sizes: [URL: SizeTotals] = [:]
    @Published private(set) var progress: (done: Int, total: Int)?
    @Published private(set) var loaded = false

    init() {
        if let cache = ScanCache.loadExplorer() {
            for (path, entry) in cache.entries {
                let url = URL(fileURLWithPath: path)
                sizes[url] = entry.totals
                measured[url] = entry.measured
                if let bytes = entry.previous, let date = entry.previousMeasured { previous[url] = (bytes, date) }
            }
        }
    }

    /// Several folders listed together, e.g. everything counted as "Developer" in the disk breakdown.
    struct Group: Equatable {
        let title: String
        let roots: [URL]
    }

    @Published private(set) var group: Group?

    /// Showing the group's folders themselves (none opened yet).
    var atGroupLevel: Bool { group != nil && trail.isEmpty }
    var current: URL { trail.last ?? FileManager.default.homeDirectoryForCurrentUser }
    /// Identity of the list on screen, so each new listing starts scrolled to the top.
    var listID: String { atGroupLevel ? "group:\(group?.title ?? "")" : current.path }
    var loading: Bool { progress != nil }
    var currentTotal: Int64 { entries.reduce(0) { $0 + (sizes[$1.url]?.allocated ?? 0) } }
    var largest: Int64 { entries.map { sizes[$0.url]?.allocated ?? 0 }.max() ?? 0 }

    /// Oldest measurement among the shown entries when it comes from a previous launch.
    var cachedSince: Date? {
        let dates = entries.compactMap { measured[$0.url] }.filter { $0 < sessionStart }
        return dates.min()
    }

    func open(_ entry: Entry) {
        guard entry.isFolder else { return }
        trail.append(entry.url)
        load()
    }

    func showGroup(_ title: String, roots: [URL]) {
        group = Group(title: title, roots: roots)
        trail = []
        load()
    }

    /// Opens `url`, with breadcrumbs from the home folder when it's inside it.
    func show(_ url: URL) {
        group = nil
        let home = FileManager.default.homeDirectoryForCurrentUser
        var trail = [url]
        if url.path.hasPrefix(home.path + "/") {
            var parent = url.deletingLastPathComponent()
            while parent.path.count >= home.path.count {
                trail.insert(parent, at: 0)
                if parent.path == home.path { break }
                parent = parent.deletingLastPathComponent()
            }
        }
        self.trail = trail
        load()
    }

    /// Index -1 goes back to the group's list.
    func jump(to index: Int) {
        guard index < trail.count - 1, index >= -1, index >= 0 || group != nil else { return }
        trail = Array(trail.prefix(index + 1))
        load()
    }

    func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.directoryURL = current
        panel.prompt = "Explore"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        group = nil
        trail = [url]
        load()
    }

    func load(force: Bool = false) {
        token?.cancel()
        let token = CancelToken()
        self.token = token
        loaded = true

        let keys: [URLResourceKey] = [.isDirectoryKey, .isSymbolicLinkKey]
        let home = NSHomeDirectory()
        let urls = atGroupLevel
            ? (group?.roots ?? []).filter { FileManager.default.fileExists(atPath: $0.path) }
            : (try? FileManager.default.contentsOfDirectory(at: current, includingPropertiesForKeys: keys)) ?? []
        entries = urls.map { url in
            let values = try? url.resourceValues(forKeys: Set(keys))
            let isFolder = values?.isDirectory == true && values?.isSymbolicLink != true
            // In a group, show where each folder is.
            let name = atGroupLevel ? url.path.replacingOccurrences(of: home, with: "~") : url.lastPathComponent
            return Entry(url: url, name: name, isFolder: isFolder)
        }
        sortEntries()

        // Measured during this session (e.g. as part of the parent folder): already accurate.
        // From a previous launch: shown right away, but measured again.
        let pending = entries.filter { force || (measured[$0.url] ?? .distantPast) < sessionStart }
        guard !pending.isEmpty else {
            progress = nil
            return
        }
        let files = pending.filter { !$0.isFolder }.map(\.url)
        let folders = pending.filter(\.isFolder).map(\.url)
        progress = (0, pending.count)
        let engine = engine
        // Keep measuring at full speed while Spacebar is in the background (App Nap).
        let activity = ProcessInfo.processInfo.beginActivity(options: .userInitiated, reason: "Measuring folder sizes")

        Task.detached(priority: .userInitiated) {
            defer { ProcessInfo.processInfo.endActivity(activity) }
            if !files.isEmpty {
                let totals = engine.measure(files, cancel: token)
                await MainActor.run {
                    guard !token.isCancelled else { return }
                    self.record(zip(files, totals).map { ($0, $1) })
                    self.progress?.done += files.count
                }
            }
            for folder in folders {
                if token.isCancelled { return }
                let tree = engine.measureTree(folder, depth: Self.treeDepth, cancel: token)
                await MainActor.run {
                    guard !token.isCancelled else { return }
                    self.record(tree.map { (URL(fileURLWithPath: $0.key), $0.value) })
                    self.progress?.done += 1
                }
            }
            await MainActor.run {
                guard !token.isCancelled else { return }
                self.progress = nil
                self.sortEntries()
                self.saveCache()
            }
        }
    }

    /// Forget sizes for removed items, everything inside them, and every folder above them.
    func didRemove(_ urls: [URL]) {
        var sizes = self.sizes
        for url in urls {
            let prefix = url.path + "/"
            for key in sizes.keys where key == url || key.path.hasPrefix(prefix) {
                sizes[key] = nil
                measured[key] = nil
            }
            var parent = url.deletingLastPathComponent()
            while parent.pathComponents.count > 1 {
                measured[parent] = nil
                parent = parent.deletingLastPathComponent()
            }
        }
        self.sizes = sizes
        load()
    }

    /// Applies a batch with one assignment: mutating a @Published dictionary entry by entry
    /// copies it every time, which froze the UI for seconds after measuring ~/Library.
    private func record(_ batch: [(URL, SizeTotals)]) {
        let now = Date()
        var sizes = self.sizes
        for (url, totals) in batch {
            // Keep the last measurement from an earlier session (at least an hour old) as "previous".
            if let old = sizes[url], let oldDate = measured[url], now.timeIntervalSince(oldDate) > 3600 {
                previous[url] = (old.allocated, oldDate)
            }
            sizes[url] = totals
            measured[url] = now
        }
        self.sizes = sizes
    }

    private func sortEntries() {
        if sortByGrowth {
            ordered = entries.sorted { a, b in
                (growth(a.url)?.bytes ?? Int64.min) > (growth(b.url)?.bytes ?? Int64.min)
            }
            return
        }
        ordered = entries.sorted { a, b in
            switch (sizes[a.url]?.allocated, sizes[b.url]?.allocated) {
            case let (x?, y?) where x != y: return x > y
            case (_?, nil): return true
            case (nil, _?): return false
            default: return a.name.localizedStandardCompare(b.name) == .orderedAscending
            }
        }
    }

    private func saveCache() {
        var entries: [String: ScanCache.Explorer.Entry] = [:]
        for (url, totals) in sizes {
            if let date = measured[url] {
                entries[url.path] = .init(totals: totals, measured: date,
                                          previous: previous[url]?.bytes, previousMeasured: previous[url]?.date)
            }
        }
        ScanCache.save(ScanCache.Explorer(entries: entries))
    }
}
