import Foundation

/// "What is this?" for well-known folders: what's in it, who makes it, and whether it's safe to
/// remove. Offline: the guide ships inside the app (FolderGuideData.swift).
public enum FolderGuide {
    public enum Safety: String, Codable, Sendable {
        /// A cache or build output its tool makes again.
        case regenerates
        /// Temporary or leftover data nothing needs.
        case safe
        /// May be useful: look before deleting.
        case review
        /// Needed by macOS or an app, or your own files.
        case keep
    }

    public struct Entry: Codable, Sendable, Equatable {
        public let match: [String]
        public let title: [String: String]
        public let what: [String: String]
        public let by: String
        public let safety: Safety
        public let category: String?

        public func title(_ language: String) -> String { title[language] ?? title["en"] ?? "" }
        public func what(_ language: String) -> String { what[language] ?? what["en"] ?? "" }
    }

    public struct Match: Sendable, Equatable {
        public let entry: Entry
        /// The folder is inside a known one rather than the known folder itself.
        public let inside: Bool
    }

    public static let entries: [Entry] = {
        (try? JSONDecoder().decode([Entry].self, from: Data(FolderGuideData.json.utf8))) ?? []
    }()

    /// The guide's language for the app's current one (English otherwise).
    public static var language: String {
        let preferred = Bundle.main.preferredLocalizations.first ?? "en"
        return ["tr", "es", "de"].first { preferred.hasPrefix($0) } ?? "en"
    }

    /// What `path` is, or the nearest known folder it's inside.
    public static func lookup(_ path: String, home: String = NSHomeDirectory(), entries: [Entry] = entries) -> Match? {
        var current = display(path, home: home)
        var inside = false
        while current.count > 1 {
            if let entry = best(for: current, in: entries) { return Match(entry: entry, inside: inside) }
            guard let slash = current.lastIndex(of: "/") else { break }
            current = String(current[..<slash])
            inside = true
            if current == "~" || current.isEmpty { break }
        }
        return nil
    }

    /// The most specific entry for a display path: exact patterns first, then the longest.
    static func best(for path: String, in entries: [Entry]) -> Entry? {
        var found: (entry: Entry, score: Int)?
        for entry in entries {
            for pattern in entry.match where matches(path, pattern) {
                let score = (pattern.contains("*") ? 0 : 10_000) + pattern.count
                if found == nil || score > found!.score { found = (entry, score) }
            }
        }
        return found?.entry
    }

    /// Glob match where * stays within one folder name; a leading "*/" matches at any depth.
    static func matches(_ path: String, _ pattern: String) -> Bool {
        if pattern.hasPrefix("*/") {
            let tail = pattern.dropFirst(2).split(separator: "/").map(String.init)
            let parts = path.split(separator: "/").map(String.init)
            guard parts.count >= tail.count else { return false }
            return zip(parts.suffix(tail.count), tail).allSatisfy { fnmatch($1, $0, 0) == 0 }
        }
        return fnmatch(pattern, path, FNM_PATHNAME) == 0
    }

    /// "~/…" for the home folder; the Data volume's prefix is dropped.
    static func display(_ path: String, home: String) -> String {
        var path = path
        if path.hasPrefix("/System/Volumes/Data/") { path = String(path.dropFirst("/System/Volumes/Data".count)) }
        if path == home { return "~" }
        if path.hasPrefix(home + "/") { return "~" + path.dropFirst(home.count) }
        return path
    }
}
