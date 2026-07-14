import Foundation
import Observation

public struct AIQueryResult: Sendable {
    public let answer: String
    public let sources: [AISource]
    public let confidence: Double

    public init(answer: String, sources: [AISource] = [], confidence: Double = 1.0) {
        self.answer = answer
        self.sources = sources
        self.confidence = confidence
    }
}

public struct AISource: Sendable, Identifiable {
    public let id: UUID
    public let title: String
    public let category: String
    public let date: Date?

    public init(title: String, category: String, date: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.category = category
        self.date = date
    }
}

@Observable
@MainActor
public final class AIAssistantService {
    public var isProcessing = false
    public var conversationHistory: [(query: String, result: AIQueryResult)] = []

    public init() {}

    public func ask(_ query: String, context: AIContext) async -> AIQueryResult {
        isProcessing = true
        defer { isProcessing = false }

        if let onDeviceResult = await tryOnDeviceAnswer(query, context: context) {
            conversationHistory.append((query: query, result: onDeviceResult))
            return onDeviceResult
        }

        try? await Task.sleep(nanoseconds: 200_000_000)

        let result = Self.processQuery(query, context: context)
        conversationHistory.append((query: query, result: result))
        return result
    }

    private func tryOnDeviceAnswer(_ query: String, context: AIContext) async -> AIQueryResult? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            guard OnDeviceAIService.isAvailable else { return nil }
            let summary = AIContextBuilder.buildSummary(from: context)
            do {
                let answer = try await OnDeviceAIService.answer(query: query, contextSummary: summary)
                return AIQueryResult(
                    answer: answer,
                    sources: [AISource(title: "On-device model", category: "Apple Intelligence", date: nil)],
                    confidence: 0.92
                )
            } catch {
                return nil
            }
        }
        #endif
        return nil
    }

    private static func processQuery(_ query: String, context: AIContext) -> AIQueryResult {
        let lowered = query.lowercased()

        if let specialized = specializedAnswer(for: lowered, context: context) {
            return specialized
        }

        if let searchResult = searchAllData(query: lowered, context: context) {
            return searchResult
        }

        return AIQueryResult(
            answer: "I searched calendar, expenses, medical records, documents, messages, and timeline but couldn't find a match for \"\(query)\". Try being more specific — e.g. \"When is the next exchange?\" or \"Show unpaid expenses.\"",
            confidence: 0.4
        )
    }

    private static func specializedAnswer(for lowered: String, context: AIContext) -> AIQueryResult? {
        if lowered.contains("dentist") || lowered.contains("dental") {
            return dentalAnswer(context: context)
        }
        if lowered.contains("unpaid") || lowered.contains("outstanding") || lowered.contains("owe") {
            return unpaidAnswer(context: context)
        }
        if lowered.contains("exchange") || lowered.contains("pickup") {
            return exchangeAnswer(context: context)
        }
        if lowered.contains("custody") && (lowered.contains("who") || lowered.contains("with")) {
            return custodyAnswer(context: context)
        }
        if lowered.contains("passport") {
            return passportAnswer(context: context)
        }
        if lowered.contains("medication") || lowered.contains("medicine") {
            return medicationAnswer(context: context)
        }
        if lowered.contains("allerg") {
            return allergyAnswer(context: context)
        }
        if lowered.contains("school") && (lowered.contains("what") || lowered.contains("where") || lowered.contains("name")) {
            return schoolAnswer(context: context)
        }
        if lowered.contains("paid") || lowered.contains("expense") || lowered.contains("cost") {
            if let expenseAnswer = expenseSearch(lowered: lowered, context: context) {
                return expenseAnswer
            }
        }
        return nil
    }

    private static func searchAllData(query: String, context: AIContext) -> AIQueryResult? {
        let tokens = query.split(separator: " ").map(String.init).filter { $0.count > 2 }
        guard !tokens.isEmpty else { return nil }

        let scored = context.searchableItems.map { item -> (SearchableItem, Int) in
            let haystack = item.body.lowercased()
            let score = tokens.reduce(0) { $0 + (haystack.contains($1) ? 1 : 0) }
            return (item, score)
        }
        .filter { $0.1 > 0 }
        .sorted { $0.1 > $1.1 }

        let best = Array(scored.prefix(5).map(\.0))
        guard !best.isEmpty else { return nil }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium

        if best.count == 1, let item = best.first {
            var answer = "Found in \(item.category): \(item.title)"
            if let detail = item.detail, !detail.isEmpty { answer += " — \(detail)" }
            if let date = item.date { answer += " (\(formatter.string(from: date)))" }
            return AIQueryResult(
                answer: answer,
                sources: [AISource(title: item.title, category: item.category, date: item.date)],
                confidence: 0.85
            )
        }

        let summary = best.prefix(3).map { item -> String in
            if let date = item.date {
                return "• \(item.title) (\(formatter.string(from: date)))"
            }
            return "• \(item.title)"
        }.joined(separator: "\n")

        return AIQueryResult(
            answer: "I found \(best.count) matches:\n\(summary)",
            sources: best.prefix(5).map { AISource(title: $0.title, category: $0.category, date: $0.date) },
            confidence: 0.75
        )
    }

    private static func dentalAnswer(context: AIContext) -> AIQueryResult {
        if let record = context.medicalRecords.filter({ $0.category == .dental }).sorted(by: { $0.date > $1.date }).first {
            let f = DateFormatter(); f.dateStyle = .medium
            return AIQueryResult(
                answer: "\(context.childName)'s last dental visit was \(f.string(from: record.date))\(record.provider.map { " at \($0)" } ?? "").",
                sources: [AISource(title: record.title, category: "Medical", date: record.date)],
                confidence: 0.95
            )
        }
        return AIQueryResult(answer: "No dental records for \(context.childName) yet.", confidence: 0.9)
    }

    private static func unpaidAnswer(context: AIContext) -> AIQueryResult {
        let unpaid = context.expenses.filter { !$0.isReimbursed }
        let total = unpaid.reduce(Decimal.zero) { $0 + $1.owedAmount }
        if unpaid.isEmpty {
            return AIQueryResult(answer: "All expenses are settled. No outstanding balances.", confidence: 1.0)
        }
        let formatted = String(format: "%.2f", NSDecimalNumber(decimal: total).doubleValue)
        return AIQueryResult(
            answer: "\(unpaid.count) unpaid expense\(unpaid.count == 1 ? "" : "s") totaling $\(formatted).",
            sources: unpaid.map { AISource(title: $0.title, category: "Expense", date: $0.date) },
            confidence: 0.98
        )
    }

    private static func exchangeAnswer(context: AIContext) -> AIQueryResult {
        if let event = context.upcomingEvents.first(where: { $0.category == .exchange }) {
            let f = DateFormatter(); f.dateStyle = .full; f.timeStyle = .short
            return AIQueryResult(
                answer: "Next exchange: \(event.title) on \(f.string(from: event.startDate)).",
                sources: [AISource(title: event.title, category: "Calendar", date: event.startDate)],
                confidence: 0.92
            )
        }
        return AIQueryResult(answer: "No upcoming custody exchanges on the calendar.", confidence: 0.85)
    }

    private static func custodyAnswer(context: AIContext) -> AIQueryResult {
        if let event = context.upcomingEvents.first(where: { $0.category == .custody }) {
            let f = DateFormatter(); f.dateStyle = .medium
            return AIQueryResult(
                answer: "\(context.childName) is scheduled with \(event.title.replacingOccurrences(of: "With ", with: "")) starting \(f.string(from: event.startDate)).",
                sources: [AISource(title: event.title, category: "Custody", date: event.startDate)],
                confidence: 0.88
            )
        }
        return AIQueryResult(answer: "No custody blocks found on the calendar.", confidence: 0.8)
    }

    private static func passportAnswer(context: AIContext) -> AIQueryResult {
        if let passport = context.documents.first(where: { $0.category == .passport }), let expiry = passport.expiryDate {
            let f = DateFormatter(); f.dateStyle = .long
            return AIQueryResult(
                answer: "\(context.childName)'s passport expires \(f.string(from: expiry)).",
                sources: [AISource(title: passport.title, category: "Document", date: expiry)],
                confidence: 0.97
            )
        }
        return AIQueryResult(answer: "No passport on file for \(context.childName).", confidence: 0.9)
    }

    private static func medicationAnswer(context: AIContext) -> AIQueryResult {
        let active = context.medications.filter(\.isActive)
        if active.isEmpty {
            return AIQueryResult(answer: "\(context.childName) has no active medications.", confidence: 0.95)
        }
        let list = active.map { "\($0.name) (\($0.dosage))" }.joined(separator: ", ")
        return AIQueryResult(
            answer: "Active medications: \(list).",
            sources: active.map { AISource(title: $0.name, category: "Medication", date: $0.startDate) },
            confidence: 0.96
        )
    }

    private static func allergyAnswer(context: AIContext) -> AIQueryResult {
        if context.allergies.isEmpty {
            return AIQueryResult(answer: "No allergies recorded for \(context.childName).", confidence: 0.95)
        }
        return AIQueryResult(
            answer: "\(context.childName)'s allergies: \(context.allergies.joined(separator: ", ")).",
            sources: [AISource(title: "Allergies", category: "Medical", date: nil)],
            confidence: 0.98
        )
    }

    private static func schoolAnswer(context: AIContext) -> AIQueryResult {
        if let school = context.schoolName {
            return AIQueryResult(
                answer: "\(context.childName) attends \(school).",
                sources: [AISource(title: school, category: "School", date: nil)],
                confidence: 0.95
            )
        }
        return AIQueryResult(answer: "No school information on file.", confidence: 0.9)
    }

    private static func expenseSearch(lowered: String, context: AIContext) -> AIQueryResult? {
        let sports = context.expenses.filter { $0.category == .sports || lowered.contains("sport") || lowered.contains("football") || lowered.contains("soccer") }
        if let latest = sports.sorted(by: { $0.date > $1.date }).first {
            let f = DateFormatter(); f.dateStyle = .medium
            let amount = String(format: "%.2f", NSDecimalNumber(decimal: latest.amount).doubleValue)
            return AIQueryResult(
                answer: "\(latest.paidByName) paid $\(amount) for \(latest.title) on \(f.string(from: latest.date)).",
                sources: [AISource(title: latest.title, category: "Expense", date: latest.date)],
                confidence: 0.94
            )
        }
        return nil
    }
}

