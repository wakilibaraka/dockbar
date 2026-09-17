import AppKit
import Combine

struct BluetoothDeviceStats: Equatable, Identifiable {
    let id: String
    let name: String
    let batteryLevel: Int? // 0-100
    let type: String // e.g. "airpods", "mouse", "keyboard"
    var isConnected: Bool
}

final class BluetoothStatsService: ObservableObject {
    static let shared = BluetoothStatsService()
    
    @Published var connectedDevices: [BluetoothDeviceStats] = []
    
    private var cancellables = Set<AnyCancellable>()
    private var isMonitoring = false
    private var tickCount = 0
    private var notifiedLowBatteryDevices = Set<String>()
    private var knownDevices = Set<String>()
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        SharedTimer.shared.tick5s
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                self.tickCount += 1
                if self.tickCount % 2 == 0 { // Every 10s
                    Task { @MainActor in
                        await self.fetchDevices()
                        self.processNotifications()
                    }
                }
            }
            .store(in: &cancellables)
            
        Task { @MainActor in
            await fetchDevices()
            self.knownDevices = Set(self.connectedDevices.map { $0.id })
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        cancellables.removeAll()
    }
    
    @MainActor
    private func processNotifications() {
        let currentDeviceIDs = Set(connectedDevices.map { $0.id })
        let newlyConnected = currentDeviceIDs.subtracting(knownDevices)
        let newlyDisconnected = knownDevices.subtracting(currentDeviceIDs)
        
        let notifyConnect = UserDefaults.standard.bool(forKey: "notifyBluetoothConnect")
        let notifyLowBattery = UserDefaults.standard.bool(forKey: "notifyBluetoothLowBattery")
        
        if notifyConnect {
            for id in newlyConnected {
                if let dev = connectedDevices.first(where: { $0.id == id }) {
                    NotificationManager.shared.sendNotification(title: "Bluetooth Connected", body: dev.name, identifier: "bt-conn-\(id)")
                }
            }
            for id in newlyDisconnected {
                NotificationManager.shared.sendNotification(title: "Bluetooth Disconnected", body: "A device disconnected", identifier: "bt-disc-\(id)")
                notifiedLowBatteryDevices.remove(id) // Reset low battery state when disconnected
            }
        }
        
        knownDevices = currentDeviceIDs
        
        if notifyLowBattery {
            for dev in connectedDevices {
                if let battery = dev.batteryLevel, battery < 20 {
                    if !notifiedLowBatteryDevices.contains(dev.id) {
                        notifiedLowBatteryDevices.insert(dev.id)
                        NotificationManager.shared.sendNotification(title: "Low Battery", body: "\(dev.name) is at \(battery)%", identifier: "bt-batt-\(dev.id)")
                    }
                } else if let battery = dev.batteryLevel, battery > 20 {
                    // Remove if they charged it while connected
                    notifiedLowBatteryDevices.remove(dev.id)
                }
            }
        }
    }
    
    @MainActor
    private func fetchDevices() async {
        let devices = await Task.detached(priority: .background) { () -> [BluetoothDeviceStats] in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/sbin/system_profiler")
            process.arguments = ["SPBluetoothDataType", "-xml"]
            
            let pipe = Pipe()
            process.standardOutput = pipe
            
            do {
                try process.run()
                process.waitUntilExit()
                
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                
                guard let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [[String: Any]],
                      let firstItem = plist.first?["_items"] as? [[String: Any]],
                      let bluetoothInfo = firstItem.first else {
                    return []
                }
                
                var results: [BluetoothDeviceStats] = []
                
                // Parse connected devices
                if let connected = bluetoothInfo["device_connected"] as? [[String: Any]] {
                    for deviceDict in connected {
                        for (deviceName, info) in deviceDict {
                            guard let details = info as? [String: Any] else { continue }
                            
                            var battery: Int?
                            if let batteryStr = details["device_batteryLevelMain"] as? String {
                                battery = Int(batteryStr.replacingOccurrences(of: "%", with: "").trimmingCharacters(in: .whitespaces))
                            }
                            
                            let address = details["device_address"] as? String ?? deviceName
                            
                            var type = "bluetooth"
                            if let minorType = details["device_minorType"] as? String {
                                if minorType.lowercased().contains("mouse") { type = "mouse" }
                                else if minorType.lowercased().contains("keyboard") { type = "keyboard" }
                                else if minorType.lowercased().contains("headphones") { type = "headphones" }
                            }
                            
                            results.append(BluetoothDeviceStats(
                                id: address,
                                name: deviceName,
                                batteryLevel: battery,
                                type: type,
                                isConnected: true
                            ))
                        }
                    }
                }
                return results
                
            } catch {
                return []
            }
        }.value
        
        self.connectedDevices = devices
    }
}
