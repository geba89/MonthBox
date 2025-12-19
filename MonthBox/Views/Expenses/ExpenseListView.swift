import SwiftUI
import SwiftData

struct ExpenseListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.createdAt, order: .reverse) private var allExpenses: [Expense]
    @Query private var settings: [UserSettings]

    @State private var currentDate = Date()
    @State private var showingAddExpense = false
    @State private var filterPaidStatus: PaidFilter = .all

    enum PaidFilter: String, CaseIterable {
        case all = "All"
        case unpaid = "Unpaid"
        case paid = "Paid"
    }

    private var currentMonthYear: String {
        currentDate.monthYearString
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var filteredExpenses: [Expense] {
        let monthExpenses = allExpenses.filter { $0.monthYear == currentMonthYear }

        switch filterPaidStatus {
        case .all:
            return monthExpenses
        case .unpaid:
            return monthExpenses.filter { !$0.isPaid }
        case .paid:
            return monthExpenses.filter { $0.isPaid }
        }
    }

    private var fixedExpenses: [Expense] {
        filteredExpenses.filter { $0.isFixed }
    }

    private var variableExpenses: [Expense] {
        filteredExpenses.filter { !$0.isFixed }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Navigator
                monthNavigator
                    .padding()

                // Filter
                filterPicker
                    .padding(.horizontal)

                // Expense List
                List {
                    if !fixedExpenses.isEmpty {
                        Section("Fixed Bills") {
                            ForEach(fixedExpenses) { expense in
                                ExpenseRowView(expense: expense, currencyCode: userSettings.currencyCode)
                            }
                            .onDelete { indexSet in
                                deleteExpenses(from: fixedExpenses, at: indexSet)
                            }
                        }
                    }

                    if !variableExpenses.isEmpty {
                        Section("Variable Expenses") {
                            ForEach(variableExpenses) { expense in
                                ExpenseRowView(expense: expense, currencyCode: userSettings.currencyCode)
                            }
                            .onDelete { indexSet in
                                deleteExpenses(from: variableExpenses, at: indexSet)
                            }
                        }
                    }

                    if filteredExpenses.isEmpty {
                        Section {
                            ContentUnavailableView(
                                "No Expenses",
                                systemImage: "creditcard",
                                description: Text("Add your first expense to start tracking your budget.")
                            )
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Expenses")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddExpense = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(monthYear: currentMonthYear)
            }
        }
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
                    .font(.title3)
            }

            Spacer()

            Text(currentDate.displayMonthYear)
                .font(.headline)

            Spacer()

            Button {
                withAnimation {
                    currentDate = currentDate.addingMonths(1)
                }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.title3)
            }
        }
    }

    // MARK: - Filter Picker
    private var filterPicker: some View {
        Picker("Filter", selection: $filterPaidStatus) {
            ForEach(PaidFilter.allCases, id: \.self) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(.segmented)
    }

    private func deleteExpenses(from expenses: [Expense], at offsets: IndexSet) {
        for index in offsets {
            let expense = expenses[index]
            modelContext.delete(expense)
        }
    }
}

#Preview {
    ExpenseListView()
        .modelContainer(for: [Expense.self, Income.self, UserSettings.self, FixedExpenseTemplate.self], inMemory: true)
}
