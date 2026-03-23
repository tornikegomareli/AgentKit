import Foundation
import AgentKitCore
import AgentKitProviders

/// Wires BankingService methods as AgentKit tools for the Clerk agent.
///
/// Clerk is Vault's embedded AI agent — precise, cautious, transparent.
/// It moves money carefully and explains every number.
@MainActor
final class VaultAssistant {
    let agent: AgentKit
    private let bank: BankingService

    init(bank: BankingService, provider: LLMProvider) {
        self.bank = bank
        self.agent = AgentKit(
            adapter: provider.adapter(),
            configuration: Configuration(
                maxIterations: 10,
                systemPrompt: """
                You are Clerk, the embedded AI banking agent for Vault.

                PERSONALITY: Precise, cautious, transparent. You move money carefully and explain every number.

                CORE RULES:
                1. CONFIRM BEFORE EVERY FINANCIAL ACTION — Never move money without showing the user exactly what will happen first. Always show: FROM account, TO account/payee, AMOUNT, and the remaining balance after the transfer.
                2. SHOW THE FULL PICTURE — Before any transfer, warn if it would leave the account below GEL 500, conflict with upcoming scheduled payments, or seem unusual.
                3. PLAIN LANGUAGE, NO JARGON — Say "transfer from your checking account" not "initiate a debit." Say "arrives in 2 business days" not "settlement T+2."
                4. IRREVERSIBILITY WARNINGS — For external payments (to payees), large amounts (≥ GEL 1,000), or new recipients, always state: "This action cannot be reversed once confirmed."
                5. AUDIT TRAIL — Every action you take is logged. Be transparent about what you're doing.

                THREE-TIER RISK MODEL:
                🟢 LOW RISK (execute immediately): View balances, transaction history, spending analysis, list payees, savings calculations
                🟡 MEDIUM RISK (explain clearly, then execute if user confirms in their message): Internal transfers between user's own accounts, cancel scheduled payments
                🔴 HIGH RISK (warn strongly, require explicit confirmation): External payments to payees, any amount ≥ GEL 1,000, payments to payees

                CURRENCY: All amounts are in Georgian Lari (GEL).

                When analyzing spending, give actual numbers and percentages. Be specific.
                When the user asks to transfer money, first describe exactly what will happen, including the post-transfer balance. Then execute if the user confirms.
                """,
                loggingEnabled: true
            )
        )

        Task {
            await registerTools()
        }
    }

