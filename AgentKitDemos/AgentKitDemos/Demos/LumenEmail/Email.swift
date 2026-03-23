import Foundation

/// An email message in the Lumen demo.
struct Email: Identifiable, Hashable {
    let id: String
    let from: Contact
    let to: [Contact]
    let subject: String
    let body: String
    let date: Date
    var isRead: Bool
    var isStarred: Bool
    var labels: [Label]
    let threadId: String
    var agentSummary: String?
    var agentAction: String?

    enum Label: String, CaseIterable, Hashable {
        case inbox = "Inbox"
        case starred = "Starred"
        case action = "Action Needed"
        case clients = "Clients"
        case newsletters = "Newsletters"
        case finance = "Finance"
        case archive = "Archive"

        var icon: String {
            switch self {
            case .inbox: return "tray.fill"
            case .starred: return "star.fill"
            case .action: return "exclamationmark.circle.fill"
            case .clients: return "person.2.fill"
            case .newsletters: return "newspaper.fill"
            case .finance: return "dollarsign.circle.fill"
            case .archive: return "archivebox.fill"
            }
        }
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        let cal = Calendar.current
        if cal.isDateInToday(date) {
            formatter.dateFormat = "h:mm a"
        } else if cal.isDateInYesterday(date) {
            return "Yesterday"
        } else {
            formatter.dateFormat = "MMM d"
        }
        return formatter.string(from: date)
    }

    var preview: String {
        String(body.prefix(120))
    }
}

struct Contact: Hashable {
    let name: String
    let email: String

    var initials: String {
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))"
        }
        return String(name.prefix(2)).uppercased()
    }
}

