import Foundation

/// Events emitted by the agent loop during a single turn of reasoning.
///
/// Subscribe to these events via ``AgentSession/events`` to drive your UI.
/// Events arrive in real time — tokens stream as the LLM generates them,
/// tool calls are announced before and after execution, and the final
/// response is delivered as a single complete string.
public enum AgentLoopEvent: Sendable {
    /// A single token from the LLM's streaming response.
    /// Append these to the current assistant message for real-time display.
    case token(String)

    /// The agent has decided to call a tool. Fires before execution begins.
    case toolCallStarted(name: String)

    /// A tool call has finished executing. The result will be fed back to the LLM.
    case toolCallCompleted(name: String, result: String)

    /// The LLM has finished its response with no pending tool calls.
    /// This is the terminal event for a single reasoning turn.
    case responseComplete(String)

    /// An error occurred during the agent loop.
    case error(AgentError)
}

extension AgentLoopEvent: CustomStringConvertible {
    public var description: String {
        switch self {
        case .token(let t):
            return "[token] \(t)"
        case .toolCallStarted(let name):
            return "[tool_start] \(name)"
        case .toolCallCompleted(let name, let result):
            return "[tool_done] \(name) -> \(result)"
        case .responseComplete(let text):
            return "[complete] \(text.prefix(80))..."
        case .error(let error):
            return "[error] \(error)"
        }
    }
}
