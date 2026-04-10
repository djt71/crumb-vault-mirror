---
project: agent-to-agent-communication
type: specification
domain: software
skill_origin: systems-analyst
status: reviewed
created: 2026-03-04
updated: 2026-03-04
review_round: 1
review_date: 2026-03-04
tags:
  - tess
  - openclaw
  - agent-communication
  - architecture
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Agent-to-Agent Communication — Specification

**Input document:** `design/agent-to-agent-communication-input-spec.md` (796 lines, 8-source synthesis, v0.2)

## 1. Problem Statement

Danny is the manual router between Tess and Crumb. Every multi-step workflow — research, contextualize, write, deliver — stalls at human handoff points, sometimes for hours or days. This bottleneck prevents the agent ecosystem from compounding: insights that should chain automatically terminate at each handoff. The goal is to shift Tess into an orchestrator role where she holds Danny's context, dispatches scoped work to Crumb and future workers, makes intermediate decisions within defined authority, and surfaces finished artifacts through channel-agnostic delivery.

## 2. Facts

- F1. **crumb-tess-bridge is DONE.** Phase: DONE, last_gate: IMPLEMENT-to-DONE. Transport layer operational: atomic file handoff, CTB-016 dispatch lifecycle with state machine, crash recovery, budget enforcement.
- F2. **Researcher-skill M5 is complete.** 15/15 tasks done (2026-03-04). The full research pipeline is operational: Scoping → Planning → Research Loop → Citation Verification → Synthesis → Writing. This was assumed months out in the input spec — it's available now.
- F3. **Feed-intel-framework is in TASK phase.** M2 9/11 complete. Pipeline captures, triages, and delivers via x-feed-intel. Framework extraction underway.
- F4. **Customer-intelligence is in ACT phase.** Account dossier infrastructure being built (comms strategies + value cards).
- F5. **Tess-operations is in TASK phase.** Operational tasks (TOP-*) define Tess's capabilities: awareness-check, morning briefing, approval contracts.
- F6. **Tess runs Haiku 4.5 at ~$8.40/mo** (tess-model-architecture). Always-on via OpenClaw gateway.
- F7. **CTB-016 §2.3 rule 12 enforces single active dispatch.** Rule 12 is protocol-level: if another dispatch holds the flock, new dispatches fail with DISPATCH_CONFLICT. Multi-dispatch requires either a protocol amendment (Phase 4, conditional) or sequential orchestration by Tess (Phase 2, implemented).
- F8. **TOP-049 (Approval Contract)** is the prerequisite for Tier 2 HITL operations. Currently designed for Telegram inline UI.
- F9. **Telegram has a 4,096-char message limit.** Current delivery model is Telegram-only.
- F10. **Web UI proposal exists** (`x-feed-intel/design/feed-intel-web-ui-proposal.md`). Cloudflare Tunnel + Access recommended for hosting. Originally scoped for feed-intel digest; now generalizes to mission control.
- F11. **Claude `--print` automation patterns are documented** (solutions/claude-print-automation-patterns.md) — runner-owns-deterministic-fields, CLAUDE.md as durable instruction surface, hash-verify/canary-stamp, live deployment iteration budgeting.
- F12. **Distributed code architecture confirmed.** Orchestration code lands where it architecturally belongs (OpenClaw skills, bridge runner, feed-intel-framework), not in a standalone repo.
- F13. **The vault functions as a blackboard** — shared persistent knowledge substrate where workers contribute bounded results and Tess (controller) schedules and coordinates.
- F14. **Skill capabilities are not currently declared in structured format.** SKILL.md frontmatter has name, description, model_tier — but no machine-readable capability manifest. Tess cannot programmatically discover which skills can fulfill a given need.

## 3. Assumptions

- A1. **Haiku is sufficient for Phase 1 orchestration.** Routing-class and evaluation-class decisions (compound insights, feedback logging, structural quality checks) don't require Sonnet. Judgment-class decisions (escalation resolution, brief formulation) may. (Validate: Workflow 1 gate evaluation.)
- A2. **Dispatch state files + correlation IDs provide adequate traceability.** No message bus or event store needed. (Validate: if retrospectives reveal grep-based tracing is insufficient, invest in structured audit store.)
- A3. **Channel-agnostic delivery is achievable incrementally.** A delivery adapter pattern can wrap existing Telegram code without rewriting it. (Validate: confirm Telegram delivery code is localized enough to wrap.)
- A4. **Mission control can evolve from read to full control surface without rework.** The API design anticipates approval gates and dispatch controls from the start, even if the UI ships read-first. (Validate: prototype API surface before building.)
- A5. **3-day gate evaluations provide sufficient signal.** Extend per-workflow if needed. (Validate: assess signal quality after first gate.)
- A6. **Curation is the primary context strategy; capacity is the backstop.** With 1M-token windows (Opus/Sonnet 4.6 GA, Mar 2026), context availability is no longer a binding constraint. The 8K persistent context ceiling and 12K/32K situational ceilings remain as focus-driven guardrails, not capacity limits. Workflows that benefit from richer context (research synthesis, multi-project gate checks) may exceed these ceilings when the additional material demonstrably improves output quality. The curation principle holds: curated context outperforms raw capacity. But the ceilings are now soft targets, not hard limits. (Validated: A2A-013 gate, Mar 2026 — 1M GA shifts constraint regime. Reassessed for Phase 2: SE prep budget raised 16K→32K, batch dispatch sizing added at 5/batch, research cap raised to 5/day post-gate.)
- A7. **Capability-based dispatch through SKILL.md frontmatter provides sufficient skill discovery.** Passive registration (read frontmatter at decision time) works without a runtime registry or startup handshake. (Validate: if capability resolution latency becomes a problem, cache manifests.)

## 4. Unknowns

- U1. **Orchestration logic hosting.** Discrete OpenClaw skill invocations per workflow vs. unified orchestration engine. Recommendation: discrete skills called by crons — avoid the "everything in awareness-check becomes a monolith" anti-pattern. (Resolve: Phase 1 PLAN.)
- U2. **Compound insight noise ceiling.** 5/day starting guess. (Resolve: Workflow 1 gate.)
- U3. **Mission control hosting model.** Cloudflare Tunnel + Access is the leading candidate. Needs validation for the broader scope including approval gates. (Resolve: Phase 2 PLAN.)
- U4. **Mission control tech stack.** SSR templates (sufficient for read) vs. richer client (needed for real-time approvals). (Resolve: Phase 2 PLAN.)
- U5. **Multi-channel approval conflict resolution.** When approvals are available on both Telegram and web UI, how to resolve simultaneous responses? Recommendation: first-response-wins with idempotency, logged with channel provenance. (Resolve: approval contract design.)
- U6. **Discord migration scope.** Full Telegram replacement or coexistence? Notification-only or also voice? Deferred — no timeline. (Resolve: when need arises.)
- U7. **Sonnet orchestration cost.** 3-5 Sonnet calls/day estimated. (Resolve: Workflow 1 gate measurement.)

