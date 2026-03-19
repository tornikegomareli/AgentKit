# AgentKit — Claude Code Build Prompt

> Paste this entire document into Claude Code as a single message.
> Attach or paste the contents of `AgentKit_DesignDoc.md` alongside it.

---

You are building **AgentKit** — a Swift Package Manager library that gives iOS apps an agentic AI layer. Read everything below carefully before writing a single line of code.

---

## 0. Before You Start

Search and read the current documentation for these Swift packages before implementing any adapter. Use the actual SDK APIs — do not re-implement HTTP calls for any provider that has a usable Swift SDK.

| Provider | Package to read |
|---|---|
| Claude | github.com/jamesrochabrun/SwiftAnthropic |
| OpenAI + Groq | github.com/MacPaw/OpenAI |
| Gemini | firebase.google.com/docs/ai-logic (FirebaseAILogic SPM target) |
| Apple on-device | developer.apple.com/documentation/FoundationModels |
| Ollama | No SDK — plain URLSession to local REST |

---

## 1. Repository Structure

```
AgentKit/
├── Package.swift
├── README.md
├── CHANGELOG.md
├── Sources/
│   ├── AgentKitCore/
│   ├── AgentKitProviders/
│   ├── AgentKitMCP/
│   ├── AgentKitUI/
│   ├── AgentKitDevTools/
│   └── AgentKitTestSupport/
└── Tests/
    ├── AgentKitCoreTests/
    ├── AgentKitProviderTests/
    └── AgentKitUITests/
```

---

## 2. Package.swift Requirements

- Swift tools version: **5.9 minimum**
- iOS deployment target: **16.0** (Apple adapter gates on iOS 26 at runtime via `#available`, not compile time)
- Declare all six targets including `AgentKitTestSupport`
- Pin `SwiftAnthropic`, `MacPaw/OpenAI`, and `firebase-ios-sdk` to current stable versions with `.upToNextMajor`
- `FoundationModels` is a system framework — import conditionally with `#available(iOS 26, *)`
- `AgentKitCore` must have **zero external dependencies**

---

## 3. AgentKitCore — Implement These Exactly

### AgentTool

```swift
public struct AgentTool {
    public let name: String
    public let description: String
    public let parameters: [ToolParameter]
    public let handler: ([String: Any]) async throws -> Any
}
```

### ToolParameter

```swift
public enum ToolParameter {
    case string(_ name: String, description: String, required: Bool = true)
    case int(_ name: String, description: String, required: Bool = false)
    case bool(_ name: String, description: String, required: Bool = false)
    case object(_ name: String, description: String, required: Bool = false)
}
```

### AgentContext

```swift
public struct AgentContext: Sendable {
    public var currentScreen: String?
    public var userProperties: [String: Any]
    public var customState: [String: Any]
    public init(
        currentScreen: String? = nil,
        userProperties: [String: Any] = [:],
        customState: [String: Any] = [:]
    )
}
```

### AgentMessage

```swift
public enum AgentMessage: Sendable {
    case user(String)
    case assistant(String)
    case toolCall(name: String, params: [String: Any])
    case toolResult(name: String, result: String)
}
```

### AgentLoopEvent

```swift
public enum AgentLoopEvent: Sendable {
    case token(String)
    case toolCallStarted(name: String)
    case toolCallCompleted(name: String, result: String)
    case responseComplete(String)
    case error(AgentError)
}
```

### AgentError

```swift
public enum AgentError: Error {
    case providerUnavailable(String)
    case toolNotFound(String)
    case toolExecutionFailed(String, Error)
    case contextWindowExceeded
    case networkUnavailable
    case unknown(Error)
}
```

### AgentStateProvider (protocol)

```swift
public protocol AgentStateProvider: AnyObject {
    /// Current app state snapshot — called before each reasoning step
    func snapshot() async -> AgentContext

    /// Subscribe to significant state changes.
    /// Only push events that meaningfully affect what the agent can do.
    func subscribe(onChange: @escaping (AgentContext) -> Void)
}
```

