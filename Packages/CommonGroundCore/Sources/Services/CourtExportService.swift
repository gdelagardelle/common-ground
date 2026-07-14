#if canImport(UIKit)
import Foundation
import SwiftData
import UIKit
import CryptoKit

public struct CourtExportOptions: Sendable {
    public var rangeMonths: Int?
    public var includeMessages: Bool
    public var includeExpenses: Bool
    public var includeCalendar: Bool
    public var includeMedical: Bool
    public var includeDocuments: Bool

    public init(
        rangeMonths: Int? = 12,
        includeMessages: Bool = true,
        includeExpenses: Bool = true,
        includeCalendar: Bool = true,
        includeMedical: Bool = true,
        includeDocuments: Bool = true
    ) {
        self.rangeMonths = rangeMonths
        self.includeMessages = includeMessages
        self.includeExpenses = includeExpenses
        self.includeCalendar = includeCalendar
        self.includeMedical = includeMedical
        self.includeDocuments = includeDocuments
    }
}

@MainActor
public enum CourtExportService {
    public static func generatePDF(
        context: ModelContext,
        family: Family,
        threads: [MessageThread] = [],
        options: CourtExportOptions
    ) throws -> URL {
        let cutoff = cutoffDate(for: options.rangeMonths)
        let content = buildReportContent(family: family, threads: threads, cutoff: cutoff, options: options)
        let signature = content.signatureHash

        let pdfData = renderPDF(title: family.name, body: content.text, signature: signature)
        return try write(data: pdfData, filename: "CommonGround-Report-\(timestamp()).pdf")
    }

    public static func generateJSON(
        context: ModelContext,
        family: Family,
        options: CourtExportOptions
    ) throws -> URL {
        let cutoff = cutoffDate(for: options.rangeMonths)
        let payload = ExportPayload(family: family, cutoff: cutoff, options: options)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        return try write(data: data, filename: "CommonGround-Export-\(timestamp()).json")
    }

    private static func cutoffDate(for rangeMonths: Int?) -> Date? {
        guard let months = rangeMonths else { return nil }
        return Calendar.current.date(byAdding: .month, value: -months, to: Date())
    }

    private static func buildReportContent(
        family: Family,
        threads: [MessageThread],
        cutoff: Date?,
        options: CourtExportOptions
    ) -> (text: String, signatureHash: String) {
        var lines: [String] = []
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        lines.append("COMMON GROUND — FAMILY RECORD EXPORT")
        lines.append("Generated: \(formatter.string(from: Date()))")
        lines.append("Family: \(family.name)")
        lines.append("Export hash: pending")
        lines.append(String(repeating: "─", count: 52))
        lines.append("")

        for child in family.children {
            lines.append("CHILD: \(child.fullName)")
            lines.append("Date of birth: \(formatter.string(from: child.dateOfBirth))")
            if !child.allergies.isEmpty {
                lines.append("Allergies: \(child.allergies.joined(separator: ", "))")
            }
            lines.append("")

            if options.includeCalendar {
                lines.append("CALENDAR EVENTS")
                let events = child.events
                    .filter { event in cutoff.map { event.startDate >= $0 } ?? true }
                    .sorted(by: { $0.startDate > $1.startDate })
                if events.isEmpty {
                    lines.append("  (none)")
                } else {
                    for event in events {
                        lines.append("  • \(formatter.string(from: event.startDate)) — \(event.title) [\(event.category.displayName)]")
                    }
                }
                lines.append("")
            }

            if options.includeExpenses {
                lines.append("EXPENSES")
                let expenses = child.expenses
                    .filter { expense in cutoff.map { expense.date >= $0 } ?? true }
                    .sorted(by: { $0.date > $1.date })
                if expenses.isEmpty {
                    lines.append("  (none)")
                } else {
                    for expense in expenses {
                        let status = expense.isReimbursed ? "Settled" : "Pending"
                        let amount = NSDecimalNumber(decimal: expense.amount).doubleValue
                        lines.append("  • \(formatter.string(from: expense.date)) — \(expense.title): $\(String(format: "%.2f", amount)) paid by \(expense.paidByName) [\(status)]")
                    }
                }
                lines.append("")
            }

            if options.includeMedical {
                lines.append("MEDICAL RECORDS")
                let records = child.medicalRecords
                    .filter { record in cutoff.map { record.date >= $0 } ?? true }
                    .sorted(by: { $0.date > $1.date })
                if records.isEmpty {
                    lines.append("  (none)")
                } else {
                    for record in records {
                        lines.append("  • \(formatter.string(from: record.date)) — \(record.title) [\(record.category.displayName)]")
                    }
                }
                lines.append("")

                let meds = child.medications.filter(\.isActive)
                if !meds.isEmpty {
                    lines.append("ACTIVE MEDICATIONS")
                    for med in meds {
                        lines.append("  • \(med.name) \(med.dosage) — \(med.frequency)")
                    }
                    lines.append("")
                }
            }

            if options.includeDocuments {
                lines.append("DOCUMENTS")
                if child.documents.isEmpty {
                    lines.append("  (none)")
                } else {
                    for doc in child.documents {
                        var line = "  • \(doc.title) [\(doc.category.displayName)]"
                        if let expiry = doc.expiryDate {
                            line += " expires \(formatter.string(from: expiry))"
                        }
                        lines.append(line)
                    }
                }
                lines.append("")
            }
        }

        if options.includeMessages {
            lines.append("MESSAGES")
            lines.append("(Immutable, timestamped records)")
            let allMessages = threads.flatMap { thread in
                thread.messages.map { (thread: thread, message: $0) }
            }.filter { item in cutoff.map { item.message.sentAt >= $0 } ?? true }
            .sorted(by: { $0.message.sentAt > $1.message.sentAt })

            if allMessages.isEmpty {
                lines.append("  (none)")
            } else {
                for item in allMessages {
                    lines.append("  • \(formatter.string(from: item.message.sentAt)) — \(item.message.senderName): \(item.message.content)")
                }
            }
            lines.append("")
        }

        let body = lines.joined(separator: "\n")
        let hash = SHA256.hash(data: Data(body.utf8)).compactMap { String(format: "%02x", $0) }.joined()
        let signed = body.replacingOccurrences(of: "Export hash: pending", with: "Export hash: \(hash.prefix(16))")
        return (signed, hash)
    }

