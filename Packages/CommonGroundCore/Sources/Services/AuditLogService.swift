import Foundation
import SwiftData

public struct AuditEntry: Identifiable, Sendable {
    public let id: UUID
    public let title: String
    public let timestamp: Date
    public let actorName: String

    public init(id: UUID = UUID(), title: String, timestamp: Date, actorName: String) {
        self.id = id
        self.title = title
        self.timestamp = timestamp
        self.actorName = actorName
    }
}

@MainActor
public enum AuditLogService {
    public static func recentEntries(
        context: ModelContext,
        family: Family?,
        limit: Int = 50
    ) -> [AuditEntry] {
        guard let family else { return [] }

        var entries: [AuditEntry] = []
        let childIds = Set(family.children.map(\.id))

        let threadDescriptor = FetchDescriptor<MessageThread>()
        if let threads = try? context.fetch(threadDescriptor) {
            for thread in threads {
                for message in thread.messages {
                    entries.append(
                        AuditEntry(
                            id: message.id,
                            title: L10n.auditMessageSent,
                            timestamp: message.sentAt,
                            actorName: message.senderName
                        )
                    )
                }
            }
        }

        let expenseDescriptor = FetchDescriptor<Expense>()
        if let expenses = try? context.fetch(expenseDescriptor) {
            for expense in expenses where expense.child.map({ childIds.contains($0.id) }) ?? true {
                entries.append(
                    AuditEntry(
                        id: expense.id,
                        title: L10n.auditExpenseAdded,
                        timestamp: expense.createdAt,
                        actorName: expense.paidByName
                    )
                )
            }
        }

        let eventDescriptor = FetchDescriptor<CalendarEvent>()
        if let events = try? context.fetch(eventDescriptor) {
            for event in events where event.child.map({ childIds.contains($0.id) }) ?? true {
                let actor = event.assignedParentId.flatMap { parentId in
                    family.members.first(where: { $0.id == parentId })?.displayName
                } ?? family.members.first?.displayName ?? "—"

                entries.append(
                    AuditEntry(
                        id: event.id,
                        title: L10n.auditCalendarUpdated,
                        timestamp: event.updatedAt,
                        actorName: actor
                    )
                )
            }
        }

        let documentDescriptor = FetchDescriptor<Document>()
        if let documents = try? context.fetch(documentDescriptor) {
            for document in documents where document.child.map({ childIds.contains($0.id) }) ?? true {
                entries.append(
                    AuditEntry(
                        id: document.id,
                        title: L10n.auditDocumentUploaded,
                        timestamp: document.createdAt,
                        actorName: family.members.first?.displayName ?? "—"
                    )
                )
            }
        }

        return entries
            .sorted { $0.timestamp > $1.timestamp }
            .prefix(limit)
            .map { $0 }
    }
}
