import SwiftUI

struct WidgetsSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
            Section(header: Text("System Resources Widget").font(.headline)) {
                Toggle("Show system resource widget", isOn: $settings.showSystemResourceWidget)
                
                Group {
                    Toggle("Show ring charts", isOn: $settings.showRingCharts)
                    Toggle("Show CPU metric", isOn: $settings.showSystemResourceCPUMetric)
                    Toggle("Show Memory metric", isOn: $settings.showSystemResourceMemoryMetric)
                    Toggle("Show GPU metric", isOn: $settings.showSystemResourceGPUMetric)
                }
                .disabled(!settings.showSystemResourceWidget)
                .padding(.leading, 16)
            }
        }
        .padding()
    }
}
