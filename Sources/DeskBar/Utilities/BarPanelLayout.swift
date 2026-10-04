import CoreGraphics

/// Where the panel and its chrome sit for a bar on a given edge.
///
/// `TaskbarPanel` used to compute these inline and could only ever produce a strip along
/// the bottom of the screen: the height came from `taskbarHeight` and the width from the
/// layout mode, with no notion of which edge the bar was on. Eskele's vertical bar needed
/// that, so the arithmetic moved here where it can be tested without a window server.
///
/// Two rects, as before:
/// * the **panel** is the carrier. For a full-span bar it is the whole edge, which gives
///   the content view room to lay out and gives AppKit a window to constrain.
/// * the **chrome** is what the user actually sees. It is the panel inset by floating
///   margins, so a hugging bar floats clear of the edge while a full-span one sits flush.
struct BarPanelLayout: Equatable {
    var panel: CGRect
    var chrome: CGRect

    /// - Parameters:
    ///   - screenFrame: the display's full frame. The bar may sit in its corners and under
    ///     the menu bar's reserved strip.
    ///   - visibleFrame: the display minus the menu bar and dock. A hugging bar floats
    ///     inside this rather than hard against the physical edge.
    ///   - thickness: the bar's cross-axis size — its height on a bottom bar, its width on
    ///     a vertical one.
    ///   - contentLength: how long the contents would like to be, used only when hugging.
    ///   - endMargin: breathing room left at each end of a hugging bar.
    static func make(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        edge: BarEdge,
        span: BarSpan,
        thickness: CGFloat,
        contentLength: CGFloat,
        floatsClearOfEdge: Bool = false,
        endMargin: CGFloat = 8
    ) -> BarPanelLayout {
        let panel = BarGeometry.barFrame(
            screenFrame: screenFrame,
            visibleFrame: visibleFrame,
            edge: edge,
            span: span,
            thickness: thickness,
            contentLength: contentLength,
            floating: floatsClearOfEdge
        )

        return BarPanelLayout(panel: panel, chrome: inset(panel, edge: edge, span: span, floating: floatsClearOfEdge))
    }

    /// The chrome: the panel pulled in by the floating margins.
    ///
    /// Only a *floating* bar has margins. A full-span bar *is* the edge, and a hugging bar
    /// that is not floating is already inset from the edge by `BarGeometry`, so in both
    /// cases the chrome is the panel unchanged.
    private static func inset(_ frame: CGRect, edge: BarEdge, span: BarSpan, floating: Bool) -> CGRect {
        guard floating else { return frame }

        var result = frame
        switch edge {
        case .bottom:
            result.origin.y += BarGeometry.floatingInset
            result.size.height -= BarGeometry.floatingInset
        case .left:
            result.origin.x += BarGeometry.floatingInset
            result.size.width -= BarGeometry.floatingInset
        case .right:
            // A right-edge bar's *inner* edge is its left side, so the floating margin
            // comes off the width without moving the origin. Moving it left instead would
            // push the chrome past the panel's own edge and off the screen.
            result.size.width -= BarGeometry.floatingInset
        }
        return result
    }
}