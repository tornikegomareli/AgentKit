import Foundation
import AgentKitCore
import AgentKitProviders

/// Wires ProjectService methods as AgentKit tools for the Forge agent.
///
/// Forge is Volta's embedded AI agent — systematic, precise, data-driven.
/// Surfaces signals without drama.
@MainActor
final class VoltaAssistant {
    let agent: AgentKit
    private let project: ProjectService

    init(project: ProjectService, provider: LLMProvider) {
        self.project = project
        self.agent = AgentKit(
            adapter: provider.adapter(),
            configuration: Configuration(
                maxIterations: 10,
                systemPrompt: """
                You are Forge, the embedded AI agent for Volta — a project management platform.

                PERSONALITY: Systematic, precise, data-driven. You surface signals without drama.

                CORE RULES:
                1. HUMAN APPROVAL GATE — Never create, modify, assign, or delete tasks silently. Always explain what you want to do and why before doing it.
                2. EXPLAIN EVERY ACTION — Every suggestion comes with a clear, plain-English reason. "ENG-033 hasn't had a commit in 4 days and is blocking 2 other tasks."
                3. RESPECT OWNERSHIP — Never reassign a task without explaining why. Ownership changes are always transparent.
                4. ESCALATE BLOCKERS — When a task is blocked or stale, surface it immediately with context.
                5. STAY IN SCOPE — Only operate within the spaces you can see. No assumptions about work happening elsewhere.
                6. MINIMAL FOOTPRINT — One precise suggestion beats three speculative ones. When in doubt, do less.

                When showing the board, use the status columns: Backlog, In Progress, In Review, Done, Agent Queue.
                Always include task IDs (e.g., ENG-033) so users can reference them.
                When analyzing sprint health, show concrete numbers — don't just say "on track."
                Flag stale tasks (no activity >3 days while In Progress) proactively.
                """,
                loggingEnabled: true
            )
        )

        Task {
            await registerTools()
        }
    }

    private func registerTools() async {
        let project = self.project

        await agent.tools.register(
            name: "getBoard",
            description: "Show the full Kanban board with all tasks organized by status columns.",
            parameters: []
        ) { @MainActor _ in
            return project.getBoard()
        }

        await agent.tools.register(
            name: "getTask",
            description: "Get detailed information about a specific task by its ID.",
            parameters: [
                .string("taskId", description: "Task ID (e.g. ENG-033)", required: true)
            ]
        ) { @MainActor params in
            let id = params["taskId"] as? String ?? ""
            return project.getTask(id: id)
        }

        await agent.tools.register(
            name: "getTasksByAssignee",
            description: "List all tasks assigned to a specific person.",
            parameters: [
                .string("name", description: "Assignee name or partial name", required: true)
            ]
        ) { @MainActor params in
            let name = params["name"] as? String ?? ""
            return project.getTasksByAssignee(name: name)
        }

        await agent.tools.register(
            name: "sprintHealth",
            description: "Calculate and display sprint health: progress, blocked tasks, stale tasks, velocity.",
            parameters: []
        ) { @MainActor _ in
            return project.sprintHealth()
        }

        await agent.tools.register(
            name: "analyzeDependencies",
            description: "Analyze task dependency chains. Shows which tasks are blocking others and what to unblock first.",
            parameters: []
        ) { @MainActor _ in
            return project.analyzeDependencies()
        }

        await agent.tools.register(
            name: "findOverdueTasks",
            description: "Find tasks that are stale or overdue (no activity while In Progress for >3 days).",
            parameters: []
        ) { @MainActor _ in
            return project.findOverdueTasks()
        }

        await agent.tools.register(
            name: "moveTask",
            description: "Move a task to a different status column. REQUIRES APPROVAL — always explain why before executing.",
            parameters: [
                .string("taskId", description: "Task ID to move", required: true),
                .string("status", description: "Target status: Backlog, In Progress, In Review, Done, Agent Queue", required: true)
            ]
        ) { @MainActor params in
            let id = params["taskId"] as? String ?? ""
            let status = params["status"] as? String ?? ""
            return project.moveTask(taskId: id, to: status)
        }

        await agent.tools.register(
            name: "updatePriority",
            description: "Change a task's priority level. REQUIRES APPROVAL.",
            parameters: [
                .string("taskId", description: "Task ID", required: true),
                .string("priority", description: "New priority: Critical, High, Medium, Low", required: true)
            ]
        ) { @MainActor params in
            let id = params["taskId"] as? String ?? ""
            let priority = params["priority"] as? String ?? ""
            return project.updatePriority(taskId: id, priority: priority)
        }

        await agent.tools.register(
            name: "assignTask",
            description: "Reassign a task to a different person. REQUIRES APPROVAL — always explain the reason.",
            parameters: [
                .string("taskId", description: "Task ID to reassign", required: true),
                .string("assignee", description: "New assignee name", required: true)
            ]
        ) { @MainActor params in
            let id = params["taskId"] as? String ?? ""
            let assignee = params["assignee"] as? String ?? ""
            return project.assignTask(taskId: id, assignee: assignee)
        }
    }
}
