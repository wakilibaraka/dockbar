import AppKit
import Testing
@testable import DockBar

// MARK: - Flyout placement

private let screen = NSRect(x: 0, y: 0, width: 1920, height: 1080)
private let spacing: CGFloat = 12

@Test
func flyoutOpensBelowItsAnchorWhenThereIsRoom() {
    // A taskbar widget sits along the bottom edge, so "below" here means toward the
    // middle of the screen; the anchor is given in screen coordinates.
    let anchor = NSRect(x: 900, y: 20, width: 80, height: 40)
    let placement = FlyoutLayout.placement(
        anchor: anchor,
        contentSize: NSSize(width: 320, height: 200),
        visibleFrame: screen,
        spacing: spacing
    )

    #expect(placement.opensAbove == false)
    #expect(placement.frame.minY == anchor.maxY + spacing)
    #expect(placement.frame.width == 320)
    #expect(placement.frame.height == 200)
    #expect(placement.frame.midX == anchor.midX)
}

@Test
func tallFlyoutFlipsAboveInsteadOfBeingSquashed() {
    // The regression this geometry exists for: a panel that does not fit below used to
    // have its height clamped, which crushed tall content (calendar, quick settings).
    let anchor = NSRect(x: 900, y: 900, width: 80, height: 40)
    let requested = NSSize(width: 320, height: 600)

    let placement = FlyoutLayout.placement(
        anchor: anchor,
        contentSize: requested,
        visibleFrame: screen,
        spacing: spacing
    )

    #expect(placement.opensAbove)
    // Full height preserved, not trimmed to whatever was left below.
    #expect(placement.frame.height == requested.height)
    #expect(placement.frame.maxY == anchor.minY - spacing)
}

@Test
func flyoutIsKeptInsideTheVisibleFrameHorizontally() {
    let leftEdge = FlyoutLayout.placement(
        anchor: NSRect(x: 10, y: 400, width: 40, height: 40),
        contentSize: NSSize(width: 300, height: 200),
        visibleFrame: screen,
        spacing: spacing
    )
    #expect(leftEdge.frame.minX >= screen.minX + spacing)

    let rightEdge = FlyoutLayout.placement(
        anchor: NSRect(x: 1890, y: 400, width: 40, height: 40),
        contentSize: NSSize(width: 300, height: 200),
        visibleFrame: screen,
        spacing: spacing
    )
    #expect(rightEdge.frame.maxX <= screen.maxX - spacing)
}

@Test
func flyoutNeverExceedsTheVisibleFrame() {
    let placement = FlyoutLayout.placement(
        anchor: NSRect(x: 900, y: 500, width: 80, height: 40),
        contentSize: NSSize(width: 4000, height: 3000),
        visibleFrame: screen,
        spacing: spacing
    )

    #expect(placement.frame.width <= screen.width - spacing * 2)
    #expect(placement.frame.height <= screen.height - spacing * 2)
    #expect(screen.contains(placement.frame))
}

@Test
func degenerateInputsStaySane() {
    // No displays, no content: must not produce NaN or an inverted rect.
    let noScreens = FlyoutLayout.placement(
        anchor: .zero,
        contentSize: .zero,
        visibleFrame: NSRect(x: 0, y: 0, width: 0, height: 0),
        spacing: spacing
    )
    #expect(noScreens.frame.width == 0)
    #expect(noScreens.frame.height == 0)

    let zeroContent = FlyoutLayout.placement(
        anchor: NSRect(x: 100, y: 100, width: 20, height: 20),
        contentSize: .zero,
        visibleFrame: screen,
        spacing: spacing
    )
    #expect(zeroContent.frame.width == 0)
}

// MARK: - Launcher affordance

@Test
func noStyleShowsTwoLaunchersAtOnce() {
    // The button and the zone are alternative launchers; a style showing both leaves a
    // duplicate control on the bar. This is pure logic through the strategy protocol.
    for mode in TaskbarMode.allCases {
        let zones = NSStackView()
        let button = NSView()
        let launcherZone = NSView()
        let insets = NSEdgeInsets(top: 4, left: 12, bottom: 4, right: 12)

        mode.strategy.applyModeLayout(
            zonesStackView: zones,
            launcherButtonView: button,
            launcherZoneView: launcherZone,
            defaultZoneEdgeInsets: insets
        )

        #expect(!(button.isHidden && launcherZone.isHidden), "\(mode) hides both launchers")
        #expect(!(!button.isHidden && !launcherZone.isHidden), "\(mode) shows two launchers")
    }
}