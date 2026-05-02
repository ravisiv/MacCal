import Foundation
import SwiftUI

struct CalendarInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let color: Color
}

struct CalendarGroupInfo: Identifiable, Hashable {
    let id: String
    let title: String
    let calendarIDs: [String]
    let colors: [Color]

    var subtitle: String? {
        calendarIDs.count > 1 ? "\(calendarIDs.count) calendars" : nil
    }
}
