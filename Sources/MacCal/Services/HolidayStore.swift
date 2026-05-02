import Foundation

@MainActor
final class HolidayStore: ObservableObject {
    @Published private(set) var holidaysByDate: [String: [Holiday]] = [:]

    private let cacheURL: URL
    private var loadedYears: Set<Int> = []

    init() {
        let supportDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let appDirectory = supportDirectory.appendingPathComponent("MacCal", isDirectory: true)
        cacheURL = appDirectory.appendingPathComponent("holidays.json")
        loadCache()
    }

    func load(year: Int) {
        guard !loadedYears.contains(year) else { return }
        loadedYears.insert(year)
        merge(Self.fallbackHolidays(for: year))

        Task {
            await refreshOnline(year: year)
        }
    }

    func holidays(for date: Date, calendar: Calendar) -> [Holiday] {
        holidaysByDate[Self.dateKey(for: date, calendar: calendar)] ?? []
    }

    private func refreshOnline(year: Int) async {
        var onlineHolidays: [Holiday] = []

        if let usHolidays = await fetchUSHolidays(year: year) {
            onlineHolidays.append(contentsOf: usHolidays)
        }

        if let indiaHolidays = await fetchIndiaHolidays(year: year) {
            onlineHolidays.append(contentsOf: indiaHolidays)
        }

        guard !onlineHolidays.isEmpty else { return }
        merge(onlineHolidays)
        saveCache()
    }

    private func merge(_ holidays: [Holiday]) {
        var next = holidaysByDate

        for holiday in holidays {
            var dayHolidays = next[holiday.dateKey, default: []]
            dayHolidays.removeAll { $0.region == holiday.region && $0.name == holiday.name }
            dayHolidays.append(holiday)
            dayHolidays.sort { lhs, rhs in
                if lhs.region.rawValue == rhs.region.rawValue {
                    return lhs.name < rhs.name
                }

                return lhs.region.rawValue < rhs.region.rawValue
            }
            next[holiday.dateKey] = dayHolidays
        }

        holidaysByDate = next
    }

    private func loadCache() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode([Holiday].self, from: data) else {
            return
        }

        merge(cached)
    }

    private func saveCache() {
        do {
            try FileManager.default.createDirectory(at: cacheURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let holidays = holidaysByDate.values.flatMap { $0 }
            let data = try JSONEncoder().encode(holidays)
            try data.write(to: cacheURL, options: .atomic)
        } catch {
            NSLog("MacCal holiday cache save failed: \(error.localizedDescription)")
        }
    }

    private func fetchUSHolidays(year: Int) async -> [Holiday]? {
        guard let url = URL(string: "https://www.opm.gov/policy-data-oversight/pay-leave/federal-holidays/") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            let section = Self.section(in: html, forYear: year)
            let source = section ?? html
            let holidays = Self.parseOPMHolidays(source, year: year)
            return holidays.isEmpty ? nil : holidays
        } catch {
            NSLog("MacCal U.S. holiday refresh failed: \(error.localizedDescription)")
            return nil
        }
    }

    private func fetchIndiaHolidays(year: Int) async -> [Holiday]? {
        guard let url = URL(string: "https://www.indiapost.gov.in/holidays-list") else {
            return nil
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let html = String(data: data, encoding: .utf8) else { return nil }
            let holidays = Self.parseIndiaPostHolidays(html, year: year)
            return holidays.isEmpty ? nil : holidays
        } catch {
            NSLog("MacCal India holiday refresh failed: \(error.localizedDescription)")
            return nil
        }
    }
}

private extension HolidayStore {
    static func fallbackHolidays(for year: Int) -> [Holiday] {
        fallbackUSHolidays(for: year) + fallbackIndiaHolidays(for: year)
    }

    static func fallbackUSHolidays(for year: Int) -> [Holiday] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent

