import Foundation
import Observation

@Observable
final class StoreService {
    var cart: [CartItem] = []
    var orders: [Order] = Order.samples
    let catalog: [Product] = Product.catalog

    // MARK: - Product Search

    func searchProducts(query: String, category: Product.Category? = nil) -> [Product] {
        var results = catalog
        if let category {
            results = results.filter { $0.category == category }
        }
        if !query.isEmpty {
            let lowered = query.lowercased()
            results = results.filter {
                $0.name.lowercased().contains(lowered) ||
                $0.description.lowercased().contains(lowered) ||
                $0.category.rawValue.lowercased().contains(lowered)
            }
        }
        return results
    }

    func product(byId id: String) -> Product? {
        catalog.first { $0.id == id }
    }

    // MARK: - Cart

    func addToCart(productId: String, quantity: Int = 1) -> String {
        guard let product = product(byId: productId) else {
            return "Product not found: \(productId)"
        }
        guard product.inStock else {
            return "\(product.name) is out of stock"
        }
        if let index = cart.firstIndex(where: { $0.product.id == productId }) {
            cart[index].quantity += quantity
        } else {
            cart.append(CartItem(product: product, quantity: quantity))
        }
        return "Added \(quantity)x \(product.name) to cart"
    }

    func removeFromCart(productId: String) -> String {
        guard let index = cart.firstIndex(where: { $0.product.id == productId }) else {
            return "Item not in cart"
        }
        let name = cart[index].product.name
        cart.remove(at: index)
        return "Removed \(name) from cart"
    }

    var cartSummary: String {
        guard !cart.isEmpty else { return "Cart is empty" }
        let items = cart.map { "\($0.quantity)x \($0.product.name) — \($0.product.formattedPrice)" }
        let total = cart.reduce(0.0) { $0 + $1.subtotal }
        return items.joined(separator: "\n") + "\n\nTotal: \(String(format: "$%.2f", total))"
    }

    var cartTotal: Double {
        cart.reduce(0.0) { $0 + $1.subtotal }
    }

    var cartItemCount: Int {
        cart.reduce(0) { $0 + $1.quantity }
    }

    // MARK: - Orders

    func order(byId id: String) -> Order? {
        orders.first { $0.id == id }
    }

    func trackOrder(orderId: String) -> String {
        guard let order = order(byId: orderId) else {
            return "Order not found: \(orderId)"
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return """
        Order \(order.id):
        Status: \(order.status.rawValue)
        Items: \(order.items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: ", "))
        Total: \(String(format: "$%.2f", order.total))
        Estimated delivery: \(formatter.string(from: order.estimatedDelivery))
        """
    }
}
