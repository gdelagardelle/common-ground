import Foundation

#if canImport(CloudKit)
import CloudKit
#endif

@MainActor
public enum CloudKitShareAcceptanceService {
    public static var didAcceptShare = false

    #if canImport(CloudKit)
    public static func accept(metadata: CKShare.Metadata) async {
        let container = CKContainer(identifier: AppIdentifiers.cloudKitContainer)
        do {
            _ = try await container.accept(metadata)
            didAcceptShare = true
            SyncPreferences.isCloudKitEnabled = true
        } catch {
            // Share acceptance is handled by the system; failures are surfaced in sync settings.
        }
    }
    #endif
}
