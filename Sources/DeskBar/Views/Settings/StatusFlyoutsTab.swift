import SwiftUI

struct StatusFlyoutsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @StateObject private var quickSettingsState = QuickSettingsTabState()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // Connectivity
                GroupBox(label: Text("Connectivity Tracking").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Show connections icon in tray", isOn: $settings.showConnections)
                        
                        Divider().padding(.vertical, 4)
                        
                        Text("Notifications")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Toggle("Bluetooth device connected/disconnected", isOn: $settings.notifyBluetoothConnect)
                            .padding(.leading, 16)
                        Toggle("Bluetooth device low battery", isOn: $settings.notifyBluetoothLowBattery)
                            .padding(.leading, 16)
                        Toggle("WiFi network changed", isOn: $settings.notifyWiFiChange)
                            .padding(.leading, 16)
                        Toggle("WiFi signal weak", isOn: $settings.notifyWiFiWeak)
                            .padding(.leading, 16)
                            
                        Button("Test Notification") {
                            NotificationManager.shared.requestAuthorization { granted in
                                if granted {
                                    DispatchQueue.main.async {
                                        NotificationManager.shared.sendNotification(
                                            title: "Connectivity Tracker",
                                            body: "This is a test notification from DeskBar Settings.",
                                            identifier: UUID().uuidString
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // Quick Settings
                GroupBox(label: Text("Customize Quick Settings").font(.headline)) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Drag items to reorder them in the flyout menu.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 4)
                        
                        List {
                            ForEach($quickSettingsState.items) { $item in
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                        .foregroundColor(.secondary)
                                        .frame(width: 20)
                                    
                                    Image(systemName: item.symbol)
                                        .frame(width: 24)
                                    
                                    Text(item.title)
                                    
                                    Spacer()
                                    
                                    Toggle("", isOn: $item.isEnabled)
                                        .onChange(of: item.isEnabled) {
                                            saveQuickSettings()
                                        }
                                }
                                .padding(.vertical, 4)
                            }
                            .onMove(perform: moveQuickSetting)
                        }
                        .frame(height: 300)
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primary.opacity(0.1)))
                    }
                    .padding(.top, 8)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

            }
            .padding(20)
        }
        .onAppear(perform: loadQuickSettings)
    }
    
    // MARK: - Quick Settings Methods
    
    private func loadQuickSettings() {
        let all = QuickSettingsManager.shared.allSettings
        let enabled = Set(settings.enabledQuickSettings)
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
        ordered.append(contentsOf: itemsMap.values.sorted { $0.title < $1.title })
        
        quickSettingsState.items = ordered
    }
    
    private func moveQuickSetting(from source: IndexSet, to destination: Int) {
        quickSettingsState.items.move(fromOffsets: source, toOffset: destination)
        saveQuickSettings()
    }
    
    private func saveQuickSettings() {
        let order = quickSettingsState.items.map { $0.id }
        let enabled = quickSettingsState.items.filter { $0.isEnabled }.map { $0.id }
        
        UserDefaults.standard.set(order, forKey: "quickSettingsOrder")
        settings.enabledQuickSettings = enabled
    }
}
