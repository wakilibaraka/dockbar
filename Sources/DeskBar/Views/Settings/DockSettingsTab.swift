import SwiftUI

struct DockSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        VStack(spacing: 24) {
            
            SettingsCard(title: "Taskbar", icon: "macwindow") {
                SettingsRow(title: "Dock Mode", subtitle: "How DeskBar interacts with the native macOS Dock") {
                    Picker("", selection: $settings.dockMode) {
                        Text("Independent").tag(DockMode.independent)
                        Text("Hide Native Dock").tag(DockMode.hidden)
                        Text("Replace (Autohide)").tag(DockMode.autoHide)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Theme", subtitle: "Color style of the taskbar") {
                    Picker("", selection: $settings.appTheme) {
                        ForEach(AppTheme.allCases) { theme in
                            Text(theme.displayName).tag(theme)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Preset", subtitle: "General shape and alignment") {
                    Picker("", selection: $settings.preset) {
                        Text("Split").tag(DeskBarPreset.split)
                        Text("Compact").tag(DeskBarPreset.compact)
                        Text("Full Width").tag(DeskBarPreset.fullWidth)
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
                SettingsDivider()
                SettingsRow(title: "Edge Style", subtitle: "Corners and edge flushness") {
                    Picker("", selection: $settings.edgeStyle) {
                        Text("Rounded (Floating)").tag(DeskBarEdgeStyle.rounded)
                        Text("Sharp (Flush)").tag(DeskBarEdgeStyle.sharp)
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
                SettingsDivider()
                SettingsRow(title: "Taskbar Height") {
                    HStack {
                        Slider(value: $settings.taskbarHeight, in: 30...80, step: 2)
                        Text("\(Int(settings.taskbarHeight))")
                            .frame(width: 30, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Show over fullscreen windows") {
                    Toggle("", isOn: $settings.showOverFullScreenApps).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show on all monitors") {
                    Toggle("", isOn: $settings.showOnAllMonitors).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
            }
            
            SettingsCard(title: "Task Items", icon: "rectangle.stack") {
                SettingsRow(title: "Icons Only", subtitle: "Hide app and window titles") {
                    Toggle("", isOn: Binding(get: { !settings.showTitles }, set: { settings.showTitles = !$0 }))
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Title Source") {
                    Picker("", selection: $settings.taskTitleSource) {
                        Text("Window Title").tag(TaskTitleSource.windowTitle)
                        Text("Application Name").tag(TaskTitleSource.appName)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Truncation Style") {
                    Picker("", selection: $settings.taskTruncationStyle) {
                        Text("Tail").tag(TaskTruncationStyle.tail)
                        Text("Middle").tag(TaskTruncationStyle.middle)
                        Text("Head").tag(TaskTruncationStyle.ellipsisHead)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Title Font Size") {
                    HStack {
                        Slider(value: $settings.titleFontSize, in: 10...24, step: 1)
                        Text("\(Int(settings.titleFontSize))")
                            .frame(width: 30, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Max Task Width") {
                    HStack {
                        Slider(value: $settings.maxTaskWidth, in: 100...400, step: 10)
                        Text("\(Int(settings.maxTaskWidth))")
                            .frame(width: 30, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Hover Thumbnail Size") {
                    HStack {
                        Slider(value: $settings.thumbnailSize, in: 100...300, step: 10)
                        Text("\(Int(settings.thumbnailSize))")
                            .frame(width: 30, alignment: .trailing)
                    }
                    .frame(width: 150)
                }
            }
        }
    }
}
