import SwiftUI

/// Shows the Clerk agent's activity log — dark theme.
struct ActivityLogView: View {
    @Environment(BankingService.self) private var bank

    var body: some View {
        NavigationStack {
            Group {
                if bank.activityLog.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundStyle(Color(hex: 0x334455))
                        Text("No Activity Yet")
                            .font(.headline)
                            .foregroundStyle(Color(hex: 0x8899AA))
                        Text("Clerk's actions will appear here as you interact with the agent.")
                            .font(.caption)
                            .foregroundStyle(Color(hex: 0x556677))
                            .multilineTextAlignment(.center)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(bank.activityLog) { entry in
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(entryColor(entry.type))
                                        .frame(width: 8, height: 8)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(entry.description)
                                            .font(.subheadline)
                                            .foregroundStyle(.white)
                                        Text(entry.formattedTime)
                                            .font(.caption2)
                                            .foregroundStyle(Color(hex: 0x556677))
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 10)
                            }
                        }
                    }
                }
            }
            .background(Color(hex: 0x0C0F14))
            .navigationTitle("Activity")
            .toolbarBackground(Color(hex: 0x0C0F14), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func entryColor(_ type: BankingService.ActivityEntry.EntryType) -> Color {
        switch type {
        case .readOnly: return Color(hex: 0x64748B)
        case .proposed: return Color(hex: 0xFBBF24)
        case .confirmed: return Color(hex: 0x34D399)
        case .warning: return Color(hex: 0xF87171)
        }
    }
}
