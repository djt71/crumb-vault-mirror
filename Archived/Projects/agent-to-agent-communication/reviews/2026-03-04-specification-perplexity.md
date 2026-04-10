---
type: review
review_type: peer-review
review_mode: full
scope: specification
project: agent-to-agent-communication
domain: software
skill_origin: external-review
created: 2026-03-04
updated: 2026-03-04
status: active
reviewer: perplexity/sonar-reasoning-pro
tags:
  - review
  - agent-communication
  - architecture
---

# Agent-to-Agent Communication — Peer Review (Perplexity)

**Reviewer:** Perplexity Sonar Reasoning Pro (manual submission via claude.ai relay)
**Scope:** Full specification review — adversarial, findings-only format
**Materials reviewed:** specification.md (formal spec, 25 tasks)

**Note:** This review was submitted manually. The reviewer had access to the formal specification.md (unlike the Opus external review which worked from the input spec + design notes).

---

Below is the adversarial review you asked for, focused only on findings that would change design or implementation. All items are tagged as **[critical]**, **[significant]**, or **[minor]**.

***

## 1. Architectural coherence (blackboard + file bridge)

### 1.1 Blackboard vs. orchestration complexity

**Finding [significant]:** The blackboard pattern is doing double duty as both (a) long-term knowledge store and (b) short-lived orchestration scratchpad, but you only explicitly design for (a). Your workflows assume that Tess can cheaply reconstruct "what's in flight" from dispatch state files and vault context, but you don't define any lifecycle or garbage-collection for orchestration artifacts (briefs, partial outputs, scratch notes).

Impact:

- Over time, `_openclaw/state` and related orchestration artifacts will accumulate and slow grep-based introspection and debugging.
- There's no clear distinction between "durable knowledge" and "ephemeral coordination state," which makes later changes (e.g., external agents, new workflows) harder.

Change:

- Define a strict split:
  - **Durable:** vault notes, account dossiers, compound insights, research outputs.
  - **Ephemeral orchestration:** dispatch state files, temporary planning artifacts, scratch prompts.
- Add a simple retention policy: e.g., dispatch state + ephemeral orchestration state older than N days are archived or compacted into monthly summary logs.

### 1.2 Single-threaded Crumb vs. multi-dispatch and advanced patterns

**Finding [critical]:** The spec treats "multi-dispatch" and patterns like Research Council as concurrent / parallel in concept, but your actual execution environment is strictly single-threaded for Claude Code sessions. That means "3 concurrent per group" is not concurrency, it's just "up to 3 queued branches" with serialized execution.

Impact:

- The mental model you encode in join contracts ("concurrent branches", "timeout behavior") doesn't match reality; timeouts will be dominated by queueing delays, not true parallel fetching.
- For Workflow 3 (SE Account Prep), "parallel vault-query ∥ external-research" is actually "sequential with some ordering," which matters if you're trying to meet deadlines (e.g., deliver ≥20 minutes before a meeting).

Changes:

- Make the concurrency model explicit: "At most one Crumb dispatch is executed at a time; 'multi-dispatch' refers to multiple in-flight dispatches with interleaved state, not parallel execution."
- In join contracts, require Tess to estimate "wall-clock time given serialized execution" and factor that into deadlines, especially for SE prep.
- Remove "3 concurrent per group" as a concurrency concept and restate it as "maximum 3 branches per group" to avoid misleading yourself.

### 1.3 Blackboard "ownership" of facts vs. Tess's authority

**Finding [significant]:** Tess is the orchestrator and governor, but the spec is silent on what happens when a worker writes conclusions that conflict with Tess's view of context. You only specify conflict resolution for external information (§11.4), not intra-vault or intra-agent contradictions.

Impact:

- Example: Researcher writes a conclusion that contradicts existing account dossier info; Tess may later treat both as equally valid unless you encode a priority rule.
- SE account prep workflow explicitly prefers vault facts over external research but does not have a general "source precedence" rule outside that workflow.

Changes:

