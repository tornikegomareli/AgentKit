# AgentKit

**Give any iOS or macOS app an AI agent in few lines of Swift.**

AgentKit is a modular Swift Package that adds an agentic layer to your app, a loop that can reason, call tools, observe state, and respond. It wraps multiple LLM providers behind a single protocol and ships a drop-in agentic UI with built-in tool confirmation flows.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS%2017%2B%20%7C%20macOS%2014%2B-blue.svg)](https://developer.apple.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Quick Start

### 1. Add the package

```swift
dependencies: [
    .package(url: "https://github.com/tornikegomareli/AgentKit.git", from: "0.1.0")
]
```

Or in Xcode: **File > Add Package Dependencies** > paste the URL.

### 2. Drop-in chat

```swift
import AgentKitCore
import AgentKitProviders
import AgentKitChat

let agent = AgentKit(
    provider: .openai(apiKey: "sk-..."),
    configuration: .init(systemPrompt: "You are Aria, a friendly shopping assistant. Be concise.")
)

await agent.tools.register(
    name: "getOrderStatus",
    description: "Look up an order by ID",
    parameters: [.string("orderId", description: "The order ID", required: true)]
) { params in
    let id = params.string("orderId") ?? ""
    return await OrderService.status(for: id)
}

// In your SwiftUI view:
AgentChatView(session: agent.startSession())
    .agentName("Aria")
    .agentAccentColor(.purple)
    .suggestedPrompts(["Track my order", "Help me find a product"])
```

### 3. Headless mode

```swift
import AgentKitCore
import AgentKitProviders

let agent = AgentKit(provider: .claude(apiKey: "sk-ant-..."))
let session = agent.startSession()
await session.send("What's the weather in Tbilisi?")

for await event in session.events {
    switch event {
    case .token(let t):              print(t, terminator: "")
    case .toolCallStarted(let name): print("\n[calling \(name)...]")
    case .toolCallCompleted:         print("[done]")
    case .responseComplete(let r):   print("\n\(r)")
    case .error(let e):              print("Error: \(e)")
    default: break
    }
}
```

---

## System Prompt

Set the agent's personality, constraints, and instructions via `Configuration.systemPrompt`:

```swift
let agent = AgentKit(
    provider: .claude(apiKey: key),
    configuration: .init(
        systemPrompt: """
        You are Clerk, a banking assistant for Vault.
        - Always confirm before making transfers.
        - Never reveal internal account IDs.
        - Be concise and professional.
        """
    )
)
```

The system prompt is sent to the LLM on every turn. If you also use an `AgentStateProvider` that returns a `systemPrompt` in its `AgentContext`, the context's prompt takes precedence — this lets you swap prompts dynamically based on app state.

---

## Tool Registration

Tools are functions your agent can call. Define them with a name, description, typed parameters, and a handler:

```swift
await agent.tools.register(
    name: "searchProducts",
    description: "Search the product catalog by keyword",
    parameters: [
        .string("query", description: "Search term", required: true),
        .int("limit", description: "Max results to return", required: false)
    ]
) { params in
    let query = params.string("query") ?? ""
    let limit = params.int("limit") ?? 10
    return await catalog.search(query, limit: limit)
}
```

The `description` is passed directly to the LLM — write it like a docstring for a colleague. Quality matters.

**Typed accessors** on parameters reduce casting noise:

```swift
params.string("name")   // String?
params.int("count")     // Int?
params.double("amount") // Double?
params.bool("enabled")  // Bool?
```

---

## Tool Confirmation

For actions that shouldn't execute without user approval, add a confirmation policy:

```swift
/// User must tap "Approve" before the tool runs
await agent.tools.register(
    name: "deleteAccount",
    description: "Permanently delete the user's account",
    parameters: [...],
    confirmation: .required({ params in
        "Delete account \(params.string("accountId") ?? "")? This cannot be undone."
    })
) { params in
    return await accountService.delete(params.string("accountId") ?? "")
}

// Requires Face ID / Passcode before executing
await agent.tools.register(
    name: "transferFunds",
    description: "Transfer money between accounts",
    parameters: [...],
    confirmation: .biometric({ params in
        let amount = params.double("amount") ?? 0
        return "Transfer $\(String(format: "%.2f", amount))?"
    })
) { params in
    return await bank.transfer(...)
}

// No confirmation needed
await agent.tools.register(name: "getBalance", ...) { params in ... }
```

**Three tiers:**

| Policy | Behavior |
|--------|----------|
| `.none` | Execute immediately (default) |
| `.required` | Show confirmation sheet, user taps Approve |
| `.biometric` | Confirmation sheet + Face ID / Touch ID / passcode |

The confirmation sheet is built into `AgentChatView`. For headless usage, handle the event directly:

```swift
for await event in session.events {
    case .toolConfirmationRequired(let pending):
        if userApproved {
            session.approve(pending.id)
        } else {
            session.reject(pending.id)
        }
}
```

**Custom confirmation UI** — replace the default sheet with your own:

```swift
AgentChatView(session: session)
    .confirmationView { confirmation, approve, reject in
        MyBankingConfirmationView(
            action: confirmation.displayMessage ?? confirmation.toolName,
            onApprove: approve,
            onReject: reject
        )
    }
```

---

## Providers

| Provider | Enum | Default Model |
|----------|------|---------------|
| **Claude** (Anthropic) | `.claude(apiKey:)` | `.sonnet` (Claude Sonnet 4.6) |
| **OpenAI** | `.openai(apiKey:)` | `.gpt4o` (GPT-4o) |
| **Apple** (on-device) | `.apple()` | `.general` (no API key needed) |

```swift
// Claude
let agent = AgentKit(provider: .claude(apiKey: key, model: .opus))

// OpenAI
let agent = AgentKit(provider: .openai(apiKey: key, model: .gpt5_4))

// Apple on-device (iOS 26+, Local LLM)
let agent = AgentKit(provider: .apple())
```

**Offline fallback** — automatic failover when the primary provider is unreachable:

```swift
let agent = AgentKit(
    provider: .claude(apiKey: key),
    fallbackProvider: .apple()
)
```

<details>
<summary><strong>All Claude models</strong></summary>

| Case | API ID | Notes |
|------|--------|-------|
| `.opus` | `claude-opus-4-6` | Most intelligent |
| `.sonnet` | `claude-sonnet-4-6` | Best balance (default) |
| `.haiku` | `claude-haiku-4-5` | Fastest, 200k context |
| `.sonnet4_5` | `claude-sonnet-4-5` | Previous gen |
| `.opus4_5` | `claude-opus-4-5` | Previous gen |
| `.opus4_1` | `claude-opus-4-1` | Extended thinking |
| `.sonnet4` | `claude-sonnet-4-0` | Legacy |
| `.opus4` | `claude-opus-4-0` | Legacy |

</details>

<details>
<summary><strong>All OpenAI models</strong></summary>

| Case | API ID | Notes |
|------|--------|-------|
| `.gpt5_4` | `gpt-5.4` | Flagship, 1M context |
| `.gpt5_4Mini` | `gpt-5.4-mini` | Faster, 400k |
| `.gpt5_4Nano` | `gpt-5.4-nano` | Cheapest, 400k |
| `.gpt4o` | `gpt-4o` | Previous flagship (default) |
| `.gpt4oMini` | `gpt-4o-mini` | Fast and affordable |
| `.gpt4Turbo` | `gpt-4-turbo` | Legacy |

</details>

---

## App State

Give the agent real-time context about your app:

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
        // Push state changes to the agent
    }
}

