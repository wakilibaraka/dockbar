import AppKit
import SwiftUI

final class OnboardingWindowController: NSWindowController {
    convenience init(settings: TaskbarSettings, permissionsManager: PermissionsManager, thumbnailService: ThumbnailService, completion: @escaping () -> Void) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 500),
            styleMask: [.titled, .closable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.titlebarAppearsTransparent = true
        window.titleVisibility = .hidden
        window.isMovableByWindowBackground = true
        window.center()
        
        // Blurred background like modern setup assistants
        let visualEffect = NSVisualEffectView()
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.blendingMode = .behindWindow
        window.contentView = visualEffect
        
        self.init(window: window)
        
        let onboardingView = OnboardingView(settings: settings, permissionsManager: permissionsManager, thumbnailService: thumbnailService, completion: { [weak self] in
            settings.hasCompletedOnboarding = true
            completion()
            self?.close()
        })
        
        let hostingView = NSHostingView(rootView: onboardingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        visualEffect.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: visualEffect.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffect.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: visualEffect.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffect.trailingAnchor)
        ])
    }
}
