import Foundation
import Observation

@Observable
@MainActor
public final class AppState {
    public var selectedChildId: UUID?
    public var selectedTab: AppTab = .home
    public var isOnboardingComplete = false
    public var preferredColorScheme: ColorScheme?
    public var searchQuery = ""
    public var isAIAssistantPresented = false

    public var currentMemberId: UUID?
    public var currentMemberName: String = "You"

    public init() {}
}

public enum AppTab: String, CaseIterable, Identifiable, Sendable {
    case home
    case calendar
    case children
    case messages
    case more

    public var id: String { rawValue }

    public var title: String {
        switch self {
        case .home: "Home"
        case .calendar: "Calendar"
        case .children: "Children"
        case .messages: "Messages"
        case .more: "More"
        }
    }

    public var icon: String {
        switch self {
        case .home: "house.fill"
        case .calendar: "calendar"
        case .children: "figure.2.and.child.holdinghands"
        case .messages: "bubble.left.and.bubble.right.fill"
        case .more: "ellipsis.circle.fill"
        }
    }
}

#if canImport(SwiftUI)
import SwiftUI
#endif