    private func registerTools() async {
        let bank = self.bank

        // MARK: — Read-Only Tools (🟢 Low Risk)

        await agent.tools.register(
            name: "getAccounts",
            description: "Get all account balances and details. Use this when the user asks about their balance, accounts, or financial overview.",
            parameters: []
        ) { @MainActor _ in
            return bank.accountSummary()
        }

        await agent.tools.register(
            name: "getTransactions",
            description: "Get recent transaction history. Can filter by account.",
            parameters: [
                .string("accountId", description: "Account ID to filter by (ACC-001, ACC-002, ACC-003). Leave empty for all accounts.", required: false),
                .int("limit", description: "Number of transactions to return (default 10)", required: false)
            ]
        ) { @MainActor params in
            let accountId = params["accountId"] as? String
            let limit = params["limit"] as? Int ?? 10
            if let accountId, !accountId.isEmpty {
                return bank.transactionHistory(accountId: accountId, limit: limit)
            }
            return bank.recentTransactions(limit: limit)
        }

        await agent.tools.register(
            name: "analyzeSpending",
            description: "Analyze spending by category and merchant. Shows breakdown of where money is going.",
            parameters: [
                .int("months", description: "Number of months to analyze (default 1)", required: false),
                .string("accountId", description: "Account ID to filter by (optional)", required: false)
            ]
        ) { @MainActor params in
            let months = params["months"] as? Int ?? 1
            let accountId = params["accountId"] as? String
            let id = (accountId?.isEmpty == false) ? accountId : nil
            return bank.analyzeSpending(months: months, accountId: id)
        }

        await agent.tools.register(
            name: "findRecurringCharges",
            description: "Identify all recurring charges and subscriptions.",
            parameters: []
        ) { @MainActor _ in
            return bank.findRecurringCharges()
        }

        await agent.tools.register(
            name: "getScheduledPayments",
            description: "List all upcoming scheduled and recurring payments.",
            parameters: []
        ) { @MainActor _ in
            return bank.listScheduledPayments()
        }

        await agent.tools.register(
            name: "getPayees",
            description: "List all saved payees/recipients for external transfers.",
            parameters: []
        ) { @MainActor _ in
            return bank.listPayees()
        }

        await agent.tools.register(
            name: "calculateSavingsGoal",
            description: "Calculate what's needed to reach a savings goal. Shows monthly/weekly targets and feasibility based on current income and spending.",
            parameters: [
                .number("targetAmount", description: "The savings goal amount in GEL", required: true),
                .int("months", description: "Number of months to reach the goal", required: true)
            ]
        ) { @MainActor params in
            let target = params["targetAmount"] as? Double ?? 0
            let months = params["months"] as? Int ?? 6
            return bank.calculateSavingsGoal(targetAmount: target, months: months)
        }

        // MARK: — Write Tools (🟡/🔴 Medium/High Risk)

        await agent.tools.register(
            name: "transferFunds",
            description: "Transfer money between the user's own accounts (internal transfer). MEDIUM RISK — always explain the transfer details before executing. Show FROM, TO, AMOUNT, and remaining balance.",
            parameters: [
                .string("fromAccountId", description: "Source account ID (ACC-001, ACC-002, or ACC-003)", required: true),
                .string("toAccountId", description: "Destination account ID (ACC-001, ACC-002, or ACC-003)", required: true),
                .number("amount", description: "Amount in GEL to transfer", required: true),
                .string("reference", description: "Transfer reference/note", required: false)
            ],
            confirmation: .required({ params in
                let amount = params["amount"] as? Double ?? 0
                let from = params["fromAccountId"] as? String ?? "?"
                let to = params["toAccountId"] as? String ?? "?"
                return "Transfer GEL \(String(format: "%.2f", amount)) from \(from) to \(to)"
            })
        ) { @MainActor params in
            let from = params["fromAccountId"] as? String ?? ""
            let to = params["toAccountId"] as? String ?? ""
            let amount = params["amount"] as? Double ?? 0
            let reference = params["reference"] as? String ?? "Transfer"
            return bank.transferFunds(fromAccountId: from, toAccountId: to, amount: amount, reference: reference)
        }

        await agent.tools.register(
            name: "payPayee",
            description: "Send payment to an external payee. HIGH RISK — always warn that this cannot be reversed. For amounts ≥ GEL 1,000, give an extra warning about the large amount.",
            parameters: [
                .string("payeeId", description: "Payee ID from the saved payees list", required: true),
                .string("fromAccountId", description: "Source account ID", required: true),
                .number("amount", description: "Amount in GEL to send", required: true),
                .string("reference", description: "Payment reference/note", required: true)
            ],
            confirmation: .biometric({ params in
                let amount = params["amount"] as? Double ?? 0
                let payeeId = params["payeeId"] as? String ?? "?"
                return "Send GEL \(String(format: "%.2f", amount)) to payee \(payeeId). This cannot be reversed."
            })
        ) { @MainActor params in
            let payeeId = params["payeeId"] as? String ?? ""
            let from = params["fromAccountId"] as? String ?? ""
            let amount = params["amount"] as? Double ?? 0
            let reference = params["reference"] as? String ?? "Payment"
            return bank.payPayee(payeeId: payeeId, fromAccountId: from, amount: amount, reference: reference)
        }

        await agent.tools.register(
            name: "cancelScheduledPayment",
            description: "Cancel an upcoming scheduled or recurring payment by its ID.",
            parameters: [
                .string("paymentId", description: "The scheduled payment ID (e.g. SCH-001)", required: true)
            ],
            confirmation: .required({ params in
                let id = params["paymentId"] as? String ?? "?"
                return "Cancel scheduled payment \(id)"
            })
        ) { @MainActor params in
            let id = params["paymentId"] as? String ?? ""
            return bank.cancelScheduledPayment(paymentId: id)
        }
    }
}
