import Foundation

public enum InviteService {
    public static func inviteMessage(familyName: String, inviterName: String, familyId: UUID) -> String {
        """
        \(inviterName) invited you to join "\(familyName)" on Common Ground — the shared app for co-parenting.

        Download Common Ground and use this family code to connect:
        \(familyId.uuidString.prefix(8).uppercased())

        Common Ground keeps custody schedules, expenses, medical records, and messages in one secure place.
        """
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

    public static var isCloudKitEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: cloudKitKey) }
        set { UserDefaults.standard.set(newValue, forKey: cloudKitKey) }
    }

    public static var requiresRestartMessage: String {
        "iCloud sync will take effect the next time you open the app. Sign in to iCloud and enable iCloud capability in Xcode for full sync."
    }
}
