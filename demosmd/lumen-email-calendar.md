# Lumen — Email & Calendar
### Agentic Product Design Document

---

## Overview

Lumen is a communication platform where an AI agent — the **Courier Agent** — handles the cognitive overhead of email: triaging, summarising, drafting replies, and scheduling meetings. It treats your inbox as a decision surface, not a reading list. Courier does the reading; you make the calls.

**Target users:** Executives, account managers, team leads, anyone with a high-volume inbox  
**Core problem:** Email is the most used communication tool and the most cognitively expensive — triaging alone consumes hours that should be spent on decisions  
**Agent name:** Courier  
**Agent personality:** Organised, discreet, never sends anything you haven't seen

---

## Product Design

### Layout & Information Architecture

```
┌──────────────────────────────────────────────────────────────────────────────────┐
│ SIDEBAR (220px) │ EMAIL LIST (320px) │ EMAIL VIEW (flex)       │ CALENDAR (260px)│
│                 │                    │                          │                 │
│ ☀ Lumen         │ Inbox       [14]   │ Partnership proposal —   │ March 2026      │
│                 │ ─────────────────  │ Q2 expansion             │ Thursday, 19th  │
│ [Compose]       │ ● Marcus Reyes     │                          │ M T W T F S S   │
│                 │   Partnership…     │ From: Marcus Reyes        │ 16 17 18 19…   │
│ Mail            │   9:42 am          │ To: me · 9:42 am         │                 │
│ ● Inbox    [14] │ ─────────────────  │                          │ Today           │
│ ○ Starred   [3] │ ● Sarah Chen       │ ┌──────────────────────┐ │ 10:00 Standup   │
│ ○ Snoozed   [2] │   Design review…   │ │ 🤖 Courier Summary   │ │ 2:00 Marcus ⚡  │
│ ○ Sent          │   8:15 am          │ │ Marcus is following  │ │ 4:30 Q2 Review  │
│ ○ Archive       │ ─────────────────  │ │ up on last week…     │ │                 │
│                 │ Acme Billing  ⚡   │ │ [Schedule][Draft]    │ │ Core Values     │
│ Labels          │   Invoice #2847    │ │ [Decline]            │ │ 01–05           │
│ ○ Clients   [5] │   Yesterday        │ └──────────────────────┘ │                 │
│ ○ Action    [7] │ ─────────────────  │                          │                 │
│ ○ Newsletters   │ Priya Sharma       │ [Email body]             │                 │
│                 │   Onboarding sched │                          │                 │
│ [Courier Agent  │   Yesterday        │                          │                 │
│  active card]   │                    │                          │                 │
└──────────────────────────────────────────────────────────────────────────────────┘
```

### Visual Identity

| Property | Value |
|---|---|
| Theme | Light editorial — airy, focused, warm |
| Background | `#f8f6f2` (warm white), `#ffffff` (cards) |
| Accent | `#1e6fa8` (sky blue) — primary actions |
| Agent color | `#1a7a6e` (teal) — Courier presence |
| Urgent | `#b04060` (rose) — flags and alerts |
| Text | `#1c1917` (near black), `#6b6560` (secondary) |
| Display font | Playfair Display — elegant, editorial headings |
| UI font | Geist — clean, modern, readable |
| Border style | `rgba(0,0,0,0.09)` — delicate, refined |

### Key UI Patterns

**Agent summary block** — appears at the top of every email view for messages over 4 lines. Teal-tinted card with the Courier Agent's plain-language summary and 2–3 suggested actions

**Suggested actions strip:**
- `[ Schedule meeting ]` — opens a proposed calendar slot based on email context
- `[ Draft reply ]` — generates a full draft for review, pre-populated with relevant context
- `[ Decline politely ]` — writes a graceful decline based on your communication style

**Agent-handled inbox item** — emails the agent has already acted on (e.g. forwarded to Finance) show a teal left border and a `Courier: forwarded to Finance` tag, so you always know what happened

**Calendar panel** — mini calendar with today's events shown below; agent-scheduled meetings are marked with ⚡ and "Suggested by Courier Agent" subtitle

