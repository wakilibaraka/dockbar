import AppKit
import Combine
import IOKit.ps
import IOKit.pwr_mgt

enum BatteryCondition: String {
    case optimal = "Normal"
    case suboptimal = "Replace Soon"
    case malfunctioning = "Service Battery"
    case unknown = "Unknown"
}

struct MacBatteryStats: Equatable {
    var percentage: Double
    var isCharging: Bool
    var wattage: Double
    var cycleCount: Int
    var healthPercentage: Int
    var temperature: Double
    var condition: BatteryCondition
}

final class SystemStatsService: ObservableObject {
    static let shared = SystemStatsService()
    
    @Published var batteryStats: MacBatteryStats?
    
    private var runLoopSource: CFRunLoopSource?
    
    private init() {
        setupBatteryMonitoring()
        updateBatteryStats()
    }
    
    deinit {
        if let source = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetMain(), source, .defaultMode)
        }
    }
    
    private func setupBatteryMonitoring() {
        let context = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        let loopSource = IOPSNotificationCreateRunLoopSource({ (context) in
            if let ctx = context {
                let service = Unmanaged<SystemStatsService>.fromOpaque(ctx).takeUnretainedValue()
                service.updateBatteryStats()
            }
        }, context).takeRetainedValue()
        
        self.runLoopSource = loopSource
        CFRunLoopAddSource(CFRunLoopGetMain(), loopSource, .defaultMode)
    }
    
    func updateBatteryStats() {
        var newStats = MacBatteryStats(
            percentage: 100,
            isCharging: false,
            wattage: 0,
            cycleCount: 0,
            healthPercentage: 100,
            temperature: 0,
            condition: .optimal
        )
        
        // 1. Get standard percentage and charging state
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if desc[kIOPSTypeKey as String] as? String == kIOPSInternalBatteryType {
                    newStats.percentage = desc[kIOPSCurrentCapacityKey as String] as? Double ?? 100.0
                    newStats.isCharging = desc[kIOPSIsChargingKey as String] as? Bool ?? false
                }
            }
        }
        
        // 2. Deep IOKit query for precise metrics
        let masterPort: mach_port_t
        if #available(macOS 12.0, *) {
            masterPort = kIOMainPortDefault
        } else {
            masterPort = 0 // fallback
        }
        
        let service = IOServiceGetMatchingService(masterPort, IOServiceMatching("IOPMPowerSource"))
        if service != 0 {
            var properties: Unmanaged<CFMutableDictionary>?
            if IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == kIOReturnSuccess,
               let dict = properties?.takeRetainedValue() as? [String: Any] {
                
                // Wattage (Draw)
                let amperage = dict["InstantAmperage"] as? Double ?? dict["Amperage"] as? Double ?? 0
                let voltageStr = dict["AppleRawBatteryVoltage"] as? Double ?? dict["Voltage"] as? Double ?? 0
                if amperage != 0 && voltageStr != 0 {
                    let w = (abs(amperage) * voltageStr) / 1000000.0
                    newStats.wattage = (w * 10).rounded() / 10 // 1 decimal place
                }
                
                // Cycles
                newStats.cycleCount = dict["CycleCount"] as? Int ?? 0
                
                // Health
                if let full = dict["AppleRawMaxCapacity"] as? Double ?? dict["FullChargeCapacity"] as? Double,
                   let design = dict["DesignCapacity"] as? Double, design > 0 {
                    newStats.healthPercentage = min(100, max(0, Int((full / design) * 100)))
                    
                    if newStats.healthPercentage < 80 {
                        newStats.condition = .suboptimal
                    }
                }
                
                // Temperature
                if let tempRaw = dict["Temperature"] as? Double {
                    newStats.temperature = tempRaw / 100.0
                }
            }
            IOObjectRelease(service)
        }
        
        DispatchQueue.main.async {
            self.batteryStats = newStats
        }
    }
}
