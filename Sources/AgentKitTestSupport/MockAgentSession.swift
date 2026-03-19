import Foundation
import AgentKitCore

/// A mock agent session that replays a pre-defined event sequence.
///
/// Use this in UI tests to drive ``AgentChatView`` or custom views
/// without a real LLM or agent loop.
///
/// ## Example
/// ```swift
/// let mockSession = MockAgentSession(
///     scriptedEvents: [
///         .token("Hello"),
///         .token(" world"),
///         .responseComplete("Hello world")
///     ]
/// )
/// ```
public final class MockAgentSession: @unchecked Sendable {
    /// The events this mock will replay when ``send(_:)`` is called.
    public var scriptedEvents: [AgentLoopEvent]

    /// All messages sent to this mock, for assertion.
    public private(set) var sentMessages: [String] = []

    /// Simulated conversation history.
    public private(set) var messages: [AgentMessage] = []

    /// Whether a "request" is in progress.
    public private(set) var isProcessing: Bool = false

    public init(scriptedEvents: [AgentLoopEvent] = []) {
        self.scriptedEvents = scriptedEvents
    }

    /// "Send" a message — records it and replays scripted events.
    public func send(_ text: String) -> AsyncStream<AgentLoopEvent> {
        sentMessages.append(text)
        messages.append(.user(text))
        isProcessing = true

        let events = scriptedEvents
        return AsyncStream { continuation in
            for event in events {
                continuation.yield(event)
                // Update messages based on event
                switch event {
                case .responseComplete(let response):
                    self.messages.append(.assistant(response))
                default:
                    break
                }
            }
            self.isProcessing = false
            continuation.finish()
        }
    }

    /// Reset to initial state.
    public func reset() {
        sentMessages.removeAll()
        messages.removeAll()
        isProcessing = false
    }
}
