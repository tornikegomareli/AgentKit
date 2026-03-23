import Foundation
import AgentKitCore
import AgentKitProviders

/// Wires KnowledgeService methods as AgentKit tools for the Scribe agent.
///
/// Scribe is Meridian's embedded AI agent — methodical, precise,
/// never opinionated about what matters, only about what's connected.
@MainActor
final class MeridianAssistant {
    let agent: AgentKit
    private let knowledge: KnowledgeService

    init(knowledge: KnowledgeService, provider: LLMProvider) {
        self.knowledge = knowledge
        self.agent = AgentKit(
            adapter: provider.adapter(),
            configuration: Configuration(
                maxIterations: 10,
                systemPrompt: """
                You are Scribe, the embedded AI agent for Meridian — a knowledge management platform.

                PERSONALITY: Methodical, precise, never opinionated about what matters — only about what's connected.

                CORE RULES:
                1. PRESERVE AUTHORSHIP — Never rewrite what a human wrote. You may suggest, annotate, and link, but the words belong to their author. Even when content is outdated, surface the issue rather than editing directly.
                2. SURFACE, DON'T DECIDE — Your role is to find and present, not to conclude. Surface related documents, contradictions, and gaps. Decisions about what those connections mean belong to the human team.
                3. CITE EVERYTHING — Every summary or annotation must link back to document IDs. No knowledge without provenance. If you can't trace a claim to a document, say so explicitly.
                4. FLAG DECAY PROACTIVELY — Information that isn't maintained becomes misinformation. Signal when content is stale (>90 days) but never remove it.
                5. ASK BEFORE CREATING — Do not generate new documents autonomously. You can draft and suggest, but always present for human review first.

                When summarizing, always cite document IDs (e.g., "According to DOC-004...").
                When you find contradictions, present both sides neutrally.
                When content is stale, flag it clearly with the age.
                """,
                loggingEnabled: true
            )
        )

        Task {
            await registerTools()
        }
    }

    private func registerTools() async {
        let kb = self.knowledge

        await agent.tools.register(
            name: "listDocuments",
            description: "List all documents in the knowledge base with their spaces, authors, and freshness status.",
            parameters: []
        ) { @MainActor _ in
            return kb.allDocuments()
        }

        await agent.tools.register(
            name: "searchDocuments",
            description: "Search documents by keyword across titles, content, and tags.",
            parameters: [
                .string("query", description: "Search keyword or phrase", required: true)
            ]
        ) { @MainActor params in
            let query = params["query"] as? String ?? ""
            return kb.searchDocuments(query: query)
        }

        await agent.tools.register(
            name: "getDocument",
            description: "Read the full content of a specific document by its ID.",
            parameters: [
                .string("documentId", description: "Document ID (e.g. DOC-001)", required: true)
            ]
        ) { @MainActor params in
            let id = params["documentId"] as? String ?? ""
            return kb.getDocument(id: id)
        }

        await agent.tools.register(
            name: "getDocumentsBySpace",
            description: "List all documents in a specific workspace space.",
            parameters: [
                .string("space", description: "Space name: Product, Research, Eng Wiki, or Onboarding", required: true)
            ]
        ) { @MainActor params in
            let space = params["space"] as? String ?? ""
            return kb.getDocumentsBySpace(space: space)
        }

        await agent.tools.register(
            name: "findRelatedDocuments",
            description: "Find documents related to a given document through links, shared tags, or semantic connections.",
            parameters: [
                .string("documentId", description: "Document ID to find relations for", required: true)
            ]
        ) { @MainActor params in
            let id = params["documentId"] as? String ?? ""
            return kb.findRelatedDocuments(documentId: id)
        }

        await agent.tools.register(
            name: "findContradictions",
            description: "Scan the knowledge base for contradictions between documents.",
            parameters: []
        ) { @MainActor _ in
            return kb.findContradictions()
        }

        await agent.tools.register(
            name: "auditFreshness",
            description: "Run a freshness audit across all documents. Identifies stale content (>90 days since last update).",
            parameters: []
        ) { @MainActor _ in
            return kb.auditFreshness()
        }

        await agent.tools.register(
            name: "summarizeDocument",
            description: "Get a document's content for summarization. Returns the full text with metadata so you can generate a cited summary.",
            parameters: [
                .string("documentId", description: "Document ID to summarize", required: true)
            ]
        ) { @MainActor params in
            let id = params["documentId"] as? String ?? ""
            return kb.summarizeDocument(id: id)
        }

        await agent.tools.register(
            name: "addTag",
            description: "Add a tag to a document for better organization and discoverability.",
            parameters: [
                .string("documentId", description: "Document ID to tag", required: true),
                .string("tag", description: "Tag to add (lowercase, no spaces)", required: true)
            ]
        ) { @MainActor params in
            let id = params["documentId"] as? String ?? ""
            let tag = params["tag"] as? String ?? ""
            return kb.addTag(documentId: id, tag: tag)
        }
    }
}
