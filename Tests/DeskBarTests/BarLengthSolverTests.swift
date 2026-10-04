import CoreGraphics
import Foundation
import Testing
@testable import DockBar

/// `BarLengthSolver` is ported from eskele to serve the vertical and mixed-width bars the
/// redesign adds. These tests pin the properties that make it better than a uniform cap:
/// floors are never violated, the surplus is shared in proportion to what each cell wanted,
/// and rows split evenly rather than greedily.
@Suite("Bar length solver")
struct BarLengthSolverTests {
    private func total(_ values: [CGFloat]) -> CGFloat {
        values.reduce(0, +)
    }

    // MARK: lengths

    @Test
    func noCellsGivesNoLengths() {
        #expect(BarLengthSolver.lengths(minimums: [], desired: [], available: 500).isEmpty)
    }

    @Test
    func everythingGetsItsCeilingWhenThereIsRoom() {
        let lengths = BarLengthSolver.lengths(minimums: [40, 40, 40], desired: [120, 200, 60], available: 1_000)
        #expect(lengths == [120, 200, 60])
    }

    @Test
    func exactlyEnoughRoomStillYieldsEveryCeiling() {
        let lengths = BarLengthSolver.lengths(minimums: [40, 40], desired: [120, 80], available: 200)
        #expect(lengths == [120, 80])
    }

    @Test
    func aTightBarSharesTheSurplusInProportionToWhatEachCellWanted() {
        // Floors 30 each (90 total); desires want 90, 60, 30 of growth (180 total).
        // 150 available leaves 60 of slack: a third each -> 30 + 30, 30 + 20, 30 + 10.
        let lengths = BarLengthSolver.lengths(minimums: [30, 30, 30], desired: [120, 90, 60], available: 150)

        #expect(abs(lengths[0] - 60) < 0.001)
        #expect(abs(lengths[1] - 50) < 0.001)
        #expect(abs(lengths[2] - 40) < 0.001)
        #expect(abs(total(lengths) - 150) < 0.001)
    }

    @Test
    func floorsAreNeverViolatedHoweverTightTheBarGets() {
        let lengths = BarLengthSolver.lengths(minimums: [50, 50, 50], desired: [200, 200, 200], available: 160)

        #expect(lengths.allSatisfy { $0 >= 50 })
        #expect(abs(total(lengths) - 160) < 0.001)
    }

    @Test
    func aBarTooShortForTheFloorsHandsBackTheFloorsUnchanged() {
        // Shrinking further would produce unreadable slivers, so the strip clips instead.
        let lengths = BarLengthSolver.lengths(minimums: [50, 50, 50], desired: [90, 90, 90], available: 100)
        #expect(lengths == [50, 50, 50])
    }

    @Test
    func aDesiredSmallerThanTheFloorIsRaisedToTheFloor() {
        let lengths = BarLengthSolver.lengths(minimums: [60, 60], desired: [10, 90], available: 1_000)
        #expect(lengths == [60, 90])
    }

    @Test
    func cellsThatWantNoExtraRoomKeepExactlyTheirFloor() {
        // One cell wants to grow, the other is already at its floor: all slack goes to the
        // first, and the second must not be handed slack it never asked for. 30 of floor
        // each leaves 30 of slack, and the first cell wants all of the growth, so it takes
        // all 30 — 60, not 90, because the bar only has 90 to give.
        let lengths = BarLengthSolver.lengths(minimums: [30, 30], desired: [130, 30], available: 90)

        #expect(abs(lengths[0] - 60) < 0.001)
        #expect(abs(lengths[1] - 30) < 0.001)
        #expect(abs(total(lengths) - 90) < 0.001)
    }

    @Test
    func aUniformBarIsUnchangedByTheSolver() {
        let lengths = BarLengthSolver.lengths(minimums: [40, 40, 40], desired: [100, 100, 100], available: 180)
        #expect(lengths.allSatisfy { abs($0 - 60) < 0.001 })
    }

