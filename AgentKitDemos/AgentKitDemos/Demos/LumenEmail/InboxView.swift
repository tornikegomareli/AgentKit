import SwiftUI

/// Email inbox view for the Lumen demo.
struct InboxView: View {
    @Environment(MailService.self) private var mail
    @State private var selectedLabel: Email.Label?
    @State private var selectedEmail: Email?

    var body: some View {
        NavigationStack {
            List {
                // Label filter
                Section {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            labelChip(nil, label: "All")
                            ForEach([Email.Label.inbox, .action, .clients, .finance, .newsletters], id: \.self) { lbl in
                                labelChip(lbl, label: lbl.rawValue)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    .listRowBackground(Color.clear)
                }

                // Emails
                ForEach(filteredEmails) { email in
                    NavigationLink {
                        EmailDetailView(email: email)
                    } label: {
                        emailRow(email)
                    }
                }
            }
            .navigationTitle("Lumen")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    if mail.unreadCount > 0 {
                        Text("\(mail.unreadCount) unread")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color(hex: 0x1E6FA8))
                    }
                }
            }
        }
    }

    private var filteredEmails: [Email] {
        var emails = mail.emails
        if let selectedLabel {
            emails = emails.filter { $0.labels.contains(selectedLabel) }
        }
        return emails.sorted { $0.date > $1.date }
    }

    private func emailRow(_ email: Email) -> some View {
        HStack(spacing: 12) {
            // Unread indicator
            Circle()
                .fill(email.isRead ? .clear : Color(hex: 0x1E6FA8))
                .frame(width: 8, height: 8)

            // Avatar
            Text(email.from.initials)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .background(avatarColor(for: email.from.name))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(email.from.name)
                        .font(.subheadline.weight(email.isRead ? .regular : .semibold))
                    Spacer()
                    Text(email.formattedDate)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }

                Text(email.subject)
                    .font(.subheadline)
                    .lineLimit(1)
                    .foregroundStyle(email.isRead ? .secondary : .primary)

                Text(email.preview)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
            }

            if email.isStarred {
                Image(systemName: "star.fill")
                    .font(.caption2)
                    .foregroundStyle(.yellow)
            }
        }
        .padding(.vertical, 2)
    }

    private func labelChip(_ label: Email.Label?, label labelText: String) -> some View {
        let isSelected = selectedLabel == label
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) { selectedLabel = label }
        } label: {
            Text(labelText)
                .font(.caption.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color(hex: 0x1E6FA8) : Color.secondary.opacity(0.12))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private func avatarColor(for name: String) -> Color {
        let colors: [Color] = [
            Color(hex: 0x1E6FA8), Color(hex: 0x1A7A6E), Color(hex: 0xB04060),
            Color(hex: 0x8B6914), Color(hex: 0x6B4C9A), Color(hex: 0x2D7D46)
        ]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
}
