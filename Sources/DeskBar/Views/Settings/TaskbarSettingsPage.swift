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

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 200), spacing: 12)], spacing: 12) {
                        ForEach(TaskbarMode.allCases) { mode in
                            TaskbarStyleCard(
                                mode: mode,
                                isSelected: settings.taskbarMode == mode
                            ) {
                                settings.taskbarMode = mode
                            }
                        }
                    }
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

/// A selectable card describing one `TaskbarMode`.
struct TaskbarStyleCard: View {
    let mode: TaskbarMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: mode.symbolName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(isSelected ? Color.accentColor : .secondary)
                    Text(mode.displayName)
                        .font(.body.weight(.semibold))
                    Spacer(minLength: 0)
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                TaskbarStylePreview(mode: mode)
                    .frame(height: 34)
                Text(mode.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Shape.cardCornerRadius, style: .continuous)
                    .fill(isSelected ? Color.accentColor.opacity(0.12) : Color.secondary.opacity(0.06))
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Shape.cardCornerRadius, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color.secondary.opacity(0.15),
                        lineWidth: DesignSystem.Shape.hairline
                    )
            )
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .help(mode.subtitle)
    }
}

/// A tiny schematic of what each bar style looks like. Purely decorative, but it turns
/// a list of names into something you can actually choose between.
struct TaskbarStylePreview: View {
    let mode: TaskbarMode

    private var segments: [CGFloat] {
        switch mode {
        case .custom: return [10, 10, 10, 10, 10]
        case .windows: return [8, 10, 10, 10, 10, 10]
        case .mac: return [8, 9, 9, 9]
        case .classic: return [10, 10, 10, 10, 10, 10, 10]
        case .eskele: return [9, 9, 9, 9]
        }
    }

    private var width: CGFloat {
        switch mode {
        case .custom, .classic: return 1
        case .windows: return 1
        case .mac: return 0.82
        case .eskele: return 0.66
        }
    }

    private var isGlass: Bool {
        switch mode {
        case .custom, .classic, .eskele, .windows: return false
        case .mac: return true
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let barWidth = proxy.size.width * width
            HStack(spacing: 3) {
                HStack(spacing: 3) {
                    ForEach(Array(segments.enumerated()), id: \.offset) { _, width in
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(.secondary.opacity(0.45))
                            .frame(width: width)
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: DesignSystem.Shape.chipCornerRadius, style: .continuous)
                        .fill(.quaternary)
                )
                Spacer(minLength: 0)
            }
            .frame(width: barWidth)
            .frame(maxWidth: .infinity)
        }
    }
}