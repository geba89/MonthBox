import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var allExpenses: [Expense]
    @Query private var allIncome: [Income]
    @Query(filter: #Predicate<FixedExpenseTemplate> { $0.isActive })
    private var activeTemplates: [FixedExpenseTemplate]

    @State private var currentDate = Date()
    @State private var activeSheet: ActiveSheet?

    enum ActiveSheet: Identifiable {
        case addExpense
        case addIncome

        var id: Int { hashValue }
    }

    private var currentMonthYear: String {
        currentDate.monthYearString
    }

    private var expenses: [Expense] {
        allExpenses.filter { $0.monthYear == currentMonthYear }
    }

    private var income: [Income] {
        allIncome.filter { $0.monthYear == currentMonthYear }
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var totalIncome: Double {
        income.reduce(0) { $0 + $1.amount }
    }

    private var totalExpenses: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }

    private var paidExpenses: Double {
        expenses.filter { $0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var unpaidExpenses: Double {
        expenses.filter { !$0.isPaid }.reduce(0) { $0 + $1.amount }
    }

    private var remainingBudget: Double {
        totalIncome - paidExpenses
    }

    private var projectedRemaining: Double {
        totalIncome - totalExpenses
    }

    private var budgetHealth: BudgetHealth {
        if projectedRemaining < 0 {
            return .danger
        } else if projectedRemaining < totalIncome * 0.1 {
            return .warning
        } else {
            return .good
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Month Navigation
                    monthNavigator

                    // Budget Summary Card
                    budgetSummaryCard

                    // Quick Stats
                    quickStatsSection

                    // Upcoming Bills
                    upcomingBillsSection

                    // Quick Actions
                    quickActionsSection
                }
                .padding()
            }
            .navigationTitle("Budget")
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addExpense:
                    AddExpenseView(monthYear: currentMonthYear)
                case .addIncome:
                    AddIncomeView(monthYear: currentMonthYear)
                }
            }
            .onAppear {
                populateMonthIfNeeded()
            }
            .onChange(of: currentMonthYear) { _, _ in
                populateMonthIfNeeded()
            }
        }
    }

    // MARK: - Populate Month
    private func populateMonthIfNeeded() {
        // Check if this month has already been initialized
        let initializedMonthsKey = "initializedMonths"
        var initializedMonths = UserDefaults.standard.stringArray(forKey: initializedMonthsKey) ?? []

        // If already initialized, don't re-populate (respects deletions)
        if initializedMonths.contains(currentMonthYear) {
            return
        }

        let monthExpenses = allExpenses.filter { $0.monthYear == currentMonthYear }
        let monthIncome = allIncome.filter { $0.monthYear == currentMonthYear }

        // Get previous month's data
        let previousMonthYear = currentDate.addingMonths(-1).monthYearString
        let previousMonthExpenses = allExpenses.filter { $0.monthYear == previousMonthYear }
        let previousMonthIncome = allIncome.filter { $0.monthYear == previousMonthYear }

        // Get existing expense names in current month
        let existingExpenseNames = Set(monthExpenses.map { $0.name })

        // 1. Create fixed expenses from templates (if not already exist)
        for template in activeTemplates {
            if !existingExpenseNames.contains(template.name) {
                let expense = template.createExpense(for: currentMonthYear)
                modelContext.insert(expense)
            }
        }

        // 2. Copy fixed expenses from previous month (if not already exist and not from template)
        let templateNames = Set(activeTemplates.map { $0.name })
        let fixedExpensesFromPrevMonth = previousMonthExpenses.filter { $0.isFixed && !templateNames.contains($0.name) }

        for expense in fixedExpensesFromPrevMonth {
            if !existingExpenseNames.contains(expense.name) {
                let newExpense = Expense(
                    name: expense.name,
                    amount: expense.amount,
                    category: expense.category,
                    isFixed: true,
                    dueDay: expense.dueDay,
                    isPaid: false,
                    monthYear: currentMonthYear
                )
                modelContext.insert(newExpense)
            }
        }

        // 3. Copy recurring income from previous month (if not already exist)
        let existingIncomeNames = Set(monthIncome.map { $0.name })
        let recurringIncomeFromPrevMonth = previousMonthIncome.filter { $0.isRecurring }

        for income in recurringIncomeFromPrevMonth {
            if !existingIncomeNames.contains(income.name) {
                let newIncome = Income(
                    name: income.name,
                    amount: income.amount,
                    date: currentDate.startOfMonth,
                    isRecurring: true,
                    monthYear: currentMonthYear
                )
                modelContext.insert(newIncome)
            }
        }

        // Mark this month as initialized
        initializedMonths.append(currentMonthYear)
        UserDefaults.standard.set(initializedMonths, forKey: initializedMonthsKey)
    }

    // MARK: - Month Navigator
    private var monthNavigator: some View {
        HStack {
            Button {
                withAnimation {
                    currentDate = currentDate.addingMonths(-1)
                }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }

            Spacer()

            Text(currentDate.displayMonthYear)
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button {
                withAnimation {
                    currentDate = currentDate.addingMonths(1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title2)
                    .foregroundStyle(.primary)
            }
        }
        .padding(.horizontal)
    }

    // MARK: - Budget Summary Card
    private var budgetSummaryCard: some View {
        VStack(spacing: 16) {
            Text("Available to Spend")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(remainingBudget.formatted(currencyCode: userSettings.currencyCode))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundColor(remainingBudget >= 0 ? .primary : .red)

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 12)

                    if totalIncome > 0 {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                            .frame(width: min(geometry.size.width * (paidExpenses / totalIncome), geometry.size.width), height: 12)
                    }
                }
            }
            .frame(height: 12)

            HStack {
                Text("Paid: \(paidExpenses.formatted(currencyCode: userSettings.currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()

                Text("Income: \(totalIncome.formatted(currencyCode: userSettings.currencyCode))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if unpaidExpenses > 0 {
                HStack {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundStyle(.orange)
                        .font(.caption)
                    Text("Pending bills: \(unpaidExpenses.formatted(currencyCode: userSettings.currencyCode))")
                        .font(.caption)
                        .foregroundStyle(.orange)
                    Spacer()
                    Text("After all: \(projectedRemaining.formatted(currencyCode: userSettings.currencyCode))")
                        .font(.caption)
                        .foregroundStyle(budgetHealth.color)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Income",
                value: totalIncome.formatted(currencyCode: userSettings.currencyCode),
                icon: "arrow.down.circle.fill",
                color: .green
            )

            StatCard(
                title: "Expenses",
                value: totalExpenses.formatted(currencyCode: userSettings.currencyCode),
                icon: "arrow.up.circle.fill",
                color: .red
            )
        }
    }

    // MARK: - Upcoming Bills Section
    private var upcomingBillsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Upcoming Bills")
                    .font(.headline)
                Spacer()
                NavigationLink {
                    ExpenseListView()
                } label: {
                    Text("See All")
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                }
            }

            let unpaidBills = expenses.filter { !$0.isPaid }.prefix(3)

            if unpaidBills.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.largeTitle)
                            .foregroundStyle(.green)
                        Text("All bills paid!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    Spacer()
                }
            } else {
                ForEach(Array(unpaidBills), id: \.id) { expense in
                    UpcomingBillRow(expense: expense, currencyCode: userSettings.currencyCode)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    // MARK: - Quick Actions Section
    private var quickActionsSection: some View {
        HStack(spacing: 12) {
            Button {
                activeSheet = .addExpense
            } label: {
                Label("Add Expense", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }

            Button {
                activeSheet = .addIncome
            } label: {
                Label("Add Income", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Budget Health
enum BudgetHealth {
    case good, warning, danger

    var color: Color {
        switch self {
        case .good: return .green
        case .warning: return .orange
        case .danger: return .red
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

// MARK: - Upcoming Bill Row
struct UpcomingBillRow: View {
    @Environment(\.modelContext) private var modelContext
    let expense: Expense
    let currencyCode: String

    var body: some View {
        HStack {
            Image(systemName: expense.category.icon)
                .foregroundStyle(categoryColor)
                .frame(width: 32, height: 32)
                .background(categoryColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                if let dueDay = expense.dueDay {
                    Text("Due: \(dueDay)th")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Text(expense.amount.formatted(currencyCode: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)

            Button {
                withAnimation {
                    expense.markAsPaid()
                }
            } label: {
                Image(systemName: "circle")
                    .font(.title2)
                    .foregroundStyle(.gray)
            }
        }
        .padding(.vertical, 4)
    }

    private var categoryColor: Color {
        switch expense.category.color {
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "green": return .green
        default: return .gray
        }
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [Expense.self, Income.self, UserSettings.self, FixedExpenseTemplate.self], inMemory: true)
}
