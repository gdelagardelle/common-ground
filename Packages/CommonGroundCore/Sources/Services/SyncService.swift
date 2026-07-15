import Foundation

public enum SyncStatus: Sendable {
    case idle
    case syncing
    case conflict(resolved: Int)
    case error(String)
}

@MainActor
public protocol SyncServiceProtocol: Sendable {
    var status: SyncStatus { get }
    func sync() async
    func resolveConflicts() async
}

@Observable
@MainActor
public final class CloudKitSyncService: SyncServiceProtocol {
    public private(set) var status: SyncStatus = .idle
    public private(set) var lastSyncDate: Date?

    public init() {
        lastSyncDate = SyncPreferences.lastCloudSyncDate
    }

    public func sync() async {
        guard SyncPreferences.isCloudKitEnabled else {
            status = .error(L10n.cloudErrorDisabled)
            return
        }

        guard CloudKitShareService.isSignedInToiCloud else {
            status = .error(L10n.cloudErrorNotSignedIn)
            return
        }

        status = .syncing
        try? await Task.sleep(nanoseconds: 500_000_000)
        lastSyncDate = Date()
        SyncPreferences.lastCloudSyncDate = lastSyncDate
        status = .idle
    }

    public func resolveConflicts() async {
        await sync()
    }
}

public enum ConflictResolutionStrategy: Sendable {
    case lastWriterWins
    case merge
    case manual
}

public struct SyncConflict: Identifiable, Sendable {
    public let id: UUID
    public let entityType: String
    public let localModified: Date
    public let remoteModified: Date
    public let field: String

    public init(entityType: String, localModified: Date, remoteModified: Date, field: String) {
        self.id = UUID()
        self.entityType = entityType
        self.localModified = localModified
        self.remoteModified = remoteModified
        self.field = field
    }
}
