import AppKit
import Combine
import SwiftUI

@MainActor
final class HoldToQuitService: ObservableObject {
    static let shared = HoldToQuitService()
    
    private var overlayWindow: NSWindow?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    @Published var isShowingOverlay = false
    @Published var progress: Double = 0.0
    @Published var symbol: String = "q.circle.fill"
    
    private var timer: Timer?
    private var startTime: Date?
    private var holdDuration: Double = 2.0
    private var isTracking = false
    
    private var isHandlingSynthesizedEvent = false
    private var currentEventToForward: CGEvent?
    
        private init() {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 160, height: 160),
            styleMask: [.nonactivatingPanel, .borderless],
            backing: .buffered,
            defer: false
        )
        panel.level = .screenSaver
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        panel.backgroundColor = .clear
        panel.isOpaque = false
        panel.hasShadow = false
        panel.ignoresMouseEvents = true
        panel.center()
        let view = NSHostingView(rootView: HoldToQuitOverlayView())
        panel.contentView = view
        self.overlayWindow = panel
    }
    
    func start() {
        guard eventTap == nil else { return }
        
        let mask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue) | (1 << CGEventType.flagsChanged.rawValue)
        
        eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(mask),
            callback: { proxy, type, event, refcon in
                let service = Unmanaged<HoldToQuitService>.fromOpaque(refcon!).takeUnretainedValue()
                return service.handleEvent(proxy: proxy, type: type, event: event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        )
        
        guard let tap = eventTap else {
            print("HoldToQuitService: Failed to create event tap. Make sure accessibility permissions are granted.")
            return
        }
        
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
    }
    
    func stop() {
        if let tap = eventTap {
            CGEvent.tapEnable(tap: tap, enable: false)
            if let rls = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetMain(), rls, .commonModes)
            }
            eventTap = nil
            runLoopSource = nil
        }
    }
    
    private func handleEvent(proxy: CGEventTapProxy, type: CGEventType, event: CGEvent) -> Unmanaged<CGEvent>? {
        if isHandlingSynthesizedEvent {
            return Unmanaged.passUnretained(event)
        }
        
        let enableHoldToQuit = UserDefaults.standard.object(forKey: "enableHoldToQuit") as? Bool ?? true
        guard enableHoldToQuit else { return Unmanaged.passUnretained(event) }
        
        let holdDuration = UserDefaults.standard.object(forKey: "holdToQuitDuration") as? Double ?? 2.0
        let holdToQuitCmdW = UserDefaults.standard.object(forKey: "holdToQuitCmdW") as? Bool ?? false
        
        let flags = event.flags
        let isCmdPressed = flags.contains(.maskCommand)
        let isShiftPressed = flags.contains(.maskShift)
        let isOptionPressed = flags.contains(.maskAlternate)
        let isControlPressed = flags.contains(.maskControl)
        
        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        // Q key is 12, W key is 13
        let isQ = keyCode == 12
        let isW = keyCode == 13
        
        // Only trigger on raw Cmd+Q or Cmd+W (no shift/opt/ctrl)
        let isTargetCombo = (isQ || (isW && holdToQuitCmdW)) && isCmdPressed && !isShiftPressed && !isOptionPressed && !isControlPressed
        
        if type == .keyDown {
            if isTargetCombo && !isTracking {
                // Ignore auto-repeat
                if event.getIntegerValueField(.keyboardEventAutorepeat) != 0 {
                    return nil // Consume repeat
                }
                
                DispatchQueue.main.async {
                    self.beginTracking(event: event, duration: holdDuration, symbol: isQ ? "q.circle.fill" : "w.circle.fill")
                }
                return nil // Consume the event
            }
        } else if type == .keyUp || type == .flagsChanged {
            if isTracking {
                if !isTargetCombo {
                    DispatchQueue.main.async {
                        self.cancelTracking()
                    }
                }
                if isTargetCombo {
                    return nil
                }
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
    
    private func beginTracking(event: CGEvent, duration: Double, symbol: String) {
        isTracking = true
        self.symbol = symbol
        currentEventToForward = event
        
        if duration <= 0.0 {
            // 0s mode: flash overlay and immediately quit
            self.progress = 1.0
            self.isShowingOverlay = true
            showWindow()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.isShowingOverlay = false
            }
            commitQuit()
            return
        }
        
        holdDuration = duration
        startTime = Date()
        progress = 0.0
        isShowingOverlay = true
        showWindow()
        
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.016, repeats: true) { [weak self] _ in
            self?.updateProgress()
        }
    }
    
    private func updateProgress() {
        guard let start = startTime else { return }
        let elapsed = Date().timeIntervalSince(start)
        progress = min(elapsed / holdDuration, 1.0)
        
        if progress >= 1.0 {
            timer?.invalidate()
            timer = nil
            
            // Wait slightly before dismissing so user sees 100%
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isShowingOverlay = false
                self.hideWindow()
            }
            commitQuit()
        }
    }
    
    private func cancelTracking() {
        isTracking = false
        timer?.invalidate()
        timer = nil
        isShowingOverlay = false
        hideWindow()
        currentEventToForward = nil
    }
    
    private func showWindow() {
        guard let win = overlayWindow else { return }
        if let host = win.contentView as? NSHostingView<AnyView> {
            // Can't directly assign to AnyView generic type like this, wait.
            // Will replace with proper SwiftUI binding.
        }
        win.makeKeyAndOrderFront(nil)
    }
    
    private func hideWindow() {
        overlayWindow?.orderOut(nil)
    }
    
    private func commitQuit() {
        isTracking = false
        if let event = currentEventToForward {
            isHandlingSynthesizedEvent = true
            // Synthesize the down and up
            let down = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)), keyDown: true)
            down?.flags = .maskCommand
            down?.post(tap: .cgSessionEventTap)
            
            let up = CGEvent(keyboardEventSource: nil, virtualKey: CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode)), keyDown: false)
            up?.flags = .maskCommand
            up?.post(tap: .cgSessionEventTap)
            
            isHandlingSynthesizedEvent = false
        }
        currentEventToForward = nil
    }
}
