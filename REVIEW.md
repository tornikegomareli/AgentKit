# AgentKit Library Review

**Reviewer**: Claude (acting as a Swift/iOS developer consuming this library)
**Date**: 2026-03-24
**Scope**: Public API design, developer experience, simplicity, correctness, concerns

---

## Overall Impression

AgentKit is a well-structured library with a clean separation of concerns. The 10-line quick start is genuinely achievable. The module split (Core/Providers/Chat/MCP/DevTools/TestSupport) is smart — most iOS libraries over-bundle. The actor-based concurrency model and streaming-first design are the right calls for 2026 Swift.

That said, there are real friction points that would slow me down as a consumer. This review focuses on those.

---

## Critical Issues (Should Fix)

### 1. `SendableDictionary` is the biggest DX pain point

Every tool handler receives `SendableDictionary` and the developer writes code like this:

```swift
let query = params["query"] as? String ?? ""
let limit = params["limit"] as? Int ?? 10
```

This is:
- **Stringly-typed** — no autocomplete, no compile-time safety
- **Casting-heavy** — `as? String ?? ""` on every param
- **Error-silent** — wrong key name or wrong type silently returns the default
- **Repetitive** — every handler starts with 3-5 lines of casting boilerplate

The parameter names are defined in `[ToolParameter]` at registration but completely disconnected from what the handler receives. There's no way to validate that the handler reads the same keys it declared.

**Suggestion**: Add typed accessor helpers on `SendableDictionary`:

```swift
extension SendableDictionary {
    public func string(_ key: String) -> String? { storage[key] as? String }
    public func int(_ key: String) -> Int? { storage[key] as? Int }
    public func double(_ key: String) -> Double? { storage[key] as? Double }
    public func bool(_ key: String) -> Bool? { storage[key] as? Bool }
    // etc.
}
```

This is a small change but meaningfully reduces casting noise:
```swift
// Before
let query = params["query"] as? String ?? ""
// After
let query = params.string("query") ?? ""
```

---

### 2. `ToolConfirmationPolicy` leaks private cases into autocompletion

The enum has public cases `._required(...)` and `._biometric(...)` with underscored names:

```swift
public enum ToolConfirmationPolicy: Sendable {
    case none
    case _required((@Sendable (SendableDictionary) -> String)?)
    case _biometric((@Sendable (SendableDictionary) -> String)?)
}
```

In Xcode, a developer typing `confirmation: .` sees `._required`, `._biometric`, `.none`, `.required`, `.biometric`, `.required(_:)`, `.biometric(_:)` — **seven options** for what is conceptually three choices (none, required, biometric). The underscore-prefixed cases are implementation details that leak into the public API surface.

**Suggestion**: Use `indirect` cases or a struct-based approach. Simplest fix — hide the associated value behind static factories only:

```swift
public struct ToolConfirmationPolicy: Sendable {
    // internal storage
    let kind: Kind
    let messageBuilder: (@Sendable (SendableDictionary) -> String)?

    enum Kind { case none, required, biometric }

    public static let none = ToolConfirmationPolicy(kind: .none, messageBuilder: nil)
    public static let required = ToolConfirmationPolicy(kind: .required, messageBuilder: nil)
    public static let biometric = ToolConfirmationPolicy(kind: .biometric, messageBuilder: nil)

    public static func required(_ message: @escaping @Sendable (SendableDictionary) -> String) -> Self {
        ToolConfirmationPolicy(kind: .required, messageBuilder: message)
    }
    public static func biometric(_ message: @escaping @Sendable (SendableDictionary) -> String) -> Self {
        ToolConfirmationPolicy(kind: .biometric, messageBuilder: message)
    }
}
```

Now autocompletion shows exactly 5 clean options. No underscored cases polluting the namespace.

---

### 3. `AgentSession` is `@unchecked Sendable` but mutates state from a non-isolated `Task`

`AgentSession` is marked `@unchecked Sendable` (line 30 of AgentSession.swift) but its mutable properties (`messages`, `isProcessing`, `pendingConfirmations`, `currentTask`) are modified both from the main actor (`handleEvent` is `@MainActor`) and from the non-`@MainActor` `send()` method.

In `send()`:
```swift
public func send(_ text: String) {
    currentTask?.cancel()         // Not @MainActor
    eventContinuation?.finish()   // Not @MainActor
    messages.append(.user(text))  // Not @MainActor — data race!
    isProcessing = true           // Not @MainActor — data race!
}
```

Meanwhile `handleEvent` is `@MainActor`. This is a data race between `send()` (called from any context) and `handleEvent` (main actor only).

