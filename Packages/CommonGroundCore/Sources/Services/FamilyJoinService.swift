import Foundation
import SwiftData

public enum FamilyJoinError: LocalizedError {
    case invalidCode
    case familyNotFound
    case alreadyMember
    case emptyName

    public var errorDescription: String? {
        switch self {
        case .invalidCode:
            L10n.familyJoinErrorInvalidCode
        case .familyNotFound:
            L10n.familyJoinErrorNotFound
        case .alreadyMember:
            L10n.familyJoinErrorAlreadyMember
        case .emptyName:
            L10n.familyJoinErrorEmptyName
        }
    }
}

@MainActor
public enum FamilyJoinService {
    public static func normalizedCode(_ input: String) -> String {
        input
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .uppercased()
            .replacingOccurrences(of: "-", with: "")
    }

    public static func findFamily(code: String, context: ModelContext) throws -> Family? {
        let normalized = normalizedCode(code)
        guard normalized.count >= 6 else { return nil }

        let families = try context.fetch(FetchDescriptor<Family>())
        return families.first { family in
            let prefix = String(family.id.uuidString.prefix(8)).uppercased()
            return prefix == normalized || family.id.uuidString.uppercased().hasPrefix(normalized)
        }
    }

    public static func findFamilyWithCloudSyncRetry(
        code: String,
        context: ModelContext,
        maxAttempts: Int = 8,
        delayNanoseconds: UInt64 = 2_000_000_000
    ) async throws -> Family? {
        for attempt in 0..<maxAttempts {
            if let family = try findFamily(code: code, context: context) {
                return family
            }

            guard SyncPreferences.isCloudKitEnabled, attempt < maxAttempts - 1 else { break }
            try await Task.sleep(nanoseconds: delayNanoseconds)
        }
        return try findFamily(code: code, context: context)
    }

    @discardableResult
    public static func joinFamily(
        context: ModelContext,
        code: String,
        memberName: String,
        email: String? = nil
    ) throws -> (Family, FamilyMember) {
        let trimmedName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw FamilyJoinError.emptyName }

        guard let family = try findFamily(code: code, context: context) else {
            throw FamilyJoinError.familyNotFound
        }

        if family.members.contains(where: { $0.displayName.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            throw FamilyJoinError.alreadyMember
        }

        let member = FamilyMember(displayName: trimmedName, role: .parent, email: email?.nilIfEmpty)
        member.family = family
        family.members.append(member)
        family.updatedAt = Date()

        try context.save()
        try FamilyMessagingBootstrap.ensureCoParentThread(context: context, family: family)
        return (family, member)
    }

    @discardableResult
    public static func joinFamilyWithRetry(
        context: ModelContext,
        code: String,
        memberName: String,
        email: String? = nil
    ) async throws -> (Family, FamilyMember) {
        let trimmedName = memberName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else { throw FamilyJoinError.emptyName }

        guard let family = try await findFamilyWithCloudSyncRetry(code: code, context: context) else {
            throw FamilyJoinError.familyNotFound
        }

        if family.members.contains(where: { $0.displayName.caseInsensitiveCompare(trimmedName) == .orderedSame }) {
            throw FamilyJoinError.alreadyMember
        }

        let member = FamilyMember(displayName: trimmedName, role: .parent, email: email?.nilIfEmpty)
        member.family = family
        family.members.append(member)
        family.updatedAt = Date()

        try context.save()
        try FamilyMessagingBootstrap.ensureCoParentThread(context: context, family: family)
        return (family, member)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
