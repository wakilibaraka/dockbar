import SwiftUI

struct OnboardingView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject var calendarService = CalendarEventService.shared
    
    let completion: () -> Void
    
    class ViewState: ObservableObject {
        @Published var step = 0
    }
    @StateObject private var state = ViewState()
    
    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                Spacer()
                
                if state.step == 0 {
                    VStack(spacing: 16) {
                        Image(nsImage: NSApplication.shared.applicationIconImage)
                            .resizable()
                            .frame(width: 96, height: 96)
                            .shadow(radius: 10)
                            .padding(.bottom, 10)
                            .transition(.scale)
                        
                        Text("Welcome to DeskBar")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .transition(.opacity)
                        Text("A fully native, lightweight taskbar for macOS.")
                            .foregroundColor(.secondary)
                            .font(.title3)
                            .transition(.opacity)
                    }
                } else if state.step == 1 {
                    VStack(spacing: 16) {
                        Text("Permissions")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("DeskBar needs a few permissions to function properly.")
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 12) {
                            PermissionRow(
                                title: "Accessibility (Required)",
                                description: "Required to monitor active windows and bring them to the front.",
                                isGranted: permissionsManager.isAccessibilityGranted,
                                action: { permissionsManager.requestAccessibilityPermission() }
                            )
                            PermissionRow(
                                title: "Screen Recording (Required)",
                                description: "Required to show window thumbnails when hovering.",
                                isGranted: thumbnailService.isScreenRecordingGranted,
                                action: {
                                    if !thumbnailService.requestScreenRecordingPermission() {
                                        NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ScreenCapture")!)
                                    }
                                }
                            )
                            PermissionRow(
                                title: "Calendar (Optional)",
                                description: "Required to show upcoming events in the calendar widget.",
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
                        Text("Personalize DeskBar")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("Choose your preferred layout and behavior.")
                            .foregroundColor(.secondary)
                        
                        Form {
                            Picker("Layout Theme", selection: $settings.layoutMode) {
                                Text("Windows 11 (Floating)").tag(DeskBarLayoutMode.windows11Floating)
                                Text("Windows 11 (Full Width)").tag(DeskBarLayoutMode.windows11FullWidth)
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
                        }
                        .frame(maxWidth: 400)
                        .padding(.top, 10)
                    }
                } else if state.step == 3 {
                    VStack(spacing: 16) {
                        Text("Dock Integration")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                        Text("How should DeskBar interact with the native macOS Dock?")
                            .foregroundColor(.secondary)
                        
                        Picker("", selection: $settings.dockMode) {
                            Text("Independent").tag(DockMode.independent)
                            Text("Hide Native Dock").tag(DockMode.hidden)
                            Text("Replace (Autohide)").tag(DockMode.autoHide)
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
                    
                    Button(state.step == 3 ? "Finish" : "Continue") {
                        if state.step == 3 {
                            completion()
                        } else {
                            withAnimation { state.step += 1 }
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 8)
                    .background(isNextButtonDisabled ? Color.gray.opacity(0.5) : Color.accentColor)
                    .foregroundColor(isNextButtonDisabled ? Color.secondary : .white)
                    .cornerRadius(8)
                    .disabled(isNextButtonDisabled)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 30)
            }
            .padding(.top, 40)
        }
        .frame(width: 700, height: 450)
    }
    
    private var isNextButtonDisabled: Bool {
        if state.step == 1 {
            return !permissionsManager.isAccessibilityGranted || !thumbnailService.isScreenRecordingGranted
        }
        return false
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
        .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        .cornerRadius(12)
    }
}
