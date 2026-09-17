import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState) -> NSImage {
        // Larger dimensions to match macOS native battery height and provide breathing room
        let width: CGFloat = 38
        let height: CGFloat = 16
        let size = NSSize(width: width, height: height)
        
        // Use a drawing handler so NSColor.labelColor automatically adapts to dark/light mode dynamically
        let image = NSImage(size: size, flipped: false) { rect in
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            
            // 1. Dimensions
            let bodyWidth: CGFloat = 33
            let bodyHeight: CGFloat = 13
            let bodyRect = NSRect(x: 1.5, y: 1.5, width: bodyWidth, height: bodyHeight)
            let cornerRadius: CGFloat = 4.0
            
            // 2. Colors
            let strokeColor = NSColor.labelColor.withAlphaComponent(0.45)
            var fillColor: NSColor
            
            if state.isCharging {
                fillColor = NSColor.systemGreen
            } else if state.percentage >= 50 {
                fillColor = NSColor.systemGreen
            } else if state.percentage >= 20 {
                fillColor = NSColor.systemOrange
            } else {
                fillColor = NSColor.systemRed
            }
            
            // 3. Draw Outer Body
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
            bodyPath.lineWidth = 1.0
            strokeColor.setStroke()
            bodyPath.stroke()
            
            // 4. Draw Terminal Nub
            let nubHeight: CGFloat = 5.0
            let nubRect = NSRect(x: 1.5 + bodyWidth, y: (height - nubHeight) / 2.0, width: 2.0, height: nubHeight)
            let nubPath = NSBezierPath(
                roundedRect: nubRect,
                xRadius: 1.0,
                yRadius: 1.0
            )
            strokeColor.setFill()
            nubPath.fill()
            
            // 5. Draw Inner Fill
            // 1.5pt padding from the outer stroke
            let maxFillWidth = bodyRect.width - 3.0
            let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillWidth, maxFillWidth))
            
            if fillWidth > 0 {
                let fillRectBase = NSRect(x: 3.0, y: 3.0, width: fillWidth, height: bodyRect.height - 3.0)
                // Inner corner radius should mathematically be outer - padding
                let innerRadius: CGFloat = cornerRadius - 1.5
                let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                fillColor.setFill()
                fillPath.fill()
            }
            
            // 6. Draw Text or Bolt
            if state.isCharging {
                let boltPath = NSBezierPath()
                let cx: CGFloat = 1.5 + bodyRect.width / 2.0
                let cy: CGFloat = height / 2.0
                boltPath.move(to: NSPoint(x: cx + 1.5, y: cy + 4.5))
                boltPath.line(to: NSPoint(x: cx - 2.5, y: cy + 0.5))
                boltPath.line(to: NSPoint(x: cx + 0.5, y: cy + 0.5))
                boltPath.line(to: NSPoint(x: cx - 1.5, y: cy - 4.5))
                boltPath.line(to: NSPoint(x: cx + 2.5, y: cy - 0.5))
                boltPath.line(to: NSPoint(x: cx - 0.5, y: cy - 0.5))
                boltPath.close()
                
                // Draw white bolt
                NSColor.white.setFill()
                boltPath.fill()
                
                // Add a tiny shadow/stroke for contrast
                NSColor.black.withAlphaComponent(0.3).setStroke()
                boltPath.lineWidth = 0.5
                boltPath.stroke()
            } else {
                let text = "\(state.percentage)"
                // System font with tabular figures to prevent jitter
                let baseFont = NSFont.systemFont(ofSize: 10, weight: .bold)
                let font = baseFont // We'll just use the standard bold for clean rendering
                
                let textSize = (text as NSString).size(withAttributes: [.font: font])
                let textRect = NSRect(
                    x: bodyRect.minX + (bodyRect.width - textSize.width) / 2.0,
                    y: bodyRect.minY + (bodyRect.height - textSize.height) / 2.0 - 0.5, // Nudge down slightly
                    width: textSize.width,
                    height: textSize.height
                )
                
                // Draw text inside the colored fill (white text for contrast against green/orange/red)
                context?.saveGState()
                let fillRegion = NSRect(x: 3.0, y: 3.0, width: fillWidth, height: bodyRect.height - 3.0)
                context?.clip(to: fillRegion)
                let insideAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.white
                ]
                text.draw(in: textRect, withAttributes: insideAttrs)
                context?.restoreGState()
                
                // Draw text outside the colored fill (labelColor for contrast against menu bar)
                context?.saveGState()
                let emptyRegion = NSRect(x: 3.0 + fillWidth, y: 3.0, width: maxFillWidth - fillWidth, height: bodyRect.height - 3.0)
                context?.clip(to: emptyRegion)
                let outsideAttrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: NSColor.labelColor
                ]
                text.draw(in: textRect, withAttributes: outsideAttrs)
                context?.restoreGState()
            }
            
            context?.restoreGState()
            return true
        }
        
        // Not a template image, because we want the green/orange/red fill colors to show.
        // The drawing handler automatically resolves NSColor.labelColor to white/black 
        // based on the menu bar appearance at render time.
        image.isTemplate = false
        return image
    }
}
