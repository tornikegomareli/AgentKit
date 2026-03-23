import Foundation
import Observation

/// Mock banking service that simulates a real banking backend.
/// All financial operations happen in-memory for demo purposes.
@Observable
final class BankingService {
    var accounts: [Account] = Account.samples
    var transactions: [Transaction] = Transaction.samples()
    var payees: [Payee] = Payee.samples
    var scheduledPayments: [ScheduledPayment] = ScheduledPayment.samples()
    var activityLog: [ActivityEntry] = []

    // MARK: - Activity Log

    struct ActivityEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let description: String
        let type: EntryType

        enum EntryType {
            case readOnly
            case proposed
            case confirmed
            case warning
        }

        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: timestamp)
        }
    }

    private func log(_ description: String, type: ActivityEntry.EntryType = .readOnly) {
        activityLog.insert(
            ActivityEntry(timestamp: Date(), description: description, type: type),
            at: 0
        )
    }

    // MARK: - Account Queries

    func account(byId id: String) -> Account? {
        accounts.first { $0.id == id }
    }

    func accountSummary() -> String {
        log("Viewed account balances")
        return accounts.map { acc in
            "\(acc.name) (••\(acc.lastFourDigits)): \(acc.formattedBalance)"
        }.joined(separator: "\n")
    }

    func totalBalance() -> Double {
        accounts.reduce(0) { $0 + $1.balance }
    }

    // MARK: - Transaction Queries

    func transactionsForAccount(_ accountId: String, limit: Int = 10) -> [Transaction] {
        transactions
            .filter { $0.accountId == accountId }
            .sorted { $0.date > $1.date }
            .prefix(limit)
            .map { $0 }
    }

    func recentTransactions(limit: Int = 15) -> String {
        log("Viewed recent transactions")
        let recent = transactions
            .sorted { $0.date > $1.date }
            .prefix(limit)

        return recent.map { txn in
            "\(txn.formattedDate) · \(txn.merchant) · \(txn.formattedAmount) (\(txn.category.rawValue))"
        }.joined(separator: "\n")
    }

    func transactionHistory(accountId: String, limit: Int = 10) -> String {
        let txns = transactionsForAccount(accountId, limit: limit)
        guard !txns.isEmpty else { return "No transactions found for this account." }

        let account = account(byId: accountId)
        log("Viewed transactions for \(account?.name ?? accountId)")

        return txns.map { txn in
            "\(txn.formattedDate) · \(txn.merchant) · \(txn.formattedAmount) · \(txn.category.rawValue)"
        }.joined(separator: "\n")
    }

    // MARK: - Spending Analysis

    func analyzeSpending(months: Int = 1, accountId: String? = nil) -> String {
        let cal = Calendar.current
        let cutoff = cal.date(byAdding: .month, value: -months, to: Date()) ?? Date()

        var filtered = transactions.filter { $0.date >= cutoff && $0.amount < 0 }
        if let accountId {
            filtered = filtered.filter { $0.accountId == accountId }
        }

        guard !filtered.isEmpty else {
            return "No spending data found for the requested period."
        }

        // Group by category
        var categoryTotals: [Transaction.Category: Double] = [:]
        for txn in filtered {
            categoryTotals[txn.category, default: 0] += abs(txn.amount)
        }

        let totalSpend = categoryTotals.values.reduce(0, +)
        let sorted = categoryTotals.sorted { $0.value > $1.value }

        var result = "Spending analysis (last \(months) month\(months > 1 ? "s" : "")):\n"
        result += String(format: "Total spent: GEL %.2f\n\n", totalSpend)

        for (category, amount) in sorted {
            let pct = (amount / totalSpend) * 100
            result += String(format: "  %@ — GEL %.2f (%.0f%%)\n", category.rawValue, amount, pct)
        }

        // Top merchants
        var merchantTotals: [String: Double] = [:]
        for txn in filtered {
            merchantTotals[txn.merchant, default: 0] += abs(txn.amount)
        }
        let topMerchants = merchantTotals.sorted { $0.value > $1.value }.prefix(5)

        result += "\nTop merchants:\n"
        for (merchant, amount) in topMerchants {
            result += String(format: "  %@ — GEL %.2f\n", merchant, amount)
        }

        log("Spending analysis — \(months) month\(months > 1 ? "s" : "")")
        return result
    }

    // MARK: - Recurring Charges

    func findRecurringCharges() -> String {
        let subscriptions = transactions.filter { $0.category == .subscriptions }
        guard !subscriptions.isEmpty else { return "No recurring charges found." }

        log("Identified recurring charges")

        // Deduplicate by merchant
        var seen: Set<String> = []
        var unique: [Transaction] = []
        for txn in subscriptions {
            if !seen.contains(txn.merchant) {
                seen.insert(txn.merchant)
                unique.append(txn)
            }
        }

        let total = unique.reduce(0.0) { $0 + abs($1.amount) }
        var result = "Recurring charges / subscriptions:\n"
        for txn in unique {
            result += String(format: "  %@ — GEL %.2f/month\n", txn.merchant, abs(txn.amount))
        }
        result += String(format: "\nTotal monthly subscriptions: GEL %.2f", total)
        return result
    }

    // MARK: - Transfer

    func transferFunds(fromAccountId: String, toAccountId: String, amount: Double, reference: String) -> String {
        guard let fromIndex = accounts.firstIndex(where: { $0.id == fromAccountId }) else {
            return "Source account not found: \(fromAccountId)"
        }
        guard let toIndex = accounts.firstIndex(where: { $0.id == toAccountId }) else {
            return "Destination account not found: \(toAccountId)"
        }
        guard amount > 0 else {
            return "Transfer amount must be positive."
        }
        guard accounts[fromIndex].balance >= amount else {
            return String(format: "Insufficient funds. Available balance: GEL %.2f, requested: GEL %.2f",
                          accounts[fromIndex].balance, amount)
        }

        // Execute transfer
        accounts[fromIndex].balance -= amount
        accounts[toIndex].balance += amount

        let fromName = accounts[fromIndex].name
        let toName = accounts[toIndex].name

        // Record transactions
        let debitTxn = Transaction(
            id: "TXN-\(Int.random(in: 10000...99999))",
            accountId: fromAccountId,
            description: "Transfer to \(toName) — \(reference)",
            amount: -amount,
            category: .transfer,
            date: Date(),
            merchant: "Internal"
        )
        let creditTxn = Transaction(
            id: "TXN-\(Int.random(in: 10000...99999))",
            accountId: toAccountId,
            description: "Transfer from \(fromName) — \(reference)",
            amount: amount,
            category: .transfer,
            date: Date(),
            merchant: "Internal"
        )
        transactions.insert(debitTxn, at: 0)
        transactions.insert(creditTxn, at: 0)

        log("Transfer GEL \(String(format: "%.2f", amount)) from \(fromName) to \(toName)", type: .confirmed)

        return String(format: """
            Transfer completed successfully.
            FROM: %@ (••%@)
            TO: %@ (••%@)
            AMOUNT: GEL %.2f
            REFERENCE: %@

            New balance of %@: GEL %.2f
            """,
            fromName, accounts[fromIndex].lastFourDigits,
            toName, accounts[toIndex].lastFourDigits,
            amount,
            reference,
            fromName, accounts[fromIndex].balance
        )
    }

    // MARK: - External Transfer (to payee)

    func payPayee(payeeId: String, fromAccountId: String, amount: Double, reference: String) -> String {
        guard let payee = payees.first(where: { $0.id == payeeId }) else {
            return "Payee not found: \(payeeId)"
        }
        guard let fromIndex = accounts.firstIndex(where: { $0.id == fromAccountId }) else {
            return "Source account not found: \(fromAccountId)"
        }
        guard amount > 0 else {
            return "Payment amount must be positive."
        }
        guard accounts[fromIndex].balance >= amount else {
            return String(format: "Insufficient funds. Available: GEL %.2f", accounts[fromIndex].balance)
        }

        accounts[fromIndex].balance -= amount

        let txn = Transaction(
            id: "TXN-\(Int.random(in: 10000...99999))",
            accountId: fromAccountId,
            description: "Payment to \(payee.name) — \(reference)",
            amount: -amount,
            category: .transfer,
            date: Date(),
            merchant: payee.name
        )
        transactions.insert(txn, at: 0)

        let isLarge = amount >= 1000
        log("Payment GEL \(String(format: "%.2f", amount)) to \(payee.name)\(isLarge ? " ⚠️ LARGE" : "")", type: isLarge ? .warning : .confirmed)

        return String(format: """
            Payment sent successfully.
            TO: %@ (%@) at %@
            FROM: %@ (••%@)
            AMOUNT: GEL %.2f
            REFERENCE: %@
            %@
            New balance: GEL %.2f
            """,
            payee.name, payee.maskedIBAN, payee.bankName,
            accounts[fromIndex].name, accounts[fromIndex].lastFourDigits,
            amount,
            reference,
            isLarge ? "\n⚠️ This was a large transaction above GEL 1,000." : "",
            accounts[fromIndex].balance
        )
    }

    // MARK: - Scheduled Payments

    func listScheduledPayments() -> String {
        guard !scheduledPayments.isEmpty else { return "No scheduled payments." }
        log("Viewed scheduled payments")
        return scheduledPayments.map { sp in
            "\(sp.id): \(sp.formattedAmount) to \(sp.payeeName) — \(sp.frequency.rawValue), next: \(sp.formattedNextDate) (\(sp.reference))"
        }.joined(separator: "\n")
    }

    func cancelScheduledPayment(paymentId: String) -> String {
        guard let index = scheduledPayments.firstIndex(where: { $0.id == paymentId }) else {
            return "Scheduled payment not found: \(paymentId)"
        }
        let payment = scheduledPayments.remove(at: index)
        log("Cancelled scheduled payment \(payment.id) to \(payment.payeeName)", type: .confirmed)
        return "Cancelled scheduled payment \(payment.id): \(payment.formattedAmount) to \(payment.payeeName) (\(payment.reference))"
    }

    // MARK: - Payee Management

    func listPayees() -> String {
        log("Viewed payees list")
        return payees.map { p in
            "\(p.id): \(p.name) — \(p.maskedIBAN) at \(p.bankName)\(p.isVerified ? " ✓" : "")"
        }.joined(separator: "\n")
    }

    // MARK: - Savings Calculator

    func calculateSavingsGoal(targetAmount: Double, months: Int) -> String {
        let currentSavings = accounts.first(where: { $0.type == .savings })?.balance ?? 0
        let remaining = max(0, targetAmount - currentSavings)
        let monthlyNeeded = remaining / Double(months)
        let weeklyNeeded = remaining / (Double(months) * 4.33)

        // Estimate available from recent spending
        let recentExpenses = transactions
            .filter { $0.amount < 0 && $0.category != .transfer }
            .prefix(30)
        let avgMonthlySpend = recentExpenses.reduce(0.0) { $0 + abs($1.amount) }
        let checkingBalance = accounts.first(where: { $0.type == .checking })?.balance ?? 0
        let estimatedMonthlyIncome = transactions
            .filter { $0.category == .salary }
            .prefix(2)
            .reduce(0.0) { $0 + $1.amount } / 2

        log("Savings goal calculation — GEL \(String(format: "%.0f", targetAmount)) in \(months) months")

        return String(format: """
            Savings Goal Analysis:
            Target: GEL %.2f
            Current savings: GEL %.2f
            Remaining to save: GEL %.2f

            Required rate:
              Monthly: GEL %.2f
              Weekly: GEL %.2f

            Your estimated monthly income: GEL %.2f
            Recent monthly spending: ~GEL %.2f
            Estimated monthly surplus: ~GEL %.2f

            %@
            """,
            targetAmount,
            currentSavings,
            remaining,
            monthlyNeeded,
            weeklyNeeded,
            estimatedMonthlyIncome,
            avgMonthlySpend,
            estimatedMonthlyIncome - avgMonthlySpend,
            monthlyNeeded <= (estimatedMonthlyIncome - avgMonthlySpend)
                ? "✅ This goal looks achievable based on your current spending."
                : "⚠️ You may need to reduce spending by GEL \(String(format: "%.2f", monthlyNeeded - (estimatedMonthlyIncome - avgMonthlySpend)))/month to hit this target."
        )
    }
}
