import Foundation

/// Safe runtime probe for Apple Intelligence / FoundationModels without crashing on unsupported OS builds.
@MainActor
public enum OnDeviceAIAvailability {
    public static var isSupported: Bool {
        #if canImport(FoundationModels)
        guard #available(iOS 26.0, *) else { return false }
        return OnDeviceAIService.isAvailable
        #else
        return false
        #endif
    }
}
