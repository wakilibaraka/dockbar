import AppKit

extension NSImage {
    static func bluetoothIcon(size: CGSize = CGSize(width: 18, height: 18), color: NSColor = .white) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        let path = NSBezierPath()
        // Center the bluetooth logo in the canvas
        let cx = size.width / 2.0
        let cy = size.height / 2.0
        let h: CGFloat = 12.0 // total height
        let w: CGFloat = h * 0.5
        
        // Start from bottom left
        path.move(to: NSPoint(x: cx - w/2, y: cy - h/4))
        // To center cross
        path.line(to: NSPoint(x: cx + w/2, y: cy + h/4))
        // To top peak
        path.line(to: NSPoint(x: cx, y: cy + h/2))
        // Down the center spine
        path.line(to: NSPoint(x: cx, y: cy - h/2))
        // To bottom right
        path.line(to: NSPoint(x: cx + w/2, y: cy - h/4))
        // To center cross
        path.line(to: NSPoint(x: cx - w/2, y: cy + h/4))
        
        path.lineWidth = 1.5
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        color.setStroke()
        path.stroke()
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
