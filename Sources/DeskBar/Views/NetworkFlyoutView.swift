import SwiftUI

struct NetworkFlyoutView: View {
    @ObservedObject var monitor: NetworkThroughputMonitor
    @ObservedObject var speedTest: SpeedTestController
    var onChange: (() -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Network")
                .font(.headline)

            throughputRow(
                title: "Download",
                value: monitor.downloadRate,
                samples: monitor.downloadSamples,
                color: .green
            )
            throughputRow(
                title: "Upload",
                value: monitor.uploadRate,
                samples: monitor.uploadSamples,
                color: .orange
            )

            Divider()

            if let liveDown = speedTest.liveDown, let liveUp = speedTest.liveUp {
                Text("Testing: \(formatMbps(liveDown)) down / \(formatMbps(liveUp)) up")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else if let result = speedTest.last {
                Text("Last test: \(formatMbps(result.down)) down / \(formatMbps(result.up)) up · \(result.rpm) RPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button(speedTest.isRunning ? "Running speed test…" : "Run speed test") {
                speedTest.run()
                onChange?()
            }
            .disabled(speedTest.isRunning)
        }
        .padding(16)
        .frame(width: 260)
    }

    private func throughputRow(
        title: String,
        value: Double,
        samples: [Double],
        color: Color
    ) -> some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatBytesPerSecond(value))
                    .font(.system(.body, design: .monospaced).weight(.semibold))
            }
            Spacer()
            MetricGraphView(
                samples: samples,
                accent: color,
                style: .line,
                maximum: max(samples.max() ?? 1, 1)
            )
        }
    }

    private func formatBytesPerSecond(_ bytes: Double) -> String {
        formatMbps(bytes * 8 / 1_000_000)
    }

    private func formatMbps(_ value: Double) -> String {
        String(format: "%.1f Mbps", value)
    }
}
