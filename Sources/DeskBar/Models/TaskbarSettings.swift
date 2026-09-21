import AppKit
import Combine

enum DockMode: String, CaseIterable {
    case independent
    case autoHide
    case hidden
}

enum WindowGroupingMode: String, CaseIterable {
    case never
    case automatic
    case always
}

enum DeskBarLayoutMode: String, CaseIterable {
    case fullWidth
    case fullWidthGlass
    case compact
    case compactGlass
}

enum BatteryIconSize: String, CaseIterable, Identifiable {
    case small = "small"
    case standard = "standard"
    case large = "large"
    
    var id: String { self.rawValue }
    
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .standard: return "Standard"
        case .large: return "Large"
        }
    }
}

enum BatteryIconStyle: String, CaseIterable, Identifiable {
    case horizontal
    case vertical
    case verticalBars
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .vertical: return "Vertical"
        case .verticalBars: return "Vertical (Bars)"
        }
    }
}

enum GroupedClickAction: String, CaseIterable {
    case showPopover
    case cycleWindows
}

enum FrontmostClickAction: String, CaseIterable {
    case minimize
    case cycle
}

enum AppsLauncherShortcut: String, CaseIterable {
    case commandTap
    case rightCommandTap
    case controlOptionReturn
    case controlOptionSpace
    case optionSpace
}


enum AppTheme: String, CaseIterable, Identifiable {
    case system
    case light
    case dark
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

enum LauncherStyle: String, CaseIterable {
    case anchored
    case floating
}

enum TaskTitleSource: String, CaseIterable {
    case appName        // Show the app name (e.g. "Chrome")
    case windowTitle    // Show the window title (e.g. "GitHub — Google Chrome")
}

enum TaskTruncationStyle: String, CaseIterable {
    case tail           // "My Very Long Titl..."
    case middle         // "My Very...g Title"
    case ellipsisHead   // "...Very Long Title"
}


enum WidgetLocation: String, CaseIterable, Identifiable {
    case dock
    case menuBar
    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .dock: return "Dock"
        case .menuBar: return "Menu Bar"
        }
    }
}

enum DockWidgetID: String, CaseIterable, Identifiable {
    case connectivity
    case calendar
    case quickSettings
    case systemResources
    case battery
    case weather

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .connectivity: return "Calendar & Quick Settings"
        case .calendar: return "Calendar"
        case .quickSettings: return "Quick Settings"
        case .systemResources: return "System Resources"
        case .battery: return "Battery"
        case .weather: return "Weather"
        }
    }
}

enum WeatherUnit: String, CaseIterable, Identifiable {
    case celsius
    case fahrenheit

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .celsius: return "Celsius (°C)"
        case .fahrenheit: return "Fahrenheit (°F)"
        }
    }
}

enum WeatherLocationMode: String, CaseIterable, Identifiable {
    case automatic
    case manual

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .automatic: return "Automatic"
        case .manual: return "Manual"
        }
    }
}

enum ResourceDisplayStyle: String, CaseIterable, Identifiable {
    case bar
    case graph

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bar: return "Bar"
        case .graph: return "Graph"
        }
    }
}

class TaskbarSettings: ObservableObject {
    static let defaultTaskbarHeight: CGFloat = 44
    static let defaultTitleFontSize: CGFloat = 12
    static let defaultMaxTaskWidth: CGFloat = 240
    static let defaultThumbnailSize: CGFloat = 200

    private let defaults: UserDefaults


