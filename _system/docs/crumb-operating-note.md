---
type: reference
domain: software
status: draft
created: 2026-06-10
updated: 2026-07-04
skill_origin: none
confidence: high
tags:
  - kb/software-dev
  - architecture
  - identity
  - operations
related_projects:
  - vault-optimization
  - agentic-sunset
informed_by:
  - "_system/docs/adr-crumb-v3-knowledge-store-identity.md"
  - "Projects/vault-optimization/keep-set-manifest.md"
topics:
  - moc-crumb-operations
---

# Crumb — Core-Functionality Operating Note

> **DRAFT — pending VO-036.** Drafted at vault-optimization VO-018 (M2, before
> any deletion batch executed). The must-exist set below reflects manifest
> *dispositions*, some still proposals frozen at M3 changesets. Finalized at
> VO-036 (M5 close-out) after batches B1–B6 and the soak period, when the
> keep-set is the actual tree. This note is the canonical entrypoint for
> future maintenance once finalized.

## 1. What Crumb Is (Identity)

**Crumb is a durable knowledge store and reasoning substrate. It is not an
automation platform.** (v3 ADR, accepted 2026-06-10 —
`adr-crumb-v3-knowledge-store-identity.md`, which owns the full rationale.)

Concretely, Crumb is:

- **A knowledge store** — specifications, designs, decisions, run-logs, KB
  notes (`Sources/`, `Domains/`, `#kb/` taxonomy), summaries. The vault is the
  single source of truth; the work persists here, not in chat history.
- **A reasoning substrate** — phased workflows (SPECIFY → PLAN → TASK →
  IMPLEMENT and lighter variants), phase-transition gates, compound
  engineering, convergence rubrics. Structure that makes multi-session work
  trustworthy.
- **An operator-triggered skill surface** — knowledge-work skills the operator
  invokes to think, write, analyze, review, and organize. A skill the operator
  runs to get help thinking is knowledge work; a service that runs
  autonomously and writes to the vault is automation, and automation does not
  live here.

Git history is the archive. Deleted content is retrievable from the remote;
the working tree carries only what is active, canonical-reference, or
compound-provenance.

## 2. What Must Exist for Crumb to Remain Itself

The item-level source of truth is the keep-set manifest
(`Projects/vault-optimization/keep-set-manifest.md`, 199 rows; after VO close,
the final manifest state in git). The categories, with their load-bearing
members:

**Constitution & conventions**
- `CLAUDE.md` (post-AS-025 rewrite) — workflow routing, risk tiers, behavioral
  boundaries
- `_system/docs/file-conventions.md` — top structural anchor (refs=89)
- `_system/docs/context-checkpoint-protocol.md`, session-end protocol,
  convergence rubrics, estimation calibration
- `_system/docs/overlays/` + overlay-index (8 overlays, all evidenced)

**Knowledge base (Tier-1 data — never surface, never in deletion scope)**
- `Sources/`, `Domains/`, the `#kb/` tag taxonomy, MOCs, goal-tracker
  (refs=81), personal-context

**Skill surface (post-B5 consolidation)**
- Workflow skills: systems-analyst (absorbed learning-plan, VO B5),
  action-architect, audit (absorbed checkpoint, VO B5), peer-review, critic,
  writing-coach (critic/writing-coach merges declined by operator 2026-06-10),
  deliberation, researcher, code-review
- Capture/hygiene: inbox-processor, vault-query, sync (feed-pipeline retired
  outright at AS-028)
- Knowledge-work: attention-manager, deck-intel (absorbed diagram-capture,
  VO B5), mermaid

**Vault-protecting machinery**
- `vault-check.sh`, `session-startup.sh`, skill-preflight hook, the backup
  chain (vault-backup, drive-sync, mirror-sync + filter) and its launchd
  plists
- The kept viewing stack: dashboard/vault-web/cloudflared (operator decision
  2026-06-10 — knowledge-work viewing surface only; runtime-ops panels
  stripped)

**Compound engineering**
- `_system/docs/solutions/` (21+ live entries), failure-log, the compound
  evaluation step at every phase transition

**Project records**
- `Projects/*/` project-state, run-logs, progress-logs — provenance for every
  decision; archival is operator-initiated only

## 3. What Is Deliberately No Longer Part of Crumb

Excluded by decision, not by neglect — do not rebuild without a new ADR:

- **Autonomous orchestration & dispatch** — Tess/OpenClaw/Hermes runtime,
  bridge dispatch, staging/promotion machinery for autonomous vault writes,
  a2a/brief/capability schemas. Retired architectural branch (v3 ADR;
  agentic-sunset executed).
- **Scheduled execution inside the vault** — pollers, cron-driven vault
  writers, runtime health-checkers. Future scheduled automation lives
  *outside* Crumb in a runtime that reads the vault and never writes back; no
  in-vault automation re-entry without a new ADR (acceptance refresh Q3).
- **Runtime-ops management** — Mission Control as ops manager, service-health
  panels, runtime queues, operational state-of-record. The dashboard survives
  only as a stripped knowledge-work viewing surface.
- **The skill-workflows documentation layer** — zero-consumer orphan
  (VO-015); capability docs without consumer wiring violate the ceremony
  budget principle.
- **Dormant-marking as a retention strategy** — superseded by aggressive
  deletion: working tree keeps canonical-reference/compound-provenance only;
  everything else is git history.
- **Executed specs/change-specs as working-tree files** — provenance lives in
  git, not the tree.

## 4. Future-Addition Decision Rubric

Before adding any capability, skill, pipeline, or document layer to Crumb,
answer all four (spec deliverable #2, vault-optimization):

1. **Does it serve knowledge storage or the reasoning substrate directly?**
   If it serves automation, scheduling, or runtime ops, it belongs outside
   Crumb (read-only consumer of the vault) — not here.
2. **Is it core, support, or residue?** Core: the operator's thinking/writing
   workflow breaks without it. Support: protects or feeds core (backup,
   hygiene, intake). Residue: exists because something else once needed it.
   Only core and support get added; name which one and what consumes it.
3. **Net maintenance burden vs demonstrated value?** New primitives increase
   operational surface — justify against maintenance gravity *with evidence*,
   not anticipated value. Prefer a trial period with a recorded review date
   over a permanent addition.
4. **Can a retained primitive satisfy the need?** Check the manifest keep-set
   and the merge history (obsidian-cli→vault-query, excalidraw→mermaid,
   critic/writing-coach→peer-review, checkpoint→audit, learning-plan→
   systems-analyst) before creating anything. Heavy ceremony on an existing
   feature masquerades as a missing feature — reduce ceremony first
   (CLAUDE.md Ceremony Budget Principle).

A proposed addition that fails any question is declined or re-homed outside
the vault. Additions that pass still follow the Primitive Creation Protocol
(operator approval before files are written).
