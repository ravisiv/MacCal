import XCTest
@testable import MacCal

final class CalendarGridTests: XCTestCase {
    func testGridAlwaysContainsSixWeeks() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let month = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 2, day: 1)))

        let entries = CalendarGrid.entries(for: month, calendar: calendar)

        XCTAssertEqual(entries.count, 42)
        XCTAssertEqual(entries.first?.weekdayColumn, 0)
        XCTAssertEqual(entries.last?.weekdayColumn, 6)
        XCTAssertEqual(entries.last?.row, 5)
    }

    func testGridRespectsMondayFirstWeekday() throws {
        let calendar = gregorianCalendar(firstWeekday: 2)
        let month = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 5, day: 1)))

        let entries = CalendarGrid.entries(for: month, calendar: calendar)
        let first = try XCTUnwrap(entries.first?.date)

        XCTAssertEqual(calendar.component(.month, from: first), 4)
        XCTAssertEqual(calendar.component(.day, from: first), 27)
    }

    func testVisibleRangeCoversTheDisplayedGrid() throws {
        let calendar = gregorianCalendar(firstWeekday: 1)
        let month = try XCTUnwrap(calendar.date(from: DateComponents(year: 2026, month: 6, day: 1)))
        let entries = CalendarGrid.entries(for: month, calendar: calendar)

        let range = try XCTUnwrap(CalendarGrid.visibleRange(for: entries, calendar: calendar))

        XCTAssertEqual(dateKey(for: range.start, calendar: calendar), "2026-05-31")
        XCTAssertEqual(dateKey(for: range.end, calendar: calendar), "2026-07-12")
    }

    private func gregorianCalendar(firstWeekday: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}
