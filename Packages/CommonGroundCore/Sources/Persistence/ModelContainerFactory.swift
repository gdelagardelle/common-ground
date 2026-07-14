import Foundation
import SwiftData
import os

public enum ModelContainerFactory {
    private static let logger = Logger(subsystem: AppIdentifiers.bundleID, category: "SwiftData")

    public static let cloudKitContainerID = AppIdentifiers.cloudKitContainer

    /// Uses CloudKit when the user has opted in via SyncPreferences; otherwise local-only storage.
    public static func makePreferred() throws -> ModelContainer {
        if SyncPreferences.isCloudKitEnabled {
            return try makeWithCloudKitIfAvailable()
        }
        return try make()
    }

    /// Local-only storage. Explicitly disables CloudKit even when iCloud entitlements are present.
    public static func make() throws -> ModelContainer {
        let schema = Schema(CommonGroundSchema.models)

        do {
            return try makeLocalContainer(schema: schema, inMemory: false)
        } catch {
            logger.error("Local persistent store failed: \(error.localizedDescription). Attempting store reset.")
            resetPersistentStore()
        }

        do {
            return try makeLocalContainer(schema: schema, inMemory: false)
        } catch {
            logger.error("Local store failed after reset: \(error.localizedDescription)")
        }

        logger.warning("Falling back to in-memory store.")
        return try makeLocalContainer(schema: schema, inMemory: true)
    }

    /// CloudKit sync — requires signed entitlements and models with CloudKit-compatible schema.
    public static func makeWithCloudKitIfAvailable() throws -> ModelContainer {
        let schema = Schema(CommonGroundSchema.models)

        do {
            let cloudConfiguration = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            return try ModelContainer(for: schema, configurations: [cloudConfiguration])
        } catch {
            logger.warning("CloudKit store unavailable, using local storage: \(error.localizedDescription)")
            return try make()
        }
    }

    private static func makeLocalContainer(schema: Schema, inMemory: Bool) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory,
            cloudKitDatabase: .none
        )
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    private static func resetPersistentStore() {
        let directories = [
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first,
            FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppIdentifiers.appGroup),
        ].compactMap { $0 }

        let storeNames = ["default.store", "default.store-shm", "default.store-wal"]
        for directory in directories {
            for name in storeNames {
                let url = directory.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: url.path) {
                    do {
                        try FileManager.default.removeItem(at: url)
                        logger.info("Removed stale store file: \(url.path)")
                    } catch {
                        logger.error("Failed to remove \(url.path): \(error.localizedDescription)")
                    }
                }

                let appSupport = directory.appendingPathComponent("Library/Application Support", isDirectory: true)
                let nestedURL = appSupport.appendingPathComponent(name)
                if FileManager.default.fileExists(atPath: nestedURL.path) {
                    try? FileManager.default.removeItem(at: nestedURL)
                }
            }
        }
    }
}
