import Foundation
import SwiftData

// MARK: - Family

@Model
public final class Family {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \FamilyMember.family)
    public var members: [FamilyMember]

    @Relationship(deleteRule: .cascade, inverse: \Child.family)
    public var children: [Child]

    @Relationship(deleteRule: .cascade, inverse: \CustodyAgreement.family)
    public var custodyAgreements: [CustodyAgreement]

    public init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.members = []
        self.children = []
        self.custodyAgreements = []
    }
}

// MARK: - Family Member

@Model
public final class FamilyMember {
    @Attribute(.unique) public var id: UUID
    public var displayName: String
    public var email: String?
    public var phone: String?
    public var role: MemberRole
    public var avatarEmoji: String
    public var permissions: MemberPermissions
    public var joinedAt: Date

    public var family: Family?

    public init(
        displayName: String,
        role: MemberRole,
        email: String? = nil,
        phone: String? = nil
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.email = email
        self.phone = phone
        self.role = role
        self.avatarEmoji = role.defaultEmoji
        self.permissions = MemberPermissions.default(for: role)
        self.joinedAt = Date()
    }
}

public enum MemberRole: String, Codable, CaseIterable, Sendable {
    case parent
    case stepParent
    case grandparent
    case guardian
    case fosterParent
    case caregiver
    case professional

    public var displayName: String {
        switch self {
        case .parent: "Parent"
        case .stepParent: "Step Parent"
        case .grandparent: "Grandparent"
        case .guardian: "Guardian"
        case .fosterParent: "Foster Parent"
        case .caregiver: "Caregiver"
        case .professional: "Professional"
        }
    }

    public var defaultEmoji: String {
        switch self {
        case .parent: "👤"
        case .stepParent: "🤝"
        case .grandparent: "👴"
        case .guardian: "🛡️"
        case .fosterParent: "🏠"
        case .caregiver: "💚"
        case .professional: "⚖️"
        }
    }
}