        let rules: [(Date?, String)] = [
            (date(year, 1, 1, calendar), "New Year's Day"),
            (nthWeekday(year: year, month: 1, weekday: 2, ordinal: 3, calendar: calendar), "Birthday of Martin Luther King, Jr."),
            (nthWeekday(year: year, month: 2, weekday: 2, ordinal: 3, calendar: calendar), "Washington's Birthday"),
            (lastWeekday(year: year, month: 5, weekday: 2, calendar: calendar), "Memorial Day"),
            (date(year, 6, 19, calendar), "Juneteenth National Independence Day"),
            (date(year, 7, 4, calendar), "Independence Day"),
            (nthWeekday(year: year, month: 9, weekday: 2, ordinal: 1, calendar: calendar), "Labor Day"),
            (nthWeekday(year: year, month: 10, weekday: 2, ordinal: 2, calendar: calendar), "Columbus Day"),
            (date(year, 11, 11, calendar), "Veterans Day"),
            (nthWeekday(year: year, month: 11, weekday: 5, ordinal: 4, calendar: calendar), "Thanksgiving Day"),
            (date(year, 12, 25, calendar), "Christmas Day")
        ]

        return rules.compactMap { date, name in
            guard let date else { return nil }
            return Holiday(
                dateKey: dateKey(for: observedUSFederalDate(for: date, calendar: calendar), calendar: calendar),
                name: name,
                region: .unitedStates,
                source: "Bundled fallback"
            )
        }
    }

    static func fallbackIndiaHolidays(for year: Int) -> [Holiday] {
        if year == 2026 {
            return [
                (1, 26, "Republic Day"),
                (3, 4, "Holi"),
                (3, 21, "Id-ul-Fitr"),
                (3, 26, "Ram Navami"),
                (3, 31, "Mahavir Jayanti"),
                (4, 3, "Good Friday"),
                (5, 1, "Buddha Purnima"),
                (5, 27, "Id-ul-Zuha"),
                (6, 26, "Muharram"),
                (8, 15, "Independence Day"),
                (8, 26, "Id-e-Milad"),
                (9, 4, "Janmashtami"),
                (10, 2, "Mahatma Gandhi's Birthday"),
                (10, 20, "Dussehra"),
                (11, 8, "Diwali"),
                (11, 24, "Guru Nanak's Birthday"),
                (12, 25, "Christmas Day")
            ].compactMap { month, day, name in
                fixedIndiaHoliday(year: year, month: month, day: day, name: name)
            }
        }

        return [
            fixedIndiaHoliday(year: year, month: 1, day: 26, name: "Republic Day"),
            fixedIndiaHoliday(year: year, month: 8, day: 15, name: "Independence Day"),
            fixedIndiaHoliday(year: year, month: 10, day: 2, name: "Mahatma Gandhi's Birthday"),
            fixedIndiaHoliday(year: year, month: 12, day: 25, name: "Christmas Day")
        ].compactMap { $0 }
    }

    static func fixedIndiaHoliday(year: Int, month: Int, day: Int, name: String) -> Holiday? {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .autoupdatingCurrent
        guard let date = date(year, month, day, calendar) else { return nil }

        return Holiday(
            dateKey: dateKey(for: date, calendar: calendar),
            name: name,
            region: .india,
            source: "Bundled fallback"
        )
    }

    static func observedUSFederalDate(for date: Date, calendar: Calendar) -> Date {
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 7 {
            return calendar.date(byAdding: .day, value: -1, to: date) ?? date
        }

        if weekday == 1 {
            return calendar.date(byAdding: .day, value: 1, to: date) ?? date
        }

        return date
    }

    static func date(_ year: Int, _ month: Int, _ day: Int, _ calendar: Calendar) -> Date? {
        calendar.date(from: DateComponents(year: year, month: month, day: day))
    }

    static func nthWeekday(year: Int, month: Int, weekday: Int, ordinal: Int, calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.weekday = weekday
        components.weekdayOrdinal = ordinal
        return calendar.date(from: components)
    }

    static func lastWeekday(year: Int, month: Int, weekday: Int, calendar: Calendar) -> Date? {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.weekday = weekday
        components.weekdayOrdinal = -1
        return calendar.date(from: components)
    }

    static func dateKey(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", components.year ?? 0, components.month ?? 0, components.day ?? 0)
    }
}

