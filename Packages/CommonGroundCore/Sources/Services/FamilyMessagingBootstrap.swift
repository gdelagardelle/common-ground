import Foundation
import SwiftData

@MainActor
public enum FamilyMessagingBootstrap {
    public static func ensureCoParentThread(
        context: ModelContext,
        family: Family
    ) throws {
        let parents = family.members.filter { $0.role == .parent }
        guard parents.count >= 2 else { return }

        let parentIds = Set(parents.map(\.id))
        let descriptor = FetchDescriptor<MessageThread>()
        let existing = try context.fetch(descriptor)

        if existing.contains(where: { Set($0.participantIds) == parentIds }) {
            return
        }

        _ = try MessagingService.createThread(
            context: context,
            members: parents,
            subject: L10n.format("messages.defaultSubject", family.name)
        )
    }
}
