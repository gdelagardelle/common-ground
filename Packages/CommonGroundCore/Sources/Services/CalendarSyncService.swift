import Foundation
import EventKit
import SwiftData
import CoreGraphics

public struct CalendarSyncResult: Sendable {
    public let exported: Int
    public let imported: Int
    public let updated: Int

    public init(exported: Int, imported: Int, updated: Int) {
        self.exported = exported
        self.imported = imported
        self.updated = updated
    }
}

@MainActor
public enum CalendarSyncService {
    private static let store = EKEventStore()
    private static let calendarTitle = "Common Ground"
    private static let sourceMarker = "commonground://"

    public static func requestAccess() async -> Bool {
        await CalendarImportService.requestAccess()
    }

    public static func authorizationStatus() -> EKAuthorizationStatus {
        CalendarImportService.authorizationStatus()
    }

    public static func performFullSync(
        context: ModelContext,
        child: Child?,
        daysAhead: Int = 90
    ) async throws -> CalendarSyncResult {
        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: daysAhead, to: start) else {
            return CalendarSyncResult(exported: 0, imported: 0, updated: 0)
        }

        let calendar = try getOrCreateCommonGroundCalendar()
        let exportStats = try exportEvents(context: context, to: calendar)
        let importCount = try importExternalEvents(
            context: context,
            child: child,
            start: start,
            end: end,
            excludingCalendar: calendar
        )

