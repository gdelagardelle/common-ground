import Foundation
import SwiftData

public enum CustodyScheduleGenerator {
    private static let schedulePrefix = "schedule:"

    public static func generateEvents(
        schedule: CustodySchedule,
        child: Child,
        context: ModelContext,
        weeks: Int = 12
    ) throws {
        removeExistingGeneratedEvents(schedule: schedule, child: child, context: context)

        let calendar = Calendar.current
        let start = calendar.startOfDay(for: schedule.startDate)
        let totalDays = weeks * 7

        for dayOffset in 0..<totalDays {
            guard let day = calendar.date(byAdding: .day, value: dayOffset, to: start) else { continue }

            let parent = assignedParent(for: day, schedule: schedule, calendar: calendar, start: start)
            let parentName = parent.id == schedule.parentAId ? schedule.parentAName : schedule.parentBName

            let custody = CalendarEvent(
                title: "With \(parentName)",
                startDate: day,
                endDate: day,
                category: .custody,
                isAllDay: true
            )
            custody.assignedParentId = parent.id
            custody.child = child
            custody.isRecurring = true
            custody.recurrenceRule = rule(for: schedule)
            child.events.append(custody)
            context.insert(custody)

            if shouldCreateExchange(on: day, schedule: schedule, calendar: calendar, start: start, dayOffset: dayOffset) {
                let exchangeDate = exchangeDate(for: day, schedule: schedule, calendar: calendar)
                let exchange = CalendarEvent(
                    title: "Custody Exchange",
                    startDate: exchangeDate,
                    endDate: calendar.date(byAdding: .minute, value: 30, to: exchangeDate) ?? exchangeDate,
                    category: .exchange
                )
                exchange.location = schedule.exchangeLocation
                exchange.child = child
                exchange.recurrenceRule = rule(for: schedule)
                exchange.reminderMinutes = 60
                child.events.append(exchange)
                context.insert(exchange)
            }
        }

        schedule.isActive = true
        try context.save()
    }

    private static func rule(for schedule: CustodySchedule) -> String {
        "\(schedulePrefix)\(schedule.id.uuidString)"
    }

    private static func removeExistingGeneratedEvents(
        schedule: CustodySchedule,
        child: Child,
        context: ModelContext
    ) {
        let marker = rule(for: schedule)
        let toRemove = child.events.filter { $0.recurrenceRule == marker }
        toRemove.forEach { event in
            context.delete(event)
            child.events.removeAll { $0.id == event.id }
        }
    }

    private struct ParentRef {
        let id: UUID
    }

    private static func assignedParent(
        for day: Date,
        schedule: CustodySchedule,
        calendar: Calendar,
        start: Date
    ) -> ParentRef {
        let dayIndex = calendar.dateComponents([.day], from: start, to: day).day ?? 0

        switch schedule.pattern {
        case .weekOnWeekOff:
            let week = dayIndex / 7
            return ParentRef(id: week.isMultiple(of: 2) ? schedule.parentAId : schedule.parentBId)

        case .twoTwoThree:
            let cycleDay = dayIndex % 14
            switch cycleDay {
            case 0...1, 4...6, 9...10:
                return ParentRef(id: schedule.parentAId)
            default:
                return ParentRef(id: schedule.parentBId)
            }

        case .alternatingWeekends:
            let weekday = calendar.component(.weekday, from: day)
            let isWeekend = weekday == 1 || weekday == 7
            if !isWeekend {
                return ParentRef(id: schedule.parentAId)
            }
            let week = dayIndex / 7
            return ParentRef(id: week.isMultiple(of: 2) ? schedule.parentBId : schedule.parentAId)

        case .custom:
            return ParentRef(id: schedule.parentAId)
        }
    }

    private static func shouldCreateExchange(
        on day: Date,
        schedule: CustodySchedule,
        calendar: Calendar,
        start: Date,
        dayOffset: Int
    ) -> Bool {
        guard dayOffset > 0 else { return false }
        let previousDay = calendar.date(byAdding: .day, value: -1, to: day)!
        let todayParent = assignedParent(for: day, schedule: schedule, calendar: calendar, start: start)
        let yesterdayParent = assignedParent(for: previousDay, schedule: schedule, calendar: calendar, start: start)
        return todayParent.id != yesterdayParent.id
    }

    private static func exchangeDate(for day: Date, schedule: CustodySchedule, calendar: Calendar) -> Date {
        if let exchangeTime = schedule.exchangeTime {
            let time = calendar.dateComponents([.hour, .minute], from: exchangeTime)
            return calendar.date(bySettingHour: time.hour ?? 17, minute: time.minute ?? 0, second: 0, of: day) ?? day
        }
        return calendar.date(bySettingHour: 17, minute: 0, second: 0, of: day) ?? day
    }
}

@MainActor
public enum CustodySetupService {
    public static func createSchedule(
        context: ModelContext,
        child: Child,
        pattern: CustodyPattern,
        parentA: FamilyMember,
        parentB: FamilyMember,
        startDate: Date,
        exchangeLocation: String?,
        exchangeTime: Date?
    ) throws -> CustodySchedule {
        let schedule = CustodySchedule(
            name: "\(child.firstName)'s \(pattern.displayName)",
            pattern: pattern,
            startDate: startDate,
            parentAId: parentA.id,
            parentBId: parentB.id,
            parentAName: parentA.displayName,
            parentBName: parentB.displayName
        )
        schedule.exchangeLocation = exchangeLocation?.nilIfEmpty
        schedule.exchangeTime = exchangeTime
        schedule.child = child
        child.custodySchedules.forEach { $0.isActive = false }

        context.insert(schedule)
        try CustodyScheduleGenerator.generateEvents(schedule: schedule, child: child, context: context)
        return schedule
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
