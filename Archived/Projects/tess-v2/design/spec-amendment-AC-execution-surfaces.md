---
project: tess-v2
type: design-input
domain: software
status: draft
created: 2026-04-21
updated: 2026-04-21
source: anthropic-consolidation-hypothesis.md (2026-04-21); live operational evidence 2026-03-27 through 2026-04-21 (Kimi K2.5 orchestration trial, GPT-5.4 runtime swap); operator-directed architectural reframe 2026-04-21
supersedes_portion_of: spec-amendment-Z-interactive-dispatch.md
tags:
  - spec-amendment
  - orchestration
  - execution-surfaces
  - architecture-retraction
  - liberation-directive
---

# Spec Amendment AC: Orchestrator Role Retraction and Execution Surface Division of Labor

## Problem Statement

Amendment Z (2026-04-04, peer-reviewed 2026-04-06) established Tess as the
dispatch authority for all execution modes — autonomous *and* interactive —
with Crumb/Claude Code as the interactive executor reading Tess's dispatch
queue. The architectural thesis: "Tess is the orchestrator in name.
Crumb is the orchestrator in practice. The hierarchy is inverted. Z
corrects the inversion."

Two weeks of live operation have falsified that thesis for the operator's
standard of use.

### Evidence

1. **Kimi K2.5 as orchestrator runtime (2026-03-30 onward):** Scored 76/95
   on the TV2-Cloud battery and 87/100 on a subsequent synthetic battery.
   Live operator use revealed unacceptable latency and reasoning quality
   for the orchestration role despite passing synthetic evaluation.
   Documented in `model-hermes-crumb-evaluation-frame-2026-04-20.md`:
   benchmark score does not predict orchestrator acceptability; live soak
   is the governing signal.

2. **GPT-5.4 runtime swap (2026-04-20→21):** Tess orchestrator moved from
   Kimi K2.5 (OpenRouter) to GPT-5.4 via OpenAI API. Swap trigger was
   persistent operator-judged inadequacy of the orchestration output under
   real workloads. Swap confirms the pattern — the issue is not model
   choice but the role itself: autonomous orchestration of operator-facing
   strategic work does not meet the operator's bar regardless of which
   cloud frontier model drives Tess.

3. **Preferred working mode:** The operator prefers interactive work via
   claude.ai (web chat) and Claude Code (via Crumb and the vault).
   Two weeks of use have stabilized this preference. Strategic thinking,
   spec authorship, and ambiguous decomposition happen in interactive
   surfaces. Autonomous orchestration by Tess is not the desired default.

4. **Anthropic consolidation hypothesis surfacing (2026-04-21):** Web
   Opus conversation triggered a broader review of Anthropic's execution
   surface inventory (Cowork, Routines, Channels, Remote Control). The
   inventory was structured around the hypothesis that Tess should sunset.
   Verification pass kept Tess; but the pass also surfaced that the live
   evidence independently argues against Tess's orchestrator role, even
   with Tess retained. See `_system/docs/anthropic-consolidation-hypothesis.md`.

### Implication

Amendment Z's load-bearing architectural decision — **AD-013: Interactive
Dispatch Authority** — must be retracted. Tess is not the dispatch authority
for operator-interactive work. The hierarchy Z sought to establish (Tess
over Crumb) is rejected on live-evidence grounds. Z's supporting machinery
(dispatch queue schema, session report schema, claims file, startup hook
integration) survives, but with the writer role inverted — upstream
operator-facing surfaces write; Crumb reads.

## Architectural Decisions

### AD-017: Orchestrator Role Retraction (retires AD-013)

Tess is not the dispatch authority for operator-interactive work. Tess's
role is scoped to **autonomous execution of scheduled launchd services**
(the 15 `com.tess.v2.*` LaunchAgents currently managed by dispatch.sh +
the tess-v2 contract runner). Tess does not plan operator-facing work,
does not maintain a dispatch queue for interactive sessions, and does
not run an autonomous planning cycle.

This reverses AD-013. It does not retract:
- **AD-014 (Structured Session Reporting)** — the session report schema
  survives, re-homed per AD-018 below.
- **AD-008 (Staging → Promotion Write Model)** — unchanged; still governs
  autonomous executors writing to isolated staging.

### AD-018: Execution Surface Division of Labor

