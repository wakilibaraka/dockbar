import AppKit
import Foundation

struct MigrationManager {
    static func runMigrations() {
        let fileManager = FileManager.default
        let homeDirectory = fileManager.homeDirectoryForCurrentUser
        
        // 1. Terminate any running old "DeskBar" instances
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if app.bundleIdentifier == "com.deskbar.app" {
                print("DeskBar Migration: Terminating old instance -> \(app.localizedName ?? "Unknown")")
                app.forceTerminate()
            }
        }
        
        // 2. Unload and remove old LaunchAgents
        let oldAgents = [
            "Library/LaunchAgents/com.deskbar.app.plist",
            "Library/LaunchAgents/com.deskbar.dock-watchdog.plist"
        ]
        
        for agentPath in oldAgents {
            let url = homeDirectory.appendingPathComponent(agentPath)
            if fileManager.fileExists(atPath: url.path) {
                print("DeskBar Migration: Removing old LaunchAgent -> \(agentPath)")
                // Attempt to unload
                let process = Process()
                process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                process.arguments = ["bootout", "gui/\(getuid())", url.path]
                try? process.run()
                process.waitUntilExit()
                
                // Backup unload method
                let fallbackProcess = Process()
                fallbackProcess.executableURL = URL(fileURLWithPath: "/bin/launchctl")
                fallbackProcess.arguments = ["unload", url.path]
                try? fallbackProcess.run()
                fallbackProcess.waitUntilExit()
                
                // Remove the file
                try? fileManager.removeItem(at: url)
            }
        }
        
        // 3. Remove old config directory and state files
        let oldConfigDir = homeDirectory
            .appendingPathComponent(".config", isDirectory: true)
            .appendingPathComponent("deskbar", isDirectory: true)
        
        if fileManager.fileExists(atPath: oldConfigDir.path) {
            print("DeskBar Migration: Removing old config directory -> \(oldConfigDir.path)")
            try? fileManager.removeItem(at: oldConfigDir)
        }
    }
}
