import Foundation

struct CartItem: Identifiable, Hashable {
    let id = UUID()
    let product: Product
    var quantity: Int

    var subtotal: Double {
        product.price * Double(quantity)
    }
}