## 5. System Map

### 5.1 Components

| Component | Owner | Role | State |
|-----------|-------|------|-------|
| Tess (orchestrator) | OpenClaw gateway | Context-aware governor; dispatches work; intermediate decisions; delivers artifacts | Operational (Haiku) |
| Crumb (primary worker) | Claude Code sessions | Narrow-scope executor; governed by CLAUDE.md | Operational |
| crumb-tess-bridge | Vault + runner | Async file handoff; CTB-016 state machine | DONE |
| Feed-intel pipeline | feed-intel-framework | Capture → triage → digest → feedback | TASK (M2 9/11) |
| Researcher-skill | Crumb skill | Full research pipeline (6 stages) | M5 complete |
| Customer-intelligence | Vault + processes | Account dossiers, comms strategies | ACT phase |
| **Delivery layer** | **NEW** | Channel-agnostic delivery abstraction | Not started |
| **Mission control web UI** | **NEW** | Full control surface for Danny | Not started |
| **Feedback infrastructure** | **NEW** | Feedback ledger, correlation IDs, learning log | Not started |

### 5.2 Architecture

```
                    Danny (goal-setter, final approver)
                             │
              ┌──────────────┼──────────────┐
              │              │              │
         ┌────▼────┐  ┌─────▼─────┐  ┌─────▼─────┐
         │Telegram │  │ Mission   │  │ Discord   │
         │(current)│  │ Control   │  │ (future)  │
         └────┬────┘  └─────┬─────┘  └─────┬─────┘
              │              │              │
              └──────────────┼──────────────┘
                    ┌────────▼───────────┐
                    │   Delivery Layer   │
                    │  (channel-agnostic)│
                    └────────┬───────────┘
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

### 5.3 Dependencies

**Upstream (must exist):**
- crumb-tess-bridge DONE ✓
- researcher-skill M5 ✓
- feed-intel-framework M2 (9/11, in progress)
- TOP-009 morning briefing (tess-operations)
- TOP-049 approval contract (tess-operations)
- TOP-027 calendar integration (tess-operations, Workflow 3 only)

**Downstream (consumes this project's output):**
- Any future workflow using Tess as orchestrator
- Any future agent joining the worker pool
- Mission control web UI (consumes delivery layer API)

### 5.4 Constraints

- C1. **Solo operator.** System must reduce Danny's load, not add to it.
- C2. **Cost ceiling.** Haiku ~$8.40/mo baseline. Sonnet elevation must be budgeted.
- C3. **Single machine.** Mac Studio. No multi-host coordination.
- C4. **HITL is a feature.** Mechanical enforcement. Tess cannot bypass approval gates.
- C5. **File-based transport.** Atomic file exchange via bridge. No WebSocket/persistent connections.

### 5.5 Levers (high-impact intervention points)

- **L1. Delivery layer abstraction.** Decouples all workflows from any specific channel. Enables mission control, Discord, future channels without workflow changes.
- **L2. Feedback infrastructure.** Single prerequisite for all operational intelligence. Without feedback, no workflow can self-improve.
- **L3. Tess context model.** Orchestration decision quality is bounded by context quality. Higher leverage than adding workflows.
- **L4. Progressive trust gates.** The mechanism for expanding autonomy safely. Skipping gates undermines trust.

### 5.6 Second-Order Effects

- Mission control becomes the primary interface for Danny's entire interaction with the agent ecosystem — design decisions here have outsized downstream impact.
- Channel-agnostic delivery enables Discord migration without touching workflow logic, but also means the approval contract must be channel-independent from the start.
- Researcher-skill being ready earlier than expected (M5 done) means Workflow 2 can move to Phase 1b, not distant Phase 2.
- As Tess takes on orchestration, Haiku-vs-Sonnet becomes a recurring cost-quality trade-off needing instrumentation, not estimation.

## 6. Domain Classification & Workflow Depth

**Domain:** Software (system)
**Workflow:** SPECIFY → PLAN → TASK → IMPLEMENT (full four-phase)
**Rationale:** Cross-project orchestration architecture, new infrastructure (delivery layer, feedback systems, web UI), mechanical enforcement of authority model. Foundational system architecture.

---

## 7. Delivery Layer Architecture

### 7.1 Channel-Agnostic Delivery

All Tess-to-Danny communication flows through an abstract delivery interface. No workflow logic references a specific channel.

**Delivery intents:**

| Intent | Description | Current Channel | Future Channels |
|--------|-------------|-----------------|-----------------|
| `notify` | Short alert, status update, prompt for action | Telegram message | Discord message, web UI push notification |
| `present` | Structured artifact for review | Telegram (truncated) / doc | Web UI artifact view, Discord embed |
| `approve` | HITL gate requiring Danny's decision (AID-*) | Telegram inline buttons | Web UI approval panel, Discord reactions |
| `feedback` | Request Danny's signal on a delivered artifact | Telegram reactions | Web UI feedback buttons, Discord reactions |
| `converse` | Interactive exchange | Telegram conversation | Discord thread, web UI chat panel |

### 7.2 Delivery Adapter Pattern

```
Tess orchestration logic
    │
    ▼
┌──────────────────────┐
│   Delivery Router    │  ← Resolves intent + content → channel(s)
│   (channel config)   │
└──┬───────┬───────┬───┘
   │       │       │
   ▼       ▼       ▼
