import Foundation
import SwiftData

#if canImport(ActivityKit)
import ActivityKit

@MainActor
public enum LiveActivityService {
    public static func startExchangeActivity(
        childName: String,
        exchangeTime: Date,
        location: String?,
        withParent: String
    ) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let hoursRemaining = max(0, Calendar.current.dateComponents([.hour], from: Date(), to: exchangeTime).hour ?? 0)
        let attributes = ExchangeActivityAttributes(childName: childName)
        let state = ExchangeActivityAttributes.ContentState(
            exchangeTime: exchangeTime,
            location: location,
            withParent: withParent,
            hoursRemaining: hoursRemaining
        )

        let content = ActivityContent(state: state, staleDate: exchangeTime)

        for activity in Activity<ExchangeActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: content,
                pushType: nil
            )
        } catch {
            // Unavailable in some simulator configurations
        }
    }

    public static func updateForUpcomingExchange(
        childName: String,
        event: CalendarEvent,
        withParent: String
    ) async {
        let hoursUntil = Calendar.current.dateComponents([.hour], from: Date(), to: event.startDate).hour ?? 0
        guard hoursUntil <= 24, hoursUntil >= 0 else { return }
        await startExchangeActivity(
            childName: childName,
            exchangeTime: event.startDate,
            location: event.location,
            withParent: withParent
        )
    }

    public static func endAll() async {
        for activity in Activity<ExchangeActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }

    public static func syncUpcomingExchanges(from context: ModelContext) async {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let now = Date()
        let descriptor = FetchDescriptor<CalendarEvent>(
            sortBy: [SortDescriptor(\.startDate)]
        )

        guard let events = try? context.fetch(descriptor) else { return }

        guard let event = events.first(where: { $0.category == .exchange && $0.startDate >= now }) else {
            await endAll()
            return
        }

        let hoursUntil = Calendar.current.dateComponents([.hour], from: now, to: event.startDate).hour ?? 99
        guard hoursUntil <= 24 else {
            await endAll()
            return
        }

        let childName = event.child?.firstName ?? "Child"
        let withParent = event.child?.family?.members.dropFirst().first?.displayName ?? "Co-parent"

        await updateForUpcomingExchange(
            childName: childName,
            event: event,
            withParent: withParent
        )
    }
}
#endif

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
