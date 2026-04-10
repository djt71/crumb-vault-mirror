---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/agent-to-agent-communication/design/action-plan.md
artifact_type: action-plan
artifact_hash: 1c1bfee8
prompt_hash: 4443e841
base_ref: null
project: agent-to-agent-communication
domain: software
skill_origin: peer-review
created: 2026-03-04
updated: 2026-03-04
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "Soft: 'customer' keyword in action-plan.md:167 (customer-intelligence dossiers reference, not actual customer data)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 62558
    attempts: 1
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 49746
    attempts: 1
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 164796
    attempts: 2
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 30836
    attempts: 1
    raw_json: Projects/agent-to-agent-communication/reviews/raw/2026-03-04-action-plan-grok.json
status: active
tags:
  - review
  - peer-review
---

# Peer Review: Action Plan (Agent-to-Agent Communication)

**Artifact:** Projects/agent-to-agent-communication/design/action-plan.md
**Supplementary:** tasks.md, action-plan-summary.md
**Mode:** full
**Reviewed:** 2026-03-04
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning
**Review prompt:** PLAN phase evaluation — milestone ordering, spec fidelity, task atomicity, feasibility, risk coverage, consistency, critical path analysis

---

## OpenAI (gpt-5.2)

- [F1]
- [Severity]: STRENGTH
- [Finding]: Milestone ordering is broadly correct: M1 (infra) -> M2 (W1) -> gate -> M3 (capabilities/quality gates) -> M4 (W2) -> gate, with Phase 2+ sketched afterward.
- [Why]: This sequence matches the natural build-up: shared delivery/context/feedback first, then a first workflow to exercise it, then generalize via capability manifests/quality gates before building the second workflow that depends on those abstractions.
- [Fix]: None.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Dependency edges are mostly sensible, but a few are missing or slightly misaligned:
  - A2A-004.1 depends on "--" but practically depends on *at least* A2A-001 (delivery envelope fields like correlation_id/workflow/intent show up in template) and possibly A2A-003 (feedback verbs influence template's feedback request pattern).
  - A2A-004.3 depends only on A2A-004.2, but it also implicitly depends on A2A-004.1 (schema/template) and M1 items; those are currently only indirectly implied through A2A-004.2.
  - A2A-012.2 depends on A2A-009/010/012.1, but it also practically depends on A2A-001 and A2A-003 (deliver + feedback) and A2A-011 (learning log writeback), even if already used during 012.1.
- [Why]: Missing edges make execution order ambiguous and can cause "integration" tasks to start before prerequisites exist, increasing iteration count and rework.
- [Fix]: Tighten the dependency graph in `tasks.md`:
  - Add `Depends On: A2A-001` (and optionally A2A-003) to A2A-004.1.
  - Change A2A-004.3 `Depends On` to include `A2A-004.1, A2A-001, A2A-002, A2A-003` (or just `A2A-004.1, A2A-004.2` if 004.2 already strictly depends on M1).
  - Add `A2A-001, A2A-003, A2A-011` to A2A-012.2 dependencies (or document explicitly why not needed).

- [F3]
- [Severity]: MINOR
- [Finding]: No circular dependencies are apparent in the current table; the graph is acyclic as written.
- [Why]: Avoids deadlock in execution planning.
- [Fix]: None.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: M3 is marked as depending on "M2 gate passed (A2A-005)" in `action-plan.md`, but several M3 tasks (schema definition and adding manifests) could be executed before the W1 gate without harming the plan.
- [Why]: Over-constraining M3 behind the W1 gate lengthens the critical path and delays W2 unnecessarily -- especially since M3 is mostly schema + metadata work that is low-risk to do earlier.
- [Fix]: Reframe M3 dependencies:
  - Keep **A2A-008** (resolution logic) and **A2A-009** (adaptive gates) behind W1 gate if you want to preserve "learn from W1 first".
  - Allow **A2A-006/007** to start in parallel with late M2 (e.g., after A2A-004.1 or after A2A-004.3 smoke test).

- [F5]
- [Severity]: STRENGTH
- [Finding]: All spec task IDs A2A-001 through A2A-025 are represented in `tasks.md`, and milestone mapping in `action-plan.md`/summary covers all of them (detailed for Phase 1/1b, sketched for later phases).
- [Why]: Indicates good coverage against the reviewed SPECIFY output.
- [Fix]: None.

- [F6]
- [Severity]: STRENGTH
- [Finding]: The splits of A2A-004 into 004.1/004.2/004.3 and A2A-012 into 012.1/012.2 are justified and aligned with integration reality (schema/template vs orchestration vs end-to-end).
- [Why]: This reduces "monster tasks," supports incremental validation, and makes iteration budgeting (Pattern 4) more actionable.
- [Fix]: None.

- [F7]
- [Severity]: MINOR
- [Finding]: There is a slight representational mismatch: `action-plan.md` lists "Spec tasks: A2A-004, A2A-005" under M2, but execution actually uses A2A-004.1/2/3. This is fine but can confuse readers cross-referencing.
- [Why]: Small traceability friction during implementation.
- [Fix]: In `action-plan.md`, annotate M2 as "A2A-004 (implemented as 004.1/004.2/004.3), A2A-005".

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Several tasks are not truly "single-session atomic" as written, especially those that are primarily "SOUL.md instructions" but also require testing + wiring:
  - A2A-001 (delivery layer) includes schema definition + adapter behavior + "no workflow branches on channel capabilities" -- that last part is a cross-task invariant.
  - A2A-008 (capability resolution) includes reading/manifests parsing + ranking algorithm + dispatch format amendment + escalation on zero matches.
  - A2A-009 (quality review schema) includes defining checks + wiring to manifests + policy for redispatch/escalate + validating researcher output format.
  - A2A-010 (escalation logic) includes multiple categories, heuristics, audit trail requirements.
- [Why]: Non-atomic tasks tend to slip, and acceptance criteria become harder to verify in one pass; they also complicate "iteration budget" forecasting.
- [Fix]: Either split further or explicitly declare them as "multi-session but single deliverable." If splitting, suggested splits:
  - **A2A-001a** schema + contract; **A2A-001b** Telegram adapter wrapper behavior + smoke test.
  - **A2A-008a** manifest reading + filtering; **A2A-008b** ranking/tiebreakers + dispatch format.
  - **A2A-009a** gate checklist + decision tree; **A2A-009b** manifest-driven filtering + validation harness.
  - **A2A-010a** escalation taxonomy + rules; **A2A-010b** N-entries heuristic + audit logging format.

- [F9]
- [Severity]: STRENGTH
- [Finding]: Many acceptance criteria are concrete and testable (e.g., file paths, required fields, caps, max redispatches, append-only ledgers, "one real dispatch through full pipeline" smoke tests).
- [Why]: Testable ACs reduce ambiguity and align well with an operational/prompt-instructions codebase.
- [Fix]: None.

- [F10]
- [Severity]: MINOR
- [Finding]: A2A-002 includes "8K token ceiling enforced," but enforcement mechanism isn't specified (hard truncation vs summarization vs refusal) and "token" depends on model/tokenizer.
- [Why]: Ambiguity can lead to inconsistent behavior and brittle context refresh.
- [Fix]: Define enforcement behavior in AC: e.g., "must fit within X characters OR X approx-tokens using method Y; if exceeds, Tess summarizes sections A/B/C to fit; always preserve project list + current priorities."

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: A2A-003's "Mechanical coupling rule documented: learning log entry only after dispatch + (feedback OR timeout)" implies a timeout mechanism, but no task explicitly defines timeout duration, scheduler, or how "no feedback" is detected.
- [Why]: Without a defined timeout policy, learning log completeness and dispatch closure become inconsistent, weakening the whole "learning loop."
- [Fix]: Add explicit acceptance criteria (and possibly a subtask) defining:
  - timeout duration per workflow,
  - how pending items are tracked,
  - what outcome_signal is recorded on timeout (e.g., `no-feedback`),
  - whether a reminder nudge is sent.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: A2A-004.2 contains ">50% not-useful -> disable pattern." It's unclear over what window and minimum sample size this is computed (5 items? 20? last 3 days?), and whether it's per-tag, per-crossref type, or global.
- [Why]: A poorly defined auto-disable rule can either shut down the workflow prematurely (cold start) or fail to stop noisy behavior.
- [Fix]: Specify: window (e.g., last 20 items or last 7 days), minimum N (e.g., N>=10), and scope (global vs per pattern key).

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: A2A-015 explicitly says "Needs decomposition during Phase 2 PLAN," but it still has detailed tech choices (Express + SSR, Cloudflare Tunnel + Access, web UI delivery adapter) that are not reflected as subtasks.
- [Why]: It reads like a large multi-week epic; leaving it as a single task undermines planning accuracy for Phase 2.
- [Fix]: In Phase 2 PLAN, decompose into at least: scaffolding/auth, artifact indexer, UI views, feedback action wiring, delivery adapter integration, deployment runbook.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: The approach relies heavily on "SOUL.md instructions as executable logic" (delivery, correlation IDs, resolution, quality gates, escalation). This is feasible for Crumb, but hidden complexity is **determinism and regression control**: prompt-instruction logic can drift with model updates and lacks unit tests.
- [Why]: Operational systems need stable behavior; without a lightweight test harness, iteration budgets may be exceeded and subtle regressions can appear across workflows.
- [Fix]: Add a minimal "prompt regression" harness task (even a manual checklist + canned fixtures):
  - a folder of example briefs/manifests/dispatch requests,
  - expected outputs for resolution/gating/escalation decisions,
  - runbook for re-validating after SOUL.md edits or model change.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: "Tess reads SKILL.md frontmatter at dispatch time" (A2A-008) is plausible, but depends on reliable file IO, consistent frontmatter formatting, and performance. There's no explicit fallback behavior if a SKILL.md is missing/invalid YAML.
- [Why]: A single malformed frontmatter block can break dispatch routing and cascade into escalations.
- [Fix]: Define robustness rules in A2A-008 AC: validation, skip-invalid-with-log, and a "safe default escalate with error details."

- [F16]
- [Severity]: MINOR
- [Finding]: Using YAML ledgers (`feedback-ledger.yaml`, `dispatch-learning.yaml`) is feasible but risks merge/conflict and corruption if multiple processes write concurrently (cron + manual runs).
- [Why]: Ledger integrity is core to learning + gating.
- [Fix]: Add an append protocol: one-entry-per-line (JSONL) or "append-only YAML list with file lock" convention; at minimum document "single writer" assumption and scheduling constraints.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: Risk summary is good but misses several major operational risks:
  1) **Correlation/dispatch ID mismatches** across systems (Telegram message, bridge dispatch, vault artifact) causing broken feedback linkage.
  2) **Ledger growth / performance** (context file 8K cap, ledgers unbounded).
  3) **Schema drift** (frontmatter, briefs, manifests) without validation tooling.
  4) **Security/privacy** risk: delivering sensitive research/account info to Telegram or web UI without classification rules.