- Add a "source precedence" rule for internal knowledge:
  - E.g., in absence of explicit override, `_system/` specs > account dossiers > recent research > older research.
- Tie this into Tess's conflict-resolution schema, not just research conflicts.

***

## 2. Infrastructure prerequisites: gaps and overreach

### 2.1 Multi-dispatch as a prerequisite

**Finding [critical]:** You elevate "multi-dispatch" to a core infrastructure prerequisite (§8.5, A2A-013) that gates Workflow 3, but given the single-threaded constraint, its main value is orchestration semantics, not performance.

Impact:

- You're taking on significant complexity (group state files, join contracts, flock semantics, protocol amendments) for relatively little benefit in this environment.
- For Workflow 3, you could achieve almost the same behavior with a simple two-step sequential dispatch plus explicit synthesis and timeout logic.

Changes:

- Demote "multi-dispatch" from a generic infra prerequisite to "Workflow-3-specific orchestration pattern" initially.
- Implement Workflow 3 in Phase 2 using a simple pattern:
  - Dispatch `vault-query`.
  - Dispatch `external-research`.
  - Synthesize with explicit "what if one side fails/ times out?" logic, but no generic dispatch-group abstraction yet.
- Only introduce CTB-016 multi-dispatch amendments if you later pursue Research Council or cascading chains at real scale.

### 2.2 Tess context model and refresh cadence

**Finding [significant]:** You assume a daily refresh of `tess-context.md` is sufficient and treat "stale > 24h" as a warning, but some workflows (especially SE prep and time-sensitive research) may require more frequent updates, and you don't specify how Tess should behave under stale context conditions beyond warning.

Impact:

- Tess might proceed with decisions based on obviously stale account priorities or commitments while only emitting a "warning" that you'll likely ignore in practice.
- This undermines the authority model: "HITL is a feature" but you haven't described when stale context forces escalation or re-briefing.

Changes:

- Add a rule: For workflows tagged "time-sensitive" (e.g., account prep within 24h of a meeting), if `tess-context` is older than X hours (say 6-12h), Tess must:
  - Either refresh context as a pre-step, or
  - Explicitly escalate or at least downgrade confidence and require human acknowledgement.
- Distinguish "soft stale" (>24h, warn) vs "hard stale" (>N days, certain workflows disallowed).

### 2.3 Feedback + learning log coupling

**Finding [significant]:** You treat feedback ledger and dispatch learning log as separate infra pieces but don't define a strict causal relationship between them.

Impact:

- You risk having dispatches with learning log entries but no feedback, or feedback entries that are never reflected in learning patterns.
- That breaks your "observed cost precedes manifest cost" rule if learning log coverage is partial.

Changes:

- Define a mechanical rule: a dispatch learning log entry is only created/updated when:
  - A dispatch completes, and
  - A feedback ledger entry exists (or a timeout period passes and is logged as "no-feedback" outcome).
- Distinguish "no-feedback yet" vs "no-feedback after window" in outcome_signal.

***

## 3. Workflow feasibility and blind spots

### 3.1 Workflow 1: Compound Insights

**Finding [significant]:** The dedup strategy is purely exact match + simple temporal window; there's no guard against "insight spam" when feed-intel signal scoring is noisy.

Impact:

- You can meet "max 5/day" while still spamming low-value or repetitive insights, and your acceptance criteria don't require utility, just structural correctness.
- This will pollute the vault and degrade your trust in the system.

Changes:

- Add an explicit "minimum utility threshold" based on feedback:
  - E.g., if compound insights from a given source or pattern receive >X% "not useful" feedback over the gate period, Tess reduces or disables that pattern automatically.
- During gate, treat "not useful" feedback as a hard signal to alter routing, not just a retrospective metric.

### 3.2 Workflow 2: Research pipeline

**Finding [critical]:** The trigger "Tess-identified research need" is underspecified and open-ended.

Impact:

- Tess may trigger research workflows frequently and unnecessarily, especially as you add more advanced awareness, which can:
  - Drive up cost.
  - Generate noise in the vault.
