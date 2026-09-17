import Foundation
import IOKit.ps
import Combine

struct BatteryState {
    var percentage: Int
    var isCharging: Bool
}

final class BatteryMonitor: ObservableObject {
    static let shared = BatteryMonitor()
    
    @Published var state = BatteryState(percentage: 100, isCharging: false)
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        updateBatteryState()
        SharedTimer.shared.tick5s
            .sink { [weak self] _ in
                self?.updateBatteryState()
            }
            .store(in: &cancellables)
    }
    
    private func updateBatteryState() {
        let snapshot = IOPSCopyPowerSourcesInfo().takeRetainedValue()
        let sources = IOPSCopyPowerSourcesList(snapshot).takeRetainedValue() as Array
        
        var totalCurrentCapacity = 0
        var totalMaxCapacity = 0
        var isCharging = false
        var foundBattery = false
        
        for source in sources {
            if let desc = IOPSGetPowerSourceDescription(snapshot, source).takeUnretainedValue() as? [String: Any] {
                if let type = desc[kIOPSTypeKey] as? String, type == kIOPSInternalBatteryType {
                    foundBattery = true
                    if let current = desc[kIOPSCurrentCapacityKey] as? Int,
                       let max = desc[kIOPSMaxCapacityKey] as? Int {
                        totalCurrentCapacity += current
                        totalMaxCapacity += max
                    }
                    if let state = desc[kIOPSPowerSourceStateKey] as? String {
                        if state == kIOPSACPowerValue {
                            if let charging = desc[kIOPSIsChargingKey] as? Bool {
                                isCharging = charging || isCharging
                            }
                        }
                    }
                }
            }
        }
        
        if foundBattery && totalMaxCapacity > 0 {
            let percentage = Int((Double(totalCurrentCapacity) / Double(totalMaxCapacity)) * 100.0)
            let newState = BatteryState(percentage: min(100, max(0, percentage)), isCharging: isCharging)
            if self.state.percentage != newState.percentage || self.state.isCharging != newState.isCharging {
                self.state = newState
            }
        }
    }
}
