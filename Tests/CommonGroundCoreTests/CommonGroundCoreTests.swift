import Testing
@testable import CommonGroundCore

@Suite("Expense Calculations")
struct ExpenseTests {
    @Test("Owed amount calculates split correctly")
    func owedAmountSplit() {
        let expense = Expense(
            title: "Soccer",
            amount: 100,
            category: .sports,
            paidByMemberId: UUID(),
            paidByName: "Sarah",
            splitRatio: 0.5
        )
        #expect(expense.owedAmount == 50)
    }

    @Test("Reimbursed expense owes nothing")
    func reimbursedOwesZero() {
        let expense = Expense(
            title: "School",
            amount: 50,
            category: .school,
            paidByMemberId: UUID(),
            paidByName: "Michael"
        )
        expense.isReimbursed = true
        #expect(expense.owedAmount == 0)
    }
}

@Suite("Message Audit")
struct MessageAuditTests {
    @Test("Audit hash is deterministic")
    func auditHashConsistency() {
        let id = UUID()
        let date = Date(timeIntervalSince1970: 1_700_000_000)
        let hash1 = Message.computeAuditHash(content: "Hello", senderId: id, sentAt: date)
        let hash2 = Message.computeAuditHash(content: "Hello", senderId: id, sentAt: date)
        #expect(hash1 == hash2)
    }

    @Test("Messages are immutable by default")
    func messagesImmutable() {
        let message = Message(content: "Test", senderId: UUID(), senderName: "Sarah")
        #expect(message.isImmutable == true)
        #expect(message.auditHash != nil)
    }
}

@Suite("Member Permissions")
struct PermissionTests {
    @Test("Parent has full permissions")
    func parentPermissions() {
        let perms = MemberPermissions.default(for: .parent)
        #expect(perms.canEditCalendar)
        #expect(perms.canExportRecords)
    }

    @Test("Professional has read-only export")
    func professionalPermissions() {
        let perms = MemberPermissions.default(for: .professional)
        #expect(!perms.canSendMessages)
        #expect(perms.canViewDocuments)
        #expect(perms.canExportRecords)
    }
}

@Suite("AI Assistant")
struct AIAssistantTests {
    @Test("Finds unpaid expenses")
    @MainActor
    func unpaidExpensesQuery() async {
        let service = AIAssistantService()
        let context = AIContext(
            childName: "Emma",
            expenses: [
                ExpenseSnapshot(
                    title: "School Supplies",
                    amount: 50,
                    category: .school,
                    paidByName: "Michael",
                    isReimbursed: false,
                    owedAmount: 25,
                    date: Date()
                ),
            ]
        )
        let result = await service.ask("Show all unpaid expenses", context: context)
        #expect(result.answer.contains("unpaid"))
    }
}
