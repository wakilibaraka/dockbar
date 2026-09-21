import AppKit
import Combine

@MainActor
final class KeyboardLockQuickSetting: QuickSetting, ObservableObject {
    let id = "keyboardLock"
    var title: String {
        return isOn ? "Keyboard Locked" : "Keyboard Lock"
    }
    var symbolName: String {
        return isOn ? "lock.fill" : "keyboard"
    }
    @Published private(set) var isOn: Bool = false
    @Published private(set) var unlockDate: Date?

    // We'll just toggle it and use an event tap to block all keyboard events
    nonisolated(unsafe) private var eventTap: CFMachPort?
    nonisolated(unsafe) private var runLoopSource: CFRunLoopSource?

    deinit {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
        }
    }

    func refreshState() {
        isOn = eventTap != nil
    }

    func toggle() {
        if isOn {
            disableLock()
        } else {
            enableLock()
        }
        refreshState()
    }

    private func enableLock() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        guard AXIsProcessTrustedWithOptions(options) else {
            let alert = NSAlert()
            alert.messageText = "Accessibility Permission Required"
            alert.informativeText = "Keyboard lock requires Accessibility permission to intercept and swallow keyboard events."
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
            return
        }

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        let callback: CGEventTapCallBack = { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
            // Swallow all keyboard events
            return nil
        }

        guard let tap = CGEvent.tapCreate(
            tap: .cghidEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: callback,
            userInfo: nil
        ) else {
            print("Failed to create keyboard event tap")
            return
        }

        self.eventTap = tap
        let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        self.runLoopSource = source
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)

        // Auto-unlock after 5 minutes
        unlockDate = Date().addingTimeInterval(5 * 60)
        Task {
            try? await Task.sleep(nanoseconds: 5 * 60 * 1_000_000_000)
            if self.eventTap != nil {
                self.disableLock()
                self.refreshState()
                QuickSettingsManager.shared.refreshAll()
            }
        }
    }

    private func disableLock() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let source = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .commonModes)
            }
            self.eventTap = nil
            self.runLoopSource = nil
        }
        unlockDate = nil
    }
}
