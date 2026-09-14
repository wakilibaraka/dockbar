import AppKit

extension NSImage {
    static func dockBarMenuIcon(size: CGSize = CGSize(width: 18, height: 14)) -> NSImage {
        let image = NSImage(size: size)
        image.lockFocus()
        
        // Draw a miniature screen with a bottom taskbar
        let rect = NSRect(origin: .zero, size: size)
        let path = NSBezierPath(roundedRect: rect, xRadius: 2, yRadius: 2)
        path.lineWidth = 1.5
        NSColor.labelColor.setStroke()
        path.stroke()
        
        let taskbarRect = NSRect(x: 0, y: 0, width: size.width, height: 4)
        let taskbarPath = NSBezierPath(roundedRect: taskbarRect, xRadius: 1, yRadius: 1)
        NSColor.labelColor.setFill()
        taskbarPath.fill()
        
        image.unlockFocus()
        image.isTemplate = true
        return image
    }
}
