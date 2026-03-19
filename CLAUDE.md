# AgentKit — Project Instructions

## What is this project

AgentKit is a modular Swift Package that gives iOS/macOS apps an agentic layer — a loop that can reason, call tools, observe state, and respond. It wraps multiple LLM providers behind a single protocol and ships a drop-in chat UI.

## Build & Test

```bash
swift build          # Build all targets, must produce zero warnings
swift test           # Run all tests, must all pass
swift test --filter AgentKitCoreTests      # Core unit tests only
swift test --filter AgentKitProviderTests  # Provider adapter tests only
swift test --filter AgentKitChatTests      # Chat UI tests only
```

## Module Structure

| Target | Path | Dependencies | Purpose |
|---|---|---|---|
| AgentKitCore | Sources/AgentKitCore | None | Agent loop, tool registry, state, session, protocols |
| AgentKitProviders | Sources/AgentKitProviders | Core + SwiftAnthropic + MacPaw/OpenAI | LLM adapters (Claude, OpenAI, Groq, Ollama) + schema translation |
| AgentKitChat | Sources/AgentKitChat | Core only | Drop-in SwiftUI chat view and theming |
| AgentKitMCP | Sources/AgentKitMCP | Core only | MCP client + system API bundles |
| AgentKitDevTools | Sources/AgentKitDevTools | Core only | Debug inspector, loop replay, token counter |
| AgentKitTestSupport | Sources/AgentKitTestSupport | Core only | Public mock types for app test suites |

## Code Rules

- No force unwraps (`!`) in library code
- No `print` — use `os.Logger`
- All public types must be `Sendable` or explicitly `@MainActor`
- Use `async/await` and `AsyncStream`/`AsyncThrowingStream` — no Combine, no callbacks
- AgentKitCore must have zero external dependencies
- Modules must compile independently — no circular imports
- Use actors for shared mutable state, not locks

## Documentation Rules

- DocC comment on every public type and function
- Document WHY and the contract, never document what the name says
- Include usage snippets for non-trivial APIs

## Testing Rules

- All core tests use MockLLMAdapter — no network calls
- Provider tests use mocked SDK responses — no live API keys in unit tests
- Integration tests are opt-in and gated behind environment variables

## Architecture Decisions

- `AgentSession` lives in Core, not Chat — headless users never import SwiftUI
- `ToolRegistry` and `StateManager` are actors for thread safety
- `LLMAdapter` protocol is public so consumers can implement `.custom()` providers
- `AgentKitChat` is a separate target from Core — UI is always optional
- `SendableDictionary` wraps `[String: Any]` for Sendable compliance
- Schema translation layers live in `AgentKitProviders/SchemaTranslation/`
- `LLMProvider` enum provides convenience `AgentKit(provider:)` initializer
- `ChatMessageViewModel` bridges `AgentSession` events to renderable `ChatItem` list
- `MCPBundle` protocol enables custom system API tool bundles
- `ChatConfiguration` is injected via SwiftUI environment for composable theming
