import CoreGraphics
import QuartzCore

struct BareCommandShortcutDetector {
    private(set) var isTrackingCommandTap = false
    private var isCommandDown = false
    private var lastCommandDownTime: CFTimeInterval = 0
    private var trackingRightCommandOnly: Bool = false
    
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
                isTrackingCommandTap = !hasOtherModifier
                lastCommandDownTime = CACurrentMediaTime()
                if keyCode == 54 {
                    trackingRightCommandOnly = true
                } else {
                    trackingRightCommandOnly = false
                }
            } else if hasOtherModifier {
                isTrackingCommandTap = false
            }
            isCommandDown = true
            return false
        }

        defer {
            isTrackingCommandTap = false
            isCommandDown = false
        }
        
        let elapsed = CACurrentMediaTime() - lastCommandDownTime
        let validTap = isCommandDown && isTrackingCommandTap && !hasOtherModifier && elapsed >= 0.25
        if validTap {
            isRightCommandTap = trackingRightCommandOnly
            return true
        }
        return false
    }

    mutating func handleKeyDown() {
        isTrackingCommandTap = false
    }

    mutating func cancel() {
        isTrackingCommandTap = false
        isCommandDown = false
    }
}
