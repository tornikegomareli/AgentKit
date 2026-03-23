import Foundation
import AgentKitCore
import AgentKitProviders

/// Wires MailService methods as AgentKit tools for the Courier agent.
///
/// Courier is Lumen's embedded AI agent — organised, discreet,
/// never sends anything you haven't seen.
@MainActor
final class LumenAssistant {
    let agent: AgentKit
    private let mail: MailService

    init(mail: MailService, provider: LLMProvider) {
        self.mail = mail
        self.agent = AgentKit(
            adapter: provider.adapter(),
            configuration: Configuration(
                maxIterations: 10,
                systemPrompt: """
                You are Courier, the embedded AI agent for Lumen — an email and calendar platform.

                PERSONALITY: Organised, discreet, never sends anything the user hasn't seen.

                CORE RULES:
                1. DRAFT, DON'T SEND — Never send an email without explicit human approval. Every draft is clearly marked as agent-written and sits in review until the user approves. Sending is always a human act.
                2. NO TONE IMPERSONATION — Drafts are written professionally but always marked as "Draft by Courier." You write on behalf of the user with their awareness.
                3. CALENDAR CONSENT — Even when a meeting time is obvious, propose the event — don't create it without asking. Calendar events are suggested, shown for review, and only confirmed when the user approves.
                4. TRIAGE WITH REASONING — Every label, urgency flag, or priority you apply comes with a brief explanation: "Marked urgent — contains a deadline of April 5th."
                5. NO DATA LEAKAGE — Email content is confidential. Never reference email content outside the current conversation.

                When triaging, categorize by urgency and explain why.
                When drafting replies, keep them professional and concise.
                When suggesting meeting times, check the calendar first.
                Always include email IDs (e.g., EM-001) so the user can reference them.
                """,
                loggingEnabled: true
            )
        )

        Task {
            await registerTools()
        }
    }

    private func registerTools() async {
        let mail = self.mail

        await agent.tools.register(
            name: "getInbox",
            description: "Show inbox emails. Can filter to unread only.",
            parameters: [
                .bool("unreadOnly", description: "Only show unread emails (default false)", required: false)
            ]
        ) { @MainActor params in
            let unreadOnly = params["unreadOnly"] as? Bool ?? false
            return mail.getInbox(unreadOnly: unreadOnly)
        }

        await agent.tools.register(
            name: "getEmail",
            description: "Read the full content of a specific email.",
            parameters: [
                .string("emailId", description: "Email ID (e.g. EM-001)", required: true)
            ]
        ) { @MainActor params in
            let id = params["emailId"] as? String ?? ""
            return mail.getEmail(id: id)
        }

        await agent.tools.register(
            name: "searchEmails",
            description: "Search emails by keyword across subject, body, and sender.",
            parameters: [
                .string("query", description: "Search keyword or phrase", required: true)
            ]
        ) { @MainActor params in
            let query = params["query"] as? String ?? ""
            return mail.searchEmails(query: query)
        }

        await agent.tools.register(
            name: "getEmailsByLabel",
            description: "List emails with a specific label.",
            parameters: [
                .string("label", description: "Label name: Inbox, Starred, Action Needed, Clients, Newsletters, Finance, Archive", required: true)
            ]
        ) { @MainActor params in
            let label = params["label"] as? String ?? ""
            return mail.getEmailsByLabel(label: label)
        }

        await agent.tools.register(
            name: "triageInbox",
            description: "Analyze and triage the inbox. Shows unread count, action items, and stale threads with reasoning.",
            parameters: []
        ) { @MainActor _ in
            return mail.triageInbox()
        }

        await agent.tools.register(
            name: "draftReply",
            description: "Generate a reply draft for a specific email. The draft is saved for review — it is NOT sent automatically.",
            parameters: [
                .string("emailId", description: "Email ID to reply to", required: true),
                .string("tone", description: "Reply tone: professional, warm, brief, or detailed (default: professional)", required: false)
            ]
        ) { @MainActor params in
            let id = params["emailId"] as? String ?? ""
            let tone = params["tone"] as? String ?? "professional"
            return mail.draftReply(emailId: id, tone: tone)
        }

        await agent.tools.register(
            name: "saveDraft",
            description: "Save a composed email draft for the user to review before sending.",
            parameters: [
                .string("to", description: "Recipient email or name", required: true),
                .string("subject", description: "Email subject line", required: true),
                .string("body", description: "The draft email body text", required: true),
                .string("replyToEmailId", description: "Email ID this is a reply to (optional)", required: false)
            ]
        ) { @MainActor params in
            let to = params["to"] as? String ?? ""
            let subject = params["subject"] as? String ?? ""
            let body = params["body"] as? String ?? ""
            let replyTo = params["replyToEmailId"] as? String
            return mail.saveDraft(replyToEmailId: replyTo, to: to, subject: subject, body: body)
        }

        await agent.tools.register(
            name: "getTodaySchedule",
            description: "Show today's calendar events with times and attendees.",
            parameters: []
        ) { @MainActor _ in
            return mail.getTodaySchedule()
        }

        await agent.tools.register(
            name: "suggestMeetingTime",
            description: "Find a free time slot and suggest a meeting. Checks the calendar for conflicts.",
            parameters: [
                .string("withContact", description: "Name of the person to meet with", required: true),
                .int("durationMinutes", description: "Meeting duration in minutes (default 30)", required: false)
            ]
        ) { @MainActor params in
            let contact = params["withContact"] as? String ?? ""
            let duration = params["durationMinutes"] as? Int ?? 30
            return mail.suggestMeetingTime(withContact: contact, durationMinutes: duration)
        }

        await agent.tools.register(
            name: "createEvent",
            description: "Create a calendar event. REQUIRES APPROVAL — always suggest the event first and wait for confirmation.",
            parameters: [
                .string("title", description: "Event title", required: true),
                .int("hour", description: "Start hour (24h format)", required: true),
                .int("minute", description: "Start minute (default 0)", required: false),
                .int("durationMinutes", description: "Duration in minutes (default 30)", required: false),
                .string("attendees", description: "Comma-separated attendee names", required: false)
            ]
        ) { @MainActor params in
            let title = params["title"] as? String ?? ""
            let hour = params["hour"] as? Int ?? 9
            let minute = params["minute"] as? Int ?? 0
            let duration = params["durationMinutes"] as? Int ?? 30
            let attendeesStr = params["attendees"] as? String ?? ""
            let names = attendeesStr.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
            return mail.createEvent(title: title, hour: hour, minute: minute, durationMinutes: duration, attendeeNames: names)
        }

        await agent.tools.register(
            name: "addLabel",
            description: "Add a label to an email for organization.",
            parameters: [
                .string("emailId", description: "Email ID", required: true),
                .string("label", description: "Label to add", required: true)
            ]
        ) { @MainActor params in
            let id = params["emailId"] as? String ?? ""
            let label = params["label"] as? String ?? ""
            return mail.addLabel(emailId: id, label: label)
        }

        await agent.tools.register(
            name: "toggleStar",
            description: "Star or unstar an email.",
            parameters: [
                .string("emailId", description: "Email ID", required: true)
            ]
        ) { @MainActor params in
            let id = params["emailId"] as? String ?? ""
            return mail.toggleStar(emailId: id)
        }
    }
}
