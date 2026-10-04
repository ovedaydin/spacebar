import Foundation

private let fm = FileManager.default

private func list(_ url: URL) -> [URL] {
    (try? fm.contentsOfDirectory(at: url, includingPropertiesForKeys: nil)) ?? []
}

private func modified(_ url: URL) -> Date? {
    (try? url.resourceValues(forKeys: [.contentModificationDateKey]))?.contentModificationDate
}

private func ago(_ date: Date?) -> String {
    guard let date else { return "unknown" }
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: Date())
}

/// Developer tool data: Android, Xcode copies, JetBrains, AI models, Homebrew, git.
enum DeveloperTools {
    typealias Candidate = CleanCategory.Candidate

    static func candidates(home: URL, cancel: CancelToken?) -> [Candidate] {
        android(home: home) + xcodeCopies() + jetBrains(home: home) + aiModels(home: home)
            + homebrew() + gitRepositories(home: home, cancel: cancel)
    }

    // MARK: Android

    /// Simple `key=value` files (Android .ini and config.ini).
    static func keyValues(_ url: URL) -> [String: String] {
        guard let text = try? String(contentsOf: url, encoding: .utf8) else { return [:] }
        var values: [String: String] = [:]
        for line in text.split(separator: "\n") {
            let parts = line.split(separator: "=", maxSplits: 1).map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 { values[parts[0]] = parts[1] }
        }
        return values
    }

    static func android(home: URL) -> [Candidate] {
        var result: [Candidate] = []
        let avdRoot = home.appendingPathComponent(".android/avd")
        var usedImages = Set<String>()
        for ini in list(avdRoot) where ini.pathExtension == "ini" {
            guard let path = keyValues(ini)["path"] else { continue }
            let folder = URL(fileURLWithPath: path)
            guard folder.deletingLastPathComponent().standardizedFileURL.path == avdRoot.standardizedFileURL.path else { continue }
            let config = keyValues(folder.appendingPathComponent("config.ini"))
            if let image = config["image.sysdir.1"] { usedImages.insert(image.trimmingCharacters(in: CharacterSet(charactersIn: "/"))) }
            let lastUsed = list(folder).compactMap(modified).max()
            result.append(Candidate(url: folder, name: config["avd.ini.displayname"] ?? folder.deletingPathExtension().lastPathComponent,
                                    date: lastUsed, detail: "Android emulator · used \(ago(lastUsed))",
                                    kind: .androidEmulator(ini: ini.path), lastUsed: lastUsed))
        }

        let sdk = home.appendingPathComponent("Library/Android/sdk")
        // system-images/<api>/<tag>/<abi>
        for api in list(sdk.appendingPathComponent("system-images")) {
            for tag in list(api) {
                for abi in list(tag) {
                    let relative = "system-images/\(api.lastPathComponent)/\(tag.lastPathComponent)/\(abi.lastPathComponent)"
                    let used = usedImages.contains(relative)
                    result.append(Candidate(url: abi, name: "Android \(api.lastPathComponent) image (\(tag.lastPathComponent))",
                                            date: modified(abi),
                                            detail: used ? "Used by an emulator" : "No emulator uses it · downloaded again by Android Studio when needed",
                                            suggested: used ? nil : true,
                                            lockedReason: used ? "Used by an emulator: remove the emulator first" : nil))
                }
            }
        }
        // Build-tools: keep the newest.
        let tools = list(sdk.appendingPathComponent("build-tools"))
            .sorted { $0.lastPathComponent.compare($1.lastPathComponent, options: .numeric) == .orderedDescending }
        for old in tools.dropFirst() {
            result.append(Candidate(url: old, name: "Android build-tools \(old.lastPathComponent)",
                                    detail: "Newer build-tools \(tools[0].lastPathComponent) installed"))
        }
        return result
    }

    // MARK: Xcode copies

    static func xcodeCopies() -> [Candidate] {
        let index = InstalledAppsIndex.current()
        let active = PathRules.activeDeveloperApp
        return index.apps.filter { $0.bundleID == "com.apple.dt.Xcode" && $0.url.path != active }.map { app in
            let version = Bundle(url: app.url)?.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
            let used = NSMetadataItem(url: app.url)?.value(forAttribute: "kMDItemLastUsedDate") as? Date
            let inApplications = app.url.path.hasPrefix("/Applications/")
            return Candidate(url: app.url, name: "Xcode \(version ?? "")".trimmingCharacters(in: .whitespaces),
                             detail: "Not the Xcode in use · \(app.url.deletingLastPathComponent().path) · opened \(ago(used))",
                             kind: inApplications ? .application : .file, lastUsed: used)
        }
    }

    // MARK: JetBrains

