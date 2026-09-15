import SwiftUI
import Combine

struct UnifiedSystemResourceWidgetView: View {
    @ObservedObject var monitor: SystemResourceMonitor
    
    var body: some View {
        let memPercent = monitor.snapshot.memoryUsedPercent ?? 0
        let memColor: Color = {
            if memPercent > 80 { return .red }
            if memPercent > 60 { return .orange }
            return .green
        }()
        
        Text("\(Int(memPercent))%")
            .font(.system(size: 11, weight: .bold, design: .monospaced))
            .padding(.horizontal, 6)
            .frame(height: 20)
            .background(memColor.opacity(0.15))
            .foregroundStyle(memColor)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}
