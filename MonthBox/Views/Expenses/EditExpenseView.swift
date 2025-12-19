import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var expense: Expense

    @State private var name: String
    @State private var amount: String
    @State private var category: ExpenseCategory
    @State private var isFixed: Bool
    @State private var dueDay: Int
    @State private var showingDeleteConfirmation = false

    init(expense: Expense) {
        self.expense = expense
        _name = State(initialValue: expense.name)
        _amount = State(initialValue: String(expense.amount))
        _category = State(initialValue: expense.category)
        _isFixed = State(initialValue: expense.isFixed)
        _dueDay = State(initialValue: expense.dueDay ?? 1)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Expense name", text: $name)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
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
                }

                Section {
                    HStack {
                        Text("Status")
                        Spacer()
                        Text(expense.isPaid ? "Paid" : "Unpaid")
                            .foregroundStyle(expense.isPaid ? .green : .orange)
                    }

                    if expense.isPaid, let paidDate = expense.paidDate {
                        HStack {
                            Text("Paid Date")
                            Spacer()
                            Text(paidDate.shortDateString)
                                .foregroundStyle(.secondary)
                        }
                    }

                    Button {
                        withAnimation {
                            if expense.isPaid {
                                expense.markAsUnpaid()
                            } else {
                                expense.markAsPaid()
                            }
                        }
                    } label: {
                        Text(expense.isPaid ? "Mark as Unpaid" : "Mark as Paid")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Expense")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveExpense()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .confirmationDialog("Delete Expense?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(expense)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func saveExpense() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        expense.name = name
        expense.amount = amountValue
        expense.category = category
        expense.isFixed = isFixed
        expense.dueDay = isFixed ? dueDay : nil

        dismiss()
    }
}

#Preview {
    let expense = Expense(name: "Netflix", amount: 15.99, category: .entertainment, isFixed: true, dueDay: 15)
    return EditExpenseView(expense: expense)
        .modelContainer(for: Expense.self, inMemory: true)
}
