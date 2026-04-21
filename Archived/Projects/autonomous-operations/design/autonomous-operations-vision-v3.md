---
type: design
status: active
domain: software
project: autonomous-operations
created: 2026-03-11
updated: 2026-03-11
---

# Autonomous Operations Vision for Crumb/Tess

> **Document type:** Pre-spec conceptual model. Establishes ontology, design philosophy, reference analysis, and phased roadmap for the autonomous operations layer of Crumb/Tess. Not a spec — but shapes the ontology that specs will use.
>
> Created: 2026-03-11
> Sources: @elvissun build-in-public series, OpenClaw docs, karpathy/autoresearch, GPT peer review session
> Reviewed: 4-model peer review (DeepSeek V3.2, Gemini 3 Pro, Perplexity Deep Research, ChatGPT Deep Research). 7 must-fixes and 9 should-fixes applied.

---

## 1. The Core Thesis

24/7 productivity is not a personality trick or a better prompt. It comes from five compounding properties:

1. **The system is always on.** Dead time disappears. Problems are noticed, ideas are captured, follow-ups happen without waiting for a human to sit down.
2. **Signal-to-action distance is compressed.** A bug, note, customer request, or metric change becomes an attention item almost immediately, with context attached, and can be committed into a task when action is warranted.
3. **Context is externalized.** Notes, decisions, customer context, prior failures, standards, and task state live outside the human head. The agent picks up from there.
4. **Most supervision is deterministic.** Scripts check whether processes are alive, whether CI passed, whether files changed. The LLM is only invoked where judgment is needed.
5. **The operator has narrowed the loop.** Tight feedback loops (ship → observe → fix → repeat) massively increase output quality.

### The Ambient Signal Principle

The system should continuously convert ambient signal into prepared work.

Not alerts. Not summaries. *Prepared work* — context assembled, ambiguity reduced, next move identified, safe parts already executed.

This principle is subject to a **throughput constraint**: prepared work must not accumulate faster than it can be consumed. Without bounded throughput (per-cycle caps, discard policies, WIP limits), "prepared work" becomes another inbox — the system creates the problem it was designed to solve.

---

## 2. Anti-Goals

This vision is **not** trying to optimize for:

- **Maximum agent count.** More agents ≠ more value. Coordination overhead is real.
- **Uninterrupted visible activity.** Constant motion without leverage is theater.
- **Autonomous action without trust boundaries.** Speed at the cost of trust is net negative.
- **Speculative infrastructure ahead of real need.** The Ceremony Budget Principle holds.
- **Quantity over leverage.** The goal is disproportionate impact, not maximum volume.
- **Replacing human judgment with throughput.** The system prepares and executes within bounds. Strategy, taste, and final calls remain human.

**Enforcement note:** In a single-operator system, the primary enforcement mechanisms are spec-first methodology, phase gates, and the operator's own discipline. These are softer than mechanical enforcement but appropriate for the context. Two anti-goals have partial mechanical enforcement once Phase 3 ships: "no autonomous action without trust boundaries" (five-property safety gate + HITL on non-safe actions) and "no replacing human judgment" (HITL gate). The remainder are enforced by convention and periodic self-audit. The most dangerous drift vector is **incremental expansion of `safe_autorun` scope** — gradual reclassification of actions from human-required to safe without formal review. A periodic boundary audit (quarterly) should review the safe-action allowlist for scope creep.

---

## 3. Ontology

These terms are used precisely throughout this document:

### Core Entities

- **Event** = an observed change or signal from any source. Events have two tiers:
  - **Fact events**: directly observable state changes (file diff, timestamp change, process status). Binary, verifiable.
  - **Inferred events**: pattern matches, anomaly detections, staleness judgments, interpretive analyzer outputs. Probabilistic, carry a confidence score.
  The attention engine should not treat these tiers with equal weight. Fact events are ground truth. Inferred events are hypotheses.

- **Attention item** = a ranked decision candidate derived from one or more events. A decision object, not an execution object.

- **Context pack** = a compact, ephemeral preparation artifact. Built on demand for the current attention cycle. Not cached indefinitely — regenerated if the item resurfaces in a later cycle. Context packs may be referenced by multiple attention items (shared, not one-to-one). Packs are immutable once built; tasks reference them by pointer and own only deltas. Packs carry dependency metadata (source file timestamps) for freshness checking. **Versioning contract:** packs referenced by any committed task become versioned durable artifacts (retained with a version ID and "supersedes" link); ephemeral regeneration applies only to packs attached to uncommitted attention items.

- **Task** = an execution unit, created only when action is committed. Has a definition of done, lifecycle status, and executor assignment. A single attention item may spawn multiple tasks with different action classes (e.g., one `safe_autorun` task to update a stale marker + one `dispatch_to_crumb` task for the actual fix). This composite decomposition is expected, not exceptional.

- **Outcome** = structured record of what happened when a task completed, failed, was abandoned, or reached a checkpoint. Outcomes may be **terminal** (task complete/failed/abandoned) or **non-terminal** (progress checkpoint on long-running work). Non-terminal outcomes are essential for domains where work is ongoing and never "done" (health habits, relationship maintenance, career positioning). If outcomes are only emitted at terminal states, the system biases toward short-horizon completable work and under-instruments the domains where attention allocation matters most.

### Key Relationships

Events produce attention items. Attention items may spawn context packs and, when committed, become tasks. Tasks produce outcomes. **Outcomes feed back as events** — a failed task creates a failure event, which may spawn a new attention item. This cycle is expected, not a bug.

**Cycle management:** To prevent cascading loops, events that originate from the current attention cycle's own actions carry a `cycle_origin_id`. The attention engine dampens re-entry: same-object events within the same cycle are aggregated, not multiplied. Escalation thresholds (max N re-entries per object before forced human escalation) prevent infinite loops.

**Event identity and deduplication:** Recurring events about the same object (e.g., "stale project X" firing daily) must be aggregated into a single attention item with rising urgency, not multiplied into N separate items. Events carry an `object_id` field. The attention engine maintains a deduplication window: if an event for the same `object_id` and `change_type` is already represented by an active attention item, the existing item's urgency is incremented rather than a new item being created.

