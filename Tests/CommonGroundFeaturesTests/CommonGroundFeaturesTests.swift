import Testing
import CommonGroundCore

@Suite("App State")
struct AppStateTests {
    @Test("Default tab is home")
    @MainActor
    func defaultTab() {
        let state = AppState()
        #expect(state.selectedTab == .home)
    }

    @Test("All tabs have icons")
    func tabIcons() {
        for tab in AppTab.allCases {
            #expect(!tab.icon.isEmpty)
            #expect(!tab.title.isEmpty)
        }
    }
}

@Suite("Custody Patterns")
struct CustodyTests {
    @Test("All patterns have descriptions")
    func patternDescriptions() {
        for pattern in CustodyPattern.allCases {
            #expect(!pattern.displayName.isEmpty)
            #expect(!pattern.description.isEmpty)
        }
    }
}

@Suite("Timeline Categories")
struct TimelineTests {
    @Test("Categories have icons")
    func categoryIcons() {
        for category in TimelineCategory.allCases {
            #expect(!category.icon.isEmpty)
            #expect(!category.displayName.isEmpty)
        }
    }
}
