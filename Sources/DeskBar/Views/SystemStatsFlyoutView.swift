import SwiftUI
import Combine
import AppKit

struct SystemStatsFlyoutView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    @StateObject private var samples = ResourceSamples()
    @StateObject private var batteryService = SystemStatsService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // CPU & GPU
            HStack(spacing: 12) {
                if let cpu = monitor.snapshot.cpuPercent {
                    ResourceRow(title: "CPU", valueText: String(format: "%.0f%%", cpu), percent: cpu, color: .blue, samples: samples.cpu)
                }
                
                if let gpu = monitor.snapshot.gpuPercent {
                    ResourceRow(title: "GPU", valueText: String(format: "%.0f%%", gpu), percent: gpu, color: .purple, samples: samples.gpu)
                }
            }
            
            // RAM
            if let memory = monitor.snapshot.memoryUsedPercent {
                let text = "\(formatBytes(monitor.snapshot.memoryUsedBytes ?? 0)) / \(formatBytes(monitor.snapshot.memoryTotalBytes ?? 0))"
                ResourceRow(title: "RAM", valueText: text, percent: memory, color: .green, samples: samples.memory)
            }
            
            // Battery
            if let bat = batteryService.batteryStats {
                VStack(spacing: 6) {
                    HStack {
                        Text("Battery")
                            .font(.system(size: 12, weight: .medium))
                        Spacer()
                        Text("\(Int(bat.percentage))% • \(bat.isCharging ? "Charging" : "Discharging")")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    MetricGraphView(
                        samples: [bat.percentage],
                        accent: bat.percentage < 20 && !bat.isCharging ? .red : .yellow,
                        style: .filledWave,
                        maximum: 100
                    )
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack {
                        Text("Health: \(bat.healthPercentage)%")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(bat.cycleCount) Cycles")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.1))
            
            BackgroundProcessesSectionView()
        }
        .padding(16)
        .frame(width: 280)
        .onReceive(monitor.$snapshot) { snapshot in
            if let cpu = snapshot.cpuPercent {
                samples.cpu = Array((samples.cpu + [cpu]).suffix(60))
            }
            if let gpu = snapshot.gpuPercent {
                samples.gpu = Array((samples.gpu + [gpu]).suffix(60))
            }
            if let memory = snapshot.memoryUsedPercent {
                samples.memory = Array((samples.memory + [memory]).suffix(60))
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }
}

private final class ResourceSamples: ObservableObject {
    @Published var cpu: [Double] = []
    @Published var gpu: [Double] = []
    @Published var memory: [Double] = []
}

struct ResourceRow: View {
    let title: String
    let valueText: String
    let percent: Double
    let color: Color
    let samples: [Double]
    var maximum: Double? = 100
    
    var body: some View {
        VStack(spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                Spacer()
                Text(valueText)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            MetricGraphView(
                samples: samples.isEmpty ? [percent] : samples,
                accent: color,
                style: .filledWave,
                maximum: maximum
            )
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Background Processes
struct BackgroundProcessesSectionView: View {
    @StateObject private var viewModel = AccessoryAppsViewModel()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Background Apps")
                    .font(.system(size: 14, weight: .semibold))
                Spacer()
                if viewModel.isRefreshing {
                    ProgressView()
                        .controlSize(.mini)
                }
            }
            
            if viewModel.apps.isEmpty && !viewModel.isRefreshing {
                Text("No 3rd-party background apps found.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.apps.prefix(6), id: \.processIdentifier) { app in
                        HStack(spacing: 10) {
                            if let icon = app.icon {
                                Image(nsImage: icon)
                                    .resizable()
                                    .frame(width: 16, height: 16)
                            } else {
                                Image(systemName: "gearshape.fill")
                                    .resizable()
                                    .frame(width: 16, height: 16)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(app.localizedName ?? "Unknown")
                                .font(.system(size: 12))
                                .lineLimit(1)
                            
                            Spacer()
                            
                            if let mem = viewModel.memoryMap[app.processIdentifier] {
                                Text(formatRAM(mem))
                                    .font(.system(size: 10, weight: .medium, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }
                            
                            Button(action: {
                                app.terminate()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.refreshApps()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
                                    .font(.system(size: 12))
                            }
                            .buttonStyle(.plain)
                            .onHover { hovering in
                                if hovering {
                                    NSCursor.pointingHand.push()
                                } else {
                                    NSCursor.pop()
                                }
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshApps()
        }
    }
    
    private func formatRAM(_ bytes: Int) -> String {
        let mb = Double(bytes) / 1_048_576
        if mb > 1024 {
            return String(format: "%.1f GB", mb / 1024)
        }
        return String(format: "%.0f MB", mb)
    }
}

class AccessoryAppsViewModel: ObservableObject {
    @Published var apps: [NSRunningApplication] = []
    @Published var memoryMap: [pid_t: Int] = [:]
    @Published var isRefreshing = false
    
    init() {
        refreshApps(sync: true)
    }
    
    func refreshApps(sync: Bool = false) {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        let work = {
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/ps")
            task.arguments = ["-x", "-o", "pid,rss"]
            let pipe = Pipe()
            task.standardOutput = pipe
            try? task.run()
            task.waitUntilExit()
            
            var memMap: [pid_t: Int] = [:]
            if let data = try? pipe.fileHandleForReading.readToEnd(),
               let output = String(data: data, encoding: .utf8) {
                let lines = output.split(separator: "\n")
                for line in lines.dropFirst() {
                    let parts = line.split(separator: " ", omittingEmptySubsequences: true)
                    if parts.count >= 2, let pid = Int32(parts[0]), let rss = Int(parts[1]) {
                        memMap[pid] = rss * 1024 // RSS is in KB, convert to bytes
                    }
                }
            }
            
            let filtered = NSWorkspace.shared.runningApplications
                .filter { $0.activationPolicy == .accessory }
                .filter { app in
                    guard let path = app.bundleURL?.path else { return false }
                    // Exclude Apple system background apps
                    if path.hasPrefix("/System/") { return false }
                    if path.hasPrefix("/usr/") { return false }
                    return true
                }
                .filter { $0.localizedName != nil && !$0.localizedName!.isEmpty }
                .sorted {
                    let mem0 = memMap[$0.processIdentifier] ?? 0
                    let mem1 = memMap[$1.processIdentifier] ?? 0
                    if mem0 != mem1 {
                        return mem0 > mem1
                    }
                    return ($0.localizedName ?? "") < ($1.localizedName ?? "")
                }
            
            if sync {
                DispatchQueue.main.async {
                    self.apps = filtered
                    self.memoryMap = memMap
                    self.isRefreshing = false
                }
            } else {
                DispatchQueue.main.async {
                    self.apps = filtered
                    self.memoryMap = memMap
                    self.isRefreshing = false
                }
            }
            return (filtered, memMap)
        }
        
        if sync {
            let (f, m) = work()
            self.apps = f
            self.memoryMap = m
            self.isRefreshing = false
        } else {
            DispatchQueue.global(qos: .userInitiated).async { _ = work() }
        }
    }
}
