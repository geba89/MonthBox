import Foundation
import SwiftData

/// Represents an income entry in the budget
@Model
final class Income {
    var id: UUID
    var name: String
    var amount: Double
    var date: Date
    var isRecurring: Bool
    var monthYear: String // Format: "2024-12" for grouping

    init(
        name: String,
        amount: Double,
        date: Date = Date(),
        isRecurring: Bool = false,
        monthYear: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.amount = amount
        self.date = date
        self.isRecurring = isRecurring
        self.monthYear = monthYear ?? date.monthYearString
    }
}
