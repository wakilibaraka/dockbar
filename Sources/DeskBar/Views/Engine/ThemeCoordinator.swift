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
    private var screenFrame: CGRect

    private let themeID: String

    private var weatherService: WeatherService?
    private var resourceMonitor: SystemResourceMonitor?
    private var calendarService: CalendarEventService?
    
    init(settings: TaskbarSettings, windowManager: WindowManager, screen: NSScreen, themeID: String, weatherService: WeatherService? = nil, resourceMonitor: SystemResourceMonitor? = nil, calendarService: CalendarEventService? = nil) {
        self.themeID = themeID
        self.settings = settings
        self.windowManager = windowManager
        self.weatherService = weatherService
        self.resourceMonitor = resourceMonitor
        self.calendarService = calendarService
        self.screenFrame = screen.frame
        let theme = ThemeRegistry.shared.theme(for: themeID)!
        self.containerView = ThemeContainerView(theme: theme)

        // Icon provider: ask the system for the running app icon
        containerView.iconProvider = { appID in
            NSWorkspace.shared.runningApplications
                .first(where: { $0.bundleIdentifier == appID })?
                .icon
        }

        bind()
    }

    private func bind() {
        // Re-resolve whenever apps change
        windowManager.$visibleWindows
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in self?.resolve() }
            .store(in: &cancellables)
    }

    func updateScreen(_ screen: NSScreen) {
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
        
        let apps = groups.map { id, windows in
            LayoutEngine.AppItem(
                id: id,
                isRunning: true,
                isFocused: id == frontmostApp,
                hasMultipleWindows: windows.count > 1,
                isMinimized: windows.allSatisfy { $0.isMinimized }
            )
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
            case "resources":
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
            isDockHidden: false, // Wire up to settings.dockMode later
            isFullScreen: false // Wire up to fullscreen detector later
        )
        let resolved = LayoutEngine.resolve(input: input)
        containerView.applyTheme(theme)
        containerView.applyLayout(resolved)
    }
}
