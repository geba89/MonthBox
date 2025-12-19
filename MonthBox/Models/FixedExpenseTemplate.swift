import Foundation
import SwiftData

/// Template for recurring fixed expenses that auto-populate each month
@Model
final class FixedExpenseTemplate {
    var id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var dueDay: Int
    var isActive: Bool
    var createdAt: Date

    init(
        name: String,
        amount: Double,
        category: ExpenseCategory = .bills,
        dueDay: Int = 1,
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.dueDay = dueDay
        self.isActive = isActive
        self.createdAt = Date()
    }

    /// Create an expense from this template for a given month
    func createExpense(for monthYear: String) -> Expense {
        Expense(
            name: name,
            amount: amount,
            category: category,
            isFixed: true,
            dueDay: dueDay,
            isPaid: false,
            monthYear: monthYear
        )
    }
}
