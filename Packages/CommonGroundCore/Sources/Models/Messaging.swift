import Foundation
import SwiftData

@Model
public final class MessageThread {
    @Attribute(.unique) public var id: UUID
    public var subject: String?
    public var participantIds: [UUID]
    public var participantNames: [String]
    public var isPinned: Bool
    public var createdAt: Date
    public var lastMessageAt: Date

    @Relationship(deleteRule: .cascade, inverse: \Message.thread)
    public var messages: [Message]

    public init(participantIds: [UUID], participantNames: [String], subject: String? = nil) {
        self.id = UUID()
        self.subject = subject
        self.participantIds = participantIds
        self.participantNames = participantNames
        self.isPinned = false
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.messages = []
    }
}

@Model
public final class Message {
    @Attribute(.unique) public var id: UUID
    public var content: String
    public var senderId: UUID
    public var senderName: String
    public var sentAt: Date
    public var readAt: Date?
    public var attachmentType: MessageAttachmentType?
    public var attachmentData: Data?
    public var isImmutable: Bool
    public var auditHash: String?

    public var thread: MessageThread?

    public var isRead: Bool { readAt != nil }

    public init(content: String, senderId: UUID, senderName: String) {
        self.id = UUID()
        self.content = content
        self.senderId = senderId
        self.senderName = senderName
        self.sentAt = Date()
        self.isImmutable = true
        self.auditHash = Message.computeAuditHash(content: content, senderId: senderId, sentAt: Date())
    }

    public static func computeAuditHash(content: String, senderId: UUID, sentAt: Date) -> String {
        let payload = "\(content)|\(senderId.uuidString)|\(sentAt.timeIntervalSince1970)"
        return payload.data(using: .utf8)?.base64EncodedString() ?? ""
    }
}

public enum MessageAttachmentType: String, Codable, Sendable {
    case photo
    case video
    case voiceNote
    case document
}

@Model
public final class Checklist {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var childId: UUID?
    public var createdAt: Date
    public var updatedAt: Date

    @Relationship(deleteRule: .cascade, inverse: \ChecklistItem.checklist)
    public var items: [ChecklistItem]

    public var completedCount: Int {
        items.filter(\.isCompleted).count
    }

    public var progress: Double {
        guard !items.isEmpty else { return 0 }
        return Double(completedCount) / Double(items.count)
    }

    public init(title: String, childId: UUID? = nil) {
        self.id = UUID()
        self.title = title
        self.childId = childId
        self.createdAt = Date()
        self.updatedAt = Date()
        self.items = []
    }
}

@Model
public final class ChecklistItem {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var isCompleted: Bool
    public var completedAt: Date?
    public var sortOrder: Int
    public var createdAt: Date

    public var checklist: Checklist?

    public init(title: String, sortOrder: Int = 0) {
        self.id = UUID()
        self.title = title
        self.isCompleted = false
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
