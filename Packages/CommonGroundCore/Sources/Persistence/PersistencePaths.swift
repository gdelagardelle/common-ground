import Foundation

public enum PersistencePaths {
    public static let storeFileNames = ["default.store", "default.store-shm", "default.store-wal"]

    public static var applicationSupportDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
    }

    public static var primaryStoreFiles: [URL] {
        storeFileNames.map { applicationSupportDirectory.appendingPathComponent($0) }
    }

    public static var backupsDirectory: URL {
        let directory = applicationSupportDirectory.appendingPathComponent("Backups", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    public static var hasPrimaryStore: Bool {
        FileManager.default.fileExists(atPath: primaryStoreFiles[0].path)
    }
}