- [Why]: These are common failure modes in agentic orchestration and external-memory systems and can undermine trust quickly.
- [Fix]: Add risks + mitigations:
  - ID integrity: enforce "correlation_id required everywhere," add a checker script.
  - Retention: rolling windows/archival for ledgers.
  - Schema validation: simple lint/validate step for YAML/frontmatter.
  - Data handling: classification tags + "never deliver X to Telegram" rule, require approval for sensitive artifacts.

- [F18]
- [Severity]: MINOR
- [Finding]: "Live deployment iterations exceed budget" mitigation is mostly "we budgeted for it," but not "how we stop bleeding."
- [Why]: Budgeting isn't a mitigation if iteration count balloons.
- [Fix]: Add stop conditions: rollback to previous stable, feature-flag workflow off, and a checklist for what to validate per iteration.

- [F19]
- [Severity]: STRENGTH
- [Finding]: The three documents largely tell the same story: 9 milestones, 28 tasks, Phase 1/1b detailed, Phase 2-4 sketched; same iteration budgets; same key decisions.
- [Why]: Reduces implementation confusion.
- [Fix]: None.

- [F20]
- [Severity]: MINOR
- [Finding]: Minor inconsistencies/ambiguities:
  - `action-plan.md` says "Spec tasks: A2A-010, A2A-011, A2A-012, A2A-013, A2A-014" but later implies A2A-011 coupling was deferred earlier (M1 mentions deferred to A2A-011 implementation) -- fine, but could be clearer that M1 only logs feedback; M4 closes the loop.
  - The summary says "M1 feedback infra operational -> M5" while tasks table lists A2A-015 depends on A2A-003 (consistent), but action-plan.md adds Cloudflare/Express details not elsewhere.
