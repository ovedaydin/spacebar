import Foundation

/// Browser caches per profile, updater leftovers, and profiles nobody has used in months.
/// Cookies, history, logins, bookmarks and site storage are never offered.
enum BrowserData {
    struct Chromium {
        let name: String
        let bundleID: String
        /// Under ~/Library/Application Support and ~/Library/Caches.
        let userData: String
    }

    static let chromium: [Chromium] = [
        Chromium(name: "Google Chrome", bundleID: "com.google.Chrome", userData: "Google/Chrome"),
        Chromium(name: "Microsoft Edge", bundleID: "com.microsoft.edgemac", userData: "Microsoft Edge"),
        Chromium(name: "Brave", bundleID: "com.brave.Browser", userData: "BraveSoftware/Brave-Browser"),
        Chromium(name: "Arc", bundleID: "company.thebrowser.Browser", userData: "Arc/User Data"),
        Chromium(name: "Vivaldi", bundleID: "com.vivaldi.Vivaldi", userData: "Vivaldi"),
        Chromium(name: "Chromium", bundleID: "org.chromium.Chromium", userData: "Chromium"),
    ]

    /// Inside a Chromium profile: only caches the browser rebuilds.
    static let profileCaches = ["Service Worker/CacheStorage", "Service Worker/ScriptCache", "GPUCache", "Code Cache",
                                "DawnCache", "DawnGraphiteCache", "DawnWebGPUCache"]
    /// In the user-data folder itself.
    static let sharedCaches = ["GrShaderCache", "ShaderCache", "GraphiteDawnCache", "component_crx_cache", "extensions_crx_cache"]

    /// Profiles untouched for this long are listed (never preselected: they hold logins and bookmarks).
    static let oldProfileDays: Double = 180

    static func candidates(home: URL, now: Date = Date()) -> [CleanCategory.Candidate] {
        let fm = FileManager.default
        let support = home.appendingPathComponent("Library/Application Support")
        let caches = home.appendingPathComponent("Library/Caches")
        var found: [CleanCategory.Candidate] = []
        func add(_ url: URL, _ name: String, _ detail: String, owner: String?) {
            guard fm.fileExists(atPath: url.path) else { return }
            found.append(.init(url: url, name: name, detail: detail, owner: owner, suggested: true))
        }

        for browser in chromium {
            let data = support.appendingPathComponent(browser.userData)
            guard fm.fileExists(atPath: data.path) else { continue }
            let state = localState(data)
            for profile in profiles(in: data) {
                let label = state.names[profile] ?? profile
                let title = "\(browser.name) · \(label)"
                add(caches.appendingPathComponent(browser.userData).appendingPathComponent(profile), title,
                    String(localized: "Web cache"), owner: browser.bundleID)
                for path in profileCaches {
                    add(data.appendingPathComponent(profile).appendingPathComponent(path), title,
                        path.hasPrefix("Service Worker") ? String(localized: "Offline site data (service workers)") : String(localized: "Graphics and code cache"),
                        owner: browser.bundleID)
                }
                // Profiles nobody has opened in months: listed for review, never preselected.
                if let active = state.lastActive[profile], profile != state.lastUsed,
                   active < now.addingTimeInterval(-oldProfileDays * 86400) {
                    found.append(.init(url: data.appendingPathComponent(profile), name: title,
                                       date: active,
                                       detail: String(localized: "Profile last used \(active.formatted(.relative(presentation: .named))) · its bookmarks, passwords and history go too"),
                                       owner: browser.bundleID, kind: .browserProfile, lastUsed: active, suggested: false))
                }
            }
            for path in sharedCaches {
                add(data.appendingPathComponent(path), browser.name, String(localized: "Shared cache"), owner: browser.bundleID)
            }
        }

        // Firefox: each profile's cache lives under ~/Library/Caches.
        for profile in (try? fm.contentsOfDirectory(at: caches.appendingPathComponent("Firefox/Profiles"), includingPropertiesForKeys: nil)) ?? [] {
            add(profile.appendingPathComponent("cache2"), "Firefox · \(profile.lastPathComponent)", String(localized: "Web cache"),
                owner: "org.mozilla.firefox")
        }
        // Safari keeps its cache in its container (and an older one in ~/Library/Caches).
        add(home.appendingPathComponent("Library/Containers/com.apple.Safari/Data/Library/Caches"), "Safari",
            String(localized: "Web cache"), owner: "com.apple.Safari")
        add(caches.appendingPathComponent("com.apple.Safari"), "Safari", String(localized: "Web cache"), owner: "com.apple.Safari")

        // What browser updaters leave behind after installing.
        for (path, name) in [("Library/Application Support/Google/GoogleUpdater/crx_cache", "Google Updater"),
                             ("Library/Caches/com.google.SoftwareUpdate", "Google Software Update"),
                             ("Library/Application Support/Microsoft/EdgeUpdater/crx_cache", "Microsoft Edge Updater")] {
            add(home.appendingPathComponent(path), name, String(localized: "Downloaded updates, already installed"), owner: nil)
        }
        return found
    }