┌──────┐┌──────┐┌──────┐
│Tgram ││Web UI││Discord│
│Adapt.││Adapt.││Adapt. │
└──────┘└──────┘└──────┘
```

**Routing rules (configurable):**
- `notify` → chat channel + optional web UI badge
- `present` → web UI (primary) + chat channel notification with link
- `approve` → all active channels (first-response-wins, idempotent)
- `feedback` → channel where artifact was most recently viewed
- `converse` → chat channel

**Multi-channel approval resolution:** First response is authoritative. Other channels updated to reflect decision. Correlation ID links approval to dispatch. Channel provenance logged for audit.

### 7.3 Implementation Path

- **Phase 1:** Telegram-only with abstract interface. Workflows call `deliver(intent, content)`, not Telegram APIs. Adapter is thin but present.
- **Phase 2:** Web UI adapter. `present` and `feedback` route to web UI. Telegram gets notifications with links.
- **Phase 3:** Approval gates on web UI. `approve` routes to both channels.
- **Future:** Discord adapter replaces Telegram. Workflow code unchanged.

---

## 8. Infrastructure Prerequisites

### 8.1 Tess Context Model

**Persistent context file** (`_openclaw/state/tess-context.md`): Refreshed daily during morning briefing (TOP-009). Soft target: 8K tokens. Contains: active project list with phases and next actions, account priority tiers, open commitments, standing decision principles. The 8K target is a curation discipline, not a hard limit — with 1M model windows, exceeding it for richer operational context is acceptable when justified.

**Situational context:** Per-trigger from project-state.yaml, run-logs, dossiers. Default budgets: 12K (compound insights), 32K (SE account prep). These are focus-driven defaults — workflows may exceed them when additional context demonstrably improves output quality (e.g., research synthesis loading full source material rather than summaries). Intermediate dispatch results (e.g., vault-query output held while awaiting research dispatch) are working state, not counted against situational budgets.

**Tiered staleness model:**
- `refreshed_at` timestamp on every refresh.
- **Soft stale** (> 24h): Orchestration decisions carry warning flag. Most workflows proceed.
- **Hard stale** (> 72h): Time-sensitive workflows (Workflow 3) disallowed until refresh completes.
- **Time-sensitive override:** For Workflow 3, if context is > 6h old, Tess performs a lightweight refresh (project-state.yaml files only, not full briefing rebuild) before brief formulation — or escalates if refresh fails.

### 8.2 Feedback Signal Infrastructure

**Feedback ledger** (`_openclaw/state/feedback-ledger.yaml`): Append-only. Records: signal (useful/not-useful/edited), source channel, correlation_id, timestamp, artifact_path, workflow. No feedback = no signal (graceful degradation).

### 8.3 Correlation IDs

Every dispatch carries a `correlation_id` linking: triggering event → orchestration decision → dispatch lifecycle → feedback signal → learning log. UUID generated by Tess at orchestration decision time. Appears in dispatch state files, feedback ledger, learning log, artifact provenance metadata.

### 8.4 Dispatch Learning Log

**`_openclaw/state/dispatch-learning.yaml`:** After dispatch completes with feedback signal, Tess appends: correlation_id, workflow, brief_params, outcome_signal, pattern_note (Tess-generated). Consulted at brief formulation time (real-time learning, not periodic review).

### 8.5 Sequential Multi-Dispatch

**Constraint:** Claude Code sessions are single-threaded. CTB-016 rule 12 enforces single active dispatch via protocol-level flock. "Multi-dispatch" in this system means sequential dispatches with Tess holding orchestration context across them — not parallel execution.

**Orchestration pattern (Workflow 3):** Tess dispatches branch A (e.g., vault query), waits for completion, dispatches branch B (e.g., external research), then synthesizes results. This is implemented as sequential dispatch calls with Tess managing intermediate state — no generic dispatch-group infrastructure required.

**Batch dispatch (unlocked by 1M context):** With 1M-token windows, Tess can hold richer orchestration context across sequential dispatches. Related dispatches (e.g., multiple research items from the same feed cycle) can be batched into a single session rather than requiring separate sessions. The flock constraint (one active dispatch at a time) still applies — batching means sequential dispatches within one session, not parallel execution. Soft ceiling: 5 dispatches per batch — the binding constraint is Tess session coherence (orchestration quality degrades with accumulated state), not token capacity.

**Wall-clock implications:** Sequential execution means Workflow 3's total time ≈ sum of individual dispatch times. Tess must estimate wall-clock time from learning log averages and factor this into deadline calculations (§10.3).

**Future: Generic multi-dispatch (Phase 4, conditional).** If Research Council (§14.2) or cascading dispatch chains (§14.1) prove needed at scale, invest in CTB-016 §2.6 amendments: per-group flock, group state file, join contracts (required branches, per-branch budgets, merge policy, timeout behavior). Maximum 3 branches per group (still sequential). Only build if concrete need materializes — the simple sequential pattern handles Workflow 3 without this infrastructure.

### 8.6 Orchestration Artifact Lifecycle

**Durable artifacts** (vault-permanent): compound insights, research outputs, account briefs, account dossiers, feedback ledger, dispatch learning log.

**Ephemeral orchestration artifacts** (retention-bounded): dispatch state files, temporary briefs, scratch notes, partial outputs, group state files.

**Retention policy:** Ephemeral artifacts in `_openclaw/state/dispatch/` older than 30 days are archived to `_openclaw/state/dispatch/archive/YYYY-MM/` and compacted into a monthly summary log. Dispatch learning log entries older than 90 days are archived to a separate file (consulted only during retrospectives, not real-time brief formulation).

### 8.7 Capability-Based Skill Dispatch

**Design principle (P7): Capability-addressed dispatch.** Workflows depend on capabilities, not named skills. Skills are plugins — when a new skill comes online, it participates in workflows without rewiring orchestration logic.

**Full design:** `design/skill-plugin-architecture.md`

**Capability manifest:** Every dispatch-target skill declares a `capabilities` list in its SKILL.md frontmatter: capability ID, accepted brief schema, produced artifacts, cost profile, required tools, quality signals. Skills invoked only by the operator (startup, checkpoint, sync) are exempt.

**Capability resolution:** Tess dispatches to capability IDs, not skill names. Resolution: exact match on capability ID → select from candidates using (a) dispatch learning log patterns, (b) cost fit, (c) quality signal coverage, (d) model tier. Zero matches → escalate (fail closed). Resolution happens in Tess's orchestration layer (Option A); the dispatch runner receives a resolved skill name + originating capability ID for audit.

**Granularity heuristic (substitution test):** A capability is correctly scoped when you can name a plausible second skill that would offer it. If you can't, too narrow. If every skill qualifies, too broad.

**Brief schema registry** (`_system/schemas/briefs/`): Shared contracts defining required fields only. Optional fields are genuinely optional — established skills handle more, lightweight alternatives ignore them. Schemas emerge from practice: extract when a second skill needs the same brief type. First schema: `research-brief.yaml` extracted from researcher-skill.

**Cost data precedence:** Manifest `cost_profile` is cold-start estimate. Once the dispatch learning log (§8.4) has ≥3 data points for a capability, Tess uses observed costs. Manifest is fallback for new/untested skills.

**Adaptive quality gates:** The quality review schema (§11.1) checks only what the skill's manifest declares via `quality_signals`. A skill that doesn't produce convergence scores isn't checked for convergence.

**Scope exception:** Workflow 1 (Compound Insights) does not use capability-based dispatch. Its Crumb dispatch is a simple template-write — no plausible substitute exists. The plugin model applies to dispatches where substitution is meaningful.

**Dispatch request amendment:**
```yaml
skill: researcher                        # resolved skill name
capability: research.external.standard   # originating capability ID (for audit)
brief:
  schema: research-brief
  question: "..."
  rigor: standard
