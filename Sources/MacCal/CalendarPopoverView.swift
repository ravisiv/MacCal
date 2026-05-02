import SwiftUI

struct CalendarPopoverView: View {
    @Environment(\.colorScheme) private var colorScheme

    @AppStorage(MacCalPreferences.showUSHolidaysKey) private var showUSHolidays = true
    @AppStorage(MacCalPreferences.showIndiaHolidaysKey) private var showIndiaHolidays = true
    @AppStorage(MacCalPreferences.showCalendarEventsKey) private var showCalendarEvents = false
    @AppStorage(MacCalPreferences.calendarSelectionVersionKey) private var calendarSelectionVersion = 0

    @StateObject private var holidayStore = HolidayStore()
    @StateObject private var calendarEventStore = CalendarEventStore()
    @State private var visibleMonth: Date = Calendar.autoupdatingCurrent.startOfMonth(for: Date())
    @State private var selectedDate: Date?
    @State private var hoveredDayID: String?
    @State private var pickerMode: PickerMode = .days

    private let weekdayColumns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    private let monthColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 3)
    private let yearColumns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)
    private let maxVisibleEvents = 5

    var body: some View {
        ZStack {
            VStack(spacing: 14) {
                header

                if pickerMode == .years {
                    yearGrid
                } else if pickerMode == .months {
                    monthPicker
                } else {
                    monthGrid
                }
            }
            .padding(.horizontal, 48)
            .frame(height: 326, alignment: .top)

            HStack {
                sideNavigationButton(systemName: "chevron.left", help: pickerMode == .years ? "Previous decade" : "Previous month") {
                    moveBackward()
                }

                Spacer()

                sideNavigationButton(systemName: "chevron.right", help: pickerMode == .years ? "Next decade" : "Next month") {
                    moveForward()
                }
            }
            .padding(.horizontal, 14)
            .offset(y: 28)
        }
        .padding(.vertical, 16)
        .frame(width: 390, height: 360)
        .background(Color(nsColor: .windowBackgroundColor))
        .task(id: visibleYear) {
            holidayStore.load(year: visibleYear)
        }
        .task(id: calendarEventRefreshKey) {
            loadCalendarEventsIfNeeded()
        }
        .onExitCommand {
            pickerMode = .days
        }
        .focusable()
        .focusEffectDisabled()
        .onKeyPress("t") {
            goToToday()
            return .handled
        }
        .onKeyPress(keys: [.leftArrow, .rightArrow]) { press in
            if press.key == .leftArrow, press.modifiers.contains(.command) {
                moveVisibleYear(by: -1)
            } else if press.key == .rightArrow, press.modifiers.contains(.command) {
                moveVisibleYear(by: 1)
            } else if press.key == .leftArrow {
                moveVisibleMonth(by: -1)
            } else if press.key == .rightArrow {
                moveVisibleMonth(by: 1)
            }
            return .handled
        }
        .onKeyPress(.upArrow) {
            moveSelection(by: -7)
            return .handled
        }
        .onKeyPress(.downArrow) {
            moveSelection(by: 7)
            return .handled
        }
    }

    private var header: some View {
        ZStack {
            Button {
                advancePickerMode()
            } label: {
                Text(headerTitle)
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .buttonStyle(.plain)
            .help(headerHelp)

            HStack {
                Spacer()
                Button("Today") {
                    goToToday()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .help("Go to today")
            }
        }
        .frame(height: 36)
    }

    private var monthGrid: some View {
        VStack(spacing: 8) {
            LazyVGrid(columns: weekdayColumns, spacing: 0) {
                ForEach(weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.secondary)
                        .frame(height: 22)
                }
            }

            LazyVGrid(columns: weekdayColumns, spacing: 8) {
                ForEach(calendarDays) { day in
                    Button {
                        selectedDate = day.date
                    } label: {
                        dayCell(day)
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                    .onHover { isHovering in
                        hoveredDayID = isHovering && day.hasDetails ? day.id.description : nil
                    }
                    .contextMenu {
                        Button("Copy Date") {
                            copyDate(day.date)
                        }
                    }
                    .accessibilityLabel(accessibilityLabel(for: day))
                }
            }

        }
        .frame(height: 276, alignment: .top)
    }

    private func dayCell(_ day: CalendarDay) -> some View {
        ZStack(alignment: .top) {
            Text("\(calendar.component(.day, from: day.date))")
                .font(.system(size: 15, weight: day.isToday ? .bold : .regular, design: .rounded))
                .foregroundStyle(textColor(for: day))
                .frame(width: 38, height: 34)
                .background(background(for: day))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay {
                    if day.isToday && !day.isSelected {
                        RoundedRectangle(cornerRadius: 9, style: .continuous)
                            .stroke(Color.accentColor, lineWidth: 1.5)
                    }
                }
                .overlay(alignment: .bottom) {
                    if day.hasMarkers {
                        dayMarkers(for: day)
                            .padding(.bottom, 3)
                    }
                }

            if hoveredDayID == day.id.description, day.hasDetails {
                detailCard(for: day)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    }
                    .offset(x: hoverCardXOffset(for: day), y: -38)
                    .offset(y: hoverCardYOffset(for: day))
                    .zIndex(10)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: 38, height: 34)
    }

    private func detailCard(for day: CalendarDay) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            if !day.events.isEmpty {
                ForEach(deduplicatedEvents(for: day).prefix(maxVisibleEvents)) { event in
                    Text(event.displayText(calendar: calendar))
                        .lineLimit(1)
                }

                if deduplicatedEvents(for: day).count > maxVisibleEvents {
                    Text("+\(deduplicatedEvents(for: day).count - maxVisibleEvents) more")
                        .foregroundStyle(.secondary)
                }
            }

            if !day.events.isEmpty, !day.holidays.isEmpty {
                Divider()
            }

            if !day.holidays.isEmpty {
                Text(day.holidays.displayText)
                    .lineLimit(2)
            }
        }
        .font(.system(size: 11, weight: .medium))
        .foregroundStyle(.primary)
        .multilineTextAlignment(.leading)
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(width: 190, alignment: .leading)
    }

    private func hoverCardXOffset(for day: CalendarDay) -> CGFloat {
        switch day.weekdayColumn {
        case 0:
            return 112
        case 1:
            return 66
        case 5:
            return -66
        case 6:
            return -112
        default:
            return 0
        }
    }

    private func hoverCardYOffset(for day: CalendarDay) -> CGFloat {
        day.row == 0 ? 58 : 0
    }

    private func deduplicatedEvents(for day: CalendarDay) -> [CalendarEvent] {
        var seen: Set<String> = []
        return day.events.filter { event in
            seen.insert(event.title.normalizedEventTitle).inserted
        }
    }

    private var monthPicker: some View {
        LazyVGrid(columns: monthColumns, spacing: 10) {
            ForEach(1...12, id: \.self) { month in
                Button {
                    visibleMonth = calendar.date(from: DateComponents(year: visibleYear, month: month, day: 1)) ?? visibleMonth
                    pickerMode = .days
                } label: {
                    Text(monthSymbol(for: month))
                        .font(.system(size: 14, weight: month == visibleMonthNumber ? .bold : .medium, design: .rounded))
                        .foregroundStyle(month == visibleMonthNumber ? Color.white : Color.primary)
                        .frame(height: 42)
                        .frame(maxWidth: .infinity)
                        .background {
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(month == visibleMonthNumber ? Color.accentColor : Color.secondary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .frame(height: 276, alignment: .top)
    }

    private var yearGrid: some View {
        VStack(spacing: 16) {
            LazyVGrid(columns: yearColumns, spacing: 12) {
                ForEach(decadeYears, id: \.self) { year in
                    Button {
                        visibleMonth = calendar.date(from: DateComponents(year: year, month: calendar.component(.month, from: visibleMonth), day: 1)) ?? visibleMonth
                        pickerMode = .days
                    } label: {
                        Text(String(year))
                            .font(.system(size: 15, weight: year == currentYear ? .bold : .medium, design: .rounded))
                            .foregroundStyle(year == visibleYear ? Color.white : Color.primary)
                            .frame(height: 44)
                            .frame(maxWidth: .infinity)
                            .background {
                                RoundedRectangle(cornerRadius: 9, style: .continuous)
                                    .fill(year == visibleYear ? Color.accentColor : Color.secondary.opacity(colorScheme == .dark ? 0.18 : 0.10))
                            }
                            .overlay {
                                if year == currentYear && year != visibleYear {
                                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                                        .stroke(Color.accentColor, lineWidth: 1.5)
                                }
                            }
                    }
                    .buttonStyle(.plain)
                    .contentShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                }
            }
        }
        .frame(height: 276, alignment: .top)
    }

    private func sideNavigationButton(systemName: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(.primary)
                .frame(width: 44, height: 112)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func dayMarkers(for day: CalendarDay) -> some View {
        HStack(spacing: 3) {
            ForEach(Holiday.Region.allCases, id: \.rawValue) { region in
                if day.holidays.contains(where: { $0.region == region }) {
                    Circle()
                        .fill(region.markerColor)
                        .frame(width: 5, height: 5)
                }
            }

            if !day.events.isEmpty {
                ForEach(Array(day.eventMarkerColors.prefix(3).enumerated()), id: \.offset) { _, color in
                    Circle()
                        .fill(color)
                        .frame(width: 5, height: 5)
                }
            }
        }
    }

    private func filteredHolidays(for date: Date) -> [Holiday] {
        holidayStore.holidays(for: date, calendar: calendar).filter { holiday in
            switch holiday.region {
            case .unitedStates:
                return showUSHolidays
            case .india:
                return showIndiaHolidays
            }
        }
    }

    private func events(for date: Date) -> [CalendarEvent] {
        guard showCalendarEvents else { return [] }
        return calendarEventStore.events(for: date, calendar: calendar)
    }

    private var calendarEventRefreshKey: String {
        "\(visibleMonth.timeIntervalSinceReferenceDate)-\(showCalendarEvents)-\(calendarSelectionVersion)"
    }

    private func loadCalendarEventsIfNeeded() {
        guard showCalendarEvents, let range = visibleGridRange else { return }
        calendarEventStore.load(start: range.start, end: range.end, calendar: calendar, enabled: showCalendarEvents)
    }

    private var visibleGridRange: DateInterval? {
        CalendarGrid.visibleRange(for: gridEntries, calendar: calendar)
    }

    private var calendar: Calendar {
        Calendar.autoupdatingCurrent
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "MMMM y", options: 0, locale: .autoupdatingCurrent)
        return formatter.string(from: visibleMonth)
    }

    private var headerTitle: String {
        switch pickerMode {
        case .days:
            return monthTitle
        case .months:
            return String(visibleYear)
        case .years:
            return decadeTitle
        }
    }

    private var headerHelp: String {
        switch pickerMode {
        case .days:
            return "Select month"
        case .months:
            return "Select year"
        case .years:
            return "Show month"
        }
    }

    private var weekdaySymbols: [String] {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        let symbols = formatter.veryShortStandaloneWeekdaySymbols ?? formatter.veryShortWeekdaySymbols ?? []
        guard symbols.count == 7 else { return [] }

        let firstIndex = max(calendar.firstWeekday - 1, 0)
        return Array(symbols[firstIndex...] + symbols[..<firstIndex])
    }

    private var calendarDays: [CalendarDay] {
        gridEntries.map { entry in
            return CalendarDay(
                date: entry.date,
                weekdayColumn: entry.weekdayColumn,
                row: entry.row,
                isInVisibleMonth: entry.isInVisibleMonth,
                isToday: calendar.isDateInToday(entry.date),
                isSelected: selectedDate.map { calendar.isDate(entry.date, inSameDayAs: $0) } ?? false,
                holidays: filteredHolidays(for: entry.date),
                events: events(for: entry.date)
            )
        }
    }

    private var gridEntries: [CalendarGridEntry] {
        CalendarGrid.entries(for: visibleMonth, calendar: calendar)
    }

    private var visibleYear: Int {
        calendar.component(.year, from: visibleMonth)
    }

    private var visibleMonthNumber: Int {
        calendar.component(.month, from: visibleMonth)
    }

    private var currentYear: Int {
        calendar.component(.year, from: Date())
    }

    private var decadeStart: Int {
        (visibleYear / 10) * 10
    }

    private var decadeTitle: String {
        "\(decadeStart)-\(decadeStart + 9)"
    }

    private var decadeYears: [Int] {
        Array(decadeStart...(decadeStart + 9))
    }

    private func moveBackward() {
        if pickerMode == .years {
            visibleMonth = calendar.date(byAdding: .year, value: -10, to: visibleMonth) ?? visibleMonth
        } else if pickerMode == .months {
            visibleMonth = calendar.date(byAdding: .year, value: -1, to: visibleMonth) ?? visibleMonth
        } else {
            moveVisibleMonth(by: -1)
        }
    }

    private func moveForward() {
        if pickerMode == .years {
            visibleMonth = calendar.date(byAdding: .year, value: 10, to: visibleMonth) ?? visibleMonth
        } else if pickerMode == .months {
            visibleMonth = calendar.date(byAdding: .year, value: 1, to: visibleMonth) ?? visibleMonth
        } else {
            moveVisibleMonth(by: 1)
        }
    }

    private func goToToday() {
        let today = Date()
        visibleMonth = calendar.startOfMonth(for: today)
        selectedDate = today
        hoveredDayID = nil
        pickerMode = .days
    }

    private func moveSelection(by days: Int) {
        let baseDate = selectedDate ?? Date()
        guard let nextDate = calendar.date(byAdding: .day, value: days, to: baseDate) else { return }
        selectedDate = nextDate
        visibleMonth = calendar.startOfMonth(for: nextDate)
        pickerMode = .days
    }

    private func moveVisibleMonth(by months: Int) {
        visibleMonth = calendar.date(byAdding: .month, value: months, to: visibleMonth) ?? visibleMonth
        pickerMode = .days
    }

    private func moveVisibleYear(by years: Int) {
        visibleMonth = calendar.date(byAdding: .year, value: years, to: visibleMonth) ?? visibleMonth
        pickerMode = .days
    }

    private func advancePickerMode() {
        switch pickerMode {
        case .days:
            pickerMode = .months
        case .months:
            pickerMode = .years
        case .years:
            pickerMode = .days
        }
    }

    private func monthSymbol(for month: Int) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        return formatter.shortStandaloneMonthSymbols[safe: month - 1] ?? "\(month)"
    }

    private func copyDate(_ date: Date) {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(formatter.string(from: date), forType: .string)
    }

    private func textColor(for day: CalendarDay) -> Color {
        if day.isSelected {
            return .white
        }

        if !day.isInVisibleMonth {
            return .secondary.opacity(0.55)
        }

        return .primary
    }

    @ViewBuilder
    private func background(for day: CalendarDay) -> some View {
        if day.isSelected {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.accentColor)
        } else if day.isToday {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.accentColor.opacity(colorScheme == .dark ? 0.22 : 0.12))
        } else if !day.holidays.isEmpty {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.yellow.opacity(colorScheme == .dark ? 0.15 : 0.20))
        } else if !day.events.isEmpty {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.blue.opacity(colorScheme == .dark ? 0.13 : 0.10))
        } else {
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.clear)
        }
    }

    private func accessibilityLabel(for day: CalendarDay) -> String {
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.dateStyle = .full
        formatter.timeStyle = .none

        var parts = [formatter.string(from: day.date)]
        if day.isToday {
            parts.append("today")
        }
        if day.isSelected {
            parts.append("selected")
        }
        if !day.holidays.isEmpty {
            parts.append(day.holidays.displayText)
        }
        if !day.events.isEmpty {
            let eventCount = deduplicatedEvents(for: day).count
            parts.append(eventCount == 1 ? "1 event" : "\(eventCount) events")
        }
        return parts.joined(separator: ", ")
    }
}

private enum PickerMode {
    case days
    case months
    case years
}

private struct CalendarDay: Identifiable {
    let date: Date
    let weekdayColumn: Int
    let row: Int
    let isInVisibleMonth: Bool
    let isToday: Bool
    let isSelected: Bool
    let holidays: [Holiday]
    let events: [CalendarEvent]

    var id: Date { date }

    var hasDetails: Bool {
        !holidays.isEmpty || !events.isEmpty
    }

    var hasMarkers: Bool {
        hasDetails
    }

    var eventMarkerColors: [Color] {
        var seen: Set<String> = []
        return events.compactMap { event -> Color? in
            if seen.insert(event.calendarTitle).inserted {
                return event.calendarColor
            }
            return nil
        }
    }
}

private extension Array {
    subscript(safe index: Index) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
