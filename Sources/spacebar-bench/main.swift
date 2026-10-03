// Read-only benchmark for Spacebar's scanners. Never deletes or modifies files.
//
//   swift run -c release spacebar-bench [--path P]... [--runs N] [--engines bulk,fm,du]
//                                       [--workers N] [--catalog] [--on-demand]
import Foundation
import SpacebarCore

struct Options {
    var paths: [String] = []
    var runs = 3
    var engines = ["bulk", "fm", "du"]
    var workers: Int?
    var catalog = false
    var onDemand = false
    var treeDepth: Int?
    var list: [String] = []
    var storage = false
    var algos = false
}

func parse() -> Options {
    var options = Options()
    var args = CommandLine.arguments.dropFirst()
    func value() -> String {
        guard let v = args.popFirst() else { fatalError("missing value") }
        return v
    }
    while let arg = args.popFirst() {
        switch arg {
        case "--path": options.paths.append((value() as NSString).expandingTildeInPath)
        case "--runs": options.runs = max(1, Int(value()) ?? 3)
        case "--engines": options.engines = value().split(separator: ",").map(String.init)
        case "--workers": options.workers = Int(value())
        case "--catalog": options.catalog = true
        case "--on-demand": options.onDemand = true
        case "--tree": options.treeDepth = Int(value())
        case "--list": options.list.append(value()); options.catalog = true
        case "--storage": options.storage = true
        case "--algos": options.algos = true
        case "-h", "--help":
            print("""
            spacebar-bench: read-only scanner benchmark
              --path P        folder to measure (repeatable; default: ~/Library/Caches, ~/Library/Developer)
              --runs N        runs per engine (default 3; first run is "cold")
              --engines L     comma list of bulk,fm,du (default all)
              --workers N     BulkScanner thread count
              --catalog       also time the cleanup catalog scan (what the app shows)
              --on-demand     include Old Downloads and Large Files in --catalog (may show privacy prompts)
              --tree D        also time measureTree(depth D) and check subfolder totals against separate scans
              --list ID       print every item of a catalog category (e.g. apps, leftovers, simulators)
              --algos         compare scanning approaches on each --path (speed and accuracy); --runs sets rounds
            """)
            exit(0)
        default:
            FileHandle.standardError.write(Data("unknown argument \(arg)\n".utf8))
            exit(2)
        }
    }
    if options.paths.isEmpty && !options.catalog && !options.storage && !options.algos {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        options.paths = ["\(home)/Library/Caches", "\(home)/Library/Developer"]
            .filter { FileManager.default.fileExists(atPath: $0) }
    }
    return options
}

func time<T>(_ body: () -> T) -> (T, Double) {
    let start = DispatchTime.now().uptimeNanoseconds
    let result = body()
    return (result, Double(DispatchTime.now().uptimeNanoseconds - start) / 1e9)
}

/// `du -skx`: allocated KB, one filesystem, hard links once. Reference for accuracy.
func du(_ path: String) -> Int64 {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/du")
    process.arguments = ["-skx", path]
    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = FileHandle.nullDevice
    try? process.run()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    process.waitUntilExit()
    let kb = String(decoding: data, as: UTF8.self).split(separator: "\t").first.flatMap { Int64($0) } ?? 0
    return kb * 1024
}

func pad(_ s: String, _ n: Int) -> String { s.count >= n ? s : s + String(repeating: " ", count: n - s.count) }
func lpad(_ s: String, _ n: Int) -> String { s.count >= n ? s : String(repeating: " ", count: n - s.count) + s }
func seconds(_ t: Double) -> String { String(format: "%.3fs", t) }

IOPolicy.configureForScanning()
setvbuf(stdout, nil, _IOLBF, 0) // print each result as soon as it's ready, even into a file
let options = parse()
let bulk = options.workers.map { BulkScanner(workers: $0) } ?? BulkScanner()

print("Spacebar bench · \(ProcessInfo.processInfo.operatingSystemVersionString) · \(ProcessInfo.processInfo.activeProcessorCount) cores · bulk workers \(bulk.workers)")
if let space = VolumeSpace.home() {
    print("Data volume: \(ByteFormat.string(space.used)) used, \(ByteFormat.string(space.free)) free, \(ByteFormat.string(space.purgeable)) purgeable")
}
print("Full Disk Access for this process: \(FullDiskAccess.isGranted().map { $0 ? "yes" : "no" } ?? "unknown")")

