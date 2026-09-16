import re

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'r') as f:
    content = f.read()

# I will replace AccessoryAppsListView entirely
new_accessory_view = """
class AccessoryAppsViewModel: ObservableObject {
    @Published var apps: [NSRunningApplication] = []
    
    init() {
        refreshApps()
    }
    
    func refreshApps() {
        self.apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .accessory || $0.activationPolicy == .prohibited }
            .filter { $0.localizedName != nil && !$0.localizedName!.isEmpty }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}

struct AccessoryAppsListView: View {
    @StateObject private var viewModel = AccessoryAppsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if viewModel.apps.isEmpty {
                    Text("No background processes found.")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                } else {
                    ForEach(viewModel.apps, id: \\.processIdentifier) { app in
                        HStack {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "gearshape.fill")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(app.localizedName ?? "Unknown")
                                .font(.system(size: 12))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            Button(action: {
                                app.terminate()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.refreshApps()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                }
            }
        }
        .frame(maxHeight: 120)
        .onAppear {
            viewModel.refreshApps()
        }
    }
}
"""

content = re.sub(r"struct AccessoryAppsListView: View \{.*", new_accessory_view, content, flags=re.DOTALL)

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'w') as f:
    f.write(content)

