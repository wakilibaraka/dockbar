import AppKit
import Combine
import CoreLocation

// MARK: - Weather Service
struct WeatherResponse: Codable {
    let current_weather: CurrentWeather?
}
struct CurrentWeather: Codable {
    let temperature: Double
    let windspeed: Double
    let weathercode: Int
}

final class WeatherService: ObservableObject {
    @Published var temperature: String = "--°"
    @Published var condition: String = "Unknown"
    
    func fetchWeather(for city: String) {
        let trimmed = city.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        
        let geocodeURLString = "https://geocoding-api.open-meteo.com/v1/search?name=\(trimmed.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&count=1&format=json"
        
        guard let url = URL(string: geocodeURLString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            struct GeoResponse: Codable {
                struct Result: Codable { let latitude: Double; let longitude: Double; let name: String }
                let results: [Result]?
            }
            if let geo = try? JSONDecoder().decode(GeoResponse.self, from: data), let first = geo.results?.first {
                self?.fetchWeatherForCoords(lat: first.latitude, lon: first.longitude)
            }
        }.resume()
    }
    
    private func fetchWeatherForCoords(lat: Double, lon: Double) {
        let urlString = "https://api.open-meteo.com/v1/forecast?latitude=\(lat)&longitude=\(lon)&current_weather=true"
        guard let url = URL(string: urlString) else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, _, _ in
            guard let data = data else { return }
            if let response = try? JSONDecoder().decode(WeatherResponse.self, from: data), let current = response.current_weather {
                DispatchQueue.main.async {
                    self?.temperature = "\(Int(current.temperature))°"
                    self?.condition = "Code \(current.weathercode)"
                }
            }
        }.resume()
    }
}

// MARK: - Sticky Notes Service
struct StickyNote: Codable, Identifiable {
    var id: UUID
    var text: String
}

final class StickyNotesService: ObservableObject {
    @Published var notes: [StickyNote] = []
    
    private let fileURL: URL
    
    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("DeskBar")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        fileURL = dir.appendingPathComponent("stickynotes.json")
        load()
        if notes.isEmpty {
            notes.append(StickyNote(id: UUID(), text: "Welcome to DeskBar!"))
        }
    }
    
    func save() {
        if let data = try? JSONEncoder().encode(notes) {
            try? data.write(to: fileURL)
        }
    }
    
    private func load() {
        if let data = try? Data(contentsOf: fileURL),
           let saved = try? JSONDecoder().decode([StickyNote].self, from: data) {
            self.notes = saved
        }
    }
}

// MARK: - View
final class DashboardLeftWidgetsView: NSView, NSTextViewDelegate {
    private let weatherService = WeatherService()
    private let stickyService = StickyNotesService()
    private let calendarService = CalendarEventService()
    
    private let weatherLabel = NSTextField(labelWithString: "Weather: --")
    private let calendarLabel = NSTextField(labelWithString: "Next Event: None")
    private let noteTextView = NSTextView()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        super.init(frame: .zero)
        setupUI()
        
        weatherService.$temperature
            .combineLatest(weatherService.$condition)
            .receive(on: RunLoop.main)
            .sink { [weak self] temp, cond in
                self?.weatherLabel.stringValue = "\(temp) - \(cond)"
            }
            .store(in: &cancellables)
            
        calendarService.$upcomingEvents
            .receive(on: RunLoop.main)
            .sink { [weak self] events in
                if let first = events.first {
                    self?.calendarLabel.stringValue = "Next: \(first.title)"
                } else {
                    self?.calendarLabel.stringValue = "Next: None"
                }
            }
            .store(in: &cancellables)
            
        weatherService.fetchWeather(for: UserDefaults.standard.string(forKey: "weatherLocation") ?? "San Francisco")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.distribution = .fill
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)
        
        weatherLabel.translatesAutoresizingMaskIntoConstraints = false
        weatherLabel.font = .systemFont(ofSize: 13)
        stack.addArrangedSubview(weatherLabel)
        
        calendarLabel.translatesAutoresizingMaskIntoConstraints = false
        calendarLabel.font = .systemFont(ofSize: 13)
        stack.addArrangedSubview(calendarLabel)
        
        let noteScroll = NSScrollView()
        noteScroll.translatesAutoresizingMaskIntoConstraints = false
        noteScroll.hasVerticalScroller = true
        
        noteTextView.delegate = self
        noteTextView.string = stickyService.notes.first?.text ?? ""
        noteTextView.font = .systemFont(ofSize: 13)
        noteTextView.backgroundColor = .controlBackgroundColor
        noteTextView.isRichText = false
        
        noteScroll.documentView = noteTextView
        stack.addArrangedSubview(noteScroll)
        
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            noteScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 100),
            noteScroll.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }
    
    func textDidChange(_ notification: Notification) {
        if !stickyService.notes.isEmpty {
            stickyService.notes[0].text = noteTextView.string
            stickyService.save()
        }
    }
}