**Stable object identity (foundational requirement):** `object_id` is the dedup key, the urgency-accumulation key, the cycle-dampening key, and the replay-correlation key. It must be a **stable identifier**, not a file path. File paths change when objects are renamed, moved, or reorganized. If identity is path-based, a rename resets urgency, breaks dedup, and corrupts replay labels. The implementation must use a stable ID (e.g., UUID in frontmatter or a content-addressable hash) with file paths treated as mutable pointers. Object rename, split, and merge must be handled as identity operations (alias/redirect) rather than new-object creation. This is a Phase 1 design decision that is expensive to retrofit.

**Off-pipeline actions:** Attention items classified as `surface_only` may be acted on informally (operator reads notification, acts hours later without committing a formal task). The learning loop has a blind spot here: these items were valuable but never transitioned through the pipeline. Two mechanisms address this: (1) a "done_no_task" explicit outcome — a one-tap affordance in the review interface where the operator marks an item as handled without creating a formal task (this is the primary signal, captured at the moment of action); (2) a "dismissed_or_acted_informally" inferred outcome based on vault-change correlation when no explicit signal was provided (secondary, lower confidence). Both are imperfect but better than treating all non-committed items as noise.

### What the Ontology Is Not

The ontology defines vocabulary and relationships, not a mandatory processing pipeline. An event does not have to march through every stage sequentially. A recurring cron action that needs no attention-item stage simply doesn't create one. The entities are conceptual boundaries, not pipeline stages that must execute in order.

---

## 4. Reference System: Elvis/Zoe

### What It Is

Elvis Sun (@elvissun) is a solo founder building Medialyst (agentic PR / media database SaaS) using an OpenClaw agent named "Zoe" as his orchestration layer. He documents the build publicly on X.

**Confidence levels on claims below:**
- ✅ = directly supported by public posts or OpenClaw docs
- 🔶 = reasonable inference from public evidence
- ⚠️ = plausible but unverified detail

### Architecture

- ✅ **Zoe is an OpenClaw instance** acting as orchestrator, not a separate product
- ✅ **Orchestrator/executor split**: Zoe holds business context and spawns downstream coding agents (Codex, Claude Code, Gemini)
- ✅ **Obsidian vault as shared memory**: meeting notes auto-sync; "zero explanation needed" when scoping features
- ✅ **Telegram as primary human interface**: notifications when PRs are ready
- ✅ **tmux sessions per agent**: each coding agent runs in its own tmux session for mid-task redirection
- ✅ **Git worktrees for parallelism**: each agent works on an isolated branch
- 🔶 **SOUL.md / AGENTS.md configuration**: likely uses OpenClaw's standard persona/directive files
- ✅ **Multi-model routing**: different models for different task types
- ✅ **Read-only prod DB access for Zoe**: coding agents never get this
- 🔶 **Cron-based proactive scanning**: Sentry errors → agents, meeting notes → feature requests, git log → changelog updates
- ✅ **JSON task registry** tracking active agent tasks with structured status

### Hardware Evolution

- Started: Mac Mini 16GB → topped out at 4-5 simultaneous agents
- Upgraded: Mac Studio M4 Max 128GB ($3,500) specifically for agent swarm capacity

### The Eight-Step Workflow (from public writeup)

1. Customer request → scoping with Zoe (vault context, no re-explanation needed)
2. Zoe spawns agent in tmux session with enriched prompt
3. Deterministic monitoring script runs every 10 minutes (no LLM, just bash checks)
4. Agent creates PR
5. Multi-model code review (Codex, Gemini, Claude)
6. Automated testing (lint, types, unit, E2E, screenshot requirement for UI changes)
7. Human review (5-10 minutes, often merge-on-sight from screenshot)
8. Merge + daily cleanup cron for orphaned worktrees

### Key Operational Pattern: The Failure Analysis Loop

When an agent fails, Zoe doesn't restart with the same prompt. She analyzes the failure with business context:
- Agent ran out of context → "Focus only on these three files"
- Agent went wrong direction → "The customer wanted X, not Y. Here's the meeting note"
- Agent needs clarification → "Here's the customer's email and company context"

Success patterns get logged: which prompt structures work for which task types.

### Security Model

- ✅ Zoe has read-only prod DB access; agents never do
- ✅ Scoped admin API access (e.g., `/admin/zoe/*` for credit topups)
- ✅ One-time access for sensitive ops (Gmail), self-revoke after completion
- ✅ Dedicated scripts over improvised bash
- ✅ Audit trails everywhere

### Business Metrics (founder-reported, not audited)

- ~50 commits/day average, peak 94 in one day
- 7 PRs in 30 minutes
- SaaS MRR grew from $300 → $420 over ~2 weeks (day 17-33)
- Agency revenue separate ($3.6k/mo)
- Cost: ~$100/mo Claude + ~$90/mo Codex

### What's OpenClaw vs. What's Elvis

Much of the apparent "custom magic" is standard OpenClaw capability operated well. By March 2026, OpenClaw natively supports multi-agent routing, session spawning, cron/heartbeat scheduling, typed tools, skills, per-agent sandbox/tool controls, and Obsidian integration. The "Zoe" story is partly branding, partly good systems design, partly platform maturity.

### Disposition for Crumb/Tess

| Pattern | Disposition | Notes |
|---|---|---|
| Orchestrator/executor context split | **Adopt** | Already exists as Tess/Crumb split. Strengthen context-injection at dispatch time. |
| Obsidian vault as shared memory | **Adopt** | Already core architecture. No change needed. |
| Proactive cron scanning for work | **Adopt** | Highest-priority gap. Core of attention-manager. |
| Deterministic bash monitoring (no LLM) | **Adopt** | Extend tess-mechanic scanning scope. |
| JSON task registry with completion criteria | **Adapt** | Use SQLite instead of JSON. Align with existing dashboard_actions pattern. |
| Failure analysis with context-enriched retry | **Adapt** | AKM is the mechanism but needs to surface knowledge at failure-time, not session-start. |
| Multi-model routing (Codex/Claude/Gemini) | **Defer** | Not needed until parallel execution. Current Claude-only is fine for now. |
| Git worktree parallelism | **Defer** | No product to swarm on yet. Revisit when execution loop tightens. |
| tmux-based agent lifecycle management | **Defer** | Follows from parallelism. Not a current need. |
| Multi-model code review | **Reject for now** | Single-tier review is working. Added complexity not justified yet. |

