import SwiftUI
import Collaboration

struct LauncherFooterView: View {
    class ViewState: ObservableObject {
        @Published var showingPowerConfirmation = false
        @Published var powerAction: PowerAction?
    }
    @StateObject private var state = ViewState()
    
    enum PowerAction {
        case restart, shutdown, logout
    }
    
    var body: some View {
        HStack {
            // User Profile
            HStack(spacing: 12) {
                if let identity = CBIdentity(name: NSUserName(), authority: .default()), let image = identity.image {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                } else {
                    Circle()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text(initials(from: NSFullUserName()))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.primary)
                        )
                }
                Text(NSFullUserName())
                    .font(.system(size: 14, weight: .medium))
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 16) {
                Button(action: {
                    NSApp.sendAction(Selector(("openSettings:")), to: nil, from: nil)
                    LaunchpickManager.shared.hide()
                }) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Menu {
                    Button(action: { lockScreen() }) {
                        Label("Lock Screen", systemImage: "lock")
                    }
                    Button(action: { sleepMac() }) {
                        Label("Sleep", systemImage: "moon.zzz")
                    }
                    Divider()
                    Button(action: { triggerPowerAction(.restart) }) {
                        Label("Restart...", systemImage: "restart.circle")
                    }
                    Button(action: { triggerPowerAction(.shutdown) }) {
                        Label("Shut Down...", systemImage: "power")
                    }
                    Button(action: { triggerPowerAction(.logout) }) {
                        Label("Log Out...", systemImage: "person.crop.circle.badge.xmark")
                    }
                } label: {
                    Image(systemName: "power")
                        .font(.system(size: 16))
                        .foregroundColor(.primary)
                }
                .menuStyle(BorderlessButtonMenuStyle(showsMenuIndicator: false))
                .fixedSize()
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(Color.primary.opacity(0.05))
        .alert(isPresented: $state.showingPowerConfirmation) {
            let title: String
            let action: () -> Void
            switch state.powerAction {
            case .restart:
                title = "Are you sure you want to restart your computer now?"
                action = restartMac
            case .shutdown:
                title = "Are you sure you want to shut down your computer now?"
                action = shutdownMac
            case .logout:
                title = "Are you sure you want to log out now?"
                action = logoutMac
            case .none:
                title = ""
                action = {}
            }
            return Alert(
                title: Text(title),
                primaryButton: .destructive(Text("Confirm"), action: action),
                secondaryButton: .cancel()
            )
        }
    }
    
    private func initials(from name: String) -> String {
        let components = name.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !components.isEmpty else { return "U" }
        if components.count == 1 { return String(components[0].prefix(1)).uppercased() }
        return (String(components.first!.prefix(1)) + String(components.last!.prefix(1))).uppercased()
    }
    
    private func triggerPowerAction(_ action: PowerAction) {
        state.powerAction = action
        state.showingPowerConfirmation = true
    }
    
    private func runAppleScript(_ source: String) {
        let script = "tell application \"System Events\" to " + source
        DispatchQueue.global(qos: .userInitiated).async {
            var error: NSDictionary?
            if let appleScript = NSAppleScript(source: script) {
                appleScript.executeAndReturnError(&error)
                if let err = error {
                    print("AppleScript error: \\(err)")
                }
            }
        }
    }
    
    private func sleepMac() { runAppleScript("sleep") }
    private func restartMac() { runAppleScript("restart") }
    private func shutdownMac() { runAppleScript("shut down") }
    private func logoutMac() { runAppleScript("log out") }
    
    private func lockScreen() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["displaysleepnow"]
        try? task.run()
    }
}
