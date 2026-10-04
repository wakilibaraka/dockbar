import SwiftUI

struct TaskbarSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        SettingsPage(
            title: "Taskbar",
            subtitle: "Choose a bar style, then tune its size and how task buttons behave."
        ) {
            SettingsGroup("Style") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Each style is a complete layout: how the bar is sized, whether it groups windows, and where the launcher and widgets sit.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    TaskbarStylePicker(selection: $settings.taskbarMode)
                }
            }

            SettingsGroup(
                "Appearance",
                footer: "Glass layouts use a translucent material that lets the desktop show through."
            ) {
                PickerRow(
                    "Layout",
                    help: "How much of the screen the bar spans.",
                    selection: $settings.layoutMode,
                    options: DeskBarLayoutMode.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Position",
                    help: "Where the bar sits on screen.",
                    selection: $settings.dockPosition,
                    options: DockPosition.allCases.map { ($0.displayName, $0) }
                )
                PickerRow(
                    "Theme",
                    help: "Follow the system appearance, or force one.",
                    selection: $settings.appTheme,
                    options: AppTheme.allCases.map { ($0.displayName, $0) }
                )
                SliderRow(
                    "Bar Height",
                    help: "Height of the bar in points.",
                    value: Binding(
                        get: { Double(settings.taskbarHeight) },
                        set: { settings.taskbarHeight = CGFloat($0) }
                    ),
                    range: 28...96,
                    step: 1,
                    suffix: " pt"
                )
                SliderRow(
                    "Icon Size",
                    help: "Size of task buttons when titles are hidden.",
                    value: Binding(
                        get: { Double(settings.iconOnlySize) },
                        set: { settings.iconOnlySize = CGFloat($0) }
                    ),
                    range: 16...64,
                    step: 1,
                    suffix: " pt"
                )
            }

            SettingsGroup("Task Buttons") {
                ToggleRow(
                    "Drag to Reorder",
                    help: "Drag task buttons to change their order.",
                    isOn: $settings.dragReorder
                )
                ToggleRow(
                    "Middle-Click Closes",
                    help: "Middle-clicking a task button closes that window.",
                    isOn: $settings.middleClickCloses
                )
                ToggleRow(
                    "Attention Flash",
                    help: "Flash a button when its window asks for attention.",
                    isOn: $settings.flashAttentionIndicators
                )
                ToggleRow(
                    "Progress Indicators",
                    help: "Show progress on windows that are downloading or busy.",
                    isOn: $settings.showProgressIndicators
                )
                ToggleRow(
                    "Activity Mode",
                    help: "Let windows report that they are still working.",
                    isOn: $settings.enableActivityMode
                )
                SliderRow(
                    "Hover Delay",
                    help: "How long the pointer rests on a button before its thumbnail appears.",
                    value: $settings.hoverDelay,
                    range: 0...1.5,
                    step: 0.05,
                    formatter: { String(format: "%.2f s", $0) }
                )
            }
        }
    }
}
