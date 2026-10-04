import AppKit

/// The project's visual constants, in one place.
///
/// These used to be scattered literals: `14` for the flyout corner radius, `10` in
/// three different card styles, `44` for the bar height in several files. Centralising
/// them is what makes "rounder flyouts" a one-line change instead of a hunt.
enum DesignSystem {
    // MARK: Metrics

    enum Metrics {
        /// Default bar height in points.
        static let barHeight: CGFloat = 44

        /// Corner radius of the bar itself, which grows with its height so a tall bar
        /// does not look pinched.
        static func barCornerRadius(forHeight height: CGFloat) -> CGFloat {
            min(height / 2, 14)
        }

        /// Task buttons are inset from the bar's edges by this much.
        static let barContentInset: CGFloat = 8

        /// Gap between a task button and the next one.
        static let taskSpacing: CGFloat = 4

        /// Below this width a task button drops its title and shows the icon alone.
        static let minimumWidthForTitle: CGFloat = 120

        /// Width of an icon-only task button.
        static let iconOnlyTaskWidth: CGFloat = 48

        /// Padding added to the bar height for an icon-only button.
        static let iconOnlyInset: CGFloat = 8

        /// Width of the gap between the window cluster and the widget cluster.
        static let widgetClusterSpacing: CGFloat = 12

        /// Inner padding of a flyout.
        static let flyoutPadding: CGFloat = 12

        /// Height of a widget view hosted in a menu bar status item.
        static let menuBarItemHeight: CGFloat = 22
    }

    // MARK: Shape

    enum Shape {
        /// Flyouts are rounded rectangles with no pointer, so the outline reads as one
        /// continuous shape. See `FlyoutLayout` for placement.
        static let flyoutCornerRadius: CGFloat = 14

        /// Group boxes, cards, and menu items.
        static let cardCornerRadius: CGFloat = 10

        /// Widgets and other small pills on the bar.
        static let chipCornerRadius: CGFloat = 7

        /// Buttons inside the settings window.
        static let controlCornerRadius: CGFloat = 6

        /// Stroke width for card and flyout outlines.
        static let hairline: CGFloat = 1
    }

    // MARK: Motion

    enum Motion {
        /// Hover thumbnails and popovers: long enough to not flicker, short enough to
        /// feel instant.
        static let hoverReveal: TimeInterval = 0.12

        /// Closing a flyout is faster than opening it, which reads as responsive.
        static let flyoutDismiss: TimeInterval = 0.10

        /// Windows-style bars wait a beat after activating a group before showing the
        /// window picker, so the click that activated the window is not eaten by it.
        static let groupedPreviewDelay: TimeInterval = 0.1

        /// The window switcher holds for this long before it steps to the next window.
        static let windowSwitcherHold: TimeInterval = 0.35
    }

    // MARK: Colour

    /// The alpha values used for task button states. They used to be re-typed per
    /// strategy, which is why the styles drifted apart visually.
    enum State {
        static func activeFill(isActive: Bool, emphasis: CGFloat) -> NSColor? {
            isActive ? NSColor.controlAccentColor.withAlphaComponent(emphasis) : nil
        }

        /// Orange, because attention is not an error but it is time-sensitive.
        static let attention = NSColor.systemOrange

        static func hoverFill(alpha: CGFloat) -> NSColor {
            NSColor.labelColor.withAlphaComponent(alpha)
        }
    }
}