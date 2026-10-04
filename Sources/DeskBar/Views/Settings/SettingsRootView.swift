import AppKit
import Combine
import SwiftUI

/// Sidebar selection, the search query, and the pending revert confirmation.
///
/// `@State` is deliberately avoided throughout Settings: this toolchain has a SwiftPM
/// macro bug where `@State` fails to expand, so view-local state lives in an
/// `ObservableObject` like this one.
final class SettingsNavigationModel: ObservableObject {
    @Published var selection: SettingsSection? = .taskbar
    /// Non-empty when the search field has text; the detail pane then shows results.
    @Published var query: String = ""
    /// Set when the user asks to revert a section, cleared when the alert is dismissed.
    @Published var isConfirmingRevert = false

    var isConfirmingRevertBinding: Binding<Bool> {
        Binding(
            get: { self.isConfirmingRevert },
            set: { self.isConfirmingRevert = $0 }
        )
    }
}

/// The settings window: a sidebar of the six catalogue sections, a search field, and the
/// page for whichever section is selected.
struct SettingsRootView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var blacklistManager: BlacklistManager
    @ObservedObject var pinnedAppManager: PinnedAppManager
    @ObservedObject var permissionsManager: PermissionsManager
    @ObservedObject var thumbnailService: ThumbnailService
    @ObservedObject private var navigation: SettingsNavigationModel

    init(
        settings: TaskbarSettings,
        blacklistManager: BlacklistManager,
        pinnedAppManager: PinnedAppManager,
        permissionsManager: PermissionsManager,
        thumbnailService: ThumbnailService,
        navigation: SettingsNavigationModel = SettingsNavigationModel()
    ) {
        self.settings = settings
        self.blacklistManager = blacklistManager
        self.pinnedAppManager = pinnedAppManager
        self.permissionsManager = permissionsManager
        self.thumbnailService = thumbnailService
        self.navigation = navigation
    }

    private var isSearching: Bool {
        !navigation.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detail
        }
        .navigationSplitViewStyle(.balanced)
        .frame(minWidth: 880, minHeight: 580)
        .searchable(
            text: $navigation.query,
            placement: .toolbar,
            prompt: "Search settings"
        )
    }

    // MARK: Sidebar

    private var sidebar: some View {
        VStack(spacing: 0) {
            List(SettingsSection.allCases, selection: $navigation.selection) { section in
                Label(section.title, systemImage: section.symbol)
                    .tag(section)
            }
            .listStyle(.sidebar)

            Divider()

            revertButton
        }
        .frame(minWidth: 210)
        .navigationTitle("DockBar")
        .alert(
            "Revert \(navigation.selection?.title ?? "")?",
            isPresented: navigation.isConfirmingRevertBinding
        ) {
            Button("Revert", role: .destructive) {
                guard let selection = navigation.selection else { return }
                SettingsCatalog.revert(settings, sections: [selection])
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every setting in this section returns to its default. Other sections are untouched.")
        }
    }

    @ViewBuilder
    private var revertButton: some View {
        if let selection = navigation.selection {
            Button {
                navigation.isConfirmingRevert = true
            } label: {
                Label("Revert \(selection.title)", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.borderless)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .help("Restore every setting in \(selection.title) to its default.")
        }
    }

    // MARK: Detail

    @ViewBuilder
    private var detail: some View {
        if isSearching {
            SettingsSearchResultsView(
                query: navigation.query,
                settings: settings,
                onOpenSection: { navigation.selection = $0 }
            )
        } else {
            sectionPage
        }
    }

    @ViewBuilder
    private var sectionPage: some View {
        switch navigation.selection ?? .taskbar {
        case .taskbar:
            TaskbarSettingsPage(settings: settings)
        case .windows:
            WindowsSettingsPage(settings: settings)
        case .displays:
            DisplaysSettingsPage(settings: settings)
        case .launcher:
            LauncherSettingsPage(settings: settings, pinnedAppManager: pinnedAppManager)
        case .widgets:
            WidgetsSettingsPage(settings: settings)
        case .system:
            SystemSettingsPage(
                settings: settings,
                blacklistManager: blacklistManager,
                permissionsManager: permissionsManager,
                thumbnailService: thumbnailService
            )
        }
    }
}