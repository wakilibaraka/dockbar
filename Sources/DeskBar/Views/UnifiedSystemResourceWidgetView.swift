import SwiftUI
import Combine

struct UnifiedSystemResourceWidgetView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    
    // CPU: outer ring, Memory: inner ring
    var body: some View {
        let cpuPercent = monitor.snapshot.cpuPercent ?? 0
        let memPercent = monitor.snapshot.memoryUsedPercent ?? 0
        
        let cpuColor = color(for: cpuPercent)
        let memColor = color(for: memPercent)
        
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(Color.white.opacity(0.06))
                .frame(width: 44, height: 24)
            
            HStack(spacing: 6) {
                // Outer ring CPU, Inner ring Memory
                ZStack {
                    // CPU Background
                    Circle().stroke(cpuColor.opacity(0.15), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 16, height: 16)
                    // CPU Foreground
                    Circle().trim(from: 0, to: CGFloat(min(cpuPercent / 100.0, 1.0)))
                        .stroke(cpuColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 16, height: 16)
                        .animation(.linear(duration: 1.0), value: cpuPercent)
                    
                    // Memory Background
                    Circle().stroke(memColor.opacity(0.15), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .frame(width: 9, height: 9)
                    // Memory Foreground
                    Circle().trim(from: 0, to: CGFloat(min(memPercent / 100.0, 1.0)))
                        .stroke(memColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .frame(width: 9, height: 9)
                        .animation(.linear(duration: 1.0), value: memPercent)
                }
                
                // Agent badge
                Circle()
                    .fill(Color(red: 1.0, green: 0.28, blue: 0.0)) // Ember color
                    .frame(width: 4, height: 4)
                    .shadow(color: Color(red: 1.0, green: 0.28, blue: 0.0), radius: 2)
            }
        }
        .frame(height: 32)
    }
    
    private func color(for percent: Double) -> Color {
        if percent > 80 { return .red }
        if percent > 60 { return .orange }
        return .green
    }
}