for path in options.paths {
    print("\n▸ \(path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))")
    print("  " + pad("engine", 16) + lpad("cold", 9) + lpad("median", 9) + lpad("size", 12) + lpad("files", 10) + lpad("dirs", 9) + lpad("unread", 8) + lpad("cloud", 7) + lpad("vs du", 9) + "  newest change")
    var reference: Int64?
    var rows: [(String, [Double], SizeTotals?)] = []

    for engine in options.engines {
        var times: [Double] = []
        var last: SizeTotals?
        for _ in 0..<options.runs {
            switch engine {
            case "bulk":
                let (r, t) = time { bulk.measure(URL(fileURLWithPath: path)) }
                last = r; times.append(t)
            case "fm":
                let (r, t) = time { FileManagerScanner().measure(URL(fileURLWithPath: path)) }
                last = r; times.append(t)
            case "du":
                let (bytes, t) = time { du(path) }
                var r = SizeTotals(); r.allocated = bytes
                last = r; reference = bytes; times.append(t)
            default:
                print("  unknown engine \(engine)")
            }
        }
        rows.append((engine, times, last))
    }

    for (engine, times, totals) in rows {
        guard let totals, let cold = times.first else { continue }
        let median = times.sorted()[times.count / 2]
        var delta = ""
        if let reference, reference > 0, engine != "du" {
            delta = String(format: "%+.2f%%", Double(totals.allocated - reference) / Double(reference) * 100)
        }
        let isDu = engine == "du"
        print("  " + pad(engine == "bulk" ? "getattrlistbulk" : engine == "fm" ? "FileManager" : "du -skx", 16)
              + lpad(seconds(cold), 9) + lpad(seconds(median), 9) + lpad(ByteFormat.string(totals.allocated), 12)
              + lpad(isDu ? "-" : "\(totals.files)", 10) + lpad(isDu ? "-" : "\(totals.directories)", 9)
              + lpad(isDu ? "-" : "\(totals.unreadable)", 8) + lpad(isDu ? "-" : "\(totals.cloudOnlyFiles)", 7)
              + lpad(delta, 9) + "  " + (totals.lastModified.map { ISO8601DateFormatter().string(from: $0) } ?? "-"))
    }
}

if options.algos {
    let engines: [(String, SizeEngine)] = [
        ("bulk · 8w · 128K · DFS · clones (current)", BulkScanner(workers: 8)),
        ("bulk · 4 workers", BulkScanner(workers: 4)),
        ("bulk · 16 workers", BulkScanner(workers: 16)),
        ("bulk · 32 workers", BulkScanner(workers: 32)),
        ("bulk · 32 KB buffer", BulkScanner(workers: 8, bufferSize: 32 * 1024)),
        ("bulk · 512 KB buffer", BulkScanner(workers: 8, bufferSize: 512 * 1024)),
        ("bulk · breadth-first", BulkScanner(workers: 8, breadthFirst: true)),
        ("bulk · no clone lookups", BulkScanner(workers: 8, cloneAware: false)),
        ("fts (1 thread, lstat)", FTSScanner()),
        ("readdir+fstatat · 8w", ParallelStatScanner(workers: 8)),
        ("FileManager", FileManagerScanner()),
    ]
    let rounds = max(options.runs, 2)
    for path in options.paths {
        let url = URL(fileURLWithPath: path)
        print("\n▸ \(path.replacingOccurrences(of: NSHomeDirectory(), with: "~"))  (\(rounds) rounds, rotated order, first round = warm-up)")
        let (reference, duTime) = time { du(path) }
        var times = Array(repeating: [Double](), count: engines.count)
        var results = Array(repeating: SizeTotals(), count: engines.count)
        for round in 0...rounds {
            for offset in 0..<engines.count {
                let index = (offset + round) % engines.count
                let (result, seconds) = time { engines[index].1.measure(url) }
                results[index] = result
                if round > 0 { times[index].append(seconds) }
            }
        }
        let baseline = times[0].sorted()[times[0].count / 2]
        print("  " + pad("approach", 42) + lpad("median", 9) + lpad("vs current", 11) + lpad("size", 11)
              + lpad("vs du", 9) + lpad("files", 10) + lpad("unread", 8))
        for (index, engine) in engines.enumerated() {
            let median = times[index].sorted()[times[index].count / 2]
            let delta = reference > 0 ? String(format: "%+.2f%%", Double(results[index].allocated - reference) / Double(reference) * 100) : "-"
            print("  " + pad(engine.0, 42) + lpad(seconds(median), 9) + lpad(String(format: "%.2f×", baseline / median), 11)
                  + lpad(ByteFormat.string(results[index].allocated), 11) + lpad(delta, 9)
                  + lpad("\(results[index].files)", 10) + lpad("\(results[index].unreadable)", 8))
        }
        print("  " + pad("du -skx (reference)", 42) + lpad(seconds(duTime), 9) + lpad(String(format: "%.2f×", baseline / duTime), 11)
              + lpad(ByteFormat.string(reference), 11))
    }
}

