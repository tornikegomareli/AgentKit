import Foundation
import os.log

/// The main entry point for AgentKit.
///
/// Initialize with an LLM adapter, register tools, optionally set a state provider,
/// and start a session. That's it.
///
/// ## Minimal Integration (10 lines)
/// ```swift
/// let agent = AgentKit(adapter: myAdapter)
/// await agent.tools.register("ping") { _ in "pong" }
/// let session = agent.startSession()
/// ```
///
/// ## With State Provider
/// ```swift
/// let agent = AgentKit(adapter: myAdapter, configuration: .init(maxIterations: 15))
/// agent.state.setProvider(myStateProvider)
/// await agent.tools.register(name: "search", description: "Search products", parameters: [...]) { params in
///     return await catalog.search(params)
/// }
/// let session = agent.startSession()
/// ```
public final class AgentKit: Sendable {
    /// The tool registry. Register tools here before starting a session.
    public let tools: ToolRegistry

    /// The state manager. Set a provider to give the agent app context.
    public let state: StateManager

    /// Configuration for the agent loop.
    public let configuration: Configuration

    private let adapter: any LLMAdapter
    private let fallbackAdapter: (any LLMAdapter)?
    private let logger = Logger(subsystem: "com.agentkit", category: "AgentKit")

    /// Initialize AgentKit with an LLM adapter.
    ///
    /// - Parameters:
    ///   - adapter: The LLM adapter to use for all requests.
    ///   - fallbackAdapter: Optional offline fallback adapter used when the primary
    ///     adapter fails with a network error.
    ///   - configuration: Loop and runtime configuration. Uses defaults if omitted.
    public init(
        adapter: any LLMAdapter,
        fallbackAdapter: (any LLMAdapter)? = nil,
        configuration: Configuration = .default
    ) {
        self.adapter = adapter
        self.fallbackAdapter = fallbackAdapter
        self.configuration = configuration
        self.tools = ToolRegistry()
        self.state = StateManager()

        if configuration.loggingEnabled {
            logger.info("AgentKit initialized")
        }
    }

    /// Start a new conversation session.
    ///
    /// Each session maintains its own conversation history.
    /// Create multiple sessions for independent conversations.
    ///
    /// - Returns: An ``AgentSession`` (iOS 17+) that you can send messages to.
    @available(iOS 17.0, macOS 14.0, *)
    public func startSession() -> AgentSession {
        let gate = ToolConfirmationGate()
        let runner = AgentLoopRunner(
            adapter: adapter,
            fallbackAdapter: fallbackAdapter,
            toolRegistry: tools,
            stateManager: state,
            configuration: configuration,
            confirmationGate: gate
        )
        return AgentSession(loopRunner: runner, confirmationGate: gate)
    }

    /// Start a new conversation session for iOS 16.
    ///
    /// Uses ``AgentSessionLegacy`` which does not require @Observable.
    public func startLegacySession() -> AgentSessionLegacy {
        let gate = ToolConfirmationGate()
        let runner = AgentLoopRunner(
            adapter: adapter,
            fallbackAdapter: fallbackAdapter,
            toolRegistry: tools,
            stateManager: state,
            configuration: configuration,
            confirmationGate: gate
        )
        return AgentSessionLegacy(loopRunner: runner, confirmationGate: gate)
    }
}
