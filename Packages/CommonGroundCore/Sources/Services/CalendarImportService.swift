import Foundation
import EventKit
import SwiftData

@MainActor
public enum CalendarImportService {
    private static let store = EKEventStore()

    public static func requestAccess() async -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                return false
            }
        } else {
            return await withCheckedContinuation { continuation in
                store.requestAccess(to: .event) { granted, _ in
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    public static func authorizationStatus() -> EKAuthorizationStatus {
        EKEventStore.authorizationStatus(for: .event)
    }

    public static func importEvents(
        context: ModelContext,
        child: Child?,
        daysAhead: Int = 30
    ) async throws -> Int {
        let start = Date()
        guard let end = Calendar.current.date(byAdding: .day, value: daysAhead, to: start) else {
            return 0
        }

        let predicate = store.predicateForEvents(withStart: start, end: end, calendars: nil)
        let ekEvents = store.events(matching: predicate)
            .sorted(by: { $0.startDate < $1.startDate })

        var imported = 0
        for ekEvent in ekEvents {
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
            event.child = child
            if let child {
                child.events.append(event)
            }
            context.insert(event)
            imported += 1
        }

        if imported > 0 {
            try context.save()
        }
        return imported
    }

    private static func mapCategory(_ event: EKEvent) -> EventCategory {
        let title = (event.title ?? "").lowercased()
        if title.contains("school") { return .school }
        if title.contains("doctor") || title.contains("dentist") || title.contains("medical") { return .medical }
        if title.contains("soccer") || title.contains("sport") || title.contains("practice") { return .sports }
        if title.contains("birthday") { return .birthday }
        return .appointment
    }
}
