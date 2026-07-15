import SwiftUI

public enum CGModuleAccent {
    case medical, school, expenses, documents, timeline, emergency, daily, messages, calendar
}

// MARK: - Brand palette (Calm Clarity + vivid accents)

public enum CGColor {
    // Core brand
    public static let primary = Color(red: 0.263, green: 0.388, blue: 0.922)       // #4363EB
    public static let primaryDark = Color(red: 0.216, green: 0.188, blue: 0.639)  // #3730A3
    public static let sky = Color(red: 0.420, green: 0.647, blue: 0.980)           // #6BA5FA
    public static let coral = Color(red: 0.976, green: 0.451, blue: 0.486)         // #F9737C
    public static let mint = Color(red: 0.298, green: 0.851, blue: 0.722)          // #4CD9B8
    public static let lavender = Color(red: 0.655, green: 0.545, blue: 0.980)      // #A78BFA
    public static let accent = primary

    // Surfaces
    public static let warmSand = Color(red: 0.961, green: 0.941, blue: 0.910)      // #F5F0E8
    public static let warmHighlight = Color(red: 0.973, green: 0.957, blue: 0.933) // #F8F4EE
    public static let elevatedSurface = Color(.secondarySystemGroupedBackground)
    public static let canvas = Color(.systemGroupedBackground)
    public static let shadow = Color.black.opacity(0.08)

    // Daily updates & warmth
    public static let warmAmber = Color(red: 0.910, green: 0.647, blue: 0.294)      // #E8A54B
    public static let warmAmberSoft = warmAmber.opacity(0.18)

    // Semantic category colors
    public static let custodyBlue = primary
    public static let schoolGreen = Color(red: 0.204, green: 0.659, blue: 0.325)   // #34A853
    public static let medicalRed = Color(red: 0.878, green: 0.322, blue: 0.322)    // #E05252
    public static let sportsOrange = warmAmber
    public static let activityPurple = Color(red: 0.486, green: 0.435, blue: 0.875) // #7C6FDF
    public static let birthdayPink = Color(red: 0.910, green: 0.459, blue: 0.663)
    public static let holidayYellow = Color(red: 0.918, green: 0.773, blue: 0.251)
    public static let appointmentTeal = Color(red: 0.302, green: 0.714, blue: 0.675)
    public static let exchangeIndigo = primaryDark
    public static let neutralGray = Color.secondary

    public static func forEventCategory(_ category: String) -> Color {
        switch category {
        case "CustodyBlue": custodyBlue
        case "SchoolGreen": schoolGreen
        case "MedicalRed": medicalRed
        case "SportsOrange": sportsOrange
        case "ActivityPurple": activityPurple
        case "BirthdayPink": birthdayPink
        case "HolidayYellow": holidayYellow
        case "AppointmentTeal": appointmentTeal
        case "ExchangeIndigo": exchangeIndigo
        case "NeutralGray": neutralGray
        default: neutralGray
        }
    }

