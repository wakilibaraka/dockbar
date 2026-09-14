import AppKit
import SwiftUI

final class LaunchpickManager {
    static let shared = LaunchpickManager()
    
    private var panel: LaunchpickPanel?
    private var state: LaunchpickState?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    private init() {}
    
    func toggle() {
        if let panel = panel, panel.isVisible {
            hide()
        } else {
            show()
        }
    }
    
    func show() {
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
        
        panel.center()
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
