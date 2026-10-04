import SwiftUI

struct LauncherSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var pinnedAppManager: PinnedAppManager

    @ObservedObject private var launchpickManager = LaunchpickConfigManager.shared
    @AppStorage("launchpickShowPinnedApps") private var showPinnedApps = true
    @AppStorage("launchpickShowMostUsedApps") private var showMostUsedApps = true
    @AppStorage("allAppsLayout") private var allAppsLayout = AllAppsLayout.grid

    var body: some View {
        SettingsPage(
            title: "Launcher",
            subtitle: "Search apps, files, and commands from anywhere."
        ) {
            SettingsGroup("Opening the Launcher") {
                ToggleRow(
                    "Enable Launcher",
                    help: "Open the launcher with the shortcut below.",
                    isOn: $settings.enableBareCommandLauncher
                )
                PickerRow(
                    "Shortcut",
                    help: "The gesture or key combination that opens the launcher.",
                    selection: $settings.appsLauncherShortcut,
                    options: AppsLauncherShortcut.allCases.map { ($0.displayName, $0) },
                    width: 240
                )
                .disabled(!settings.enableBareCommandLauncher)
                PickerRow(
                    "Presentation",
                    help: "Anchored grows out of the bar; floating centres a panel on screen.",
                    selection: $settings.launcherStyle,
                    options: LauncherStyle.allCases.map { ($0.displayName, $0) }
                )
                .disabled(!settings.enableBareCommandLauncher)
            }

            SettingsGroup("Searching") {
                ToggleRow(
                    "Fuzzy Search",
                    help: "Find close matches even when the query is not an exact name.",
                    isOn: $settings.fuzzySearch
                )
                ToggleRow(
                    "Open Single Results",
                    help: "Launch the only match as soon as it is the sole result.",
                    isOn: $settings.autoOpenSingleSearchResult
                )
            }

            SettingsGroup("Launchpick", footer: "Launchpick is the launcher's all-apps view. Shortcuts are shell commands DockBar can run for you.") {
                Toggle("Show pinned apps", isOn: $showPinnedApps)
                Toggle("Show most-used apps", isOn: $showMostUsedApps)
                PickerRow(
                    "All Apps Layout",
                    help: "Arrange the all-apps grid.",
                    selection: $allAppsLayout,
                    options: AllAppsLayout.allCases.map { ($0.rawValue, $0) },
                    width: 180
                )

                HStack {
                    ChooseApplicationButton { url in
                        let name = Bundle(url: url)?.object(forInfoDictionaryKey: "CFBundleName") as? String
                            ?? url.deletingPathExtension().lastPathComponent
                        launchpickManager.addLauncher(
                            ConfigLauncher(name: name, exec: "open -a '\(name)'", icon: nil)
                        )
                    }
                    Spacer()
                }

                if launchpickManager.config.launchers.isEmpty {
                    Text("No custom shortcuts yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(launchpickManager.config.launchers.enumerated()), id: \.element.name) { index, launcher in
                        HStack(spacing: 10) {
                            Image(systemName: "app.fill")
                                .foregroundStyle(.secondary)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(launcher.name)
                                Text(launcher.exec)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.middle)
                            }
                            Spacer()
                            Button("Remove", role: .destructive) {
                                launchpickManager.removeLauncher(at: index)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            SettingsGroup("Pinned Apps", footer: "Pinned apps stay in the bar even when they have no open windows.") {
                HStack {
                    ChooseApplicationButton { url in
                        guard let bundle = Bundle(url: url),
                              let bundleID = bundle.bundleIdentifier else { return }
                        let name = bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
                            ?? url.deletingPathExtension().lastPathComponent
                        pinnedAppManager.pin(bundleIdentifier: bundleID, name: name)
                    }
                    Spacer()
                }

                if pinnedAppManager.pinnedApps.isEmpty {
                    Text("No pinned apps yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(pinnedAppManager.pinnedApps, id: \.bundleIdentifier) { app in
                        HStack(spacing: 10) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 20, height: 20)
                            }
                            Text(app.name)
                            Spacer()
                            Button("Remove", role: .destructive) {
                                pinnedAppManager.unpin(bundleIdentifier: app.bundleIdentifier)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }
        }
    }
}