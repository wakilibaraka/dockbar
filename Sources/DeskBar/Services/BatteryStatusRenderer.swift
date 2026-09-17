import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState) -> NSImage {
        // Increased size for better text legibility
        let width: CGFloat = 36
        let height: CGFloat = 16
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        
        image.lockFocus()
        let context = NSGraphicsContext.current?.cgContext
        context?.saveGState()
        
        let bodyWidth: CGFloat = 33
        let bodyHeight: CGFloat = 14
        let bodyRect = NSRect(x: 1, y: 1, width: bodyWidth, height: bodyHeight)
        let cornerRadius: CGFloat = 3.5
        
        // 1. Draw Empty portion (translucent background pill)
        let emptyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
        // Alpha determines the "gray" tint when isTemplate = true
        NSColor(calibratedWhite: 0, alpha: 0.35).setFill()
        emptyPath.fill()
        
        // 2. Draw Charged portion (opaque foreground pill)
        let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * bodyWidth, bodyWidth))
        if fillWidth > 0 {
            context?.saveGState()
            let clipRect = NSRect(x: 1, y: 1, width: fillWidth, height: bodyHeight)
            context?.clip(to: clipRect)
            NSColor.black.setFill() // Alpha 1.0 = solid color when isTemplate = true
            emptyPath.fill()
            context?.restoreGState()
        }
        
        // 3. Draw Terminal nub
        let nubRect = NSRect(x: 1 + bodyWidth, y: (height - 6) / 2.0, width: 2, height: 6)
        let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 1.0, yRadius: 1.0)
        NSColor.black.setFill()
        nubPath.fill()
        
        // 4. Punch out text or bolt
        // .destinationOut erases the shape from the image completely, letting the menu bar show through.
        context?.setBlendMode(.destinationOut)
        NSColor.black.setFill()
        
        if state.isCharging {
            let boltPath = NSBezierPath()
            let cx: CGFloat = 1 + bodyWidth / 2.0
            let cy: CGFloat = height / 2.0
            boltPath.move(to: NSPoint(x: cx + 1.5, y: cy + 4.5))
            boltPath.line(to: NSPoint(x: cx - 2.5, y: cy + 0.5))
            boltPath.line(to: NSPoint(x: cx + 0.5, y: cy + 0.5))
            boltPath.line(to: NSPoint(x: cx - 1.5, y: cy - 4.5))
            boltPath.line(to: NSPoint(x: cx + 2.5, y: cy - 0.5))
            boltPath.line(to: NSPoint(x: cx - 0.5, y: cy - 0.5))
            boltPath.close()
            boltPath.fill()
        } else {
            let text = "\(state.percentage)"
            let font = NSFont.systemFont(ofSize: 10, weight: .bold)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.black // The color doesn't matter for .destinationOut, just alpha 1.0
            ]
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let textSize = attrString.size()
            let textRect = NSRect(x: 1 + (bodyWidth - textSize.width) / 2.0,
                                  y: 1 + (bodyHeight - textSize.height) / 2.0 - 0.5, // Nudge down slightly
                                  width: textSize.width,
                                  height: textSize.height)
            attrString.draw(in: textRect)
        }
        
        context?.restoreGState()
        image.unlockFocus()
        
        // Treating it as a template image allows macOS to automatically tint it for dark/light mode
        image.isTemplate = true
        return image
    }
}
