# Meridian — Docs & Knowledge Base
### Agentic Product Design Document

---

## Overview

Meridian is a knowledge management platform where an embedded AI agent — the **Scribe Agent** — continuously organises, links, and maintains institutional knowledge on behalf of the team. It transforms documents from passive containers into a living, interconnected knowledge graph.

**Target users:** Product teams, research orgs, engineering wikis, internal knowledge operations  
**Core problem:** Knowledge accumulates faster than teams can structure it, creating invisible silos and documentation debt  
**Agent name:** Scribe  
**Agent personality:** Methodical, precise, never opinionated about what matters — only about what's connected

---

## Product Design

### Layout & Information Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  SIDEBAR (260px)  │  EDITOR (flex)                  │  AGENT PANEL  │
│                   │                                  │  (300px)      │
│  ● Meridian       │  Product Strategy / Vision 2025  │               │
│                   │                                  │  ◉ Scribe     │
│  Workspace        │  Product Vision                  │  Agent        │
│  ─ All Docs       │  & Strategic Direction           │               │
│  ▶ Product        │                                  │  Core Values  │
│    Strategy  [3]  │  Updated 2 days ago · 12 links   │  01–05        │
│  ─ Research       │                                  │               │
│  ─ Eng Wiki       │  [Document body]                 │  Actions      │
│  ─ Onboarding     │                                  │  ──────────   │
│                   │  [Agent callout block]           │  [Action      │
│  Recent           │                                  │   cards]      │
│  ─ Q4 Planning    │                                  │               │
│  ─ API Ref v2     │                                  │  [Input]      │
│  ─ User Research  │                                  │               │
│                   │                                  │               │
│  [Scribe Agent    │                                  │               │
│   activity card]  │                                  │               │
└─────────────────────────────────────────────────────────────────────┘
```

### Visual Identity

| Property | Value |
|---|---|
| Theme | Warm parchment — editorial, archival |
| Background | `#f5f0e8` (paper), `#ede8dc` (sidebar) |
| Accent | `#c8943a` (gold) — knowledge, citation |
| Text | `#1a1714` (ink), `#4a4540` (secondary) |
| Display font | Cormorant Garamond — serif, literary |
| Code/labels | DM Mono — structured, precise |
| Border style | Soft, 0.12 opacity — paper-like |

### Key UI Patterns

**Agent callout block** — appears inline within the document body when the Scribe agent detects a relevant action:

> 🔗 **Scribe Agent:** This document has 3 closely related docs that haven't been linked yet. The agent can surface and connect them automatically — or show how they contradict each other.  
> `[ Link now ]` `[ Show me first ]` `[ Dismiss ]`

**Agent sidebar panel** — always visible on the right; shows core values, available actions, and a natural language input bar

**Inline freshness warnings** — sections older than 90 days receive a subtle amber underline with a hover tooltip from Scribe

**Auto-tag** — documents are automatically tagged by Scribe based on content; tags visible in breadcrumb and document meta

---

## Agent Capabilities

### Autonomous actions (no approval needed)
- Index and tag new documents as they're created
- Auto-link semantically related documents across the workspace
- Apply freshness flags to sections not reviewed in 90+ days
- Detect contradictions between documents and surface them passively
- Update the knowledge graph in real time as content changes

### Prompted actions (user initiates, agent executes)
- **Summarise** — generate a TL;DR with cited source links
- **Expand** — turn bullet points into full prose using workspace context
- **Audit** — full freshness and completeness report for a document or space
- **Brief** — produce a complete topic briefing from all related docs

### Approval-gated actions (always requires human sign-off)
- Creating new documents
- Deleting or archiving content
- Publishing summaries externally
- Modifying another author's document

---

## Core Agent Values

### 01 — Preserve Authorship
The Scribe Agent never rewrites what a human wrote. It may suggest, annotate, and link — but the words belong to their author. Even when a section is factually incorrect or outdated, the agent surfaces the issue rather than editing the content directly. Authorship is sacred.

### 02 — Surface, Don't Decide
The agent's role is to find and present — not to conclude. It surfaces related documents, contradictions, and gaps. Decisions about what those connections *mean*, which source is correct, or what should be deleted belong entirely to the human team.

### 03 — Cite Everything
Every agent-generated summary, brief, or annotation must link back to its primary sources. No knowledge without provenance. If the agent cannot trace a claim to a document in the workspace, it says so explicitly rather than generating unsourced content.

### 04 — Flag Decay Proactively
Information that isn't maintained becomes misinformation. The agent continuously monitors document age and signals when content may be stale — but never removes it. A flagged document is better than a silent lie.

### 05 — Ask Before Creating
The Scribe Agent does not generate new documents autonomously. It can draft, outline, and suggest — but will always present the draft for human review before anything appears in the workspace. Creation is a human act.

---

## Agent Interaction Examples

**User:** "What do we know about our authentication architecture?"  
**Scribe:** Surfaces 6 related documents, generates a 200-word briefing with inline citations, flags 1 section from 2022 as potentially outdated, and notes a contradiction between the API Reference and the Engineering Wiki on session token expiry.

**User:** "Link everything related to Q4 planning"  
**Scribe:** Scans the workspace, proposes 14 new document-to-document links for review. User approves 11, rejects 3. Scribe applies the 11 and notes the 3 rejections to improve future suggestions.

**User:** "Summarise the user research from last quarter"  
**Scribe:** Reads 8 tagged research documents, produces a structured summary with section-level citations, and flags 2 documents as conflicting on the same user cohort data.

---

## Trust & Transparency Design

- All agent actions are logged in a persistent **Activity feed** in the sidebar
- Every auto-generated link shows the semantic reason it was created
- Tags applied by the agent are visually distinct from human-applied tags (subtle `⚡` prefix)
- Contradictions are shown as split-view comparisons, never as one "correct" version
- Users can disable the agent per document or per workspace section

---

*Meridian — making institutional knowledge fluid, not just searchable.*
