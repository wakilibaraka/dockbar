import SwiftUI

struct WeatherHeroView: View {
    @ObservedObject var service: WeatherService
    @EnvironmentObject var settings: TaskbarSettings
    
    private let calendar = Calendar.current
    
    var body: some View {
        let conditions = service.conditions
        
        VStack {
            switch conditions.state {
            case .loading:
                ProgressView()
                    .frame(maxWidth: .infinity, minHeight: 120)
            case .available:
                HStack(spacing: 20) {
                    // Left Column (Current condition & temp)
                    VStack(spacing: 6) {
                        Image(systemName: conditions.symbolName)
                            .font(.system(size: 28, weight: .regular))
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.3), radius: 3)
                        
                        Text(conditions.temperature.map { WeatherService.displayTemperature($0, unit: settings.weatherUnit) } ?? "--")
                            .font(.system(size: 32, weight: .medium, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .frame(width: 80, height: 100)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    )
                    
                    // Right Column (Forecast Card)
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(conditions.locationName ?? "Weather")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 4) {
                                    Text(conditions.conditionText)
                                    Text("·")
                                    if let high = conditions.highTemperature {
                                        Text("H \(WeatherService.displayTemperature(high, unit: settings.weatherUnit))")
                                    }
                                    if let low = conditions.lowTemperature {
                                        Text("L \(WeatherService.displayTemperature(low, unit: settings.weatherUnit))")
                                    }
                                }
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            
                            Text(conditions.temperature.map { WeatherService.displayTemperature($0, unit: settings.weatherUnit) } ?? "--")
                                .font(.system(size: 36, weight: .light, design: .rounded))
                                .foregroundColor(.primary)
                                .offset(y: -6)
                        }
                        
                        Spacer()
                        
                        // Hourly Forecast
                        HStack(alignment: .bottom) {
                            let hours = Array(conditions.hourlyForecast.prefix(6))
                            ForEach(Array(hours.enumerated()), id: \.offset) { index, hour in
                                VStack(spacing: 6) {
                                    Text(hourString(from: hour.time))
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundColor(index == 0 ? .primary : .secondary)
                                    
                                    Image(systemName: WeatherService.icon(for: hour.weatherCode))
                                        .font(.system(size: 14))
                                        .foregroundColor(.primary)
                                    
                                    Text(WeatherService.displayTemperature(hour.temperature, unit: settings.weatherUnit))
                                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.primary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        
                        Spacer()
                        
                        // Footer
                        HStack {
                            if let updated = conditions.lastUpdated {
                                Text("Updated \(timeAgo(from: updated))")
                            }
                            Text("·")
                            Text("Apple Weather")
                        }
                        .font(.system(size: 9))
                        .foregroundColor(.secondary.opacity(0.7))
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity)
                    .frame(height: 120)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.primary.opacity(0.04))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                            )
                    )
                }
            default:
                VStack(spacing: 8) {
                    Image(systemName: "cloud.sun")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    Text(conditions.conditionText)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, minHeight: 120)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(16)
            }
        }
    }
    
    private func hourString(from date: Date) -> String {
        let hour = calendar.component(.hour, from: date)
        return String(format: "%02d", hour)
    }
    
    private func timeAgo(from date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
