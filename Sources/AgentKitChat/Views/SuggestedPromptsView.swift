import SwiftUI

/// Displays suggested prompt chips when the conversation is empty.
@available(iOS 17.0, macOS 14.0, *)
struct SuggestedPromptsView: View {
    let prompts: [String]
    let onSelect: (String) -> Void
    @Environment(\.chatConfiguration) private var config

    var body: some View {
        VStack(spacing: 16) {
            Text("How can I help?")
                .font(.title2.bold())
                .foregroundStyle(.primary)

            LazyVGrid(
                columns: [GridItem(.adaptive(minimum: 140), spacing: 10)],
                spacing: 10
            ) {
                ForEach(prompts, id: \.self) { prompt in
                    Button {
                        onSelect(prompt)
                    } label: {
                        Text(prompt)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.12))
                            .clipShape(
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal, 24)
    }
}
