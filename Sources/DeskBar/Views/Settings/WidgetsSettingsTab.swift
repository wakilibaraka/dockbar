import SwiftUI

struct WidgetsSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
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
