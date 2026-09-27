import AppKit

/// Renders the Windows 11-style indicator line under a task button.
/// Frame is injected by the container from ResolvedLayout — zero layout math here.
public final class Win11IndicatorView: NSView {
    private let leftPill = CALayer()
    private let rightPill = CALayer()
    private let singlePill = CALayer()

    public override init(frame: NSRect) {
        super.init(frame: frame)
        wantsLayer = true
        layer?.addSublayer(singlePill)
        layer?.addSublayer(leftPill)
        layer?.addSublayer(rightPill)
        [singlePill, leftPill, rightPill].forEach {
            $0.cornerRadius = 1.5
            $0.cornerCurve = .continuous
            $0.backgroundColor = NSColor.controlAccentColor.cgColor
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public func apply(state: LayoutEngine.IndicatorState, style: IndicatorStyle, animated: Bool = false) {
        CATransaction.begin()
        CATransaction.setDisableActions(!animated)
        if animated { CATransaction.setAnimationDuration(style.animationDuration) }

        let b = bounds
        let h = b.height // == style.thickness (caller sized this)

        switch state {
        case .none:
            singlePill.isHidden = true; leftPill.isHidden = true; rightPill.isHidden = true
        case .unfocused:
            singlePill.isHidden = false
            singlePill.frame = CGRect(x: (b.width - style.unfocusedWidth) / 2, y: 0,
                                      width: style.unfocusedWidth, height: h)
            singlePill.opacity = 0.6
            leftPill.isHidden = true; rightPill.isHidden = true
        case .focused:
            singlePill.isHidden = false
            singlePill.frame = CGRect(x: (b.width - style.focusedWidth) / 2, y: 0,
                                      width: style.focusedWidth, height: h)
            singlePill.opacity = 1.0
            leftPill.isHidden = true; rightPill.isHidden = true
        case .groupedFocused:
            singlePill.isHidden = true
            let halfW = (style.focusedWidth - 2) / 2 // 2pt gap between segments
            leftPill.frame = CGRect(x: (b.width - style.focusedWidth) / 2, y: 0,
                                    width: halfW, height: h)
            rightPill.frame = CGRect(x: leftPill.frame.maxX + 2, y: 0,
                                     width: halfW, height: h)
            leftPill.isHidden = false; rightPill.isHidden = false
            leftPill.opacity = 1.0; rightPill.opacity = 1.0
        }
        CATransaction.commit()
    }
}
