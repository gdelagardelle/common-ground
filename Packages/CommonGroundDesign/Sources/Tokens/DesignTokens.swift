import SwiftUI

public enum CGColor {
    public static let custodyBlue = Color.blue
    public static let schoolGreen = Color.green
    public static let medicalRed = Color.red
    public static let sportsOrange = Color.orange
    public static let activityPurple = Color.purple
    public static let accent = Color.accentColor

    public static func forEventCategory(_ category: String) -> Color {
        switch category {
        case "CustodyBlue": custodyBlue
        case "SchoolGreen": schoolGreen
        case "MedicalRed": medicalRed
        case "SportsOrange": sportsOrange
        case "ActivityPurple": activityPurple
        default: Color.secondary
        }
    }
}

public enum CGSpacing {
    public static let xxs: CGFloat = 4
    public static let xs: CGFloat = 8
    public static let sm: CGFloat = 12
    public static let md: CGFloat = 16
    public static let lg: CGFloat = 24
    public static let xl: CGFloat = 32
    public static let xxl: CGFloat = 48
}

public enum CGRadius {
    public static let sm: CGFloat = 8
    public static let md: CGFloat = 12
    public static let lg: CGFloat = 16
    public static let xl: CGFloat = 24
    public static let full: CGFloat = 999
}

public enum CGAnimation {
    public static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
    public static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.85)
    public static let gentle = Animation.easeInOut(duration: 0.25)
}

public struct CGGradient {
    public static let hero = LinearGradient(
        colors: [Color.accentColor.opacity(0.15), Color.accentColor.opacity(0.02)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let card = LinearGradient(
        colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
        startPoint: .top,
        endPoint: .bottom
    )
}
