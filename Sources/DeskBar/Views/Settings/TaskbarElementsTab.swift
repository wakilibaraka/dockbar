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
                // Battery Widget
                GroupBox(label: Text("Battery Widget").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
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
                

                GroupBox(label: Text("Calendar & Quick Settings").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Location:", selection: $settings.connectivityTrayLocation) {
                            ForEach(WidgetLocation.allCases) { loc in
                                Text(loc.displayName).tag(loc)
                            }

                            GroupBox(label: Text("Weather Widget").font(.headline)) {
                                VStack(alignment: .leading, spacing: 12) {
                                    Toggle("Enable weather widget", isOn: $settings.weatherEnabled)
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
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(maxWidth: 200)
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                // System Resources
                GroupBox(label: Text("System Resources Widget").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
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
                GroupBox(label: Text("Session Manager Plugin").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Enable Session Manager plugin", isOn: $settings.enableSessionManagerPlugin)
                        
                        Group {
                            Toggle("Show agent titles", isOn: $settings.showSessionManagerAgentTitles)
                            Toggle("Show activity indicators", isOn: $settings.showSessionManagerActivityIndicators)
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
}
