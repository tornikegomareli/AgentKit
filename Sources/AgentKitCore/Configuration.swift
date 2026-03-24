import Foundation

/// Configuration options for the agent loop and runtime behavior.
///
/// All values have sensible defaults. Override only what you need.
///
/// ## Example
/// ```swift
/// let agent = AgentKit(
///     provider: .claude(apiKey: "sk-ant-..."),
///     configuration: .init(
///         maxIterations: 15,
///         systemPrompt: "You are a helpful assistant."
///     )
/// )
/// ```
public struct Configuration: Sendable {
    /// Maximum number of LLM round-trips per user message.
    /// Prevents infinite tool call loops.
    /// Default: 10.
    public let maxIterations: Int

    /// System prompt prepended to every conversation.
    /// Use this to set the agent's personality, constraints, or instructions.
    /// Default: a generic helpful assistant prompt.
    public let systemPrompt: String?

    /// Whether to log agent loop events via `os.Logger`.
    /// Useful during development. Default: false.
    public let loggingEnabled: Bool

    public init(
        maxIterations: Int = 10,
        systemPrompt: String? = nil,
        loggingEnabled: Bool = false
    ) {
        precondition(maxIterations > 0, "maxIterations must be positive")
        self.maxIterations = maxIterations
        self.systemPrompt = systemPrompt
        self.loggingEnabled = loggingEnabled
    }

    /// Default configuration.
    public static let `default` = Configuration()
}
