import SwiftUI

struct LauncherOptionsTab: View {
    @ObservedObject var settings: TaskbarSettings
    
    var body: some View {
        Form {
            Section(header: Text("Command Launcher").font(.headline)) {
                Toggle("Enable bare command launcher", isOn: $settings.enableBareCommandLauncher)
            }
            
            Divider().padding(.vertical, 8)
            
            Section(header: Text("Apps Launcher").font(.headline)) {
                Picker("Shortcut", selection: $settings.appsLauncherShortcut) {
                    Text("Double Tap Command").tag(AppsLauncherShortcut.commandTap)
                    Text("Double Tap Right Command").tag(AppsLauncherShortcut.rightCommandTap)
                    Text("Control + Option + Return").tag(AppsLauncherShortcut.controlOptionReturn)
                    Text("Control + Option + Space").tag(AppsLauncherShortcut.controlOptionSpace)
                    Text("Option + Space").tag(AppsLauncherShortcut.optionSpace)
                }
                
                Picker("Style", selection: $settings.launcherStyle) {
                    Text("Anchored").tag(LauncherStyle.anchored)
                    Text("Floating").tag(LauncherStyle.floating)
                }
            }
        }
        .padding(20)
    }
}
