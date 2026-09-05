import AppKit

final class ChromePillView: NSView {
    let visualEffectView = NSVisualEffectView()
    private let glassHighlightLayer = CAGradientLayer()

    override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.backgroundColor = NSColor.clear.cgColor

        visualEffectView.material = .hudWindow
        visualEffectView.blendingMode = .behindWindow
        visualEffectView.state = .active
        visualEffectView.autoresizingMask = [.width, .height]
        visualEffectView.wantsLayer = true
        visualEffectView.frame = bounds
        addSubview(visualEffectView)

        glassHighlightLayer.colors = [
            NSColor.white.withAlphaComponent(0.2).cgColor,
            NSColor.white.withAlphaComponent(0.0).cgColor
        ]
        glassHighlightLayer.startPoint = CGPoint(x: 0.5, y: 1.0)
        glassHighlightLayer.endPoint = CGPoint(x: 0.5, y: 0.0)
        glassHighlightLayer.borderWidth = 1
        glassHighlightLayer.borderColor = NSColor.white.withAlphaComponent(0.1).cgColor
        visualEffectView.layer?.addSublayer(glassHighlightLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private var currentLayoutMode: DeskBarLayoutMode = .pills

    func updateVisualStyle(layoutMode: DeskBarLayoutMode) {
        self.currentLayoutMode = layoutMode
        updateLayers()
    }
    
    override func layout() {
        super.layout()
        updateLayers()
    }
    
    private func updateLayers() {
        let usesGlassChrome = currentLayoutMode.usesGlassChrome || currentLayoutMode == .pills
        let cornerRadius = usesGlassChrome ? min(bounds.height / 2, 18) : 0

        layer?.cornerRadius = cornerRadius
        layer?.masksToBounds = false
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = usesGlassChrome ? 0.28 : 0
        layer?.shadowRadius = usesGlassChrome ? 14 : 0
        layer?.shadowOffset = NSSize(width: 0, height: 2)
        layer?.shadowPath = usesGlassChrome
            ? CGPath(roundedRect: bounds, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
            : nil

        visualEffectView.layer?.cornerRadius = cornerRadius
        visualEffectView.layer?.cornerCurve = .continuous
        visualEffectView.layer?.masksToBounds = usesGlassChrome

        glassHighlightLayer.isHidden = (currentLayoutMode != .winstrix && currentLayoutMode != .pills)
        glassHighlightLayer.cornerRadius = cornerRadius
        glassHighlightLayer.cornerCurve = .continuous
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        glassHighlightLayer.frame = visualEffectView.bounds
        CATransaction.commit()
    }
}
