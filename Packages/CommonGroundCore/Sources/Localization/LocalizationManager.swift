import Foundation
import Observation

@MainActor
@Observable
public final class LocalizationManager {
    public static let shared = LocalizationManager()

    public private(set) var language: AppLanguage

    public var locale: Locale {
        language.locale ?? Locale.current
    }

    private init() {
        language = AppLanguagePreferences.storedLanguage
    }

    public func apply(language: AppLanguage) {
        self.language = language
    }
}
