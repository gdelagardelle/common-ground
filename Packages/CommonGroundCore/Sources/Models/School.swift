import Foundation
import SwiftData

@Model
public final class SchoolInfo {
    @Attribute(.unique) public var id: UUID
    public var schoolName: String
    public var grade: String?
    public var classroom: String?
    public var schoolPhone: String?
    public var schoolAddress: String?
    public var schoolYear: String?
    public var createdAt: Date
    public var updatedAt: Date

    public var child: Child?

    @Relationship(deleteRule: .cascade, inverse: \Contact.schoolInfo)
    public var teachers: [Contact]

    public init(schoolName: String, grade: String? = nil) {
        self.id = UUID()
        self.schoolName = schoolName
        self.grade = grade
        self.createdAt = Date()
        self.updatedAt = Date()
        self.teachers = []
    }
}

@Model
public final class Contact {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var role: String?
    public var email: String?
    public var phone: String?
    public var notes: String?
    public var isEmergencyContact: Bool
    public var createdAt: Date

    public var schoolInfo: SchoolInfo?

    public init(name: String, role: String? = nil, phone: String? = nil) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.phone = phone
        self.isEmergencyContact = false
        self.createdAt = Date()
    }
}

@Model
public final class Document {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var category: DocumentCategory
    public var fileData: Data?
    public var fileName: String?
    public var mimeType: String?
    public var expiryDate: Date?
    public var isEncrypted: Bool
    public var createdAt: Date
    public var updatedAt: Date

    public var child: Child?

    public var isExpiringSoon: Bool {
        guard let expiry = expiryDate else { return false }
        let threshold = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
        return expiry <= threshold
    }

    public init(title: String, category: DocumentCategory) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.isEncrypted = true
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

public enum DocumentCategory: String, Codable, CaseIterable, Sendable {
    case passport
    case birthCertificate
    case insurance
    case schoolReport
    case medicalReport
    case permissionSlip
    case contract
    case receipt
    case other

    public var displayName: String {
        switch self {
        case .passport: "Passport"
        case .birthCertificate: "Birth Certificate"
        case .insurance: "Insurance"
        case .schoolReport: "School Report"
        case .medicalReport: "Medical Report"
        case .permissionSlip: "Permission Slip"
        case .contract: "Contract"
        case .receipt: "Receipt"
        case .other: "Other"
        }
    }

    public var icon: String {
        switch self {
        case .passport: "person.text.rectangle.fill"
        case .birthCertificate: "doc.text.fill"
        case .insurance: "shield.fill"
        case .schoolReport: "book.closed.fill"
        case .medicalReport: "heart.text.clipboard.fill"
        case .permissionSlip: "signature"
        case .contract: "doc.richtext.fill"
        case .receipt: "receipt.fill"
        case .other: "folder.fill"
        }
    }
}
