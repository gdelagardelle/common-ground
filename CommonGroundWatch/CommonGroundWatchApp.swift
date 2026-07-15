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
    private var snapshot: WidgetSnapshot {
        WidgetDataStore.load() ?? .placeholder
    }

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.watchToday) {
                    Label(L10n.format("custody.withParent", snapshot.currentParent), systemImage: "house.fill")
                    if let exchange = snapshot.nextExchange {
                        Label(
                            exchange.formatted(.relative(presentation: .named)),
                            systemImage: "arrow.left.arrow.right"
                        )
                    } else {
                        Label(L10n.homeNoUpcomingEvents, systemImage: "arrow.left.arrow.right")
                    }
                }

                Section(L10n.watchReminders) {
                    Label(snapshot.nextEvent, systemImage: "calendar")
                }

                Section {
                    Text(L10n.watchOpenOnPhone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle(snapshot.childName)
        }
    }
}

#Preview {
    WatchHomeView()
}
