import Foundation
import SwiftUI

struct CalendarEvent: Identifiable, Hashable {
    let id: String
    let dateKey: String
    let title: String
    let startDate: Date
    let endDate: Date
    let isAllDay: Bool
    let calendarTitle: String
    let calendarColor: Color

    func displayText(calendar: Calendar) -> String {
        if isAllDay {
            return "\(title) (\(calendarTitle))"
        }

        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.calendar = calendar
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return "\(formatter.string(from: startDate)) \(title) (\(calendarTitle))"
    }
}

extension String {
    var normalizedEventTitle: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }
}