```

---

## 9. HITL Authority Model

### 9.1 Authority Tiers

| Tier | Description | Examples | Gate |
|------|-------------|----------|------|
| **Auto-approve** | Read-only vault ops, new notes/insights, searches | Compound insight writes, vault queries, context assembly | None — Tess proceeds |
| **Approval Contract (AID-\*)** | External actions, destructive vault ops, budget above threshold | Email, file moves, dispatch groups > $2/day | Danny approves via delivery layer |
| **Always escalate** | Risk escalations, conflict, customer decisions | Customer commitments, `_system/` spec changes, architectural decisions | Tess surfaces with context + recommendation |

**Channel-agnostic enforcement:** AID-* tokens delivered through delivery layer `approve` intent. The approval contract system is channel-unaware. Channel provenance is logged.

**Critical dependency:** TOP-049 prerequisite for Tier 2. Until operational, Tier 2 → Tier 3.

### 9.2 Mechanical Enforcement

Authority tiers are enforced through infrastructure, not behavioral instructions (P3).

**Tool guardrails:** Tess's dispatch requests specify allowed tools per dispatch. Workers receive only the tools their task requires — no access to delivery channels, external APIs, or vault paths outside the dispatch scope.

**Filesystem path allowlists:** Dispatch briefs include explicit path scopes. Workers write results to designated output paths only. The bridge runner validates output paths before accepting results.

**Budget thresholds for Tier 2:** Dispatches with estimated cost above a configurable threshold (starting: $2/day cumulative) require AID-* approval before execution. Budget enforcement is runner-level, not behavioral.

**Approval token contracts:** AID-* tokens carry: TTL (default 24h, configurable per workflow), idempotency key (prevents duplicate approvals from multi-channel delivery), channel provenance. Expired tokens are invalid — Tess must re-request approval.

**Kill switch:** `_openclaw/state/kill-switch` file checked before every dispatch. Present = all dispatches halted, Tess notifies Danny.

### 9.3 Escalation Auto-Resolution

- **Scope escalations:** Tess resolves using persistent context.
- **Access escalations:** Tess routes around unavailable sources with quality ceiling noted.
- **Conflict escalations:** Always escalate to Danny.
- **Risk escalations:** Always escalate to Danny.
- **Confidence override:** Low confidence on any auto-resolution → escalate regardless of type.
- **Confidence calibration:** If the account or project has fewer than N entries in the dispatch learning log, Tess escalates regardless (N calibrated during gate evaluation, starting: 3).
- **Catch-all:** If Tess cannot execute an auto-resolution for any reason, treat as Conflict escalation to Danny with error details.

All auto-resolutions logged: reasoning, context used, confidence assessment.

---

## 10. Core Workflows

### 10.1 Workflow 1: Feed Intel → Compound Insight Generation

**Why first:** Pipeline running, daily cadence, low external risk. The gap between "what was captured" and "what it means for Danny's work" is felt daily.

**Trigger:** Daily feed-intel digest cycle or high-signal item detection.

**Flow:**
1. Pipeline captures and triages (feed-intel-framework operational).
2. Items passing tier-based selection pass to Tess: all T1 items + T2 items matching active project tags. (FIF uses tier classification T1/T2/T3, not continuous scores.)
3. Tess loads persistent context, cross-references against active projects.
4. For genuine cross-references, dispatches Crumb to write compound insight.
5. Delivers via `present` intent.
6. Requests feedback via `feedback` intent.

**Compound insight schema:**
```yaml
type: compound-insight
source_item: "feed-intel item ID/URL"
cross_references: ["[[wikilink]]"]
confidence: high | medium | low
provenance:
  workflow: compound-insight
  dispatch_id: uuid
  correlation_id: uuid
  model: "model-id"
  critic_reviewed: false
```

Required sections: Signal, Cross-Reference, Implication, Source Trail.

**Dedup:** Exact match on source_item. Temporal: same cross-reference pair within 7 days → append delta. Semantic dedup deferred.

**Noise ceiling:** 5/day (calibrate during gate).

**Acceptance criteria:**
- Valid frontmatter, resolved wikilinks, vault-check passes
- Feedback signal logged per insight
- Delivery through abstract delivery layer
- Maximum 5/day enforced

**Dependencies:** A2A-001, A2A-002, A2A-003, feed-intel-framework M2.

### 10.2 Workflow 2: Research → Tess → Vault Pipeline

**Requires capability:** `research.external.*`

**Why second (promoted from distant Phase 2):** A skill declaring `research.external.*` capability exists and is operational (researcher-skill, M5 complete). The key unlock is Tess handling escalations instead of relaying to Danny.

**Trigger:** Danny's request via chat channel, or Tess-identified research need.

**Flow:**
1. Research need identified.
2. Tess formulates brief conforming to `research-brief` schema. Consults dispatch learning log.
3. Resolves `research.external.*` capability → skill. Dispatches via bridge.
4. Escalations per §9.3.
5. Quality gate (§11.1) — adaptive, checks only quality signals declared by the resolved skill.
6. Delivers via `present` intent. Requests feedback.

**Re-dispatch limit:** Max 2 re-dispatches. Third failure → escalate.

**Dependencies:** A2A-006, A2A-008, A2A-009, A2A-010, A2A-011.

### 10.3 Workflow 3: SE Account Prep

**Why third:** Highest daily-work ROI for Danny's customer role. Uses sequential dispatch with Tess-managed synthesis.

**Trigger:** Upcoming meeting (TOP-027) or manual request.

**Requires capabilities:** `vault.query.facts`, `research.external.*`

**Flow:**
1. Trigger fires.
2. Scheduling precondition: Tess estimates wall-clock time from learning log averages. Insufficient time slack → escalate with "too late to fully prep."
3. If context is > 6h stale, lightweight refresh before brief formulation.
4. Sequential dispatch (§8.5): resolve `vault.query.facts` → dispatch → resolve `research.external.*` → dispatch. Prefer vault facts, surface contradictions.
5. Tess synthesizes pre-call brief from both results.
6. Deadline-aware: if meeting < 30 min, deliver partial with flag.
7. Post-call feedback prompt.

**Staleness signal:** `last_refreshed` > 30 days → explicit warning.

**Dependencies:** A2A-008, A2A-016, TOP-027.

### 10.4 Workflow 4: Vault Gardening

**Why fourth:** Detection infrastructure exists (vault-check.sh, TOP-010). Value increases as content accumulates.

**Trigger:** Scheduled or manual.

**Flow:** Categorize findings by tier:
- Tier 1 (auto-fix): Broken wikilinks, deterministic fixes → auto-dispatch.
- Tier 2 (structural): Missing MOC entries, orphans → dispatch + review.
- Tier 3 (destructive): Archival, moves, merges → AID-* approval.

**Dependencies:** TOP-049 operational.

---

## 11. Quality Assurance

### 11.1 Quality Review Schema

| Check | Type | Pass Criteria |
|-------|------|---------------|
| Convergence score | Structural | ≥ rigor profile threshold |
| Citation verification | Structural | 0 verification failures |
| Writing validation | Structural | All 4 checks pass |
| Deliverable format | Structural | Matches brief spec |
| Length bounds | Structural | Within ±30% of target |
| Relevance | Context (Tess) | Addresses original question |

All structural pass + high convergence → auto-deliver. Structural fail → re-dispatch (within limit). Low convergence or questionable relevance → escalate.

**Adaptive gates:** Checks are filtered by the resolved skill's `quality_signals` manifest (§8.7). A skill that doesn't declare `convergence_score: true` is not checked for convergence. Relevance check (Tess judgment) always applies regardless of manifest.

### 11.2 Adversarial Review (Critic Skill)

Second Crumb instance reviews high-stakes outputs: unsupported claims, logical gaps, missing perspectives, independent citation verification. Tess decides invocation based on rigor profile, downstream impact, budget.

**Implementation:** `.claude/skills/critic/SKILL.md`. Single-stage, structured critique, severity ratings (minor/significant/critical).

### 11.3 Provenance Metadata

Every agent-generated artifact:
```yaml
provenance:
  workflow: "compound-insight | research | account-prep | gardening"
  dispatch_id: uuid
  correlation_id: uuid
  model: "model-id"
  critic_reviewed: true | false
  confidence: high | medium | low
  confidence_basis: source_authority | corroboration | recency | inference