    public static func moduleGradient(_ module: CGModuleAccent) -> LinearGradient {
        switch module {
        case .medical:
            LinearGradient(colors: [medicalRed, coral], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .school:
            LinearGradient(colors: [schoolGreen, mint], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .expenses:
            LinearGradient(colors: [mint, appointmentTeal], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .documents:
            LinearGradient(colors: [primary, sky], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .timeline:
            LinearGradient(colors: [activityPurple, lavender], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .emergency:
            LinearGradient(colors: [warmAmber, coral], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .daily:
            LinearGradient(colors: [warmAmber, birthdayPink], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .messages:
            LinearGradient(colors: [sky, primary], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .calendar:
            LinearGradient(colors: [primaryDark, activityPurple], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

// MARK: - Typography

public enum CGTypography {
    public static let display = Font.system(.largeTitle, design: .rounded).weight(.bold)
    public static let title = Font.system(.title2, design: .rounded).weight(.semibold)
    public static let section = Font.system(.title3, design: .rounded).weight(.semibold)
    public static let headline = Font.system(.headline, design: .rounded).weight(.semibold)
    public static let body = Font.body
    public static let caption = Font.caption
    public static let captionEmphasis = Font.caption.weight(.medium)
}

// MARK: - Spacing & radius

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
    public static let xl: CGFloat = 20
    public static let xxl: CGFloat = 24
    public static let full: CGFloat = 999
}

// MARK: - Motion

public enum CGAnimation {
    public static let quick = Animation.spring(response: 0.3, dampingFraction: 0.8)
    public static let smooth = Animation.spring(response: 0.45, dampingFraction: 0.85)
    public static let gentle = Animation.easeInOut(duration: 0.25)
}

// MARK: - Gradients

public struct CGGradient {
    public static let hero = LinearGradient(
        colors: [
            CGColor.primary.opacity(0.28),
            CGColor.sky.opacity(0.18),
            CGColor.lavender.opacity(0.12),
            CGColor.warmAmber.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let heroHeader = LinearGradient(
        colors: [
            CGColor.primary.opacity(0.35),
            CGColor.sky.opacity(0.22),
            CGColor.coral.opacity(0.12),
            Color.clear
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let aurora = LinearGradient(
        colors: [CGColor.primary, CGColor.sky, CGColor.lavender, CGColor.coral.opacity(0.85)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let sunset = LinearGradient(
        colors: [CGColor.warmAmber, CGColor.coral, CGColor.birthdayPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let avatar = LinearGradient(
        colors: [CGColor.primary, CGColor.sky, CGColor.lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let warmFeed = LinearGradient(
        colors: [CGColor.warmSand.opacity(0.75), CGColor.warmAmber.opacity(0.15), CGColor.birthdayPink.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let brandSplash = LinearGradient(
        colors: [CGColor.primary, CGColor.primaryDark, CGColor.activityPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let cardShine = LinearGradient(
        colors: [Color.white.opacity(0.22), Color.clear],
        startPoint: .topLeading,
        endPoint: .center
    )

    public static func avatarRing(seed: String) -> AngularGradient {
        let palettes: [[Color]] = [
            [CGColor.primary, CGColor.sky, CGColor.lavender, CGColor.coral, CGColor.primary],
            [CGColor.warmAmber, CGColor.coral, CGColor.birthdayPink, CGColor.lavender, CGColor.warmAmber],
            [CGColor.schoolGreen, CGColor.mint, CGColor.sky, CGColor.primary, CGColor.schoolGreen],
            [CGColor.activityPurple, CGColor.primary, CGColor.coral, CGColor.warmAmber, CGColor.activityPurple]
        ]
        let index = abs(seed.hashValue) % palettes.count
        return AngularGradient(colors: palettes[index], center: .center)
    }

    public static func avatarFill(seed: String) -> LinearGradient {
        let palettes: [[Color]] = [
            [CGColor.primary, CGColor.sky],
            [CGColor.coral, CGColor.birthdayPink],
            [CGColor.mint, CGColor.schoolGreen],
            [CGColor.lavender, CGColor.activityPurple],
            [CGColor.warmAmber, CGColor.coral]
        ]
        let index = abs(seed.hashValue) % palettes.count
        let colors = palettes[index]
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    public static func quickAction(_ emphasis: CGQuickAction.Emphasis) -> LinearGradient {
        switch emphasis {
        case .primary:
            LinearGradient(colors: [CGColor.primary.opacity(0.22), CGColor.sky.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .warm:
            LinearGradient(colors: [CGColor.warmAmber.opacity(0.28), CGColor.coral.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .mint:
            LinearGradient(colors: [CGColor.mint.opacity(0.28), CGColor.schoolGreen.opacity(0.14)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .purple:
            LinearGradient(colors: [CGColor.lavender.opacity(0.32), CGColor.activityPurple.opacity(0.16)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .neutral:
            LinearGradient(colors: [Color.secondary.opacity(0.14), Color.secondary.opacity(0.06)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
