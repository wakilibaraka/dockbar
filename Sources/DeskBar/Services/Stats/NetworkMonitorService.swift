import Combine
import CoreWLAN
import Foundation
import Network

@MainActor
final class NetworkMonitorService: ObservableObject {
    static let shared = NetworkMonitorService()
    
    @Published var ssid: String?
    @Published var rssi: Int? // dBm
    @Published var localIP: String?
    @Published var isConnected = false
    
    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "com.dockbar.networkmonitor")
    private var cancellables = Set<AnyCancellable>()
    
    private var lastWiFiState: Bool?
    private var lastSSID: String?
    
    // Debounce state
    private var connectionChangeEventTime = Date()
    private var ssidChangeEventTime = Date()
    
    private init() {}
    
    func startMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.handlePathUpdate(path)
            }
        }
        pathMonitor.start(queue: monitorQueue)
        
        // Poll CoreWLAN every 2s for signal updates
        SharedTimer.shared.tick2s
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.fetchWiFiDetails()
            }
            .store(in: &cancellables)
            
        fetchWiFiDetails()
    }
    
    private func handlePathUpdate(_ path: NWPath) {
        let currentlyConnected = path.status == .satisfied
        
        // Wait, WiFi might be connected but no internet. 
        // path.usesInterfaceType(.wifi) is useful.
        let isWiFi = path.usesInterfaceType(.wifi)
        self.isConnected = currentlyConnected && isWiFi
        
        // Grab IP
        self.localIP = getLocalIPAddress()
        
        // Notifications logic
        
        if let lastState = lastWiFiState, lastState != isConnected {
            if Date().timeIntervalSince(connectionChangeEventTime) > 3.0 {
                connectionChangeEventTime = Date()
                
                if UserDefaults.standard.bool(forKey: "notifyWiFiChange") {
                    let title = isConnected ? "WiFi Connected" : "WiFi Disconnected"
                    let body = isConnected ? "Connected to \(ssid ?? "a network")" : "Lost connection"
                    NotificationManager.shared.sendNotification(title: title, body: body, identifier: "wifi-status")
                }
            }
        }
        lastWiFiState = isConnected
    }
    
    private func fetchWiFiDetails() {
        guard let interface = CWWiFiClient.shared().interface() else {
            self.ssid = nil
            self.rssi = nil
            return
        }
        
        let newSSID = interface.ssid()
        self.ssid = newSSID
        self.rssi = interface.rssiValue()
        
        // Update local IP occasionally too
        if self.localIP == nil && self.isConnected {
            self.localIP = getLocalIPAddress()
        }
        
        
        if let last = lastSSID, last != newSSID, newSSID != nil {
            if Date().timeIntervalSince(ssidChangeEventTime) > 3.0 {
                ssidChangeEventTime = Date()
                if UserDefaults.standard.bool(forKey: "notifyWiFiChange") {
                    NotificationManager.shared.sendNotification(
                        title: "WiFi Changed",
                        body: "Joined \(newSSID!)",
                        identifier: "wifi-status"
                    )
                }
            }
        }
        lastSSID = newSSID
        
        if let rssi = self.rssi, rssi < -80, UserDefaults.standard.bool(forKey: "notifyWiFiWeak") {
            // Very basic throttle for weak signal (every 10 mins at most)
            let weakSignalKey = "lastWeakSignalNotify"
            let lastNotify = UserDefaults.standard.double(forKey: weakSignalKey)
            if Date().timeIntervalSince1970 - lastNotify > 600 {
                UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: weakSignalKey)
                NotificationManager.shared.sendNotification(
                    title: "Weak WiFi Signal",
                    body: "Signal strength is very low (\(rssi) dBm)",
                    identifier: "wifi-weak"
                )
            }
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return nil }
        defer { freeifaddrs(ifaddr) }
        
        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let flags = Int32(ptr.pointee.ifa_flags)
            let addr = ptr.pointee.ifa_addr.pointee
            
            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                if addr.sa_family == UInt8(AF_INET) {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    if getnameinfo(ptr.pointee.ifa_addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                        let ip = String(cString: hostname)
                        if String(cString: ptr.pointee.ifa_name).hasPrefix("en") {
                            address = ip
                            break
                        }
                    }
                }
            }
        }
        return address
    }
}
