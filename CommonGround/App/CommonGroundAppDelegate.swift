import UIKit
import CloudKit
import CommonGroundCore

final class CommonGroundAppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        userDidAcceptCloudKitShareWith cloudKitShareMetadata: CKShare.Metadata
    ) {
        Task { @MainActor in
            await CloudKitShareAcceptanceService.accept(metadata: cloudKitShareMetadata)
        }
    }
}