### LLMAdapter (internal — not public)

```swift
protocol LLMAdapter {
    func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error>
}
```

---

## 4. LLMProvider Enum (public, in AgentKitProviders)

```swift
public enum LLMProvider {
    case claude(apiKey: String, model: ClaudeModel = .sonnet)
    case openai(apiKey: String, model: OpenAIModel = .gpt4o)
    case gemini(apiKey: String, model: GeminiModel = .flash)
    case groq(apiKey: String, model: GroqModel = .llama3)
    case apple
    case ollama(model: String, host: String = "localhost:11434")
    case custom(any LLMAdapter)
}
```

### AgentKit — Main Entry Point

```swift
public final class AgentKit {
    public init(
        llm: LLMProvider,
        offlineFallback: LLMProvider? = nil
    )
    public let tools: ToolRegistry
    public let state: StateManager
    public let mcp: MCPManager       // only usable if AgentKitMCP is imported
    public func startSession() -> AgentSession
}
```

---

## 5. Adapter Rules

For each adapter, follow this checklist:

1. Use the real SDK — do not write raw HTTP unless no SDK exists (Ollama only)
2. Translate the `[AgentTool]` array to the provider's native tool/function schema
3. Translate the provider's response stream to `AsyncThrowingStream<AgentLoopEvent, Error>`
4. Map all provider-specific errors to `AgentError`
5. `AppleAdapter` must check `#available(iOS 26, *)` and throw `.providerUnavailable` if not met
6. If a provider has no native tool calling, implement **prompt-based fallback**: inject tool schemas as JSON in the system prompt, parse tool calls from response text

### Groq

Groq uses OpenAI-compatible endpoints. Reuse `OpenAIAdapter` with a different base URL — do not write a separate adapter.

---

## 6. ToolRegistry

- Backed by an **actor** for thread safety
- `register(name:description:parameters:handler:)` — full form
- `register(_ name: String, _ handler: ...)` — convenience shorthand, empty parameters
- `execute(name: String, params: [String: Any]) async throws -> String` — called by agent loop
- `schema(for provider: LLMProvider) -> [Any]` — returns provider-specific tool schema array

---

## 7. Agent Loop

- Implemented as an **actor** (`AgentLoopRunner`)
- **Max iterations: 10** (configurable via `AgentKit.Configuration`) — prevents infinite tool call loops
- Calls `stateProvider?.snapshot()` before each LLM call
- Context budget: estimate tokens, truncate oldest messages if approaching 80% of provider limit
- Yields `AgentLoopEvent` via `AsyncThrowingStream` to the caller

### Context Window Limits

| Provider | Limit | Compression strategy |
|---|---|---|
| Claude Sonnet | 200k | Minimal |
| GPT-4o | 128k | Minimal |
| Gemini Flash | 1M | None needed |
| Apple on-device | 4096 | Aggressive — last 3 turns + slim context |
| Ollama | varies | Moderate |

---

## 8. AgentKitUI

- `AgentChatView`: SwiftUI `View`, takes an `AgentSession` (via `@State` or injected)
- Messages render as bubbles; tool calls render as a subtle system row (e.g. *"Checking calendar..."*)
- Streaming: append tokens to the last assistant bubble in real time
- `AgentSession` is `@Observable` — uses the Observation framework (iOS 17+)
- Headless: `AgentSession.events` is an `AsyncStream<AgentLoopEvent>`

### AgentChatView Customisation

```swift
AgentChatView(agent: agent)
    .agentName("Aria")
    .accentColor(.blue)
    .avatarImage(Image("assistant-avatar"))
    .suggestedPrompts(["What can you help with?"])
```

---

## 9. AgentKitMCP

- `MCPManager.enable(_ bundles: [MCPBundle])` — activates built-in connectors
- `MCPManager.connect(url: URL)` — connects to a custom MCP server
- On activation, bundle tools are automatically added to the `ToolRegistry`

