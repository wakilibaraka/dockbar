import SwiftUI
import AppKit
import Combine

final class StartMenuViewController: NSHostingController<StartMenuView> {
    init(settings: TaskbarSettings, pinnedAppManager: PinnedAppManager) {
        super.init(rootView: StartMenuView(settings: settings, pinnedApps: pinnedAppManager))
    }
    
    @MainActor required dynamic init?(coder: NSCoder) { fatalError() }
}

class StartMenuState: ObservableObject {
    @Published var mostUsed: [LaunchpickItem] = []
    @Published var searchText = ""
    
    func loadMostUsed() {
        SpotlightMostUsed.shared.fetch(limit: 10) { items in
            DispatchQueue.main.async {
                self.mostUsed = items
            }
        }
    }
}

struct StartMenuView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var pinnedApps: PinnedAppManager
    @StateObject private var state = StartMenuState()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search apps, files, and web", text: $state.searchText)
                    .textFieldStyle(PlainTextFieldStyle())
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            
            // Pinned Apps Grid
            VStack(alignment: .leading) {
                Text("Pinned")
                    .font(.headline)
                    .padding(.horizontal, 16)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 6), spacing: 16) {
                    ForEach(filteredPinnedApps, id: \.bundleIdentifier) { app in
                        AppGridItem(app: app)
                    }
                }
                .padding(.horizontal, 16)
            }
            
            // Recommended / Most Used
            VStack(alignment: .leading) {
                Text("Recommended")
                    .font(.headline)
                    .padding(.horizontal, 16)
                
                List(filteredMostUsed, id: \.name) { app in
                    AppListItem(app: app)
                }
                .listStyle(PlainListStyle())
                .frame(maxHeight: .infinity)
            }
            
            Spacer(minLength: 0)
            
            // Power Row
            HStack {
                Spacer()
                Button(action: { sleepMac() }) {
                    Image(systemName: "moon.fill")
                }
                Button(action: { restartMac() }) {
                    Image(systemName: "restart.circle.fill")
                }
                Button(action: { shutdownMac() }) {
                    Image(systemName: "power")
                }
            }
            .buttonStyle(PlainButtonStyle())
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(width: 400, height: 500)
        .onAppear {
            state.loadMostUsed()
        }
    }
    
    private var filteredPinnedApps: [PinnedApp] {
        if state.searchText.isEmpty { return pinnedApps.pinnedApps }
        return pinnedApps.pinnedApps.filter { $0.name.localizedCaseInsensitiveContains(state.searchText) }
    }
    
    private var filteredMostUsed: [LaunchpickItem] {
        if state.searchText.isEmpty { return state.mostUsed }
        return state.mostUsed.filter { $0.name.localizedCaseInsensitiveContains(state.searchText) }
    }
    
    private func sleepMac() {
        let task = Process()
        task.launchPath = "/usr/bin/pmset"
        task.arguments = ["sleepnow"]
        try? task.run()
    }
    
    private func restartMac() {
        let script = "tell application \"System Events\" to restart"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
    
    private func shutdownMac() {
        let script = "tell application \"System Events\" to shut down"
        NSAppleScript(source: script)?.executeAndReturnError(nil)
    }
}

struct AppGridItem: View {
    let app: PinnedApp
    var body: some View {
        VStack {
            if let icon = app.icon {
                Image(nsImage: icon)
                    .resizable()
                    .frame(width: 32, height: 32)
            } else {
                Image(systemName: "app.fill")
                    .resizable()
                    .frame(width: 32, height: 32)
            }
            Text(app.name)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(width: 50, height: 60)
        .contentShape(Rectangle())
        .onTapGesture {
            if let url = app.applicationURL {
                NSWorkspace.shared.open(url)
            }
        }
    }
}

struct AppListItem: View {
    let app: LaunchpickItem
    var body: some View {
        HStack {
            Image(nsImage: app.icon)
                .resizable()
                .frame(width: 24, height: 24)
            VStack(alignment: .leading) {
                Text(app.name).font(.subheadline)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            LaunchpickManager.shared.launch(item: app)
        }
    }
}
