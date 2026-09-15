import AppKit
import SwiftUI

final class SystemResourceFlyoutPanel: NSPanel {
    private let monitor: SystemResourceMonitor
    private let blurView = NSVisualEffectView()
    private var localMonitor: Any?
    private var globalMonitor: Any?

    init(monitor: SystemResourceMonitor) {
        self.monitor = monitor
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 360, height: 480),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        level = .popUpMenu
        collectionBehavior = [.canJoinAllSpaces, .ignoresCycle, .transient]
        isFloatingPanel = true
        backgroundColor = .clear
        hasShadow = true
        
        setupUI()
    }
    
    deinit {
        removeMonitors()
    }
    
    private func setupUI() {
        blurView.material = .hudWindow
        blurView.blendingMode = .behindWindow
        blurView.state = .active
        blurView.wantsLayer = true
        blurView.layer?.cornerRadius = 14
        blurView.layer?.cornerCurve = .continuous
        blurView.layer?.masksToBounds = true
        contentView = blurView
        
        let hostingView = NSHostingView(rootView: SystemResourceDashboardView(monitor: monitor))
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        blurView.addSubview(hostingView)
        
        NSLayoutConstraint.activate([
            hostingView.topAnchor.constraint(equalTo: blurView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: blurView.bottomAnchor),
            hostingView.leadingAnchor.constraint(equalTo: blurView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: blurView.trailingAnchor)
        ])
    }
    
    override func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        addMonitors()
    }
    
    override func close() {
        super.close()
        removeMonitors()
    }
    
    private func addMonitors() {
        if localMonitor == nil {
            localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { [weak self] event in
                if event.keyCode == 53 { // escape
                    self?.close()
                    return nil
                }
                return event
            }
        }
        if globalMonitor == nil {
            globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
                self?.close()
            }
        }
    }
    
    private func removeMonitors() {
        if let local = localMonitor {
            NSEvent.removeMonitor(local)
            localMonitor = nil
        }
        if let global = globalMonitor {
            NSEvent.removeMonitor(global)
            globalMonitor = nil
        }
    }
}
