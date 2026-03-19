import SwiftUI
import AgentKitCore
import AgentKitProviders

/// Headless mode demo — custom UI driven by AgentSession events directly.
/// Shows that AgentKitChat is optional; you can build any UI you want.
struct CodeExplainerDemo: View {
    @State private var codeInput: String = """
    func fibonacci(_ n: Int) -> Int {
        guard n > 1 else { return n }
        return fibonacci(n - 1) + fibonacci(n - 2)
    }
    """
    @State private var explanation: String = ""
    @State private var isLoading = false
    @State private var session: AgentSession?
    @State private var agent: AgentKit?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Paste code below and tap Explain. Uses AgentKit in headless mode — no AgentChatView, just raw event streaming into a custom UI.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                // Code input
                VStack(alignment: .leading, spacing: 6) {
                    Text("Code")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)

                    TextEditor(text: $codeInput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 150)
                        .padding(8)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }

                // Explain button
                Button {
                    Task { await explain() }
                } label: {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .controlSize(.small)
                        }
                        Text(isLoading ? "Explaining..." : "Explain This Code")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || codeInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                // Explanation output
                if !explanation.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Explanation")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button {
                                #if canImport(UIKit)
                                UIPasteboard.general.string = explanation
                                #endif
                            } label: {
                                Label("Copy", systemImage: "doc.on.doc")
                                    .font(.caption)
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }

                        Text(explanation)
                            .font(.body)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .textSelection(.enabled)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Code Explainer")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if agent == nil {
                let kit = AgentKit(
                    provider: .openai(
                        apiKey: ProcessInfo.processInfo.environment["OPENAI_API_KEY"] ?? "your-key-here",
                        model: .gpt4o
                    ),
                    configuration: Configuration(
                        systemPrompt: """
                        You are a code explanation assistant. When given code, explain what it does
                        in clear, beginner-friendly language. Break it down step by step.
                        Use bullet points. Mention time/space complexity if relevant.
                        Do NOT rewrite the code — only explain it.
                        """
                    )
                )
                agent = kit
                session = kit.startSession()
            }
        }
    }

    @MainActor
    private func explain() async {
        guard let session else { return }
        isLoading = true
        explanation = ""

        session.send("Explain this code:\n```\n\(codeInput)\n```")

        // Consume events directly — headless mode, no AgentChatView
        for await event in session.events {
            switch event {
            case .token(let token):
                explanation += token
            case .responseComplete(let text):
                explanation = text
            case .error(let error):
                explanation = "Error: \(error.description)"
            default:
                break
            }
        }

        isLoading = false
    }
}
