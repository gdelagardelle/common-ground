import Foundation
import os

public enum PersistenceBackupService {
    private static let logger = Logger(subsystem: AppIdentifiers.bundleID, category: "PersistenceBackup")
    private static let lastBackupVersionKey = "persistence.backup.buildVersion"
    private static let maxAutomaticBackups = 5

    /// Copies the SwiftData store before opening the container when the app build number changes.
    public static func backupBeforeLaunchIfNeeded() {
        guard PersistencePaths.hasPrimaryStore else { return }

        let currentBuild = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let lastBackedUpBuild = UserDefaults.standard.string(forKey: lastBackupVersionKey)

        guard lastBackedUpBuild != currentBuild else { return }

        createBackup(label: "pre-update-\(currentBuild)")
        UserDefaults.standard.set(currentBuild, forKey: lastBackupVersionKey)
        logger.info("Created pre-update backup for build \(currentBuild)")
    }

    @discardableResult
    public static func createBackup(label: String) -> URL? {
        guard PersistencePaths.hasPrimaryStore else { return nil }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = PersistencePaths.backupsDirectory
            .appendingPathComponent("\(label)-\(timestamp)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for source in PersistencePaths.primaryStoreFiles where FileManager.default.fileExists(atPath: source.path) {
                let destination = directory.appendingPathComponent(source.lastPathComponent)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: source, to: destination)
            }
            pruneOldBackups()
            logger.info("Backed up store to \(directory.path)")
            return directory
        } catch {
            logger.error("Backup failed: \(error.localizedDescription)")
            return nil
        }
    }

    public static func restoreLatestBackup() -> Bool {
        guard let latest = sortedBackupDirectories().last else { return false }
        return restoreBackup(from: latest)
    }

    public static func restoreBackup(from directory: URL) -> Bool {
        do {
            for fileName in PersistencePaths.storeFileNames {
                let source = directory.appendingPathComponent(fileName)
                guard FileManager.default.fileExists(atPath: source.path) else { continue }
                let destination = PersistencePaths.applicationSupportDirectory.appendingPathComponent(fileName)
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: source, to: destination)
            }
            logger.info("Restored store from \(directory.path)")
            return PersistencePaths.hasPrimaryStore
        } catch {
            logger.error("Restore failed: \(error.localizedDescription)")
            return false
        }
    }

    public static func archiveCorruptedStore() {
        guard PersistencePaths.hasPrimaryStore else { return }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withDashSeparatorInDate, .withColonSeparatorInTime]
        let timestamp = formatter.string(from: Date()).replacingOccurrences(of: ":", with: "-")
        let directory = PersistencePaths.backupsDirectory
            .appendingPathComponent("corrupted-\(timestamp)", isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            for source in PersistencePaths.primaryStoreFiles where FileManager.default.fileExists(atPath: source.path) {
                let destination = directory.appendingPathComponent(source.lastPathComponent)
                try FileManager.default.moveItem(at: source, to: destination)
            }
            logger.warning("Archived corrupted store to \(directory.path)")
        } catch {
            logger.error("Failed to archive corrupted store: \(error.localizedDescription)")
        }
    }

    private static func sortedBackupDirectories() -> [URL] {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: PersistencePaths.backupsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: [.skipsHiddenFiles]
        ) else {
            return []
        }

        return contents
            .filter { $0.hasDirectoryPath }
            .sorted {
                let lhs = (try? $0.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                let rhs = (try? $1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? .distantPast
                return lhs < rhs
            }
    }

    private static func pruneOldBackups() {
        let directories = sortedBackupDirectories()
        guard directories.count > maxAutomaticBackups else { return }

        for directory in directories.prefix(directories.count - maxAutomaticBackups) {
            try? FileManager.default.removeItem(at: directory)
        }
    }
}
