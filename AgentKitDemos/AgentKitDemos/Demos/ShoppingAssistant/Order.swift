import Foundation

struct Order: Identifiable, Hashable {
    let id: String
    let items: [OrderItem]
    let total: Double
    let status: Status
    let date: Date
    let estimatedDelivery: Date

    enum Status: String, Hashable {
        case processing = "Processing"
        case shipped = "Shipped"
        case outForDelivery = "Out for Delivery"
        case delivered = "Delivered"

        var icon: String {
            switch self {
            case .processing: return "clock"
            case .shipped: return "shippingbox"
            case .outForDelivery: return "box.truck"
            case .delivered: return "checkmark.circle.fill"
            }
        }
    }

    struct OrderItem: Hashable {
        let productName: String
        let quantity: Int
        let price: Double
    }
}

extension Order {
    static let samples: [Order] = [
        Order(
            id: "ORD-10042",
            items: [
                OrderItem(productName: "Wireless Noise-Canceling Headphones", quantity: 1, price: 299.99),
                OrderItem(productName: "Smart LED Desk Lamp", quantity: 1, price: 59.99)
            ],
            total: 359.98,
            status: .shipped,
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            estimatedDelivery: Calendar.current.date(byAdding: .day, value: 2, to: Date())!
        ),
        Order(
            id: "ORD-10038",
            items: [
                OrderItem(productName: "Running Shoes Pro", quantity: 1, price: 159.99)
            ],
            total: 159.99,
            status: .delivered,
            date: Calendar.current.date(byAdding: .day, value: -10, to: Date())!,
            estimatedDelivery: Calendar.current.date(byAdding: .day, value: -5, to: Date())!
        ),
        Order(
            id: "ORD-10051",
            items: [
                OrderItem(productName: "Cast Iron Dutch Oven", quantity: 1, price: 69.99),
                OrderItem(productName: "The Art of Clean Code", quantity: 2, price: 34.99)
            ],
            total: 139.97,
            status: .processing,
            date: Date(),
            estimatedDelivery: Calendar.current.date(byAdding: .day, value: 5, to: Date())!
        ),
    ]
}