extension Email {
    static func samples(relativeTo now: Date = Date()) -> [Email] {
        let cal = Calendar.current
        let me = Contact(name: "Tornike Gomareli", email: "tornike@agentkit.dev")

        func hoursAgo(_ h: Int) -> Date {
            cal.date(byAdding: .hour, value: -h, to: now) ?? now
        }
        func daysAgo(_ d: Int) -> Date {
            cal.date(byAdding: .day, value: -d, to: now) ?? now
        }

        return [
            Email(
                id: "EM-001",
                from: Contact(name: "Marcus Reyes", email: "marcus@partnerco.com"),
                to: [me], subject: "Partnership proposal — Q2 expansion",
                body: "Hi Tornike,\n\nFollowing up on our conversation last week about the Q2 expansion. I've put together a proposal for integrating AgentKit into our platform.\n\nKey points:\n- We'd like to white-label the chat UI for our enterprise clients\n- Volume: ~50k monthly active agent sessions\n- Timeline: pilot in April, full rollout by June\n- Budget: $15k/month for the enterprise license\n\nI've attached the full proposal deck. Can we schedule a call this week to discuss? I'm available Thursday afternoon or any time Friday.\n\nBest,\nMarcus",
                date: hoursAgo(2), isRead: false, isStarred: false,
                labels: [.inbox, .clients, .action],
                threadId: "THR-001", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-002",
                from: Contact(name: "Sarah Chen", email: "sarah@designstudio.io"),
                to: [me], subject: "Design review: Agent confirmation cards",
                body: "Hey Tornike,\n\nI've finished the design review for the agent confirmation card component (DES-012). A few notes:\n\n1. The risk-tier color coding looks great — green/amber/red is intuitive\n2. I'd suggest making the 'Cancel' button more prominent for high-risk actions\n3. The animation on confirm feels too fast — can we slow it to 300ms?\n4. Added dark mode variants to the Figma file\n\nLet me know if you want to hop on a quick call to walk through the changes.\n\nCheers,\nSarah",
                date: hoursAgo(5), isRead: true, isStarred: false,
                labels: [.inbox, .clients],
                threadId: "THR-002", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-003",
                from: Contact(name: "Acme Corp Billing", email: "billing@acmecorp.com"),
                to: [me], subject: "Invoice #2847 — Due March 28",
                body: "Invoice #2847\n\nClient: AgentKit Team\nAmount: $2,400.00\nDue date: March 28, 2026\nService: Cloud infrastructure — March 2026\n\nPayment methods: Wire transfer or ACH.\nBank details attached.\n\nPlease ensure timely payment to avoid service interruption.\n\nAccounting Department\nAcme Corp",
                date: daysAgo(1), isRead: false, isStarred: false,
                labels: [.inbox, .finance, .action],
                threadId: "THR-003", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-004",
                from: Contact(name: "Priya Sharma", email: "priya@techstart.dev"),
                to: [me], subject: "Onboarding schedule for new contributors",
                body: "Hi Tornike,\n\nWe have 3 new contributors joining next week. I've drafted an onboarding schedule based on DOC-008:\n\nMonday: Repo setup + build verification\nTuesday: Architecture walkthrough (you or Dato?)\nWednesday: First PR — documentation fixes\nThursday: Tool registration tutorial\nFriday: Code review practice\n\nCan you confirm the architecture walkthrough slot? Also, should we update the onboarding doc — it still references the old auth middleware.\n\nThanks,\nPriya",
                date: daysAgo(1), isRead: true, isStarred: true,
                labels: [.inbox, .action],
                threadId: "THR-004", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-005",
                from: Contact(name: "Tom Lindqvist", email: "tom@investfund.se"),
                to: [me], subject: "Q2 budget approval — follow up",
                body: "Hi Tornike,\n\nJust checking in on the Q2 budget approval. I sent the breakdown two weeks ago and haven't heard back. We need sign-off by end of this week to secure the funding for the developer relations program.\n\nQuick reminder of the ask:\n- DevRel hire: $8k/month\n- Conference sponsorships: $15k (2 events)\n- Documentation site hosting: $200/month\n\nTotal Q2: ~$39.6k\n\nLet me know if you need anything else from my end.\n\nBest,\nTom",
                date: daysAgo(14), isRead: true, isStarred: false,
                labels: [.inbox, .finance, .action],
                threadId: "THR-005", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-006",
                from: Contact(name: "Swift Weekly Brief", email: "newsletter@swiftweekly.com"),
                to: [me], subject: "Swift Weekly Brief #412 — SE-0430 accepted",
                body: "This week in Swift:\n\n- SE-0430: Typed throws accepted for Swift 6.1\n- New async algorithms package release\n- Community spotlight: Building AI agents in Swift (mentions AgentKit!)\n- Xcode 17 beta 3 release notes\n\nRead more at swiftweekly.com/412",
                date: daysAgo(2), isRead: true, isStarred: false,
                labels: [.newsletters],
                threadId: "THR-006", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-007",
                from: Contact(name: "GitHub Notifications", email: "noreply@github.com"),
                to: [me], subject: "[AgentKit] PR #47: Add Groq adapter — ready for review",
                body: "Pull Request #47 opened by @contributor-alex\n\nTitle: Add Groq adapter\nDescription: Implements GroqAdapter by reusing OpenAISchema translation layer. Groq uses the OpenAI-compatible API so this is mostly configuration.\n\nFiles changed: 3\nAdditions: 120\nDeletions: 2\n\nReview requested from @tornikegomareli",
                date: hoursAgo(8), isRead: false, isStarred: false,
                labels: [.inbox, .action],
                threadId: "THR-007", agentSummary: nil, agentAction: nil
            ),
            Email(
                id: "EM-008",
                from: Contact(name: "Dato Sulakvelidze", email: "dato@agentkit.dev"),
                to: [me], subject: "Re: Token leak incident — CI check is live",
                body: "Tornike,\n\nThe CI check for print() statements is now live. Any PR that introduces a print() call in Sources/ will fail the build.\n\nAlso added a pre-commit hook that warns locally. Documented in CLAUDE.md.\n\nLet me know if we should extend this to the demo app too or just keep it for library code.\n\n— Dato",
                date: daysAgo(3), isRead: true, isStarred: false,
                labels: [.inbox],
                threadId: "THR-008", agentSummary: nil, agentAction: nil
            ),
        ]
    }
}
