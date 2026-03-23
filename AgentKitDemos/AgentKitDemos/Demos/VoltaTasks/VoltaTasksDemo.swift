import SwiftUI
import AgentKitCore
import AgentKitProviders

/// Volta Task Management demo — a Kanban board with the Forge AI agent.
///
/// Shows: sprint health monitoring, dependency analysis, blocker detection,
/// task mutation with approval gates, and stale task alerts.
struct VoltaTasksDemo: View {
    @State private var project = ProjectService()
    @State private var assistant: VoltaAssistant?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            BoardView()
                .tabItem { Label("Board", systemImage: "square.grid.2x2") }
                .tag(0)

            Group {
                if let assistant {
                    ForgeView(assistant: assistant)
                } else {
                    ProgressView("Starting Forge agent...")
                }
            }
            .tabItem { Label("Forge", systemImage: "bolt.fill") }
            .tag(1)
        }
        .tint(Color(hex: 0xA8E040))
        .environment(project)
        .task {
            if assistant == nil {
                let provider: LLMProvider = .openai(
                    apiKey: APIKeys.openai,
                    model: .gpt4o
                )
                assistant = VoltaAssistant(project: project, provider: provider)
            }
        }
    }
}
