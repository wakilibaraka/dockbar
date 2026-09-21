import SwiftUI

enum AllAppsViewMode: String {
    case category = "Category"
    case alphabetical = "A-Z"
}

enum AllAppsLayout: String, CaseIterable, Identifiable {
    case list = "List"
    case grid = "Grid"
    var id: String { self.rawValue }
}

class LaunchpickState: ObservableObject {
    @Published var searchText = ""
    @Published var launchers: [LaunchpickItem] = []
    @Published var mostUsedLaunchers: [LaunchpickItem] = []
    @Published var columns: Int = 4
    @Published var focusTrigger = false
        @Published var selectedIndex: Int = 0
    @Published var viewMode: AllAppsViewMode = .category

    var onLaunch: ((LaunchpickItem) -> Void)?
    var onDismiss: (() -> Void)?

    var systemApps: [LaunchpickItem] {
        AppScanner.shared.apps.filter { app in
            guard let bundleID = app.bundleIdentifier else { return true }
            return !BlacklistManager.shared.isBlacklisted(bundleIdentifier: bundleID)
        }.map { app in
            LaunchpickItem(
                name: app.name,
                exec: "open -a '\(app.name)'",
                icon: app.icon,
                category: app.category,
                bundleIdentifier: app.bundleIdentifier,
                applicationPath: app.path
            )
        }
    }

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

    var groupedSystemApps: [(String, [LaunchpickItem])] {
        let apps = searchText.isEmpty ? systemApps : systemApps.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
        
        if viewMode == .category {
            let grouped = Dictionary(grouping: apps, by: { $0.category })
            let sortedKeys = grouped.keys.sorted {
                if $0 == "Other" { return false }
                if $1 == "Other" { return true }
                return $0 < $1
            }
            return sortedKeys.map { ($0, grouped[$0]!) }
        } else {
            let grouped = Dictionary(grouping: apps, by: { String($0.name.prefix(1).uppercased()) })
            let sortedKeys = grouped.keys.sorted()
            return sortedKeys.map { ($0, grouped[$0]!) }
        }
    }

    var orderedSystemApps: [LaunchpickItem] {
        groupedSystemApps.flatMap { $0.1 }
    }

    var totalFilteredCount: Int {
        filteredLaunchers.count + orderedSystemApps.count
    }
}

struct LaunchpickItem: Identifiable {
    let id = UUID()
    let name: String
    let exec: String
    let icon: NSImage
    let category: String
    var bundleIdentifier: String? = nil
    var applicationPath: String? = nil
}

struct ContentView: View {
    @ObservedObject var state: LaunchpickState
    @AppStorage("allAppsLayout") private var allAppsLayout: AllAppsLayout = .list
    @AppStorage("showAllPinned") private var showAllPinned: Bool = false
    @AppStorage("launchpickShowPinnedApps") private var launchpickShowPinnedApps: Bool = true
    @AppStorage("launchpickShowMostUsedApps") private var launchpickShowMostUsedApps: Bool = false
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
                    if launchpickShowPinnedApps && !state.filteredLaunchers.isEmpty {
                        VStack {
                            HStack {
                                Text("Pinned")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                                if state.filteredLaunchers.count > state.columns * 2 {
                                    Button(action: { showAllPinned.toggle() }) {
                                        HStack(spacing: 4) {
                                            Text(showAllPinned ? "Show less" : "Show more")
                                                .font(.system(size: 12))
                                            Image(systemName: showAllPinned ? "chevron.up" : "chevron.down")
                                                .font(.system(size: 10))
                                        }
                                        .padding(.vertical, 4)
                                        .padding(.horizontal, 8)
                                        .background(Color.primary.opacity(0.05))
                                        .cornerRadius(6)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                            
                            let visibleLaunchers = showAllPinned ? state.filteredLaunchers : Array(state.filteredLaunchers.prefix(state.columns * 2))
                            
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: state.columns),
                                spacing: 16
                            ) {
                                ForEach(Array(visibleLaunchers.enumerated()), id: \.element.id) { index, item in
                                    LaunchpickItemView(item: item, isSelected: index == state.selectedIndex) {
                                        state.onLaunch?(item)
                                    }
                                }
                            }
                        }
                    }

                    // Most Used section
                    if launchpickShowMostUsedApps && !state.mostUsedLaunchers.isEmpty {
                        VStack {
                            HStack {
                                Text("Most Used")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .padding(.bottom, 8)
                            
                            LazyVGrid(
                                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: state.columns),
                                spacing: 16
                            ) {
                                ForEach(Array(state.mostUsedLaunchers.enumerated()), id: \.element.id) { index, item in
                                    // Offset the index for keyboard selection (assuming most used apps come right after pinned apps)
                                    let offsetIndex = (launchpickShowPinnedApps ? state.filteredLaunchers.count : 0) + index
                                    LaunchpickItemView(item: item, isSelected: offsetIndex == state.selectedIndex) {
                                        state.onLaunch?(item)
                                    }
                                }
                            }
                        }
                    }

                    // Phase 2: All Apps (Grouped & Searchable)
                    Divider().padding(.vertical, 8)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("All Apps")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            Picker("", selection: $state.viewMode) {
                                Text("Category").tag(AllAppsViewMode.category)
                                Text("A-Z").tag(AllAppsViewMode.alphabetical)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                            .frame(width: 150)
                        }
                        .padding(.horizontal, 4)
                        
                        let groups = state.groupedSystemApps
                        if groups.isEmpty {
                            Text("No apps found")
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, minHeight: 100)
                        } else {
                            VStack(alignment: .leading, spacing: 20) {
                                ForEach(groups, id: \.0) { group in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(group.0)
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.secondary)
                                            .padding(.horizontal, 8)
                                        
                                        if allAppsLayout == .list {
                                            VStack(spacing: 2) {
                                                ForEach(group.1, id: \.id) { app in
                                                    SystemAppRow(item: app, isSelected: (state.orderedSystemApps.firstIndex(where: { $0.id == app.id }).map { $0 + state.filteredLaunchers.count } ?? -1) == state.selectedIndex) {
                                                        state.onLaunch?(app)
                                                    }
                                                }
                                            }
                                        } else {
                                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 76, maximum: 96), spacing: 12)], spacing: 16) {
                                                ForEach(group.1, id: \.id) { app in
                                                    SystemAppGridView(item: app, isSelected: (state.orderedSystemApps.firstIndex(where: { $0.id == app.id }).map { $0 + state.filteredLaunchers.count } ?? -1) == state.selectedIndex) {
                                                        state.onLaunch?(app)
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
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
            
            // Phase 3 Footer
            LauncherFooterView()
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

struct SystemAppGridView: View {
    let item: LaunchpickItem
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(nsImage: item.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 48, height: 48)
                Text(item.name)
                    .font(.system(size: 11))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(height: 28, alignment: .top)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
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
