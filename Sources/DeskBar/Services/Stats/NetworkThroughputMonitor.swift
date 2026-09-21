import Combine
import Darwin
import Foundation
import SwiftUI

@MainActor
final class NetworkThroughputMonitor: ObservableObject {
    @Published private(set) var downloadRate: Double = 0
    @Published private(set) var uploadRate: Double = 0
    @Published private(set) var downloadSamples: [Double] = []
    @Published private(set) var uploadSamples: [Double] = []

    nonisolated(unsafe) private var timer: Timer?
    private var previousCounters: (input: UInt64, output: UInt64)?

    init() {
        sample()
        let timer = Timer(timeInterval: 1, repeats: true) { [weak self] _ in
            self?.sample()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit {
        timer?.invalidate()
    }

    private func sample() {
        let counters = Self.interfaceCounters()
        guard let previousCounters else {
            self.previousCounters = counters
            return
        }

        let down = Double(counters.input.saturatingSubtract(previousCounters.input))
        let up = Double(counters.output.saturatingSubtract(previousCounters.output))
        self.previousCounters = counters

        downloadRate = down
        uploadRate = up
        downloadSamples = Array((downloadSamples + [down]).suffix(60))
        uploadSamples = Array((uploadSamples + [up]).suffix(60))
    }

    private nonisolated static func interfaceCounters() -> (input: UInt64, output: UInt64) {
        var address: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&address) == 0 else { return (0, 0) }
        defer { freeifaddrs(address) }

        var candidates: [(name: String, input: UInt64, output: UInt64)] = []
        var cursor = address
        while let current = cursor {
            defer { cursor = current.pointee.ifa_next }
            let flags = current.pointee.ifa_flags
            guard flags & UInt32(IFF_UP) != 0,
                  flags & UInt32(IFF_RUNNING) != 0,
                  flags & UInt32(IFF_LOOPBACK) == 0,
                  let name = String(validatingCString: current.pointee.ifa_name),
                  let data = current.pointee.ifa_data,
                  let socketAddress = current.pointee.ifa_addr,
                  socketAddress.pointee.sa_family == UInt8(AF_INET)
            else { continue }

            let stats = data.assumingMemoryBound(to: if_data.self).pointee
            candidates.append((name, UInt64(stats.ifi_ibytes), UInt64(stats.ifi_obytes)))
        }

        let selected = candidates.first(where: { $0.name == "en0" })
            ?? candidates.first(where: { $0.name.hasPrefix("en") })
            ?? candidates.max { $0.input + $0.output < $1.input + $1.output }
        return selected.map { ($0.input, $0.output) } ?? (0, 0)
    }
}

private extension UInt64 {
    func saturatingSubtract(_ other: UInt64) -> UInt64 {
        self >= other ? self - other : 0
    }
}
