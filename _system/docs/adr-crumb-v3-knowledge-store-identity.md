---
type: reference
domain: software
status: accepted
created: 2026-05-15
updated: 2026-06-10
skill_origin: compound
confidence: high
tags:
  - kb/software-dev
  - architecture
  - identity
  - decision
related_projects:
  - tess-v2
  - feed-intel-framework
  - mission-control
  - agentic-sunset
  - vault-optimization
supersedes:
  - "Implicit framing of Crumb as 'personal multi-agent OS'"
informed_by:
  - "Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md (2026-04-21)"
  - "_system/docs/solutions/live-soak-beats-benchmark.md"
  - "_system/docs/crumb-v2-system-health-assessment.md"
topics:
  - moc-crumb-operations
---

# ADR: Crumb v3 — Knowledge Store + Reasoning Substrate

## Status

**Accepted** — 2026-06-10, operator sign-off via vault-optimization VO-010
(decision-gate outcome: **proceed** — minor drift, no re-plan). The identity
statement and tier model are ratified as written; the 2026-05-15 snapshot
content below is refreshed by the Acceptance Refresh section, which prevails
where they differ. Original text retained as provenance.

## Acceptance Refresh (2026-06-10)

Accepted thirteen days and one project after drafting: agentic-sunset ("AS")
M1+M2 have executed most of Tier 3, and two operator decisions postdate the
draft (aggressive deletion — git history is the archive; dashboard stack
kept). Four refresh points:

1. **Tier 3 is largely executed or AS-owned.** Tess plists, bridge wiring,
   FIF pollers, Ollama: torn down in AS M1/M2. Remainder (CLAUDE.md diff,
   `_openclaw`/`_tess`/`_staging` archival, skills + memory cleanup) is AS
   M6/M7 scope per XD-027. This ADR ratifies the *category*; it does not
   authorize work owned elsewhere.
2. **Tier 2 is narrowed.** "Keep, dormant" predates the aggressive-deletion
   decision and is superseded by it: the working tree retains only items
   qualifying as **canonical-reference or compound-provenance** (the
   vault-optimization VO-006 retention rule); everything else in the original
   Tier 2 list lives in git history. Item-level dispositions belong to the
   keep-set manifest (VO-002), not this ADR.
3. **Mission Control: runtime shed, stripped dashboard kept** (operator
   decision 2026-06-10, reconciling the original "shed" proposal with the AS
   decision to keep the dashboard stack). MC-as-runtime-ops-manager is gone;
   dashboard/vault-web/cloudflared survive as a knowledge-work viewing
   surface. Individual panels face the VO-002 evidence rubric — dead runtime
   panels (service health, queues) are stripped in vault-optimization.
4. **Tier 1's skill enumeration is presumptive, not binding.** The tier
   defines the *category* (knowledge-work skills stay); whether each of the
   17 listed skills stays, merges, or goes is decided by the VO-002 evidence
   rubric (SkillsBench: focused beats exhaustive).

**Open questions, answered at acceptance:**
1. *Feed intel scheduled aspect:* answered by events — pollers decommissioned
   (AS); manual-drop/NotebookLM intake stays open (standing operator
   feedback). Ratified.
2. *Mission Control specifics:* refresh point 3 above.
3. *Reactivation policy:* ratified as hypothesized — future scheduled
   automation lives **outside Crumb** in a separate runtime that reads the
   vault and never writes back. No in-vault automation re-entry without a new
   ADR.
4. *Tess memory entries:* ownership settled — AS-029 owns memory cleanup
   (joint-surface contract, VO-002 Appendix A). Model-behavior memories
   (Grok/Kimi fabrication records) are confirmed keeps — durable model
   knowledge, actively in use (review-panel calibration watch). Ops memories
   already flagged decommissioned pending AS-029 rewrite.

**Implications addenda:** project closures (tess-v2, feed-intel-framework,
mission-control phase changes) are AS-030–032 scope, not triggered by this
acceptance. Liberation-directive references in CLAUDE.md are **not**
Tess-specific (operator strategy, independent of the agentic layer) — they
survive the CLAUDE.md rewrite.

## Decision

**Crumb is a durable knowledge store and reasoning substrate. It is not an automation platform.**

The Tess / OpenClaw / Hermes line is reclassified from "incomplete migration" to "retired architectural branch." No further development on autonomous orchestration, scheduled execution, bridge dispatch, or vault-as-runtime-bus. Work continues on knowledge work, project workflows, and lightweight skills that help the operator think, write, analyze, and organize.

