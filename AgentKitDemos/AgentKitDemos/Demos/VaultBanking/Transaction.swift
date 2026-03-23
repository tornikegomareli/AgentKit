import Foundation

/// A financial transaction in the Vault demo.
struct Transaction: Identifiable, Hashable {
    let id: String
    let accountId: String
    let description: String
    let amount: Double
    let category: Category
    let date: Date
    let merchant: String

    /// Positive = credit, negative = debit.
    var isCredit: Bool { amount > 0 }

    var formattedAmount: String {
        let sign = isCredit ? "+" : ""
        return String(format: "%@GEL %.2f", sign, abs(amount))
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter.string(from: date)
    }

    enum Category: String, CaseIterable, Hashable {
        case food = "Food & Dining"
        case transport = "Transport"
        case shopping = "Shopping"
        case utilities = "Utilities"
        case entertainment = "Entertainment"
        case salary = "Salary"
        case transfer = "Transfer"
        case subscriptions = "Subscriptions"
        case healthcare = "Healthcare"
        case other = "Other"

        var icon: String {
            switch self {
            case .food: return "fork.knife"
            case .transport: return "car.fill"
            case .shopping: return "bag.fill"
            case .utilities: return "bolt.fill"
            case .entertainment: return "film.fill"
            case .salary: return "briefcase.fill"
            case .transfer: return "arrow.left.arrow.right"
            case .subscriptions: return "arrow.clockwise"
            case .healthcare: return "heart.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
}

extension Transaction {
    static func samples(relativeTo now: Date = Date()) -> [Transaction] {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        return [
            // Recent transactions for checking
            Transaction(id: "TXN-001", accountId: "ACC-001", description: "Bolt ride to office", amount: -18.50, category: .transport, date: daysAgo(0), merchant: "Bolt"),
            Transaction(id: "TXN-002", accountId: "ACC-001", description: "Amazon purchase", amount: -220.00, category: .shopping, date: daysAgo(1), merchant: "Amazon"),
            Transaction(id: "TXN-003", accountId: "ACC-001", description: "Monthly salary", amount: 4500.00, category: .salary, date: daysAgo(2), merchant: "Employer LLC"),
            Transaction(id: "TXN-004", accountId: "ACC-001", description: "Transfer to savings", amount: -500.00, category: .transfer, date: daysAgo(3), merchant: "Internal"),
            Transaction(id: "TXN-005", accountId: "ACC-001", description: "Wendy's lunch", amount: -24.00, category: .food, date: daysAgo(3), merchant: "Wendy's"),
            Transaction(id: "TXN-006", accountId: "ACC-001", description: "Netflix subscription", amount: -29.99, category: .subscriptions, date: daysAgo(5), merchant: "Netflix"),
            Transaction(id: "TXN-007", accountId: "ACC-001", description: "Electricity bill", amount: -85.00, category: .utilities, date: daysAgo(6), merchant: "Energo-Pro"),
            Transaction(id: "TXN-008", accountId: "ACC-001", description: "Grocery store", amount: -132.50, category: .food, date: daysAgo(7), merchant: "Carrefour"),
            Transaction(id: "TXN-009", accountId: "ACC-001", description: "Spotify Premium", amount: -14.99, category: .subscriptions, date: daysAgo(8), merchant: "Spotify"),
            Transaction(id: "TXN-010", accountId: "ACC-001", description: "Pharmacy", amount: -45.00, category: .healthcare, date: daysAgo(9), merchant: "GPC Pharmacy"),
            Transaction(id: "TXN-011", accountId: "ACC-001", description: "Restaurant dinner", amount: -78.00, category: .food, date: daysAgo(10), merchant: "Barbarestan"),
            Transaction(id: "TXN-012", accountId: "ACC-001", description: "Uber ride", amount: -12.00, category: .transport, date: daysAgo(11), merchant: "Uber"),
            Transaction(id: "TXN-013", accountId: "ACC-001", description: "Coffee shop", amount: -8.50, category: .food, date: daysAgo(12), merchant: "Starbucks"),
            Transaction(id: "TXN-014", accountId: "ACC-001", description: "Cinema tickets", amount: -32.00, category: .entertainment, date: daysAgo(14), merchant: "Cavea"),
            Transaction(id: "TXN-015", accountId: "ACC-001", description: "Water bill", amount: -35.00, category: .utilities, date: daysAgo(15), merchant: "GWP"),

            // Savings account transactions
            Transaction(id: "TXN-016", accountId: "ACC-002", description: "Transfer from checking", amount: 500.00, category: .transfer, date: daysAgo(3), merchant: "Internal"),
            Transaction(id: "TXN-017", accountId: "ACC-002", description: "Interest earned", amount: 12.30, category: .other, date: daysAgo(15), merchant: "Bank"),

            // Business account transactions
            Transaction(id: "TXN-018", accountId: "ACC-003", description: "Client payment — Acme Corp", amount: 8500.00, category: .salary, date: daysAgo(1), merchant: "Acme Corp"),
            Transaction(id: "TXN-019", accountId: "ACC-003", description: "Cloud hosting — AWS", amount: -420.00, category: .utilities, date: daysAgo(4), merchant: "AWS"),
            Transaction(id: "TXN-020", accountId: "ACC-003", description: "Figma subscription", amount: -45.00, category: .subscriptions, date: daysAgo(5), merchant: "Figma"),
            Transaction(id: "TXN-021", accountId: "ACC-003", description: "Client payment — TechStart", amount: 3200.00, category: .salary, date: daysAgo(10), merchant: "TechStart"),
            Transaction(id: "TXN-022", accountId: "ACC-003", description: "Office supplies", amount: -180.00, category: .shopping, date: daysAgo(12), merchant: "Office Depot"),
        ]
    }
}
