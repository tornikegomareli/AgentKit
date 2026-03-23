import SwiftUI
import AgentKitCore
import AgentKitChat

/// The Courier agent chat interface for Lumen.
struct CourierView: View {
    let assistant: LumenAssistant
    @State private var session: AgentSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    AgentChatView(session: session)
                        .agentName("Courier")
                        .agentAccentColor(Color(hex: 0x1A7A6E))
                        .suggestedPrompts([
                            "Triage my inbox",
                            "What emails need my attention?",
                            "Draft a reply to Marcus",
                            "What's on my calendar today?",
                            "Schedule a meeting with Sarah",
                            "Show me finance-related emails"
                        ])
                        .inputPlaceholder("Ask Courier...")
                } else {
                    ProgressView("Starting Courier...")
                }
            }
            .navigationTitle("Courier Agent")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if session == nil {
                    session = assistant.agent.startSession()
                }
            }
        }
    }
}
