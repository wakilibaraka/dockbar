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
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                GroupBox(label: Text("Command Launcher").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Enable bare command launcher", isOn: $settings.enableBareCommandLauncher)
                        
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
                        
                        Group {
                            Toggle("Fuzzy Search", isOn: $settings.fuzzySearch)
                            Toggle("Auto-open single search results", isOn: $settings.autoOpenSingleSearchResult)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Start Menu Options").font(.headline)) {
                    VStack(alignment: .leading, spacing: 16) {
                        Toggle("Show Pinned Apps", isOn: $launchpickShowPinnedApps)
                        Toggle("Show Most Used Apps", isOn: $launchpickShowMostUsedApps)
                        
                        HStack {
                            Text("All Apps Layout:")
                            Picker("", selection: $allAppsLayout) {
                                ForEach(AllAppsLayout.allCases) { layout in
                                    Text(layout.rawValue).tag(layout)
                                }
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Start Menu Pinned Apps").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("These apps appear in the pinned grid inside the Start Menu.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Add Application...") {
                                state.isShowingStartMenuPicker = true
                            }
                            Spacer()
                        }
                        
                        List {
                            ForEach(0..<launchpickManager.config.launchers.count, id: \.self) { index in
                                let launcher = launchpickManager.config.launchers[index]
                                HStack {
                                    Image(systemName: "app.fill")
                                        .resizable()
                                        .frame(width: 20, height: 20)
                                        .foregroundColor(.accentColor)
                                    
                                    VStack(alignment: .leading) {
                                        Text(launcher.name)
                                        Text(launcher.exec)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        launchpickManager.removeLauncher(at: index)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                            .onMove { source, destination in
                                launchpickManager.moveLauncher(from: source, to: destination)
                            }
                        }
                        .frame(minHeight: 150)
                        .border(Color.secondary.opacity(0.2))
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                GroupBox(label: Text("Taskbar Pinned Apps").font(.headline)) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("These apps will always be pinned to the DeskBar taskbar.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Add Application...") {
                                state.isShowingTaskbarPicker = true
                            }
                            Spacer()
                        }
                        
                        List {
                            ForEach(pinnedAppManager.pinnedApps, id: \.bundleIdentifier) { app in
                                HStack {
                                    if let icon = app.icon {
                                        Image(nsImage: icon)
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    } else {
                                        Image(systemName: "app.dashed")
                                            .resizable()
                                            .frame(width: 24, height: 24)
                                    }
                                    
                                    VStack(alignment: .leading) {
                                        Text(app.name)
                                        Text(app.bundleIdentifier)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Spacer()
                                    Button(action: {
                                        pinnedAppManager.unpin(bundleIdentifier: app.bundleIdentifier)
                                    }) {
                                        Image(systemName: "trash")
                                            .foregroundColor(.red)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                                .padding(.vertical, 4)
                            }
                            .onMove { source, destination in
                                pinnedAppManager.reorder(from: source.first ?? 0, to: destination)
                            }
                        }
                        .frame(minHeight: 150)
                        .border(Color.secondary.opacity(0.2))
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
            }
            .padding(20)
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