- [Why]: Small clarity issues can cause "where does this belong?" confusion.
- [Fix]: Add one sentence to M1 and/or summary: "M1 captures feedback; M4 adds learning-log closure rules and uses it for routing."

- [F21]
- [Severity]: SIGNIFICANT
- [Finding]: The stated critical path "M1 -> M2 gate -> M3 -> M4 gate" is reasonable but likely **over-serialized**:
  - As noted, M3 schema + manifests (A2A-006/007) can proceed in parallel with M2 gate observation.
  - The critic skill (A2A-014) could be built earlier (after A2A-006/007) even before W2 integration, since it's largely an isolated skill definition.
- [Why]: Parallelization can reduce calendar time without increasing risk significantly.
- [Fix]: Update critical path to:
  - M1 -> M2 build (to 004.3) -> (parallel: M2 gate + M3.006/007 + A2A-014 draft) -> M3.008/009 -> M4 -> M4 gate.

- [F22]
- [Severity]: STRENGTH
- [Finding]: External blockers are identified and attached to later phases: TOP-027 calendar for SE prep; TOP-049 approval contract for approvals/gardening/control; "tess-operations M2" noted as a Phase 2 blocker.
- [Why]: Prevents planning Phase 1/1b around dependencies that aren't ready.
- [Fix]: None.

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: References to `claude-print-automation-patterns.md Pattern 4` and its "budget 3-6 iterations" guidance.
- [Why]: I can't access that document to confirm Pattern 4 content or the iteration budgets derived from it.
- [Fix]: Provide a short excerpt or linkable citation inside the vault (or restate Pattern 4 in the plan) so reviewers can verify.

- [F24]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Dependencies marked "TOP-009 operational", "FIF M3 done", "tess-operations M2," "TOP-027 calendar," "TOP-049 approval contract," and "CTB-016 dispatch lifecycle identifier."
- [Why]: These look like internal project IDs; I can't verify their status, definitions, or whether they exist as specified.
- [Fix]: Add links (vault paths) to the referenced TOP/FIF/CTB artifacts and/or a short "dependency register" section with current status and location.

- [F25]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: "Existing OpenClaw Telegram delivery (wrapped, not rewritten)" and "awareness-check is a bash script + cron, morning briefing is a prompt-based skill."
- [Why]: I can't inspect the OpenClaw codebase or existing automation in this environment to confirm these components exist and behave as assumed.
- [Fix]: Add file-path pointers and/or a brief inventory of the existing scripts/skills being depended on, including how they are invoked.

**Net assessment:** The PLAN is coherent, spec-complete, and operationally aligned with Crumb's "vault + SOUL.md" paradigm. The biggest improvements are (a) tightening dependencies so integration tasks can't start prematurely, (b) defining a few underspecified policies (timeouts, disable thresholds, robustness), and (c) adding lightweight validation/regression mechanisms to control prompt-driven logic drift.

---

## Google (gemini-3-pro-preview)

### 1. Milestone Ordering and Dependency Correctness

*   **F1** [MINOR] **Dependency Definition Gap in Task A2A-010**
    *   **Finding:** In `tasks.md`, task A2A-010 ("Build escalation auto-resolution logic") lists `A2A-002` as its only dependency. However, the logic described (resolving "scope," "risk," and "confidence") strongly implies a dependency on the capability manifests defined in **A2A-006** and the resolution logic in **A2A-008**.
    *   **Why:** You cannot reliably define "scope escalation" rules without the capability definitions (M3) that establish what "in-scope" means.
    *   **Fix:** Update A2A-010 dependencies in `tasks.md` to include `A2A-006` and `A2A-008`.

### 2. Spec Fidelity

*   **F2** [STRENGTH] **Pragmatic Task Decomposition**
    *   **Finding:** The breakdown of **A2A-004** (Compound Insights) into three sub-tasks (.1 Schema, .2 Trigger, .3 Integration) and **A2A-012** (Research) into two (.1 Template, .2 Integration) demonstrates high fidelity to the engineering reality. This avoids the common failure mode of under-estimating integration effort.

### 3. Task Atomicity and Completeness

*   **F3** [SIGNIFICANT] **Complexity Risk in A2A-008 (Capability Resolution)**
    *   **Finding:** A2A-008 requires Tess (Haiku) to "read SKILL.md frontmatter" from multiple files, filter by rigor, rank by learning log/cost/quality, and tiebreak alphabetically.
    *   **Why:** While listed as a single task, this requires Tess to perform a "Retrieve and Rank" operation inside her context window. Haiku may struggle with the cognitive load of parsing multiple YAML frontmatters and applying complex sorting logic in a single inference step (SOUL instruction), potentially leading to hallucinated capabilities or ignored costs.
    *   **Fix:** Split A2A-008 or add a sub-task to benchmark Haiku's ability to handle this logic. Consider a fallback where the "Available Capabilities" are summarized into a single `_openclaw/state/capabilities.json` index (maintained by a separate script) rather than asking the agent to crawl raw SKILL.md files at runtime.

### 4. Feasibility

*   **F4** [SIGNIFICANT] **Fragility of "Prompt-Based Infrastructure"**
    *   **Finding:** Infrastructure components like the "Delivery layer" (A2A-001) and "Feedback ledger" (A2A-003) are implemented purely as "SOUL.md instructions."
    *   **Why:** If the system prompt (SOUL.md) grows too large or context pressure increases, the agent may ignore these "infrastructure" instructions. Unlike code, which either runs or throws an exception, prompt-based infrastructure can silently fail (e.g., sending a message without a correlation ID or failing to write to the ledger).
    *   **Fix:** Add a specific validation step in the Acceptance Criteria for A2A-001 and A2A-003: "Stress test: Verify delivery/feedback integrity when context window is >80% full."

### 5. Risk Coverage

*   **F5** [MINOR] **Missing Data Dependency for Workflow 3**
    *   **Finding:** Task A2A-017 (SE Account Prep) relies on "dossiers," and A2A-016 defines the schema. However, there is no task listed to *populate* these dossiers historically.
    *   **Why:** Workflow 3 might fail at launch if it expects dossiers to exist but finds only empty files matching the schema.
    *   **Fix:** Add a risk or a task note: "Requires manual or automated backfill of Account Dossiers before W3 gate."

