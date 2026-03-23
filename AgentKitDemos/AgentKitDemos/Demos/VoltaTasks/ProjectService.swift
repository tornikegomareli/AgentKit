import Foundation
import Observation

/// Mock project management service for the Volta demo.
@Observable
final class ProjectService {
    var tasks: [TaskItem] = TaskItem.samples()
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

    // MARK: - Queries

    var sprintName: String { "Engineering Sprint 24" }

    func allTasks() -> String {
        log("Listed all tasks")
        return tasks.map { taskLine($0) }.joined(separator: "\n")
    }

    func tasksByStatus(_ status: TaskItem.Status) -> [TaskItem] {
        tasks.filter { $0.status == status }
    }

    func getTask(id: String) -> String {
        guard let task = tasks.first(where: { $0.id == id }) else {
            return "Task not found: \(id)"
        }
        log("Viewed task \(task.id)")
        return """
        TASK: \(task.id) — \(task.title)
        STATUS: \(task.status.rawValue)
        PRIORITY: \(task.priority.rawValue)
        ASSIGNEE: \(task.assignee)
        STORY POINTS: \(task.storyPoints)
        SPACE: \(task.space)
        LABELS: \(task.labels.joined(separator: ", "))
        BLOCKED BY: \(task.blockedBy.isEmpty ? "None" : task.blockedBy.joined(separator: ", "))
        LAST ACTIVITY: \(task.daysSinceActivity) days ago
        \(task.isStale ? "⚠️ STALE — no activity in \(task.daysSinceActivity) days" : "")

        DESCRIPTION:
        \(task.description)
        """
    }

    func getBoard() -> String {
        log("Viewed Kanban board")
        var result = "📋 \(sprintName)\n\n"
        for status in TaskItem.Status.allCases {
            let col = tasks.filter { $0.status == status }
            result += "[\(status.rawValue)] — \(col.count) tasks\n"
            for task in col {
                result += "  \(taskLine(task))\n"
            }
            result += "\n"
        }
        return result
    }

    func getTasksByAssignee(name: String) -> String {
        let assigned = tasks.filter { $0.assignee.lowercased().contains(name.lowercased()) }
        guard !assigned.isEmpty else { return "No tasks found for '\(name)'." }
        log("Listed tasks for \(name)")
        return assigned.map { taskLine($0) }.joined(separator: "\n")
    }

    // MARK: - Sprint Health

    func sprintHealth() -> String {
        let total = tasks.filter { $0.space == "Engineering" }
        let done = total.filter { $0.status == .done }
        let blocked = total.filter { $0.isBlocked }
        let stale = total.filter { $0.isStale }
        let inProgress = total.filter { $0.status == .inProgress }
        let totalPoints = total.reduce(0) { $0 + $1.storyPoints }
        let donePoints = done.reduce(0) { $0 + $1.storyPoints }
        let healthPct = totalPoints > 0 ? (Double(donePoints) / Double(totalPoints)) * 100 : 0

        log("Sprint health check — \(Int(healthPct))%")

        return """
        Sprint Health: \(sprintName)

        Progress: \(done.count)/\(total.count) tasks done (\(donePoints)/\(totalPoints) story points)
        Completion: \(String(format: "%.0f%%", healthPct))

        In Progress: \(inProgress.count) tasks
        Blocked: \(blocked.count) tasks\(blocked.isEmpty ? "" : " ⚠️")
        Stale (no activity >3 days): \(stale.count) tasks\(stale.isEmpty ? "" : " ⚠️")

        \(blocked.isEmpty ? "" : "Blocked tasks:\n" + blocked.map { "  \($0.id): \($0.title) — blocked by \($0.blockedBy.joined(separator: ", "))" }.joined(separator: "\n"))

        \(stale.isEmpty ? "" : "\nStale tasks:\n" + stale.map { "  \($0.id): \($0.title) — \($0.daysSinceActivity) days without activity (assigned to \($0.assignee))" }.joined(separator: "\n"))
        """
    }

    // MARK: - Dependency Analysis

    func analyzeDependencies() -> String {
        let blocked = tasks.filter { $0.isBlocked }
        let blockers = Set(blocked.flatMap(\.blockedBy))

        log("Dependency analysis")

        var result = "Dependency Analysis:\n\n"
        result += "Blocking tasks (unblock these first):\n"
        for blockerId in blockers {
            let blocker = tasks.first(where: { $0.id == blockerId })
            let dependents = blocked.filter { $0.blockedBy.contains(blockerId) }
            result += "  \(blockerId): \(blocker?.title ?? "Unknown") [\(blocker?.status.rawValue ?? "?")]"
            result += " — blocks \(dependents.count) task\(dependents.count == 1 ? "" : "s"): \(dependents.map(\.id).joined(separator: ", "))\n"
        }

        if blocked.isEmpty {
            result += "  No blocked tasks — dependency chain is clear.\n"
        }
        return result
    }

    // MARK: - Task Mutations

    func moveTask(taskId: String, to status: String) -> String {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            return "Task not found: \(taskId)"
        }
        guard let newStatus = TaskItem.Status(rawValue: status) else {
            return "Invalid status: \(status). Valid: \(TaskItem.Status.allCases.map(\.rawValue).joined(separator: ", "))"
        }
        let oldStatus = tasks[index].status
        tasks[index].status = newStatus
        tasks[index].lastActivityDate = Date()
        log("Moved \(taskId) from \(oldStatus.rawValue) → \(newStatus.rawValue)")
        return "Moved \(taskId) \"\(tasks[index].title)\" from \(oldStatus.rawValue) → \(newStatus.rawValue)"
    }

    func updatePriority(taskId: String, priority: String) -> String {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            return "Task not found: \(taskId)"
        }
        guard let newPriority = TaskItem.Priority(rawValue: priority) else {
            return "Invalid priority: \(priority). Valid: \(TaskItem.Priority.allCases.map(\.rawValue).joined(separator: ", "))"
        }
        let old = tasks[index].priority
        tasks[index].priority = newPriority
        tasks[index].lastActivityDate = Date()
        log("Changed \(taskId) priority: \(old.rawValue) → \(newPriority.rawValue)")
        return "Updated \(taskId) priority from \(old.rawValue) → \(newPriority.rawValue)"
    }

    func assignTask(taskId: String, assignee: String) -> String {
        guard let index = tasks.firstIndex(where: { $0.id == taskId }) else {
            return "Task not found: \(taskId)"
        }
        let old = tasks[index].assignee
        tasks[index].assignee = assignee
        tasks[index].lastActivityDate = Date()
        log("Reassigned \(taskId): \(old) → \(assignee)")
        return "Reassigned \(taskId) \"\(tasks[index].title)\" from \(old) → \(assignee)"
    }

    func findOverdueTasks() -> String {
        let stale = tasks.filter { $0.isStale }
        guard !stale.isEmpty else { return "No stale or overdue tasks found." }
        log("Found \(stale.count) overdue/stale tasks")
        return "Overdue/stale tasks (no activity >3 days while In Progress):\n" +
            stale.map { "  \($0.id): \($0.title) — \($0.daysSinceActivity) days idle, assigned to \($0.assignee)" }
                .joined(separator: "\n")
    }

    // MARK: - Helpers

    private func taskLine(_ task: TaskItem) -> String {
        var line = "\(task.id) [\(task.status.rawValue)] \(task.priority.rawValue.prefix(1))·\(task.storyPoints)pt — \(task.title)"
        if task.isBlocked { line += " 🚫 BLOCKED" }
        if task.isStale { line += " ⚠️ STALE" }
        if task.source == .agent { line += " ⚡" }
        return line
    }
}
