import Foundation

enum MacCalPreferences {
    static let showUSHolidaysKey = "showUSHolidays"
    static let showIndiaHolidaysKey = "showIndiaHolidays"
    static let showCalendarEventsKey = "showCalendarEvents"
    static let menuBarDisplayFormatKey = "menuBarDisplayFormat"
    static let selectedCalendarIDsKey = "selectedCalendarIDs"
    static let calendarSelectionVersionKey = "calendarSelectionVersion"

    static func registerDefaults() {
        UserDefaults.standard.register(defaults: [
            showUSHolidaysKey: true,
            showIndiaHolidaysKey: true,
            showCalendarEventsKey: false,
            selectedCalendarIDsKey: [],
            calendarSelectionVersionKey: 0,
            menuBarDisplayFormatKey: MenuBarDisplayFormat.calendarIcon.rawValue
        ])
    }

    static func selectedCalendarIDs() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: selectedCalendarIDsKey) ?? [])
    }

    static func setSelectedCalendarIDs(_ ids: Set<String>) {
        UserDefaults.standard.set(Array(ids).sorted(), forKey: selectedCalendarIDsKey)
        UserDefaults.standard.set(
            UserDefaults.standard.integer(forKey: calendarSelectionVersionKey) + 1,
            forKey: calendarSelectionVersionKey
        )
    }
}

enum MenuBarDisplayFormat: String, CaseIterable, Identifiable {
    case calendarIcon
    case shortDate
    case dayOnly
    case weekdayDay

    var id: String { rawValue }

    var title: String {
        switch self {
        case .calendarIcon:
            return "Calendar icon"
        case .shortDate:
            return "Short date"
        case .dayOnly:
            return "Day only"
        case .weekdayDay:
            return "Weekday + day"
        }
    }
}
