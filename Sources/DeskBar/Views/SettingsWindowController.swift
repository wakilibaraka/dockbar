import AppKit
import SwiftUI

final class SettingsWindowController: NSWindowController {
    convenience init(
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        permissionsManager: PermissionsManager,
        thumbnailService: ThumbnailService
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 900, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "DeskBar Settings"
        window.minSize = NSSize(width: 780, height: 520)
        window.toolbarStyle = .unified
        window.center()

        self.init(window: window)
        window.contentViewController = NSHostingController(
            rootView: SettingsRootView(
                settings: settings,
                blacklistManager: blacklistManager,
                pinnedAppManager: pinnedAppManager,
                permissionsManager: permissionsManager,
                thumbnailService: thumbnailService
            )
        )
    }
}
