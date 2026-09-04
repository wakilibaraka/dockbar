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
    case winstrix
}

enum AppsLauncherShortcut: String, CaseIterable {
    case commandTap
    case controlOptionReturn
    case controlOptionSpace
    case optionSpace
}

enum FrontmostAppClickBehavior: String, CaseIterable {
    case cycleWindows
    case minimize
}

final class TaskbarSettings: ObservableObject {
    static let defaultTaskbarHeight: CGFloat = 48
    static let defaultTitleFontSize: CGFloat = 13
    static let defaultMaxTaskWidth: CGFloat = 180
    static let defaultThumbnailSize: CGFloat = 200

    private let defaults: UserDefaults

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

    @Published var groupingMode: WindowGroupingMode {
        didSet { defaults.set(groupingMode.rawValue, forKey: "groupingMode") }
    }

    @Published var frontmostAppClickBehavior: FrontmostAppClickBehavior {
        didSet { defaults.set(frontmostAppClickBehavior.rawValue, forKey: "frontmostAppClickBehavior") }
    }

    @Published var dragReorder: Bool {
        didSet { defaults.set(dragReorder, forKey: "dragReorder") }
    }
    
    @Published var quitOnClose: Bool {
        didSet { defaults.set(quitOnClose, forKey: "quitOnClose") }
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

    @Published var hideNativeDock: Bool {
        didSet { defaults.set(hideNativeDock, forKey: "hideNativeDock") }
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

    @Published var showSystemResourceMemoryMetric: Bool {
        didSet { defaults.set(showSystemResourceMemoryMetric, forKey: "showSystemResourceMemoryMetric") }
    }

    @Published var showSystemResourceCPUMetric: Bool {
        didSet { defaults.set(showSystemResourceCPUMetric, forKey: "showSystemResourceCPUMetric") }
    }

    @Published var showSystemResourceGPUMetric: Bool {
        didSet { defaults.set(showSystemResourceGPUMetric, forKey: "showSystemResourceGPUMetric") }
    }

    @Published var systemResourceWidgetCollapsed: Bool {
        didSet { defaults.set(systemResourceWidgetCollapsed, forKey: "systemResourceWidgetCollapsed") }
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

    @Published var showSessionManagerWidget: Bool {
        didSet { defaults.set(showSessionManagerWidget, forKey: "showSessionManagerWidget") }
    }

    @Published var sessionManagerWidgetPinnedDisplayID: CGDirectDisplayID? {
        didSet {
            if let sessionManagerWidgetPinnedDisplayID {
                defaults.set(Int(sessionManagerWidgetPinnedDisplayID), forKey: "sessionManagerWidgetPinnedDisplayID")
            } else {
                defaults.removeObject(forKey: "sessionManagerWidgetPinnedDisplayID")
            }
        }
    }

    @Published var startAtLogin: Bool {
        didSet { defaults.set(startAtLogin, forKey: "startAtLogin") }
    }

    @Published var showClock: Bool {
        didSet { defaults.set(showClock, forKey: "showClock") }
    }

    @Published var clockTargetApp: String {
        didSet { defaults.set(clockTargetApp, forKey: "clockTargetApp") }
    }

    @Published var richContextMenu: Bool {
        didSet { defaults.set(richContextMenu, forKey: "richContextMenu") }
    }

    @Published var pinnedTrayApps: [String] {
        didSet { defaults.set(pinnedTrayApps, forKey: "pinnedTrayApps") }
    }

    @Published var clockTheme: ClockTheme {
        didSet { defaults.set(clockTheme.rawValue, forKey: "clockTheme") }
    }

    @Published var showClockEvents: Bool {
        didSet { defaults.set(showClockEvents, forKey: "showClockEvents") }
    }

    @Published var showQuickSettings: Bool {
        didSet { defaults.set(showQuickSettings, forKey: "showQuickSettings") }
    }

    @Published var enabledQuickSettings: [String] {
        didSet { defaults.set(enabledQuickSettings, forKey: "enabledQuickSettings") }
    }

    @Published var useAppIconAsLauncherButton: Bool {
        didSet { defaults.set(useAppIconAsLauncherButton, forKey: "useAppIconAsLauncherButton") }
    }

    @Published var enableReopenLastQuit: Bool {
        didSet { defaults.set(enableReopenLastQuit, forKey: "enableReopenLastQuit") }
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

    @Published var enableSessionManagerPlugin: Bool {
        didSet { defaults.set(enableSessionManagerPlugin, forKey: "enableSessionManagerPlugin") }
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
        taskbarHeight = defaults.object(forKey: "taskbarHeight") as? CGFloat ?? Self.defaultTaskbarHeight
        titleFontSize = defaults.object(forKey: "titleFontSize") as? CGFloat ?? Self.defaultTitleFontSize
        maxTaskWidth = defaults.object(forKey: "maxTaskWidth") as? CGFloat ?? Self.defaultMaxTaskWidth
        showTitles = defaults.object(forKey: "showTitles") as? Bool ?? true
        if let rawValue = defaults.string(forKey: "groupingMode"),
           let groupingMode = WindowGroupingMode(rawValue: rawValue) {
            self.groupingMode = groupingMode
        } else if defaults.object(forKey: "groupByApp") != nil {
            self.groupingMode = (defaults.object(forKey: "groupByApp") as? Bool ?? false) ? .always : .never
        } else {
            groupingMode = .never
        }
        frontmostAppClickBehavior = FrontmostAppClickBehavior(rawValue: defaults.string(forKey: "frontmostAppClickBehavior") ?? "") ?? .cycleWindows
        dragReorder = defaults.object(forKey: "dragReorder") as? Bool ?? true
        quitOnClose = defaults.object(forKey: "quitOnClose") as? Bool ?? false
        middleClickCloses = defaults.object(forKey: "middleClickCloses") as? Bool ?? true
        thumbnailSize = defaults.object(forKey: "thumbnailSize") as? CGFloat ?? Self.defaultThumbnailSize
        hoverDelay = defaults.object(forKey: "hoverDelay") as? TimeInterval ?? 0.4
        hideNativeDock = defaults.object(forKey: "hideNativeDock") as? Bool ?? true
        showOverFullScreenApps = defaults.object(forKey: "showOverFullScreenApps") as? Bool ?? false
        flashAttentionIndicators = defaults.object(forKey: "flashAttentionIndicators") as? Bool ?? true
        showProgressIndicators = defaults.object(forKey: "showProgressIndicators") as? Bool ?? true
        enableActivityMode = defaults.object(forKey: "enableActivityMode") as? Bool ?? true
        showSystemResourceWidget = defaults.object(forKey: "showSystemResourceWidget") as? Bool ?? true
        showSystemResourceMemoryMetric = defaults.object(forKey: "showSystemResourceMemoryMetric") as? Bool ?? true
        showSystemResourceCPUMetric = defaults.object(forKey: "showSystemResourceCPUMetric") as? Bool ?? true
        showSystemResourceGPUMetric = defaults.object(forKey: "showSystemResourceGPUMetric") as? Bool ?? true
        systemResourceWidgetCollapsed = defaults.object(forKey: "systemResourceWidgetCollapsed") as? Bool ?? false
        if let pinnedDisplayID = defaults.object(forKey: "systemResourceWidgetPinnedDisplayID") as? NSNumber {
            systemResourceWidgetPinnedDisplayID = CGDirectDisplayID(pinnedDisplayID.uint32Value)
        } else {
            systemResourceWidgetPinnedDisplayID = nil
        }
        showSessionManagerWidget = defaults.object(forKey: "showSessionManagerWidget") as? Bool ?? true
        if let pinnedDisplayID = defaults.object(forKey: "sessionManagerWidgetPinnedDisplayID") as? NSNumber {
            sessionManagerWidgetPinnedDisplayID = CGDirectDisplayID(pinnedDisplayID.uint32Value)
        } else {
            sessionManagerWidgetPinnedDisplayID = nil
        }
        startAtLogin = defaults.object(forKey: "startAtLogin") as? Bool ?? false
        showClock = defaults.object(forKey: "showClock") as? Bool ?? false
        clockTargetApp = defaults.object(forKey: "clockTargetApp") as? String ?? "Calendar 366 II"
        richContextMenu = defaults.object(forKey: "richContextMenu") as? Bool ?? false
        pinnedTrayApps = defaults.stringArray(forKey: "pinnedTrayApps") ?? []
        clockTheme = ClockTheme(rawValue: defaults.string(forKey: "clockTheme") ?? "") ?? .ocean
        showClockEvents = defaults.object(forKey: "showClockEvents") as? Bool ?? false
        showQuickSettings = defaults.object(forKey: "showQuickSettings") as? Bool ?? false
        enabledQuickSettings = defaults.stringArray(forKey: "enabledQuickSettings") ?? ["darkMode", "mute", "muteMic", "keepAwake", "bluetooth"]
        useAppIconAsLauncherButton = defaults.object(forKey: "useAppIconAsLauncherButton") as? Bool ?? false
        enableReopenLastQuit = defaults.object(forKey: "enableReopenLastQuit") as? Bool ?? false
        showOnAllMonitors = defaults.object(forKey: "showOnAllMonitors") as? Bool ?? true
        layoutMode = DeskBarLayoutMode(rawValue: defaults.string(forKey: "layoutMode") ?? "") ?? .winstrix
        enableWindowSwitcher = defaults.object(forKey: "enableWindowSwitcher") as? Bool ?? false
        enableBareCommandLauncher = defaults.object(forKey: "enableBareCommandLauncher") as? Bool ?? false
        appsLauncherShortcut = AppsLauncherShortcut(rawValue: defaults.string(forKey: "appsLauncherShortcut") ?? "") ?? .controlOptionReturn
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