        @Published var enabledQuickSettings: [String] {
        didSet { defaults.set(enabledQuickSettings, forKey: "enabledQuickSettings") }
    }

    
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: "hasCompletedOnboarding") }
    }

    @Published var showConnections: Bool {
        didSet { defaults.set(showConnections, forKey: "showConnections") }
    }
    @Published var notifyBluetoothConnect: Bool {
        didSet { defaults.set(notifyBluetoothConnect, forKey: "notifyBluetoothConnect") }
    }
    @Published var notifyBluetoothLowBattery: Bool {
        didSet { defaults.set(notifyBluetoothLowBattery, forKey: "notifyBluetoothLowBattery") }
    }
    @Published var notifyWiFiChange: Bool {
        didSet { defaults.set(notifyWiFiChange, forKey: "notifyWiFiChange") }
    }
    @Published var notifyWiFiWeak: Bool {
        didSet { defaults.set(notifyWiFiWeak, forKey: "notifyWiFiWeak") }
    }
    
    @Published var autoOpenSingleSearchResult: Bool {
        didSet { defaults.set(autoOpenSingleSearchResult, forKey: "autoOpenSingleSearchResult") }
    }
    
    @Published var fuzzySearch: Bool {
        didSet { defaults.set(fuzzySearch, forKey: "fuzzySearch") }
    }

    @Published var showWindowCountBadges: Bool {
        didSet { defaults.set(showWindowCountBadges, forKey: "showWindowCountBadges") }
    }

    @Published var taskbarHeight: CGFloat {
        didSet { defaults.set(taskbarHeight, forKey: "taskbarHeight") }
    }

    @Published var titleFontSize: CGFloat {
        didSet { defaults.set(titleFontSize, forKey: "titleFontSize") }
    }

    @Published var maxTaskWidth: CGFloat {
        didSet { defaults.set(maxTaskWidth, forKey: "maxTaskWidth") }
    }

    @Published var showTitles: Bool {
        didSet { defaults.set(showTitles, forKey: "showTitles") }
    }

    @Published var taskTitleSource: TaskTitleSource {
        didSet { defaults.set(taskTitleSource.rawValue, forKey: "taskTitleSource") }
    }

    @Published var taskTruncationStyle: TaskTruncationStyle {
        didSet { defaults.set(taskTruncationStyle.rawValue, forKey: "taskTruncationStyle") }
    }

    @Published var iconOnlySize: CGFloat {
        didSet { defaults.set(iconOnlySize, forKey: "iconOnlySize") }
    }

    @Published var groupingMode: WindowGroupingMode {
        didSet { defaults.set(groupingMode.rawValue, forKey: "groupingMode") }
    }

    @Published var groupedClickAction: GroupedClickAction {
        didSet { defaults.set(groupedClickAction.rawValue, forKey: "groupedClickAction") }
    }

    @Published var frontmostClickAction: FrontmostClickAction {
        didSet { defaults.set(frontmostClickAction.rawValue, forKey: "frontmostClickAction") }
    }

    @Published var dragReorder: Bool {
        didSet { defaults.set(dragReorder, forKey: "dragReorder") }
    }

    @Published var middleClickCloses: Bool {
        didSet { defaults.set(middleClickCloses, forKey: "middleClickCloses") }
    }

    @Published var thumbnailSize: CGFloat {
        didSet { defaults.set(thumbnailSize, forKey: "thumbnailSize") }
    }

    @Published var hoverDelay: TimeInterval {
        didSet { defaults.set(hoverDelay, forKey: "hoverDelay") }
    }

    @Published var dockMode: DockMode {
        didSet { defaults.set(dockMode.rawValue, forKey: "dockMode") }
    }

    @Published var showOverFullScreenApps: Bool {
        didSet { defaults.set(showOverFullScreenApps, forKey: "showOverFullScreenApps") }
    }

    @Published var flashAttentionIndicators: Bool {
        didSet { defaults.set(flashAttentionIndicators, forKey: "flashAttentionIndicators") }
    }

    @Published var showProgressIndicators: Bool {
        didSet { defaults.set(showProgressIndicators, forKey: "showProgressIndicators") }
    }

    @Published var enableActivityMode: Bool {
        didSet { defaults.set(enableActivityMode, forKey: "enableActivityMode") }
    }

    @Published var showSystemResourceWidget: Bool {
        didSet { defaults.set(showSystemResourceWidget, forKey: "showSystemResourceWidget") }
    }

    @Published var resourceDisplayStyle: ResourceDisplayStyle {
        didSet { defaults.set(resourceDisplayStyle.rawValue, forKey: "resourceDisplayStyle") }
    }
    
    @Published var systemResourceWidgetPinnedDisplayID: CGDirectDisplayID? {
        didSet {
            if let systemResourceWidgetPinnedDisplayID {
                defaults.set(Int(systemResourceWidgetPinnedDisplayID), forKey: "systemResourceWidgetPinnedDisplayID")
            } else {
                defaults.removeObject(forKey: "systemResourceWidgetPinnedDisplayID")
            }
        }
    }

    @Published var startAtLogin: Bool {
        didSet { defaults.set(startAtLogin, forKey: "startAtLogin") }
    }

    @Published var showOnAllMonitors: Bool {
        didSet { defaults.set(showOnAllMonitors, forKey: "showOnAllMonitors") }
    }

    @Published var layoutMode: DeskBarLayoutMode {
        didSet { defaults.set(layoutMode.rawValue, forKey: "layoutMode") }
    }

    @Published var enableWindowSwitcher: Bool {
        didSet { defaults.set(enableWindowSwitcher, forKey: "enableWindowSwitcher") }
    }

    @Published var enableBareCommandLauncher: Bool {
        didSet { defaults.set(enableBareCommandLauncher, forKey: "enableBareCommandLauncher") }
    }

    @Published var appsLauncherShortcut: AppsLauncherShortcut {
        didSet { defaults.set(appsLauncherShortcut.rawValue, forKey: "appsLauncherShortcut") }
    }

        @Published var appTheme: AppTheme {
        didSet { defaults.set(appTheme.rawValue, forKey: "appTheme") }
    }

    @Published var launcherStyle: LauncherStyle {
        didSet { defaults.set(launcherStyle.rawValue, forKey: "launcherStyle") }
    }

    @Published var enableSessionManagerPlugin: Bool {
        didSet { defaults.set(enableSessionManagerPlugin, forKey: "enableSessionManagerPlugin") }
    }

    @Published var showBatteryPercentage: Bool {
        didSet { defaults.set(showBatteryPercentage, forKey: "showBatteryPercentage") }
    }

    @Published var showPercentageInsideIcon: Bool {
        didSet { defaults.set(showPercentageInsideIcon, forKey: "showPercentageInsideIcon") }
    }

    @Published var batteryIconStyle: BatteryIconStyle {
        didSet { defaults.set(batteryIconStyle.rawValue, forKey: "batteryIconStyle") }
    }

    @Published var batteryIconSize: BatteryIconSize {
        didSet { defaults.set(batteryIconSize.rawValue, forKey: "batteryIconSize") }
    }


    @Published var connectivityTrayLocation: WidgetLocation {
        didSet { defaults.set(connectivityTrayLocation.rawValue, forKey: "connectivityTrayLocation") }
    }

    @Published var splitCalendarAndQuickSettings: Bool {
        didSet { defaults.set(splitCalendarAndQuickSettings, forKey: "splitCalendarAndQuickSettings") }
    }

    @Published var calendarLocation: WidgetLocation {
        didSet { defaults.set(calendarLocation.rawValue, forKey: "calendarLocation") }
    }

    @Published var quickSettingsLocation: WidgetLocation {
        didSet { defaults.set(quickSettingsLocation.rawValue, forKey: "quickSettingsLocation") }
    }

    @Published var systemResourceWidgetLocation: WidgetLocation {
        didSet { defaults.set(systemResourceWidgetLocation.rawValue, forKey: "systemResourceWidgetLocation") }
    }

    @Published var batteryWidgetLocation: WidgetLocation {
        didSet { defaults.set(batteryWidgetLocation.rawValue, forKey: "batteryWidgetLocation") }
    }

    @Published var weatherEnabled: Bool {
        didSet { defaults.set(weatherEnabled, forKey: "weatherEnabled") }
    }

    @Published var weatherWidgetLocation: WidgetLocation {
        didSet { defaults.set(weatherWidgetLocation.rawValue, forKey: "weatherWidgetLocation") }
    }

    @Published var dockWidgetOrder: [String] {
        didSet { defaults.set(dockWidgetOrder, forKey: "dockWidgetOrder") }
    }

    @Published var weatherUnit: WeatherUnit {
        didSet { defaults.set(weatherUnit.rawValue, forKey: "weatherUnit") }
    }

    @Published var weatherPollingInterval: TimeInterval {
        didSet { defaults.set(weatherPollingInterval, forKey: "weatherPollingInterval") }
    }

    @Published var weatherLocationMode: WeatherLocationMode {
        didSet { defaults.set(weatherLocationMode.rawValue, forKey: "weatherLocationMode") }
    }

    @Published var weatherManualLatitude: Double {
        didSet { defaults.set(weatherManualLatitude, forKey: "weatherManualLatitude") }
    }

    @Published var weatherManualLongitude: Double {
        didSet { defaults.set(weatherManualLongitude, forKey: "weatherManualLongitude") }
    }

    @Published var showSessionManagerAgentTitles: Bool {
        didSet { defaults.set(showSessionManagerAgentTitles, forKey: "showSessionManagerAgentTitles") }
    }

    @Published var showSessionManagerActivityIndicators: Bool {
        didSet { defaults.set(showSessionManagerActivityIndicators, forKey: "showSessionManagerActivityIndicators") }
    }

    @Published var showSessionManagerTokenUsage: Bool {
        didSet { defaults.set(showSessionManagerTokenUsage, forKey: "showSessionManagerTokenUsage") }
    }

    @Published var animateSessionManagerActivity: Bool {
        didSet { defaults.set(animateSessionManagerActivity, forKey: "animateSessionManagerActivity") }
    }

    @Published var enableHoldToQuit: Bool {
        didSet { defaults.set(enableHoldToQuit, forKey: "enableHoldToQuit") }
    }
    @Published var holdToQuitDuration: Double {
        didSet { defaults.set(holdToQuitDuration, forKey: "holdToQuitDuration") }
    }
    @Published var holdToQuitCmdW: Bool {
        didSet { defaults.set(holdToQuitCmdW, forKey: "holdToQuitCmdW") }
    }

    @Published var enableSessionManagerTerminalActions: Bool {
        didSet { defaults.set(enableSessionManagerTerminalActions, forKey: "enableSessionManagerTerminalActions") }
    }

    @Published var showSessionManagerActionButton: Bool {
        didSet { defaults.set(showSessionManagerActionButton, forKey: "showSessionManagerActionButton") }
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        hasCompletedOnboarding = defaults.object(forKey: "hasCompletedOnboarding") as? Bool ?? false
                showConnections = defaults.object(forKey: "showConnections") as? Bool ?? false
        notifyBluetoothConnect = defaults.object(forKey: "notifyBluetoothConnect") as? Bool ?? false
        notifyBluetoothLowBattery = defaults.object(forKey: "notifyBluetoothLowBattery") as? Bool ?? false
        notifyWiFiChange = defaults.object(forKey: "notifyWiFiChange") as? Bool ?? true
        notifyWiFiWeak = defaults.object(forKey: "notifyWiFiWeak") as? Bool ?? false
        
        autoOpenSingleSearchResult = defaults.object(forKey: "autoOpenSingleSearchResult") as? Bool ?? false
        fuzzySearch = defaults.object(forKey: "fuzzySearch") as? Bool ?? true
        
        showWindowCountBadges = defaults.object(forKey: "showWindowCountBadges") as? Bool ?? true
        enabledQuickSettings = defaults.object(forKey: "enabledQuickSettings") as? [String] ?? [
            "wifi", "bluetooth", "darkMode", "truetone", "mute", "muteMic",
            "keepAwake", "autohideDock", "autohideMenuBar", "hiddenFiles",
            "finderPathBar", "showExtensions", "showUserLibrary", "dockRecentApps",
            "screenshot", "restartFinder", "emptyTrash", "emptyPasteboard",
            "ejectDiscs", "screenSaver", "hideDesktop", "smallLaunchpad",
            "xcodeCache", "pomodoro", "keyboardLock", "speedTest"
        ]
        taskbarHeight = defaults.object(forKey: "taskbarHeight") as? CGFloat ?? Self.defaultTaskbarHeight
        titleFontSize = defaults.object(forKey: "titleFontSize") as? CGFloat ?? Self.defaultTitleFontSize
        maxTaskWidth = defaults.object(forKey: "maxTaskWidth") as? CGFloat ?? Self.defaultMaxTaskWidth
        showTitles = defaults.object(forKey: "showTitles") as? Bool ?? true
        taskTitleSource = TaskTitleSource(rawValue: defaults.string(forKey: "taskTitleSource") ?? "") ?? .windowTitle
        taskTruncationStyle = TaskTruncationStyle(rawValue: defaults.string(forKey: "taskTruncationStyle") ?? "") ?? .tail
        iconOnlySize = defaults.object(forKey: "iconOnlySize") as? CGFloat ?? 24
        if let rawValue = defaults.string(forKey: "groupingMode"),
           let groupingMode = WindowGroupingMode(rawValue: rawValue) {
            self.groupingMode = groupingMode
        } else if defaults.object(forKey: "groupByApp") != nil {
            self.groupingMode = (defaults.object(forKey: "groupByApp") as? Bool ?? false) ? .always : .never
        } else {
            groupingMode = .always
        }
                groupedClickAction = GroupedClickAction(rawValue: defaults.string(forKey: "groupedClickAction") ?? "") ?? .cycleWindows
        frontmostClickAction = FrontmostClickAction(rawValue: defaults.string(forKey: "frontmostClickAction") ?? "") ?? .cycle
        dragReorder = defaults.object(forKey: "dragReorder") as? Bool ?? true
        middleClickCloses = defaults.object(forKey: "middleClickCloses") as? Bool ?? true
        thumbnailSize = defaults.object(forKey: "thumbnailSize") as? CGFloat ?? Self.defaultThumbnailSize
        hoverDelay = defaults.object(forKey: "hoverDelay") as? TimeInterval ?? 0.4
        dockMode = DockMode(rawValue: defaults.string(forKey: "dockMode") ?? "") ?? .independent
        showOverFullScreenApps = defaults.object(forKey: "showOverFullScreenApps") as? Bool ?? false
        flashAttentionIndicators = defaults.object(forKey: "flashAttentionIndicators") as? Bool ?? true
        showProgressIndicators = defaults.object(forKey: "showProgressIndicators") as? Bool ?? true
        enableActivityMode = defaults.object(forKey: "enableActivityMode") as? Bool ?? true
        showSystemResourceWidget = defaults.object(forKey: "showSystemResourceWidget") as? Bool ?? true
        resourceDisplayStyle = ResourceDisplayStyle(
            rawValue: defaults.string(forKey: "resourceDisplayStyle") ?? ""
        ) ?? .bar
        if let pinnedDisplayID = defaults.object(forKey: "systemResourceWidgetPinnedDisplayID") as? NSNumber {
            systemResourceWidgetPinnedDisplayID = CGDirectDisplayID(pinnedDisplayID.uint32Value)
        } else {
            systemResourceWidgetPinnedDisplayID = nil
        }
        startAtLogin = defaults.object(forKey: "startAtLogin") as? Bool ?? false
        showOnAllMonitors = defaults.object(forKey: "showOnAllMonitors") as? Bool ?? true
        layoutMode = DeskBarLayoutMode(rawValue: defaults.string(forKey: "layoutMode") ?? "") ?? .compactGlass
        enableWindowSwitcher = defaults.object(forKey: "enableWindowSwitcher") as? Bool ?? true
        enableBareCommandLauncher = defaults.object(forKey: "enableBareCommandLauncher") as? Bool ?? true
        appsLauncherShortcut = AppsLauncherShortcut(rawValue: defaults.string(forKey: "appsLauncherShortcut") ?? "") ?? .rightCommandTap
        appTheme = AppTheme(rawValue: defaults.string(forKey: "appTheme") ?? "") ?? .system
        launcherStyle = LauncherStyle(rawValue: defaults.string(forKey: "launcherStyle") ?? "") ?? .anchored
        showBatteryPercentage = defaults.object(forKey: "showBatteryPercentage") as? Bool ?? true
        showPercentageInsideIcon = defaults.object(forKey: "showPercentageInsideIcon") as? Bool ?? false
        batteryIconStyle = BatteryIconStyle(rawValue: defaults.string(forKey: "batteryIconStyle") ?? "") ?? .horizontal
        batteryIconSize = BatteryIconSize(rawValue: defaults.string(forKey: "batteryIconSize") ?? "") ?? .large
        enableSessionManagerPlugin = defaults.object(forKey: "enableSessionManagerPlugin") as? Bool ?? true

        connectivityTrayLocation = WidgetLocation(rawValue: defaults.string(forKey: "connectivityTrayLocation") ?? "") ?? .dock
        splitCalendarAndQuickSettings = defaults.object(forKey: "splitCalendarAndQuickSettings") as? Bool ?? false
        calendarLocation = WidgetLocation(rawValue: defaults.string(forKey: "calendarLocation") ?? "") ?? .dock
        quickSettingsLocation = WidgetLocation(rawValue: defaults.string(forKey: "quickSettingsLocation") ?? "") ?? .menuBar
        systemResourceWidgetLocation = WidgetLocation(rawValue: defaults.string(forKey: "systemResourceWidgetLocation") ?? "") ?? .menuBar
        batteryWidgetLocation = WidgetLocation(rawValue: defaults.string(forKey: "batteryWidgetLocation") ?? "") ?? .menuBar
        weatherEnabled = defaults.object(forKey: "weatherEnabled") as? Bool ?? true
        weatherWidgetLocation = WidgetLocation(rawValue: defaults.string(forKey: "weatherWidgetLocation") ?? "") ?? .dock
        dockWidgetOrder = Self.loadDockWidgetOrder(from: defaults)
        weatherUnit = WeatherUnit(rawValue: defaults.string(forKey: "weatherUnit") ?? "") ?? .celsius
        weatherPollingInterval = defaults.object(forKey: "weatherPollingInterval") as? TimeInterval ?? 900
        weatherLocationMode = WeatherLocationMode(rawValue: defaults.string(forKey: "weatherLocationMode") ?? "") ?? .automatic
        weatherManualLatitude = defaults.object(forKey: "weatherManualLatitude") as? Double ?? 0
        weatherManualLongitude = defaults.object(forKey: "weatherManualLongitude") as? Double ?? 0
        showSessionManagerAgentTitles = defaults.object(forKey: "showSessionManagerAgentTitles") as? Bool ?? true
        showSessionManagerActivityIndicators = defaults.object(forKey: "showSessionManagerActivityIndicators") as? Bool ?? true
        showSessionManagerTokenUsage = defaults.object(forKey: "showSessionManagerTokenUsage") as? Bool ?? true
        animateSessionManagerActivity = defaults.object(forKey: "animateSessionManagerActivity") as? Bool ?? false
                enableHoldToQuit = defaults.object(forKey: "enableHoldToQuit") as? Bool ?? true
        holdToQuitDuration = defaults.object(forKey: "holdToQuitDuration") as? Double ?? 2.0
        holdToQuitCmdW = defaults.object(forKey: "holdToQuitCmdW") as? Bool ?? false
        enableSessionManagerTerminalActions = defaults.object(forKey: "enableSessionManagerTerminalActions") as? Bool ?? true
        showSessionManagerActionButton = defaults.object(forKey: "showSessionManagerActionButton") as? Bool ?? true
    }

    func resetAppearanceSlidersToDefaults() {
        taskbarHeight = Self.defaultTaskbarHeight
        titleFontSize = Self.defaultTitleFontSize
        maxTaskWidth = Self.defaultMaxTaskWidth
        thumbnailSize = Self.defaultThumbnailSize
    }

    private static func loadDockWidgetOrder(from defaults: UserDefaults) -> [String] {
        let saved = defaults.stringArray(forKey: "dockWidgetOrder") ?? []
        let valid = Set(DockWidgetID.allCases.map(\.rawValue))
        var result = saved.filter { valid.contains($0) }
        result.append(contentsOf: DockWidgetID.allCases.map(\.rawValue).filter { !result.contains($0) })
        return result
    }
}
