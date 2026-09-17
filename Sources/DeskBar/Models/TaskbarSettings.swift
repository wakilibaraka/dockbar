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

    @Published var batteryIconStyle: BatteryIconStyle {
        didSet { defaults.set(batteryIconStyle.rawValue, forKey: "batteryIconStyle") }
    }

    @Published var showSessionManagerAgentTitles: Bool {
        didSet { defaults.set(showSessionManagerAgentTitles, forKey: "showSessionManagerAgentTitles") }
    }

    @Published var showSessionManagerActivityIndicators: Bool {
        didSet { defaults.set(showSessionManagerActivityIndicators, forKey: "showSessionManagerActivityIndicators") }
    }

    @Published var animateSessionManagerActivity: Bool {
        didSet { defaults.set(animateSessionManagerActivity, forKey: "animateSessionManagerActivity") }
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
                enabledQuickSettings = defaults.object(forKey: "enabledQuickSettings") as? [String] ?? ["darkMode", "mute", "muteMic", "keepAwake", "bluetooth", "hideDesktop", "hiddenFiles"]
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
            groupingMode = .automatic
        }
                groupedClickAction = GroupedClickAction(rawValue: defaults.string(forKey: "groupedClickAction") ?? "") ?? .cycleWindows
        frontmostClickAction = FrontmostClickAction(rawValue: defaults.string(forKey: "frontmostClickAction") ?? "") ?? .minimize
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
        batteryIconStyle = BatteryIconStyle(rawValue: defaults.string(forKey: "batteryIconStyle") ?? "") ?? .horizontal
        enableSessionManagerPlugin = defaults.object(forKey: "enableSessionManagerPlugin") as? Bool ?? true
        showSessionManagerAgentTitles = defaults.object(forKey: "showSessionManagerAgentTitles") as? Bool ?? true
        showSessionManagerActivityIndicators = defaults.object(forKey: "showSessionManagerActivityIndicators") as? Bool ?? true
        animateSessionManagerActivity = defaults.object(forKey: "animateSessionManagerActivity") as? Bool ?? false
        enableSessionManagerTerminalActions = defaults.object(forKey: "enableSessionManagerTerminalActions") as? Bool ?? true
        showSessionManagerActionButton = defaults.object(forKey: "showSessionManagerActionButton") as? Bool ?? true
    }

    func resetAppearanceSlidersToDefaults() {
        taskbarHeight = Self.defaultTaskbarHeight
        titleFontSize = Self.defaultTitleFontSize
        maxTaskWidth = Self.defaultMaxTaskWidth
        thumbnailSize = Self.defaultThumbnailSize
    }
}
