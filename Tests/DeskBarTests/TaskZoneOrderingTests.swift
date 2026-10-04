import Foundation
import Testing
@testable import DockBar

/// `TaskZoneOrderingState` keeps the user's manual ordering stable while windows come and
/// go. It was private to a 3,700-line file and so had no coverage at all; these tests
/// pin the behaviour the bar relies on.
struct TaskZoneOrderingTests {
    @Test
    func withoutAnyManualOrderingTheOriginalOrderIsPreserved() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b", "c"])
        #expect(state.arrangedIDs(for: ["a", "b", "c"]) == ["a", "b", "c"])
    }

    @Test
    func aManuallyPositionedItemLandsWhereItWasDropped() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b", "c"])
        // The user drags "c" to the front.
        state.applyManualOrder(["c", "a", "b"], userPositionedItemID: "c")

        #expect(state.arrangedIDs(for: ["a", "b", "c"]) == ["c", "a", "b"])
    }

    @Test
    func aNewlyOpenedWindowAppendsRatherThanDisplacingTheRest() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b"])
        state.applyManualOrder(["a", "b"], userPositionedItemID: "a")

        state.reconcile(currentIDs: ["a", "b", "new"])
        let arranged = state.arrangedIDs(for: ["a", "b", "new"])
        #expect(arranged.count == 3)
        #expect(Set(arranged) == ["a", "b", "new"])
        #expect(arranged.first == "a", "the manually positioned item should stay put")
        #expect(arranged.last == "new", "the new window should land at the end")
    }

    @Test
    func closingAWindowDoesNotDisturbTheRest() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b", "c"])
        state.applyManualOrder(["c", "b", "a"], userPositionedItemID: "c")

        state.reconcile(currentIDs: ["a", "c"])
        #expect(state.arrangedIDs(for: ["a", "c"]) == ["c", "a"])
    }

    @Test
    func aWindowThatReopensWithinTheGraceWindowKeepsItsPlace() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b", "c"])
        state.applyManualOrder(["c", "a", "b"], userPositionedItemID: "c")

        // "c" goes away and comes straight back, which is the common
        // minimise-then-restore case.
        state.reconcile(currentIDs: ["a", "b"])
        state.reconcile(currentIDs: ["a", "b", "c"])

        #expect(
            state.arrangedIDs(for: ["a", "b", "c"]) == ["c", "a", "b"],
            "a window that briefly disappeared should not lose its manual position"
        )
    }

    @Test
    func everyCurrentItemIsAlwaysReturnedExactlyOnce() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b", "c", "d"])
        state.applyManualOrder(["d", "c"], userPositionedItemID: "d")

        for current in [["a", "b", "c", "d"], ["a", "b"], ["a", "b", "c", "d", "e"], []] {
            let arranged = state.arrangedIDs(for: current)
            #expect(arranged.count == current.count, "\(current) lost or gained an item")
            #expect(Set(arranged) == Set(current), "\(current) was not preserved exactly")
        }
    }

    @Test
    func arrangingNothingProducesNothing() {
        let state = TaskZoneOrderingState()
        #expect(state.arrangedIDs(for: []) == [])
    }

    @Test
    func ranksBeyondTheEndsAreClampedRatherThanDroppingItems() {
        var state = TaskZoneOrderingState()
        state.reconcile(currentIDs: ["a", "b"])
        // A stale rank from when the bar held far more windows.
        state.applyManualOrder(["a", "b"], userPositionedItemID: "a")
        state.reconcile(currentIDs: ["a"])

        let arranged = state.arrangedIDs(for: ["a"])
        #expect(arranged == ["a"])
    }
}