```

### 11.4 Conflict Resolution

When contradictory information appears: identify → assess source reliability → assess recency → surface with reasoning. Don't silently choose — present the contradiction with assessment.

**Intra-vault source precedence** (default, absent explicit override):
1. `_system/` specs and design docs (highest authority)
2. Account dossiers and project-state files
3. Recent research outputs (< 30 days)
4. Older research outputs
5. Compound insights (derived, lowest authority)

This precedence applies to intra-agent contradictions (e.g., researcher writes a conclusion that conflicts with account dossier data), not just external information conflicts.

---

## 12. Mission Control Web UI

### 12.1 Vision: Full Control Surface

Mission control evolves from a read surface to Danny's primary interface with the agent ecosystem.

**Phase 1 — Read + feedback:**
- Artifact browser (compound insights, research outputs, account briefs)
- Per-item feedback actions (useful, not useful, edited)
- Feed-intel digest view (replaces Telegram's truncated digest)
- Past artifacts browsable by date, workflow, project
- Mobile-friendly responsive design

**Phase 2 — Approval + status:**
- Approval gate panel (AID-* tokens with context and recommendations)
- Active dispatch status (running, pending, completed)
- Project status dashboard (phases, next actions, stall indicators)
- Cost dashboard (MTD spend, per-workflow cost, guardrail status)

**Phase 3 — Control:**
- Dispatch requests from web UI (initiate research, account prep)
- Workflow configuration (noise ceilings, model tiers, polling frequencies)
- Feedback history and pattern visualization
- Investigation requests (feed-intel "investigate" action)

### 12.2 Architecture

- **Hosting:** Cloudflare Tunnel + Cloudflare Access. Zero-trust, accessible from anywhere, email OTP auth.
- **Stack:** Express + SSR templates (Phase 1). Evaluate client-side JS for real-time flows (Phase 2). Node.js matches existing stack.
- **Data:** Reads from pipeline data stores (SQLite, YAML/markdown, dispatch state files). No data duplication.
- **API:** RESTful. Designed for all three phases from day one, even if Phase 1 only.
- **Code location:** Within feed-intel-framework initially. Evaluate extraction when scope grows beyond feed-intel.

### 12.3 Delivery Layer Integration

Mission control is a channel adapter (§7.2). The delivery router sends `present`, `feedback`, and `approve` intents to the web UI adapter. The web UI's API writes feedback and approvals back through the same channel-agnostic infrastructure.

---

## 13. Tess Model Tier for Orchestration

| Decision Type | Examples | Model Tier |
|---------------|----------|------------|
| Routing | Dispatch write, forward artifact | Haiku |
| Evaluation | Quality gate checks, feedback logging | Haiku |
| Judgment | Escalation resolution, brief formulation, synthesis, critic decision | Sonnet |

Judgment-class calls are infrequent: estimated 3-5/day at scale. Track during Workflow 1 gate. If Haiku suffices for Phase 1 orchestration, defer Sonnet elevation.

Enforced in orchestration code, not behavioral prompting.

---

## 14. Advanced Coordination Patterns (Roadmap)

Documented to inform current design. Not initial build targets.

### 14.1 Cascading Dispatch Chains
Output of one dispatch triggers the next. Tess holds a multi-step task plan. Requires: multi-dispatch, task plan structure, intermediate result evaluation.

### 14.2 Research Council
2-3 Crumb instances with different lenses on the same question. Tess synthesizes. Only for consequential research (2-3× cost). Requires: multi-dispatch, personas, synthesis prompt.

### 14.3 Event-Driven Triggers
Agents react to environmental changes (git commits, new files, emails, high-signal items, calendar events). Lightweight event bus via fswatch. Requires: routing rules, debounce/rate limiting.

---

## 15. Operational Intelligence (Roadmap)

### 15.1 Project Stall Detection
Diagnose, don't just notify. Blocked by dependency? Scope creep? Recurring pattern? Output: single recommended next action.

### 15.2 Dispatch Retrospective
Weekly review of dispatch + feedback + learning logs. Identifies failure modes, prompt improvements, cost patterns. All changes require Danny's approval.

### 15.3 Cost-Aware Routing
Model tier by work type. Daily budget tracking. Degradation mode near ceiling. Utility scoring over time. **Cost data precedence:** dispatch learning log (observed, ≥3 data points) supersedes capability manifest `cost_profile` (cold-start estimate). Manifest is fallback for new/untested skills.

### 15.4 Degradation-Aware Routing
Model, API, data freshness, cost degradation awareness. Route around problems.

---

## 16. Proactive Awareness (Roadmap)

### 16.1 Near-Term
Post-capture compound insights, stall detection in morning briefing, anticipatory session prep (TOP-047), workflow health.

### 16.2 Medium-Term
Meeting prep auto-triggers, cross-project dependency surfacing, anticipatory project scaffolding, weekly cross-session synthesis.

### 16.3 Guardrail
Signal-to-noise test: would Danny act > 50% of the time? Measured via feedback. > 50% 👎 over gate period → disable or revise.

---

## 17. Future Architecture (Roadmap)

### 17.1 Session Continuity
Pre-session context assembly (TOP-047 via orchestration). Post-session knowledge extraction.

### 17.2 Decision Journal
Structured log of significant decisions with "change your mind" conditions. Tess surfaces when conditions are met.

### 17.3 Communication Voice Calibration
Audience-specific voice profiles from Danny's sent messages. Inform draft generation.

### 17.4 External Agent Interoperability
Monitor MCP and A2A standards. Design schemas so workers could be exposed as A2A servers. Don't implement until concrete use case.

### 17.5 Skill and Tool Acquisition
Tess discovers capability gaps → searches ClawHub, MCP servers → evaluates → proposes → Danny approves → installs. Governed by approval contract.

---

## 18. Exclusions

- Social media automation
- Multi-provider model orchestration beyond Anthropic
- Financial/trading automation
- Full autonomy (human-out-of-the-loop)
- Cross-vault / cross-tenant agent communication
- Smart home integration
- Formal message envelope / transport schema registry (brief schemas in §8.7 are capability contracts, not message transport)
- Distributed systems infrastructure (CRDTs, message buses, SPIFFE/SPIRE)
- Self-evolving agent workflows
- Digital twin of operator cognitive state

---

## 19. Build Order

### Phase 1: Foundation + Compound Insights

| # | Item | Dependencies | Notes |
|---|------|-------------|-------|
| 1 | Delivery layer abstraction §7 — Phase 1 | None | Abstract interface + Telegram adapter |
| 2 | Tess context model §8.1 | TOP-009 | tess-context.md |
| 3 | Feedback infrastructure §8.2-8.3 | #1 | Ledger + correlation IDs |
| 4 | Workflow 1: Compound insights §10.1 | #1, #2, #3, FIF M2 | End-to-end (no capability dispatch) |
| 5 | Gate evaluation — Workflow 1 | #4 operational | 3-day gate |

### Phase 1b: Research Pipeline

**Prerequisites (condition-based):**
- Capability `research.external.*` registered and smoke-tested
- Infrastructure: tess-context.md operational (#2)
- Infrastructure: feedback infra operational (#3)

| # | Item | Dependencies | Notes |
|---|------|-------------|-------|
| 6 | Capability manifest schema + first brief schema §8.7 | None | `research-brief.yaml` extracted from researcher-skill |
| 7 | Add capability manifests to existing dispatch-target skills | #6 | Researcher + feed-pipeline only; critic manifest deferred to #14 |
| 8 | Capability resolution in orchestration §8.7 | #6, #7 | Tess resolves capability → skill |
| 9 | Quality review schema §11.1 (adaptive) | #7 | Checks filtered by quality_signals |
| 10 | Escalation auto-resolution §9.3 | #2 | Scope + access auto-resolve |
| 11 | Dispatch learning log §8.4 | #5 | Real-time brief improvement |
| 12 | Workflow 2: Research pipeline §10.2 | #8, #9, #10, #11 | Capability-addressed dispatch |
| 13 | Gate evaluation — Workflow 2 | #12 operational | 3-day gate |
| 14 | Critic skill §11.2 | #12 operational | Declares `review.adversarial.standard` capability manifest |

### Phase 2: Mission Control + SE Prep

**Realistic timeline:** Phase 2 depends on tess-operations M2 (Google integration) completing for TOP-027 (calendar). The dependency chain: TOP-014 (M1 gate) → M2 (Google infra) → TOP-027. Earliest realistic start: Q2-Q3 2026. Session-effort estimates below are for the A2A work itself, not calendar elapsed time.

**Prerequisites (condition-based):**
- Capabilities `vault.query.facts` + `research.external.*` registered
- Infrastructure: account dossier schema defined (#16)

| # | Item | Dependencies | Notes |
|---|------|-------------|-------|
| 15 | Mission control — Phase 1 read + feedback §12 | #3 | Artifact browser, digest view |
| 16 | Account dossier schema | Customer-intel | Query-ready frontmatter |
| 17 | Workflow 3: SE Account Prep §10.3 | #8, #16, TOP-027 | Sequential dispatch + synthesis (no multi-dispatch prereq) |
| 18 | Gate evaluation — Workflow 3 | #17 operational | 3-day gate |
| 19 | Mission control — Phase 2 approval + status §12.1 | #15, TOP-049 | AID-* on web |

### Phase 3: Gardening + Operational Intelligence

**Realistic timeline:** Phase 3 requires TOP-049 (Approval Contract), which depends on tess-operations M1 gate pass + M2-M3 completion. Earliest realistic start: Q3 2026. Session-effort estimates are for A2A work only.

| # | Item | Dependencies | Notes |
|---|------|-------------|-------|
| 20 | Workflow 4: Vault Gardening §10.4 | TOP-049 | Tiered action model |
| 21 | Dispatch retrospective §15.2 | 2+ weeks data | Weekly pattern detection |
| 22 | Cost-aware routing §15.3 | Multi-workflow | Budget governance |
| 23 | Stall detection §15.1 | Morning briefing | Diagnosis, not notification |
| 24 | Mission control — Phase 3 control §12.1 | #19, #21 | Dispatch, config, visualization |

### Phase 4: Advanced Patterns (Roadmap)

| # | Item | Dependencies | Notes |
|---|------|-------------|-------|
| 25 | Multi-dispatch amendment CTB-016 §8.5 | #12 proven, concrete need | Only if Research Council or cascading chains warrant generic infra |

Items from §14, §16, §17. Each requires its own SPECIFY → PLAN cycle.

---

## 20. Open Questions

1. **Orchestration logic hosting:** Discrete skills per workflow vs. unified engine? (Phase 1 PLAN)
2. **Compound insight noise ceiling:** 5/day starting. (Workflow 1 gate)
3. **Mission control hosting:** Cloudflare Tunnel + Access confirmed? (Phase 2 PLAN)
4. **Mission control tech stack:** SSR vs. rich client. (Phase 2 PLAN)
5. **Multi-channel approval conflicts:** First-response-wins with TTL/idempotency. (Approval contract design)
6. **Discord timeline and scope.** (When need arises)
7. ~~**Sonnet cost.**~~ Resolved: A/B comparison (5 Haiku / 5 Sonnet) as first gate activity (A2A-005).
8. **Semantic dedup.** (When exact matching proves insufficient)
9. **Web UI code location:** In feed-intel-framework initially. (Phase 2 PLAN)

### 20.1 Deferred Review Items (tracked, not blocking)

Items from peer review round 1 (2026-03-04). Revisit at the indicated trigger point.

| ID | Item | Trigger |
|----|------|---------|
| D1 | Glossary / terminology standardization (dispatch_id vs correlation_id vs group_id) | PLAN phase |
| D2 | Gate measurement formulas (utility rate, false positive rate, minimum sample size) | Gate evaluation time |
| D3 | Artifact index for Mission Control querying | Phase 2 PLAN |
| D4 | Account dossier MVP data requirements + fallback behavior | Phase 2 PLAN |
| D5 | Per-assumption validation metrics table | Nice-to-have for traceability |
| D6 | Confidence generation logic for compound insights (Crumb sets, Tess overrides post-gate) | Workflow 1 implementation |
| D7 | Dispatch learning log pruning policy (archive entries > 90 days) | Incorporated in §8.6 retention policy |
| D8 | Quality signal versioning in capability manifests | Revisit if skill updates break gates |
| D9 | Wikilink-variant count in vault-check as entity resolution trigger | Workflow 4 implementation |
| D10 | Tighten Workflow 4 Tier 1 auto-fix definition | Incorporated in A2A-020 acceptance criteria |
| D11 | Constrain Phase 1b capability dispatch to one capability + one alternative before adding complexity | Phase 1b already scoped to `research.external.*` only |
| D12 | Automated MOC maintenance workflow — cluster detection → structural drafting → human review. MOC synthesis is unsustainable as manual-only at current note volumes. Respects locked taxonomy (propose, not create). Extends Workflow 4 scope from hygiene to knowledge graph topology. | Phase 3 (Vault Gardening) PLAN |

---

## 21. Task Decomposition

### Phase 1: Foundation + Compound Insights

**A2A-001: Implement delivery layer abstraction — Phase 1**
Risk: medium | Tags: `#code` `#architecture`
Acceptance criteria:
- Abstract `deliver(intent, content, artifact_path?)` interface defined
- Channel-neutral artifact model: vault artifact first, adapters own truncation/formatting
- Telegram adapter wraps existing delivery code
- All Workflow 1 delivery calls use abstract interface
- No workflow code branches on channel capabilities
- Canonical delivery envelope: correlation_id, dispatch_id, workflow, intent, timestamps, artifact_paths, cost, model

