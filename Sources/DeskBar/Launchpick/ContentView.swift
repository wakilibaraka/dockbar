import SwiftUI

class LaunchpickState: ObservableObject {
    @Published var searchText = ""
    @Published var launchers: [LaunchpickItem] = []
    @Published var columns: Int = 4
    @Published var focusTrigger = false
    @Published var selectedIndex: Int = 0

    var onLaunch: ((LaunchpickItem) -> Void)?
    var onDismiss: (() -> Void)?

    lazy var systemApps: [LaunchpickItem] = {
        AppScanner.shared.apps.map { app in
            LaunchpickItem(
                name: app.name,
                exec: "open -a '\(app.name)'",
                icon: app.icon
            )
        }
    }()

    var filteredLaunchers: [LaunchpickItem] {
        if searchText.isEmpty {
            return launchers
        }
        return launchers.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var filteredSystemApps: [LaunchpickItem] {
        guard !searchText.isEmpty else { return [] }
        let launcherExecs = Set(launchers.map { $0.exec.lowercased() })
        return systemApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) &&
            !launcherExecs.contains($0.exec.lowercased())
        }
    }

    var totalFilteredCount: Int {
        filteredLaunchers.count + filteredSystemApps.count
    }
}

struct LaunchpickItem: Identifiable {
    let id = UUID()
    let name: String
    let exec: String
    let icon: NSImage
}

struct ContentView: View {
    @ObservedObject var state: LaunchpickState
    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                    .font(.system(size: 16, weight: .medium))
                TextField("Search...", text: $state.searchText)
                    .textFieldStyle(.plain)
                    .font(.system(size: 18))
            }
            .padding(12)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(8)
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 16)

            ScrollView {
                VStack(spacing: 16) {
                    // Launchers grid
                    if !state.filteredLaunchers.isEmpty {
                        LazyVGrid(
                            columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: state.columns),
                            spacing: 16
                        ) {
                            ForEach(Array(state.filteredLaunchers.enumerated()), id: \.element.id) { index, item in
                                LaunchpickItemView(item: item, isSelected: index == state.selectedIndex) {
                                    state.onLaunch?(item)
                                }
                            }
                        }
                    }

                    // System apps section
                    if !state.filteredSystemApps.isEmpty {
                        if !state.filteredLaunchers.isEmpty {
                            Divider().padding(.vertical, 4)
                        }

                        VStack(spacing: 2) {
                            ForEach(Array(state.filteredSystemApps.prefix(8).enumerated()), id: \.element.id) { index, app in
                                let globalIndex = state.filteredLaunchers.count + index
                                SystemAppRow(item: app, isSelected: globalIndex == state.selectedIndex) {
                                    state.onLaunch?(app)
                                }
                            }
                        }
                    }

                    // Phase 1 Scaffold: All Apps
                    if state.searchText.isEmpty {
                        Divider().padding(.vertical, 8)
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("All Apps")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                                .padding(.horizontal, 4)
                            
                            // Scaffold placeholder for now
                            VStack {
                                Text("All Apps will be listed here (Phase 2)")
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, minHeight: 200)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(8)
                        }
                    }

                    // No results
                    if state.filteredLaunchers.isEmpty && state.filteredSystemApps.isEmpty {
                        Text("No matches")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, minHeight: 80)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 16)
            }
        }
        .onChange(of: state.searchText) { _, _ in
            state.selectedIndex = 0
        }
    }
}

struct VisualEffectBackground: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = .hudWindow
        view.state = .active
        view.blendingMode = .behindWindow
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {}
}

struct LaunchpickItemView: View {
    let item: LaunchpickItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 96, height: 96)
                Text(item.name)
                    .font(.system(size: 13))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 32)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(isSelected ? Color.accentColor : Color.clear, lineWidth: 2.5)
            )
        }
        .buttonStyle(.plain)
    }
}

struct SystemAppRow: View {
    let item: LaunchpickItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 32, height: 32)
                Text(item.name)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor.opacity(0.2) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}
