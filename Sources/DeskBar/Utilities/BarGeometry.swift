import CoreGraphics
import Foundation

/// Where the bar sits on a screen, and how much room it takes.
///
/// Pure and free of AppKit so every rule here is unit-testable, which matters because
/// this is the part that fails invisibly: a bar on the wrong edge reserves space on the
/// wrong side, and windows quietly end up underneath it.
enum BarGeometry {
    /// How far a hugging bar floats clear of its edge.
    static let floatingInset: CGFloat = 8

    /// The bar's own rect.
    ///
    /// `screenFrame` rather than the visible frame, because the bar is allowed to sit
    /// under the menu bar's reserved strip and in the corners; only the size and the
    /// edge it hugs come from `visibleFrame`.
    ///
    /// A full-span bar covers the whole edge. A hugging bar is `contentLength` long,
    /// centred on a horizontal edge and hugging the inner edge on a vertical one, so a
    /// left-edge bar's buttons grow away from the screen and a right-edge bar's grow
    /// toward it.
    static func barFrame(
        screenFrame: CGRect,
        visibleFrame: CGRect,
        edge: BarEdge,
        span: BarSpan,
        thickness: CGFloat,
        contentLength: CGFloat,
        floating: Bool = false
    ) -> CGRect {
        let inset = floating ? floatingInset : 0
        let size = max(thickness, 0)

        switch (edge, span) {
        case (.bottom, .fullSpan):
            return CGRect(x: screenFrame.minX, y: screenFrame.minY, width: screenFrame.width, height: size)

        case (.bottom, .hugContents):
            let length = min(max(contentLength, size), visibleFrame.width)
            let x = floating
                ? visibleFrame.midX - length / 2
                : visibleFrame.minX + inset
            let y = floating
                ? visibleFrame.minY + inset
                : screenFrame.minY
            return CGRect(x: x, y: y, width: length, height: size)

        case (.left, .fullSpan):
            return CGRect(x: screenFrame.minX, y: screenFrame.minY, width: size, height: screenFrame.height)

        case (.left, .hugContents):
            let length = min(max(contentLength, size), visibleFrame.height)
            let x = floating ? visibleFrame.minX + inset : screenFrame.minX
            let y = floating ? visibleFrame.midY - length / 2 : visibleFrame.minY + inset
            return CGRect(x: x, y: y, width: size, height: length)

        case (.right, .fullSpan):
            return CGRect(
                x: screenFrame.maxX - size,
                y: screenFrame.minY,
                width: size,
                height: screenFrame.height
            )

        case (.right, .hugContents):
            let length = min(max(contentLength, size), visibleFrame.height)
            let x = floating ? visibleFrame.maxX - size - inset : screenFrame.maxX - size
            let y = floating ? visibleFrame.midY - length / 2 : visibleFrame.minY + inset
            return CGRect(x: x, y: y, width: size, height: length)
        }
    }

    /// The strip of the display the bar occupies, which windows must be kept out of.
    ///
    /// A full-span bar reserves a strip along its whole edge. A hugging bar reserves
    /// nothing: it floats over the desktop and takes no space away from anything, which
    /// is the whole point of choosing it.
    static func reservedInsets(
        barFrame: CGRect,
        edge: BarEdge,
        span: BarSpan
    ) -> EdgeInsets {
        guard span == .fullSpan else { return EdgeInsets() }

        switch edge {
        case .bottom:
            return EdgeInsets(bottom: barFrame.height)
        case .left:
            return EdgeInsets(left: barFrame.width)
        case .right:
            return EdgeInsets(right: barFrame.width)
        }
    }

    /// Shifts, and only if it must shrinks, a window so it does not sit under a
    /// full-span bar.
    ///
    /// Moving is always tried first, because a window that keeps its size when nudged
    /// out from under the bar is less disruptive than one that is resized. Shrinking is
    /// the fallback for a window too big to simply move.
    ///
    /// Returns `nil` when nothing needs to change, and when the window could not be made
    /// usable at all — a sliver is worse than a window overlapping the bar.
    static func frameAvoidingBar(
        _ frame: CGRect,
        displayBounds: CGRect,
        reserved: EdgeInsets,
        minimumRemainingLength: CGFloat = 100
    ) -> CGRect? {
        guard !reserved.isEmpty else { return nil }

        let allowed = CGRect(
            x: displayBounds.minX + reserved.left,
            y: displayBounds.minY + reserved.bottom,
            width: displayBounds.width - reserved.left - reserved.right,
            height: displayBounds.height - reserved.bottom - reserved.top
        )
        guard allowed.width >= minimumRemainingLength,
              allowed.height >= minimumRemainingLength
        else { return nil }

        // Already clear of the bar: leave the window exactly where it is.
        guard !allowed.contains(frame) else { return nil }

        // Preferred fix: keep the size, slide the window into the allowed area.
        var moved = frame
        if moved.maxX > allowed.maxX { moved.origin.x = allowed.maxX - frame.width }
        if moved.minX < allowed.minX { moved.origin.x = allowed.minX }
        if moved.maxY > allowed.maxY { moved.origin.y = allowed.maxY - frame.height }
        if moved.minY < allowed.minY { moved.origin.y = allowed.minY }
        if allowed.contains(moved) { return moved }

        // Too big to move: shrink to fit, never past the minimum.
        var shrunk = frame
        shrunk.size.width = min(frame.width, allowed.width)
        shrunk.size.height = min(frame.height, allowed.height)
        guard shrunk.width >= minimumRemainingLength,
              shrunk.height >= minimumRemainingLength
        else { return nil }

        shrunk.origin.x = min(max(shrunk.minX, allowed.minX), allowed.maxX - shrunk.width)
        shrunk.origin.y = min(max(shrunk.minY, allowed.minY), allowed.maxY - shrunk.height)

        return shrunk == frame ? nil : shrunk
    }
}

/// Insets that are not `NSEdgeInsets`, so the geometry rules stay testable without AppKit.
struct EdgeInsets: Equatable, Sendable {
    var top: CGFloat = 0
    var left: CGFloat = 0
    var bottom: CGFloat = 0
    var right: CGFloat = 0

    static let zero = EdgeInsets()

    var isEmpty: Bool { self == .zero }
}