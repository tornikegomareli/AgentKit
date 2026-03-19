import Testing
import Foundation
@testable import AgentKitChat
@testable import AgentKitCore
import AgentKitTestSupport

@Suite("ChatItem Tests")
struct ChatItemTests {

    @Test("ChatItem stores user role and content")
    func testUserItem() {
        let item = ChatItem(role: .user, content: "Hello")
        #expect(item.role == .user)
        #expect(item.content == "Hello")
        #expect(item.toolState == nil)
    }

    @Test("ChatItem stores assistant role")
    func testAssistantItem() {
        let item = ChatItem(role: .assistant, content: "Hi there")
        #expect(item.role == .assistant)
        #expect(item.content == "Hi there")
    }

    @Test("ChatItem stores tool call with state")
    func testToolCallItem() {
        let item = ChatItem(
            role: .toolCall,
            content: "getWeather",
            toolResult: nil,
            toolState: .running
        )
        #expect(item.role == .toolCall)
        #expect(item.toolState == .running)

        let completed = ChatItem(
            role: .toolCall,
            content: "getWeather",
            toolResult: "Sunny, 72F",
            toolState: .completed
        )
        #expect(completed.toolState == .completed)
        #expect(completed.toolResult == "Sunny, 72F")
    }

    @Test("ChatItem stores error")
    func testErrorItem() {
        let item = ChatItem(role: .error, content: "Network unavailable")
        #expect(item.role == .error)
    }

    @Test("Each ChatItem has a unique ID")
    func testUniqueIDs() {
        let a = ChatItem(role: .user, content: "a")
        let b = ChatItem(role: .user, content: "a")
        #expect(a.id != b.id)
    }
}

@Suite("ChatConfiguration Tests")
struct ChatConfigurationTests {

    @Test("Default configuration has sensible values")
    func testDefaults() {
        if #available(iOS 17.0, macOS 14.0, *) {
            let config = ChatConfiguration.default
            #expect(config.agentName == "Agent")
            #expect(config.inputPlaceholder == "Message...")
            #expect(config.suggestedPrompts.isEmpty)
            #expect(config.showTypingIndicator == true)
            #expect(config.showToolCalls == true)
            #expect(config.avatarImageName == nil)
        }
    }

    @Test("Custom configuration overrides defaults")
    func testCustomConfig() {
        if #available(iOS 17.0, macOS 14.0, *) {
            let config = ChatConfiguration(
                agentName: "Aria",
                inputPlaceholder: "Ask Aria...",
                suggestedPrompts: ["Help me", "What can you do?"],
                showToolCalls: false
            )
            #expect(config.agentName == "Aria")
            #expect(config.inputPlaceholder == "Ask Aria...")
            #expect(config.suggestedPrompts.count == 2)
            #expect(config.showToolCalls == false)
        }
    }
}

@Suite("ChatMessageViewModel Tests")
struct ChatMessageViewModelTests {

    @Test("ViewModel starts with empty items")
    func testInitialState() async {
        if #available(iOS 17.0, macOS 14.0, *) {
            let mock = MockLLMAdapter()
            mock.responses = [.text("Hello")]
            let runner = AgentLoopRunner(
                adapter: mock,
                toolRegistry: ToolRegistry(),
                stateManager: StateManager()
            )
            let session = AgentSession(loopRunner: runner)
            let vm = ChatMessageViewModel(session: session)

            #expect(vm.items.isEmpty)
            #expect(vm.isStreaming == false)
            #expect(vm.streamingText == "")
        }
    }
}
