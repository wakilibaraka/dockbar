import AppKit
import SwiftUI

final class LaunchpickManager {
    static let shared = LaunchpickManager()
    
    private var panel: LaunchpickPanel?
    private var popover: NSPopover?
    private var state: LaunchpickState?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    
    private init() {}
    
    func toggle(relativeTo view: NSView? = nil) {
        if (panel?.isVisible == true) || (popover?.isShown == true) {
            hide()
        } else {
            show(relativeTo: view)
        }
    }
    
    func show(relativeTo view: NSView? = nil) {
        if state == nil {
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
            
            self.state = newState
        }
        
        guard let state = state else { return }
        
        state.searchText = ""
        state.focusTrigger.toggle()
        
        let launcherStyleRaw = UserDefaults.standard.string(forKey: "launcherStyle") ?? ""
        let style = LauncherStyle(rawValue: launcherStyleRaw) ?? .anchored
        
        let contentView = ContentView(state: state)
        let hostingView = NSHostingView(rootView: contentView)
        
        if style == .anchored, let view = view {
            // Use Popover
            panel?.orderOut(nil)
            panel = nil
            
            if popover == nil {
                let newPopover = NSPopover()
                newPopover.behavior = .transient
                let vc = NSViewController()
                vc.view = hostingView
                vc.preferredContentSize = NSSize(width: 680, height: 680)
                newPopover.contentViewController = vc
                self.popover = newPopover
            }
            
            popover?.show(relativeTo: view.bounds, of: view, preferredEdge: .maxY)
        } else {
            // Use Panel
            popover?.performClose(nil)
            popover = nil
            
            if panel == nil {
                let newPanel = LaunchpickPanel()
                hostingView.frame = newPanel.contentView!.bounds
                hostingView.autoresizingMask = [.width, .height]
                newPanel.contentView?.addSubview(hostingView)
                self.panel = newPanel
            }
            
            panel?.center()
            panel?.makeKeyAndOrderFront(nil)
            setupMonitors()
        }
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hide() {
        panel?.orderOut(nil)
        popover?.performClose(nil)
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
