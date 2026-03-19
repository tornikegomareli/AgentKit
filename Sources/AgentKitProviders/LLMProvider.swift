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
/// let agent = AgentKit(provider: .openai(apiKey: key, model: .gpt5_4))
/// let agent = AgentKit(provider: .groq(apiKey: key, model: .llama3_3_70b))
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

    /// Groq (OpenAI-compatible endpoint).
    ///
    /// - Parameters:
    ///   - apiKey: Your Groq API key.
    ///   - model: A ``ModelIdentifier/Groq`` case. Defaults to `.llama3_3_70b`.
    case groq(apiKey: String, model: ModelIdentifier.Groq = .default)

    /// Ollama local models.
    ///
    /// - Parameters:
    ///   - model: A ``ModelIdentifier/Ollama`` case. Defaults to `.llama3_3`.
    ///   - host: Server URL. Defaults to http://localhost:11434.
    case ollama(model: ModelIdentifier.Ollama = .default, host: String = "http://localhost:11434")

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
    case groqCustom(apiKey: String, modelId: String)
    case ollamaCustom(modelId: String, host: String = "http://localhost:11434")

    /// Create a concrete ``LLMAdapter`` from this provider configuration.
    public func adapter() -> any LLMAdapter {
        switch self {
        case .claude(let apiKey, let model):
            return ClaudeAdapter(apiKey: apiKey, model: model.rawValue)

        case .openai(let apiKey, let model):
            return OpenAIAdapter(apiKey: apiKey, model: model.rawValue)

        case .groq(let apiKey, let model):
            return OpenAIAdapter(
                apiKey: apiKey,
                model: model.rawValue,
                host: "api.groq.com"
            )

        case .ollama(let model, let host):
            return OllamaAdapter(model: model.rawValue, host: host)

        case .custom(let adapter):
            return adapter

        case .claudeCustom(let apiKey, let modelId):
            return ClaudeAdapter(apiKey: apiKey, model: modelId)

        case .openaiCustom(let apiKey, let modelId):
            return OpenAIAdapter(apiKey: apiKey, model: modelId)

        case .groqCustom(let apiKey, let modelId):
            return OpenAIAdapter(apiKey: apiKey, model: modelId, host: "api.groq.com")

        case .ollamaCustom(let modelId, let host):
            return OllamaAdapter(model: modelId, host: host)
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
