import SwiftUI
import AgentKitCore
import AgentKitProviders
import AgentKitChat

/// The "10 lines" demo — shows how little code is needed for a working agent chat.
/// This is the demo you'd show in a README or conference talk.
struct MinimalChatDemo: View {
    @State private var agent: AgentKit?
    @State private var session: AgentSession?

    var body: some View {
        Group {
            if let session {
                AgentChatView(session: session)
                    .agentName("Atlas")
                    .agentAccentColor(.blue)
                    .suggestedPrompts([
                        "Tell me a fun fact",
                        "Write a haiku about Swift",
                        "Explain async/await simply"
                    ])
                    .inputPlaceholder("Ask Atlas anything...")
            } else {
                ProgressView("Loading...")
            }
        }
        .navigationTitle("Minimal Chat")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if agent == nil {
                let kit = AgentKit(
                    provider: .openai(
                        apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-key-here",
                        model: .gpt4o
                    ),
                    configuration: Configuration(
                        systemPrompt: "You are Atlas, a friendly and concise assistant. Keep responses short and helpful."
                    )
                )
                agent = kit
                session = kit.startSession()
            }
        }
    }
}
