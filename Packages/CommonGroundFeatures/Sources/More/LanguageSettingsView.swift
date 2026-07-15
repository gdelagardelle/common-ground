import SwiftUI
import CommonGroundCore
import CommonGroundDesign

public struct LanguageSettingsView: View {
    @Environment(LocalizationManager.self) private var localization
    @State private var selection: AppLanguage = AppLanguagePreferences.current

    public init() {}

    public var body: some View {
        Form {
            Section {
                Picker(L10n.languageTitle, selection: $selection) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.localizedDisplayName).tag(language)
                    }
                }
                .pickerStyle(.inline)
                .labelsHidden()
            } footer: {
                Text(L10n.languageFooter)
            }
        }
        .navigationTitle(L10n.languageTitle)
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: selection) { _, newValue in
            AppLanguagePreferences.current = newValue
            localization.apply(language: newValue)
        }
    }
}
