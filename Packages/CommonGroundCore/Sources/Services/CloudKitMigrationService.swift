import Foundation
import SwiftData
import os

public struct CloudKitMigrationResult: Sendable {
    public let recordsCopied: Int
    public let skippedBecauseAlreadyMigrated: Bool

    public init(recordsCopied: Int, skippedBecauseAlreadyMigrated: Bool = false) {
        self.recordsCopied = recordsCopied
        self.skippedBecauseAlreadyMigrated = skippedBecauseAlreadyMigrated
    }
}

public enum CloudKitMigrationError: LocalizedError {
    case cloudKitUnavailable
    case notSignedInToiCloud
    case migrationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .cloudKitUnavailable:
            L10n.cloudErrorUnavailable
        case .notSignedInToiCloud:
            L10n.cloudErrorNotSignedIn
        case .migrationFailed(let message):
            L10n.format("sync.migration.failed", message)
        }
    }
}

public enum CloudKitMigrationService {
    private static let logger = Logger(subsystem: AppIdentifiers.bundleID, category: "CloudKitMigration")
    private static let migrationCompletedKey = "sync.localMigrationCompleted"

    private static var isSignedInToiCloud: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    public static var isMigrationCompleted: Bool {
        get { SharedPreferences.defaults.bool(forKey: migrationCompletedKey) }
        set { SharedPreferences.defaults.set(newValue, forKey: migrationCompletedKey) }
    }

    /// Runs after the app is using the CloudKit-backed container.
    @MainActor
    public static func migrateLocalStoreToCloudIfNeeded(into cloudContext: ModelContext) {
        guard SyncPreferences.isCloudKitEnabled else { return }
        do {
            let result = try migrateFromLocalStore(into: cloudContext)
            SyncPreferences.lastMigrationSummary = migrationSummary(for: result)
        } catch {
            logger.error("Cloud migration failed: \(error.localizedDescription)")
            SyncPreferences.lastMigrationSummary = error.localizedDescription
            SyncPreferences.isCloudKitEnabled = false
            PersistenceReloadCoordinator.shared.requestReload()
        }
    }

    private static func migrationSummary(for result: CloudKitMigrationResult) -> String {
        if result.skippedBecauseAlreadyMigrated {
            L10n.syncMigrationAlreadyDone
        } else if result.recordsCopied > 0 {
            L10n.format("sync.migration.success", result.recordsCopied)
        } else {
            L10n.syncMigrationReady
        }
    }

    /// Migrates local on-disk data into the active CloudKit-backed store context.
    @discardableResult
    public static func migrateFromLocalStore(into cloudContext: ModelContext) throws -> CloudKitMigrationResult {
        guard CloudKitCapability.isConfigured else {
            throw CloudKitMigrationError.cloudKitUnavailable
        }
        guard isSignedInToiCloud else {
            throw CloudKitMigrationError.notSignedInToiCloud
        }

        let cloudFamilies = try cloudContext.fetch(FetchDescriptor<Family>())
        if !cloudFamilies.isEmpty {
            isMigrationCompleted = true
            return CloudKitMigrationResult(recordsCopied: 0, skippedBecauseAlreadyMigrated: true)
        }

        if isMigrationCompleted {
            let localContainer = try ModelContainerFactory.openLocal()
            let localFamilies = try ModelContext(localContainer).fetch(FetchDescriptor<Family>())
            if localFamilies.isEmpty {
                return CloudKitMigrationResult(recordsCopied: 0, skippedBecauseAlreadyMigrated: true)
            }
        }

        guard PersistencePaths.hasPrimaryStore else {
            isMigrationCompleted = true
            return CloudKitMigrationResult(recordsCopied: 0)
        }

        PersistenceBackupService.createBackup(label: "pre-cloud-migration")

        let localContainer = try ModelContainerFactory.openLocal()
        let local = ModelContext(localContainer)

        let localFamilies = try local.fetch(FetchDescriptor<Family>())
        guard !localFamilies.isEmpty else {
            isMigrationCompleted = true
            return CloudKitMigrationResult(recordsCopied: 0)
        }

        var copied = 0
        for family in localFamilies {
            copied += try copy(family: family, to: cloudContext)
        }

        let localThreads = try local.fetch(FetchDescriptor<MessageThread>())
        for thread in localThreads {
            copied += try copy(thread: thread, to: cloudContext)
        }

        let localChecklists = try local.fetch(FetchDescriptor<Checklist>())
        for checklist in localChecklists {
            copied += try copy(checklist: checklist, to: cloudContext)
        }

        try cloudContext.save()
        isMigrationCompleted = true
        logger.info("Migrated \(copied) records from local store into CloudKit context")
        return CloudKitMigrationResult(recordsCopied: copied)
    }

