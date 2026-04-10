---
project: tess-v2
type: design-input
domain: software
status: draft
created: 2026-03-30
updated: 2026-04-03
source: design/response-harness-analysis.md
tags:
  - spec-amendment
  - contract-execution
  - escalation
---

# Spec Amendment Proposals — Response Validation Harness

Design inputs from AutoBE harness analysis, mapped to spec sections. For application during Phase 3 design (TV2-017 through TV2-030).

---

## Amendment T: Structured Diagnostics in Failure Context (§9.4)

**Section:** §9.4 Retry Failure Classes

**Current state:** §9.4 defines four failure classes and retry strategies but doesn't specify what information feeds into iteration N+1.

**Proposed addition after the failure class table:**

> **Failure context format.** When a Ralph loop iteration fails contract evaluation, the failure context injected into iteration N+1 must include structured diagnostics:
>
> ```yaml
> failure_context:
>   iteration: 1
>   failed_checks:
>     - check_id: "quality_check_3"
>       expected: "vault path under Projects/tess-v2/"
>       actual: "/Users/tess/crumb-vault/Projects/tess-v2/"
>       delta: "absolute path instead of vault-relative path"
>   failure_class: deterministic  # from §9.4 table
>   retry_strategy: "fix input format, same executor"
> ```
>
> Structured diagnostics vs. prose "try again" is the difference between 1-2 iteration convergence and retry budget exhaustion. Each failed `quality_check` produces: check ID, expected value/pattern, actual value, and the minimal delta description.

**Rationale:** AutoBE demonstrates convergence across 10x model parameter range using field-level diagnostics. Their validators produce exact path, expected type, actual value, constraint violation. Tess's contract evaluator should do the same.

**Affects tasks:** TV2-017 (state machine), TV2-019 (contract schema), TV2-031b (contract runner)

---

## Amendment U: Lenient Parsing Layer (new §9.6)

**Section:** New subsection after §9.5 (Prior Art Integration)

**Proposed:**

> ### 9.6 Response Parsing: Lenient Recovery Before Evaluation
>
> Between executor output and contract evaluation, a lenient parsing layer recovers from common LLM formatting errors without burning a retry iteration:
>
> **Recoverable errors (fix silently, log):**
> - Markdown code block wrapping (`\`\`\`json ... \`\`\``)
> - Trailing commas in JSON
> - Unclosed brackets (best-effort repair)
> - Double-stringification of union types
> - Whitespace/newline normalization
> - Type coercion for non-critical fields (string "3" → int 3)
>
> **Non-recoverable errors (trigger retry):**
> - Missing required fields
> - Wrong field names (semantic, not formatting)
> - Content that violates contract constraints
> - Truncated output (incomplete response)
>
> **Per-executor quirk profiles.** Each executor model accumulates observed parsing quirks during onboarding. The lenient parser adapts based on the executor's profile. Example: Nemotron Cascade 2 consistently places answers in `reasoning_content` instead of `content` at 128K context — the parser checks both fields.
>
> **Design principle:** Parsing tolerance preserves the retry budget for semantic failures. A Ralph loop that burns 2 of 3 iterations on JSON formatting has 1 left for actual reasoning errors.

**Rationale:** Local models produce more formatting errors than frontier models. Each unnecessary retry burns context and latency. AutoBE documents 7 recoverable quirks; Nemotron's 128K content-field behavior (from TV2-013) is another.

**Affects tasks:** TV2-019 (contract schema — parsing spec), TV2-031b (contract runner implementation)

---

## Amendment V: Closed Schema Principle (§9.3 addition)

**Section:** §9.3 Design Principles — add new bullet

**Proposed addition:**

> - **Structural impossibility over prohibition.** Contract output schemas constrain what executors *can* produce, not what they should avoid. Prefer closed schemas (enumerated fields, typed unions, format-validated strings) over open schemas (freeform text with instructions). This extends C6 (no behavioral triggers for critical operations) from process design to output structure. Example: a contract expecting vault paths uses `Format<"vault-path">` type, not a string field with a prompt saying "only use real vault paths."

