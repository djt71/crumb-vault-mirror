---
project: agent-to-agent-communication
type: specification
domain: software
status: draft
created: 2026-02-28
updated: 2026-02-28
tags:
  - tess
  - openclaw
  - agent-communication
  - architecture
---

# Agent-to-Agent Communication — Specification

**Version:** 0.2 (SPECIFY phase — post-review, not yet peer-reviewed)
**Scope:** Defines communication patterns, coordination protocols, and workflows enabling Tess, Crumb, and future specialist agents to coordinate work with reduced human routing overhead.
**Normative references:**
- `crumb-design-spec-v2-0.md` — system architecture, vault conventions
- `crumb-tess-bridge/design/dispatch-protocol.md` (CTB-016) — dispatch lifecycle, state machine
- `crumb-tess-bridge/design/bridge-schema.md` — transport layer, atomic file exchange
- `tess-operations/tasks.md` — Tess operational capabilities and planned milestones
- `researcher-skill/design/tasks.md` — research pipeline stage definitions
- `feed-intel-framework/design/action-plan-summary.md` — feed intel pipeline architecture

---

## 1. Problem Statement

Today Danny is the router between Tess and Crumb. He receives output from one system, interprets it, and manually dispatches the next step. This creates three bottlenecks:

1. **Latency.** Multi-step workflows (research → contextualize → write → deliver) stall at each human handoff, sometimes for hours or days.
2. **Cognitive load.** Danny carries inter-agent context (what Crumb produced, what Tess knows, what the vault says) in his head across sessions.
3. **Lost compounding.** Insights that should chain automatically (feed capture → cross-reference → vault write → briefing) terminate at each manual handoff point.

The goal is to shift Tess into an orchestrator role — holding Danny's context and intent, dispatching specialized work to Crumb and future agents, making intermediate decisions she's qualified for, and surfacing finished artifacts to Danny via Telegram.

---

## 2. Core Architecture

### 2.1 Topology

```
                    ┌────────────────────┐
                    │      Danny         │
                    │  (goal-setter,     │
                    │   final approver)  │
                    └────────┬───────────┘
                             │ Telegram
                    ┌────────▼───────────┐
                    │       Tess         │
                    │  (orchestrator /   │
                    │   governor)        │
                    └──┬──────┬──────┬───┘
                       │      │      │
              ┌────────▼┐ ┌──▼────┐ ┌▼────────┐
              │  Crumb   │ │Worker │ │ Worker  │
              │(primary) │ │  N    │ │  N+1    │
              └──────────┘ └───────┘ └─────────┘
                  ▲            ▲          ▲
                  └────────────┴──────────┘
                     crumb-tess-bridge
                   (atomic file handoff)
```

**Tess** = context-aware orchestrator and governor. Holds Danny's business context, priorities, and intent. Makes intermediate decisions within defined authority boundaries.

**Workers** (Crumb + future specialists) = narrow-scope executors. Receive well-scoped briefs, produce bounded artifacts, have no cross-task memory.

**Transport** = crumb-tess-bridge. Async file handoff with atomic writes (tmp + rename). CTB-016 state machine manages lifecycle, budget, and crash recovery.

**HITL gates** = Approval Contract (TOP-049). Mechanical enforcement via AID-* tokens. Tess cannot bypass; Danny approves or denies via Telegram inline UI.

**Architectural framing:** The vault functions as a blackboard in the classic AI sense — a shared, persistent knowledge substrate where specialized knowledge sources (workers) contribute bounded results and a controller (Tess) schedules and coordinates work. This validates the file-based approach as architecturally sound, not a compromise to be outgrown.

### 2.2 Design Principles

**P1 — File-based handoffs are sufficient.** The bridge's atomic file exchange handles all async workflows. No WebSocket or persistent connections needed. The dispatch protocol's state machine already manages multi-stage lifecycles with crash recovery, budget enforcement, and escalation.

