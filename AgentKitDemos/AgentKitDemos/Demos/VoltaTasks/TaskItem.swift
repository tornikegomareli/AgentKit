import Foundation

/// A task/ticket in the Volta demo.
struct TaskItem: Identifiable, Hashable {
    let id: String
    var title: String
    var description: String
    var status: Status
    var priority: Priority
    var assignee: String
    var storyPoints: Int
    let space: String
    let createdDate: Date
    var lastActivityDate: Date
    var labels: [String]
    var blockedBy: [String]
    var source: Source

    enum Status: String, CaseIterable, Hashable {
        case backlog = "Backlog"
        case inProgress = "In Progress"
        case inReview = "In Review"
        case done = "Done"
        case agentQueue = "Agent Queue"

        var icon: String {
            switch self {
            case .backlog: return "tray"
            case .inProgress: return "arrow.right.circle.fill"
            case .inReview: return "eye.fill"
            case .done: return "checkmark.circle.fill"
            case .agentQueue: return "bolt.fill"
            }
        }
    }

    enum Priority: String, CaseIterable, Hashable {
        case critical = "Critical"
        case high = "High"
        case medium = "Medium"
        case low = "Low"

        var icon: String {
            switch self {
            case .critical: return "exclamationmark.triangle.fill"
            case .high: return "arrow.up.circle.fill"
            case .medium: return "minus.circle.fill"
            case .low: return "arrow.down.circle.fill"
            }
        }
    }

    enum Source: String, Hashable {
        case manual = "Manual"
        case agent = "Agent"
        case github = "GitHub"
        case slack = "Slack"
    }

    var daysSinceActivity: Int {
        Calendar.current.dateComponents([.day], from: lastActivityDate, to: Date()).day ?? 0
    }

    var isStale: Bool { daysSinceActivity > 3 && status == .inProgress }
    var isBlocked: Bool { !blockedBy.isEmpty }
}

extension TaskItem {
    static func samples(relativeTo now: Date = Date()) -> [TaskItem] {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date {
            cal.date(byAdding: .day, value: -n, to: now) ?? now
        }

        return [
            TaskItem(id: "ENG-033", title: "Implement streaming response support", description: "Add AsyncStream-based streaming to AgentSession so users can see tokens as they arrive.", status: .inProgress, priority: .high, assignee: "Tornike G.", storyPoints: 8, space: "Engineering", createdDate: daysAgo(10), lastActivityDate: daysAgo(5), labels: ["core", "streaming"], blockedBy: [], source: .manual),
            TaskItem(id: "ENG-034", title: "Add token counting to DevTools", description: "Track input/output tokens per session and display in the debug inspector.", status: .backlog, priority: .medium, assignee: "Dato S.", storyPoints: 5, space: "Engineering", createdDate: daysAgo(8), lastActivityDate: daysAgo(8), labels: ["devtools", "observability"], blockedBy: ["ENG-033"], source: .manual),
            TaskItem(id: "ENG-035", title: "Fix race condition in ToolRegistry", description: "Concurrent tool registration can crash when the registry is mutated during iteration.", status: .inProgress, priority: .critical, assignee: "Tornike G.", storyPoints: 3, space: "Engineering", createdDate: daysAgo(3), lastActivityDate: daysAgo(1), labels: ["bug", "core", "concurrency"], blockedBy: [], source: .github),
            TaskItem(id: "ENG-036", title: "Write integration test for Claude adapter", description: "End-to-end test that runs a multi-turn conversation with tool calls against the real API.", status: .backlog, priority: .medium, assignee: "Unassigned", storyPoints: 5, space: "Engineering", createdDate: daysAgo(12), lastActivityDate: daysAgo(12), labels: ["testing", "providers"], blockedBy: [], source: .manual),
            TaskItem(id: "ENG-037", title: "MCP client — transport layer", description: "Implement JSON-RPC transport for MCP protocol. Support stdio and HTTP+SSE.", status: .inReview, priority: .high, assignee: "Luka M.", storyPoints: 13, space: "Engineering", createdDate: daysAgo(15), lastActivityDate: daysAgo(2), labels: ["mcp", "networking"], blockedBy: [], source: .manual),
            TaskItem(id: "ENG-038", title: "Update README with quick-start guide", description: "Add a 5-minute getting started section with code snippets.", status: .done, priority: .medium, assignee: "Nino K.", storyPoints: 2, space: "Engineering", createdDate: daysAgo(7), lastActivityDate: daysAgo(1), labels: ["docs"], blockedBy: [], source: .slack),
            TaskItem(id: "ENG-039", title: "Add Groq adapter", description: "Groq uses the OpenAI-compatible API. Create a GroqAdapter that reuses OpenAISchema translation.", status: .backlog, priority: .low, assignee: "Unassigned", storyPoints: 3, space: "Engineering", createdDate: daysAgo(20), lastActivityDate: daysAgo(20), labels: ["providers", "groq"], blockedBy: [], source: .github),
            TaskItem(id: "ENG-040", title: "ChatConfiguration dark mode support", description: "Ensure all AgentChatView themes work correctly in dark mode.", status: .inProgress, priority: .medium, assignee: "Nino K.", storyPoints: 5, space: "Engineering", createdDate: daysAgo(6), lastActivityDate: daysAgo(4), labels: ["chat", "ui", "dark-mode"], blockedBy: [], source: .manual),
            TaskItem(id: "DES-011", title: "Design demo app icon set", description: "Create icons for each demo in the catalog: banking, shopping, docs, tasks, email.", status: .backlog, priority: .low, assignee: "Salome R.", storyPoints: 3, space: "Design", createdDate: daysAgo(5), lastActivityDate: daysAgo(5), labels: ["design", "demos"], blockedBy: [], source: .manual),
            TaskItem(id: "DES-012", title: "Agent confirmation card component", description: "Design a reusable confirmation card for high-risk agent actions (transfers, deletions).", status: .inReview, priority: .high, assignee: "Salome R.", storyPoints: 5, space: "Design", createdDate: daysAgo(9), lastActivityDate: daysAgo(3), labels: ["design", "components", "safety"], blockedBy: [], source: .manual),
            TaskItem(id: "MKT-005", title: "Write launch blog post", description: "Draft a technical blog post announcing AgentKit. Target: iOS dev community on Twitter/X.", status: .backlog, priority: .medium, assignee: "Nino K.", storyPoints: 5, space: "Marketing", createdDate: daysAgo(14), lastActivityDate: daysAgo(14), labels: ["content", "launch"], blockedBy: ["ENG-033"], source: .manual),
            TaskItem(id: "MKT-006", title: "Record demo video for README", description: "30-second screen recording showing the shopping assistant demo with tool calls.", status: .backlog, priority: .high, assignee: "Luka M.", storyPoints: 3, space: "Marketing", createdDate: daysAgo(4), lastActivityDate: daysAgo(4), labels: ["content", "video"], blockedBy: ["DES-011"], source: .slack),
        ]
    }
}
