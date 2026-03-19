import Foundation
import AgentKitCore

/// A convenience enum for selecting an LLM provider.
///
/// Use ``adapter()`` to get a concrete ``LLMAdapter`` instance.
/// This is the only type most app developers need from `AgentKitProviders`.
///
/// ## Example
/// ```swift
/// let adapter = LLMProvider.claude(apiKey: "sk-ant-...").adapter()
/// let agent = AgentKit(adapter: adapter)
/// ```
public enum LLMProvider: Sendable {
    /// Anthropic Claude models.
    /// - Parameters:
    ///   - apiKey: Your Anthropic API key.
    ///   - model: Model identifier. Defaults to claude-3.7-sonnet-latest.
    case claude(apiKey: String, model: String = "claude-3-7-sonnet-latest")

    /// OpenAI models (GPT-4o, GPT-4, etc.).
    /// - Parameters:
    ///   - apiKey: Your OpenAI API key.
    ///   - model: Model identifier. Defaults to gpt-4o.
    case openai(apiKey: String, model: String = "gpt-4o")

    /// Groq (OpenAI-compatible endpoint).
    /// - Parameters:
    ///   - apiKey: Your Groq API key.
    ///   - model: Model identifier. Defaults to llama-3.3-70b-versatile.
    case groq(apiKey: String, model: String = "llama-3.3-70b-versatile")

    /// Ollama local models.
    /// - Parameters:
    ///   - model: The Ollama model name (e.g. "llama3.1", "mistral").
    ///   - host: Server URL. Defaults to http://localhost:11434.
    case ollama(model: String, host: String = "http://localhost:11434")

    /// A custom adapter. Use this for providers not built into AgentKit,
    /// or for testing with ``MockLLMAdapter``.
    case custom(any LLMAdapter)

    /// Create a concrete ``LLMAdapter`` from this provider configuration.
    public func adapter() -> any LLMAdapter {
        switch self {
        case .claude(let apiKey, let model):
            return ClaudeAdapter(apiKey: apiKey, model: model)

        case .openai(let apiKey, let model):
            return OpenAIAdapter(apiKey: apiKey, model: model)

        case .groq(let apiKey, let model):
            return OpenAIAdapter(
                apiKey: apiKey,
                model: model,
                host: "api.groq.com"
            )

        case .ollama(let model, let host):
            return OllamaAdapter(model: model, host: host)

        case .custom(let adapter):
            return adapter
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
