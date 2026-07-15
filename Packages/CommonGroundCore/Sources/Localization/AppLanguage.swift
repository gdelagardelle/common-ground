import Foundation

public enum AppLanguage: String, CaseIterable, Identifiable, Sendable, Codable {
    case system
    case english = "en"
    case german = "de"
    case french = "fr"
    case portuguese = "pt"
    case luxembourgish = "lb"

    public var id: String { rawValue }

    public var locale: Locale? {
        switch self {
        case .system: nil
        case .english: Locale(identifier: "en")
        case .german: Locale(identifier: "de")
        case .french: Locale(identifier: "fr")
        case .portuguese: Locale(identifier: "pt")
        case .luxembourgish: Locale(identifier: "lb")
        }
    }

    public var displayName: String {
        switch self {
        case .system:
            L10nCatalog.translation(for: "language.system", language: .english) ?? "System Language"
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .portuguese: "Português"
        case .luxembourgish: "Lëtzebuergesch"
        }
    }

    public var localizedDisplayName: String {
        switch self {
        case .system: L10n.languageSystem
        case .english: "English"
        case .german: "Deutsch"
        case .french: "Français"
        case .portuguese: "Português"
        case .luxembourgish: "Lëtzebuergesch"
        }
    }
}

public enum AppLanguagePreferences {
    private static let key = "app.preferredLanguage"

    public static var storedLanguage: AppLanguage {
        guard let raw = SharedPreferences.defaults.string(forKey: key),
              let language = AppLanguage(rawValue: raw) else {
            return .system
        }
        return language
    }

    public static var current: AppLanguage {
        get { storedLanguage }
        set {
            SharedPreferences.defaults.set(newValue.rawValue, forKey: key)
            UserDefaults.standard.set(newValue.rawValue, forKey: key)
            Task { @MainActor in
                LocalizationManager.shared.apply(language: newValue)
            }
        }
    }
}