**A2A-002: Build Tess persistent context model**
Risk: medium | Tags: `#code` `#architecture`
Acceptance criteria:
- `_openclaw/state/tess-context.md` schema defined and populated
- Refreshed during morning briefing (TOP-009)
- Maximum 8K tokens enforced
- Tiered staleness model: soft stale (>24h, warn) vs hard stale (>72h, workflows disallowed)
- For time-sensitive workflows (Workflow 3): stale >6h → lightweight refresh (project-state.yaml files only) before brief formulation, or escalate

**A2A-003: Build feedback signal infrastructure**
Risk: medium | Tags: `#code`
Acceptance criteria:
- `_openclaw/state/feedback-ledger.yaml` operational
- Verbs: useful, not-useful, edited (with optional "What was missing?" free-text on edited)
- Correlation ID links feedback to dispatch
- Channel provenance recorded; append-only; graceful degradation
- Mechanical coupling: dispatch learning log entry created only when dispatch completes AND (feedback exists OR timeout window passes as "no-feedback" outcome)
- Distinguish "no-feedback-yet" vs "no-feedback-after-window" in outcome_signal

**A2A-004: Build compound insight workflow (Workflow 1)**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- End-to-end: feed trigger → cross-reference → dispatch → vault write → deliver → feedback
- Compound insights match schema; wikilinks resolve; vault-check passes
- Dedup: exact source_item + 7-day temporal
- Maximum 5/day (3/day during gate evaluation period); delivery through abstract layer
- Minimum utility threshold: if insights from a given pattern receive >50% "not useful" over gate period, Tess disables that pattern

