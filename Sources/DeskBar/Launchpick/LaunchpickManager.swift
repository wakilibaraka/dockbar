import AppKit
import SwiftUI

final class LaunchpickManager {
    static let shared = LaunchpickManager()
    
    private var panel: LaunchpickPanel?
    private var popover: NSPopover?
    private var state: LaunchpickState?
    private var localMonitor: Any?
    private var globalMonitor: Any?
    private var keyMonitor: Any?
    
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
        
        // Refresh launchers from config
        let config = LaunchpickConfigManager.shared.config
        state.columns = config.columns ?? 4
        state.launchers = config.launchers.map { launcher in
            LaunchpickItem(
                name: launcher.name,
                exec: launcher.exec,
                icon: IconResolver.resolve(icon: launcher.icon, exec: launcher.exec),
                category: "Pinned"
            )
        }
        
        if UserDefaults.standard.bool(forKey: "launchpickShowMostUsedApps") {
            SpotlightMostUsed.shared.fetch { items in
                state.mostUsedLaunchers = items
            }
        } else {
            state.mostUsedLaunchers = []
        }
        
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
        
        if keyMonitor == nil {
            keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
                guard let self = self, let state = self.state else { return event }
                let maxIndex = state.totalFilteredCount - 1
                if maxIndex < 0 { return event }
                
                switch event.keyCode {
                case 126: // Up
                    state.selectedIndex = max(0, state.selectedIndex - state.columns)
                    return nil
                case 125: // Down
                    state.selectedIndex = min(maxIndex, state.selectedIndex + state.columns)
                    return nil
                case 123: // Left
                    state.selectedIndex = max(0, state.selectedIndex - 1)
                    return nil
                case 124: // Right
                    state.selectedIndex = min(maxIndex, state.selectedIndex + 1)
                    return nil
                case 36: // Enter
                    let index = state.selectedIndex
                    if index < state.filteredLaunchers.count {
                        self.launch(item: state.filteredLaunchers[index])
                    } else if index - state.filteredLaunchers.count < state.orderedSystemApps.count {
                        self.launch(item: state.orderedSystemApps[index - state.filteredLaunchers.count])
                    }
                    self.hide()
                    return nil
                default:
                    return event
                }
            }
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
        if let m = keyMonitor { NSEvent.removeMonitor(m); keyMonitor = nil }
    }
    
    private func launch(item: LaunchpickItem) {
        if let bundleIdentifier = item.bundleIdentifier,
           let applicationURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier) {
            if !NSWorkspace.shared.open(applicationURL) {
                NSLog("Launchpick: failed to open application with bundle identifier %@", bundleIdentifier)
            }
            return
        }

        if let applicationPath = item.applicationPath,
           applicationPath.hasSuffix(".app") {
            if !NSWorkspace.shared.open(URL(fileURLWithPath: applicationPath)) {
                NSLog("Launchpick: failed to open application at %@", applicationPath)
            }
            return
        }

        guard let arguments = splitCommandLine(item.exec),
              let executable = arguments.first
        else {
            NSLog("Launchpick: could not parse launcher command for %@", item.name)
            return
        }

        if executable.hasSuffix(".app") {
            if !NSWorkspace.shared.open(URL(fileURLWithPath: executable)) {
                NSLog("Launchpick: failed to open application at %@", executable)
            }
            return
        }

        guard let executableURL = resolveExecutable(named: executable) else {
            NSLog("Launchpick: executable not found for %@", item.name)
            return
        }

        let task = Process()
        task.executableURL = executableURL
        task.arguments = Array(arguments.dropFirst())

        do {
            try task.run()
        } catch {
            NSLog("Launchpick: failed to launch %@: %@", executableURL.path, error.localizedDescription)
        }
    }

    private func resolveExecutable(named executable: String) -> URL? {
        if executable.contains("/") {
            let url = URL(fileURLWithPath: executable)
            return FileManager.default.isExecutableFile(atPath: url.path) ? url : nil
        }

        let path = ProcessInfo.processInfo.environment["PATH"] ?? "/usr/local/bin:/usr/bin:/bin"
        for directory in path.split(separator: ":").map(String.init) {
            let candidate = URL(fileURLWithPath: directory).appendingPathComponent(executable)
            if FileManager.default.isExecutableFile(atPath: candidate.path) {
                return candidate
            }
        }

        return nil
    }

    private func splitCommandLine(_ command: String) -> [String]? {
        var arguments: [String] = []
        var argument = ""
        var quote: Character?
        var escaping = false

        for character in command {
            if escaping {
                argument.append(character)
                escaping = false
                continue
            }

            if character == "\\" {
                escaping = true
                continue
            }

            if let activeQuote = quote {
                if character == activeQuote {
                    quote = nil
                } else {
                    argument.append(character)
                }
                continue
            }

            if character == "'" || character == "\"" {
                quote = character
            } else if character.isWhitespace {
                if !argument.isEmpty {
                    arguments.append(argument)
                    argument = ""
                }
            } else {
                argument.append(character)
            }
        }

        guard !escaping, quote == nil else {
            return nil
        }

        if !argument.isEmpty {
            arguments.append(argument)
        }

        return arguments.isEmpty ? nil : arguments
    }
}
