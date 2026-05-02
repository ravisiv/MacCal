import XCTest
@testable import MacCal

final class DetailDedupingTests: XCTestCase {
    func testHolidayDisplayCondensesSameHolidayAcrossRegions() {
        let holidays = [
            Holiday(dateKey: "2026-12-25", name: "Christmas Day", region: .unitedStates, source: "Test"),
            Holiday(dateKey: "2026-12-25", name: "Christmas Day", region: .india, source: "Test")
        ]

        XCTAssertEqual(holidays.displayText, "US, India: Christmas Day")
    }

    func testEventTitleNormalizationTreatsWhitespaceAndCaseAsDuplicates() {
        XCTAssertEqual(" Father's   Day ".normalizedEventTitle, "father's day")
        XCTAssertEqual("FATHER'S DAY".normalizedEventTitle, "father's day")
    }
}
