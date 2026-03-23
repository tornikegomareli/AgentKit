import SwiftUI
import AgentKitCore
import AgentKitProviders

/// Lumen Email & Calendar demo — a communication platform with the Courier AI agent.
///
/// Shows: inbox triage, email summarization, reply drafting,
/// calendar integration, meeting scheduling, and label management.
struct LumenEmailDemo: View {
    @State private var mail = MailService()
    @State private var assistant: LumenAssistant?
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            InboxView()
                .tabItem { Label("Inbox", systemImage: "tray.fill") }
                .badge(mail.unreadCount)
                .tag(0)

            CalendarDayView()
                .tabItem { Label("Calendar", systemImage: "calendar") }
                .tag(1)

            Group {
                if let assistant {
                    CourierView(assistant: assistant)
                } else {
                    ProgressView("Starting Courier agent...")
                }
            }
            .tabItem { Label("Courier", systemImage: "sparkles") }
            .tag(2)
        }
        .tint(Color(hex: 0x1E6FA8))
        .environment(mail)
        .task {
            if assistant == nil {
                let provider: LLMProvider = .openai(
                    apiKey: APIKeys.openai,
                    model: .gpt4o
                )
                assistant = LumenAssistant(mail: mail, provider: provider)
            }
        }
    }
}
