import SwiftUI
import AgentKitCore
import AgentKitChat

/// The agent-powered shopping assistant tab.
/// Uses AgentChatView as a drop-in chat interface.
struct AssistantView: View {
    let assistant: ShoppingAssistant
    @State private var session: AgentSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    AgentChatView(session: session)
                        .agentName("ShopBot")
                        .agentAccentColor(.indigo)
                        .suggestedPrompts([
                            "What headphones do you have?",
                            "Show me sports gear",
                            "What's in my cart?",
                            "Track order ORD-10042"
                        ])
                        .inputPlaceholder("Ask ShopBot...")
                } else {
                    ProgressView("Starting assistant...")
                }
            }
            .navigationTitle("Assistant")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if session == nil {
                    session = assistant.agent.startSession()
                }
            }
        }
    }
}
