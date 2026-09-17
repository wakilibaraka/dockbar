import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState) -> NSImage {
        // Wider battery to fit both the bolt and "100%"
        let width: CGFloat = 52
        let height: CGFloat = 16
        let size = NSSize(width: width, height: height)
        
        let image = NSImage(size: size, flipped: false) { rect in
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            
            // Dimensions
            let bodyWidth: CGFloat = 46
            let bodyHeight: CGFloat = 13
            let bodyRect = NSRect(x: 1.5, y: 1.5, width: bodyWidth, height: bodyHeight)
            let cornerRadius: CGFloat = 4.0
            
            // Colors
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
            
            // Draw Outer Body
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
            bodyPath.lineWidth = 1.0
            strokeColor.setStroke()
            bodyPath.stroke()
            
            // Draw Terminal Nub
            let nubHeight: CGFloat = 5.0
            let nubRect = NSRect(x: 1.5 + bodyWidth, y: (height - nubHeight) / 2.0, width: 2.0, height: nubHeight)
            let nubPath = NSBezierPath(
                roundedRect: nubRect,
                xRadius: 1.0,
                yRadius: 1.0
            )
            strokeColor.setFill()
            nubPath.fill()
            
            // Draw Inner Fill
            let maxFillWidth = bodyRect.width - 3.0
            let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillWidth, maxFillWidth))
            
            if fillWidth > 0 {
                let fillRectBase = NSRect(x: 3.0, y: 3.0, width: fillWidth, height: bodyRect.height - 3.0)
                let innerRadius: CGFloat = cornerRadius - 1.5
                let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                fillColor.setFill()
                fillPath.fill()
            }
            
            // Prepare Text & Bolt
            let text = "\(state.percentage)%"
            let font = NSFont.systemFont(ofSize: 10, weight: .bold)
            let textSize = (text as NSString).size(withAttributes: [.font: font])
            
            let boltWidth: CGFloat = state.isCharging ? 5.0 : 0.0
            let boltSpacing: CGFloat = state.isCharging ? 2.0 : 0.0
            let totalContentWidth = boltWidth + boltSpacing + textSize.width
            
            let startX = bodyRect.minX + (bodyRect.width - totalContentWidth) / 2.0
            let cy = height / 2.0
            
            // Define drawing function for content (so we can draw it twice for clipping contrast)
            let drawContent = { (isInsideFill: Bool) in
                let currentTextColor = isInsideFill ? NSColor.white : NSColor.labelColor
                
                // 1. Draw Bolt
                if state.isCharging {
                    let cx = startX + boltWidth / 2.0
                    let boltPath = NSBezierPath()
                    boltPath.move(to: NSPoint(x: cx + 1.5, y: cy + 4.5))
                    boltPath.line(to: NSPoint(x: cx - 2.5, y: cy + 0.5))
                    boltPath.line(to: NSPoint(x: cx + 0.5, y: cy + 0.5))
                    boltPath.line(to: NSPoint(x: cx - 1.5, y: cy - 4.5))
                    boltPath.line(to: NSPoint(x: cx + 2.5, y: cy - 0.5))
                    boltPath.line(to: NSPoint(x: cx - 0.5, y: cy - 0.5))
                    boltPath.close()
                    
                    if isInsideFill {
                        // High contrast bolt inside the colored fill
                        NSColor.white.setFill()
                        boltPath.fill()
                        // Small dark shadow for legibility inside the bright green fill
                        NSColor.black.withAlphaComponent(0.2).setStroke()
                        boltPath.lineWidth = 0.5
                        boltPath.stroke()
                    } else {
                        // Regular bolt outside the fill
                        NSColor.labelColor.setFill()
                        boltPath.fill()
                    }
                }
                
                // 2. Draw Text
                let textX = startX + boltWidth + boltSpacing
                let textRect = NSRect(
                    x: textX,
                    y: bodyRect.minY + (bodyRect.height - textSize.height) / 2.0 - 0.5,
                    width: textSize.width,
                    height: textSize.height
                )
                let attrs: [NSAttributedString.Key: Any] = [
                    .font: font,
                    .foregroundColor: currentTextColor
                ]
                text.draw(in: textRect, withAttributes: attrs)
            }
            
            // Draw content twice using clipping to switch colors right at the fill boundary
            
            // Inside Fill
            context?.saveGState()
            let fillRegion = NSRect(x: 3.0, y: 3.0, width: fillWidth, height: bodyRect.height - 3.0)
            context?.clip(to: fillRegion)
            drawContent(true)
            context?.restoreGState()
            
            // Outside Fill
            context?.saveGState()
            let emptyRegion = NSRect(x: 3.0 + fillWidth, y: 3.0, width: maxFillWidth - fillWidth, height: bodyRect.height - 3.0)
            context?.clip(to: emptyRegion)
            drawContent(false)
            context?.restoreGState()
            
            context?.restoreGState()
            return true
        }
        
        image.isTemplate = false
        return image
    }
}
