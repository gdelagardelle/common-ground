import Foundation
import SwiftData

#if canImport(CloudKit)
import CloudKit
#endif

public enum CloudKitShareError: LocalizedError {
    case notSignedIn
    case cloudKitDisabled
    case sharingUnavailable
    case shareFailed(String)

    public var errorDescription: String? {
        switch self {
        case .notSignedIn:
            L10n.cloudErrorNotSignedIn
        case .cloudKitDisabled:
            L10n.cloudErrorDisabled
        case .sharingUnavailable:
            L10n.cloudErrorUnavailable
        case .shareFailed(let message):
            message
        }
    }
}

@MainActor
public enum CloudKitShareService {
    public static var isSignedInToiCloud: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }

    public static var canShare: Bool {
        #if canImport(CloudKit)
        return CloudKitCapability.isConfigured && isSignedInToiCloud && SyncPreferences.isCloudKitEnabled
        #else
        return false
        #endif
    }

    #if canImport(CloudKit)
    public static func shareFamily(
        _ family: Family,
        context: ModelContext,
        existingShare: CKShare? = nil
    ) async throws -> (CKShare, CKContainer) {
        guard isSignedInToiCloud else { throw CloudKitShareError.notSignedIn }
        guard SyncPreferences.isCloudKitEnabled else { throw CloudKitShareError.cloudKitDisabled }
        guard CloudKitCapability.isConfigured else { throw CloudKitShareError.sharingUnavailable }

        if let existingShare {
            let container = CKContainer(identifier: AppIdentifiers.cloudKitContainer)
            return (existingShare, container)
        }

        let container = CKContainer(identifier: AppIdentifiers.cloudKitContainer)
        let zoneName = "CommonGround-Family-\(family.id.uuidString)"
        let zoneID = CKRecordZone.ID(zoneName: zoneName, ownerName: CKCurrentUserDefaultName)

        do {
            _ = try await container.sharedCloudDatabase.recordZone(for: zoneID)
        } catch {
            let zone = CKRecordZone(zoneID: zoneID)
            do {
                _ = try await container.privateCloudDatabase.modifyRecordZones(saving: [zone], deleting: [])
            } catch {
                throw CloudKitShareError.shareFailed(error.localizedDescription)
            }
        }

        let familyRecordID = CKRecord.ID(recordName: "family-\(family.id.uuidString)", zoneID: zoneID)
        let familyRecord = CKRecord(recordType: "CommonGroundFamily", recordID: familyRecordID)
        familyRecord["name"] = family.name as CKRecordValue
        familyRecord["familyId"] = family.id.uuidString as CKRecordValue
        familyRecord["updatedAt"] = Date() as CKRecordValue

        let share = CKShare(rootRecord: familyRecord)
        share[CKShare.SystemFieldKey.title] = "Common Ground — \(family.name)" as CKRecordValue
        share.publicPermission = .none

        do {
            _ = try await container.privateCloudDatabase.modifyRecords(saving: [familyRecord, share], deleting: [])
        } catch {
            throw CloudKitShareError.shareFailed(error.localizedDescription)
        }

        SyncPreferences.storeShareReference(familyId: family.id, zoneName: zoneName)
        try? context.save()

        return (share, container)
    }
    #endif

    public static var statusMessage: String {
        if !CloudKitCapability.isConfigured {
            return L10n.cloudErrorUnavailable
        }
        if !isSignedInToiCloud {
            return L10n.cloudStatusNotSignedIn
        }
        if !SyncPreferences.isCloudKitEnabled {
            return L10n.cloudStatusDisabled
        }
        return L10n.cloudStatusReady
    }
}

public extension SyncPreferences {
    private static let shareZonePrefix = "sync.shareZone."

    static func storeShareReference(familyId: UUID, zoneName: String) {
        UserDefaults.standard.set(zoneName, forKey: shareZonePrefix + familyId.uuidString)
    }

    static func shareZoneName(for familyId: UUID) -> String? {
        UserDefaults.standard.string(forKey: shareZonePrefix + familyId.uuidString)
    }
}
