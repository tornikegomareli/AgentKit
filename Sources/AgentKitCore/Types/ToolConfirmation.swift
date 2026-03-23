import Foundation

/// Controls whether a tool requires user approval before execution.
///
/// Assign a confirmation policy when registering a tool to pause the agent
/// loop and wait for the user to approve or reject the action.
///
/// ## Usage
/// ```swift
/// // Trailing closure for the message builder
/// await agent.tools.register(
///     name: "transferFunds",
///     description: "Transfer money",
///     parameters: [...],
///     confirmation: .required { params in
///         "Transfer GEL \(params["amount"] as? Double ?? 0)?"
///     }
/// ) { params in ... }
///
/// // Without custom message (generic fallback)
/// confirmation: .required
///
/// // With biometric authentication
/// confirmation: .biometric { params in "Send external payment?" }
/// ```
public enum ToolConfirmationPolicy: Sendable {
    /// Execute immediately with no user interaction. This is the default.
    case none
    /// Pause and show a confirmation dialog. The user must explicitly approve.
    case _required((@Sendable (SendableDictionary) -> String)?)
    /// Pause, show a confirmation dialog, and require biometric authentication
    /// (Face ID / Touch ID / device PIN) before executing.
    case _biometric((@Sendable (SendableDictionary) -> String)?)

    /// Require user confirmation before executing this tool.
    public static var required: Self { ._required(nil) }

    /// Require user confirmation with biometric authentication.
    public static var biometric: Self { ._biometric(nil) }

    /// Require user confirmation with a custom message describing the action.
    ///
    /// - Parameter message: Closure that receives the tool parameters and returns
    ///   a human-readable description of what the tool will do.
    public static func required(_ message: @escaping @Sendable (SendableDictionary) -> String) -> Self {
        ._required(message)
    }

    /// Require biometric-authenticated confirmation with a custom message.
    ///
    /// - Parameter message: Closure that receives the tool parameters and returns
    ///   a human-readable description of what the tool will do.
    public static func biometric(_ message: @escaping @Sendable (SendableDictionary) -> String) -> Self {
        ._biometric(message)
    }

    /// Whether this policy requires any user confirmation.
    public var requiresConfirmation: Bool {
        switch self {
        case .none: return false
        case ._required, ._biometric: return true
        }
    }

    /// Whether this policy requires biometric authentication.
    public var requiresBiometric: Bool {
        switch self {
        case ._biometric: return true
        default: return false
        }
    }

    /// Build the display message for a given set of parameters, or nil if no builder was provided.
    public func buildMessage(for params: SendableDictionary) -> String? {
        switch self {
        case .none:
            return nil
        case ._required(let builder):
            return builder?(params)
        case ._biometric(let builder):
            return builder?(params)
        }
    }
}

/// A pending tool call awaiting user approval.
///
/// When a tool with a confirmation policy is called by the LLM, the agent loop
/// suspends and emits this value. The UI (or headless consumer) must call
/// ``AgentSession/approve(_:)`` or ``AgentSession/reject(_:)`` to resume.
public struct PendingToolConfirmation: Identifiable, Sendable {
    /// Unique identifier for this pending confirmation.
    public let id: UUID
    /// The name of the tool awaiting approval.
    public let toolName: String
    /// The parameters the LLM provided for this tool call.
    public let parameters: SendableDictionary
    /// A human-readable description of the action, built from the developer's message closure.
    /// Nil if no message builder was provided at registration.
    public let displayMessage: String?
    /// Whether biometric authentication is required to approve.
    public let requiresBiometric: Bool

    public init(
        id: UUID = UUID(),
        toolName: String,
        parameters: SendableDictionary,
        displayMessage: String?,
        requiresBiometric: Bool
    ) {
        self.id = id
        self.toolName = toolName
        self.parameters = parameters
        self.displayMessage = displayMessage
        self.requiresBiometric = requiresBiometric
    }
}

/// The user's decision on a pending tool confirmation.
public enum ToolConfirmationDecision: Sendable {
    case approved
    case rejected
}
