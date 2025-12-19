import SwiftUI
import SwiftData

struct IncomeListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Income.date, order: .reverse) private var allIncome: [Income]
    @Query private var settings: [UserSettings]

    @State private var currentDate = Date()
    @State private var showingAddIncome = false

    private var currentMonthYear: String {
        currentDate.monthYearString
    }

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    private var filteredIncome: [Income] {
        allIncome.filter { $0.monthYear == currentMonthYear }
    }

    private var totalIncome: Double {
        filteredIncome.reduce(0) { $0 + $1.amount }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Month Navigator
                monthNavigator
                    .padding()

                // Total Card
                totalIncomeCard
                    .padding(.horizontal)
                    .padding(.bottom)

                // Income List
                List {
                    if filteredIncome.isEmpty {
                        ContentUnavailableView(
                            "No Income",
                            systemImage: "banknote",
                            description: Text("Add your income to start tracking your budget.")
                        )
                    } else {
                        ForEach(filteredIncome) { income in
                            IncomeRowView(income: income, currencyCode: userSettings.currencyCode)
                        }
                        .onDelete(perform: deleteIncome)
                    }
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Income")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddIncome = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddIncome) {
                AddIncomeView(monthYear: currentMonthYear)
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

    // MARK: - Total Income Card
    private var totalIncomeCard: some View {
        VStack(spacing: 8) {
            Text("Total Income")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(totalIncome.formatted(currencyCode: userSettings.currencyCode))
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundStyle(.green)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }

    private func deleteIncome(at offsets: IndexSet) {
        for index in offsets {
            let income = filteredIncome[index]
            modelContext.delete(income)
        }
    }
}

// MARK: - Income Row View
struct IncomeRowView: View {
    @Environment(\.modelContext) private var modelContext
    let income: Income
    let currencyCode: String

    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: income.isRecurring ? "arrow.triangle.2.circlepath.circle.fill" : "banknote.fill")
                .foregroundStyle(.green)
                .frame(width: 32, height: 32)
                .background(Color.green.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(income.name)
                    .font(.body)

                HStack(spacing: 4) {
                    Text(income.date.shortDateString)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if income.isRecurring {
                        Text("Recurring")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            Text(income.amount.formatted(currencyCode: currencyCode))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(.green)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditIncomeView(income: income)
        }
    }
}

#Preview {
    IncomeListView()
        .modelContainer(for: [Expense.self, Income.self, UserSettings.self, FixedExpenseTemplate.self], inMemory: true)
}
