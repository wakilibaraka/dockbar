import CoreGraphics
import Foundation
import Testing
@testable import DockBar

/// The bar can now sit on any edge, so the rules that place it and reserve the space it
/// occupies need pinning on all three, not just the bottom.
struct BarGeometryTests {
    // A 1000x600 display. The menu bar eats 25pt off the top of the usable area, so the
    // visible frame is shorter than the screen frame but starts at the same y.
    private let screen = CGRect(x: 0, y: 0, width: 1000, height: 600)
    private let visible = CGRect(x: 0, y: 0, width: 1000, height: 575)
    private let thickness: CGFloat = 48

    private func frame(
        edge: BarEdge,
        span: BarSpan,
        contentLength: CGFloat = 300,
        floating: Bool = false
    ) -> CGRect {
        BarGeometry.barFrame(
            screenFrame: screen,
            visibleFrame: visible,
            edge: edge,
            span: span,
            thickness: thickness,
            contentLength: contentLength,
            floating: floating
        )
    }

    // MARK: Full-span frames

    @Test
    func aFullSpanBarCoversItsWholeEdge() {
        let bottom = frame(edge: .bottom, span: .fullSpan)
        #expect(bottom == CGRect(x: 0, y: 0, width: 1000, height: 48))

        let left = frame(edge: .left, span: .fullSpan)
        #expect(left == CGRect(x: 0, y: 0, width: 48, height: 600))

        let right = frame(edge: .right, span: .fullSpan)
        #expect(right == CGRect(x: 952, y: 0, width: 48, height: 600))
    }

    @Test
    func verticalBarsAreSquareToTheirEdge() {
        for edge in [BarEdge.left, .right] {
            let rect = frame(edge: edge, span: .fullSpan)
            #expect(rect.width == thickness, "\(edge) bar should be as wide as it is thick")
        }
        let bottom = frame(edge: .bottom, span: .fullSpan)
        #expect(bottom.height == thickness, "a bottom bar should be as tall as it is thick")
    }

    // MARK: Hugging frames

    @Test
    func aHuggingBottomBarIsOnlyAsLongAsItsContents() {
        let rect = frame(edge: .bottom, span: .hugContents, contentLength: 300)
        #expect(rect.width == 300)
        #expect(rect.height == thickness)
        #expect(rect.minY == visible.minY)
    }

    @Test
    func aHuggingVerticalBarIsOnlyAsLongAsItsContents() {
        let rect = frame(edge: .left, span: .hugContents, contentLength: 300)
        #expect(rect.height == 300)
        #expect(rect.width == thickness)
        #expect(rect.minY == visible.minY)
    }

    @Test
    func aHuggingBarNeverOutgrowsTheUsableArea() {
        let rect = frame(edge: .left, span: .hugContents, contentLength: 5000)
        #expect(rect.height <= visible.height, "a left bar cannot be taller than the screen")
        #expect(rect.height == visible.height)

        let bottom = frame(edge: .bottom, span: .hugContents, contentLength: 5000)
        #expect(bottom.width <= visible.width)
    }

    @Test
    func aHuggingBarIsNeverShorterThanItsOwnThickness() {
        // A bar with two buttons should still read as a bar, not a sliver.
        let rect = frame(edge: .bottom, span: .hugContents, contentLength: 4)
        #expect(rect.width == thickness)
    }

    @Test
    func aFloatingBarCentresOnTheVisibleArea() {
        let rect = frame(edge: .bottom, span: .hugContents, contentLength: 300, floating: true)
        #expect(abs(rect.midX - visible.midX) < 0.5)
        #expect(rect.minY == visible.minY + BarGeometry.floatingInset)

        let left = frame(edge: .left, span: .hugContents, contentLength: 300, floating: true)
        #expect(abs(left.midY - visible.midY) < 0.5)
        #expect(left.minX == visible.minX + BarGeometry.floatingInset)
    }

    // MARK: Reserved space

    @Test
    func aFullSpanBarReservesAStripAlongItsEdge() {
        let bottom = BarGeometry.reservedInsets(
            barFrame: frame(edge: .bottom, span: .fullSpan), edge: .bottom, span: .fullSpan)
        #expect(bottom == EdgeInsets(bottom: 48))
        #expect(bottom.top == 0 && bottom.left == 0 && bottom.right == 0)

        let left = BarGeometry.reservedInsets(
            barFrame: frame(edge: .left, span: .fullSpan), edge: .left, span: .fullSpan)
        #expect(left == EdgeInsets(left: 48))

        let right = BarGeometry.reservedInsets(
            barFrame: frame(edge: .right, span: .fullSpan), edge: .right, span: .fullSpan)
        #expect(right == EdgeInsets(right: 48))
    }

