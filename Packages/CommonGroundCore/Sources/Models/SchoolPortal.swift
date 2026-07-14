import Foundation
import SwiftData

@Model
public final class SchoolAnnouncement {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var body: String
    public var portalSource: String
    public var publishedAt: Date
    public var isRead: Bool
    public var createdAt: Date

    public var child: Child?

    public init(title: String, body: String, portalSource: String, publishedAt: Date = Date()) {
        self.id = UUID()
        self.title = title
        self.body = body
        self.portalSource = portalSource
        self.publishedAt = publishedAt
        self.isRead = false
        self.createdAt = Date()
    }
}

@Model
public final class SchoolAssignment {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var subject: String?
    public var dueDate: Date
    public var isCompleted: Bool
    public var portalSource: String
    public var createdAt: Date

    public var child: Child?

    public init(title: String, subject: String?, dueDate: Date, portalSource: String) {
        self.id = UUID()
        self.title = title
        self.subject = subject
        self.dueDate = dueDate
        self.isCompleted = false
        self.portalSource = portalSource
        self.createdAt = Date()
    }
}

public enum SchoolPortalType: String, CaseIterable, Codable, Sendable {
    case classDojo
    case googleClassroom
    case powerSchool
    case canvas

    public var displayName: String {
        switch self {
        case .classDojo: "ClassDojo"
        case .googleClassroom: "Google Classroom"
        case .powerSchool: "PowerSchool"
        case .canvas: "Canvas"
        }
    }

    public var icon: String {
        switch self {
        case .classDojo: "person.3.fill"
        case .googleClassroom: "graduationcap.fill"
        case .powerSchool: "building.columns.fill"
        case .canvas: "books.vertical.fill"
        }
    }
}
