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

public struct WritableCalendarInfo: Identifiable, Sendable, Hashable {
    public let id: String
    public let title: String
    public let sourceTitle: String

    public init(id: String, title: String, sourceTitle: String) {
        self.id = id
        self.title = title
        self.sourceTitle = sourceTitle
    }

    public var displayTitle: String {
        if sourceTitle.isEmpty { return title }
        return "\(title) · \(sourceTitle)"
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

    public static func writableCalendars() -> [WritableCalendarInfo] {
        store.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .sorted { lhs, rhs in
                lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            .map {
                WritableCalendarInfo(
                    id: $0.calendarIdentifier,
                    title: $0.title,
                    sourceTitle: $0.source.title
                )
            }
    }

    public static func performFullSync(
        context: ModelContext,
        child: Child?,
        daysAhead: Int = 90
    ) async throws -> CalendarSyncResult {
        let exported = try await exportOnly(context: context)
        let imported = try await importOnly(context: context, child: child, daysAhead: daysAhead)
        CalendarSyncPreferences.lastSyncDate = Date()
        return CalendarSyncResult(
            exported: exported.exported,
            imported: imported.imported,
            updated: exported.updated
        )
    }

    public static func exportOnly(context: ModelContext) async throws -> CalendarSyncResult {
        guard await requestAccess() else {
            return CalendarSyncResult(exported: 0, imported: 0, updated: 0)
        }
        let calendar = try resolveExportCalendar()
        let exportStats = try exportEvents(context: context, to: calendar)
        try context.save()
        CalendarSyncPreferences.lastSyncDate = Date()
        return CalendarSyncResult(
            exported: exportStats.created,
            imported: 0,
            updated: exportStats.updated
        )
    }

    public static func importOnly(
        context: ModelContext,
        child: Child?,
        daysAhead: Int = 90
    ) async throws -> CalendarSyncResult {
        guard await requestAccess() else {
            return CalendarSyncResult(exported: 0, imported: 0, updated: 0)
        }
        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: daysAhead, to: start) else {
            return CalendarSyncResult(exported: 0, imported: 0, updated: 0)
        }
        let dedicated = try? getOrCreateCommonGroundCalendar()
        let importCount = try importExternalEvents(
            context: context,
            child: child,
            start: start,
            end: end,
            excludingCalendar: dedicated
        )
        CalendarSyncPreferences.lastSyncDate = Date()
        return CalendarSyncResult(exported: 0, imported: importCount, updated: 0)
    }

    public static func exportEventIfNeeded(_ event: CalendarEvent, context: ModelContext) async {
        guard CalendarSyncPreferences.isAutoSyncEnabled else { return }
        guard shouldExport(event) else { return }
        guard await requestAccess() else { return }

        do {
            let calendar = try resolveExportCalendar()
            try upsert(event: event, in: calendar)
            try context.save()
        } catch {
            // Calendar export is best-effort
        }
    }

    public static func exportPendingEvents(context: ModelContext) async throws -> Int {
        let result = try await exportOnly(context: context)
        return result.exported + result.updated
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
           let existing = store.event(withIdentifier: identifier),
           existing.calendar?.calendarIdentifier == calendar.calendarIdentifier {
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

        try store.save(ekEvent, span: .thisEvent, commit: true)

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
            parts.append("cg-child:\(child.firstName)")
        }
        return parts.joined(separator: "\n")
    }

    // MARK: - Import

    private static func importExternalEvents(
        context: ModelContext,
        child: Child?,
        start: Date,
        end: Date,
        excludingCalendar: EKCalendar?
    ) throws -> Int {
        let linkedIDs = Set(
            try context.fetch(FetchDescriptor<CalendarEvent>())
                .compactMap(\.appleCalendarEventIdentifier)
        )

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)
            .filter { ek in
                guard let excludingCalendar else { return true }
                return ek.calendar?.calendarIdentifier != excludingCalendar.calendarIdentifier
            }
            .sorted(by: { $0.startDate < $1.startDate })

        var imported = 0
        for ekEvent in ekEvents {
            guard let eventID = ekEvent.eventIdentifier, !linkedIDs.contains(eventID) else { continue }
            if notesContainSourceMarker(ekEvent.notes) { continue }

            let category = mapCategory(ekEvent)
            let event = CalendarEvent(
                title: ekEvent.title ?? L10n.eventAppointment,
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
        if title.contains("exchange") || title.contains("custody") || title.contains("iwwergab") || title.contains("garde") { return .exchange }
        if title.contains("school") || title.contains("schule") || title.contains("schoul") || title.contains("école") { return .school }
        if title.contains("doctor") || title.contains("dentist") || title.contains("medical") || title.contains("arzt") { return .medical }
        if title.contains("soccer") || title.contains("sport") || title.contains("practice") { return .sports }
        if title.contains("birthday") || title.contains("geburt") || title.contains("anniversaire") { return .birthday }
        return .appointment
    }

    // MARK: - Calendar setup

    private static func resolveExportCalendar() throws -> EKCalendar {
        switch CalendarSyncPreferences.exportDestination {
        case .dedicated:
            return try getOrCreateCommonGroundCalendar()
        case .existing:
            guard let id = CalendarSyncPreferences.exportTargetCalendarIdentifier,
                  let calendar = store.calendars(for: .event).first(where: { $0.calendarIdentifier == id }),
                  calendar.allowsContentModifications else {
                throw CalendarSyncError.calendarNotFound
            }
            return calendar
        }
    }

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
    case calendarNotFound

    public var errorDescription: String? {
        switch self {
        case .noCalendarSource:
            L10n.errorCalendarNoSource
        case .calendarNotFound:
            L10n.errorCalendarNotFound
        }
    }
}