---

## 5. Reference System: Karpathy's Autoresearch

### What It Is

A 630-line autonomous ML experimentation framework. An AI agent edits a single training file (`train.py`), runs a 5-minute experiment, checks whether val_bpb improved, keeps or discards the change, and repeats. ~100 experiments overnight on one GPU.

### The Four Hard Properties

1. **Narrow editable surface**: agent only modifies `train.py`
2. **Cheap repeatable evaluations**: fixed 5-minute time budget
3. **Objective score**: val_bpb (lower is better)
4. **Automatic accept/reject**: improvement → keep, regression → revert

### The Control Interface

The human edits `program.md` — a markdown file that provides context and instructions to the agent. The key insight: **the human designs the arena; the agent iterates within it.**

### Results

- 126 experiments in one overnight run; loss reduced from 0.9979 to 0.9697
- 700 autonomous changes over two days on a deeper model
- ~20 additive improvements that transferred to larger models
- 11% efficiency gain on a project Karpathy thought was already well-tuned
- Agent caught attention scaling and regularization oversights missed over two decades of manual work

### The Deeper Transfer: Evaluation-First Design

The most important import from autoresearch is not "bounded optimization loop." It is **evaluation-first architecture**: if a subsystem cannot be replayed and scored, it cannot be meaningfully improved. Therefore instrumentation is part of architecture, not an afterthought.

This means: every subsystem in the operations layer should be designed with the question "how would I replay and score this?" in mind — even if the actual autotune loop is years away.

### Disposition for Crumb/Tess

| Pattern | Disposition | Notes |
|---|---|---|
| Bounded mutation + evaluation + keep/revert loop | **Adopt (future)** | Apply to attention ranking, context-pack construction, dispatch quality, escalation policy. Not now — after production data exists. |
| program.md as human control interface | **Adopt** | Maps to skill definitions and overlay lens questions. Human programs the arena; agent iterates. |
| Fixed time/resource budget per experiment | **Adapt** | For Crumb/Tess, the "budget" is token cost and wall-clock time per attention cycle, not GPU minutes. |
| Replay store for all decisions | **Adopt (from day one)** | Log key decisions with stable IDs and pointers. See §9 for minimum viable logging scope. |
| Self-modifying system behavior | **Reject** | Autotune should modify policies within hard guardrails, never safety boundaries, path permissions, or governance rules. |

---

## 6. OpenClaw Proactive Mechanics (Reference for Tess Design)

OpenClaw has two scheduling primitives relevant to Tess's design:

### Heartbeats
- Run in the **main session** at regular intervals (default 30 min)
- Agent reads a HEARTBEAT.md checklist and works through it
- Context-aware: shares session state, knows recent conversations
- Smart suppression: if nothing needs attention, replies HEARTBEAT_OK (message suppressed)
- Batches multiple checks into one agent turn (cheaper than N separate crons)
- Configurable active hours (e.g., 08:00-22:00)

### Cron Jobs
- Run at **precise times** in isolated or main sessions
- No conversational context (isolated mode)
- Can use different models per job
- Results "announced" back to a chat channel
- Good for: morning briefings, weekly reviews, one-shot reminders

### Design Principle
Use heartbeat for **periodic awareness checks** that should stay quiet unless something matters. Use cron for **scheduled actions** that need precise timing or session isolation. Most setups use both.

### Disposition for Crumb/Tess

OpenClaw demonstrates useful proactive patterns, but its ecosystem also underscores the importance of strict tool provenance, scoped permissions, and hard review boundaries — the skills marketplace has already experienced malicious contributions, and privileged agent execution on a host OS is an inherently high-risk surface.

| Pattern | Disposition | Notes |
|---|---|---|
| Heartbeat-style periodic scanning | **Adapt** | Tess's attention cycle is the equivalent. Implement as tess-operations cron that triggers attention engine, not as OpenClaw heartbeat directly. |
| Smart suppression (HEARTBEAT_OK) | **Adopt** | Essential. No notification unless something actually matters. Noisy automation kills trust. |
| Cron for precise scheduled actions | **Adopt** | Already have cron infrastructure via LaunchDaemon. Extend with attention-manager scheduled cycles. |
| Active hours windowing | **Adopt** | Tess should not ping during SE work hours unless urgent. Configure attention delivery windows. |
| Session isolation for scheduled work | **Adapt** | Tess crons should not pollute interactive Crumb sessions. Use separate tess-mechanic context. |

---

## 7. The Crumb/Tess Delta Analysis

### Where Crumb/Tess Has Parity or Advantage

| Capability | Elvis/Zoe | Crumb/Tess | Assessment |
|---|---|---|---|
| Vault as shared memory | Obsidian with meeting notes, customer data | ~1,400 files, 3-level tag taxonomy, MOC system, structured KBs | **Structural advantage Crumb** (breadth and organization) |
| Orchestrator/executor split | Zoe / Codex+Claude+Gemini | Tess / Crumb | Parity |
| Telegram delivery | OpenClaw native | tess-voice on Haiku via Anthropic API | Parity |
| Always-on daemon | OpenClaw LaunchDaemon | LaunchDaemon on Mac Studio M3 Ultra (96GB) | Parity |
| Async coordination | JSON task registry + tmux | CTB file-based bridge with atomic writes, UUIDv7 | Parity (different mechanism) |
| Knowledge layer | Meeting notes only | Networking KB, Security KB, competitive intel, MITRE/NIST mappings | **Major structural advantage Crumb** (potential; value depends on retrieval precision) |
| Multi-domain overlays | Different "Zoe sessions" (Sales, SRE, Dev) | Formal overlay system with activation signals, lens questions, 50-line budget | **Advantage Crumb** (more rigorous formalism) |
| Code review | Multi-model (Codex, Gemini, Claude) | Single-tier code review | Advantage Elvis |
| Spec-first methodology | None visible | Design spec v2.0.2, SPECIFY→PLAN→IMPLEMENT→REVIEW | **Potential advantage Crumb** (advantage only if it accelerates rather than slows execution) |
| Security/governance | Scoped access, audit trails | CTB governance verification, HITL enforcement, kill-switches | **Stronger formal governance model** (partially operationalized; full runtime validation ongoing) |

