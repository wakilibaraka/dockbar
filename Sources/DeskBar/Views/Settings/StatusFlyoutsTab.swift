import SwiftUI

struct StatusFlyoutsTab: View {
    @ObservedObject var settings: TaskbarSettings
    @StateObject private var quickSettingsState = QuickSettingsTabState()
    
    var body: some View {
        VStack(spacing: 24) {
            
            SettingsCard(title: "Connectivity Tracking", icon: "antenna.radiowaves.left.and.right") {
                SettingsRow(title: "Show connections icon in tray") {
                    Toggle("", isOn: $settings.showConnections).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                }
                
                SettingsDivider()
                
                VStack(alignment: .leading, spacing: 0) {
                    Text("Notifications")
                        .font(.system(size: 13, weight: .semibold))
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    SettingsRow(title: "Bluetooth device connected/disconnected") {
                        Toggle("", isOn: $settings.notifyBluetoothConnect).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    SettingsDivider()
                    SettingsRow(title: "Bluetooth device low battery") {
                        Toggle("", isOn: $settings.notifyBluetoothLowBattery).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    SettingsDivider()
                    SettingsRow(title: "WiFi network changed") {
                        Toggle("", isOn: $settings.notifyWiFiChange).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    SettingsDivider()
                    SettingsRow(title: "WiFi signal weak") {
                        Toggle("", isOn: $settings.notifyWiFiWeak).labelsHidden().toggleStyle(SwitchToggleStyle(tint: .accentColor))
                    }
                    SettingsDivider()
                    HStack {
                        Spacer()
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
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }
                }
            }
            
            SettingsCard(title: "Customize Quick Settings", icon: "slider.horizontal.3") {
                VStack(alignment: .leading, spacing: 0) {
                    Text("Drag items to reorder them in the flyout menu.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.top, 16)
                        .padding(.bottom, 8)
                    
                    List {
                        ForEach($quickSettingsState.items) { $item in
                            HStack {
                                Image(systemName: "line.3.horizontal")
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                                
                                Image(systemName: item.symbol)
                                    .frame(width: 24)
                                
                                Text(item.title)
                                    .font(.system(size: 13))
                                
                                Spacer()
                                
                                Toggle("", isOn: $item.isEnabled)
                                    .labelsHidden()
                                    .toggleStyle(SwitchToggleStyle(tint: .accentColor))
                                    .onChange(of: item.isEnabled) {
                                        saveQuickSettings()
                                    }
                            }
                            .padding(.vertical, 4)
                        }
                        .onMove(perform: moveQuickSetting)
                    }
                    .frame(height: 300)
                    .listStyle(.plain)
                }
            }

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

class QuickSettingsTabState: ObservableObject {
    struct QuickSettingItem: Identifiable {
        let id: String
        let title: String
        let symbol: String
        var isEnabled: Bool
    }
    @Published var items: [QuickSettingItem] = []
}
