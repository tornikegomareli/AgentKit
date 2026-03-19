import SwiftUI
import AgentKitCore

/// Configuration for the drop-in ``AgentChatView``.
///
/// Customize colors, agent name, avatar, suggested prompts, and placeholder text.
/// Pass via the environment or through view modifiers on ``AgentChatView``.
///
/// ## Example
/// ```swift
/// AgentChatView(session: session)
///     .agentName("Aria")
///     .agentAccentColor(.purple)
///     .suggestedPrompts(["What can you do?", "Help me find a product"])
/// ```
@available(iOS 17.0, macOS 14.0, *)
public struct ChatConfiguration: Sendable {
    /// Display name of the agent shown in the header.
    public var agentName: String

    /// Accent color for the agent's message bubbles and UI elements.
    public var accentColor: Color

    /// Avatar image name (from the asset catalog) shown next to agent messages.
    public var avatarImageName: String?

    /// Placeholder text in the input bar when empty.
    public var inputPlaceholder: String

    /// Suggested prompts shown when the conversation is empty.
    public var suggestedPrompts: [String]

    /// Whether to show the typing indicator while the agent is processing.
    public var showTypingIndicator: Bool

    /// Whether to show tool call details inline in the chat.
    public var showToolCalls: Bool

    public init(
        agentName: String = "Agent",
        accentColor: Color = .blue,
        avatarImageName: String? = nil,
        inputPlaceholder: String = "Message...",
        suggestedPrompts: [String] = [],
        showTypingIndicator: Bool = true,
        showToolCalls: Bool = true
    ) {
        self.agentName = agentName
        self.accentColor = accentColor
        self.avatarImageName = avatarImageName
        self.inputPlaceholder = inputPlaceholder
        self.suggestedPrompts = suggestedPrompts
        self.showTypingIndicator = showTypingIndicator
        self.showToolCalls = showToolCalls
    }

    public static let `default` = ChatConfiguration()
}

// MARK: - Environment Key

@available(iOS 17.0, macOS 14.0, *)
private struct ChatConfigurationKey: EnvironmentKey {
    static let defaultValue = ChatConfiguration.default
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    var chatConfiguration: ChatConfiguration {
        get { self[ChatConfigurationKey.self] }
        set { self[ChatConfigurationKey.self] = newValue }
    }
}
