import SwiftUI
import AppKit

final class CalendarState: ObservableObject {
    @Published var currentDate = Date()
    @Published var selectedDay = Date()
    @Published var hoveredDay: Date? = nil
}

struct CalendarView: View {
    @ObservedObject var state = CalendarState()
    @ObservedObject var eventService = CalendarEventService.shared
    
    private let calendar = Calendar.current
    private let daysInWeek = 7
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text(dateFormatter.string(from: state.currentDate))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.primary)
                Spacer()
                HStack(spacing: 12) {
                    Button {
                        changeMonth(by: -1)
                    } label: {
                        Image(systemName: "chevron.up")
                    }
                    .buttonStyle(.plain)
                    
                    Button {
                        changeMonth(by: 1)
                    } label: {
                        Image(systemName: "chevron.down")
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 4)
            
            // Days of week
            HStack(spacing: 0) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { symbol in
                    Text(symbol.prefix(2))
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            
            // Grid
            let days = daysInMonth()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 0), count: 7)
            
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(0..<days.count, id: \.self) { index in
                    if let date = days[index] {
                        let dayEvents = eventService.events.filter { calendar.isDate($0.startDate, inSameDayAs: date) }
                        DayCell(date: date, isToday: calendar.isDateInToday(date), state: state, events: dayEvents)
                    } else {
                        Color.clear
                            .frame(height: 32)
                    }
                }
            }
            
            Divider()
                .padding(.top, 4)
            
            let selectedEvents = eventService.events.filter { calendar.isDate($0.startDate, inSameDayAs: state.selectedDay) }
            
            HStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        if selectedEvents.isEmpty {
                            HStack {
                                Image(systemName: "calendar.badge.clock")
                                    .foregroundStyle(.secondary)
                                Text("No events")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            ForEach(selectedEvents) { ev in
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(ev.color)
                                        .frame(width: 6, height: 6)
                                    Text(ev.title)
                                        .font(.system(size: 11))
                                        .lineLimit(1)
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
        .padding(20)
        // Colourful Windows-like background using a gradient overlay
        .background {
            LinearGradient(
                colors: [Color.accentColor.opacity(0.15), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .frame(width: 320)
    }
    
    private func changeMonth(by value: Int) {
        if let newDate = calendar.date(byAdding: .month, value: value, to: state.currentDate) {
            state.currentDate = newDate
        }
    }
    
    private func daysInMonth() -> [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: state.currentDate) else { return [] }
        let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start)
        
        var dates: [Date?] = []
        
        // Add leading empty spaces
        if let firstWeek = monthFirstWeek {
            let offset = calendar.dateComponents([.day], from: firstWeek.start, to: monthInterval.start).day ?? 0
            for _ in 0..<offset {
                dates.append(nil)
            }
        }
        
        // Add days of the month
        let days = calendar.range(of: .day, in: .month, for: state.currentDate)!.count
        for i in 0..<days {
            if let date = calendar.date(byAdding: .day, value: i, to: monthInterval.start) {
                dates.append(date)
            }
        }
        
        return dates
    }
}

struct DayCell: View {
    let date: Date
    let isToday: Bool
    @ObservedObject var state: CalendarState
    let events: [CalendarEvent]
    
    var body: some View {
        let dayNumber = Calendar.current.component(.day, from: date)
        let isHovered = state.hoveredDay == date
        let isSelected = Calendar.current.isDate(state.selectedDay, inSameDayAs: date)
        
        VStack(spacing: 2) {
            Text("\(dayNumber)")
                .font(.system(size: 13, weight: (isToday || isSelected) ? .bold : .regular))
                .foregroundStyle((isToday || isSelected) ? Color.white : Color.primary)
                .frame(width: 28, height: 28)
                .background {
                    if isToday {
                        Circle().fill(Color.accentColor)
                    } else if isSelected {
                        Circle().fill(Color.primary.opacity(0.6))
                    } else if isHovered {
                        Circle().fill(Color.secondary.opacity(0.2))
                    }
                }
            
            HStack(spacing: 2) {
                ForEach(events.prefix(3)) { ev in
                    Circle()
                        .fill(ev.color)
                        .frame(width: 3, height: 3)
                }
            }
            .frame(height: 3)
        }
        .frame(width: 36, height: 36)
        .contentShape(Rectangle())
        .onTapGesture {
            state.selectedDay = date
        }
        .onHover { hovering in
            if hovering {
                state.hoveredDay = date
            } else if state.hoveredDay == date {
                state.hoveredDay = nil
            }
        }
    }
}
