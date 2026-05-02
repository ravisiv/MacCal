import Foundation
import SwiftUI

struct Holiday: Identifiable, Codable, Hashable {
    enum Region: String, Codable, CaseIterable {
        case unitedStates = "US"
        case india = "India"

        var markerColor: Color {
            switch self {
            case .unitedStates:
                return .green
            case .india:
                return .orange
            }
        }
    }

    let id: String
    let dateKey: String
    let name: String
    let region: Region
    let source: String

    init(dateKey: String, name: String, region: Region, source: String) {
        self.id = "\(dateKey)-\(region.rawValue)-\(name)"
        self.dateKey = dateKey
        self.name = name
        self.region = region
        self.source = source
    }
}

extension Array where Element == Holiday {
    var tooltipText: String {
        groupedByName
            .map { name, holidays in
                "\(regionList(for: holidays)): \(name)"
            }
            .joined(separator: "\n")
    }

    var displayText: String {
        groupedByName
            .map { name, holidays in
                "\(regionList(for: holidays)): \(name)"
            }
            .joined(separator: "  |  ")
    }

    private var groupedByName: [(String, [Holiday])] {
        var grouped: [String: (String, [Holiday])] = [:]

        for holiday in self {
            let key = holiday.name.normalizedHolidayName
            let current = grouped[key] ?? (holiday.name, [])
            grouped[key] = (current.0, current.1 + [holiday])
        }

        return grouped.values.sorted { lhs, rhs in
            lhs.0 < rhs.0
        }
    }

    private func regionList(for holidays: [Holiday]) -> String {
        Holiday.Region.allCases
            .filter { region in holidays.contains(where: { $0.region == region }) }
            .map(\.rawValue)
            .joined(separator: ", ")
    }
}

private extension String {
    var normalizedHolidayName: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .lowercased()
    }
}
