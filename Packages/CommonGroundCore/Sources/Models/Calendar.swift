import Foundation
import SwiftData

@Model
public final class CustodySchedule {
    @Attribute(.unique) public var id: UUID
    public var name: String
    public var pattern: CustodyPattern
    public var startDate: Date
    public var parentAId: UUID
    public var parentBId: UUID
    public var parentAName: String
    public var parentBName: String
    public var exchangeTime: Date?
    public var exchangeLocation: String?
    public var isActive: Bool
    public var createdAt: Date

    public var child: Child?

    public init(
        name: String,
        pattern: CustodyPattern,
        startDate: Date,
        parentAId: UUID,
        parentBId: UUID,
        parentAName: String,
        parentBName: String
    ) {
        self.id = UUID()
        self.name = name
        self.pattern = pattern
        self.startDate = startDate
        self.parentAId = parentAId
        self.parentBId = parentBId
        self.parentAName = parentAName
        self.parentBName = parentBName
        self.isActive = true
        self.createdAt = Date()
    }
}

public enum CustodyPattern: String, Codable, CaseIterable, Sendable {
    case weekOnWeekOff
    case twoTwoThree
    case alternatingWeekends
    case custom

    public var displayName: String {
        switch self {
        case .weekOnWeekOff: L10n.custodyWeekOnWeekOff
        case .twoTwoThree: L10n.custodyTwoTwoThree
        case .alternatingWeekends: L10n.custodyAlternatingWeekends
        case .custom: L10n.custodyCustom
        }
    }

    public var description: String {
        switch self {
        case .weekOnWeekOff: L10n.custodyDescWeekOnWeekOff
        case .twoTwoThree: L10n.custodyDescTwoTwoThree
        case .alternatingWeekends: L10n.custodyDescAlternatingWeekends
        case .custom: L10n.custodyDescCustom
        }
    }
}

@Model
public final class CalendarEvent {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var detail: String?
    public var startDate: Date
    public var endDate: Date
    public var isAllDay: Bool
    public var category: EventCategory
    public var location: String?
    public var assignedParentId: UUID?
    public var isRecurring: Bool
    public var recurrenceRule: String?
    public var reminderMinutes: Int?
    public var createdAt: Date
    public var updatedAt: Date
    /// EventKit identifier when exported to Apple Calendar.
    public var appleCalendarEventIdentifier: String?
    public var lastSyncedAt: Date?
    public var latitude: Double?
    public var longitude: Double?
    public var sharedLocationAt: Date?
    public var sharedLocationMemberName: String?

    public var child: Child?

    public var hasSharedLocation: Bool {
        latitude != nil && longitude != nil
    }

    public var mapsURL: URL? {
        guard let latitude, let longitude else { return nil }
        return URL(string: "https://maps.apple.com/?ll=\(latitude),\(longitude)")
    }

    public init(
        title: String,
        startDate: Date,
        endDate: Date,
        category: EventCategory,
        isAllDay: Bool = false
    ) {
        self.id = UUID()
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.isAllDay = isAllDay
        self.category = category
        self.isRecurring = false
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}

public enum EventCategory: String, Codable, CaseIterable, Sendable {
    case custody
    case school
    case medical
    case sports
    case activities
    case birthday
    case holiday
    case appointment
    case exchange
    case other

    public var displayName: String {
        switch self {
        case .custody: L10n.eventCustody
        case .school: L10n.eventSchool
        case .medical: L10n.eventMedical
        case .sports: L10n.eventSports
        case .activities: L10n.eventActivities
        case .birthday: L10n.eventBirthday
        case .holiday: L10n.eventHoliday
        case .appointment: L10n.eventAppointment
        case .exchange: L10n.eventExchange
        case .other: L10n.eventOther
        }
    }

    public var icon: String {
        switch self {
        case .custody: "house.fill"
        case .school: "book.fill"
        case .medical: "cross.case.fill"
        case .sports: "sportscourt.fill"
        case .activities: "music.note"
        case .birthday: "birthday.cake.fill"
        case .holiday: "sun.max.fill"
        case .appointment: "calendar.badge.clock"
        case .exchange: "arrow.left.arrow.right"
        case .other: "calendar"
        }
    }

    public var color: String {
        switch self {
        case .custody: "CustodyBlue"
        case .school: "SchoolGreen"
        case .medical: "MedicalRed"
        case .sports: "SportsOrange"
        case .activities: "ActivityPurple"
        case .birthday: "BirthdayPink"
        case .holiday: "HolidayYellow"
        case .appointment: "AppointmentTeal"
        case .exchange: "ExchangeIndigo"
        case .other: "NeutralGray"
        }
    }
}
