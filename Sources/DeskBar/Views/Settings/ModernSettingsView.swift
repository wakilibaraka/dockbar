import SwiftUI

struct ModernSettingsView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var pinnedAppManager: PinnedAppManager
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    
    var body: some View {
        TabView {
            GeneralSettingsTab(settings: settings, permissionsManager: permissionsManager, thumbnailService: thumbnailService)
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }
            
            AppearanceSettingsTab(settings: settings)
                .tabItem {
                    Label("Appearance", systemImage: "paintbrush")
                }
            
            BehaviorSettingsTab(settings: settings)
                .tabItem {
                    Label("Behavior", systemImage: "hand.tap")
                }
            
            WidgetsSettingsTab(settings: settings)
                .tabItem {
                    Label("Widgets", systemImage: "widget.small")
                }
            
            PluginsSettingsTab(settings: settings)
                .tabItem {
                    Label("Plugins", systemImage: "puzzlepiece.extension")
                }
            
            LauncherSettingsTab(pinnedAppManager: pinnedAppManager)
                .tabItem {
                    Label("Launcher", systemImage: "rocket")
                }
            
            QuickSettingsTab(settings: settings)
                .tabItem {
                    Label("Quick Settings", systemImage: "switch.2")
                }
                
            BlacklistSettingsTab(blacklistManager: blacklistManager)
                .tabItem {
                    Label("Blacklist", systemImage: "nosign")
                }
        }
        .padding(20)
        .frame(width: 660, height: 480)
    }
}
