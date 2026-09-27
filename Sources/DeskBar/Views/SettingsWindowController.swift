import AppKit
import SwiftUI

class SettingsWindowController: NSWindowController {
    
    convenience init(
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        permissionsManager: PermissionsManager,
        thumbnailService: ThumbnailService,
        weatherService: WeatherService?
    ) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 750, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "Settings"
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.center()
        window.setFrameAutosaveName("DeskBarSettingsWindow_v2")
        
        self.init(window: window)
        
        let settingsView = SettingsView(
            settings: settings,
            permissionsManager: permissionsManager,
            thumbnailService: thumbnailService,
            blacklistManager: blacklistManager,
            pinnedAppManager: pinnedAppManager,
            weatherService: weatherService
        )
        
        // Add a visual effect view for the background
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .sidebar
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        
        let hostingView = NSHostingView(rootView: settingsView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        
        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
        ])
        
        window.contentView = visualEffect
    }
}
