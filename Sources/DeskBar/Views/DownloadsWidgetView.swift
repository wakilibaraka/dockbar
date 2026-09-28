import AppKit

public final class DownloadsWidgetView: NSControl {
    private let trayLayer = CAShapeLayer()
    private let arrowLayer = CAShapeLayer()
    private let progressLayer = CAShapeLayer()
    
    public var isDownloading: Bool = false {
        didSet { updateAppearance() }
    }
    public var progress: CGFloat = 0.0 {
        didSet { updateAppearance() }
    }
    
    public override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        setupLayers()
        updateAppearance()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }
    
    private func setupLayers() {
        guard let layer = self.layer else { return }
        
        trayLayer.fillColor = nil
        trayLayer.lineWidth = 1.5
        trayLayer.lineCap = .round
        trayLayer.lineJoin = .round
        layer.addSublayer(trayLayer)
        
        arrowLayer.fillColor = nil
        arrowLayer.lineWidth = 1.5
        arrowLayer.lineCap = .round
        arrowLayer.lineJoin = .round
        layer.addSublayer(arrowLayer)
        
        progressLayer.fillColor = nil
        progressLayer.lineWidth = 1.5
        progressLayer.lineCap = .round
        progressLayer.strokeEnd = 0
        layer.addSublayer(progressLayer)
    }
    
    public override func layout() {
        super.layout()
        let b = bounds
        let center = CGPoint(x: b.midX, y: b.midY)
        
        // Custom Tray (U-shape)
        let trayPath = CGMutablePath()
        trayPath.move(to: CGPoint(x: center.x - 7, y: center.y + 1))
        trayPath.addLine(to: CGPoint(x: center.x - 7, y: center.y - 5))
        trayPath.addCurve(to: CGPoint(x: center.x - 4, y: center.y - 8), control1: CGPoint(x: center.x - 7, y: center.y - 7), control2: CGPoint(x: center.x - 6, y: center.y - 8))
        trayPath.addLine(to: CGPoint(x: center.x + 4, y: center.y - 8))
        trayPath.addCurve(to: CGPoint(x: center.x + 7, y: center.y - 5), control1: CGPoint(x: center.x + 6, y: center.y - 8), control2: CGPoint(x: center.x + 7, y: center.y - 7))
        trayPath.addLine(to: CGPoint(x: center.x + 7, y: center.y + 1))
        trayLayer.path = trayPath
        
        // Arrow pointing down
        let arrowPath = CGMutablePath()
        arrowPath.move(to: CGPoint(x: center.x, y: center.y + 8))
        arrowPath.addLine(to: CGPoint(x: center.x, y: center.y - 1))
        arrowPath.move(to: CGPoint(x: center.x - 3, y: center.y + 2))
        arrowPath.addLine(to: CGPoint(x: center.x, y: center.y - 1))
        arrowPath.addLine(to: CGPoint(x: center.x + 3, y: center.y + 2))
        arrowLayer.path = arrowPath
        
        // Progress Ring (Circle around)
        let progPath = CGPath(ellipseIn: CGRect(x: center.x - 12, y: center.y - 12, width: 24, height: 24), transform: nil)
        progressLayer.path = progPath
        
        // Fix coordinates for AppKit vs CALayer (AppKit y is up, CoreGraphics y can be up in layer too)
    }
    
    private func updateAppearance() {
        let color = NSColor.white.cgColor // Use simple token for now
        trayLayer.strokeColor = color
        arrowLayer.strokeColor = color
        progressLayer.strokeColor = NSColor.systemBlue.cgColor
        
        if isDownloading {
            progressLayer.strokeEnd = max(0.05, progress)
            progressLayer.opacity = 1.0
            
            // Subtle bounce animation for arrow
            if arrowLayer.animation(forKey: "bounce") == nil {
                let anim = CABasicAnimation(keyPath: "transform.translation.y")
                anim.fromValue = 0
                anim.toValue = -2
                anim.duration = 0.5
                anim.autoreverses = true
                anim.repeatCount = .infinity
                arrowLayer.add(anim, forKey: "bounce")
            }
        } else {
            progressLayer.opacity = 0.0
            arrowLayer.removeAnimation(forKey: "bounce")
        }
    }
    
    public override func mouseDown(with event: NSEvent) {
        sendAction(action, to: target)
    }
}
