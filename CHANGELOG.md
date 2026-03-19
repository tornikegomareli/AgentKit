# Changelog

All notable changes to AgentKit will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2026-03-19

### Added

**AgentKitCore**
- `AgentKit` main entry point with adapter and configuration
- `AgentLoopRunner` actor — core reasoning loop with cancellation, offline fallback, and max iteration guard
- `AgentSession` — `@Observable` conversation session (iOS 17+) with event stream
- `AgentSessionLegacy` — non-Observable session for iOS 16
- `ToolRegistry` actor — thread-safe tool registration and execution
- `StateManager` actor — pull/push app state delivery
- `Configuration` — max iterations, context budget, system prompt, logging
- `AgentTool`, `ToolParameter`, `AgentContext`, `AgentMessage`, `AgentLoopEvent`, `AgentError`
- `SendableDictionary` — `Sendable` wrapper for `[String: Any]`
- `LLMAdapter` protocol — provider-agnostic LLM interface
- `AgentStateProvider` protocol — app state injection

**AgentKitProviders**
- `ClaudeAdapter` — Anthropic Claude via SwiftAnthropic SDK
- `OpenAIAdapter` — OpenAI GPT models via MacPaw/OpenAI SDK
- `OllamaAdapter` — local Ollama models via raw URLSession
- `LLMProvider` enum — `.claude`, `.openai`, `.groq`, `.ollama`, `.custom`
- Groq support via OpenAIAdapter with host override
- Anthropic and OpenAI schema translation layers
- `AgentKit(provider:)` convenience initializer

**AgentKitChat**
- `AgentChatView` — drop-in SwiftUI chat screen
- `ChatMessageViewModel` — `@Observable` event-to-UI bridge
- `ChatConfiguration` — theming (agent name, accent color, avatar, prompts)
- `MessageBubble`, `ToolCallRow`, `StreamingTextView`, `InputBarView`, `SuggestedPromptsView`
- View modifiers: `.agentName()`, `.agentAccentColor()`, `.agentAvatar()`, `.suggestedPrompts()`, `.showToolCalls()`, `.inputPlaceholder()`, `.showTypingIndicator()`

**AgentKitMCP**
- `MCPManager` — bundle registration and tool installation
- `MCPBundle` protocol — custom system API bundles
- `ClipboardBundle` — macOS clipboard read/write

**AgentKitDevTools**
- `TokenCounter` — heuristic token estimation
- `LoopEventRecorder` — timestamped event capture for debugging

**AgentKitTestSupport**
- `MockLLMAdapter` — scripted responses with call recording
- `MockAgentStateProvider` — static context with simulated changes
- `MockAgentSession` — event replay for UI testing

### Test Coverage
- 48 tests across 10 suites, all passing
- Zero network calls in test suite
