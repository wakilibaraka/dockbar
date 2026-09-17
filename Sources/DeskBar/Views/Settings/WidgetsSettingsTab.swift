import SwiftUI

struct WidgetsSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
            Section(header: Text("Battery Widget").font(.headline)) {
                VStack(alignment: .leading, spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Toggle("Show percentage next to icon", isOn: $settings.showBatteryPercentage)
                        Toggle("Show percentage inside icon", isOn: $settings.showPercentageInsideIcon)
                    }
                    
                    Divider().opacity(0.5)
                    
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
                .padding(.vertical, 4)
            }
            .padding(.bottom, 12)

            Section(header: Text("System Resources Widget").font(.headline)) {
                Toggle("Show system resource widget", isOn: $settings.showSystemResourceWidget)
                
                Group {
                }
                .disabled(!settings.showSystemResourceWidget)
                .padding(.leading, 16)
            }
        }
        .padding()
    }
}