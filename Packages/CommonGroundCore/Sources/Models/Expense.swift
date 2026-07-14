import Foundation
import SwiftData

@Model
public final class Expense {
    @Attribute(.unique) public var id: UUID
    public var title: String
    public var amount: Decimal
    public var currency: String
    public var category: ExpenseCategory
    public var paidByMemberId: UUID
    public var paidByName: String
    public var splitRatio: Double
    public var isReimbursed: Bool
    public var reimbursedAt: Date?
    public var receiptData: Data?
    public var notes: String?
    public var date: Date
    public var createdAt: Date

    public var child: Child?

    public var owedAmount: Decimal {
        guard !isReimbursed else { return 0 }
        let share = Decimal(splitRatio)
        return amount * share
    }

    public init(
        title: String,
        amount: Decimal,
        category: ExpenseCategory,
        paidByMemberId: UUID,
        paidByName: String,
        splitRatio: Double = 0.5,
        date: Date = Date()
    ) {
        self.id = UUID()
        self.title = title
        self.amount = amount
        self.currency = "USD"
        self.category = category
        self.paidByMemberId = paidByMemberId
        self.paidByName = paidByName
        self.splitRatio = splitRatio
        self.isReimbursed = false
        self.date = date
        self.createdAt = Date()
    }
}

public enum ExpenseCategory: String, Codable, CaseIterable, Sendable {
    case school
    case medical
    case sports
    case activities
    case clothing
    case allowance
    case childcare
    case travel
    case food
    case other

    public var displayName: String {
        switch self {
        case .school: "School"
        case .medical: "Medical"
        case .sports: "Sports"
        case .activities: "Activities"
        case .clothing: "Clothing"
        case .allowance: "Allowance"
        case .childcare: "Childcare"
        case .travel: "Travel"
        case .food: "Food"
        case .other: "Other"
        }
    }

    public var icon: String {
        switch self {
        case .school: "book.fill"
        case .medical: "cross.case.fill"
        case .sports: "sportscourt.fill"
        case .activities: "theatermasks.fill"
        case .clothing: "tshirt.fill"
        case .allowance: "dollarsign.circle.fill"
        case .childcare: "figure.and.child.holdinghands"
        case .travel: "airplane"
        case .food: "fork.knife"
        case .other: "creditcard.fill"
        }
    }
}
