import Foundation

/// Decides which paths may ever be removed. Checked when building the catalog and
/// again immediately before any deletion.
public enum PathRules {
    static let home = FileManager.default.homeDirectoryForCurrentUser.resolvingSymlinksInPath().standardizedFileURL

    /// Home-relative paths that are never removed, nor anything inside them.
    static let neverTouch: [String] = [
        "Library/Keychains", "Library/Accounts", "Library/Mail", "Library/Messages",
        "Library/Calendars", "Library/Contacts", "Library/Mobile Documents", "Library/CloudStorage",
        "Library/Group Containers", "Library/Preferences", "Library/Application Support/com.apple.TCC",
        "Library/Application Support/com.apple.idleassetsd", "Library/Application Support/com.apple.wallpaper",
        ".ssh", ".gnupg", ".orbstack", ".ollama/models", ".lmstudio/models",
        ".cache/huggingface", ".cache/torch", ".cache/pypoetry/virtualenvs", ".m2/repository",
    ]

    /// SSH and similar private keys, wherever they are.
    static let securityFilePatterns = ["id_rsa", "id_ed25519", "id_ecdsa", "id_dsa", "authorized_keys", "known_hosts"]
    static let securityExtensions: Set<String> = ["pem", "p12", "pfx", "key", "keychain", "keychain-db", "gpg", "asc", "kdbx"]

    /// Configuration files in the home folder that shells and tools read at startup.
    static let homeConfigFiles: Set<String> = [
        ".zshrc", ".zprofile", ".zshenv", ".zlogin", ".bashrc", ".bash_profile", ".profile", ".bash_login",
        ".gitconfig", ".gitignore_global", ".npmrc", ".yarnrc", ".netrc", ".vimrc", ".tmux.conf", ".inputrc",
        ".config", ".local", ".docker", ".kube", ".aws", ".azure", ".gcloud", ".terraform.d",
    ]

    /// Top-level folders in home that can't be removed themselves (their contents can).
    static let protectedTopLevel: Set<String> = [
        "library", "documents", "desktop", "downloads", "pictures", "movies", "music",
        "applications", "public", ".trash", "sites", "developer",
    ]

    /// The app bundle of the active developer tools (`xcode-select`), e.g. ~/Downloads/Xcode.app.
    static let activeDeveloperApp: String? = {
        let developer = URL(fileURLWithPath: "/var/db/xcode_select_link").resolvingSymlinksInPath().path
        guard let range = developer.range(of: ".app/") else { return nil }
        return String(developer[..<range.lowerBound]) + ".app"
    }()

    /// True if `url` may be removed as the given kind of item.
    public static func isDeletable(_ url: URL, kind: ItemKind = .file) -> Bool {
        reasonNotDeletable(url, kind: kind) == nil
    }