### Where Elvis/Zoe Is Ahead

| Capability | What Elvis Has | What Crumb/Tess Needs |
|---|---|---|
| **Proactive autonomous action** | Crons scan for work, do the work, notify when done | Tess currently reactive. Attention-manager designed but not shipped |
| **Parallel agent execution** | 5+ simultaneous agents in separate worktrees | Single sequential Claude Code session |
| **Structured task registry** | JSON with machine-checkable completion criteria | dashboard_actions exists but scoped to FIF triage only |
| **Deterministic monitoring** | Bash script every 10 min, no LLM cost | tess-mechanic exists but scanning scope narrow |
| **Failure analysis loop** | Context-enriched prompt rewriting on failure | AKM exists but surfacing at wrong moment (session-start vs failure-time) |
| **Product revenue generating signal** | $420+ MRR, real customers, real feedback | No product yet (SE work is primary) |

---

## 8. The Blueprint: From Mythology to Mechanism

### Target State

Tess is continuously doing six things:
1. **Watching** for signal
2. **Deciding** what matters
3. **Preparing** work
4. **Executing** safe work
5. **Tracking** in-flight work
6. **Escalating** only when needed

### Mapping to Existing Primitives

The subsystems below describe the conceptual architecture. Several already have partial or full implementations in the current system:

| Subsystem | Existing Primitive | Relationship |
|---|---|---|
| §8.1 Signal Ingestion | Project-state.yaml files, FIF promoted items, vault-check.sh | Phase 1 sources. Currently scanned by attention-manager skill during daily procedure (steps 2-4). No formal event normalization yet. |
| §8.2 Attention Engine | **attention-manager skill** (`.claude/skills/attention-manager/SKILL.md`) | **This is Phase 1.** The shipped skill is the attention engine. Daily procedure produces ranked attention items as the daily-attention artifact. |
| §8.3 Context-Pack Builder | "Why now" + "Source" fields in daily-attention artifact | Phase 1: daily artifact fields only. Full context packs (assembled files, prior attempts, constraints) are Phase 2+. |
| §8.4 Safe-Action Layer | Not yet implemented | Phase 3. |
| §8.5 Dispatch Layer | CTB dispatch protocol (`crumb-tess-bridge`) | Existing infrastructure handles Tess→Crumb handoff. Dispatch envelopes would extend the CTB protocol with DoD and context-pack references. |
| §8.6 Task Registry | `dashboard_actions` SQLite table (mission-control) | Partial analog. dashboard_actions tracks FIF triage actions. A general task registry would follow the same SQLite pattern but with broader scope. |
| §8.7 Deterministic Monitor | `tess-mechanic` (local Qwen), vault-check.sh, awareness-check.sh, vault-health.sh | Existing scripts are the deterministic monitor. tess-mechanic is the interpretive analyzer. Scope expansion needed, not new infrastructure. |
| §8.8 Learning Loop | Run-logs, AKM knowledge-retrieve.sh | Precursors. Run-logs capture session narratives. AKM attempts knowledge surfacing. Neither produces the typed residue described here. Phase 2+. |

### The Subsystems

#### 8.1 Signal Ingestion Layer
Captures events from multiple sources and normalizes them into structured records.

**Phase 1 scope:** No formal event normalization layer. The attention-manager skill directly scans project-state files, goal-tracker, and SE inventory during its daily procedure. Event record shape, triage layer, and overload mechanics are future-phase design. Phase 1 validates that the right sources are being scanned and that the ranking input is useful.

**V1 sources** (start narrow): vault changes, FIF promoted items, run-log patterns, stale scratch items

**Future sources**: meeting notes, product backlog, external alerts (Sentry), customer feedback

**Event record shape:** source, timestamp, object_type, object_id, change_type, summary, raw_pointer, confidence, requires_reasoning, event_tier (fact | inferred), cycle_origin_id (null for external events)

**Scaling note:** At 2-3 sources, linear scanning per cycle works. At 30+ sources, a **triage layer** is required: deterministic pre-filtering (file modification timestamps, change magnitude) followed by LLM ranking of only the survivors. The current architecture does not include this triage layer. It is a known future requirement that should be addressed before source expansion beyond ~15 sources.

**Source expansion protocol:** Adding a new signal source requires: (1) a scanner implementation, (2) event normalization mapping to the standard record shape, (3) validation that the new source's event volume doesn't exceed the cycle's throughput budget. Source expansion is a design decision, not just a configuration change.

**Overload mechanics (must be defined before scaling beyond ~15 sources):** The throughput constraint in §8.2 says what the budget is. The following questions define what happens when the budget is violated at runtime — these are unanswered in Phase 1 (acceptable at 2-3 sources) but must be resolved before source expansion:
- **What gets dropped?** Low-priority events below a threshold, or the oldest unprocessed events, or events from sources that have already consumed their per-source quota?
- **What gets deferred?** Are deferred events retried next cycle, or rolled up into a summary event ("12 low-priority changes in project X since last cycle")?
- **What gets rolled up?** During burst activity (refactors, bulk edits), can multiple file-change events be coalesced into a single "session edit" work unit with multiple pointers?
- **How does the operator know something was shed?** A low-cost "tail log" of dropped/deferred events should exist for forensic review, even if those events never reach the attention engine. Silent loss is the failure mode that kills trust.

