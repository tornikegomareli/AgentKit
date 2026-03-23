import SwiftUI

/// Kanban board view for the Volta task management demo.
struct BoardView: View {
    @Environment(ProjectService.self) private var project
    @State private var selectedColumn: TaskItem.Status = .inProgress

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Column picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 0) {
                        ForEach(TaskItem.Status.allCases, id: \.self) { status in
                            columnTab(status)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
                .background(Color(hex: 0x141418))

                // Task list for selected column
                let tasks = project.tasksByStatus(selectedColumn)
                if tasks.isEmpty {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: selectedColumn.icon)
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: 0x9090A0))
                        Text("No tasks in \(selectedColumn.rawValue)")
                            .font(.subheadline)
                            .foregroundStyle(Color(hex: 0x9090A0))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(tasks) { task in
                                taskCard(task)
                            }
                        }
                        .padding()
                    }
                }
            }
            .background(Color(hex: 0x0D0D0F))
            .navigationTitle(project.sprintName)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color(hex: 0x141418), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func columnTab(_ status: TaskItem.Status) -> some View {
        let count = project.tasksByStatus(status).count
        let isSelected = selectedColumn == status
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedColumn = status }
        } label: {
            VStack(spacing: 4) {
                HStack(spacing: 4) {
                    if status == .agentQueue {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: 0xA8E040))
                    }
                    Text(status.rawValue)
                        .font(.caption.weight(.medium))
                    Text("\(count)")
                        .font(.caption2.weight(.bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(isSelected ? Color.white.opacity(0.2) : Color.white.opacity(0.08))
                        .clipShape(Capsule())
                }
                .foregroundStyle(isSelected ? Color.white : Color(hex: 0x9090A0))

                Rectangle()
                    .fill(isSelected ? (status == .agentQueue ? Color(hex: 0xA8E040) : .white) : .clear)
                    .frame(height: 2)
            }
            .padding(.horizontal, 12)
        }
        .buttonStyle(.plain)
    }

    private func taskCard(_ task: TaskItem) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // ID + Priority
            HStack {
                Text(task.id)
                    .font(.caption.weight(.bold).monospaced())
                    .foregroundStyle(Color(hex: 0xA8E040))
                if task.source == .agent {
                    Text("⚡ AGENT")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Color(hex: 0xA8E040))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(hex: 0xA8E040).opacity(0.15))
                        .clipShape(Capsule())
                }
                Spacer()
                HStack(spacing: 4) {
                    Image(systemName: task.priority.icon)
                        .font(.caption2)
                    Text(task.priority.rawValue)
                        .font(.caption2)
                }
                .foregroundStyle(priorityColor(task.priority))
            }

            // Title
            Text(task.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color(hex: 0xE8E8EC))

            // Bottom row
            HStack {
                Text(task.assignee)
                    .font(.caption)
                    .foregroundStyle(Color(hex: 0x9090A0))

                Spacer()

                HStack(spacing: 8) {
                    if task.isBlocked {
                        Text("BLOCKED")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.red)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.red.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    if task.isStale {
                        Text("STALE")
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .clipShape(Capsule())
                    }
                    Text("\(task.storyPoints) pts")
                        .font(.caption2.monospaced())
                        .foregroundStyle(Color(hex: 0x9090A0))
                }
            }

            // Labels
            if !task.labels.isEmpty {
                HStack(spacing: 4) {
                    ForEach(task.labels.prefix(3), id: \.self) { label in
                        Text(label)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.white.opacity(0.07))
                            .clipShape(Capsule())
                            .foregroundStyle(Color(hex: 0x9090A0))
                    }
                }
            }
        }
        .padding(14)
        .background(Color(hex: 0x1A1A1F))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(task.source == .agent ? Color(hex: 0xA8E040).opacity(0.3) : Color.white.opacity(0.07), lineWidth: 1)
        )
    }

    private func priorityColor(_ priority: TaskItem.Priority) -> Color {
        switch priority {
        case .critical: return .red
        case .high: return .orange
        case .medium: return Color(hex: 0x9090A0)
        case .low: return Color(hex: 0x606070)
        }
    }
}
