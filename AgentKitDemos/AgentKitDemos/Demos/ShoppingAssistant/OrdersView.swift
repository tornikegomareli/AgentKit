import SwiftUI

struct OrdersView: View {
    @Environment(StoreService.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.orders.isEmpty {
                    ContentUnavailableView(
                        "No Orders",
                        systemImage: "shippingbox",
                        description: Text("Your order history will appear here.")
                    )
                } else {
                    List(store.orders) { order in
                        OrderRow(order: order)
                    }
                }
            }
            .navigationTitle("Orders")
        }
    }
}

struct OrderRow: View {
    let order: Order

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(order.id)
                    .font(.subheadline.weight(.semibold).monospaced())
                Spacer()
                Text(String(format: "$%.2f", order.total))
                    .font(.subheadline.weight(.semibold))
            }

            HStack(spacing: 6) {
                Image(systemName: order.status.icon)
                    .foregroundStyle(statusColor)
                Text(order.status.rawValue)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(statusColor)
            }

            Text(order.items.map { "\($0.quantity)x \($0.productName)" }.joined(separator: ", "))
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if order.status != .delivered {
                let formatter = DateFormatter()
                Text("Estimated delivery: \(formattedDate(order.estimatedDelivery))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch order.status {
        case .processing: return .orange
        case .shipped: return .blue
        case .outForDelivery: return .purple
        case .delivered: return .green
        }
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}
