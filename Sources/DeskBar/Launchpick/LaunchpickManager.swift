import AppKit
import SwiftUI

final class LaunchpickManager {
    static let shared = LaunchpickManager()
    
    private var panel: LaunchpickPanel?
    private var state: LaunchpickState?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    private init() {}
    
    func toggle(relativeTo view: NSView? = nil) {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show(relativeTo: view)
        }
    }
    
    func show(relativeTo view: NSView? = nil) {
        if panel == nil {
            let newState = LaunchpickState()
            
            // Load config
            let config = LaunchpickConfig.load()
            newState.launchers = config.launchers.map { launcher in
                LaunchpickItem(
                    name: launcher.name,
                    exec: launcher.exec,
                    icon: IconResolver.resolve(icon: launcher.icon, exec: launcher.exec)
                )
            }
            newState.columns = config.columns ?? 4
            
            newState.onLaunch = { [weak self] item in
                self?.launch(item: item)
                self?.hide()
            }
            
            newState.onDismiss = { [weak self] in
                self?.hide()
            }
            
            let contentView = ContentView(state: newState)
            let hostingView = NSHostingView(rootView: contentView)
            
            let newPanel = LaunchpickPanel()
            newPanel.contentView = hostingView
            
            self.state = newState
            self.panel = newPanel
        }
        
        guard let panel = panel, let state = state else { return }
        
        state.searchText = ""
        state.focusTrigger.toggle()
        
        let launcherStyleRaw = UserDefaults.standard.string(forKey: "launcherStyle") ?? ""
        let style = LauncherStyle(rawValue: launcherStyleRaw) ?? .anchored
        
        if style == .anchored, let view = view, let window = view.window {
            let buttonRect = view.convert(view.bounds, to: nil)
            let screenRect = window.convertToScreen(buttonRect)
            
            // Wait, we need the panel's size to position it properly.
            // Since the panel might not be layouted yet, let's force layout or just use frame.
            panel.layoutIfNeeded()
            let panelSize = panel.frame.size
            let margin: CGFloat = 8
            
            // Position above the button, aligned to its left edge.
            // But wait, the button might be on the left or right of the screen?
            // If the panel is 300px wide, and button is on the far left, minX is good.
            // If it exceeds the screen right edge, we'd need to clamp it, but for now minX is fine.
            let x = max(8, screenRect.minX)
            let y = screenRect.maxY + margin
            
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        } else {
            panel.center()
        }
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        setupMonitors()
    }
    
    func hide() {
        panel?.orderOut(nil)
        removeMonitors()
    }
    
    private func setupMonitors() {
        guard localMonitor == nil else { return }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] event in
            guard let self = self, let panel = self.panel, panel.isVisible else { return event }
            if panel.contentView?.frame.contains(event.locationInWindow) == false {
                self.hide()
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.hide()
        }
    }
    
    private func removeMonitors() {
        if let m = localMonitor { NSEvent.removeMonitor(m); localMonitor = nil }
        if let m = globalMonitor { NSEvent.removeMonitor(m); globalMonitor = nil }
    }
    
    private func launch(item: LaunchpickItem) {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", item.exec]
        try? task.run()
    }
}
