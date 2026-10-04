import SwiftUI

struct DisplaysSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        SettingsPage(
            title: "Displays",
            subtitle: "Decide which screens get a bar, and what happens to the system Dock."
        ) {
            SettingsGroup("Screens") {
                VStack(alignment: .leading, spacing: 10) {
                    Text("A bar can appear on every display, follow whichever display has focus, or stay on the one that owns the menu bar.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    PickerRow(
                        "Show On",
                        help: settings.screenMode.subtitle,
                        selection: $settings.screenMode,
                        options: TaskbarScreenMode.allCases.map { ($0.displayName, $0) },
                        width: 240
                    )

                    ForEach(TaskbarScreenMode.allCases) { mode in
                        HStack(spacing: 8) {
                            Image(systemName: settings.screenMode == mode ? "largecircle.fill.circle" : "circle")
                                .foregroundStyle(settings.screenMode == mode ? Color.accentColor : .secondary)
                            Text(mode.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
            }

            SettingsGroup(
                "System Dock",
                footer: "DockBar never hides the Dock while macOS thinks it is in use; if the Dock reappears, the bar is still there."
            ) {
                ForEach(NativeDockBehavior.allCases) { behavior in
                    Button {
                        settings.nativeDockBehavior = behavior
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: settings.nativeDockBehavior == behavior
                                ? "largecircle.fill.circle"
                                : "circle")
                                .foregroundStyle(settings.nativeDockBehavior == behavior ? Color.accentColor : .secondary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(behavior.displayName)
                                    .foregroundStyle(.primary)
                                Text(behavior.help)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            Spacer(minLength: 0)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                }
            }

            SettingsGroup("Full Screen") {
                ToggleRow(
                    "Show Over Full Screen",
                    help: "Keep the bar visible while a full screen app is in front. macOS normally hides overlays in full screen, so this trades a little immersion for constant access.",
                    isOn: $settings.showOverFullScreenApps
                )
            }
        }
    }
}