import Foundation
import SwiftData

public enum AgreementStatus: String, Codable, CaseIterable, Sendable {
    case draft
    case pendingSignatures
    case fullySigned
    case archived

    public var displayName: String {
        switch self {
        case .draft: L10n.agreementStatusDraft
        case .pendingSignatures: L10n.agreementStatusPending
        case .fullySigned: L10n.agreementStatusSigned
        case .archived: L10n.agreementStatusArchived
        }
    }
}

@Model
public final class CustodyAgreement {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var bodyText: String
    public var statusRaw: String
    public var effectiveDate: Date?
    public var parentAId: UUID?
    public var parentAName: String?
    public var parentASignatureData: Data?
    public var parentASignedAt: Date?
    public var parentBId: UUID?
    public var parentBName: String?
    public var parentBSignatureData: Data?
    public var parentBSignedAt: Date?
    public var documentHash: String?
    public var createdAt: Date
    public var updatedAt: Date

    public var family: Family?
    public var child: Child?

    public var status: AgreementStatus {
        get { AgreementStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    public init(title: String, bodyText: String, effectiveDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.bodyText = bodyText
        self.statusRaw = AgreementStatus.draft.rawValue
        self.effectiveDate = effectiveDate
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    public var isFullySigned: Bool {
        parentASignatureData != nil && parentBSignatureData != nil
    }

    public func pendingSignerId(currentMemberId: UUID) -> Bool {
        if parentAId == currentMemberId { return parentASignatureData == nil }
        if parentBId == currentMemberId { return parentBSignatureData == nil }
        return false
    }
}
