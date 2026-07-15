import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundFeatures

@main
struct CommonGroundApp: App {
    @State private var appState = AppState()
    @State private var securityService = SecurityService()
    @State private var localization = LocalizationManager.shared

    private let sharedModelContainer: ModelContainer = {
        do {
            return try ModelContainerFactory.makePreferred()
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(securityService)
                .environment(localization)
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(appState.preferredColorScheme)
                .environment(\.locale, localization.locale)
                .tint(Color("BrandPrimary", bundle: .main))
                .id(localization.language.rawValue)
        }
    }
}
