import SwiftUI

/// Root view — a catalog of AgentKit demos.
struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Text("Explore AgentKit capabilities through interactive demos. Each demo showcases a different integration pattern.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
                }

                Section("Drop-in UI") {
                    DemoRow(
                        title: "Minimal Chat",
                        subtitle: "The \"10 lines\" demo — just AgentChatView with zero tools",
                        icon: "bubble.left.fill",
                        color: .blue
                    ) {
                        MinimalChatDemo()
                    }

                    DemoRow(
                        title: "Shopping Assistant",
                        subtitle: "Full app with 5 tools: search, cart, orders, product details",
                        icon: "bag.fill",
                        color: .indigo
                    ) {
                        ShoppingAssistantDemo()
                            .navigationBarBackButtonHidden(false)
                    }
                }

                Section("Custom UI") {
                    DemoRow(
                        title: "Code Explainer",
                        subtitle: "Headless mode — custom UI driven by raw event stream",
                        icon: "chevron.left.forwardslash.chevron.right",
                        color: .orange
                    ) {
                        CodeExplainerDemo()
                    }
                }

                Section("Advanced") {
                    DemoRow(
                        title: "Multi-Provider",
                        subtitle: "Same chat view, switch between OpenAI and Ollama live",
                        icon: "arrow.triangle.swap",
                        color: .green
                    ) {
                        MultiProviderDemo()
                    }
                }

                Section {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Set your API key")
                            .font(.subheadline.weight(.medium))
                        Text("Edit Scheme > Run > Environment Variables > OPENAI_API_KEY")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowBackground(Color.yellow.opacity(0.1))
                }
            }
            .navigationTitle("AgentKit Demos")
        }
    }
}

/// A row in the demo catalog.
struct DemoRow<Destination: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
    @ViewBuilder let destination: () -> Destination

    var body: some View {
        NavigationLink {
            destination()
        } label: {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(.white)
                    .frame(width: 40, height: 40)
                    .background(color, in: RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body.weight(.semibold))
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

#Preview {
    ContentView()
}
