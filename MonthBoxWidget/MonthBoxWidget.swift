import WidgetKit
import SwiftUI
import SwiftData

// MARK: - Widget Entry
struct BudgetEntry: TimelineEntry {
    let date: Date
    let remainingBudget: Double
    let totalIncome: Double
    let totalExpenses: Double
    let paidExpenses: Double
    let unpaidCount: Int
    let currencyCode: String

    static var placeholder: BudgetEntry {
        BudgetEntry(
            date: Date(),
            remainingBudget: 1847.23,
            totalIncome: 5000,
            totalExpenses: 3152.77,
            paidExpenses: 2000,
            unpaidCount: 3,
            currencyCode: "USD"
        )
    }
}

// MARK: - Timeline Provider
struct BudgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> BudgetEntry {
        BudgetEntry.placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (BudgetEntry) -> Void) {
        let entry = loadBudgetData()
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BudgetEntry>) -> Void) {
        let entry = loadBudgetData()
        // Update every hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func loadBudgetData() -> BudgetEntry {
        // In a real implementation, this would read from the shared SwiftData container
        // For now, return placeholder data
        // To make this work, you'd need to use App Groups to share data between app and widget
        return BudgetEntry.placeholder
    }
}

// MARK: - Small Widget View
struct SmallWidgetView: View {
    let entry: BudgetEntry

    var body: some View {
        VStack(spacing: 4) {
            Text("Budget")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text(entry.remainingBudget.formatted(currencyCode: entry.currencyCode))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(budgetColor)
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            Text("left this month")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var budgetColor: Color {
        if entry.remainingBudget < 0 {
            return .red
        } else if entry.remainingBudget < entry.totalIncome * 0.1 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Medium Widget View
struct MediumWidgetView: View {
    let entry: BudgetEntry

    var body: some View {
        HStack(spacing: 16) {
            // Budget Amount
            VStack(alignment: .leading, spacing: 4) {
                Text("Available")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.remainingBudget.formatted(currencyCode: entry.currencyCode))
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(budgetColor)
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 6)

                        if entry.totalIncome > 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(budgetColor)
                                .frame(width: min(geometry.size.width * (entry.paidExpenses / entry.totalIncome), geometry.size.width), height: 6)
                        }
                    }
                }
                .frame(height: 6)
            }

            Divider()

            // Stats
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "arrow.down.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                    Text(entry.totalIncome.formatted(currencyCode: entry.currencyCode))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                    Text(entry.totalExpenses.formatted(currencyCode: entry.currencyCode))
                        .font(.caption)
                        .fontWeight(.medium)
                }

                if entry.unpaidCount > 0 {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundStyle(.orange)
                            .font(.caption)
                        Text("\(entry.unpaidCount) unpaid")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var budgetColor: Color {
        if entry.remainingBudget < 0 {
            return .red
        } else if entry.remainingBudget < entry.totalIncome * 0.1 {
            return .orange
        } else {
            return .green
        }
    }
}

// MARK: - Large Widget View
struct LargeWidgetView: View {
    let entry: BudgetEntry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("MonthBox")
                    .font(.headline)
                Spacer()
                Text(entry.date.displayMonthYear)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            // Budget Card
            VStack(spacing: 8) {
                Text("Available to Spend")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(entry.remainingBudget.formatted(currencyCode: entry.currencyCode))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(budgetColor)

                // Progress Bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 10)

                        if entry.totalIncome > 0 {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(budgetColor)
                                .frame(width: min(geometry.size.width * (entry.paidExpenses / entry.totalIncome), geometry.size.width), height: 10)
                        }
                    }
                }
                .frame(height: 10)
            }
            .padding()
            .background(Color(.systemBackground).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Stats Row
            HStack(spacing: 20) {
                StatWidget(title: "Income", value: entry.totalIncome, currencyCode: entry.currencyCode, color: .green, icon: "arrow.down.circle.fill")

                StatWidget(title: "Expenses", value: entry.totalExpenses, currencyCode: entry.currencyCode, color: .red, icon: "arrow.up.circle.fill")
            }

            // Footer
            if entry.unpaidCount > 0 {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                    Text("\(entry.unpaidCount) bills unpaid")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .containerBackground(.fill.tertiary, for: .widget)
    }

    private var budgetColor: Color {
        if entry.remainingBudget < 0 {
            return .red
        } else if entry.remainingBudget < entry.totalIncome * 0.1 {
            return .orange
        } else {
            return .green
        }
    }
}

struct StatWidget: View {
    let title: String
    let value: Double
    let currencyCode: String
    let color: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value.formatted(currencyCode: currencyCode))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Widget Configuration
struct MonthBoxWidget: Widget {
    let kind: String = "MonthBoxWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: BudgetProvider()) { entry in
            MonthBoxWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Budget Balance")
        .description("See your remaining budget at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct MonthBoxWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: BudgetEntry

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Widget Bundle
@main
struct MonthBoxWidgetBundle: WidgetBundle {
    var body: some Widget {
        MonthBoxWidget()
    }
}

// MARK: - Extensions for Widget
extension Double {
    func formatted(currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}

extension Date {
    var displayMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }
}

#Preview(as: .systemSmall) {
    MonthBoxWidget()
} timeline: {
    BudgetEntry.placeholder
}

#Preview(as: .systemMedium) {
    MonthBoxWidget()
} timeline: {
    BudgetEntry.placeholder
}

#Preview(as: .systemLarge) {
    MonthBoxWidget()
} timeline: {
    BudgetEntry.placeholder
}
