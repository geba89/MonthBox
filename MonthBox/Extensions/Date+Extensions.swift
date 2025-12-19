import Foundation

extension Date {
    /// Returns the month-year string in format "2024-12"
    var monthYearString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: self)
    }

    /// Returns a display-friendly month and year string like "December 2024"
    var displayMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: self)
    }

    /// Returns just the day of the month
    var dayOfMonth: Int {
        Calendar.current.component(.day, from: self)
    }

    /// Returns the start of the current month
    var startOfMonth: Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        return calendar.date(from: components) ?? self
    }

    /// Returns the end of the current month
    var endOfMonth: Date {
        let calendar = Calendar.current
        guard let startOfNextMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth) else {
            return self
        }
        return calendar.date(byAdding: .day, value: -1, to: startOfNextMonth) ?? self
    }

    /// Returns date for a specific day in the current month
    func dateForDay(_ day: Int) -> Date? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: self)
        components.day = day
        return calendar.date(from: components)
    }

    /// Add or subtract months from this date
    func addingMonths(_ months: Int) -> Date {
        Calendar.current.date(byAdding: .month, value: months, to: self) ?? self
    }

    /// Check if this date is in the same month as another date
    func isSameMonth(as other: Date) -> Bool {
        let calendar = Calendar.current
        return calendar.isDate(self, equalTo: other, toGranularity: .month)
    }

    /// Short date format for display
    var shortDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter.string(from: self)
    }
}
