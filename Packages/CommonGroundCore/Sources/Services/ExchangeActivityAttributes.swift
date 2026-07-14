import Foundation

#if canImport(ActivityKit)
import ActivityKit

public struct ExchangeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var exchangeTime: Date
        public var location: String?
        public var withParent: String
        public var hoursRemaining: Int

        public init(exchangeTime: Date, location: String?, withParent: String, hoursRemaining: Int) {
            self.exchangeTime = exchangeTime
            self.location = location
            self.withParent = withParent
            self.hoursRemaining = hoursRemaining
        }
    }

    public var childName: String

    public init(childName: String) {
        self.childName = childName
    }
}
#endif
