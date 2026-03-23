import SwiftUI

/// Calendar view for the Lumen demo showing today's events.
struct CalendarDayView: View {
    @Environment(MailService.self) private var mail

    var body: some View {
        NavigationStack {
            Group {
                if todayEvents.isEmpty {
                    ContentUnavailableView(
                        "No Events Today",
                        systemImage: "calendar",
                        description: Text("Your schedule is clear.")
                    )
                } else {
                    List {
                        Section("Today") {
                            ForEach(todayEvents) { event in
                                eventRow(event)
                            }
                        }

                        if !tomorrowEvents.isEmpty {
                            Section("Tomorrow") {
                                ForEach(tomorrowEvents) { event in
                                    eventRow(event)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Calendar")
        }
    }

    private var todayEvents: [CalendarEvent] {
        mail.events
            .filter { Calendar.current.isDateInToday($0.startTime) }
            .sorted { $0.startTime < $1.startTime }
    }

    private var tomorrowEvents: [CalendarEvent] {
        mail.events
            .filter { Calendar.current.isDateInTomorrow($0.startTime) }
            .sorted { $0.startTime < $1.startTime }
    }

    private func eventRow(_ event: CalendarEvent) -> some View {
        HStack(spacing: 12) {
            // Time
            VStack(spacing: 2) {
                Text(event.formattedStartTime)
                    .font(.caption.weight(.semibold).monospacedDigit())
                Text("\(event.durationMinutes)m")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .frame(width: 60)

            // Color bar
            Rectangle()
                .fill(event.isAgentSuggested ? Color(hex: 0x1A7A6E) : Color(hex: 0x1E6FA8))
                .frame(width: 3)
                .clipShape(Capsule())

            // Details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.subheadline.weight(.medium))
                    if event.isAgentSuggested {
                        Image(systemName: "bolt.fill")
                            .font(.caption2)
                            .foregroundStyle(Color(hex: 0x1A7A6E))
                    }
                }
                Text(event.attendees.map(\.name).joined(separator: ", "))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 4)
    }
}
