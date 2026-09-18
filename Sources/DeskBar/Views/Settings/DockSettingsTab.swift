import SwiftUI

struct DockSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                GroupBox(label: Text("Taskbar").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Dock mode", selection: $settings.dockMode) {
                            Text("Independent").tag(DockMode.independent)
                            Text("Hide Native Dock").tag(DockMode.hidden)
                            Text("Replace (Autohide)").tag(DockMode.autoHide)
                        }
                        .pickerStyle(MenuPickerStyle())
                        
                        Picker("Theme", selection: $settings.appTheme) {
                            ForEach(AppTheme.allCases) { theme in
                                Text(theme.displayName).tag(theme)
                            }
                        }
                        
                        HStack {
                            Text("Height:")
                            Slider(value: $settings.taskbarHeight, in: 30...80, step: 2)
                            Text("\(Int(settings.taskbarHeight))")
                        }
                        
                        Toggle("Show over fullscreen windows", isOn: $settings.showOverFullScreenApps)
                        Toggle("Show on all monitors", isOn: $settings.showOnAllMonitors)
                        
                        Picker("Layout mode", selection: $settings.layoutMode) {
                            Text("Full Width").tag(DeskBarLayoutMode.fullWidth)
                            Text("Full Width (Glass)").tag(DeskBarLayoutMode.fullWidthGlass)
                            Text("Compact").tag(DeskBarLayoutMode.compact)
                            Text("Compact (Glass)").tag(DeskBarLayoutMode.compactGlass)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Task Items").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Show titles", isOn: $settings.showTitles)
                        
                        Picker("Title source", selection: $settings.taskTitleSource) {
                            Text("Window Title").tag(TaskTitleSource.windowTitle)
                            Text("Application Name").tag(TaskTitleSource.appName)
                        }
                        
                        Picker("Truncation style", selection: $settings.taskTruncationStyle) {
                            Text("Tail").tag(TaskTruncationStyle.tail)
                            Text("Middle").tag(TaskTruncationStyle.middle)
                            Text("Head").tag(TaskTruncationStyle.ellipsisHead)
                        }
                        
                        HStack {
                            Text("Title font size:")
                            Slider(value: $settings.titleFontSize, in: 10...24, step: 1)
                            Text("\(Int(settings.titleFontSize))")
                        }
                        
                        HStack {
                            Text("Max task width:")
                            Slider(value: $settings.maxTaskWidth, in: 100...400, step: 10)
                            Text("\(Int(settings.maxTaskWidth))")
                        }
                        
                        HStack {
                            Text("Thumbnail size:")
                            Slider(value: $settings.thumbnailSize, in: 100...300, step: 10)
                            Text("\(Int(settings.thumbnailSize))")
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(20)
        }
    }
}