#### 8.2 Attention Engine
Transforms raw events into ranked attention items (decision objects, not execution objects).

**Phase 1 scope:** The shipped attention-manager skill IS this subsystem. Daily cycle, 5-8 items, overlay lenses, carry-forward mechanics. Daily cadence is a Phase 1 constraint that will tighten in later phases — it is not the target state. Action_class field, dedup, and replay logging are Phase 1 additions to the existing skill; everything else below (composite decomposition, reclassification, throughput eviction) is documented for coherence but ships in Phase 2+.

**Tess asks for each event:** Is this new? Important? Time-sensitive? Reversible? Actionable now? Can I prepare it? Safely execute it? Does Danny need to decide?

**Attention item shape:** attention_id, object_id, title, why_now, domain, priority, recommended_mode, deadline, dependencies, context_pack_pointer, **action_class**

**Event deduplication:** The engine maintains a deduplication window keyed on `object_id` + `change_type`. If an event matches an existing active attention item, the item's urgency is incremented rather than a new item created. This prevents recurring scans (e.g., "stale project X" daily) from generating N separate items when one with rising urgency is correct.

**action_class — routing hint, not policy engine:**
- `surface_only` — notify Danny, no prep needed
- `prepare_only` — build context pack, queue for review
- `safe_autorun` — execute within trusted boundaries
- `dispatch_to_crumb` — hand off to executor with structured envelope
- `human_decision_required` — escalate, present options

`action_class` is the **primary routing recommendation** for the item, not an exhaustive specification of all actions it may need. Real work frequently requires multiple action types: a single attention item may need a context pack (prepare), a stale-marker update (safe autorun), AND a Crumb dispatch for the actual fix. In such cases, the attention item spawns multiple tasks, each with its own execution authority. The `action_class` on the item itself indicates the *highest-authority* action required — the one that determines the approval boundary.

`action_class` is mutable. Context-pack construction may reveal that the initial classification was wrong (e.g., a `prepare_only` item turns out to need a human decision due to a discovered dependency conflict). Reclassification is permitted and expected. The replay log captures both the original and revised class with a reason code.

**Caution:** `action_class` should be treated as metadata for routing and display, not as a hard schema constraint that downstream systems branch on. If dashboards, registries, and notification logic bake in assumptions about the enum values, any future refinement (orthogonal flags, sub-classifications) becomes a breaking change.

**Throughput budget:** Each attention cycle has a bounded output: maximum N attention items surfaced (Phase 1: 5-8 per daily cycle), maximum M context packs generated (Phase 1: top-5 items). Items beyond the budget are discarded or deferred, not accumulated. The system must not build inventory faster than the operator can consume it. **The budget discards from the bottom of the ranked list, not the top.** Events are processed in priority order (fact before inferred, deadline-bearing before open-ended) so that a late-arriving high-priority signal displaces low-priority items rather than being blocked by a full buffer.

#### 8.3 Context-Pack Builder
When something matters, assemble a compact, task-ready context pack.

**Phase 1 scope:** Not a separate subsystem in Phase 1. The daily-attention artifact's "Why now" and "Source" fields are a lightweight precursor. Full context packs (assembled files, prior attempts, constraints, freshness metadata) ship in Phase 2. Pack versioning contract (durable artifacts for committed tasks) deferred to Phase 2 when the task registry exists.

**Pack contents:** what changed, why it matters, relevant files/notes (pointers not full content), related prior attempts, constraints, open questions (with explicit unknowns and confidence notes where relevant), recommended next step, suggested Crumb prompt if dispatching

**Pack freshness:** Every pointer in a pack carries a dependency timestamp (file mtime at generation time). Before a pack is consumed (by operator review or task dispatch), a lightweight freshness check compares current mtimes against recorded ones. If any dependency has changed, the pack is flagged as potentially stale. For `safe_autorun` and `dispatch_to_crumb` actions, this freshness check is **mandatory** — stale packs must not drive execution without re-validation.

**Pack types (initial, keep small):** Resume pack (stale project restart), Failure pack (recurring issue), Spec amendment pack (design drift), Opportunity pack (external research/notes). Resist proliferating pack types early — learn from usage which types actually get consumed before adding more.

**When NOT to build a pack:** Not every surfaced attention item needs a context pack. Trivial items (tag a file, move an item) should skip pack generation entirely. The threshold: if the expected action takes less effort than reading the pack would, skip the pack.

#### 8.4 Safe-Action Layer
Bounded work Tess can do without asking.

**Phase 1 scope:** Not implemented. Ships in Phase 3. Documented here for ontological completeness and to establish the five-property gate before safe actions are ever permitted.

**Every safe action must satisfy all five properties:**
1. **Reversible** — can be undone without data loss
2. **Auditable** — leaves a structured trail
3. **No external impact** — does not send messages, emails, or modify external systems
4. **Not source-of-truth** — does not modify authoritative spec/design documents. Clarification: machine-generated operational state files (project-state.yaml, dashboard summaries) are not "source-of-truth" in this context — authoritative means documents that define design intent, human decisions, or contractual commitments.
5. **Low rollback cost** — undoing it takes seconds, not a forensic investigation

Actions that satisfy all five: create backlog stubs, generate session briefs, draft changelog entries, place files in inboxes, tag and route content, refresh summaries, mark stale items for review.

Actions that violate any property require HITL.

**Boundary audit:** The safe-action allowlist should be reviewed quarterly for scope creep. The most dangerous drift is gradual reclassification of actions from human-required to safe without formal review.

#### 8.5 Dispatch Layer
When work exceeds safe-action boundary, dispatch to Crumb (or future executor).

**Phase 1 scope:** Not implemented. Ships in Phase 4. The existing CTB dispatch protocol provides the infrastructure; this subsystem extends it with structured envelopes, DoD enforcement, and freshness checks.

**Dispatch envelope:** task type, target executor, context pack (referenced by pointer, immutable; task owns only deltas), definition of done (machine-checkable), constraints, stop conditions, escalation conditions, expected artifacts, review mode (auto-merge vs. human review)