## Context

Crumb began as a personal Obsidian vault. Over 2026 Q1–Q2 it accumulated a substantial operational scaffold:

- ~15 Tess v2 launchd services
- Bridge dispatch protocol for cross-agent handoff
- Staging/promotion machinery for autonomous vault writes
- Feed intel framework with scheduled pollers
- Mission Control dashboard for runtime ops
- 8 overlays, 20 skills, multi-agent orchestration doctrine

This scaffold was built in the belief that Crumb could serve as the substrate for an autonomous personal multi-agent OS. Three accumulated pieces of evidence argue against that belief:

1. **Amendment AC (2026-04-21):** Tess's orchestrator role was retracted on live-evidence grounds. Two peer reviews and extensive synthetic evaluation had certified the architecture; only live operator soak surfaced the mismatch. The captured pattern (`_system/docs/solutions/live-soak-beats-benchmark.md`) explicitly notes that GPT-5.4 swap surfaced the role *itself* as inadequate, not just the model choice.

2. **Maintenance gravity outpacing return.** The 2026-04-20 audit and subsequent staleness data show operational machinery (services, plists, bridge queues) accumulating maintenance debt while the actual operator workflow continues to be: open Claude Code, work in the vault, write knowledge, get reviews. The autonomous tier has not delivered observed value commensurate with its surface area.

3. **Ceremony budget principle (CLAUDE.md):** "Reducing ceremony is higher leverage than adding capability." The current state violates this — every new orchestration capability has required new ceremony, while the underlying knowledge-work surface (specs, designs, run-logs, KB notes, deliberations) has been the durable value generator throughout.

The decision named here is the natural conclusion: stop carrying the operational skeleton; preserve the durable lessons.

## Scope

### What Crumb v3 Is

- Durable knowledge store: specifications, plans, decisions, run-logs, KB notes, summaries
- Reasoning substrate: workflows (SPECIFY → PLAN → TASK → IMPLEMENT and variants), phase transition gates, compound engineering
- Lightweight skill surface for knowledge work: writing-coach, systems-analyst, action-architect, researcher, critic, peer-review, deliberation, audit, inbox-processor, code-review, vault-query
- Vault-protecting checks: vault-check, hooks, session-startup, sync
- Discovery / capture / hygiene: feed-pipeline as a *skill* (operator-triggered intake processing), inbox-processor, audit

### What Crumb v3 Is Not

- Not a runtime host for scheduled services
- Not a bridge / dispatch / staging system for autonomous agents
- Not the system of record for operational state (logs, queues, runtime metrics)
- Not an orchestrator of multi-agent execution beyond user-triggered skill dispatch

### Tier Categorization

Three tiers, not a binary keep/shed:

**Tier 1 — Keep, Active**
- Knowledge-work skills (writing-coach, systems-analyst, action-architect, researcher, critic, peer-review, deliberation, audit, inbox-processor, code-review, vault-query, attention-manager, learning-plan, simplify, mermaid, diagram-capture, deck-intel)
- Project workflow primitives (specifications, designs, plans, run-logs, progress-logs, project-state.yaml)
- Knowledge base (`Sources/`, `Domains/`, `kb/` tag system)
- Vault hygiene (vault-check, sync, audit, session-startup hook)
- Compound engineering (`_system/docs/solutions/`, failure-log, convergence rubrics)
- Feed intel intake (`_openclaw/inbox/` as passive drop zone) and feed-pipeline skill (operator-triggered processing)

