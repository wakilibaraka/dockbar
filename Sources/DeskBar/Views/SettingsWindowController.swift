import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    
    private let tabViewController = NSTabViewController()
    
    convenience init(
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        permissionsManager: PermissionsManager,
        thumbnailService: ThumbnailService,
        weatherService: WeatherService?
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 650),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeskBar Settings"
        window.center()
        // Save the window size across launches
        window.setFrameAutosaveName("DeskBarSettingsWindow")
        
        self.init(window: window as NSWindow?)
        
        // Configure NSTabViewController
        tabViewController.tabStyle = .toolbar
        tabViewController.transitionOptions = [.crossfade, .slideDown]
        
        let minW: CGFloat = 700
        let minH: CGFloat = 650
        
        // 1. General
        let generalTab = NSHostingController(rootView: GeneralSettingsTab(
            settings: settings,
            permissionsManager: permissionsManager,
            thumbnailService: thumbnailService,
            blacklistManager: blacklistManager,
            weatherService: weatherService
        ).frame(minWidth: minW, minHeight: minH, alignment: .top))
        generalTab.title = "General"
        let generalItem = NSTabViewItem(viewController: generalTab)
        generalItem.image = NSImage(systemSymbolName: "gearshape", accessibilityDescription: "General")
        tabViewController.addTabViewItem(generalItem)
        
        // 2. Dock
        let dockTab = NSHostingController(rootView: DockSettingsTab(settings: settings)
            .frame(minWidth: minW, minHeight: minH, alignment: .top))
        dockTab.title = "Dock"
        let dockItem = NSTabViewItem(viewController: dockTab)
        dockItem.image = NSImage(systemSymbolName: "macwindow.badge.plus", accessibilityDescription: "Dock")
        tabViewController.addTabViewItem(dockItem)
        
        // 3. Behavior
        let behaviorTab = NSHostingController(rootView: BehaviorSettingsTab(settings: settings)
            .frame(minWidth: minW, minHeight: minH, alignment: .top))
        behaviorTab.title = "Behavior"
        let behaviorItem = NSTabViewItem(viewController: behaviorTab)
        behaviorItem.image = NSImage(systemSymbolName: "hand.tap", accessibilityDescription: "Behavior")
        tabViewController.addTabViewItem(behaviorItem)
        
        // 4. Launcher
        let launcherTab = NSHostingController(rootView: LauncherOptionsTab(settings: settings, pinnedAppManager: pinnedAppManager)
            .frame(minWidth: minW, minHeight: minH, alignment: .top))
        launcherTab.title = "Launcher"
        let launcherItem = NSTabViewItem(viewController: launcherTab)
        launcherItem.image = NSImage(systemSymbolName: "command", accessibilityDescription: "Launcher")
        tabViewController.addTabViewItem(launcherItem)
        
        // 5. Elements
        let elementsTab = NSHostingController(rootView: TaskbarElementsTab(settings: settings)
            .frame(minWidth: minW, minHeight: minH, alignment: .top))
        elementsTab.title = "Elements"
        let elementsItem = NSTabViewItem(viewController: elementsTab)
        elementsItem.image = NSImage(systemSymbolName: "puzzlepiece.extension", accessibilityDescription: "Elements")
        tabViewController.addTabViewItem(elementsItem)
        
        // 6. Flyouts
        let statusTab = NSHostingController(rootView: StatusFlyoutsTab(settings: settings)
            .frame(minWidth: minW, minHeight: minH, alignment: .top))
        statusTab.title = "Flyouts"
        let statusItem = NSTabViewItem(viewController: statusTab)
        statusItem.image = NSImage(systemSymbolName: "menubar.rectangle", accessibilityDescription: "Flyouts")
        tabViewController.addTabViewItem(statusItem)
        
        window.contentViewController = tabViewController
    }
}
