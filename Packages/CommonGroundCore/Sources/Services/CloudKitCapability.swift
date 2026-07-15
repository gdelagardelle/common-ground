import Foundation

#if canImport(CloudKit)
import CloudKit

public enum CloudKitCapability {
    /// True when the app is built with the project's CloudKit container entitlements.
    public static var isConfigured: Bool {
        CKContainer(identifier: AppIdentifiers.cloudKitContainer).containerIdentifier
            == AppIdentifiers.cloudKitContainer
    }
}
#else
public enum CloudKitCapability {
    public static var isConfigured: Bool { false }
}
#endif
