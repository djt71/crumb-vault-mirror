---
type: reference
domain: software
status: active
created: 2026-06-10
updated: 2026-08-10
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

> **FINAL — validated at VO-036** (M5 close-out, 2026-08-10). Drafted at
> VO-018; finalized after batches B1–B6 and the soak window
> (2026-07-04 → 2026-08-08, PASS on all exercised criteria — see
> `Projects/vault-optimization/validation-record.md`). The must-exist set
> below is the actual tree. This note is the canonical entrypoint for
> future maintenance.

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
(`Projects/vault-optimization/keep-set-manifest.md`, 199 rows, frozen at VO
close — the tree in git is authoritative for deltas thereafter). The
categories, with their load-bearing members:

**Constitution & conventions**
- `CLAUDE.md` (post-AS-025 rewrite) — workflow routing, risk tiers, behavioral
  boundaries
- `_system/docs/file-conventions.md` — top structural anchor (refs=89)
- `_system/docs/context-checkpoint-protocol.md`, session-end protocol,
  convergence rubrics, estimation calibration
- `_system/docs/overlays/` + overlay-index (8 overlays, all evidenced)

**Knowledge base (Tier-1 data — never surface, never in deletion scope)**
- `Sources/`, `Domains/`, the `#kb/` tag taxonomy, MOCs, personal-context
  (goal-tracker retired 2026-07-05 with attention-manager — operator delta,
  post-keep-set; priorities live in personal-context §Strategic Priorities)

**Skill surface (post-B5 consolidation + skills-library review 2026-07-07 —
11 skills)**
- Workflow skills: systems-analyst (absorbed learning-plan, VO B5),
  action-architect, audit (absorbed checkpoint, VO B5), peer-review,
  writing-coach, review-panel (cross-model escalation tier above the built-in
  /code-review; renamed from code-review 2026-07-07)
- Capture/hygiene: inbox-processor, vault-query, startup
- Knowledge-work: deck-intel (absorbed diagram-capture, VO B5), mermaid
- Retired post-keep-set (operator deltas, recorded in skills-library run-log):
  attention-manager → Cowork 2026-07-05 (`cowork-attention-handoff.md`);
  researcher, critic, sync, deliberation retired 2026-07-07 under the
  built-in-overlap policy (harness built-ins cover the need; supersedes the
  2026-06-10 critic/writing-coach merge-decline). feed-pipeline retired
  outright at AS-028.

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
