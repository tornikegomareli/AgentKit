import Foundation
import Observation

/// Mock knowledge base service for the Meridian demo.
@Observable
final class KnowledgeService {
    var documents: [KBDocument] = KBDocument.samples()
    var activityLog: [ActivityEntry] = []

    struct ActivityEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let description: String

        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: timestamp)
        }
    }

    private func log(_ description: String) {
        activityLog.insert(
            ActivityEntry(timestamp: Date(), description: description), at: 0
        )
    }

    // MARK: - Document Queries

    func allDocuments() -> String {
        log("Listed all documents")
        return documents.map { doc in
            "\(doc.id): \"\(doc.title)\" — \(doc.space.rawValue) · by \(doc.author) · updated \(doc.formattedLastUpdate)\(doc.isStale ? " ⚠️ STALE" : "")"
        }.joined(separator: "\n")
    }

    func searchDocuments(query: String) -> String {
        let lowered = query.lowercased()
        let results = documents.filter { doc in
            doc.title.lowercased().contains(lowered) ||
            doc.body.lowercased().contains(lowered) ||
            doc.tags.contains(where: { $0.lowercased().contains(lowered) })
        }
        guard !results.isEmpty else { return "No documents found matching '\(query)'." }
        log("Searched documents: '\(query)' — \(results.count) results")
        return results.map { doc in
            "\(doc.id): \"\(doc.title)\" [\(doc.tags.joined(separator: ", "))] — \(doc.space.rawValue)"
        }.joined(separator: "\n")
    }

    func getDocument(id: String) -> String {
        guard let doc = documents.first(where: { $0.id == id }) else {
            return "Document not found: \(id)"
        }
        log("Read document: \(doc.title)")
        let linked = doc.linkedDocumentIds.compactMap { lid in
            documents.first(where: { $0.id == lid })?.title
        }
        return """
        TITLE: \(doc.title)
        ID: \(doc.id)
        SPACE: \(doc.space.rawValue)
        AUTHOR: \(doc.author)
        TAGS: \(doc.tags.joined(separator: ", "))
        LAST UPDATED: \(doc.formattedLastUpdate)\(doc.isStale ? " ⚠️ STALE (over 90 days)" : "")
        LINKED DOCS: \(linked.isEmpty ? "None" : linked.joined(separator: ", "))

        ---

        \(doc.body)
        """
    }

    func getDocumentsBySpace(space: String) -> String {
        guard let sp = KBDocument.Space(rawValue: space) else {
            return "Unknown space: \(space). Valid spaces: \(KBDocument.Space.allCases.map(\.rawValue).joined(separator: ", "))"
        }
        let docs = documents.filter { $0.space == sp }
        guard !docs.isEmpty else { return "No documents in \(space) space." }
        log("Listed \(sp.rawValue) space — \(docs.count) documents")
        return docs.map { doc($0) }.joined(separator: "\n")
    }

    // MARK: - Knowledge Graph

    func findRelatedDocuments(documentId: String) -> String {
        guard let doc = documents.first(where: { $0.id == documentId }) else {
            return "Document not found: \(documentId)"
        }
        // Find related by shared tags or explicit links
        let related = documents.filter { other in
            other.id != documentId && (
                doc.linkedDocumentIds.contains(other.id) ||
                other.linkedDocumentIds.contains(documentId) ||
                !Set(doc.tags).intersection(Set(other.tags)).isEmpty
            )
        }
        guard !related.isEmpty else { return "No related documents found." }
        log("Found \(related.count) documents related to \"\(doc.title)\"")
        return "Documents related to \"\(doc.title)\":\n" + related.map { r in
            let sharedTags = Set(doc.tags).intersection(Set(r.tags))
            let isLinked = doc.linkedDocumentIds.contains(r.id) || r.linkedDocumentIds.contains(documentId)
            return "  \(r.id): \"\(r.title)\" — \(isLinked ? "🔗 linked" : "") tags: [\(sharedTags.joined(separator: ", "))]"
        }.joined(separator: "\n")
    }

    func findContradictions() -> String {
        log("Scanned for contradictions across workspace")
        // Simulated contradiction detection
        return """
        Potential contradictions found:

        1. DOC-006 "Authentication Architecture (Legacy)" vs DOC-009 "API Reference: Core Types"
           DOC-006 describes session token storage in UserDefaults, but DOC-009 doesn't mention auth at all.
           DOC-006 is marked as legacy and is 150+ days old — it may need an archival notice.

        2. DOC-008 "Onboarding Checklist" references "auth middleware" in passing,
           but DOC-006 notes the auth middleware was replaced in the 2025 migration.
           Recommendation: Update DOC-008 to remove the legacy reference.
        """
    }

    // MARK: - Freshness

    func auditFreshness() -> String {
        let stale = documents.filter { $0.isStale }
        let fresh = documents.filter { !$0.isStale }
        log("Freshness audit — \(stale.count) stale, \(fresh.count) fresh")

        var result = "Freshness Audit Report:\n"
        result += "Total documents: \(documents.count)\n"
        result += "Fresh: \(fresh.count)\n"
        result += "Stale (>90 days): \(stale.count)\n\n"

        if !stale.isEmpty {
            result += "⚠️ Stale documents requiring review:\n"
            for doc in stale {
                result += "  \(doc.id): \"\(doc.title)\" — last updated \(doc.daysSinceUpdate) days ago by \(doc.author)\n"
            }
        }
        return result
    }

    // MARK: - Summarize

    func summarizeDocument(id: String) -> String {
        guard let doc = documents.first(where: { $0.id == id }) else {
            return "Document not found: \(id)"
        }
        log("Summarized: \(doc.title)")
        // Return the body for the LLM to actually summarize
        return """
        Please summarize the following document:

        TITLE: \(doc.title)
        AUTHOR: \(doc.author)
        SPACE: \(doc.space.rawValue)

        CONTENT:
        \(doc.body)

        LINKED DOCUMENTS: \(doc.linkedDocumentIds.joined(separator: ", "))
        """
    }

    // MARK: - Tagging

    func getDocumentTags(id: String) -> String {
        guard let doc = documents.first(where: { $0.id == id }) else {
            return "Document not found: \(id)"
        }
        return "Tags for \"\(doc.title)\": \(doc.tags.joined(separator: ", "))"
    }

    func addTag(documentId: String, tag: String) -> String {
        guard let index = documents.firstIndex(where: { $0.id == documentId }) else {
            return "Document not found: \(documentId)"
        }
        let cleanTag = tag.lowercased().trimmingCharacters(in: .whitespaces)
        if documents[index].tags.contains(cleanTag) {
            return "Tag '\(cleanTag)' already exists on \"\(documents[index].title)\"."
        }
        documents[index].tags.append(cleanTag)
        log("Tagged \"\(documents[index].title)\" with '\(cleanTag)'")
        return "Added tag '\(cleanTag)' to \"\(documents[index].title)\". Current tags: \(documents[index].tags.joined(separator: ", "))"
    }

    private func doc(_ doc: KBDocument) -> String {
        "\(doc.id): \"\(doc.title)\" — \(doc.space.rawValue) · \(doc.author)\(doc.isStale ? " ⚠️ STALE" : "")"
    }
}
