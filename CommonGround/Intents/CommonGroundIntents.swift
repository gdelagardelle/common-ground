import AppIntents

struct CommonGroundShortcuts: AppShortcutsProvider {
    @AppShortcutsBuilder
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextExchangeIntent(),
            phrases: [
                "When is the next exchange in \(.applicationName)",
                "Next custody exchange in \(.applicationName)",
            ],
            shortTitle: "Next Exchange",
            systemImageName: "arrow.left.arrow.right"
        )
        AppShortcut(
            intent: UnpaidExpensesIntent(),
            phrases: [
                "Show unpaid expenses in \(.applicationName)",
                "What do I owe in \(.applicationName)",
            ],
            shortTitle: "Unpaid Expenses",
            systemImageName: "dollarsign.circle"
        )
        AppShortcut(
            intent: AskFamilyAIIntent(),
            phrases: [
                "Ask \(.applicationName) about my family",
                "Ask \(.applicationName) a question",
            ],
            shortTitle: "Ask AI",
            systemImageName: "sparkles"
        )
    }
}

struct NextExchangeIntent: AppIntent {
    static var title: LocalizedStringResource { "Next Custody Exchange" }
    static var description: IntentDescription { IntentDescription("Shows when the next custody exchange is scheduled.") }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Your next custody exchange is in 2 days at the school parking lot.")
    }
}

struct UnpaidExpensesIntent: AppIntent {
    static var title: LocalizedStringResource { "Unpaid Expenses" }
    static var description: IntentDescription { IntentDescription("Shows outstanding shared expenses.") }
    static var openAppWhenRun: Bool { true }

    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "You have 1 unpaid expense totaling $33.75 for school supplies.")
    }
}

struct AskFamilyAIIntent: AppIntent {
    static var title: LocalizedStringResource { "Ask Family AI" }
    static var description: IntentDescription { IntentDescription("Ask a question about your family's records.") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Question")
    var question: String?

    func perform() async throws -> some IntentResult & ProvidesDialog {
        let q = question ?? "What's happening this week?"
        return .result(dialog: "I'll help you with: \(q). Opening Common Ground.")
    }
}

struct OpenChildProfileIntent: AppIntent {
    static var title: LocalizedStringResource { "Open Child Profile" }
    static var description: IntentDescription { IntentDescription("Opens a child's profile.") }
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Child Name")
    var childName: String

    func perform() async throws -> some IntentResult {
        .result()
    }
}