**Pre-dispatch freshness check:** Before dispatching, verify that the context pack's dependency timestamps are still current. If the triggering conditions have changed since the attention item was created, the dispatch should be flagged for re-evaluation rather than executed against stale state.

Tess should not say: "Dan wants help with X."
Tess should say: "Produce Y, using these constraints, based on these files, with this definition of done, and stop at this review boundary."

#### 8.6 Task Registry
Structured source of truth for committed execution work. Tasks are distinct from attention items — a task is created only when action is committed.

**Phase 1 scope:** Not implemented. Ships in Phase 2. Phase 1 defines only the minimum shared identity fields (attention_id, object_id) needed for future registry compatibility. The existing dashboard_actions SQLite table is the implementation template, not the registry itself.

**Task record shape:** task_id, origin_attention_id, executor, status (`queued` → `enveloped` → `dispatched` → `running` → `blocked` → `awaiting_review` → `complete` → `abandoned`), created_at, updated_at, attempt_count, definition_of_done (JSON), completion_state (JSON), artifact_pointers, blocked_reason, next_check_at, escalation_state, correlation_id (UUIDv7), parent_task_id (for composite decomposition and retry correlation)

Status notes: `queued` = task committed, awaiting preparation. `enveloped` = dispatch envelope assembled with context pack, DoD, and constraints — ready for dispatch. This is distinct from the attention item's context pack; the envelope is executor-specific.

**Registry scope:** The task registry tracks tasks this system created or dispatched. It does not attempt to track all work the operator does across all contexts. "Zero untracked tasks" means zero system-initiated tasks without registry entries, not "everything the operator does is tracked."

#### 8.7 Monitoring Layer

**Phase 1 scope:** Existing scripts (vault-check.sh, awareness-check.sh, vault-health.sh) and tess-mechanic already provide both deterministic monitoring and interpretive analysis. Phase 1 work is scope expansion (what additional checks to run), not new infrastructure. The separation below documents the architectural boundary; it doesn't require rebuilding what works.

Two distinct components that should not be merged:

**Deterministic Monitor** (bash/scripts only, zero LLM cost): Which tasks are stale? Which jobs failed? Which expected artifacts never appeared? Which deadlines are approaching? Which retries exceeded threshold? Best for: process liveness, file-existence assertions, timestamp-based staleness, retry counts, CI pass/fail — binary, observable, unambiguous checks.

**Interpretive Analyzer** (optional, local model via tess-mechanic on Qwen): Pattern clustering across recent failures. Anomaly summarization. Trend detection across attention items. Semantic file-change assessment (did this change *matter*?). Best for: targets that are semantic rather than syntactic, where bash cannot answer the question and a small model call is cheaper than maintaining a brittle parser.

Keep these separate. The deterministic monitor runs always. The interpretive analyzer runs on a slower cadence and its outputs feed into the attention engine as inferred events, not as direct actions.

**Principle restatement:** "Deterministic before intelligent" means: use deterministic checks for hard safety gates, mechanical invariants, and binary state assertions. Use model-based checks for semantic triage, novelty detection, and pattern recognition where deterministic approaches would be more brittle and expensive to maintain. This is a domain-specific heuristic, not a blanket hierarchy.

#### 8.8 Learning Loop

**Phase 1 scope:** Minimum viable logging only (§9): inputs, outputs, operator actions, override rationales. The full typed-residue schema below (failure codes, missing-context markers, pattern candidates, task-class outcomes) ships in Phase 2 when the task registry provides structured outcome data. Documented here so that Phase 1 logging decisions don't foreclose Phase 2 capabilities.

Structured, typed residue from every outcome. This is not generic memory or free-form notes. It produces:

- **Typed failure codes**: context_insufficient, wrong_direction, executor_timeout, ambiguous_spec, missing_dependency, permission_blocked
- **Missing-context markers**: what specific files, notes, or prior decisions would have prevented the failure
- **Reusable pattern candidates**: prompt structures, context combinations, or workflow sequences that succeeded
- **Task-class outcomes**: success/failure rates by task type, domain, executor, and complexity
- **Override rationales**: when Danny overrode Tess's recommendation, what was the reasoning (structured, not narrative)

Without typed residue, future replay and autotune will be weak. This subsystem is the bridge between operations and optimization.

**Confidence distinction:** Some outcome labels are directly observable (executor_timeout, permission_blocked). Others require interpretation (wrong_direction, ambiguous_spec). Future replay and autotune should weight observed signals more heavily than inferred diagnoses. When recording inferred labels, include a confidence indicator.

**Non-terminal outcomes:** For long-running, multi-episode work (health habits, relationship maintenance, career positioning, ongoing refactors), emit checkpoint outcomes at natural pause points rather than waiting for terminal completion. Without this, the learning loop biases toward short-horizon work and under-instruments the domains where attention allocation matters most.

**Zombie-thread prevention:** Non-terminal tasks that emit only checkpoint outcomes without meaningful state change for N weeks (suggested: 4 weeks) are flagged by the deterministic monitor for review. The operator either confirms continued relevance (resetting the clock) or archives the task. Without this, long-running items accumulate in the registry as perpetual "in progress" entries that bloat the outcome history and degrade learning-loop signal quality.

---

## 9. Autoresearch Pattern Applied to Crumb/Tess

### Applicable Subsystems (Future, Not Now)

| Subsystem | Editable Surface | Evaluation Method | Metric |
|---|---|---|---|
| **Attention ranking** | Scoring weights, urgency rules, surfacing thresholds | Replay past weeks of events against actual outcomes | Precision, recall on high-value items, false-positive rate, time-to-action |
| **Context-pack construction** | Pack schema, retrieval rules, compression rules | Replay old stalled tasks, measure restart quality | Token budget compliance, field coverage, restart speed, clarification frequency |
| **Dispatch quality** | Framing template, DoD style, stop conditions | Measure executor success from historical dispatches | Completion rate, retry count, review burden, artifact conformity |
| **Escalation policy** | Retry limits, stale thresholds, timing | Replay blocked task history | False/missed escalation rates, resolution time |