The system is organized as a four-level stack, with each surface owning
a bounded set of responsibilities:

```
┌──────────────────────────────────────────────────────────────────┐
│  Level 1: OPERATOR (Danny)                                       │
│  Strategic direction, override authority, all cross-surface      │
│  decisions. Carries context between levels.                      │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│  Level 2: UPSTREAM OPERATOR SURFACES                             │
│                                                                  │
│  • claude.ai (web chat)     — strategic thinking, scoping,       │
│                                ambiguous decomposition           │
│  • Cowork (desktop)         — polished deliverables (Word,       │
│                                Excel, PDF, PowerPoint)           │
│  • Remote Control           — phone-initiated CC sessions        │
│    (claude.ai/code)           routed to the Mac Studio           │
│                                                                  │
│  All produce work that may flow downstream to Crumb for vault-   │
│  grounded execution. Not autonomous — operator is present.       │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│  Level 3: CRUMB / CLAUDE CODE (vault-grounded execution)         │
│                                                                  │
│  • Reads upstream work from the dispatch queue                   │
│  • Executes vault-writing work under operator supervision        │
│  • Writes structured session reports at session end              │
│  • Runs interactively with the operator present                  │
└──────────────────────────────────────────────────────────────────┘
                            │
                            ▼
┌──────────────────────────────────────────────────────────────────┐
│  Level 4: TESS (autonomous scheduled services)                   │
│                                                                  │
│  Platform: Mac Studio launchd → dispatch.sh → tess-v2 contract   │
│    runner (Python) → Hermes gateway (for LLM routing)            │
│  Scope: 15 com.tess.v2.* LaunchAgents — health, vault gardening, │
│    FIF, Scout, daily-attention, overnight-research,              │
│    connections-brainstorm                                        │
│  Does NOT: plan operator work, dispatch interactive sessions,    │
│    maintain interactive dispatch queues                          │
└──────────────────────────────────────────────────────────────────┘
```

## Surface Inventory — Verdicts

| Surface | Verdict | Rationale |
|---|---|---|
| **Tess (launchd + contract runner + Hermes)** | Keep — scoped to scheduled services only | Handles 15 current services reliably; local MCP; live FS; sub-hour cadence; free-tier Nemotron execution |
| **Crumb / Claude Code local** | Keep — primary interactive execution | Operator-present vault work; deep reasoning; spec/design/code authoring |
| **claude.ai web chat** | Keep — Level 2 upstream | Strategic thinking, ambiguous scoping, conversations operator drives |
| **Cowork** (desktop) | Adopt — Level 2 upstream | Polished document production (Word/Excel/PDF/PPT). No current Tess service maps; net-new capability |
| **Remote Control** (claude.ai/code → Mac Studio) | Adopt — Level 2 upstream | Phone-initiated CC sessions on the Mac. Complements Crumb local. 10-min network timeout + Ultraplan conflict noted. |
| **Routines** (Anthropic cloud) | Reject — redundant under Tess retention | Offers scheduled execution, but Tess+Hermes already cover this at broader capability (local MCP, live FS, sub-hour, free-tier). Routines gives up capability for no offsetting gain when Mac Studio is always-on. HA-failover argument is weak given shared-fate with other Mac Studio dependencies. |
| **Channels** (Telegram → CC plugin) | Reject — Telegram is notifications-only | Operator has determined Telegram is notifications-only, not a work-input surface. Channels' value proposition (text Telegram → arrives in CC session) collapses when Telegram cannot carry meaningful inbound work. |

## Service Mapping

All 15 `com.tess.v2.*` services remain on Tess. No migrations.

| Service | Cadence | Class (Z/AB) |
|---|---|---|
| health-ping | 900s | C |
| awareness-check | 1800s | C |
| backup-status | 900s | C |
| vault-health | daily 02:00 | C (transitional, A-eligible per TV2-040) |
| vault-gc | daily 04:00 | C |
| fif-capture | daily 06:05 | C |
| fif-attention | daily 07:05 | C |
| fif-feedback-health | KeepAlive | C |
| daily-attention | 1800s | A |
| overnight-research | daily 23:00 | C (executor_target: claude-code) |
| connections-brainstorm | daily | C |
| scout-pipeline | daily 07:00 | C |
| scout-weekly-heartbeat | Monday 08:00 | C |
| scout-feedback-health | KeepAlive | C |
| scout-feedback-poller | KeepAlive | C |

