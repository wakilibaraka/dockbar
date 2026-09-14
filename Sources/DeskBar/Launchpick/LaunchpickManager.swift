import AppKit
import SwiftUI

final class LaunchpickManager {
    static let shared = LaunchpickManager()
    
    private var panel: LaunchpickPanel?
    private var state: LaunchpickState?
    
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
    }
    
    func hide() {
        panel?.orderOut(nil)
    }
    
    private func launch(item: LaunchpickItem) {
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", item.exec]
        try? task.run()
    }
}
