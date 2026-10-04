import AppKit

/// Pure geometry for taskbar flyouts.
///
/// Taskbar flyouts are plain, corner-continuous rounded rectangles with no notch or
/// pointer (menu-bar panels are the ones allowed to carry one), so all this needs to
/// decide is where the rectangle goes. It is deliberately free of AppKit state: the
/// rules are unit-tested, and `BorderlessFlyout` only applies the result.
enum FlyoutLayout {
    struct Placement: Equatable {
        let frame: NSRect
        /// True when the panel had to open above its anchor instead of below.
        let opensAbove: Bool
    }

    /// Places a flyout next to `anchor`, preferring below, flipping above when it would
    /// not fit, and clamping inside the visible frame only as a last resort.
    ///
    /// The clamp is the important part: the previous implementation shrank the panel's
    /// height when it ran out of room, which squashed tall panels (calendar, quick
    /// settings) instead of moving them.
    static func placement(
        anchor: NSRect,
        contentSize: NSSize,
        visibleFrame: NSRect,
        spacing: CGFloat = 12
    ) -> Placement {
        let maxWidth = max(visibleFrame.width - spacing * 2, 0)
        let maxHeight = max(visibleFrame.height - spacing * 2, 0)
        let width = min(max(contentSize.width, 0), maxWidth)
        let height = min(max(contentSize.height, 0), maxHeight)

        let minX = visibleFrame.minX + spacing
        let maxX = visibleFrame.maxX - spacing - width
        let originX = min(max(anchor.midX - width / 2, minX), max(maxX, minX))

        let belowY = anchor.maxY + spacing
        let aboveY = anchor.minY - spacing - height

        if belowY + height <= visibleFrame.maxY - spacing {
            return Placement(
                frame: NSRect(x: originX, y: belowY, width: width, height: height),
                opensAbove: false
            )
        }

        if aboveY >= visibleFrame.minY + spacing {
            return Placement(
                frame: NSRect(x: originX, y: aboveY, width: width, height: height),
                opensAbove: true
            )
        }

        // Neither side fits (very tall panel): keep the requested height inside the
        // visible frame rather than squashing it further.
        let clampedY = min(max(belowY, visibleFrame.minY + spacing), visibleFrame.maxY - spacing - height)
        return Placement(
            frame: NSRect(x: originX, y: clampedY, width: width, height: height),
            opensAbove: false
        )
    }
}