import Foundation

/// A scheduled or recurring payment in the Vault demo.
struct ScheduledPayment: Identifiable, Hashable {
    let id: String
    let payeeName: String
    let amount: Double
    let fromAccountId: String
    let frequency: Frequency
    let nextDate: Date
    let reference: String

    enum Frequency: String, Hashable {
        case once = "One-time"
        case weekly = "Weekly"
        case monthly = "Monthly"

        var icon: String {
            switch self {
            case .once: return "1.circle"
            case .weekly: return "calendar.badge.clock"
            case .monthly: return "calendar"
            }
        }
    }

    var formattedAmount: String {
        String(format: "GEL %.2f", amount)
    }

    var formattedNextDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: nextDate)
    }
}

extension ScheduledPayment {
    static func samples(relativeTo now: Date = Date()) -> [ScheduledPayment] {
        let cal = Calendar.current
        return [
            ScheduledPayment(
                id: "SCH-001",
                payeeName: "Giorgi Beridze",
                amount: 800.00,
                fromAccountId: "ACC-001",
                frequency: .monthly,
                nextDate: cal.date(byAdding: .day, value: 8, to: now) ?? now,
                reference: "Rent — April"
            ),
            ScheduledPayment(
                id: "SCH-002",
                payeeName: "Energo-Pro Georgia",
                amount: 85.00,
                fromAccountId: "ACC-001",
                frequency: .monthly,
                nextDate: cal.date(byAdding: .day, value: 15, to: now) ?? now,
                reference: "Electricity"
            ),
            ScheduledPayment(
                id: "SCH-003",
                payeeName: "Nino Kapanadze",
                amount: 200.00,
                fromAccountId: "ACC-001",
                frequency: .once,
                nextDate: cal.date(byAdding: .day, value: 3, to: now) ?? now,
                reference: "Birthday gift"
            ),
        ]
    }
}
