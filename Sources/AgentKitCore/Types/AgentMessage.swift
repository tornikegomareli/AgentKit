import Foundation

/// A single message in the agent's conversation history.
///
/// The agent loop maintains an ordered list of messages that grows as the
/// conversation progresses. This history is sent to the LLM on each turn,
/// subject to context window budget constraints.
public enum AgentMessage: Sendable {
    /// A message from the user.
    case user(String)

    /// A text response from the assistant.
    case assistant(String)

    /// A tool invocation requested by the assistant.
    case toolCall(name: String, params: SendableDictionary)

    /// The result of a tool execution, fed back to the LLM.
    case toolResult(name: String, result: String)
}

extension AgentMessage: Equatable {
    public static func == (lhs: AgentMessage, rhs: AgentMessage) -> Bool {
        switch (lhs, rhs) {
        case (.user(let a), .user(let b)):
            return a == b
        case (.assistant(let a), .assistant(let b)):
            return a == b
        case (.toolCall(let nameA, let paramsA), .toolCall(let nameB, let paramsB)):
            return nameA == nameB && paramsA.description == paramsB.description
        case (.toolResult(let nameA, let resultA), .toolResult(let nameB, let resultB)):
            return nameA == nameB && resultA == resultB
        default:
            return false
        }
    }
}

extension AgentMessage: CustomStringConvertible {
    public var description: String {
        switch self {
        case .user(let text):
            return "[user] \(text)"
        case .assistant(let text):
            return "[assistant] \(text)"
        case .toolCall(let name, let params):
            return "[tool_call] \(name)(\(params))"
        case .toolResult(let name, let result):
            return "[tool_result] \(name) -> \(result)"
        }
    }
}