**Suggestion**: Either make `AgentSession` an `@MainActor` class (it's a UI-facing object, this is natural) or make `send()` `@MainActor` as well. The `send()` function modifies observable state — it should run on the main actor.

---

### 4. `AgentSessionLegacy` is a full copy-paste of `AgentSession` with subtle behavior differences

`AgentSessionLegacy` (lines 198-282 of AgentSession.swift) duplicates the entire session logic but:
- Doesn't dispatch `handleEvent` to `@MainActor`
- Doesn't set `lastError`
- Swallows errors silently (`catch { // Stream ended }`)
- Doesn't call `finish()` on the event continuation after errors
- Doesn't handle `.toolConfirmationRequired` properly (appends to `pendingConfirmations` but never clears them on reject)

This is a maintenance hazard and a source of bugs. If confirmation was added to the main session, it was partially added to legacy.

**Suggestion**: Extract the shared event-handling logic into a non-UI helper, or — more pragmatically — consider whether iOS 16 support is worth the maintenance cost in 2026. iOS 17 adoption is >95%. If you keep it, at least share the event-handling logic via a protocol default or a shared function.

---

### 5. `contextBudgetFraction` is declared but never enforced

`Configuration.contextBudgetFraction` is documented as controlling history truncation, has a precondition validating its range, and defaults to 0.8. But `AgentLoopRunner.run()` never reads it. Messages grow unbounded until the LLM rejects them with a context overflow error.

**Suggestion**: Either implement it or remove it. A dead config option is worse than no config option — it gives developers false confidence that history management is handled.

---

## Moderate Issues (Should Consider)

### 6. `ToolParameter` enum is verbose and repetitive

Every computed property (`name`, `description`, `isRequired`, `typeName`) switches over all 6 cases with identical destructuring. Adding a new parameter type (e.g., `.enum` or `.date`) requires modifying 4 switch statements.

**Suggestion**: Make it a struct:

```swift
public struct ToolParameter: Sendable {
    public let name: String
    public let description: String
    public let type: ParameterType
    public let isRequired: Bool

    public enum ParameterType: String, Sendable {
        case string, integer, boolean, object, array, number
    }

    // Keep the factory methods for ergonomic construction
    public static func string(_ name: String, description: String, required: Bool = true) -> Self { ... }
    public static func int(_ name: String, description: String, required: Bool = false) -> Self { ... }
    // etc.
}
```

Call sites look identical (`.string("query", description: "Search term", required: true)`) but the implementation is simpler and extensible.

---

### 7. No way to register tools with the result bridge pattern

Every tool handler returns `Any`, which gets `String(describing:)` on its way back to the LLM:

```swift
let result = try await tool.handler(params)
return String(describing: result) // ToolRegistry.swift:99
```

This means if my handler returns a complex struct, the LLM gets something like `MyStruct(name: "foo", count: 42)` — Swift's debug description, not JSON. Most real tools need to return structured data.

**Suggestion**: Add a `ToolResult` protocol or accept `Encodable`:

```swift
// Option A: Codable-aware
public func register<T: Encodable>(
    name: String,
    description: String,
    parameters: [ToolParameter] = [],
    handler: @escaping @Sendable (SendableDictionary) async throws -> T
)

// Option B: explicit string return (simpler)
// Just change the handler signature to return String directly
handler: @escaping @Sendable (SendableDictionary) async throws -> String
```

Option B is simpler and more honest — the result IS a string going to an LLM. Forcing `-> String` makes developers think about serialization explicitly. The current `-> Any` gives an illusion of flexibility that `String(describing:)` breaks.

---

### 8. `AgentLoopEvent.toolCallCompleted` is overloaded

The same event case is used for:
1. **LLM adapter → loop**: carries the **raw JSON params string** (`params` parameter)
2. **Loop → session/UI**: carries the **tool execution result** (`result` parameter)

Both are `toolCallCompleted(name: String, result: String)` but `result` means completely different things depending on context. In `AgentLoopRunner.swift:124`, the adapter emits `.toolCallCompleted(name, params)` where the second argument is the JSON params string. Then at line 161, the loop emits `.toolCallCompleted(name, result)` where it's the execution result.

This is confusing for anyone implementing a custom `LLMAdapter` or consuming the event stream.

**Suggestion**: Split into two events:
```swift
case toolCallRequested(name: String, arguments: String)  // From adapter
case toolCallCompleted(name: String, result: String)      // After execution
```

---

### 9. `StateManager.push()` consumes on read — surprising behavior

`currentContext()` consumes the pushed context (sets `latestPushedContext = nil`). This means:
- If the loop iterates twice (tool call → re-call LLM), only the first iteration gets the pushed context
- The second iteration falls back to the provider snapshot, which may be different
- A developer who calls `push()` expects that context to persist until the next `push()`, not vanish after one read

**Suggestion**: Don't consume on read. Let pushed context persist until replaced by a new push or provider snapshot. Or at minimum, document this clearly.

---

### 10. `startSession()` creates a new `ToolConfirmationGate` every time

Each call to `startSession()` creates a fresh `ToolConfirmationGate` (AgentKit.swift:70). This means sessions can't share confirmation state. If a developer creates a session, then creates another (e.g., different tab), pending confirmations from the first are orphaned — the gate's CheckedContinuations never resume.

This is correct isolation, but there's no cleanup. If a session is abandoned without calling `cancel()` or `reset()`, the gate's continuations leak (they never resume, so the suspended Task hangs forever).

**Suggestion**: Add a `deinit` or cleanup mechanism that rejects all pending confirmations when the session is deallocated. Since `AgentSession` is a class, you can do this in `deinit`.

---

### 11. Tool handler captures create retain cycle risk

```swift
await agent.tools.register(name: "search", ...) { params in
    return await catalog.search(params)  // captures `catalog`
}
```

Since `ToolRegistry` is an actor owned by `AgentKit`, and tools are closures stored indefinitely, anything captured by a tool handler lives for the lifetime of `AgentKit`. If `catalog` holds a reference back to the agent (common in demo apps where the service layer and agent are siblings), you get a retain cycle.

The library provides `unregister()` and `unregisterAll()` but there's no guidance or documentation about lifecycle management of captured objects.

**Suggestion**: Document this in the ToolRegistry doc comment. Consider offering `[weak catalog]` examples in the documentation. This is the kind of thing that causes hard-to-debug memory leaks in production.

---

### 12. `ModelIdentifier` exists but is disconnected from `LLMProvider`

`ModelIdentifier` is a rich enum in Core with `.claude(.opus)`, `.openAI(.gpt4o)`, etc. But `LLMProvider` takes the nested type directly:

```swift
case claude(apiKey: String, model: ModelIdentifier.Claude = .default)
```

And `ModelIdentifier` as a top-level enum (with `.claude(Claude)`, `.openAI(OpenAI)`) is never actually used by any public API. It exists as a type but has no consumer.

**Suggestion**: Either use `ModelIdentifier` as the model parameter in `LLMProvider` (`.claude(apiKey: key, model: .claude(.opus))` — too verbose) or remove the top-level `ModelIdentifier` wrapper and just keep the nested `Claude`/`OpenAI`/`Apple` enums. The current design has an unused abstraction layer.

---

## Minor Issues (Nice to Fix)

### 13. `register(_ name: String, _ handler:)` shorthand uses name as description

```swift
public func register(_ name: String, _ handler: ...) {
    register(name: name, description: name, handler: handler) // description == name
}
```

A tool named "getWeather" gets description "getWeather". This is unhelpful for the LLM — the description should explain *when and why* to use the tool. The shorthand makes it too easy to ship tools with bad descriptions.

**Suggestion**: Either require description always, or make the shorthand clearly marked as dev-only:
```swift
/// For quick prototyping only. Production tools should use the full `register(name:description:...)`.
public func register(_ name: String, _ handler: ...)
```

---

### 14. No `Equatable` or `Hashable` on `AgentMessage`

`AgentMessage` has no `Equatable` conformance. This makes testing assertions harder than they should be:

```swift
// Can't do this:
XCTAssertEqual(session.messages.last, .user("hello"))

// Have to do:
if case .user(let text) = session.messages.last {
    XCTAssertEqual(text, "hello")
}
```

**Suggestion**: Add `Equatable` conformance (at least for the simple cases). `SendableDictionary` blocks `Equatable` synthesis for `.toolCall`, but you can provide a manual implementation that compares the string description.

---

### 15. `ChatItem` mixes mutable and immutable properties

```swift
public struct ChatItem: Identifiable, Sendable {
    public let id: UUID          // immutable
    public let role: Role        // immutable
    public var content: String   // mutable
    public var toolName: String? // mutable
    public var toolResult: String? // mutable
    public var toolState: ToolState? // mutable
    public var pendingConfirmation: PendingToolConfirmation? // mutable
}
```

This is a struct stored in an array, mutated via index lookups. It works, but the mixed let/var signals that `ChatItem` is doing double duty as both an immutable data record and a mutable state container. This makes it harder to reason about what can change after creation.

**Suggestion**: Consider making all properties `let` and replacing items in the array with new instances (builder pattern). Or accept the mutability but make all stored properties `var` for consistency. The current mix is confusing.

---

### 16. No timeout on `ToolConfirmationGate.awaitDecision()`

If the user never approves or rejects, the continuation hangs forever. The Task in the agent loop is suspended indefinitely. No timeout, no expiry, no way to detect orphaned confirmations.

**Suggestion**: Add an optional timeout (e.g., configurable in `Configuration`):
```swift
public func awaitDecision(for confirmation: PendingToolConfirmation, timeout: Duration = .seconds(300)) async -> ToolConfirmationDecision
```

---

### 17. Demo code uses `.openai(apiKey: "YOUR_API_KEY_HERE")`

Every demo hardcodes a placeholder API key. A developer copy-pasting from demos into their app will ship with a broken string. This is expected for demos, but the README quick-start also doesn't mention where to put the key (Keychain? Env var? Info.plist?).

**Suggestion**: Add a one-liner in README about secure key storage. Even just: "Store API keys in the Keychain or environment — never hardcode them in source."

---

### 18. `DevToolsPlaceholder.swift` is a single file with "Placeholder" in the name

The file contains `TokenCounter` and `LoopEventRecorder` — real, useful utilities. But the filename says "placeholder" which signals "not real yet, don't depend on this." The module is advertised as providing "debug inspector, loop replay, token counter" but only the last two exist.

**Suggestion**: Rename to `DevTools.swift` or split into `TokenCounter.swift` and `LoopEventRecorder.swift`. Remove "Placeholder" — it undermines confidence.

---

## Architecture Observations (Not Issues, Just Notes)

### What's Working Well

1. **Module split** — Core has zero dependencies. Chat is optional. Providers are separate. This is exactly right.
2. **Actor usage** — ToolRegistry and StateManager as actors is the correct pattern for shared mutable state.
3. **Streaming-first** — `AsyncThrowingStream<AgentLoopEvent>` is the right primitive. No Combine dependency.
4. **Confirmation flow** — The gate pattern (suspend loop → wait for UI → resume) is elegant. Just needs the fixes above.
5. **LLMAdapter protocol** — Clean, minimal, easy to implement. Good extension point.
6. **View modifiers for Chat** — `.agentName("Aria").agentAccentColor(.purple)` is very SwiftUI-native. Nice DX.

### What Consumers Will Struggle With

1. **Understanding the event flow** — Events go through adapter → loop → session → view model → UI. That's 4 layers. A sequence diagram in docs would help.
2. **Knowing what to import** — "Do I need AgentKitProviders or just AgentKitCore?" requires reading the module table. Most will need both.
3. **Testing** — `MockLLMAdapter` is good but `MockAgentSession` is a simplified stub that doesn't match the real session interface. Testing tool confirmation flows is hard.
4. **Error recovery** — When a tool fails, the error string goes back to the LLM and the loop continues. But if the LLM itself errors, the loop stops. There's no retry, no circuit breaker, no way to handle transient failures.

---

## Priority Summary

| # | Issue | Effort | Impact |
|---|-------|--------|--------|
| 1 | SendableDictionary typed accessors | Small | High — reduces noise in every tool handler |
| 2 | ToolConfirmationPolicy struct refactor | Medium | High — cleans up public API surface |
| 3 | AgentSession data race in send() | Small | Critical — correctness bug |
| 4 | AgentSessionLegacy duplication | Medium | Medium — maintenance risk |
| 5 | contextBudgetFraction not enforced | Small (remove) / Large (implement) | Medium — dead config is misleading |
| 6 | ToolParameter → struct | Medium | Low-Medium — extensibility |
| 7 | Tool handler return type (Any → String) | Small | Medium — forces explicit serialization |
| 8 | Split toolCallCompleted event | Medium | Medium — reduces confusion for adapter authors |
| 9 | StateManager push consumption | Small | Low-Medium — surprising behavior |
| 10 | Session cleanup on dealloc | Small | Medium — prevents leaked continuations |
| 11 | Document retain cycle risk | Small | Medium — prevents production memory leaks |
| 12 | Remove unused ModelIdentifier wrapper | Small | Low — dead code |
| 13 | Shorthand register description | Small | Low |
| 14 | AgentMessage Equatable | Small | Low-Medium — better testing |
| 15 | ChatItem mutability consistency | Small | Low |
| 16 | Confirmation timeout | Medium | Low-Medium |
| 17 | API key guidance in README | Small | Low |
| 18 | Rename DevToolsPlaceholder | Trivial | Low |

---

## Recommended Fix Order

**Pass 1 (correctness)**: #3 (data race), #5 (remove or implement contextBudgetFraction), #10 (cleanup gate)
**Pass 2 (DX wins)**: #1 (typed accessors), #2 (confirmation policy struct), #7 (handler return type)
**Pass 3 (cleanup)**: #4 (legacy session), #6 (ToolParameter struct), #8 (split events), #12 (ModelIdentifier), #18 (rename placeholder)
**Pass 4 (docs)**: #11, #13, #14, #17
