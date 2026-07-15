import Foundation

public enum SharedPreferences {
    public static var defaults: UserDefaults {
        UserDefaults(suiteName: AppIdentifiers.appGroup) ?? .standard
    }
}