**Rationale:** AutoBE's schema constraint layer eliminates entire failure categories structurally. A model can't produce a utility function if the output format has no slot for one. Similarly, a Tess executor can't fabricate a vault path if the schema validates against the actual vault structure.

**Affects tasks:** TV2-019 (contract schema design)

---

## Amendment W: Convergence Rate as Escalation Signal (§7.3 addition)

**Section:** §7.3 Recommendation — add Gate 4

**Proposed addition after Gate 3:**

> **Gate 4: Convergence rate monitor.** Track per-action-class convergence rates over time. If a known task class that normally converges in 1-2 iterations starts requiring 3+ → signal either a harder-than-typical instance or model capability degradation. This is a mechanical signal, not self-reported confidence.
>
> Gate 4 also provides a routing feedback loop: if action class X consistently exhausts retry budgets on Nemotron but converges in 1 attempt on Kimi → reclassify X from Tier 1/2 to Tier 3 in the routing table. The routing table becomes self-tuning.
>
> ```yaml
> convergence_tracking:
>   action_class: "vault-write"
>   rolling_window: 20  # last 20 executions
>   avg_iterations: 1.3
>   p95_iterations: 2
>   escalation_threshold: 3  # flag if avg exceeds this
>   reclassification_threshold: 5  # promote tier if p95 exceeds this
> ```

**Rationale:** AutoBE demonstrates that strong models converge in 1-2 attempts, weak in 3-4. Retry count is an objective, mechanical confidence proxy — no self-assessment, no logprobs. Complements Gates 1-3 by providing longitudinal trend data.

**Affects tasks:** TV2-018 (escalation design), TV2-029 (calibration drift policy)

---

## Amendment X: Verifiability-Based Contract Classification (§9.1 addition)

**Section:** §9.1 What Is a Ralph Loop — add verifiability note

**Proposed addition:**

> **Contract verifiability tiers.** Not all contracts converge with equal mechanical certainty. Classify by verifiability to right-size validation effort:
>
> | Tier | Verifiability | Validation | Examples |
> |------|--------------|------------|---------|
> | V1: Deterministic | Output can be mechanically verified | Compiler, test suite, schema, file existence | Code generation, vault writes, structured reports |
> | V2: Heuristic | Output can be checked against rules + patterns | Schema + heuristic checks (section count, citation presence, length bounds) | Research briefs, knowledge notes, career recommendations |
> | V3: Judgment | Output quality requires evaluator model | Schema only for format; quality requires LLM evaluation | Creative writing, strategic analysis, escalation decisions |
>
> Ralph loops converge reliably for V1 (AutoBE demonstrates this across 10x parameter range). V2 contracts converge with looser stop conditions. V3 contracts use fixed iteration budgets rather than convergence detection.
>
> **Routing-by-verifiability (AD-010):** Route tasks to the cheapest tier where mechanical enforcement is possible. Nemotron handles V1 contracts locally. Kimi handles V2-V3 contracts where judgment is needed for evaluation. This aligns model cost with verification difficulty, not task perceived difficulty.

**Rationale:** Extends AD-010 (route by verifiability) into the contract schema design. Prevents over-engineering validation for judgment tasks and under-engineering it for mechanical ones.

**Affects tasks:** TV2-019 (contract schema), TV2-017 (state machine routing)

---

## Amendment Y: Orchestrator Plan-Before-Request Directive (§10b, TV2-023)

**Section:** §10b System Prompt Architecture, §5 Orchestrator Prompt Composition

**Current state:** TV2-023 §5.1 defines the orchestrator prompt as evaluation-focused (role: `evaluator`, Layer 2: routing table + executor profiles, Layer 4: quality_checks as primary instruction surface). The executor prompt includes an explicit anti-deferral directive (§5.2 Layer 1: "Produce your final answer directly. Do not defer to tool calls"). The orchestrator has no equivalent directive for its *planning* role — when it needs to decompose a complex task into a contract sequence rather than evaluate a single contract's output.

**Evidence:** Kimi K2.5 scored 2/5 on TC-05 (Multi-Step Orchestration) in both the March 30 and April 3 evaluations. The pattern is consistent: given complex tasks ("prepare morning briefing"), Kimi defaults to "what data do you have?" rather than "step 1: check feeds, step 2: check calendar, step 3: synthesize." This is the same behavioral class as TV2-013's tool-deferral pattern in Nemotron — models default to requesting inputs rather than structuring work. Qwen 3.6-Plus (the designated failover) showed the same weakness at lesser severity (3/5).

