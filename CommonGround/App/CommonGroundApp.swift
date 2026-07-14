import SwiftUI
import SwiftData
import CommonGroundCore
import CommonGroundFeatures

@main
struct CommonGroundApp: App {
    @State private var appState = AppState()
    @State private var securityService = SecurityService()

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
                .modelContainer(sharedModelContainer)
                .preferredColorScheme(appState.preferredColorScheme)
        }
    }
}
