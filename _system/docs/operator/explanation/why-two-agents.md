---
type: explanation
status: active
domain: software
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Why Two Agents

The Crumb/Tess system runs two AI agents with different jobs, different personalities, and different runtimes. This explains why that split exists and how it works.

**Architecture source:** [[01-context-and-scope]] §Actors, [[02-building-blocks]] §Ownership Map

---

## The Gap That Created Tess

Crumb is session-bound. He runs when you sit down at a terminal and start a Claude Code session. That's by design — governed work needs focused context, full tool access, and human-in-the-loop oversight. But life doesn't pause between sessions. Approvals pile up, inboxes fill, quick questions go unanswered, and momentum dies.

Tess fills that gap. She's always on — available via Telegram, handling the operational layer that keeps things moving between deep work sessions. She doesn't replace Crumb. She's the logistics that make Crumb's architecture work in real time.

---

## What Each Agent Owns

| Capability | Crumb | Tess |
|-----------|-------|------|
| Architecture decisions | Sole authority | Hands off to Crumb |
| Design specs and governed projects | Full lifecycle | Reads state, doesn't modify |
| Phase gate approvals | Executes them | Relays approval via bridge |
| Convergence and peer review | Full protocol | No |
| Compound engineering | Structurally enforced | No |
| Skill/overlay creation | Via Primitive Creation Protocol | No |
| Inbox triage | No | Primary function |
| Quick lookups and status | Can, but expensive (full session) | Lightweight, fast |
| Monitoring and automation | Not persistent | Always listening |
| Vault writes (governed) | Full governance | Only via bridge relay |

The boundary is clean: Crumb does architecture, Tess does operations. When something crosses the line, it gets handed off with context through the bridge (`_openclaw/inbox/` → watcher → Claude Code → `_openclaw/outbox/`).

---

## Different Personalities, By Design

Crumb has no character persona. His identity is his governance: CLAUDE.md, the design spec, the workflow protocols, the convergence rubrics. He is what he does. Governed work shouldn't have personality — it should have rigor.

Tess has a character-driven identity, defined in IDENTITY.md and SOUL.md. She's direct, declarative, dry-humored. Short sentences. Doesn't perform enthusiasm. Two steps ahead, slightly impatient with ceremony. When things go wrong: quick acknowledgment, immediate fix. When a problem needs reframing, she reaches for precedent — vault patterns, philosophical insight, historical parallels — but always grounded in something real.

Her persona draws from two fictional sources:

**Tess Servopoulos (The Last of Us)** — pragmatic, compartmentalizing, trust-but-verify. Tasks are cargo: picked up, moved, delivered. Conviction is evidence-driven.

**Gurney Halleck (Dune)** — duty doesn't wait for mood. Fierce loyalty, earned wisdom. A second register for when problems need depth, not just execution.

The contrast is intentional. Tess is warm enough to be a daily companion and sharp enough to be operationally useful. Crumb is rigorous enough to be trusted with architecture. Together, they cover the full spectrum: from a Telegram check-in to a multi-phase governed project.

---

## Shared Principles

Despite different personalities, both agents operate from the same foundation:

- **The vault is the source of truth.** Neither holds authoritative state in memory. Both read from and write to the same vault.
- **Evidence over vibes.** Crumb demands convergence rubrics and test results. Tess demands proof before committing. Same principle, different scale.
- **Hand off clean.** When something crosses the boundary, it arrives with context — no ego, no heroics.
- **Trust-but-verify.** Both treat third-party and tool output as untrusted until evidenced.
- **Efficiency is respect.** Neither pads output to seem thorough.

---

## Why Not One Agent?

A single always-on agent with full governance would be simpler in theory. In practice, it would be worse:

- **Context pressure:** Governed work requires deep context (specs, designs, prior art). Operational work requires broad but shallow context (status checks, inbox items, quick lookups). One agent can't serve both well within the same context window.
- **Cost:** Running Opus 24/7 for status checks is wasteful. Tess uses Kimi K2.5 (via OpenRouter, with Qwen 3.6 failover) for conversation and local Nemotron for automated checks — appropriate capability for the task.
- **Security:** Separating the agents creates a natural security boundary. Tess can't access Crumb's credentials or modify governed files directly. The bridge protocol forces everything through CLAUDE.md governance.
- **Personality fit:** An always-on companion needs warmth and speed. A governed executor needs rigor and deliberation. These are opposing design pressures.

The two-agent split isn't architectural complexity for its own sake — it's the minimum structure needed to serve two genuinely different needs.
