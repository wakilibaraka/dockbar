import SwiftUI

class QuickSettingsTabState: ObservableObject {
    @Published var items: [QuickSettingItem] = []
    
    struct QuickSettingItem: Identifiable, Equatable {
        let id: String
        let title: String
        let symbol: String
        var isEnabled: Bool
    }
}

struct QuickSettingsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @StateObject private var state = QuickSettingsTabState()
    
    var body: some View {
        Form {
            Section(header: Text("Customize Quick Settings").font(.headline)) {
                Text("Drag items to reorder them in the flyout menu.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 4)
                
                List {
                    ForEach($state.items) { $item in
                        HStack {
                            Image(systemName: "line.3.horizontal")
                                .foregroundColor(.secondary)
                                .frame(width: 20)
                            
                            Image(systemName: item.symbol)
                                .frame(width: 24)
                            
                            Text(item.title)
                            
                            Spacer()
                            
                            Toggle("", isOn: $item.isEnabled)
                                .onChange(of: item.isEnabled) { _ in
                                    save()
                                }
                        }
                        .padding(.vertical, 4)
                    }
                    .onMove(perform: move)
                }
                .frame(height: 300)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1)))
            }
        }
        .padding(20)
        .onAppear(perform: load)
    }
    
    private func load() {
        let all = QuickSettingsManager.shared.allSettings
        let enabled = Set(settings.enabledQuickSettings)
        
        // Use saved order from TaskbarSettings if available
        let savedOrder = UserDefaults.standard.stringArray(forKey: "quickSettingsOrder") ?? []
        
        var itemsMap = [String: QuickSettingsTabState.QuickSettingItem]()
        for s in all {
            itemsMap[s.id] = QuickSettingsTabState.QuickSettingItem(
                id: s.id,
                title: s.title,
                symbol: s.symbolName,
                isEnabled: enabled.contains(s.id)
            )
        }
        
        var ordered: [QuickSettingsTabState.QuickSettingItem] = []
        for id in savedOrder {
            if let item = itemsMap.removeValue(forKey: id) {
                ordered.append(item)
            }
        }
        // Append any remaining (new) settings
        ordered.append(contentsOf: itemsMap.values.sorted { $0.title < $1.title })
        
        state.items = ordered
    }
    
    private func move(from source: IndexSet, to destination: Int) {
        state.items.move(fromOffsets: source, toOffset: destination)
        save()
    }
    
    private func save() {
        let order = state.items.map { $0.id }
        let enabled = state.items.filter { $0.isEnabled }.map { $0.id }
        
        UserDefaults.standard.set(order, forKey: "quickSettingsOrder")
        settings.enabledQuickSettings = enabled
    }
}
