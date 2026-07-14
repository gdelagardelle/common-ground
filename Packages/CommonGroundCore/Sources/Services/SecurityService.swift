import Foundation
import LocalAuthentication
import Observation
import Security

@Observable
@MainActor
public final class SecurityService {
    private enum StorageKey {
        static let lockEnabled = "security.lockEnabled"
    }

    public var isUnlocked = false
    public var biometricType: LABiometryType = .none
    public private(set) var requiresAuthentication: Bool

    private let keychain = KeychainService()
    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.requiresAuthentication = Self.initialLockEnabled(defaults: defaults)
        detectBiometricType()
        isUnlocked = !requiresAuthentication
    }

    public var isLockEnabled: Bool {
        get { requiresAuthentication }
        set { setLockEnabled(newValue) }
    }

    public var lockMethodDescription: String {
        switch biometricType {
        case .faceID: "Face ID"
        case .touchID: "Touch ID"
        case .opticID: "Optic ID"
        default: "Device Passcode"
        }
    }

    public func setLockEnabled(_ enabled: Bool) {
        requiresAuthentication = enabled
        defaults.set(enabled, forKey: StorageKey.lockEnabled)

        if enabled {
            isUnlocked = false
        } else {
            isUnlocked = true
        }
    }

    public func authenticate() async -> Bool {
        guard requiresAuthentication else {
            isUnlocked = true
            return true
        }

        let context = LAContext()
        var error: NSError?

        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return await authenticateWithPasscode(context: context)
        }

        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Unlock Common Ground to access your family's information."
            )
            isUnlocked = success
            return success
        } catch {
            return await authenticateWithPasscode(context: context)
        }
    }

    public func lock() {
        guard requiresAuthentication else { return }
        isUnlocked = false
    }

    public func storeSecureValue(_ value: String, for key: String) throws {
        try keychain.store(value, for: key)
    }

    public func retrieveSecureValue(for key: String) throws -> String? {
        try keychain.retrieve(for: key)
    }

    private static func initialLockEnabled(defaults: UserDefaults) -> Bool {
        if defaults.object(forKey: StorageKey.lockEnabled) != nil {
            return defaults.bool(forKey: StorageKey.lockEnabled)
        }

        #if targetEnvironment(simulator)
        return false
        #else
        return true
        #endif
    }

    private func authenticateWithPasscode(context: LAContext) async -> Bool {
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthentication,
                localizedReason: "Unlock Common Ground to access your family's information."
            )
            isUnlocked = success
            return success
        } catch {
            isUnlocked = false
            return false
        }
    }

    private func detectBiometricType() {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            biometricType = .none
            return
        }
        biometricType = context.biometryType
    }
}

public final class KeychainService: Sendable {
    private let service = AppIdentifiers.bundleID

    public init() {}

    public func store(_ value: String, for key: String) throws {
        guard let data = value.data(using: .utf8) else { return }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
        ]

        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.storeFailed(status)
        }
    }

    public func retrieve(for key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound { return nil }
            throw KeychainError.retrieveFailed(status)
        }

        return String(data: data, encoding: .utf8)
    }

    public func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.deleteFailed(status)
        }
    }
}

public enum KeychainError: Error, LocalizedError {
    case storeFailed(OSStatus)
    case retrieveFailed(OSStatus)
    case deleteFailed(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .storeFailed: "Failed to store secure value."
        case .retrieveFailed: "Failed to retrieve secure value."
        case .deleteFailed: "Failed to delete secure value."
        }
    }
}
