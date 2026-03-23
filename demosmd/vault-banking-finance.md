# Vault — Banking & Finance
### Agentic Product Design Document

---

## Overview

Vault is a personal and business banking platform with an embedded AI agent — the **Clerk Agent** — that handles the cognitive and operational burden of financial management. Users can instruct Clerk in plain language to move money, schedule payments, analyse spending, and manage accounts. Vault is where conversational banking becomes real — not a chatbot bolted onto a legacy interface, but an agent that understands your financial life and acts within strict, auditable boundaries.

**Target users:** Individuals, freelancers, small business owners, finance operations teams  
**Core problem:** Banking UIs are designed for banks, not people — routine financial operations require too many steps, too much context-switching, and zero intelligence  
**Agent name:** Clerk  
**Agent personality:** Precise, cautious, transparent — moves money carefully and explains every number

> ⚠️ **Design philosophy:** Financial actions are irreversible or near-irreversible. Vault's entire UX is built around a single principle — *the agent makes it easy to act, and impossible to act accidentally.*

---

## Product Design

### Layout & Information Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│ SIDEBAR (240px)  │ MAIN PANEL (flex)                  │ CLERK PANEL     │
│                  │                                     │ (320px)         │
│ 🏛 Vault         │ ┌── Account Overview ─────────────┐ │                 │
│                  │ │ Current         GEL 12,480.00   │ │ ◉ Clerk Agent   │
│ Accounts         │ │ Savings         GEL  8,200.00   │ │                 │
│ ● Checking 12.4k │ │ Business        GEL 24,600.00   │ │ "Transfer 500   │
│ ● Savings   8.2k │ └─────────────────────────────────┘ │  GEL to        │
│ ● Business 24.6k │                                     │  savings"       │
│ + Add account    │ ┌── Recent Transactions ──────────┐ │                 │
│                  │ │ Mar 19 · Bolt        -GEL 18.50 │ │ ┌─ Confirm ──┐ │
│ Cards            │ │ Mar 18 · Amazon     -GEL 220.00 │ │ │ FROM        │ │
│ ○ Personal ••4521│ │ Mar 17 · Salary    +GEL 4500.00 │ │ │ Checking    │ │
│ ○ Business ••8820│ │ Mar 16 · Transfer  -GEL 500.00  │ │ │ TO          │ │
│                  │ └─────────────────────────────────┘ │ │ Savings     │ │
│ Scheduled        │                                     │ │ AMOUNT      │ │
│ ○ 3 upcoming     │ ┌── Spending Analysis ────────────┐ │ │ GEL 500.00  │ │
│                  │ │ [Donut chart · categories]       │ │ │             │ │
│ Payees           │ └─────────────────────────────────┘ │ │ [Confirm ✓] │ │
│                  │                                     │ │ [Cancel  ×] │ │
│ [Clerk Agent     │                                     │ └─────────────┘ │
│  activity card]  │                                     │                 │
│                  │                                     │ Core Values     │
│                  │                                     │ 01–07           │
│                  │                                     │ [Instruct Clerk]│
└──────────────────────────────────────────────────────────────────────────┘
```

### Visual Identity

| Property | Value |
|---|---|
| Theme | Trust-first — deep navy, clean white, gold precision |
| Background | `#f0f4f8` (cool light), `#ffffff` (card surfaces) |
| Primary | `#1a3a5c` (deep navy) — authority, trustworthiness |
| Agent color | `#2a6496` (steel blue) — Clerk presence |
| Confirm | `#1a6b3a` (treasury green) — safe, approved action |
| Warning | `#b05a10` (amber) — review required |
| Danger | `#8b2020` (crimson) — irreversible action |
| Text | `#1a2332` (near black), `#5a6b7a` (secondary) |
| Display font | Söhne (or Neue Haas Grotesk fallback) — Swiss banking precision |
| UI font | Inter — neutral, legible at small sizes |
| Numbers | Tabular figures, monospaced — amounts always align |
| Border style | Subtle, 1px — professional, not decorative |

### Key UI Patterns

**Clerk confirmation card** — the most critical UI component. Every financial action Clerk proposes appears as a structured card with:

