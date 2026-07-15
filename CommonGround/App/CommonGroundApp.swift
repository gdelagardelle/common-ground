import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundFeatures

@main
struct CommonGroundApp: App {
    @UIApplicationDelegateAdaptor(CommonGroundAppDelegate.self) private var appDelegate

    @Environment(\.scenePhase) private var scenePhase
    @State private var appState = AppState()
    @State private var securityService = SecurityService()
    @State private var aiService = AIAssistantService()
    @State private var localization = LocalizationManager.shared
    @State private var deepLinks = DeepLinkCoordinator()
    @State private var containerState = AppContainerState()

    var body: some Scene {
        WindowGroup {
            Group {
                if let container = containerState.container {
                    RootView()
                        .environment(appState)
                        .environment(securityService)
                        .environment(aiService)
                        .environment(localization)
                        .environment(deepLinks)
                        .modelContainer(container)
                        .preferredColorScheme(appState.preferredColorScheme)
                        .environment(\.locale, localization.locale)
                        .tint(Color("BrandPrimary", bundle: .main))
                        .id(localization.language.rawValue)
                        .onOpenURL { url in
                            deepLinks.handle(url)
                        }
                } else if let error = containerState.lastError {
                    PersistenceRecoveryView(error: error) {
                        containerState.reload()
                    }
                } else {
                    ProgressView(L10n.commonLoading)
                }
            }
            .task {
                if containerState.container == nil {
                    containerState.reload()
                }
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .background {
                    securityService.lock()
                }
            }
        }
    }
}

@MainActor
@Observable
private final class AppContainerState {
    var container: ModelContainer?
    var lastError: Error?

    func reload() {
        do {
            container = try ModelContainerFactory.makePreferred()
            lastError = nil
        } catch {
            container = nil
            lastError = error
        }
    }
}
