import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState) -> NSImage {
        // Classic macOS dimensions
        let width: CGFloat = 28
        let height: CGFloat = 14
        let size = NSSize(width: width, height: height)
        
        let image = NSImage(size: size, flipped: false) { rect in
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            
            // Dimensions
            let bodyWidth: CGFloat = 24
            let bodyHeight: CGFloat = 11
            let bodyRect = NSRect(x: 1.5, y: (height - bodyHeight) / 2.0, width: bodyWidth, height: bodyHeight)
            let cornerRadius: CGFloat = 3.0
            
            // Colors
            let strokeColor = NSColor.labelColor.withAlphaComponent(0.45)
            var fillColor: NSColor
            
            if state.isCharging {
                fillColor = NSColor.systemGreen
            } else if state.isACPowered {
                fillColor = NSColor.labelColor
            } else if state.percentage <= 5 {
                fillColor = NSColor.systemRed
            } else if state.percentage <= 20 {
                fillColor = NSColor.systemOrange
            } else {
                // User explicitly preferred green for standard > 20%
                fillColor = NSColor.systemGreen
            }
            
            // Draw Outer Body
            let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
            bodyPath.lineWidth = 1.0
            strokeColor.setStroke()
            bodyPath.stroke()
            
            // Draw Terminal Nub
            let nubHeight: CGFloat = 4.0
            let nubRect = NSRect(x: 1.5 + bodyWidth, y: (height - nubHeight) / 2.0, width: 1.5, height: nubHeight)
            let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
            strokeColor.setFill()
            nubPath.fill()
            
            // Draw Inner Fill
            let maxFillWidth = bodyRect.width - 3.0
            let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillWidth, maxFillWidth))
            
            if fillWidth > 0 {
                let fillRectBase = NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5, width: fillWidth, height: bodyRect.height - 3.0)
                let innerRadius: CGFloat = cornerRadius - 1.0
                let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                fillColor.setFill()
                fillPath.fill()
            }
            
            // Draw center icon if charging or on AC
            let needsIcon = state.isCharging || state.isACPowered
            
            if needsIcon {
                let drawIcon = { (isInsideFill: Bool) in
                    let iconColor = isInsideFill ? NSColor.white : NSColor.labelColor
                    
                    let cx = bodyRect.minX + bodyRect.width / 2.0
                    let cy = height / 2.0
                    
                    if state.isCharging {
                        // Draw Bolt
                        let boltPath = NSBezierPath()
                        boltPath.move(to: NSPoint(x: cx + 1.0, y: cy + 3.5))
                        boltPath.line(to: NSPoint(x: cx - 2.0, y: cy + 0.5))
                        boltPath.line(to: NSPoint(x: cx + 0.5, y: cy + 0.5))
                        boltPath.line(to: NSPoint(x: cx - 1.0, y: cy - 3.5))
                        boltPath.line(to: NSPoint(x: cx + 2.0, y: cy - 0.5))
                        boltPath.line(to: NSPoint(x: cx - 0.5, y: cy - 0.5))
                        boltPath.close()
                        
                        if isInsideFill {
                            NSColor.white.setFill()
                            boltPath.fill()
                            NSColor.black.withAlphaComponent(0.15).setStroke()
                            boltPath.lineWidth = 0.5
                            boltPath.stroke()
                        } else {
                            NSColor.labelColor.setFill()
                            boltPath.fill()
                        }
                    } else {
                        // Draw Plug for Smart Charging
                        // A simple plug symbol:
                        let plugPath = NSBezierPath()
                        
                        // Body
                        plugPath.appendRect(NSRect(x: cx - 2.0, y: cy - 1.0, width: 4.0, height: 3.5))
                        
                        // Prongs
                        plugPath.move(to: NSPoint(x: cx - 1.0, y: cy + 2.5))
                        plugPath.line(to: NSPoint(x: cx - 1.0, y: cy + 4.0))
                        
                        plugPath.move(to: NSPoint(x: cx + 1.0, y: cy + 2.5))
                        plugPath.line(to: NSPoint(x: cx + 1.0, y: cy + 4.0))
                        
                        // Cord
                        plugPath.move(to: NSPoint(x: cx, y: cy - 1.0))
                        plugPath.line(to: NSPoint(x: cx, y: cy - 4.0))
                        
                        plugPath.lineWidth = 1.0
                        plugPath.lineCapStyle = .square
                        iconColor.setStroke()
                        plugPath.stroke()
                        
                        // Ensure inside fill is visible if it overlays on a light color (like fully white battery in dark mode)
                        // Actually, if it's AC powered (not charging), the fill is labelColor.
                        // So inside the fill, the text is white. In light mode, labelColor is black, so white plug on black fill.
                        // In dark mode, labelColor is white, so black plug on white fill (WAIT, isInsideFill gives white color!)
                        // If fill is labelColor (white in dark mode), we want the plug inside it to be NSColor.windowBackgroundColor or black!
                        // Let's use NSColor.windowBackgroundColor for insideFill when fillColor is labelColor!
                        if isInsideFill && fillColor == NSColor.labelColor {
                            NSColor.windowBackgroundColor.setStroke()
                            plugPath.stroke()
                        }
                    }
                }
                
                // Inside Fill
                context?.saveGState()
                let fillRegion = NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5, width: fillWidth, height: bodyRect.height - 3.0)
                context?.clip(to: fillRegion)
                drawIcon(true)
                context?.restoreGState()
                
                // Outside Fill
                context?.saveGState()
                let emptyRegion = NSRect(x: bodyRect.minX + 1.5 + fillWidth, y: bodyRect.minY + 1.5, width: maxFillWidth - fillWidth, height: bodyRect.height - 3.0)
                context?.clip(to: emptyRegion)
                drawIcon(false)
                context?.restoreGState()
            }
            
            context?.restoreGState()
            return true
        }
        
        image.isTemplate = false
        return image
    }
}
