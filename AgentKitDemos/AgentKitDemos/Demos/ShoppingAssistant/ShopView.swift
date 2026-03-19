import SwiftUI

struct ShopView: View {
    @Environment(StoreService.self) private var store
    @State private var searchText = ""
    @State private var selectedCategory: Product.Category?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Category chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            categoryChip(nil, label: "All")
                            ForEach(Product.Category.allCases, id: \.self) { cat in
                                categoryChip(cat, label: cat.rawValue)
                            }
                        }
                        .padding(.horizontal)
                    }

                    // Product grid
                    LazyVGrid(
                        columns: [GridItem(.adaptive(minimum: 160), spacing: 12)],
                        spacing: 12
                    ) {
                        ForEach(filteredProducts) { product in
                            ProductCard(product: product)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Shop")
            .searchable(text: $searchText, prompt: "Search products...")
        }
    }

    private var filteredProducts: [Product] {
        store.searchProducts(query: searchText, category: selectedCategory)
    }

    @ViewBuilder
    private func categoryChip(_ category: Product.Category?, label: String) -> some View {
        let isSelected = selectedCategory == category
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedCategory = category
            }
        } label: {
            Text(label)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

struct ProductCard: View {
    let product: Product
    @Environment(StoreService.self) private var store

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: product.imageSystemName)
                .font(.system(size: 32))
                .frame(maxWidth: .infinity, minHeight: 60)
                .foregroundStyle(.secondary)

            Text(product.name)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Text(product.formattedPrice)
                    .font(.headline)
                Spacer()
                HStack(spacing: 2) {
                    Image(systemName: "star.fill")
                        .font(.caption2)
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", product.rating))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Button {
                _ = store.addToCart(productId: product.id)
            } label: {
                Text(product.inStock ? "Add to Cart" : "Out of Stock")
                    .font(.caption.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(product.inStock ? Color.accentColor : Color.gray)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .disabled(!product.inStock)
        }
        .padding(12)
        .background(Color.secondary.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
