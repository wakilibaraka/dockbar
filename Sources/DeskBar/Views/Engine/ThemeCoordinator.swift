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
            case "liveEvents":
                // Minimal placeholder for now
                let v = NSButton(title: "Live Events", target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                containerView.setWidgetView(v, for: def.id)


            case "widgetsBoard":
                let v = NSButton(image: NSImage(systemSymbolName: "rectangle.3.offgrid", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                containerView.setWidgetView(v, for: def.id)
            case "trash":
                let v = NSButton(image: NSImage(systemSymbolName: "trash", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                v.target = TrashActionHandler.shared
                v.action = #selector(TrashActionHandler.shared.openTrash)
                
                // Add right-click menu
                let menu = NSMenu()
                let emptyItem = NSMenuItem(title: "Empty Trash", action: #selector(TrashActionHandler.shared.emptyTrash), keyEquivalent: "")
                emptyItem.target = TrashActionHandler.shared
                menu.addItem(emptyItem)
                v.menu = menu
                
                containerView.setWidgetView(v, for: def.id)
            case "downloads":
                let v = NSButton(image: NSImage(systemSymbolName: "arrow.down.circle", accessibilityDescription: nil) ?? NSImage(), target: nil, action: nil)
                v.bezelStyle = .texturedRounded
                v.isBordered = false
                v.target = DownloadsActionHandler.shared
                v.action = #selector(DownloadsActionHandler.shared.openDownloads)
                containerView.setWidgetView(v, for: def.id)
            default: break
            }
        }

        containerView.onAppActivate = { appID in
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == appID }) {
                let pid = app.processIdentifier
                let axApp = AXUIElementCreateApplication(pid)
                var windowsValue: CFTypeRef?
                var minimizedWindows: [AXUIElement] = []
                var unminimizedWindows: [AXUIElement] = []
                
                if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsValue) == .success,
                   let windows = windowsValue as? [AXUIElement] {
                    for window in windows {
                        var minVal: CFTypeRef?
                        var isMin = false
                        if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minVal) == .success,
                           let m = minVal as? Bool, m {
                            isMin = true
                        }
                        if isMin { minimizedWindows.append(window) }
                        else { unminimizedWindows.append(window) }
                    }
                }
                
                if !app.isActive {
                    app.activate(options: [.activateIgnoringOtherApps])
                    if unminimizedWindows.isEmpty && !minimizedWindows.isEmpty {
                        AXUIElementSetAttributeValue(minimizedWindows[0], kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
                    } else if !unminimizedWindows.isEmpty {
                        AXUIElementPerformAction(unminimizedWindows[0], kAXRaiseAction as CFString)
                    }
                } else {
                    // Running & frontmost -> minimize/hide/cycle
                    if !unminimizedWindows.isEmpty {
                        // If multiple unminimized, cycle by raising the last one? Or hide the app?
                        // "minimize/hide/cycle its windows (match Vorssaint)" -> typical behavior is to hide if frontmost.
                        app.hide()
                    } else if !minimizedWindows.isEmpty {
                        // All minimized -> restore
                        AXUIElementSetAttributeValue(minimizedWindows[0], kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
                    }
                }
            } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appID) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
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
        settings.$showStartButton.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showSearch.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showWidgetsBoard.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showDownloads.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showTrash.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$showLiveEvents.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
        settings.$appAlignment.receive(on: RunLoop.main).sink { [weak self] _ in self?.resolve() }.store(in: &cancellables)
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
            case "startButton":
                isEnabled = settings.showStartButton
            case "search":
                isEnabled = settings.showSearch

            case "widgetsBoard":
                isEnabled = settings.showWidgetsBoard
            case "trash":
                isEnabled = settings.showTrash
            case "downloads":
                isEnabled = settings.showDownloads
            case "liveEvents":
                isEnabled = settings.showLiveEvents
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
            isFullScreen: windowManager.hasFullScreenWindow(on: screen),
            appAlignment: settings.appAlignment.rawValue
        )
        let resolved = LayoutEngine.resolve(input: input)
        print("Widget Requests: \(widgetRequests.map { $0.id })")
        print("Resolved Widget Frames: \(resolved.widgetFrames)")

        containerView.applyTheme(theme)
        containerView.applyLayout(resolved)
    }
}

class TrashActionHandler {
    static let shared = TrashActionHandler()
    @objc func openTrash() {
        let url = URL(fileURLWithPath: "/Users/" + NSUserName() + "/.Trash")
        NSWorkspace.shared.open(url)
    }
    
    @objc func emptyTrash() {
        let alert = NSAlert()
        alert.messageText = "Empty Trash?"
        alert.informativeText = "Are you sure you want to permanently erase the items in the Trash?"
        alert.addButton(withTitle: "Empty Trash")
        alert.addButton(withTitle: "Cancel")
        if alert.runModal() == .alertFirstButtonReturn {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            task.arguments = ["-e", "tell application \"Finder\" to empty trash"]
            try? task.run()
        }
    }
}

class DownloadsActionHandler {
    static let shared = DownloadsActionHandler()
    @objc func openDownloads() {
        // Mode 1: Flyout (Not implemented yet, fallback to Finder)
        // Mode 2: Finder
        // Mode 3: External App
        let mode = UserDefaults.standard.integer(forKey: "downloadsAction")
        if mode == 3, let externalApp = UserDefaults.standard.string(forKey: "downloadsExternalApp") {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: externalApp) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                return
            }
        }
        
        // Fallback for Mode 1 & 2
        let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
        NSWorkspace.shared.open(downloadsURL)
    }
}