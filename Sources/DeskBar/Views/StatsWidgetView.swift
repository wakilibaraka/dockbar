import SwiftUI

struct StatsWidgetView: View {
    @ObservedObject var statsService = SystemStatsService.shared
    
    var body: some View {
        let percentage = statsService.batteryStats?.percentage ?? 100
        let isCharging = statsService.batteryStats?.isCharging ?? false
        
        let bgColor: Color = {
            if isCharging { return Color.green.opacity(0.8) }
            if percentage > 40 { return Color(NSColor.controlBackgroundColor).opacity(0.8) } // neutral
            if percentage > 20 { return Color.orange.opacity(0.8) }
            return Color.red.opacity(0.8)
        }()
        
        let fgColor: Color = {
            if isCharging { return .white }
            if percentage > 40 { return .primary }
            return .white
        }()
        
        HStack(spacing: 4) {
            if isCharging {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 11, weight: .bold))
            }
            Text("\(Int(percentage))%")
                .font(.system(size: 13, weight: .heavy, design: .rounded))
        }
        .padding(.horizontal, 8)
        .frame(height: 26)
        .background(bgColor)
        .foregroundStyle(fgColor)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .help("System Stats")
    }
}
