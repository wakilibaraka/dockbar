import AppKit

class AppScanner {
    static let shared = AppScanner()

    struct App: Identifiable {
        let id: String
        let name: String
        let path: String
        let icon: NSImage
    }

    lazy var apps: [App] = {
        var result: [App] = []
        var seen = Set<String>()
        let fm = FileManager.default
        let searchPaths = [
            "/Applications",
            "/System/Applications",
            "/System/Applications/Utilities",
            "\(NSHomeDirectory())/Applications",
        ]

        for basePath in searchPaths {
            guard let items = try? fm.contentsOfDirectory(atPath: basePath) else { continue }
            for item in items.sorted() where item.hasSuffix(".app") {
                let fullPath = "\(basePath)/\(item)"
                let name = String(item.dropLast(4))
                guard seen.insert(name).inserted else { continue }
                let icon = NSWorkspace.shared.icon(forFile: fullPath)
                result.append(App(id: fullPath, name: name, path: fullPath, icon: icon))
            }
        }

        return result.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }()
}