```
┌─────────────────────────────────────────────┐
│ ⚠ Review before confirming                  │
│                                             │
│ ACTION      Transfer funds                  │
│ FROM        Checking Account (••4521)       │
│ TO          Savings Account (••8890)        │
│ AMOUNT      GEL 500.00                      │
│ TIMING      Immediate                       │
│ REFERENCE   "Monthly savings — March"      │
│                                             │
│ Remaining balance after: GEL 11,980.00     │
│                                             │
│      [ Cancel ]    [ Confirm Transfer ]    │
└─────────────────────────────────────────────┘
```

**Three-tier action classification:**

| Tier | Examples | Flow |
|---|---|---|
| 🟢 Low risk | View balance, spending analysis, export statement | Agent executes instantly |
| 🟡 Medium risk | Internal transfer, schedule payment, add payee | Clerk proposes → user confirms once |
| 🔴 High risk | External transfer, large amount, new recipient, international wire | Clerk proposes → user confirms → biometric/PIN → executed |

**Natural language input bar** — always visible at the bottom of the Clerk panel:

```
┌──────────────────────────────────────────────┐
│ 💬  Tell Clerk what to do…             [→]   │
│                                              │
│ Try: "Pay rent on the 1st of every month"    │
│      "How much did I spend on food in Feb?"  │
│      "Transfer 200 to savings"               │
└──────────────────────────────────────────────┘
```

**Spending analysis** — triggered by natural language, rendered as visual breakdowns with Clerk's interpretation alongside

---

## Agent Capabilities

### Read-only actions (no approval needed)
- Display account balances and transaction history
- Generate spending breakdowns by category, merchant, or time period
- Calculate savings rate, average monthly spend, or runway
- Identify recurring charges and subscriptions
- Surface unusual or anomalous transactions with explanation
- Export statements in requested format

### Proposed actions (user confirms, then executed)
- **Internal transfer** — move funds between owned accounts
- **Schedule recurring transfer** — set up a regular savings or payment rule
- **Pay a saved payee** — send to a previously verified recipient
- **Cancel scheduled payment** — stop an upcoming recurring payment

### High-security actions (confirm + biometric/PIN)
- **New external transfer** — send to a recipient not in the payee list
- **Add new payee** — register a new external account
- **Large transfer** — any amount over the user's configured threshold (default: GEL 1,000)
- **International wire** — cross-border payment with FX conversion
- **Card freeze / unfreeze** — instant card lock

### Permanently blocked (Clerk can never do this)
- Approve its own transfers
- Override spending limits
- Disable security checks
- Transfer to unverified accounts
- Access accounts outside the logged-in user's profile

---

## Core Agent Values

### 01 — Confirm Before Every Financial Action
The Clerk Agent never moves money without an explicit, separate confirmation from the user. There is no "fast mode" for financial transfers. Even if the user says "transfer 500 to savings and do it now," Clerk presents the confirmation card first. The extra tap is not a bug — it is the product.

### 02 — Show the Full Picture
Before confirming any transfer, Clerk shows the post-transaction balance of the source account. It proactively warns if a proposed transfer would leave the account below a safe threshold, conflict with an upcoming scheduled payment, or trigger an overdraft. The user always sees the consequence before acting.

### 03 — Escalate Anomalies Immediately
If Clerk detects a transaction pattern that looks unusual — a new large payee, a transfer at an unusual time, an amount that deviates significantly from the user's history — it flags the transaction and asks the user to re-confirm before proceeding. Anomaly detection runs on every outbound action.

### 04 — Irreversibility Warnings Are Mandatory
For any action that cannot be undone (external wire, new payee creation, large transfer), Clerk must explicitly state: "This action cannot be reversed once confirmed." This message cannot be removed from the confirmation flow. No exceptions.

### 05 — Plain Language, No Jargon
Every Clerk response uses plain language. Not "initiate an ACH debit" — "transfer from your checking account." Not "settlement T+2" — "arrives in 2 business days." Users should never need to interpret what the agent said in order to make a financial decision.

