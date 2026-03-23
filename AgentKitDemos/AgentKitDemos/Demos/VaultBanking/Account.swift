import Foundation

/// A bank account in the Vault demo.
struct Account: Identifiable, Hashable {
    let id: String
    let name: String
    let type: AccountType
    var balance: Double
    let currency: String = "GEL"
    let lastFourDigits: String

    enum AccountType: String, CaseIterable, Hashable {
        case checking = "Checking"
        case savings = "Savings"
        case business = "Business"

        var icon: String {
            switch self {
            case .checking: return "creditcard.fill"
            case .savings: return "banknote.fill"
            case .business: return "building.columns.fill"
            }
        }
    }

    var formattedBalance: String {
        String(format: "%@ %.2f", currency, balance)
    }
}

extension Account {
    static let samples: [Account] = [
        Account(
            id: "ACC-001",
            name: "Personal Checking",
            type: .checking,
            balance: 12_480.00,
            lastFourDigits: "4521"
        ),
        Account(
            id: "ACC-002",
            name: "Savings",
            type: .savings,
            balance: 8_200.00,
            lastFourDigits: "8890"
        ),
        Account(
            id: "ACC-003",
            name: "Business Account",
            type: .business,
            balance: 24_600.00,
            lastFourDigits: "8820"
        ),
    ]
}
