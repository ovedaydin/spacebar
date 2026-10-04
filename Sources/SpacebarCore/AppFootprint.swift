import Foundation

/// Everything an app keeps in ~/Library, for a complete uninstall.
public enum AppFootprint {
    public struct Part: Identifiable, Sendable {
        public var id: URL { url }
        public let url: URL
        /// What it is, e.g. "Settings" or "Caches".
        public let label: String
        /// Selected by default. Shared data (Group Containers) isn't.
        public let selectedByDefault: Bool
    }

    public struct App: Sendable {
        public let url: URL
        public let bundleID: String
        public let name: String
        public let version: String?
    }

    public static func app(at url: URL) -> App? {
        guard let bundle = Bundle(url: url), let id = bundle.bundleIdentifier else { return nil }
        let name = (bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)
            ?? (bundle.object(forInfoDictionaryKey: "CFBundleName") as? String)
            ?? url.deletingPathExtension().lastPathComponent
        return App(url: url, bundleID: id, name: name,
                   version: bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String)
    }

    /// Folders in ~/Library where apps keep data, and how each is labelled.
    static let places: [(folder: String, label: String)] = [
        ("Application Support", "App data"), ("Caches", "Caches"), ("Containers", "Sandbox container"),
        ("Group Containers", "Shared container"), ("Preferences", "Settings"), ("Preferences/ByHost", "Settings"),
        ("Saved Application State", "Saved windows"), ("HTTPStorages", "Web data"), ("WebKit", "Web data"),
        ("Cookies", "Cookies"), ("Logs", "Logs"), ("LaunchAgents", "Launch agent"), ("Application Scripts", "Scripts"),
    ]

    /// Whether an entry named `name` in one of `places` belongs to the app.
    /// Entries named after the bundle ID always do; entries named after the app (e.g. "Slack" in
    /// Application Support) only in App Support and Logs, where apps use plain names.
    public static func belongs(_ name: String, folder: String, bundleID: String, appName: String) -> Bool {
        let lowerName = name.lowercased()
        let id = bundleID.lowercased()
        if lowerName == id || lowerName.hasPrefix(id + ".") { return true }      // com.x.app, com.x.app.plist, .savedState…
        if folder == "Group Containers" { return lowerName.hasSuffix("." + id) || lowerName.contains("." + id + ".") }
        if folder == "LaunchAgents" { return lowerName.hasPrefix(id) && lowerName.hasSuffix(".plist") }
        if folder == "Application Support" || folder == "Logs" {
            return appName.count >= 3 && lowerName == appName.lowercased()
        }
        return false
    }

    /// The app's data in `home`/Library.
    public static func locate(_ app: App, home: URL = FileManager.default.homeDirectoryForCurrentUser) -> [Part] {
        guard !app.bundleID.hasPrefix("com.apple.") else { return [] }
        let library = home.appendingPathComponent("Library")
        var parts: [Part] = []
        for place in places {
            let folder = library.appendingPathComponent(place.folder)
            let entries = (try? FileManager.default.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil)) ?? []
            for entry in entries where belongs(entry.lastPathComponent, folder: place.folder, bundleID: app.bundleID, appName: app.name) {
                parts.append(Part(url: entry, label: place.label, selectedByDefault: place.folder != "Group Containers"))
            }
        }
        return parts
    }
}
