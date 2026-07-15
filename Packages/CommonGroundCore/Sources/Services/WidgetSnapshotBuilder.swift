import Foundation
import SwiftData

@MainActor
public enum WidgetSnapshotBuilder {
    public static func refresh(from context: ModelContext) {
        let familyDescriptor = FetchDescriptor<Family>()
        guard let family = try? context.fetch(familyDescriptor).first else { return }

        let child = family.children.sorted { $0.firstName < $1.firstName }.first
        let childName = child?.firstName ?? L10n.tabChildren

        let eventsDescriptor = FetchDescriptor<CalendarEvent>(
            sortBy: [SortDescriptor(\.startDate)]
        )
        let events = (try? context.fetch(eventsDescriptor)) ?? []
        let childEvents = events.filter { $0.child?.id == child?.id || child == nil }

        let now = Date()
        let currentParent = resolveCurrentParent(
            events: childEvents,
            family: family,
            at: now
        )

        let nextExchange = childEvents
            .first(where: { $0.category == .exchange && $0.startDate >= now })?
            .startDate

        let nextEvent = childEvents
            .first(where: { $0.startDate >= now && $0.category != .custody })?
            .title ?? L10n.homeNoUpcomingEvents

        WidgetDataStore.save(
            WidgetSnapshot(
                childName: childName,
                currentParent: currentParent,
                nextExchange: nextExchange,
                nextEvent: nextEvent
            )
        )
    }

    public static func resolveCurrentParent(
        events: [CalendarEvent],
        family: Family,
        at date: Date
    ) -> String {
        if let custody = events.first(where: {
            $0.category == .custody
                && $0.startDate <= date
                && $0.endDate >= date
        }), let parentId = custody.assignedParentId,
           let parent = family.members.first(where: { $0.id == parentId }) {
            return parent.displayName
        }

        if let parent = family.members.first(where: { $0.role == .parent }) {
            return parent.displayName
        }

        return family.members.first?.displayName ?? "—"
    }

    public static func resolveExchangeParent(
        for event: CalendarEvent,
        family: Family
    ) -> String {
        if let parentId = event.assignedParentId,
           let parent = family.members.first(where: { $0.id == parentId }) {
            return parent.displayName
        }

        let parents = family.members.filter { $0.role == .parent }
        if parents.count >= 2 {
            return parents[1].displayName
        }
        return parents.first?.displayName ?? L10n.custodyParentB
    }
}
