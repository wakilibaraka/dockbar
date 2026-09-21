import SwiftUI

struct NetworkFlyoutView: View {
    @ObservedObject var networkMonitor = NetworkThroughputMonitor.shared
    @StateObject private var speedTestController = SpeedTestController()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Network Activity")
                .font(.headline)

            HStack(spacing: 20) {
                // Download
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.blue)
                        Text(formatBytes(networkMonitor.downRate) + "/s")
                            .font(.system(.body, design: .monospaced))
                    }
                    MetricGraphView(
                        samples: networkMonitor.downBuffer,
                        color: .blue,
                        style: .filledWave,
                        maxValue: networkMonitor.downBuffer.max() ?? 1024
                    )
                    .frame(height: 40)
                }

                // Upload
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: "arrow.up.circle.fill")
                            .foregroundColor(.green)
                        Text(formatBytes(networkMonitor.upRate) + "/s")
                            .font(.system(.body, design: .monospaced))
                    }
                    MetricGraphView(
                        samples: networkMonitor.upBuffer,
                        color: .green,
                        style: .filledWave,
                        maxValue: networkMonitor.upBuffer.max() ?? 1024
                    )
                    .frame(height: 40)
                }
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Speed Test")
                    .font(.headline)

                if speedTestController.isRunning {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.5)
                        Text("Running (\(speedTestController.elapsed)s)...")
                            .foregroundColor(.secondary)
                    }
                } else if let last = speedTestController.last {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading) {
                            Text("↓ \(Int(last.down)) Mbps")
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        VStack(alignment: .leading) {
                            Text("↑ \(Int(last.up)) Mbps")
                                .font(.system(.subheadline, design: .monospaced))
                        }
                        VStack(alignment: .leading) {
                            Text("\(last.rpm) RPM")
                                .font(.system(.subheadline, design: .monospaced))
                        }
                    }
                } else if speedTestController.failed {
                    Text("Last test failed.")
                        .foregroundColor(.red)
                } else {
                    Text("No recent tests.")
                        .foregroundColor(.secondary)
                }

                Button(speedTestController.isRunning ? "Testing..." : "Run Speed Test") {
                    speedTestController.run()
                }
                .disabled(speedTestController.isRunning)
                .padding(.top, 4)
            }
        }
        .padding()
        .frame(width: 320)
    }

    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useBytes, .useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}
