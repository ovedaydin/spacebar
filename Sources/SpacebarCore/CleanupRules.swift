import Foundation

/// A cleanup rule the user made, e.g. "DMGs and ZIPs in Downloads older than 30 days".
/// Each rule shows up as its own category; matches still go through PathRules and Exclusions,
/// and are only ever moved to the Trash.
public struct CleanupRule: Codable, Identifiable, Sendable, Equatable, Hashable {
    public var id = UUID()
    public var name: String
    /// Where to look: an absolute path, or one starting with "~/".
    public var folder: String
    /// Names to match, with * and ? wildcards (case-insensitive), e.g. "*.dmg" or "node_modules".
    public var patterns: [String]
    /// Only items not changed for this many days.
    public var olderThanDays: Int
    /// How many folder levels to look into: 1 is just the folder's own items.
    public var depth: Int = 1
    /// Include in the weekly automatic clean.
    public var automatic = false

    public init(name: String, folder: String, patterns: [String], olderThanDays: Int, depth: Int = 1, automatic: Bool = false) {
        self.name = name
        self.folder = folder
        self.patterns = patterns
        self.olderThanDays = olderThanDays
        self.depth = depth
        self.automatic = automatic
    }

    /// The category ID, e.g. "rule-1a2b3c4d" (also what `spacebar clean` takes).
    public var categoryID: String { "rule-" + id.uuidString.prefix(8).lowercased() }

    public var folderURL: URL {
        let expanded = folder.hasPrefix("~/") || folder == "~"
            ? FileManager.default.homeDirectoryForCurrentUser.path + folder.dropFirst() : folder
        return URL(fileURLWithPath: expanded).standardizedFileURL
    }

    /// Starting points offered in the rule editor.
    public static var presets: [CleanupRule] {
        [
            CleanupRule(name: String(localized: "Old installers and archives in Downloads"), folder: "~/Downloads",
                        patterns: ["*.dmg", "*.pkg", "*.zip", "*.xip"], olderThanDays: 30),
            CleanupRule(name: String(localized: "Old screenshots on the Desktop"), folder: "~/Desktop",
                        patterns: ["Screenshot*", "Screen Shot*", "Screen Recording*", "Ekran Resmi*", "Captura de pantalla*",
                                   "Bildschirmfoto*"], olderThanDays: 14),
            CleanupRule(name: String(localized: "node_modules in projects untouched for 3 months"), folder: "~/Documents",
                        patterns: ["node_modules"], olderThanDays: 90, depth: 5),
        ]
    }
}

public enum CleanupRules {
    public static let defaultsKey = "cleanupRules"

    public static func load(from defaults: UserDefaults) -> [CleanupRule] {
        guard let data = defaults.data(forKey: defaultsKey) else { return [] }
        return (try? JSONDecoder().decode([CleanupRule].self, from: data)) ?? []
    }

    public static func save(_ rules: [CleanupRule], to defaults: UserDefaults) {
        defaults.set(try? JSONEncoder().encode(rules), forKey: defaultsKey)
    }

    /// Whether `name` matches one of the patterns (shell wildcards, case-insensitive).
    public static func matches(_ name: String, _ patterns: [String]) -> Bool {
        patterns.contains { pattern in
            let trimmed = pattern.trimmingCharacters(in: .whitespaces)
            return !trimmed.isEmpty && fnmatch(trimmed, name, FNM_CASEFOLD) == 0
        }
    }

    /// Files and folders under the rule's folder that match and are old enough. A matching folder
    /// counts as one item (its contents aren't searched). Packages, hidden folders and symlinks
    /// aren't entered.
    static func find(_ rule: CleanupRule, engine: SizeEngine, cancel: CancelToken?, now: Date = Date()) -> [CleanCategory.Candidate] {
        let fm = FileManager.default
        let cutoff = now.addingTimeInterval(-Double(max(0, rule.olderThanDays)) * 86400)
        let keys: [URLResourceKey] = [.isDirectoryKey, .isPackageKey, .isSymbolicLinkKey, .contentModificationDateKey,
                                      .addedToDirectoryDateKey, .isHiddenKey]
        var found: [CleanCategory.Candidate] = []
        var folders: [(URL, Int)] = [(rule.folderURL, 1)]
        while let (folder, level) = folders.popLast() {
            if cancel?.isCancelled == true { break }
            guard let entries = try? fm.contentsOfDirectory(at: folder, includingPropertiesForKeys: keys) else { continue }
            for entry in entries {
                guard let values = try? entry.resourceValues(forKeys: Set(keys)), values.isSymbolicLink != true else { continue }
                let isFolder = values.isDirectory == true
                if matches(entry.lastPathComponent, rule.patterns) {
                    if isFolder {
                        // A folder is as recent as the newest thing in it.
                        let totals = engine.measure(entry, cancel: cancel)
                        guard let newest = totals.lastModified, newest < cutoff else { continue }
                        found.append(.init(url: entry, date: newest, knownSize: totals.allocated, lastUsed: newest, suggested: true))
                    } else {
                        let changed = [values.contentModificationDate, values.addedToDirectoryDate].compactMap { $0 }.max()
                        guard let changed, changed < cutoff else { continue }
                        found.append(.init(url: entry, date: changed, lastUsed: changed, suggested: true))
                    }
                } else if isFolder, level < rule.depth, values.isPackage != true, values.isHidden != true {
                    folders.append((entry, level + 1))
                }
            }
        }
        return found
    }
}

extension CleanCategory {
    /// The category for a user's rule. Everything it finds is preselected: the rule is the user's choice.
    public static func rule(_ rule: CleanupRule) -> CleanCategory {
        let pattern = rule.patterns.joined(separator: ", ")
        return CleanCategory(
            id: rule.categoryID, name: rule.name, icon: "wand.and.stars",
            summary: String(localized: "Your rule: \(pattern) in \(rule.folder), unchanged for \(rule.olderThanDays) days. Matches go to the Trash."),
            safety: .review, mode: .trash, needsFullDiskAccess: false, onDemand: false, owners: [],
            watchedFolder: rule.folderURL.path,
            collect: { context in CleanupRules.find(rule, engine: context.engine, cancel: context.cancel) })
    }
}

extension CleanupRule {
    /// Why the rule can't be saved, if it can't. Patterns must name something (a bare "*" would
    /// match everything), and the folder must exist.
    public var problem: String? {
        if name.trimmingCharacters(in: .whitespaces).isEmpty { return String(localized: "Give the rule a name.") }
        let named = patterns.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        if named.isEmpty { return String(localized: "Add at least one name to match, like *.dmg.") }
        if named.contains(where: { $0.filter { !"*?[]".contains($0) }.count < 2 }) {
            return String(localized: "Each pattern needs some text, like *.dmg or Screenshot*. A lone * would match everything.")
        }
        var isFolder: ObjCBool = false
        if !FileManager.default.fileExists(atPath: folderURL.path, isDirectory: &isFolder) || !isFolder.boolValue {
            return String(localized: "Choose a folder that exists.")
        }
        return nil
    }

    /// What the rule matches right now (for the editor's preview).
    public func preview(engine: SizeEngine) -> (count: Int, bytes: Int64) {
        let found = CleanupRules.find(self, engine: engine, cancel: nil)
            .filter { PathRules.isDeletable($0.url, kind: .file) }
        let unsized = found.filter { $0.knownSize == nil }.map(\.url)
        let sizes = engine.measure(unsized, cancel: nil).reduce(0) { $0 + $1.allocated }
        return (found.count, sizes + found.compactMap(\.knownSize).reduce(0, +))
    }
}
