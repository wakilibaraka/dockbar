import SwiftUI

struct PluginsSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
            Section(header: Text("Session Manager").font(.headline)) {
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
        }
        .padding()
    }
}
