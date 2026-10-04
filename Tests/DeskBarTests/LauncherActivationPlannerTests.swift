import Testing
@testable import DockBar

@Test
func launcherActivationPlannerLaunchesNonRunningApps() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: false,
            bundleIdentifier: "com.example.alpha",
            isRunning: false,
            hasVisibleLocalWindows: false,
            hasAnyWindows: nil
        ) == .launchApplication
    )
}

@Test
func launcherActivationPlannerActivatesVisibleWindows() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: false,
            bundleIdentifier: "com.example.alpha",
            isRunning: true,
            hasVisibleLocalWindows: true,
            hasAnyWindows: true
        ) == .activateMostRecentWindow
    )
}

@Test
func launcherActivationPlannerActivatesRunningAppsWithoutLocalWindows() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: false,
            bundleIdentifier: "com.example.alpha",
            isRunning: true,
            hasVisibleLocalWindows: false,
            hasAnyWindows: true
        ) == .activateApplication
    )
}

@Test
func launcherActivationPlannerOpensFinderWindowWhenFinderHasNoWindows() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: false,
            bundleIdentifier: LauncherActivationPlanner.finderBundleIdentifier,
            isRunning: true,
            hasVisibleLocalWindows: false,
            hasAnyWindows: false
        ) == .openFinderWindow
    )
}

@Test
func launcherActivationPlannerOpensFinderWindowWhenNoLocalFinderWindowExists() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: false,
            bundleIdentifier: LauncherActivationPlanner.finderBundleIdentifier,
            isRunning: true,
            hasVisibleLocalWindows: false,
            hasAnyWindows: true
        ) == .openFinderWindow
    )
}

@Test
func launcherActivationPlannerOpensFinderWindowWhenFinderWindowStateIsUnknown() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: false,
            bundleIdentifier: LauncherActivationPlanner.finderBundleIdentifier,
            isRunning: true,
            hasVisibleLocalWindows: false,
            hasAnyWindows: nil
        ) == .openFinderWindow
    )
}

@Test
func launcherActivationPlannerCyclesWindowsWhenAppIsActiveAndClickCycles() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .cycle,
            isActive: true,
            bundleIdentifier: "com.example.alpha",
            isRunning: true,
            hasVisibleLocalWindows: true,
            hasAnyWindows: true
        ) == .cycleWindows
    )
}

@Test
func launcherActivationPlannerMinimizesWhenAppIsActiveAndClickMinimizes() {
    #expect(
        LauncherActivationPlanner.action(
            frontmostClickAction: .minimize,
            isActive: true,
            bundleIdentifier: "com.example.alpha",
            isRunning: true,
            hasVisibleLocalWindows: true,
            hasAnyWindows: true
        ) == .minimizeApplication
    )
}
