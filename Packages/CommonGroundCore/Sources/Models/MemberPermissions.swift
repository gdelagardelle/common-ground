import Foundation

public struct MemberPermissions: Codable, Sendable, Equatable {
    public var canEditCalendar: Bool
    public var canEditExpenses: Bool
    public var canEditMedical: Bool
    public var canSendMessages: Bool
    public var canViewDocuments: Bool
    public var canExportRecords: Bool

    public var canViewCalendar: Bool
    public var canViewExpenses: Bool
    public var canViewMedical: Bool
    public var canViewMessages: Bool
    public var canViewTimeline: Bool
    public var canViewSchool: Bool
    public var canViewEmergency: Bool

    public init(
        canEditCalendar: Bool,
        canEditExpenses: Bool,
        canEditMedical: Bool,
        canSendMessages: Bool,
        canViewDocuments: Bool,
        canExportRecords: Bool,
        canViewCalendar: Bool,
        canViewExpenses: Bool,
        canViewMedical: Bool,
        canViewMessages: Bool,
        canViewTimeline: Bool,
        canViewSchool: Bool,
        canViewEmergency: Bool
    ) {
        self.canEditCalendar = canEditCalendar
        self.canEditExpenses = canEditExpenses
        self.canEditMedical = canEditMedical
        self.canSendMessages = canSendMessages
        self.canViewDocuments = canViewDocuments
        self.canExportRecords = canExportRecords
        self.canViewCalendar = canViewCalendar
        self.canViewExpenses = canViewExpenses
        self.canViewMedical = canViewMedical
        self.canViewMessages = canViewMessages
        self.canViewTimeline = canViewTimeline
        self.canViewSchool = canViewSchool
        self.canViewEmergency = canViewEmergency
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        canEditCalendar = try container.decode(Bool.self, forKey: .canEditCalendar)
        canEditExpenses = try container.decode(Bool.self, forKey: .canEditExpenses)
        canEditMedical = try container.decode(Bool.self, forKey: .canEditMedical)
        canSendMessages = try container.decode(Bool.self, forKey: .canSendMessages)
        canViewDocuments = try container.decode(Bool.self, forKey: .canViewDocuments)
        canExportRecords = try container.decode(Bool.self, forKey: .canExportRecords)
        canViewCalendar = try container.decodeIfPresent(Bool.self, forKey: .canViewCalendar) ?? true
        canViewExpenses = try container.decodeIfPresent(Bool.self, forKey: .canViewExpenses) ?? true
        canViewMedical = try container.decodeIfPresent(Bool.self, forKey: .canViewMedical) ?? true
        canViewMessages = try container.decodeIfPresent(Bool.self, forKey: .canViewMessages) ?? true
        canViewTimeline = try container.decodeIfPresent(Bool.self, forKey: .canViewTimeline) ?? true
        canViewSchool = try container.decodeIfPresent(Bool.self, forKey: .canViewSchool) ?? true
        canViewEmergency = try container.decodeIfPresent(Bool.self, forKey: .canViewEmergency) ?? true
    }

    private enum CodingKeys: String, CodingKey {
        case canEditCalendar, canEditExpenses, canEditMedical, canSendMessages
        case canViewDocuments, canExportRecords
        case canViewCalendar, canViewExpenses, canViewMedical, canViewMessages
        case canViewTimeline, canViewSchool, canViewEmergency
    }

    public static func `default`(for role: MemberRole) -> MemberPermissions {
        switch role {
        case .parent, .guardian:
            MemberPermissions(
                canEditCalendar: true,
                canEditExpenses: true,
                canEditMedical: true,
                canSendMessages: true,
                canViewDocuments: true,
                canExportRecords: true,
                canViewCalendar: true,
                canViewExpenses: true,
                canViewMedical: true,
                canViewMessages: true,
                canViewTimeline: true,
                canViewSchool: true,
                canViewEmergency: true
            )
        case .stepParent, .fosterParent:
            MemberPermissions(
                canEditCalendar: true,
                canEditExpenses: true,
                canEditMedical: true,
                canSendMessages: true,
                canViewDocuments: true,
                canExportRecords: false,
                canViewCalendar: true,
                canViewExpenses: true,
                canViewMedical: true,
                canViewMessages: true,
                canViewTimeline: true,
                canViewSchool: true,
                canViewEmergency: true
            )
        case .grandparent, .caregiver:
            MemberPermissions(
                canEditCalendar: false,
                canEditExpenses: false,
                canEditMedical: false,
                canSendMessages: false,
                canViewDocuments: true,
                canExportRecords: false,
                canViewCalendar: true,
                canViewExpenses: false,
                canViewMedical: false,
                canViewMessages: false,
                canViewTimeline: true,
                canViewSchool: true,
                canViewEmergency: true
            )
        case .professional:
            MemberPermissions(
                canEditCalendar: false,
                canEditExpenses: false,
                canEditMedical: false,
                canSendMessages: false,
                canViewDocuments: true,
                canExportRecords: true,
                canViewCalendar: true,
                canViewExpenses: true,
                canViewMedical: true,
                canViewMessages: false,
                canViewTimeline: true,
                canViewSchool: true,
                canViewEmergency: true
            )
        }
    }

    public mutating func applyRoleDefaults(_ role: MemberRole) {
        self = MemberPermissions.default(for: role)
    }
}

public enum PermissionModule: String, CaseIterable, Identifiable, Sendable {
    case calendar
    case expenses
    case medical
    case messages
    case timeline
    case school
    case documents
    case emergency

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .calendar: L10n.tabCalendar
        case .expenses: L10n.childrenModuleExpenses
        case .medical: L10n.childrenModuleMedical
        case .messages: L10n.tabMessages
        case .timeline: L10n.childrenModuleTimeline
        case .school: L10n.childrenModuleSchool
        case .documents: L10n.childrenModuleDocuments
        case .emergency: L10n.childrenModuleEmergency
        }
    }

    public var icon: String {
        switch self {
        case .calendar: "calendar"
        case .expenses: "dollarsign.circle"
        case .medical: "cross.case"
        case .messages: "bubble.left.and.bubble.right"
        case .timeline: "sun.horizon"
        case .school: "book"
        case .documents: "doc"
        case .emergency: "exclamationmark.shield"
        }
    }
}
