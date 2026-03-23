import Foundation

/// Manages the pause/resume of the agent loop when a tool requires confirmation.
///
/// The gate holds a `CheckedContinuation` for each pending confirmation.
/// When the agent loop encounters a tool that requires approval, it calls
/// ``awaitDecision(for:)`` which suspends until ``resolve(id:decision:)``
/// is called by the session's `approve` or `reject` method.
///
/// This actor is shared between ``AgentLoopRunner`` and ``AgentSession``
/// to bridge the gap between the loop's execution context and the UI.
public actor ToolConfirmationGate {
    private var pending: [UUID: CheckedContinuation<ToolConfirmationDecision, Never>] = [:]

    public init() {}

    /// Suspend the caller until the user approves or rejects the tool call.
    ///
    /// - Parameter confirmation: The pending confirmation to wait on.
    /// - Returns: The user's decision.
    public func awaitDecision(for confirmation: PendingToolConfirmation) async -> ToolConfirmationDecision {
        await withCheckedContinuation { continuation in
            pending[confirmation.id] = continuation
        }
    }

    /// Resume a suspended tool call with the user's decision.
    ///
    /// - Parameters:
    ///   - id: The confirmation ID to resolve.
    ///   - decision: Whether the user approved or rejected.
    public func resolve(id: UUID, decision: ToolConfirmationDecision) {
        guard let continuation = pending.removeValue(forKey: id) else { return }
        continuation.resume(returning: decision)
    }

    /// Reject all pending confirmations. Used when a session is cancelled.
    public func cancelAll() {
        for (_, continuation) in pending {
            continuation.resume(returning: .rejected)
        }
        pending.removeAll()
    }
}