    @Test
    func everySolvedLengthStaysWithinItsFloorAndCeiling() {
        let minimums: [CGFloat] = [30, 44, 28, 60, 36]
        let desired: [CGFloat] = [90, 44, 120, 75, 36]
        for available in stride(from: CGFloat(200), through: 400, by: 25) {
            let lengths = BarLengthSolver.lengths(minimums: minimums, desired: desired, available: available)
            for (index, length) in lengths.enumerated() {
                #expect(length >= minimums[index] - 0.001, "cell \(index) below its floor at \(available)")
                #expect(length <= Swift.max(minimums[index], desired[index]) + 0.001,
                        "cell \(index) above its ceiling at \(available)")
            }
        }
    }

    @Test
    func moreRoomNeverMakesACellSmaller() {
        // Monotonicity is what makes the bar's animation stable while windows open and close.
        let minimums: [CGFloat] = [30, 44, 28]
        let desired: [CGFloat] = [90, 60, 120]
        var previous = BarLengthSolver.lengths(minimums: minimums, desired: desired, available: 100)
        for available in stride(from: CGFloat(120), through: 400, by: 20) {
            let current = BarLengthSolver.lengths(minimums: minimums, desired: desired, available: available)
            for index in previous.indices {
                #expect(current[index] >= previous[index] - 0.001,
                        "cell \(index) shrank when the bar grew to \(available)")
            }
            previous = current
        }
    }

    // MARK: rows

    @Test
    func noCellsGivesNoRows() {
        #expect(BarLengthSolver.rows(minimums: [], desired: [], rows: 3).isEmpty)
    }

    @Test
    func aSingleRowKeepsEveryCellTogether() {
        #expect(BarLengthSolver.rows(minimums: [40, 40, 40], desired: [40, 40, 40], rows: 1) == [0..<3])
    }

    @Test
    func rowsAlwaysCoverEveryCellExactlyOnceInOrder() {
        let count = 17
        let ranges = BarLengthSolver.rows(
            minimums: Array(repeating: 30, count: count),
            desired: Array(repeating: 50, count: count),
            rows: 3
        )

        #expect(!ranges.isEmpty)
        #expect(ranges.count <= 3)
        #expect(ranges.first?.lowerBound == 0)
        #expect(ranges.last?.upperBound == count)
        for (previous, next) in zip(ranges, ranges.dropFirst()) {
            #expect(previous.upperBound == next.lowerBound, "rows must be contiguous")
        }
    }

    @Test
    func cellsAreSpreadEvenlyRatherThanPackedIntoTheFirstRows() {
        // Twenty identical cells over two rows: greedy filling would put fifteen in row one
        // and five in row two. An equal share gives ten and ten.
        let count = 20
        let ranges = BarLengthSolver.rows(
            minimums: Array(repeating: 30, count: count),
            desired: Array(repeating: 40, count: count),
            rows: 2
        )

        #expect(ranges == [0..<10, 10..<20])
    }

    @Test
    func aRowCountAboveTheCellCountStillCoversEveryCell() {
        // Nine rows were asked for and only two cells exist, so there is nothing to put nine
        // rows of. What matters is that the cells are still all placed, one per row, rather
        // than dropped or over-counted.
        let ranges = BarLengthSolver.rows(minimums: [30, 30], desired: [30, 30], rows: 9)

        #expect(ranges == [0..<1, 1..<2])
        #expect(ranges.count <= 9, "must never produce more rows than were asked for")
    }

    @Test
    func oneVeryWideCellDoesNotEmptyTheLastRow() {
        // A single huge cell must still land somewhere rather than being dropped.
        let ranges = BarLengthSolver.rows(minimums: [30, 30, 30], desired: [900, 30, 30], rows: 3)
        #expect(ranges.last?.upperBound == 3)
        #expect(!ranges.isEmpty)
    }

    @Test
    func rowsAndLengthsAgreeOnTheCellsEachRowGets() {
        // The two halves must not disagree: `rows` decides the split, `lengths` sizes it.
        let minimums: [CGFloat] = Array(repeating: 30, count: 12)
        let desired: [CGFloat] = Array(repeating: 60, count: 12)
        let ranges = BarLengthSolver.rows(minimums: minimums, desired: desired, rows: 2)
        let perRow = BarLengthSolver.lengths(
            minimums: Array(minimums[0..<6]),
            desired: Array(desired[0..<6]),
            available: 600
        )

        #expect(ranges.count == 2)
        #expect(perRow.count == ranges[0].count)
    }
}