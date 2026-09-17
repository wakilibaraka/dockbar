import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState, style: BatteryIconStyle = .horizontal, showTextInside: Bool = false) -> NSImage {
        
        let isHorizontal = (style == .horizontal)
        
        // Match Native macOS Menu Bar Battery Dimensions
        let width: CGFloat = isHorizontal ? 28 : 16
        let height: CGFloat = isHorizontal ? 14 : 26
        let size = NSSize(width: width, height: height)
        
        let image = NSImage(size: size, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            
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
            
            if isHorizontal {
                // Native Mac proportions
                let bodyWidth: CGFloat = 22.5
                let bodyHeight: CGFloat = 10.5
                let bodyRect = NSRect(x: 1.5, y: (height - bodyHeight) / 2.0, width: bodyWidth, height: bodyHeight)
                let cornerRadius: CGFloat = 2.5
                
                // Outer Body
                let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
                bodyPath.lineWidth = 1.0
                strokeColor.setStroke()
                bodyPath.stroke()
                
                // Terminal Nub
                let nubWidth: CGFloat = 1.5
                let nubHeight: CGFloat = 4.0
                let nubRect = NSRect(x: bodyRect.maxX + 0.5, y: (height - nubHeight) / 2.0, width: nubWidth, height: nubHeight)
                let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
                strokeColor.setFill()
                nubPath.fill()
                
                // Inner Fill
                let padding: CGFloat = 1.5
                let maxFillWidth = bodyRect.width - (padding * 2)
                let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillWidth, maxFillWidth))
                
                let fillRectBase = NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: fillWidth, height: bodyRect.height - (padding * 2))
                
                if fillWidth > 0 {
                    let innerRadius: CGFloat = 1.5
                    let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                    fillColor.setFill()
                    fillPath.fill()
                }
                
                // Draw Overlay (Icon or Text)
                if showTextInside {
                    drawTextInside(percentage: state.percentage, cx: bodyRect.minX + bodyRect.width / 2.0, cy: height / 2.0, fillWidth: fillWidth, isHorizontal: true, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor)
                } else {
                    drawCenterIcon(state: state, cx: bodyRect.minX + bodyRect.width / 2.0, cy: height / 2.0, fillWidth: fillWidth, isHorizontal: true, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor)
                }
                
            } else { 
                // Vertical or VerticalBars
                let bodyWidth: CGFloat = 12
                let bodyHeight: CGFloat = 22
                let bodyRect = NSRect(x: (width - bodyWidth) / 2.0, y: 1.0, width: bodyWidth, height: bodyHeight)
                let cornerRadius: CGFloat = 2.5
                let padding: CGFloat = 1.5
                
                // Outer Body
                let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
                bodyPath.lineWidth = 1.0
                strokeColor.setStroke()
                bodyPath.stroke()
                
                // Terminal Nub (top)
                let nubWidth: CGFloat = 4.0
                let nubHeight: CGFloat = 1.5
                let nubRect = NSRect(x: (width - nubWidth) / 2.0, y: bodyRect.maxY + 0.5, width: nubWidth, height: nubHeight)
                let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
                strokeColor.setFill()
                nubPath.fill()
                
                let maxFillHeight = bodyRect.height - (padding * 2)
                let fillHeight = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillHeight, maxFillHeight))
                
                if style == .vertical {
                    if fillHeight > 0 {
                        let fillRectBase = NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: bodyRect.width - (padding * 2), height: fillHeight)
                        let innerRadius: CGFloat = 1.5
                        let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                        fillColor.setFill()
                        fillPath.fill()
                    }
                    
                    if showTextInside {
                        drawTextInside(percentage: state.percentage, cx: width / 2.0, cy: bodyRect.minY + bodyRect.height / 2.0, fillWidth: fillHeight, isHorizontal: false, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor)
                    } else {
                        drawCenterIcon(state: state, cx: width / 2.0, cy: bodyRect.minY + bodyRect.height / 2.0, fillWidth: fillHeight, isHorizontal: false, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor)
                    }
                } else if style == .verticalBars {
                    let barCount = 4
                    let totalSpacing: CGFloat = 2.0
                    let spacing: CGFloat = totalSpacing / CGFloat(barCount - 1)
                    let barHeight = (maxFillHeight - totalSpacing) / CGFloat(barCount)
                    
                    let activeBars = min(barCount, max(1, Int(ceil(CGFloat(state.percentage) / 25.0))))
                    let barsToDraw = state.percentage > 0 ? activeBars : 0
                    
                    for i in 0..<barsToDraw {
                        let y = bodyRect.minY + padding + CGFloat(i) * (barHeight + spacing)
                        let barRect = NSRect(x: bodyRect.minX + padding, y: y, width: bodyRect.width - (padding * 2), height: barHeight)
                        let fillPath = NSBezierPath(roundedRect: barRect, xRadius: 1.0, yRadius: 1.0)
                        fillColor.setFill()
                        fillPath.fill()
                    }
                    
                    // No clipping trick for bars since they are discrete
                    if showTextInside {
                        drawTextSimple(percentage: state.percentage, cx: width / 2.0, cy: bodyRect.minY + bodyRect.height / 2.0, fillColor: fillColor)
                    } else if state.isCharging || state.isACPowered {
                        drawCenterIconSimple(state: state, cx: width / 2.0, cy: bodyRect.minY + bodyRect.height / 2.0, fillColor: fillColor)
                    }
                }
            }
            
            context.restoreGState()
            return true
        }
        
        image.isTemplate = false
        return image
    }
    
    // MARK: - Drawing Helpers
    
    private static func drawTextSimple(percentage: Int, cx: CGFloat, cy: CGFloat, fillColor: NSColor) {
        let text = "\(percentage)"
        let font = NSFont.systemFont(ofSize: 8, weight: .bold)
        
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: NSColor.labelColor
        ]
        
        let attrString = NSAttributedString(string: text, attributes: attributes)
        let size = attrString.size()
        let rect = NSRect(x: cx - size.width / 2.0, y: cy - size.height / 2.0, width: size.width, height: size.height)
        attrString.draw(in: rect)
    }
    
    private static func drawTextInside(percentage: Int, cx: CGFloat, cy: CGFloat, fillWidth: CGFloat, isHorizontal: Bool, context: CGContext, bodyRect: NSRect, padding: CGFloat, fillColor: NSColor) {
        let maxFill = isHorizontal ? (bodyRect.width - (padding * 2)) : (bodyRect.height - (padding * 2))
        
        let drawText = { (isInsideFill: Bool) in
            let text = "\(percentage)"
            let font = NSFont.systemFont(ofSize: 8, weight: .heavy)
            
            // For text inside the fill, use windowBackgroundColor (which adapts nicely to dark/light mode against colored fills)
            // Or just use white for green/red/orange, and windowBackgroundColor for labelColor.
            let colorInsideFill: NSColor
            if fillColor == NSColor.labelColor {
                colorInsideFill = NSColor.windowBackgroundColor
            } else {
                colorInsideFill = NSColor.white
            }
            
            let textColor = isInsideFill ? colorInsideFill : NSColor.labelColor
            
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: textColor
            ]
            
            let attrString = NSAttributedString(string: text, attributes: attributes)
            let size = attrString.size()
            
            // Adjust y slightly for visual centering
            let rect = NSRect(x: cx - size.width / 2.0, y: cy - size.height / 2.0 + 0.5, width: size.width, height: size.height)
            attrString.draw(in: rect)
        }
        
        // Inside Fill
        context.saveGState()
        let fillRegion = isHorizontal ? 
            NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: fillWidth, height: bodyRect.height - (padding * 2)) :
            NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: bodyRect.width - (padding * 2), height: fillWidth)
        context.clip(to: fillRegion)
        drawText(true)
        context.restoreGState()
        
        // Outside Fill
        context.saveGState()
        let emptyRegion = isHorizontal ? 
            NSRect(x: bodyRect.minX + padding + fillWidth, y: bodyRect.minY + padding, width: maxFill - fillWidth, height: bodyRect.height - (padding * 2)) :
            NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding + fillWidth, width: bodyRect.width - (padding * 2), height: maxFill - fillWidth)
        context.clip(to: emptyRegion)
        drawText(false)
        context.restoreGState()
    }
    
    private static func drawCenterIconSimple(state: BatteryState, cx: CGFloat, cy: CGFloat, fillColor: NSColor) {
        if state.isCharging {
            drawBolt(cx: cx, cy: cy, isInsideFill: false, fillColor: fillColor)
        } else if state.isACPowered {
            drawPlug(cx: cx, cy: cy, isInsideFill: false, fillColor: fillColor)
        }
    }
    
    private static func drawCenterIcon(state: BatteryState, cx: CGFloat, cy: CGFloat, fillWidth: CGFloat, isHorizontal: Bool, context: CGContext, bodyRect: NSRect, padding: CGFloat, fillColor: NSColor) {
        let needsIcon = state.isCharging || state.isACPowered
        if !needsIcon { return }
        
        let drawIcon = { (isInsideFill: Bool) in
            if state.isCharging {
                drawBolt(cx: cx, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor)
            } else {
                drawPlug(cx: cx, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor)
            }
        }
        
        let maxFill = isHorizontal ? (bodyRect.width - (padding * 2)) : (bodyRect.height - (padding * 2))
        
        // Inside Fill
        context.saveGState()
        let fillRegion = isHorizontal ? 
            NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: fillWidth, height: bodyRect.height - (padding * 2)) :
            NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: bodyRect.width - (padding * 2), height: fillWidth)
        context.clip(to: fillRegion)
        drawIcon(true)
        context.restoreGState()
        
        // Outside Fill
        context.saveGState()
        let emptyRegion = isHorizontal ? 
            NSRect(x: bodyRect.minX + padding + fillWidth, y: bodyRect.minY + padding, width: maxFill - fillWidth, height: bodyRect.height - (padding * 2)) :
            NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding + fillWidth, width: bodyRect.width - (padding * 2), height: maxFill - fillWidth)
        context.clip(to: emptyRegion)
        drawIcon(false)
        context.restoreGState()
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
            // For bolt inside fill, use appropriate contrasting color
            let colorInsideFill: NSColor
            if fillColor == NSColor.labelColor {
                colorInsideFill = NSColor.windowBackgroundColor
            } else {
                colorInsideFill = NSColor.white
            }
            
            colorInsideFill.setFill()
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
        
        let colorInsideFill: NSColor
        if fillColor == NSColor.labelColor {
            colorInsideFill = NSColor.windowBackgroundColor
        } else {
            colorInsideFill = NSColor.white
        }
        
        let iconColor = isInsideFill ? colorInsideFill : NSColor.labelColor
        iconColor.setStroke()
        plugPath.stroke()
        
        if isInsideFill && fillColor == NSColor.labelColor {
            NSColor.windowBackgroundColor.setStroke()
            plugPath.stroke()
        }
    }
}
