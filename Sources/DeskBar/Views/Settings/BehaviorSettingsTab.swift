import SwiftUI

struct BehaviorSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
            Section(header: Text("Window Management").font(.headline)) {
                Picker("Grouping mode", selection: $settings.groupingMode) {
                    Text("Never").tag(WindowGroupingMode.never)
                    Text("Automatic").tag(WindowGroupingMode.automatic)
                    Text("Always").tag(WindowGroupingMode.always)
                }
                
                Picker("Grouped click action", selection: $settings.groupedClickAction) {
                    Text("Show Popover").tag(GroupedClickAction.showPopover)
                    Text("Cycle Windows").tag(GroupedClickAction.cycleWindows)
                }
                
                Picker("Active app click action", selection: $settings.frontmostClickAction) {
                    Text("Minimize").tag(FrontmostClickAction.minimize)
                    Text("Cycle Windows").tag(FrontmostClickAction.cycle)
                }
                
                Toggle("Drag reorder", isOn: $settings.dragReorder)
                Toggle("Middle click closes window", isOn: $settings.middleClickCloses)
            }
            
            Divider().padding(.vertical, 8)
            
            Section(header: Text("Visual Feedback").font(.headline)) {
                Toggle("Flash attention indicators", isOn: $settings.flashAttentionIndicators)
                Toggle("Show progress indicators", isOn: $settings.showProgressIndicators)
                
                HStack {
                    Text("Hover delay:")
                    Slider(value: $settings.hoverDelay, in: 0.0...1.0, step: 0.1)
                    Text(String(format: "%.1fs", settings.hoverDelay))
                }
            }
            
            Divider().padding(.vertical, 8)
            
            Section(header: Text("Hold-to-Quit (Cmd+Q / Cmd+W)").font(.headline)) {
                Toggle("Enable hold-to-quit prevention", isOn: $settings.enableHoldToQuit)
                
                Group {
                    Toggle("Include Cmd+W (Close Window)", isOn: $settings.holdToQuitCmdW)
                    
                    HStack {
                        Text("Hold duration:")
                        Slider(value: $settings.holdToQuitDuration, in: 0.5...5.0, step: 0.5)
                        Text(String(format: "%.1fs", settings.holdToQuitDuration))
                    }
                }
                .disabled(!settings.enableHoldToQuit)
                .padding(.leading, 16)
            }
        }
        .padding()
    }
}