**Proposed additions:**

### Y1: Plan-Before-Request Layer 1 Directive

Add to the orchestrator Layer 1 template (alongside the existing role and response format directives):

> **Planning discipline.** When dispatched with a complex task that decomposes into multiple steps:
> 1. Output an ordered step plan FIRST — identify what needs to happen, in what sequence, with what dependencies.
> 2. For each step, classify whether it requires tool access, vault reads, or can be resolved from provided context.
> 3. Only THEN identify what data or tool access you need to execute the plan.
>
> Never respond to a planning prompt with only a data request. The plan is the primary output; data gaps are secondary metadata.

### Y2: Two-Turn Dispatch Pattern for Multi-Step Orchestration

Define a structured two-turn dispatch pattern for orchestration tasks that require both planning and execution:

> **Turn 1 (plan):** Orchestrator receives the task description + available context. Responds with a step plan in a constrained schema:
> ```yaml
> plan:
>   steps:
>     - id: 1
>       action: "check_feeds"
>       requires: ["fif_db_access"]
>       output: "feed_summary"
>     - id: 2
>       action: "check_calendar"
>       requires: ["google_calendar"]
>       depends_on: []
>       output: "calendar_events"
>     - id: 3
>       action: "synthesize_briefing"
>       requires: ["feed_summary", "calendar_events"]
>       depends_on: [1, 2]
>       output: "morning_briefing"
>   data_gaps: ["calendar OAuth token status"]
> ```
>
> **Turn 2 (execute):** Contract runner materializes the data for each step (dispatches sub-contracts or reads vault), then returns the plan + data to the orchestrator for synthesis.

This is the Ralph loop applied one level up: the orchestrator's plan is a contract, and the contract runner verifies the plan has the right structure before proceeding to execution.

### Y3: Service Context Layer 2 Enhancement

When the orchestrator is dispatched for a **planning** task (as opposed to an evaluation task), Layer 2 must include:

- The planning discipline directive (Y1)
- Available data sources and their access methods (so the orchestrator can classify step requirements)
- The plan schema (Y2) as the expected response format

This is distinct from evaluation dispatches where Layer 2 carries the routing table and executor profiles.

**Rationale:** The TC-05 weakness is not a bug — it's a consistent behavioral trait across frontier models when presented with complex tasks without explicit decomposition instructions. The executor anti-deferral directive (TV2-023 §5.2 line 240) solved the same problem for Nemotron. This amendment applies the same principle to the orchestration layer: structural enforcement over behavioral compliance (AD-006).

**Affects:**
- TV2-023 system prompt architecture (Layer 1 + Layer 2 orchestrator templates)
- Contract runner dispatch logic (two-turn orchestration pattern)
- Service interfaces for multi-step services (morning briefing, daily attention — any service where the orchestrator plans rather than evaluates)

**Priority:** High. This is load-bearing for production. Without it, the orchestrator will reliably ask for data instead of planning, and the contract runner will have no workflow to execute.

---

## Application Sequence

These amendments are design inputs, not immediate spec changes. Apply during Phase 3 task execution:

1. **TV2-017 (state machine):** Apply Amendments W, X for routing logic
2. **TV2-018 (escalation):** Apply Amendment W for Gate 4
3. **TV2-019 (contract schema):** Apply Amendments T, U, V for schema design
4. **TV2-031b (contract runner):** Apply Amendments T, U for runtime implementation
5. **TV2-023 (system prompt architecture):** Apply Amendment Y for orchestrator planning directive — load-bearing for any service where the orchestrator plans rather than evaluates

Spec text should be updated when the corresponding task begins — not before — to keep amendments grounded in implementation reality.

**Note (2026-04-03):** Amendment Y is high priority. The TC-05 pattern was confirmed across two evaluation rounds (Mar 30 and Apr 3) and affects both Kimi (primary) and Qwen 3.6-Plus (failover). It should be applied before any multi-step orchestration contracts are dispatched in production.
