import CoreGraphics
import QuartzCore

struct BareCommandShortcutDetector {
    private(set) var isTrackingCommandTap = false
    private var isCommandDown = false
    private var lastCommandDownTime: CFTimeInterval = 0

    mutating func handleFlagsChanged(_ flags: CGEventFlags) -> Bool {
        let commandIsDown = flags.contains(.maskCommand)
        let hasOtherModifier =
            flags.contains(.maskAlternate) ||
            flags.contains(.maskControl) ||
            flags.contains(.maskShift)

        if commandIsDown {
            if !isCommandDown {
                isTrackingCommandTap = !hasOtherModifier
                lastCommandDownTime = CACurrentMediaTime()
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
        return isCommandDown && isTrackingCommandTap && !hasOtherModifier && elapsed >= 0.25
    }

    mutating func handleKeyDown() {
        isTrackingCommandTap = false
    }

    mutating func cancel() {
        isTrackingCommandTap = false
        isCommandDown = false
    }
}
