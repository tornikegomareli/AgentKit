import SwiftUI
import AgentKitCore

/// A drop-in SwiftUI chat view powered by AgentKit.
///
/// Provides a complete chat interface: message bubbles, streaming text,
/// tool call indicators, suggested prompts, and a text input bar.
/// Customize with view modifiers like `.agentName()` and `.agentAccentColor()`.
///
/// ## Minimal Usage
/// ```swift
/// AgentChatView(session: agent.startSession())
///     .agentName("Aria")
///     .agentAccentColor(.purple)
/// ```
///
/// ## Custom Confirmation Sheet
/// ```swift
/// AgentChatView(session: session)
///     .confirmationView { confirmation, approve, reject in
///         MyCustomConfirmationView(
///             confirmation: confirmation,
///             onApprove: approve,
///             onReject: reject
///         )
///     }
/// ```
@available(iOS 17.0, macOS 14.0, *)
public struct AgentChatView: View {
    @State private var viewModel: ChatMessageViewModel
    @State private var inputText = ""
    @Environment(\.chatConfiguration) private var config
    @Environment(\.confirmationViewBuilder) private var customConfirmationView

    /// Create a chat view connected to an agent session.
    ///
    /// - Parameter session: The ``AgentSession`` to send messages to and receive events from.
    public init(session: AgentSession) {
        self._viewModel = State(initialValue: ChatMessageViewModel(session: session))
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if viewModel.items.isEmpty && !config.suggestedPrompts.isEmpty {
                            SuggestedPromptsView(
                                prompts: config.suggestedPrompts,
                                onSelect: { prompt in
                                    inputText = ""
                                    viewModel.send(prompt)
                                }
                            )
                            .padding(.top, 40)
                        }

                        ForEach(viewModel.items) { item in
                            switch item.role {
                            case .toolCall:
                                if config.showToolCalls {
                                    // Don't show pendingConfirmation items inline — the sheet handles it
                                    if item.toolState != .pendingConfirmation {
                                        ToolCallRow(item: item)
                                    }
                                }
                            default:
                                MessageBubble(item: item)
                            }
                        }

                        // Streaming indicator
                        if viewModel.isStreaming && !viewModel.streamingText.isEmpty {
                            HStack(alignment: .top, spacing: 8) {
                                streamingAvatar
                                StreamingTextView(text: viewModel.streamingText)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 10)
                                    .background(Color.secondary.opacity(0.12))
                                    .clipShape(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    )
                                Spacer(minLength: 60)
                            }
                            .padding(.horizontal, 16)
                        }

                        // Typing indicator
                        if viewModel.isStreaming
                            && viewModel.streamingText.isEmpty
                            && config.showTypingIndicator {
                            HStack {
                                TypingIndicator()
                                    .padding(.leading, 52)
                                Spacer()
                            }
                        }

                        // Scroll anchor
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.items.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.2)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.streamingText) { _, _ in
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }

            Divider()

            // Input bar
            InputBarView(
                text: $inputText,
                placeholder: config.inputPlaceholder,
                isDisabled: viewModel.isStreaming
            ) {
                let message = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
                inputText = ""
                viewModel.send(message)
            }
        }
        .sheet(item: $viewModel.activeConfirmation) { confirmation in
            if let builder = customConfirmationView {
                builder(
                    confirmation,
                    { viewModel.approve(confirmation.id) },
                    { viewModel.reject(confirmation.id) }
                )
            } else {
                ToolConfirmationSheet(
                    confirmation: confirmation,
                    onApprove: { viewModel.approve(confirmation.id) },
                    onReject: { viewModel.reject(confirmation.id) }
                )
            }
        }
    }

    // MARK: - Subviews

    private var headerView: some View {
        HStack {
            if let imageName = config.avatarImageName {
                Image(imageName)
                    .resizable()
                    .frame(width: 32, height: 32)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(config.accentColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String(config.agentName.prefix(1)).uppercased())
                            .font(.subheadline.bold())
                            .foregroundStyle(config.accentColor)
                    }
            }

            Text(config.agentName)
                .font(.headline)

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var streamingAvatar: some View {
        if let imageName = config.avatarImageName {
            Image(imageName)
                .resizable()
                .frame(width: 28, height: 28)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(config.accentColor.opacity(0.15))
                .frame(width: 28, height: 28)
                .overlay {
                    Text(String(config.agentName.prefix(1)).uppercased())
                        .font(.caption.bold())
                        .foregroundStyle(config.accentColor)
                }
        }
    }
}

// MARK: - Typing Indicator

@available(iOS 17.0, macOS 14.0, *)
private struct TypingIndicator: View {
    @State private var phase = 0.0

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(Color.secondary)
                    .frame(width: 6, height: 6)
                    .scaleEffect(dotScale(for: index))
                    .animation(
                        .easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: phase
                    )
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.secondary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .onAppear { phase = 1.0 }
    }

    private func dotScale(for index: Int) -> CGFloat {
        phase > 0 ? 1.0 : 0.5
    }
}

// MARK: - Custom Confirmation View Environment

/// Type-erased closure for custom confirmation views.
@available(iOS 17.0, macOS 14.0, *)
public typealias ConfirmationViewBuilder = (PendingToolConfirmation, @escaping () -> Void, @escaping () -> Void) -> AnyView

@available(iOS 17.0, macOS 14.0, *)
private struct ConfirmationViewBuilderKey: EnvironmentKey {
    static let defaultValue: ConfirmationViewBuilder? = nil
}

@available(iOS 17.0, macOS 14.0, *)
extension EnvironmentValues {
    var confirmationViewBuilder: ConfirmationViewBuilder? {
        get { self[ConfirmationViewBuilderKey.self] }
        set { self[ConfirmationViewBuilderKey.self] = newValue }
    }
}
