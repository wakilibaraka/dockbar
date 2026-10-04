import CoreGraphics

/// Distributes a bar's length across its cells.
///
/// Ported from eskele's `BarLayoutSolver`, because it solves a problem
/// `TaskbarWidthPlanner.uniformWidthCap` cannot: that planner binary-searches a *single* cap
/// and gives every button the same width, which is right for a horizontal bar of labelled
/// buttons. When the cells have genuinely different sizes — a vertical bar mixing icons and
/// expanded items, or a bar where one app has a long title and the rest do not — a uniform
/// cap either starves the wide cells or wastes room on the narrow ones. This shares the
/// surplus out in proportion to how much each cell wanted to grow, so buttons give up width
/// evenly and collapse to plain icons together rather than the last few vanishing while the
/// first stay full width.
///
/// Pure and separately testable: this is the part most likely to be wrong, and the axis a
/// vertical bar is laid out along.
enum BarLengthSolver {
    /// - Parameters:
    ///   - minimums: each cell's icon-only extent. Never violated.
    ///   - desired: what each cell would take if the bar were unbounded. Raised to the
    ///     matching minimum when smaller, so a bad caller cannot ask for less than the floor.
    ///   - available: the extent the cells share, excluding the bar's own end padding.
    static func lengths(minimums: [CGFloat], desired: [CGFloat], available: CGFloat) -> [CGFloat] {
        precondition(minimums.count == desired.count, "one minimum per cell")
        guard !minimums.isEmpty else { return [] }

        let ceilings = zip(minimums, desired).map { Swift.max($0, $1) }
        let desiredTotal = ceilings.reduce(0, +)
        if desiredTotal <= available { return ceilings }

        let floorTotal = minimums.reduce(0, +)
        // Even the floors do not fit. Overflow is the caller's problem — the strip clips —
        // because shrinking below the icon size would only produce unreadable slivers.
        guard available > floorTotal else { return minimums }

        let growthWanted = zip(ceilings, minimums).map { $0 - $1 }
        let totalGrowth = growthWanted.reduce(0, +)
        guard totalGrowth > 0 else { return minimums }

        let slack = available - floorTotal
        return zip(minimums, growthWanted).map { minimum, growth in
            minimum + slack * (growth / totalGrowth)
        }
    }

    /// Splits the cells into rows, in order, one contiguous run per row.
    ///
    /// Every row aims at an equal share of the total, and nothing else. The bar is as many
    /// rows thick as the user asked for whether or not the cells need them all, so filling
    /// each row before starting the next would leave a three-row bar showing one row of icons
    /// and two empty strips.
    ///
    /// Deliberately blind to how long the bar actually is. Wrapping at the bar's length instead
    /// would give thirty cells on a two-row bar ten comfortable ones and twenty crammed into
    /// what was left; an equal share gives fifteen and fifteen, squeezed alike. A row that
    /// comes out longer than the bar is `lengths`' problem, which is what `lengths` is for.
    ///
    /// - Returns: one range per row, covering the cells in order. Never more than `rowCount`
    ///   ranges, and fewer when there are not enough cells to go round.
    static func rows(minimums: [CGFloat], desired: [CGFloat], rows rowCount: Int) -> [Range<Int>] {
        precondition(minimums.count == desired.count, "one minimum per cell")
        let count = minimums.count
        guard count > 0 else { return [] }
        guard rowCount > 1 else { return [0..<count] }

        let ceilings = zip(minimums, desired).map { Swift.max($0, $1) }
        let target = ceilings.reduce(0, +) / CGFloat(rowCount)

        var result: [Range<Int>] = []
        var start = 0
        var length: CGFloat = 0
        for index in 0..<count {
            let ceiling = ceilings[index]
            // Rounding rather than truncation: a cell is taken when it leaves the row closer to
            // the target than leaving it out would. Truncating alone packs the early rows and
            // leaves the last one carrying everything that did not fit.
            let overshoots = (length + ceiling - target) > (target - length)
            let isLastRow = result.count == rowCount - 1
            // A row that already holds something can wrap; an empty one takes the cell whatever
            // its size, because it has to go somewhere. The last row keeps the remainder for
            // the same reason: there is nowhere else to put it.
            if !isLastRow, index > start, overshoots {
                result.append(start..<index)
                start = index
                length = 0
            }
            length += ceiling
        }
        result.append(start..<count)
        return result
    }
}