public struct AIContext: Sendable {
    public let childName: String
    public let medicalRecords: [MedicalRecordSnapshot]
    public let expenses: [ExpenseSnapshot]
    public let upcomingEvents: [EventSnapshot]
    public let pastEvents: [EventSnapshot]
    public let documents: [DocumentSnapshot]
    public let medications: [MedicationSnapshot]
    public let messages: [MessageSnapshot]
    public let timeline: [TimelineSnapshot]
    public let allergies: [String]
    public let schoolName: String?
    public let searchableItems: [SearchableItem]

    public init(
        childName: String,
        medicalRecords: [MedicalRecordSnapshot] = [],
        expenses: [ExpenseSnapshot] = [],
        upcomingEvents: [EventSnapshot] = [],
        pastEvents: [EventSnapshot] = [],
        documents: [DocumentSnapshot] = [],
        medications: [MedicationSnapshot] = [],
        messages: [MessageSnapshot] = [],
        timeline: [TimelineSnapshot] = [],
        allergies: [String] = [],
        schoolName: String? = nil,
        searchableItems: [SearchableItem] = []
    ) {
        self.childName = childName
        self.medicalRecords = medicalRecords
        self.expenses = expenses
        self.upcomingEvents = upcomingEvents
        self.pastEvents = pastEvents
        self.documents = documents
        self.medications = medications
        self.messages = messages
        self.timeline = timeline
        self.allergies = allergies
        self.schoolName = schoolName
        self.searchableItems = searchableItems
    }
}

