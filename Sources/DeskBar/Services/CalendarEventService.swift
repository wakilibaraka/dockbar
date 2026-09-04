import Foundation
import EventKit
import Combine

final class CalendarEventService: ObservableObject {
    @Published var upcomingEvents: [EKEvent] = []
    @Published var permissionDenied: Bool = false
    
    private let store = EKEventStore()
    private var refreshTimer: Timer?
    private var notificationObserver: NSObjectProtocol?
    
    init() {
        requestAccessAndFetch()
    }
    
    deinit {
        refreshTimer?.invalidate()
        if let obs = notificationObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }
    
    private func requestAccessAndFetch() {
        let status = EKEventStore.authorizationStatus(for: .event)
        switch status {
        case .authorized, .fullAccess:
            scheduleRefreshAndFetch()
        case .denied, .restricted:
            DispatchQueue.main.async { self.permissionDenied = true }
        case .notDetermined:
            if #available(macOS 14.0, *) {
                store.requestFullAccessToEvents { [weak self] granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            self?.scheduleRefreshAndFetch()
                        } else {
                            self?.permissionDenied = true
                        }
                    }
                }
            } else {
                store.requestAccess(to: .event) { [weak self] granted, _ in
                    DispatchQueue.main.async {
                        if granted {
                            self?.scheduleRefreshAndFetch()
                        } else {
                            self?.permissionDenied = true
                        }
                    }
                }
            }
        @unknown default:
            DispatchQueue.main.async { self.permissionDenied = true }
        }
    }
    
    private func scheduleRefreshAndFetch() {
        fetch()
        // Refresh every 5 minutes
        refreshTimer = Timer(timeInterval: 5 * 60, repeats: true) { [weak self] _ in
            self?.fetch()
        }
        refreshTimer.map { RunLoop.main.add($0, forMode: .common) }
        // Also refresh on store changes
        notificationObserver = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: store,
            queue: .main
        ) { [weak self] _ in
            self?.fetch()
        }
    }
    
    func fetch() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            guard let self else { return }
            let now = Date()
            let sevenDaysLater = Calendar.current.date(byAdding: .day, value: 7, to: now) ?? now.addingTimeInterval(7 * 24 * 3600)
            let predicate = self.store.predicateForEvents(withStart: now, end: sevenDaysLater, calendars: nil)
            let events = self.store.events(matching: predicate)
                .filter { !$0.isAllDay }
                .sorted { $0.startDate < $1.startDate }
            DispatchQueue.main.async {
                self.upcomingEvents = events
                self.permissionDenied = false
            }
        }
    }
}
