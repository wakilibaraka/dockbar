import AppKit
import SwiftUI
import Combine
import DockBarCore

/// Coordinates between live services and ThemeContainerView.
/// Reads WindowManager output only — does not call any WindowManager methods.
@MainActor
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
        
        WidgetEngine.shared.flyoutHandler = { [weak self] id, content in
            self?.presentFlyout(for: id, content: content)
        }

        // Icon provider: ask the system for the running app icon
        containerView.iconProvider = { appID in
            NSWorkspace.shared.runningApplications
                .first(where: { $0.bundleIdentifier == appID })?
                .icon
        }


        // Instantiate widgets
        let activeWidgets = settings.leadingWidgets + settings.centerWidgets + settings.trailingWidgets
        for id in activeWidgets {
            if id == "appLauncher" { continue } // Natively handled by ThemeCoordinator
            
            if let widgetView = WidgetEngine.shared.makeView(for: id, settings: settings) {
                containerView.setWidgetView(widgetView, for: id)
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
        
        // Leading Widgets
        for id in settings.leadingWidgets {
            if let desc = WidgetEngine.shared.descriptor(for: id) {
                var rule = desc.defaultRule
                if id == "weather" { rule = settings.weatherWidgetLocation }
                widgetRequests.append(.init(id: id, slot: .leading, rule: rule, size: desc.preferredSize))
            }
        }
        
        // Trailing Widgets
        for id in settings.trailingWidgets {
            if let desc = WidgetEngine.shared.descriptor(for: id) {
                var rule = desc.defaultRule
                if id == "systemStats" { rule = settings.systemResourceWidgetLocation }
                if id == "connectivity" { rule = settings.connectivityTrayLocation }
                widgetRequests.append(.init(id: id, slot: .tray, rule: rule, size: desc.preferredSize))
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
    
    private var activeFlyout: BorderlessFlyout?

    private func presentFlyout(for id: String, content: AnyView) {
        if activeFlyout?.isShown == true {
            activeFlyout?.performClose(nil)
            activeFlyout = nil
            return
        }
        
        guard let anchorView = containerView.widgetViews[id] else { return }
        
        let newFlyout = BorderlessFlyout()
        newFlyout.onDismiss = { [weak self] in self?.activeFlyout = nil }
        
        let rootVC = NSHostingController(rootView: content)
        rootVC.view.translatesAutoresizingMaskIntoConstraints = false
        // Estimate size
        rootVC.view.layoutSubtreeIfNeeded()
        let fittingSize = rootVC.view.fittingSize
        rootVC.view.frame = NSRect(origin: .zero, size: fittingSize)
        rootVC.preferredContentSize = fittingSize
        
        newFlyout.show(contentViewController: rootVC, relativeTo: anchorView.bounds, of: anchorView)
        self.activeFlyout = newFlyout
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