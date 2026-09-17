import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState) -> NSImage {
        let width: CGFloat = 28
        let height: CGFloat = 14
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        
        image.lockFocus()
        
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        
        // Define colors
        let borderColor = NSColor.labelColor
        let fillColor = state.percentage <= 20 ? NSColor.systemRed : (state.isCharging ? NSColor.systemGreen : NSColor.labelColor)
        
        // Draw battery outline
        let bodyRect = NSRect(x: 1, y: 1, width: width - 3, height: height - 2)
        let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: 2.5, yRadius: 2.5)
        borderColor.setStroke()
        bodyPath.lineWidth = 1.5
        bodyPath.stroke()
        
        // Draw battery terminal
        let terminalRect = NSRect(x: width - 2, y: height / 2 - 2.5, width: 2, height: 5)
        let terminalPath = NSBezierPath(rect: terminalRect)
        borderColor.setFill()
        terminalPath.fill()
        
        // Draw battery level fill
        let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * (width - 7), width - 7))
        if fillWidth > 0 {
            let fillRect = NSRect(x: 2.5, y: 2.5, width: fillWidth, height: height - 5)
            let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: 1.0, yRadius: 1.0)
            fillColor.setFill()
            fillPath.fill()
        }
        
        // Draw lightning bolt if charging
        if state.isCharging {
            let boltPath = NSBezierPath()
            boltPath.move(to: NSPoint(x: width / 2 + 1, y: height - 3))
            boltPath.line(to: NSPoint(x: width / 2 - 2, y: height / 2))
            boltPath.line(to: NSPoint(x: width / 2, y: height / 2))
            boltPath.line(to: NSPoint(x: width / 2 - 1, y: 3))
            boltPath.line(to: NSPoint(x: width / 2 + 2, y: height / 2 + 1))
            boltPath.line(to: NSPoint(x: width / 2, y: height / 2 + 1))
            boltPath.close()
            
            NSColor.windowBackgroundColor.setFill() // Contrast color
            boltPath.fill()
        }
        
        context?.restoreGState()
        image.unlockFocus()
        image.isTemplate = !state.isCharging && state.percentage > 20
        return image
    }
}