- You have no guardrail beyond cost-aware routing (later) and the HITL model, but this workflow is Phase 1b and might get ahead of your cost controls.

Changes:

- Constrain Tess-initiated research to:
  - Requests where the brief would be used by an existing active workflow (e.g., account prep, compound insight clarification).
  - Or where there is an explicit "investigate" flag from feed-intel or mission control.
- Add a simple daily cap for Tess-initiated research and log when it's hit.

### 3.3 Workflow 3: SE Account Prep

**Finding [critical]:** Timing guarantees are aspirational but not enforceable given single-threaded Crumb and no preemption.

Impact:

- You state "delivered >= 20 min before calendar events" and "deadline-aware: if meeting < 30 min, deliver partial," but the spec does not:
  - Model expected wall-clock runtime of vault-query and external-research dispatches.
  - Account for backlog from other workflows (compound insights, other research jobs).
- You can easily find yourself starting account prep too late and delivering just-in-time or late, violating the spec promise.

Changes:

- Explicitly integrate runtime statistics from the dispatch learning log into scheduling:
  - Tess should compute "expected time to complete account prep" based on historical averages and use that to decide whether to initiate or escalate.
- Add a precondition: account prep trigger is only honored if there is enough expected time slack; otherwise, Tess escalates with a "too late to fully prep" notice.

### 3.4 Workflow 4: Vault Gardening

**Finding [significant]:** The tiering model assumes detection is perfect and doesn't address false positives in auto-fix.

Impact:

- Tier 1 auto-fix for "deterministic" errors (broken wikilinks, etc.) is only safe if detection is truly deterministic and non-destructive, which is rarely true in practice.
- Risk of silent corruption of your knowledge graph (links rewired incorrectly, pages split or merged badly).

Changes:

- Tighten Tier 1 definition: only allow auto-fix operations that are:
  - Purely additive (e.g., adding missing backlinks) or
  - Proven non-destructive via tests (e.g., reformatting frontmatter).
- For anything that moves or deletes content, treat as Tier 2 or 3 with explicit approval.

***

## 4. Capability-based skill dispatch model

### 4.1 YAGNI vs timing

**Finding [significant]:** Capability-based dispatch is likely *correctly* timed for your trajectory, but you're not using it in Workflow 1 and you only have one real capability (`external-research`) in play initially.

Impact:

- You risk spending a lot of time on capability manifests and resolution logic before you have enough skills to benefit from substitution.
- The learning log and feedback infra are higher leverage early on.

Changes:

- For Phase 1b, constrain capability dispatch to exactly one capability (`external-research`) and one concrete alternative skill (e.g., a future lighter-weight research skill) before adding more complexity.
- Defer manifest fields that you're not immediately using (e.g., `required_tools` or granular `quality_signals`) until you have at least two consumers that need them.

### 4.2 Substitution test and incompatible qualities

**Finding [critical]:** The substitution test ensures that a capability isn't trivially unique, but you don't define what to do when two skills with the same capability are *not* interchangeable in quality (e.g., high-rigor slow vs. fast low-rigor).

Impact:

- Tess's selection rules (learning log, cost, quality signals, model tier) don't encode "fit for purpose" by default.
- You may inadvertently route a high-stakes research job to a "cheap & shallow" research skill because it has good cost metrics, unless the brief encodes rigor and the capability resolution respects it.

Changes:

- Extend capability manifests and brief schemas with an explicit "rigor profile" dimension:
  - Skill manifest: `supported_rigor: [quick, standard, deep]`.
  - Brief: `rigor: quick | standard | deep`.
- Update resolution rules: Tess must only consider skills whose `supported_rigor` includes the brief's `rigor`; then apply cost + learning-log criteria.
- Treat "calling a skill with incompatible rigor" as a design-time error.

### 4.3 Capability ID naming and evolution

**Finding [significant]:** Capability IDs are under-specified; you rely on exact match but don't define format, namespacing, or evolution.

