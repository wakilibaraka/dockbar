import AppKit
import ApplicationServices
import ServiceManagement

final class TrayIconView: NSView {
    private let application: TrayApplicationInfo
    private let pinnedAppManager: PinnedAppManager
    private let accessibilityService: AccessibilityService
    private let settings: TaskbarSettings
    private let iconView = NSImageView()

    init(
        application: TrayApplicationInfo,
        pinnedAppManager: PinnedAppManager,
        settings: TaskbarSettings,
        accessibilityService: AccessibilityService = AccessibilityService()
    ) {
        self.application = application
        self.pinnedAppManager = pinnedAppManager
        self.settings = settings
        self.accessibilityService = accessibilityService
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        toolTip = application.name
        setAccessibilityElement(true)
        setAccessibilityRole(.button)
        setAccessibilityLabel(application.name)

        configureSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 24, height: 24)
    }

    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        true
    }

    override func mouseDown(with event: NSEvent) {
        if event.modifierFlags.contains(.control) {
            showContextMenu(with: event)
            return
        }

        IconClickFeedback.show(on: iconView)
        activateApplication()
    }

    override func rightMouseDown(with event: NSEvent) {
        showContextMenu(with: event)
    }

    private func configureSubviews() {
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.wantsLayer = true
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.image = application.icon?.scaled(to: NSSize(width: 24, height: 24))

        addSubview(iconView)

        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 24),
            heightAnchor.constraint(equalToConstant: 24),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.trailingAnchor.constraint(equalTo: trailingAnchor),
            iconView.topAnchor.constraint(equalTo: topAnchor),
            iconView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func activateApplication() {
        switch TrayActivationPlanner.action(
            bundleIdentifier: application.bundleIdentifier,
            hasAnyWindows: hasAnyApplicationWindows()
        ) {
        case .activateApplication:
            activateOrReopenApplication(shouldReopen: false)
        case .reopenApplication:
            activateOrReopenApplication(shouldReopen: true)
        case .openFinderWindow:
            LauncherApplicationActivator.openFinderWindow()
        }
    }

    private func activateOrReopenApplication(shouldReopen: Bool) {
        guard let bundleIdentifier = application.bundleIdentifier else {
            application.runningApplication?.unhide()
            application.runningApplication?.activate(options: .activateAllWindows)
            return
        }

        if let runningApplication = application.runningApplication {
            LauncherApplicationActivator.activate(
                runningApplication,
                bundleIdentifier: bundleIdentifier,
                applicationURL: application.bundleURL,
                shouldReopen: shouldReopen
            )
        } else if shouldReopen {
            LauncherApplicationActivator.reopen(
                bundleIdentifier: bundleIdentifier,
                applicationURL: application.bundleURL
            )
        } else {
            LauncherApplicationActivator.launch(
                bundleIdentifier: bundleIdentifier,
                applicationURL: application.bundleURL
            )
        }
    }

    private func hasAnyApplicationWindows() -> Bool? {
        guard let runningApplication = application.runningApplication else {
            return nil
        }

        if AXIsProcessTrusted() {
            let windows = accessibilityService.enumerateWindows(for: runningApplication)
            if !windows.isEmpty {
                return true
            }
        }

        return LauncherApplicationActivator.hasCGWindows(for: runningApplication)
    }

    private func makeContextMenu() -> NSMenu {
        let menu = NSMenu()
        menu.autoenablesItems = false

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApplication(_:)), keyEquivalent: "")
        quitItem.target = self
        quitItem.isEnabled = application.runningApplication != nil
        menu.addItem(quitItem)

        let hideItem = NSMenuItem(title: "Hide", action: #selector(hideApplication(_:)), keyEquivalent: "")
        hideItem.target = self
        hideItem.isEnabled = application.runningApplication != nil
        menu.addItem(hideItem)

        let pinItem = NSMenuItem(title: "Pin to Launcher", action: #selector(pinToLauncher(_:)), keyEquivalent: "")
        pinItem.target = self
        pinItem.isEnabled = application.bundleIdentifier != nil
        menu.addItem(pinItem)

        if settings.richContextMenu {
            menu.addItem(.separator())
            
            let forceQuitItem = NSMenuItem(title: "Force Quit", action: #selector(forceQuitApplication(_:)), keyEquivalent: "")
            forceQuitItem.target = self
            forceQuitItem.isEnabled = application.runningApplication != nil
            menu.addItem(forceQuitItem)
            
            if let bundleID = application.bundleIdentifier {
                let isPinned = settings.pinnedTrayApps.contains(bundleID)
                let pinTitle = isPinned ? "Unpin from Taskbar" : "Pin to Taskbar"
                let customPinItem = NSMenuItem(title: pinTitle, action: #selector(togglePinTaskbar(_:)), keyEquivalent: "")
                customPinItem.target = self
                menu.addItem(customPinItem)
            }
            
            let isOpenAtLogin = SMAppService.mainApp.status == .enabled
            let loginTitle = isOpenAtLogin ? "Remove from Login Items" : "Open on Login"
            let loginItem = NSMenuItem(title: loginTitle, action: #selector(toggleOpenOnLogin(_:)), keyEquivalent: "")
            loginItem.target = self
            menu.addItem(loginItem)
        }

        return menu
    }

    private func showContextMenu(with event: NSEvent) {
        NSMenu.popUpContextMenu(makeContextMenu(), with: event, for: self)
    }

    @objc
    private func quitApplication(_ sender: Any?) {
        application.runningApplication?.terminate()
    }

    @objc
    private func forceQuitApplication(_ sender: Any?) {
        application.runningApplication?.forceTerminate()
    }

    @objc
    private func togglePinTaskbar(_ sender: Any?) {
        guard let bundleID = application.bundleIdentifier else { return }
        if settings.pinnedTrayApps.contains(bundleID) {
            settings.pinnedTrayApps.removeAll { $0 == bundleID }
        } else {
            settings.pinnedTrayApps.append(bundleID)
        }
    }

    @objc
    private func toggleOpenOnLogin(_ sender: Any?) {
        do {
            if SMAppService.mainApp.status == .enabled {
                try SMAppService.mainApp.unregister()
            } else {
                try SMAppService.mainApp.register()
            }
        } catch {
            print("Failed to toggle SMAppService: \(error)")
        }
    }

    @objc
    private func hideApplication(_ sender: Any?) {
        application.runningApplication?.hide()
    }

    @objc
    private func pinToLauncher(_ sender: Any?) {
        guard let bundleIdentifier = application.bundleIdentifier else {
            return
        }

        pinnedAppManager.pin(
            bundleIdentifier: bundleIdentifier,
            name: application.name
        )
    }
}