        CalendarSyncPreferences.lastSyncDate = Date()
        return CalendarSyncResult(
            exported: exportStats.created,
            imported: importCount,
            updated: exportStats.updated
        )
    }

    public static func exportEventIfNeeded(_ event: CalendarEvent, context: ModelContext) async {
        guard CalendarSyncPreferences.isAutoSyncEnabled else { return }
        guard shouldExport(event) else { return }
        guard await requestAccess() else { return }

        do {
            let calendar = try getOrCreateCommonGroundCalendar()
            try upsert(event: event, in: calendar)
            try context.save()
        } catch {
            // Calendar export is best-effort
        }
    }

    public static func exportPendingEvents(context: ModelContext) async throws -> Int {
        guard await requestAccess() else { return 0 }
        let calendar = try getOrCreateCommonGroundCalendar()
        let stats = try exportEvents(context: context, to: calendar)
        try context.save()
        return stats.created + stats.updated
    }

    // MARK: - Export

    private struct ExportStats {
        var created = 0
        var updated = 0
    }

    private static func exportEvents(context: ModelContext, to calendar: EKCalendar) throws -> ExportStats {
        let descriptor = FetchDescriptor<CalendarEvent>(sortBy: [SortDescriptor(\.startDate)])
        let events = try context.fetch(descriptor)
        var stats = ExportStats()

        for event in events where shouldExport(event) {
            let wasLinked = event.appleCalendarEventIdentifier != nil
            try upsert(event: event, in: calendar)
            if wasLinked {
                stats.updated += 1
            } else {
                stats.created += 1
            }
        }
        return stats
    }

    private static func shouldExport(_ event: CalendarEvent) -> Bool {
        if CalendarSyncPreferences.exportAllEvents { return true }
        return event.category == .custody || event.category == .exchange
    }

    private static func upsert(event: CalendarEvent, in calendar: EKCalendar) throws {
        let ekEvent: EKEvent
        if let identifier = event.appleCalendarEventIdentifier,
           let existing = store.event(withIdentifier: identifier) {
            ekEvent = existing
        } else {
            ekEvent = EKEvent(eventStore: store)
        }

        ekEvent.calendar = calendar
        ekEvent.title = formattedTitle(for: event)
        ekEvent.startDate = event.startDate
        ekEvent.endDate = event.endDate
        ekEvent.isAllDay = event.isAllDay
        ekEvent.location = event.location
        ekEvent.notes = formattedNotes(for: event)

        if ekEvent.eventIdentifier == nil {
            try store.save(ekEvent, span: .thisEvent, commit: true)
        } else {
            try store.save(ekEvent, span: .thisEvent, commit: true)
        }

        event.appleCalendarEventIdentifier = ekEvent.eventIdentifier
        event.lastSyncedAt = Date()
        event.updatedAt = Date()
    }

    private static func formattedTitle(for event: CalendarEvent) -> String {
        if event.category == .custody || event.category == .exchange {
            return event.title
        }
        return "[CG] \(event.title)"
    }

    private static func formattedNotes(for event: CalendarEvent) -> String {
        var parts = ["\(sourceMarker)\(event.id.uuidString)"]
        if let detail = event.detail, !detail.isEmpty {
            parts.append(detail)
        }
        if let child = event.child {
            parts.append("Child: \(child.firstName)")
        }
        return parts.joined(separator: "\n")
    }

    // MARK: - Import

    private static func importExternalEvents(
        context: ModelContext,
        child: Child?,
        start: Date,
        end: Date,
        excludingCalendar: EKCalendar
    ) throws -> Int {
        let linkedIDs = Set(
            try context.fetch(FetchDescriptor<CalendarEvent>())
                .compactMap(\.appleCalendarEventIdentifier)
        )

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)
            .filter { $0.calendar?.calendarIdentifier != excludingCalendar.calendarIdentifier }
            .sorted(by: { $0.startDate < $1.startDate })

        var imported = 0
        for ekEvent in ekEvents {
            guard let eventID = ekEvent.eventIdentifier, !linkedIDs.contains(eventID) else { continue }
            if notesContainSourceMarker(ekEvent.notes) { continue }

            let category = mapCategory(ekEvent)
            let event = CalendarEvent(
                title: ekEvent.title ?? "Calendar Event",
                startDate: ekEvent.startDate,
                endDate: ekEvent.endDate,
                category: category,
                isAllDay: ekEvent.isAllDay
            )
            event.location = ekEvent.location
            event.detail = ekEvent.notes
            event.appleCalendarEventIdentifier = eventID
            event.lastSyncedAt = Date()
            event.child = child
            child?.events.append(event)
            context.insert(event)
            imported += 1
        }

        if imported > 0 {
            try context.save()
        }
        return imported
    }

    private static func notesContainSourceMarker(_ notes: String?) -> Bool {
        guard let notes else { return false }
        return notes.contains(sourceMarker)
    }

    private static func mapCategory(_ event: EKEvent) -> EventCategory {
        let title = (event.title ?? "").lowercased()
        if title.contains("exchange") || title.contains("custody") { return .exchange }
        if title.contains("school") { return .school }
        if title.contains("doctor") || title.contains("dentist") || title.contains("medical") { return .medical }
        if title.contains("soccer") || title.contains("sport") || title.contains("practice") { return .sports }
        if title.contains("birthday") { return .birthday }
        return .appointment
    }

    // MARK: - Calendar setup

    private static func getOrCreateCommonGroundCalendar() throws -> EKCalendar {
        if let storedID = CalendarSyncPreferences.storedCalendarIdentifier,
           let existing = store.calendars(for: .event).first(where: { $0.calendarIdentifier == storedID }) {
            return existing
        }

        if let existing = store.calendars(for: .event).first(where: { $0.title == calendarTitle }) {
            CalendarSyncPreferences.storedCalendarIdentifier = existing.calendarIdentifier
            return existing
        }

        let calendar = EKCalendar(for: .event, eventStore: store)
        calendar.title = calendarTitle
        calendar.cgColor = CGColor(red: 0.26, green: 0.39, blue: 0.92, alpha: 1.0)

        if let source = store.defaultCalendarForNewEvents?.source ?? store.sources.first {
            calendar.source = source
        } else {
            throw CalendarSyncError.noCalendarSource
        }

        try store.saveCalendar(calendar, commit: true)
        CalendarSyncPreferences.storedCalendarIdentifier = calendar.calendarIdentifier
        return calendar
    }
}

public enum CalendarSyncError: LocalizedError {
    case noCalendarSource

    public var errorDescription: String? {
        switch self {
        case .noCalendarSource:
            "No calendar account is available. Add an iCloud or local calendar in Settings."
        }
    }
}
