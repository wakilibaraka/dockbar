import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject var calendarService = CalendarEventService.shared
    
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
                    Text("Device Control and Data Access")
                    Spacer()
                    Text(permissionsManager.isAccessibilityGranted ? "Granted" : "Not Granted")
                        .foregroundColor(permissionsManager.isAccessibilityGranted ? .green : .red)
                    Button("Open Settings") {
                        permissionsManager.requestAccessibilityPermission()
                    }
                }
                HStack {
                    Text("Screen Recording")
                    Spacer()
                    Text(thumbnailService.isScreenRecordingGranted ? "Granted" : "Not Granted")
                        .foregroundColor(thumbnailService.isScreenRecordingGranted ? .green : .red)
                    Button("Open Settings") {
                        if !thumbnailService.requestScreenRecordingPermission() {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                        }
                    }
                }
                HStack {
                    Text("Calendar")
                    Spacer()
                    Text(calendarService.isAuthorized ? "Granted" : "Not Granted")
                        .foregroundColor(calendarService.isAuthorized ? .green : .red)
                    Button("Open Settings") {
                        CalendarEventService.shared.checkPermission()
                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                    }
                }
            }
        }
        .padding()
    }
}
