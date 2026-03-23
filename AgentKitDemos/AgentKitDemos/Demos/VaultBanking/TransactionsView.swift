import SwiftUI

/// Full transaction history with account filtering — dark theme.
struct TransactionsView: View {
    @Environment(BankingService.self) private var bank
    @State private var selectedAccount: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Account filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        filterChip(nil, label: "All Accounts")
                        ForEach(bank.accounts) { account in
                            filterChip(account.id, label: "\(account.name) ••\(account.lastFourDigits)")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
                .background(Color(hex: 0x111620))

                // Transaction list
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedTransactions, id: \.key) { group in
                            // Date header
                            HStack {
                                Text(group.key)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color(hex: 0x556677))
                                Spacer()
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)
                            .padding(.bottom, 6)

                            ForEach(group.value) { txn in
                                transactionRow(txn)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(hex: 0x0C0F14))
            .navigationTitle("Transactions")
            .toolbarBackground(Color(hex: 0x0C0F14), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var filteredTransactions: [Transaction] {
        var result = bank.transactions.sorted { $0.date > $1.date }
        if let selectedAccount {
            result = result.filter { $0.accountId == selectedAccount }
        }
        return result
    }

    private var groupedTransactions: [(key: String, value: [Transaction])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        let grouped = Dictionary(grouping: filteredTransactions) { txn in
            formatter.string(from: txn.date)
        }
        return grouped.sorted { a, b in
            guard let dateA = a.value.first?.date, let dateB = b.value.first?.date else { return false }
            return dateA > dateB
        }
    }

    private func filterChip(_ accountId: String?, label: String) -> some View {
        let isSelected = selectedAccount == accountId
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedAccount = accountId }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: 0x1B6BF3) : Color.white.opacity(0.07))
                .foregroundStyle(isSelected ? .white : Color(hex: 0x8899AA))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func transactionRow(_ txn: Transaction) -> some View {
        HStack(spacing: 12) {
            Image(systemName: txn.category.icon)
                .font(.callout)
                .foregroundStyle(.white)
                .frame(width: 38, height: 38)
                .background(categoryColor(txn.category).opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(txn.merchant)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white)
                Text(txn.category.rawValue)
                    .font(.caption2)
                    .foregroundStyle(Color(hex: 0x556677))
            }

            Spacer()

            Text(txn.formattedAmount)
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(txn.isCredit ? Color(hex: 0x34D399) : Color(hex: 0xF87171))
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func categoryColor(_ category: Transaction.Category) -> Color {
        switch category {
        case .food: return Color(hex: 0xD97706)
        case .transport: return Color(hex: 0x2563EB)
        case .shopping: return Color(hex: 0xDB2777)
        case .utilities: return Color(hex: 0xEA580C)
        case .entertainment: return Color(hex: 0x9333EA)
        case .salary: return Color(hex: 0x059669)
        case .transfer: return Color(hex: 0x0284C7)
        case .subscriptions: return Color(hex: 0x7C3AED)
        case .healthcare: return Color(hex: 0xDC2626)
        case .other: return Color(hex: 0x475569)
        }
    }
}
