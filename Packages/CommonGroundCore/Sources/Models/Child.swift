import Foundation
import SwiftData

@Model
public final class Child {
    @Attribute(.unique) public var id: UUID
    public var firstName: String
    public var lastName: String
    public var dateOfBirth: Date
    public var photoData: Data?
    /// Raw `NSAdaptiveImageGlyph.imageContent` for Apple Genmoji faces.
    public var genmojiData: Data?
    public var avatarEmoji: String
    public var bloodType: String?
    public var allergies: [String]
    public var clothingSize: String?
    public var shoeSize: String?
    public var socialSecurityLastFour: String?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date

    public var family: Family?

    @Relationship(deleteRule: .cascade, inverse: \MedicalRecord.child)
    public var medicalRecords: [MedicalRecord]

    @Relationship(deleteRule: .cascade, inverse: \Medication.child)
    public var medications: [Medication]

    @Relationship(deleteRule: .cascade, inverse: \GrowthMeasurement.child)
    public var growthMeasurements: [GrowthMeasurement]

    @Relationship(deleteRule: .cascade, inverse: \SchoolAnnouncement.child)
    public var schoolAnnouncements: [SchoolAnnouncement]

    @Relationship(deleteRule: .cascade, inverse: \SchoolAssignment.child)
    public var schoolAssignments: [SchoolAssignment]

    @Relationship(deleteRule: .cascade, inverse: \SchoolInfo.child)
    public var schoolInfo: SchoolInfo?

    @Relationship(deleteRule: .cascade, inverse: \EmergencyInfo.child)
    public var emergencyInfo: EmergencyInfo?

    @Relationship(deleteRule: .cascade, inverse: \TimelineEntry.child)
    public var timelineEntries: [TimelineEntry]

    @Relationship(deleteRule: .cascade, inverse: \CalendarEvent.child)
    public var events: [CalendarEvent]

    @Relationship(deleteRule: .cascade, inverse: \Expense.child)
    public var expenses: [Expense]

    @Relationship(deleteRule: .cascade, inverse: \Document.child)
    public var documents: [Document]

    @Relationship(deleteRule: .cascade, inverse: \CustodySchedule.child)
    public var custodySchedules: [CustodySchedule]

    public var fullName: String { "\(firstName) \(lastName)" }

    public var age: Int {
        Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year ?? 0
    }

    public init(firstName: String, lastName: String, dateOfBirth: Date) {
        self.id = UUID()
        self.firstName = firstName
        self.lastName = lastName
        self.dateOfBirth = dateOfBirth
        self.avatarEmoji = "🧒"
        self.allergies = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.medicalRecords = []
        self.medications = []
        self.growthMeasurements = []
        self.schoolAnnouncements = []
        self.schoolAssignments = []
        self.timelineEntries = []
        self.events = []
        self.expenses = []
        self.documents = []
        self.custodySchedules = []
    }
}

@Model
public final class EmergencyInfo {
    @Attribute(.unique) public var id: UUID
    public var primaryContactName: String?
    public var primaryContactPhone: String?
    public var secondaryContactName: String?
    public var secondaryContactPhone: String?
    public var pediatricianName: String?
    public var pediatricianPhone: String?
    public var hospitalPreference: String?
    public var insuranceProvider: String?
    public var insurancePolicyNumber: String?
    public var insuranceGroupNumber: String?
    public var passportNumber: String?
    public var passportExpiry: Date?
    public var passportCountry: String?
    public var additionalNotes: String?

    public var child: Child?

    public init() {
        self.id = UUID()
    }
}

@Model
public final class TimelineEntry {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var detail: String?
    public var category: TimelineCategory
    public var date: Date
    public var photoData: Data?
    public var authorMemberId: UUID?
    public var authorName: String?
    public var createdAt: Date

    public var child: Child?

    public init(
        title: String,
        category: TimelineCategory,
        date: Date,
        detail: String? = nil,
        authorMemberId: UUID? = nil,
        authorName: String? = nil
    ) {
        self.id = UUID()
        self.title = title
        self.detail = detail
        self.category = category
        self.date = date
        self.authorMemberId = authorMemberId
        self.authorName = authorName
        self.createdAt = Date()
    }

    public var isDailyUpdate: Bool { category == .dailyUpdate }
}

public enum TimelineCategory: String, Codable, CaseIterable, Sendable {
    case dailyUpdate
    case milestone
    case medical
    case school
    case achievement
    case trip
    case birthday
    case first
    case other

    public var displayName: String {
        switch self {
        case .dailyUpdate: L10n.timelineDailyUpdate
        case .milestone: L10n.timelineMilestone
        case .medical: L10n.timelineMedical
        case .school: L10n.timelineSchool
        case .achievement: L10n.timelineAchievement
        case .trip: L10n.timelineTrip
        case .birthday: L10n.timelineBirthday
        case .first: L10n.timelineFirst
        case .other: L10n.timelineOther
        }
    }

    public var icon: String {
        switch self {
        case .dailyUpdate: "sun.horizon.fill"
        case .milestone: "star.fill"
        case .medical: "cross.case.fill"
        case .school: "book.fill"
        case .achievement: "trophy.fill"
        case .trip: "airplane"
        case .birthday: "birthday.cake.fill"
        case .first: "1.circle.fill"
        case .other: "circle.fill"
        }
    }
}
