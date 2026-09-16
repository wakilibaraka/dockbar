import SwiftUI
import Combine

struct UnifiedSystemResourceWidgetView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var monitor: SystemResourceMonitor
    
    var body: some View {
        let cpuPercent = monitor.snapshot.cpuPercent ?? 0
        let memPercent = monitor.snapshot.memoryUsedPercent ?? 0
        
        let cpuColor = color(for: cpuPercent)
        let memColor = Color(NSColor.systemBlue)
        let pressureColor = color(for: memPercent)
        
        let baseWidth: CGFloat = 56
        
        ZStack {
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.primary.opacity(0.06))
                .frame(width: baseWidth, height: 24)
            
            HStack(spacing: 4) {
                // Text metrics
                VStack(alignment: .trailing, spacing: 1) {
                    Text("CPU \(Int(cpuPercent))%")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(cpuColor)
                    Text("RAM \(Int(memPercent))%")
                        .font(.system(size: 8, weight: .semibold, design: .monospaced))
                        .foregroundColor(memColor)
                }
                
                // Memory Pressure Dot
                Circle()
                    .fill(pressureColor)
                    .frame(width: 4, height: 4)
                    .shadow(color: pressureColor.opacity(0.5), radius: 2)
            }
        }
        .frame(width: baseWidth, height: 32)
    }
    
    private func color(for percent: Double) -> Color {
        if percent > 80 { return .red }
        if percent > 60 { return .orange }
        return .green
    }
}
