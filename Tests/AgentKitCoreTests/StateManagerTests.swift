import Testing
import Foundation
@testable import AgentKitCore
import AgentKitTestSupport

@Suite("StateManager Tests")
struct StateManagerTests {

    @Test("Pull returns default context when no provider is set")
    func testDefaultContext() async {
        let manager = StateManager()
        let context = await manager.currentContext()
        #expect(context.currentScreen == nil)
        #expect(context.userProperties.isEmpty)
        #expect(context.customState.isEmpty)
    }

    @Test("Pull returns provider snapshot")
    func testPullFromProvider() async {
        let provider = MockAgentStateProvider(
            context: AgentContext(
                currentScreen: "settings",
                userProperties: SendableDictionary(["name": "Test"]),
                customState: [:]
            )
        )

        let manager = StateManager()
        await manager.setProvider(provider)

        let context = await manager.currentContext()
        #expect(context.currentScreen == "settings")
        #expect(provider.snapshotCallCount == 1)
    }

    @Test("Push overrides pull and is consumed once")
    func testPushOverridesPull() async {
        let provider = MockAgentStateProvider(
            context: AgentContext(currentScreen: "home")
        )

        let manager = StateManager()
        await manager.setProvider(provider)

        // Push a different context
        await manager.push(AgentContext(currentScreen: "checkout"))

        // First pull should return pushed context
        let first = await manager.currentContext()
        #expect(first.currentScreen == "checkout")
        #expect(provider.snapshotCallCount == 0) // Provider NOT called

        // Second pull should fall back to provider
        let second = await manager.currentContext()
        #expect(second.currentScreen == "home")
        #expect(provider.snapshotCallCount == 1) // Provider called now
    }

    @Test("Subscribe callback pushes state")
    func testSubscribeCallback() async throws {
        let provider = MockAgentStateProvider(
            context: AgentContext(currentScreen: "home")
        )

        let manager = StateManager()
        await manager.setProvider(provider)

        // Simulate a state change via the provider's subscribe mechanism
        provider.simulateStateChange(
            AgentContext(currentScreen: "product-detail")
        )

        // Give the Task in subscribe a moment to run
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms

        // The pushed state should be available
        let context = await manager.currentContext()
        #expect(context.currentScreen == "product-detail")
    }
}
