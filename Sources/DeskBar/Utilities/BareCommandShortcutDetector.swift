import CoreGraphics
import QuartzCore

struct BareCommandShortcutDetector {
    private var isTrackingCommandTap = false
    private var isCommandDown = false
    private var trackingRightCommandOnly: Bool = false
    
    // For double tap
    private var lastValidTapTime: CFTimeInterval = 0
    private let doubleTapThreshold: CFTimeInterval = 0.3
    
    var isRightCommandTap = false

    mutating func handleFlagsChanged(_ flags: CGEventFlags, event: CGEvent) -> Bool {
        let commandIsDown = flags.contains(.maskCommand)
        let hasOtherModifier =
            flags.contains(.maskAlternate) ||
            flags.contains(.maskControl) ||
            flags.contains(.maskShift)

        let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
        
        if commandIsDown {
            if !isCommandDown {
                // Command just pressed
                isTrackingCommandTap = !hasOtherModifier
                if keyCode == 54 {
                    trackingRightCommandOnly = true
                } else {
                    trackingRightCommandOnly = false
                }
            } else if hasOtherModifier {
                isTrackingCommandTap = false
            }
            isCommandDown = true
            return false // We don't trigger on press, only on release
        }

        // Command released
        let wasTracking = isTrackingCommandTap
        let wasCommandDown = isCommandDown
        let rightCommand = trackingRightCommandOnly
        
        defer {
            isTrackingCommandTap = false
            isCommandDown = false
        }
        
        if wasCommandDown && wasTracking && !hasOtherModifier {
            let now = CACurrentMediaTime()
            let elapsedSinceLastTap = now - lastValidTapTime
            
            if elapsedSinceLastTap <= doubleTapThreshold {
                // Double tap confirmed!
                lastValidTapTime = 0 // Reset
                isRightCommandTap = rightCommand
                return true
            } else {
                // First tap
                lastValidTapTime = now
            }
        } else {
            // Invalid tap
            lastValidTapTime = 0
        }
        
        return false
    }

    mutating func handleKeyDown() {
        isTrackingCommandTap = false
        lastValidTapTime = 0
    }

    mutating func cancel() {
        isTrackingCommandTap = false
        isCommandDown = false
        lastValidTapTime = 0
    }
}
