# AgentKit

**Give any iOS or macOS app an AI agent in 10 lines of Swift.**

AgentKit is a modular Swift Package that adds an agentic layer to your app — a loop that can reason, call tools, observe state, and respond. It wraps multiple LLM providers behind a single protocol and ships a drop-in chat UI.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2016%2B%20%7C%20macOS%2013%2B-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Why AgentKit?

- **10 lines to a working agent** — register tools, pick an LLM, drop in a chat view
- **Zero lock-in** — swap Claude for GPT-4o for Gemini for on-device Apple models. Same code.
- **Modular** — import only what you need. Headless? Skip the UI. Custom UI? Skip the chat view.
- **Swift-native** — async/await, actors, structured concurrency. No Combine, no callbacks.
- **Testable** — every component has a mock. No network calls in tests.

## Quick Start

### 1. Add the package

```swift
// Package.swift
dependencies: [
    .package(url: "https://github.com/tornikegomareli/AgentKit.git", from: "0.1.0")
]
```

Or in Xcode: File > Add Package Dependencies > paste the URL.

### 2. Drop-in chat (10 lines)

```swift
import AgentKitCore
import AgentKitProviders
import AgentKitChat

// 1. Create the agent
let agent = AgentKit(provider: .claude(apiKey: "sk-ant-..."))

// 2. Register a tool
await agent.tools.register(
    name: "getOrderStatus",
    description: "Look up an order by ID",
    parameters: [.string("orderId", description: "The order ID", required: true)]
) { params in
    let id = params["orderId"] as? String ?? ""
    return await OrderService.status(for: id)
}

// 3. Show the chat
AgentChatView(session: agent.startSession())
    .agentName("Aria")
    .agentAccentColor(.purple)
    .suggestedPrompts(["Track my order", "Help me find a product"])
```

### 3. Headless mode (no UI import)

```swift
import AgentKitCore
import AgentKitProviders

let agent = AgentKit(provider: .openai(apiKey: "sk-..."))
let session = agent.startSession()
session.send("What's the weather?")

for await event in session.events {
    switch event {
    case .token(let t):          print(t, terminator: "")
    case .toolCallStarted(let n): print("\n[calling \(n)...]")
    case .toolCallCompleted:      print("[done]")
    case .responseComplete(let r): print("\n\(r)")
    case .error(let e):           print("Error: \(e)")
    }
}
```

## Supported Providers

| Provider | Enum | Model Default |
|---|---|---|
| **Claude** (Anthropic) | `.claude(apiKey:)` | claude-3.7-sonnet-latest |
| **GPT-4o** (OpenAI) | `.openai(apiKey:)` | gpt-4o |
| **Groq** | `.groq(apiKey:)` | llama-3.3-70b-versatile |
| **Ollama** (local) | `.ollama(model:)` | — |
| **Custom** | `.custom(adapter)` | — |

Switch providers with one line. Your tools, state, and conversation history stay the same.

```swift
// Cloud
let agent = AgentKit(provider: .claude(apiKey: key))

// Local
let agent = AgentKit(provider: .ollama(model: "llama3.1"))

// With offline fallback
let agent = AgentKit(
    provider: .claude(apiKey: key),
    fallbackProvider: .ollama(model: "llama3.1")
)
```

## Module Structure

Import only what you need:

| Module | Import | What you get |
|---|---|---|
| **AgentKitCore** | `import AgentKitCore` | Agent loop, tool registry, state, session, protocols. Zero dependencies. |
| **AgentKitProviders** | `import AgentKitProviders` | Claude, OpenAI, Groq, Ollama adapters + `LLMProvider` enum. |
| **AgentKitChat** | `import AgentKitChat` | Drop-in `AgentChatView` + theming modifiers. |
| **AgentKitMCP** | `import AgentKitMCP` | MCP bundle system for exposing system APIs as tools. |
| **AgentKitDevTools** | `import AgentKitDevTools` | Token counter, event recorder for debugging. |
| **AgentKitTestSupport** | `import AgentKitTestSupport` | `MockLLMAdapter`, `MockAgentStateProvider`, `MockAgentSession`. |

## Tools

Tools are functions your agent can call. Define them with a name, description, parameters, and a handler:

```swift
await agent.tools.register(
    name: "searchProducts",
    description: "Search the product catalog by keyword",
    parameters: [
        .string("query", description: "Search term", required: true),
        .int("limit", description: "Max results to return", required: false)
    ]
) { params in
    let query = params["query"] as? String ?? ""
    let limit = params["limit"] as? Int ?? 10
    return await catalog.search(query, limit: limit)
}
```

The description is passed directly to the LLM. Write it like a docstring for a colleague — quality matters.

## App State

Give the agent context about your app:

```swift
class MyStateProvider: AgentStateProvider {
    func snapshot() async -> AgentContext {
        AgentContext(
            currentScreen: "product-detail",
            userProperties: ["tier": "premium"],
            customState: ["productId": "SKU-123"]
        )
    }

    func subscribe(onChange: @escaping @Sendable (AgentContext) -> Void) {
        // Push when something significant changes
    }
}

agent.state.setProvider(MyStateProvider())
```

## Theming the Chat View

```swift
AgentChatView(session: session)
    .agentName("Aria")
    .agentAccentColor(.purple)
    .agentAvatar("aria-avatar")  // from asset catalog
    .suggestedPrompts(["What can you do?", "Track my order"])
    .inputPlaceholder("Ask Aria...")
    .showToolCalls(false)        // hide tool call details
```

## Testing

All tests use mocks — no network calls, no API keys:

```swift
import AgentKitTestSupport

let mock = MockLLMAdapter()
mock.responses = [
    .toolCall(name: "getWeather", params: #"{"city":"SF"}"#),
    .text("It's sunny in SF!")
]

let agent = AgentKit(adapter: mock)
// ... test your tool integration
```

Run the test suite:

```bash
swift test                                    # All 48 tests
swift test --filter AgentKitCoreTests         # Core only
swift test --filter AgentKitProviderTests     # Provider adapters
swift test --filter AgentKitChatTests         # Chat UI
```

## Architecture

```
AgentKitCore            (zero external dependencies)
    |
    +-- AgentKitProviders   (Core + SwiftAnthropic + MacPaw/OpenAI)
    +-- AgentKitChat        (Core + SwiftUI)
    +-- AgentKitMCP         (Core only)
    +-- AgentKitDevTools    (Core only)
    +-- AgentKitTestSupport (Core only)
```

Key design decisions:

- **`AgentSession` lives in Core**, not Chat — headless users never import SwiftUI
- **`ToolRegistry` and `StateManager` are actors** — thread-safe by construction
- **`LLMAdapter` is a public protocol** — implement your own for any provider
- **AgentKitChat is optional** — build any UI you want on top of the event stream

## Requirements

- Swift 5.9+
- iOS 16+ / macOS 13+
- iOS 17+ / macOS 14+ for `AgentChatView` (uses `@Observable`)

## License

MIT. See [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome. Please:

1. Fork the repo
2. Create a feature branch
3. Ensure `swift build` produces zero warnings
4. Ensure `swift test` passes all tests
5. Open a PR with a clear description

---

Built with Swift, async/await, and actors. No Combine. No callbacks. No magic.
