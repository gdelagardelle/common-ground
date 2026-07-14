import Foundation
import SwiftData

public enum SchoolPortalPreferences {
    private static let portalTypeKey = "school.portal.type"
    private static let lastSyncKey = "school.portal.lastSync"

    public static var connectedPortal: SchoolPortalType? {
        get {
            guard let raw = UserDefaults.standard.string(forKey: portalTypeKey) else { return nil }
            return SchoolPortalType(rawValue: raw)
        }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue.rawValue, forKey: portalTypeKey)
            } else {
                UserDefaults.standard.removeObject(forKey: portalTypeKey)
            }
        }
    }

    public static var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: lastSyncKey) as? Date }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: lastSyncKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSyncKey)
            }
        }
    }
}

public struct SchoolPortalSyncResult: Sendable {
    public let announcementsImported: Int
    public let assignmentsImported: Int

    public init(announcementsImported: Int, assignmentsImported: Int) {
        self.announcementsImported = announcementsImported
        self.assignmentsImported = assignmentsImported
    }
}

@MainActor
public enum SchoolPortalService {
    public static func connect(_ portal: SchoolPortalType) {
        SchoolPortalPreferences.connectedPortal = portal
    }

    public static func disconnect() {
        SchoolPortalPreferences.connectedPortal = nil
        SchoolPortalPreferences.lastSyncDate = nil
    }

    public static func sync(
        context: ModelContext,
        child: Child,
        portal: SchoolPortalType? = SchoolPortalPreferences.connectedPortal
    ) throws -> SchoolPortalSyncResult {
        guard let portal else {
            return SchoolPortalSyncResult(announcementsImported: 0, assignmentsImported: 0)
        }

        let existingAnnouncementTitles = Set(child.schoolAnnouncements.map(\.title))
        let existingAssignmentTitles = Set(child.schoolAssignments.map(\.title))

        var announcementsImported = 0
        var assignmentsImported = 0

        for item in mockAnnouncements(for: child, portal: portal) where !existingAnnouncementTitles.contains(item.title) {
            let announcement = SchoolAnnouncement(
                title: item.title,
                body: item.body,
                portalSource: portal.displayName,
                publishedAt: item.date
            )
            announcement.child = child
            child.schoolAnnouncements.append(announcement)
            context.insert(announcement)
            announcementsImported += 1
        }

        for item in mockAssignments(for: child, portal: portal) where !existingAssignmentTitles.contains(item.title) {
            let assignment = SchoolAssignment(
                title: item.title,
                subject: item.subject,
                dueDate: item.dueDate,
                portalSource: portal.displayName
            )
            assignment.child = child
            child.schoolAssignments.append(assignment)
            context.insert(assignment)
            assignmentsImported += 1
        }

        if announcementsImported > 0 || assignmentsImported > 0 {
            try context.save()
        }

        SchoolPortalPreferences.lastSyncDate = Date()
        return SchoolPortalSyncResult(
            announcementsImported: announcementsImported,
            assignmentsImported: assignmentsImported
        )
    }

    private struct MockAnnouncement {
        let title: String
        let body: String
        let date: Date
    }

    private struct MockAssignment {
        let title: String
        let subject: String?
        let dueDate: Date
    }

    private static func mockAnnouncements(for child: Child, portal: SchoolPortalType) -> [MockAnnouncement] {
        let school = child.schoolInfo?.schoolName ?? "school"
        let calendar = Calendar.current
        return [
            MockAnnouncement(
                title: "Early dismissal Friday",
                body: "\(school) dismisses at 1:30 PM this Friday for teacher in-service. Pick-up at the usual location.",
                date: calendar.date(byAdding: .day, value: -1, to: Date()) ?? Date()
            ),
            MockAnnouncement(
                title: "Field trip permission due",
                body: "Please sign the science museum permission slip by Thursday. Uploaded via \(portal.displayName).",
                date: calendar.date(byAdding: .day, value: -2, to: Date()) ?? Date()
            ),
            MockAnnouncement(
                title: "Parent-teacher conferences",
                body: "Sign up for a 15-minute slot next week. Slots are first-come on \(portal.displayName).",
                date: calendar.date(byAdding: .day, value: -3, to: Date()) ?? Date()
            ),
        ]
    }

    private static func mockAssignments(for child: Child, portal: SchoolPortalType) -> [MockAssignment] {
        let calendar = Calendar.current
        let grade = child.schoolInfo?.grade ?? "class"
        return [
            MockAssignment(
                title: "Math worksheet — fractions",
                subject: "Math",
                dueDate: calendar.date(byAdding: .day, value: 2, to: Date()) ?? Date()
            ),
            MockAssignment(
                title: "Read chapter 4 and summarize",
                subject: "Reading",
                dueDate: calendar.date(byAdding: .day, value: 4, to: Date()) ?? Date()
            ),
            MockAssignment(
                title: "\(grade) spelling list — test Friday",
                subject: "Language Arts",
                dueDate: calendar.date(byAdding: .day, value: 5, to: Date()) ?? Date()
            ),
        ]
    }
}

@MainActor
public enum SchoolSetupService {
    @discardableResult
    public static func addOrUpdateSchoolInfo(
        context: ModelContext,
        child: Child,
        schoolName: String,
        grade: String? = nil,
        classroom: String? = nil,
        phone: String? = nil,
        address: String? = nil
    ) throws -> SchoolInfo {
        let school: SchoolInfo
        if let existing = child.schoolInfo {
            school = existing
        } else {
            school = SchoolInfo(schoolName: schoolName)
            school.child = child
            child.schoolInfo = school
            context.insert(school)
        }

        school.schoolName = schoolName
        school.grade = grade?.nilIfEmpty
        school.classroom = classroom?.nilIfEmpty
        school.schoolPhone = phone?.nilIfEmpty
        school.schoolAddress = address?.nilIfEmpty
        school.updatedAt = Date()
        child.updatedAt = Date()

        try context.save()
        return school
    }

    @discardableResult
    public static func addTeacher(
        context: ModelContext,
        school: SchoolInfo,
        name: String,
        role: String? = nil,
        phone: String? = nil,
        email: String? = nil
    ) throws -> Contact {
        let contact = Contact(name: name, role: role, phone: phone)
        contact.email = email?.nilIfEmpty
        contact.schoolInfo = school
        school.teachers.append(contact)
        context.insert(contact)
        try context.save()
        return contact
    }

    public static func markAssignmentComplete(_ assignment: SchoolAssignment, context: ModelContext) throws {
        assignment.isCompleted = true
        try context.save()
    }

    public static func markAnnouncementRead(_ announcement: SchoolAnnouncement, context: ModelContext) throws {
        announcement.isRead = true
        try context.save()
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
