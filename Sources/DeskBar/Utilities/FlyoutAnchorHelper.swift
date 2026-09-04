import AppKit

struct FlyoutAnchorHelper {
    static func position(flyout: NSWindow, relativeTo triggerView: NSView, gap: CGFloat = 8) {
        guard let window = triggerView.window,
              let screen = window.screen else {
            return
        }
        
        // 1. Calculate trigger button's frame in screen coordinates
        let buttonRectInWindow = triggerView.convert(triggerView.bounds, to: nil)
        let buttonRectInScreen = window.convertToScreen(buttonRectInWindow)
        
        // 2. Position X: center align if possible
        var x = buttonRectInScreen.midX - (flyout.frame.width / 2)
        
        // 3. Position Y: above the taskbar with a gap
        let y = buttonRectInScreen.maxY + gap
        
        // 4. Clamp to screen bounds
        let screenRect = screen.visibleFrame
        if x < screenRect.minX + 8 {
            x = screenRect.minX + 8
        } else if x + flyout.frame.width > screenRect.maxX - 8 {
            x = screenRect.maxX - flyout.frame.width - 8
        }
        
        flyout.setFrameOrigin(NSPoint(x: x, y: y))
    }
}
