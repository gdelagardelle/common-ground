import Foundation
import SwiftData
import os

public enum ModelContainerFactory {
    private static let logger = Logger(subsystem: AppIdentifiers.bundleID, category: "SwiftData")

    public static let cloudKitContainerID = AppIdentifiers.cloudKitContainer

    /// Uses CloudKit when the user has opted in via SyncPreferences; otherwise local-only storage.
    public static func makePreferred() throws -> ModelContainer {
        if SyncPreferences.isCloudKitEnabled {
            CloudKitMigrationService.migrateLocalStoreToCloudIfNeeded()
            return try makeWithCloudKitIfAvailable()
        }
        return try make()
    }

    /// Opens a local-only container for migration or recovery.
    public static func openLocal() throws -> ModelContainer {
        try makeLocalContainer(inMemory: false)
    }

    /// Opens a CloudKit-backed container.
    public static func openCloud() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CommonGroundSchemaV1.self)
        let cloudConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private(cloudKitContainerID)
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: CommonGroundMigrationPlan.self,
            configurations: [cloudConfiguration]
        )
    }

    /// Local-only storage. Explicitly disables CloudKit even when iCloud entitlements are present.
    public static func make() throws -> ModelContainer {
        PersistenceBackupService.backupBeforeLaunchIfNeeded()

        do {
            return try makeLocalContainer(inMemory: false)
        } catch {
            logger.error("Local persistent store failed: \(error.localizedDescription). Attempting backup restore.")
        }

        if PersistenceBackupService.restoreLatestBackup() {
            do {
                return try makeLocalContainer(inMemory: false)
            } catch {
                logger.error("Local store failed after restore: \(error.localizedDescription)")
            }
        }

        if PersistencePaths.hasPrimaryStore {
            PersistenceBackupService.archiveCorruptedStore()
            do {
                return try makeLocalContainer(inMemory: false)
            } catch {
                logger.error("Local store failed after archiving corrupted data: \(error.localizedDescription)")
            }
        }

        logger.fault("Unable to open persistent store. Creating a new local database.")
        return try makeLocalContainer(inMemory: false)
    }

    /// CloudKit sync — requires signed entitlements and models with CloudKit-compatible schema.
    public static func makeWithCloudKitIfAvailable() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CommonGroundSchemaV1.self)

        do {
            let cloudConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            return try ModelContainer(
                for: schema,
                migrationPlan: CommonGroundMigrationPlan.self,
                configurations: [cloudConfiguration]
            )
        } catch {
            logger.warning("CloudKit store unavailable, using local storage: \(error.localizedDescription)")
            return try make()
        }
    }

    private static func makeLocalContainer(inMemory: Bool) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CommonGroundSchemaV1.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: CommonGroundMigrationPlan.self,
            configurations: [configuration]
        )
    }
}
