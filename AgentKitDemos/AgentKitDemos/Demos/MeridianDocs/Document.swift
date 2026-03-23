import Foundation

/// A knowledge document in the Meridian demo.
struct KBDocument: Identifiable, Hashable {
    let id: String
    let title: String
    let space: Space
    let author: String
    var body: String
    let createdDate: Date
    var lastUpdatedDate: Date
    var tags: [String]
    var linkedDocumentIds: [String]
    var isFresh: Bool

    enum Space: String, CaseIterable, Hashable {
        case product = "Product"
        case research = "Research"
        case engineering = "Eng Wiki"
        case onboarding = "Onboarding"

        var icon: String {
            switch self {
            case .product: return "lightbulb.fill"
            case .research: return "magnifyingglass"
            case .engineering: return "wrench.and.screwdriver.fill"
            case .onboarding: return "person.badge.plus"
            }
        }
    }

    var daysSinceUpdate: Int {
        Calendar.current.dateComponents([.day], from: lastUpdatedDate, to: Date()).day ?? 0
    }

    var isStale: Bool { daysSinceUpdate > 90 }

    var formattedLastUpdate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: lastUpdatedDate, relativeTo: Date())
    }
}

extension KBDocument {
    static func samples(relativeTo now: Date = Date()) -> [KBDocument] {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        return [
            KBDocument(
                id: "DOC-001", title: "Product Vision & Strategic Direction 2026",
                space: .product, author: "Nino K.",
                body: "Our north star is to become the default agentic platform for iOS developers. We believe that agents — not chatbots — are the next interface paradigm. AgentKit should be to agents what UIKit was to mobile UI: the foundational layer everyone builds on.\n\nKey strategic pillars:\n1. Developer experience first — 5 minutes to first working agent\n2. Provider agnostic — never lock developers into one LLM\n3. Production-grade safety — tool confirmation, audit trails, rate limits\n4. Native Swift — not a wrapper around Python, but built for Apple platforms",
                createdDate: daysAgo(45), lastUpdatedDate: daysAgo(2),
                tags: ["strategy", "vision", "2026"], linkedDocumentIds: ["DOC-003", "DOC-007"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-002", title: "User Research: Developer Pain Points with LLM Integration",
                space: .research, author: "Luka M.",
                body: "Interviewed 24 iOS developers (12 indie, 8 startup, 4 enterprise). Key findings:\n\n1. Tool calling is the #1 pain point — 83% said wiring functions to LLMs took more time than expected\n2. Multi-turn conversation state management is confusing — developers want a session abstraction\n3. 71% want streaming but find AsyncSequence/Combine bridging difficult\n4. Testing is an afterthought — no one had good mocks for their LLM layer\n5. Provider switching is a major concern — teams want to evaluate multiple models without rewriting code\n\nQuote: 'I spent 3 days just getting tool calls to work with Claude. Then my PM asked me to add GPT-4 as a fallback and I had to rewrite everything.'",
                createdDate: daysAgo(30), lastUpdatedDate: daysAgo(15),
                tags: ["research", "user-interviews", "pain-points"], linkedDocumentIds: ["DOC-001", "DOC-004"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-003", title: "Q2 2026 Roadmap",
                space: .product, author: "Nino K.",
                body: "Q2 priorities:\n- Phase 3: MCP client integration (April)\n- Phase 4: DevTools — inspector, replay, token counter (May)\n- Phase 5: Documentation site + example gallery (June)\n- Stretch: Apple Foundation Models adapter\n\nSuccess metric: 500 GitHub stars by end of Q2\nShip cadence: bi-weekly releases",
                createdDate: daysAgo(20), lastUpdatedDate: daysAgo(5),
                tags: ["roadmap", "Q2", "planning"], linkedDocumentIds: ["DOC-001", "DOC-005"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-004", title: "Architecture: Agent Loop Design",
                space: .engineering, author: "Tornike G.",
                body: "The agent loop follows a simple cycle: Prompt → LLM → Parse → (Tool Call → Result → LLM)* → Final Response.\n\nKey decisions:\n- AgentLoopRunner is an actor — all state mutations are serial\n- Tool execution is async and can be parallelized in future\n- Max iterations prevent runaway loops (configurable, default 8)\n- Each iteration emits AgentLoopEvent via AsyncStream\n- Session history is maintained as [AgentMessage] array\n\nThe LLMAdapter protocol is the boundary: Core knows nothing about HTTP, SDKs, or specific providers.",
                createdDate: daysAgo(60), lastUpdatedDate: daysAgo(25),
                tags: ["architecture", "agent-loop", "core"], linkedDocumentIds: ["DOC-005", "DOC-006"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-005", title: "Provider Adapter Implementation Guide",
                space: .engineering, author: "Tornike G.",
                body: "Each LLM provider needs an adapter conforming to LLMAdapter protocol.\n\nRequired method: sendMessage(_ messages:tools:) async throws -> LLMResponse\n\nThe adapter must:\n1. Translate AgentMessage array to provider-specific format\n2. Convert ToolParameter schemas to provider's tool format\n3. Parse the response into LLMResponse (text + optional tool calls)\n4. Handle streaming if the provider supports it\n\nCurrent adapters: ClaudeAdapter, OpenAIAdapter, OllamaAdapter, AppleAdapter\nSchema translation lives in SchemaTranslation/ — one file per provider.",
                createdDate: daysAgo(55), lastUpdatedDate: daysAgo(20),
                tags: ["guide", "providers", "adapters"], linkedDocumentIds: ["DOC-004"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-006", title: "Authentication Architecture (Legacy)",
                space: .engineering, author: "Dato S.",
                body: "Note: This document describes the PREVIOUS auth system used before the 2025 migration.\n\nSession tokens were stored in UserDefaults with a 24-hour TTL. Refresh tokens used Keychain with biometric protection. The auth middleware intercepted all API calls and attached the bearer token.\n\nKnown issues:\n- Session token storage in UserDefaults didn't meet compliance requirements\n- No token rotation on suspicious activity\n- Refresh flow had a race condition under poor connectivity",
                createdDate: daysAgo(200), lastUpdatedDate: daysAgo(150),
                tags: ["auth", "legacy", "security"], linkedDocumentIds: ["DOC-005"],
                isFresh: false
            ),
            KBDocument(
                id: "DOC-007", title: "Competitive Landscape Analysis",
                space: .product, author: "Luka M.",
                body: "Direct competitors:\n- LangChain (Python) — dominant in Python, no Swift support\n- Vercel AI SDK (TypeScript) — excellent DX, web-focused\n- Semantic Kernel (C#/.NET) — Microsoft-backed, enterprise-heavy\n\nKey differentiator: None of these target Apple platforms natively. iOS developers currently cobble together raw API calls or use thin wrappers. AgentKit is the first Swift-native agentic framework.\n\nOpportunity: 5.7M registered Apple developers, growing LLM adoption in iOS apps.",
                createdDate: daysAgo(35), lastUpdatedDate: daysAgo(10),
                tags: ["competitive", "market", "analysis"], linkedDocumentIds: ["DOC-001", "DOC-002"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-008", title: "New Developer Onboarding Checklist",
                space: .onboarding, author: "Nino K.",
                body: "Week 1:\n- [ ] Clone repo, run swift build and swift test\n- [ ] Read CLAUDE.md for code rules\n- [ ] Read Architecture doc (DOC-004)\n- [ ] Build and run the demo app\n- [ ] Submit a small PR (documentation fix or test)\n\nWeek 2:\n- [ ] Implement a toy tool and register it\n- [ ] Write tests using MockLLMAdapter\n- [ ] Review one open PR\n- [ ] Read Provider Adapter guide (DOC-005)\n\nWeek 3:\n- [ ] Pick a starter issue from the backlog\n- [ ] Ship your first feature PR",
                createdDate: daysAgo(40), lastUpdatedDate: daysAgo(40),
                tags: ["onboarding", "checklist", "new-hire"], linkedDocumentIds: ["DOC-004", "DOC-005"],
                isFresh: true
            ),
            KBDocument(
                id: "DOC-009", title: "API Reference: Core Types",
                space: .engineering, author: "Tornike G.",
                body: "AgentKit — main entry point, holds ToolRegistry + Configuration\nAgentSession — manages a single conversation, emits events\nAgentLoopRunner — executes the reason/act/observe loop\nToolRegistry — actor, stores and executes tools\nStateManager — actor, key-value state shared across tools\nConfiguration — maxIterations, systemPrompt, logging\nAgentMessage — .user/.assistant/.toolCall/.toolResult\nAgentTool — name, description, parameters, handler\nLLMAdapter — protocol for provider implementations\nLLMResponse — text + optional [ToolCall]",
                createdDate: daysAgo(50), lastUpdatedDate: daysAgo(120),
                tags: ["api", "reference", "types"], linkedDocumentIds: ["DOC-004", "DOC-005"],
                isFresh: false
            ),
            KBDocument(
                id: "DOC-010", title: "Incident Post-Mortem: Token Leak in Logs",
                space: .engineering, author: "Dato S.",
                body: "Date: January 2026\nSeverity: Medium\nImpact: API keys were printed to console in debug builds\n\nRoot cause: The OpenAI adapter logged the full request headers including Authorization. The print statement was added during debugging and never removed.\n\nFix: Removed all print() calls. Added os.Logger as the only logging mechanism. Added a CI check that fails on any print() in library code.\n\nLesson: This is why CLAUDE.md says 'No print — use os.Logger'. The rule exists because of this incident.",
                createdDate: daysAgo(80), lastUpdatedDate: daysAgo(80),
                tags: ["incident", "security", "post-mortem"], linkedDocumentIds: ["DOC-005"],
                isFresh: true
            ),
        ]
    }
}