Rationale for keeping all: sub-hour cadence, live local filesystem, local
SQLite state, destructive local ops, KeepAlive persistence, and free-tier
execution — none of these are improved by any Level 2 surface, and Routines
is rejected above.

## Amendment Z — What Is Retained, What Is Retired

### Retained (repurposed with writer inversion)

Z's machinery is sound; its direction was wrong. AC carries these forward:

- **Dispatch queue schema (Z §Z1):** The YAML schema at
  `_tess/dispatch/queue.yaml` is retained. Writer is no longer Tess's
  planning cycle; writer is an upstream-work bridge (design deferred,
  see Open Questions). Reader is still Crumb at session start.
- **Claims file (Z §Z1b):** Retained. Crumb emits claims at session
  start; claims resolve on session end. Single-writer invariant on the
  queue is preserved.
- **Session report schema (Z §Z2):** Retained. Crumb writes structured
  reports at session end to `~/.tess/state/session_reports.db`.
  Consumer is no longer Tess's planning cycle; consumer is the
  operator (via vault queryability, startup summary, and potential
  upstream bridge round-trip).
- **Startup hook integration (Z §Z3):** Retained. Crumb reads queue +
  last session report at session start and proposes work.
- **Orphaned-session detection (Z §Z3):** Retained. Same mechanism.
- **Task class taxonomy (Z §Z1):** Retained as a vocabulary; graduated
  autonomy (Z §Z4 "Phase C") is retired because Tess no longer
  dispatches autonomous-promoted task classes for operator-facing work.

### Retired

- **AD-013 (Interactive Dispatch Authority)** — reversed by AD-017.
- **Z4 Tess Planning Cycle** — no Tess-run planning loop over operator
  work. The planning service, autonomous dispatch routing, planning
  inputs, and planning-service failure handling are all retired.
- **Graduated autonomy promotion/demotion (Z §Z4)** — out of scope.
  Pre-approved autonomous task classes remain eligible for Tess-run
  scheduled services (that's just contract execution); the promotion
  *process* with operator-approval gates does not apply.
- **The "hierarchy inversion" framing (Z intro)** — rejected. Crumb as
  the de-facto operator-facing surface is now the deliberate design,
  not a bug.

## Upstream Work Bridge (Design Deferred)

AC establishes the *need* for a mechanism that moves work from Level 2
(claude.ai, Cowork, Remote Control) into the Level 3 dispatch queue,
preserving the schema Z defined. The *implementation* is deferred to a
follow-on design task.

Candidate mechanisms (not selected here):

1. **Skill-based export from claude.ai** — operator invokes an export
   skill in a claude.ai conversation; skill produces a queue-shaped
   YAML block; operator pastes into `_inbox/` for inbox-processor
   routing.
2. **Cowork deliverable + companion note** — Cowork produces a document;
   operator drops it into `_inbox/`; inbox-processor creates a companion
   note and the queue entry referencing the document.
3. **Manual operator-authored queue entry** — operator writes the
   queue entry directly in Crumb based on upstream-session context,
   no automation.
4. **Remote Control direct-write** — operator on phone invokes a
   Crumb session that writes a queue entry and exits; later Crumb
   session picks it up.

Selection criteria, ceremony cost analysis, and bridge contract design
belong to a subsequent amendment or a TV2-* task. AC does not preempt
that work.

## Implications for Other Spec Artifacts

The following require updating after AC is ratified:

1. **specification.md**
   - §3.1 System Map — replace the Tess/Crumb hierarchy with the
     four-level stack from AD-018.
   - §3.5 Second-Order Effects — "Danny's role shifts from session-by-
     session driver to strategic director" is partially retracted. Danny
     remains session driver *within Crumb*, but with Level 2 upstream
     surfaces where strategic thinking originates.
   - §16 Success Criteria — "Tess operates as an autonomous orchestrator,
     not a notification layer" is retracted. Success becomes: (a) Tess's
     15 scheduled services run reliably without operator attention;
     (b) work from upstream surfaces flows cleanly into Crumb via the
     queue.
   - AD list — add AD-017 and AD-018; annotate AD-013 as retracted.

2. **specification-summary.md**
   - Problem statement — "Nothing gets built unless Danny drives an
     interactive Crumb session" is no longer framed as the problem.
     Interactive Crumb is the preferred mode.
   - Solution — Tess's role description narrows to scheduled services.
   - Success — mirror §16 revision.

3. **tasks.md**
   - No scheduled TV2-* tasks are retired. All open items
     (TV2-038, TV2-040, TV2-057d, TV2-057e, TV2-057f) remain valid.
     They concern the scheduled-services side of Tess, which survives.
   - If a future task set is added for the Upstream Work Bridge, it
     belongs in a new phase (Phase 5 or similar).

4. **action-plan.md / action-plan-summary.md**
   - Milestone descriptions that frame Tess as "autonomous orchestrator"
     get narrowed to "autonomous scheduled-services executor."

5. **spec-amendment-Z-interactive-dispatch.md**
   - Add supersession header: `superseded_by: spec-amendment-AC`,
     noting which sections are retained (Z1 schema, Z1b claims, Z2
     report schema, Z3 startup hook) and which are retired (AD-013,
     Z4 planning cycle, graduated autonomy).

6. **Liberation Directive** (`_system/directives/liberation-directive.md`)
   - Bigger reconciliation outside tess-v2 scope. AC fixes the Tess
     spec side; the directive's surface model and the Tess standing-
     order pattern need a v1.2 update. Out of scope for AC itself;
     flagged as downstream work.

## Open Questions

1. **Upstream Work Bridge mechanism selection.** Deferred — needs more
   analysis (per operator direction 2026-04-21).
2. **Session report consumer model.** Under Z, Tess's planning cycle
   consumed session reports. With Tess retracted from that role, what
   (if anything) consumes the reports? Options: operator review only;
   vault-queryable history; round-trip back to claude.ai context via
   the bridge. Unresolved.
3. **Telegram digest channel concern.** Scout daily digest, health
   digest, and scout weekly heartbeat currently deliver multi-section
   markdown over Telegram. Under the notifications-only rule, that's
   a misuse. Separate amendment or flagged for future design — not
   AC scope.
4. **Hermes gateway role going forward.** Hermes remains part of the
   Tess stack (LLM gateway for scheduled services). Whether the
   gateway's orchestration-layer features (multi-step planning,
   tool-calling) are still justified for scheduled-services-only use,
   or whether a lighter runtime would suffice, is a subsequent question.
