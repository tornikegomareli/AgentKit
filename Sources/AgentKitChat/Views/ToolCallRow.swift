import SwiftUI
import AgentKitCore

/// Displays an inline tool call with status indicator.
@available(iOS 17.0, macOS 14.0, *)
struct ToolCallRow: View {
    let item: ChatItem
    @Environment(\.chatConfiguration) private var config

    var body: some View {
        HStack(spacing: 8) {
            statusIcon
            VStack(alignment: .leading, spacing: 2) {
                Text(item.content)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                if let result = item.toolResult, item.toolState == .completed {
                    Text(result.prefix(200))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                        .lineLimit(3)
                }
            }
            Spacer()
        }
        .padding(.horizontal, 52)
        .padding(.vertical, 4)
    }

    @ViewBuilder
    private var statusIcon: some View {
        switch item.toolState {
        case .running:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
                .font(.caption)
        case .rejected:
            Image(systemName: "xmark.circle.fill")
                .foregroundStyle(.red)
                .font(.caption)
        case .pendingConfirmation:
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)
                .font(.caption)
        case .none:
            EmptyView()
        }
    }
}
