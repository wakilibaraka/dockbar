import SwiftUI

struct WidgetsSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
            Section(header: Text("Battery Widget").font(.headline)) {
                Toggle("Show battery percentage text", isOn: $settings.showBatteryPercentage)
                Picker("Battery Icon Style", selection: $settings.batteryIconStyle) {
                    ForEach(BatteryIconStyle.allCases) { style in
                        Text(style.displayName).tag(style)
                    }
                }
                .pickerStyle(MenuPickerStyle())
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