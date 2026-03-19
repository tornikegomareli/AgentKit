import Foundation

/// A snapshot of the app's current state, provided to the agent before each reasoning step.
///
/// The agent uses this context to understand what screen the user is on,
/// what properties are relevant, and any custom state your app wants to expose.
/// Keep snapshots lightweight — they are serialized into the LLM prompt on every turn.
public struct AgentContext: Sendable {
    /// The system prompt that defines the agent's personality, role, and constraints.
    /// This is the primary way developers configure agent behavior.
    /// Passed as the system/instruction message to the LLM on every turn.
    public var systemPrompt: String?

    /// The name or identifier of the screen the user is currently viewing.
    /// Helps the agent understand what actions are contextually relevant.
    public var currentScreen: String?

    /// Properties about the current user (e.g. name, subscription tier, locale).
    /// Injected into the system prompt so the agent can personalize responses.
    public var userProperties: SendableDictionary

    /// Arbitrary app state the agent should be aware of.
    /// Use this for domain-specific context (e.g. current cart contents, selected filters).
    public var customState: SendableDictionary

    public init(
        systemPrompt: String? = nil,
        currentScreen: String? = nil,
        userProperties: SendableDictionary = [:],
        customState: SendableDictionary = [:]
    ) {
        self.systemPrompt = systemPrompt
        self.currentScreen = currentScreen
        self.userProperties = userProperties
        self.customState = customState
    }
}
