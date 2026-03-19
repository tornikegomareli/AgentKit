import SwiftUI

struct ContentView: View {
    let assistant: ShoppingAssistant?
    @State private var selectedTab = 0
    @Environment(StoreService.self) private var store

    var body: some View {
        TabView(selection: $selectedTab) {
            ShopView()
                .tabItem {
                    Label("Shop", systemImage: "bag")
                }
                .tag(0)

            CartView()
                .tabItem {
                    Label("Cart", systemImage: "cart")
                }
                .badge(store.cartItemCount)
                .tag(1)

            OrdersView()
                .tabItem {
                    Label("Orders", systemImage: "shippingbox")
                }
                .tag(2)

            Group {
                if let assistant {
                    AssistantView(assistant: assistant)
                } else {
                    ProgressView("Loading...")
                }
            }
            .tabItem {
                Label("Assistant", systemImage: "bubble.left.and.bubble.right")
            }
            .tag(3)
        }
    }
}