    /// Why `url` can't be removed, in words for the user; nil when it can.
    public static func reasonNotDeletable(_ url: URL, kind: ItemKind = .file) -> String? {
        let path = url.path
        guard path.hasPrefix("/"), !path.contains("\0"),
              !url.pathComponents.contains(".."),
              path.unicodeScalars.allSatisfy({ $0.value >= 0x20 }) else { return String(localized: "Unusual path") }
        switch kind {
        case .messagesAttachments:
            // A group: the files are found and checked again when removing, inside Messages/Attachments only.
            return url.scheme == "messages" ? nil : String(localized: "Not Messages attachments")
        case .simulatorRuntime, .dockerPrune, .timeMachineSnapshots, .photoAsset:
            return nil // removed by simctl, docker, tmutil or Photos, not by file operations
        case .homebrewKeg:
            // /opt/homebrew/Cellar/<formula>/<version> (or /usr/local/Cellar on Intel), never the linked one.
            let parts = url.standardizedFileURL.pathComponents
            let cellar = parts.starts(with: ["/", "opt", "homebrew", "Cellar"]) ? 4
                : parts.starts(with: ["/", "usr", "local", "Cellar"]) ? 4 : nil
            guard let cellar, parts.count == cellar + 2, !parts.contains("..") else { return String(localized: "Not a Homebrew version folder") }
            let prefix = "/" + parts[1..<(cellar - 1)].joined(separator: "/")
            let linked = URL(fileURLWithPath: "\(prefix)/opt/\(parts[cellar])").resolvingSymlinksInPath().lastPathComponent
            return linked == parts[cellar + 1] ? String(localized: "The version Homebrew is using") : nil
        case .gitCompact:
            return url.lastPathComponent == ".git" ? nil : String(localized: "Not a git repository")
        default:
            break
        }

        // Resolve symlinks in ancestors (not the item itself: removing a symlink only removes the link).
        let resolved = url.deletingLastPathComponent().resolvingSymlinksInPath()
            .appendingPathComponent(url.lastPathComponent).standardizedFileURL
        if let developer = activeDeveloperApp,
           resolved.path == developer || resolved.path.hasPrefix(developer + "/") || developer.hasPrefix(resolved.path + "/") {
            let tools = (developer as NSString).lastPathComponent
            return String(localized: "Contains the developer tools you're using (\(tools))")
        }
        let components = resolved.pathComponents
        let homeComponents = home.pathComponents
        let inHome = components.count > homeComponents.count
            && zip(homeComponents, components).allSatisfy { $0.lowercased() == $1.lowercased() }
        let relative = inHome ? Array(components.dropFirst(homeComponents.count)) : []
        let lower = relative.map { $0.lowercased() }

        switch kind {
        case .application:
            let isApp = resolved.pathExtension == "app"
            let inApplications = (components.count == 3 || components.count == 4) && components[1] == "Applications"
            let inUserApplications = lower.count == 2 && lower[0] == "applications"
            guard isApp, inApplications || inUserApplications else { return String(localized: "Not an app in an Applications folder") }
            let bundleID = Bundle(url: resolved)?.bundleIdentifier ?? ""
            // Xcode is Apple's but not part of macOS: extra copies may go (the active one is protected above).
            if bundleID.hasPrefix("com.apple.") && bundleID != "com.apple.dt.Xcode" { return String(localized: "Part of macOS") }
            if bundleID == Bundle.main.bundleIdentifier { return String(localized: "That's Spacebar") }
            return nil
        case .appLeftover:
            guard inHome, lower.count == 3, lower[0] == "library",
                  ["containers", "application support", "saved application state", "httpstorages", "webkit", "caches"].contains(lower[1])
            else { return String(localized: "Not an app data folder") }
            if lower[2].hasPrefix("com.apple.") { return String(localized: "Part of macOS") }
            return neverTouchReason(lower)
        case .appData(let bundleID, let appName):
            // ~/Library/<place>/<entry> (or Preferences/ByHost/<entry>) named for this app, never Apple's.
            guard inHome, lower.first == "library", !bundleID.lowercased().hasPrefix("com.apple.") else {
                return String(localized: "Not this app's data")
            }
            let folder = relative.count == 4 && lower[1] == "preferences" && lower[2] == "byhost"
                ? "Preferences/ByHost" : relative.count == 3 ? relative[1] : ""
            guard AppFootprint.places.contains(where: { $0.folder == folder }),
                  AppFootprint.belongs(relative[relative.count - 1], folder: folder, bundleID: bundleID, appName: appName)
            else { return String(localized: "Not this app's data") }
            return nil
        case .iCloudEvict:
            // Only files inside iCloud Drive (Mobile Documents) or a cloud drive (CloudStorage:
            // Dropbox, Google Drive, OneDrive…); nothing is deleted.
            let iCloud = lower.count >= 3 && lower.starts(with: ["library", "mobile documents"])
            let cloudDrive = lower.count >= 4 && lower.starts(with: ["library", "cloudstorage"])
            return inHome && (iCloud || cloudDrive) ? nil : String(localized: "Not in iCloud Drive or a cloud drive")
        case .aiModel:
            guard inHome, (lower.starts(with: [".lmstudio", "models"]) || lower.starts(with: [".cache", "lm-studio", "models"])),
                  lower.count == (lower[0] == ".lmstudio" ? 4 : 5) else { return String(localized: "Not a downloaded model") }
            return nil
        case .androidEmulator(let ini):
            guard inHome, lower.count == 3, lower[0] == ".android", lower[1] == "avd", resolved.pathExtension == "avd",
                  URL(fileURLWithPath: ini).deletingLastPathComponent().standardizedFileURL.path == resolved.deletingLastPathComponent().path
            else { return String(localized: "Not an Android emulator") }
            return nil
        case .simulatorDevice:
            return inHome && lower.count == 5 && lower.starts(with: ["library", "developer", "coresimulator", "devices"])
                ? nil : String(localized: "Not a simulator device folder")
        case .mailAttachments, .mailAttachmentsOlderThan:
            return inHome && lower.count == 4 && lower.starts(with: ["library", "mail"]) && lower[2].hasPrefix("v")
                ? nil : String(localized: "Not a Mail account folder")
        case .simulatorRuntime, .file, .dockerPrune, .timeMachineSnapshots, .photoAsset, .homebrewKeg, .gitCompact,
             .messagesAttachments:
            break
        }

        guard inHome else {
            // Outside home: only macOS installer apps in /Applications.
            if components.count == 3 && components[1] == "Applications"
                && components[2].hasPrefix("Install macOS") && components[2].hasSuffix(".app") { return nil }
            // Other drives: anything inside, except the drive itself, its system folders and backups.
            if components.count >= 3 && components[1] == "Volumes" {
                let systemFolders: Set<String> = [".Spotlight-V100", ".fseventsd", ".Trashes", ".DocumentRevisions-V100",
                                                  ".TemporaryItems", ".PKInstallSandboxManager", ".MobileBackups"]
                if components.count == 3 { return String(localized: "The drive itself") }
                if components[2].hasPrefix(".") { return String(localized: "A drive used by macOS") }
                if systemFolders.contains(components[3]) { return String(localized: "A folder macOS manages on this drive") }
                let driveRoot = "/Volumes/" + components[2]
                if components.contains("Backups.backupdb")
                    || FileManager.default.fileExists(atPath: driveRoot + "/Backups.backupdb")
                    || FileManager.default.fileExists(atPath: driveRoot + "/.com.apple.timemachine.donotpresent") {
                    return String(localized: "Time Machine backups. Manage them in Time Machine")
                }
                return nil
            }
            // /Users/Shared holds user content (games, app libraries); the folder itself stays.
            if components.count >= 3 && components[1] == "Users" && components[2] == "Shared" {
                return components.count >= 4 ? nil : String(localized: "The folder all accounts share")
            }
            if components.count >= 2 && components[1] == "Applications" {
                return String(localized: "Remove apps from the Unused Apps list or with the trash button on the app itself")
            }
            return String(localized: "Outside your home folder")
        }
        guard !lower.isEmpty else { return String(localized: "Your home folder") }
        let name = lower[lower.count - 1]
        if securityFilePatterns.contains(where: { name.contains($0) }) || securityExtensions.contains(resolved.pathExtension.lowercased()) {
            return String(localized: "Looks like a security key or certificate")
        }
        if lower.count == 1 && homeConfigFiles.contains(name) { return String(localized: "Settings for your shell or developer tools") }
        if lower.count == 1 && protectedTopLevel.contains(lower[0]) { return String(localized: "A standard folder of your Mac") }
        if lower.first == "library" && lower.count <= 2 { return String(localized: "A system folder macOS and apps rely on") }
        // A container's own caches folder is fine to clear (the app rebuilds it); the rest of the
        // container is the app's data.
        let containerCaches = lower.count >= 6 && lower[3] == "data" && lower[4] == "library" && lower[5] == "caches"
        if lower.count <= 6 && lower.starts(with: ["library", "containers"]) && !containerCaches {
            return String(localized: "An app's data container. Removing it erases that app's data")
        }
        return neverTouchReason(lower)
    }

