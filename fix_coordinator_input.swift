import Foundation

let path = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content = try! String(contentsOfFile: path)

let oldInputInit = """
        let input = LayoutEngine.Input(
            theme: theme,
            screenFrame: screenFrame,
            visibleFrame: screenFrame,
            apps: apps,
            activeAppID: frontmostApp,
            widgetRequests: widgetRequests,
            isDockHidden: settings.dockMode == .hidden,
            isFullScreen: windowManager.hasFullScreenWindow(on: screen)
        )
"""

let newInputInit = """
        let input = LayoutEngine.Input(
            theme: theme,
            screenFrame: screenFrame,
            visibleFrame: screenFrame,
            apps: apps,
            activeAppID: frontmostApp,
            widgetRequests: widgetRequests,
            isDockHidden: settings.dockMode == .hidden,
            isFullScreen: windowManager.hasFullScreenWindow(on: screen),
            appAlignment: settings.appAlignment.rawValue
        )
"""

content = content.replacingOccurrences(of: oldInputInit, with: newInputInit)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
