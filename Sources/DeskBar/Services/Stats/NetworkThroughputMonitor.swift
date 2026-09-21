import Foundation
import Combine
import SwiftUI

@MainActor
final class NetworkThroughputMonitor: ObservableObject {
    static let shared = NetworkThroughputMonitor()

    @Published var downRate: Double = 0
    @Published var upRate: Double = 0

    // Fixed capacity buffers for graphing (e.g. 60 samples for 60 seconds)
    @Published var downBuffer: [Double] = Array(repeating: 0, count: 60)
    @Published var upBuffer: [Double] = Array(repeating: 0, count: 60)

    private var lastDownBytes: UInt64 = 0
    private var lastUpBytes: UInt64 = 0
    private var firstTick = true

    nonisolated(unsafe) private var timer: Timer?

    private init() {
        start()
    }

    deinit {
        timer?.invalidate()
    }

    private func start() {
        let t = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.tick()
            }
        }
        RunLoop.main.add(t, forMode: .common)
        self.timer = t
    }

    private func tick() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0, let firstAddr = ifaddr else { return }
        defer { freeifaddrs(ifaddr) }

        var currentDown: UInt64 = 0
        var currentUp: UInt64 = 0

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let name = String(cString: ptr.pointee.ifa_name)

            // typically en0 is the active interface, but we aggregate active `en` interfaces
            if name.hasPrefix("en") {
                let flags = Int32(ptr.pointee.ifa_flags)
                let isUp = (flags & IFF_UP) == IFF_UP
                let isRunning = (flags & IFF_RUNNING) == IFF_RUNNING

                if isUp && isRunning {
                    let family = ptr.pointee.ifa_addr.pointee.sa_family
                    if family == UInt8(AF_LINK) {
                        let data = unsafeBitCast(ptr.pointee.ifa_data, to: UnsafeMutablePointer<if_data>.self)
                        currentDown += UInt64(data.pointee.ifi_ibytes)
                        currentUp += UInt64(data.pointee.ifi_obytes)
                    }
                }
            }
        }

        if !firstTick {
            let downDelta = currentDown > lastDownBytes ? currentDown - lastDownBytes : 0
            let upDelta = currentUp > lastUpBytes ? currentUp - lastUpBytes : 0

            downRate = Double(downDelta)
            upRate = Double(upDelta)

            downBuffer.removeFirst()
            downBuffer.append(downRate)

            upBuffer.removeFirst()
            upBuffer.append(upRate)
        }

        lastDownBytes = currentDown
        lastUpBytes = currentUp
        firstTick = false
    }
}
