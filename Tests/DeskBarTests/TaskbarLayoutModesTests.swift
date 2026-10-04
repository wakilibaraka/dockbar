import Foundation
import Testing
@testable import DockBar

// MARK: - Styles

@Test
func everyStyleHasCopyAndAStrategy() {
    #expect(TaskbarMode.allCases.count == 5)

    for mode in TaskbarMode.allCases {
        #expect(!mode.displayName.isEmpty)
        #expect(!mode.subtitle.isEmpty)
        #expect(!mode.symbolName.isEmpty)
        // Every mode must resolve to a strategy; a missing case is a compile error at
        // the switch, this keeps the contract explicit.
        let strategy = mode.strategy
        #expect(strategy.layoutMode(defaultLayoutMode: .compact) != .fullWidthGlass || mode == .windows)
    }
}

@Test
func stylesPinTheirGeometry() {
    // A table of what each style promises, so a regression in one mode cannot quietly
    // change the others. (mode, layoutMode, dockPosition, compactWidth, groupsWindows)
    let expectations: [(TaskbarMode, DeskBarLayoutMode, DockPosition, Bool, Bool)] = [
        (.windows, .fullWidthGlass, .bottomCenter, false, true),
        (.mac, .compactGlass, .floatingCenter, true, true),
        (.deskBar, .fullWidth, .bottomCenter, false, false),
        (.eskele, .compactGlass, .floatingCenter, true, false)
    ]

    for (mode, expectedLayout, expectedPosition, expectedCompact, expectedGrouping) in expectations {
        let strategy = mode.strategy
        #expect(strategy.layoutMode(defaultLayoutMode: .compact) == expectedLayout, "\(mode)")
        #expect(strategy.dockPosition(defaultPosition: .bottomLeft) == expectedPosition, "\(mode)")
        #expect(strategy.usesCompactContentWidth(defaultUsesCompactWidth: false) == expectedCompact, "\(mode)")
        #expect(strategy.shouldGroupWindows(defaultGrouping: false) == expectedGrouping, "\(mode)")
    }
}

@Test
func deskBarAndEskeleStylesDifferFromWindows() {
    // The point of adding them: the DeskBar style is the solid edge-to-edge bar, Eskele
    // is a fit-to-icons pill. Neither may collapse onto the Windows style.
    #expect(TaskbarMode.deskBar.strategy.layoutMode(defaultLayoutMode: .compactGlass) != .fullWidthGlass)
    #expect(TaskbarMode.eskele.strategy.layoutMode(defaultLayoutMode: .fullWidth) != .fullWidthGlass)

    // Windows keeps its distinct behaviours.
    #expect(TaskbarMode.windows.strategy.combinesPinnedApps)
    #expect(TaskbarMode.deskBar.strategy.combinesPinnedApps == false)
}

@Test
func widgetPlacementWidthsSplitTrailingWindowsCluster() {
    let windows = TaskbarMode.windows.strategy
    let deskBar = TaskbarMode.deskBar.strategy

    // Windows and DeskBar pin the window cluster to the trailing edge.
    #expect(windows.dockWidgetWidths(originalWidths: [40, 60], clusterWidth: 300) == [40, 60, 312])
    #expect(deskBar.dockWidgetWidths(originalWidths: [40, 60], clusterWidth: 300) == [40, 60, 312])

    // Eskele fits its contents, so the widgets keep their own widths.
    #expect(TaskbarMode.eskele.strategy.dockWidgetWidths(originalWidths: [40, 60], clusterWidth: 300) == [40, 60])
}

// MARK: - Screen model

@Test
func screenModePicksTheDisplaysThatGetABar() {
    #expect(TaskbarScreenMode.allScreens.displayIndexes(displayCount: 3) == [0, 1, 2])
    #expect(TaskbarScreenMode.perDisplay.displayIndexes(displayCount: 3) == [0, 1, 2])
    #expect(TaskbarScreenMode.menuBarScreen.displayIndexes(displayCount: 3) == [0])
    #expect(TaskbarScreenMode.focusedScreen.displayIndexes(displayCount: 3, focusedIndex: 2) == [2])
}

@Test
func screenModeHandlesDegenerateDisplays() {
    // No displays attached: nothing to place.
    for mode in TaskbarScreenMode.allCases {
        #expect(mode.displayIndexes(displayCount: 0).isEmpty, "\(mode)")
    }

    // One display: every mode resolves to it.
    for mode in TaskbarScreenMode.allCases {
        #expect(mode.displayIndexes(displayCount: 1, focusedIndex: 7) == [0], "\(mode)")
    }

    // A stale focus index must not read out of bounds.
    #expect(TaskbarScreenMode.focusedScreen.displayIndexes(displayCount: 2, focusedIndex: 9) == [1])
    #expect(TaskbarScreenMode.focusedScreen.displayIndexes(displayCount: 2, focusedIndex: -3) == [0])
}

@Test
func onlyAllScreensAndPerDisplayCoverEveryDisplay() {
    #expect(TaskbarScreenMode.allScreens.showsBarOnEveryDisplay)
    #expect(TaskbarScreenMode.perDisplay.showsBarOnEveryDisplay)
    #expect(TaskbarScreenMode.menuBarScreen.showsBarOnEveryDisplay == false)
    #expect(TaskbarScreenMode.focusedScreen.showsBarOnEveryDisplay == false)
}

@Test
func legacyShowOnAllMonitorsMigratesToAScreenMode() {
    func migrate(legacyValue: Bool?) -> TaskbarScreenMode {
        let suiteName = "TaskbarScreenModeMigration.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }

        if let legacyValue {
            defaults.set(legacyValue, forKey: "showOnAllMonitors")
        }

        let settings = TaskbarSettings(defaults: defaults)
        return settings.screenMode
    }

    // Old installs stored a boolean: true meant every display, false followed focus.
    #expect(migrate(legacyValue: true) == .allScreens)
    #expect(migrate(legacyValue: false) == .focusedScreen)
    // A brand new install gets every display, as before.
    #expect(migrate(legacyValue: nil) == .allScreens)
}

@Test
func anExplicitScreenModeWinsOverTheLegacyFlag() {
    let suiteName = "TaskbarScreenModeExplicit.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    defaults.set(false, forKey: "showOnAllMonitors")
    defaults.set(TaskbarScreenMode.menuBarScreen.rawValue, forKey: "screenMode")

    #expect(TaskbarSettings(defaults: defaults).screenMode == .menuBarScreen)
}

@Test
func screenModeRoundTripsThroughDefaults() {
    let suiteName = "TaskbarScreenModeRoundTrip.\(UUID().uuidString)"
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    defer { defaults.removePersistentDomain(forName: suiteName) }

    for mode in TaskbarScreenMode.allCases {
        let settings = TaskbarSettings(defaults: defaults)
        settings.screenMode = mode

        #expect(TaskbarSettings(defaults: defaults).screenMode == mode)
    }
}