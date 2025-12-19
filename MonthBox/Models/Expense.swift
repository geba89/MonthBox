import Foundation
import SwiftData

/// Represents an expense entry in the budget
@Model
final class Expense {
    var id: UUID
    var name: String
    var amount: Double
    var category: ExpenseCategory
    var isFixed: Bool
    var dueDay: Int?
    var isPaid: Bool
    var paidDate: Date?
    var createdAt: Date
    var monthYear: String // Format: "2024-12" for grouping

    init(
        name: String,
        amount: Double,
        category: ExpenseCategory = .other,
        isFixed: Bool = false,
        dueDay: Int? = nil,
        isPaid: Bool = false,
        paidDate: Date? = nil,
        monthYear: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.category = category
        self.isFixed = isFixed
        self.dueDay = dueDay
        self.isPaid = isPaid
        self.paidDate = paidDate
        self.createdAt = Date()
        self.monthYear = monthYear ?? Date().monthYearString
    }

    /// Mark expense as paid
    func markAsPaid() {
        isPaid = true
        paidDate = Date()
    }

    /// Mark expense as unpaid
    func markAsUnpaid() {
        isPaid = false
        paidDate = nil
    }
}

/// Categories for organizing expenses
enum ExpenseCategory: String, Codable, CaseIterable {
    case bills = "Bills"
    case food = "Food"
    case transport = "Transport"
    case shopping = "Shopping"
    case entertainment = "Entertainment"
    case other = "Other"

    var icon: String {
        switch self {
        case .bills: return "doc.text.fill"
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .shopping: return "bag.fill"
        case .entertainment: return "tv.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .bills: return "blue"
        case .food: return "orange"
        case .transport: return "purple"
        case .shopping: return "pink"
        case .entertainment: return "green"
        case .other: return "gray"
        }
    }
}
