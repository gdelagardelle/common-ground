import Foundation

public enum CalendarSyncPreferences {
    private static let autoSyncKey = "calendar.autoSyncEnabled"
    private static let exportAllKey = "calendar.exportAllEvents"
    private static let calendarIDKey = "calendar.ekCalendarIdentifier"
    private static let lastSyncKey = "calendar.lastSyncDate"

    public static var isAutoSyncEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: autoSyncKey) }
        set { UserDefaults.standard.set(newValue, forKey: autoSyncKey) }
    }

    /// When false, only custody and exchange events are exported.
    public static var exportAllEvents: Bool {
        get { UserDefaults.standard.bool(forKey: exportAllKey) }
        set { UserDefaults.standard.set(newValue, forKey: exportAllKey) }
    }

    public static var storedCalendarIdentifier: String? {
        get { UserDefaults.standard.string(forKey: calendarIDKey) }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: calendarIDKey)
            } else {
                UserDefaults.standard.removeObject(forKey: calendarIDKey)
            }
        }
    }

    public static var lastSyncDate: Date? {
        get { UserDefaults.standard.object(forKey: lastSyncKey) as? Date }
        set {
            if let newValue {
                UserDefaults.standard.set(newValue, forKey: lastSyncKey)
            } else {
                UserDefaults.standard.removeObject(forKey: lastSyncKey)
            }
        }
    }
}
