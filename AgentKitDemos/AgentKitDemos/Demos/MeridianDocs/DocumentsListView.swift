import SwiftUI

/// Document browser for the Meridian knowledge base.
struct DocumentsListView: View {
    @Environment(KnowledgeService.self) private var knowledge
    @State private var selectedSpace: KBDocument.Space?
    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                // Space filter
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            spaceChip(nil, label: "All")
                            ForEach(KBDocument.Space.allCases, id: \.self) { space in
                                spaceChip(space, label: space.rawValue)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                // Documents
                ForEach(filteredDocuments) { doc in
                    NavigationLink {
                        DocumentDetailView(document: doc)
                    } label: {
                        documentRow(doc)
                    }
                }
            }
            .navigationTitle("Meridian")
            .searchable(text: $searchText, prompt: "Search knowledge base...")
        }
    }

    private var filteredDocuments: [KBDocument] {
        var docs = knowledge.documents
        if let selectedSpace {
            docs = docs.filter { $0.space == selectedSpace }
        }
        if !searchText.isEmpty {
            let lowered = searchText.lowercased()
            docs = docs.filter {
                $0.title.lowercased().contains(lowered) ||
                $0.tags.contains(where: { $0.contains(lowered) })
            }
        }
        return docs.sorted { $0.lastUpdatedDate > $1.lastUpdatedDate }
    }

    private func documentRow(_ doc: KBDocument) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: doc.space.icon)
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0xC8943A))
                Text(doc.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(2)
            }

            HStack(spacing: 8) {
                Text(doc.author)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(doc.formattedLastUpdate)
                    .font(.caption)
                    .foregroundStyle(doc.isStale ? Color(hex: 0xB05A10) : .secondary)
                if doc.isStale {
                    Text("STALE")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xB05A10))
                        .clipShape(Capsule())
                }
            }

            // Tags
            HStack(spacing: 4) {
                ForEach(doc.tags.prefix(4), id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xC8943A).opacity(0.15))
                        .clipShape(Capsule())
                }
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private func spaceChip(_ space: KBDocument.Space?, label: String) -> some View {
        let isSelected = selectedSpace == space
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedSpace = space }
        } label: {
            Text(label)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: 0xC8943A) : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
