import SwiftUI
import AppKit
import Combine
import UniformTypeIdentifiers

enum SettingsSection: String, CaseIterable, Identifiable {
    case general
    case commandLauncher
    case startMenu
    case taskbar
    case widgets
    case calendarPlugins
    case tray

    var id: String { rawValue }

    var title: String {
        switch self {
        case .general: return "General"
        case .commandLauncher: return "Command Launcher"
        case .startMenu: return "Start Menu"
        case .taskbar: return "Taskbar & Dock"
        case .widgets: return "Widgets"
        case .calendarPlugins: return "Calendar & Plugins"
        case .tray: return "System Tray & Flyouts"
        }
    }

    var symbol: String {
        switch self {
        case .general: return "gearshape"
        case .commandLauncher: return "command"
        case .startMenu: return "square.grid.2x2"
        case .taskbar: return "macwindow"
        case .widgets: return "puzzlepiece.extension"
        case .calendarPlugins: return "calendar.badge.clock"
        case .tray: return "menubar.rectangle"
        }
    }
}

final class SettingsNavigationModel: ObservableObject {
    @Published var selection: SettingsSection? = .general
}

struct SettingsRootView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var pinnedAppManager: PinnedAppManager
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject private var navigation: SettingsNavigationModel

    init(
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        permissionsManager: PermissionsManager,
        thumbnailService: ThumbnailService,
        navigation: SettingsNavigationModel = SettingsNavigationModel()
    ) {
        self.settings = settings
        self.blacklistManager = blacklistManager
        self.pinnedAppManager = pinnedAppManager
        self.permissionsManager = permissionsManager
        self.thumbnailService = thumbnailService
        self.navigation = navigation
    }

    var body: some View {
        NavigationSplitView {
            List(SettingsSection.allCases, selection: $navigation.selection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
            }
            .listStyle(.sidebar)
            .navigationTitle("DeskBar")
            .frame(minWidth: 210)
        } detail: {
            Group {
                switch navigation.selection ?? .general {
                case .general:
                    GeneralSettingsPage(settings: settings, blacklistManager: blacklistManager, permissionsManager: permissionsManager, thumbnailService: thumbnailService)
                case .commandLauncher:
                    CommandLauncherSettingsPage(settings: settings)
                case .startMenu:
                    StartMenuSettingsPage(settings: settings, pinnedAppManager: pinnedAppManager)
                case .taskbar:
                    TaskbarSettingsPage(settings: settings, pinnedAppManager: pinnedAppManager)
                case .widgets:
                    WidgetsSettingsPage(settings: settings)
                case .calendarPlugins:
                    CalendarPluginsSettingsPage(settings: settings)
                case .tray:
                    TraySettingsPage(settings: settings)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
        .navigationSplitViewStyle(.balanced)
    }
}

private struct SettingsPage<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: () -> Content
    let footer: (() -> Text)?

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: @escaping () -> Content,
        footer: (() -> Text)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content
        self.footer = footer
    }

    var body: some View {
        ScrollView {
            Form {
                Section {
                    content()
                } header: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(title).font(.title2.weight(.semibold))
                        Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .textCase(nil)
                } footer: {
                    footer?()
                }
            }
            .formStyle(.grouped)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .frame(maxWidth: 720, alignment: .leading)
        }
    }
}

