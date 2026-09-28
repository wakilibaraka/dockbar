import Foundation

let path1 = "Sources/DockBarCore/LayoutEngine.swift"
var content1 = try! String(contentsOfFile: path1)

let oldInput = """
        public var activeAppID: String?
        public var widgetRequests: [WidgetRequest]
        public var isDockHidden: Bool
        public var isFullScreen: Bool
"""

let newInput = """
        public var activeAppID: String?
        public var widgetRequests: [WidgetRequest]
        public var isDockHidden: Bool
        public var isFullScreen: Bool
        public var appAlignment: String
"""

content1 = content1.replacingOccurrences(of: oldInput, with: newInput)

let oldInit = """
        public init(
            theme: TaskbarTheme,
            screenFrame: CGRect,
            visibleFrame: CGRect,
            apps: [AppItem],
            activeAppID: String?,
            widgetRequests: [WidgetRequest],
            isDockHidden: Bool,
            isFullScreen: Bool
        ) {
            self.theme = theme
            self.screenFrame = screenFrame
            self.visibleFrame = visibleFrame
            self.apps = apps
            self.activeAppID = activeAppID
            self.widgetRequests = widgetRequests
            self.isDockHidden = isDockHidden
            self.isFullScreen = isFullScreen
        }
"""

let newInit = """
        public init(
            theme: TaskbarTheme,
            screenFrame: CGRect,
            visibleFrame: CGRect,
            apps: [AppItem],
            activeAppID: String?,
            widgetRequests: [WidgetRequest],
            isDockHidden: Bool,
            isFullScreen: Bool,
            appAlignment: String = "centered"
        ) {
            self.theme = theme
            self.screenFrame = screenFrame
            self.visibleFrame = visibleFrame
            self.apps = apps
            self.activeAppID = activeAppID
            self.widgetRequests = widgetRequests
            self.isDockHidden = isDockHidden
            self.isFullScreen = isFullScreen
            self.appAlignment = appAlignment
        }
"""

content1 = content1.replacingOccurrences(of: oldInit, with: newInit)
try! content1.write(toFile: path1, atomically: true, encoding: .utf8)
