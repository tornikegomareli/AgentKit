import SwiftUI
import AgentKitCore
import AgentKitProviders

/// Self-contained Shopping Assistant demo.
/// Shows: tool calling, drop-in AgentChatView, multi-tab app integration.
struct ShoppingAssistantDemo: View {
    @State private var store = StoreService()
    @State private var assistant: ShoppingAssistant?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ShopView()
                .tabItem { Label("Shop", systemImage: "bag") }
                .tag(0)

            CartView()
                .tabItem { Label("Cart", systemImage: "cart") }
                .badge(store.cartItemCount)
                .tag(1)

            OrdersView()
                .tabItem { Label("Orders", systemImage: "shippingbox") }
                .tag(2)

            Group {
                if let assistant {
                    AssistantView(assistant: assistant)
                } else {
                    ProgressView("Starting assistant...")
                }
            }
            .tabItem { Label("Assistant", systemImage: "bubble.left.and.bubble.right") }
            .tag(3)
        }
        .environment(store)
        .task {
            if assistant == nil {
                let provider: LLMProvider = .openai(
                    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-key-here",
                    model: .gpt4o
                )
                assistant = ShoppingAssistant(store: store, provider: provider)
            }
        }
    }
}
