---
type: reference
domain: software
status: accepted
created: 2026-06-11
updated: 2026-06-11
skill_origin: null
confidence: high
tags:
  - kb/software-dev
  - architecture
  - decision
related_projects:
  - agentic-sunset
  - vault-optimization
amends:
  - "_system/docs/adr-crumb-v3-knowledge-store-identity.md (reactivation policy)"
topics:
  - moc-crumb-operations
---

# ADR: Vault Write Boundary for Scheduled Agents and Non-Crumb Surfaces

## Status

**Accepted** — 2026-06-11, operator sign-off in the work-surfaces session (same session
that produced [[work-surfaces]]). This ADR is the "new ADR" that the Crumb v3 identity
ADR requires before any in-vault automation write re-entry — a narrow, explicit
amendment of its reactivation policy. Everything else in the v3 ADR stands.

## Context

The Crumb v3 ADR ratified: future scheduled automation lives outside Crumb, reads the
vault, and never writes back — no re-entry without a new ADR. Agentic-sunset AS-023
immediately tests that line: the daily attention plan replacement is a scheduled agent
writing `_system/daily/{date}.md`, and the artifact needs vault residence because
tomorrow's run reads yesterday's plan (carry-forward escalation).

The governing lesson from the sunset: what killed the old system was not autonomous
writes per se but the **staging/promotion machinery built to make them safe** — that
machinery was the maintenance gravity. A policy that answers every scheduled write with
review infrastructure recreates the disease. The alternative adopted here: classify
writes by content and blast radius, permit the narrow safe class directly, and rely on
mechanical enforcement rather than bespoke machinery.

## Decision

Vault writes are classified by **content, not surface**. Four classes:

### Class 0 — Stateless consumables
Briefings, alerts, anything read-once with no downstream reader.
**Rule:** delivered outside-in (push/Gmail); never enter the vault. Anything else
quietly turns the delivery channel into a shadow vault.

### Class 1 — Operational consumables with state continuity
Type specimen: the daily attention plan — operator reads it, acts, and the next
scheduled run needs the prior artifact. Low blast radius (single directory, expiring
artifacts).
**Rule:** direct write permitted, into **enumerated drop-zone paths only**. The writer
commits immediately with a recognizable prefix; pre-commit vault-check enforces
conventions; session-startup `git pull` absorbs the writes into the next operator
session. No staging, no promotion, no review queue.

**Drop-zone registry** (the complete list; additions are explicit, logged operator
decisions):

| Path | Writer | Purpose |
|---|---|---|
| `_system/daily/` | AS-023 scheduled attention agent | Daily attention plan artifacts |

### Class 2 — Knowledge candidates
Signals, research output, anything aspiring to `Sources/`, `Domains/`, or a `#kb/` tag.
**Rule:** deposit into `_inbox/` only; enters the knowledge graph solely through
operator-triggered processing (inbox-processor). Scheduled agents and all surfaces may
*deposit*; nothing promotes without the operator on the trigger. This is the
already-ratified intake pattern, generalized to every surface.

### Class 3 — Everything else
Specs, projects, system docs, KB content, directives, philosophy.
**Rule:** **operator-present sessions only** — on either Crumb (Claude Code) or Cowork.
The restriction is against unattended writers, not against surfaces: an interactive
Cowork session with the operator driving qualifies. Cowork production work enters git
history through Crumb commit boundaries, so every edit passes vault-check on its way in.
No scheduled writer touches Class 3 paths, ever.

## Guardrails

1. **The drop-zone registry lives in this ADR and nowhere else.** It is short by
   design; a growing list is the smell of automation re-entry. Each addition is an
   explicit operator decision with a named writer and purpose.
2. **Drop zones are terminal or operator-pulled.** Nothing flows from a drop zone
   deeper into the vault without the operator in the loop. No promotion automation —
   that is the line the old staging machinery crossed.
3. **Mechanical enforcement over writer good behavior.** vault-check at the commit
   boundary is the guard, which matters increasingly as non-CLAUDE.md surfaces write.
4. **PR-mediated writes (Routines) need no exception** — review is structurally built
   in. They are, however, the wrong mandatory path for daily-cadence consumables:
   ceremony at that frequency suppresses adoption or rubber-stamps itself.

## Consequences

- AS-023 has a sanctioned write path; the policy tilts that pilot toward
  Cowork-scheduled (direct drop-zone write beats daily PR ceremony), with the final
  substrate call owned by the pilot after product re-verification (see
  [[work-surfaces]] § Verification List).
- The Crumb v3 reactivation policy now reads, in effect: *read-only except the Class 1
  registry and Class 2 deposit into `_inbox/`* — both narrow, enumerated, and
  operator-gated downstream.
- Future scheduled-agent migrations declare their write class at design time; Class 3
  is prohibited for them by construction.

## Related

- [[work-surfaces]] — roster and companion policies (memory ownership, Glean airlock)
- [[adr-crumb-v3-knowledge-store-identity]] — amended reactivation policy; all else stands
- `_system/docs/solutions/live-soak-beats-benchmark.md` — provenance of the
  machinery-not-writes lesson
- Projects/agentic-sunset — AS-023 (first Class 1 writer), AS-026/028 (inbox
  consolidation execution)
