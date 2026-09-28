import Foundation

let path = "Sources/DeskBar/Models/TaskbarSettings.swift"
var content = try! String(contentsOfFile: path)

let togglesCode = """
    @Published var appAlignment: DeskBarAppAlignment {
        didSet { defaults.set(appAlignment.rawValue, forKey: "appAlignment") }
    }
    @Published var showStartButton: Bool {
        didSet { defaults.set(showStartButton, forKey: "showStartButton") }
    }
    @Published var showSearch: Bool {
        didSet { defaults.set(showSearch, forKey: "showSearch") }
    }
    @Published var showTaskView: Bool {
        didSet { defaults.set(showTaskView, forKey: "showTaskView") }
    }
    @Published var showWidgetsBoard: Bool {
        didSet { defaults.set(showWidgetsBoard, forKey: "showWidgetsBoard") }
    }
    @Published var showDownloads: Bool {
        didSet { defaults.set(showDownloads, forKey: "showDownloads") }
    }
    @Published var showLiveEvents: Bool {
        didSet { defaults.set(showLiveEvents, forKey: "showLiveEvents") }
    }
"""

let initCode = """
        appAlignment = DeskBarAppAlignment(rawValue: defaults.string(forKey: "appAlignment") ?? "") ?? .centered
        showStartButton = defaults.object(forKey: "showStartButton") as? Bool ?? true
        showSearch = defaults.object(forKey: "showSearch") as? Bool ?? true
        showTaskView = defaults.object(forKey: "showTaskView") as? Bool ?? true
        showWidgetsBoard = defaults.object(forKey: "showWidgetsBoard") as? Bool ?? true
        showDownloads = defaults.object(forKey: "showDownloads") as? Bool ?? true
        showLiveEvents = defaults.object(forKey: "showLiveEvents") as? Bool ?? true
"""

content = content.replacingOccurrences(of: "    @Published var showOnAllMonitors: Bool", with: togglesCode + "\n    @Published var showOnAllMonitors: Bool")
content = content.replacingOccurrences(of: "        showOnAllMonitors = defaults.object(forKey: \"showOnAllMonitors\") as? Bool ?? true", with: initCode + "\n        showOnAllMonitors = defaults.object(forKey: \"showOnAllMonitors\") as? Bool ?? true")

try! content.write(toFile: path, atomically: true, encoding: .utf8)
