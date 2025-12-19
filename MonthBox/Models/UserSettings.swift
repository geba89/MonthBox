import Foundation
import SwiftData

/// User preferences and settings
@Model
final class UserSettings {
    var id: UUID
    var currencyCode: String
    var monthStartDay: Int
    var createdAt: Date

    init(
        currencyCode: String = "USD",
        monthStartDay: Int = 1
    ) {
        self.id = UUID()
        self.currencyCode = currencyCode
        self.monthStartDay = monthStartDay
        self.createdAt = Date()
    }

    /// Get currency symbol from currency code
    var currencySymbol: String {
        let locale = Locale(identifier: Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: currencyCode]))
        return locale.currencySymbol ?? "$"
    }

    /// Available currencies
    static let availableCurrencies: [(code: String, name: String)] = [
        ("USD", "US Dollar"),
        ("EUR", "Euro"),
        ("GBP", "British Pound"),
        ("PLN", "Polish Zloty"),
        ("CAD", "Canadian Dollar"),
        ("AUD", "Australian Dollar"),
        ("JPY", "Japanese Yen"),
        ("CHF", "Swiss Franc"),
        ("SEK", "Swedish Krona"),
        ("NOK", "Norwegian Krone"),
        ("DKK", "Danish Krone"),
        ("CZK", "Czech Koruna"),
        ("HUF", "Hungarian Forint"),
        ("INR", "Indian Rupee"),
        ("CNY", "Chinese Yuan"),
        ("BRL", "Brazilian Real"),
        ("MXN", "Mexican Peso")
    ]
}
