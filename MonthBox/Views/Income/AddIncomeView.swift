import SwiftUI
import SwiftData

struct AddIncomeView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let monthYear: String

    @State private var name = ""
    @State private var amount = ""
    @State private var date = Date()
    @State private var isRecurring = false

    @FocusState private var focusedField: Field?

    enum Field {
        case name, amount
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Income source", text: $name)
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
                    DatePicker("Date", selection: $date, displayedComponents: .date)

                    Toggle("Recurring Monthly", isOn: $isRecurring)
                } footer: {
                    Text("Recurring income will be suggested to add at the start of each month.")
                }
            }
            .navigationTitle("Add Income")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addIncome()
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

    private func addIncome() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        let income = Income(
            name: name,
            amount: amountValue,
            date: date,
            isRecurring: isRecurring,
            monthYear: monthYear
        )

        modelContext.insert(income)
        dismiss()
    }
}

#Preview {
    AddIncomeView(monthYear: Date().monthYearString)
        .modelContainer(for: Income.self, inMemory: true)
}
