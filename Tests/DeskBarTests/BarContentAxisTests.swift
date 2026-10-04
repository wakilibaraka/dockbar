import CoreGraphics
import Foundation
import Testing
@testable import DockBar

/// A bar on a side edge stacks down the screen; a bottom bar stacks across it. The panel
/// knew this before the content views did, so these tests pin the mapping from a style to
/// its content axis — getting it wrong lays a row of buttons down a vertical strip.
@Suite("Bar content axis")
struct BarContentAxisTests {
    @Test
    func theAxisFollowsTheEdge() {
        #expect(BarContentAxis.forEdge(.left) == .vertical)
        #expect(BarContentAxis.forEdge(.right) == .vertical)
        #expect(BarContentAxis.forEdge(.bottom) == .horizontal)
    }

    @Test
    func onlyEskeleRunsItsContentVertically() {
        let vertical = Set(
            TaskbarMode.allCases
                .filter { BarContentAxis.forSpec($0.spec).isVertical }
                .map(\.rawValue)
        )
        #expect(vertical == ["eskele"])
    }

    @Test
    func everyOtherStyleKeepsItsHorizontalBar() {
        // Custom leaves the edge to the user, but until that user picks a side the bar is
        // horizontal, and no other style may silently rotate.
        for mode in TaskbarMode.allCases where mode != .eskele {
            #expect(BarContentAxis.forSpec(mode.spec) == .horizontal, "\(mode.rawValue)")
        }
    }

    @Test
    func aHorizontalBarNeverWraps() {
        // A second line of task buttons is a different product from the single row people
        // expect, so a horizontal bar ignores the row setting entirely.
        for spec in [TaskbarStyleSpec.eskele, .classic, .hybrid, .custom] {
            #expect(BarContentAxis.rowCount(spec: spec, edge: .bottom, userChoice: 4) == 1)
        }
    }

    @Test
    func aVerticalBarStacksAsManyRowsAsAsked() {
        #expect(BarContentAxis.rowCount(spec: .eskele, edge: .left, userChoice: 3) == 3)
        // A nonsensical count must not produce an empty bar.
        #expect(BarContentAxis.rowCount(spec: .eskele, edge: .left, userChoice: 0) == 1)
        #expect(BarContentAxis.rowCount(spec: .eskele, edge: .left, userChoice: -2) == 1)
    }

    @Test
    func aHorizontalBarTakesTheSingleStackPath() {
        // `nil` means "keep the existing single-stack layout", so a horizontal bar must not
        // be pushed onto the general multi-row path it does not use.
        let rows = BarContentAxis.rows(
            minimums: [30, 30, 30],
            desired: [40, 40, 40],
            axis: .horizontal,
            rowCount: 3
        )
        #expect(rows == nil)
    }

    @Test
    func aSingleRowVerticalBarAlsoTakesTheSingleStackPath() {
        let rows = BarContentAxis.rows(
            minimums: [30, 30, 30],
            desired: [40, 40, 40],
            axis: .vertical,
            rowCount: 1
        )
        #expect(rows == nil)
    }

    @Test
    func aStackedVerticalBarSplitsItsCellsEvenly() {
        let rows = BarContentAxis.rows(
            minimums: Array(repeating: 30, count: 12),
            desired: Array(repeating: 60, count: 12),
            axis: .vertical,
            rowCount: 2
        )
        #expect(rows == [0..<6, 6..<12])
    }

    @Test
    func theRowsAlwaysCoverEveryCell() {
        for count in 1...20 {
            for rowCount in 2...4 {
                guard let rows = BarContentAxis.rows(
                    minimums: Array(repeating: 30, count: count),
                    desired: Array(repeating: 45, count: count),
                    axis: .vertical,
                    rowCount: rowCount
                ) else { continue }

                #expect(rows.first?.lowerBound == 0)
                #expect(rows.last?.upperBound == count)
                for (previous, next) in zip(rows, rows.dropFirst()) {
                    #expect(previous.upperBound == next.lowerBound)
                }
            }
        }
    }
}