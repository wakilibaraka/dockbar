import AppKit
import Combine

enum TaskbarMode: String, CaseIterable, Identifiable {
    case custom
    case windows
    case mac
    case classic
    case eskele

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .custom: return "Custom"
        case .windows: return "Windows"
        case .mac: return "Mac"
        case .classic: return "Classic"
        case .eskele: return "Eskele"
        }
    }

    var subtitle: String {
        switch self {
        case .custom: return "The classic DeskBar experience."
        case .windows: return "A Windows-style taskbar with Start button."
        case .mac: return "A macOS-style floating dock."
        case .classic: return "The original bar: solid edge to edge, one button per window."
        case .eskele: return "A fit-to-icons pill, mirroring eskele's bar."
        }
    }

    /// SF Symbol shown on the onboarding and style cards.
    var symbolName: String {
        switch self {
        case .custom: return "macwindow"
        case .windows: return "window.cascading"
        case .mac: return "dock.rectangle"
        case .classic: return "rectangle.grid.1x2"
        case .eskele: return "capsule"
        }
    }

    /// Older releases persisted this style as `deskBar`. Upgrading installs must keep
    /// their chosen bar, so the legacy raw value is remapped rather than rejected.
    init?(persistedRawValue: String) {
        switch persistedRawValue {
        case "deskBar": self = .classic
        default: self.init(rawValue: persistedRawValue)
        }
    }
}

/// Which displays get a taskbar. This is eskele's screen model, plus the old
/// "follow the focused display" behaviour kept as a named mode so upgrading installs
/// do not silently move their bar.
enum TaskbarScreenMode: String, CaseIterable, Identifiable {
    case allScreens
    case perDisplay
    case menuBarScreen
    case focusedScreen
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .allScreens: return "All displays"
        case .perDisplay: return "Per display"
        case .menuBarScreen: return "Menu bar display"
        case .focusedScreen: return "Focused display"
        }
    }
    
    var subtitle: String {
        switch self {
        case .allScreens: return "The same bar on every display."
        case .perDisplay: return "A bar on every display, each showing that display's windows."
        case .menuBarScreen: return "Only on the display that owns the menu bar."
        case .focusedScreen: return "Follows whichever display has focus (the previous behaviour)."
        }
    }
    
    /// Whether every connected display gets its own bar.
    var showsBarOnEveryDisplay: Bool {
        self == .allScreens || self == .perDisplay
    }
    
    /// Pure display selection, so the rule is unit-testable without NSScreen.
    /// `focusedIndex` is the index of the focused display within the connected list.
    func displayIndexes(displayCount: Int, focusedIndex: Int = 0) -> [Int] {
        guard displayCount > 0 else { return [] }
        switch self {
        case .allScreens, .perDisplay:
            return Array(0..<displayCount)
        case .menuBarScreen:
            // NSScreen.screens lists the menu-bar (primary) display first.
            return [0]
        case .focusedScreen:
            return [min(max(focusedIndex, 0), displayCount - 1)]
        }
    }
}

enum DockPosition: String, CaseIterable, Identifiable {
    case bottomCenter
    case bottomLeft
    case floatingCenter
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .bottomCenter: return "Bottom Center"
        case .bottomLeft: return "Bottom Left"
        case .floatingCenter: return "Floating Center"
        }
    }
}
enum NativeDockBehavior: String, CaseIterable, Identifiable {
    case independent
    case autoHide
    case hidden

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .independent: return "Independent"
        case .autoHide: return "Replace (auto-hide)"
        case .hidden: return "Hidden"
        }
    }

    var help: String {
        switch self {
        case .independent: return "Leave the system Dock exactly as macOS manages it."
        case .autoHide: return "Hide the system Dock and let it slide out on demand."
        case .hidden: return "Hide the system Dock completely."
        }
    }
}

enum WindowGroupingMode: String, CaseIterable, Identifiable {
    case never
    case automatic
    case always

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .never: return "Never"
        case .automatic: return "Automatic"
        case .always: return "Always"
        }
    }
}

enum DeskBarLayoutMode: String, CaseIterable, Identifiable {
    case fullWidth
    case fullWidthGlass
    case compact
    case compactGlass

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fullWidth: return "Full Width"
        case .fullWidthGlass: return "Full Width Glass"
        case .compact: return "Compact"
        case .compactGlass: return "Compact Glass"
        }
    }
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

enum GroupedClickAction: String, CaseIterable, Identifiable {
    case showPopover
    case cycleWindows

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .showPopover: return "Show window list"
        case .cycleWindows: return "Cycle windows"
        }
    }
}

enum FrontmostClickAction: String, CaseIterable, Identifiable {
    case minimize
    case cycle

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimize: return "Minimise"
        case .cycle: return "Cycle windows"
        }
    }
}

enum AppsLauncherShortcut: String, CaseIterable, Identifiable {
    case commandTap
    case rightCommandTap
    case controlOptionReturn
    case controlOptionSpace
    case optionSpace

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .commandTap: return "Double-tap ⌘"
        case .rightCommandTap: return "Double-tap right ⌘"
        case .controlOptionReturn: return "⌃⌥ Return"
        case .controlOptionSpace: return "⌃⌥ Space"
        case .optionSpace: return "⌥ Space"
        }
    }
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

