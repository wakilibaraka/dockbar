import SwiftUI

struct BehaviorSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                GroupBox(label: Text("Windows").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Picker("Window Grouping", selection: $settings.groupingMode) {
                                Text("Always (macOS style)").tag(WindowGroupingMode.always)
                                Text("Automatic (Hybrid)").tag(WindowGroupingMode.automatic)
                                Text("Never (Windows style)").tag(WindowGroupingMode.never)
                            }
                            
                            switch settings.groupingMode {
                            case .always:
                                Text("Always group windows by application. App icons stay in their pinned/stable locations and never move when minimized.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            case .automatic:
                                Text("Group windows by application only when taskbar space is running low.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            case .never:
                                Text("Never group windows. Each open window gets its own separate button on the taskbar.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Picker("Left-click action", selection: $settings.groupedClickAction) {
                            Text("Cycle Windows").tag(GroupedClickAction.cycleWindows)
                            Text("Show Window List").tag(GroupedClickAction.showPopover)
                        }
                        .disabled(settings.groupingMode == .never)
                        
                        Picker("When clicking frontmost", selection: $settings.frontmostClickAction) {
                            Text("Minimize").tag(FrontmostClickAction.minimize)
                            Text("Cycle to next").tag(FrontmostClickAction.cycle)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Interaction").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Enable task dragging to reorder", isOn: $settings.dragReorder)
                        
                        HStack {
                            Text("Hover preview delay:")
                            Slider(value: $settings.hoverDelay, in: 0.0...1.0, step: 0.1)
                            Text(String(format: "%.1fs", settings.hoverDelay))
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Hold-to-Quit (Cmd+Q / Cmd+W)").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
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
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            }
            .padding(20)
        }
    }
}