if options.storage {
    let (result, t) = time { StorageAnalyzer.analyze(engine: bulk) { _ in } }
    if let result {
        print("\n▸ Storage breakdown (\(seconds(t)))  total \(ByteFormat.string(result.total)), free \(ByteFormat.string(result.free))")
        for segment in result.segments {
            let share = Double(segment.bytes) / Double(max(result.total, 1)) * 100
            print("  " + pad(segment.name, 26) + lpad(ByteFormat.string(segment.bytes), 11) + lpad(String(format: "%.1f%%", share), 8))
            for part in segment.parts { print("      " + pad(part.name, 44) + lpad(ByteFormat.string(part.bytes), 11)) }
        }
        let sum = result.segments.reduce(0) { $0 + $1.bytes } + result.free
        print("  " + pad("Free", 26) + lpad(ByteFormat.string(result.free), 11) + "   (segments + free = \(ByteFormat.string(sum)))")
    } else {
        print("Storage breakdown unavailable")
    }
}

if let depth = options.treeDepth {
    for path in options.paths {
        let root = URL(fileURLWithPath: path)
        let (tree, t) = time { bulk.measureTree(root, depth: depth) }
        print("\n▸ measureTree \(path.replacingOccurrences(of: NSHomeDirectory(), with: "~")) depth \(depth): \(tree.count) folders in \(seconds(t))")
        let direct = bulk.measure(root)
        print("  root: tree \(tree[root.path]?.allocated ?? -1) B vs separate \(direct.allocated) B → \(tree[root.path]?.allocated == direct.allocated ? "match" : "MISMATCH")")
        let children = tree.filter { URL(fileURLWithPath: $0.key).deletingLastPathComponent().path == root.path }
            .sorted { $0.value.allocated > $1.value.allocated }.prefix(5)
        for (child, totals) in children {
            let separate = bulk.measure(URL(fileURLWithPath: child)).allocated
            print("  \(pad(URL(fileURLWithPath: child).lastPathComponent, 40)) \(lpad(ByteFormat.string(totals.allocated), 10))  \(totals.allocated == separate ? "match" : "MISMATCH (\(separate))")")
        }
    }
}

if options.catalog {
    let context = ScanContext(engine: bulk, runningApps: RunningApps.bundleIDs(),
                              fullDiskAccess: FullDiskAccess.isGranted() ?? false)
    print("\n▸ Cleanup catalog (what the app would offer, nothing is deleted)")
    print("  " + pad("category", 24) + lpad("time", 9) + lpad("items", 7) + lpad("size", 12) + lpad("in use", 8)
          + lpad("suggested", 22) + "  safety")
    var total: Int64 = 0
    var safeTotal: Int64 = 0
    for category in CleanCategory.all where (options.onDemand || !category.onDemand || options.list.contains(category.id))
        && (options.list.isEmpty || options.list.contains(category.id)) {
        let (items, t) = time { category.scan(context) }
        let size = items.reduce(0) { $0 + $1.size }
        total += size
        let suggested = items.filter { Suggestion.isSuggested($0, in: category) }
        let suggestedSize = suggested.reduce(0) { $0 + $1.size }
        safeTotal += suggestedSize
        print("  " + pad(category.name, 24) + lpad(seconds(t), 9) + lpad("\(items.count)", 7)
              + lpad(ByteFormat.string(size), 12) + lpad("\(items.filter(\.inUse).count)", 8)
              + lpad("\(suggested.count) · \(ByteFormat.string(suggestedSize))", 22) + "  \(category.safety.rawValue)")
        if options.list.contains(category.id) {
            for item in items {
                let flags = [Suggestion.isSuggested(item, in: category) ? "suggested" : nil, item.inUse ? "in use" : nil,
                             item.lockedReason.map { "locked: \($0)" }].compactMap { $0 }.joined(separator: ", ")
                print("    " + lpad(ByteFormat.string(item.size), 10) + "  " + pad(String(item.name.prefix(48)), 50)
                      + (item.detail ?? "") + (flags.isEmpty ? "" : "  [\(flags)]"))
            }
        }
    }
    print("  Total found: \(ByteFormat.string(total)) · suggested (safe, not in use, unused for \(Suggestion.defaultStaleDays)+ days): \(ByteFormat.string(safeTotal))")
}
