import Foundation
import SwiftData

@MainActor
public enum AIContextBuilder {
    public static func build(from child: Child, allEvents: [CalendarEvent], allThreads: [MessageThread]) -> AIContext {
        let messages = allThreads.flatMap { thread in
            thread.messages.map { message in
                MessageSnapshot(
                    content: message.content,
                    senderName: message.senderName,
                    sentAt: message.sentAt,
                    threadSubject: thread.subject
                )
            }
        }

        let timeline = child.timelineEntries.map {
            TimelineSnapshot(title: $0.title, detail: $0.detail, category: $0.category.displayName, date: $0.date)
        }

        let searchable = buildSearchIndex(child: child, events: allEvents, messages: messages, timeline: timeline)

        return AIContext(
            childName: child.firstName,
            medicalRecords: child.medicalRecords.map {
                MedicalRecordSnapshot(title: $0.title, category: $0.category, date: $0.date, provider: $0.provider)
            },
            expenses: child.expenses.map {
                ExpenseSnapshot(
                    title: $0.title,
                    amount: $0.amount,
                    category: $0.category,
                    paidByName: $0.paidByName,
                    isReimbursed: $0.isReimbursed,
                    owedAmount: $0.owedAmount,
                    date: $0.date
                )
            },
            upcomingEvents: allEvents.filter { $0.child?.id == child.id && $0.startDate >= Date() }.map {
                EventSnapshot(title: $0.title, category: $0.category, startDate: $0.startDate)
            },
            pastEvents: allEvents.filter { $0.child?.id == child.id && $0.startDate < Date() }.map {
                EventSnapshot(title: $0.title, category: $0.category, startDate: $0.startDate)
            },
            documents: child.documents.map {
                DocumentSnapshot(title: $0.title, category: $0.category, expiryDate: $0.expiryDate)
            },
            medications: child.medications.map {
                MedicationSnapshot(name: $0.name, dosage: $0.dosage, isActive: $0.isActive, startDate: $0.startDate)
            },
            messages: messages,
            timeline: timeline,
            allergies: child.allergies,
            schoolName: child.schoolInfo?.schoolName,
            searchableItems: searchable
        )
    }

    private static func buildSearchIndex(
        child: Child,
        events: [CalendarEvent],
        messages: [MessageSnapshot],
        timeline: [TimelineSnapshot]
    ) -> [SearchableItem] {
        var items: [SearchableItem] = []

        for event in events where event.child?.id == child.id {
            items.append(SearchableItem(
                title: event.title,
                detail: event.location,
                category: "Calendar · \(event.category.displayName)",
                date: event.startDate,
                body: "\(event.title) \(event.category.displayName) \(event.location ?? "")"
            ))
        }

        for expense in child.expenses {
            items.append(SearchableItem(
                title: expense.title,
                detail: "Paid by \(expense.paidByName)",
                category: "Expense · \(expense.category.displayName)",
                date: expense.date,
                body: "\(expense.title) \(expense.paidByName) \(expense.category.displayName)"
            ))
        }

        for record in child.medicalRecords {
            items.append(SearchableItem(
                title: record.title,
                detail: record.provider,
                category: "Medical · \(record.category.displayName)",
                date: record.date,
                body: "\(record.title) \(record.category.displayName) \(record.provider ?? "")"
            ))
        }

        for doc in child.documents {
            items.append(SearchableItem(
                title: doc.title,
                detail: doc.category.displayName,
                category: "Document",
                date: doc.expiryDate,
                body: doc.title
            ))
        }

        for message in messages {
            items.append(SearchableItem(
                title: message.content,
                detail: message.senderName,
                category: "Message",
                date: message.sentAt,
                body: message.content
            ))
        }

        for entry in timeline {
            items.append(SearchableItem(
                title: entry.title,
                detail: entry.detail,
                category: "Timeline · \(entry.category)",
                date: entry.date,
                body: "\(entry.title) \(entry.detail ?? "")"
            ))
        }

        return items
    }

    public static func buildSummary(from context: AIContext) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        var sections: [String] = ["Child: \(context.childName)"]

        if !context.allergies.isEmpty {
            sections.append("Allergies: \(context.allergies.joined(separator: ", "))")
        }
        if let school = context.schoolName {
            sections.append("School: \(school)")
        }

        if !context.medications.isEmpty {
            let meds = context.medications.filter(\.isActive).map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
            sections.append("Active medications: \(meds.isEmpty ? "None" : meds)")
        }

        if !context.upcomingEvents.isEmpty {
            let events = context.upcomingEvents.prefix(8).map {
                "\($0.title) · \($0.category.displayName) · \(formatter.string(from: $0.startDate))"
            }.joined(separator: "\n")
            sections.append("Upcoming events:\n\(events)")
        }

        if !context.expenses.isEmpty {
            let unpaid = context.expenses.filter { !$0.isReimbursed }
            let total = unpaid.reduce(Decimal.zero) { $0 + $1.owedAmount }
            let totalText = String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
            sections.append("Unpaid expenses: \(unpaid.count) totaling $\(totalText)")
            let recent = context.expenses.prefix(5).map {
                "\($0.title) $\(String(format: "%.2f", NSDecimalNumber(decimal: $0.amount).doubleValue)) paid by \($0.paidByName)"
            }.joined(separator: "\n")
            sections.append("Recent expenses:\n\(recent)")
        }

        if !context.medicalRecords.isEmpty {
            let records = context.medicalRecords.prefix(5).map {
                "\($0.title) (\($0.category.displayName)) \(formatter.string(from: $0.date))"
            }.joined(separator: "\n")
            sections.append("Medical records:\n\(records)")
        }

        if !context.documents.isEmpty {
            let docs = context.documents.prefix(5).map { doc -> String in
                if let expiry = doc.expiryDate {
                    return "\(doc.title) expires \(formatter.string(from: expiry))"
                }
                return doc.title
            }.joined(separator: "\n")
            sections.append("Documents:\n\(docs)")
        }

        if !context.messages.isEmpty {
            let msgs = context.messages.suffix(5).map { "\($0.senderName): \($0.content)" }.joined(separator: "\n")
            sections.append("Recent messages:\n\(msgs)")
        }

        return sections.joined(separator: "\n\n")
    }
}

public struct MessageSnapshot: Sendable {
    public let content: String
    public let senderName: String
    public let sentAt: Date
    public let threadSubject: String?
}

public struct TimelineSnapshot: Sendable {
    public let title: String
    public let detail: String?
    public let category: String
    public let date: Date
}

public struct SearchableItem: Sendable {
    public let title: String
    public let detail: String?
    public let category: String
    public let date: Date?
    public let body: String

    public init(title: String, detail: String?, category: String, date: Date?, body: String) {
        self.title = title
        self.detail = detail
        self.category = category
        self.date = date
        self.body = body
    }
}
