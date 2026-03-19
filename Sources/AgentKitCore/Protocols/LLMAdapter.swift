import Foundation

/// The contract every LLM provider must implement.
///
/// Adapters translate between AgentKit's universal types and provider-specific
/// APIs. Each adapter wraps a real SDK (SwiftAnthropic, MacPaw/OpenAI, etc.)
/// and normalizes the response into an ``AgentLoopEvent`` stream.
///
/// App developers never interact with this protocol directly — they choose
/// a provider via ``LLMProvider`` and AgentKit handles the rest.
///
/// ## Adapter Responsibilities
/// 1. Translate ``AgentTool`` to the provider's native tool/function schema
/// 2. Send messages to the provider and stream the response
/// 3. Normalize the provider's streaming format into ``AgentLoopEvent``
/// 4. Map all provider-specific errors to ``AgentError``
public protocol LLMAdapter: Sendable {
    /// Send a conversation to the LLM and receive a stream of events.
    ///
    /// - Parameters:
    ///   - messages: The conversation history.
    ///   - tools: The tools available for the LLM to call.
    ///   - context: The current app state snapshot.
    /// - Returns: An async stream of events representing the LLM's response.
    func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error>
}
