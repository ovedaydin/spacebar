import Foundation

/// What an app really takes: the app itself plus everything it keeps in ~/Library.
public struct AppUsage: Sendable, Identifiable, Codable {
    public struct Piece: Sendable, Codable {
        public let label: String
        public let url: URL
        public let bytes: Int64
        /// Rebuilt by the app when needed, so safe to clear.
        public let isCache: Bool
    }

    public var id: String { bundleID }
    public let url: URL
    public let bundleID: String
    public let name: String
    public let appBytes: Int64
    public let pieces: [Piece]

    public var dataBytes: Int64 { pieces.reduce(0) { $0 + $1.bytes } }
    public var cacheBytes: Int64 { pieces.filter(\.isCache).reduce(0) { $0 + $1.bytes } }
    public var total: Int64 { appBytes + dataBytes }
    public var caches: [Piece] { pieces.filter(\.isCache) }
}

public enum AppUsageAnalyzer {
    /// Every app in /Applications and ~/Applications with its footprint, largest first.
    /// Blocking; `progress` gets the apps measured so far.
    /// `knownSizes`: app bundles measured elsewhere (Unused Apps), so they aren't measured again.
    public static func measure(engine: SizeEngine, home: URL = FileManager.default.homeDirectoryForCurrentUser,
                               knownSizes: [URL: Int64] = [:],
                               cancel: CancelToken? = nil, progress: ([AppUsage]) -> Void = { _ in }) -> [AppUsage] {
        let library = home.appendingPathComponent("Library")
        // Each ~/Library place is listed once, then matched against every app.
        let listings = AppFootprint.places.map { place in
            (place, (try? FileManager.default.contentsOfDirectory(at: library.appendingPathComponent(place.folder),
                                                                  includingPropertiesForKeys: nil)) ?? [])
        }
        struct Found {
            let app: AppFootprint.App
            var urls: [(label: String, url: URL, isCache: Bool)]
        }
        var found: [Found] = []
        for url in InstalledAppsIndex.standardAppURLs() {
            if cancel?.isCancelled == true { break }
            guard let app = AppFootprint.app(at: url) else { continue }
            var urls: [(label: String, url: URL, isCache: Bool)] = []
            // Measuring only, so Apple's apps count too (the uninstaller leaves them alone).
            do {
                for (place, entries) in listings {
                    for entry in entries where AppFootprint.belongs(entry.lastPathComponent, folder: place.folder,
                                                                     bundleID: app.bundleID, appName: app.name) {
                        urls.append((place.label, entry, place.folder == "Caches"))
                        // A sandboxed app's caches live inside its container.
                        if place.folder == "Containers" {
                            let caches = entry.appendingPathComponent("Data/Library/Caches")
                            if FileManager.default.fileExists(atPath: caches.path) {
                                urls.append((String(localized: "Caches in its container"), caches, true))
                            }
                        }
                    }
                }
            }
            // Vendor folders: "Google Chrome" keeps its data in Application Support/Google/Chrome.
            for folder in ["Application Support", "Caches"] {
                for vendor in listings.first(where: { $0.0.folder == folder })?.1 ?? []
                    where app.name.hasPrefix(vendor.lastPathComponent + " ") {
                    let product = String(app.name.dropFirst(vendor.lastPathComponent.count + 1))
                    let entry = vendor.appendingPathComponent(product)
                    if FileManager.default.fileExists(atPath: entry.path), !urls.contains(where: { $0.url == entry }) {
                        urls.append((folder == "Caches" ? String(localized: "Caches") : String(localized: "App data"), entry, folder == "Caches"))
                    }
                }
            }
            // Developer tools keep their data outside the usual places.
            if app.bundleID == "com.apple.dt.Xcode" {
                for (label, path) in [(String(localized: "Build data and archives"), "Developer/Xcode"),
                                      (String(localized: "Simulators"), "Developer/CoreSimulator")] {
                    let entry = library.appendingPathComponent(path)
                    if FileManager.default.fileExists(atPath: entry.path) { urls.append((label, entry, false)) }
                }
            }
            found.append(Found(app: app, urls: urls))
        }
        // A few apps per batch: the scanner's threads stay busy, and the list fills in as it goes.
        var usages: [AppUsage] = []
        for chunk in stride(from: 0, to: found.count, by: 6).map({ Array(found[$0..<min($0 + 6, found.count)]) }) {
            if cancel?.isCancelled == true { break }
            let all = chunk.flatMap { (knownSizes[$0.app.url] != nil ? [] : [$0.app.url]) + $0.urls.map(\.url) }
            var sizes = Dictionary(zip(all, engine.measure(all, cancel: cancel).map(\.allocated)), uniquingKeysWith: max)
            sizes.merge(knownSizes) { measured, _ in measured }
            for entry in chunk {
                let app = entry.app
                var pieces = entry.urls.map { piece in
                    AppUsage.Piece(label: piece.label, url: piece.url, bytes: sizes[piece.url] ?? 0, isCache: piece.isCache)
                }
                // Container sizes include their caches; count those bytes once, as cache.
                for cache in pieces where cache.isCache && cache.url.path.contains("/Containers/") {
                    let container = cache.url.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
                    if let index = pieces.firstIndex(where: { $0.url == container }) {
                        let old = pieces[index]
                        pieces[index] = .init(label: old.label, url: old.url, bytes: max(0, old.bytes - cache.bytes), isCache: false)
                    }
                }
                usages.append(AppUsage(url: app.url, bundleID: app.bundleID, name: app.name, appBytes: sizes[app.url] ?? 0,
                                       pieces: pieces.filter { $0.bytes > 0 }.sorted { $0.bytes > $1.bytes }))
            }
            progress(usages.sorted { $0.total > $1.total })
        }
        return usages.sorted { $0.total > $1.total }
    }
}
