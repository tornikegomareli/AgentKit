import SwiftUI
import AgentKitCore

/// A single message bubble in the chat.
@available(iOS 17.0, macOS 14.0, *)
struct MessageBubble: View {
    let item: ChatItem
    @Environment(\.chatConfiguration) private var config

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            if item.role == .assistant || item.role == .error {
                avatarView
            }

            if item.role == .user {
                Spacer(minLength: 60)
            }

            contentView
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(bubbleBackground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            if item.role == .assistant || item.role == .error {
                Spacer(minLength: 60)
            }
        }
        .padding(.horizontal, 16)
    }

    // MARK: - Subviews

    @ViewBuilder
    private var contentView: some View {
        switch item.role {
        case .user:
            Text(item.content)
                .foregroundStyle(.white)

        case .assistant:
            Text(item.content)
                .foregroundStyle(.primary)
                .textSelection(.enabled)

        case .error:
            Label(item.content, systemImage: "exclamationmark.triangle")
                .foregroundStyle(.red)

        case .toolCall:
            EmptyView() // Handled by ToolCallRow
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        if let imageName = config.avatarImageName {
            Image(imageName)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(config.accentColor.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(String(config.agentName.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(config.accentColor)
                }
        }
    }

    private var bubbleBackground: some ShapeStyle {
        switch item.role {
        case .user:
            return AnyShapeStyle(config.accentColor)
        case .assistant:
            return AnyShapeStyle(Color.secondary.opacity(0.12))
        case .error:
            return AnyShapeStyle(Color.red.opacity(0.1))
        case .toolCall:
            return AnyShapeStyle(Color.clear)
        }
    }
}