### Built-in Bundles

| Case | Framework | Permission key |
|---|---|---|
| `.calendar` | EventKit | NSCalendarsUsageDescription |
| `.reminders` | EventKit | NSRemindersUsageDescription |
| `.mail` | MessageUI | None (compose only) |
| `.contacts` | Contacts | NSContactsUsageDescription |

---

## 10. AgentKitTestSupport (public target)

These mock types must be **public** — app developers use them in their own test suites.

- `MockLLMAdapter` — configurable scripted responses, records all calls, injectable via `.custom()`
- `MockAgentStateProvider` — returns a static `AgentContext`
- `MockAgentSession` — replays a pre-defined `[AgentLoopEvent]` sequence

---

## 11. Tests to Write

### AgentKitCoreTests — all using MockLLMAdapter, no network

| Test | Verifies |
|---|---|
| `testToolRegistrationAndExecution` | Register tool, run loop, tool is called, result fed back to LLM |
| `testLoopTermination` | Loop stops when LLM returns no tool calls |
| `testMaxIterationGuard` | Loop stops at max iterations and throws |
| `testContextBudget` | Large message history is trimmed before LLM call |
| `testOfflineFallback` | Primary adapter throws `.networkUnavailable`, fallback is used |
| `testPromptBasedToolFallback` | Adapter with no native tool support parses tool call from text |

### AgentKitProviderTests — schema translation, no live network

| Test | Verifies |
|---|---|
| `testClaudeToolSchema` | Known `AgentTool` → correct Anthropic JSON schema |
| `testOpenAIToolSchema` | Known `AgentTool` → correct OpenAI function schema |
| `testGeminiToolSchema` | Known `AgentTool` → correct Gemini function declaration |
| `testStreamNormalization` | Mock provider stream → correct `AgentLoopEvent` sequence |
| `testAppleAdapterAvailabilityGate` | Throws `.providerUnavailable` on unsupported OS |
| `testErrorMapping` | Each provider's errors map to the correct `AgentError` case |

### AgentKitUITests

| Test | Verifies |
|---|---|
| `testChatViewRendersMessages` | `AgentChatView` renders with `MockAgentSession` |
| `testHeadlessEventOrder` | Headless session events arrive in correct sequence |
| `testStreamingTokenAppend` | Tokens append to assistant bubble in real time |

---

## 12. Documentation Rules

- DocC comment on every public type and public function
- Document **WHY** and the contract — never document what the name already says
- Include a usage snippet in DocC for every non-trivial public API
- No inline comments on obvious code

### README.md must include

1. Installation (SPM snippet)
2. 5-minute quickstart (the 10-line integration)
3. Module overview table (which target to import for what)
4. LLM provider setup — link to each provider's API key page
5. Link to DocC documentation

### CHANGELOG.md

Write the initial `0.1.0` entry documenting all included features.

---

## 13. Code Quality Rules

- No force unwraps (`!`) anywhere in library code
- No `print` statements — use `os.Logger` in Core where logging is needed
- All public types are `Sendable` or explicitly `@MainActor`
- Use `async/await` and `AsyncStream` / `AsyncThrowingStream` throughout — no Combine, no callbacks
- No third-party dependencies in `AgentKitCore`
- Modules must compile independently — no circular imports

---

## 14. Build Verification

Before considering the implementation complete:

1. `swift build` succeeds with **zero warnings** on all targets
2. `swift test` succeeds on all non-integration tests
3. The following compiles and runs correctly in a blank iOS 16+ app:

```swift
import AgentKitCore
import AgentKitProviders
import AgentKitUI

let agent = AgentKit(llm: .claude(apiKey: "test-key"))

agent.tools.register("ping") { _ in return "pong" }

struct ContentView: View {
    var body: some View {
        AgentChatView(agent: agent)
    }
}
```

---

*End of Claude Code Prompt — AgentKit v1.0*
