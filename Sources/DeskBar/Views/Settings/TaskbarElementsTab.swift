import SwiftUI

class QuickSettingsTabState: ObservableObject {
    @Published var items: [QuickSettingItem] = []
    
    struct QuickSettingItem: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
        var isEnabled: Bool
    }
}

struct TaskbarElementsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Choose what appears in the Dock and menu bar. Changes apply immediately.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                // Battery Widget
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Battery", symbol: "battery.100")
                        Picker("Location:", selection: $settings.batteryWidgetLocation) {
                            ForEach(WidgetLocation.allCases) { loc in
                                Text(loc.displayName).tag(loc)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)

                        Divider()
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle("Show percentage next to icon", isOn: $settings.showBatteryPercentage)
                            Toggle("Show percentage inside icon", isOn: $settings.showPercentageInsideIcon)
                        }
                        
                        HStack(spacing: 16) {
                            Picker("Style:", selection: $settings.batteryIconStyle) {
                                ForEach(BatteryIconStyle.allCases) { style in
                                    Text(style.displayName).tag(style)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: 200)
                            
                            Picker("Size:", selection: $settings.batteryIconSize) {
                                ForEach(BatteryIconSize.allCases) { size in
                                    Text(size.displayName).tag(size)
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(maxWidth: 160)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Calendar & Quick Settings", symbol: "calendar.badge.clock")
                        Text("Keep them together, or place each control independently.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Toggle("Split Calendar & Quick Settings", isOn: $settings.splitCalendarAndQuickSettings)
                        if settings.splitCalendarAndQuickSettings {
                            Picker("Calendar location:", selection: $settings.calendarLocation) {
                                ForEach(WidgetLocation.allCases) { loc in
                                    Text(loc.displayName).tag(loc)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 240)
                            Picker("Quick Settings location:", selection: $settings.quickSettingsLocation) {
                                ForEach(WidgetLocation.allCases) { loc in
                                    Text(loc.displayName).tag(loc)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 240)
                        } else {
                            Picker("Location:", selection: $settings.connectivityTrayLocation) {
                                ForEach(WidgetLocation.allCases) { loc in
                                    Text(loc.displayName).tag(loc)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(maxWidth: 200)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("Weather", symbol: "cloud.sun")
                        Toggle("Enable weather widget", isOn: $settings.weatherEnabled)
                        Text("Shows the current temperature and conditions in the Dock or menu bar.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Picker("Location:", selection: $settings.weatherWidgetLocation) {
                            ForEach(WidgetLocation.allCases) { loc in
                                Text(loc.displayName).tag(loc)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)
                        Picker("Units:", selection: $settings.weatherUnit) {
                            ForEach(WeatherUnit.allCases) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        Picker("Refresh:", selection: $settings.weatherPollingInterval) {
                            Text("15 minutes").tag(TimeInterval(900))
                            Text("30 minutes").tag(TimeInterval(1800))
                            Text("1 hour").tag(TimeInterval(3600))
                        }
                        Picker("Location mode:", selection: $settings.weatherLocationMode) {
                            ForEach(WeatherLocationMode.allCases) { mode in
                                Text(mode.displayName).tag(mode)
                            }
                        }
                        Text(settings.weatherLocationMode == .automatic
                             ? "Automatic uses macOS Location Services."
                             : "Manual uses the latitude and longitude below.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        if settings.weatherLocationMode == .manual {
                            HStack {
                                TextField("Latitude", value: $settings.weatherManualLatitude, format: .number)
                                TextField("Longitude", value: $settings.weatherManualLongitude, format: .number)
                            }
                        }
                    }
                    .disabled(!settings.weatherEnabled)
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // System Resources
                GroupBox {
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader("System Resources", symbol: "chart.xyaxis.line")
                        Picker("Location:", selection: $settings.systemResourceWidgetLocation) {
                            ForEach(WidgetLocation.allCases) { loc in
                                Text(loc.displayName).tag(loc)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)

                        Divider()

                        Toggle("Show system resource widget", isOn: $settings.showSystemResourceWidget)

                        Picker("Display:", selection: $settings.resourceDisplayStyle) {
                            ForEach(ResourceDisplayStyle.allCases) { style in
                                Text(style.displayName).tag(style)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Session Manager Plugin
                GroupBox {
                    VStack(alignment: .leading, spacing: 8) {
                        sectionHeader("Session Manager", symbol: "terminal")
                        Text("Show live agent state and usage details on terminal-backed tasks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Toggle("Enable Session Manager plugin", isOn: $settings.enableSessionManagerPlugin)
                        
                        Group {
                            Toggle("Show agent titles", isOn: $settings.showSessionManagerAgentTitles)
                            Toggle("Show activity indicators", isOn: $settings.showSessionManagerActivityIndicators)
                            Toggle("Show AI token usage", isOn: $settings.showSessionManagerTokenUsage)
                            Toggle("Animate activity", isOn: $settings.animateSessionManagerActivity)
                                .disabled(!settings.showSessionManagerActivityIndicators)
                            Toggle("Enable terminal actions", isOn: $settings.enableSessionManagerTerminalActions)
                            Toggle("Show action button", isOn: $settings.showSessionManagerActionButton)
                        }
                        .disabled(!settings.enableSessionManagerPlugin)
                        .padding(.leading, 16)
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding(20)
        }
    }

    private func sectionHeader(_ title: String, symbol: String) -> some View {
        Label(title, systemImage: symbol)
            .font(.headline)
            .symbolRenderingMode(.hierarchical)
    }
}
