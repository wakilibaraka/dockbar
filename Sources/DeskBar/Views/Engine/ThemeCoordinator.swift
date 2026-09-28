import AppKit
import SwiftUI
import Combine
import DockBarCore

/// Coordinates between live services and ThemeContainerView.
/// Reads WindowManager output only — does not call any WindowManager methods.
final class ThemeCoordinator: NSObject, ObservableObject {
    let containerView: ThemeContainerView
    private let settings: TaskbarSettings
    private let windowManager: WindowManager
    private var cancellables = Set<AnyCancellable>()
    private var unpinnedOrder: [String] = []
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
        var theme = ThemeRegistry.shared.theme(for: themeID)!
        
        // Dynamically scale height and icon sizes
        let baseHeight: CGFloat = 44.0
        let currentHeight = settings.taskbarHeight
        let scale = currentHeight / baseHeight
        
        theme.geometry.height = currentHeight
        // Scale icon sizes while keeping the tight padding
        theme.icons.hitTargetSize = currentHeight
        theme.icons.size = min(28 * scale, currentHeight - 8)
        self.containerView = ThemeContainerView(theme: theme)
        super.init()

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

            case "systemStats":
                if let rm = resourceMonitor {
                    let resources = SystemStatsWidgetView(settings: settings, monitor: rm)
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
                let v = DownloadsWidgetView(frame: .zero)
                DownloadsActionHandler.shared.widgetView = v
                DownloadsActionHandler.shared.settings = settings
                v.target = DownloadsActionHandler.shared
                v.action = #selector(DownloadsActionHandler.shared.openDownloads)
                containerView.setWidgetView(v, for: def.id)
                // Bind
                DownloadsMonitor.shared.$activeDownloads
                    .receive(on: DispatchQueue.main)
                    .sink { actives in
                    v.isDownloading = !actives.isEmpty
                    if let first = actives.first {
                        v.progress = first.progress
                    }
                }.store(in: &DownloadsActionHandler.shared.cancellables)
            default: break
            }
        }

        containerView.onAppActivate = { [weak self] appID in
            guard let self else { return }
            if !AXIsProcessTrusted() {
                let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
                AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
            }
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
                    app.activate()
                    if app.isHidden { app.unhide() }
                    
                    if unminimizedWindows.isEmpty && !minimizedWindows.isEmpty {
                        AXUIElementSetAttributeValue(minimizedWindows[0], kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
                    } else {
                        for window in unminimizedWindows.reversed() {
                            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                        }
                    }
                } else {
                    if unminimizedWindows.isEmpty && !minimizedWindows.isEmpty {
                        AXUIElementSetAttributeValue(minimizedWindows[0], kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
                    } else if app.isHidden {
                        app.unhide()
                    } else {
                        if self.settings.minimizeOnAppClick {
                            app.hide()
                        }
                    }
                }
            } else if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appID) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
            }
        }
        
        containerView.onAppRightClick = { [weak self] appID in
            guard let self else { return nil }
            let menu = NSMenu(title: "")
            
            var windowCount = 0
            let windows = self.windowManager.visibleWindows.filter { $0.bundleIdentifier == appID }
            for w in windows {
                let title = w.title ?? "Window"
                let item = NSMenuItem(title: title, action: #selector(self.raiseWindow(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = ["pid": w.pid, "cgWindowID": w.cgWindowID]
                menu.addItem(item)
                windowCount += 1
            }
            if windowCount > 0 { menu.addItem(.separator()) }
            
            let isPinned = self.settings.pinnedApps.contains(appID)
            let pinItem = NSMenuItem(title: isPinned ? "Remove from Dock" : "Keep in Dock", action: #selector(self.togglePin(_:)), keyEquivalent: "")
            pinItem.target = self
            pinItem.representedObject = appID
            menu.addItem(pinItem)
            
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: appID) {
                let showItem = NSMenuItem(title: "Show in Finder", action: #selector(self.showInFinder(_:)), keyEquivalent: "")
                showItem.target = self
                showItem.representedObject = url
                menu.addItem(showItem)
            }
            
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == appID }) {
                menu.addItem(.separator())
                let quitItem = NSMenuItem(title: "Quit", action: #selector(self.quitApp(_:)), keyEquivalent: "")
                quitItem.target = self
                quitItem.representedObject = app
                menu.addItem(quitItem)
            }
            
            return menu
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
        var theme = ThemeRegistry.shared.theme(for: themeID)!
        
        // Dynamically scale height and icon sizes
        let baseHeight: CGFloat = 44.0
        let currentHeight = settings.taskbarHeight
        let scale = currentHeight / baseHeight
        
        theme.geometry.height = currentHeight
        // Scale icon sizes while keeping the tight padding
        theme.icons.hitTargetSize = currentHeight
        theme.icons.size = min(28 * scale, currentHeight - 8)
        
        let windowData = windowManager.visibleWindows.map { w in
            WindowData(bundleIdentifier: w.bundleIdentifier ?? w.appName ?? UUID().uuidString, isMinimized: w.isMinimized)
        }
        let runningApps = Set(NSWorkspace.shared.runningApplications.compactMap { $0.bundleIdentifier })
        let frontmostApp = NSWorkspace.shared.frontmostApplication?.bundleIdentifier
        
        let apps = LayoutEngine.buildAppItems(
            visibleWindows: windowData,
            pinnedApps: settings.pinnedApps,
            unpinnedOrder: &unpinnedOrder,
            frontmostApp: frontmostApp,
            runningApps: runningApps
        )
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
                        case "systemStats":
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
    
    @objc private func raiseWindow(_ sender: NSMenuItem) {
        guard let dict = sender.representedObject as? [String: Any],
              let pid = dict["pid"] as? pid_t,
              let cgWindowID = dict["cgWindowID"] as? CGWindowID else { return }
        
        if let app = NSWorkspace.shared.runningApplications.first(where: { $0.processIdentifier == pid }) {
            app.activate()
            let axApp = AXUIElementCreateApplication(pid)
            var windowsValue: CFTypeRef?
            if AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &windowsValue) == .success,
               let windows = windowsValue as? [AXUIElement] {
                for window in windows {
                    var minVal: CFTypeRef?
                    if AXUIElementCopyAttributeValue(window, kAXMinimizedAttribute as CFString, &minVal) == .success,
                       let m = minVal as? Bool, m {
                        AXUIElementSetAttributeValue(window, kAXMinimizedAttribute as CFString, kCFBooleanFalse as CFTypeRef)
                    }
                    AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                }
            }
        }
    }
    
    @objc private func togglePin(_ sender: NSMenuItem) {
        guard let appID = sender.representedObject as? String else { return }
        if settings.pinnedApps.contains(appID) {
            settings.pinnedApps.removeAll(where: { $0 == appID })
        } else {
            settings.pinnedApps.append(appID)
        }
    }
    
    @objc private func showInFinder(_ sender: NSMenuItem) {
        guard let url = sender.representedObject as? URL else { return }
        NSWorkspace.shared.activateFileViewerSelecting([url])
    }
    
    @objc private func quitApp(_ sender: NSMenuItem) {
        guard let app = sender.representedObject as? NSRunningApplication else { return }
        app.terminate()
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
    var widgetView: NSView?
    var flyout: BorderlessFlyout?
    var settings: TaskbarSettings?
    var cancellables = Set<AnyCancellable>()
    
    @objc func openDownloads() {
        let mode = UserDefaults.standard.integer(forKey: "downloadsAction")
        if mode == 3, let externalApp = UserDefaults.standard.string(forKey: "downloadsExternalApp") {
            if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: externalApp) {
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration(), completionHandler: nil)
                return
            }
        } else if mode == 2 {
            let downloadsURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first!
            NSWorkspace.shared.open(downloadsURL)
            return
        }
        
        // Mode 1 or fallback: Flyout
        guard let view = widgetView else { return }
        if let current = flyout, current.isShown {
            current.performClose(nil)
            return
        }
        
        let popover = BorderlessFlyout()
        popover.onDismiss = { [weak self] in self?.flyout = nil }
        
        let hc = SwiftUI.NSHostingController(rootView: DownloadsFlyoutView().environmentObject(settings!))
        popover.show(contentViewController: hc, relativeTo: view.bounds, of: view)
        flyout = popover
    }
}