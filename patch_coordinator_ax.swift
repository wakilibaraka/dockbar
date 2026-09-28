import Foundation

let path = "Sources/DeskBar/Views/Engine/ThemeCoordinator.swift"
var content = try! String(contentsOfFile: path)
let target = """
        containerView.onAppActivate = { appID in
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == appID }) {
"""
let replacement = """
        containerView.onAppActivate = { appID in
            if !AXIsProcessTrusted() {
                let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
                AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)
            }
            if let app = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == appID }) {
"""
content = content.replacingOccurrences(of: target, with: replacement)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
