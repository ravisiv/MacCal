import Foundation
import SwiftUI

struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let sourceTitle: String
    let color: Color
}

struct CalendarGroupInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let calendarIDs: [String]
    let sourceTitles: [String]
    let colors: [Color]

    var subtitle: String? {
        let sources = sourceTitles.isEmpty ? "" : sourceTitles.joined(separator: ", ")
        if calendarIDs.count > 1, !sources.isEmpty {
            return "\(calendarIDs.count) calendars - \(sources)"
        }
        if calendarIDs.count > 1 {
            return "\(calendarIDs.count) calendars"
        }
        return sources.isEmpty ? nil : sources
    }
}