public struct MedicalRecordSnapshot: Sendable {
    public let title: String
    public let category: MedicalCategory
    public let date: Date
    public let provider: String?

    public init(title: String, category: MedicalCategory, date: Date, provider: String? = nil) {
        self.title = title
        self.category = category
        self.date = date
        self.provider = provider
    }
}

public struct ExpenseSnapshot: Sendable {
    public let title: String
    public let amount: Decimal
    public let category: ExpenseCategory
    public let paidByName: String
    public let isReimbursed: Bool
    public let owedAmount: Decimal
    public let date: Date

    public init(
        title: String,
        amount: Decimal,
        category: ExpenseCategory,
        paidByName: String,
        isReimbursed: Bool,
        owedAmount: Decimal,
        date: Date
    ) {
        self.title = title
        self.amount = amount
        self.category = category
        self.paidByName = paidByName
        self.isReimbursed = isReimbursed
        self.owedAmount = owedAmount
        self.date = date
    }
}

public struct EventSnapshot: Sendable {
    public let title: String
    public let category: EventCategory
    public let startDate: Date

    public init(title: String, category: EventCategory, startDate: Date) {
        self.title = title
        self.category = category
        self.startDate = startDate
    }
}

public struct DocumentSnapshot: Sendable {
    public let title: String
    public let category: DocumentCategory
    public let expiryDate: Date?

    public init(title: String, category: DocumentCategory, expiryDate: Date? = nil) {
        self.title = title
        self.category = category
        self.expiryDate = expiryDate
    }
}

public struct MedicationSnapshot: Sendable {
    public let name: String
    public let dosage: String
    public let isActive: Bool
    public let startDate: Date

    public init(name: String, dosage: String = "", isActive: Bool, startDate: Date) {
        self.name = name
        self.dosage = dosage
        self.isActive = isActive
        self.startDate = startDate
    }
}
