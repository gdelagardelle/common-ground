import SwiftUI
import CommonGroundCore

@main
struct CommonGroundWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchHomeView()
        }
    }
}

struct WatchHomeView: View {
    var body: some View {
        NavigationStack {
            List {
                Section(L10n.watchToday) {
                    Label(L10n.format("custody.withParent", "Sarah"), systemImage: "house.fill")
                    Label(L10n.watchDemoExchangeIn, systemImage: "arrow.left.arrow.right")
                }

                Section(L10n.watchReminders) {
                    Label(L10n.watchDemoSoccer, systemImage: "sportscourt.fill")
                    Label(L10n.watchDemoMedication, systemImage: "pills.fill")
                }

                Section {
                    NavigationLink {
                        Text(L10n.watchAskAIHint)
                            .font(.caption)
                    } label: {
                        Label(L10n.homeActionAskAI, systemImage: "sparkles")
                    }
                }
            }
            .navigationTitle("Emma")
        }
    }
}

#Preview {
    WatchHomeView()
}
