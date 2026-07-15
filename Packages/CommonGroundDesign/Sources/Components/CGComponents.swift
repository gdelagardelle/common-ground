import SwiftUI
import CommonGroundCore

// MARK: - Card

public struct CGCard<Content: View>: View {
    let content: Content
    var padding: CGFloat
    var style: Style

    public enum Style {
        case elevated
        case warm
        case aurora
        case flat
    }

    public init(
        padding: CGFloat = CGSpacing.md,
        style: Style = .elevated,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.style = style
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(background, in: RoundedRectangle(cornerRadius: CGRadius.lg, style: .continuous))
            .overlay {
                if style == .warm {
                    RoundedRectangle(cornerRadius: CGRadius.lg, style: .continuous)
                        .strokeBorder(
                            LinearGradient(
                                colors: [CGColor.warmAmber.opacity(0.35), CGColor.coral.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                } else if style == .aurora {
                    RoundedRectangle(cornerRadius: CGRadius.lg, style: .continuous)
                        .strokeBorder(CGGradient.aurora.opacity(0.45), lineWidth: 1)
                }
            }
            .overlay {
                if style != .flat {
                    RoundedRectangle(cornerRadius: CGRadius.lg, style: .continuous)
                        .fill(CGGradient.cardShine)
                        .allowsHitTesting(false)
                }
            }
            .shadow(color: style == .flat ? .clear : CGColor.shadow, radius: 10, y: 3)
    }

    private var background: AnyShapeStyle {
        switch style {
        case .elevated:
            AnyShapeStyle(CGColor.elevatedSurface)
        case .warm:
            AnyShapeStyle(CGGradient.warmFeed)
        case .aurora:
            AnyShapeStyle(CGGradient.aurora.opacity(0.12))
        case .flat:
            AnyShapeStyle(Color.clear)
        }
    }
}

// MARK: - Section header

public struct CGSectionHeader: View {
    let title: String
    var action: String?
    var onAction: (() -> Void)?

    public init(_ title: String, action: String? = nil, onAction: (() -> Void)? = nil) {
        self.title = title
        self.action = action
        self.onAction = onAction
    }

    public var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(CGTypography.section)
                .foregroundStyle(.primary)
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(CGTypography.captionEmphasis)
                    .foregroundStyle(CGColor.primary)
            }
        }
    }
}

// MARK: - Empty state

public struct CGEmptyState: View {
    let icon: String
    let title: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    public init(icon: String, title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: CGSpacing.md) {
            Image(systemName: icon)
                .font(.system(size: 44, weight: .medium))
                .foregroundStyle(CGColor.primary.opacity(0.45))
                .symbolEffect(.pulse, options: .repeating.speed(0.3))

            Text(title)
                .font(CGTypography.section)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
                    .tint(CGColor.primary)
                    .padding(.top, CGSpacing.xs)
            }
        }
        .padding(CGSpacing.xl)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Avatar

public struct CGAvatar: View {
    let name: String
    var imageData: Data?
    var genmojiData: Data?
    var emoji: String?
    var size: CGFloat
    var showGradientRing: Bool

    public init(
        name: String,
        imageData: Data? = nil,
        genmojiData: Data? = nil,
        emoji: String? = nil,
        size: CGFloat = 44,
        showGradientRing: Bool = true
    ) {
        self.name = name
        self.imageData = imageData
        self.genmojiData = genmojiData
        self.emoji = emoji
        self.size = size
        self.showGradientRing = showGradientRing
    }

    public var body: some View {
        ZStack {
            avatarContent
                .frame(width: innerSize, height: innerSize)
                .clipShape(Circle())

            if showGradientRing {
                Circle()
                    .strokeBorder(CGGradient.avatarRing(seed: name), lineWidth: ringWidth)
            }
        }
        .frame(width: size, height: size)
        .shadow(color: CGColor.primary.opacity(0.2), radius: size > 50 ? 10 : 5, y: 3)
        .accessibilityLabel(name)
    }

    @ViewBuilder
    private var avatarContent: some View {
        if let imageData, let uiImage = UIImage(data: imageData) {
            Image(uiImage: uiImage)
                .resizable()
                .scaledToFill()
        } else if let genmojiData {
            CGGenmojiImage(data: genmojiData, size: innerSize)
                .background(CGGradient.avatarFill(seed: name))
        } else if let emoji, !emoji.isEmpty {
            Text(emoji)
                .font(.system(size: innerSize * 0.52))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CGGradient.avatarFill(seed: name))
        } else {
            Text(name.prefix(1).uppercased())
                .font(.system(size: innerSize * 0.38, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(CGGradient.avatarFill(seed: name))
        }
    }

    private var innerSize: CGFloat {
        showGradientRing ? size - ringWidth * 2 : size
    }

    private var ringWidth: CGFloat {
        size > 60 ? 3.5 : (size > 40 ? 2.5 : 2)
    }
}

// MARK: - Badge

public struct CGBadge: View {
    let text: String
    var color: Color

    public init(_ text: String, color: Color = CGColor.primary) {
        self.text = text
        self.color = color
    }