    /// "PyCharmCE2022.3" → ("PyCharmCE", "2022.3").
    static func productVersion(_ name: String) -> (product: String, version: String)? {
        guard let range = name.range(of: #"\d{4}\.\d+$"#, options: .regularExpression) else { return nil }
        return (String(name[..<range.lowerBound]), String(name[range]))
    }

    static func jetBrains(home: URL) -> [Candidate] {
        var result: [Candidate] = []
        for (folder, label, suggest) in [("Library/Caches/JetBrains", "caches", true),
                                         ("Library/Application Support/JetBrains", "settings", false),
                                         ("Library/Logs/JetBrains", "logs", true)] {
            let byProduct = Dictionary(grouping: list(home.appendingPathComponent(folder)).compactMap { url in
                productVersion(url.lastPathComponent).map { (url, $0.product, $0.version) }
            }, by: { $0.1 })
            for (product, versions) in byProduct {
                let sorted = versions.sorted { $0.2.compare($1.2, options: .numeric) == .orderedDescending }
                let installed = InstalledAppsIndex.current().apps.contains { $0.bundleID.lowercased().hasPrefix("com.jetbrains") && $0.name.replacingOccurrences(of: " ", with: "").lowercased().hasPrefix(product.lowercased().replacingOccurrences(of: "ce", with: "")) }
                // The newest version's data stays if that IDE is still installed.
                for entry in (installed ? Array(sorted.dropFirst()) : sorted) {
                    result.append(Candidate(url: entry.0, name: "\(product) \(entry.2) \(label)",
                                            date: modified(entry.0),
                                            detail: installed ? "Older version: newer \(product) data exists" : "\(product) isn't installed",
                                            suggested: suggest ? true : nil))
                }
            }
        }
        return result
    }

    // MARK: AI models

    static func aiModels(home: URL) -> [Candidate] {
        var result: [Candidate] = []
        for root in [".lmstudio/models", ".cache/lm-studio/models"] {
            for publisher in list(home.appendingPathComponent(root)) {
                for model in list(publisher) {
                    let downloaded = modified(model)
                    result.append(Candidate(url: model, name: "\(model.lastPathComponent)",
                                            date: downloaded, detail: "LM Studio model by \(publisher.lastPathComponent) · downloaded \(ago(downloaded))",
                                            kind: .aiModel, lastUsed: downloaded))
                }
            }
        }
        return result
    }

    // MARK: Homebrew

    static func homebrew() -> [Candidate] {
        var result: [Candidate] = []
        for prefix in ["/opt/homebrew", "/usr/local"] {
            let pinned = Set(list(URL(fileURLWithPath: "\(prefix)/var/homebrew/pinned")).map(\.lastPathComponent))
            for formula in list(URL(fileURLWithPath: "\(prefix)/Cellar")) where !pinned.contains(formula.lastPathComponent) {
                let versions = list(formula)
                guard versions.count > 1 else { continue }
                let linked = URL(fileURLWithPath: "\(prefix)/opt/\(formula.lastPathComponent)").resolvingSymlinksInPath().lastPathComponent
                for version in versions where version.lastPathComponent != linked && !version.lastPathComponent.hasPrefix(".") {
                    result.append(Candidate(url: version, name: "\(formula.lastPathComponent) \(version.lastPathComponent)",
                                            date: modified(version), detail: "Old Homebrew version · \(linked) is in use",
                                            kind: .homebrewKeg, suggested: true))
                }
            }
        }
        return result
    }

    // MARK: git

    /// Loose objects git gc would pack, and how many pack files there are.
    static func looseObjects(_ git: URL) -> (bytes: Int64, packs: Int) {
        let objects = git.appendingPathComponent("objects")
        var bytes: Int64 = 0
        for folder in list(objects) where folder.lastPathComponent.count == 2 {
            for file in list(folder) {
                bytes += Int64((try? file.resourceValues(forKeys: [.totalFileAllocatedSizeKey]))?.totalFileAllocatedSize ?? 0)
            }
        }
        let packs = list(objects.appendingPathComponent("pack")).filter { $0.pathExtension == "pack" }.count
        return (bytes, packs)
    }

    static func gitRepositories(home: URL, cancel: CancelToken?) -> [Candidate] {
        guard let walker = fm.enumerator(at: home, includingPropertiesForKeys: [.isDirectoryKey],
                                         options: [.skipsPackageDescendants], errorHandler: { _, _ in true }) else { return [] }
        var result: [Candidate] = []
        let skipped: Set<String> = ["Library", ".Trash", "node_modules", ".cache", ".npm", ".gradle", ".android", ".cocoapods"]
        while let url = walker.nextObject() as? URL {
            if cancel?.isCancelled == true { break }
            let name = url.lastPathComponent
            if skipped.contains(name) { walker.skipDescendants(); continue }
            guard name == ".git" else {
                if name.hasPrefix(".") && walker.level > 1 { walker.skipDescendants() }
                continue
            }
            walker.skipDescendants()
            let (bytes, packs) = looseObjects(url)
            guard bytes >= 50_000_000 || packs >= 20 else { continue }
            let repo = url.deletingLastPathComponent()
            result.append(Candidate(url: url, name: "\(repo.lastPathComponent) (git)",
                                    detail: "\(repo.path.replacingOccurrences(of: home.path, with: "~")) · \(ByteFormat.string(bytes)) not packed, \(packs) pack files · git gc runs in Terminal",
                                    knownSize: max(bytes, 1), kind: .gitCompact))
        }
        return result
    }
}
