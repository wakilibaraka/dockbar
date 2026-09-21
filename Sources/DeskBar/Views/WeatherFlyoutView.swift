import SwiftUI

@MainActor
struct WeatherFlyoutView: View {
    @ObservedObject var service: WeatherService
    @ObservedObject var settings: TaskbarSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(service.conditions.locationName ?? "Weather")
                .font(.headline)
            switch service.conditions.state {
            case .available:
                let conditions = service.conditions
                HStack(spacing: 10) {
                    Image(systemName: conditions.symbolName)
                        .font(.system(size: 30))
                    Text(conditions.temperature.map {
                        WeatherService.displayTemperature($0, unit: settings.weatherUnit)
                    } ?? "--")
                        .font(.system(size: 28, weight: .medium, design: .rounded))
                }
                Text(conditions.conditionText)
                detail("Feels like", conditions.apparentTemperature.map {
                    WeatherService.displayTemperature($0, unit: settings.weatherUnit)
                } ?? "--")
                detail("Humidity", conditions.humidity.map { "\(Int($0.rounded()))%" } ?? "--")
                detail("Wind", conditions.windSpeed.map { "\(Int($0.rounded())) km/h" } ?? "--")
                if let updated = conditions.lastUpdated {
                    Text("Updated \(updated.formatted(date: .omitted, time: .shortened))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            case .loading:
                ProgressView("Loading weather…")
            case .noLocation:
                Text(service.conditions.conditionText)
                    .foregroundStyle(.secondary)
            case .error(let message):
                Text(message)
                    .foregroundStyle(.secondary)
            }
            Divider()
            Text("Weather data by Open-Meteo")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 250, alignment: .leading)
    }

    private func detail(_ label: String, _ value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.callout)
    }
}