5. **Documenting the runtime swap formally.** AD-008 "supersession by
   runtime drift" (per project-state.yaml) still needs a formal note.
   Not AC's job, but adjacent.

## Provenance

- **Anthropic consolidation hypothesis** (2026-04-21):
  `_system/docs/anthropic-consolidation-hypothesis.md` — full surface
  inventory, verification pass, and the framing-risk compound observation
  that both the source conversation and first verification pass anchored
  on Cowork and missed Routines/Channels.
- **Live operational evidence (2026-03-27 through 2026-04-21):**
  - `design/conversation-analysis-2026-03-27.md` — early orchestration trial
  - `design/model-hermes-crumb-evaluation-frame-2026-04-20.md` — benchmark
    score ≠ orchestrator acceptability (doctrine shift)
  - `design/live-vs-documented-hierarchy-reconciliation-2026-04-20.md` —
    live hierarchy differs from spec; documented gap
  - `design/codex-integration-note-2026-04-20.md` — interim Codex OAuth
    trial prior to direct-API swap
  - `project-state.yaml` next_action (2026-04-21) — K2.5 → GPT-5.4 runtime
    swap rationale
- **Operator architectural reframe (2026-04-21):** reframing conversation
  in Crumb session of 2026-04-21 established: (a) operator preference for
  interactive claude.ai + Claude Code, (b) Hermes not meeting the
  orchestrator bar by operator standards, (c) need for an upstream→Crumb
  bridge that preserves Z's handoff schema.
- **Prior amendment**: `spec-amendment-Z-interactive-dispatch.md` —
  superseded portion; schemas retained.

## Peer Review

None yet. AC is the operator's own architectural retraction based on two
weeks of live evidence; the authority to reverse AD-013 is operator-held.
External peer review may still add value for the surface-inventory
reasoning and the bridge-mechanism open question, but is not required to
ratify AC.

Status on ratification: pending operator approval, then the implication
sweep (specification.md, specification-summary.md, Z supersession header,
action-plan* narrowing) proceeds.
