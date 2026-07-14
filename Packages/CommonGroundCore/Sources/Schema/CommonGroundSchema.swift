import Foundation
import SwiftData

public enum CommonGroundSchema {
    public static let models: [any PersistentModel.Type] = [
        Family.self,
        FamilyMember.self,
        Child.self,
        CustodySchedule.self,
        CalendarEvent.self,
        Expense.self,
        MedicalRecord.self,
        Medication.self,
        GrowthMeasurement.self,
        SchoolAnnouncement.self,
        SchoolAssignment.self,
        SchoolInfo.self,
        Contact.self,
        MessageThread.self,
        Message.self,
        Document.self,
        TimelineEntry.self,
        Checklist.self,
        ChecklistItem.self,
        EmergencyInfo.self,
        CustodyAgreement.self,
    ]
}
