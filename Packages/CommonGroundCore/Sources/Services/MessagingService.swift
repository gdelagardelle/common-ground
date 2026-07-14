import Foundation
import SwiftData

@MainActor
public enum MessagingService {
    public static func createThread(
        context: ModelContext,
        members: [FamilyMember],
        subject: String? = nil
    ) throws -> MessageThread {
        let thread = MessageThread(
            participantIds: members.map(\.id),
            participantNames: members.map(\.displayName),
            subject: subject?.nilIfEmpty
        )
        context.insert(thread)
        try context.save()
        return thread
    }

    public static func sendMessage(
        context: ModelContext,
        thread: MessageThread,
        content: String,
        sender: FamilyMember
    ) throws -> Message {
        let trimmed = content.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            throw MessagingError.emptyMessage
        }

        let message = Message(content: trimmed, senderId: sender.id, senderName: sender.displayName)
        message.thread = thread
        thread.messages.append(message)
        thread.lastMessageAt = message.sentAt
        context.insert(message)
        try context.save()
        return message
    }

    public static func markThreadRead(thread: MessageThread, readerId: UUID, context: ModelContext) throws {
        var updated = false
        for message in thread.messages where message.senderId != readerId && message.readAt == nil {
            message.readAt = Date()
            updated = true
        }
        if updated { try context.save() }
    }
}

public enum MessagingError: Error, LocalizedError {
    case emptyMessage
    case noSender

    public var errorDescription: String? {
        switch self {
        case .emptyMessage: "Message cannot be empty."
        case .noSender: "Could not identify the sender."
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
