import SwiftUI

/// Full document view with content, metadata, and linked docs.
struct DocumentDetailView: View {
    let document: KBDocument
    @Environment(KnowledgeService.self) private var knowledge

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: document.space.icon)
                            .foregroundStyle(Color(hex: 0xC8943A))
                        Text(document.space.rawValue)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: 0xC8943A))
                    }

                    Text(document.title)
                        .font(.title2.weight(.bold))

                    HStack(spacing: 12) {
                        Label(document.author, systemImage: "person")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Label(document.formattedLastUpdate, systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(document.isStale ? Color(hex: 0xB05A10) : .secondary)
                        Label("\(document.linkedDocumentIds.count) links", systemImage: "link")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if document.isStale {
                    staleWarning
                }

                Divider()

                // Body
                Text(document.body)
                    .font(.body)
                    .lineSpacing(4)

                // Tags
                if !document.tags.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(document.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color(hex: 0xC8943A).opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                }

                // Linked documents
                if !document.linkedDocumentIds.isEmpty {
                    Divider()
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Linked Documents")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        ForEach(linkedDocuments) { linked in
                            HStack {
                                Image(systemName: "link")
                                    .font(.caption)
                                    .foregroundStyle(Color(hex: 0xC8943A))
                                Text(linked.title)
                                    .font(.subheadline)
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color(hex: 0xF5F0E8))
        .navigationBarTitleDisplayMode(.inline)
    }

    private var linkedDocuments: [KBDocument] {
        document.linkedDocumentIds.compactMap { id in
            knowledge.documents.first { $0.id == id }
        }
    }

    private var staleWarning: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color(hex: 0xB05A10))
            VStack(alignment: .leading, spacing: 2) {
                Text("Potentially Stale Content")
                    .font(.caption.weight(.semibold))
                Text("Last updated \(document.daysSinceUpdate) days ago. This content may be outdated.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0xB05A10).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

/// Simple flow layout for tags.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrangeSubviews(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrangeSubviews(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var maxX: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
            maxX = max(maxX, x)
        }

        return (positions, CGSize(width: maxX, height: y + rowHeight))
    }
}
