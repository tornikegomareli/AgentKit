import SwiftUI
import AgentKitCore
import AgentKitChat

/// The Forge agent chat interface for Volta.
struct ForgeView: View {
    let assistant: VoltaAssistant
    @State private var session: AgentSession?

    var body: some View {
        NavigationStack {
            Group {
                if let session {
                    AgentChatView(session: session)
                        .agentName("Forge")
                        .agentAccentColor(Color(hex: 0xA8E040))
                        .suggestedPrompts([
                            "Show me the board",
                            "How's our sprint health?",
                            "What's blocking progress?",
                            "Find stale tasks",
                            "What's Tornike working on?",
                            "Triage the backlog by dependencies"
                        ])
                        .inputPlaceholder("Instruct Forge...")
                } else {
                    ProgressView("Starting Forge...")
                }
            }
            .navigationTitle("Forge Agent")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                if session == nil {
                    session = assistant.agent.startSession()
                }
            }
        }
    }
}
