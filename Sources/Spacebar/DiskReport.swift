import AppKit
import SpacebarCore
import WebKit

/// A one-page, self-contained snapshot of the disk: breakdown, what grew, forecast, largest
/// folders and apps, and what Spacebar can free. Saved as HTML, or printed to PDF.
@MainActor
enum DiskReport {
    /// The app's slice colors (light, dark), so the report matches what people see.
    static let colors: [StorageSegment.Kind: (String, String)] = [
        .macOS: ("#8A8985", "#8F8E88"), .apps: ("#2A78D6", "#3987E5"), .documents: ("#EB6834", "#D95926"),
        .media: ("#1BAF7A", "#199E70"), .developer: ("#EDA100", "#C98500"), .appData: ("#E87BA4", "#D55181"),
        .iCloud: ("#008300", "#008300"), .mail: ("#4A3AA7", "#9085E9"), .trash: ("#E34948", "#E66767"),
        .shared: ("#5D5C58", "#B8B7B0"), .systemData: ("#C4C3BD", "#5B5A56"),
    ]

    static func html(model: AppModel, privatePaths: Bool, now: Date = Date()) -> String {
        let home = NSHomeDirectory()
        func path(_ raw: String) -> String {
            var shown = raw.hasPrefix(home) ? "~" + raw.dropFirst(home.count) : raw
            if privatePaths {
                // Only the top-level folder ("~/Documents/…"); inside Library one more level, since
                // its folder names (Containers, Caches) aren't personal.
                let parts = shown.split(separator: "/", omittingEmptySubsequences: false)
                let keep = parts.count > 1 && parts[1] == "Library" ? 3 : 2
                if parts.count > keep { shown = parts.prefix(keep).joined(separator: "/") + "/…" }
            }
            return escape(shown)
        }
        func size(_ bytes: Int64) -> String { escape(ByteFormat.string(bytes)) }
        var body = ""
        let machine = ProcessInfo.processInfo.operatingSystemVersionString
        body += "<header><h1>\(escape(String(localized: "Disk report")))</h1><p>\(escape(now.formatted(date: .long, time: .shortened))) · macOS \(escape(machine))</p></header>"

        if let space = model.space {
            body += "<section><h2>\(escape(String(localized: "Startup disk")))</h2>"
            body += "<p class=big>\(size(space.available)) \(escape(String(localized: "available of"))) \(size(space.total))</p>"
            if let storage = model.storage {
                let segments = storage.segments.filter { $0.bytes > 0 }
                body += "<div class=bar role=img aria-label=\"\(escape(String(localized: "Disk usage")))\">"
                for segment in segments {
                    let share = Double(segment.bytes) / Double(max(storage.total, 1)) * 100
                    body += "<span style=\"width:\(String(format: "%.2f", share))%;background:var(--\(segment.kind.rawValue))\" title=\"\(escape(segment.name)): \(size(segment.bytes))\"></span>"
                }
                body += "</div><table><thead><tr><th>\(escape(String(localized: "Category")))</th><th class=num>\(escape(String(localized: "Size")))</th></tr></thead><tbody>"
                for segment in segments.sorted(by: { $0.bytes > $1.bytes }) {
                    body += "<tr><td><i style=\"background:var(--\(segment.kind.rawValue))\"></i>\(escape(segment.name))</td><td class=num>\(size(segment.bytes))</td></tr>"
                }
                body += "<tr><td><i class=free></i>\(escape(String(localized: "Free")))</td><td class=num>\(size(storage.free))</td></tr></tbody></table>"
                if let system = segments.first(where: { $0.kind == .systemData }), !system.parts.isEmpty {
                    body += "<h3>\(escape(String(localized: "System Data")))</h3><table><tbody>"
                    for part in system.parts { body += "<tr><td>\(escape(part.name))</td><td class=num>\(size(part.bytes))</td></tr>" }
                    body += "</tbody></table>"
                }
            }
            if let forecast = model.forecast, forecast.days < 365 {
                body += "<p>\(escape(String(localized: "At this rate, the disk is full \(AppModel.forecastPhrase(days: forecast.days)) (about \(ByteFormat.string(Int64(forecast.bytesPerDay))) a day).")))</p>"
            }
            body += "</section>"
        }

        if let growth = model.history.growth(), !growth.items.isEmpty {
            body += "<section><h2>\(escape(String(localized: "What grew"))) <small>\(escape(String(localized: "since \(growth.since.formatted(date: .abbreviated, time: .omitted))")))</small></h2><table><tbody>"
            for item in growth.items.prefix(10) {
                body += "<tr><td>\(path(item.path))</td><td class=num>+\(size(item.delta))</td></tr>"
            }
            body += "</tbody></table></section>"
        }

        if let folders = model.storage?.folderSizes, !folders.isEmpty {
            body += "<section><h2>\(escape(String(localized: "Largest folders")))</h2><table><tbody>"
            for (folder, bytes) in folders.sorted(by: { $0.value > $1.value }).prefix(12) {
                body += "<tr><td>\(path(folder))</td><td class=num>\(size(bytes))</td></tr>"
            }
            body += "</tbody></table></section>"
        }

        if !model.appUsage.isEmpty {
            body += "<section><h2>\(escape(String(localized: "Largest apps")))</h2><table><thead><tr><th>\(escape(String(localized: "App")))</th><th class=num>\(escape(String(localized: "Total")))</th><th class=num>\(escape(String(localized: "Caches")))</th></tr></thead><tbody>"
            for app in model.appUsage.prefix(12) {
                body += "<tr><td>\(escape(app.name))</td><td class=num>\(size(app.total))</td><td class=num>\(size(app.cacheBytes))</td></tr>"
            }
            body += "</tbody></table></section>"
        }

        let cleanable = model.categories.map { ($0, model.suggestedItems($0).reduce(Int64(0)) { $0 + $1.size }) }.filter { $0.1 > 0 }
        if !cleanable.isEmpty {
            body += "<section><h2>\(escape(String(localized: "What Spacebar can free")))</h2><table><tbody>"
            for (category, bytes) in cleanable.sorted(by: { $0.1 > $1.1 }) {
                body += "<tr><td>\(escape(category.name))</td><td class=num>\(size(bytes))</td></tr>"
            }
            body += "</tbody></table></section>"
        }
        body += "<footer>\(escape(String(localized: "Made with Spacebar"))) · ovedaydin.github.io/spacebar</footer>"

        let light = colors.map { "--\($0.key.rawValue):\($0.value.0)" }.joined(separator: ";")
        let dark = colors.map { "--\($0.key.rawValue):\($0.value.1)" }.joined(separator: ";")
        return """
        <!doctype html><html lang="\(FolderGuide.language)"><head><meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1"><title>\(escape(String(localized: "Disk report")))</title>
        <style>
        :root{\(light);--bg:#fff;--text:#1d1d1f;--muted:#6e6e73;--line:#e5e5ea;--free:#e8e8ed}
        @media (prefers-color-scheme:dark){:root{\(dark);--bg:#161618;--text:#f2f2f4;--muted:#a1a1aa;--line:#2c2c31;--free:#2c2c31}}
        body{margin:0;background:var(--bg);color:var(--text);font:15px/1.5 -apple-system,BlinkMacSystemFont,"Helvetica Neue",Arial,sans-serif}
        header,section,footer{max-width:760px;margin:0 auto;padding:18px 16px}
        h1{margin:0;font-size:26px}h2{font-size:18px;margin:0 0 10px}h3{font-size:15px;margin:16px 0 6px}
        header p,small,footer{color:var(--muted);font-weight:normal}.big{font-size:20px;font-weight:600;margin:0 0 10px}
        .bar{display:flex;gap:2px;height:16px;border-radius:4px;overflow:hidden;background:var(--free);margin-bottom:12px}
        .bar span{display:block;min-width:1px}
        table{width:100%;border-collapse:collapse}td,th{padding:5px 0;border-bottom:1px solid var(--line);text-align:left}
        th{color:var(--muted);font-weight:500}.num{text-align:right;font-variant-numeric:tabular-nums;white-space:nowrap;padding-left:16px}
        td i{display:inline-block;width:10px;height:10px;border-radius:2px;margin-right:8px;vertical-align:-1px}i.free{background:var(--free)}
        footer{font-size:13px}@media print{section{break-inside:avoid}}
        </style></head><body>\(body)</body></html>
        """
    }

