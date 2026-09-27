import SwiftUI

struct BehaviorSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        VStack(spacing: 24) {
            
            SettingsCard(title: "Windows", icon: "uiwindow.split.2x1") {
                SettingsRow(title: "Window Grouping") {
                    Picker("", selection: $settings.groupingMode) {
                        Text("Always").tag(WindowGroupingMode.always)
                        Text("Automatic").tag(WindowGroupingMode.automatic)
                        Text("Never").tag(WindowGroupingMode.never)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                
                HStack {
                    switch settings.groupingMode {
                    case .always:
                        Text("App icons stay in their pinned locations and never move.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    case .automatic:
                        Text("Group windows only when taskbar space is running low.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    case .never:
                        Text("Each open window gets its own separate button.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                
                SettingsDivider()
                
                SettingsRow(title: "Left-click action", subtitle: "When clicking a grouped app icon") {
                    Picker("", selection: $settings.groupedClickAction) {
                        Text("Cycle Windows").tag(GroupedClickAction.cycleWindows)
                        Text("Show Window List").tag(GroupedClickAction.showPopover)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .disabled(settings.groupingMode == .never)
                }
                
                SettingsDivider()
                
                SettingsRow(title: "When clicking frontmost", subtitle: "Clicking the currently active window") {
                    Picker("", selection: $settings.frontmostClickAction) {
                        Text("Minimize").tag(FrontmostClickAction.minimize)
                        Text("Cycle to next").tag(FrontmostClickAction.cycle)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            }
            
            SettingsCard(title: "Interaction", icon: "hand.point.up.left") {
                SettingsRow(title: "Enable task dragging to reorder") {
                    Toggle("", isOn: $settings.dragReorder).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Hover preview delay") {
                    HStack {
                        Slider(value: $settings.hoverDelay, in: 0.0...1.0, step: 0.1)
                        Text(String(format: "%.1fs", settings.hoverDelay))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
            }
            
            SettingsCard(title: "Hold-to-Quit Prevention", icon: "keyboard") {
                SettingsRow(title: "Require hold to quit (Cmd+Q)") {
                    Toggle("", isOn: $settings.enableHoldToQuit).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Include Cmd+W (Close Window)") {
                    Toggle("", isOn: $settings.holdToQuitCmdW)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                        .disabled(!settings.enableHoldToQuit)
                }
                SettingsDivider()
                SettingsRow(title: "Hold duration") {
                    HStack {
                        Slider(value: $settings.holdToQuitDuration, in: 0.5...5.0, step: 0.5)
                        Text(String(format: "%.1fs", settings.holdToQuitDuration))
                            .frame(width: 40, alignment: .trailing)
                    }
                    .frame(width: 150)
                    .disabled(!settings.enableHoldToQuit)
                }
            }
        }
    }
}
