import Foundation

/// A type-safe model identifier for LLM providers.
///
/// Use the nested enums (``Claude``, ``OpenAI``, ``Groq``, ``Ollama``)
/// for built-in models, or ``custom(_:)`` for any model ID string.
/// Every enum case maps to the exact API model ID accepted by the provider.
///
/// ## Example
/// ```swift
/// let agent = AgentKit(provider: .claude(apiKey: key, model: .sonnet))
/// let agent = AgentKit(provider: .openai(apiKey: key, model: .gpt4o))
/// let agent = AgentKit(provider: .groq(apiKey: key, model: .llama3_3_70b))
/// ```
public enum ModelIdentifier: Sendable, Equatable, CustomStringConvertible {

    // MARK: - Anthropic Claude

    /// Anthropic Claude model identifiers.
    /// Source: https://docs.anthropic.com/en/docs/about-claude/models
    public enum Claude: String, Sendable, CaseIterable {
        // Current generation (Claude 4.6)
        /// Most intelligent model — complex reasoning, agents, coding.
        /// 1M context, 128k output.
        case opus = "claude-opus-4-6"

        /// Best speed/intelligence balance.
        /// 1M context, 64k output.
        case sonnet = "claude-sonnet-4-6"

        /// Fastest model with near-frontier intelligence.
        /// 200k context, 64k output.
        case haiku = "claude-haiku-4-5"

        // Previous generation
        /// Claude Sonnet 4.5 — previous best speed/intelligence balance.
        case sonnet4_5 = "claude-sonnet-4-5"

        /// Claude Opus 4.5 — previous most intelligent model.
        case opus4_5 = "claude-opus-4-5"

        /// Claude Opus 4.1 — extended thinking support.
        case opus4_1 = "claude-opus-4-1"

        /// Claude Sonnet 4 — previous generation sonnet.
        case sonnet4 = "claude-sonnet-4-0"

        /// Claude Opus 4 — previous generation opus.
        case opus4 = "claude-opus-4-0"

        /// The default model recommended for most use cases.
        public static var `default`: Claude { .sonnet }
    }

    // MARK: - OpenAI

    /// OpenAI model identifiers.
    /// Source: https://platform.openai.com/docs/models
    public enum OpenAI: String, Sendable, CaseIterable {
        // GPT-5.4 family (latest)
        /// Flagship model — complex reasoning, agents, coding.
        /// 1M context, 128k output.
        case gpt5_4 = "gpt-5.4"

        /// Smaller, faster, cheaper GPT-5.4 variant.
        /// 400k context, 128k output.
        case gpt5_4Mini = "gpt-5.4-mini"

        /// Cheapest GPT-5.4 variant for high-volume tasks.
        /// 400k context, 128k output.
        case gpt5_4Nano = "gpt-5.4-nano"

        // GPT-4o family (previous generation)
        /// GPT-4o — strong all-around model.
        case gpt4o = "gpt-4o"

        /// GPT-4o mini — fast and affordable.
        case gpt4oMini = "gpt-4o-mini"

        /// GPT-4 Turbo — previous generation flagship.
        case gpt4Turbo = "gpt-4-turbo"

        /// The default model recommended for most use cases.
        public static var `default`: OpenAI { .gpt4o }
    }

    // MARK: - Groq

    /// Groq model identifiers (OpenAI-compatible API).
    /// Source: https://console.groq.com/docs/models
    public enum Groq: String, Sendable, CaseIterable {
        /// Llama 3.3 70B — versatile, fast.
        /// 131k context, 32k output.
        case llama3_3_70b = "llama-3.3-70b-versatile"

        /// Llama 3.1 8B — fastest, lightweight.
        /// 131k context, 131k output.
        case llama3_1_8b = "llama-3.1-8b-instant"

        /// OpenAI GPT-OSS 120B on Groq — large open model.
        /// 131k context, 65k output.
        case gptOss120b = "openai/gpt-oss-120b"

        /// OpenAI GPT-OSS 20B on Groq — smaller open model.
        /// 131k context, 65k output.
        case gptOss20b = "openai/gpt-oss-20b"

        /// Llama 4 Scout 17B (preview).
        /// 131k context, 8k output.
        case llama4Scout = "meta-llama/llama-4-scout-17b-16e-instruct"

        /// Qwen3 32B (preview).
        /// 131k context, 40k output.
        case qwen3_32b = "qwen/qwen3-32b"

        /// The default model recommended for most use cases.
        public static var `default`: Groq { .llama3_3_70b }
    }

    // MARK: - Ollama

    /// Common Ollama model names.
    /// These are the default pull names — Ollama supports any GGUF model.
    public enum Ollama: String, Sendable, CaseIterable {
        case llama3_1 = "llama3.1"
        case llama3_2 = "llama3.2"
        case llama3_3 = "llama3.3"
        case mistral = "mistral"
        case mixtral = "mixtral"
        case codellama = "codellama"
        case phi3 = "phi3"
        case gemma2 = "gemma2"
        case qwen2_5 = "qwen2.5"
        case deepseekCoder = "deepseek-coder-v2"

        /// The default model for local Ollama usage.
        public static var `default`: Ollama { .llama3_3 }
    }

    // MARK: - Apple (on-device)

    /// Apple Foundation Models identifiers (iOS 26+, macOS 26+).
    ///
    /// Apple's on-device models don't have named model IDs — you select
    /// a use case and guardrail level. These enum cases map to those configurations.
    public enum Apple: String, Sendable, CaseIterable {
        /// General-purpose on-device model with standard content safety.
        /// ~4096 token context window. Runs fully on-device, no network needed.
        case general = "apple-on-device-general"

        /// General-purpose model with relaxed guardrails for content transformation.
        /// Use for rewriting, summarization, and creative tasks.
        case generalPermissive = "apple-on-device-general-permissive"

        /// The default Apple on-device configuration.
        public static var `default`: Apple { .general }
    }

    // MARK: - Description

    public var description: String {
        switch self {
        case .claude(let m): return m.rawValue
        case .openAI(let m): return m.rawValue
        case .groq(let m): return m.rawValue
        case .ollama(let m): return m.rawValue
        case .apple(let m): return m.rawValue
        case .custom(let id): return id
        }
    }

    /// The raw string model ID accepted by the provider's API.
    public var id: String { description }

    case claude(Claude)
    case openAI(OpenAI)
    case groq(Groq)
    case ollama(Ollama)
    case apple(Apple)
    case custom(String)
}
