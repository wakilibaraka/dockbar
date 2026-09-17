import SwiftUI

struct BatteryFlyoutView: View {
    @ObservedObject var systemStats = SystemStatsService.shared
    @ObservedObject var bluetoothStats = BluetoothStatsService.shared
    @ObservedObject var recentlyClosed = RecentlyClosedTracker.shared
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("DockBar")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Power & Devices")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)
            
            Divider().opacity(0.4)
            
            // Top Section: Battery & Devices
            HStack(alignment: .top, spacing: 14) {
                // Left Column: Battery Hero
                VStack {
                    Spacer()
                    BatteryHeroView(stats: systemStats.batteryStats)
                    Spacer()
                }
                .padding(14)
                .frame(width: 170)
                .frame(maxHeight: .infinity)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)
                
                // Right Column: Bluetooth Devices
                VStack(alignment: .leading, spacing: 8) {
                    Text("Connected Devices")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.secondary)
                        .padding(.leading, 4)
                    
                    if !bluetoothStats.connectedDevices.isEmpty {
                        ScrollView(.vertical, showsIndicators: true) {
                            VStack(spacing: 8) {
                                ForEach(bluetoothStats.connectedDevices) { device in
                                    DeviceCardView(device: device)
                                }
                            }
                            .padding(.trailing, 4)
                        }
                    } else {
                        VStack(spacing: 12) {
                            Spacer()
                            Image(systemName: "bolt.horizontal.circle")
                                .font(.system(size: 28))
                                .foregroundColor(.secondary.opacity(0.4))
                            Text("No Connected Devices")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(12)
            }
            .frame(height: 190)
            .padding(14)

            // Recently Closed Apps (Always render to maintain structure)
            VStack(alignment: .leading, spacing: 10) {
                Text("Recently Closed")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.secondary)
                
                if recentlyClosed.closedApps.isEmpty {
                    Text("No recently closed apps")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.vertical, 8)
                } else {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(recentlyClosed.closedApps, id: \.bundleIdentifier) { app in
                                Button(action: {
                                    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: app.bundleIdentifier) {
                                        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                                        recentlyClosed.remove(bundleIdentifier: app.bundleIdentifier)
                                    }
                                }) {
                                    VStack(spacing: 4) {
                                        if let icon = app.icon {
                                            Image(nsImage: icon)
                                                .resizable()
                                                .frame(width: 32, height: 32)
                                        } else {
                                            Color.gray.opacity(0.3).frame(width: 32, height: 32).cornerRadius(8)
                                        }
                                        Text(app.localizedName)
                                            .font(.system(size: 10))
                                            .lineLimit(1)
                                            .frame(width: 50)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
            
            // Context Menu Actions in a Unified Card
            VStack(spacing: 2) {
                ContextMenuButton(
                    title: "Restore Windows From Last Sleep",
                    icon: "uiwindow.split.2x1",
                    action: { NSApp.sendAction(Selector(("restoreWindowsFromLastSleep:")), to: nil, from: nil) }
                )
                Divider().opacity(0.4).padding(.horizontal, 8)
                ContextMenuButton(
                    title: "Settings...",
                    icon: "gearshape.fill",
                    action: { NSApp.sendAction(Selector(("openSettings:")), to: nil, from: nil) }
                )
                Divider().opacity(0.4).padding(.horizontal, 8)
                ContextMenuButton(
                    title: "Quit DeskBar",
                    icon: "power",
                    action: { NSApp.terminate(nil) },
                    isDestructive: true
                )
            }
            .padding(.vertical, 6)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(12)
            .padding(.horizontal, 14)
            .padding(.bottom, 14)
        }
        .frame(width: 440)
        .onAppear {
            bluetoothStats.startMonitoring()
            systemStats.updateBatteryStats()
        }
    }
}

struct BatteryHeroView: View {
    let stats: MacBatteryStats?

    private var ringColor: [Color] {
        guard let stats = stats else { return [.gray] }
        let pct = stats.percentage
        if stats.isCharging { return [Color.yellow, Color.orange] }
        if pct < 20 { return [Color.red, Color.orange] }
        if pct < 50 { return [Color.orange, Color.yellow] }
        return [Color.green, Color.cyan]
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Circular progress ring
            ZStack {
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 8)
                
                let pct = stats?.percentage ?? 0
                Circle()
                    .trim(from: 0.0, to: CGFloat(min(max(pct / 100.0, 0.0), 1.0)))
                    .stroke(
                        LinearGradient(colors: ringColor, startPoint: .topLeading, endPoint: .bottomTrailing),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.7, dampingFraction: 0.8), value: pct)
                
