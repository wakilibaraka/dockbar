import Foundation
let path = "Sources/DeskBar/Views/Settings/TaskbarElementsTab.swift"
var content = try! String(contentsOfFile: path)
let newCard = """
            SettingsCard(title: "Center Matrix", icon: "square.grid.3x2") {
                SettingsRow(title: "Show Start Button") {
                    Toggle("", isOn: $settings.showStartButton).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Search Field") {
                    Toggle("", isOn: $settings.showSearch).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Task View Button") {
                    Toggle("", isOn: $settings.showTaskView).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Widgets Board Button") {
                    Toggle("", isOn: $settings.showWidgetsBoard).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Downloads Button") {
                    Toggle("", isOn: $settings.showDownloads).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
            }
"""
content = content.replacingOccurrences(of: "        }\n    }\n}", with: newCard + "\n        }\n    }\n}")
try! content.write(toFile: path, atomically: true, encoding: .utf8)
