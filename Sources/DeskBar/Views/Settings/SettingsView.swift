import SwiftUI

enum SettingsTab: String, CaseIterable, Identifiable, Hashable {
    case general = "General"
    case dock = "Dock"
    case behavior = "Behavior"
    case launcher = "Launcher"
    case elements = "Elements"
    case flyouts = "Flyouts"
    
    var id: SettingsTab { self }
    
    var icon: String {
        switch self {
        case .general: return "gearshape"
        case .dock: return "macwindow.badge.plus"
        case .behavior: return "hand.tap"
        case .launcher: return "command"
        case .elements: return "puzzlepiece.extension"
        case .flyouts: return "menubar.rectangle"
        }
    }
}

struct SettingsView: View {
    @ObservedObject var settings: TaskbarSettings
    let permissionsManager: PermissionsManager
    let thumbnailService: ThumbnailService
    let blacklistManager: BlacklistManager
    let pinnedAppManager: PinnedAppManager
    let weatherService: WeatherService?
    
    class ViewState: ObservableObject {
        @Published var selection: SettingsTab? = .general
    }
    @StateObject private var state = ViewState()
    
    var body: some View {
        NavigationSplitView {
            List(SettingsTab.allCases, selection: $state.selection) { tab in
                NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .font(.system(size: 13, weight: .regular))
                }
            }
            .navigationSplitViewColumnWidth(min: 160, ideal: 180, max: 220)
            .listStyle(.sidebar)
        } detail: {
            ZStack {
                Color(nsColor: .windowBackgroundColor)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        Text(state.selection?.rawValue ?? "")
                            .font(.system(size: 24, weight: .semibold))
                            .padding(.bottom, 8)
                        
                        detailContent()
                    }
                    .padding(32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
    
    @ViewBuilder
    private func detailContent() -> some View {
        if let tab = state.selection {
            switch tab {
            case .general:
                GeneralSettingsTab(settings: settings, permissionsManager: permissionsManager, thumbnailService: thumbnailService, blacklistManager: blacklistManager, weatherService: weatherService)
            case .dock:
                DockSettingsTab(settings: settings)
            case .behavior:
                BehaviorSettingsTab(settings: settings)
            case .launcher:
                LauncherOptionsTab(settings: settings, pinnedAppManager: pinnedAppManager)
            case .elements:
                TaskbarElementsTab(settings: settings)
            case .flyouts:
                StatusFlyoutsTab(settings: settings)
            }
        } else {
            Text("Select a category")
        }
    }
}
