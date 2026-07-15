import Foundation
import SwiftData

@MainActor
public final class SampleDataService {
    public static func seedIfNeeded(context: ModelContext) {
        let descriptor = FetchDescriptor<Family>()
        let existing = (try? context.fetch(descriptor)) ?? []
        guard existing.isEmpty else { return }

        let family = Family(name: "The Johnson Family")

        let parentA = FamilyMember(displayName: "Sarah", role: .parent, email: "sarah@example.com")
        let parentB = FamilyMember(displayName: "Michael", role: .parent, email: "michael@example.com")
        parentA.family = family
        parentB.family = family
        family.members = [parentA, parentB]

        let emma = Child(firstName: "Emma", lastName: "Johnson", dateOfBirth: {
            var components = DateComponents()
            components.year = 2018
            components.month = 3
            components.day = 15
            return Calendar.current.date(from: components) ?? Date()
        }())
        emma.bloodType = "O+"
        emma.allergies = ["Peanuts", "Shellfish"]
        emma.clothingSize = "6T"
        emma.shoeSize = "12"
        emma.family = family
        family.children = [emma]

        let emergency = EmergencyInfo()
        emergency.primaryContactName = "Sarah Johnson"
        emergency.primaryContactPhone = "(555) 123-4567"
        emergency.pediatricianName = "Dr. Patel"
        emergency.pediatricianPhone = "(555) 987-6543"
        emergency.insuranceProvider = "Blue Cross"
        emergency.insurancePolicyNumber = "BC-12345678"
        emergency.passportNumber = "••••4892"
        emergency.passportExpiry = Calendar.current.date(byAdding: .year, value: 2, to: Date())
        emergency.passportCountry = "United States"
        emergency.child = emma
        emma.emergencyInfo = emergency

        let school = SchoolInfo(schoolName: "Lincoln Elementary", grade: "2nd")
        school.classroom = "Room 204"
        school.schoolPhone = "(555) 456-7890"
        school.child = emma
        emma.schoolInfo = school

        let teacher = Contact(name: "Ms. Rodriguez", role: "Teacher", phone: "(555) 456-7891")
        teacher.schoolInfo = school
        school.teachers = [teacher]

        let dental = MedicalRecord(title: "Dental Checkup", category: .dental, date: {
            Calendar.current.date(byAdding: .month, value: -4, to: Date()) ?? Date()
        }(), provider: "Bright Smiles Pediatric Dentistry")
        dental.child = emma
        emma.medicalRecords = [dental]

        let medication = Medication(name: "Children's Zyrtec", dosage: "5mg", frequency: "Once daily")
        medication.prescribedBy = "Dr. Patel"
        medication.child = emma
        emma.medications = [medication]

        let passport = Document(title: "Emma's Passport", category: .passport)
        passport.expiryDate = emergency.passportExpiry
        passport.child = emma

        let events = createSampleEvents(for: emma, parentA: parentA, parentB: parentB)
        emma.events = events

        let expenses = createSampleExpenses(for: emma, parentA: parentA, parentB: parentB)
        emma.expenses = expenses
        emma.documents = [passport]

        let timeline = [
            TimelineEntry(
                title: "Soccer practice went well",
                category: .dailyUpdate,
                date: Calendar.current.date(byAdding: .hour, value: -3, to: Date()) ?? Date(),
                detail: "Emma scored a goal. Homework done before dinner.",
                authorMemberId: parentA.id,
                authorName: parentA.displayName
            ),
            TimelineEntry(title: "First day of 2nd grade", category: .school, date: Calendar.current.date(byAdding: .month, value: -2, to: Date()) ?? Date()),
            TimelineEntry(title: "Lost first tooth", category: .first, date: Calendar.current.date(byAdding: .month, value: -6, to: Date()) ?? Date()),
            TimelineEntry(title: "Soccer tournament win", category: .achievement, date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()),
        ]
        timeline.forEach { $0.child = emma }
        emma.timelineEntries = timeline

        let thread = MessageThread(
            participantIds: [parentA.id, parentB.id],
            participantNames: [parentA.displayName, parentB.displayName],
            subject: "Emma's Week"
        )
        let msg1 = Message(content: "Emma has a science project due Friday. I'll help her start it tonight.", senderId: parentA.id, senderName: parentA.displayName)
        let msg2 = Message(content: "Sounds good. I'll pick up poster board on my way home.", senderId: parentB.id, senderName: parentB.displayName)
        msg1.thread = thread
        msg2.thread = thread
        msg2.readAt = Date()
        thread.messages = [msg1, msg2]

        let packingList = Checklist(title: "Overnight Bag", childId: emma.id)
        let items = ["Toothbrush", "Pajamas", "Homework folder", "Soccer cleats", "Lovey"].enumerated().map { index, title in
            ChecklistItem(title: title, sortOrder: index)
        }
        items.forEach { $0.checklist = packingList }
        packingList.items = items

        context.insert(family)
        context.insert(thread)
        context.insert(packingList)

        try? context.save()
    }

    private static func createSampleEvents(for child: Child, parentA: FamilyMember, parentB: FamilyMember) -> [CalendarEvent] {
        let calendar = Calendar.current
        let today = Date()

        var events: [CalendarEvent] = []

        if let exchange = calendar.date(byAdding: .day, value: 2, to: today) {
            let e = CalendarEvent(title: "Custody Exchange", startDate: exchange, endDate: exchange, category: .exchange)
            e.location = "School parking lot"
            e.assignedParentId = parentB.id
            e.child = child
            events.append(e)
        }

        if let soccer = calendar.date(byAdding: .day, value: 4, to: today) {
            let e = CalendarEvent(title: "Soccer Practice", startDate: soccer, endDate: soccer, category: .sports)
            e.location = "Riverside Park Field 3"
            e.child = child
            events.append(e)
        }

        if let dentist = calendar.date(byAdding: .day, value: 14, to: today) {
            let e = CalendarEvent(title: "Dentist Appointment", startDate: dentist, endDate: dentist, category: .medical)
            e.location = "Bright Smiles Pediatric Dentistry"
            e.child = child
            events.append(e)
        }

        let custody = CalendarEvent(
            title: "With \(parentA.displayName)",
            startDate: today,
            endDate: calendar.date(byAdding: .day, value: 7, to: today) ?? today,
            category: .custody,
            isAllDay: true
        )
        custody.assignedParentId = parentA.id
        custody.child = child
        events.append(custody)

        return events
    }

    private static func createSampleExpenses(for child: Child, parentA: FamilyMember, parentB: FamilyMember) -> [Expense] {
        var expenses: [Expense] = []

        let football = Expense(
            title: "Fall Football Registration",
            amount: 185,
            category: .sports,
            paidByMemberId: parentA.id,
            paidByName: parentA.displayName,
            date: Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        )
        football.child = child
        expenses.append(football)

        let school = Expense(
            title: "School Supplies",
            amount: 67.50,
            category: .school,
            paidByMemberId: parentB.id,
            paidByName: parentB.displayName,
            date: Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
        )
        school.isReimbursed = false
        school.child = child
        expenses.append(school)

        let medical = Expense(
            title: "Copay - Dr. Patel",
            amount: 30,
            category: .medical,
            paidByMemberId: parentA.id,
            paidByName: parentA.displayName,
            date: Calendar.current.date(byAdding: .weekOfYear, value: -2, to: Date()) ?? Date()
        )
        medical.isReimbursed = true
        medical.reimbursedAt = Date()
        medical.child = child
        expenses.append(medical)

        return expenses
    }
}