                VStack(spacing: 2) {
                    Text("\(Int(pct))%")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                        .contentTransition(.numericText())
                        .animation(.easeOut(duration: 0.3), value: pct)
                    
                    if stats?.isCharging == true {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.yellow)
                            .shadow(color: Color.yellow.opacity(0.4), radius: 3, x: 0, y: 0)
                    }
                }
            }
            .frame(width: 90, height: 90)
            
            // Power draw row
            VStack(spacing: 3) {
                if let stats = stats {
                    if stats.wattage > 0.1 {
                        HStack(spacing: 4) {
                            Image(systemName: stats.isCharging ? "bolt.fill" : "bolt.horizontal.fill")
                                .font(.system(size: 9))
                            Text(String(format: "%.1f W", stats.wattage))
                                .font(.system(size: 11, weight: .semibold, design: .rounded))
                        }
                        .foregroundColor(stats.isCharging ? .yellow.opacity(0.9) : .secondary)
                        .animation(.easeOut(duration: 0.3), value: stats.isCharging)
                    }
                    
                    // Temperature & health row
                    HStack(spacing: 8) {
                        if stats.temperature > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "thermometer.medium")
                                    .font(.system(size: 9))
                                Text(String(format: "%.0f°C", stats.temperature))
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(stats.temperature > 40 ? .orange : .secondary.opacity(0.8))
                        }
                        
                        if stats.healthPercentage > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "heart.fill")
                                    .font(.system(size: 9))
                                Text(String(format: "%d%%", stats.healthPercentage))
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(stats.healthPercentage < 80 ? .orange : .secondary.opacity(0.8))
                        }
                        
                        if stats.cycleCount > 0 {
                            HStack(spacing: 3) {
                                Image(systemName: "arrow.trianglehead.2.clockwise")
                                    .font(.system(size: 9))
                                Text("\(stats.cycleCount)")
                                    .font(.system(size: 10))
                            }
                            .foregroundColor(.secondary.opacity(0.7))
                        }
                    }
                }
            }
            .padding(.top, 2)
        }
    }
}

struct DeviceCardView: View {
    let device: BluetoothDeviceStats
    
    var body: some View {
        let percent = device.batteryLevel ?? 0
        let isLowBattery = percent > 0 && percent < 20
        
        let iconName: String = {
            switch device.type {
            case "mouse": return "magicmouse"
            case "keyboard": return "keyboard"
            case "headphones": return "headphones"
            default: return "bluetooth"
            }
        }()
        
        HStack(spacing: 8) {
            Image(systemName: iconName)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(isLowBattery ? .orange : .primary.opacity(0.8))
                .frame(width: 26, height: 26)
                .background(Color.primary.opacity(0.04))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 3) {
                Text(device.name)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .lineLimit(1)
                    .foregroundColor(.primary)
                
                if device.batteryLevel != nil {
                    // Color-coded battery bar
                    GeometryReader { geo in
                        let pct = CGFloat(percent) / 100.0
                        let barColor: Color = {
                            if pct < 0.2 { return .red }
                            if pct < 0.5 { return .orange }
                            return .green
                        }()
                        
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.primary.opacity(0.1))
                            Capsule()
                                .fill(barColor)
                                .frame(width: max(0, pct * geo.size.width))
                        }
                    }
                    .frame(height: 4)
                } else {
                    Text("Connected")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
            
            if let level = device.batteryLevel {
                Text("\(level)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.secondary)
                    .frame(width: 30, alignment: .trailing)
            }
        }
        .padding(8)
        .background(Color.primary.opacity(0.03))
        .cornerRadius(8)
    }
}


struct ContextMenuButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var isDestructive: Bool = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .frame(width: 20)
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Text(title)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isDestructive ? .red : .primary)
                
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            // macOS standard context menu uses a subtle background on hover, but since we cannot use @State easily here due to the SPM macro bug, we will let PlainButtonStyle handle the basic interaction, or use a built-in style.
        }
        .buttonStyle(PlainButtonStyle())
    }
}
