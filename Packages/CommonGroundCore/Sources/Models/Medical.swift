import Foundation
import SwiftData

@Model
public final class MedicalRecord {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var provider: String?
    public var date: Date
    public var category: MedicalCategory
    public var notes: String?
    public var attachmentData: Data?
    public var createdAt: Date

    public var child: Child?

    public init(title: String, category: MedicalCategory, date: Date, provider: String? = nil) {
        self.id = UUID()
        self.title = title
        self.provider = provider
        self.date = date
        self.category = category
        self.createdAt = Date()
    }
}

public enum MedicalCategory: String, Codable, CaseIterable, Sendable {
    case visit
    case vaccination
    case prescription
    case lab
    case dental
    case vision
    case growth
    case allergy
    case emergency
    case other

    public var displayName: String {
        switch self {
        case .visit: "Doctor Visit"
        case .vaccination: "Vaccination"
        case .prescription: "Prescription"
        case .lab: "Lab Results"
        case .dental: "Dental"
        case .vision: "Vision"
        case .growth: "Growth"
        case .allergy: "Allergy"
        case .emergency: "Emergency"
        case .other: "Other"
        }
    }

    public var icon: String {
        switch self {
        case .visit: "stethoscope"
        case .vaccination: "syringe.fill"
        case .prescription: "pills.fill"
        case .lab: "flask.fill"
        case .dental: "mouth.fill"
        case .vision: "eye.fill"
        case .growth: "chart.line.uptrend.xyaxis"
        case .allergy: "allergens"
        case .emergency: "cross.case.fill"
        case .other: "heart.text.clipboard.fill"
        }
    }
}

@Model
public final class Medication {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var dosage: String
    public var frequency: String
    public var prescribedBy: String?
    public var startDate: Date
    public var endDate: Date?
    public var reminderTimes: [Date]
    public var isActive: Bool
    public var notes: String?
    public var createdAt: Date

    public var child: Child?

    public init(name: String, dosage: String, frequency: String, startDate: Date = Date()) {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.frequency = frequency
        self.startDate = startDate
        self.reminderTimes = []
        self.isActive = true
        self.createdAt = Date()
    }
}
