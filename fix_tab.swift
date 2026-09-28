import Foundation

let path = "Sources/DeskBar/Views/Settings/DockSettingsTab.swift"
var content = try! String(contentsOfFile: path)

let oldPicker = """
                SettingsRow(title: "Layout Mode", subtitle: "General shape and alignment") {
                    Picker("", selection: $settings.layoutMode) {
                        Text("Full Width").tag(DeskBarLayoutMode.fullWidth)
                        Text("Full Width (Glass)").tag(DeskBarLayoutMode.fullWidthGlass)
                        Text("Compact").tag(DeskBarLayoutMode.compact)
                        Text("Compact (Glass)").tag(DeskBarLayoutMode.compactGlass)
                        Text("Windows 11 (Full Width)").tag(DeskBarLayoutMode.windows11FullWidth)
                        Text("Windows 11 (Floating)").tag(DeskBarLayoutMode.windows11Floating)
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
"""

let newPicker = """
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
"""
content = content.replacingOccurrences(of: oldPicker, with: newPicker)

try! content.write(toFile: path, atomically: true, encoding: .utf8)
