import SwiftUI
import AppKit
import DockBarCore

struct BatteryWidgetDescriptor: WidgetDescriptor {
    let id = "battery"
    let preferredSize = CGSize(width: 50, height: 44)
    let defaultRule: WidgetLocation = .dock
    
    func makeView(context: WidgetContext) -> NSView {
        let view = NSHostingView(rootView: BatteryWidgetView(context: context))
        view.sizingOptions = []
        return view
    }
}

struct BatteryWidgetView: View {
    let context: WidgetContext
    @StateObject private var service = SystemStatsService.shared
    
    private func batteryIcon(for stats: MacBatteryStats) -> String {
        if stats.isCharging { return "battery.100.bolt" }
        let p = Int(stats.percentage)
        if p > 75 { return "battery.100" }
        if p > 50 { return "battery.75" }
        if p > 25 { return "battery.50" }
        return "battery.25"
    }

    var body: some View {
        HStack(spacing: 4) {
            if let stats = service.batteryStats {
                Image(systemName: batteryIcon(for: stats))
                    .font(.system(size: 14))
                    .foregroundColor(Int(stats.percentage) <= 20 && !stats.isCharging ? .red : .white)
                
                if context.settings.showBatteryPercentage {
                    Text("\(Int(stats.percentage))%")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                }
            } else {
                Image(systemName: "battery.100")
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
        }
        .frame(height: 44)
        .padding(.horizontal, 6)
        .onTapGesture {
            context.openFlyout(AnyView(BatteryFlyoutView()))
        }
    }
}

struct BatteryFlyoutView: View {
    @StateObject private var service = SystemStatsService.shared
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Battery")
                .font(.headline)
            if let bat = service.batteryStats {
                Text("\(Int(bat.percentage))% • \(bat.isCharging ? "Charging" : "Discharging")")
                    .font(.subheadline)
            } else {
                Text("Calculating...")
            }
        }
        .padding()
        .frame(width: 200)
    }
}
