import Foundation
import os.log

/// Manages the flow of app state into the agent loop.
///
/// Supports both pull (agent asks for state before each turn) and push
/// (app proactively notifies the agent of state changes). Pull always
/// happens; push is optional.
///
/// ## Pull (default)
/// Before each reasoning step, the agent calls the state provider's
/// ``AgentStateProvider/snapshot()`` to get current context.
///
/// ## Push (optional)
/// Call ``push(_:)`` when something significant changes — user navigates,
/// completes a purchase, changes context. The agent loop can use this to
/// adjust its behavior on the next iteration.
public actor StateManager {
    private let logger = Logger(subsystem: "com.agentkit", category: "StateManager")
    private var stateProvider: (any AgentStateProvider)?
    private var latestPushedContext: AgentContext?

    public init() {}

    /// Set the state provider. Call this before starting an agent session.
    public func setProvider(_ provider: any AgentStateProvider) {
        self.stateProvider = provider

        provider.subscribe { [weak self] context in
            guard let self else { return }
            Task {
                await self.push(context)
            }
        }

        logger.debug("State provider set")
    }

    /// Push a state update to the agent.
    ///
    /// Use this for significant state changes that the agent should know about
    /// immediately. The pushed context will be used on the next agent loop iteration.
    public func push(_ context: AgentContext) {
        latestPushedContext = context
        logger.debug("State pushed: screen=\(context.currentScreen ?? "nil")")
    }

    /// Pull the current state. Prefers pushed context if available (consumes it),
    /// otherwise calls the provider's snapshot.
    ///
    /// Called by the agent loop before each LLM call.
    public func currentContext() async -> AgentContext {
        if let pushed = latestPushedContext {
            latestPushedContext = nil
            return pushed
        }

        if let provider = stateProvider {
            return await provider.snapshot()
        }

        return AgentContext()
    }
}
