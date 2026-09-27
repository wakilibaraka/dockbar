import SwiftUI
import CoreLocation

struct GeneralSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var calendarService: CalendarEventService
    let weatherService: WeatherService?
    
    class ViewState: ObservableObject { @Published var newBlacklistBundleID = "" }
    @StateObject private var state = ViewState()
    
    init(settings: TaskbarSettings, permissionsManager: PermissionsManager, thumbnailService: ThumbnailService, blacklistManager: BlacklistManager, weatherService: WeatherService? = nil) {
        self.settings = settings
        self.permissionsManager = permissionsManager
        self.thumbnailService = thumbnailService
        self.blacklistManager = blacklistManager
        self.weatherService = weatherService
        self.calendarService = CalendarEventService.shared
    }

    var body: some View {
        VStack(spacing: 24) {
            
            SettingsCard(title: "Startup", icon: "power") {
                SettingsRow(title: "Start at login", subtitle: "Launch DeskBar automatically when you log in") {
                    Toggle("", isOn: $settings.startAtLogin)
                        .labelsHidden()
                        .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
            }
            
            SettingsCard(title: "Permissions", icon: "lock.shield") {
                SettingsRow(title: "Device Control", subtitle: "Accessibility permission to manage windows") {
                    HStack {
                        Image(systemName: permissionsManager.isAccessibilityGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(permissionsManager.isAccessibilityGranted ? .green : .red)
                        Button("Settings") {
                            permissionsManager.requestAccessibilityPermission()
                        }
                    }
                }
                SettingsDivider()
                SettingsRow(title: "Screen Recording", subtitle: "Required for window hover thumbnails") {
                    HStack {
                        Image(systemName: thumbnailService.isScreenRecordingGranted ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(thumbnailService.isScreenRecordingGranted ? .green : .red)
                        Button("Settings") {
                            if !thumbnailService.requestScreenRecordingPermission() {
                                NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                            }
                        }
                    }
                }
                SettingsDivider()
                SettingsRow(title: "Calendar", subtitle: "Required to show events in the flyout") {
                    HStack {
                        Image(systemName: calendarService.isAuthorized ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(calendarService.isAuthorized ? .green : .red)
                        Button("Settings") {
                            CalendarEventService.shared.checkPermission()
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                        }
                    }
                }
            }
            
            SettingsCard(title: "Hidden Applications", icon: "eye.slash") {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        TextField("Bundle Identifier (e.g. com.apple.Safari)", text: $state.newBlacklistBundleID)
                            .textFieldStyle(.roundedBorder)
                        Button("Add") {
                            blacklistManager.add(bundleIdentifier: state.newBlacklistBundleID)
                            state.newBlacklistBundleID = ""
                        }
                        .disabled(state.newBlacklistBundleID.isEmpty)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    
                    SettingsDivider()
                    
                    if blacklistManager.blacklistedBundleIDs.isEmpty {
                        Text("No apps hidden")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(Array(blacklistManager.blacklistedBundleIDs).sorted(), id: \.self) { bundleID in
                            HStack {
                                Text(bundleID)
                                    .font(.system(size: 13, weight: .regular))
                                Spacer()
                                Button(action: {
                                    blacklistManager.remove(bundleIdentifier: bundleID)
                                }) {
                                    Image(systemName: "trash")
                                        .foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            SettingsDivider()
                        }
                    }
                }
            }
        }
    }
}
