import Foundation

public enum InviteService {
    public static func inviteMessage(familyName: String, inviterName: String, familyId: UUID) -> String {
        L10n.format(
            "invite.message",
            inviterName,
            familyName,
            String(familyId.uuidString.prefix(8).uppercased())
        )
    }

    public static func inviteURL(familyId: UUID) -> URL {
        URL(string: "https://commonground.app/invite/\(familyId.uuidString)")!
    }

    public static func mailtoURL(email: String, subject: String, body: String) -> URL? {
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = email
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body),
        ]
        return components.url
    }
}

public enum SyncPreferences {
    private static let cloudKitKey = "sync.cloudKitEnabled"
    private static let migrationCompletedKey = "sync.localMigrationCompleted"

    public static var isCloudKitEnabled: Bool {
        get { SharedPreferences.defaults.bool(forKey: cloudKitKey) }
        set {
            SharedPreferences.defaults.set(newValue, forKey: cloudKitKey)
            UserDefaults.standard.set(newValue, forKey: cloudKitKey)
            if !newValue {
                SharedPreferences.defaults.set(false, forKey: migrationCompletedKey)
                UserDefaults.standard.set(false, forKey: migrationCompletedKey)
            }
        }
    }

    public static var requiresRestartMessage: String {
        L10n.syncRequiresRestart
    }
}
