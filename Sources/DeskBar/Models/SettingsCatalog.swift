import Foundation

/// The top-level groups shown in the Settings sidebar.
///
/// This enum is the whole taxonomy: the sidebar, the search index, the per-section
/// revert, and the coverage tests all read from `SettingsCatalog`. Adding a `@Published`
/// property to `TaskbarSettings` without adding it here fails `SettingsCatalogTests`.
enum SettingsSection: String, CaseIterable, Identifiable, Sendable {
    case taskbar
    case windows
    case displays
    case launcher
    case widgets
    case system

    var id: String { rawValue }

    var title: String {
        switch self {
        case .taskbar: return "Taskbar"
        case .windows: return "Windows"
        case .displays: return "Displays"
        case .launcher: return "Launcher"
        case .widgets: return "Widgets"
        case .system: return "System"
        }
    }

    var symbol: String {
        switch self {
        case .taskbar: return "macwindow"
        case .windows: return "square.grid.2x2"
        case .displays: return "display"
        case .launcher: return "magnifyingglass"
        case .widgets: return "puzzlepiece.extension"
        case .system: return "gearshape"
        }
    }

    var summary: String {
        switch self {
        case .taskbar: return "Bar style, size, and how task buttons behave."
        case .windows: return "Titles, grouping, thumbnails, and window actions."
        case .displays: return "Which displays get a bar, and what happens to the Dock."
        case .launcher: return "Quick search for apps, files, and commands."
        case .widgets: return "Status widgets, flyouts, and notifications."
        case .system: return "Startup, plugins, and integration with other apps."
        }
    }
}

/// How a setting is presented. Deliberately coarse: it is enough to pick a control and
/// to drive search without a per-setting view.
enum SettingControl: Equatable, Sendable {
    case toggle
    case slider(min: Double, max: Double, step: Double)
    /// An enum-backed `Picker`.
    case choice
    /// A reorderable multi-value list, edited with a bespoke view.
    case list
    /// Free numeric text entry.
    case text
}

/// One setting, described exactly once.
///
/// `reset` and `read` are what make the catalogue more than documentation: "Revert
/// section" needs a way to put a setting back, and search shows each setting's current
/// value. Keeping both here means neither can drift from the UI.
struct SettingDescriptor: Identifiable, Sendable {
    let id: String
    let section: SettingsSection
    let title: String
    /// The help string. Also indexed by search.
    let help: String
    let control: SettingControl
    /// Extra search terms that are not in the title or help text.
    let keywords: [String]
    /// False for flow state the user never edits directly.
    let isUserVisible: Bool
    /// Puts the setting back to its factory value.
    let reset: @Sendable (TaskbarSettings) -> Void
    /// Renders the setting's current value as a short string.
    let read: @Sendable (TaskbarSettings) -> String
    /// Title, help, and keywords, lowercased once for search.
    let searchText: String

    init(
        id: String,
        section: SettingsSection,
        title: String,
        help: String = "",
        control: SettingControl,
        keywords: [String] = [],
        isUserVisible: Bool = true,
        reset: @escaping @Sendable (TaskbarSettings) -> Void,
        read: @escaping @Sendable (TaskbarSettings) -> String
    ) {
        self.id = id
        self.section = section
        self.title = title
        self.help = help
        self.control = control
        self.keywords = keywords
        self.isUserVisible = isUserVisible
        self.reset = reset
        self.read = read
        self.searchText = ([id, title, help] + keywords).joined(separator: " ").lowercased()
    }

    /// Score for a search query. An exact title beats a title prefix, which beats a
    /// title substring, which beats a keyword, which beats a help-text hit.
    /// `nil` means no match.
    func searchScore(for query: String) -> Int? {
        guard !query.isEmpty else { return 0 }
        let q = query.lowercased()
        let titleLower = title.lowercased()
        if titleLower == q { return 100 }
        if titleLower.hasPrefix(q) { return 80 }
        if titleLower.contains(q) { return 60 }
        if keywords.contains(where: { $0.lowercased().contains(q) }) { return 30 }
        if help.lowercased().contains(q) { return 20 }
        return nil
    }
}

