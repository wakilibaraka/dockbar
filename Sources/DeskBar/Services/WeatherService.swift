import Foundation
import Combine
import CoreLocation

struct CachedWeather: Codable {
    let temperature: Double?
    let apparentTemperature: Double?
    let humidity: Double?
    let windSpeed: Double?
    let weatherCode: Int?
    let symbolName: String
    let conditionText: String
    let locationName: String?
    let lastUpdated: Date?
    let highTemperature: Double?
    let lowTemperature: Double?
    let hourlyForecast: [HourlyForecastCache]
    
    struct HourlyForecastCache: Codable {
        let time: Date
        let temperature: Double
        let weatherCode: Int
    }
}

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
    var highTemperature: Double?
    var lowTemperature: Double?
    var hourlyForecast: [HourlyForecast] = []
}

struct HourlyForecast: Identifiable {
    let id = UUID()
    let time: Date
    let temperature: Double
    let weatherCode: Int
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


    func requestLocationAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    var authorizationStatus: CLAuthorizationStatus {
        if #available(macOS 11.0, *) {
            return locationManager.authorizationStatus
        } else {
            return CLLocationManager.authorizationStatus()
        }
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
        conditions.state = .loading

        var components = URLComponents(string: "https://api.open-meteo.com/v1/forecast")!
        components.queryItems = [
            URLQueryItem(name: "latitude", value: String(location.coordinate.latitude)),
            URLQueryItem(name: "longitude", value: String(location.coordinate.longitude)),
            URLQueryItem(name: "current", value: "temperature_2m,weather_code,apparent_temperature,relative_humidity_2m,wind_speed_10m"),
            URLQueryItem(name: "hourly", value: "temperature_2m,weather_code"),
            URLQueryItem(name: "daily", value: "temperature_2m_max,temperature_2m_min"),
            URLQueryItem(name: "timeformat", value: "unixtime"),
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
                self?.conditions = Self.conditions(from: payload, locationName: name)
                
                // Cache it
                if let conditions = self?.conditions {
                    let cache = CachedWeather(
                        temperature: conditions.temperature,
                        apparentTemperature: conditions.apparentTemperature,
                        humidity: conditions.humidity,
                        windSpeed: conditions.windSpeed,
                        weatherCode: conditions.weatherCode,
                        symbolName: conditions.symbolName,
                        conditionText: conditions.conditionText,
                        locationName: conditions.locationName,
                        lastUpdated: conditions.lastUpdated,
                        highTemperature: conditions.highTemperature,
                        lowTemperature: conditions.lowTemperature,
                        hourlyForecast: conditions.hourlyForecast.map { CachedWeather.HourlyForecastCache(time: $0.time, temperature: $0.temperature, weatherCode: $0.weatherCode) }
                    )
                    if let encoded = try? JSONEncoder().encode(cache) {
                        UserDefaults.standard.set(encoded, forKey: "DeskBarWeatherCache")
                    }
                }
            } catch {
                // Check cache if less than 24h old
                if let cachedData = UserDefaults.standard.data(forKey: "DeskBarWeatherCache"),
                   let cache = try? JSONDecoder().decode(CachedWeather.self, from: cachedData),
                   let lastUpdated = cache.lastUpdated,
                   Date().timeIntervalSince(lastUpdated) < 24 * 3600 {
                    
                    self?.conditions = WeatherConditions(
                        state: .available,
                        temperature: cache.temperature,
                        apparentTemperature: cache.apparentTemperature,
                        humidity: cache.humidity,
                        windSpeed: cache.windSpeed,
                        weatherCode: cache.weatherCode,
                        symbolName: cache.symbolName,
                        conditionText: cache.conditionText + " (Cached)",
                        locationName: cache.locationName,
                        lastUpdated: cache.lastUpdated,
                        highTemperature: cache.highTemperature,
                        lowTemperature: cache.lowTemperature,
                        hourlyForecast: cache.hourlyForecast.map { HourlyForecast(time: $0.time, temperature: $0.temperature, weatherCode: $0.weatherCode) }
                    )
                } else {
                    self?.conditions = WeatherConditions(state: .error("Weather unavailable"))
                }
            }
        }
    }

    private static func conditions(from response: OpenMeteoResponse, locationName: String) -> WeatherConditions {
        let current = response.current
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
            lastUpdated: Date(),
            highTemperature: response.daily?.temperatureMax.first,
            lowTemperature: response.daily?.temperatureMin.first,
            hourlyForecast: Self.parseHourly(response.hourly)
        )
    }

    
    static func icon(for weatherCode: Int) -> String {
        return description(for: weatherCode).symbol
    }

    private static func parseHourly(_ hourly: OpenMeteoHourly?) -> [HourlyForecast] {
        guard let hourly = hourly else { return [] }
        var result: [HourlyForecast] = []
        let now = Date().timeIntervalSince1970
        for i in 0..<min(hourly.time.count, hourly.temperature.count) {
            let t = hourly.time[i]
            if TimeInterval(t) > now - 3600 {
                let code = i < hourly.weatherCode.count ? hourly.weatherCode[i] : 0
                result.append(HourlyForecast(time: Date(timeIntervalSince1970: TimeInterval(t)), temperature: hourly.temperature[i], weatherCode: code))
                if result.count >= 6 { break }
            }
        }
        return result
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
    let hourly: OpenMeteoHourly?
    let daily: OpenMeteoDaily?
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

private struct OpenMeteoHourly: Decodable {
    let time: [Int]
    let temperature: [Double]
    let weatherCode: [Int]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperature = "temperature_2m"
        case weatherCode = "weather_code"
    }
}

private struct OpenMeteoDaily: Decodable {
    let time: [Int]
    let temperatureMax: [Double]
    let temperatureMin: [Double]
    
    enum CodingKeys: String, CodingKey {
        case time
        case temperatureMax = "temperature_2m_max"
        case temperatureMin = "temperature_2m_min"
    }
}
