import Foundation

struct Product: Identifiable, Hashable {
    let id: String
    let name: String
    let category: Category
    let price: Double
    let description: String
    let rating: Double
    let reviewCount: Int
    let imageSystemName: String
    let inStock: Bool

    enum Category: String, CaseIterable, Hashable {
        case electronics = "Electronics"
        case clothing = "Clothing"
        case home = "Home & Kitchen"
        case sports = "Sports"
        case books = "Books"
    }

    var formattedPrice: String {
        String(format: "$%.2f", price)
    }
}

extension Product {
    static let catalog: [Product] = [
        Product(id: "SKU-001", name: "Wireless Noise-Canceling Headphones", category: .electronics, price: 299.99, description: "Premium over-ear headphones with active noise cancellation, 30-hour battery life, and spatial audio support.", rating: 4.7, reviewCount: 2341, imageSystemName: "headphones", inStock: true),
        Product(id: "SKU-002", name: "Smart Watch Ultra", category: .electronics, price: 449.99, description: "Advanced fitness tracking, ECG monitoring, always-on display, titanium case with 72-hour battery.", rating: 4.8, reviewCount: 1892, imageSystemName: "applewatch", inStock: true),
        Product(id: "SKU-003", name: "Portable Bluetooth Speaker", category: .electronics, price: 79.99, description: "Waterproof speaker with 360-degree sound, 12-hour playtime, and built-in microphone.", rating: 4.5, reviewCount: 3456, imageSystemName: "hifispeaker", inStock: true),
        Product(id: "SKU-004", name: "Merino Wool Crew Neck Sweater", category: .clothing, price: 89.99, description: "Lightweight, breathable merino wool sweater. Machine washable. Available in 6 colors.", rating: 4.6, reviewCount: 876, imageSystemName: "tshirt", inStock: true),
        Product(id: "SKU-005", name: "Running Shoes Pro", category: .sports, price: 159.99, description: "Carbon-plate running shoes with responsive foam cushioning. Race-day performance for everyday training.", rating: 4.4, reviewCount: 1245, imageSystemName: "shoe", inStock: true),
        Product(id: "SKU-006", name: "Cast Iron Dutch Oven", category: .home, price: 69.99, description: "5.5-quart enameled cast iron. Oven-safe to 500F. Perfect for soups, stews, and bread baking.", rating: 4.9, reviewCount: 4521, imageSystemName: "oven", inStock: true),
        Product(id: "SKU-007", name: "Mechanical Keyboard", category: .electronics, price: 129.99, description: "Hot-swappable switches, RGB backlighting, USB-C, gasket-mounted for a premium typing feel.", rating: 4.6, reviewCount: 987, imageSystemName: "keyboard", inStock: false),
        Product(id: "SKU-008", name: "Yoga Mat Premium", category: .sports, price: 49.99, description: "6mm thick, non-slip natural rubber. Alignment markers. Comes with carrying strap.", rating: 4.3, reviewCount: 2134, imageSystemName: "figure.yoga", inStock: true),
        Product(id: "SKU-009", name: "The Art of Clean Code", category: .books, price: 34.99, description: "A practical guide to writing maintainable, testable software. Covers Swift, Python, and TypeScript.", rating: 4.7, reviewCount: 654, imageSystemName: "book", inStock: true),
        Product(id: "SKU-010", name: "Smart LED Desk Lamp", category: .home, price: 59.99, description: "Adjustable color temperature, brightness memory, USB charging port. Touch controls.", rating: 4.5, reviewCount: 1678, imageSystemName: "lamp.desk", inStock: true),
    ]
}
