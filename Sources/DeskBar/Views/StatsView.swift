import SwiftUI

struct StatsView: View {
    @ObservedObject var systemStats = SystemStatsService.shared
    @ObservedObject var bluetoothStats = BluetoothStatsService.shared
    
    var body: some View {
        VStack(spacing: 16) {
            // Top blocks
            HStack(spacing: 16) {
                // Battery Gauge
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                    
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(Color.secondary.opacity(0.2), lineWidth: 8)
                            
                            let percentage = systemStats.batteryStats?.percentage ?? 100
                            Circle()
                                .trim(from: 0, to: CGFloat(percentage) / 100)
                                .stroke(Color.orange, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                            
                            VStack(spacing: 0) {
                                Text("\(Int(percentage))%")
                                    .font(.system(size: 24, weight: .bold))
                                Image(systemName: "bolt.fill")
                                    .foregroundStyle(.orange)
                                    .font(.system(size: 10))
                                    .opacity(systemStats.batteryStats?.isCharging == true ? 1 : 0)
                            }
                        }
                        .frame(width: 80, height: 80)
                        .padding(.top, 8)
                        
                        Text(String(format: "%.1f W", systemStats.batteryStats?.wattage ?? 0))
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(.orange)
                        
                        Text(systemStats.batteryStats?.isCharging == true ? "Charging..." : "On Battery")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
                
                // Bluetooth List
                ZStack(alignment: .topLeading) {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color(NSColor.controlBackgroundColor))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connected Devices")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.secondary)
                        
                        ScrollView {
                            VStack(spacing: 8) {
                                if bluetoothStats.connectedDevices.isEmpty {
                                    Text("No Devices")
                                        .font(.system(size: 12))
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.top, 8)
                                } else {
                                    ForEach(bluetoothStats.connectedDevices) { device in
                                        HStack {
                                            Image(systemName: device.type == "headphones" ? "headphones" : (device.type == "mouse" ? "magicmouse" : "keyboard"))
                                                .foregroundStyle(.orange)
                                            Text(device.name)
                                                .font(.system(size: 12, weight: .medium))
                                                .lineLimit(1)
                                            Spacer()
                                            if let level = device.batteryLevel {
                                                Text("\(level)%")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundStyle(.orange)
                                            }
                                        }
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: 180)
            
            // Middle tiles
            HStack(spacing: 8) {
                StatTile(
                    icon: "bolt.fill", iconColor: .orange,
                    value: String(format: "%.1fW", systemStats.batteryStats?.wattage ?? 0),
                    label: "Draw"
                )
                StatTile(
                    icon: "thermometer.medium", iconColor: .teal,
                    value: systemStats.batteryStats?.temperature == 0 ? "—" : String(format: "%.0f°", systemStats.batteryStats?.temperature ?? 0),
                    label: "Temp"
                )
                StatTile(
                    icon: "heart.fill", iconColor: .green,
                    value: "\(systemStats.batteryStats?.healthPercentage ?? 100)%",
                    label: "Health"
                )
                StatTile(
                    icon: "arrow.2.circlepath", iconColor: .blue,
                    value: "\(systemStats.batteryStats?.cycleCount ?? 0)",
                    label: "Cycles"
                )
                StatTile(
                    icon: "checkmark.seal.fill", iconColor: .green,
                    value: systemStats.batteryStats?.condition.rawValue ?? "Normal",
                    label: "State"
                )
            }
            .frame(height: 64)
        }
        .padding(16)
        .frame(width: 400)
    }
}

struct StatTile: View {
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .foregroundStyle(iconColor)
                .font(.system(size: 14))
            Text(value)
                .font(.system(size: 13, weight: .bold))
            Text(label)
                .font(.system(size: 10))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
