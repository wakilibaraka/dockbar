import Foundation
let path = "Sources/DeskBar/Views/Settings/DockSettingsTab.swift"
var content = try! String(contentsOfFile: path)
let oldLayout = """
                SettingsRow(title: "Preset", subtitle: "General shape and alignment") {
                    Picker("", selection: $settings.preset) {
                        Text("Split").tag(DeskBarPreset.split)
                        Text("Compact").tag(DeskBarPreset.compact)
                        Text("Full Width").tag(DeskBarPreset.fullWidth)
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
"""
let newLayout = """
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
                SettingsRow(title: "App Alignment", subtitle: "Position of running apps within the center zone") {
                    Picker("", selection: $settings.appAlignment) {
                        ForEach(DeskBarAppAlignment.allCases) { alignment in
                            Text(alignment.displayName).tag(alignment)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
"""
content = content.replacingOccurrences(of: oldLayout, with: newLayout)
try! content.write(toFile: path, atomically: true, encoding: .utf8)
