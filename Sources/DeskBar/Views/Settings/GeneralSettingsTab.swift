import SwiftUI

struct GeneralSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var calendarService: CalendarEventService
    
    class ViewState: ObservableObject { @Published var newBlacklistBundleID = "" }
    @StateObject private var state = ViewState()
    
    init(settings: TaskbarSettings, permissionsManager: PermissionsManager, thumbnailService: ThumbnailService, blacklistManager: BlacklistManager) {
        self.settings = settings
        self.permissionsManager = permissionsManager
        self.thumbnailService = thumbnailService
        self.blacklistManager = blacklistManager
        self.calendarService = CalendarEventService.shared
    }
    
    var body: some View {
        Form {
            Section(header: Text("Startup").font(.headline)) {
                Toggle("Start at login", isOn: $settings.startAtLogin)
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
            
            Divider().padding(.vertical, 8)
            
            Section(header: Text("Hidden Applications (Blacklist)").font(.headline)) {
                Text("Apps added here will not appear in the taskbar.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack {
                    TextField("Bundle Identifier (e.g. com.apple.Safari)", text: $state.newBlacklistBundleID)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button("Add") {
                        blacklistManager.add(bundleIdentifier: state.newBlacklistBundleID)
                        state.newBlacklistBundleID = ""
                    }
                    .disabled(state.newBlacklistBundleID.isEmpty)
                }
                
                List {
                    ForEach(Array(blacklistManager.blacklistedBundleIDs).sorted(), id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                            Spacer()
                            Button(action: {
                                blacklistManager.remove(bundleIdentifier: bundleID)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                .frame(minHeight: 100)
                .border(Color.secondary.opacity(0.2))
            }
        }
        .padding(20)
    }
}
