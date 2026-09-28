import DockBarCore

import SwiftUI

struct TaskbarElementsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        VStack(spacing: 24) {
            
            SettingsCard(title: "Battery Widget", icon: "battery.100") {
                SettingsRow(title: "Location") {
                    Picker("", selection: $settings.batteryWidgetLocation) {
                        ForEach(WidgetLocation.allCases) { loc in
                            Text(loc.displayName).tag(loc)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Show percentage next to icon") {
                    Toggle("", isOn: $settings.showBatteryPercentage).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show percentage inside icon") {
                    Toggle("", isOn: $settings.showPercentageInsideIcon).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Style") {
                    Picker("", selection: $settings.batteryIconStyle) {
                        ForEach(BatteryIconStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Size") {
                    Picker("", selection: $settings.batteryIconSize) {
                        ForEach(BatteryIconSize.allCases) { size in
                            Text(size.displayName).tag(size)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
            }
            
            SettingsCard(title: "Connectivity & Time", icon: "wifi") {
                SettingsRow(title: "Location") {
                    Picker("", selection: $settings.connectivityTrayLocation) {
                        ForEach(WidgetLocation.allCases) { loc in
                            Text(loc.displayName).tag(loc)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            
            SettingsCard(title: "Weather Widget", icon: "cloud.sun.fill") {
                SettingsRow(title: "Enable weather widget") {
                    Toggle("", isOn: $settings.weatherEnabled).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Units") {
                    Picker("", selection: $settings.weatherUnit) {
                        ForEach(WeatherUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .disabled(!settings.weatherEnabled)
                }
                SettingsDivider()
                SettingsRow(title: "Refresh Interval") {
                    Picker("", selection: $settings.weatherPollingInterval) {
                        Text("15 minutes").tag(TimeInterval(900))
                        Text("30 minutes").tag(TimeInterval(1800))
                        Text("1 hour").tag(TimeInterval(3600))
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .disabled(!settings.weatherEnabled)
                }
                SettingsDivider()
                SettingsRow(title: "Location Mode") {
                    Picker("", selection: $settings.weatherLocationMode) {
                        ForEach(WeatherLocationMode.allCases) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 150)
                    .disabled(!settings.weatherEnabled)
                }
                
                if settings.weatherLocationMode == .manual {
                    SettingsDivider()
                    SettingsRow(title: "Coordinates") {
                        HStack {
                            TextField("Lat", value: $settings.weatherManualLatitude, format: .number)
                            TextField("Lon", value: $settings.weatherManualLongitude, format: .number)
                        }
                        .frame(width: 150)
                    }
                }
            }
            
            SettingsCard(title: "System Resources", icon: "cpu") {
                SettingsRow(title: "Show system resource widget") {
                    Toggle("", isOn: $settings.showSystemResourceWidget).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Location") {
                    Picker("", selection: $settings.systemResourceWidgetLocation) {
                        ForEach(WidgetLocation.allCases) { loc in
                            Text(loc.displayName).tag(loc)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Display Style") {
                    Picker("", selection: $settings.resourceDisplayStyle) {
                        ForEach(ResourceDisplayStyle.allCases) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            SettingsCard(title: "Center Matrix", icon: "square.grid.3x2") {
                SettingsRow(title: "Show Start Button") {
                    Toggle("", isOn: $settings.showStartButton).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Search Field") {
                    Toggle("", isOn: $settings.showSearch).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }

                SettingsDivider()
                SettingsRow(title: "Show Widgets Board Button") {
                    Toggle("", isOn: $settings.showWidgetsBoard).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Downloads Button") {
                    Toggle("", isOn: $settings.showDownloads).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Trash Button") {
                    Toggle("", isOn: $settings.showTrash).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                if settings.showDownloads {
                    SettingsDivider()
                    SettingsRow(title: "Downloads Action", subtitle: "What happens when you click the Downloads button") {
                        Picker("", selection: $settings.downloadsAction) {
                            Text("Open Downloads Flyout (Coming soon)").tag(1)
                            Text("Open in Finder").tag(2)
                            Text("Open in External App").tag(3)
                        }.labelsHidden().frame(width: 200)
                    }
                    if settings.downloadsAction == 3 {
                        SettingsDivider()
                        SettingsRow(title: "External App Bundle ID") {
                            TextField("com.example.App", text: $settings.downloadsExternalApp)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .frame(width: 200)
                        }
                    }
                }
            }
        }
    }
}