### 6. Consistency

*   **F6** [STRENGTH] **Live Iteration Budgeting**
    *   **Finding:** The explicit inclusion of a "Live Deployment Iteration Budget" (Pattern 4) in `action-plan.md` and the referencing of it in `tasks.md` creates a consistent, realistic expectation for the integration phase. This effectively mitigates the "it didn't work the first time" morale risk.

### 7. Critical Path Analysis

*   **F7** [SIGNIFICANT] **Phase 2 Implementation Gap**
    *   **Finding:** Task A2A-015 ("Build mission control web UI") is a massive undertaking (Express, Cloudflare, SSR, UI, Adapter) compressed into a single line item. While the plan acknowledges it needs decomposition, leaving it as a single task in a "Reviewed Plan" obscures the true critical path for Phase 2.
    *   **Why:** M5 (Mission Control) is likely a 2-3 week sprint in itself, not a single task.
    *   **Fix:** Even if sketched, break A2A-015 into at least 3 placeholders (A2A-015.1 Scaffolding, A2A-015.2 Read-UI, A2A-015.3 Feedback-Write) to represent the effort magnitude on the timeline.

### Unverifiable Claims

*   **F8** [SIGNIFICANT] **UNVERIFIABLE CLAIM: External Documentation & State**
    *   **Finding:** The plan relies on specific definitions and patterns in:
        *   `claude-print-automation-patterns.md` (specifically "Pattern 4")
        *   `design/specification.md` (The source of the 25 tasks)
        *   `TOP-009`, `TOP-027`, `TOP-049` (Operational tasks/dependencies)
        *   `CTB-016` (Dispatch lifecycle identifier)
    *   **Why:** The validity of the "Iteration Budget" and "Dispatch ID" logic rests entirely on these unreviewed documents.
    *   **Fix:** Verify that "Pattern 4" explicitly supports the "3-6 iterations" claim and that `CTB-016` is compatible with the `dispatch_id` generation strategy in D1.

*   **F9** [SIGNIFICANT] **UNVERIFIABLE CLAIM: Future Dating**
    *   **Finding:** The documents are dated `2026-03-04`.
    *   **Why:** This implies either a future-dated plan or a fictional scenario.
    *   **Fix:** Review assumes this is valid context data ("Crumb is a personal multi-agent OS"). No fix required if context is fictional/simulation, but noted for grounding.

---

## DeepSeek (deepseek-reasoner)

**Overall Assessment:** The PLAN phase deliverables are comprehensive, well-structured, and demonstrate a clear translation from the SPECIFY phase into actionable work. The approach is pragmatic, leveraging existing patterns and avoiding over-engineering. The primary risks are acknowledged and mitigated. The artifacts are largely consistent. Several dependencies and atomicity issues require clarification.

### 1. Milestone ordering and dependency correctness

- **F1: SIGNIFICANT**
    - **Finding:** Dependency error for A2A-008 ("Implement capability resolution"). The action plan states the resolution algorithm consults the learning log for ranking. However, the task table lists dependencies as A2A-006 and A2A-007 only, not A2A-011 ("Build dispatch learning log"). This creates a logical gap: the resolution mechanism cannot rank by learning log data that does not yet exist or is not guaranteed to be built.
    - **Why:** A2A-008 will be incomplete or must implement a fallback path that was not part of its acceptance criteria. This could lead to rework or a broken integration during M4.
    - **Fix:** Add A2A-011 as a dependency for A2A-008 in the task table. Alternatively, amend the acceptance criteria for A2A-008 to specify that the initial implementation uses only the fallback `cost_profile` from manifests, with learning log integration deferred to a later sub-task.

- **F2: MINOR**
    - **Finding:** Milestone M3 ("Capability Infrastructure") is stated to depend on M2 gate (A2A-005), but tasks A2A-006 and A2A-007 have no dependencies on M2. This creates a slight inconsistency between milestone sequencing and task-level dependencies.
    - **Why:** This is likely a project management sequencing choice rather than a technical blocker. However, it could cause confusion during execution if the team interprets the milestone dependency as strict.
    - **Fix:** Clarify in the action plan that M3 can *begin* with A2A-006 and A2A-007 (schema work) in parallel with M2, but that A2A-008 and A2A-009 (which depend on M2's outcomes and the learning log) must wait for the M2 gate.

- **F3: MINOR**
    - **Finding:** Milestone M5 ("Mission Control Read") has a single dependency (A2A-003) and could theoretically be parallelized with M3 and M4, yet it is scheduled for Phase 2.
    - **Why:** This is likely a resource or focus prioritization decision, not a technical constraint. The summary correctly notes it "can start independently of M3/M4."
    - **Fix:** None required, but the reasoning (e.g., "focus on core agent workflows first") could be briefly noted in the action plan to preempt questions.

### 2. Spec fidelity

- **F4: STRENGTH**
    - **Finding:** The plan faithfully represents all 25 specification tasks (A2A-001 through A2A-025). The splits of A2A-004 and A2A-012 into subtasks are justified and improve atomicity.
    - **Why:** The splits appropriately separate schema definition, orchestration logic, and integration testing into distinct, manageable units of work.
    - **Fix:** None.

- **F5: MINOR**
    - **Finding:** The spec task A2A-015 ("Build mission control web UI") is noted as needing decomposition during Phase 2 PLAN. This is appropriate but leaves a large, high-risk task undefined.
    - **Why:** This is a responsible approach for a complex task dependent on external choices (e.g., framework). It does not affect the current plan's validity.
    - **Fix:** Ensure a placeholder exists in the project backlog to schedule the decomposition of A2A-015 before Phase 2 work begins.

### 3. Task atomicity and completeness

- **F6: STRENGTH**
    - **Finding:** Task acceptance criteria are generally specific, testable, and focused on delivered artifacts (e.g., "Schema defined at `_system/schemas/capabilities/manifest.yaml`").
    - **Why:** This clarity will reduce ambiguity during implementation and review.
    - **Fix:** None.

- **F7: SIGNIFICANT**
    - **Finding:** Task A2A-012.2 ("Research pipeline end-to-end integration") is described as a single task but budgets 3-4 live iterations and encompasses wiring together multiple complex subsystems (capability resolution, escalation, quality gates, delivery, feedback).
    - **Why:** This task risks becoming a multi-session integration "big bang" that could be difficult to track and test atomically.
    - **Fix:** Consider splitting it into two tasks: 1) "Integration of core research dispatch flow" (up to first delivery), and 2) "Integration of feedback and crash policy" (closing the loop). This maintains the iterative approach but provides clearer intermediate checkpoints.