    private static func copy(family source: Family, to cloud: ModelContext) throws -> Int {
        var count = 0

        let family = Family(name: source.name)
        family.id = source.id
        family.createdAt = source.createdAt
        family.updatedAt = source.updatedAt
        cloud.insert(family)
        count += 1

        var membersById: [UUID: FamilyMember] = [:]
        for sourceMember in source.members {
            let member = FamilyMember(
                displayName: sourceMember.displayName,
                role: sourceMember.role,
                email: sourceMember.email,
                phone: sourceMember.phone
            )
            member.id = sourceMember.id
            member.avatarEmoji = sourceMember.avatarEmoji
            member.genmojiData = sourceMember.genmojiData
            member.permissions = sourceMember.permissions
            member.joinedAt = sourceMember.joinedAt
            member.family = family
            family.members.append(member)
            cloud.insert(member)
            membersById[member.id] = member
            count += 1
        }

        var childrenById: [UUID: Child] = [:]
        for sourceChild in source.children {
            let child = Child(
                firstName: sourceChild.firstName,
                lastName: sourceChild.lastName,
                dateOfBirth: sourceChild.dateOfBirth
            )
            child.id = sourceChild.id
            child.photoData = sourceChild.photoData
            child.genmojiData = sourceChild.genmojiData
            child.avatarEmoji = sourceChild.avatarEmoji
            child.bloodType = sourceChild.bloodType
            child.allergies = sourceChild.allergies
            child.clothingSize = sourceChild.clothingSize
            child.shoeSize = sourceChild.shoeSize
            child.socialSecurityLastFour = sourceChild.socialSecurityLastFour
            child.notes = sourceChild.notes
            child.createdAt = sourceChild.createdAt
            child.updatedAt = sourceChild.updatedAt
            child.family = family
            family.children.append(child)
            cloud.insert(child)
            childrenById[child.id] = child
            count += 1

            count += try copy(childDetails: sourceChild, to: child, in: cloud)
        }

        for sourceAgreement in source.custodyAgreements {
            let agreement = CustodyAgreement(
                title: sourceAgreement.title,
                bodyText: sourceAgreement.bodyText,
                effectiveDate: sourceAgreement.effectiveDate
            )
            agreement.id = sourceAgreement.id
            agreement.statusRaw = sourceAgreement.statusRaw
            agreement.parentAId = sourceAgreement.parentAId
            agreement.parentAName = sourceAgreement.parentAName
            agreement.parentASignatureData = sourceAgreement.parentASignatureData
            agreement.parentASignedAt = sourceAgreement.parentASignedAt
            agreement.parentBId = sourceAgreement.parentBId
            agreement.parentBName = sourceAgreement.parentBName
            agreement.parentBSignatureData = sourceAgreement.parentBSignatureData
            agreement.parentBSignedAt = sourceAgreement.parentBSignedAt
            agreement.documentHash = sourceAgreement.documentHash
            agreement.createdAt = sourceAgreement.createdAt
            agreement.updatedAt = sourceAgreement.updatedAt
            agreement.family = family
            agreement.child = sourceAgreement.child.flatMap { childrenById[$0.id] }
            family.custodyAgreements.append(agreement)
            cloud.insert(agreement)
            count += 1
        }

        _ = membersById
        return count
    }