    static func escape(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;").replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;").replacingOccurrences(of: "\"", with: "&quot;")
    }

    /// Asks where to save, then writes HTML or prints to PDF.
    static func export(model: AppModel, pdf: Bool) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = String(localized: "Disk Report") + (pdf ? ".pdf" : ".html")
        panel.allowedContentTypes = [pdf ? .pdf : .html]
        let privacy = NSButton(checkboxWithTitle: String(localized: "Show only top-level folder names"), target: nil, action: nil)
        privacy.state = .on
        panel.accessoryView = privacy
        guard panel.runModal() == .OK, let url = panel.url else { return }
        let html = html(model: model, privatePaths: privacy.state == .on)
        if pdf {
            PDFRenderer.shared.render(html, to: url)
        } else {
            try? Data(html.utf8).write(to: url, options: .atomic)
            NSWorkspace.shared.activateFileViewerSelecting([url])
        }
    }
}

/// Renders HTML to a PDF with WebKit (offscreen).
@MainActor
final class PDFRenderer: NSObject, WKNavigationDelegate {
    static let shared = PDFRenderer()
    private var view: WKWebView?
    private var destination: URL?

    func render(_ html: String, to url: URL) {
        let view = WKWebView(frame: NSRect(x: 0, y: 0, width: 800, height: 1100))
        view.navigationDelegate = self
        view.appearance = NSAppearance(named: .aqua) // print in light mode
        self.view = view
        destination = url
        view.loadHTMLString(html, baseURL: nil)
    }

    nonisolated func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        Task { @MainActor in
            let configuration = WKPDFConfiguration()
            webView.createPDF(configuration: configuration) { result in
                Task { @MainActor in
                    if case .success(let data) = result, let url = self.destination {
                        try? data.write(to: url, options: .atomic)
                        NSWorkspace.shared.activateFileViewerSelecting([url])
                    }
                    self.view = nil
                    self.destination = nil
                }
            }
        }
    }
}
