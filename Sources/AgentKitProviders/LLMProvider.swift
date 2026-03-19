import Foundation
import AgentKitCore

// MARK: - LLM Provider placeholder
// Full adapter implementations will be added in Phase 2.

/// Placeholder to allow the package to compile.
/// Phase 2 will implement ClaudeAdapter, OpenAIAdapter, GeminiAdapter,
/// AppleAdapter, and OllamaAdapter here.
public enum LLMProviderKind {
    case claude(apiKey: String)
    case openai(apiKey: String)
    case gemini(apiKey: String)
    case apple
    case ollama(model: String, host: String = "localhost:11434")
    case custom(any LLMAdapter)
}
