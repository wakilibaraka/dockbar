import SwiftUI
import Combine

struct UnifiedSystemResourceWidgetView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    @ObservedObject var systemStats = SystemStatsService.shared
    
    var body: some View {
        let memPercent = monitor.snapshot.memoryUsedPercent ?? 0
        let memColor: Color = {
            if memPercent > 80 { return .red }
            if memPercent > 60 { return .orange }
            return .green
        }()
        
        let batPercent = systemStats.batteryStats?.percentage ?? 100
        let isCharging = systemStats.batteryStats?.isCharging ?? false
        let batColor: Color = {
            if isCharging { return .green }
            if batPercent > 40 { return Color(NSColor.controlBackgroundColor) } // neutral
            if batPercent > 20 { return .orange }
            return .red
        }()
        
        let batFgColor: Color = {
            if isCharging { return .white }
            if batPercent > 40 { return .primary }
            return .white
        }()
        
        HStack(spacing: 4) {
            // Battery Pill
            HStack(spacing: 2) {
                if isCharging {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 9, weight: .bold))
                }
                Text("\(Int(batPercent))%")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
            }
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(batColor.opacity(0.8))
            .foregroundStyle(batFgColor)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            
            // Memory Pill
            Text("\(Int(memPercent))%")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .padding(.horizontal, 6)
                .frame(height: 20)
                .background(memColor.opacity(0.15))
                .foregroundStyle(memColor)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
    }
}
