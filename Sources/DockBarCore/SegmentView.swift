import AppKit

/// Renders one segment's surface chrome (background + border + corner radius).
/// All geometry is injected — this view does ZERO layout math.
public final class SegmentView: NSView {
    private var segment: Segment
    private let surfaceLayer: CALayer
    private let borderLayer: CAShapeLayer

    public init(segment: Segment) {
        self.segment = segment
        self.surfaceLayer = CALayer()
        self.borderLayer = CAShapeLayer()
        super.init(frame: .zero)
        wantsLayer = true
        layer?.addSublayer(surfaceLayer)
        layer?.addSublayer(borderLayer)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError() }

    public override func layout() {
        super.layout()
        applyChrome()
    }

    public func updateSegment(_ segment: Segment) {
        self.segment = segment
        applyChrome()
    }

    private func applyChrome() {
        let b = bounds
        let cr = segment.cornerRadius
        let radii = [cr.topLeft, cr.topRight, cr.bottomRight, cr.bottomLeft]
        let uniform = radii.allSatisfy { $0 == radii[0] }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // Surface
        surfaceLayer.frame = b
        if uniform {
            surfaceLayer.cornerRadius = cr.topLeft
            surfaceLayer.cornerCurve = .continuous
            surfaceLayer.mask = nil
        } else {
            // Per-corner path
            let path = makeRoundedPath(rect: b, cr: cr)
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            surfaceLayer.mask = mask
        }

        switch segment.surface {
        case .solid(let token):
            surfaceLayer.backgroundColor = resolveColorToken(token).cgColor
        case .adaptive(let light, let dark):
            let isDark = effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            surfaceLayer.backgroundColor = resolveColorToken(isDark ? dark : light).cgColor
        case .acrylic:
            surfaceLayer.backgroundColor = NSColor.clear.cgColor
        }

        // Border
        if segment.border.enabled {
            let bp = uniform
                ? NSBezierPath(roundedRect: b.insetBy(dx: segment.border.thickness/2, dy: segment.border.thickness/2),
                               xRadius: cr.topLeft, yRadius: cr.topLeft)
                : NSBezierPath(path: makeRoundedPath(rect: b.insetBy(dx: segment.border.thickness/2, dy: segment.border.thickness/2), cr: cr))
            borderLayer.path = bp.cgPath
            borderLayer.strokeColor = resolveBorderToken(segment.border.colorToken).cgColor
            borderLayer.lineWidth = segment.border.thickness
            borderLayer.fillColor = NSColor.clear.cgColor
        } else {
            borderLayer.path = nil
        }
        borderLayer.frame = b

        CATransaction.commit()
    }

    private func resolveColorToken(_ token: String) -> NSColor {
        switch token {
        case "barSurface":
            return NSColor(named: "TaskbarSurface") ?? NSColor(white: 0.15, alpha: 1.0)
        case "glassLight":
            return NSColor(white: 0.95, alpha: 0.85)
        case "glassDark":
            return NSColor(white: 0.08, alpha: 0.85)
        default:
            return NSColor(white: 0.15, alpha: 1.0)
        }
    }

    private func resolveBorderToken(_ token: String) -> NSColor {
        switch token {
        case "surfaceStrokeDefault", "surfaceStrokeGlass":
            return NSColor.white.withAlphaComponent(0.12)
        default:
            return NSColor.clear
        }
    }

    private func makeRoundedPath(rect: CGRect, cr: CornerRadius) -> NSBezierPath {
        let path = NSBezierPath()
        path.move(to: CGPoint(x: rect.minX + cr.topLeft, y: rect.maxY))
        path.line(to: CGPoint(x: rect.maxX - cr.topRight, y: rect.maxY))
        path.appendArc(withCenter: CGPoint(x: rect.maxX - cr.topRight, y: rect.maxY - cr.topRight),
                       radius: cr.topRight, startAngle: 90, endAngle: 0, clockwise: true)
        path.line(to: CGPoint(x: rect.maxX, y: rect.minY + cr.bottomRight))
        path.appendArc(withCenter: CGPoint(x: rect.maxX - cr.bottomRight, y: rect.minY + cr.bottomRight),
                       radius: cr.bottomRight, startAngle: 0, endAngle: -90, clockwise: true)
        path.line(to: CGPoint(x: rect.minX + cr.bottomLeft, y: rect.minY))
        path.appendArc(withCenter: CGPoint(x: rect.minX + cr.bottomLeft, y: rect.minY + cr.bottomLeft),
                       radius: cr.bottomLeft, startAngle: -90, endAngle: 180, clockwise: true)
        path.line(to: CGPoint(x: rect.minX, y: rect.maxY - cr.topLeft))
        path.appendArc(withCenter: CGPoint(x: rect.minX + cr.topLeft, y: rect.maxY - cr.topLeft),
                       radius: cr.topLeft, startAngle: 180, endAngle: 90, clockwise: true)
        path.close()
        return path
    }
}

// Extension to NSBezierPath that accepts NSBezierPath directly
extension NSBezierPath {
    convenience init(path: NSBezierPath) {
        self.init()
        self.append(path)
    }
}
