import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let monthYear: String

    @State private var name = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .other
    @State private var isFixed = false
    @State private var dueDay = 1

    @FocusState private var focusedField: Field?

    enum Field {
        case name, amount
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Expense name", text: $name)
                        .focused($focusedField, equals: .name)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .focused($focusedField, equals: .amount)
                    }
                }

                Section {
                    Picker("Category", selection: $category) {
                        ForEach(ExpenseCategory.allCases, id: \.self) { cat in
                            Label(cat.rawValue, systemImage: cat.icon)
                                .tag(cat)
                        }
                    }
                }

                Section {
                    Toggle("Fixed Monthly Bill", isOn: $isFixed)

                    if isFixed {
                        Picker("Due Day", selection: $dueDay) {
                            ForEach(1...31, id: \.self) { day in
                                Text("\(day)").tag(day)
                            }
                        }
                    }
                } footer: {
                    Text("Fixed bills repeat every month and auto-reset to unpaid at the start of each month.")
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addExpense()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }

                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") {
                        focusedField = nil
                    }
                }
            }
            .onAppear {
                focusedField = .name
            }
        }
    }

    private func addExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        let expense = Expense(
            name: name,
            amount: amountValue,
            category: category,
            isFixed: isFixed,
            dueDay: isFixed ? dueDay : nil,
            monthYear: monthYear
        )

        modelContext.insert(expense)
        dismiss()
    }
}

#Preview {
    AddExpenseView(monthYear: Date().monthYearString)
        .modelContainer(for: Expense.self, inMemory: true)
}
