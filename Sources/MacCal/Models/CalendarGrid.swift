import Foundation

struct CalendarGridEntry: Identifiable, Hashable {
    let date: Date
    let weekdayColumn: Int
    let row: Int
    let isInVisibleMonth: Bool

    var id: Date { date }
}

enum CalendarGrid {
    static let visibleSlotCount = 42

    static func entries(for visibleMonth: Date, calendar: Calendar) -> [CalendarGridEntry] {
        let monthStart = calendar.startOfMonth(for: visibleMonth)
        let firstWeekdayOffset = normalizedWeekdayOffset(for: monthStart, calendar: calendar)
        let gridStart = calendar.date(byAdding: .day, value: -firstWeekdayOffset, to: monthStart) ?? monthStart

        return (0..<visibleSlotCount).compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: offset, to: gridStart) else { return nil }
            return CalendarGridEntry(
                date: date,
                weekdayColumn: offset % 7,
                row: offset / 7,
                isInVisibleMonth: calendar.isDate(date, equalTo: monthStart, toGranularity: .month)
            )
        }
    }

    static func visibleRange(for entries: [CalendarGridEntry], calendar: Calendar) -> DateInterval? {
        guard let first = entries.first?.date,
              let last = entries.last?.date,
              let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) else {
            return nil
        }

        return DateInterval(start: calendar.startOfDay(for: first), end: end)
    }

    static func normalizedWeekdayOffset(for date: Date, calendar: Calendar) -> Int {
        let weekday = calendar.component(.weekday, from: date)
        return (weekday - calendar.firstWeekday + 7) % 7
    }
}

extension Calendar {
    func startOfMonth(for date: Date) -> Date {
        let components = dateComponents([.year, .month], from: date)
        return self.date(from: components) ?? startOfDay(for: date)
    }
}
