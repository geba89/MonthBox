import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var templates: [FixedExpenseTemplate]

    @State private var showingAddTemplate = false

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    var body: some View {
        NavigationStack {
            List {
                // Currency Section
                Section("Currency") {
                    Picker("Currency", selection: Binding(
                        get: { userSettings.currencyCode },
                        set: { userSettings.currencyCode = $0 }
                    )) {
                        ForEach(UserSettings.availableCurrencies, id: \.code) { currency in
                            Text("\(currency.name) (\(currency.code))")
                                .tag(currency.code)
                        }
                    }
                }

                // Month Settings
                Section {
                    Picker("Month Starts On", selection: Binding(
                        get: { userSettings.monthStartDay },
                        set: { userSettings.monthStartDay = $0 }
                    )) {
                        Text("1st").tag(1)
                        Text("15th").tag(15)
                        ForEach([5, 10, 20, 25], id: \.self) { day in
                            Text("\(day)th").tag(day)
                        }
                    }
                } header: {
                    Text("Month Settings")
                } footer: {
                    Text("Choose when your budget month starts. Useful if you get paid mid-month.")
                }

                // Fixed Expense Templates
                Section {
                    ForEach(templates) { template in
                        TemplateRowView(template: template)
                    }
                    .onDelete(perform: deleteTemplates)

                    Button {
                        showingAddTemplate = true
                    } label: {
                        Label("Add Fixed Expense", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Fixed Monthly Bills")
                } footer: {
                    Text("These expenses automatically appear each month. You just need to mark them as paid.")
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }

                    Link(destination: URL(string: "mailto:support@monthbox.app")!) {
                        HStack {
                            Text("Contact Support")
                            Spacer()
                            Image(systemName: "envelope")
                                .foregroundStyle(.secondary)
                        }
                    }

                    Link(destination: URL(string: "https://monthbox.app/privacy")!) {
                        HStack {
                            Text("Privacy Policy")
                            Spacer()
                            Image(systemName: "hand.raised")
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Data Section
                Section("Your Data") {
                    HStack {
                        Image(systemName: "lock.shield.fill")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Privacy First")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("All your data stays on your device. We never see your financial information.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showingAddTemplate) {
                AddTemplateView()
            }
        }
    }

    private func deleteTemplates(at offsets: IndexSet) {
        for index in offsets {
            let template = templates[index]
            modelContext.delete(template)
        }
    }
}

// MARK: - Template Row View
struct TemplateRowView: View {
    @Bindable var template: FixedExpenseTemplate
    @State private var showingEditSheet = false
    @Query private var settings: [UserSettings]

    private var userSettings: UserSettings {
        settings.first ?? UserSettings()
    }

    var body: some View {
        HStack {
            Image(systemName: template.category.icon)
                .foregroundStyle(categoryColor)
                .frame(width: 28, height: 28)
                .background(categoryColor.opacity(0.1))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(template.name)
                    .font(.body)
                Text("Due: \(template.dueDay)th")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(template.amount.formatted(currencyCode: userSettings.currencyCode))
                .font(.body)
                .fontWeight(.medium)

            Toggle("", isOn: $template.isActive)
                .labelsHidden()
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditTemplateView(template: template)
        }
    }

    private var categoryColor: Color {
        switch template.category.color {
        case "blue": return .blue
        case "orange": return .orange
        case "purple": return .purple
        case "pink": return .pink
        case "green": return .green
        default: return .gray
        }
    }
}

// MARK: - Add Template View
struct AddTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var amount = ""
    @State private var category: ExpenseCategory = .bills
    @State private var dueDay = 1

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bill name", text: $name)

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

                    Picker("Due Day", selection: $dueDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }
            }
            .navigationTitle("Add Fixed Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        addTemplate()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
        }
    }

    private func addTemplate() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        let template = FixedExpenseTemplate(
            name: name,
            amount: amountValue,
            category: category,
            dueDay: dueDay
        )

        modelContext.insert(template)
        dismiss()
    }
}

// MARK: - Edit Template View
struct EditTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Bindable var template: FixedExpenseTemplate

    @State private var name: String
    @State private var amount: String
    @State private var category: ExpenseCategory
    @State private var dueDay: Int
    @State private var showingDeleteConfirmation = false

    init(template: FixedExpenseTemplate) {
        self.template = template
        _name = State(initialValue: template.name)
        _amount = State(initialValue: String(template.amount))
        _category = State(initialValue: template.category)
        _dueDay = State(initialValue: template.dueDay)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Bill name", text: $name)

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

                    Picker("Due Day", selection: $dueDay) {
                        ForEach(1...31, id: \.self) { day in
                            Text("\(day)").tag(day)
                        }
                    }
                }

                Section {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Template")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Fixed Bill")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(name.isEmpty || amount.isEmpty)
                }
            }
            .confirmationDialog("Delete Template?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    modelContext.delete(template)
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will not delete existing expenses created from this template.")
            }
        }
    }

    private func saveTemplate() {
        guard let amountValue = Double(amount.replacingOccurrences(of: ",", with: ".")) else {
            return
        }

        template.name = name
        template.amount = amountValue
        template.category = category
        template.dueDay = dueDay

        dismiss()
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Expense.self, Income.self, UserSettings.self, FixedExpenseTemplate.self], inMemory: true)
}
