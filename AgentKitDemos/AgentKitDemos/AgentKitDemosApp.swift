import SwiftUI
import AgentKitCore
import AgentKitProviders

@main
struct AgentKitDemosApp: App {
    @State private var store = StoreService()
    @State private var assistant: ShoppingAssistant?

    var body: some Scene {
        WindowGroup {
            ContentView(assistant: assistant)
                .environment(store)
                .task {
                    if assistant == nil {
                        // Using OpenAI for the demo.
                        // Set OPENAI_API_KEY env var or paste your key below.
                        let provider: LLMProvider = .openai(
                            apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-key-here",
                            model: .gpt4o
                        )
                        assistant = ShoppingAssistant(store: store, provider: provider)
                    }
                }
        }
    }
}
