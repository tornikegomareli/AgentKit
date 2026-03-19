import SwiftUI

struct CartView: View {
    @Environment(StoreService.self) private var store

    var body: some View {
        NavigationStack {
            Group {
                if store.cart.isEmpty {
                    ContentUnavailableView(
                        "Cart is Empty",
                        systemImage: "cart",
                        description: Text("Add some items from the Shop tab.")
                    )
                } else {
                    List {
                        ForEach(store.cart) { item in
                            CartItemRow(item: item)
                        }
                        .onDelete(perform: deleteItems)

                        Section {
                            HStack {
                                Text("Total")
                                    .font(.headline)
                                Spacer()
                                Text(String(format: "$%.2f", store.cartTotal))
                                    .font(.title3.bold())
                            }
                        }

                        Section {
                            Button {
                                // Checkout placeholder
                            } label: {
                                Text("Checkout")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 4)
                            }
                            .buttonStyle(.borderedProminent)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                        }
                    }
                }
            }
            .navigationTitle("Cart")
        }
    }

    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let productId = store.cart[index].product.id
            _ = store.removeFromCart(productId: productId)
        }
    }
}

struct CartItemRow: View {
    let item: CartItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.product.imageSystemName)
                .font(.title2)
                .frame(width: 44, height: 44)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                Text(item.product.name)
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)
                Text("Qty: \(item.quantity) \u{00B7} \(item.product.formattedPrice) each")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Text(String(format: "$%.2f", item.subtotal))
                .font(.subheadline.weight(.semibold))
        }
    }
}
