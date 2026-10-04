import SwiftUI

/// The search results pane. Results are grouped by section and ordered by the
/// catalogue's ranking, so an exact title match always floats to the top.
struct SettingsSearchResultsView: View {
    let query: String
    @ObservedObject var settings: TaskbarSettings
    let onOpenSection: (SettingsSection) -> Void

    private var results: [SettingDescriptor] {
        SettingsCatalog.search(query)
    }

    private var grouped: [(section: SettingsSection, items: [SettingDescriptor])] {
        var order: [SettingsSection] = []
        var buckets: [SettingsSection: [SettingDescriptor]] = [:]
        for item in results {
            if buckets[item.section] == nil { order.append(item.section) }
            buckets[item.section, default: []].append(item)
        }
        return order.map { ($0, buckets[$0] ?? []) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if results.isEmpty {
                    emptyState
                } else {
                    ForEach(grouped, id: \.section) { group in
                        SettingsGroup(group.section.title) {
                            ForEach(group.items) { item in
                                resultRow(item, in: group.section)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
            .frame(maxWidth: 680, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private func resultRow(_ item: SettingDescriptor, in section: SettingsSection) -> some View {
        Button {
            onOpenSection(section)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: section.symbol)
                    .foregroundStyle(.secondary)
                    .frame(width: 20)
                VStack(alignment: .leading, spacing: 3) {
                    Text(item.title)
                        .font(.body.weight(.medium))
                        .foregroundStyle(.primary)
                    if !item.help.isEmpty {
                        Text(item.help)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    if !item.read(settings).isEmpty {
                        Text(item.read(settings))
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .help("Show in \(section.title)")
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 28))
                .foregroundStyle(.tertiary)
            Text("No settings match “\(query)”")
                .font(.headline)
            Text("Try a shorter word, such as “battery”, “grouping”, or “login”.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}