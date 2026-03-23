import Foundation
import AgentKitCore

/// A convenience enum for selecting an LLM provider.
///
/// Use ``adapter()`` to get a concrete ``LLMAdapter`` instance.
/// This is the only type most app developers need from `AgentKitProviders`.
///
/// ## Example
/// ```swift
/// let agent = AgentKit(provider: .claude(apiKey: "sk-ant-..."))
/// let agent = AgentKit(provider: .claude(apiKey: key, model: .opus))
/// let agent = AgentKit(provider: .openai(apiKey: key, model: .gpt4o))
/// let agent = AgentKit(provider: .apple())
/// ```
public enum LLMProvider: Sendable {
    /// Anthropic Claude models.
    ///
    /// - Parameters:
    ///   - apiKey: Your Anthropic API key.
    ///   - model: A ``ModelIdentifier/Claude`` case. Defaults to `.sonnet` (Claude Sonnet 4.6).
    case claude(apiKey: String, model: ModelIdentifier.Claude = .default)

    /// OpenAI models.
    ///
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key.
    ///   - model: A ``ModelIdentifier/OpenAI`` case. Defaults to `.gpt4o`.
    case openai(apiKey: String, model: ModelIdentifier.OpenAI = .default)

    /// Apple on-device model via Foundation Models (iOS 26+, macOS 26+).
    ///
    /// Runs fully on-device — no API key, no network required.
    /// - Parameter model: A ``ModelIdentifier/Apple`` case. Defaults to `.general`.
    case apple(model: ModelIdentifier.Apple = .default)

    /// A custom adapter. Use this for providers not built into AgentKit,
    /// or for testing with ``MockLLMAdapter``.
    case custom(any LLMAdapter)

    /// Use a custom model ID string with a built-in provider.
    ///
    /// For models not yet in the enum (new releases, fine-tunes, etc.).
    /// ```swift
    /// .claudeCustom(apiKey: key, modelId: "claude-sonnet-5-0")
    /// ```
    case claudeCustom(apiKey: String, modelId: String)
    case openaiCustom(apiKey: String, modelId: String)

    /// Create a concrete ``LLMAdapter`` from this provider configuration.
    public func adapter() -> any LLMAdapter {
        switch self {
        case .claude(let apiKey, let model):
            return ClaudeAdapter(apiKey: apiKey, model: model.rawValue)

        case .openai(let apiKey, let model):
            return OpenAIAdapter(apiKey: apiKey, model: model.rawValue)

        case .apple(let model):
            return AppleAdapter(model: model)

        case .custom(let adapter):
            return adapter

        case .claudeCustom(let apiKey, let modelId):
            return ClaudeAdapter(apiKey: apiKey, model: modelId)

        case .openaiCustom(let apiKey, let modelId):
            return OpenAIAdapter(apiKey: apiKey, model: modelId)
        }
    }
}

// MARK: - Convenience initializer on AgentKit

extension AgentKit {
    /// Initialize AgentKit with an ``LLMProvider`` enum value.
    ///
    /// This is the recommended entry point for most apps.
    ///
    /// ```swift
    /// let agent = AgentKit(provider: .claude(apiKey: "sk-ant-..."))
    /// let agent = AgentKit(provider: .claude(apiKey: key, model: .opus))
    /// ```
    public convenience init(
        provider: LLMProvider,
        fallbackProvider: LLMProvider? = nil,
        configuration: Configuration = .default
    ) {
        self.init(
            adapter: provider.adapter(),
            fallbackAdapter: fallbackProvider?.adapter(),
            configuration: configuration
        )
    }
}
