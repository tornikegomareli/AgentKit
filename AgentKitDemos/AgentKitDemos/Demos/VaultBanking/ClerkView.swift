import SwiftUI
import AgentKitCore
import AgentKitChat

/// The Clerk agent chat interface — the AI banking assistant.
struct ClerkView: View {
    let assistant: VaultAssistant
    @State private var session: AgentSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    AgentChatView(session: session)
                        .agentName("Clerk")
                        .agentAccentColor(Color(hex: 0x2A6496))
                        .suggestedPrompts([
                            "What are my account balances?",
                            "How much did I spend on food?",
                            "Transfer 500 GEL to savings",
                            "Show my recurring charges",
                            "I want to save 5,000 GEL by July",
                            "Pay rent to Giorgi Beridze"
                        ])
                        .inputPlaceholder("Tell Clerk what to do...")
                } else {
                    ProgressView("Starting Clerk...")
                }
            }
            .navigationTitle("Clerk Agent")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if session == nil {
                    session = assistant.agent.startSession()
                }
            }
        }
    }
}
