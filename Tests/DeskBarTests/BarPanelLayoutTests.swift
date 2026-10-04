import CoreGraphics
import Foundation
import Testing
@testable import DockBar

/// `BarPanelLayout` is what makes a vertical bar possible: `TaskbarPanel`'s own arithmetic
/// could only ever place a strip along the bottom. These tests pin the rects for all three
/// edges, because getting them wrong means the bar is off-screen or windows hide under it.
@Suite("Bar panel layout")
struct BarPanelLayoutTests {
    /// A 1600x1000 display whose menu bar takes 24pt off the top.
    private let screenFrame = CGRect(x: 0, y: 0, width: 1600, height: 1000)
    private var visibleFrame: CGRect { CGRect(x: 0, y: 0, width: 1600, height: 976) }
    private let thickness: CGFloat = 48
    private let contentLength: CGFloat = 300

    private func layout(
        edge: BarEdge,
        span: BarSpan,
        floating: Bool = false,
        on screenFrame: CGRect? = nil,
        visible: CGRect? = nil
    ) -> BarPanelLayout {
        BarPanelLayout.make(
            screenFrame: screenFrame ?? self.screenFrame,
            visibleFrame: visible ?? visibleFrame,
            edge: edge,
            span: span,
            thickness: thickness,
            contentLength: contentLength,
            floatsClearOfEdge: floating
        )
    }

    @Test
    func aFullSpanBottomBarRunsTheWidthOfTheScreen() {
        let result = layout(edge: .bottom, span: .fullSpan)
        #expect(result.panel == CGRect(x: 0, y: 0, width: 1600, height: 48))
    }

    @Test
    func aFullSpanVerticalBarRunsTheHeightOfTheScreen() {
        let left = layout(edge: .left, span: .fullSpan)
        #expect(left.panel == CGRect(x: 0, y: 0, width: 48, height: 1000))

        let right = layout(edge: .right, span: .fullSpan)
        #expect(right.panel == CGRect(x: 1552, y: 0, width: 48, height: 1000))
    }

    @Test
    func aVerticalBarsThicknessIsItsWidth() {
        // The whole point of the change: the bar's cross-axis size is its width, so the
        // height the user set is what makes it 48pt wide.
        for span in [BarSpan.fullSpan, .hugContents] {
            #expect(layout(edge: .left, span: span).panel.width == thickness, "\(span)")
            #expect(layout(edge: .right, span: span).panel.width == thickness, "\(span)")
        }
    }

    @Test
    func aVerticalBarIsOnlyAsLongAsItsContents() {
        let hugging = layout(edge: .left, span: .hugContents)
        #expect(hugging.panel.height == contentLength)
        #expect(hugging.panel.height < screenFrame.height)
    }

    @Test
    func aHuggingVerticalBarSitsFlushUnlessItIsFloating() {
        // Flush means flush: it starts at the edge with no margin of its own. Floating is
        // the only case that gets an inset, and it centres along the edge rather than
        // hanging from the top, because a free-floating pill reads wrong anchored up.
        let hugging = layout(edge: .left, span: .hugContents)
        #expect(hugging.panel.minY == visibleFrame.minY)

        let floating = layout(edge: .left, span: .hugContents, floating: true)
        #expect(floating.panel.minY >= visibleFrame.minY + BarGeometry.floatingInset)
        #expect(abs(floating.panel.midY - visibleFrame.midY) < 0.001)
    }

    @Test
    func aVerticalBarNeverCentresUnderTheMenuBar() {
        let hugging = layout(edge: .left, span: .hugContents)
        #expect(hugging.panel.minY >= visibleFrame.minY)
        #expect(hugging.panel.maxY <= visibleFrame.maxY)
    }

    @Test
    func aFullSpanBarHasNoChromeInset() {
        // A full-span bar *is* the edge, so there is nothing to float clear of.
        for edge in BarEdge.allCases {
            let result = layout(edge: edge, span: .fullSpan)
            #expect(result.chrome == result.panel, "\(edge.displayName)")
        }
    }

    @Test
    func aFloatingBarIsInsetFromItsEdge() {
        let floating = layout(edge: .bottom, span: .hugContents, floating: true)
        #expect(floating.chrome.minY > floating.panel.minY)
        #expect(floating.chrome.height == floating.panel.height - BarGeometry.floatingInset)

        let vertical = layout(edge: .left, span: .hugContents, floating: true)
        #expect(vertical.chrome.minX > vertical.panel.minX)
        #expect(vertical.chrome.width == vertical.panel.width - BarGeometry.floatingInset)
    }

    @Test
    func aRightHandFloatingBarInsetsFromItsInnerEdge() {
        // The margin comes off the bar's inner (left) side. The panel already sits inset
        // from the screen edge by `BarGeometry`, so the chrome ends a further inset short
        // of the screen and never grows past the panel it lives in.
        let floating = layout(edge: .right, span: .hugContents, floating: true)
        #expect(floating.chrome.minX == floating.panel.minX)
        #expect(floating.chrome.width == floating.panel.width - BarGeometry.floatingInset)
        #expect(floating.chrome.maxX < floating.panel.maxX)
        #expect(floating.chrome.maxX <= screenFrame.maxX)
    }

    @Test
    func theChromeNeverEscapesThePanel() {
        for edge in BarEdge.allCases {
            for span in BarSpan.allCases {
                for floating in [true, false] {
                    let result = layout(edge: edge, span: span, floating: floating)
                    let panel = result.panel
                    let chrome = result.chrome
                    #expect(chrome.minX >= panel.minX - 0.001, "\(edge) \(span) \(floating) x")
                    #expect(chrome.maxX <= panel.maxX + 0.001, "\(edge) \(span) \(floating) x")
                    #expect(chrome.minY >= panel.minY - 0.001, "\(edge) \(span) \(floating) y")
                    #expect(chrome.maxY <= panel.maxY + 0.001, "\(edge) \(span) \(floating) y")
                }
            }
        }
    }

    @Test
    func theBarStaysOnItsDisplay() {
        // A bar on a secondary display must be placed in that display's coordinates, not
        // the primary one's.
        let secondaryScreen = CGRect(x: 1600, y: 0, width: 1200, height: 800)
        let secondaryVisible = CGRect(x: 1600, y: 0, width: 1200, height: 776)
        let right = BarPanelLayout.make(
            screenFrame: secondaryScreen,
            visibleFrame: secondaryVisible,
            edge: .right,
            span: .fullSpan,
            thickness: thickness,
            contentLength: contentLength
        )
        #expect(right.panel.maxX == secondaryScreen.maxX)
        #expect(right.panel.minX >= secondaryScreen.minX)
    }
}