**P2 — Two-tier context.** Tess holds "why" (Danny's goals, business context, active projects, relationships). Workers get "what" (a scoped brief with only the information needed for one bounded task). Workers never see Danny's full context.

**P3 — Mechanical enforcement over behavioral instructions.** HITL gates, budget ceilings, kill-switch checks, and state machine transitions are enforced by the runner, not by prompting agents to be careful. This principle carries forward from CTB-016 and is non-negotiable.

**P4 — Progressive trust via gate evaluations.** New capabilities deploy with 3-day gate evaluations. Danny reviews all outputs. Measurable criteria (utility, accuracy, false positive rate, cost) determine whether to expand autonomy or revise. No capability graduates to auto-approve without passing a gate.

**P5 — Build concretely, then extract.** Ship one workflow end-to-end, extract the reusable orchestration pattern, promote to `_system/docs/solutions/`. Don't build a framework first.

**P6 — Protocols before parallelism.** Well-designed coordination protocols and evaluation loops matter more than adding agents or concurrency. Parallelism without cancel/decommit semantics produces race conditions. Autonomy without quality scoring produces a larger pile of plausible artifacts. More agents without cost routing blows budgets.

---

## 3. Infrastructure Prerequisites

Four infrastructure changes are required before any workflow in this spec can ship. These are foundational and not scoped to a single workflow.

### 3.1 Multi-Dispatch Support (CTB-016 Amendment)

**Problem:** CTB-016 §2.3 rule 12 enforces single active dispatch. This blocks parallel vault query + external research (Workflow 3), cascading dispatch chains (§7.1), and any council pattern.

**Proposed solution — dispatch groups with join contracts:**

A `dispatch_group` is a set of related dispatches under a single orchestration context. Each group has a group-level budget, timeout, and a **join contract** that defines how branch results are merged.

Constraints:
- **Default remains single-dispatch.** Group dispatch requires explicit Tess decision with a `group_id` in the dispatch request.
- **Concurrency limit.** Maximum 3 concurrent dispatches per group (prevents runaway fan-out).
- **Group-level budget.** Sum of individual dispatch budgets cannot exceed group ceiling. This is enforced by the runner before spawning additional dispatches.
- **Group lifecycle states:** `active` (at least one dispatch running), `complete` (all dispatches terminal), `failed` (any dispatch failed and no recovery path), `canceled` (user canceled the group).
- **Cancel semantics.** Canceling a group cancels all non-terminal dispatches within it. Individual dispatch cancellation within a group is also supported.

**Join contract:** Each dispatch group declares:
- **Required branches** — which dispatches must complete before join (no silent missing branches).
- **Per-branch budget caps** — enforced independently per dispatch.
- **Merge policy** — how Tess combines branch results. Example for SE Account Prep: prefer internal vault facts over external claims; external claims must be cited; contradictions surfaced rather than silently resolved.
- **Timeout behavior** — what Tess does if a branch exceeds its deadline (deliver partial results vs. wait vs. escalate).

**Tagged channels** (an alternative considered): partition dispatch capacity by work type (vault-read, external-research, vault-write). Simpler but less flexible — doesn't support arbitrary parallelism patterns. Consider as a simplification if dispatch groups prove over-engineered.

**Implementation path:** Amend CTB-016 with a §2.6 (Dispatch Groups). Runner changes: flock per-group instead of global, group state file alongside individual dispatch state files.

### 3.2 Tess Context Model

**Problem:** For Tess to answer escalations, resolve conflicts, route work intelligently, and review outputs, she needs queryable access to Danny's priorities, active projects, and business context. Full vault scan is too expensive. A static summary file becomes stale.

**Proposed solution — hybrid context with two layers:**

1. **Persistent context file (`_openclaw/state/tess-context.md`).** Refreshed daily as part of the morning briefing (TOP-009). Contains: active project list with phases and next actions, SE account priority tiers, open commitments and deadlines, standing decision principles (e.g., "prefer file-based over network," "Haiku for routine, Sonnet for consequential"). This is what Tess "knows" at any given time. Maximum 8K tokens.

2. **Situational context.** Loaded per-trigger. When a dispatch returns, Tess loads the relevant project's `project-state.yaml` and most recent run-log entries. When an escalation arrives, she loads the account dossier or project spec section relevant to the question. Targeted reads, not full scans.

**Context budget:** Tess orchestration decisions operate within a context ceiling (persistent 8K + situational context). The situational ceiling is per-workflow rather than global: Workflow 1 (compound insights) operates comfortably within 12K situational. Workflow 3 (SE Account Prep), which synthesizes vault dossier results + external research results + the synthesis prompt, may require up to 16K situational. Ceilings are enforced the same way per-job ceilings are enforced in TOP-012.

**Stale context detection:** If the morning context refresh (TOP-009) fails, Tess's persistent context file retains a `refreshed_at` timestamp. Any orchestration decision where `refreshed_at` is > 24 hours stale triggers a warning flag on the output delivered to Danny: "Context may be stale — last refresh [timestamp]." This prevents confidently routing work based on outdated priorities.

### 3.3 Feedback Signal Infrastructure

**Problem:** Without feedback on whether outputs were useful, workflows can't improve. This was flagged as a gap in every source analysis (GPT-5.2, Gemini, Claude Opus, beyond-roadmap research).

**Proposed solution — lightweight feedback verbs:**

When Tess surfaces an artifact to Danny via Telegram, the message includes inline reactions: 👍 (useful), 👎 (not useful), ✏️ (needed editing). These are logged to an append-only feedback ledger:

```yaml
# _openclaw/state/feedback-ledger.yaml
- dispatch_id: "uuid"
  workflow: "compound-insight"
  timestamp: "2026-03-01T08:15:00Z"
  signal: "useful"  # useful | not-useful | edited
  artifact_path: "Sources/compound-insights/..."
```

Tess reads this ledger during periodic retrospectives (see §8.2) to identify patterns: which workflows produce useful outputs, which source types lead to edits, which cross-references Danny consistently ignores.

No feedback verb = no signal. The system degrades gracefully (no feedback means no optimization, but workflows continue functioning).

### 3.4 Correlation IDs Across Dispatches

**Problem:** When debugging why a compound insight has a bad cross-reference or a research artifact has a weak claim, tracing the causal chain (triage score → vault entities checked → dispatch parameters → written note) requires manually correlating timestamps across separate log files. As workflows scale, this becomes untenable.

**Proposed solution:** Every dispatch carries a `correlation_id` that links the triggering event (feed-intel item, research request, calendar trigger) through orchestration decisions, dispatch lifecycle, and feedback signals. This ID appears in:
- The dispatch state file (already exists)
- The feedback ledger entry (§3.3)
- The dispatch learning log (§3.5)
- The artifact's provenance metadata (§6.2)

Not a formal event-sourced audit log — just a consistent identifier that enables `grep correlation_id` across the system's existing log files. Promote to a structured audit store if retrospectives (§8.2) reveal that grep-based tracing is insufficient.

### 3.5 Dispatch Learning Log

**Problem:** The feedback ledger (§3.3) records *whether* outputs were useful. It does not record *why* — which brief parameters produced good results, which scope constraints prevented escalations, which rigor profiles matched which question types. Without this, Tess's dispatch quality plateaus.

**Proposed solution — dispatch learning log:**

After each dispatch completes and Danny provides a feedback signal, Tess appends a structured entry:

```yaml
# _openclaw/state/dispatch-learning.yaml
- correlation_id: "uuid"
  workflow: "research"
  timestamp: "2026-03-01T14:30:00Z"
  brief_params:
    rigor: "standard"
    scope_constraints: ["exclude pricing", "focus competitive positioning"]
    source_types: ["web", "vault"]
  outcome_signal: "edited"
  pattern_note: "Danny added 'So What?' section — research lacked implications for his positioning"
```

Tess consults this log when formulating future briefs. Over time, patterns accumulate: "research briefs about competitive analysis that omit an implications section consistently require editing" → Tess adds implications as a standard section in competitive analysis briefs.

The `pattern_note` field is generated by Tess at log time, not by Danny. Danny provides only the feedback verb; Tess infers the pattern from comparing the brief, the output, and the signal.

**Integration:** Tess reads the learning log at brief formulation time (not during retrospectives — this is real-time learning, not periodic review). The dispatch retrospective (§8.2) periodically reviews the learning log to identify higher-order patterns and recommend template changes.

---

## 4. HITL Authority Model

### 4.1 Authority Tiers

All agent actions fall into one of three tiers. This replaces ad-hoc per-workflow HITL decisions with a single authority model.

| Tier | Description | Examples | Gate |
|------|-------------|----------|------|
| **Auto-approve** | Read-only vault operations, writing new notes/insights, updating wikilinks, adding MOC entries, running searches | Compound insight writes, research note creation, vault queries, context assembly | None — Tess proceeds |
| **Approval Contract (AID-\*)** | External actions, destructive vault operations, budget above threshold | Email send, calendar events, file archival/moves, dispatch groups exceeding $2/day | Danny approves via Telegram inline UI (TOP-049) |
| **Always escalate** | Risk-type escalations, conflict resolution, decisions affecting customer relationships, scope changes to active projects | Customer-facing commitments, architectural decisions, anything touching `_system/` specs | Tess surfaces with context + recommendation; Danny decides |

**Critical dependency:** TOP-049 (Approval Contract) is a prerequisite for Tier 2 operations across all workflows. If TOP-049 is not yet operational, Tier 2 actions must be routed as Tier 3 (always escalate) until the mechanical enforcement infrastructure is in place.

### 4.2 Escalation Auto-Resolution

Tess can auto-resolve certain dispatch escalations without relaying to Danny, using the severity ordering from CTB-016 §6:

- **Scope escalations:** Tess answers using her persistent context (project priorities, account tiers, SE role knowledge). Example: "Should I include pricing comparison?" → Tess checks account tier and decides.
- **Access escalations:** Tess routes around unavailable sources using degradation-aware logic (§8.4). Example: "Paywall blocks primary source" → Tess authorizes using secondary sources with quality ceiling noted.
- **Conflict escalations:** Always escalate to Danny. Contradictory authoritative sources require human judgment.
- **Risk escalations:** Always escalate to Danny. Sensitive topics, customer-facing implications, or security concerns require human judgment.

**Confidence-based override:** For scope and access escalations, Tess assesses her own confidence in the resolution. If confidence is low (e.g., the question involves an account she has sparse context on, or the decision could materially change the output's direction), she escalates to Danny regardless of escalation type. This prevents Tess from auto-resolving questions she isn't actually equipped to answer.

**Audit trail:** Every auto-resolved escalation is logged with Tess's reasoning, the context she used, and her confidence assessment. Danny reviews these in periodic retrospectives.

---

## 5. Core Workflows

Four workflows, ordered by build priority. Each is described with trigger, flow, value, dependencies, and acceptance criteria.

### 5.1 Workflow 1: Feed Intel → Compound Insight Generation

**Why first:** Pipeline already running end-to-end. Daily cadence. Low external risk (write-to-vault only). The gap between "here's what was captured" and "here's what it means for what Danny is building" is felt every time he reads a digest.

**Trigger:** Daily feed intel digest cycle (existing scheduled pipeline) or high-signal item detection during triage.

**Flow:**

1. Feed intel pipeline captures and triages content (operational via x-feed-intel + feed-intel-framework).
2. High-signal items (score ≥ threshold, where threshold is a configurable parameter starting at the top quartile of historical scores) pass to Tess with triage metadata.
3. Tess loads persistent context (`tess-context.md`) and cross-references against active projects, current milestones, open questions.
4. For items with genuine cross-references, Tess generates a compound insight — what this means for what Danny is working on, not just what it says.
5. Tess dispatches Crumb to write the compound insight to the vault as a structured note.
6. Danny receives a Telegram summary that's contextualized, not raw.

**Compound insight schema:**

```yaml
---
type: compound-insight
status: active
created: 2026-03-01
source_item: "feed-intel item ID or URL"
cross_references:
  - "[[project-or-note-wikilink]]"
confidence: high | medium | low
tags:
  - compound-insight
  - relevant-domain-tag
provenance:
  workflow: "compound-insight"
  dispatch_id: "uuid"
  correlation_id: "uuid"
  model: "claude-haiku-4.5"
  critic_reviewed: false
---
```

Required sections: **Signal** (what was captured), **Cross-Reference** (what it connects to in the vault), **Implication** (what it means for Danny's work), **Source Trail** (feed item → triage score → vault entities checked).

**Vault location:** `Sources/compound-insights/` with filename pattern `ci-YYYYMMDD-slug.md`.

**Novelty/duplication check:** Before writing, the worker searches existing compound insights for the same source item (exact match on `source_item` URL/ID). For cross-reference pair dedup, use exact wikilink pair matching as the starting mechanism. Semantic dedup (detecting that `[[multi-agent-systems]]` overlaps with `[[agent-architecture]]`) is deferred — flag as an open question for gate evaluation if exact matching proves insufficient. If a match exists, append as a delta ("what changed since last time") rather than creating a new note.

**Temporal dedup:** For ongoing themes that generate repeated feed-intel items across days, Tess checks whether an existing compound insight for the same cross-reference pair was written within the past 7 days. If so, the new item is appended as a delta to the existing note rather than creating a new one. This prevents repetitive insights on slow-moving topics.

**Acceptance criteria:**
- Compound insights have valid frontmatter matching schema
- Wikilinks in cross_references resolve to existing vault notes
- vault-check.sh passes on generated files
- Danny's feedback signal logged for each insight delivered
- Maximum 5 compound insights per daily cycle (noise ceiling)

**Dependencies:** feed-intel-framework M2 closed, tess-context.md operational, feedback signal infrastructure (§3.3).

### 5.2 Workflow 2: Research Agent → Tess → Vault Pipeline

**Why second:** Researcher-skill is progressing toward the Research Loop milestone (M3a), with Synthesis + Writing (M5) further out. Dispatch protocol already defines how Tess dispatches to Crumb. The key unlock is Tess answering intermediate escalations herself rather than relaying to Danny.

**Timeline note:** Researcher-skill is currently at M1+M2 complete with M3a (Research Loop) next. M5 (Synthesis + Writing) is several milestones away. This workflow is likely months out, not weeks. Build order reflects this — Workflow 2 is Phase 2, gated on researcher-skill M5 completion.

**Trigger:** Danny sends research request via Telegram, or Tess identifies a research need during intelligence gathering (TOP-046), compound insight generation, or SE account prep.

**Flow:**

1. Research need identified (manual or automatic trigger).
2. Tess formulates a research brief matching the researcher-skill's schema: question, deliverable_format, rigor profile (light/standard/deep), scope constraints. **Tess consults the dispatch learning log (§3.5) for patterns relevant to this brief type before finalizing parameters.**
3. Tess dispatches via bridge → Crumb executes the researcher-skill pipeline (Scoping → Planning → Research Loop → Synthesis → Citation Verification → Writing).
4. If an escalation fires (CTB-016 §6):
   - **Scope or access:** Tess evaluates against her context and auto-resolves per §4.2, including confidence-based override.
   - **Conflict or risk:** Tess relays to Danny with her context and a recommendation.
5. Pipeline completes. Tess receives the finished artifact.
6. **Quality gate:** Tess evaluates the artifact using the review schema (§6.1) before surfacing to Danny.
7. If quality gate passes → deliver via Telegram with summary. If fails → either re-dispatch with modified brief (narrower scope, additional constraints) or escalate to Danny.

**Re-dispatch limit:** Tess may re-dispatch a failing research brief a maximum of 2 times with modified parameters. If the third attempt fails the quality gate, Tess escalates to Danny with the structural metrics and her assessment of why the brief isn't producing acceptable results. This prevents infinite re-dispatch loops.

**Quality review schema (§6.1):**

| Check | Type | Source | Pass Criteria |
|-------|------|--------|---------------|
| Convergence score | Structural | Researcher-skill telemetry | ≥ rigor profile threshold |
| Citation verification | Structural | RS-007 output | 0 verification failures |
| Writing validation | Structural | RS-008 output | All 4 checks pass |
| Deliverable format | Structural | Brief vs. output comparison | Format matches brief spec |
| Length bounds | Structural | Token count | Within ±30% of brief target |
| Relevance | Context | Tess evaluation | Artifact addresses the original question (Tess judgment call) |

If all structural checks pass and convergence score is high, Tess auto-delivers. If any structural check fails, Tess re-dispatches with repair instructions (subject to re-dispatch limit). If convergence is low or relevance is questionable, Tess surfaces to Danny with the structural metrics visible.

**Dependencies:** Researcher-skill M5 complete, tess-context.md operational, escalation auto-resolution logic.

### 5.3 Workflow 3: SE Account Prep

**Why third:** Highest daily-work ROI — 15-30 minutes of pre-call prep per account across ~25 accounts. Requires multi-dispatch (§3.1) and structured account data.

**Trigger:** Upcoming customer meeting detected via calendar integration (TOP-027), or Danny's manual request ("prep me for the Acme Corp call").

**Flow:**

1. Trigger fires (calendar event or manual request).
2. Tess opens a dispatch group (§3.1) with two parallel dispatches and a join contract:
   - **Dispatch A (vault query):** Crumb searches vault for account dossier, previous meeting notes, open action items, deployment state.
   - **Dispatch B (external research):** Crumb executes a light-rigor researcher-skill run focused on the customer — recent news, tech stack changes, competitive moves in their vertical.
   - **Join contract:** Both branches required. Merge policy: prefer vault facts over external claims; external claims must be cited; contradictions surfaced explicitly.
3. Both dispatches return to Tess.
4. Tess synthesizes into a pre-call brief:
   - What's changed since last touch (staleness check: if last_touch_date > 30 days, flag explicitly)
   - What they care about (from dossier + recent external signals)
   - Recommended talking points
   - Open action items from previous meetings
5. **Deadline-aware behavior:** If the meeting is < 30 minutes away and deep research hasn't finished, Tess delivers whatever she has (vault data + partial external) with a "research still in progress" flag. Something useful in 5 minutes beats something perfect in 2 hours.
6. Delivered to Telegram 30 minutes before meeting (or as part of morning briefing for same-day meetings).

**Post-call feedback:** After the calendar event ends (detected via TOP-027), Tess prompts Danny via Telegram: "How was the prep for [Account]? 👍 helpful / 👎 not helpful / ✏️ something was missing". If Danny responds with ✏️, Tess follows up: "What was missing?" The free-text response is logged in the feedback ledger alongside the dispatch correlation_id, and in the dispatch learning log (§3.5) to improve future prep briefs for that account and account tier.

**Account data prerequisite:**

The customer-intelligence project provides the dossier infrastructure. For this workflow, each account needs structured frontmatter that Tess can query:

```yaml
---
type: account-dossier
account: "Acme Corp"
last_touch_date: 2026-02-15
engagement_state: active | prospecting | dormant
deployed_products: ["NIOS", "BloxOne DDI"]
key_contacts:
  - name: "Jane Smith"
    role: "Sr. Network Engineer"
open_action_items:
  - "Follow up on DNS migration timeline"
---
```

**Staleness signal:** If `last_touch_date` > 30 days, the brief explicitly flags: "Account data is from [date] — verify currency before using in conversation." This prevents confidently presenting stale information.

**Acceptance criteria:**
- Pre-call brief delivered ≥ 20 minutes before meeting for known calendar events
- Brief includes both vault context and external intel (or explicit flag if external research incomplete)
- Staleness warning present when account data > 30 days old
- Dispatch group completes within budget ceiling
- Post-call feedback prompt sent after calendar event ends

**Dependencies:** Multi-dispatch (§3.1), Google Calendar integration (TOP-027), structured account dossiers (customer-intelligence project), researcher-skill M5 complete.

### 5.4 Workflow 4: Vault Gardening

**Why fourth:** The vault is young — not much to garden yet. Detection infrastructure already exists (vault-check.sh, TOP-010 nightly health check). Value increases over time as content accumulates. Build this when the other three workflows are generating enough vault content to need maintenance.

**Trigger:** Scheduled (extends TOP-010 nightly vault health check) or manual request.

**Flow:**

1. Tess runs vault health scan (vault-check.sh + extended checks from TOP-010).
2. Categorizes findings by action type:
   - **Auto-fix (Tier 1):** Broken wikilinks where target is unambiguous, missing topic tags on kb-tagged files, vault-check warnings with deterministic fixes.
   - **Structural improvement (Tier 2):** Notes missing MOC entries, orphan files with clear category membership. *(Entity resolution — e.g., "Acme", "Acme Corp", "ACME" → single canonical reference — is deferred. This is a deceptively hard problem that warrants its own spike rather than being a sub-bullet in gardening.)*
   - **Destructive (Tier 3):** File archival (Archived/KB/ pattern), file moves, note merges.
3. Tier 1: Tess auto-dispatches Crumb. Results reported in next morning briefing.
4. Tier 2: Tess dispatches Crumb, reviews output, delivers proposed changes for Danny's review.
5. Tier 3: Tess routes through Approval Contract (AID-*) before any dispatch.

**Schema enforcement (structural gardening beyond remediation):**
- Enforce frontmatter required fields for each note type (dossier, spec, meeting notes, compound insight)
- Enforce MOC membership for all kb-tagged notes
- Enforce link hygiene (no broken wikilinks, no orphan notes outside Archived/)
- Detect when project-state.yaml `next_action` hasn't changed in > N days (stall detection signal for §8.1)

**Acceptance criteria:**
- Auto-fixes pass vault-check.sh without regressions
- No destructive operations without AID-* approval
- Morning briefing includes gardening summary (fixes applied, items pending review)

**Dependencies:** Approval Contract (TOP-049), sufficient vault content to justify the overhead.

---

## 6. Quality Assurance

### 6.1 Adversarial Review (Critic Skill)

For high-stakes outputs (research artifacts, customer-facing content, architectural proposals), a critic agent provides structured adversarial review before Tess delivers to Danny.

**Pattern:** After the primary worker produces an artifact, Tess dispatches a second Crumb instance with a critic skill, specifically instructed to:

- Identify claims not supported by the evidence base
- Find logical gaps or unstated assumptions
- Check for missing perspectives the original brief implied
- Verify that conclusions follow from the presented evidence

The critic receives the artifact + the original brief and produces a structured critique. Tess evaluates the critique: minor issues are annotated on the artifact; major issues trigger a revision dispatch to the original worker.

**Independent citation verification:** For research artifacts specifically, the critic skill includes a citation re-check pass: independently verify that cited sources support the claims attributed to them. This "fail closed on contradictions" posture prevents persisting falsehoods into the vault. If critical claims are unsupported or contradicted, the artifact is blocked from delivery until revised.

**When to invoke:** Tess decides based on: request criticality (was this marked deep rigor?), downstream impact (customer-facing? architectural?), and cost budget. Routine compound insights do not get critic review. Research for customer positioning does.

**Implementation:** New Crumb skill (`.claude/skills/critic/SKILL.md`). Single-stage prompt that receives an artifact and brief, produces a structured critique with severity ratings (minor/significant/critical). Lightweight — no multi-stage pipeline needed.

### 6.2 Confidence and Provenance Metadata

Every agent-generated vault artifact carries provenance metadata:

```yaml
---
provenance:
  workflow: "compound-insight | research | account-prep | gardening"
  dispatch_id: "uuid"
  correlation_id: "uuid"
  model: "claude-haiku-4.5 | claude-sonnet-4.5 | ..."
  critic_reviewed: true | false
  confidence: high | medium | low
  confidence_basis: "source_authority | corroboration | recency | inference"
---
```

The `confidence_basis` field uses a constrained enum rather than free text, enabling structured analysis during retrospectives. Categories:
- `source_authority` — confidence derived from authoritative primary source (direct customer conversation, official documentation)
- `corroboration` — confidence derived from multiple independent sources agreeing
- `recency` — confidence derived from very recent data
- `inference` — confidence derived from reasoning over indirect evidence (lowest tier)

This enables: filtering vault content by confidence, auditing which workflows produce reliable outputs, and identifying when confidence ratings drift from Danny's actual feedback.

### 6.3 Conflict Resolution

When Tess encounters contradictory information across sources or agents:

1. **Identify the contradiction.** Source A says X; source B says Y.
2. **Assess source reliability.** Direct customer conversation > industry report > social media post. Vault notes from meetings > feed-intel captures.
3. **Assess recency.** Newer information weighted higher, modulated by source reliability (a 1-week-old customer conversation outweighs a 1-day-old blog post).
4. **Surface with reasoning.** Rather than silently choosing one, Tess presents the contradiction to Danny with her assessment: "Vault note says X (from direct conversation, 4 months old). Article says Y (secondary source, 2 days old). Recommend verifying in next customer touchpoint."

This is especially important for SE Account Prep (§5.3) where incorrect pre-call briefs are worse than no brief.

---

## 7. Advanced Coordination Patterns

These patterns are not initial build targets. They describe capabilities that become buildable once the core four workflows and infrastructure prerequisites are operational. Documented here to inform architectural decisions now.

### 7.1 Cascading Dispatch Chains

**What:** The output of one dispatch triggers the next. Tess holds a multi-step task plan and adapts as intermediate results arrive.

**Example chain:**
1. Feed-intel captures competitor's new product announcement.
2. Tess identifies relevance to Account X (from tess-context.md).
3. Tess dispatches Crumb for competitive analysis (researcher-skill, standard rigor).
4. Research reveals pricing shift affecting Danny's positioning.
5. Tess dispatches Crumb to update Account X dossier.
6. Tess drafts notification for Danny with talking points for next Account X call.

Steps 3–6 are a cascade — each dispatch's output informs the next dispatch decision.

**Requires:** Multi-dispatch (§3.1), a task plan data structure (dispatch chain definition with conditional branching), and Tess orchestration logic that can evaluate intermediate results and decide next steps.

**Architectural note:** This is the capability that transforms Tess from "dispatch one thing, review, dispatch next thing" to "hold a multi-step plan, execute it, adapt as results arrive." It's the most architecturally significant advanced pattern.

### 7.2 Research Council

**What:** For high-stakes research, dispatch 2–3 Crumb instances with different analytical lenses on the same question. Tess synthesizes their outputs.

**Example lenses:**
- Crumb-Analyst: Feature comparison, market positioning, pricing
- Crumb-Skeptic: Weaknesses in the thesis, counter-arguments, risks
- Crumb-Strategist: Competitive moats, switching costs, long-term trends

Tess receives all artifacts, identifies where they agree (high-confidence findings) and where they diverge (areas needing Danny's judgment), and delivers a synthesized brief with confidence markers.

**When to use:** Only for consequential research where the additional cost (2–3× API spend) is justified. Customer-facing competitive analysis, strategic architectural decisions, high-stakes SE positioning.

**Requires:** Multi-dispatch (§3.1), persona definitions for Crumb, synthesis prompt for Tess, cost-aware routing (§8.3) to prevent routine use.

### 7.3 Event-Driven Triggers

**What:** Instead of relying solely on scheduled crons and manual requests, agents react to environmental changes in near-real-time.

**Event sources:**
- Git commit to crumb repo modifying a skill or spec → check for stale documentation
- New file in vault inbox → triage and route
- Email from a customer (via Gmail integration) → check for action items
- Feed-intel item above signal threshold → immediate compound insight generation
- Calendar event created → trigger account prep if customer-facing
- Dispatch completion → trigger downstream cascading chain

**Implementation path:** Lightweight event bus via file-watch (fswatch on the vault, filtered by path patterns). Each event type maps to a Tess evaluation: "Is this worth acting on?" Most events produce no action. High-signal events trigger a workflow.

**Requires:** File-watch infrastructure, event-to-workflow routing rules in Tess, guard against event storms (debounce, rate limiting).

---

## 8. Operational Intelligence

Capabilities that make the agent ecosystem self-aware and self-improving. These are medium-term builds that compound in value over time.

### 8.1 Project Stall Detection and Intervention

**Beyond notification:** When Tess detects a project stall (next_action unchanged for > N days, no commits to project directory, no run-log entries), she doesn't just alert — she diagnoses:

- **Blocked by dependency?** Cross-reference against other projects' states. Surface the dependency chain.
- **Scope creep?** Compare current task count against milestone plan. Suggest splitting.
- **Pattern recognition?** If a project has stalled at the same point multiple times (visible in run-log timestamps), surface that pattern.

**Output:** A single recommended next action, not a status report. "Researcher-skill M5 is blocked on multi-dispatch. Smallest unblocking step: draft §3.1 dispatch group amendment to CTB-016."

**Data sources:** project-state.yaml, run-log timestamps, vault-check output, git commit frequency.

### 8.2 Dispatch Retrospective

**Periodic review:** Weekly (or after N dispatches), Tess reviews the dispatch log + feedback ledger + dispatch learning log (§3.5) and identifies:

- Common failure modes ("research briefs about competitive analysis consistently under-scope pricing data")
- Prompt improvements ("adding explicit scope constraints about X reduces escalations by Y%")
- Cost efficiency patterns ("Haiku produces acceptable results for compound insights; Sonnet unnecessary")
- Model quality signals ("Danny edits 60% of research artifacts to add a 'So What?' section → add implications section to writing stage template")
- Dispatch learning patterns that should be promoted to template changes

**Output:** Recommended changes to workflow parameters, prompt templates, or routing rules. All changes go through Danny for approval before being applied.

**Requires:** Feedback signal infrastructure (§3.3), dispatch learning log (§3.5), accumulated dispatch history (start after 2+ weeks of operational data).

### 8.3 Cost-Aware Routing

Once multiple workflows are running, the cost model becomes a first-class engineering problem. Tess needs a budget governance function:

- **Model tier selection:** Route routine work (compound insights, vault gardening) to Haiku. Route consequential work (research, customer-facing) to Sonnet. Only use councils for explicitly high-stakes requests.
- **Daily budget tracking:** Per-dispatch cost recorded in dispatch state. Running daily total tracked. Alert at 80% of daily ceiling.
- **Degradation mode:** When daily spend approaches ceiling, automatically downgrade model tiers for non-critical work rather than hard-stopping all work.
- **Utility scoring:** Over time, correlate cost-per-workflow with Danny's feedback signals. Identify which workflows deliver the most value per dollar.

**Integration:** Extends per-job token budgets (TOP-012) from enforcement to intelligent rationing. Uses the existing ops metrics harness (TOP-050) for cost tracking.

### 8.4 Degradation-Aware Workflow Routing

Beyond binary "working / failed" status:

- **Model degradation:** If a model is responding slowly or producing lower-quality outputs (detectable via response latency, convergence scores, feedback signals), route to alternatives or escalate to human.
- **API degradation:** If Anthropic API is throttled, queue non-urgent work. If a feed source returns 429s, reduce polling frequency rather than consuming retry budget.
- **Data freshness degradation:** If vault mirror hasn't synced in > 12 hours, flag all vault-dependent outputs as "potentially stale."
- **Cost degradation:** Approaching budget ceiling → switch to cheaper models for non-critical work (see §8.3).

**Extends:** Mechanic heartbeat (TOP-007) from "check if things are running" to "check if things are running well." Extends per-job budgets (TOP-012) from enforcement to intelligent rationing.

---

## 9. Proactive Awareness

All workflows in §5 are primarily reactive (triggered by Danny, a schedule, or an event). The next evolution is Tess scanning for work without being asked.

### 9.1 Infrastructure (Already Planned)

- **Morning briefing (TOP-009):** Vault status, pipeline health, project status. Natural vehicle for proactive recommendations.
- **Awareness-check cron (TOP-053):** 30-min cycle during waking hours. Right vehicle for proactive scanning.
- **Ops metrics harness (TOP-050):** Data for pattern detection.

### 9.2 Proactive Capabilities

**Near-term (extend existing crons):**
- Post-capture compound insight generation (run as part of digest delivery, not waiting for Danny to ask)
- Project stall detection (§8.1) surfaced in morning briefing
- Anticipatory session prep (TOP-047) — already planned, natural vehicle for proactive context assembly
- System health expansion — workflow health, not just infrastructure health

**Medium-term (requires new infrastructure):**
- Meeting prep auto-triggers (after TOP-027 calendar integration)
- Cross-project dependency surfacing (morning briefing identifies when one project's completion unblocks another)
- Anticipatory project scaffolding — when Tess detects a cluster of feed-intel items on the same topic with no corresponding project, she pre-scaffolds a project directory with draft spec
- Weekly cross-session synthesis — a routine that reviews the week's dispatches, compound insights, and feedback signals, identifying recurring thematic threads across sessions and writing a brief synthesis note that captures cross-session connections. This goes beyond vault gardening (which is structural) into semantic consolidation (which is intellectual). Natural vehicle: extend the weekly dispatch retrospective (§8.2) with a synthesis pass.

**Longer-term (requires behavioral data):**
- Operational tempo adaptation — adjust cron frequency based on Danny's activity level (high activity → more frequent awareness checks, weekends → batch and reduce noise)
- Session retrospective loop — analyze past Crumb session effectiveness to calibrate future session prep
- Behavioral pattern detection — "Danny consistently ignores feed-intel tagged 'general-ai-news' but reads every 'agent-architecture' item → adjust triage weights"

### 9.3 The Proactive Awareness Guardrail

Proactive capabilities must pass a **signal-to-noise test** before deployment: would Danny act on this notification more than 50% of the time? If not, it's noise. The feedback signal infrastructure (§3.3) provides the measurement mechanism. Any proactive capability that generates > 50% 👎 signals over a gate evaluation period gets disabled or revised.

Contradiction detection (feed-intel item contradicts an assumption in an active project spec) has a much better signal-to-noise ratio than generic cross-referencing and should be prioritized as a proactive trigger.

---

## 10. Future Architecture Considerations

### 10.1 Session Continuity and Debrief

Two high-value additions that make Danny's existing daily workflow better:

**Pre-session context assembly:** Before a Crumb session, Tess assembles: last session summary, what changed since then, relevant feed-intel, dispatch results, and suggested first command. This is TOP-047 (Anticipatory Session) executed through the agent-to-agent architecture.

**Post-session knowledge extraction:** After a Crumb session ends, Tess reviews the session log and extracts: decisions made, lessons learned, new vault entities, unfinished work. These are written to structured vault locations. Session logs are rich but ephemeral — this extracts the durable value.

### 10.2 Decision Journal

Tess maintains a lightweight structured log of significant decisions: what was decided, alternatives considered, reasoning, and critically — what would change the decision. When a "change your mind" condition is later detected (via feed-intel, project outcomes, or operational data), Tess surfaces it.

Not every micro-decision. Only architectural choices, prioritization calls, trade-offs, and predictions. Capture mechanism starts manual (Tess prompts Danny at session end) before attempting automatic detection.

### 10.3 Communication Voice Calibration

As email/iMessage integration comes online (TOP-031/037/043), Tess builds and maintains voice profiles — how Danny communicates with different audiences (customers by tier, internal engineering, personal contacts). These are vault artifacts derived from Danny's sent messages, not model fine-tunes. They inform draft generation so that drafts sound like Danny writing to that specific recipient, not like generic AI email.

### 10.4 External Agent Interoperability

The industry is converging on two complementary standards:
- **MCP (Model Context Protocol):** Agent ↔ tools/data. Context exposure, tool boundaries, lifecycle management.
- **A2A (Agent2Agent Protocol):** Agent ↔ agent. Discovery (Agent Cards), task lifecycle, long-running collaboration.

**Relevance for Crumb/Tess:** The file-based CTB bridge is correct for local reliability. But message schemas should be designed so workers *could* be exposed as A2A servers later. The A2A task state machine (submitted → working → input-required → completed/failed/canceled) maps reasonably to CTB-016's lifecycle.

**Action now:** Monitor A2A/MCP developments as a feed-intel topic. Don't implement until there's a concrete use case (external agent that Tess would benefit from talking to). Consider whether the OpenClaw community reaches critical mass for peer-to-peer agent communication.

### 10.5 Skill and Tool Acquisition

When Tess encounters a capability gap, instead of just failing or escalating, she searches for solutions: ClawHub skills, MCP servers, bash tool composition. She discovers, evaluates (security, permissions, compatibility), and proposes. Danny approves. Tess installs and tests.

This is the transition from "agents that use fixed tools" to "agents that expand their own toolbox" — governed by the same Approval Contract infrastructure (TOP-049) that governs all consequential actions.

---

## 11. Tess Model Tier for Orchestration

### 11.1 The Capacity Question

This spec asks Tess to make decisions that require genuine judgment: evaluating research quality against a brief (§5.2), auto-resolving scope escalations by reasoning about account tiers and project priorities (§4.2), synthesizing parallel dispatch outputs into coherent pre-call briefs (§5.3), and deciding when critic review is warranted. These are not pattern-matching tasks.

The tess-model-architecture project placed Tess on Haiku 4.5 at $8.40/mo for sound economic reasons. But this spec expands Tess's role from conversational assistant to governor — making contextual judgment calls that shape what Danny sees and doesn't see.

### 11.2 Tiered Orchestration Decisions

Not all orchestration decisions require the same reasoning depth. Route by decision complexity:

| Decision Type | Examples | Model Tier |
|---------------|----------|------------|
| Routing | Dispatch a compound insight write, forward a completed artifact | Haiku (current) |
| Evaluation | Quality gate checks against structural criteria, feedback logging | Haiku (current) |
| Judgment | Escalation auto-resolution, research brief formulation, pre-call brief synthesis, critic invocation decisions | Sonnet (elevated) |

**Cost implication:** Judgment-class decisions are infrequent relative to routing/evaluation. Estimated additional cost: 3-5 Sonnet calls per day at orchestration scale. Track actual cost during Workflow 1 gate evaluation and adjust tiers based on observed quality.

**Implementation:** Tess's orchestration logic classifies each decision before executing. Judgment-class decisions make a Sonnet API call with the relevant context. Routing-class decisions use Tess's native Haiku capability. This is enforced in the orchestration skill, not left to behavioral prompting.

---

## 12. Build Order

### Phase 1: Foundation (build now)

| # | Item | Dependency | Est. Effort |
|---|------|------------|-------------|
| 1 | Tess context model (§3.2) | TOP-009 operational | 1 session |
| 2 | Feedback signal infrastructure (§3.3) + correlation IDs (§3.4) | Telegram bot | 1 session |
| 3 | Workflow 1: Compound insights (§5.1) | #1, #2, FIF M2 closed | 2-3 sessions |
| 4 | Gate evaluation for Workflow 1 | #3 operational | 3-day gate |

### Phase 2: Research pipeline (after researcher-skill M5)

| # | Item | Dependency | Est. Effort |
|---|------|------------|-------------|
| 5 | Quality review schema (§6.1) | RS-013/014/015 complete | 1 session |
| 6 | Escalation auto-resolution logic (§4.2) | #1 (tess-context) | 1 session |
| 7 | Dispatch learning log (§3.5) | #4 (gate data to learn from) | 1 session |
| 8 | Workflow 2: Research → Tess pipeline (§5.2) | #5, #6, #7 | 2-3 sessions |
| 9 | Gate evaluation for Workflow 2 | #8 operational | 3-day gate |
| 10 | Critic skill (§6.1) | #8 operational | 1 session |

### Phase 3: Parallel dispatch + SE prep (after TOP-027 calendar + TOP-049 approval contract)

| # | Item | Dependency | Est. Effort |
|---|------|------------|-------------|
| 11 | Multi-dispatch amendment to CTB-016 (§3.1) | #8 operational (proven single-dispatch first) | 1-2 sessions |
| 12 | Structured account dossier schema | Customer-intelligence project | 1 session |
| 13 | Workflow 3: SE Account Prep (§5.3) including post-call feedback | #11, #12, TOP-027 | 2-3 sessions |
| 14 | Gate evaluation for Workflow 3 | #13 operational | 3-day gate |

### Phase 4: Gardening + operational intelligence (as vault matures)

| # | Item | Dependency | Est. Effort |
|---|------|------------|-------------|
| 15 | Workflow 4: Vault gardening (§5.4) | TOP-049 operational | 2 sessions |
| 16 | Dispatch retrospective (§8.2) | 2+ weeks feedback data | 1 session |
| 17 | Cost-aware routing (§8.3) | Multiple workflows operational | 1-2 sessions |
| 18 | Stall detection (§8.1) | Morning briefing enrichment | 1 session |
| 19 | Weekly cross-session synthesis (§9.2) | #16 operational | 1 session |

### Phase 5: Advanced patterns (as system matures)

Items from §7, §9.2 (medium/longer-term), and §10. Sequenced based on demonstrated need, not speculative value. Each requires a separate SPECIFY → PLAN cycle before building.

---

## 13. Open Questions

These require resolution during PLAN phase or through early build experience:

1. **Orchestration logic location.** Where does Tess's dispatch decision-making live? OpenClaw skill? Extension of awareness-check (TOP-053)? New cron job? Recommendation: start as an OpenClaw skill invoked by existing crons, but be specific about which cron triggers which decision. Compound insight workflow (§5.1) is triggered by the feed-intel digest cycle — this should be a distinct invocation, not bundled into awareness-check. Account prep (§5.3) is calendar-triggered — rides on awareness-check's 30-min cycle but as a separate evaluation path. Prevent the "everything runs in awareness-check and it becomes a 3-minute monolith" failure mode by keeping orchestration decisions as discrete skill invocations called by crons, not logic embedded in the cron itself.

2. **Compound insight noise ceiling.** Maximum 5/day is a starting guess. Actual ceiling should be calibrated during gate evaluation based on Danny's feedback signals.

3. **Tess context refresh frequency.** Daily (during morning briefing) is the starting proposal. If Tess makes bad orchestration decisions because her context is stale mid-day, increase to twice-daily or event-triggered refresh. Stale context detection (§3.2) provides the safety net.

4. **Multi-dispatch concurrency limit.** 3 per group is a conservative starting point. May need adjustment after observing actual resource contention and cost patterns.

5. **Critic skill invocation threshold.** What criteria determine "high-stakes enough for critic review"? Starting proposal: deep rigor profile, or customer-facing deliverable, or Danny's explicit request. Calibrate during gate evaluation.

6. **Cross-project dependency graph.** Explicit (maintained YAML file) vs. inferred (Tess scans project files for cross-references)? Start inferred; promote to explicit if inference proves unreliable.

7. **Proactive scaffolding approval.** When Tess pre-scaffolds a project from clustered feed-intel, what HITL tier does that fall under? Recommendation: Tier 2 (Approval Contract) — creating project directories is a structural vault change.

8. **Compound insight semantic dedup.** Exact wikilink pair matching is the starting mechanism for novelty checks. If gate evaluation reveals that semantically similar but lexically different cross-references produce duplicate insights, invest in a lightweight semantic similarity check. Defer until data shows the problem is real.

9. **Sonnet orchestration call volume.** §11.2 estimates 3-5 Sonnet calls/day for judgment-class decisions. Track actual volume and cost during Workflow 1 gate evaluation. If Haiku proves sufficient for early orchestration decisions (compound insights are the simplest workflow), defer Sonnet elevation until Workflow 2 demands it.

10. **Entity resolution scope.** Deferred from vault gardening (§5.4). When the vault accumulates enough entity variants to cause practical problems (duplicate dossier references, broken cross-references), scope as a separate spike.

---

## 14. What This Spec Deliberately Excludes

- **Social media automation.** Danny's system is about intelligence and operational effectiveness, not content production.
- **Multi-provider model orchestration.** The stack is Anthropic-focused with local qwen3 backup. Adding providers adds complexity without demonstrated benefit for current use cases.
- **Financial/trading automation.** Irrelevant to Danny's use case.
- **Full autonomy (human-out-of-the-loop).** The architecture deliberately keeps HITL gates via mechanical enforcement. This is a feature, not a limitation to overcome.
- **Cross-vault / cross-tenant agent communication.** Interesting but premature. No counterparty agents exist to talk to yet. Revisit if OpenClaw community develops peer-to-peer patterns.
- **Smart home integration.** Out of scope.
- **Formal message envelope / schema registry.** The dispatch protocol's existing state files carry essential metadata. A canonical JSON-RPC envelope with versioned payloads is framework-first thinking that contradicts P5. If the system outgrows grep-based correlation and file-based state, revisit. Don't build the abstraction before the pain is real.
- **Distributed systems infrastructure.** CRDTs, message buses (NATS/MQTT), capability tokens (macaroons), policy engines (OPA), workload identity (SPIFFE/SPIRE) — all designed for multi-host, multi-tenant, adversarial environments. This is a single-user, single-machine, local-filesystem system. Revisit if the architecture goes multi-host.
- **Self-evolving agent workflows.** Genetic-algorithm-inspired trajectory optimization, automated A/B testing of workflows, and similar meta-learning approaches require sample volumes this system won't reach for months. The dispatch learning log (§3.5) provides the manual-first version. Automate when there's enough data to detect differences from noise.
- **Digital twin of operator cognitive state.** Inferring cognitive load from calendar density and Telegram response latency requires building a behavioral model from extremely sparse signals. A manual "heads down, batch everything" mode toggle provides 95% of the value. Build the toggle; skip the inference.

---

## Appendix A: Source Analysis Summary

This specification synthesizes research and analysis from eight sources:

| Source | Primary Contribution |
|--------|---------------------|
| Agent-to-agent draft (Danny's initial capture) | Core 4 workflows, Zoe pattern, architectural principles, tess-operations integration points |
| Beyond-current-roadmap research | 9 novel workflow families: stall detection, session retrospective, voice calibration, decision journal, cross-domain bridging, tempo adaptation, live recall, skill acquisition, degradation routing |
| GPT-5.2 Thinking analysis | Protocol-level critique (contract net, two-phase commit, cancel semantics), council patterns, economic controls, evaluation harnesses. Key pushback: "the unlock is protocols + evaluation + economics, not message passing" |
| Claude Opus 4.6 Thinking analysis | 6 capability categories (quality patterns, learning loops, knowledge synthesis, external interop, event-driven chains, personal intelligence), architectural implications table, priority sequencing |
| Gemini 3.1 Pro analysis | Per-workflow gap analysis, 9 beyond-spec workflows, emphasis on session continuity/debrief, confidence-weighted conflict resolution, anticipatory scaffolding. Build order recommendation interleaving core + beyond-spec |
| Perplexity deep research (round 1) | Multi-agent council patterns, cross-vault collaboration, autonomous workflow health agents, long-running project shepherds, capability negotiation, safety/red-teaming agents, relationship gardening |
| ChatGPT deep research (round 2) | Infrastructure-focused: canonical message envelopes, patch-based vault writes, capability-scoped delegation, fork-join contracts, event-sourced audit logs, cross-agent citation verification. Key contribution adopted: join contract formalism for dispatch groups, correlation ID pattern, critic skill citation verification pass |
| Perplexity deep research (round 2) | Capability-focused: self-improving dispatch templates, cross-session memory consolidation, multi-agent debate, autonomous project health, confidence-weighted conflict resolution, anticipatory context assembly. Key contributions adopted: dispatch learning log, post-call feedback loop for Workflow 3, weekly cross-session synthesis, confidence-based escalation override |

**Convergent findings across all sources:**
1. Single-dispatch constraint (CTB-016 rule 12) is the primary infrastructure bottleneck
2. Feedback loops are absent and critical for quality improvement
3. Tess's context loading model needs explicit design
4. Adversarial/critic review patterns improve quality more than adding more workers
5. Cost management becomes a first-class problem as workflows scale
6. The file-based transport layer is correct and sufficient — the work is in protocols and evaluation, not plumbing
7. Orchestrator model capacity (Haiku vs. Sonnet) must be explicitly addressed as Tess's responsibilities expand
8. Failure modes at the orchestration layer (stale context, bad quality judgments, re-dispatch loops) need safeguards equivalent to what CTB-016 provides at the dispatch layer

**Divergent recommendations resolved in this spec:**
- GPT-5.2 advocated for contract net / bidding protocols. This spec defers formal bidding in favor of Tess's deterministic routing with cost-aware model selection (simpler, sufficient for current agent count).
- Perplexity advocated for cross-vault agent communication. This spec explicitly excludes it as premature (no counterparty agents exist).
- Gemini recommended slotting session continuity (#11) ahead of Workflow 2 in build order. This spec keeps Workflow 2 first because it has a clearer infrastructure dependency chain (researcher-skill M5), while session continuity (TOP-047) is already planned independently within tess-operations.
- ChatGPT deep research advocated for a canonical message envelope and schema registry as a horizontal primitive before any workflow ships. This spec explicitly excludes it as framework-first thinking that contradicts P5. The dispatch protocol's existing state files are sufficient until proven otherwise.
- ChatGPT deep research advocated for distributed systems infrastructure (CRDTs, OPA, macaroons, SPIFFE/SPIRE). This spec explicitly excludes them as over-engineered for a single-user, single-machine system.
- Perplexity deep research advocated for digital twin of operator cognitive state and self-evolving agent workflows. This spec defers both — the former because a manual toggle is simpler and nearly as effective, the latter because sample volumes are insufficient for meaningful A/B testing.
