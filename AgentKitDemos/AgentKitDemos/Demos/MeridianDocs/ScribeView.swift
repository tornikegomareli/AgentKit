import SwiftUI
import AgentKitCore
import AgentKitChat

/// The Scribe agent chat interface for Meridian.
struct ScribeView: View {
    let assistant: MeridianAssistant
    @State private var session: AgentSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    AgentChatView(session: session)
                        .agentName("Scribe")
                        .agentAccentColor(Color(hex: 0xC8943A))
                        .suggestedPrompts([
                            "What do we know about our architecture?",
                            "Run a freshness audit",
                            "Find contradictions in the knowledge base",
                            "Summarize the product vision",
                            "What's related to Q2 planning?",
                            "Show all engineering wiki docs"
                        ])
                        .inputPlaceholder("Ask Scribe...")
                } else {
                    ProgressView("Starting Scribe...")
                }
            }
            .navigationTitle("Scribe Agent")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if session == nil {
                    session = assistant.agent.startSession()
                }
            }
        }
    }
}
