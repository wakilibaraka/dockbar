import AppKit

/// A task button driven purely by ResolvedLayout frames.
/// All geometry comes from the engine — no auto-layout, no measuring.
public final class TaskButtonEngineView: NSView {
    private let iconView = NSImageView()
    private let hoverView = NSView()
    private let indicatorView: Win11IndicatorView
    private let style: IndicatorStyle
    private let hoverStyle: HoverStyle
    private let iconStyle: IconStyle
    public var onActivate: (() -> Void)?

    public init(style: IndicatorStyle, hoverStyle: HoverStyle, iconStyle: IconStyle) {
        self.style = style
        self.hoverStyle = hoverStyle
        self.iconStyle = iconStyle
        self.indicatorView = Win11IndicatorView(frame: .zero)
        super.init(frame: .zero)
        wantsLayer = true
        setupSubviews()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    private func setupSubviews() {
        // Hover background
        hoverView.wantsLayer = true
        hoverView.layer?.cornerRadius = hoverStyle.cornerRadius
        hoverView.layer?.cornerCurve = .continuous
        hoverView.layer?.backgroundColor = NSColor.white.withAlphaComponent(hoverStyle.fillOpacity).cgColor
        hoverView.alphaValue = 0
        addSubview(hoverView)

        // Icon
        iconView.imageScaling = .scaleProportionallyDown
        iconView.imageAlignment = .alignCenter
        addSubview(iconView)

        // Indicator
        addSubview(indicatorView)

        // Tracking for hover
        let area = NSTrackingArea(rect: .zero, options: [.mouseEnteredAndExited, .inVisibleRect, .activeAlways], owner: self, userInfo: nil)
        addTrackingArea(area)
    }

    // Called by container after setting frame from ResolvedLayout
    public func configure(icon: NSImage?, indicatorState: LayoutEngine.IndicatorState,
                   hoverRect: CGRect, iconOpacity: CGFloat) {
        iconView.image = icon
        iconView.alphaValue = iconOpacity

        // Place icon centered in hit target
        let iconSize = iconStyle.size
        iconView.frame = CGRect(
            x: (bounds.width - iconSize) / 2,
            y: (bounds.height - iconSize) / 2,
            width: iconSize, height: iconSize
        )

        // Hover rect is already panel-local; convert to self-local
        let selfOrigin = frame.origin
        hoverView.frame = CGRect(
            x: hoverRect.minX - selfOrigin.x,
            y: hoverRect.minY - selfOrigin.y,
            width: hoverRect.width, height: hoverRect.height
        )

        // Indicator: bottom of button, style.thickness height, centered
        let indW = max(style.focusedWidth, style.unfocusedWidth)
        indicatorView.frame = CGRect(
            x: (bounds.width - indW) / 2,
            y: 2, // 2pt from bottom
            width: indW, height: style.thickness
        )
        indicatorView.apply(state: indicatorState, style: style)
    }

    public override func mouseEntered(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = hoverStyle.animationDuration
            hoverView.animator().alphaValue = 1
        }
    }

    public override func mouseExited(with event: NSEvent) {
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = hoverStyle.animationDuration
            hoverView.animator().alphaValue = 0
        }
    }

    public override func mouseDown(with event: NSEvent) {
        onActivate?()
    }
}
