import Foundation
import SwiftData

@MainActor
public enum DailyUpdateService {
    public static func create(
        context: ModelContext,
        child: Child,
        title: String,
        detail: String?,
        authorMemberId: UUID?,
        authorName: String
    ) throws {
        let entry = TimelineEntry(
            title: title,
            category: .dailyUpdate,
            date: Date(),
            detail: detail?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            authorMemberId: authorMemberId,
            authorName: authorName
        )
        entry.child = child
        child.timelineEntries.append(entry)
        context.insert(entry)
        try context.save()
    }

    public static func recentUpdates(for child: Child, limit: Int = 5) -> [TimelineEntry] {
        child.timelineEntries
            .filter(\.isDailyUpdate)
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