### The Scoring Problem

Every reference system that successfully compounds has a clear objective function: Elvis optimizes "ship faster," Karpathy optimizes val_bpb. Crumb/Tess attempts to optimize "allocate finite attention across 8 life domains" — but there is no objective function for that today. The attention engine ranks items by LLM judgment, not by a scoring function.

**Proxy scoring signal (define before replay logging is finalized):** An attention item is scored as *valuable* if: (a) the operator acted on it within 48 hours (from vault-change correlation or task creation), AND (b) the operator did not override its priority ranking. An item is scored as *noise* if it was surfaced but never reviewed, or reviewed and dismissed. An item is scored as *missed signal* if the operator acted on something that was NOT surfaced but should have been (detectable retroactively from vault changes that weren't preceded by an attention item). This proxy is crude but computable, and it gives the autotune loop something to optimize against.

**Known limitation — horizon bias:** The 48-hour acted-on window is systematically biased against long-horizon domains (health, relationships, creative, spiritual, career positioning). These items rarely produce an observable vault change within 48 hours of being surfaced — a health habit intention or relationship investment doesn't generate a file diff the way "fix this bug" does. Under the unmodified proxy, these items would systematically score as noise even when they're the most valuable items on the list. If autotune eventually optimizes against this signal without correction, it will push the system toward exactly the short-horizon operational bias it was built to counteract.

**Counterweight:** Items in non-operational domains should be scored on a different timescale: acted on within 7 days, or represented as a checked-off item in a subsequent daily artifact, or referenced in the monthly review's goal-alignment assessment. The monthly review (§8.8 of the attention-manager skill) is the natural evaluation surface for these domains, not the daily action cycle. The proxy scoring signal should be domain-aware: operational domains (software, career-tactical) use the 48-hour window; developmental domains (health, relationships, creative, spiritual, career-strategic) use the 7-day window and monthly-review representation.

Without at least a proxy scoring signal, the autotune vision is aspirational — well-instrumented but unscoreable. Without the horizon-bias counterweight, the proxy becomes an engine for the short-termism the system was designed to resist.

### Minimum Viable Logging (Phase 1)

The full learning-loop schema (§8.8) is the eventual target but imposes unnecessary burden on Phase 1. Phase 1 should log:

- **Inputs**: list of sources scanned, timestamp, cycle ID
- **Outputs**: attention items produced with scores and action_class assignments
- **Operator actions**: which items were reviewed, acted on, dismissed, or ignored (via Telegram interaction or vault-change correlation)
- **Override rationales**: brief structured note when the operator overrides priority or action_class (this is captured at review time and is cheap; it cannot be backfilled later)

Skip typed failure codes, missing-context markers, and task-class outcomes until Phase 2 when the task registry provides structured outcome data. The ground truth needed to score attention decisions (what was actually acted on and whether it had impact) partially depends on Phase 2 infrastructure. Phase 1 logs decisions and operator actions; Phase 2 backfills outcome linkage.

### When to Build Autotune

Not now. After the attention engine has been running in production for weeks/months generating real event-decision-outcome data with scored outcomes. The first target should be attention ranking.

---

## 10. Build Sequence

### Implementation Discipline Warning

This document describes the conceptual model for a multi-phase system. It is deliberately rich — event tiers, cycle dampening, composite tasks, non-terminal outcomes, freshness checks, reclassification semantics. Each is a defensible design choice. Together, they describe a complex system.

**Do not build the complex system.** Build the simplest concrete thing that works at each phase, informed by the conceptual model but not enslaved to it. The ontology exists so that design decisions are coherent across phases, not so that Phase 1 must implement every concept described here. Most of the richness in §3 and §8 is future-phase context, not Phase 1 requirements.

The greatest threat to this vision is not a missing feature. It is the temptation to build the cathedral before the chapel. The chapel — the attention-manager skill — is already built and nearly through soak. Phase 2 is a SQLite table and a bash script. Phase 3 is an allowlist and an audit trail. Each phase should feel small when you start it. If it doesn't, you're over-building.

"Build concretely then extract" is not just a principle in §12. It is the operational contract for using this document.

### Phases 1-4: Actionable Roadmap

These phases are sequenced, scoped, and have measurable exit criteria. They represent the concrete build plan.

### Phase 1: Attention Engine + Context Packs (NOW)

**Build:** Event normalization from 2-3 sources, attention item schema with action_class and deduplication, ranking logic, context-pack generation with freshness metadata, daily review surface, minimum viable replay logging

**Exit criteria:**
- ≥80% of top-5 daily attention items receive context packs
- Median time from event to prepared item ≤ 4 hours
- False-positive rate (items surfaced that led to no action) < 40%
- All decisions logged in replay-ready format (MVL scope per §9)
- Zero duplicate attention items for the same object in the same cycle

**Note on metrics:** Phase exit criteria stated here are directional targets. Each requires a formal operational definition in the eventual spec — including what counts as "action" (manual, safe-auto, dispatch, or any), measurement method (automated log query vs. self-report), and aggregation window. Do not evaluate exit criteria against loosely defined metrics.

**Key design decisions:**
- Include `action_class` from day one (even if only `surface_only` and `prepare_only` are active)
- Log decisions in MVL scope (§9) — not the full learning-loop schema
- Define only the minimum shared identity and status fields needed for future task registry compatibility — do not finalize a full cross-phase task schema in Phase 1
- Keep signal sources narrow (2-3 sources, not 8)
- Define proxy scoring signal before finalizing replay log schema

### Phase 2: Task Registry + Monitoring

**Build:** Task registry schema with composite decomposition support, state transitions, deterministic monitor (bash), interpretive analyzer (tess-mechanic), outcome linkage to Phase 1 replay logs

**Exit criteria:**
- Stale task detection latency < 2 hours
- Zero system-initiated tasks untracked (registry covers all tasks the system created or dispatched)
- Deterministic monitor runs without LLM cost on 100% of mechanical checks
- Task data quality: ≥90% of completed tasks have structured completion_state

### Phase 3: Safe-Action Layer

**Build:** Approved safe action types, five-property safety gate with source-of-truth clarification, audit trail, rollback operations, **shadow-run validation period**

**Exit criteria:**
- Safe-action success rate (no reversal needed) > 90%
- Zero safe actions that violated any of the five properties
- Audit trail complete for every autonomous action
- Shadow-run period: Tess proposes safe actions for N days; operator accepts/rejects before granting autonomous execution. Autonomy enabled only after operator confidence threshold is met.

### Phase 4: Dispatch to Crumb

**Build:** Structured dispatch envelopes, context-pack handoff with pre-dispatch freshness check, DoD enforcement, return artifact handling, review boundary controls

**Exit criteria:**
- ≥70% of dispatched tasks complete without clarification loop
- Dispatch packages include machine-checkable DoD
- Review burden per dispatched task < 10 minutes
- Pre-dispatch freshness check catches ≥1 stale-state issue during validation period (proves the check works)

### Phases 5-7: Contingent Capabilities

These are not sequenced phases in the traditional sense. They are capabilities gated on non-technical events that may never occur or may occur in a different order. The actionable roadmap is Phases 1-4. Everything below is aspiration with directional intent.

### Phase 5: Bounded Concurrency (When Execution Loop Tightens)

Defer substantial coding parallelism until a product or similarly tight execution loop exists. Limited bounded concurrency may be useful earlier for select workflows (research lanes, documentation, concurrent prep for independent domains).

**Build:** tmux management scripts, git worktree setup, multi-session dispatch, concurrent task tracking

### Phase 6: Product-Mode Extensions (When Product Has Customers)

**Build:** External alert integration (Sentry), customer context injection, backlog-to-code pipelines, auto-drafted PR briefs

### Phase 7: Autotune (When Sufficient Operational Data Exists)

**Build:** Replay store, policy layer, candidate generator, evaluation harness, multi-metric scorer, guardrail gate, promotion flow (shadow → limited → promoted)

**Prerequisite:** Proxy scoring signal producing consistent, computable quality labels across ≥4 weeks of attention-engine operation.

---

## 11. What to Measure

| Metric | What It Tells You | Type |
|---|---|---|
| Attention items created per day | Is signal ingestion working? | Observability |
| % with context packs | Is preparation happening? | Observability |
| % acted on within window (48h operational, 7d developmental) | Are items useful or noise? | **Quality (proxy score)** |
| Median time from event to prepared item | How fast is the pipeline? | Observability |
| % of prepared items that led to real progress | Is preparation quality high? | **Quality** |
| Items surfaced but never reviewed | Is ranking producing noise? | **Quality** |
| Actions taken on items NOT surfaced | Is ranking missing signals? | **Quality (missed-signal rate)** |
| Stale task count (>72h no status change) | Is the registry honest? | Observability |
| Retry count per task type | Where is the system struggling? | Observability |
| Safe actions completed without reversal | Is autonomous work trusted? | Observability |
| Session restart time with vs. without resume pack | Are context packs actually helping? | **Quality** |

**Goodhart warning:** Metrics like "attention items created per day" and "% with context packs" can become targets that incentivize volume over leverage. Track them for observability but do not optimize for them. The quality metrics (acted-on rate, missed-signal rate, pack consumption ROI) are what matter.

---

## 12. Design Principles

**The Ambient Signal Principle.** The system continuously converts ambient signal into prepared work — within a bounded throughput model.

**Prepared beats verbose.** Output should reduce effort, not narrate effort.

**Deterministic for invariants, intelligent for semantics.** Use scripts for hard safety gates and mechanical state checks. Use model-based checks for semantic triage, novelty detection, and pattern recognition where deterministic approaches would be more brittle.

**Context packs must be compact, fresh, and skippable.** No giant summaries. Freshness-checked before consumption. Skipped entirely for trivial items.

**Every task needs a definition of done.** Otherwise the registry becomes fiction.

**Safe autonomy must be explicit and audited.** Five-property gate on every autonomous action. Quarterly boundary review for scope creep.

**Escalation should be rare and sharp.** If Tess asks too often, the spell breaks.

**Log decisions, not everything.** Minimum viable logging that preserves autotune optionality without imposing full schema burden on Phase 1.

**Build concretely then extract.** No autotune without production data. No infrastructure until it earns its place.

**Evaluation-first design.** If a subsystem cannot be replayed and scored, it cannot be meaningfully improved. Define proxy scoring signals before instrumenting.

---

## 13. The Honest Assessment

Elvis's system is optimized for **throughput on a single product** — every optimization serves shipping features faster for Medialyst. The swarm, the multi-model routing, the overnight error fixing — all of it is pointed at one revenue-generating target with tight feedback loops.

Crumb/Tess is optimized for **cross-domain coherence across 8 life domains** — SE work, knowledge practice, personal projects, product ambitions. The attention-manager, overlays, and KB layer exist because the problem isn't "ship more code" but "allocate finite attention across many valuable things."

Both are valid. The transferable patterns are operational (proactive crons, deterministic monitoring, task registries, failure analysis, context packs). The non-transferable parts are structural (swarm-for-throughput assumes a single-product focus that doesn't match the current reality).

The critical difference: Elvis can measure improvement (features shipped, MRR growth). Crumb/Tess's cross-domain optimization has no natural objective function. The proxy scoring signal defined in §9 is a partial answer — enough to make the system improvable, but domain-aware counterweights are essential to prevent the proxy from optimizing away the long-horizon domains the system exists to serve. This is an honest limitation, not a fatal flaw. The system will compound through operational discipline and accumulated context even without perfect scoring, but the autotune endgame requires making ranking quality measurable without introducing horizon bias.

The moment a product exists with real customers and real revenue, the Crumb/Tess architecture becomes a force multiplier in exactly the way Elvis's setup is — with the added advantage of a knowledge layer, formal governance, and spec-first methodology that Elvis doesn't have. Whether those structural advantages convert to operational advantages depends on execution.

**The first step is the attention-manager. Ship it.**
