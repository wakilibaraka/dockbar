import AppKit

struct BatteryStatusRenderer {
    static func renderImage(for state: BatteryState, style: BatteryIconStyle = .horizontal, size: BatteryIconSize = .standard, showTextInside: Bool = false) -> NSImage {
        
        let isHorizontal = (style == .horizontal)
        
        let scale: CGFloat
        switch size {
        case .small: scale = 0.85
        case .standard: scale = 1.0
        case .large: scale = 1.25
        }
        
        // Base native proportions
        let baseHWidth: CGFloat = 28.0
        let baseHHeight: CGFloat = 14.0
        
        let baseVWidth: CGFloat = 16.0
        let baseVHeight: CGFloat = 26.0
        
        let canvasWidth = ceil((isHorizontal ? baseHWidth : baseVWidth) * scale)
        let canvasHeight = ceil((isHorizontal ? baseHHeight : baseVHeight) * scale)
        let canvasSize = NSSize(width: canvasWidth, height: canvasHeight)
        
        let image = NSImage(size: canvasSize, flipped: false) { rect in
            guard let context = NSGraphicsContext.current?.cgContext else { return false }
            context.saveGState()
            
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
                fillColor = NSColor.systemGreen // or whatever normal is
            }
            
            // To prevent blurry lines in CoreGraphics, coordinates for 1.0pt strokes should snap to x.5
            let lineWidth: CGFloat = 1.0
            
            if isHorizontal {
                // Dimensions based on native iOS/macOS 24x11.5 standard
                let bodyWidth = ceil(24.0 * scale)
                let bodyHeight = ceil(11.5 * scale)
                let bodyX = round((canvasWidth - bodyWidth - (1.5 * scale)) / 2.0) + 0.5
                let bodyY = round((canvasHeight - bodyHeight) / 2.0) + 0.5
                
                let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyWidth - 1.0, height: bodyHeight - 1.0)
                let cornerRadius: CGFloat = ceil(2.5 * scale)
                
                let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
                bodyPath.lineWidth = lineWidth
                strokeColor.setStroke()
                bodyPath.stroke()
                
                let nubWidth = ceil(1.5 * scale)
                let nubHeight = ceil(4.0 * scale)
                let nubRect = NSRect(x: bodyRect.maxX + 0.5, y: round((canvasHeight - nubHeight) / 2.0), width: nubWidth, height: nubHeight)
                let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
                strokeColor.setFill()
                nubPath.fill()
                
                let padding: CGFloat = 1.0 // strict 1.0 gap
                let maxFillWidth = max(0, bodyRect.width - (padding * 2))
                let fillWidth = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillWidth, maxFillWidth))
                
                let fillRectBase = NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: fillWidth, height: bodyRect.height - (padding * 2))
                
                if fillWidth > 0 {
                    let innerRadius: CGFloat = max(0.5, cornerRadius - padding)
                    let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                    fillColor.setFill()
                    fillPath.fill()
                }
                
                if showTextInside {
                    drawInsideContent(state: state, cx: bodyRect.midX, cy: canvasHeight / 2.0, fillWidth: fillWidth, isHorizontal: true, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor, scale: scale)
                } else {
                    drawCenterIcon(state: state, cx: bodyRect.midX, cy: canvasHeight / 2.0, fillWidth: fillWidth, isHorizontal: true, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor, scale: scale)
                }
                
            } else { 
                // Vertical or VerticalBars
                let bodyWidth = ceil(13.0 * scale)
                let bodyHeight = ceil(24.0 * scale)
                let bodyX = round((canvasWidth - bodyWidth) / 2.0) + 0.5
                let bodyY = round((canvasHeight - bodyHeight - (1.5 * scale)) / 2.0) + 0.5
                
                let bodyRect = NSRect(x: bodyX, y: bodyY, width: bodyWidth - 1.0, height: bodyHeight - 1.0)
                let cornerRadius: CGFloat = ceil(2.5 * scale)
                let padding: CGFloat = 1.0
                
                let bodyPath = NSBezierPath(roundedRect: bodyRect, xRadius: cornerRadius, yRadius: cornerRadius)
                bodyPath.lineWidth = lineWidth
                strokeColor.setStroke()
                bodyPath.stroke()
                
                let nubWidth = ceil(4.0 * scale)
                let nubHeight = ceil(1.5 * scale)
                let nubRect = NSRect(x: round((canvasWidth - nubWidth) / 2.0), y: bodyRect.maxY + 0.5, width: nubWidth, height: nubHeight)
                let nubPath = NSBezierPath(roundedRect: nubRect, xRadius: 0.5, yRadius: 0.5)
                strokeColor.setFill()
                nubPath.fill()
                
                let maxFillHeight = max(0, bodyRect.height - (padding * 2))
                let fillHeight = max(0, min(CGFloat(state.percentage) / 100.0 * maxFillHeight, maxFillHeight))
                
                if style == .vertical {
                    if fillHeight > 0 {
                        let fillRectBase = NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: bodyRect.width - (padding * 2), height: fillHeight)
                        let innerRadius: CGFloat = max(0.5, cornerRadius - padding)
                        let fillPath = NSBezierPath(roundedRect: fillRectBase, xRadius: innerRadius, yRadius: innerRadius)
                        fillColor.setFill()
                        fillPath.fill()
                    }
                    
                    if showTextInside {
                        drawInsideContent(state: state, cx: canvasWidth / 2.0, cy: bodyRect.midY, fillWidth: fillHeight, isHorizontal: false, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor, scale: scale)
                    } else {
                        drawCenterIcon(state: state, cx: canvasWidth / 2.0, cy: bodyRect.midY, fillWidth: fillHeight, isHorizontal: false, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor, scale: scale)
                    }
                } else if style == .verticalBars {
                    let barCount = 4
                    let totalSpacing = ceil(1.5 * scale) * CGFloat(barCount - 1)
                    let spacing = totalSpacing / CGFloat(barCount - 1)
                    let barHeight = (maxFillHeight - totalSpacing) / CGFloat(barCount)
                    
                    let activeBars = min(barCount, max(1, Int(ceil(CGFloat(state.percentage) / 25.0))))
                    let barsToDraw = state.percentage > 0 ? activeBars : 0
                    
                    for i in 0..<barsToDraw {
                        let y = bodyRect.minY + padding + CGFloat(i) * (barHeight + spacing)
                        let barRect = NSRect(x: bodyRect.minX + padding, y: y, width: bodyRect.width - (padding * 2), height: barHeight)
                        let fillPath = NSBezierPath(roundedRect: barRect, xRadius: 0.5, yRadius: 0.5)
                        fillColor.setFill()
                        fillPath.fill()
                    }
                    
                    if showTextInside {
                        drawInsideContent(state: state, cx: canvasWidth / 2.0, cy: bodyRect.midY, fillWidth: maxFillHeight * (CGFloat(barsToDraw)/CGFloat(barCount)), isHorizontal: false, context: context, bodyRect: bodyRect, padding: padding, fillColor: fillColor, scale: scale, isDiscreteBars: true, barsToDraw: barsToDraw, barHeight: barHeight, spacing: spacing)
                    } else if state.isCharging || state.isACPowered {
                        drawCenterIconSimple(state: state, cx: canvasWidth / 2.0, cy: bodyRect.midY, fillColor: fillColor, scale: scale)
                    }
                }
            }
            
            context.restoreGState()
            return true
        }
        
        image.isTemplate = false
        return image
    }
    
    private static func drawInsideContent(state: BatteryState, cx: CGFloat, cy: CGFloat, fillWidth: CGFloat, isHorizontal: Bool, context: CGContext, bodyRect: NSRect, padding: CGFloat, fillColor: NSColor, scale: CGFloat, isDiscreteBars: Bool = false, barsToDraw: Int = 0, barHeight: CGFloat = 0, spacing: CGFloat = 0) {
        
        let maxFill = isHorizontal ? (bodyRect.width - (padding * 2)) : (bodyRect.height - (padding * 2))
        
        let drawBlock = { (isInsideFill: Bool) in
            let text = "\(state.percentage)"
            // Use semibold for a cleaner look closer to native
            let baseSize: CGFloat = isHorizontal ? 8.5 : 7.0
            let font = NSFont.monospacedDigitSystemFont(ofSize: baseSize * scale, weight: .semibold)
            
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
            let textSize = attrString.size()
            
            let needsIcon = state.isCharging || state.isACPowered
            let iconSpacing: CGFloat = needsIcon ? (1.5 * scale) : 0
            let iconWidth: CGFloat = needsIcon ? (4.0 * scale) : 0
            
            // Calculate total width to perfectly center the group (text + optional icon)
            let totalWidth = textSize.width + iconSpacing + iconWidth
            
            let startX = cx - (totalWidth / 2.0)
            
            // Draw Text
            let yOffset = (font.ascender - font.capHeight) / 2.0
            let textRect = NSRect(x: startX, y: cy - textSize.height / 2.0 - yOffset, width: textSize.width, height: textSize.height)
            attrString.draw(in: textRect)
            
            // Draw Icon if needed
            if needsIcon {
                let iconCX = startX + textSize.width + iconSpacing + (iconWidth / 2.0)
                if state.isCharging {
                    drawBolt(cx: iconCX, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor, scale: scale)
                } else if state.isACPowered {
                    drawPlug(cx: iconCX, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor, scale: scale)
                }
            }
        }
        
        // Setup clip for fill (Inside)
        context.saveGState()
        if isDiscreteBars {
            let path = CGMutablePath()
            for i in 0..<barsToDraw {
                let y = bodyRect.minY + padding + CGFloat(i) * (barHeight + spacing)
                let barRect = NSRect(x: bodyRect.minX + padding, y: y, width: bodyRect.width - (padding * 2), height: barHeight)
                path.addRect(barRect)
            }
            context.addPath(path)
            context.clip()
        } else {
            let fillRegion = isHorizontal ? 
                NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: fillWidth, height: bodyRect.height - (padding * 2)) :
                NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding, width: bodyRect.width - (padding * 2), height: fillWidth)
            context.clip(to: fillRegion)
        }
        drawBlock(true)
        context.restoreGState()
        
        // Setup clip for empty (Outside)
        context.saveGState()
        if isDiscreteBars {
            let path = CGMutablePath()
            path.addRect(NSRect(x: 0, y: 0, width: 1000, height: 1000)) // everything
            // Sub path to exclude the bars
            for i in 0..<barsToDraw {
                let y = bodyRect.minY + padding + CGFloat(i) * (barHeight + spacing)
                let barRect = NSRect(x: bodyRect.minX + padding, y: y, width: bodyRect.width - (padding * 2), height: barHeight)
                path.addRect(barRect)
            }
            context.addPath(path)
            context.clip(using: .evenOdd)
        } else {
            let emptyRegion = isHorizontal ? 
                NSRect(x: bodyRect.minX + padding + fillWidth, y: bodyRect.minY + padding, width: maxFill - fillWidth, height: bodyRect.height - (padding * 2)) :
                NSRect(x: bodyRect.minX + padding, y: bodyRect.minY + padding + fillWidth, width: bodyRect.width - (padding * 2), height: maxFill - fillWidth)
            context.clip(to: emptyRegion)
        }
        drawBlock(false)
        context.restoreGState()
    }
    
    private static func drawCenterIconSimple(state: BatteryState, cx: CGFloat, cy: CGFloat, fillColor: NSColor, scale: CGFloat) {
        if state.isCharging {
            drawBolt(cx: cx, cy: cy, isInsideFill: false, fillColor: fillColor, scale: scale)
        } else if state.isACPowered {
            drawPlug(cx: cx, cy: cy, isInsideFill: false, fillColor: fillColor, scale: scale)
        }
    }
    
    private static func drawCenterIcon(state: BatteryState, cx: CGFloat, cy: CGFloat, fillWidth: CGFloat, isHorizontal: Bool, context: CGContext, bodyRect: NSRect, padding: CGFloat, fillColor: NSColor, scale: CGFloat) {
        let needsIcon = state.isCharging || state.isACPowered
        if !needsIcon { return }
        
        let drawIcon = { (isInsideFill: Bool) in
            if state.isCharging {
                drawBolt(cx: cx, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor, scale: scale)
            } else {
                drawPlug(cx: cx, cy: cy, isInsideFill: isInsideFill, fillColor: fillColor, scale: scale)
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
    
    private static func drawBolt(cx: CGFloat, cy: CGFloat, isInsideFill: Bool, fillColor: NSColor, scale: CGFloat) {
        let boltPath = NSBezierPath()
        boltPath.move(to: NSPoint(x: cx + (1.0 * scale), y: cy + (3.5 * scale)))
        boltPath.line(to: NSPoint(x: cx - (2.0 * scale), y: cy + (0.5 * scale)))
        boltPath.line(to: NSPoint(x: cx + (0.5 * scale), y: cy + (0.5 * scale)))
        boltPath.line(to: NSPoint(x: cx - (1.0 * scale), y: cy - (3.5 * scale)))
        boltPath.line(to: NSPoint(x: cx + (2.0 * scale), y: cy - (0.5 * scale)))
        boltPath.line(to: NSPoint(x: cx - (0.5 * scale), y: cy - (0.5 * scale)))
        boltPath.close()
        
        if isInsideFill {
            let colorInsideFill: NSColor
            if fillColor == NSColor.labelColor {
                colorInsideFill = NSColor.windowBackgroundColor
            } else {
                colorInsideFill = NSColor.white
            }
            
            colorInsideFill.setFill()
            boltPath.fill()
        } else {
            NSColor.labelColor.setFill()
            boltPath.fill()
        }
    }
    
    private static func drawPlug(cx: CGFloat, cy: CGFloat, isInsideFill: Bool, fillColor: NSColor, scale: CGFloat) {
        let plugPath = NSBezierPath()
        plugPath.appendRect(NSRect(x: cx - (2.0 * scale), y: cy - (1.0 * scale), width: (4.0 * scale), height: (3.5 * scale)))
        plugPath.move(to: NSPoint(x: cx - (1.0 * scale), y: cy + (2.5 * scale)))
        plugPath.line(to: NSPoint(x: cx - (1.0 * scale), y: cy + (4.0 * scale)))
        plugPath.move(to: NSPoint(x: cx + (1.0 * scale), y: cy + (2.5 * scale)))
        plugPath.line(to: NSPoint(x: cx + (1.0 * scale), y: cy + (4.0 * scale)))
        plugPath.move(to: NSPoint(x: cx, y: cy - (1.0 * scale)))
        plugPath.line(to: NSPoint(x: cx, y: cy - (4.0 * scale)))
        
        plugPath.lineWidth = 1.0 * scale
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
