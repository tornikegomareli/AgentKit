import SwiftUI

/// Full email view with agent summary block and action buttons.
struct EmailDetailView: View {
    let email: Email
    @Environment(MailService.self) private var mail

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Subject
                Text(email.subject)
                    .font(.title3.weight(.bold))

                // Sender info
                HStack(spacing: 12) {
                    Text(email.from.initials)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(Color(hex: 0x1E6FA8))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(email.from.name)
                            .font(.subheadline.weight(.semibold))
                        Text(email.from.email)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text(email.formattedDate)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }

                // Labels
                if !email.labels.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(email.labels, id: \.self) { label in
                            HStack(spacing: 4) {
                                Image(systemName: label.icon)
                                    .font(.caption2)
                                Text(label.rawValue)
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(hex: 0x1E6FA8).opacity(0.1))
                            .clipShape(Capsule())
                        }
                    }
                }

                // Agent summary (if available)
                if let summary = email.agentSummary {
                    agentSummaryCard(summary)
                }

                Divider()

                // Email body
                Text(email.body)
                    .font(.body)
                    .lineSpacing(4)
            }
            .padding()
        }
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let index = mail.emails.firstIndex(where: { $0.id == email.id }) {
                mail.emails[index].isRead = true
            }
        }
    }

    private func agentSummaryCard(_ summary: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.caption)
                Text("Courier Summary")
                    .font(.caption.weight(.semibold))
            }
            .foregroundStyle(Color(hex: 0x1A7A6E))

            Text(summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: 0x1A7A6E).opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
