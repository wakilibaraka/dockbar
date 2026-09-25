import os

with open("Sources/DeskBar/Plugins/SMPlugin/SMPluginService.swift", "w") as f:
    f.write("""import AppKit
import Combine
import SwiftUI

struct SMAgentWindowAnnotation: Equatable {
    let sessionID: String
    let friendlyName: String
    let status: String
    let activityState: ActivityState
    let tokensUsed: Int?
    let windowID: CGWindowID?
    let lastToolName: String?
    
    enum ActivityState: String {
        case idle, active
        var color: NSColor { .clear }
    }
}

enum SMPluginAgentMenuAction {
    case rename
    case openTerminalLikeThis
    case retire
    case retireAndClose
    case copySessionID
}

final class SMPluginAgentMenuCommand: NSObject {
    let action: SMPluginAgentMenuAction
    let annotation: SMAgentWindowAnnotation
    var menuItem: NSMenuItem?
    var presentationView: NSView?
    
    init(action: SMPluginAgentMenuAction, annotation: SMAgentWindowAnnotation) {
        self.action = action
        self.annotation = annotation
    }
}

enum SMPluginAgentMenuFactory {
    static func makeMenu(
        annotation: SMAgentWindowAnnotation,
        target: Any,
        action: Selector
    ) -> NSMenu {
        return NSMenu()
    }
}

struct SMWatchWindowInfo: Equatable {
    let sessionID: String
    let windowID: CGWindowID
    let terminalWindowID: CGWindowID?
    let isSelectedTerminalTab: Bool
}

final class SMPluginService: ObservableObject {
    static let terminalBundleIdentifier = "com.apple.Terminal"
    
    @Published var agentTabs: [SMAgentWindowAnnotation] = []
    @Published var windowAnnotations: [CGWindowID: SMAgentWindowAnnotation] = [:]
    @Published var terminalTabCountByWindowID: [CGWindowID: Int] = [:]
    @Published var watchWindows: [SMWatchWindowInfo] = []
    
    init(isEnabled: Bool) {}
    
    func refresh(forceTerminalMapping: Bool = false) {}
    func rename(annotation: SMAgentWindowAnnotation, relativeTo rect: NSRect) {}
    func rename(annotation: SMAgentWindowAnnotation, presentationView: NSView?) {}
    func openTerminalLike(annotation: SMAgentWindowAnnotation, inWorkingDirectory: Bool) {}
    func retire(annotation: SMAgentWindowAnnotation, closeTerminal: Bool) {}
    func openOrActivateWatch() {}
    func openNewWatchWindow() {}
    func activate(annotation: SMAgentWindowAnnotation) {}
}
""")
