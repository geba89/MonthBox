import SwiftUI

struct ExpenseRowView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var expense: Expense
    let currencyCode: String

    @State private var showingEditSheet = false

    var body: some View {
        HStack(spacing: 12) {
            // Checkbox
            Button {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    if expense.isPaid {
                        expense.markAsUnpaid()
                    } else {
                        expense.markAsPaid()
                    }
                }
            } label: {
                Image(systemName: expense.isPaid ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(expense.isPaid ? .green : .gray)
            }
            .buttonStyle(.plain)

            // Category Icon
            Image(systemName: expense.category.icon)
                .foregroundStyle(categoryColor)
                .frame(width: 28, height: 28)
                .background(categoryColor.opacity(0.1))
                .clipShape(Circle())

            // Details
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.name)
                    .font(.body)
                    .strikethrough(expense.isPaid)
                    .foregroundStyle(expense.isPaid ? .secondary : .primary)

                HStack(spacing: 4) {
                    Text(expense.category.rawValue)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if let dueDay = expense.dueDay {
                        Text("Due: \(dueDay)th")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if expense.isPaid, let paidDate = expense.paidDate {
                        Text("Paid \(paidDate.shortDateString)")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }

            Spacer()

            // Amount
            Text(expense.amount.formatted(currencyCode: currencyCode))
                .font(.body)
                .fontWeight(.semibold)
                .foregroundStyle(expense.isPaid ? .secondary : .primary)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showingEditSheet = true
        }
        .sheet(isPresented: $showingEditSheet) {
            EditExpenseView(expense: expense)
        }
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
    let expense = Expense(name: "Netflix", amount: 15.99, category: .entertainment, isFixed: true, dueDay: 15)
    return List {
        ExpenseRowView(expense: expense, currencyCode: "USD")
    }
    .modelContainer(for: Expense.self, inMemory: true)
}
