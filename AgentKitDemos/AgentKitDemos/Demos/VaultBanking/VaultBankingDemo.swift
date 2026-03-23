import SwiftUI
import AgentKitCore
import AgentKitProviders

/// Vault Banking demo — a personal banking app with the Clerk AI agent.
///
/// Shows: multi-tool agent with risk tiers, financial operations,
/// spending analysis, confirmation flows, and activity logging.
struct VaultBankingDemo: View {
    @State private var bank = BankingService()
    @State private var assistant: VaultAssistant?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            AccountsView()
                .tabItem { Label("Accounts", systemImage: "building.columns") }
                .tag(0)

            TransferView()
                .tabItem { Label("Transfer", systemImage: "arrow.left.arrow.right") }
                .tag(1)

            TransactionsView()
                .tabItem { Label("History", systemImage: "list.bullet.rectangle") }
                .tag(2)

            ActivityLogView()
                .tabItem { Label("Activity", systemImage: "clock") }
                .tag(3)

            Group {
                if let assistant {
                    ClerkView(assistant: assistant)
                } else {
                    ProgressView("Starting Clerk agent...")
                        .tint(.white)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color(hex: 0x0C0F14))
                }
            }
            .tabItem { Label("Clerk", systemImage: "bubble.left.and.text.bubble.right") }
            .tag(4)
        }
        .tint(Color(hex: 0x3D8BFD))
        .preferredColorScheme(.dark)
        .environment(bank)
        .task {
            if assistant == nil {
                let provider: LLMProvider = .openai(
                    apiKey: APIKeys.openai,
                    model: .gpt4o
                )
                assistant = VaultAssistant(bank: bank, provider: provider)
            }
        }
    }
}
