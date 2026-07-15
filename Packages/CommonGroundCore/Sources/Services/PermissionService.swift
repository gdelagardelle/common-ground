import Foundation

@MainActor
public enum PermissionService {
    public static func currentMember(in family: Family?, memberId: UUID?) -> FamilyMember? {
        guard let family, let memberId else { return nil }
        return family.members.first { $0.id == memberId }
    }

    public static func isProfessional(member: FamilyMember?) -> Bool {
        member?.role == .professional
    }

    public static func canEditCalendar(_ member: FamilyMember?) -> Bool {
        member?.permissions.canEditCalendar ?? false
    }

    public static func canEditExpenses(_ member: FamilyMember?) -> Bool {
        member?.permissions.canEditExpenses ?? false
    }

    public static func canEditMedical(_ member: FamilyMember?) -> Bool {
        member?.permissions.canEditMedical ?? false
    }

    public static func canSendMessages(_ member: FamilyMember?) -> Bool {
        member?.permissions.canSendMessages ?? false
    }

    public static func canViewDocuments(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewDocuments ?? false
    }

    public static func canExportRecords(_ member: FamilyMember?) -> Bool {
        member?.permissions.canExportRecords ?? false
    }

    public static func canViewCalendar(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewCalendar ?? false
    }

    public static func canViewExpenses(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewExpenses ?? false
    }

    public static func canViewMedical(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewMedical ?? false
    }

    public static func canViewMessages(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewMessages ?? false
    }

    public static func canViewTimeline(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewTimeline ?? false
    }

    public static func canViewSchool(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewSchool ?? false
    }

    public static func canViewEmergency(_ member: FamilyMember?) -> Bool {
        member?.permissions.canViewEmergency ?? false
    }

    public static func canPostDailyUpdate(_ member: FamilyMember?) -> Bool {
        guard let member else { return false }
        return member.permissions.canViewTimeline && member.role != .professional
    }

    public static func canView(_ module: PermissionModule, member: FamilyMember?) -> Bool {
        guard let member else { return false }
        switch module {
        case .calendar: return member.permissions.canViewCalendar
        case .expenses: return member.permissions.canViewExpenses
        case .medical: return member.permissions.canViewMedical
        case .messages: return member.permissions.canViewMessages
        case .timeline: return member.permissions.canViewTimeline
        case .school: return member.permissions.canViewSchool
        case .documents: return member.permissions.canViewDocuments
        case .emergency: return member.permissions.canViewEmergency
        }
    }

    public static func canEdit(_ module: PermissionModule, member: FamilyMember?) -> Bool {
        guard let member else { return false }
        switch module {
        case .calendar: return member.permissions.canEditCalendar
        case .expenses: return member.permissions.canEditExpenses
        case .medical: return member.permissions.canEditMedical
        case .messages: return member.permissions.canSendMessages
        case .timeline: return canPostDailyUpdate(member)
        case .school: return member.permissions.canEditCalendar
        case .documents: return member.permissions.canViewDocuments && member.role != .professional
        case .emergency: return member.permissions.canEditMedical
        }
    }

    public static func setView(_ module: PermissionModule, enabled: Bool, permissions: inout MemberPermissions) {
        switch module {
        case .calendar: permissions.canViewCalendar = enabled
        case .expenses: permissions.canViewExpenses = enabled
        case .medical: permissions.canViewMedical = enabled
        case .messages: permissions.canViewMessages = enabled
        case .timeline: permissions.canViewTimeline = enabled
        case .school: permissions.canViewSchool = enabled
        case .documents: permissions.canViewDocuments = enabled
        case .emergency: permissions.canViewEmergency = enabled
        }
        if !enabled {
            setEdit(module, enabled: false, permissions: &permissions)
        }
    }

    public static func setEdit(_ module: PermissionModule, enabled: Bool, permissions: inout MemberPermissions) {
        switch module {
        case .calendar: permissions.canEditCalendar = enabled
        case .expenses: permissions.canEditExpenses = enabled
        case .medical: permissions.canEditMedical = enabled
        case .messages: permissions.canSendMessages = enabled
        case .timeline: break
        case .school: break
        case .documents: break
        case .emergency: permissions.canEditMedical = enabled
        }
        if enabled {
            setView(module, enabled: true, permissions: &permissions)
        }
    }

    public static func professionalSummary(for family: Family) -> ProfessionalFamilySummary {
        let children = family.children.map { child in
            ProfessionalChildSummary(
                name: child.fullName,
                age: child.age,
                upcomingEvents: child.events.filter { $0.startDate >= Date() }.count,
                documentCount: child.documents.count
            )
        }
        return ProfessionalFamilySummary(
            familyName: family.name,
            memberCount: family.members.count,
            children: children,
            activeSchedules: family.children.flatMap(\.custodySchedules).filter(\.isActive).count
        )
    }
}

public struct ProfessionalFamilySummary: Sendable {
    public let familyName: String
    public let memberCount: Int
    public let children: [ProfessionalChildSummary]
    public let activeSchedules: Int
}

public struct ProfessionalChildSummary: Sendable {
    public let name: String
    public let age: Int
    public let upcomingEvents: Int
    public let documentCount: Int
}