    @Test
    func aHuggingBarReservesNothing() {
        // The point of hugging: it floats over the desktop and steals no space.
        for edge in BarEdge.allCases {
            let insets = BarGeometry.reservedInsets(
                barFrame: frame(edge: edge, span: .hugContents), edge: edge, span: .hugContents)
            #expect(insets.isEmpty, "\(edge) hugging bar should reserve nothing")
        }
    }

    // MARK: Window avoidance

    @Test
    func aWindowOverTheBarIsLiftedAboveItAtFullSize() {
        // Moving is preferred over resizing: a nudged window keeps its size.
        let window = CGRect(x: 100, y: 10, width: 800, height: 500)
        let adjusted = try? #require(
            BarGeometry.frameAvoidingBar(window, displayBounds: screen, reserved: EdgeInsets(bottom: 48))
        )
        #expect(adjusted?.minY == 48)
        #expect(adjusted?.height == 500, "lifting a window should not resize it")
    }

    @Test
    func aWindowTooTallToMoveIsShrunkInstead() {
        // 560 tall will not fit in the 552 above a 48pt bottom bar, so it must shrink.
        let window = CGRect(x: 100, y: 0, width: 800, height: 560)
        let adjusted = try? #require(
            BarGeometry.frameAvoidingBar(window, displayBounds: screen, reserved: EdgeInsets(bottom: 48))
        )
        #expect(adjusted?.height == 552)
        #expect(adjusted?.maxY == 600)
    }

    @Test
    func aWindowBesideAVerticalBarIsPushedInwards() {
        // A 900pt window slides clear of a 48pt bar on either side without resizing.
        let leftAdjusted = try? #require(
            BarGeometry.frameAvoidingBar(
                CGRect(x: 0, y: 100, width: 900, height: 400),
                displayBounds: screen,
                reserved: EdgeInsets(left: 48)
            )
        )
        #expect(leftAdjusted?.minX == 48)
        #expect(leftAdjusted?.width == 900, "sliding in from the left should not resize")

        let rightAdjusted = try? #require(
            BarGeometry.frameAvoidingBar(
                CGRect(x: 100, y: 100, width: 900, height: 400),
                displayBounds: screen,
                reserved: EdgeInsets(right: 48)
            )
        )
        #expect(rightAdjusted?.maxX == 952)
        #expect(rightAdjusted?.width == 900, "sliding in from the right should not resize")
    }

    @Test
    func aWindowWiderThanTheSpaceLeftShrinksToFit() {
        // 980pt will not fit in the 952pt a right-hand bar leaves, so it must shrink.
        let adjusted = try? #require(
            BarGeometry.frameAvoidingBar(
                CGRect(x: 0, y: 100, width: 980, height: 400),
                displayBounds: screen,
                reserved: EdgeInsets(right: 48)
            )
        )
        #expect(adjusted?.width == 952)
        #expect(adjusted?.maxX == 952)
    }

    @Test
    func aWindowClearOfTheBarIsLeftAlone() {
        let window = CGRect(x: 100, y: 100, width: 400, height: 300)
        #expect(
            BarGeometry.frameAvoidingBar(window, displayBounds: screen, reserved: EdgeInsets(bottom: 48)) == nil
        )
        #expect(
            BarGeometry.frameAvoidingBar(window, displayBounds: screen, reserved: EdgeInsets()) == nil
        )
    }

    @Test
    func aWindowTooBigToSalvageIsLeftWhereItIs() {
        // Reserving 800pt leaves 200pt of usable width; shrinking a 900pt window to that
        // would still leave it overlapping, and anything under the minimum is worse than
        // an overlap.
        let window = CGRect(x: 0, y: 0, width: 900, height: 120)
        #expect(
            BarGeometry.frameAvoidingBar(
                window,
                displayBounds: screen,
                reserved: EdgeInsets(left: 800),
                minimumRemainingLength: 300
            ) == nil
        )
    }

    @Test
    func aBarWiderThanTheDisplayReservesNothing() {
        // Pathological but reachable on a small display: there is no room left to work
        // with, so the window is left alone rather than shoved off screen.
        let window = CGRect(x: 0, y: 100, width: 400, height: 300)
        #expect(
            BarGeometry.frameAvoidingBar(
                window, displayBounds: screen, reserved: EdgeInsets(left: 960)
            ) == nil
        )
    }

    @Test
    func avoidanceRespectsTheDisplaysOwnBounds() {
        // A second display offset to the right must not be adjusted in the first one's
        // coordinates.
        let second = CGRect(x: 1000, y: 0, width: 1000, height: 600)
        let window = CGRect(x: 1000, y: 0, width: 900, height: 500)
        let adjusted = BarGeometry.frameAvoidingBar(
            window, displayBounds: second, reserved: EdgeInsets(left: 48))
        #expect(adjusted?.minX == 1048)
    }
}