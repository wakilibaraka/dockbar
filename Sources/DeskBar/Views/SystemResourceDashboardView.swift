import SwiftUI

struct SystemResourceDashboardView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("System Resources")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                Button(action: {
                    NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Activity Monitor.app"))
                }) {
                    Image(systemName: "chart.xyaxis.line")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Open Activity Monitor")
            }
            .padding(.bottom, 4)
            
            // Memory Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Memory")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.0f%%", monitor.snapshot.memoryUsedPercent ?? 0))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(colorForMem(percent: monitor.snapshot.memoryUsedPercent ?? 0))
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(colorForMem(percent: monitor.snapshot.memoryUsedPercent ?? 0))
                            .frame(width: max(0, geo.size.width * CGFloat((monitor.snapshot.memoryUsedPercent ?? 0) / 100.0)))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: monitor.snapshot.memoryUsedPercent)
                    }
                }
                .frame(height: 8)
                
                HStack {
                    Text(formatBytes(monitor.snapshot.memoryUsedBytes ?? 0))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(formatBytes(monitor.snapshot.memoryTotalBytes ?? 0))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // CPU Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("CPU")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.0f%%", monitor.snapshot.cpuPercent ?? 0))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.blue)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.blue)
                            .frame(width: max(0, geo.size.width * CGFloat((monitor.snapshot.cpuPercent ?? 0) / 100.0)))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: monitor.snapshot.cpuPercent)
                    }
                }
                .frame(height: 8)
            }
            
            Divider()
            
            // GPU Section
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("GPU")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    Spacer()
                    Text(String(format: "%.0f%%", monitor.snapshot.gpuPercent ?? 0))
                        .font(.subheadline.monospacedDigit())
                        .foregroundColor(.purple)
                }
                
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.secondary.opacity(0.2))
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.purple)
                            .frame(width: max(0, geo.size.width * CGFloat((monitor.snapshot.gpuPercent ?? 0) / 100.0)))
                            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: monitor.snapshot.gpuPercent)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(16)
        .frame(width: 260)
    }
    
    private func colorForMem(percent: Double) -> Color {
        if percent > 80 { return .red }
        if percent > 60 { return .orange }
        return .green
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }
}
