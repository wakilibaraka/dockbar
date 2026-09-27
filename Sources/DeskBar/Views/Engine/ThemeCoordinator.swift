import AppKit
import Combine
import DockBarCore

/// Coordinates between live services and ThemeContainerView.
/// Reads WindowManager output only — does not call any WindowManager methods.
final class ThemeCoordinator: ObservableObject {
    let containerView: ThemeContainerView
    private let settings: TaskbarSettings
    private let windowManager: WindowManager
    private var cancellables = Set<AnyCancellable>()
    private var screen: NSScreen
    private var screenFrame: CGRect

    private let themeID: String

    private var weatherService: WeatherService?
    private var resourceMonitor: SystemResourceMonitor?
    private var calendarService: CalendarEventService?
    private let pinnedAppManager: PinnedAppManager
    
    init(settings: TaskbarSettings, windowManager: WindowManager, screen: NSScreen, themeID: String, pinnedAppManager: PinnedAppManager, weatherService: WeatherService? = nil, resourceMonitor: SystemResourceMonitor? = nil, calendarService: CalendarEventService? = nil) {
        self.themeID = themeID
        self.settings = settings
        self.windowManager = windowManager
        self.pinnedAppManager = pinnedAppManager
        self.weatherService = weatherService
        self.resourceMonitor = resourceMonitor
        self.calendarService = calendarService
        self.screen = screen
        self.screenFrame = screen.frame
        let theme = ThemeRegistry.shared.theme(for: themeID)!
        self.containerView = ThemeContainerView(theme: theme)

        // Icon provider: ask the system for the running app icon
        containerView.iconProvider = { appID in
            NSWorkspace.shared.runningApplications
                .first(where: { $0.bundleIdentifier == appID })?
                .icon
        }


        // Instantiate widgets
        for def in WidgetRegistry.shared.definitions {
            switch def.id {
            case "clock":
                let clock = DockClockWidgetView()
                containerView.setWidgetView(clock, for: def.id)
            case "weather":
                if let ws = weatherService {
                    let weather = DockWeatherWidgetView(weatherService: ws, settings: settings)
                    containerView.setWidgetView(weather, for: def.id)
                }
            case "battery":
                if let ws = weatherService {
                    let battery = DockBatteryWidgetView(settings: settings, weatherService: ws)
                    containerView.setWidgetView(battery, for: def.id)
                }
            case "systemResources":
                if let rm = resourceMonitor {
                    let resources = SystemResourceWidgetView(settings: settings, monitor: rm, displayID: CGMainDisplayID())
                    containerView.setWidgetView(resources, for: def.id)
                }
            case "connectivity":
                let conn = ConnectivityTrayView(settings: settings)
                containerView.setWidgetView(conn, for: def.id)
            case "quickSettings":
                let qs = QuickSettingsWidgetView(settings: settings)
                containerView.setWidgetView(qs, for: def.id)
            case "startButton":
                let start = AppsLauncherButtonView()
                containerView.setWidgetView(start, for: def.id)
            default: break
            }
        }

        bind()
    }

    private func bind() {
        // Re-resolve whenever apps change
        windowManager.$visibleWindows.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$dockMode.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$weatherEnabled.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showSystemResourceWidget.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        pinnedAppManager.$pinnedApps
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.resolve() }
            .store(in: &cancellables)
    }

    func updateScreen(_ screen: NSScreen) {
        self.screen = screen
        self.screenFrame = screen.frame
        resolve()
    }

    private func resolve() {
        let theme = ThemeRegistry.shared.theme(for: themeID)!
        
        // Group visible windows by app
        var groups: [String: [WindowInfo]] = [:]
        for w in windowManager.visibleWindows {
            let id = w.bundleIdentifier ?? w.appName ?? UUID().uuidString
            groups[id, default: []].append(w)
        }
        
        let frontmostApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        
        var apps = groups.map { id, windows in
            LayoutEngine.AppItem(
                id: id,
                isRunning: true,
                isFocused: id == frontmostApp,
                hasMultipleWindows: windows.count > 1,
                isMinimized: windows.allSatisfy { $0.isMinimized }
            )
        }
        
        // Add pinned apps that are NOT running
        for pinned in pinnedAppManager.pinnedApps {
            if groups[pinned.bundleIdentifier] == nil {
                apps.append(LayoutEngine.AppItem(
                    id: pinned.bundleIdentifier,
                    isRunning: false,
                    isFocused: false,
                    hasMultipleWindows: false,
                    isMinimized: false
                ))
            }
        }
        var widgetRequests: [LayoutEngine.Input.WidgetRequest] = []
        for def in WidgetRegistry.shared.definitions {
            var rule = def.defaultRule
            var isEnabled = true
            
            switch def.id {
            case "clock":
                // no clock settings
                break
            case "weather":
                isEnabled = settings.weatherEnabled
            case "battery":
                rule = settings.batteryWidgetLocation
            case "systemResources":
                isEnabled = settings.showSystemResourceWidget
                rule = settings.systemResourceWidgetLocation
            case "connectivity":
                rule = settings.connectivityTrayLocation
            default: break
            }
            
            if isEnabled {
                widgetRequests.append(.init(id: def.id, slot: def.slotEligibility, rule: rule, size: def.fixedSize))
            }
        }



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
        let resolved = LayoutEngine.resolve(input: input)
        containerView.applyTheme(theme)
        containerView.applyLayout(resolved)
    }
}