### 4. Feasibility

- **F8: STRENGTH**
    - **Finding:** The implementation approach leveraging SOUL.md instructions, vault state files, and existing OpenClaw patterns is realistic and avoids unnecessary new code.
    - **Why:** It builds incrementally on proven system components and patterns (e.g., cron jobs, dispatch templates).
    - **Fix:** None.

- **F9: SIGNIFICANT**
    - **Finding:** The success of A2A-001 ("Implement delivery layer abstraction") depends on the existing OpenClaw Telegram delivery being wrappable to support the abstract `intent` vocabulary (`notify`, `present`, `approve`, etc.). The plan does not detail how this mapping will be achieved.
    - **Why:** If the existing delivery mechanism is tightly coupled to specific message formats or lacks hooks for `correlation_id` passthrough, this abstraction could be complex to implement.
    - **Fix:** Add a brief investigative subtask or note to A2A-001: "Verify existing Telegram delivery can be invoked with required metadata (`correlation_id`, `intent`) and document the wrapping method."

### 5. Risk coverage

- **F10: MINOR**
    - **Finding:** The risk summary is good but omits a key architectural risk: "Over-reliance on SOUL.md instruction complexity leading to fragile, hard-to-debug agent behavior."
    - **Why:** As orchestration logic grows in SOUL.md instructions, the potential for subtle prompt drift, instruction conflict, or performance issues increases.
    - **Fix:** Add a risk: "Orchestration logic in SOUL.md becomes unwieldy." Mitigation: "Plan includes iterative validation (Pattern 4); consider periodic refactoring of instructions into modular, documented sections."

### 6. Consistency

- **F11: MINOR**
    - **Finding:** Minor inconsistency between documents regarding M3's success criteria. The action plan lists "adaptive quality gates filter by manifest" as a success criterion for M3, but the task A2A-009 ("Implement quality review schema") is part of M4 in the milestone table.
    - **Why:** This is a minor misalignment that could cause confusion about when the quality gate logic is considered "done."
    - **Fix:** In the action plan's M3 section, adjust the success criteria to focus on schema and manifest completion, not the adaptive gates. Or, move the mention of adaptive gates to M4's success criteria.

### 7. Critical path analysis

- **F12: STRENGTH**
    - **Finding:** The critical path (M1 -> M2 -> M3 -> M4) is correctly identified. External blockers (tess-operations for TOP-027, approval contract TOP-049) are properly noted for Phase 2+.
    - **Why:** This provides a realistic timeline and sets expectations for later phases.
    - **Fix:** None.

### Unverifiable Claims

**UNVERIFIABLE CLAIM:** References to internal documents and project dependencies cannot be independently verified. These include:
- The existence and content of `claude-print-automation-patterns.md Pattern 4`.
- The status and details of external project dependencies: `TOP-009`, `TOP-027`, `TOP-049`, `FIF M3`.
- The current structure and capabilities of the "existing OpenClaw Telegram delivery" system.
- The existence of specific file paths (e.g., `.claude/skills/researcher-skill/SKILL.md`) and their current content.

**Recommendation:** These claims should be verified by the implementing team against the current state of the Crumb codebase and project portfolio before execution begins.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: Multiple references to unverified external dependencies and existing components cannot be independently confirmed, e.g., "TOP-009 operational" (morning briefing), "FIF M3 done", "claude-print-automation-patterns.md Pattern 4", "SOUL.md instructions" as the primary implementation mechanism, "existing OpenClaw Telegram delivery", "CTB-016 dispatch lifecycle", "researcher-skill SKILL.md", "TOP-027 calendar", "TOP-049 approval contract".
- [Why]: These are foundational to the plan's feasibility and timeline; without verification, the plan assumes infrastructure that may not exist or function as described, risking cascading failures in execution.
- [Fix]: Prefix each with "UNVERIFIABLE CLAIM:" in the documents (e.g., "UNVERIFIABLE CLAIM: TOP-009 operational") and add a verification milestone pre-M1 requiring vault/repo audit logs or screenshots.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Milestone dependencies in action-plan.md state M3 depends on "M2 gate passed (A2A-005)", but tasks.md shows A2A-006 (first M3 task) with no dependencies, and no explicit gate-task dependency edge for subsequent M3 tasks (e.g., A2A-008 deps only A2A-006,007).
- [Why]: Creates ambiguity for executors; M3 schemas (e.g., capability manifests) could theoretically start early, but plan explicitly sequences after W1 validation, risking premature implementation if tasks table is followed literally.
- [Fix]: Add "A2A-005" as a dependency to A2A-006 in tasks.md, or clarify in action-plan.md that M3 sequencing is executor-enforced, not task-level.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: A2A-011 (dispatch learning log) depends only on A2A-005 in tasks.md, but its schema and instructions are consumed by A2A-012.1 (research brief), which is in the same M4; however, plan's M3 (capability infra including A2A-008 resolution) precedes but doesn't explicitly link to learning log usage.
- [Why]: Learning log is consulted in capability resolution (A2A-008 AC: "Rank by learning log -> cost -> quality"), creating a forward dependency gap; cold-start feedback issue noted in risks but not gated.
- [Fix]: Add cross-dep A2A-008 depends on A2A-011 (or vice versa with fallback logic), and elevate cold-start to explicit AC in A2A-008.

