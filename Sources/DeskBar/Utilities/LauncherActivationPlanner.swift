enum LauncherActivationAction: Equatable {
    case launchApplication
    case activateMostRecentWindow
    case activateApplication
    case openFinderWindow
    case minimizeApplication
    case cycleWindows
}

enum LauncherActivationPlanner {
    static let finderBundleIdentifier = "com.apple.finder"

    static func action(
        frontmostClickAction: FrontmostClickAction,
        isActive: Bool,
        bundleIdentifier: String,
        isRunning: Bool,
        hasVisibleLocalWindows: Bool,
        hasAnyWindows: Bool?
    ) -> LauncherActivationAction {
        if isActive {
            return frontmostClickAction == .minimize ? .minimizeApplication : .cycleWindows
        }

        if hasVisibleLocalWindows {
            return .activateMostRecentWindow
        }

        if !isRunning {
            return .launchApplication
        }

        if bundleIdentifier == finderBundleIdentifier {
            return .openFinderWindow
        }

        return .activateApplication
    }
}