**Tier 2 — Keep, Dormant (historical record, no further development)**
*(Narrowed at acceptance — see Acceptance Refresh #2: working tree keeps only canonical-reference/compound-provenance items; the rest lives in git history.)*
- Tess v2 specs, designs, run-logs, decision records, eval results
- Feed intel framework project artifacts (specs, designs)
- OpenClaw colocation spec and reference docs
- Captured patterns from the Tess/OpenClaw era (`live-soak-beats-benchmark`, `staged-spike-with-bail`, `lenient-parsing-before-evaluation`, SOUL.md rules-as-patterns)
- Mission Control project artifacts (design docs)
- These do not decay if untouched and are valuable as compound-engineering provenance

**Tier 3 — Remove (decaying operational surface)**
*(Largely executed by agentic-sunset M1/M2 as of acceptance; remainder AS-owned — see Acceptance Refresh #1.)*
- Tess v2 launchd services (~15 plists)
- Bridge dispatch protocol active wiring (BRIDGE DISPATCH stage output, bridge queues)
- Staging / promotion machinery for autonomous vault writes
- FIF SQLite poller infrastructure and scheduled jobs
- Mission Control dashboard runtime (and the audit-status JSON I write for it — needs reassessment)
- Subagent execution-tier delegation infrastructure (the Sonnet-routing for execution-tier skills, if not actively earning its keep)
- Service registration plumbing in project-state.yaml (`services:` field)
- Tess harness validations VAL-001/002/003 (see disposition below)

## Boundary Case Decisions

The three ambiguous surfaces, each with proposed disposition and rationale. Operator to confirm or adjust.

### 1. Feed Intel Pipeline

**Proposal:** Split.

- **Keep:** `_openclaw/inbox/` as a passive intake (RSS, manual drops, NotebookLM exports), `feed-pipeline` skill as an operator-triggered processing tool, KB-tagging on outputs. This is knowledge work.
- **Shed:** Scheduled RSS pollers, FIF SQLite infrastructure, automated digest delivery, dashboard health panel.

**Rationale:** The intake is genuinely useful for knowledge accumulation. The operator memory `feedback-feed-intel-stays-open.md` explicitly says intake stays open. But the *scheduled* aspect is operational automation that fits the retirement decision. The skill-based processing is knowledge work that fits Crumb v3.

### 2. Mission Control Dashboard

**Proposal:** Shed. *(Adjusted at acceptance: runtime shed, stripped dashboard kept — see Acceptance Refresh #3.)*

**Rationale:** Mission Control exists to manage runtime ops. If Crumb v3 has no runtime ops to manage, the dashboard is a solution without a problem. The audit-status JSON written by the audit skill (step 17) should be removed from the audit procedure when MC is decommissioned.

**Open question:** Are there elements of MC the operator finds valuable for knowledge-work (e.g., the brainstorm queue surface, the feed-intel queue surface)? If yes, those specific surfaces could survive in a stripped form. To confirm before removal.

### 3. Dispatch Skills (peer-review, deliberation, code-review, researcher)

**Proposal:** Keep, active (Tier 1).

**Rationale:** These dispatch to external LLMs, but they are user-triggered, knowledge-work tools — they assist with reviewing artifacts, getting second opinions, validating research. They are not orchestrators of autonomous execution. The distinction: a skill the operator runs to get help thinking is knowledge work; a service that runs autonomously and writes to the vault is automation. The dispatch skills are the former.

## VAL Disposition (Tess Harness Validations)

VAL-001, VAL-002, VAL-003 are validations of SOUL.md rules added after the 2026-04-09 confabulation incident. Three options were considered:

- Stage scenarios deliberately
- Watch passively
- Close as superseded

**Proposal:** Close all three as **superseded** by this ADR.

**Rationale:** The validations test whether SOUL.md rules hold under pressure for Tess in her orchestrator role. If Tess's orchestrator role is retired, the rules are no longer load-bearing in production. The rules and the patterns they encoded remain as historical record (Tier 2). Closing as superseded preserves provenance while halting the staleness clock.

If Tess is later reactivated in any reduced role, the validations can be reopened with explicit re-trigger conditions.

## What Stays Open (Deliberately)

- The exact scope of CLAUDE.md rewrite — separate work, scheduled as Pass 2 of the cleanup
- Disposition of individual `_openclaw/`, `_tess/`, `_staging/` directory contents — separate work, sequenced after this ADR is accepted
- Whether to retain any sub-component of the dispatch infrastructure (e.g., the `bridge-dispatch-protocol.md` doc itself, vs. the runtime wiring it describes)
- Reactivation policy: if operator wants scheduled automation in the future, where does it live? (Hypothesis: outside Crumb, in a separate `~/openclaw/` runtime project that *reads* Crumb but does not write back. Not committed.)

## Implications

### For Active Projects

- **tess-v2:** Move from `phase: TASK` (or wherever it currently sits) to `phase: superseded`. This is a new phase value; current schema only has `phase: DONE`, `phase: ARCHIVED`, `phase: cancelled`. Add `superseded` to the schema, or use `cancelled` with a `superseded_by:` field pointing to this ADR.
- **feed-intel-framework:** Already `phase: DONE`. Verify any active operational artifacts are categorized into Tier 1 (keep) or Tier 3 (remove) per this ADR; archive the project per CLAUDE.md archival protocol.
- **mission-control:** Move to `phase: superseded` (or `cancelled` with `superseded_by:`).
- **All other active projects:** Continue. None depend on the retired runtime.

### For CLAUDE.md

CLAUDE.md retains:
- Workflow routing (SPECIFY → PLAN → TASK → IMPLEMENT and variants)
- Phase Transition Gate references
- Project Creation Protocol (without service registration step)
- Context Rules, File Access, Plan Mode
- Behavioral Boundaries
- Project Archival, Completed Project Guard
- Compound Engineering
- Skills & Agents (revised list)
- Overlay Routing
- Subagent Validation
- Convergence, Hallucination Detection
- Session Startup, Session Management, Session-End Sequence

CLAUDE.md removes:
- "Multi-Agent OS" framing in the header
- Strategic directive / liberation directive references *if* those were Tess-specific (verify before removal)
- Project Creation step 3c (service registration)
- Subagent Configuration model routing for execution-tier skills if delegation infrastructure is removed
- Bridge Dispatch Stage Output section

### For Tess Memory

The memory entries about Tess operations (`project-tess-v2-k2-route-retest`, `model-kimi-recovery-fabrication`, `model-grok-fabrications`, `ao-python-decision-engine`, `openclaw-ops`, `fif-operations`) should be reviewed:
- Operations memories → archive or mark `superseded` per ADR
- Model behavior memories (Grok fabrications, Kimi fabrications) → keep, these are durable knowledge about model behavior independent of Tess's role

## Sequencing

This ADR is **Pass 1: Decision**. No code or infrastructure changes are made by accepting it.

**Pass 2: Cleanup** is sequenced after acceptance, as three separate work items:

1. **CLAUDE.md revision** — careful pass, separate session
2. **Runtime machinery removal** — services, plists, bridge wiring, staging machinery (`_openclaw/`, `_tess/`, `_staging/` directory dispositions)
3. **Skill / overlay pruning** — remove or simplify skills/overlays tied exclusively to the retired runtime

Each Pass 2 work item is its own decision and may warrant its own ADR or project.

## Acceptance Criteria

For this ADR to be considered accepted:

- [x] Operator confirms the identity statement *(2026-06-10, VO-010 — ratified as written)*
- [x] Operator confirms or adjusts the three boundary case decisions *(2026-06-10: feed intel split confirmed (pollers already gone); Mission Control adjusted — runtime shed, stripped dashboard kept; dispatch skills keep confirmed)*
- [x] Operator confirms VAL disposition *(2026-06-10: VAL-001/002/003 closed as superseded)*
- [x] External review *(satisfied indirectly: the ADR-as-baseline was reviewed by the 4-model panel twice — vault-optimization specification round 1 and action-plan round 1, both 2026-06-10; no direct ADR dispatch deemed necessary)*
- [x] Pass 2 work items scheduled *(agentic-sunset AS-025–032 = CLAUDE.md revision + runtime/directory removal; vault-optimization VO-011–036 = skill/overlay pruning and the rest — both projects active with task-level gates per XD-027)*

## Open Questions for the Operator

1. **Feed intel scheduled aspect:** Are scheduled RSS pollers earning their keep, or is the manual-drop / NotebookLM intake path enough?
2. **Mission Control specifics:** Any specific MC surface (brainstorm queue, feed queue) you want preserved before the dashboard is decommissioned?
3. **Reactivation policy:** If you want scheduled automation later, what's the principled home for it — separate repo outside the vault, or a re-scoped subdirectory within Crumb with hard boundaries?
4. **Tess memory entries:** Archive in place, move to a "retired" namespace, or delete entirely?

## Provenance

This ADR was drafted by Crumb (Claude Opus 4.7) in a 2026-05-15 audit follow-up session, after the operator surfaced a summary articulating the identity shift. The summary cohered with patterns already captured in the vault, particularly Amendment AC and `live-soak-beats-benchmark.md`. The decision is the operator's; this document is the artifact of the decision.

## Related

- `_system/docs/crumb-design-spec-v2-4.md` — Crumb v2 design spec (will be superseded in part by Crumb v3 work)
- `_system/docs/crumb-v2-system-health-assessment.md` — health assessment that informed ceremony budget principle
- `_system/docs/solutions/live-soak-beats-benchmark.md` — captured pattern on live-soak primacy
- `Projects/tess-v2/design/spec-amendment-AC-execution-surfaces.md` — orchestrator role retraction
- `Projects/tess-v2/design/tess-harness-plan-tracking.yaml` — VAL items to be closed as superseded