### 06 — Audit Trail for Everything
Every action Clerk takes — including read-only queries, proposed transfers, and declined suggestions — is logged with a timestamp, the user's instruction, and the outcome. This log is always accessible to the user. Clerk's history is the user's history.

### 07 — Zero Autonomous Financial Actions
The Clerk Agent has no ability to execute financial transactions without user confirmation. This is an architectural constraint, not just a policy. The agent generates transaction proposals; the banking infrastructure only accepts transactions signed with the user's confirmed action. Clerk cannot move money on its own. Ever.

---

## Agent Interaction Examples

### Internal transfer
**User:** "Move 500 GEL to my savings"  
**Clerk:** Shows confirmation card: FROM Checking (GEL 12,480) → TO Savings, AMOUNT GEL 500, Remaining balance: GEL 11,980. User taps Confirm. Transfer executes. Clerk replies: "Done — GEL 500 transferred to your Savings Account. Balance is now GEL 11,980."

### Scheduled payment
**User:** "Pay my rent of 800 GEL to landlord on the 1st of every month"  
**Clerk:** "I'll set up a recurring payment of GEL 800.00 to Giorgi Beridze (••3312) on the 1st of each month, starting April 1st. Your March paycheck arrives March 25 — you'll have enough. Confirm?"  
User confirms. Recurring rule created.

### Spending analysis
**User:** "How much did I spend on food last month?"  
**Clerk:** "In February you spent GEL 1,240 on food and dining — that's 22% of your total spend. Restaurants accounted for GEL 820, groceries GEL 420. Your 3-month average is GEL 1,080, so February was about 15% above normal."  
*(No confirmation needed — this is read-only)*

### Anomaly detection
**User:** "Transfer 3,000 GEL to IBAN GE29TB000000001234567"  
**Clerk:** "⚠ This is a new recipient I haven't seen before, and GEL 3,000 is above your usual transfer amount. Before I set this up, can you confirm: who is this recipient and what is this for? This action cannot be reversed once sent."  
User: "That's my supplier, new account"  
**Clerk:** Shows full confirmation card with high-risk styling + biometric prompt.

### Savings goal
**User:** "I want to save 5,000 GEL by July"  
**Clerk:** "You have 15 weeks until July 1st. To reach GEL 5,000 you'd need to save about GEL 333 per week or GEL 1,450 per month. Based on your last 3 months, you have roughly GEL 900/month available after expenses — you'd reach about GEL 3,800 at that rate. Want me to set up an automatic GEL 900 monthly transfer to savings? Or would you like to review your spending to find the extra GEL 550?"

---

## Trust & Transparency Design

**Visual hierarchy for risk:**
- Green borders and typography for confirmed/completed actions
- Amber styling for anything requiring review
- Crimson and full-screen overlay for high-risk actions (large, external, new payee)

**Activity log** — persistent log in the sidebar showing every Clerk action today:
```
09:41  Viewed balance — Checking Account
09:42  Proposed transfer GEL 500 → Savings  [Confirmed by user]
10:15  Spending analysis — Food · February
10:22  Anomaly flagged — New large payee
```

**Clerk can explain itself:** Every suggestion and calculation comes with a "How did you get that?" link that shows Clerk's reasoning in plain steps

**Configurable thresholds:**
- Large transfer warning threshold (default GEL 1,000)
- Anomaly sensitivity (conservative / standard / relaxed)
- Biometric requirement threshold
- Auto-categorisation rules

**What Clerk never does (and users can verify):**
- A "Clerk permissions" screen shows exactly which actions Clerk is technically capable of — users can see and optionally restrict these at any time

---

## Regulatory & Compliance Notes

*(For engineering/product teams)*

- All Clerk-proposed transactions must pass through the same validation layer as manual transactions — no bypass
- Confirmation events must be cryptographically signed and stored for audit
- Anomaly detection must run server-side, not in the agent layer
- PSD2/open banking compliance: agent actions must be logged as "user-initiated via agent" in transaction metadata
- User data used for Clerk's context (spending patterns, payees) must be isolated per account and never used cross-customer

---

*Vault — banking that listens, thinks, and always asks before it acts.*