private extension HolidayStore {
    static func section(in html: String, forYear year: Int) -> String? {
        guard let startRange = html.range(of: ">\(year)<").or(html.range(of: "\(year) Holiday Schedule")) else {
            return nil
        }

        let tail = html[startRange.lowerBound...]
        if let endRange = tail.range(of: ">\(year + 1)<").or(tail.range(of: "\(year + 1) Holiday Schedule")) {
            return String(tail[..<endRange.lowerBound])
        }

        return String(tail)
    }

    static func parseOPMHolidays(_ html: String, year: Int) -> [Holiday] {
        let plain = html.htmlDecoded.strippingHTML
        let pattern = #"(?i)(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday),?\s+([A-Za-z]+)\s+(\d{1,2})\s+\*{0,2}\s+([A-Z][^\n\r]+)"#
        return matches(pattern: pattern, in: plain).compactMap { match in
            guard match.count >= 5,
                  let month = monthNumber(match[2]),
                  let day = Int(match[3]) else {
                return nil
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .autoupdatingCurrent
            guard let date = date(year, month, day, calendar) else { return nil }
            let name = cleanHolidayName(match[4])

            return Holiday(
                dateKey: dateKey(for: date, calendar: calendar),
                name: name,
                region: .unitedStates,
                source: "U.S. Office of Personnel Management"
            )
        }
    }

    static func parseIndiaPostHolidays(_ html: String, year: Int) -> [Holiday] {
        let plain = html.htmlDecoded.strippingHTML
        let pattern = #"([A-Za-z][A-Za-z\s'().\-]+?)\s+(\d{1,2})-([A-Za-z]+)-(\d{4})\s+(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)"#
        return matches(pattern: pattern, in: plain).compactMap { match in
            guard match.count >= 5,
                  Int(match[4]) == year,
                  let day = Int(match[2]),
                  let month = monthNumber(match[3]) else {
                return nil
            }

            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .autoupdatingCurrent
            guard let date = date(year, month, day, calendar) else { return nil }
            let name = cleanHolidayName(match[1])

            return Holiday(
                dateKey: dateKey(for: date, calendar: calendar),
                name: name,
                region: .india,
                source: "India Post"
            )
        }
    }

    static func matches(pattern: String, in text: String) -> [[String]] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)

        return regex.matches(in: text, range: range).map { result in
            (0..<result.numberOfRanges).compactMap { index in
                guard let range = Range(result.range(at: index), in: text) else { return nil }
                return String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
    }

    static func monthNumber(_ month: String) -> Int? {
        let prefix = month.lowercased().prefix(3)
        return [
            "jan": 1,
            "feb": 2,
            "mar": 3,
            "apr": 4,
            "may": 5,
            "jun": 6,
            "jul": 7,
            "aug": 8,
            "sep": 9,
            "oct": 10,
            "nov": 11,
            "dec": 12
        ][String(prefix)]
    }

    static func cleanHolidayName(_ value: String) -> String {
        value
            .replacingOccurrences(of: #"[*]+"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension Optional where Wrapped == Range<String.Index> {
    func or(_ other: Range<String.Index>?) -> Range<String.Index>? {
        self ?? other
    }
}

private extension String {
    var strippingHTML: String {
        replacingOccurrences(of: "<[^>]+>", with: "\n", options: .regularExpression)
            .replacingOccurrences(of: #"\n\s+\n"#, with: "\n", options: .regularExpression)
    }

    var htmlDecoded: String {
        replacingOccurrences(of: "&nbsp;", with: " ")
            .replacingOccurrences(of: "&amp;", with: "&")
            .replacingOccurrences(of: "&#39;", with: "'")
            .replacingOccurrences(of: "&apos;", with: "'")
            .replacingOccurrences(of: "&quot;", with: "\"")
            .replacingOccurrences(of: "&rsquo;", with: "'")
            .replacingOccurrences(of: "&lsquo;", with: "'")
            .replacingOccurrences(of: "&ndash;", with: "-")
            .replacingOccurrences(of: "&mdash;", with: "-")
    }
}
