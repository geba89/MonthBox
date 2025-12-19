import SwiftUI
import SwiftData

struct EditIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var income: Income

    @State private var name: String
    @State private var amount: String
    @State private var date: Date
    @State private var isRecurring: Bool
    @State private var showingDeleteConfirmation = false

    init(income: Income) {
        self.income = income
        _name = State(initialValue: income.name)
        _amount = State(initialValue: String(income.amount))
        _date = State(initialValue: income.date)
        _isRecurring = State(initialValue: income.isRecurring)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Income source", text: $name)

                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Toggle("Recurring Monthly", isOn: $isRecurring)
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Income")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveIncome()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .confirmationDialog("Delete Income?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(income)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func saveIncome() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        income.name = name
        income.amount = amountValue
        income.date = date
        income.isRecurring = isRecurring

        dismiss()
    }
}

#Preview {
    let income = Income(name: "Salary", amount: 5000, isRecurring: true)
    return EditIncomeView(income: income)
        .modelContainer(for: Income.self, inMemory: true)
}
