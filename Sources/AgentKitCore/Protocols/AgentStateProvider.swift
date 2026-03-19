import Foundation

/// Implement this protocol to give the agent visibility into your app's state.
///
/// The agent calls ``snapshot()`` before each reasoning step to assemble
/// current context. This is the "pull" model — the agent asks for state
/// when it needs it.
///
/// Optionally, implement ``subscribe(onChange:)`` to push state changes
/// to the agent proactively. Push is useful when something significant
/// changes (user navigates, completes a purchase, changes context) and
/// the agent should be aware immediately.
///
/// Apps that don't implement push still work perfectly via pull.
///
/// ## Example
/// ```swift
/// class AppStateProvider: AgentStateProvider {
///     func snapshot() async -> AgentContext {
///         AgentContext(
///             currentScreen: navigationController.currentScreen,
///             userProperties: ["tier": user.subscriptionTier],
///             customState: ["cartCount": cart.items.count]
///         )
///     }
///
///     func subscribe(onChange: @escaping (AgentContext) -> Void) {
///         NotificationCenter.default.addObserver(forName: .screenChanged, ...) { _ in
///             Task { onChange(await self.snapshot()) }
///         }
///     }
/// }
/// ```
public protocol AgentStateProvider: AnyObject, Sendable {
    /// Current app state snapshot — called before each reasoning step.
    func snapshot() async -> AgentContext

    /// Subscribe to significant state changes.
    ///
    /// Only push events that meaningfully affect what the agent can do.
    /// High-frequency pushes (e.g. scroll position) will degrade performance.
    func subscribe(onChange: @escaping @Sendable (AgentContext) -> Void)
}
