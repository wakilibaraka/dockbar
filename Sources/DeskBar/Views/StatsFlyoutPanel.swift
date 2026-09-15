import AppKit
import SwiftUI

final class StatsFlyoutPanel: NSPanel {
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 420),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        
        self.isFloatingPanel = true
        self.level = .popUpMenu
        self.collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .fullScreenAuxiliary]
        self.hasShadow = true
        self.backgroundColor = .clear
        self.isOpaque = false
        
        let container = NSView()
        
        let hostingView = NSHostingView(rootView: StatsView().background(VisualEffectBackground()).clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous)))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: container.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: container.trailingAnchor)
        ])
        
        self.contentView = container
    }
    
    override var canBecomeKey: Bool { return true }
    override var canBecomeMain: Bool { return true }
    
    func show(relativeTo view: NSView) {
        BluetoothStatsService.shared.startMonitoring()
        
        let screenRect = view.window?.convertToScreen(view.convert(view.bounds, to: nil)) ?? .zero
        let panelSize = self.frame.size
        let margin: CGFloat = 8
        let x = max(8, screenRect.midX - (panelSize.width / 2))
        let y = screenRect.maxY + margin
        
        self.setFrameOrigin(NSPoint(x: x, y: y))
        self.makeKeyAndOrderFront(nil)
        
        // Add global monitor for clicks outside
        NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self else { return }
            let location = event.locationInWindow
            if !NSMouseInRect(location, self.frame, false) && !NSMouseInRect(location, screenRect, false) {
                self.hide()
            }
        }
    }
    
    func hide() {
        self.orderOut(nil)
        BluetoothStatsService.shared.stopMonitoring()
    }
}
