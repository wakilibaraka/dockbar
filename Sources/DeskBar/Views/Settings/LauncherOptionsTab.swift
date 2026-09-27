import SwiftUI

struct LauncherOptionsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var pinnedAppManager: PinnedAppManager
    @ObservedObject var launchpickManager = LaunchpickConfigManager.shared
    
    @AppStorage("launchpickShowPinnedApps") private var launchpickShowPinnedApps = true
    @AppStorage("launchpickShowMostUsedApps") private var launchpickShowMostUsedApps = true
    @AppStorage("allAppsLayout") private var allAppsLayout = AllAppsLayout.grid
    
    class ViewState: ObservableObject { 
        @Published var isShowingTaskbarPicker = false
        @Published var isShowingStartMenuPicker = false
    }
    @StateObject private var state = ViewState()
    
    var body: some View {
        VStack(spacing: 24) {
            
            SettingsCard(title: "Command Launcher", icon: "terminal") {
                SettingsRow(title: "Enable bare command launcher") {
                    Toggle("", isOn: $settings.enableBareCommandLauncher).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Shortcut") {
                    Picker("", selection: $settings.appsLauncherShortcut) {
                        Text("Double Tap Command").tag(AppsLauncherShortcut.commandTap)
                        Text("Double Tap Right Command").tag(AppsLauncherShortcut.rightCommandTap)
                        Text("Control + Option + Return").tag(AppsLauncherShortcut.controlOptionReturn)
                        Text("Control + Option + Space").tag(AppsLauncherShortcut.controlOptionSpace)
                        Text("Option + Space").tag(AppsLauncherShortcut.optionSpace)
                    }
                    .labelsHidden()
                    .frame(width: 170)
                }
                SettingsDivider()
                SettingsRow(title: "Style") {
                    Picker("", selection: $settings.launcherStyle) {
                        Text("Anchored").tag(LauncherStyle.anchored)
                        Text("Floating Center").tag(LauncherStyle.floating)
                        Text("Floating Bottom").tag(LauncherStyle.floatingBottom)
                    }
                    .labelsHidden()
                    .frame(width: 150)
                }
                SettingsDivider()
                SettingsRow(title: "Fuzzy Search") {
                    Toggle("", isOn: $settings.fuzzySearch).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Auto-open single search results") {
                    Toggle("", isOn: $settings.autoOpenSingleSearchResult).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
            }
            
            SettingsCard(title: "Start Menu Options", icon: "square.grid.2x2") {
                SettingsRow(title: "Show Pinned Apps") {
                    Toggle("", isOn: $launchpickShowPinnedApps).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "Show Most Used Apps") {
                    Toggle("", isOn: $launchpickShowMostUsedApps).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                SettingsDivider()
                SettingsRow(title: "All Apps Layout") {
                    Picker("", selection: $allAppsLayout) {
                        ForEach(AllAppsLayout.allCases) { layout in
                            Text(layout.rawValue.capitalized).tag(layout)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 150)
                }
            }
            
            SettingsCard(title: "Taskbar Pinned Apps", icon: "pin.fill") {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("These apps will always be pinned to the DeskBar taskbar.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Add Application...") {
                            state.isShowingTaskbarPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    
                    SettingsDivider()
                    
                    if pinnedAppManager.pinnedApps.isEmpty {
                        Text("No apps pinned to Taskbar")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(pinnedAppManager.pinnedApps, id: \.bundleIdentifier) { app in
                            HStack {
                                if let icon = app.icon {
                                    Image(nsImage: icon).resizable().frame(width: 24, height: 24)
                                } else {
                                    Image(systemName: "app.dashed").resizable().frame(width: 24, height: 24)
                                }
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(app.name).font(.system(size: 13, weight: .medium))
                                    Text(app.bundleIdentifier).font(.system(size: 11)).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    pinnedAppManager.unpin(bundleIdentifier: app.bundleIdentifier)
                                }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            SettingsDivider()
                        }
                    }
                }
            }
            
            SettingsCard(title: "Start Menu Pinned Apps", icon: "list.dash") {
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text("These apps appear in the pinned grid inside the Start Menu.")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Add Application...") {
                            state.isShowingStartMenuPicker = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(16)
                    
                    SettingsDivider()
                    
                    if launchpickManager.config.launchers.isEmpty {
                        Text("No apps pinned to Start Menu")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 24)
                    } else {
                        ForEach(0..<launchpickManager.config.launchers.count, id: \.self) { index in
                            let launcher = launchpickManager.config.launchers[index]
                            HStack {
                                Image(systemName: "app.fill").resizable().frame(width: 20, height: 20).foregroundColor(.accentColor)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(launcher.name).font(.system(size: 13, weight: .medium))
                                    Text(launcher.exec).font(.system(size: 11)).foregroundColor(.secondary)
                                }
                                Spacer()
                                Button(action: {
                                    launchpickManager.removeLauncher(at: index)
                                }) {
                                    Image(systemName: "trash").foregroundColor(.red)
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            SettingsDivider()
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: Binding(
                get: { state.isShowingTaskbarPicker || state.isShowingStartMenuPicker },
                set: { if !$0 { state.isShowingTaskbarPicker = false; state.isShowingStartMenuPicker = false } }
            ),
            allowedContentTypes: [.application],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first, let bundle = Bundle(url: url) {
                    let name = (bundle.infoDictionary?["CFBundleName"] as? String) ?? url.deletingPathExtension().lastPathComponent
                    
                    if state.isShowingTaskbarPicker {
                        if let bundleIdentifier = bundle.bundleIdentifier {
                            pinnedAppManager.pin(bundleIdentifier: bundleIdentifier, name: name)
                        }
                    } else if state.isShowingStartMenuPicker {
                        let exec = "open -a '\(name)'"
                        let launcher = ConfigLauncher(name: name, exec: exec, icon: nil)
                        launchpickManager.addLauncher(launcher)
                    }
                }
            case .failure(let error):
                print("Failed to select app: \(error.localizedDescription)")
            }
        }
    }
}