**A2A-005: Workflow 1 gate evaluation**
Risk: low | Tags: `#decision`
Acceptance criteria:
- 3-day observation; measured: utility rate, false positive rate, noise ceiling adequacy
- Haiku vs Sonnet A/B comparison: 5 items each, measured as first gate activity
- Gate decision documented

### Phase 1b: Research Pipeline

**A2A-006: Define capability manifest schema + extract first brief schema**
Risk: medium | Tags: `#architecture` `#code`
Acceptance criteria:
- Capability manifest YAML schema with concrete example (researcher-skill):
  ```yaml
  capabilities:
    - id: research.external.standard
      accepts: research-brief
      produces: [research-output, citation-report]
      cost_profile:
        light: {min_usd: 0.02, max_usd: 0.10}
        standard: {min_usd: 0.15, max_usd: 0.50}
        deep: {min_usd: 0.40, max_usd: 1.50}
      supported_rigor: [quick, standard, deep]
      requires: [Bash, WebSearch, WebFetch, Read, Write]
      quality_signals:
        convergence_score: true
        citation_verification: true
        writing_validation: true
      version: 1
  ```
- ID namespace convention: `domain.purpose.variant` (e.g., `research.external.standard`, `review.structured.spec`, `feed.triage.standard`)
- No-synonym rule: exact match only, no aliases
- `_system/schemas/briefs/research-brief.yaml` extracted from researcher-skill's current brief structure
- Schema defines required fields only; optional fields documented but not enforced
- Rigor dimension: `supported_rigor` in manifests, `rigor:` in briefs. Resolution filters by rigor compatibility *before* cost/learning-log selection
- Granularity heuristic documented: substitution test
- Manifest version field for future compatibility

**A2A-007: Add capability manifests to existing dispatch-target skills**
Risk: low | Tags: `#code`
Acceptance criteria:
- Researcher-skill declares `research.external.standard` capability
- Feed-pipeline declares `feed.triage.standard`, `feed.promotion.signal`
- Obsidian-cli (or new lightweight vault-query skill) declares `vault.query.facts` capability — required for Workflow 3 (Phase 2 prerequisite)
- Operator-only skills (startup, checkpoint, sync) exempt — no manifest needed
- Critic skill manifest deferred to A2A-014

