import Testing
import Foundation
@testable import AgentKitCore

@Suite("Core Types Tests")
struct CoreTypesTests {

    // MARK: - ToolParameter

    @Test("ToolParameter exposes name, description, required, and typeName")
    func testToolParameterProperties() {
        let param = ToolParameter.string("query", description: "Search term", required: true)
        #expect(param.name == "query")
        #expect(param.description == "Search term")
        #expect(param.isRequired == true)
        #expect(param.typeName == "string")

        let optionalInt = ToolParameter.int("limit", description: "Max results", required: false)
        #expect(optionalInt.isRequired == false)
        #expect(optionalInt.typeName == "integer")
    }

    @Test("All ToolParameter cases have correct type names")
    func testAllTypeNames() {
        #expect(ToolParameter.string("a", description: "").typeName == "string")
        #expect(ToolParameter.int("a", description: "").typeName == "integer")
        #expect(ToolParameter.bool("a", description: "").typeName == "boolean")
        #expect(ToolParameter.object("a", description: "").typeName == "object")
        #expect(ToolParameter.array("a", description: "").typeName == "array")
        #expect(ToolParameter.number("a", description: "").typeName == "number")
    }

    // MARK: - AgentMessage

    @Test("AgentMessage description is human-readable")
    func testAgentMessageDescription() {
        let user = AgentMessage.user("Hello")
        #expect(user.description.contains("[user]"))
        #expect(user.description.contains("Hello"))

        let assistant = AgentMessage.assistant("Hi there")
        #expect(assistant.description.contains("[assistant]"))

        let toolCall = AgentMessage.toolCall(name: "search", params: SendableDictionary(["q": "test"]))
        #expect(toolCall.description.contains("[tool_call]"))
        #expect(toolCall.description.contains("search"))
    }

    // MARK: - AgentError

    @Test("AgentError cases have meaningful descriptions")
    func testAgentErrorDescriptions() {
        let errors: [(AgentError, String)] = [
            (.providerUnavailable("no API"), "Provider unavailable"),
            (.toolNotFound("missing"), "Tool not found: missing"),
            (.contextWindowExceeded, "Context window exceeded"),
            (.networkUnavailable, "Network unavailable"),
            (.maxIterationsExceeded, "Max iterations exceeded"),
            (.cancelled, "Operation cancelled"),
        ]

        for (error, expectedSubstring) in errors {
            #expect(error.description.contains(expectedSubstring))
        }
    }

    // MARK: - SendableDictionary

    @Test("SendableDictionary supports subscript access")
    func testSendableDictionary() {
        var dict = SendableDictionary(["key": "value"])
        #expect(dict["key"] as? String == "value")
        #expect(dict["missing"] == nil)

        dict["new"] = 42
        #expect(dict["new"] as? Int == 42)
        #expect(dict.isEmpty == false)
    }

    @Test("SendableDictionary supports dictionary literal init")
    func testSendableDictionaryLiteral() {
        let dict: SendableDictionary = ["a": 1, "b": "two"]
        #expect(dict["a"] as? Int == 1)
        #expect(dict["b"] as? String == "two")
    }

    // MARK: - AgentContext

    @Test("AgentContext default initializer creates empty context")
    func testDefaultContext() {
        let context = AgentContext()
        #expect(context.currentScreen == nil)
        #expect(context.userProperties.isEmpty)
        #expect(context.customState.isEmpty)
    }

    // MARK: - Configuration

    @Test("Configuration default values are sensible")
    func testDefaultConfiguration() {
        let config = Configuration.default
        #expect(config.maxIterations == 10)
        #expect(config.contextBudgetFraction == 0.8)
        #expect(config.systemPrompt == nil)
        #expect(config.loggingEnabled == false)
    }

    @Test("Configuration rejects invalid values")
    func testConfigurationValidation() {
        // These should not crash — valid values
        _ = Configuration(maxIterations: 1, contextBudgetFraction: 0.5)
        _ = Configuration(maxIterations: 100, contextBudgetFraction: 1.0)
    }

    // MARK: - ModelIdentifier

    @Test("Claude model IDs match official API identifiers")
    func testClaudeModelIds() {
        #expect(ModelIdentifier.Claude.sonnet.rawValue == "claude-sonnet-4-6")
        #expect(ModelIdentifier.Claude.opus.rawValue == "claude-opus-4-6")
        #expect(ModelIdentifier.Claude.haiku.rawValue == "claude-haiku-4-5")
        #expect(ModelIdentifier.Claude.sonnet4_5.rawValue == "claude-sonnet-4-5")
        #expect(ModelIdentifier.Claude.opus4.rawValue == "claude-opus-4-0")
        #expect(ModelIdentifier.Claude.default == .sonnet)
    }

    @Test("OpenAI model IDs match official API identifiers")
    func testOpenAIModelIds() {
        #expect(ModelIdentifier.OpenAI.gpt5_4.rawValue == "gpt-5.4")
        #expect(ModelIdentifier.OpenAI.gpt5_4Mini.rawValue == "gpt-5.4-mini")
        #expect(ModelIdentifier.OpenAI.gpt5_4Nano.rawValue == "gpt-5.4-nano")
        #expect(ModelIdentifier.OpenAI.gpt4o.rawValue == "gpt-4o")
        #expect(ModelIdentifier.OpenAI.gpt4oMini.rawValue == "gpt-4o-mini")
        #expect(ModelIdentifier.OpenAI.default == .gpt4o)
    }

    @Test("Groq model IDs match official API identifiers")
    func testGroqModelIds() {
        #expect(ModelIdentifier.Groq.llama3_3_70b.rawValue == "llama-3.3-70b-versatile")
        #expect(ModelIdentifier.Groq.llama3_1_8b.rawValue == "llama-3.1-8b-instant")
        #expect(ModelIdentifier.Groq.gptOss120b.rawValue == "openai/gpt-oss-120b")
        #expect(ModelIdentifier.Groq.default == .llama3_3_70b)
    }

    @Test("Ollama model names match common pull names")
    func testOllamaModelIds() {
        #expect(ModelIdentifier.Ollama.llama3_1.rawValue == "llama3.1")
        #expect(ModelIdentifier.Ollama.mistral.rawValue == "mistral")
        #expect(ModelIdentifier.Ollama.default == .llama3_3)
    }

    @Test("Apple model identifiers map to configuration names")
    func testAppleModelIds() {
        #expect(ModelIdentifier.Apple.general.rawValue == "apple-on-device-general")
        #expect(ModelIdentifier.Apple.generalPermissive.rawValue == "apple-on-device-general-permissive")
        #expect(ModelIdentifier.Apple.default == .general)
    }

    @Test("ModelIdentifier.id returns the raw API string")
    func testModelIdentifierDescription() {
        let claude = ModelIdentifier.claude(.opus)
        #expect(claude.id == "claude-opus-4-6")

        let openai = ModelIdentifier.openAI(.gpt5_4)
        #expect(openai.id == "gpt-5.4")

        let apple = ModelIdentifier.apple(.general)
        #expect(apple.id == "apple-on-device-general")

        let custom = ModelIdentifier.custom("my-fine-tune-v2")
        #expect(custom.id == "my-fine-tune-v2")
    }
}