    private static func renderPDF(title: String, body: String, signature: String) -> Data {
        let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792)
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect)

        return renderer.pdfData { context in
            context.beginPage()
            let margin: CGFloat = 48
            var y = margin

            let titleAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 20, weight: .bold),
            ]
            let bodyAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
            ]
            let footerAttributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 9),
                .foregroundColor: UIColor.secondaryLabel,
            ]

            title.draw(at: CGPoint(x: margin, y: y), withAttributes: titleAttributes)
            y += 32

            let textRect = CGRect(x: margin, y: y, width: pageRect.width - margin * 2, height: pageRect.height - y - 60)
            body.draw(in: textRect, withAttributes: bodyAttributes)

            let footer = "SHA-256: \(signature.prefix(32))… · Generated by Common Ground"
            footer.draw(at: CGPoint(x: margin, y: pageRect.height - 40), withAttributes: footerAttributes)
        }
    }

    private static func write(data: Data, filename: String) throws -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func timestamp() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd-HHmm"
        return f.string(from: Date())
    }
}

private struct ExportPayload: Codable {
    let exportedAt: Date
    let familyName: String
    let children: [ExportChild]

    init(family: Family, cutoff: Date?, options: CourtExportOptions) {
        exportedAt = Date()
        familyName = family.name
        children = family.children.map { ExportChild(child: $0, cutoff: cutoff, options: options) }
    }
}

private struct ExportChild: Codable {
    let name: String
    let dateOfBirth: Date
    let allergies: [String]
    let events: [ExportEvent]
    let expenses: [ExportExpense]
    let medicalRecords: [ExportMedical]
    let documents: [ExportDocument]

    init(child: Child, cutoff: Date?, options: CourtExportOptions) {
        name = child.fullName
        dateOfBirth = child.dateOfBirth
        allergies = child.allergies
        events = options.includeCalendar
            ? child.events.filter { event in cutoff.map { event.startDate >= $0 } ?? true }.map(ExportEvent.init)
            : []
        expenses = options.includeExpenses
            ? child.expenses.filter { expense in cutoff.map { expense.date >= $0 } ?? true }.map(ExportExpense.init)
            : []
        medicalRecords = options.includeMedical
            ? child.medicalRecords.filter { record in cutoff.map { record.date >= $0 } ?? true }.map(ExportMedical.init)
            : []
        documents = options.includeDocuments
            ? child.documents.map(ExportDocument.init)
            : []
    }
}

private struct ExportEvent: Codable {
    let title: String
    let category: String
    let startDate: Date
    init(_ event: CalendarEvent) {
        title = event.title
        category = event.category.displayName
        startDate = event.startDate
    }
}

private struct ExportExpense: Codable {
    let title: String
    let amount: Double
    let paidBy: String
    let isReimbursed: Bool
    let date: Date
    init(_ expense: Expense) {
        title = expense.title
        amount = NSDecimalNumber(decimal: expense.amount).doubleValue
        paidBy = expense.paidByName
        isReimbursed = expense.isReimbursed
        date = expense.date
    }
}

private struct ExportMedical: Codable {
    let title: String
    let category: String
    let date: Date
    init(_ record: MedicalRecord) {
        title = record.title
        category = record.category.displayName
        date = record.date
    }
}

private struct ExportDocument: Codable {
    let title: String
    let category: String
    let expiryDate: Date?
    init(_ doc: Document) {
        title = doc.title
        category = doc.category.displayName
        expiryDate = doc.expiryDate
    }
}
#endif