/// The single catalogue of every persisted setting.
///
/// `SettingsCatalogTests` enforces the invariants that used to live in reviewers'
/// heads: keys are unique, every `@Published` property on `TaskbarSettings` is described
/// here exactly once, and every `reset` really does restore the factory value.
enum SettingsCatalog {
    private static let entries: [SettingDescriptor] =
        taskbar + windows + displays + launcher + widgets + system

    static let all: [SettingDescriptor] = entries

    static func items(in section: SettingsSection) -> [SettingDescriptor] {
        entries.filter { $0.section == section }
    }

    static func userVisibleItems(in section: SettingsSection) -> [SettingDescriptor] {
        items(in: section).filter(\.isUserVisible)
    }

    static func descriptor(for id: String) -> SettingDescriptor? {
        entries.first { $0.id == id }
    }

    /// Ranked search over every user-visible setting.
    static func search(_ query: String) -> [SettingDescriptor] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return entries
            .filter(\.isUserVisible)
            .compactMap { entry -> (SettingDescriptor, Int)? in
                guard let score = entry.searchScore(for: trimmed) else { return nil }
                return (entry, score)
            }
            .sorted { lhs, rhs in
                if lhs.1 != rhs.1 { return lhs.1 > rhs.1 }
                return lhs.0.title < rhs.0.title
            }
            .map(\.0)
    }

    /// Restores every setting in `sections` to its factory value.
    static func revert(_ settings: TaskbarSettings, sections: Set<SettingsSection>) {
        for entry in entries where sections.contains(entry.section) {
            entry.reset(settings)
        }
    }

    // MARK: - The catalogue


    private static let taskbar: [SettingDescriptor] = [
        SettingDescriptor(
            id: "taskbarMode",
            section: .taskbar,
            title: "Taskbar Style",
            help: "The overall look of the bar: Classic, Windows, Mac, Compact Glass, and more.",
            control: .choice,
            keywords: ["mode", "style", "look", "appearance", "classic", "eskele"],
            reset: { $0.taskbarMode = .custom },
            read: { $0.taskbarMode.displayName }
        ),
        SettingDescriptor(
            id: "layoutMode",
            section: .taskbar,
            title: "Bar Layout",
            help: "How much of the screen the bar spans and whether it uses a translucent material.",
            control: .choice,
            keywords: ["width", "full", "compact", "glass", "material"],
            reset: { $0.layoutMode = .compactGlass },
            read: { $0.layoutMode.displayName }
        ),
        SettingDescriptor(
            id: "dockPosition",
            section: .taskbar,
            title: "Bar Position",
            help: "Where the bar sits on screen.",
            control: .choice,
            reset: { $0.dockPosition = .bottomCenter },
            read: { $0.dockPosition.displayName }
        ),
        SettingDescriptor(
            id: "appTheme",
            section: .taskbar,
            title: "Appearance",
            help: "Follow the system appearance or force light or dark.",
            control: .choice,
            keywords: ["theme", "dark", "light", "colour", "color"],
            reset: { $0.appTheme = .system },
            read: { $0.appTheme.displayName }
        ),
        SettingDescriptor(
            id: "taskbarHeight",
            section: .taskbar,
            title: "Bar Height",
            help: "Height of the bar in points.",
            control: .slider(min: 28, max: 96, step: 1),
            reset: { $0.taskbarHeight = TaskbarSettings.defaultTaskbarHeight },
            read: { String(format: "%.0f pt", $0.taskbarHeight) }
        ),
        SettingDescriptor(
            id: "iconOnlySize",
            section: .taskbar,
            title: "Icon Size",
            help: "Size of task buttons when titles are hidden.",
            control: .slider(min: 16, max: 64, step: 1),
            reset: { $0.iconOnlySize = 24 },
            read: { String(format: "%.0f pt", $0.iconOnlySize) }
        ),
        SettingDescriptor(
            id: "dragReorder",
            section: .taskbar,
            title: "Drag to Reorder",
            help: "Allow task buttons to be dragged into a new order.",
            control: .toggle,
            reset: { $0.dragReorder = true },
            read: { $0.dragReorder ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "middleClickCloses",
            section: .taskbar,
            title: "Middle-Click Closes",
            help: "Middle-clicking a task button closes that window.",
            control: .toggle,
            reset: { $0.middleClickCloses = true },
            read: { $0.middleClickCloses ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "flashAttentionIndicators",
            section: .taskbar,
            title: "Attention Flash",
            help: "Flash a task button when its window asks for attention.",
            control: .toggle,
            reset: { $0.flashAttentionIndicators = true },
            read: { $0.flashAttentionIndicators ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "showProgressIndicators",
            section: .taskbar,
            title: "Progress Indicators",
            help: "Show a progress bar on windows that are downloading or busy.",
            control: .toggle,
            reset: { $0.showProgressIndicators = true },
            read: { $0.showProgressIndicators ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "enableActivityMode",
            section: .taskbar,
            title: "Activity Mode",
            help: "Let windows signal that they are still working so the bar can show it.",
            control: .toggle,
            reset: { $0.enableActivityMode = true },
            read: { $0.enableActivityMode ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "hoverDelay",
            section: .taskbar,
            title: "Hover Delay",
            help: "How long the pointer must rest on a button before its thumbnail appears.",
            control: .slider(min: 0, max: 1.5, step: 0.05),
            reset: { $0.hoverDelay = 0.4 },
            read: { String($0.hoverDelay) }
        )
    ]

    private static let windows: [SettingDescriptor] = [
        SettingDescriptor(
            id: "showTitles",
            section: .windows,
            title: "Show Titles",
            help: "Show the application or window title inside each task button.",
            control: .toggle,
            reset: { $0.showTitles = true },
            read: { $0.showTitles ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "taskTitleSource",
            section: .windows,
            title: "Title Source",
            help: "Use the app name, or the full window title when one is available.",
            control: .choice,
            reset: { $0.taskTitleSource = .windowTitle },
            read: { $0.taskTitleSource.displayName }
        ),
        SettingDescriptor(
            id: "taskTruncationStyle",
            section: .windows,
            title: "Truncation",
            help: "Where a long title is cut: at the end, in the middle, or at the start.",
            control: .choice,
            reset: { $0.taskTruncationStyle = .tail },
            read: { $0.taskTruncationStyle.displayName }
        ),
        SettingDescriptor(
            id: "titleFontSize",
            section: .windows,
            title: "Title Size",
            help: "Font size used for task button titles.",
            control: .slider(min: 9, max: 20, step: 1),
            reset: { $0.titleFontSize = TaskbarSettings.defaultTitleFontSize },
            read: { String(format: "%.0f pt", $0.titleFontSize) }
        ),
        SettingDescriptor(
            id: "maxTaskWidth",
            section: .windows,
            title: "Maximum Task Width",
            help: "Widest a task button may grow before its title is truncated.",
            control: .slider(min: 80, max: 400, step: 10),
            reset: { $0.maxTaskWidth = TaskbarSettings.defaultMaxTaskWidth },
            read: { String(format: "%.0f pt", $0.maxTaskWidth) }
        ),
        SettingDescriptor(
            id: "thumbnailSize",
            section: .windows,
            title: "Thumbnail Size",
            help: "Width of the live window thumbnail shown on hover.",
            control: .slider(min: 120, max: 360, step: 10),
            reset: { $0.thumbnailSize = TaskbarSettings.defaultThumbnailSize },
            read: { String(format: "%.0f pt", $0.thumbnailSize) }
        ),
        SettingDescriptor(
            id: "groupingMode",
            section: .windows,
            title: "Window Grouping",
            help: "Collapse all windows of one app into a single button.",
            control: .choice,
            keywords: ["group", "stack"],
            reset: { $0.groupingMode = .always },
            read: { $0.groupingMode.displayName }
        ),
        SettingDescriptor(
            id: "groupedClickAction",
            section: .windows,
            title: "Clicking a Group",
            help: "Show a window picker, or cycle through the group's windows.",
            control: .choice,
            reset: { $0.groupedClickAction = .cycleWindows },
            read: { $0.groupedClickAction.displayName }
        ),
        SettingDescriptor(
            id: "frontmostClickAction",
            section: .windows,
            title: "Clicking the Front Window",
            help: "Minimise the front window, or cycle to the next window of that app.",
            control: .choice,
            reset: { $0.frontmostClickAction = .cycle },
            read: { $0.frontmostClickAction.displayName }
        ),
        SettingDescriptor(
            id: "showWindowCountBadges",
            section: .windows,
            title: "Window Count Badges",
            help: "Show how many windows an app has open on its task button.",
            control: .toggle,
            reset: { $0.showWindowCountBadges = true },
            read: { $0.showWindowCountBadges ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "enableWindowSwitcher",
            section: .windows,
            title: "Window Switcher",
            help: "Hold a modifier to switch between windows of the active app.",
            control: .toggle,
            keywords: ["alt tab", "switcher"],
            reset: { $0.enableWindowSwitcher = true },
            read: { $0.enableWindowSwitcher ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "enableHoldToQuit",
            section: .windows,
            title: "Hold to Quit",
            help: "Press and hold a task button to quit that app.",
            control: .toggle,
            reset: { $0.enableHoldToQuit = true },
            read: { $0.enableHoldToQuit ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "holdToQuitDuration",
            section: .windows,
            title: "Hold Duration",
            help: "How long the button must be held before the app quits.",
            control: .slider(min: 0.3, max: 5, step: 0.1),
            reset: { $0.holdToQuitDuration = 2.0 },
            read: { String($0.holdToQuitDuration) }
        ),
        SettingDescriptor(
            id: "holdToQuitCmdW",
            section: .windows,
            title: "Hold ⌘W to Quit",
            help: "Hold Command-W on a task button to close every window of that app.",
            control: .toggle,
            reset: { $0.holdToQuitCmdW = false },
            read: { $0.holdToQuitCmdW ? "On" : "Off" }
        )
    ]

    private static let displays: [SettingDescriptor] = [
        SettingDescriptor(
            id: "screenMode",
            section: .displays,
            title: "Show On",
            help: "Which displays get a taskbar: all of them, only the menu bar display, or the focused one.",
            control: .choice,
            keywords: ["monitor", "screen", "multi-display", "external"],
            reset: { $0.screenMode = .allScreens },
            read: { $0.screenMode.displayName }
        ),
        SettingDescriptor(
            id: "nativeDockBehavior",
            section: .displays,
            title: "Native Dock",
            help: "Leave the system Dock alone, auto-hide it, or hide it entirely.",
            control: .choice,
            reset: { $0.nativeDockBehavior = .independent },
            read: { $0.nativeDockBehavior.displayName }
        ),
        SettingDescriptor(
            id: "showOverFullScreenApps",
            section: .displays,
            title: "Show Over Full Screen",
            help: "Keep the bar visible while a full screen app is in front.",
            control: .toggle,
            reset: { $0.showOverFullScreenApps = false },
            read: { $0.showOverFullScreenApps ? "On" : "Off" }
        )
    ]

    private static let launcher: [SettingDescriptor] = [
        SettingDescriptor(
            id: "enableBareCommandLauncher",
            section: .launcher,
            title: "Enable Launcher",
            help: "Open the launcher from anywhere to search apps, files, and commands.",
            control: .toggle,
            reset: { $0.enableBareCommandLauncher = true },
            read: { $0.enableBareCommandLauncher ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "appsLauncherShortcut",
            section: .launcher,
            title: "Launcher Shortcut",
            help: "The gesture or key combination that opens the launcher.",
            control: .choice,
            keywords: ["keyboard", "hotkey", "command", "double tap"],
            reset: { $0.appsLauncherShortcut = .rightCommandTap },
            read: { $0.appsLauncherShortcut.displayName }
        ),
        SettingDescriptor(
            id: "launcherStyle",
            section: .launcher,
            title: "Launcher Presentation",
            help: "Show the launcher anchored to the bar, or centred as a floating panel.",
            control: .choice,
            reset: { $0.launcherStyle = .anchored },
            read: { $0.launcherStyle.displayName }
        ),
        SettingDescriptor(
            id: "fuzzySearch",
            section: .launcher,
            title: "Fuzzy Search",
            help: "Find close matches even when the query is not an exact name.",
            control: .toggle,
            reset: { $0.fuzzySearch = true },
            read: { $0.fuzzySearch ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "autoOpenSingleSearchResult",
            section: .launcher,
            title: "Open Single Results",
            help: "Launch the only match as soon as it is the sole result.",
            control: .toggle,
            reset: { $0.autoOpenSingleSearchResult = false },
            read: { $0.autoOpenSingleSearchResult ? "On" : "Off" }
        )
    ]

    private static let widgets: [SettingDescriptor] = [
        SettingDescriptor(
            id: "connectivityTrayLocation",
            section: .widgets,
            title: "Calendar & Quick Settings Location",
            help: "Put the combined calendar and quick settings widget in the bar or the menu bar.",
            control: .choice,
            keywords: ["tray", "status", "menu bar"],
            reset: { $0.connectivityTrayLocation = .dock },
            read: { $0.connectivityTrayLocation.displayName }
        ),
        SettingDescriptor(
            id: "splitCalendarAndQuickSettings",
            section: .widgets,
            title: "Split Calendar and Quick Settings",
            help: "Show the calendar and the quick settings widget as two separate items.",
            control: .toggle,
            reset: { $0.splitCalendarAndQuickSettings = false },
            read: { $0.splitCalendarAndQuickSettings ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "calendarLocation",
            section: .widgets,
            title: "Calendar Location",
            help: "Where the calendar widget appears.",
            control: .choice,
            reset: { $0.calendarLocation = .dock },
            read: { $0.calendarLocation.displayName }
        ),
        SettingDescriptor(
            id: "quickSettingsLocation",
            section: .widgets,
            title: "Quick Settings Location",
            help: "Where the quick settings widget appears.",
            control: .choice,
            reset: { $0.quickSettingsLocation = .menuBar },
            read: { $0.quickSettingsLocation.displayName }
        ),
        SettingDescriptor(
            id: "batteryWidgetLocation",
            section: .widgets,
            title: "Battery Location",
            help: "Where the battery widget appears.",
            control: .choice,
            reset: { $0.batteryWidgetLocation = .menuBar },
            read: { $0.batteryWidgetLocation.displayName }
        ),
        SettingDescriptor(
            id: "showBatteryPercentage",
            section: .widgets,
            title: "Battery Percentage",
            help: "Show the charge percentage next to the battery icon.",
            control: .toggle,
            reset: { $0.showBatteryPercentage = true },
            read: { $0.showBatteryPercentage ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "showPercentageInsideIcon",
            section: .widgets,
            title: "Percentage Inside Icon",
            help: "Draw the percentage inside the battery icon instead of beside it.",
            control: .toggle,
            reset: { $0.showPercentageInsideIcon = false },
            read: { $0.showPercentageInsideIcon ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "batteryIconStyle",
            section: .widgets,
            title: "Battery Icon Style",
            help: "Shape of the battery indicator.",
            control: .choice,
            reset: { $0.batteryIconStyle = .horizontal },
            read: { $0.batteryIconStyle.displayName }
        ),
        SettingDescriptor(
            id: "batteryIconSize",
            section: .widgets,
            title: "Battery Icon Size",
            help: "Size of the battery indicator.",
            control: .choice,
            reset: { $0.batteryIconSize = .large },
            read: { $0.batteryIconSize.displayName }
        ),
        SettingDescriptor(
            id: "systemResourceWidgetLocation",
            section: .widgets,
            title: "System Resources Location",
            help: "Where the CPU, memory, and network widget appears.",
            control: .choice,
            reset: { $0.systemResourceWidgetLocation = .menuBar },
            read: { $0.systemResourceWidgetLocation.displayName }
        ),
        SettingDescriptor(
            id: "showSystemResourceWidget",
            section: .widgets,
            title: "Show System Resources",
            help: "Show live CPU, memory, GPU, and network activity.",
            control: .toggle,
            reset: { $0.showSystemResourceWidget = true },
            read: { $0.showSystemResourceWidget ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "resourceDisplayStyle",
            section: .widgets,
            title: "Resource Display",
            help: "Draw the resources as simple bars or as scrolling graphs.",
            control: .choice,
            reset: { $0.resourceDisplayStyle = .bar },
            read: { $0.resourceDisplayStyle.displayName }
        ),
        SettingDescriptor(
            id: "weatherEnabled",
            section: .widgets,
            title: "Enable Weather",
            help: "Show current conditions and forecast.",
            control: .toggle,
            reset: { $0.weatherEnabled = true },
            read: { $0.weatherEnabled ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "weatherWidgetLocation",
            section: .widgets,
            title: "Weather Location",
            help: "Where the weather widget appears.",
            control: .choice,
            reset: { $0.weatherWidgetLocation = .dock },
            read: { $0.weatherWidgetLocation.displayName }
        ),
        SettingDescriptor(
            id: "weatherUnit",
            section: .widgets,
            title: "Weather Units",
            help: "Celsius or Fahrenheit.",
            control: .choice,
            keywords: ["temperature", "celsius", "fahrenheit"],
            reset: { $0.weatherUnit = .celsius },
            read: { $0.weatherUnit.displayName }
        ),
        SettingDescriptor(
            id: "weatherPollingInterval",
            section: .widgets,
            title: "Weather Refresh",
            help: "How often the forecast is refreshed.",
            control: .choice,
            reset: { $0.weatherPollingInterval = 900 },
            read: { String($0.weatherPollingInterval) }
        ),
        SettingDescriptor(
            id: "weatherLocationMode",
            section: .widgets,
            title: "Weather Location Source",
            help: "Use the location from the system, or enter coordinates yourself.",
            control: .choice,
            reset: { $0.weatherLocationMode = .automatic },
            read: { $0.weatherLocationMode.displayName }
        ),
        SettingDescriptor(
            id: "weatherManualLatitude",
            section: .widgets,
            title: "Latitude",
            help: "Latitude used when the location source is set to manual.",
            control: .text,
            reset: { $0.weatherManualLatitude = 0 },
            read: { String($0.weatherManualLatitude) }
        ),
        SettingDescriptor(
            id: "weatherManualLongitude",
            section: .widgets,
            title: "Longitude",
            help: "Longitude used when the location source is set to manual.",
            control: .text,
            reset: { $0.weatherManualLongitude = 0 },
            read: { String($0.weatherManualLongitude) }
        ),
        SettingDescriptor(
            id: "dockWidgetOrder",
            section: .widgets,
            title: "Widget Order",
            help: "The order widgets appear in, wherever they live.",
            control: .list,
            keywords: ["reorder", "arrange"],
            reset: { $0.dockWidgetOrder = DockWidgetID.allCases.map(\.rawValue) },
            read: { String($0.dockWidgetOrder.count) }
        ),
        SettingDescriptor(
            id: "enabledQuickSettings",
            section: .widgets,
            title: "Quick Settings Toggles",
            help: "Choose which toggles appear in the quick settings flyout, and in what order.",
            control: .list,
            keywords: ["toggles", "flyout", "menu"],
            reset: { $0.enabledQuickSettings = TaskbarSettings.defaultQuickSettingsIDs },
            read: { String($0.enabledQuickSettings.count) }
        ),
        SettingDescriptor(
            id: "showConnections",
            section: .widgets,
            title: "Connectivity Icon",
            help: "Show Wi-Fi and Bluetooth status in the menu bar.",
            control: .toggle,
            reset: { $0.showConnections = false },
            read: { $0.showConnections ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "notifyBluetoothConnect",
            section: .widgets,
            title: "Bluetooth Alerts",
            help: "Notify when a Bluetooth device connects.",
            control: .toggle,
            reset: { $0.notifyBluetoothConnect = false },
            read: { $0.notifyBluetoothConnect ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "notifyBluetoothLowBattery",
            section: .widgets,
            title: "Low Battery Alerts",
            help: "Notify when a Bluetooth device runs low on battery.",
            control: .toggle,
            reset: { $0.notifyBluetoothLowBattery = false },
            read: { $0.notifyBluetoothLowBattery ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "notifyWiFiChange",
            section: .widgets,
            title: "Network Change Alerts",
            help: "Notify when the machine joins a different network.",
            control: .toggle,
            reset: { $0.notifyWiFiChange = true },
            read: { $0.notifyWiFiChange ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "notifyWiFiWeak",
            section: .widgets,
            title: "Weak Signal Alerts",
            help: "Notify when the Wi-Fi signal degrades.",
            control: .toggle,
            reset: { $0.notifyWiFiWeak = false },
            read: { $0.notifyWiFiWeak ? "On" : "Off" }
        )
    ]

    private static let system: [SettingDescriptor] = [
        SettingDescriptor(
            id: "startAtLogin",
            section: .system,
            title: "Open at Login",
            help: "Launch DockBar when you sign in.",
            control: .toggle,
            reset: { $0.startAtLogin = false },
            read: { $0.startAtLogin ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "enableSessionManagerPlugin",
            section: .system,
            title: "Session Manager Plugin",
            help: "Track coding agents and their activity from the bar.",
            control: .toggle,
            keywords: ["agents", "ai", "plugin"],
            reset: { $0.enableSessionManagerPlugin = true },
            read: { $0.enableSessionManagerPlugin ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "showSessionManagerAgentTitles",
            section: .system,
            title: "Show Agent Titles",
            help: "Label each agent with the task it is working on.",
            control: .toggle,
            reset: { $0.showSessionManagerAgentTitles = true },
            read: { $0.showSessionManagerAgentTitles ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "showSessionManagerActivityIndicators",
            section: .system,
            title: "Show Activity Indicators",
            help: "Mark agents that are currently working.",
            control: .toggle,
            reset: { $0.showSessionManagerActivityIndicators = true },
            read: { $0.showSessionManagerActivityIndicators ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "animateSessionManagerActivity",
            section: .system,
            title: "Animate Activity",
            help: "Animate the activity indicator while an agent is working.",
            control: .toggle,
            reset: { $0.animateSessionManagerActivity = false },
            read: { $0.animateSessionManagerActivity ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "showSessionManagerTokenUsage",
            section: .system,
            title: "Show Token Usage",
            help: "Show how many tokens each agent has consumed.",
            control: .toggle,
            reset: { $0.showSessionManagerTokenUsage = true },
            read: { $0.showSessionManagerTokenUsage ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "enableSessionManagerTerminalActions",
            section: .system,
            title: "Terminal Actions",
            help: "Allow agents to run commands on your behalf from a confirmation prompt.",
            control: .toggle,
            reset: { $0.enableSessionManagerTerminalActions = true },
            read: { $0.enableSessionManagerTerminalActions ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "showSessionManagerActionButton",
            section: .system,
            title: "Show Action Button",
            help: "Show the approve and deny buttons on agent notifications.",
            control: .toggle,
            reset: { $0.showSessionManagerActionButton = true },
            read: { $0.showSessionManagerActionButton ? "On" : "Off" }
        ),
        SettingDescriptor(
            id: "hasCompletedOnboarding",
            section: .system,
            title: "Onboarding Completed",
            help: "Internal flag recording that the first-run walkthrough has been seen.",
            control: .toggle,
            isUserVisible: false,
            reset: { $0.hasCompletedOnboarding = false },
            read: { $0.hasCompletedOnboarding ? "On" : "Off" }
        )
    ]
}
