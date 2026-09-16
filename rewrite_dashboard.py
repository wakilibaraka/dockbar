import re

content = """import SwiftUI

struct SystemResourceDashboardView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    var smPluginService: SMPluginService?
    @ObservedObject var systemStats = SystemStatsService.shared
    @ObservedObject var bluetoothStats = BluetoothStatsService.shared
    
    // Theme Colors
    private let bgCard = Color.black.opacity(0.15)
    private let bgAccent = Color(nsColor: NSColor(red: 0.12, green: 0.14, blue: 0.16, alpha: 1.0))
    private let borderDark = Color.white.opacity(0.05)
    
    var body: some View {
        VStack(spacing: 20) {
            
            // 1. Battery & Devices
            BatteryAndDevicesSection(
                systemStats: systemStats,
                bluetoothStats: bluetoothStats
            )
            
            Divider().overlay(borderDark)
            
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
        .frame(width: 340)
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

// MARK: - Battery & Devices
struct BatteryAndDevicesSection: View {
    @ObservedObject var systemStats: SystemStatsService
    @ObservedObject var bluetoothStats: BluetoothStatsService
    
    var body: some View {
        HStack(spacing: 12) {
            // Main Battery Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Battery")
                            .font(.system(size: 13, weight: .semibold))
                        Text(systemStats.batteryStats?.isCharging == true ? "Charging" : "Discharging")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    ZStack {
                        let percentage = systemStats.batteryStats?.percentage ?? 100
                        Circle()
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 4)
                        Circle()
                            .trim(from: 0, to: CGFloat(percentage) / 100)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        
                        Text("\(Int(percentage))%")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .frame(width: 32, height: 32)
                }
                
                HStack(spacing: 12) {
                    PowerMetric(icon: "bolt.fill", value: String(format: "%.1f W", systemStats.batteryStats?.wattage ?? 0))
                    PowerMetric(icon: "arrow.2.circlepath", value: "\(systemStats.batteryStats?.cycleCount ?? 0) cyc")
                    PowerMetric(icon: "heart.fill", value: "\(systemStats.batteryStats?.healthPercentage ?? 100)%")
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
            
            // Devices Card
            VStack(alignment: .leading, spacing: 8) {
                Text("Devices")
                    .font(.system(size: 13, weight: .semibold))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if bluetoothStats.connectedDevices.isEmpty {
                            Text("No devices")
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(bluetoothStats.connectedDevices) { device in
                                HStack {
                                    Image(systemName: deviceIcon(for: device.type))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(device.name)
                                        .font(.system(size: 11, weight: .medium))
                                        .lineLimit(1)
                                    Spacer(minLength: 4)
                                    if let level = device.batteryLevel {
                                        Text("\(level)%")
                                            .font(.system(size: 10, weight: .bold, design: .monospaced))
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.primary.opacity(0.04))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.05), lineWidth: 1))
        }
        .frame(height: 110)
    }
    
    private func deviceIcon(for type: String) -> String {
        switch type {
        case "headphones": return "headphones"
        case "mouse": return "magicmouse"
        default: return "keyboard"
        }
    }
}

struct PowerMetric: View {
    let icon: String
    let value: String
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .medium, design: .monospaced))
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
                    valueText: formatBytes(monitor.snapshot.memoryUsed ?? 0),
                    percent: monitor.snapshot.memoryUsedPercent ?? 0,
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
            Text("Background Processes")
                .font(.system(size: 14, weight: .semibold))
            
            if viewModel.apps.isEmpty {
                Text("No background processes found.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.apps.prefix(4), id: \.processIdentifier) { app in
                        HStack {
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
                            
                            Button(action: {
                                app.terminate()
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                    viewModel.refreshApps()
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.secondary)
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
}

// AccessoryAppsViewModel (retained exactly as before)
class AccessoryAppsViewModel: ObservableObject {
    @Published var apps: [NSRunningApplication] = []
    
    init() {
        refreshApps()
    }
    
    func refreshApps() {
        self.apps = NSWorkspace.shared.runningApplications
            .filter { $0.activationPolicy == .accessory || $0.activationPolicy == .prohibited }
            .filter { $0.localizedName != nil && !$0.localizedName!.isEmpty }
            .sorted { ($0.localizedName ?? "") < ($1.localizedName ?? "") }
    }
}
"""

with open('Sources/DeskBar/Views/SystemResourceDashboardView.swift', 'w') as f:
    f.write(content)
