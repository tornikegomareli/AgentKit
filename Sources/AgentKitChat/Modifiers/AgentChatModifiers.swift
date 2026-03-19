import SwiftUI

/// View modifiers for configuring ``AgentChatView``.
///
/// These modifiers update the ``ChatConfiguration`` in the environment,
/// which the chat view and its subviews read automatically.
///
/// ## Example
/// ```swift
/// AgentChatView(session: session)
///     .agentName("Aria")
///     .agentAccentColor(.purple)
///     .agentAvatar("aria-avatar")
///     .suggestedPrompts(["What can you do?", "Track my order"])
///     .showToolCalls(false)
/// ```
@available(iOS 17.0, macOS 14.0, *)
public extension View {

    /// Set the display name of the agent.
    func agentName(_ name: String) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.agentName = name
        }
    }

    /// Set the accent color for agent bubbles and UI elements.
    func agentAccentColor(_ color: Color) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.accentColor = color
        }
    }

    /// Set the avatar image name (from asset catalog) for agent messages.
    func agentAvatar(_ imageName: String) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.avatarImageName = imageName
        }
    }

    /// Set suggested prompts shown when the conversation is empty.
    func suggestedPrompts(_ prompts: [String]) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.suggestedPrompts = prompts
        }
    }

    /// Set the placeholder text in the input bar.
    func inputPlaceholder(_ text: String) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.inputPlaceholder = text
        }
    }

    /// Whether to show tool call details inline.
    func showToolCalls(_ show: Bool) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.showToolCalls = show
        }
    }

    /// Whether to show the typing indicator while the agent processes.
    func showTypingIndicator(_ show: Bool) -> some View {
        transformEnvironment(\.chatConfiguration) { config in
            config.showTypingIndicator = show
        }
    }
}