    /// Profile folders in a Chromium user-data folder ("Default", "Profile 3"…).
    static func profiles(in data: URL) -> [String] {
        ((try? FileManager.default.contentsOfDirectory(atPath: data.path)) ?? [])
            .filter { $0 == "Default" || $0.hasPrefix("Profile ") }
            .sorted()
    }

    /// Profile names, when each was last active, and the last-used profile, from "Local State".
    static func localState(_ data: URL) -> (names: [String: String], lastActive: [String: Date], lastUsed: String?) {
        guard let json = try? Data(contentsOf: data.appendingPathComponent("Local State")),
              let root = try? JSONSerialization.jsonObject(with: json) as? [String: Any],
              let profile = root["profile"] as? [String: Any] else { return ([:], [:], nil) }
        var names: [String: String] = [:], active: [String: Date] = [:]
        for (folder, info) in profile["info_cache"] as? [String: [String: Any]] ?? [:] {
            if let name = info["name"] as? String { names[folder] = name }
            if let seconds = info["active_time"] as? Double, seconds > 0 { active[folder] = Date(timeIntervalSince1970: seconds) }
        }
        return (names, active, profile["last_used"] as? String)
    }

    /// Whether `components` (relative to ~, lowercased) is exactly a Chromium profile folder.
    static func isProfileFolder(_ components: [String]) -> Bool {
        guard components.count >= 4, components[0] == "library", components[1] == "application support" else { return false }
        let profile = components[components.count - 1]
        guard profile == "default" || profile.hasPrefix("profile ") else { return false }
        let userData = components[2..<(components.count - 1)].joined(separator: "/")
        return chromium.contains { $0.userData.lowercased() == userData }
    }
}

extension CleanCategory {
    /// Small caches aren't worth a row each.
    static let browserMinimum: Int64 = 5_000_000

    static let browsers = CleanCategory(
        id: "browsers", name: String(localized: "Browser Data"), icon: "safari",
        summary: String(localized: "Caches of Safari, Chrome, Edge, Brave, Arc and Firefox, per profile, and leftovers of their updaters. Browsers rebuild these; cookies, history, passwords, bookmarks and site data are never touched. Quit a browser to clean its caches. Profiles nobody has opened in 6 months are listed too, but never preselected: removing one removes its bookmarks and passwords (it goes to the Trash)."),
        safety: .review, mode: .permanent, needsFullDiskAccess: false, onDemand: false, owners: []
    ) { context in
        let candidates = BrowserData.candidates(home: context.home)
        let sizes = context.engine.measure(candidates.map(\.url), cancel: context.cancel).map(\.allocated)
        return zip(candidates, sizes).compactMap { candidate, size in
            guard candidate.kind == .browserProfile || size >= browserMinimum else { return nil }
            var sized = candidate
            sized.knownSize = size
            return sized
        }
    }
}