    public var body: some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, CGSpacing.xs)
            .padding(.vertical, CGSpacing.xxs)
            .background(color.opacity(0.12), in: Capsule())
    }
}

// MARK: - Progress ring

public struct CGProgressRing: View {
    let progress: Double
    var lineWidth: CGFloat

    public init(progress: Double, lineWidth: CGFloat = 6) {
        self.progress = progress
        self.lineWidth = lineWidth
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(Color.secondary.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(CGColor.primary, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(CGAnimation.smooth, value: progress)
        }
        .accessibilityLabel(L10n.a11yProgress)
        .accessibilityValue(L10n.format("a11y.progressPercent", Int(progress * 100)))
    }
}

// MARK: - Search bar

public struct CGSearchBar: View {
    @Binding var text: String
    var placeholder: String

    public init(text: Binding<String>, placeholder: String = "Search") {
        self._text = text
        self.placeholder = placeholder
    }

    public var body: some View {
        HStack(spacing: CGSpacing.xs) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            TextField(placeholder, text: $text)
                .textFieldStyle(.plain)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(L10n.commonClearSearch)
            }
        }
        .padding(CGSpacing.sm)
        .background(CGColor.elevatedSurface, in: RoundedRectangle(cornerRadius: CGRadius.md, style: .continuous))
    }
}

// MARK: - Quick action (unified brand style)

public struct CGQuickAction: View {
    let icon: String
    let title: String
    var emphasis: Emphasis
    let action: () -> Void

    public enum Emphasis {
        case primary
        case warm
        case mint
        case purple
        case neutral
    }

    public init(
        icon: String,
        title: String,
        emphasis: Emphasis = .primary,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.title = title
        self.emphasis = emphasis
        self.action = action
    }

    private var tint: Color {
        switch emphasis {
        case .primary: CGColor.primary
        case .warm: CGColor.warmAmber
        case .mint: CGColor.mint
        case .purple: CGColor.lavender
        case .neutral: Color.secondary
        }
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: CGSpacing.xs) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(tint)
                    .frame(width: 48, height: 48)
                    .background(
                        CGGradient.quickAction(emphasis),
                        in: RoundedRectangle(cornerRadius: CGRadius.md, style: .continuous)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: CGRadius.md, style: .continuous)
                            .strokeBorder(tint.opacity(0.2), lineWidth: 1)
                    }

                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(width: 72)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

// MARK: - Custody week strip

public struct CGCustodyWeekStrip: View {
    let assignments: [Bool]
    var parentAName: String
    var parentBName: String
    var compact: Bool

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    public init(
        assignments: [Bool],
        parentAName: String = "Parent A",
        parentBName: String = "Parent B",
        compact: Bool = false
    ) {
        self.assignments = assignments
        self.parentAName = parentAName
        self.parentBName = parentBName
        self.compact = compact
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: CGSpacing.xs) {
            HStack(spacing: CGSpacing.xs) {
                legendDot(color: CGColor.primary, label: parentAName)
                legendDot(color: CGColor.sky.opacity(0.55), label: parentBName)
            }
            .font(.caption2)
            .foregroundStyle(.secondary)

            HStack(spacing: compact ? 3 : 4) {
                ForEach(0..<min(7, assignments.count), id: \.self) { day in
                    let isParentA = assignments[day]
                    let isToday = day == todayOffset

                    RoundedRectangle(cornerRadius: compact ? 6 : 8, style: .continuous)
                        .fill(
                            isParentA
                                ? AnyShapeStyle(LinearGradient(
                                    colors: [CGColor.primary, CGColor.sky],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                                : AnyShapeStyle(LinearGradient(
                                    colors: [CGColor.lavender.opacity(0.45), CGColor.coral.opacity(0.25)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                ))
                        )
                        .frame(height: compact ? 28 : 36)
                        .overlay {
                            Text(dayLabels[day])
                                .font(.caption2.weight(.bold))
                                .foregroundStyle(isParentA ? .white : .primary.opacity(0.7))
                        }
                        .overlay {
                            if isToday {
                                RoundedRectangle(cornerRadius: compact ? 6 : 8, style: .continuous)
                                    .strokeBorder(.white.opacity(0.9), lineWidth: 2)
                            }
                        }
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L10n.a11yCustodyWeek)
    }

    private var todayOffset: Int {
        let weekday = Calendar.current.component(.weekday, from: Date())
        // Monday = 0 … Sunday = 6
        return (weekday + 5) % 7
    }

    private func legendDot(color: Color, label: String) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 6, height: 6)
            Text(label)
        }
    }
}

// MARK: - Trust badge (onboarding, settings)

public struct CGTrustBadge: View {
    let icon: String
    let title: String
    let detail: String

    public init(icon: String, title: String, detail: String) {
        self.icon = icon
        self.title = title
        self.detail = detail
    }

    public var body: some View {
        HStack(alignment: .top, spacing: CGSpacing.sm) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(CGColor.primary)
                .frame(width: 32, height: 32)
                .background(CGColor.primary.opacity(0.1), in: RoundedRectangle(cornerRadius: CGRadius.sm, style: .continuous))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer(minLength: 0)
        }
    }
}

#if canImport(UIKit)
import UIKit
#endif
