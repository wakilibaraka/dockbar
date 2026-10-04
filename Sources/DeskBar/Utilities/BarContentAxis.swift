import CoreGraphics
import Foundation

/// Which way a bar's contents stack.
///
/// A bar on the left or right edge runs its cells down the screen, so its zones and task
/// buttons stack vertically and its buttons are sized by *height*; a bottom bar does the
/// opposite. The panel's geometry already knows which edge the bar is on, but the views
/// inside it were written for one axis only, so the choice is made once here rather than
/// re-derived at each call site.
///
/// Pure, because picking the wrong axis is invisible in a build and obvious on screen.
enum BarContentAxis: Equatable {
    case horizontal
    case vertical

    var isVertical: Bool { self == .vertical }

    /// The axis a bar on `edge` runs along.
    static func forEdge(_ edge: BarEdge) -> BarContentAxis {
        edge.axis.isVertical ? .vertical : .horizontal
    }

    /// The axis this style lays its content out on, given the style's edge.
    static func forSpec(_ spec: TaskbarStyleSpec) -> BarContentAxis {
        forEdge(spec.resolvedEdge(userChoice: .bottom))
    }

    /// The rows the bar's cells occupy.
    ///
    /// A horizontal bar is always one row: wrapping it would mean a second line of task
    /// buttons, which is a different product from the single row people expect. A vertical
    /// bar may stack several, and how many is the user's choice — but a style has to opt
    /// in first, because a strip down the side of the screen that silently reflows into
    /// three columns is not what anyone asked for.
    static func rowCount(spec: TaskbarStyleSpec, edge: BarEdge, userChoice: Int) -> Int {
        spec.resolvedRowCount(userChoice: userChoice, edge: edge)
    }

    /// Splits the bar's cells into rows along `axis`.
    ///
    /// Returns `nil` for a single row so callers can keep their existing single-stack path
    /// rather than paying for a general case they do not use.
    static func rows(
        minimums: [CGFloat],
        desired: [CGFloat],
        axis: BarContentAxis,
        rowCount: Int
    ) -> [Range<Int>]? {
        switch axis {
        case .horizontal:
            return nil
        case .vertical:
            guard rowCount > 1 else { return nil }
            return BarLengthSolver.rows(minimums: minimums, desired: desired, rows: rowCount)
        }
    }
}