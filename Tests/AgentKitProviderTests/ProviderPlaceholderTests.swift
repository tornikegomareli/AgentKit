import Testing
import Foundation
@testable import AgentKitProviders
@testable import AgentKitCore
import AgentKitTestSupport

// MARK: - Schema Translation Tests

@Suite("Anthropic Schema Translation")
struct AnthropicSchemaTests {

    @Test("AgentTool converts to Anthropic tool format")
    func testToolTranslation() {
        let tool = AgentTool(
            name: "getWeather",
            description: "Get current weather for a city",
            parameters: [
                .string("city", description: "City name", required: true),
                .string("unit", description: "Temperature unit", required: false)
            ]
        ) { _ in "sunny" }

        let anthropicTool = AnthropicSchema.tool(from: tool)
        // Should be a .function case
        if case .function(let name, let description, _, _) = anthropicTool {
            #expect(name == "getWeather")
            #expect(description == "Get current weather for a city")
        } else {
            Issue.record("Expected .function tool")
        }
    }

    @Test("Empty tools array returns nil")
    func testEmptyToolsReturnsNil() {
        let result = AnthropicSchema.tools(from: [])
        #expect(result == nil)
    }

    @Test("AgentMessages convert to Anthropic messages")
    func testMessageTranslation() {
        let messages: [AgentMessage] = [
            .user("Hello"),
            .assistant("Hi there"),
        ]

        let anthropicMessages = AnthropicSchema.messages(from: messages)
        #expect(anthropicMessages.count == 2)
    }

    @Test("SendableDictionary round-trips through DynamicContent")
    func testDynamicContentRoundTrip() {
        let original = SendableDictionary([
            "name": "test",
            "count": 42,
            "active": true,
        ])

        let dynamic = AnthropicSchema.dynamicContent(from: original)
        let roundTripped = AnthropicSchema.sendableDictionary(from: dynamic)

        #expect(roundTripped["name"] as? String == "test")
        #expect(roundTripped["count"] as? Int == 42)
        #expect(roundTripped["active"] as? Bool == true)
    }
}

@Suite("OpenAI Schema Translation")
struct OpenAISchemaTests {

    @Test("AgentTool converts to OpenAI ChatCompletionToolParam")
    func testToolTranslation() {
        let tool = AgentTool(
            name: "searchProducts",
            description: "Search the product catalog",
            parameters: [
                .string("query", description: "Search term", required: true),
                .int("limit", description: "Max results", required: false)
            ]
        ) { _ in "results" }

        let openAITool = OpenAISchema.tool(from: tool)
        #expect(openAITool.function.name == "searchProducts")
        #expect(openAITool.function.description == "Search the product catalog")
    }

    @Test("Empty tools array returns nil")
    func testEmptyToolsReturnsNil() {
        let result = OpenAISchema.tools(from: [])
        #expect(result == nil)
    }

    @Test("Messages include system prompt when provided")
    func testSystemPromptInMessages() {
        let messages: [AgentMessage] = [.user("Hello")]
        let openAIMessages = OpenAISchema.messages(
            from: messages,
            systemPrompt: "You are a helpful assistant."
        )

        // Should have system + user = 2 messages
        #expect(openAIMessages.count == 2)
    }

    @Test("Messages without system prompt omit it")
    func testNoSystemPrompt() {
        let messages: [AgentMessage] = [.user("Hello")]
        let openAIMessages = OpenAISchema.messages(from: messages, systemPrompt: nil)
        #expect(openAIMessages.count == 1)
    }

    @Test("parseArguments handles valid JSON")
    func testParseValidJSON() {
        let json = #"{"city":"Paris","temp":22}"#
        let dict = OpenAISchema.parseArguments(json)
        #expect(dict["city"] as? String == "Paris")
        #expect(dict["temp"] as? Int == 22)
    }

    @Test("parseArguments handles invalid JSON gracefully")
    func testParseInvalidJSON() {
        let dict = OpenAISchema.parseArguments("not json")
        #expect(dict["_raw"] as? String == "not json")
    }
}

// MARK: - LLMProvider Tests

@Suite("LLMProvider")
struct LLMProviderTests {

    @Test("Custom provider returns the given adapter")
    func testCustomProvider() {
        let mock = MockLLMAdapter()
        let provider = LLMProvider.custom(mock)
        let adapter = provider.adapter()

        // Should be the same mock instance
        #expect(adapter is MockLLMAdapter)
    }

    @Test("Claude provider creates ClaudeAdapter")
    func testClaudeProvider() {
        let provider = LLMProvider.claude(apiKey: "test-key")
        let adapter = provider.adapter()
        #expect(adapter is ClaudeAdapter)
    }

    @Test("OpenAI provider creates OpenAIAdapter")
    func testOpenAIProvider() {
        let provider = LLMProvider.openai(apiKey: "test-key")
        let adapter = provider.adapter()
        #expect(adapter is OpenAIAdapter)
    }

    @Test("Groq provider creates OpenAIAdapter with Groq host")
    func testGroqProvider() {
        let provider = LLMProvider.groq(apiKey: "test-key")
        let adapter = provider.adapter()
        #expect(adapter is OpenAIAdapter)
    }

    @Test("Ollama provider creates OllamaAdapter")
    func testOllamaProvider() {
        let provider = LLMProvider.ollama(model: .llama3_1)
        let adapter = provider.adapter()
        #expect(adapter is OllamaAdapter)
    }

    @Test("Claude with specific model uses correct ID")
    func testClaudeWithModel() {
        let provider = LLMProvider.claude(apiKey: "test", model: .opus)
        let adapter = provider.adapter()
        #expect(adapter is ClaudeAdapter)
    }

    @Test("OpenAI with specific model uses correct ID")
    func testOpenAIWithModel() {
        let provider = LLMProvider.openai(apiKey: "test", model: .gpt5_4)
        let adapter = provider.adapter()
        #expect(adapter is OpenAIAdapter)
    }

    @Test("Groq with specific model uses correct ID")
    func testGroqWithModel() {
        let provider = LLMProvider.groq(apiKey: "test", model: .gptOss120b)
        let adapter = provider.adapter()
        #expect(adapter is OpenAIAdapter)
    }

    @Test("Custom model ID string works via claudeCustom")
    func testCustomModelId() {
        let provider = LLMProvider.claudeCustom(apiKey: "test", modelId: "claude-future-model")
        let adapter = provider.adapter()
        #expect(adapter is ClaudeAdapter)
    }

    @Test("AgentKit convenience initializer works with provider enum")
    func testAgentKitConvenienceInit() {
        let mock = MockLLMAdapter()
        let agent = AgentKit(provider: .custom(mock))
        #expect(agent.configuration.maxIterations == 10) // default config
    }
}
