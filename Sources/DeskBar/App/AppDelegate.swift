import AppKit
import SwiftUI
import Combine
import Darwin

final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let minimumTaskbarReservationHeight: CGFloat = 32

    private var panels: [CGDirectDisplayID: TaskbarPanel] = [:]
    private var contentViews: [CGDirectDisplayID: TaskbarContentView] = [:]
    private var windowManager: WindowManager?
    private var permissionsManager: PermissionsManager?
    private var settings: TaskbarSettings?
    private var dockManager: DockManager?
    private var blacklistManager: BlacklistManager?
    private var pinnedAppManager: PinnedAppManager?
    private var loginItemManager: LoginItemManager?
    private var badgeMonitor: BadgeMonitor?
    private var appStateMonitor: AppStateMonitor?
    private var smPluginService: SMPluginService?
    private var systemResourceMonitor: SystemResourceMonitor?
    private var thumbnailService: ThumbnailService?
    private var windowLayoutSnapshotManager: WindowLayoutSnapshotManager?
    private var windowSwitcherService: WindowSwitcherService?
    private var settingsWindowController: SettingsWindowController?
    private var onboardingWindowController: OnboardingWindowController?
    private var statusItem: NSStatusItem?
    private var statusMenu: NSMenu?
    private var restoreWindowsMenuItem: NSMenuItem?
    private var batteryPopover: NSPopover?
    private var popoverEventMonitor: Any?

    private let singleInstanceLock = SingleInstanceLock()
    private var cancellables = Set<AnyCancellable>()
    private var signalSources: [DispatchSourceSignal] = []
    private var isHandlingTerminationSignal = false
    private var screenObserver: NSObjectProtocol?
    private var workspaceObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        MigrationManager.runMigrations()
        
        guard singleInstanceLock.acquire() else {
            print("DeskBar: another instance is already running; exiting duplicate.")
            NSApp.terminate(nil)
            return
        }

        let settings = TaskbarSettings()
        self.settings = settings
        loginItemManager = LoginItemManager(settings: settings)

        let dockManager = DockManager()
        self.dockManager = dockManager

        let blacklistManager = BlacklistManager()
        self.blacklistManager = blacklistManager

        let permissions = PermissionsManager()
        permissionsManager = permissions

        let pinnedAppManager = PinnedAppManager()
        self.pinnedAppManager = pinnedAppManager

        let wm = WindowManager(
            blacklistManager: blacklistManager,
            pinnedAppManager: pinnedAppManager
        )
        wm.taskbarHeight = Self.taskbarReservationHeight(for: settings.taskbarHeight)
        windowManager = wm

        let badgeMonitor = BadgeMonitor()
        self.badgeMonitor = badgeMonitor

        let appStateMonitor = AppStateMonitor()
        self.appStateMonitor = appStateMonitor

        let smPluginService = SMPluginService(isEnabled: settings.enableSessionManagerPlugin)
        self.smPluginService = smPluginService

        let systemResourceMonitor = SystemResourceMonitor()
        self.systemResourceMonitor = systemResourceMonitor

        let thumbnailService = ThumbnailService()
        self.thumbnailService = thumbnailService

        let windowLayoutSnapshotManager = WindowLayoutSnapshotManager(windowManager: wm)
        self.windowLayoutSnapshotManager = windowLayoutSnapshotManager

        let windowSwitcherService = WindowSwitcherService(
            windowManager: wm,
            settings: settings,
            thumbnailService: thumbnailService
        )
        self.windowSwitcherService = windowSwitcherService

        if !settings.hasCompletedOnboarding {
            onboardingWindowController = OnboardingWindowController(settings: settings, permissionsManager: permissions, thumbnailService: thumbnailService) { [weak self] in
                self?.completeLaunch(wm: wm, permissions: permissions, settings: settings, blacklistManager: blacklistManager, pinnedAppManager: pinnedAppManager, thumbnailService: thumbnailService, smPluginService: smPluginService)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    self?.openSettings(nil)
                }
            }
            onboardingWindowController?.showWindow(nil)
            onboardingWindowController?.window?.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            completeLaunch(wm: wm, permissions: permissions, settings: settings, blacklistManager: blacklistManager, pinnedAppManager: pinnedAppManager, thumbnailService: thumbnailService, smPluginService: smPluginService)
        }
    }

    private func completeLaunch(
        wm: WindowManager,
        permissions: PermissionsManager,
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        thumbnailService: ThumbnailService,
        smPluginService: SMPluginService
    ) {
        configureObservers(
            windowManager: wm,
            permissionsManager: permissions,
            settings: settings
        )
        refreshPanelsForCurrentConfiguration()
        DispatchQueue.main.async { [weak self] in
            self?.refreshPanelsForCurrentConfiguration()
        }

        settingsWindowController = SettingsWindowController(
            settings: settings,
            blacklistManager: blacklistManager,
            pinnedAppManager: pinnedAppManager,
            permissionsManager: permissions,
            thumbnailService: thumbnailService
        )
        configureStatusItem()
        bindDockMode(settings: settings)
        bindSessionManagerPlugin(settings: settings, smPluginService: smPluginService)
        configureSignalHandlers()
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.forEach(workspaceCenter.removeObserver)
        dockManager?.restoreDockState()
        dockManager?.removeWatchdog()
    }

    @objc
    private func openSettings(_ sender: Any?) {
        settingsWindowController?.showWindow(sender)
        settingsWindowController?.window?.makeKeyAndOrderFront(sender)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc
    private func quitApplication(_ sender: Any?) {
        NSApp.terminate(nil)
    }

    @objc
    private func restoreWindowsFromLastSleep(_ sender: Any?) {
        windowLayoutSnapshotManager?.restoreLatestSnapshot(manual: true)
        updateRestoreWindowsMenuItem()
    }

    @objc private func restoreApp(_ sender: NSMenuItem) {
        guard let bundleID = sender.representedObject as? String else { return }
        if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleID) {
            NSWorkspace.shared.open(url)
            RecentlyClosedTracker.shared.remove(bundleIdentifier: bundleID)
        }
    }

    private func bindDockMode(settings: TaskbarSettings) {
        dockManager?.apply(mode: settings.dockMode)

        settings.$dockMode
            .dropFirst()
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] mode in
                self?.dockManager?.apply(mode: mode)
            }
            .store(in: &cancellables)
    }

    private func bindSessionManagerPlugin(settings: TaskbarSettings, smPluginService: SMPluginService) {
        settings.$enableSessionManagerPlugin
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { isEnabled in
                Task { @MainActor in
                    smPluginService.setEnabled(isEnabled)
                }
            }
            .store(in: &cancellables)
    }

    private func configureSignalHandlers() {
        [SIGTERM, SIGINT].forEach { signalNumber in
            signal(signalNumber, SIG_IGN)

            let source = DispatchSource.makeSignalSource(signal: signalNumber, queue: .main)
            source.setEventHandler { [weak self] in
                guard let self else {
                    return
                }

                self.dockManager?.restoreDockState()

                guard !self.isHandlingTerminationSignal else {
                    return
                }

                self.isHandlingTerminationSignal = true
                NSApp.terminate(nil)
            }
            source.resume()
            signalSources.append(source)
        }
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem.button {
            // Synchronously ensure non-zero width so macOS notch collapsing doesn't hide it
            button.image = BatteryStatusRenderer.renderImage(for: BatteryState(percentage: 100, isCharging: false, isACPowered: false))
            button.title = " 100%"
            button.imagePosition = .imageLeft
            button.font = NSFont.monospacedDigitSystemFont(ofSize: 12, weight: .regular)
        }
        
        BatteryMonitor.shared.$state
            .receive(on: DispatchQueue.main)
            .sink { [weak statusItem] state in
                if let button = statusItem?.button {
                    button.image = BatteryStatusRenderer.renderImage(for: state)
                    button.title = " \(state.percentage)%"
                }
            }
            .store(in: &cancellables)

        let menu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings(_:)),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        
        let recentlyClosedItem = NSMenuItem(title: "Recently Closed", action: nil, keyEquivalent: "")
        let recentlyClosedMenu = NSMenu()
        recentlyClosedItem.submenu = recentlyClosedMenu
        menu.addItem(recentlyClosedItem)
        menu.addItem(.separator())
        
        RecentlyClosedTracker.shared.$closedApps
            .receive(on: DispatchQueue.main)
            .sink { [weak self, weak recentlyClosedItem] apps in
                guard let self, let submenu = recentlyClosedItem?.submenu else { return }
                submenu.removeAllItems()
                if apps.isEmpty {
                    let emptyItem = NSMenuItem(title: "No Recently Closed Apps", action: nil, keyEquivalent: "")
                    emptyItem.isEnabled = false
                    submenu.addItem(emptyItem)
                } else {
                    for app in apps {
                        let item = NSMenuItem(title: app.localizedName, action: #selector(self.restoreApp(_:)), keyEquivalent: "")
                        item.target = self
                        item.representedObject = app.bundleIdentifier
                        if let icon = app.icon {
                            let resized = NSImage(size: NSSize(width: 16, height: 16))
                            resized.lockFocus()
                            icon.draw(in: NSRect(x: 0, y: 0, width: 16, height: 16))
                            resized.unlockFocus()
                            item.image = resized
                        }
                        submenu.addItem(item)
                    }
                }
            }
            .store(in: &cancellables)

        let restoreWindowsItem = NSMenuItem(
            title: "Restore Windows From Last Sleep",
            action: #selector(restoreWindowsFromLastSleep(_:)),
            keyEquivalent: ""
        )
        restoreWindowsItem.target = self
        menu.addItem(restoreWindowsItem)
        restoreWindowsMenuItem = restoreWindowsItem
        menu.addItem(.separator())

        let quitItem = NSMenuItem(
            title: "Quit",
            action: #selector(quitApplication(_:)),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        self.statusMenu = menu
        self.statusItem = statusItem
        updateRestoreWindowsMenuItem()
        
        // Setup popover for both left and right clicks
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: BatteryFlyoutView())
        self.batteryPopover = popover
        
        if let button = statusItem.button {
            button.action = #selector(handleStatusItemClick(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
    }
    


    @objc private func handleStatusItemClick(_ sender: Any?) {
        guard let button = statusItem?.button else { return }
        
        if let popover = self.batteryPopover {
            if popover.isShown {
                closePopover(nil)
            } else {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                NSApp.activate(ignoringOtherApps: true)
                
                self.popoverEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
                    self?.closePopover(nil)
                }
            }
        }
    }
    
    private func closePopover(_ sender: Any?) {
        self.batteryPopover?.performClose(sender)
        if let monitor = self.popoverEventMonitor {
            NSEvent.removeMonitor(monitor)
            self.popoverEventMonitor = nil
        }
    }

    private func configureObservers(
        windowManager: WindowManager,
        permissionsManager: PermissionsManager,
        settings: TaskbarSettings
    ) {
        permissionsManager.$isAccessibilityGranted
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.handleAccessibilityPermissionChange()
                self?.updateRestoreWindowsMenuItem()
            }
            .store(in: &cancellables)

        windowLayoutSnapshotManager?.$hasRestorableSnapshot
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateRestoreWindowsMenuItem()
            }
            .store(in: &cancellables)

        settings.$appTheme
            .receive(on: RunLoop.main)
            .sink { theme in
                switch theme {
                case .light: NSApp.appearance = NSAppearance(named: .aqua)
                case .dark: NSApp.appearance = NSAppearance(named: .darkAqua)
                case .system: NSApp.appearance = nil
                }
            }
            .store(in: &cancellables)

        settings.$showOnAllMonitors
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.refreshPanelsForCurrentConfiguration()
            }
            .store(in: &cancellables)

        settings.$taskbarHeight
            .receive(on: RunLoop.main)
            .sink { [weak self] height in
                self?.windowManager?.taskbarHeight = Self.taskbarReservationHeight(for: height)
            }
            .store(in: &cancellables)

        settings.$showOverFullScreenApps
            .receive(on: RunLoop.main)
            .sink { [weak self] showOverFullScreenApps in
                guard let self else {
                    return
                }

                self.panels.values.forEach {
                    $0.updateCollectionBehavior(showOverFullScreenApps: showOverFullScreenApps)
                }
                self.updatePanelVisibility()
            }
            .store(in: &cancellables)

        windowManager.$windows
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updatePanelVisibility()
            }
            .store(in: &cancellables)

        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.refreshPanelsForCurrentConfiguration()
        }

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        let workspaceNames: [Notification.Name] = [
            NSWorkspace.didActivateApplicationNotification,
            NSWorkspace.activeSpaceDidChangeNotification
        ]

        workspaceObservers = workspaceNames.map { name in
            workspaceCenter.addObserver(
                forName: name,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                self?.updatePanelVisibility()
            }
        }
    }

    private func reconcilePanels() {
        guard
            let settings,
            let windowManager,
            let permissionsManager,
            let badgeMonitor,
            let appStateMonitor,
            let smPluginService,
            let systemResourceMonitor,
            let blacklistManager,
            let pinnedAppManager
        else {
            return
        }

        let targetScreens = screensToShow(showOnAllMonitors: settings.showOnAllMonitors)
        let targetIDs = Set(targetScreens.compactMap(ScreenGeometry.displayID(for:)))

        for screen in targetScreens {
            guard let displayID = ScreenGeometry.displayID(for: screen) else {
                continue
            }

            if let panel = panels[displayID] {
                panel.updateFrame(for: screen)
                continue
            }

            let contentView = TaskbarContentView(
                windowManager: windowManager,
                badgeMonitor: badgeMonitor,
                appStateMonitor: appStateMonitor,
                smPluginService: smPluginService,
                permissionsManager: permissionsManager,
                settings: settings,
                blacklistManager: blacklistManager,
                pinnedAppManager: pinnedAppManager,
                systemResourceMonitor: systemResourceMonitor,
                thumbnailService: thumbnailService,
                displayID: displayID,
                openSettingsHandler: { [weak self] in
                    self?.openSettings(nil)
                }
            )
            let panel = TaskbarPanel(
                permissionsManager: permissionsManager,
                settings: settings,
                screen: screen
            )
            panel.updateCollectionBehavior(showOverFullScreenApps: settings.showOverFullScreenApps)
            panel.setContentSubview(contentView)
            contentView.preferredWidthDidChange = { [weak panel] in
                panel?.requestLayoutUpdate(animated: false)
            }

            contentViews[displayID] = contentView
            panels[displayID] = panel
        }

        let staleDisplayIDs = Set(panels.keys).subtracting(targetIDs)
        for displayID in staleDisplayIDs {
            panels[displayID]?.orderOut(nil)
            panels.removeValue(forKey: displayID)
            contentViews.removeValue(forKey: displayID)
        }

        windowManager.activeDisplayIDs = Set(panels.keys)
    }

    private func refreshPanelsForCurrentConfiguration() {
        reconcilePanels()
        handleAccessibilityPermissionChange()
        updatePanelVisibility()
        windowLayoutSnapshotManager?.handleDisplayConfigurationChange()
    }

    private func updatePanelVisibility() {
        guard let settings, let windowManager else {
            return
        }

        if settings.showOverFullScreenApps {
            panels.values.forEach { $0.orderFront(nil) }
            return
        }

        for (displayID, panel) in panels {
            guard let screen = ScreenGeometry.screen(for: displayID) else {
                panel.orderOut(nil)
                continue
            }

            if windowManager.hasFullScreenWindow(on: screen) {
                panel.orderOut(nil)
            } else {
                panel.orderFront(nil)
            }
        }
    }

    private func handleAccessibilityPermissionChange() {
        contentViews.values.forEach { $0.handleAccessibilityPermissionChange() }
        panels.values.forEach { $0.updateForAccessibilityPermissionChange() }
        windowSwitcherService?.updateForAccessibilityPermissionChange(
            isGranted: permissionsManager?.isAccessibilityGranted ?? false
        )
    }

    private func updateRestoreWindowsMenuItem() {
        restoreWindowsMenuItem?.isEnabled =
            (windowLayoutSnapshotManager?.hasRestorableSnapshot ?? false) &&
            (permissionsManager?.isAccessibilityGranted ?? false)
    }

    private func screensToShow(showOnAllMonitors: Bool) -> [NSScreen] {
        if showOnAllMonitors {
            return NSScreen.screens
        }

        if let mainScreen = NSScreen.main {
            return [mainScreen]
        }

        return NSScreen.screens.prefix(1).map { $0 }
    }

    private static func taskbarReservationHeight(for height: CGFloat) -> CGFloat {
        max(height, minimumTaskbarReservationHeight)
    }
}