enum LauncherStyle: String, CaseIterable, Identifiable {
    case anchored
    case floating

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .anchored: return "Anchored to bar"
        case .floating: return "Floating panel"
        }
    }
}

enum TaskTitleSource: String, CaseIterable, Identifiable {
    case appName        // Show the app name (e.g. "Chrome")
    case windowTitle    // Show the window title (e.g. "GitHub — Google Chrome")

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .appName: return "Application name"
        case .windowTitle: return "Window title"
        }
    }
}

enum TaskTruncationStyle: String, CaseIterable, Identifiable {
    case tail           // "My Very Long Titl..."
    case middle         // "My Very...g Title"
    case ellipsisHead   // "...Very Long Title"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .tail: return "End"
        case .middle: return "Middle"
        case .ellipsisHead: return "Start"
        }
    }
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

    /// The toggles the quick settings flyout ships with. Kept here so the settings
    /// catalogue's reset action and `init` agree on one list.
    static let defaultQuickSettingsIDs: [String] = [
        "wifi", "bluetooth", "darkMode", "truetone", "mute", "muteMic",
        "keepAwake", "autohideDock", "autohideMenuBar", "hiddenFiles",
        "finderPathBar", "showExtensions", "showUserLibrary", "dockRecentApps",
        "screenshot", "restartFinder", "emptyTrash", "emptyPasteboard",
        "ejectDiscs", "screenSaver", "hideDesktop", "smallLaunchpad",
        "xcodeCache", "pomodoro", "keyboardLock", "speedTest",
    ]

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

    @Published var taskbarMode: TaskbarMode {
        didSet { defaults.set(taskbarMode.rawValue, forKey: "dockMode_system") }
    }
    
    @Published var dockPosition: DockPosition {
        didSet { defaults.set(dockPosition.rawValue, forKey: "dockPosition") }
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

    @Published var nativeDockBehavior: NativeDockBehavior {
        didSet { defaults.set(nativeDockBehavior.rawValue, forKey: "nativeDockBehavior") }
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
    
    

    @Published var startAtLogin: Bool {
        didSet { defaults.set(startAtLogin, forKey: "startAtLogin") }
    }

    @Published var screenMode: TaskbarScreenMode {
        didSet { defaults.set(screenMode.rawValue, forKey: "screenMode") }
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
        enabledQuickSettings = defaults.object(forKey: "enabledQuickSettings") as? [String] ?? Self.defaultQuickSettingsIDs
        taskbarHeight = defaults.object(forKey: "taskbarHeight") as? CGFloat ?? Self.defaultTaskbarHeight
        titleFontSize = defaults.object(forKey: "titleFontSize") as? CGFloat ?? Self.defaultTitleFontSize
        maxTaskWidth = defaults.object(forKey: "maxTaskWidth") as? CGFloat ?? Self.defaultMaxTaskWidth
        showTitles = defaults.object(forKey: "showTitles") as? Bool ?? true
        
        if let storedDockMode = defaults.string(forKey: "dockMode_system"), let mode = TaskbarMode(persistedRawValue: storedDockMode) {
            taskbarMode = mode
        } else {
            let oldWindowsMode = defaults.object(forKey: "windows11Mode") as? Bool ?? false
            taskbarMode = oldWindowsMode ? .windows : .custom
        }
        
        dockPosition = DockPosition(rawValue: defaults.string(forKey: "dockPosition") ?? "") ?? .bottomCenter

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
        nativeDockBehavior = NativeDockBehavior(rawValue: defaults.string(forKey: "nativeDockBehavior") ?? "") ?? .independent
        showOverFullScreenApps = defaults.object(forKey: "showOverFullScreenApps") as? Bool ?? false
        flashAttentionIndicators = defaults.object(forKey: "flashAttentionIndicators") as? Bool ?? true
        showProgressIndicators = defaults.object(forKey: "showProgressIndicators") as? Bool ?? true
        enableActivityMode = defaults.object(forKey: "enableActivityMode") as? Bool ?? true
        showSystemResourceWidget = defaults.object(forKey: "showSystemResourceWidget") as? Bool ?? true
        resourceDisplayStyle = ResourceDisplayStyle(
            rawValue: defaults.string(forKey: "resourceDisplayStyle") ?? ""
        ) ?? .bar
        
        startAtLogin = defaults.object(forKey: "startAtLogin") as? Bool ?? false
        if let rawMode = defaults.string(forKey: "screenMode"),
           let mode = TaskbarScreenMode(rawValue: rawMode) {
            screenMode = mode
        } else {
            // Legacy installs stored a boolean: true meant "every display", false followed
            // the focused one. Both map onto a named mode so nothing moves on upgrade.
            screenMode = (defaults.object(forKey: "showOnAllMonitors") as? Bool ?? true)
                ? .allScreens
                : .focusedScreen
        }
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
