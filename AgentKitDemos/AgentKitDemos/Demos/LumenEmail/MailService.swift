import Foundation
import Observation

/// Mock email and calendar service for the Lumen demo.
@Observable
final class MailService {
    var emails: [Email] = Email.samples()
    var events: [CalendarEvent] = CalendarEvent.samples()
    var drafts: [Draft] = []
    var activityLog: [ActivityEntry] = []

    struct Draft: Identifiable {
        let id = UUID()
        let replyToEmailId: String?
        let to: String
        let subject: String
        let body: String
        let createdAt: Date
    }

    struct ActivityEntry: Identifiable {
        let id = UUID()
        let timestamp: Date
        let description: String

        var formattedTime: String {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: timestamp)
        }
    }

    private func log(_ description: String) {
        activityLog.insert(
            ActivityEntry(timestamp: Date(), description: description), at: 0
        )
    }

    // MARK: - Inbox

    var unreadCount: Int { emails.filter { !$0.isRead && $0.labels.contains(.inbox) }.count }
    var actionNeededCount: Int { emails.filter { $0.labels.contains(.action) }.count }

    func getInbox(unreadOnly: Bool = false) -> String {
        var result = emails.filter { $0.labels.contains(.inbox) }
        if unreadOnly { result = result.filter { !$0.isRead } }
        result.sort { $0.date > $1.date }
        log("Viewed inbox\(unreadOnly ? " (unread only)" : "")")
        guard !result.isEmpty else { return "Inbox is empty." }
        return result.map { emailLine($0) }.joined(separator: "\n")
    }

    func getEmail(id: String) -> String {
        guard let email = emails.first(where: { $0.id == id }) else {
            return "Email not found: \(id)"
        }
        log("Read email: \(email.subject)")
        return """
        FROM: \(email.from.name) <\(email.from.email)>
        TO: \(email.to.map { "\($0.name) <\($0.email)>" }.joined(separator: ", "))
        SUBJECT: \(email.subject)
        DATE: \(email.formattedDate)
        LABELS: \(email.labels.map(\.rawValue).joined(separator: ", "))
        READ: \(email.isRead ? "Yes" : "No")
        STARRED: \(email.isStarred ? "Yes" : "No")
        \(email.agentSummary.map { "\nAGENT SUMMARY: \($0)" } ?? "")

        ---

        \(email.body)
        """
    }

    func searchEmails(query: String) -> String {
        let lowered = query.lowercased()
        let results = emails.filter { email in
            email.subject.lowercased().contains(lowered) ||
            email.body.lowercased().contains(lowered) ||
            email.from.name.lowercased().contains(lowered) ||
            email.from.email.lowercased().contains(lowered)
        }
        guard !results.isEmpty else { return "No emails found matching '\(query)'." }
        log("Searched emails: '\(query)' — \(results.count) results")
        return results.map { emailLine($0) }.joined(separator: "\n")
    }

    func getEmailsByLabel(label: String) -> String {
        guard let lbl = Email.Label(rawValue: label) else {
            return "Unknown label: \(label). Valid: \(Email.Label.allCases.map(\.rawValue).joined(separator: ", "))"
        }
        let results = emails.filter { $0.labels.contains(lbl) }.sorted { $0.date > $1.date }
        guard !results.isEmpty else { return "No emails with label '\(label)'." }
        log("Listed emails with label: \(label)")
        return results.map { emailLine($0) }.joined(separator: "\n")
    }

    // MARK: - Triage

    func triageInbox() -> String {
        var report = "Inbox Triage Report:\n\n"
        let unread = emails.filter { !$0.isRead && $0.labels.contains(.inbox) }
        let actionItems = emails.filter { $0.labels.contains(.action) }
        let staleThreads = emails.filter {
            let days = Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0
            return days > 7 && !$0.isRead
        }

        report += "📬 Unread: \(unread.count)\n"
        report += "⚡ Action needed: \(actionItems.count)\n"
        report += "⏰ Waiting >7 days: \(staleThreads.count)\n\n"

        if !actionItems.isEmpty {
            report += "Action items (by urgency):\n"
            for email in actionItems.sorted(by: { $0.date > $1.date }) {
                report += "  \(email.id): \(email.from.name) — \"\(email.subject)\" (\(email.formattedDate))\n"
            }
        }

        if !staleThreads.isEmpty {
            report += "\nStale threads needing reply:\n"
            for email in staleThreads {
                let days = Calendar.current.dateComponents([.day], from: email.date, to: Date()).day ?? 0
                report += "  \(email.id): \(email.from.name) — waiting \(days) days\n"
            }
        }

        log("Triaged inbox — \(unread.count) unread, \(actionItems.count) action items")
        return report
    }

    // MARK: - Drafting

    func draftReply(emailId: String, tone: String) -> String {
        guard let email = emails.first(where: { $0.id == emailId }) else {
            return "Email not found: \(emailId)"
        }
        log("Drafted reply to: \(email.subject)")
        return """
        Drafting a reply to \(email.from.name) regarding "\(email.subject)".

        CONTEXT:
        Original message from \(email.from.name):
        \(email.body)

        INSTRUCTIONS: Write a \(tone) reply addressing the key points. Keep it professional and concise.
        The draft will be saved for review — it will NOT be sent automatically.
        """
    }

    func saveDraft(replyToEmailId: String?, to: String, subject: String, body: String) -> String {
        let draft = Draft(
            replyToEmailId: replyToEmailId,
            to: to, subject: subject, body: body,
            createdAt: Date()
        )
        drafts.append(draft)
        log("Saved draft: \(subject)")
        return "Draft saved for review. Subject: \"\(subject)\" to \(to).\n\n✦ Written by Courier — review and send manually."
    }

    // MARK: - Calendar

    func getTodaySchedule() -> String {
        let cal = Calendar.current
        let todayEvents = events.filter { cal.isDateInToday($0.startTime) }
            .sorted { $0.startTime < $1.startTime }
        guard !todayEvents.isEmpty else { return "No events scheduled for today." }
        log("Viewed today's schedule")
        return "Today's Schedule:\n" + todayEvents.map { event in
            "\(event.formattedTime) — \(event.title)\(event.isAgentSuggested ? " ⚡ Suggested by Courier" : "")\n  Attendees: \(event.attendees.map(\.name).joined(separator: ", "))"
        }.joined(separator: "\n\n")
    }

    func suggestMeetingTime(withContact: String, durationMinutes: Int) -> String {
        let cal = Calendar.current
        let todayEvents = events.filter { cal.isDateInToday($0.startTime) }
            .sorted { $0.startTime < $1.startTime }

        // Find a free slot today
        var suggestedHour = 9
        for event in todayEvents {
            let eventHour = cal.component(.hour, from: event.startTime)
            let eventEndHour = cal.component(.hour, from: event.endTime)
            if suggestedHour >= eventHour && suggestedHour < eventEndHour {
                suggestedHour = eventEndHour
            }
        }

        // If no slot today, suggest tomorrow
        if suggestedHour >= 17 {
            let tomorrowEvents = events.filter {
                let tomorrow = cal.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                return cal.isDate($0.startTime, inSameDayAs: tomorrow)
            }
            suggestedHour = 9
            for event in tomorrowEvents.sorted(by: { $0.startTime < $1.startTime }) {
                let h = cal.component(.hour, from: event.startTime)
                let eh = cal.component(.hour, from: event.endTime)
                if suggestedHour >= h && suggestedHour < eh {
                    suggestedHour = eh
                }
            }
            log("Suggested meeting time with \(withContact) — tomorrow at \(suggestedHour):00")
            return "Suggested time: Tomorrow at \(suggestedHour):00 for \(durationMinutes) minutes with \(withContact).\nThis slot is free on your calendar. Would you like me to create an event?"
        }

        log("Suggested meeting time with \(withContact) — today at \(suggestedHour):00")
        return "Suggested time: Today at \(suggestedHour):00 for \(durationMinutes) minutes with \(withContact).\nThis slot is free on your calendar. Would you like me to create an event?"
    }

    func createEvent(title: String, hour: Int, minute: Int, durationMinutes: Int, attendeeNames: [String]) -> String {
        let cal = Calendar.current
        var startComponents = cal.dateComponents([.year, .month, .day], from: Date())
        startComponents.hour = hour
        startComponents.minute = minute
        guard let start = cal.date(from: startComponents),
              let end = cal.date(byAdding: .minute, value: durationMinutes, to: start) else {
            return "Failed to create event — invalid time."
        }

        let attendees = attendeeNames.map { Contact(name: $0, email: "\($0.lowercased().replacingOccurrences(of: " ", with: "."))@email.com") }

        let event = CalendarEvent(
            id: "CAL-\(Int.random(in: 100...999))",
            title: title,
            startTime: start, endTime: end,
            attendees: attendees,
            isAgentSuggested: true,
            notes: "Created by Courier Agent"
        )
        events.append(event)
        log("Created event: \(title) at \(event.formattedTime)")
        return "Event created: \"\(title)\" at \(event.formattedTime) with \(attendeeNames.joined(separator: ", ")).\n⚡ Suggested by Courier Agent."
    }

    // MARK: - Labels

    func addLabel(emailId: String, label: String) -> String {
        guard let index = emails.firstIndex(where: { $0.id == emailId }) else {
            return "Email not found: \(emailId)"
        }
        guard let lbl = Email.Label(rawValue: label) else {
            return "Unknown label: \(label)"
        }
        if emails[index].labels.contains(lbl) {
            return "Email already has label '\(label)'."
        }
        emails[index].labels.append(lbl)
        log("Labelled \(emailId) as '\(label)'")
        return "Added label '\(label)' to \"\(emails[index].subject)\"."
    }

    func markAsRead(emailId: String) -> String {
        guard let index = emails.firstIndex(where: { $0.id == emailId }) else {
            return "Email not found: \(emailId)"
        }
        emails[index].isRead = true
        return "Marked \"\(emails[index].subject)\" as read."
    }

    func toggleStar(emailId: String) -> String {
        guard let index = emails.firstIndex(where: { $0.id == emailId }) else {
            return "Email not found: \(emailId)"
        }
        emails[index].isStarred.toggle()
        let action = emails[index].isStarred ? "Starred" : "Unstarred"
        log("\(action) email: \(emails[index].subject)")
        return "\(action) \"\(emails[index].subject)\"."
    }

    // MARK: - Helpers

    private func emailLine(_ email: Email) -> String {
        "\(email.id) \(email.isRead ? "○" : "●") \(email.from.name) — \"\(email.subject)\" (\(email.formattedDate))\(email.labels.contains(.action) ? " ⚡" : "")"
    }
}
