import Foundation
import AgentKitCore

/// A mock LLM adapter for testing.
///
/// Returns pre-scripted responses and records all calls for assertions.
/// Use this in your test suites to verify agent behavior without making
/// real LLM API calls.
///
/// ## Example
/// ```swift
/// let mock = MockLLMAdapter()
/// mock.responses = [
///     .toolCall(name: "getWeather", params: "{\"city\": \"SF\"}"),
///     .text("The weather in SF is 72°F.")
/// ]
/// let agent = AgentKit(adapter: mock)
/// ```
public final class MockLLMAdapter: LLMAdapter, @unchecked Sendable {
    /// The scripted responses the mock will return, in order.
    public var responses: [MockResponse] = []

    /// All calls received by this mock, for assertion.
    public private(set) var calls: [MockCall] = []

    /// If set, the adapter throws this error instead of returning responses.
    public var errorToThrow: Error?

    private var responseIndex = 0

    public init() {}

    public func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error> {
        calls.append(MockCall(
            messages: messages,
            toolNames: tools.map(\.name),
            context: context
        ))

        if let error = errorToThrow {
            throw error
        }

        guard responseIndex < responses.count else {
            return AsyncThrowingStream { $0.finish() }
        }

        let response = responses[responseIndex]
        responseIndex += 1

        return AsyncThrowingStream { continuation in
            switch response {
            case .text(let text):
                // Stream tokens word-by-word, then complete
                let words = text.split(separator: " ").map(String.init)
                for (i, word) in words.enumerated() {
                    let token = i == 0 ? word : " " + word
                    continuation.yield(.token(token))
                }
                continuation.yield(.responseComplete(text))
                continuation.finish()

            case .toolCall(let name, let params):
                continuation.yield(.toolCallStarted(name: name))
                continuation.yield(.toolCallCompleted(name: name, result: params))
                continuation.finish()

            case .error(let error):
                continuation.yield(.error(error))
                continuation.finish(throwing: error)

            case .events(let events):
                for event in events {
                    continuation.yield(event)
                }
                continuation.finish()
            }
        }
    }

    /// Reset the mock to its initial state.
    public func reset() {
        calls.removeAll()
        responses.removeAll()
        responseIndex = 0
        errorToThrow = nil
    }
}

// MARK: - Supporting Types

/// A scripted response for ``MockLLMAdapter``.
public enum MockResponse: Sendable {
    /// The mock returns a plain text response.
    case text(String)

    /// The mock requests a tool call.
    case toolCall(name: String, params: String)

    /// The mock emits an error.
    case error(AgentError)

    /// The mock emits a custom sequence of events.
    case events([AgentLoopEvent])
}

/// A recorded call to the mock adapter.
public struct MockCall: Sendable {
    public let messages: [AgentMessage]
    public let toolNames: [String]
    public let context: AgentContext
}
