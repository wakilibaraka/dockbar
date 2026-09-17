import SwiftUI

struct SystemResourceDashboardView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    var smPluginService: SMPluginService?

    
    // Theme Colors
    private let bgCard = Color.black.opacity(0.15)
    private let bgAccent = Color(nsColor: NSColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0))
    private let borderDark = Color.white.opacity(0.05)
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 2. Antigravity Activity
            if let smPluginService = smPluginService {
                AgentActivitySectionView(service: smPluginService)
                Divider().overlay(borderDark)
            }
            
            // 3. System Resources
            SystemResourcesSectionView(monitor: monitor)
            
            Divider().overlay(borderDark)
            
            // 4. Background Processes
            BackgroundProcessesSectionView()
            
        }
        .padding(20)
        .frame(width: 360)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(NSColor.windowBackgroundColor))
        )
        .onAppear {
            BluetoothStatsService.shared.startMonitoring()
        }
        .onDisappear {
            BluetoothStatsService.shared.stopMonitoring()
        }
    }
}


// MARK: - Antigravity Activity
struct AgentActivitySectionView: View {
    @ObservedObject var service: SMPluginService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Antigravity Activity")
                .font(.system(size: 14, weight: .semibold))
            
            HStack(spacing: 8) {
                AgentBadge(title: "ACT", value: service.watchSummary.workingCount, color: Color(nsColor: NSColor(red: 0.42, green: 0.8, blue: 0.67, alpha: 1.0))) // Soft Green
                AgentBadge(title: "THK", value: service.watchSummary.thinkingCount, color: Color(nsColor: NSColor(red: 0.98, green: 0.82, blue: 0.45, alpha: 1.0))) // Soft Yellow
                AgentBadge(title: "PRM", value: service.watchSummary.waitingPermissionCount, color: Color.orange)
                AgentBadge(title: "IDL", value: service.watchSummary.idleCount, color: Color.secondary)
            }
        }
    }
}

struct AgentBadge: View {
    let title: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(value > 0 ? color : Color.secondary.opacity(0.5))
            Text("\(value)")
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(value > 0 ? .primary : Color.secondary.opacity(0.5))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.05), lineWidth: 1))
    }
}

// MARK: - System Resources
struct SystemResourcesSectionView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("System Resources")
                .font(.system(size: 14, weight: .semibold))
            
            VStack(spacing: 12) {
                ResourceRow(
                    title: "Memory",
                    valueText: formatBytes(monitor.snapshot.memoryUsedBytes ?? 0),
                    percent: monitor.snapshot.memoryPressurePercent ?? 0,
                    color: Color(nsColor: NSColor(red: 0.20, green: 0.49, blue: 0.93, alpha: 1.0)) // Muted Blue
                )
                
                ResourceRow(
                    title: "CPU",
                    valueText: String(format: "%.1f%%", monitor.snapshot.cpuPercent ?? 0),
                    percent: monitor.snapshot.cpuPercent ?? 0,
                    color: Color(nsColor: NSColor(red: 0.48, green: 0.67, blue: 0.96, alpha: 1.0)) // Light Accent Blue
                )
                
                if let gpu = monitor.snapshot.gpuPercent {
                    ResourceRow(
                        title: "GPU",
                        valueText: String(format: "%.1f%%", gpu),
                        percent: gpu,
                        color: Color.purple.opacity(0.7)
                    )
                }
            }
        }
    }
    
    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / 1_073_741_824
        return String(format: "%.1f GB", gb)
    }
}

struct ResourceRow: View {
    let title: String
    let valueText: String
    let percent: Double
    let color: Color
    
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
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.05))
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(0, geo.size.width * CGFloat(percent / 100.0)))
                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: percent)
                }
            }
            .frame(height: 6)
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
        refreshApps()
    }
    
    func refreshApps() {
        guard !isRefreshing else { return }
        isRefreshing = true
        
        DispatchQueue.global(qos: .userInitiated).async {
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
            
            DispatchQueue.main.async {
                self.apps = filtered
                self.memoryMap = memMap
                self.isRefreshing = false
            }
        }
    }
}