private struct GeneralSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject private var calendarService = CalendarEventService.shared
    var body: some View {
        SettingsPage(title: "General & Permissions", subtitle: "Startup, privacy access, and apps hidden from the taskbar.") {
            LabeledContent("Start at login") {
                Toggle("", isOn: $settings.startAtLogin).labelsHidden()
            }

            Section("Permissions") {
                SettingsPermissionRow(title: "Accessibility", granted: permissionsManager.isAccessibilityGranted) {
                    permissionsManager.requestAccessibilityPermission()
                }
                SettingsPermissionRow(title: "Screen Recording", granted: thumbnailService.isScreenRecordingGranted) {
                    if !thumbnailService.requestScreenRecordingPermission() {
                        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")
                    }
                }
                SettingsPermissionRow(title: "Calendar", granted: calendarService.isAuthorized) {
                    calendarService.checkPermission()
                    openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")
                }
            }

            Section("Hidden Applications") {
                Text("Selected apps will not appear as taskbar items.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Add an app") {
                    Button("Choose Application…") {
                        chooseApplication { url in
                            if let bundleID = Bundle(url: url)?.bundleIdentifier {
                                blacklistManager.add(bundleIdentifier: bundleID)
                            }
                        }
                    }
                }
                ForEach(Array(blacklistManager.blacklistedBundleIDs).sorted(), id: \.self) { bundleID in
                    HStack {
                        Text(bundleID).font(.callout)
                        Spacer()
                        Button("Remove", role: .destructive) {
                            blacklistManager.remove(bundleIdentifier: bundleID)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
    }
}

private struct CommandLauncherSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        SettingsPage(title: "Command Launcher", subtitle: "Open DeskBar search quickly from anywhere.") {
            LabeledContent("Enable launcher") {
                Toggle("", isOn: $settings.enableBareCommandLauncher).labelsHidden()
            }
            Picker("Shortcut", selection: $settings.appsLauncherShortcut) {
                Text("Double-tap Command").tag(AppsLauncherShortcut.commandTap)
                Text("Double-tap Right Command").tag(AppsLauncherShortcut.rightCommandTap)
                Text("Control + Option + Return").tag(AppsLauncherShortcut.controlOptionReturn)
                Text("Control + Option + Space").tag(AppsLauncherShortcut.controlOptionSpace)
                Text("Option + Space").tag(AppsLauncherShortcut.optionSpace)
            }
            Picker("Presentation", selection: $settings.launcherStyle) {
                Text("Anchored").tag(LauncherStyle.anchored)
                Text("Floating").tag(LauncherStyle.floating)
            }
            Toggle("Fuzzy Search", isOn: $settings.fuzzySearch)
            Toggle("Open a single result automatically", isOn: $settings.autoOpenSingleSearchResult)
        } footer: {
            Text("Fuzzy Search finds close matches even when the query does not exactly match an app or command name.")
        }
    }
}

private struct StartMenuSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var pinnedAppManager: PinnedAppManager
    @ObservedObject private var launchpickManager = LaunchpickConfigManager.shared
    @AppStorage("launchpickShowPinnedApps") private var showPinnedApps = true
    @AppStorage("launchpickShowMostUsedApps") private var showMostUsedApps = true
    @AppStorage("allAppsLayout") private var allAppsLayout = AllAppsLayout.grid
    var body: some View {
        SettingsPage(title: "Start Menu", subtitle: "Choose what appears in Launchpick and manage its shortcuts.") {
            Toggle("Show pinned apps", isOn: $showPinnedApps)
            Toggle("Show most-used apps", isOn: $showMostUsedApps)
            Picker("All apps layout", selection: $allAppsLayout) {
                ForEach(AllAppsLayout.allCases) { layout in
                    Text(layout.rawValue).tag(layout)
                }
            }
            Section("Pinned shortcuts") {
                LabeledContent("Add shortcut") {
                    Button("Choose Application…") {
                        chooseApplication { url in
                            let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String ?? url.deletingPathExtension().lastPathComponent
                            launchpickManager.addLauncher(ConfigLauncher(name: name, exec: "open -a '\(name)'", icon: nil))
                        }
                    }
                }
                List {
                    ForEach(Array(launchpickManager.config.launchers.enumerated()), id: \.element.name) { index, launcher in
                        HStack {
                            Image(systemName: "app.fill").foregroundStyle(.secondary)
                            VStack(alignment: .leading) {
                                Text(launcher.name)
                                Text(launcher.exec).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                launchpickManager.removeLauncher(at: index)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                    .onMove { source, destination in
                        launchpickManager.moveLauncher(from: source, to: destination)
                    }
                }
                .frame(height: 180)
            }
        }
    }
}

private struct TaskbarSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var pinnedAppManager: PinnedAppManager
    var body: some View {
        SettingsPage(title: "Taskbar & Dock", subtitle: "Control the dock presentation, task buttons, and pinned apps.") {
            Picker("Dock mode", selection: $settings.nativeDockBehavior) {
                Text("Independent").tag(NativeDockBehavior.independent)
                Text("Hide Native Dock").tag(NativeDockBehavior.hidden)
                Text("Replace (Autohide)").tag(NativeDockBehavior.autoHide)
            }
            Picker("Theme", selection: $settings.appTheme) {
                ForEach(AppTheme.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("Layout", selection: $settings.layoutMode) {
                Text("Full Width").tag(DeskBarLayoutMode.fullWidth)
                Text("Full Width Glass").tag(DeskBarLayoutMode.fullWidthGlass)
                Text("Compact").tag(DeskBarLayoutMode.compact)
                Text("Compact Glass").tag(DeskBarLayoutMode.compactGlass)
            }
            LabeledContent("Taskbar height") {
                HStack {
                    Slider(value: $settings.taskbarHeight, in: 30...80, step: 2)
                    Text("\(Int(settings.taskbarHeight)) pt").monospacedDigit()
                }
                .frame(width: 220)
            }
            Toggle("Show over fullscreen windows", isOn: $settings.showOverFullScreenApps)
            Toggle("Show on all monitors", isOn: $settings.showOnAllMonitors)
            Picker("Taskbar Style", selection: $settings.taskbarMode) {
                ForEach(TaskbarMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            Section("Task items") {
                Toggle("Show titles", isOn: $settings.showTitles)
                Picker("Title source", selection: $settings.taskTitleSource) {
                    Text("Window title").tag(TaskTitleSource.windowTitle)
                    Text("Application name").tag(TaskTitleSource.appName)
                }
                Picker("Truncation", selection: $settings.taskTruncationStyle) {
                    Text("Tail").tag(TaskTruncationStyle.tail)
                    Text("Middle").tag(TaskTruncationStyle.middle)
                    Text("Head").tag(TaskTruncationStyle.ellipsisHead)
                }
                LabeledContent("Maximum task width") {
                    Slider(value: $settings.maxTaskWidth, in: 100...400, step: 10)
                        .frame(width: 220)
                }
            }
            Section("Pinned apps") {
                LabeledContent("Add an app") {
                    Button("Choose Application…") {
                        chooseApplication { url in
                            guard let bundle = Bundle(url: url),
                                  let bundleID = bundle.bundleIdentifier else { return }
                            let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String ?? url.deletingPathExtension().lastPathComponent
                            pinnedAppManager.pin(bundleIdentifier: bundleID, name: name)
                        }
                    }
                }
                List {
                    ForEach(pinnedAppManager.pinnedApps, id: \.bundleIdentifier) { app in
                        HStack {
                            if let icon = app.icon { Image(nsImage: icon).resizable().frame(width: 20, height: 20) }
                            Text(app.name)
                            Spacer()
                            Button("Remove", role: .destructive) {
                                pinnedAppManager.unpin(bundleIdentifier: app.bundleIdentifier)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
                .frame(height: 150)
            }
        }
    }
}

private struct WidgetsSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        SettingsPage(title: "Widgets", subtitle: "Choose where status widgets appear and how much detail they show.") {
            Section("Battery") {
                Picker("Location", selection: $settings.batteryWidgetLocation) {
                    ForEach(WidgetLocation.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Show percentage next to icon", isOn: $settings.showBatteryPercentage)
                Toggle("Show percentage inside icon", isOn: $settings.showPercentageInsideIcon)
                Picker("Icon style", selection: $settings.batteryIconStyle) {
                    ForEach(BatteryIconStyle.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Icon size", selection: $settings.batteryIconSize) {
                    ForEach(BatteryIconSize.allCases) { Text($0.displayName).tag($0) }
                }
            }
            Section("System Resources") {
                Picker("Location", selection: $settings.systemResourceWidgetLocation) {
                    ForEach(WidgetLocation.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                Toggle("Show resource widget", isOn: $settings.showSystemResourceWidget)
                Picker("Display", selection: $settings.resourceDisplayStyle) {
                    ForEach(ResourceDisplayStyle.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
            }
            Section("Weather") {
                Toggle("Enable weather widget", isOn: $settings.weatherEnabled)
                Picker("Location", selection: $settings.weatherWidgetLocation) {
                    ForEach(WidgetLocation.allCases) { Text($0.displayName).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Units", selection: $settings.weatherUnit) {
                    ForEach(WeatherUnit.allCases) { Text($0.displayName).tag($0) }
                }
                Picker("Refresh", selection: $settings.weatherPollingInterval) {
                    Text("15 minutes").tag(TimeInterval(900))
                    Text("30 minutes").tag(TimeInterval(1800))
                    Text("1 hour").tag(TimeInterval(3600))
                }
                Picker("Location mode", selection: $settings.weatherLocationMode) {
                    ForEach(WeatherLocationMode.allCases) { Text($0.displayName).tag($0) }
                }
                if settings.weatherLocationMode == .manual {
                    TextField("Latitude", value: $settings.weatherManualLatitude, format: .number)
                    TextField("Longitude", value: $settings.weatherManualLongitude, format: .number)
                }
            }
            Section("Widget order") {
                Text("Drag widgets to choose their order in the Dock. The order is preserved when widgets move between Dock and Menu Bar.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                List {
                    ForEach(settings.dockWidgetOrder, id: \.self) { rawValue in
                        if let widget = DockWidgetID(rawValue: rawValue) {
                            Label(widget.displayName, systemImage: "line.3.horizontal")
                        }
                    }
                    .onMove { source, destination in
                        settings.dockWidgetOrder.move(fromOffsets: source, toOffset: destination)
                    }
                }
                .frame(height: 150)
            }
        }
    }
}

private struct CalendarPluginsSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        SettingsPage(title: "Calendar & Plugins", subtitle: "Use one combined Calendar and Quick Settings control, or place each widget independently.") {
            Section("Calendar & Quick Settings") {
                Toggle("Split Calendar and Quick Settings", isOn: $settings.splitCalendarAndQuickSettings)
                if settings.splitCalendarAndQuickSettings {
                    Picker("Calendar location", selection: $settings.calendarLocation) {
                        ForEach(WidgetLocation.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                    Picker("Quick Settings location", selection: $settings.quickSettingsLocation) {
                        ForEach(WidgetLocation.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                } else {
                    Text("Combined mode uses the Calendar & Quick Settings tray as one dock or menu-bar widget. The separate Quick Settings menu-bar item is hidden.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Picker("Location", selection: $settings.connectivityTrayLocation) {
                        ForEach(WidgetLocation.allCases) { Text($0.displayName).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }
            }
            Section("Session Manager") {
                Toggle("Enable Session Manager plugin", isOn: $settings.enableSessionManagerPlugin)
                Toggle("Show agent titles", isOn: $settings.showSessionManagerAgentTitles)
                Toggle("Show activity indicators", isOn: $settings.showSessionManagerActivityIndicators)
                Toggle("Animate activity", isOn: $settings.animateSessionManagerActivity)
                Toggle("Show AI token usage", isOn: $settings.showSessionManagerTokenUsage)
                Toggle("Enable terminal actions", isOn: $settings.enableSessionManagerTerminalActions)
                Toggle("Show action button", isOn: $settings.showSessionManagerActionButton)
            }
            .disabled(!settings.enableSessionManagerPlugin)
        }
    }
}

private struct TraySettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @StateObject private var quickSettingsState = QuickSettingsTabState()

    var body: some View {
        SettingsPage(title: "System Tray & Flyouts", subtitle: "Control connectivity notifications and the Quick Settings flyout contents.") {
            Section("Connectivity") {
                Toggle("Show connections icon", isOn: $settings.showConnections)
                Toggle("Bluetooth connection alerts", isOn: $settings.notifyBluetoothConnect)
                Toggle("Bluetooth low-battery alerts", isOn: $settings.notifyBluetoothLowBattery)
                Toggle("Wi-Fi network change alerts", isOn: $settings.notifyWiFiChange)
                Toggle("Wi-Fi weak-signal alerts", isOn: $settings.notifyWiFiWeak)
                Button("Test Notification") { sendTestNotification() }
            }
            Section("Quick Settings") {
                Text("Drag to reorder. Unchecked items are hidden from the flyout.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                List {
                    ForEach($quickSettingsState.items) { $item in
                        HStack {
                            Image(systemName: "line.3.horizontal").foregroundStyle(.secondary)
                            Image(systemName: item.symbol).frame(width: 24)
                            Text(item.title)
                            Spacer()
                            Toggle("", isOn: $item.isEnabled)
                                .labelsHidden()
                                .onChange(of: item.isEnabled) { _, _ in saveQuickSettings() }
                        }
                    }
                    .onMove(perform: moveQuickSetting)
                }
                .frame(height: 220)
            }
        }
        .onAppear(perform: loadQuickSettings)
    }

    private func loadQuickSettings() {
        let enabled = Set(settings.enabledQuickSettings)
        let savedOrder = UserDefaults.standard.stringArray(forKey: "quickSettingsOrder") ?? []
        var items = Dictionary(uniqueKeysWithValues: QuickSettingsManager.shared.allSettings.map {
            ($0.id, QuickSettingsTabState.QuickSettingItem(id: $0.id, title: $0.title, symbol: $0.symbolName, isEnabled: enabled.contains($0.id)))
        })
        var ordered = savedOrder.compactMap { items.removeValue(forKey: $0) }
        ordered.append(contentsOf: items.values.sorted { $0.title < $1.title })
        quickSettingsState.items = ordered
    }

    private func moveQuickSetting(from source: IndexSet, to destination: Int) {
        quickSettingsState.items.move(fromOffsets: source, toOffset: destination)
        saveQuickSettings()
    }

    private func saveQuickSettings() {
        UserDefaults.standard.set(quickSettingsState.items.map(\.id), forKey: "quickSettingsOrder")
        settings.enabledQuickSettings = quickSettingsState.items.filter(\.isEnabled).map(\.id)
    }

    private func sendTestNotification() {
        NotificationManager.shared.requestAuthorization { granted in
            guard granted else { return }
            DispatchQueue.main.async {
                NotificationManager.shared.sendNotification(title: "Connectivity Tracker", body: "This is a test notification from DeskBar Settings.", identifier: UUID().uuidString)
            }
        }
    }
}

private struct SettingsPermissionRow: View {
    let title: String
    let granted: Bool
    let action: () -> Void

    var body: some View {
        LabeledContent(title) {
            HStack(spacing: 8) {
                Text(granted ? "Granted" : "Required")
                    .foregroundStyle(granted ? .green : .secondary)
                if !granted { Button("Open Settings", action: action) }
            }
        }
    }
}

private func chooseApplication(_ completion: @escaping (URL) -> Void) {
    let panel = NSOpenPanel()
    panel.allowedContentTypes = [.applicationBundle]
    panel.allowsMultipleSelection = false
    panel.canChooseDirectories = false
    panel.begin { response in
        guard response == .OK, let url = panel.url else { return }
        completion(url)
    }
}

private func openSystemSettings(_ rawURL: String) {
    guard let url = URL(string: rawURL) else { return }
    NSWorkspace.shared.open(url)
}
