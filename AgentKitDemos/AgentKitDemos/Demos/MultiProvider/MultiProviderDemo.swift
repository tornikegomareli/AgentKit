import SwiftUI
import AgentKitCore
import AgentKitProviders
import AgentKitChat

/// Multi-provider demo — shows the same AgentChatView powered by different LLMs.
/// Demonstrates zero-lock-in: switch providers without changing any other code.
struct MultiProviderDemo: View {
    @State private var selectedProvider: ProviderOption = .openai
    @State private var sessions: [ProviderOption: AgentSession] = [:]
    @State private var agents: [ProviderOption: AgentKit] = [:]

    enum ProviderOption: String, CaseIterable, Identifiable {
        case openai = "OpenAI GPT-4o"
        case ollama = "Ollama (Local)"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .openai: return "cloud"
            case .ollama: return "desktopcomputer"
            }
        }

        func makeProvider() -> LLMProvider {
            switch self {
            case .openai:
                return .openai(
                    apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-key-here",
                    model: .gpt4o
                )
            case .ollama:
                return .ollama(model: .llama3_3)
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Provider picker
            Picker("Provider", selection: $selectedProvider) {
                ForEach(ProviderOption.allCases) { option in
                    Label(option.rawValue, systemImage: option.icon)
                        .tag(option)
                }
            }
            .pickerStyle(.segmented)
            .padding()

            Divider()

            // Chat view for selected provider
            if let session = sessions[selectedProvider] {
                AgentChatView(session: session)
                    .agentName(selectedProvider.rawValue)
                    .agentAccentColor(selectedProvider == .openai ? .green : .orange)
                    .suggestedPrompts([
                        "What model are you?",
                        "Write a short poem",
                        "Explain recursion"
                    ])
                    .id(selectedProvider) // force recreate on switch
            } else {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Starting \(selectedProvider.rawValue)...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Multi-Provider")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            ensureSession(for: selectedProvider)
        }
        .onChange(of: selectedProvider) { _, newValue in
            ensureSession(for: newValue)
        }
    }

    private func ensureSession(for option: ProviderOption) {
        guard agents[option] == nil else { return }

        let kit = AgentKit(
            provider: option.makeProvider(),
            configuration: Configuration(
                systemPrompt: "You are a helpful assistant. Be concise. Identify which model you are when asked."
            )
        )
        agents[option] = kit
        sessions[option] = kit.startSession()
    }
}
