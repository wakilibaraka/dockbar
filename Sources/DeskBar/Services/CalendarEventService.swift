import Foundation
import EventKit
import Combine
import SwiftUI

struct CalendarEvent: Identifiable {
    let id = UUID()
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let color: Color
}

final class CalendarEventService: ObservableObject {
    static let shared = CalendarEventService()
    
    private let store = EKEventStore()
    @Published var events: [CalendarEvent] = []
    @Published var isAuthorized = false
    
    init() {
        checkPermission()
    }
    
    func checkPermission() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if status == .fullAccess || status == .authorized {
            isAuthorized = true
            fetchEvents()
        } else if status == .notDetermined {
            store.requestFullAccessToEvents { [weak self] granted, _ in
                DispatchQueue.main.async {
                    self?.isAuthorized = granted
                    if granted {
                        self?.fetchEvents()
                    }
                }
            }
        }
    }
    
    func fetchEvents() {
        guard isAuthorized else { return }
        let now = Date()
        let thirtyDaysLater = Calendar.current.date(byAdding: .day, value: 30, to: now)!
        
        let predicate = store.predicateForEvents(withStart: now, end: thirtyDaysLater, calendars: nil)
        let ekEvents = store.events(matching: predicate)
        
        var mappedEvents = ekEvents.map { ev -> CalendarEvent in
            let nsColor = ev.calendar.color ?? NSColor.systemBlue
            return CalendarEvent(
                title: ev.title,
                startDate: ev.startDate,
                endDate: ev.endDate,
                isAllDay: ev.isAllDay,
                color: Color(nsColor)
            )
        }
        
        // Add hardcoded holidays
        mappedEvents.append(contentsOf: generateHolidays(start: now, end: thirtyDaysLater))
        
        mappedEvents.sort { $0.startDate < $1.startDate }
        
        DispatchQueue.main.async {
            self.events = mappedEvents
        }
    }
    
    private func generateHolidays(start: Date, end: Date) -> [CalendarEvent] {
        var holidays: [CalendarEvent] = []
        let currentYear = Calendar.current.component(.year, from: start)
        
        // Simplified hardcoded holidays for demonstration (Italy, Kenya, US, Christian, Muslim)
        let holidayDates: [(month: Int, day: Int, title: String, color: Color)] = [
            (1, 1, "New Year's Day (US, IT, KE)", .blue),
            (6, 1, "Madaraka Day (KE)", .green),
            (6, 2, "Republic Day (IT)", .green),
            (7, 4, "Independence Day (US)", .red),
            (10, 20, "Mashujaa Day (KE)", .orange),
            (12, 12, "Jamhuri Day (KE)", .purple),
            (12, 25, "Christmas (Christian)", .red),
            (12, 26, "St. Stephen's Day (IT)", .orange),
            // Note: Muslim holidays (Eid al-Fitr, Eid al-Adha) shift by ~11 days each year. 
            // 2026 approx: Eid al-Fitr (~Mar 20), Eid al-Adha (~May 27)
            (3, 20, "Eid al-Fitr (Muslim)", .teal),
            (5, 27, "Eid al-Adha (Muslim)", .teal)
        ]
        
        for h in holidayDates {
            var comps = DateComponents(year: currentYear, month: h.month, day: h.day)
            if let date = Calendar.current.date(from: comps), date >= start && date <= end {
                holidays.append(CalendarEvent(title: h.title, startDate: date, endDate: date, isAllDay: true, color: h.color))
            }
            
            // Check next year if window spans new year
            comps.year = currentYear + 1
            if let date = Calendar.current.date(from: comps), date >= start && date <= end {
                holidays.append(CalendarEvent(title: h.title, startDate: date, endDate: date, isAllDay: true, color: h.color))
            }
        }
        
        return holidays
    }
}
