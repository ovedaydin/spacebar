import AppKit
import Combine
import Foundation

/// "Show in Spacebar" from Finder (Services menu) and `spacebar://show?path=/some/folder` links.
/// Both only open a folder in Space Explorer, which measures and never changes anything.
enum FinderIntegration {
    static let scheme = "spacebar"

    /// Folders to show in the open main window.
    static let requests = PassthroughSubject<URL, Never>()
    /// A folder waiting for the main window to open; the window takes it when it appears.
    @MainActor static var pending: URL?
    /// Opens the main window. Set by the menu bar item, which outlives closed windows.
    @MainActor static var openMainWindow: (() -> Void)?

    @MainActor static func request(_ folder: URL) {
        NSApp.activate(ignoringOtherApps: true)
        if let window = mainWindow {
            window.makeKeyAndOrderFront(nil)
            requests.send(folder)
            return
        }
        pending = folder
        // At launch SwiftUI opens the window itself; only open one if none shows up.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if pending != nil, mainWindow == nil { openMainWindow?() }
        }
    }

    @MainActor private static var mainWindow: NSWindow? {
        NSApp.windows.first { $0.canBecomeMain && $0.isVisible }
    }

    static func showURL(for folder: URL) -> URL? {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "show"
        components.queryItems = [URLQueryItem(name: "path", value: folder.path)]
        return components.url
    }

    /// The folder a `spacebar://show?path=…` link points to. A file shows its folder.
    /// Anything else (other actions, relative or missing paths) is ignored.
    static func folder(from url: URL) -> URL? {
        guard url.scheme?.lowercased() == scheme, url.host?.lowercased() == "show",
              let path = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                  .queryItems?.first(where: { $0.name == "path" })?.value,
              path.hasPrefix("/") else { return nil }
        let target = URL(fileURLWithPath: path).standardizedFileURL
        var isFolder: ObjCBool = false
        guard FileManager.default.fileExists(atPath: target.path, isDirectory: &isFolder) else { return nil }
        let isPackage = (try? target.resourceValues(forKeys: [.isPackageKey]))?.isPackage == true
        return isFolder.boolValue || isPackage ? target : target.deletingLastPathComponent()
    }
}

/// Provides the "Show in Spacebar" service (declared under NSServices in Info.plist).
@MainActor
final class ServiceProvider: NSObject {
    @objc func showInSpacebar(_ pasteboard: NSPasteboard, userData: String?,
                              error: AutoreleasingUnsafeMutablePointer<NSString?>) {
        let urls = pasteboard.readObjects(forClasses: [NSURL.self],
                                          options: [.urlReadingFileURLsOnly: true]) as? [URL] ?? []
        guard let first = urls.first, let link = FinderIntegration.showURL(for: first),
              let folder = FinderIntegration.folder(from: link) else {
            error.pointee = String(localized: "Spacebar can only show folders.") as NSString
            return
        }
        FinderIntegration.request(folder)
    }
}
