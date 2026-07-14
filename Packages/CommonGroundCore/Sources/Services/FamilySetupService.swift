import Foundation
import SwiftData

@MainActor
public enum FamilySetupService {
    public static func createFamilyWithFirstChild(
        context: ModelContext,
        familyName: String,
        parentName: String,
        childFirstName: String,
        childLastName: String,
        childDateOfBirth: Date,
        coParentName: String? = nil
    ) throws -> (Family, FamilyMember, Child) {
        let family = Family(name: familyName)
        let parent = FamilyMember(displayName: parentName, role: .parent)
        parent.family = family
        var members = [parent]

        if let coParentName, !coParentName.isEmpty {
            let coParent = FamilyMember(displayName: coParentName, role: .parent)
            coParent.family = family
            members.append(coParent)
        }

        family.members = members

        let child = try addChild(
            context: context,
            family: family,
            firstName: childFirstName,
            lastName: childLastName,
            dateOfBirth: childDateOfBirth
        )

        context.insert(family)
        try context.save()
        return (family, parent, child)
    }

    @discardableResult
    public static func addChild(
        context: ModelContext,
        family: Family,
        firstName: String,
        lastName: String,
        dateOfBirth: Date,
        bloodType: String? = nil,
        allergies: [String] = []
    ) throws -> Child {
        let child = Child(firstName: firstName, lastName: lastName, dateOfBirth: dateOfBirth)
        child.bloodType = bloodType
        child.allergies = allergies
        child.family = family
        family.children.append(child)

        let emergency = EmergencyInfo()
        emergency.child = child
        child.emergencyInfo = emergency
        context.insert(emergency)

        context.insert(child)
        try context.save()
        return child
    }

    @discardableResult
    public static func addEvent(
        context: ModelContext,
        child: Child?,
        title: String,
        category: EventCategory,
        startDate: Date,
        endDate: Date,
        isAllDay: Bool,
        location: String? = nil
    ) throws -> CalendarEvent {
        let event = CalendarEvent(
            title: title,
            startDate: startDate,
            endDate: endDate,
            category: category,
            isAllDay: isAllDay
        )
        event.location = location?.nilIfEmpty
        event.child = child
        child?.events.append(event)
        context.insert(event)
        try context.save()
        return event
    }

    @discardableResult
    public static func addExpense(
        context: ModelContext,
        child: Child?,
        title: String,
        amount: Decimal,
        category: ExpenseCategory,
        paidBy: FamilyMember,
        splitRatio: Double = 0.5,
        date: Date = Date(),
        notes: String? = nil
    ) throws -> Expense {
        let expense = Expense(
            title: title,
            amount: amount,
            category: category,
            paidByMemberId: paidBy.id,
            paidByName: paidBy.displayName,
            splitRatio: splitRatio,
            date: date
        )
        expense.notes = notes?.nilIfEmpty
        expense.child = child
        child?.expenses.append(expense)
        context.insert(expense)
        try context.save()
        return expense
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