---

## Agent Capabilities

### Autonomous actions (no approval needed)
- Triage and categorise incoming email by urgency and label
- Summarise email threads longer than 4 exchanges
- Flag time-sensitive emails (deadlines, meeting requests, invoices due)
- Forward invoices and receipts to designated finance contacts
- Apply labels based on sender, topic, and inferred intent
- Detect when a thread has been waiting for a reply for more than N days

### Prompted actions (user initiates, agent executes)
- **Draft reply** — writes a full response draft based on thread context and your writing style
- **Summarise thread** — produces a structured summary of a long conversation
- **Schedule meeting** — proposes a specific slot, writes the invite, and pre-fills attendees from the thread
- **Unsubscribe sweep** — identifies newsletters and promotional senders for bulk unsubscribe review
- **Follow-up reminder** — sets a reminder to follow up if no response arrives in N days

### Approval-gated actions (always requires human sign-off)
- Sending any email, including replies
- Creating calendar events and sending invites
- Deleting or archiving threads
- Sharing email content with any third party or external tool

---

## Core Agent Values

### 01 — Draft, Don't Send
The Courier Agent never sends an email without explicit human approval — not a reply, not a follow-up, not an auto-response. Every draft is clearly marked as agent-written and sits in a review state until the user reads, edits if needed, and sends manually. Sending is always a human act.

### 02 — No Tone Impersonation
Drafts are written in a tone consistent with your communication history, but they are always marked as `Draft by Courier` with a clear visual indicator. The agent does not silently mimic your voice — it writes on your behalf with your awareness. You are always the author.

### 03 — Calendar Consent
Even when a meeting time is obvious from the email context ("I'm free Thursday at 2pm"), the agent will propose the event — not create it. Calendar events are suggested, shown for review, and only confirmed when the user taps "Create event." No one gets an invite you didn't approve.

### 04 — Triage with Reasoning
Every label, urgency flag, or priority applied by Courier is accompanied by a brief explanation: "Marked urgent — contains a deadline of April 5th" or "Labelled Finance — sender is Acme Corp Billing." Users can see exactly why the agent made each call and override any decision.

### 05 — No Data Leakage
Email content is processed to support your workflow only. It is never used to train models, never cross-referenced outside your account, and never shared with third parties without explicit integration consent. Courier treats your inbox as confidential by default.

---

## Agent Interaction Examples

**Triage on arrival:**  
Invoice email from Acme Corp lands → Courier detects billing sender, invoice number, and due date → Auto-labels `Finance` and `Action needed` → Forwards to `finance@company.com` per saved rule → Marks thread in inbox with teal badge `Courier: forwarded to Finance`

**Meeting scheduling:**  
Marcus's email says "available Thursday afternoon or any time Friday" → Courier checks your calendar → Proposes Thursday 2:00–2:30 with pre-written invite → User taps "Send invite" → Done

**Draft reply:**  
User: "Draft a reply to Marcus accepting the partnership discussion"  
Courier: Reads the full thread, checks your calendar, writes a warm 4-sentence reply confirming Thursday 2pm, mentioning the attached proposal, and suggesting a pre-call reading list from the deck. User reads, edits one sentence, sends.

**Staleness alert:**  
"Tom Lindqvist has been waiting 14 days for a reply on the Q2 budget approval. Would you like me to draft a follow-up?"

---

## Trust & Transparency Design

- **Courier activity card** in the sidebar shows a live log of today's actions: "Drafted 2 replies · Scheduled 1 meeting · Flagged 3 urgent"
- Every agent-written draft shows `✦ Written by Courier` below the compose toolbar
- The "Undo" window for any agent action (labelling, forwarding) is 60 seconds — visible as an inline toast
- Users can set a "Courier scope" — e.g. only triage, or only drafts, not scheduling — from a single settings toggle
- All agent labels are visually distinct from user labels: a subtle `⚡` prefix in the label list

---

*Lumen — so your inbox is a decision surface, not a reading list.*
