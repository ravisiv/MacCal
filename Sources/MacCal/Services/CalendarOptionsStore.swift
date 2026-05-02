import EventKit
import SwiftUI

@MainActor
final class CalendarOptionsStore: ObservableObject {
    @Published private(set) var calendars: [CalendarInfo] = []
    @Published private(set) var calendarGroups: [CalendarGroupInfo] = []
    @Published private(set) var authorizationStatus: EKAuthorizationStatus = EKEventStore.authorizationStatus(for: .event)
    @Published var selectedIDs: Set<String> = MacCalPreferences.selectedCalendarIDs()

    private let eventStore = EKEventStore()

    func refresh() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        guard authorizationStatus == .fullAccess else {
            calendars = []
            calendarGroups = []
            return
        }

        calendars = eventStore.calendars(for: .event)
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            .map { calendar in
                CalendarInfo(
                    id: calendar.calendarIdentifier,
                    title: calendar.title,
                    color: Color(nsColor: calendar.color)
                )
            }
        calendarGroups = Self.groupedCalendars(calendars)

        if selectedIDs.isEmpty {
            selectedIDs = Set(calendars.map(\.id))
            MacCalPreferences.setSelectedCalendarIDs(selectedIDs)
        }
    }

    func requestAccess() {
        Task {
            do {
                if #available(macOS 14.0, *) {
                    _ = try await eventStore.requestFullAccessToEvents()
                }
            } catch {
                NSLog("MacCal calendar access request failed from Options: \(error.localizedDescription)")
            }

            refresh()
        }
    }

    func setSelected(_ isSelected: Bool, calendarID: String) {
        if isSelected {
            selectedIDs.insert(calendarID)
        } else {
            selectedIDs.remove(calendarID)
        }
        MacCalPreferences.setSelectedCalendarIDs(selectedIDs)
    }

    func isGroupSelected(_ group: CalendarGroupInfo) -> Bool {
        group.calendarIDs.allSatisfy { selectedIDs.contains($0) }
    }

    func setSelected(_ isSelected: Bool, group: CalendarGroupInfo) {
        if isSelected {
            selectedIDs.formUnion(group.calendarIDs)
        } else {
            selectedIDs.subtract(group.calendarIDs)
        }
        MacCalPreferences.setSelectedCalendarIDs(selectedIDs)
    }

    private static func groupedCalendars(_ calendars: [CalendarInfo]) -> [CalendarGroupInfo] {
        let grouped = Dictionary(grouping: calendars) { $0.title.normalizedCalendarTitle }

        return grouped.values.map { calendars in
            let sorted = calendars.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
            return CalendarGroupInfo(
                id: sorted.map(\.id).joined(separator: "|"),
                title: sorted.first?.title ?? "Untitled",
                calendarIDs: sorted.map(\.id),
                colors: sorted.map(\.color)
            )
        }
        .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }
}

private extension String {
    var normalizedCalendarTitle: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }
}
