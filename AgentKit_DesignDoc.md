# AgentKit
## iOS Agent Framework — Library Design Document
> v1.0 · March 2026

---

> **AgentKit** is a Swift library that lets any iOS app — new or legacy — integrate agentic AI with minimal effort. Developers register tools, pick an LLM, and drop in a UI. AgentKit handles the rest.

---

## Table of Contents

1. [Overview & Goals](#1-overview--goals)
2. [SDK Research & LLM Strategy](#2-sdk-research--llm-strategy)
3. [Module Architecture](#3-module-architecture)
4. [Core Protocols & Types](#4-core-protocols--types)
5. [LLM Provider API](#5-llm-provider-api)
6. [Tool Registry](#6-tool-registry)
7. [State Manager](#7-state-manager)
8. [Agent Loop](#8-agent-loop)
9. [MCP Bundle Layer](#9-mcp-bundle-layer)
10. [UI Kit](#10-ui-kit)
11. [Versioning Strategy](#11-versioning-strategy)
12. [Testing Strategy](#12-testing-strategy)
13. [Documentation Standards](#13-documentation-standards)
14. [Developer Experience Contract](#14-developer-experience-contract)

---

## 1. Overview & Goals

AgentKit is a modular Swift Package that gives iOS apps an agentic AI layer — a loop that can reason, call tools, observe state, and respond — with one initialization line and minimal integration work.

It is designed for two audiences: teams building new apps that want agent-first architecture, and legacy production apps that need to retrofit agentic capabilities without a rewrite.

### Design Principles

- **Minimal integration surface** — developers make one decision: which LLM to use
- **Zero framework lock-in** — swap LLMs, swap UI, eject at any time
- **Modular by default** — import only what you need
- **No magic** — behaviour is predictable, inspectable, testable
- **Swift-idiomatic** — async/await, actors, structured concurrency throughout

---

## 2. SDK Research & LLM Strategy

Before building adapters, we evaluated existing Swift SDKs for each provider to avoid re-implementing what already exists.

### Available Swift SDKs (as of March 2026)

| Provider | Swift Package | Status | Our Usage |
|---|---|---|---|
| Claude (Anthropic) | SwiftAnthropic (jamesrochabrun) | Active, unofficial | Wrap for tool calling + streaming |
| OpenAI | MacPaw/OpenAI | Active, community | Wrap chat completions + tools |
| Gemini | Firebase AI Logic SDK | Official (Google) | Wrap via FirebaseAILogic SPM |
| Apple on-device | FoundationModels (Apple) | Official (iOS 26+) | Direct — native Swift API |
| Ollama / local | REST via URLSession | No Swift SDK needed | Direct HTTP to local endpoint |
| Groq | OpenAI-compatible API | No dedicated SDK | Reuse OpenAI adapter |

> **Key insight:** Anthropic has no official Swift SDK — use SwiftAnthropic. Apple's FoundationModels is the only official first-party SDK and it's excellent. Gemini's original Swift SDK is deprecated; use FirebaseAILogic. Groq uses OpenAI-compatible endpoints so the OpenAI adapter covers it.

### LLM Initialization Contract

The developer makes exactly one choice. No routing config, no fallback chains, no capability flags.

```swift
AgentKit(llm: .claude(apiKey: "sk-ant-..."))
AgentKit(llm: .openai(apiKey: "sk-..."))
AgentKit(llm: .gemini(apiKey: "AIza..."))
AgentKit(llm: .apple)                     // no key, iOS 26+
AgentKit(llm: .ollama(model: "llama3.2")) // local
```

Optional offline fallback — still one line:

```swift
AgentKit(llm: .claude(apiKey: "..."), offlineFallback: .apple)
```

---

## 3. Module Architecture

AgentKit is a Swift Package with multiple targets. Apps import only what they need. The Core target is the only required dependency.

| Target | Import | Contents |
|---|---|---|
| AgentKitCore | `import AgentKitCore` | Agent loop, tool registry, state manager, LLM protocol. Required. |
| AgentKitProviders | `import AgentKitProviders` | All LLM adapters (Claude, OpenAI, Gemini, Apple, Ollama). Pulls in provider SDKs. |
| AgentKitMCP | `import AgentKitMCP` | MCP client + pre-built bundle connectors (Calendar, Mail, Reminders). |
| AgentKitUI | `import AgentKitUI` | SwiftUI chat view, headless session event stream. Depends on Core only. |
| AgentKitDevTools | `import AgentKitDevTools` | Tool call inspector, loop replay, token counter. Debug builds only. |
| AgentKitTestSupport | `import AgentKitTestSupport` | Mock types for use in app test suites. |

### Dependency Graph

```
AgentKitCore          ← no external dependencies
AgentKitProviders     ← Core + SwiftAnthropic + MacPaw/OpenAI + FirebaseAILogic
AgentKitMCP           ← Core
AgentKitUI            ← Core
AgentKitDevTools      ← Core
AgentKitTestSupport   ← Core
```

---

## 4. Core Protocols & Types

These types live in AgentKitCore and define the contracts every other target depends on. They are intentionally minimal.

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

Implement this to give the agent visibility into your app.

```swift
public protocol AgentStateProvider: AnyObject {
    /// Current app state snapshot — called before each reasoning step
    func snapshot() async -> AgentContext

    /// Subscribe to significant state changes.
    /// Only push events that meaningfully affect what the agent can do.
    func subscribe(onChange: @escaping (AgentContext) -> Void)
}
```

---

## 5. LLM Provider API

### LLMProvider Enum

The single type developers interact with. Every case wraps an internal adapter — they never touch adapters directly.

```swift
public enum LLMProvider {
    case claude(apiKey: String, model: ClaudeModel = .sonnet)
    case openai(apiKey: String, model: OpenAIModel = .gpt4o)
    case gemini(apiKey: String, model: GeminiModel = .flash)
    case groq(apiKey: String, model: GroqModel = .llama3)
    case apple                                // iOS 26+, no key
    case ollama(model: String, host: String = "localhost:11434")
    case custom(any LLMAdapter)               // escape hatch
}
```

### LLMAdapter Protocol (internal)

Every provider implements this. It is not public API — developers never see it.

```swift
protocol LLMAdapter {
    func respond(
        messages: [AgentMessage],
        tools: [AgentTool],
        context: AgentContext
    ) async throws -> AsyncThrowingStream<AgentLoopEvent, Error>
}
```

### AgentLoopEvent — Unified Stream

The UI layer only speaks this type. It never knows which LLM produced it.

```swift
public enum AgentLoopEvent: Sendable {
    case token(String)                        // streaming text
    case toolCallStarted(name: String)
    case toolCallCompleted(name: String, result: String)
    case responseComplete(String)
    case error(AgentError)
}
```

### Adapter Implementation Notes

- **ClaudeAdapter** — wraps SwiftAnthropic. Maps `AgentTool` to Anthropic tool schema. Streams SSE via `AsyncThrowingStream`.
- **OpenAIAdapter** — wraps MacPaw/OpenAI. Maps to function calling format. Also used for Groq (same API shape, different base URL).
- **GeminiAdapter** — wraps FirebaseAILogic. Maps to Gemini function declarations.
- **AppleAdapter** — wraps FoundationModels. Uses `@Tool` protocol and `LanguageModelSession`. Checks `#available(iOS 26, *)` and throws `.providerUnavailable` if not met.
- **OllamaAdapter** — pure URLSession to local REST endpoint. No SDK dependency. Uses OpenAI-compatible `/v1/chat/completions` format.

---

## 6. Tool Registry

The tool registry is the primary integration point. App developers register closures; AgentKit translates them to whatever schema the active LLM expects.

### Registration API

```swift
// Shorthand
agent.tools.register("createOrder") { params in
    let title = params["title"] as? String ?? ""
    return await orderService.create(title: title)
}

// With parameter schema — enables better LLM tool use
agent.tools.register(
    name: "searchProducts",
    description: "Search the product catalog",
    parameters: [
        .string("query", description: "Search term", required: true),
        .int("limit", description: "Max results", required: false)
    ]
) { params in
    return await catalog.search(params)
}
```

### Tool Schema Translation

Internally the registry maintains tools in a universal schema. Before each LLM call, the active adapter translates this to the provider-specific format. This translation is automatic and invisible.

> **Prompt-based fallback:** if the active LLM does not support native function calling (e.g. some Ollama models), AgentKit automatically falls back to injecting tool descriptions into the system prompt and parsing structured output.

---

## 7. State Manager

The state manager handles both pull (agent-initiated) and push (app-initiated) state delivery. Push is optional — apps that don't implement push still work perfectly via pull.

### Pull (default)

Before each reasoning step, the agent calls `stateProvider.snapshot()` to assemble current context. This always happens regardless of push.

### Push (optional)

Apps can push events when something significant changes — user navigates, completes a purchase, changes context. The agent uses this to interrupt or redirect its current loop.

```swift
agent.state.push(AgentContext(currentScreen: "checkout"))
```

### Context Budget

Different LLMs have different context windows. The state manager compresses context to fit — recent messages are always preserved, older history is summarised automatically. Apple's on-device model has a 4096 token limit; the state manager is especially aggressive there.

| Provider | Context Window | Strategy |
|---|---|---|
| Claude Sonnet | 200k tokens | Generous — full history in most cases |
| GPT-4o | 128k tokens | Generous |
| Gemini Flash | 1M tokens | No compression needed |
| Apple on-device | 4096 tokens | Aggressive — last 3 turns + slim context |
| Ollama (varies) | 8k–32k tokens | Moderate compression |

---

## 8. Agent Loop

The loop runs on-device. It assembles context, calls the LLM, executes tool calls, and iterates until the LLM returns a final text response with no pending tool calls.

```
User message
    │
    ▼
Assemble context (pull state + message history)
    │
    ▼
LLM call → stream events
    │
    ├── token          → yield to UI
    ├── toolCallStarted → yield to UI, execute tool
    │       │
    │       └── append toolResult to messages → loop back
    └── responseComplete → done
```

### Loop Pseudocode

```swift
func run(userMessage: String) -> AsyncThrowingStream<AgentLoopEvent, Error> {
    while iterations < maxIterations {
        let context = await stateProvider.snapshot()
        let stream = try await llm.respond(messages, tools, context)
        for await event in stream {
            switch event {
            case .token(let t):        yield .token(t)
            case .toolCallStarted:     yield .toolCallStarted(...)
            case .toolCallCompleted:
                let result = try await tools.execute(name, params)
                messages.append(.toolResult(name, result))
                yield .toolCallCompleted(name, result)
                continue   // ← loop back, feed result to LLM
            case .responseComplete:    return  // ← done
            }
        }
    }
    throw AgentError.maxIterationsExceeded
}
```

**Max iterations:** 10 by default (configurable). Prevents infinite tool call loops.

---

## 9. MCP Bundle Layer

AgentKitMCP provides pre-built connectors to Apple system APIs and a client for connecting to custom MCP servers. When enabled, their tools are automatically registered alongside app tools — the agent sees them as a single flat tool list.

### Usage

```swift
agent.mcp.enable([.calendar, .reminders, .mail])
agent.mcp.connect(url: URL(string: "https://your-backend.com/mcp")!)
```

### Built-in Bundles

| Bundle | Framework | Required Permission |
|---|---|---|
| `.calendar` | EventKit | NSCalendarsUsageDescription |
| `.reminders` | EventKit | NSRemindersUsageDescription |
| `.mail` | MessageUI | None (compose only) |
| `.contacts` | Contacts | NSContactsUsageDescription |

---

## 10. UI Kit

AgentKitUI ships two integration modes. Neither is required — apps can talk directly to the agent loop without any UI from the framework.

### Mode A — Drop-in Chat View

```swift
AgentChatView(agent: agent)
    .agentName("Aria")
    .accentColor(.blue)
    .avatarImage(Image("assistant-avatar"))
    .suggestedPrompts(["What can you help with?"])
```

Fully SwiftUI, themeable, ships with a clean production-ready default design. Tool calls appear as subtle system rows (e.g. *"Checking calendar..."*). Tokens stream into the assistant bubble in real time.

### Mode B — Headless Session

Build any UI. The session emits a stream of typed events.

```swift
let session = agent.startSession()

session.send("Book a table for 2 tomorrow")

for await event in session.events {
    switch event {
    case .token(let t):              appendToChat(t)
    case .toolCallStarted(let name): showLoader(name)
    case .toolCallCompleted:         hideLoader()
    case .responseComplete:          finalise()
    case .error(let e):              showError(e)
    }
}
```

`AgentSession` is `@Observable` (iOS 17+). Works with any UI — voice, command palette, floating button, custom chat.

---

## 11. Versioning Strategy

AgentKit follows Semantic Versioning 2.0.

| Bump | When | Examples |
|---|---|---|
| **MAJOR** (x.0.0) | Breaking public API changes | Rename `LLMProvider` cases, remove `AgentTool` params, change `AgentLoopEvent` shape |
| **MINOR** (0.x.0) | New features, new providers | Add new `LLMProvider` case, new MCP bundle, new UI customisation option |
| **PATCH** (0.0.x) | Bug fixes, provider SDK updates | Update SwiftAnthropic version, fix streaming edge case |

### Provider SDK Pinning

All third-party provider SDKs are pinned with `.upToNextMajor` in Package.swift. When a provider SDK ships a major version, AgentKit evaluates the migration and ships a corresponding MINOR or MAJOR update with migration notes in CHANGELOG.md.

### Pre-release Tags

Use `-alpha`, `-beta`, and `-rc` suffixes during development cycles (e.g. `1.0.0-beta.1`). No stability guarantees on pre-release tags.

---

## 12. Testing Strategy

Testing is split across four layers. All non-integration tests run in CI on every PR. Integration tests are opt-in and require API keys in environment variables.

### Unit Tests — AgentKitCoreTests

All using `MockLLMAdapter`, no network.

- `testToolRegistrationAndExecution` — register tool, run loop, verify tool is called and result fed back
- `testLoopTermination` — verify loop stops when LLM returns no tool calls
- `testMaxIterationGuard` — verify loop stops at max iterations
- `testContextBudget` — large message history is trimmed correctly before LLM call
- `testOfflineFallback` — primary adapter throws `.networkUnavailable`, fallback is used

### Adapter Tests — AgentKitProviderTests

Schema translation and stream normalisation, no live network.

- `testClaudeToolSchema` — known `AgentTool` → assert Anthropic JSON schema
- `testOpenAIToolSchema` — known `AgentTool` → assert OpenAI function schema
- `testGeminiToolSchema` — known `AgentTool` → assert Gemini function declaration
- `testStreamNormalization` — mock each provider's streaming format → verify `AgentLoopEvent` sequence
- `testAppleAdapterAvailabilityGate` — verify `.providerUnavailable` on unsupported OS

### Integration Tests (opt-in)

```bash
swift test --filter IntegrationTests
```

One live test per provider: init agent, register one tool, send one message, verify tool is called. Requires `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `GEMINI_API_KEY` in environment. Runs on `main` branch in CI only.

### UI Tests — AgentKitUITests

- `AgentChatView` renders with `MockAgentSession`
- Headless session events arrive in correct order
- No LLM calls — all driven by `MockAgentSession`

### AgentKitTestSupport (public)

`MockLLMAdapter`, `MockAgentStateProvider`, and `MockAgentSession` are **public types** shipped in a separate target so app developers can use them in their own test suites.

---

## 13. Documentation Standards

We document intent and non-obvious behaviour. We never comment the obvious.

### What Gets Documented

- Every public protocol, struct, enum, and function — DocC comment explaining **why** it exists and what its contract is
- Non-obvious parameter constraints (e.g. why `description` matters for tool calling accuracy)
- Behaviour differences between providers
- Error conditions and what the developer should do
- Thread safety and actor isolation where relevant

### What Does Not Get a Comment

- Property names that explain themselves (`var name: String`)
- Enum cases where the name is self-documenting (`.claude`, `.openai`, `.apple`)
- Trivial getters and setters

### DocC

All documentation is written in DocC format. A DocC catalog lives in each target. We ship an Articles section per target covering the integration walkthrough, and a Reference section auto-generated from inline docs.

```swift
/// Registers a callable tool with the agent.
///
/// The `description` is passed directly to the LLM — write it as you would
/// write a function docstring for a colleague. Vague descriptions lead to
/// the agent calling tools at the wrong time or with wrong parameters.
///
/// - Parameters:
///   - name: Unique tool identifier. Used as the function name in LLM tool schemas.
///   - description: Plain-English description of what the tool does and when to use it.
///   - parameters: Typed parameter definitions. Omit for zero-parameter tools.
///   - handler: Async closure executed when the agent calls this tool.
public func register(
    name: String,
    description: String,
    parameters: [ToolParameter] = [],
    handler: @escaping ([String: Any]) async throws -> Any
)
```

---

## 14. Developer Experience Contract

This is the bar every API decision is evaluated against.

> **The minimum viable integration is: init with one LLM, register one tool, show AgentChatView. Total new code: ~10 lines.**

### Invariants

- Changing LLM providers requires changing exactly **one argument**
- Adding a tool requires exactly **one `agent.tools.register` call**
- No framework type requires subclassing
- Nothing in Core imports UIKit or SwiftUI — it is testable in command-line targets
- AgentKit never stores API keys beyond the session — key management is the app's responsibility
- All public async functions support Swift structured concurrency and task cancellation

### The Full Integration (10 lines)

```swift
import AgentKitCore
import AgentKitProviders
import AgentKitUI

let agent = AgentKit(llm: .claude(apiKey: ProcessInfo.processInfo.environment["ANTHROPIC_API_KEY"]!))

agent.tools.register("getOrderStatus") { params in
    return await orderService.status(id: params["orderId"] as! String)
}

// In your SwiftUI view:
AgentChatView(agent: agent)
```

---

*AgentKit · Design Document · v1.0 · March 2026*