- [F4]
- [Severity]: MINOR
- [Finding]: Task splits for A2A-004 and A2A-012 are justified in summary (file-change scoping), but A2A-015 is flagged "needs decomposition during Phase 2 PLAN" without any sub-tasks created, unlike others.
- [Why]: Inconsistent handling of large tasks; A2A-015 is high-risk (web UI dev) and pending decomposition, but listed as atomic in tasks.md, potentially blocking M5.
- [Fix]: Create placeholder sub-tasks (e.g., A2A-015.1 scaffolding, .2 browser) marked "TBD" or move to sketched status.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Feasibility relies heavily on "SOUL.md instructions" for complex logic (e.g., capability resolution algorithm in A2A-008, escalation decision tree in A2A-010, tiered staleness in A2A-002), with no fallback for prompt degradation or Haiku limitations beyond A/B in A2A-005.
- [Why]: Prompt-engineered state machines scale poorly; edge cases like ambiguous ranking tiebreakers or N-entries calibration could fail silently in live iterations, exceeding budgeted 3-6 cycles.
- [Fix]: Add validation tasks (e.g., A2A-008.2: unit-test resolution logic via 10 synthetic briefs) using vault-embedded test cases.

- [F6]
- [Severity]: MINOR
- [Finding]: Acceptance criteria for integration tasks (A2A-004.3, A2A-012.2) specify "one real [workflow] through full pipeline" with iteration budgets, but no quantitative success metrics beyond "vault-check passes" (e.g., no min utility rate pre-gate).
- [Why]: Testable but subjective; "smoke test" risks passing flawed pipelines, deferring issues to 3-day gates.
- [Fix]: Add metrics to AC, e.g., "2+ successful end-to-end with feedback recorded, 0 crashes".

- [F7]
- [Severity]: CRITICAL
- [Finding]: Spec fidelity claims 25 spec tasks mapped to 28 atomic (via splits), but Phase 3 tasks A2A-020 to A2A-024 are sketched at milestone level only -- no individual AC or deps in tasks.md beyond basics, despite being listed as "pending".
- [Why]: PLAN phase should detail Phase 1+1b fully; sketched tasks undermine executability for later phases, misrepresenting completeness (summary says "19 detailed").
- [Fix]: Mark Phase 3+ tasks as "sketched/pending-PLAN" in state column, or add stub AC.

- [F8]
- [Severity]: MINOR
- [Finding]: Risk summary covers listed items well, but misses prompt drift (SOUL.md changes over time degrading orchestration) and external cron/skill invocation reliability (e.g., "discrete OpenClaw cron job").
- [Why]: Core to discrete workflow decision (OQ1); cron failures could stall triggers without detection.
- [Fix]: Add risks: "Prompt drift -> weekly SOUL.md audit"; "Cron flakiness -> stall detection tie-in from M8 early".

- [F9]
- [Severity]: MINOR
- [Finding]: Minor inconsistency: action-plan.md M2 deps include "FIF M3 done" (unverified), absent from tasks.md; summary omits it.
- [Why]: Breaks cross-doc alignment; assumes external milestone without propagation.
- [Fix]: Add to M2 deps in summary or note as "assumed complete".

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Critical path in summary ("M1 -> M2 -> M3 -> M4 -> M5/M6 parallel after M3") overlooks A2A-010 deps only on A2A-002 (M1), allowing early escalation logic, but M4 impl sequences it post-M3.
- [Why]: Opportunity for parallelization missed (escalation partially independent); could accelerate M4 but risks incomplete infra.
- [Fix]: Explicitly parallelize A2A-010 after M1 in critical path diagram.

- [F11]
- [Severity]: STRENGTH
- [Finding]: No circular dependencies detected; task deps form a DAG (e.g., M1 foundations feed M2 integration without cycles).
- [Why]: Ensures sequential executability without deadlocks.
- [Fix]: N/A (verified by tracing: e.g., 004.3 -> 005 -> 011 -> 012.1 -> 012.2).

- [F12]
- [Severity]: STRENGTH
- [Finding]: Spec fidelity high: all 25 A2A-001-025 accounted for, splits justified for scoping (e.g., A2A-004 schema separate from trigger/integration avoids partial failures).
- [Why]: No missing/misrepresented tasks; expansions add clarity without scope creep.
- [Fix]: N/A (cross-checked against milestone mappings).

- [F13]
- [Severity]: MINOR
- [Finding]: Task atomicity mostly good (e.g., schema definitions single-session), but A2A-004.3/A2A-012.2 "end-to-end + iterations" may span sessions despite budget.
- [Why]: Violates "atomic (single session)" implicitly; risks partial progress tracking.
- [Fix]: Split iterations into post-integration tasks (e.g., A2A-004.4 Iteration 1-3).

- [F14]
- [Severity]: STRENGTH
- [Finding]: Three docs consistent on milestones (9 total, same tasks/mapping), splits, budgets, risks (e.g., top risks match verbatim).
- [Why]: Enables coherent execution without reconciliation.
- [Fix]: N/A (spot-checked tables/summary vs. plan).

- [F15]
- [Severity]: STRENGTH
- [Finding]: External blockers well-identified (e.g., TOP-027/049 for Phase 2/3, timelines Q2+ 2026); Phase 1/1b independent.
- [Why]: Prevents over-optimism; mitigations (no wasted work) sound.
- [Fix]: N/A.

---

## Synthesis

### Consensus Findings

**1. M3 over-serialization — A2A-006/007 can start before M2 gate (4/4)**
Sources: OAI-F4, DS-F2, GRK-F2, GRK-F10

All four reviewers flagged that M3 is unnecessarily serialized behind the M2 gate. A2A-006 (manifest schema) and A2A-007 (skill manifests) are pure schema/metadata work with no dependency on W1 outcomes. Only A2A-008 (resolution logic) and A2A-009 (quality gates) benefit from learning from W1. Strongest consensus finding across the review.

**2. A2A-008 → A2A-011 forward dependency gap (2/4)**
Sources: DS-F1, GRK-F3

A2A-008's acceptance criteria specify "rank by learning log" but the learning log (A2A-011) is not listed as a dependency. The resolution algorithm can't rank by data that doesn't exist yet. Either add the dependency or specify that initial implementation uses manifest `cost_profile` as fallback.

**3. SOUL.md prompt fragility / drift risk (4/4)**
Sources: OAI-F14, GEM-F4, DS-F10, GRK-F5, GRK-F8

All reviewers flagged the risk of prompt-based infrastructure silently failing — no unit tests, no regression detection, context pressure could cause instruction-skipping. This is the primary architectural risk of the "SOUL.md as executable logic" approach.

**4. A2A-015 needs placeholder decomposition (3/4)**
Sources: OAI-F13, GEM-F7, GRK-F4

