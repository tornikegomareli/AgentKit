import Foundation
import AgentKitCore
import os.log

/// Counts tokens approximately for debugging and budget estimation.
///
/// Uses a simple word-based heuristic (1 token ~ 0.75 words).
/// Not accurate for billing — use provider-specific tokenizers for that.
public struct TokenCounter: Sendable {
    public init() {}

    /// Estimate token count for a string.
    public func estimateTokens(_ text: String) -> Int {
        let words = text.split(separator: " ").count
        // Rough heuristic: ~1.33 tokens per word for English
        return max(1, Int(Double(words) * 1.33))
    }

    /// Estimate total tokens for a conversation.
    public func estimateTokens(messages: [AgentMessage]) -> Int {
        messages.reduce(0) { total, message in
            switch message {
            case .user(let text), .assistant(let text):
                return total + estimateTokens(text) + 4 // role overhead
            case .toolCall(let name, let params):
                return total + estimateTokens(name) + estimateTokens(params.description) + 4
            case .toolResult(let name, let result):
                return total + estimateTokens(name) + estimateTokens(result) + 4
            }
        }
    }
}

/// Records agent loop events for debugging and replay.
///
/// Captures a timeline of events that can be inspected after a session
/// to understand agent behavior, debug tool call issues, or measure performance.
public final class LoopEventRecorder: @unchecked Sendable {
    private let logger = Logger(subsystem: "com.agentkit.devtools", category: "EventRecorder")
    private var entries: [RecordedEvent] = []
    private let lock = NSLock()

    public init() {}

    /// Record an event with a timestamp.
    public func record(_ event: AgentLoopEvent) {
        lock.lock()
        defer { lock.unlock() }
        entries.append(RecordedEvent(
            timestamp: Date(),
            event: event
        ))
    }

    /// All recorded events in chronological order.
    public var events: [RecordedEvent] {
        lock.lock()
        defer { lock.unlock() }
        return entries
    }

    /// The total number of recorded events.
    public var count: Int {
        lock.lock()
        defer { lock.unlock() }
        return entries.count
    }

    /// Clear all recorded events.
    public func reset() {
        lock.lock()
        defer { lock.unlock() }
        entries.removeAll()
    }

    /// A recorded event with its timestamp.
    public struct RecordedEvent: Sendable {
        public let timestamp: Date
        public let event: AgentLoopEvent
    }
}
