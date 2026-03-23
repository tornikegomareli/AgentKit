# Volta — Task & Project Management
### Agentic Product Design Document

---

## Overview

Volta is a project management platform built around the idea that an AI agent — the **Forge Agent** — should close the gap between "what's happening in your codebase, comms, and meetings" and "what's in your task tracker." Forge continuously watches connected sources, suggests tasks, flags blockers, and keeps the board accurate — but always waits for human approval before touching anything.

**Target users:** Engineering teams, product orgs, cross-functional sprints  
**Core problem:** Task boards go stale the moment a sprint starts; teams spend more time maintaining the tracker than doing the work  
**Agent name:** Forge  
**Agent personality:** Systematic, precise, data-driven — surfaces signals without drama

---

## Product Design

### Layout & Information Architecture

```
┌──────────────────────────────────────────────────────────────────────────────┐
│ SIDEBAR (220px)  │  KANBAN BOARD (flex)                          │  VALUES   │
│                  │                                                │  PANEL    │
│ ⚡ Volta         │  Engineering Sprint 24          [Filter][+New] │  (280px)  │
│                  │                                                │           │
│ Spaces           │  BACKLOG │ IN PROGRESS │ REVIEW │ DONE │ ⚡ Q  │  Forge    │
│ ● Engineering 12 │          │             │        │      │       │  Agent    │
│ ○ Design       5 │  [Card]  │   [Card]    │ [Card] │[Card]│[Pend- │  Values   │
│ ○ Marketing    8 │          │             │        │      │ ing   │  01–06    │
│ ○ Growth       3 │  [Card]  │   [Card ⚡] │ [Card] │[Card]│ appro-│           │
│                  │          │             │        │      │ val   │  Instruct │
│ Views            │  [Card]  │   [Card]    │        │[Card]│ cards]│  Agent    │
│ ○ My Tasks       │          │             │        │      │       │  [input]  │
│ ○ All Projects   │                                                │           │
│ ● Overdue [4]    │                                                │           │
│                  │                                                │           │
│ [⚡ FORGE AGENT  │                                                │           │
│  activity card]  │                                                │           │
└──────────────────────────────────────────────────────────────────────────────┘
```

### Visual Identity

| Property | Value |
|---|---|
| Theme | Dark terminal — focused, high-signal |
| Background | `#0d0d0f` (void), `#141418` (sidebar), `#1a1a1f` (panels) |
| Accent | `#a8e040` (electric lime) — agent activity, live signals |
| Text | `#e8e8ec` (primary), `#9090a0` (secondary) |
| Display font | Instrument Sans — clean, modern, confident |
| Labels/IDs | Space Mono — technical precision |
| Border style | `rgba(255,255,255,0.07)` — near-invisible, refined |

### Key UI Patterns

**Agent Queue column** — a dedicated 5th column on the Kanban board, visually distinct with lime border. All Forge suggestions land here as "Pending approval" cards before they touch any other column. No action is ever silent.

**Agent-created card badge** — tasks originating from the agent show a `⚡ AGENT` badge in the card ID field, making provenance instantly visible

**Approval flow:**
```
Forge detects signal → Card appears in Agent Queue → User reviews
→ [Approve] moves card to correct column
→ [Edit] lets user modify before approving
→ [Dismiss] removes it with optional feedback
```

**Sprint health indicator** — live percentage in the agent sidebar card. Calculated from: velocity, blockers, overdue ratio, and PR cycle time

---

## Agent Capabilities

### Autonomous actions (no approval needed)
- Monitor connected sources: GitHub, Slack, PR reviews, CI/CD
- Calculate and display sprint health score
- Detect task staleness (no activity in N days)
- Identify tasks likely to exceed their estimate
- Surface dependency chains and blocked tasks

### Prompted actions (user initiates, agent executes)
- **Triage** — re-prioritise backlog based on sprint goal and team capacity
- **Import** — pull open GitHub issues, Jira tickets, or Slack action items as task drafts
- **Split** — break an oversized task into smaller subtasks with estimates
- **Retrospective** — analyse the completed sprint and generate a structured retro doc

### Approval-gated actions (always requires human sign-off)
- Creating any task (even from an obvious source)
- Changing assignees
- Moving tasks between columns (except Done, which can be triggered by PR merge)
- Closing or deleting tasks
- Modifying due dates or milestones

---

## Core Agent Values

### 01 — Human Approval Gate
No task is created, modified, assigned, or deleted without a human explicitly approving it. The agent queues actions — it never executes them silently. The Agent Queue column exists precisely to make this boundary visible and physical in the interface.

### 02 — Explain Every Action
Every card in the Agent Queue comes with a clear, plain-English reason: "ENG-033 hasn't had a commit in 4 days and is blocking 2 other tasks" or "This issue was marked P0 in GitHub 3 hours ago." The agent never presents a suggestion without showing its source.

### 03 — Respect Ownership
The agent will never reassign a task without surfacing the proposal to both the current assignee and their manager. Ownership changes are always bilateral — the person being removed always sees why. Audit trails are immutable.

### 04 — Escalate Blockers
When a task is blocked, stalled, or at risk, the Forge Agent escalates to the relevant people immediately — through in-app notification and optionally Slack. It does not wait for the next standup. However, it alerts without overriding: the assignee's judgment about how to resolve the block is always respected.

### 05 — Stay in Scope
The Forge Agent operates only within the spaces it has been explicitly granted access to. No cross-space actions, no reading from other teams' boards, no inferring tasks from emails unless the email integration is explicitly connected. Scope is always visible in settings.

### 06 — Minimal Footprint
When in doubt, the agent does less. One precise suggestion beats three speculative ones. If a signal could map to multiple tasks, the agent surfaces the ambiguity and asks rather than creating duplicates. A clean board is more valuable than a busy agent.

---

## Agent Interaction Examples

**Signal → Action:**  
GitHub PR opened for `feature/auth-refactor` → Forge detects it maps to ENG-041 → Proposes moving ENG-041 to "In Review" and adding PR link → User approves with one click

**User command:**  
"Triage the backlog by what unblocks the most tasks"  
Forge analyses dependency graph → re-ranks 14 backlog items → presents the new order for review → user approves 10, reorders 4

**Staleness alert:**  
"ENG-033 has had no commits in 4 days and is on the critical path for the March 28 release. Current assignee MR hasn't been active. Would you like to reassign or flag for discussion?"

**Oversize detection:**  
"ENG-041 has a complexity estimate above 40 story points. Teams using Volta typically see better delivery when tasks are split below 13 points. I can suggest a split into 3 tasks — want to review the breakdown?"

---

## Trust & Transparency Design

- **Agent Queue** is always the first column a user sees after their own tasks — it's not hidden in settings
- Every agent-created card has its source recorded: `from: GitHub issue #234`, `from: Slack message by @alex`
- Sprint health score shows its formula on hover — no black box percentages
- Users can pause the Forge Agent per-space without losing its history
- All dismissed suggestions are stored and can be used to fine-tune Forge's signals

---

*Volta — the board that keeps up with the work, not the other way around.*
