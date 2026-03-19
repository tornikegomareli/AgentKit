# AgentKit — Design Reference

> **AgentKit** is a Swift library that lets any iOS app — new or legacy — integrate agentic capabilities with minimal effort. Developers register tools, pick an LLM, and optionally drop in a UI. AgentKit handles the rest.

## Design Principles

- **Minimal integration surface** — one decision: which LLM to use
- **Zero framework lock-in** — swap LLMs, swap UI, eject at any time
- **Modular by default** — import only what you need
- **No magic** — behaviour is predictable, inspectable, testable
- **Swift-idiomatic** — async/await, actors, structured concurrency throughout

## The 10-Line Integration

```swift
import AgentKitCore
import AgentKitProviders
import AgentKitChat

let agent = AgentKit(adapter: claudeAdapter)

await agent.tools.register("getOrderStatus") { params in
    return await orderService.status(id: params["orderId"] as! String)
}

// In your SwiftUI view:
AgentChatView(session: agent.startSession())
```

## Core Abstractions

### AgentTool
A callable tool with name, description, typed parameters, and a `@Sendable` async handler. The description is sent to the LLM — write it like a function docstring for a colleague.

### LLMAdapter (protocol)
The contract every LLM provider implements. Takes messages + tools + context, returns `AsyncThrowingStream<AgentLoopEvent, Error>`. Adapters wrap real SDKs (SwiftAnthropic, MacPaw/OpenAI, etc.) and normalize responses.

### AgentLoopRunner (actor)
The core reasoning loop. Assembles context, calls the LLM, executes tool calls, and iterates until the LLM returns a final response. Bounded by max iterations (default 10). Supports cancellation and offline fallback.

### ToolRegistry (actor)
Thread-safe store for registered tools. Handles registration, execution, and introspection. The agent loop queries it before each LLM call.

### StateManager (actor)
Manages pull (agent asks for state) and push (app notifies agent) context delivery. Pull always happens; push is optional.

### AgentSession (@Observable)
The conversation session. Maintains message history, exposes an event stream, and drives UI updates. Lives in Core — not Chat — so headless users never import SwiftUI.

### AgentLoopEvent
The event stream type. Cases: `.token`, `.toolCallStarted`, `.toolCallCompleted`, `.responseComplete`, `.error`. Any UI — custom or AgentKitChat — consumes this.

## LLM Provider Strategy

| Provider | Swift SDK | Adapter |
|---|---|---|
| Claude (Anthropic) | SwiftAnthropic (jamesrochabrun) | ClaudeAdapter |
| OpenAI | MacPaw/OpenAI | OpenAIAdapter |
| Gemini | Firebase AI Logic SDK | GeminiAdapter |
| Apple on-device | FoundationModels (iOS 26+) | AppleAdapter |
| Ollama / local | URLSession (no SDK) | OllamaAdapter |
| Groq | OpenAI-compatible | Reuses OpenAIAdapter |

## Context Window Management

| Provider | Limit | Strategy |
|---|---|---|
| Claude Sonnet | 200k | Minimal compression |
| GPT-4o | 128k | Minimal compression |
| Gemini Flash | 1M | None needed |
| Apple on-device | 4096 | Aggressive — last 3 turns + slim context |
| Ollama | varies | Moderate compression |

## Testing Strategy

- **Unit tests** — all using MockLLMAdapter, no network
- **Adapter tests** — schema translation, stream normalization, mocked responses
- **Integration tests** — opt-in, one live round-trip per provider
- **UI tests** — MockAgentSession drives AgentChatView

## Development Phases

| Phase | Focus | Status |
|---|---|---|
| Phase 1 | Core types, agent loop, tool registry, state, session, mocks, tests | Complete |
| Phase 2 | All 5 LLM adapters, schema translation, provider tests | Planned |
| Phase 3 | AgentKitChat UI, MCP bundles, DevTools | Planned |
| Phase 4 | DocC docs, example apps, README, CHANGELOG, polish | Planned |
