import XCTest
import SwiftData
@testable import MonthBox

final class MonthBoxTests: XCTestCase {

    var modelContainer: ModelContainer!
    var modelContext: ModelContext!

    override func setUpWithError() throws {
        let schema = Schema([
            Expense.self,
            Income.self,
            UserSettings.self,
            FixedExpenseTemplate.self
        ])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        modelContainer = try ModelContainer(for: schema, configurations: [config])
        modelContext = ModelContext(modelContainer)
    }

    override func tearDownWithError() throws {
        modelContainer = nil
        modelContext = nil
    }

    // MARK: - Expense Tests

    func testCreateExpense() throws {
        let expense = Expense(
            name: "Test Expense",
            amount: 100.50,
            category: .bills,
            isFixed: true,
            dueDay: 15
        )

        modelContext.insert(expense)

        XCTAssertEqual(expense.name, "Test Expense")
        XCTAssertEqual(expense.amount, 100.50)
        XCTAssertEqual(expense.category, .bills)
        XCTAssertTrue(expense.isFixed)
        XCTAssertEqual(expense.dueDay, 15)
        XCTAssertFalse(expense.isPaid)
    }

    func testMarkExpenseAsPaid() throws {
        let expense = Expense(name: "Test", amount: 50)

        XCTAssertFalse(expense.isPaid)
        XCTAssertNil(expense.paidDate)

        expense.markAsPaid()

        XCTAssertTrue(expense.isPaid)
        XCTAssertNotNil(expense.paidDate)
    }

    func testMarkExpenseAsUnpaid() throws {
        let expense = Expense(name: "Test", amount: 50)
        expense.markAsPaid()

        XCTAssertTrue(expense.isPaid)

        expense.markAsUnpaid()

        XCTAssertFalse(expense.isPaid)
        XCTAssertNil(expense.paidDate)
    }

    // MARK: - Income Tests

    func testCreateIncome() throws {
        let income = Income(
            name: "Salary",
            amount: 5000,
            isRecurring: true
        )

        modelContext.insert(income)

        XCTAssertEqual(income.name, "Salary")
        XCTAssertEqual(income.amount, 5000)
        XCTAssertTrue(income.isRecurring)
    }

    // MARK: - UserSettings Tests

    func testDefaultSettings() throws {
        let settings = UserSettings()

        XCTAssertEqual(settings.currencyCode, "USD")
        XCTAssertEqual(settings.monthStartDay, 1)
    }

    func testCurrencySymbol() throws {
        let settings = UserSettings(currencyCode: "EUR")
        // Currency symbol depends on locale, just verify it's not empty
        XCTAssertFalse(settings.currencySymbol.isEmpty)
    }

    // MARK: - FixedExpenseTemplate Tests

    func testCreateExpenseFromTemplate() throws {
        let template = FixedExpenseTemplate(
            name: "Netflix",
            amount: 15.99,
            category: .entertainment,
            dueDay: 15
        )

        let expense = template.createExpense(for: "2024-12")

        XCTAssertEqual(expense.name, "Netflix")
        XCTAssertEqual(expense.amount, 15.99)
        XCTAssertEqual(expense.category, .entertainment)
        XCTAssertTrue(expense.isFixed)
        XCTAssertEqual(expense.dueDay, 15)
        XCTAssertEqual(expense.monthYear, "2024-12")
        XCTAssertFalse(expense.isPaid)
    }

    // MARK: - Date Extension Tests

    func testMonthYearString() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: "2024-12-15")!

        XCTAssertEqual(date.monthYearString, "2024-12")
    }

    func testDisplayMonthYear() throws {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let date = formatter.date(from: "2024-12-15")!

        XCTAssertEqual(date.displayMonthYear, "December 2024")
    }

    // MARK: - Budget Calculation Tests

    func testBudgetCalculation() throws {
        let income1 = Income(name: "Salary", amount: 5000, monthYear: "2024-12")
        let income2 = Income(name: "Freelance", amount: 1000, monthYear: "2024-12")

        let expense1 = Expense(name: "Rent", amount: 1500, monthYear: "2024-12")
        let expense2 = Expense(name: "Groceries", amount: 500, monthYear: "2024-12")

        let totalIncome = income1.amount + income2.amount
        let totalExpenses = expense1.amount + expense2.amount
        let remaining = totalIncome - totalExpenses

        XCTAssertEqual(totalIncome, 6000)
        XCTAssertEqual(totalExpenses, 2000)
        XCTAssertEqual(remaining, 4000)
    }

    // MARK: - Category Tests

    func testExpenseCategoryIcon() throws {
        XCTAssertEqual(ExpenseCategory.bills.icon, "doc.text.fill")
        XCTAssertEqual(ExpenseCategory.food.icon, "fork.knife")
        XCTAssertEqual(ExpenseCategory.transport.icon, "car.fill")
        XCTAssertEqual(ExpenseCategory.shopping.icon, "bag.fill")
        XCTAssertEqual(ExpenseCategory.entertainment.icon, "tv.fill")
        XCTAssertEqual(ExpenseCategory.other.icon, "ellipsis.circle.fill")
    }

    func testExpenseCategoryColor() throws {
        XCTAssertEqual(ExpenseCategory.bills.color, "blue")
        XCTAssertEqual(ExpenseCategory.food.color, "orange")
        XCTAssertEqual(ExpenseCategory.transport.color, "purple")
        XCTAssertEqual(ExpenseCategory.shopping.color, "pink")
        XCTAssertEqual(ExpenseCategory.entertainment.color, "green")
        XCTAssertEqual(ExpenseCategory.other.color, "gray")
    }
}
