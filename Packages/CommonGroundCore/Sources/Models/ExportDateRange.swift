import Foundation

public enum ExportDateRange: String, CaseIterable, Identifiable, Sendable {
    case threeMonths
    case twelveMonths
    case allTime

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .threeMonths: L10n.exportRange3months
        case .twelveMonths: L10n.exportRange12months
        case .allTime: L10n.exportRangeAllTime
        }
    }

    public var rangeMonths: Int? {
        switch self {
        case .threeMonths: 3
        case .twelveMonths: 12
        case .allTime: nil
        }
    }
}
