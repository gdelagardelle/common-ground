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
