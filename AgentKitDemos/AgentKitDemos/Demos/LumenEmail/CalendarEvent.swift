import Foundation

/// A calendar event in the Lumen demo.
struct CalendarEvent: Identifiable, Hashable {
    let id: String
    var title: String
    var startTime: Date
    var endTime: Date
    var attendees: [Contact]
    var isAgentSuggested: Bool
    var notes: String

    var formattedTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return "\(formatter.string(from: startTime)) – \(formatter.string(from: endTime))"
    }

    var formattedStartTime: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: startTime)
    }

    var durationMinutes: Int {
        Int(endTime.timeIntervalSince(startTime) / 60)
    }
}

extension CalendarEvent {
    static func samples(relativeTo now: Date = Date()) -> [CalendarEvent] {
        let cal = Calendar.current

        func todayAt(hour: Int, minute: Int = 0) -> Date {
            var components = cal.dateComponents([.year, .month, .day], from: now)
            components.hour = hour
            components.minute = minute
            return cal.date(from: components) ?? now
        }

        func tomorrowAt(hour: Int, minute: Int = 0) -> Date {
            let tomorrow = cal.date(byAdding: .day, value: 1, to: now) ?? now
            var components = cal.dateComponents([.year, .month, .day], from: tomorrow)
            components.hour = hour
            components.minute = minute
            return cal.date(from: components) ?? now
        }

        return [
            CalendarEvent(
                id: "CAL-001", title: "Daily Standup",
                startTime: todayAt(hour: 10), endTime: todayAt(hour: 10, minute: 15),
                attendees: [
                    Contact(name: "Tornike Gomareli", email: "tornike@agentkit.dev"),
                    Contact(name: "Dato Sulakvelidze", email: "dato@agentkit.dev"),
                    Contact(name: "Nino Kapanadze", email: "nino@agentkit.dev"),
                ],
                isAgentSuggested: false, notes: "Quick sync on sprint progress"
            ),
            CalendarEvent(
                id: "CAL-002", title: "Q2 Planning Review",
                startTime: todayAt(hour: 16, minute: 30), endTime: todayAt(hour: 17, minute: 30),
                attendees: [
                    Contact(name: "Tornike Gomareli", email: "tornike@agentkit.dev"),
                    Contact(name: "Nino Kapanadze", email: "nino@agentkit.dev"),
                    Contact(name: "Tom Lindqvist", email: "tom@investfund.se"),
                ],
                isAgentSuggested: false, notes: "Review Q2 budget and roadmap"
            ),
            CalendarEvent(
                id: "CAL-003", title: "Architecture Walkthrough — New Contributors",
                startTime: tomorrowAt(hour: 11), endTime: tomorrowAt(hour: 12),
                attendees: [
                    Contact(name: "Tornike Gomareli", email: "tornike@agentkit.dev"),
                    Contact(name: "Priya Sharma", email: "priya@techstart.dev"),
                ],
                isAgentSuggested: false, notes: "Onboarding session for new contributors"
            ),
            CalendarEvent(
                id: "CAL-004", title: "Design Review — Confirmation Cards",
                startTime: tomorrowAt(hour: 14), endTime: tomorrowAt(hour: 14, minute: 30),
                attendees: [
                    Contact(name: "Tornike Gomareli", email: "tornike@agentkit.dev"),
                    Contact(name: "Sarah Chen", email: "sarah@designstudio.io"),
                ],
                isAgentSuggested: false, notes: "Review agent confirmation card designs"
            ),
        ]
    }
}