A2A-015 (mission control web UI) is acknowledged as needing decomposition but listed as a single task. Three reviewers recommend placeholder sub-tasks to represent effort magnitude, even for a sketched phase.

**5. Task atomicity concerns — large tasks exceed single session (3/4)**
Sources: OAI-F8, DS-F7, GRK-F13

Several tasks are not truly single-session atomic: A2A-008 (capability resolution), A2A-009 (quality review), A2A-010 (escalation), and integration tasks (A2A-004.3, A2A-012.2). OpenAI suggests specific splits; DeepSeek and Grok focus on integration tasks.

**6. Missing dependency edges in tasks.md (3/4)**
Sources: OAI-F2, GEM-F1, DS-F1

Multiple implicit dependencies are not reflected in the task table. Most significant: A2A-004.1 has no stated dependencies but uses delivery envelope fields from A2A-001. However, transitive coverage through A2A-004.2 mitigates practical risk.

**7. Unverifiable external references (4/4)**
Sources: OAI-F23/F24/F25, GEM-F8, DS-unverifiable, GRK-F1

All reviewers flagged TOP-009/027/049, CTB-016, Pattern 4, FIF M3, and existing OpenClaw infrastructure as unverifiable. Expected for an internal system — these are all live vault/project references verified during SPECIFY phase.

### Unique Findings

**OAI-F11: A2A-003 feedback timeout mechanism undefined**
The "dispatch + (feedback OR timeout)" coupling rule in A2A-003 implies a timeout mechanism that is never defined: duration, scheduling, detection method, outcome signal. Genuine gap — the learning loop depends on timeout closure.

**OAI-F12: A2A-004.2 disable threshold underspecified**
The ">50% not-useful → disable pattern" rule lacks parameters: window size, minimum sample N, scope (global vs per-pattern). Could auto-disable prematurely on cold start. Valid operational concern.

**OAI-F16: YAML ledger concurrent write risk**
Feedback ledger and learning log are YAML files that could face concurrent writes. Likely noise — OpenClaw runs single-threaded, and Crumb sessions are serialized by CTB-016 flock. But documenting the single-writer assumption is cheap.

**OAI-F17: Missing operational risks (4 categories)**
Correlation ID mismatches across systems, ledger growth unbounded, schema drift without validation, and security/privacy classification for sensitive deliveries. Most comprehensive risk gap analysis. Ledger growth and schema drift are the most actionable.

**GEM-F5: No dossier population task for W3**
A2A-016 defines the dossier schema but no task populates historical data. Valid gap, though customer-intelligence project handles dossier creation — cross-project dependency not documented.

**DS-F9: A2A-001 wrapping verification needed**
The plan assumes existing Telegram delivery can pass correlation_id and intent metadata, but doesn't verify this. Low risk since the "wrapping" is SOUL.md instructions (prompt engineering, not code integration), but noting the assumption is valid.

**GRK-F7: Phase 3+ tasks listed as "pending" not "sketched"**
The task table shows Phase 3+ tasks as "pending" — same status as Phase 1 tasks — despite being sketched at milestone level only. This is the only CRITICAL-rated finding (Grok), though it's a labeling issue, not a blocking problem.

**GRK-F10: A2A-010 could be parallelized earlier**
A2A-010 (escalation logic) only depends on A2A-002 (context model), so it could start during M3 rather than waiting for M3 completion. The action plan sequences it in M4 but the dependency structure allows earlier work.

### Contradictions

**M3 sequencing resolution direction:**
OAI/DS advocate loosening — let A2A-006/007 start before M2 gate. GRK-F2 notes the ambiguity between action plan (M3 after M2 gate) and tasks.md (A2A-006 has no deps) but suggests either tightening (add A2A-005 as dep to A2A-006) or clarifying as executor-enforced. Both camps agree the current state is ambiguous — they disagree on resolution direction. The loosening direction has stronger support (3 of 4 explicitly advocate it).

**A2A-010 dependency direction:**
GEM-F1 suggests adding A2A-006/A2A-008 as dependencies for A2A-010 (tightening). GRK-F10 suggests A2A-010 could be parallelized earlier since it only depends on A2A-002 (loosening). The escalation logic operates on the context model, not on capability manifests — GEM's suggestion appears based on a misreading of A2A-010's scope.

### Action Items

**Must-fix:**

- **A1** (OAI-F4, DS-F2, GRK-F2): Resolve M3 serialization. Allow A2A-006 and A2A-007 to start in parallel with late M2 (e.g., after A2A-004.1 or during M2 gate observation). Keep A2A-008 and A2A-009 gated on M2 completion. Update action plan and critical path.

- **A2** (DS-F1, GRK-F3): Fix A2A-008 learning log dependency. Either: (a) add A2A-011 as dependency, or (b) amend A2A-008 acceptance criteria to specify fallback to manifest `cost_profile` for initial implementation, with learning log integration added when A2A-011 is complete.

**Should-fix:**

- **A3** (OAI-F14, GEM-F4, DS-F10, GRK-F5): Add "SOUL.md instruction drift/fragility" to risk summary with mitigation: validation fixtures (folder of example briefs/manifests with expected resolution/gating decisions), re-validation after SOUL.md edits or model changes.

- **A4** (OAI-F13, GEM-F7, GRK-F4): Create A2A-015 placeholder sub-tasks (A2A-015.1 Scaffolding, A2A-015.2 Read UI, A2A-015.3 Feedback+Adapter) to represent Phase 2 effort magnitude.

- **A5** (OAI-F11): Define feedback timeout mechanism in A2A-003 acceptance criteria — timeout duration per workflow, pending item tracking, `no-feedback` outcome signal, and whether a reminder nudge is sent before timeout.

- **A6** (OAI-F12): Specify A2A-004.2 disable threshold parameters — window (e.g., last 20 items or 7 days), minimum N (e.g., ≥10), scope (global vs per-pattern).

- **A7** (OAI-F17): Add operational risks to risk summary — ledger growth/archival (rolling windows), schema drift (validation step in vault-check), correlation ID integrity.

- **A8** (GRK-F7): Mark Phase 3+ task state as "sketched" (not "pending") in tasks.md to distinguish from actionable Phase 1/1b tasks.