**A2A-008: Implement capability resolution in Tess orchestration layer**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- Tess reads SKILL.md frontmatter at dispatch decision time (passive discovery)
- Exact capability ID match required; zero matches → escalate (fail closed)
- Selection: filter by `supported_rigor` compatibility, then rank by (a) learning log, (b) cost fit, (c) quality signals, (d) model tier. Deterministic tiebreaker: alphabetical skill name
- Dispatch request includes resolved skill name + originating capability ID
- Cost data precedence: learning log (≥3 points) supersedes manifest cost_profile
- Calling a skill with incompatible rigor is a design-time error

**A2A-009: Implement quality review schema (adaptive)**
Risk: medium | Tags: `#code`
Acceptance criteria:
- Quality gate checks: convergence, citation, writing, format, length, relevance
- Checks filtered by resolved skill's `quality_signals` manifest; relevance always applies
- Validate researcher-skill output format against gate expectations before deployment
- Auto-deliver / re-dispatch / escalate logic; re-dispatch limit (max 2) enforced
- Re-dispatch strategy: first failure → Tess refines brief using learning log + quality gate diagnostics; second failure → try alternative skill with same capability (if exists) or escalate

**A2A-010: Build escalation auto-resolution logic**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- Scope + access: Tess auto-resolves using context
- Conflict + risk: always escalate
- Confidence override: low → escalate regardless
- Confidence calibration: if account/project has < N entries in learning log, escalate regardless (N calibrated during gate)
- Catch-all: if Tess cannot execute auto-resolution, treat as Conflict escalation with error details
- Audit trail: reasoning, context, confidence logged

**A2A-011: Build dispatch learning log**
Risk: low | Tags: `#code`
Acceptance criteria:
- `_openclaw/state/dispatch-learning.yaml` operational
- Entries: correlation_id, workflow, brief_params, outcome_signal, pattern_note, crash (distinct outcome type)
- Consulted at brief formulation time

**A2A-012: Build research → Tess → vault pipeline (Workflow 2)**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- End-to-end: request → brief (conforming to `research-brief` schema) → resolve `research.external.*` capability → dispatch → escalation handling → adaptive quality gate → deliver → feedback
- "Tess-identified research need" constrained to: briefs used by existing active workflows, or explicit "investigate" flag from feed-intel/mission control
- Daily cap for Tess-initiated research (starting: 3/day)
- Learning log consulted; re-dispatch on failure (max 2); delivery through abstract layer
- Dispatch request includes resolved skill name + capability ID
- Orchestration-level crash policy: if CTB reports dispatch failed with no partial result, re-dispatch once (same correlation_id) or escalate based on workflow/risk tier

**A2A-013: Workflow 2 gate evaluation**
Risk: low | Tags: `#decision`
Acceptance criteria:
- 3-day observation; measured: research quality, escalation accuracy, re-dispatch rate, feedback
- Gate decision documented

**A2A-014: Build critic skill**
Risk: medium | Tags: `#code`
Acceptance criteria:
- `.claude/skills/critic/SKILL.md` operational with `review.adversarial.standard` capability manifest
- Accepts `review-brief` schema (shared with peer-review, enabling Tess to choose between them)
- Structured critique with severity ratings; independent citation verification
- Invocation criteria codified (rigor, impact, budget)

### Phase 2: Mission Control + SE Prep

**A2A-015: Build mission control web UI — Phase 1 (read + feedback)**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- Express + SSR; artifact browser (filterable by date/workflow/project)
- Feed-intel digest view; per-item feedback; browsable history
- Cloudflare Tunnel + Access; mobile-friendly
- Web UI delivery adapter functional

**A2A-016: Define account dossier schema**
Risk: low | Tags: `#research` `#decision`
Acceptance criteria:
- Frontmatter schema (type, account, last_refreshed, engagement_state, products, contacts, action_items)
- Tess-queryable; staleness signal > 30 days

**A2A-017: Build SE account prep workflow (Workflow 3)**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- Sequential dispatch: resolve `vault.query.facts` → dispatch → resolve `research.external.*` → dispatch → synthesize. No multi-dispatch infrastructure required
- Tess holds orchestration context across sequential dispatches and merges results
- Briefs conform to shared schemas; capability resolution per §8.7
- Pre-call brief synthesized; deadline-aware (partial if < 30 min)
- Scheduling precondition: Tess computes expected completion time from learning log averages; insufficient time slack → escalate with "too late to fully prep"
- Post-call feedback; delivered ≥ 20 min before calendar events

**A2A-018: Workflow 3 gate evaluation**
Risk: low | Tags: `#decision`
Acceptance criteria:
- 3-day observation; measured: timeliness, completeness, feedback, cost
- Gate decision documented

**A2A-019: Build mission control — Phase 2 (approval + status)**
Risk: high | Tags: `#code`
Acceptance criteria:
- AID-* approval panel; dispatch status; project dashboard; cost dashboard
- Multi-channel approval: TTL, idempotency key, replay protection, primary channel designation
- Any one configured channel sufficient to proceed; others best-effort, failures logged but non-fatal

### Phase 3: Gardening + Operational Intelligence

**A2A-020: Build vault gardening workflow (Workflow 4)**
Risk: medium | Tags: `#code`
Acceptance criteria:
- Tiered actions: auto-fix (purely additive or proven non-destructive via tests only), structural (review), destructive (AID-*)
- Moves, deletes, content merges → Tier 2+ with explicit approval
- Schema enforcement; morning briefing summary; vault-check passes

**A2A-021: Build dispatch retrospective**
Risk: medium | Tags: `#code`
Acceptance criteria:
- Weekly review of logs; identifies failure modes, improvements, patterns
- All changes require Danny approval

**A2A-022: Implement cost-aware routing**
Risk: medium | Tags: `#code`
Acceptance criteria:
- Model tier by work type; daily tracking; 80% alert; degradation mode

**A2A-023: Build stall detection**
Risk: low | Tags: `#code`
Acceptance criteria:
- Detects: unchanged next_action, no commits, no run-log entries
- Diagnoses cause; outputs single recommended action; surfaced in morning briefing

**A2A-024: Build mission control — Phase 3 (control)**
Risk: high | Tags: `#code`
Acceptance criteria:
- Dispatch initiation from web; workflow config; feedback visualization; investigation requests

### Phase 4: Advanced Patterns

**A2A-025: Amend CTB-016 for multi-dispatch (conditional)**
Risk: high | Tags: `#code` `#architecture`
Acceptance criteria:
- Only pursue if Research Council or cascading dispatch chains prove needed
- CTB-016 §2.6 added; runner supports per-group flock + state file
- Join contracts: required branches, budgets, merge policy, timeout behavior
- Maximum 3 branches per group (sequential execution, not parallel); default remains single-dispatch
