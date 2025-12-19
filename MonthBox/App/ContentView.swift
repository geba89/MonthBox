import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var selectedTab: Tab = .dashboard

    enum Tab {
        case dashboard
        case expenses
        case income
        case settings
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Budget", systemImage: "chart.pie.fill")
                }
                .tag(Tab.dashboard)

            ExpenseListView()
                .tabItem {
                    Label("Expenses", systemImage: "creditcard.fill")
                }
                .tag(Tab.expenses)

            IncomeListView()
                .tabItem {
                    Label("Income", systemImage: "banknote.fill")
                }
                .tag(Tab.income)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(Tab.settings)
        }
        .onAppear {
            ensureSettingsExist()
        }
    }

    /// Ensure default settings exist
    private func ensureSettingsExist() {
        if settings.isEmpty {
            let defaultSettings = UserSettings()
            modelContext.insert(defaultSettings)
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, Income.self, UserSettings.self, FixedExpenseTemplate.self], inMemory: true)
}