- **A9** (OAI-F2, GEM-F1): Tighten dependency edges in tasks.md — add A2A-001 as dependency for A2A-004.1 (delivery envelope fields used in template). Document that transitive coverage through A2A-004.2 provides practical safety, but explicit edges improve traceability.

- **A10** (DS-F9): Add note to A2A-001 acceptance criteria: "Verify existing OpenClaw Telegram delivery supports correlation_id/intent metadata passthrough."

**Defer:**

- **A11** (OAI-F8, GEM-F3): Split A2A-008/009/010 into sub-tasks. Defer to implementation — these tasks are complex but coherent deliverables. If they exceed a single session, they can be split at implementation time. The A/B gate (A2A-005) covers model capability assessment.

- **A12** (GRK-F13): Split integration iterations (A2A-004.3, A2A-012.2) into per-iteration sub-tasks. Over-granular — Pattern 4 already budgets iterations as a known cost, not as separately planned tasks.

- **A13** (GRK-F6): Add quantitative AC metrics to integration smoke tests. The 3-day gate evaluations (A2A-005, A2A-013) provide the real measurement; smoke tests are go/no-go for pipeline functionality.

- **A14** (OAI-F16): Formalize YAML ledger single-writer protocol. OpenClaw is single-threaded and CTB-016 flock serializes Crumb sessions. Add a one-line doc note about single-writer assumption but no infrastructure needed.

- **A15** (GEM-F5): Add dossier population task for W3. Deferred — customer-intelligence project handles dossier creation. Cross-project dependency should be documented in Phase 2 PLAN.

- **A16** (OAI-F10): Specify A2A-002 "8K token ceiling" enforcement mechanism. Deferred to implementation — this is an operational detail that will be determined by Tess's context management during the first refresh cycle.

- **A17** (OAI-F18): Add iteration budget stop conditions (rollback, feature-flag off). Pattern 4's iteration budget is cost-bounded, not time-bounded. If iterations balloon, the gate evaluation (A2A-005/A2A-013) catches it.

### Considered and Declined

- **GEM-F1** (Adding A2A-006/A2A-008 as deps for A2A-010): `incorrect` — A2A-010 is about auto-resolution of Tess escalation decisions (scope vs conflict vs confidence), not about capability-scoped decisions. It operates on the context model (A2A-002), not on capability manifests.

- **GRK-F2** (Add A2A-005 as dep to A2A-006, tightening direction): `constraint` — conflicts with the 4/4 consensus finding that M3 schema work should be parallelizable with M2. The ambiguity should be resolved by loosening, not tightening.

- **GEM-F9** (2026 date verification): `out-of-scope` — 2026-03-04 is the actual current date. Not a fictional scenario.

- **DS-F11** (M3 success criteria claims A2A-009 is in M4): `incorrect` — A2A-009 is listed under M3 in the action plan ("Spec tasks: A2A-006, A2A-007, A2A-008, A2A-009"). The task table's Phase 1b section groups M3 and M4 tasks together, which may have caused the misreading.

- **DS-F3** (M5 parallelization rationale should be documented): `overkill` — the summary already notes "Can start independently of M3/M4" and the Phase 2 timing is explicitly a focus decision, not a dependency constraint.

- **OAI-F17.4** (Security/privacy classification for sensitive deliveries): `out-of-scope` — the spec's delivery layer (§7) already defines intent types; content classification is a Phase 3+ concern when vault gardening introduces additive auto-fix actions. Not relevant to Phase 1/1b scope.

---

## External Review Addendum (2 additional reviewers)

Two external reviews submitted by Danny: Claude Opus 4.6 (claude.ai with vault access) and Perplexity Sonar Reasoning Pro (file upload).

### Additional Action Items Applied

| # | Source | Finding | Resolution |
|---|--------|---------|------------|
| A18 | EXT-F1 | vault.query.facts manifest on wrong skill — obsidian-cli is a utility, not a dispatch target | **Must-fix.** New vault-query skill (A2A-007.5) created. A2A-007 updated to remove obsidian-cli manifest. |
| A19 | PPLX-1.3 | No manifest validation between schema definition and resolution logic | **Must-fix.** A2A-006.5 (manifest validation script) inserted as dep for A2A-008. |
| A20 | PPLX-1.1 | M1 exit criteria need stability thresholds | **Should-fix.** Concrete thresholds added to M1: delivery 2 days clean, 3+ context refreshes, 3+ feedback entries with stable schema. |
| A21 | PPLX-2.3 | Acceptance criteria non-testable — need test harness | **Should-fix.** Test scenarios added to M3 and M4 sections. |
| A22 | PPLX-3.2, GEM-F3 | Capability resolution in SOUL.md — pre-compute capabilities index | **Should-fix.** `capabilities.json` pre-computed from SKILL.md manifests, read by Tess instead of raw frontmatter. |
| A23 | EXT-F4 | No session estimates per milestone | **Should-fix.** Estimates added: M1 ~2-3, M2 ~3-4, M3 ~2-3, M4 ~3-4. |
| A24 | PPLX-5.1 | Cold-start restriction missing | **Should-fix.** <3 learning log entries → blocked from `rigor: deep` auto-selection. |
| A25 | PPLX-6.1 | M5 dependency too loose | **Should-fix.** M5 now requires M2 gate + learning log schema (A2A-011). |

### SOUL.md Code Helper Layer Decision

**Deferred with concrete trigger.** All 6 reviewers flagged SOUL.md fragility as a concern (4/4 automated + EXT + PPLX). PPLX proposed a code helper layer for deterministic operations. Operator decision: SOUL.md is the right starting point. M2 gate (A2A-005) evaluates whether deterministic operations (envelope format, ledger schema, correlation ID format) produced inconsistent outputs requiring correction. If yes → targeted bash helpers before M3. If no → proceed.

### Additional Items Deferred

- PPLX-2.1 (M1 task splits): Same reasoning as A11 — coherent deliverables, split at implementation time if needed.
- PPLX-2.2 (A2A-004.3 dry-run/live split): Over-granular for PLAN phase.
- PPLX-7.1-7.3 (test strategy, prompt versioning, feature flags): Good ideas, Phase 2+ scope.
- PPLX-6.2, 6.3, 5.3: Minor, Phase 2+ details.
- EXT-F5 (dispatch_group_id in glossary): Added note to D1.
- EXT-F3 (M5 vs M3 priority): Added recommendation to M5 section.
