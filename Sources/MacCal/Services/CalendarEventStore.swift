import EventKit
import Foundation
import SwiftUI

@MainActor
final class CalendarEventStore: ObservableObject {
    @Published private(set) var eventsByDate: [String: [CalendarEvent]] = [:]
    @Published private(set) var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)

    private let eventStore = EKEventStore()
    private var loadedRange: DateInterval?

    init() {
        NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged,
            object: eventStore,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                guard let self, let loadedRange = self.loadedRange else { return }
                self.fetchEvents(start: loadedRange.start, end: loadedRange.end)
            }
        }
    }

    func load(start: Date, end: Date, calendar: Calendar, enabled: Bool) {
        guard enabled else {
            eventsByDate = [:]
            return
        }

        authorizationStatus = EKEventStore.authorizationStatus(for: .event)

        if authorizationStatus == .fullAccess {
            fetchEvents(start: start, end: end)
        } else if authorizationStatus == .notDetermined {
            requestAccessThenFetch(start: start, end: end)
        } else {
            UserDefaults.standard.set("Calendar access is \(authorizationStatus.diagnosticText).", forKey: MacCalPreferences.lastCalendarEventErrorKey)
        }
    }

    func events(for date: Date, calendar: Calendar) -> [CalendarEvent] {
        eventsByDate[Self.dateKey(for: date, calendar: calendar)] ?? []
    }

    private func requestAccessThenFetch(start: Date, end: Date) {
        Task {
            do {
                let granted: Bool
                if #available(macOS 14.0, *) {
                    granted = try await eventStore.requestFullAccessToEvents()
                } else {
                    granted = try await withCheckedThrowingContinuation { continuation in
                        eventStore.requestAccess(to: .event) { granted, error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume(returning: granted)
                            }
                        }
                    }
                }

                authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                if granted {
                    fetchEvents(start: start, end: end)
                }
            } catch {
                UserDefaults.standard.set(error.localizedDescription, forKey: MacCalPreferences.lastCalendarEventErrorKey)
                NSLog("MacCal calendar access request failed: \(error.localizedDescription)")
            }
        }
    }

    private func fetchEvents(start: Date, end: Date) {
        loadedRange = DateInterval(start: start, end: end)

        let selectedIDs = MacCalPreferences.selectedCalendarIDs()
        let allCalendars = eventStore.calendars(for: .event)
        let calendars = selectedIDs.isEmpty
            ? allCalendars
            : allCalendars.filter { selectedIDs.contains($0.calendarIdentifier) }
        let predicate = eventStore.predicateForEvents(withStart: start, end: end, calendars: calendars)
        let events = eventStore.events(matching: predicate)
            .filter { !$0.isDetached }
            .sorted { $0.startDate < $1.startDate }
        UserDefaults.standard.set(Date().timeIntervalSinceReferenceDate, forKey: MacCalPreferences.lastCalendarEventRefreshKey)
        UserDefaults.standard.set("", forKey: MacCalPreferences.lastCalendarEventErrorKey)
        NSLog("MacCal loaded \(events.count) calendar events from \(calendars.count) calendars for visible range \(start) - \(end)")

        var next: [String: [CalendarEvent]] = [:]
        var calendar = Calendar.autoupdatingCurrent
        calendar.timeZone = .autoupdatingCurrent

        for event in events {
            for key in Self.dateKeysCovered(by: event, calendar: calendar) {
                let calendarEvent = CalendarEvent(
                    id: "\(event.eventIdentifier ?? UUID().uuidString)-\(key)",
                    dateKey: key,
                    title: event.title?.isEmpty == false ? event.title : "Untitled Event",
                    startDate: event.startDate,
                    endDate: event.endDate,
                    isAllDay: event.isAllDay,
                    calendarTitle: event.calendar.title,
                    calendarColor: Color(nsColor: event.calendar.color)
                )
                next[key, default: []].append(calendarEvent)
            }
        }

        for key in next.keys {
            next[key] = Self.deduplicated(next[key] ?? [], calendar: calendar)
        }

        eventsByDate = next
    }

    private static func deduplicated(_ events: [CalendarEvent], calendar: Calendar) -> [CalendarEvent] {
        var seen: Set<String> = []
        var result: [CalendarEvent] = []

        for event in events {
            let key = event.title.normalizedEventTitle

            if seen.insert(key).inserted {
                result.append(event)
            }
        }

        return result
    }

    private static func dateKeysCovered(by event: EKEvent, calendar: Calendar) -> [String] {
        guard let eventStart = event.startDate else { return [] }

        let start = calendar.startOfDay(for: eventStart)
        let eventEnd = event.endDate ?? eventStart
        let adjustedEnd = event.isAllDay
            ? calendar.date(byAdding: .second, value: -1, to: eventEnd) ?? eventEnd
            : eventEnd
        let end = calendar.startOfDay(for: adjustedEnd)

        guard start <= end else {
            return [dateKey(for: eventStart, calendar: calendar)]
        }

        var keys: [String] = []
        var current = start
        while current <= end {
            keys.append(dateKey(for: current, calendar: calendar))
            guard let next = calendar.date(byAdding: .day, value: 1, to: current) else { break }
            current = next
        }
        return keys
    }

    static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

private extension EKAuthorizationStatus {
    var diagnosticText: String {
        switch self {
        case .notDetermined:
            return "not determined"
        case .restricted:
            return "restricted"
        case .denied:
            return "denied"
        case .fullAccess:
            return "full access"
        case .writeOnly:
            return "write only"
        @unknown default:
            return "unknown"
        }
    }
}
