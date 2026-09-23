import SwiftUI
import AppKit

struct OnboardingView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject var calendarService = CalendarEventService.shared
    let completion: () -> Void
    
    class ViewState: ObservableObject { @Published var step = 0 }
    @StateObject private var state = ViewState()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header / Graphic area
            ZStack {
                Color.black.opacity(0.2)
                
                if state.step == 0 {
                    Image(nsImage: NSApplication.shared.applicationIconImage ?? NSImage())
                        .resizable()
                        .frame(width: 128, height: 128)
                        .shadow(radius: 20)
                        .transition(.scale.combined(with: .opacity))
                } else if state.step == 1 {
                    Image(systemName: "lock.shield.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.blue.gradient)
                        .transition(.scale.combined(with: .opacity))
                } else if state.step == 2 {
                    Image(systemName: "paintpalette.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(.orange.gradient)
                        .transition(.scale.combined(with: .opacity))
                } else if state.step == 3 {
                    Image(systemName: "macwindow.badge.plus")
                        .font(.system(size: 80))
                        .foregroundStyle(.purple.gradient)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .frame(height: 220)
            .clipped()
            
            // Content area
            VStack(spacing: 24) {
                if state.step == 0 {
                    VStack(spacing: 8) {
                        Text("Welcome to DeskBar")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                        Text("A modern, highly customizable taskbar replacement for macOS. Let's get you set up in just a few clicks.")
                            .font(.system(size: 15))
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 40)
                    }
                } else if state.step == 1 {
                    VStack(spacing: 16) {
                        Text("Permissions required")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        
                        VStack(spacing: 12) {
                            PermissionRow(
                                title: "Device Control and Data Access",
                                description: "Required to interact with windows and switch apps.",
                                isGranted: permissionsManager.isAccessibilityGranted,
                                action: { permissionsManager.requestAccessibilityPermission() }
                            )
                            PermissionRow(
                                title: "Screen Recording",
                                description: "Required for window thumbnails.",
                                isGranted: thumbnailService.isScreenRecordingGranted,
                                action: {
                                    if !thumbnailService.requestScreenRecordingPermission() {
                                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                                    }
                                }
                            )
                            PermissionRow(
                                title: "Calendar",
                                description: "Required to show upcoming events in the widget.",
                                isGranted: calendarService.isAuthorized,
                                action: {
                                    CalendarEventService.shared.checkPermission()
                                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
                                }
                            )
                        }
                        .padding(.horizontal, 40)
                    }
                } else if state.step == 2 {
                    VStack(spacing: 16) {
                        Text("Choose Your Style")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Select how you want DeskBar to look and behave.")
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 20) {
                            ForEach(TaskbarMode.allCases) { mode in
                                VStack(spacing: 12) {
                                    Image(systemName: mode == .custom ? "macwindow" : mode == .windows ? "window.cascading" : "dock.rectangle")
                                        .font(.system(size: 40))
                                        .foregroundColor(settings.taskbarMode == mode ? .white : .secondary)
                                    Text(mode.displayName)
                                        .font(.title3.bold())
                                    Text(mode.subtitle)
                                        .font(.caption)
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(settings.taskbarMode == mode ? .white.opacity(0.8) : .secondary)
                                }
                                .padding()
                                .frame(width: 200, height: 180)
                                .background(settings.taskbarMode == mode ? Color.blue : Color.white.opacity(0.05))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(settings.taskbarMode == mode ? Color.blue.opacity(0.5) : Color.white.opacity(0.1), lineWidth: 2)
                                )
                                .onTapGesture {
                                    withAnimation { settings.taskbarMode = mode }
                                }
                            }
                        }
                        .padding(.top, 20)
                    }
                } else if state.step == 3 {
                    VStack(spacing: 16) {
                        Text("Personalize Your DeskBar")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Choose your preferred layout and window behavior.")
                            .foregroundColor(.secondary)
                        
                        Form {
                            Picker("Layout Theme", selection: $settings.layoutMode) {
                                Text("Compact Glass").tag(DeskBarLayoutMode.compactGlass)
                                Text("Full Width Glass").tag(DeskBarLayoutMode.fullWidthGlass)
                                Text("Full Width (Solid)").tag(DeskBarLayoutMode.fullWidth)
                            }
                            .padding(.bottom, 8)
                            
                            Picker("Window Grouping", selection: $settings.groupingMode) {
                                Text("Never").tag(WindowGroupingMode.never)
                                Text("Automatic").tag(WindowGroupingMode.automatic)
                                Text("Always").tag(WindowGroupingMode.always)
                            }
                            
                            Toggle("Track WiFi & Bluetooth connections", isOn: $settings.showConnections)
                                .padding(.top, 10)
                            
                            if settings.showConnections {
                                Toggle("Enable connection alerts", isOn: Binding(get: {
                                    settings.notifyBluetoothConnect || settings.notifyBluetoothLowBattery || settings.notifyWiFiChange
                                }, set: { val in
                                    if val {
                                        NotificationManager.shared.requestAuthorization { granted in
                                            DispatchQueue.main.async {
                                                if granted {
                                                    settings.notifyBluetoothConnect = true
                                                    settings.notifyBluetoothLowBattery = true
                                                    settings.notifyWiFiChange = true
                                                }
                                            }
                                        }
                                    } else {
                                        settings.notifyBluetoothConnect = false
                                        settings.notifyBluetoothLowBattery = false
                                        settings.notifyWiFiChange = false
                                        settings.notifyWiFiWeak = false
                                    }
                                }))
                                .padding(.leading, 20)
                                .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: 400)
                        .padding(.top, 10)
                    }
                } else if state.step == 4 {
                    VStack(spacing: 16) {
                        Text("Dock Integration")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Choose how DeskBar interacts with the native macOS Dock.")
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.nativeDockBehavior) {
                            Text("Independent (Both visible)").tag(NativeDockBehavior.independent)
                            Text("Hide Native Dock").tag(NativeDockBehavior.hidden)
                            Text("Replace (Autohide)").tag(NativeDockBehavior.autoHide)
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                        .padding(.top, 10)
                    }
                }
                
                Spacer()
                
                // Footer
                HStack {
                    if state.step > 0 {
                        Button("Back") {
                            withAnimation { state.step -= 1 }
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    Spacer()
                    
                    Button(state.step == 4 ? "Finish" : "Continue") {
                        if state.step == 4 {
                            completion()
                        } else {
                            withAnimation { state.step += 1 }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding(.top, 30)
        }
        .frame(width: 800, height: 600)
    }
}

struct PermissionRow: View {
    let title: String
    let description: String
    let isGranted: Bool
    let action: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if isGranted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            } else {
                Button("Grant Access", action: action)
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(6)
            }
        }
        .padding(16)
        .background(Color.black.opacity(0.2))
        .cornerRadius(12)
    }
}
