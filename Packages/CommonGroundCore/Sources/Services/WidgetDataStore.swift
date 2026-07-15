import Foundation

#if canImport(WidgetKit)
import WidgetKit
#endif

public struct WidgetSnapshot: Codable, Sendable, Equatable {
    public var childName: String
    public var currentParent: String
    public var nextExchange: Date?
    public var nextEvent: String
    public var updatedAt: Date

    public init(
        childName: String,
        currentParent: String,
        nextExchange: Date?,
        nextEvent: String,
        updatedAt: Date = Date()
    ) {
        self.childName = childName
        self.currentParent = currentParent
        self.nextExchange = nextExchange
        self.nextEvent = nextEvent
        self.updatedAt = updatedAt
    }

    public static let placeholder = WidgetSnapshot(
        childName: "—",
        currentParent: "—",
        nextExchange: nil,
        nextEvent: "—"
    )
}

public enum WidgetDataStore {
    private static let snapshotKey = "widget.snapshot"

    public static func save(_ snapshot: WidgetSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        SharedPreferences.defaults.set(data, forKey: snapshotKey)
        #if canImport(WidgetKit)
        WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    public static func load() -> WidgetSnapshot? {
        guard let data = SharedPreferences.defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(WidgetSnapshot.self, from: data)
    }
}
