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
    
    private var updateTask: Task<Void, Never>?
    private var isMonitoring = false
    
    private init() {}
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        
        updateTask = Task {
            while !Task.isCancelled {
                await fetchDevices()
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10s
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        updateTask?.cancel()
        updateTask = nil
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
