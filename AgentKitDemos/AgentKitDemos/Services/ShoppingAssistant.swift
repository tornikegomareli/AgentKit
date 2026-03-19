import Foundation
import AgentKitCore
import AgentKitProviders

/// Wires StoreService methods as AgentKit tools.
///
/// This is the integration layer — it shows how a real app
/// connects its business logic to the agent framework.
@MainActor
final class ShoppingAssistant {
    let agent: AgentKit
    private let store: StoreService

    init(store: StoreService, provider: LLMProvider) {
        self.store = store
        self.agent = AgentKit(
            adapter: provider.adapter(),
            configuration: Configuration(
                maxIterations: 8,
                systemPrompt: """
                You are a friendly shopping assistant for a retail store.
                Help customers find products, manage their cart, and track orders.
                Be concise and helpful. When showing products, include the price.
                If you're unsure about something, say so.
                """,
                loggingEnabled: true
            )
        )

        Task {
            await registerTools()
        }
    }

    private func registerTools() async {
        let store = self.store

        await agent.tools.register(
            name: "searchProducts",
            description: "Search the product catalog. Use this when the user wants to find, browse, or discover products.",
            parameters: [
                .string("query", description: "Search keyword (e.g. 'headphones', 'running')", required: true),
                .string("category", description: "Optional category filter: Electronics, Clothing, Home & Kitchen, Sports, Books", required: false)
            ]
        ) { @MainActor params in
            let query = params["query"] as? String ?? ""
            let categoryName = params["category"] as? String
            let category = categoryName.flatMap { Product.Category(rawValue: $0) }
            let results = store.searchProducts(query: query, category: category)
            if results.isEmpty {
                return "No products found for '\(query)'"
            }
            return results.map { "\($0.name) — \($0.formattedPrice) (ID: \($0.id), \($0.inStock ? "In Stock" : "Out of Stock"), \($0.rating)/5)" }.joined(separator: "\n")
        }

        await agent.tools.register(
            name: "getProductDetails",
            description: "Get detailed information about a specific product by its ID.",
            parameters: [
                .string("productId", description: "The product SKU ID (e.g. SKU-001)", required: true)
            ]
        ) { @MainActor params in
            let id = params["productId"] as? String ?? ""
            guard let product = store.product(byId: id) else {
                return "Product not found: \(id)"
            }
            return """
            \(product.name)
            Price: \(product.formattedPrice)
            Category: \(product.category.rawValue)
            Rating: \(product.rating)/5 (\(product.reviewCount) reviews)
            In Stock: \(product.inStock ? "Yes" : "No")
            Description: \(product.description)
            """
        }

        await agent.tools.register(
            name: "addToCart",
            description: "Add a product to the shopping cart.",
            parameters: [
                .string("productId", description: "The product SKU ID to add", required: true),
                .int("quantity", description: "How many to add (default 1)", required: false)
            ]
        ) { @MainActor params in
            let id = params["productId"] as? String ?? ""
            let qty = params["quantity"] as? Int ?? 1
            return store.addToCart(productId: id, quantity: qty)
        }

        await agent.tools.register(
            name: "getCartSummary",
            description: "Get a summary of what's currently in the shopping cart with totals.",
            parameters: []
        ) { @MainActor params in
            return store.cartSummary
        }

        await agent.tools.register(
            name: "trackOrder",
            description: "Track the status of an order by its order ID.",
            parameters: [
                .string("orderId", description: "The order ID (e.g. ORD-10042)", required: true)
            ]
        ) { @MainActor params in
            let id = params["orderId"] as? String ?? ""
            return store.trackOrder(orderId: id)
        }
    }
}