Impact:

- Mild but real risk of "external-research", "external_research", "research.external" fragmentation as you add more skills.
- Renaming a capability later will be painful because workflows refer to capability IDs in their specs and briefs.

Changes:

- Define a canonical format, e.g.:
  - `domain.purpose.variant` -> `research.external.standard`, `vault.query.facts`, `review.diff.code`.
- Prohibit synonyms; if you must rename, specify a migration rule (e.g., skills can declare `aliases` but Tess only emits canonical IDs).

***

## 5. Build order and phasing

### 5.1 Multi-dispatch gating Phase 2

**Finding [critical]:** You make Workflow 3 depend on multi-dispatch infrastructure (#13) even though many of its benefits can be achieved with simple sequential dispatch and explicit synthesis logic.

Impact:

- You're blocking high-ROI SE prep work on a fairly heavy CTB-016 amendment that mostly buys conceptual symmetry, not real concurrency.
- This increases schedule risk given your SE day job and limited build time.

Changes:

- Remove `A2A-013` as a hard prerequisite for Workflow 3.
- Implement Workflow 3 as:
  - Two sequential dispatches with a small orchestration function to merge results and handle missing or stale data.
  - Log it as "proto multi-dispatch" so you can later refactor into full dispatch groups if needed.

### 5.2 Mission control vs A2A maturity

**Finding [significant]:** You sequence mission control (Phase 2) after research pipeline but before vault gardening and some operational intelligence, which is reasonable, but you may be front-loading UI work before you've stabilized A2A behavior.

Impact:

- You risk reworking mission control APIs and adapters as you refine feedback, quality gating, and authority patterns.
- For a solo operator with limited cycles, you might get more leverage by delaying Phase 2 web UI until after at least two workflows + retrospective (#19) have run for a bit.

Changes:

- Consider swapping the order:
  - Finish Vault Gardening and Dispatch Retrospective before building Phase 2 mission control features.
- Or at least narrow Phase 2 mission control scope to read-only status + approvals, deferring configuration features until after retrospectives.

***

## 6. Missing failure modes and edge cases

### 6.1 Worker crash mid-dispatch

**Finding [significant]:** CTB-016 handles crash recovery and budget enforcement at the file-transport level, but the spec doesn't describe what orchestration semantics Tess should follow when Crumb crashes mid-dispatch.

Impact:

- Without orchestration-level rules, you may end up with:
  - Orphaned dispatches that never complete but remain "in progress".
  - Duplicate work if Tess naively re-dispatches.
- It also affects your cost and reliability metrics.

Changes:

- Define an orchestration-level crash policy:
  - If CTB reports a dispatch as failed with no partial result, Tess may:
    - Re-dispatch once (with same correlation_id) or
    - Escalate to Danny depending on workflow and risk tier.
  - Log crash events in dispatch learning log as a distinct outcome.

### 6.2 Partial outputs and retries

**Finding [significant]:** For re-dispatch after a structural failure (quality gate), you don't specify whether Tess should send the same brief, a modified brief, or re-use partial outputs.

Impact:

- Sending the exact same brief repeatedly after the same error can lead to repeated failures (e.g., if it's caused by incorrect assumptions or ambiguous wording).
- You also miss the opportunity to shrink scope on re-dispatch to save cost.

Changes:

- Add a simple re-dispatch strategy:
  - First failure: Tess refines the brief using learning log + critic feedback (if available).
  - Second failure: either:
    - Try alternative skill with same capability, or
    - Escalate if none exists.
- Log reason for each re-dispatch (e.g., "format failure", "citation failure").

### 6.3 Approvals lost or delayed across channels

**Finding [minor]:** You specify first-response-wins and idempotency for approvals, but not what happens if a channel fails to deliver the approval request or if mission control is down.

Impact:

- Small risk that you'll block on "waiting for approval" when your primary channel is temporarily broken.

Changes:

- Define that "availability of any one configured channel is sufficient to proceed"; others are best-effort, and failures are logged but non-fatal.