    private static func copy(childDetails source: Child, to child: Child, in cloud: ModelContext) throws -> Int {
        var count = 0

        if let sourceEmergency = source.emergencyInfo {
            let emergency = EmergencyInfo()
            emergency.id = sourceEmergency.id
            emergency.primaryContactName = sourceEmergency.primaryContactName
            emergency.primaryContactPhone = sourceEmergency.primaryContactPhone
            emergency.secondaryContactName = sourceEmergency.secondaryContactName
            emergency.secondaryContactPhone = sourceEmergency.secondaryContactPhone
            emergency.pediatricianName = sourceEmergency.pediatricianName
            emergency.pediatricianPhone = sourceEmergency.pediatricianPhone
            emergency.hospitalPreference = sourceEmergency.hospitalPreference
            emergency.insuranceProvider = sourceEmergency.insuranceProvider
            emergency.insurancePolicyNumber = sourceEmergency.insurancePolicyNumber
            emergency.insuranceGroupNumber = sourceEmergency.insuranceGroupNumber
            emergency.passportNumber = sourceEmergency.passportNumber
            emergency.passportExpiry = sourceEmergency.passportExpiry
            emergency.passportCountry = sourceEmergency.passportCountry
            emergency.additionalNotes = sourceEmergency.additionalNotes
            emergency.child = child
            child.emergencyInfo = emergency
            cloud.insert(emergency)
            count += 1
        }

        if let sourceSchool = source.schoolInfo {
            let school = SchoolInfo(schoolName: sourceSchool.schoolName, grade: sourceSchool.grade)
            school.id = sourceSchool.id
            school.classroom = sourceSchool.classroom
            school.schoolPhone = sourceSchool.schoolPhone
            school.schoolAddress = sourceSchool.schoolAddress
            school.schoolYear = sourceSchool.schoolYear
            school.createdAt = sourceSchool.createdAt
            school.updatedAt = sourceSchool.updatedAt
            school.child = child
            child.schoolInfo = school
            cloud.insert(school)
            count += 1

            for sourceTeacher in sourceSchool.teachers {
                let teacher = Contact(name: sourceTeacher.name, role: sourceTeacher.role, phone: sourceTeacher.phone)
                teacher.id = sourceTeacher.id
                teacher.email = sourceTeacher.email
                teacher.notes = sourceTeacher.notes
                teacher.isEmergencyContact = sourceTeacher.isEmergencyContact
                teacher.createdAt = sourceTeacher.createdAt
                teacher.schoolInfo = school
                school.teachers.append(teacher)
                cloud.insert(teacher)
                count += 1
            }
        }

        for sourceRecord in source.medicalRecords {
            let record = MedicalRecord(
                title: sourceRecord.title,
                category: sourceRecord.category,
                date: sourceRecord.date,
                provider: sourceRecord.provider
            )
            record.id = sourceRecord.id
            record.notes = sourceRecord.notes
            record.attachmentData = sourceRecord.attachmentData
            record.createdAt = sourceRecord.createdAt
            record.child = child
            cloud.insert(record)
            count += 1
        }

        for sourceMedication in source.medications {
            let medication = Medication(
                name: sourceMedication.name,
                dosage: sourceMedication.dosage,
                frequency: sourceMedication.frequency,
                startDate: sourceMedication.startDate
            )
            medication.id = sourceMedication.id
            medication.prescribedBy = sourceMedication.prescribedBy
            medication.endDate = sourceMedication.endDate
            medication.reminderTimes = sourceMedication.reminderTimes
            medication.isActive = sourceMedication.isActive
            medication.notes = sourceMedication.notes
            medication.createdAt = sourceMedication.createdAt
            medication.child = child
            cloud.insert(medication)
            count += 1
        }

        for sourceGrowth in source.growthMeasurements {
            let growth = GrowthMeasurement(
                date: sourceGrowth.date,
                heightCm: sourceGrowth.heightCm,
                weightKg: sourceGrowth.weightKg,
                source: sourceGrowth.source,
                healthKitSampleId: sourceGrowth.healthKitSampleId
            )
            growth.id = sourceGrowth.id
            growth.createdAt = sourceGrowth.createdAt
            growth.child = child
            cloud.insert(growth)
            count += 1
        }

        for sourceAnnouncement in source.schoolAnnouncements {
            let announcement = SchoolAnnouncement(
                title: sourceAnnouncement.title,
                body: sourceAnnouncement.body,
                portalSource: sourceAnnouncement.portalSource,
                publishedAt: sourceAnnouncement.publishedAt
            )
            announcement.id = sourceAnnouncement.id
            announcement.isRead = sourceAnnouncement.isRead
            announcement.createdAt = sourceAnnouncement.createdAt
            announcement.child = child
            cloud.insert(announcement)
            count += 1
        }

        for sourceAssignment in source.schoolAssignments {
            let assignment = SchoolAssignment(
                title: sourceAssignment.title,
                subject: sourceAssignment.subject,
                dueDate: sourceAssignment.dueDate,
                portalSource: sourceAssignment.portalSource
            )
            assignment.id = sourceAssignment.id
            assignment.isCompleted = sourceAssignment.isCompleted
            assignment.createdAt = sourceAssignment.createdAt
            assignment.child = child
            cloud.insert(assignment)
            count += 1
        }

        for sourceEntry in source.timelineEntries {
            let entry = TimelineEntry(
                title: sourceEntry.title,
                category: sourceEntry.category,
                date: sourceEntry.date,
                detail: sourceEntry.detail,
                authorMemberId: sourceEntry.authorMemberId,
                authorName: sourceEntry.authorName
            )
            entry.id = sourceEntry.id
            entry.photoData = sourceEntry.photoData
            entry.createdAt = sourceEntry.createdAt
            entry.child = child
            cloud.insert(entry)
            count += 1
        }

        for sourceEvent in source.events {
            let event = CalendarEvent(
                title: sourceEvent.title,
                startDate: sourceEvent.startDate,
                endDate: sourceEvent.endDate,
                category: sourceEvent.category,
                isAllDay: sourceEvent.isAllDay
            )
            event.id = sourceEvent.id
            event.detail = sourceEvent.detail
            event.location = sourceEvent.location
            event.assignedParentId = sourceEvent.assignedParentId
            event.isRecurring = sourceEvent.isRecurring
            event.recurrenceRule = sourceEvent.recurrenceRule
            event.reminderMinutes = sourceEvent.reminderMinutes
            event.createdAt = sourceEvent.createdAt
            event.updatedAt = sourceEvent.updatedAt
            event.appleCalendarEventIdentifier = sourceEvent.appleCalendarEventIdentifier
            event.lastSyncedAt = sourceEvent.lastSyncedAt
            event.latitude = sourceEvent.latitude
            event.longitude = sourceEvent.longitude
            event.sharedLocationAt = sourceEvent.sharedLocationAt
            event.sharedLocationMemberName = sourceEvent.sharedLocationMemberName
            event.child = child
            cloud.insert(event)
            count += 1
        }

        for sourceExpense in source.expenses {
            let expense = Expense(
                title: sourceExpense.title,
                amount: sourceExpense.amount,
                category: sourceExpense.category,
                paidByMemberId: sourceExpense.paidByMemberId,
                paidByName: sourceExpense.paidByName,
                splitRatio: sourceExpense.splitRatio,
                date: sourceExpense.date
            )
            expense.id = sourceExpense.id
            expense.currency = sourceExpense.currency
            expense.isReimbursed = sourceExpense.isReimbursed
            expense.reimbursedAt = sourceExpense.reimbursedAt
            expense.receiptData = sourceExpense.receiptData
            expense.notes = sourceExpense.notes
            expense.createdAt = sourceExpense.createdAt
            expense.child = child
            cloud.insert(expense)
            count += 1
        }

        for sourceDocument in source.documents {
            let document = Document(title: sourceDocument.title, category: sourceDocument.category)
            document.id = sourceDocument.id
            document.fileData = sourceDocument.fileData
            document.fileName = sourceDocument.fileName
            document.mimeType = sourceDocument.mimeType
            document.expiryDate = sourceDocument.expiryDate
            document.isEncrypted = sourceDocument.isEncrypted
            document.createdAt = sourceDocument.createdAt
            document.updatedAt = sourceDocument.updatedAt
            document.child = child
            cloud.insert(document)
            count += 1
        }

        for sourceSchedule in source.custodySchedules {
            let schedule = CustodySchedule(
                name: sourceSchedule.name,
                pattern: sourceSchedule.pattern,
                startDate: sourceSchedule.startDate,
                parentAId: sourceSchedule.parentAId,
                parentBId: sourceSchedule.parentBId,
                parentAName: sourceSchedule.parentAName,
                parentBName: sourceSchedule.parentBName
            )
            schedule.id = sourceSchedule.id
            schedule.exchangeTime = sourceSchedule.exchangeTime
            schedule.exchangeLocation = sourceSchedule.exchangeLocation
            schedule.isActive = sourceSchedule.isActive
            schedule.createdAt = sourceSchedule.createdAt
            schedule.child = child
            cloud.insert(schedule)
            count += 1
        }

        return count
    }

