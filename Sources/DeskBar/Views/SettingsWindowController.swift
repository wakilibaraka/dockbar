import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    convenience init(
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        permissionsManager: PermissionsManager,
        thumbnailService: ThumbnailService
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 660, height: 480),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeskBar Settings"
        window.center()
        
        let settingsView = ModernSettingsView(
            settings: settings,
            pinnedAppManager: pinnedAppManager,
            blacklistManager: blacklistManager,
            permissionsManager: permissionsManager
        )
        
        window.contentView = NSHostingView(rootView: settingsView)
        self.init(window: window)
    }
}
