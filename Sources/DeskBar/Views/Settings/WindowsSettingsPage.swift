import SwiftUI

struct WindowsSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        SettingsPage(
            title: "Windows",
            subtitle: "How titles are shown, how windows collapse into one button, and what clicking does."
        ) {
            SettingsGroup("Titles") {
                ToggleRow(
                    "Show Titles",
                    help: "Show the application or window title inside each task button.",
                    isOn: $settings.showTitles
                )
                PickerRow(
                    "Title Source",
                    help: "The app name is stable; the window title is more informative but jumps around.",
                    selection: $settings.taskTitleSource,
                    options: TaskTitleSource.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Truncation",
                    help: "Where a long title is cut.",
                    selection: $settings.taskTruncationStyle,
                    options: TaskTruncationStyle.allCases.map { ($0.displayName, $0) }
                )
                SliderRow(
                    "Title Size",
                    help: "Font size for task button titles.",
                    value: Binding(
                        get: { Double(settings.titleFontSize) },
                        set: { settings.titleFontSize = CGFloat($0) }
                    ),
                    range: 9...20,
                    step: 1,
                    suffix: " pt"
                )
                SliderRow(
                    "Maximum Task Width",
                    help: "Widest a task button may grow before its title is truncated.",
                    value: Binding(
                        get: { Double(settings.maxTaskWidth) },
                        set: { settings.maxTaskWidth = CGFloat($0) }
                    ),
                    range: 80...400,
                    step: 10,
                    suffix: " pt"
                )
            }

            SettingsGroup(
                "Grouping",
                footer: "Grouping keeps one button per app and stacks its windows behind it."
            ) {
                PickerRow(
                    "Window Grouping",
                    help: "When to collapse an app's windows into a single button.",
                    selection: $settings.groupingMode,
                    options: WindowGroupingMode.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Clicking a Group",
                    help: "What a single click on a grouped button does.",
                    selection: $settings.groupedClickAction,
                    options: GroupedClickAction.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Clicking the Front Window",
                    help: "What clicking the app that is already focused does.",
                    selection: $settings.frontmostClickAction,
                    options: FrontmostClickAction.allCases.map { ($0.displayName, $0) }
                )
                ToggleRow(
                    "Window Count Badges",
                    help: "Show how many windows an app has open.",
                    isOn: $settings.showWindowCountBadges
                )
            }

            SettingsGroup("Thumbnails") {
                SliderRow(
                    "Thumbnail Size",
                    help: "Width of the live window thumbnail shown on hover.",
                    value: Binding(
                        get: { Double(settings.thumbnailSize) },
                        set: { settings.thumbnailSize = CGFloat($0) }
                    ),
                    range: 120...360,
                    step: 10,
                    suffix: " pt"
                )
            }

            SettingsGroup("Switching and Quitting") {
                ToggleRow(
                    "Window Switcher",
                    help: "Hold a modifier to step through the windows of the active app.",
                    isOn: $settings.enableWindowSwitcher
                )
                ToggleRow(
                    "Hold to Quit",
                    help: "Press and hold a task button to quit that app.",
                    isOn: $settings.enableHoldToQuit
                )
                SliderRow(
                    "Hold Duration",
                    help: "How long the button must be held before the app quits.",
                    value: $settings.holdToQuitDuration,
                    range: 0.3...5,
                    step: 0.1,
                    formatter: { String(format: "%.1f s", $0) }
                )
                .disabled(!settings.enableHoldToQuit)
                ToggleRow(
                    "Hold ⌘W to Quit",
                    help: "Hold Command-W on a task button to close every window of that app.",
                    isOn: $settings.holdToQuitCmdW
                )
                .disabled(!settings.enableHoldToQuit)
            }
        }
    }
}