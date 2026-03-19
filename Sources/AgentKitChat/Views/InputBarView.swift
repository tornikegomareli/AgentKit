import SwiftUI

/// The text input bar at the bottom of the chat.
@available(iOS 17.0, macOS 14.0, *)
struct InputBarView: View {
    @Binding var text: String
    let placeholder: String
    let isDisabled: Bool
    let onSend: () -> Void
    @Environment(\.chatConfiguration) private var config

    var body: some View {
        HStack(spacing: 12) {
            TextField(placeholder, text: $text, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.secondary.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .disabled(isDisabled)
                .onSubmit { sendIfReady() }

            Button(action: sendIfReady) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(canSend ? config.accentColor : .gray)
            }
            .disabled(!canSend)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    private var canSend: Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isDisabled
    }

    private func sendIfReady() {
        guard canSend else { return }
        onSend()
    }
}
