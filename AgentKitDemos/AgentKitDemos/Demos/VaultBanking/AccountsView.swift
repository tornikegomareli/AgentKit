import SwiftUI

/// Overview of all bank accounts with balances and recent activity — dark theme.
struct AccountsView: View {
    @Environment(BankingService.self) private var bank

    private let cardGradients: [(Color, Color)] = [
        (Color(hex: 0x1B6BF3), Color(hex: 0x3D8BFD)),  // Blue — Checking
        (Color(hex: 0x0EA574), Color(hex: 0x34D399)),  // Green — Savings
        (Color(hex: 0x8B5CF6), Color(hex: 0xA78BFA)),  // Purple — Business
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    totalBalanceCard
                        .padding(.horizontal)

                    ForEach(Array(bank.accounts.enumerated()), id: \.element.id) { index, account in
                        accountCard(account, gradient: cardGradients[index % cardGradients.count])
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(hex: 0x0C0F14))
            .navigationTitle("Vault")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color(hex: 0x0C0F14), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private var totalBalanceCard: some View {
        VStack(spacing: 6) {
            Text("Total Balance")
                .font(.caption.weight(.medium))
                .foregroundStyle(Color(hex: 0x8899AA))
            Text(String(format: "GEL %.2f", bank.totalBalance()))
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .contentTransition(.numericText())
            Text("\(bank.accounts.count) accounts")
                .font(.caption2)
                .foregroundStyle(Color(hex: 0x556677))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .background(Color(hex: 0x151A22))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
    }

    private func accountCard(_ account: Account, gradient: (Color, Color)) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with colored icon
            HStack {
                Image(systemName: account.type.icon)
                    .font(.title2)
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(
                        LinearGradient(colors: [gradient.0, gradient.1], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 2) {
                    Text(account.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text("••\(account.lastFourDigits)")
                        .font(.caption.monospaced())
                        .foregroundStyle(Color(hex: 0x667788))
                }

                Spacer()

                Text(account.formattedBalance)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(gradient.0)
                    .contentTransition(.numericText())
            }

            // Recent transactions
            let recent = bank.transactionsForAccount(account.id, limit: 3)
            if !recent.isEmpty {
                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(height: 1)

                ForEach(recent) { txn in
                    HStack(spacing: 10) {
                        Image(systemName: txn.category.icon)
                            .font(.caption)
                            .foregroundStyle(categoryColor(txn.category))
                            .frame(width: 22)
                        Text(txn.merchant)
                            .font(.caption)
                            .foregroundStyle(Color(hex: 0x99AABB))
                        Spacer()
                        Text(txn.formattedAmount)
                            .font(.caption.weight(.semibold).monospacedDigit())
                            .foregroundStyle(txn.isCredit ? Color(hex: 0x34D399) : Color(hex: 0xF87171))
                    }
                }
            }
        }
        .padding(16)
        .background(Color(hex: 0x151A22))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(gradient.0.opacity(0.2), lineWidth: 1)
        )
    }

    private func categoryColor(_ category: Transaction.Category) -> Color {
        switch category {
        case .food: return Color(hex: 0xFBBF24)
        case .transport: return Color(hex: 0x60A5FA)
        case .shopping: return Color(hex: 0xF472B6)
        case .utilities: return Color(hex: 0xFB923C)
        case .entertainment: return Color(hex: 0xC084FC)
        case .salary: return Color(hex: 0x34D399)
        case .transfer: return Color(hex: 0x38BDF8)
        case .subscriptions: return Color(hex: 0xA78BFA)
        case .healthcare: return Color(hex: 0xF87171)
        case .other: return Color(hex: 0x94A3B8)
        }
    }
}
