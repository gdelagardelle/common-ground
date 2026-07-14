import Foundation
import SwiftData

@MainActor
public enum MedicalSetupService {
    @discardableResult
    public static func addMedication(
        context: ModelContext,
        child: Child,
        name: String,
        dosage: String,
        frequency: String,
        prescribedBy: String? = nil,
        reminderHour: Int = 8,
        reminderMinute: Int = 0
    ) throws -> Medication {
        let medication = Medication(name: name, dosage: dosage, frequency: frequency)
        medication.prescribedBy = prescribedBy?.nilIfEmpty
        medication.child = child

        var components = DateComponents()
        components.hour = reminderHour
        components.minute = reminderMinute
        if let reminder = Calendar.current.date(from: components) {
            medication.reminderTimes = [reminder]
        }

        child.medications.append(medication)
        context.insert(medication)
        try context.save()

        NotificationService.scheduleMedicationReminder(for: medication, childName: child.firstName)
        return medication
    }

    public static func deactivateMedication(_ medication: Medication, context: ModelContext) throws {
        medication.isActive = false
        medication.endDate = Date()
        try context.save()
    }

    @discardableResult
    public static func addMedicalRecord(
        context: ModelContext,
        child: Child,
        title: String,
        category: MedicalCategory,
        date: Date,
        provider: String? = nil,
        notes: String? = nil
    ) throws -> MedicalRecord {
        let record = MedicalRecord(title: title, category: category, date: date, provider: provider)
        record.notes = notes?.nilIfEmpty
        record.child = child
        child.medicalRecords.append(record)
        context.insert(record)
        try context.save()
        return record
    }
}

@MainActor
public enum DocumentSetupService {
    @discardableResult
    public static func addDocument(
        context: ModelContext,
        child: Child,
        title: String,
        category: DocumentCategory,
        fileData: Data?,
        fileName: String?,
        mimeType: String?,
        expiryDate: Date? = nil
    ) throws -> Document {
        let document = Document(title: title, category: category)
        document.fileData = fileData
        document.fileName = fileName
        document.mimeType = mimeType
        document.expiryDate = expiryDate
        document.child = child
        child.documents.append(document)
        context.insert(document)
        try context.save()
        return document
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
