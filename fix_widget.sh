#!/bin/bash
cat << 'SWIFT' > Sources/DeskBar/Views/UnifiedSystemResourceWidgetView.swift
import SwiftUI
import Combine

struct UnifiedSystemResourceWidgetView: View {
    @ObservedObject var settings: TaskbarSettings
    @ObservedObject var monitor: SystemResourceMonitor
    @ObservedObject var systemStats = SystemStatsService.shared
    
    var body: some View {
        let cpuPercent = monitor.snapshot.cpuPercent ?? 0
        let memPercent = monitor.snapshot.memoryUsedPercent ?? 0
        
        let cpuColor = color(for: cpuPercent)
        let memColor = Color(NSColor.systemBlue)
        let pressureColor = color(for: memPercent)
        
        let hasBattery = systemStats.batteryStats != nil
        let baseWidth: CGFloat = settings.showRingCharts ? 44 : 56
        
        HStack(spacing: 6) {
            // Pill 1: CPU / RAM
            ZStack {
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(Color.primary.opacity(0.06))
                    .frame(width: baseWidth, height: 24)
                
                HStack(spacing: settings.showRingCharts ? 6 : 4) {
                    if settings.showRingCharts {
                        // Ring Charts
                        ZStack {
                            Circle().stroke(cpuColor.opacity(0.15), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .frame(width: 16, height: 16)
                            Circle().trim(from: 0, to: CGFloat(min(cpuPercent / 100.0, 1.0)))
                                .stroke(cpuColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 16, height: 16)
                                .animation(.linear(duration: 1.0), value: cpuPercent)
                            
                            Circle().stroke(memColor.opacity(0.15), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .frame(width: 9, height: 9)
                            Circle().trim(from: 0, to: CGFloat(min(memPercent / 100.0, 1.0)))
                                .stroke(memColor, style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
                                .rotationEffect(.degrees(-90))
                                .frame(width: 9, height: 9)
                                .animation(.linear(duration: 1.0), value: memPercent)
                        }
                    } else {
                        // Text metrics
                        VStack(alignment: .trailing, spacing: 1) {
                            Text("CPU \(Int(cpuPercent))%")
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundColor(cpuColor)
                            Text("RAM \(Int(memPercent))%")
                                .font(.system(size: 8, weight: .semibold, design: .monospaced))
                                .foregroundColor(memColor)
                        }
                    }
                    
                    // Memory Pressure Dot
                    Circle()
                        .fill(pressureColor)
                        .frame(width: 4, height: 4)
                        .shadow(color: pressureColor.opacity(0.5), radius: 2)
                }
            }
            
            // Pill 2: Battery
            if let battery = systemStats.batteryStats {
                ZStack {
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(0.06))
                        .frame(width: 28, height: 24)
                    
                    ZStack {
                        Image(systemName: "battery.100")
                            .font(.system(size: 11))
                            .opacity(0.4)
                        if battery.isCharging {
                            Image(systemName: "bolt.fill")
                                .font(.system(size: 8))
                                .foregroundColor(.orange)
                        }
                    }
                }
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
SWIFT