await agent.state.setProvider(MyStateProvider())
```

---

## Chat View Theming

```swift
AgentChatView(session: session)
    .agentName("Clerk")
    .agentAccentColor(.blue)
    .agentAvatar("clerk-avatar")          // from asset catalog
    .suggestedPrompts(["Check balance", "Transfer funds"])
    .inputPlaceholder("Ask Clerk...")
    .showToolCalls(true)                  // show tool execution inline
    .showTypingIndicator(true)            // show typing dots
```

---

## Module Structure

Import only what you need:

| Module | What you get |
|--------|-------------|
| **AgentKitCore** | Agent loop, tool registry, state, session, protocols. Zero dependencies. |
| **AgentKitProviders** | Claude, OpenAI, Apple adapters + `LLMProvider` enum. |
| **AgentKitChat** | Drop-in `AgentChatView`, theming modifiers, confirmation sheet. |
| **AgentKitMCP** | MCP client + system API tool bundles. |
| **AgentKitDevTools** | Token counter, event recorder for debugging. |
| **AgentKitTestSupport** | `MockLLMAdapter`, `MockAgentStateProvider` for tests. |

```
AgentKitCore              (zero external dependencies)
    |
    +-- AgentKitProviders    (Core + SwiftAnthropic + MacPaw/OpenAI)
    +-- AgentKitChat         (Core + SwiftUI + LocalAuthentication)
    +-- AgentKitMCP          (Core only)
    +-- AgentKitDevTools     (Core only)
    +-- AgentKitTestSupport  (Core only)
```

---

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
let session = agent.startSession()
await session.send("What's the weather?")

// Assert tool was called, response is correct, etc.
```

```bash
swift test                               # All tests
swift test --filter AgentKitCoreTests    # Core only
swift test --filter AgentKitProviderTests # Providers
swift test --filter AgentKitChatTests    # Chat UI
```

---

## Demo Apps

The `AgentKitDemos/` Xcode project contains 5 complete demo apps showcasing different integration patterns:

| Demo | Agent | Tools | What it shows |
|------|-------|-------|---------------|
| **Vault** (Banking) | Clerk | 10 | Transfers, spending analysis, savings goals, biometric confirmation |
| **Meridian** (Docs) | Scribe | 9 | Knowledge search, freshness audit, contradiction detection |
| **Volta** (Tasks) | Forge | 9 | Kanban board, sprint health, dependency analysis |
| **Lumen** (Email) | Courier | 12 | Inbox triage, reply drafts, calendar scheduling |
| **Shopping** | ShopBot | 5 | Product search, cart, order tracking |

---

## Requirements

- Swift 5.9+
- iOS 17+ / macOS 14+
- iOS 26+ / macOS 26+ for Apple on-device models

## License

MIT. See [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome:

1. Fork the repo
2. Create a feature branch
3. `swift build` must produce zero warnings
4. `swift test` must pass all tests
5. Open a PR with a clear description

---

Built with Swift, async/await, and actors. No Combine. No callbacks. No magic.
