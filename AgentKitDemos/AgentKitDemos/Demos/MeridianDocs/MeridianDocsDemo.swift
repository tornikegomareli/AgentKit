import SwiftUI
import AgentKitCore
import AgentKitProviders

/// Meridian Docs & Knowledge demo — a knowledge management platform with the Scribe AI agent.
///
/// Shows: document search, knowledge graph, freshness auditing,
/// contradiction detection, and cited summarization.
struct MeridianDocsDemo: View {
    @State private var knowledge = KnowledgeService()
    @State private var assistant: MeridianAssistant?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DocumentsListView()
                .tabItem { Label("Documents", systemImage: "doc.text.fill") }
                .tag(0)

            Group {
                if let assistant {
                    ScribeView(assistant: assistant)
                } else {
                    ProgressView("Starting Scribe agent...")
                }
            }
            .tabItem { Label("Scribe", systemImage: "text.magnifyingglass") }
            .tag(1)
        }
        .tint(Color(hex: 0xC8943A))
        .environment(knowledge)
        .task {
            if assistant == nil {
                let provider: LLMProvider = .openai(
                    apiKey: APIKeys.openai,
                    model: .gpt4o
                )
                assistant = MeridianAssistant(knowledge: knowledge, provider: provider)
            }
        }
    }
}
