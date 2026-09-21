import Foundation
import Combine
import CoreLocation

struct WeatherConditions {
    enum State {
        case noLocation
        case loading
        case available
        case error(String)
    }

    var state: State = .noLocation
    var temperature: Double?
    var apparentTemperature: Double?
    var humidity: Double?
    var windSpeed: Double?
    var weatherCode: Int?
    var symbolName = "location.slash"
    var conditionText = "Location unavailable"
    var locationName: String?
    var lastUpdated: Date?
}

@MainActor
final class WeatherService: NSObject, ObservableObject, CLLocationManagerDelegate {
    @Published private(set) var conditions = WeatherConditions()

    private let settings: TaskbarSettings
    private let locationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private var timer: Timer?
    private var requestInFlight = false
    nonisolated(unsafe) private var timerReference: Timer?

    init(settings: TaskbarSettings) {
        self.settings = settings
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer

        settings.$weatherPollingInterval
            .sink { [weak self] _ in self?.restartTimer() }
            .store(in: &cancellables)
        settings.$weatherLocationMode
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
        settings.$weatherEnabled
            .sink { [weak self] _ in self?.refresh() }
            .store(in: &cancellables)
        settings.$weatherManualLatitude
            .combineLatest(settings.$weatherManualLongitude)
            .sink { [weak self] _, _ in self?.refresh() }
            .store(in: &cancellables)
    }

    private var cancellables = Set<AnyCancellable>()

    deinit {
        timerReference?.invalidate()
    }

    func start() {
        restartTimer()
        refresh()
    }

    func refresh() {
        guard settings.weatherEnabled else {
            conditions = WeatherConditions()
            return
        }

        guard !requestInFlight else { return }
        if settings.weatherLocationMode == .manual {
            let latitude = settings.weatherManualLatitude
            let longitude = settings.weatherManualLongitude
            guard (-90...90).contains(latitude), (-180...180).contains(longitude),
                  latitude != 0 || longitude != 0 else {
                conditions = WeatherConditions(state: .error("Enter a valid manual location"))
                return
            }
            fetchWeather(for: CLLocation(latitude: latitude, longitude: longitude), name: "Manual location")
            return
        }

        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            conditions.state = .loading
            locationManager.requestLocation()
        case .notDetermined:
            conditions = WeatherConditions(state: .noLocation, conditionText: "Location permission required")
            locationManager.requestWhenInUseAuthorization()
        default:
            conditions = WeatherConditions(state: .noLocation, conditionText: "Set a manual location")
        }
    }

    private func restartTimer() {
        timer?.invalidate()
        let interval = max(60, settings.weatherPollingInterval)
        let newTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            self?.refresh()
        }
        timer = newTimer
        timerReference = newTimer
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        refresh()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        geocoder.reverseGeocodeLocation(location) { [weak self] placemarks, _ in
            Task { @MainActor in
                let name = placemarks?.first?.locality
                    ?? placemarks?.first?.administrativeArea
                    ?? "Current location"
                self?.fetchWeather(for: location, name: name)
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        conditions = WeatherConditions(state: .error("Unable to determine location"))
    }

    private func fetchWeather(for location: CLLocation, name: String) {
        guard !requestInFlight else { return }
        requestInFlight = true
        // Only show the loading indicator when we have no temperature to display yet.
        // On subsequent refreshes the stale value stays visible — no "--" flash.
        if conditions.temperature == nil {
            conditions.state = .loading
        }

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m,wind_speed_10m"),
            URLQueryItem(name: "timezone", value: "auto")
        ]

        Task { [weak self] in
            defer { self?.requestInFlight = false }
            do {
                let (data, response) = try await URLSession.shared.data(from: components.url!)
                guard let httpResponse = response as? HTTPURLResponse,
                      (200...299).contains(httpResponse.statusCode) else {
                    throw URLError(.badServerResponse)
                }
                let payload = try JSONDecoder().decode(OpenMeteoResponse.self, from: data)
                self?.conditions = Self.conditions(from: payload.current, locationName: name)
            } catch {
                self?.conditions = WeatherConditions(state: .error("Weather unavailable"))
            }
        }
    }

    private static func conditions(from current: OpenMeteoCurrent, locationName: String) -> WeatherConditions {
        let description = description(for: current.weatherCode)
        return WeatherConditions(
            state: .available,
            temperature: current.temperature,
            apparentTemperature: current.apparentTemperature,
            humidity: current.humidity,
            windSpeed: current.windSpeed,
            weatherCode: current.weatherCode,
            symbolName: description.symbol,
            conditionText: description.text,
            locationName: locationName,
            lastUpdated: Date()
        )
    }

    static func displayTemperature(_ temperature: Double, unit: WeatherUnit) -> String {
        let value = unit == .celsius ? temperature : (temperature * 9 / 5) + 32
        return "\(Int(value.rounded()))°"
    }

    private static func description(for code: Int) -> (symbol: String, text: String) {
        switch code {
        case 0: return ("sun.max.fill", "Clear sky")
        case 1...3: return ("cloud.sun.fill", "Partly cloudy")
        case 45, 48: return ("cloud.fog.fill", "Fog")
        case 51...57: return ("cloud.drizzle.fill", "Drizzle")
        case 61...67: return ("cloud.rain.fill", "Rain")
        case 71...77: return ("cloud.snow.fill", "Snow")
        case 80...82: return ("cloud.heavyrain.fill", "Showers")
        case 85...86: return ("cloud.snow.fill", "Snow showers")
        case 95, 96, 99: return ("cloud.bolt.rain.fill", "Thunderstorm")
        default: return ("questionmark.circle", "Unknown")
        }
    }
}

private struct OpenMeteoResponse: Decodable {
    let current: OpenMeteoCurrent
}

private struct OpenMeteoCurrent: Decodable {
    let temperature: Double
    let weatherCode: Int
    let apparentTemperature: Double
    let humidity: Double
    let windSpeed: Double

    enum CodingKeys: String, CodingKey {
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
        case apparentTemperature = "apparent_temperature"
        case humidity = "relative_humidity_2m"
        case windSpeed = "wind_speed_10m"
    }
}
