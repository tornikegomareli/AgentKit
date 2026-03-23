import Foundation
import AgentKitCore
import SwiftUI

/// Transforms ``AgentLoopEvent`` streams into renderable chat items.
///
/// This is the bridge between the headless ``AgentSession`` and the chat UI.
/// It accumulates streaming tokens into the current assistant message,
/// tracks tool call state, and produces a flat list of ``ChatItem`` for display.
@available(iOS 17.0, macOS 14.0, *)
@Observable
public final class ChatMessageViewModel {
    /// All renderable items in the conversation.
    public private(set) var items: [ChatItem] = []

    /// Whether the agent is currently generating a response.
    public private(set) var isStreaming: Bool = false

    /// The text accumulated so far in the current streaming response.
    public private(set) var streamingText: String = ""

    /// Active tool calls being executed.
    public private(set) var activeToolCalls: Set<String> = []

    private let session: AgentSession

    public init(session: AgentSession) {
        self.session = session
    }

    /// Send a user message and begin consuming the event stream.
    @MainActor
    public func send(_ text: String) {
        items.append(ChatItem(role: .user, content: text))
        isStreaming = true
        streamingText = ""

        session.send(text)

        Task { @MainActor [weak self] in
            guard let self else { return }
            for await event in session.events {
                self.handleEvent(event)
            }
            self.finalizeStream()
        }
    }

    /// Clear the conversation.
    @MainActor
    public func reset() {
        items.removeAll()
        streamingText = ""
        isStreaming = false
        activeToolCalls.removeAll()
        session.reset()
    }

    // MARK: - Private

    @MainActor
    private func handleEvent(_ event: AgentLoopEvent) {
        switch event {
        case .token(let token):
            streamingText += token

        case .toolCallStarted(let name):
            activeToolCalls.insert(name)
            items.append(ChatItem(role: .toolCall, content: name, toolState: .running))

        case .toolCallCompleted(let name, let result):
            activeToolCalls.remove(name)
            // Update the matching tool call item
            if let index = items.lastIndex(where: {
                $0.role == .toolCall && $0.content == name && $0.toolState == .running
            }) {
                items[index] = ChatItem(
                    role: .toolCall,
                    content: name,
                    toolResult: result,
                    toolState: .completed
                )
            }

        case .responseComplete(let text):
            streamingText = ""
            items.append(ChatItem(role: .assistant, content: text))

        case .toolConfirmationRequired(let pending):
            items.append(ChatItem(
                role: .toolCall,
                content: pending.displayMessage ?? "Confirm: \(pending.toolName)",
                toolState: .pendingConfirmation,
                pendingConfirmation: pending
            ))

        case .error(let error):
            items.append(ChatItem(role: .error, content: error.description))
        }
    }

    /// Approve a pending tool confirmation, allowing it to execute.
    @MainActor
    public func approve(_ id: UUID) {
        if let index = items.lastIndex(where: { $0.pendingConfirmation?.id == id }) {
            items[index] = ChatItem(
                role: .toolCall,
                content: items[index].content,
                toolState: .running
            )
        }
        session.approve(id)
    }

    /// Reject a pending tool confirmation. The LLM receives a "declined" result.
    @MainActor
    public func reject(_ id: UUID) {
        if let index = items.lastIndex(where: { $0.pendingConfirmation?.id == id }) {
            items[index] = ChatItem(
                role: .toolCall,
                content: items[index].content,
                toolState: .rejected
            )
        }
        session.reject(id)
    }

    @MainActor
    private func finalizeStream() {
        // If we have leftover streaming text that wasn't finalized by responseComplete
        if !streamingText.isEmpty {
            items.append(ChatItem(role: .assistant, content: streamingText))
            streamingText = ""
        }
        isStreaming = false
    }
}

// MARK: - Chat Item

/// A single renderable item in the chat.
public struct ChatItem: Identifiable, Sendable {
    public let id = UUID()
    public let role: Role
    public let content: String
    public var toolResult: String?
    public var toolState: ToolState?

    public enum Role: Sendable {
        case user
        case assistant
        case toolCall
        case error
    }

    public enum ToolState: Sendable {
        case running
        case completed
        case pendingConfirmation
        case rejected
    }

    public var pendingConfirmation: PendingToolConfirmation?

    public init(
        role: Role,
        content: String,
        toolResult: String? = nil,
        toolState: ToolState? = nil,
        pendingConfirmation: PendingToolConfirmation? = nil
    ) {
        self.role = role
        self.content = content
        self.toolResult = toolResult
        self.toolState = toolState
        self.pendingConfirmation = pendingConfirmation
    }
}
