import SwiftUI

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
                Section("Today") {
                    Label("With Sarah", systemImage: "house.fill")
                    Label("Exchange in 2 days", systemImage: "arrow.left.arrow.right")
                }

                Section("Reminders") {
                    Label("Soccer practice", systemImage: "sportscourt.fill")
                    Label("Zyrtec 5mg", systemImage: "pills.fill")
                }

                Section {
                    NavigationLink {
                        Text("Ask AI on iPhone for full answers.")
                            .font(.caption)
                    } label: {
                        Label("Ask AI", systemImage: "sparkles")
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
