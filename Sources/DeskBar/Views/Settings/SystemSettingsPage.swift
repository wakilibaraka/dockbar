import SwiftUI

struct SystemSettingsPage: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject private var calendarService = CalendarEventService.shared
    @StateObject private var notificationAuthorization = NotificationAuthorizationModel()

    var body: some View {
        SettingsPage(
            title: "System",
            subtitle: "Startup, permissions, and integration with your development tools."
        ) {
            SettingsGroup("Startup") {
                ToggleRow(
                    "Open at Login",
                    help: "Launch DockBar when you sign in.",
                    isOn: $settings.startAtLogin
                )
                SettingsRow(
                    "Version",
                    help: "Check GitHub for a newer release without leaving Settings."
                ) {
                    HStack(spacing: 10) {
                        Text(Self.versionString)
                            .monospacedDigit()
                            .foregroundStyle(.secondary)
                        Button("Check for Updates…") {
                            Task { await UpdatePresenter.checkAndPresent() }
                        }
                    }
                }
            }

            SettingsGroup(
                "Permissions",
                footer: "DockBar works without these, but each one unlocks a feature."
            ) {
                PermissionRow(
                    title: "Accessibility",
                    pane: "Privacy_Accessibility",
                    isGranted: permissionsManager.isAccessibilityGranted,
                    request: { permissionsManager.requestAccessibilityPermission() }
                )
                PermissionRow(
                    title: "Screen Recording",
                    pane: "Privacy_ScreenCapture",
                    isGranted: thumbnailService.isScreenRecordingGranted,
                    request: {
                        if !thumbnailService.requestScreenRecordingPermission() {
                            openSystemSettingsPane("Privacy_ScreenCapture")
                        }
                    }
                )
                PermissionRow(
                    title: "Calendar",
                    pane: "Privacy_Calendars",
                    isGranted: calendarService.isAuthorized,
                    request: {
                        calendarService.checkPermission()
                        openSystemSettingsPane("Privacy_Calendars")
                    }
                )
                PermissionRow(
                    title: "Notifications",
                    pane: "Privacy_Notifications",
                    isGranted: notificationAuthorization.isAuthorized,
                    request: {
                        Task { await notificationAuthorization.request() }
                    }
                )
            }

            SettingsGroup(
                "Hidden Applications",
                footer: "Hidden apps never appear in the bar, in any style."
            ) {
                HStack {
                    ChooseApplicationButton { url in
                        guard let bundleID = Bundle(url: url)?.bundleIdentifier else { return }
                        blacklistManager.add(bundleIdentifier: bundleID)
                    }
                    Spacer()
                }

                if blacklistManager.blacklistedBundleIDs.isEmpty {
                    Text("No hidden apps.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(blacklistManager.blacklistedBundleIDs.sorted(), id: \.self) { bundleID in
                        HStack {
                            Text(bundleID)
                                .font(.callout)
                            Spacer()
                            Button("Remove", role: .destructive) {
                                blacklistManager.remove(bundleIdentifier: bundleID)
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            SettingsGroup(
                "Session Manager",
                footer: "Session Manager watches your coding agents and surfaces what they are doing on the bar."
            ) {
                ToggleRow(
                    "Enable Session Manager",
                    help: "Track coding agents and their activity.",
                    isOn: $settings.enableSessionManagerPlugin
                )
                ToggleRow(
                    "Show Agent Titles",
                    help: "Label each agent with the task it is working on.",
                    isOn: $settings.showSessionManagerAgentTitles
                )
                ToggleRow(
                    "Show Activity Indicators",
                    help: "Mark agents that are currently working.",
                    isOn: $settings.showSessionManagerActivityIndicators
                )
                ToggleRow(
                    "Animate Activity",
                    help: "Animate the indicator while an agent is working. Attractive, but distracting in long sessions.",
                    isOn: $settings.animateSessionManagerActivity
                )
                ToggleRow(
                    "Show Token Usage",
                    help: "Show how many tokens each agent has consumed.",
                    isOn: $settings.showSessionManagerTokenUsage
                )
                ToggleRow(
                    "Terminal Actions",
                    help: "Allow agents to run commands on your behalf from a confirmation prompt.",
                    isOn: $settings.enableSessionManagerTerminalActions
                )
                ToggleRow(
                    "Show Action Button",
                    help: "Show the approve and deny buttons on agent notifications.",
                    isOn: $settings.showSessionManagerActionButton
                )
            }
            .disabled(!settings.enableSessionManagerPlugin)
        }
        .task {
            await notificationAuthorization.refresh()
        }
    }

    private static var versionString: String {
        let info = Bundle.main.infoDictionary
        return info?["CFBundleShortVersionString"] as? String ?? "—"
    }
}