    static func neverTouchReason(_ lower: [String]) -> String? {
        let joined = lower.joined(separator: "/")
        for rule in neverTouch where joined == rule.lowercased() || joined.hasPrefix(rule.lowercased() + "/") {
            switch rule {
            case "Library/Keychains": return String(localized: "Your passwords and keys")
            case "Library/Mail": return String(localized: "Your mailboxes")
            case "Library/Messages": return String(localized: "Your messages")
            case "Library/Mobile Documents": return String(localized: "iCloud Drive: deleting here deletes it on all your devices")
            case "Library/CloudStorage": return String(localized: "Cloud storage synced with another service")
            case "Library/Group Containers": return String(localized: "Data shared between apps")
            case "Library/Preferences": return String(localized: "App settings")
            case ".ssh", ".gnupg": return String(localized: "Your security keys")
            default: return String(localized: "Protected data")
            }
        }
        return nil
    }
}

/// Which entries of `~/Library/Caches` are offered for cleaning.
public enum CachePolicy {
    /// Apple caches that are safe to clear. Every other `com.apple.*` cache is left alone:
    /// several hold state (blank System Settings panes, iCloud re-sync, broken ML models).
    static let appleAllowed: Set<String> = [
        "com.apple.QuickLook.thumbnailcache", "com.apple.Safari", "com.apple.WebKit.Networking",
        "GeoServices", "com.apple.helpd", "com.apple.parsecd", "com.apple.appstore",
        "com.apple.Music", "com.apple.podcasts", "com.apple.TV",
    ]

    /// Third-party or Apple caches known to hold state or licences.
    static let deniedPrefixes: [String] = [
        "CloudKit", "FamilyCircle", "GIPPseudonymousID", "CCTClearcutLogger", "ms-playwright",
        "com.paceap", "com.native-instruments", "Adobe", "com.adobe", "com.crowdstrike",
        "com.sentinelone", "com.microsoft.SharePoint", "dev.orbstack", "com.docker",
        "Spacebar",
    ]

    public static func isCleanable(_ name: String) -> Bool {
        if name.hasPrefix(".") || name == Bundle.main.bundleIdentifier { return false }
        if name.hasSuffix("ShortcutsSandboxCache") { return false }
        if deniedPrefixes.contains(where: { name.hasPrefix($0) }) { return false }
        if name.hasPrefix("com.apple.") || name.hasPrefix("com.apple_") {
            return appleAllowed.contains(name)
        }
        return true
    }

    /// Best guess at the app owning a cache folder, used to skip apps that are running.
    public static func ownerBundleID(for name: String) -> String? {
        let known: [String: String] = [
            "Google": "com.google.Chrome", "Firefox": "org.mozilla.firefox",
            "BraveSoftware": "com.brave.Browser", "com.apple.Safari": "com.apple.Safari",
            "com.apple.WebKit.Networking": "com.apple.Safari", "Mozilla": "org.mozilla.firefox",
            "com.apple.Music": "com.apple.Music", "com.apple.podcasts": "com.apple.podcasts",
            "com.apple.TV": "com.apple.TV",
        ]
        if let owner = known[name] { return owner }
        // Most cache folders are named after their app's bundle identifier.
        let parts = name.split(separator: ".")
        return parts.count >= 3 && !name.contains(" ") ? name : nil
    }
}
