import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    
    var body: some View {
        Form {
            Section(header: Text("Startup & Integration").font(.headline)) {
                Toggle("Start at login", isOn: $settings.startAtLogin)
                Toggle("Track Bluetooth device batteries", isOn: $settings.trackBluetoothDevices)
                
                Picker("Dock mode", selection: $settings.dockMode) {
                    Text("Independent").tag(DockMode.independent)
                    Text("Hide Native Dock").tag(DockMode.hidden)
                    Text("Replace (Autohide)").tag(DockMode.autoHide)
                }
                .pickerStyle(MenuPickerStyle())
            }
            
            Divider().padding(.vertical, 8)
            
            Section(header: Text("Permissions").font(.headline)) {
                HStack {
                    Text("Accessibility")
                    Spacer()
                    Text(permissionsManager.isAccessibilityGranted ? "Granted" : "Not Granted")
                        .foregroundColor(permissionsManager.isAccessibilityGranted ? .green : .red)
                    Button("Open Settings") {
                        permissionsManager.requestAccessibilityPermission()
                    }
                }


            }
        }
        .padding()
    }
}
