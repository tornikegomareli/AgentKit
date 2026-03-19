import Foundation
import AgentKitCore

/// A mock state provider that returns a static ``AgentContext``.
///
/// Use this in tests to control exactly what context the agent sees.
///
/// ## Example
/// ```swift
/// let stateProvider = MockAgentStateProvider(
///     context: AgentContext(currentScreen: "checkout", customState: ["cartTotal": 42.99])
/// )
/// agent.state.setProvider(stateProvider)
/// ```
public final class MockAgentStateProvider: AgentStateProvider, @unchecked Sendable {
    /// The context that ``snapshot()`` returns.
    public var context: AgentContext

    /// Number of times ``snapshot()`` has been called.
    public private(set) var snapshotCallCount = 0

    /// The callback registered via ``subscribe(onChange:)``, if any.
    public private(set) var onChangeCallback: (@Sendable (AgentContext) -> Void)?

    public init(context: AgentContext = AgentContext()) {
        self.context = context
    }

    public func snapshot() async -> AgentContext {
        snapshotCallCount += 1
        return context
    }

    public func subscribe(onChange: @escaping @Sendable (AgentContext) -> Void) {
        onChangeCallback = onChange
    }

    /// Simulate a state change push.
    public func simulateStateChange(_ newContext: AgentContext) {
        context = newContext
        onChangeCallback?(newContext)
    }
}
