import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState, style: BatteryIconStyle = .horizontal) -> NSImage {
        
        // Define sizes based on style
        let width: CGFloat = style == .horizontal ? 28 : 16
        let height: CGFloat = style == .horizontal ? 14 : 26
        let size = NSSize(width: width, height: height)
        
        let image = NSImage(size: size, flipped: false) { rect in
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            
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
                fillColor = NSColor.systemGreen
            }
            
            if style == .horizontal {
                let bodyWidth: CGFloat = 24
                let bodyHeight: CGFloat = 11
                let bodyRect = NSRect(x: 1.5, y: (height - bodyHeight) / 2.0, width: bodyWidth, height: bodyHeight)
                
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
                
                // Inner Fill
                let maxFillWidth = bodyRect.width - 3.0
                let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillWidth, maxFillWidth))
                if fillWidth > 0 {
                    let fillRectBase = NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5, width: fillWidth, height: bodyRect.height - 3.0)
                    let innerRadius: CGFloat = cornerRadius - 1.0
                    let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                    fillColor.setFill()
                    fillPath.fill()
                }
                
                drawCenterIcon(state: state, cx: bodyRect.minX + bodyRect.width / 2.0, cy: height / 2.0, fillWidth: fillWidth, isHorizontal: true, context: context, bodyRect: bodyRect, fillColor: fillColor)
                
            } else { // vertical or verticalBars
                let bodyWidth: CGFloat = 12
                let bodyHeight: CGFloat = 22
                let bodyRect = NSRect(x: (width - bodyWidth) / 2.0, y: 1.0, width: bodyWidth, height: bodyHeight)
                
                // Draw Outer Body
                let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
                bodyPath.lineWidth = 1.0
                strokeColor.setStroke()
                bodyPath.stroke()
                
                // Draw Terminal Nub (on top)
                let nubWidth: CGFloat = 4.0
                let nubHeight: CGFloat = 1.5
                let nubRect = NSRect(x: (width - nubWidth) / 2.0, y: 1.0 + bodyHeight, width: nubWidth, height: nubHeight)
                let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
                strokeColor.setFill()
                nubPath.fill()
                
                let maxFillHeight = bodyRect.height - 3.0
                let fillHeight = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillHeight, maxFillHeight))
                
                if style == .vertical {
                    // Standard Vertical Fill
                    if fillHeight > 0 {
                        let fillRectBase = NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5, width: bodyRect.width - 3.0, height: fillHeight)
                        let innerRadius: CGFloat = cornerRadius - 1.0
                        let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                        fillColor.setFill()
                        fillPath.fill()
                    }
                } else if style == .verticalBars {
                    // Vertical Bars Fill (e.g., 4 discrete bars)
                    let barCount = 4
                    let totalSpacing: CGFloat = 3.0
                    let spacing: CGFloat = totalSpacing / CGFloat(barCount - 1)
                    let barHeight = (maxFillHeight - totalSpacing) / CGFloat(barCount)
                    
                    let activeBars = min(barCount, max(1, Int(ceil(CGFloat(state.percentage) / 25.0))))
                    // if percentage is 0, activeBars is 1, but let's check percentage specifically
                    let barsToDraw = state.percentage > 0 ? activeBars : 0
                    
                    for i in 0..<barsToDraw {
                        let y = bodyRect.minY + 1.5 + CGFloat(i) * (barHeight + spacing)
                        let barRect = NSRect(x: bodyRect.minX + 1.5, y: y, width: bodyRect.width - 3.0, height: barHeight)
                        let innerRadius: CGFloat = 1.0
                        let fillPath = NSBezierPath(roundedRect: barRect, xRadius: innerRadius, yRadius: innerRadius)
                        fillColor.setFill()
                        fillPath.fill()
                    }
                }
                
                // We will only draw center icon for continuous vertical style, or if charging.
                // Actually, verticalBars with a bolt inside might be messy, but let's draw it over everything.
                if style == .vertical {
                    drawCenterIcon(state: state, cx: width / 2.0, cy: bodyRect.minY + bodyRect.height / 2.0, fillWidth: fillHeight, isHorizontal: false, context: context, bodyRect: bodyRect, fillColor: fillColor)
                } else if style == .verticalBars && (state.isCharging || state.isACPowered) {
                    // Just draw it in the center without the clipping trick since bars are discrete
                    drawCenterIconSimple(state: state, cx: width / 2.0, cy: bodyRect.minY + bodyRect.height / 2.0, fillColor: fillColor)
                }
            }
            
            context?.restoreGState()
            return true
        }
        
        image.isTemplate = false
        return image
    }
    
    private static func drawCenterIconSimple(state: BatteryState, cx: CGFloat, cy: CGFloat, fillColor: NSColor) {
        if state.isCharging {
            drawBolt(cx: cx, cy: cy, isInsideFill: false, fillColor: fillColor)
        } else if state.isACPowered {
            drawPlug(cx: cx, cy: cy, isInsideFill: false, fillColor: fillColor)
        }
    }
    
    private static func drawCenterIcon(state: BatteryState, cx: CGFloat, cy: CGFloat, fillWidth: CGFloat, isHorizontal: Bool, context: CGContext?, bodyRect: NSRect, fillColor: NSColor) {
        let needsIcon = state.isCharging || state.isACPowered
        if !needsIcon { return }
        
        let drawIcon = { (isInsideFill: Bool) in
            if state.isCharging {
                drawBolt(cx: cx, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor)
            } else {
                drawPlug(cx: cx, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor)
            }
        }
        
        let maxFill = isHorizontal ? (bodyRect.width - 3.0) : (bodyRect.height - 3.0)
        
        // Inside Fill
        context?.saveGState()
        let fillRegion = isHorizontal ? 
            NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5, width: fillWidth, height: bodyRect.height - 3.0) :
            NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5, width: bodyRect.width - 3.0, height: fillWidth)
        context?.clip(to: fillRegion)
        drawIcon(true)
        context?.restoreGState()
        
        // Outside Fill
        context?.saveGState()
        let emptyRegion = isHorizontal ? 
            NSRect(x: bodyRect.minX + 1.5 + fillWidth, y: bodyRect.minY + 1.5, width: maxFill - fillWidth, height: bodyRect.height - 3.0) :
            NSRect(x: bodyRect.minX + 1.5, y: bodyRect.minY + 1.5 + fillWidth, width: bodyRect.width - 3.0, height: maxFill - fillWidth)
        context?.clip(to: emptyRegion)
        drawIcon(false)
        context?.restoreGState()
    }
    
    private static func drawBolt(cx: CGFloat, cy: CGFloat, isInsideFill: Bool, fillColor: NSColor) {
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
    }
    
    private static func drawPlug(cx: CGFloat, cy: CGFloat, isInsideFill: Bool, fillColor: NSColor) {
        let plugPath = NSBezierPath()
        plugPath.appendRect(NSRect(x: cx - 2.0, y: cy - 1.0, width: 4.0, height: 3.5))
        plugPath.move(to: NSPoint(x: cx - 1.0, y: cy + 2.5))
        plugPath.line(to: NSPoint(x: cx - 1.0, y: cy + 4.0))
        plugPath.move(to: NSPoint(x: cx + 1.0, y: cy + 2.5))
        plugPath.line(to: NSPoint(x: cx + 1.0, y: cy + 4.0))
        plugPath.move(to: NSPoint(x: cx, y: cy - 1.0))
        plugPath.line(to: NSPoint(x: cx, y: cy - 4.0))
        
        plugPath.lineWidth = 1.0
        plugPath.lineCapStyle = .square
        
        let iconColor = isInsideFill ? NSColor.white : NSColor.labelColor
        iconColor.setStroke()
        plugPath.stroke()
        
        if isInsideFill && fillColor == NSColor.labelColor {
            NSColor.windowBackgroundColor.setStroke()
            plugPath.stroke()
        }
    }
}
