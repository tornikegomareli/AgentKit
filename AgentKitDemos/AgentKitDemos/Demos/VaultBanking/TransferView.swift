import SwiftUI

/// Transfer money between accounts — dark theme with account selector cards.
struct TransferView: View {
    @Environment(BankingService.self) private var bank
    @State private var fromAccountId: String = "ACC-001"
    @State private var toAccountId: String = "ACC-002"
    @State private var amountText: String = ""
    @State private var reference: String = ""
    @State private var showResult = false
    @State private var resultMessage = ""
    @State private var resultSuccess = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // FROM account
                    VStack(alignment: .leading, spacing: 8) {
                        Label("From", systemImage: "arrow.up.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0xF87171))
                        accountPicker(selected: $fromAccountId, exclude: toAccountId)
                    }

                    // Swap button
                    Button {
                        withAnimation(.spring(duration: 0.3)) {
                            let temp = fromAccountId
                            fromAccountId = toAccountId
                            toAccountId = temp
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                            .font(.title)
                            .foregroundStyle(Color(hex: 0x1B6BF3))
                            .frame(width: 44, height: 44)
                            .background(Color(hex: 0x1B6BF3).opacity(0.15))
                            .clipShape(Circle())
                    }

                    // TO account
                    VStack(alignment: .leading, spacing: 8) {
                        Label("To", systemImage: "arrow.down.circle.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0x34D399))
                        accountPicker(selected: $toAccountId, exclude: fromAccountId)
                    }

                    // Amount input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Amount")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0x8899AA))

                        HStack(spacing: 8) {
                            Text("GEL")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(Color(hex: 0x556677))
                            TextField("0.00", text: $amountText)
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(16)
                        .background(Color(hex: 0x151A22))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.08), lineWidth: 1)
                        )
                    }

                    // Reference input
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Reference (optional)")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Color(hex: 0x8899AA))

                        TextField("What's this for?", text: $reference)
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .padding(14)
                            .background(Color(hex: 0x151A22))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
                            )
                    }

                    // Balance preview
                    if let amount = Double(amountText), amount > 0, let fromAccount = bank.account(byId: fromAccountId) {
                        balancePreview(fromAccount: fromAccount, amount: amount)
                    }

                    // Transfer button
                    Button {
                        executeTransfer()
                    } label: {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                            Text("Transfer")
                                .font(.headline)
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            canTransfer
                                ? LinearGradient(colors: [Color(hex: 0x1B6BF3), Color(hex: 0x3D8BFD)], startPoint: .leading, endPoint: .trailing)
                                : LinearGradient(colors: [Color(hex: 0x2A2F3A), Color(hex: 0x2A2F3A)], startPoint: .leading, endPoint: .trailing)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!canTransfer)
                }
                .padding()
            }
            .background(Color(hex: 0x0C0F14))
            .navigationTitle("Transfer")
            .toolbarBackground(Color(hex: 0x0C0F14), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .alert(resultSuccess ? "Transfer Complete" : "Transfer Failed", isPresented: $showResult) {
                Button("OK") {
                    if resultSuccess {
                        amountText = ""
                        reference = ""
                    }
                }
            } message: {
                Text(resultMessage)
            }
        }
    }

    private var canTransfer: Bool {
        guard let amount = Double(amountText), amount > 0 else { return false }
        return fromAccountId != toAccountId
    }

    private func executeTransfer() {
        guard let amount = Double(amountText) else { return }
        let ref = reference.isEmpty ? "Transfer" : reference
        let result = bank.transferFunds(
            fromAccountId: fromAccountId,
            toAccountId: toAccountId,
            amount: amount,
            reference: ref
        )
        resultSuccess = !result.contains("Insufficient") && !result.contains("not found")
        resultMessage = result
        showResult = true
    }

    private func accountPicker(selected: Binding<String>, exclude: String) -> some View {
        VStack(spacing: 8) {
            ForEach(bank.accounts) { account in
                let isSelected = selected.wrappedValue == account.id
                let isExcluded = account.id == exclude

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selected.wrappedValue = account.id
                    }
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: account.type.icon)
                            .font(.title3)
                            .foregroundStyle(.white)
                            .frame(width: 40, height: 40)
                            .background(accountGradient(account.type))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.subheadline.weight(.medium))
                                .foregroundStyle(isExcluded ? Color(hex: 0x445566) : .white)
                            Text("••\(account.lastFourDigits)")
                                .font(.caption.monospaced())
                                .foregroundStyle(Color(hex: 0x556677))
                        }

                        Spacer()

                        Text(account.formattedBalance)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(isExcluded ? Color(hex: 0x445566) : Color(hex: 0x99AABB))
                    }
                    .padding(12)
                    .background(isSelected ? Color(hex: 0x1B6BF3).opacity(0.12) : Color(hex: 0x151A22))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color(hex: 0x1B6BF3) : Color.white.opacity(0.06), lineWidth: isSelected ? 1.5 : 1)
                    )
                    .opacity(isExcluded ? 0.4 : 1)
                }
                .buttonStyle(.plain)
                .disabled(isExcluded)
            }
        }
    }

    private func balancePreview(fromAccount: Account, amount: Double) -> some View {
        let newBalance = fromAccount.balance - amount
        let isLow = newBalance < 500
        let isNegative = newBalance < 0

        return VStack(spacing: 8) {
            HStack {
                Text("Balance after transfer")
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x8899AA))
                Spacer()
                Text(String(format: "GEL %.2f", newBalance))
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(isNegative ? Color(hex: 0xF87171) : isLow ? Color(hex: 0xFBBF24) : Color(hex: 0x34D399))
            }
            if isNegative {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("Insufficient funds")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(Color(hex: 0xF87171))
                .frame(maxWidth: .infinity, alignment: .trailing)
            } else if isLow {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption2)
                    Text("Balance will be below GEL 500")
                        .font(.caption2.weight(.medium))
                }
                .foregroundStyle(Color(hex: 0xFBBF24))
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(14)
        .background(Color(hex: 0x151A22))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func accountGradient(_ type: Account.AccountType) -> LinearGradient {
        switch type {
        case .checking:
            return LinearGradient(colors: [Color(hex: 0x1B6BF3), Color(hex: 0x3D8BFD)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .savings:
            return LinearGradient(colors: [Color(hex: 0x0EA574), Color(hex: 0x34D399)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .business:
            return LinearGradient(colors: [Color(hex: 0x8B5CF6), Color(hex: 0xA78BFA)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}
