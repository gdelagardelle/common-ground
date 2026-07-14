import Foundation
import SwiftData

@MainActor
public enum ExpenseService {
    public static func markReimbursed(_ expense: Expense, context: ModelContext) throws {
        expense.isReimbursed = true
        expense.reimbursedAt = Date()
        try context.save()
    }

    public static func settleAll(unpaid: [Expense], context: ModelContext) throws {
        let now = Date()
        for expense in unpaid where !expense.isReimbursed {
            expense.isReimbursed = true
            expense.reimbursedAt = now
        }
        try context.save()
    }

    public static func unsettle(_ expense: Expense, context: ModelContext) throws {
        expense.isReimbursed = false
        expense.reimbursedAt = nil
        try context.save()
    }
}