    private static func copy(thread source: MessageThread, to cloud: ModelContext) throws -> Int {
        let thread = MessageThread(
            participantIds: source.participantIds,
            participantNames: source.participantNames,
            subject: source.subject
        )
        thread.id = source.id
        thread.isPinned = source.isPinned
        thread.createdAt = source.createdAt
        thread.lastMessageAt = source.lastMessageAt
        cloud.insert(thread)

        var count = 1
        for sourceMessage in source.messages {
            let message = Message(
                content: sourceMessage.content,
                senderId: sourceMessage.senderId,
                senderName: sourceMessage.senderName
            )
            message.id = sourceMessage.id
            message.sentAt = sourceMessage.sentAt
            message.readAt = sourceMessage.readAt
            message.attachmentType = sourceMessage.attachmentType
            message.attachmentData = sourceMessage.attachmentData
            message.isImmutable = sourceMessage.isImmutable
            message.auditHash = sourceMessage.auditHash
            message.thread = thread
            thread.messages.append(message)
            cloud.insert(message)
            count += 1
        }
        return count
    }

    private static func copy(checklist source: Checklist, to cloud: ModelContext) throws -> Int {
        let checklist = Checklist(title: source.title, childId: source.childId)
        checklist.id = source.id
        checklist.createdAt = source.createdAt
        checklist.updatedAt = source.updatedAt
        cloud.insert(checklist)

        var count = 1
        for sourceItem in source.items {
            let item = ChecklistItem(title: sourceItem.title, sortOrder: sourceItem.sortOrder)
            item.id = sourceItem.id
            item.isCompleted = sourceItem.isCompleted
            item.completedAt = sourceItem.completedAt
            item.createdAt = sourceItem.createdAt
            item.checklist = checklist
            checklist.items.append(item)
            cloud.insert(item)
            count += 1
        }
        return count
    }
}
