---
project: tess-v2
type: design
domain: software
status: active
created: 2026-04-01
updated: 2026-04-01
task: TV2-018
skill_origin: action-architect
review: reviews/2026-04-01-state-machine-escalation.md
---

# Tess v2 — Confidence-Aware Escalation: Four-Gate Hybrid Design

Detailed design for escalation logic across the contract lifecycle. Gate 1 and Gate 3 fire at ROUTING time (mechanical). Gate 2 fires within EXECUTING first-turn (executor confidence). Gate 4 runs as a background process (convergence monitoring). Defines the confidence field schema, calibration procedure, re-entry behavior, and validation test plan.

## 1. Design Inputs

- §7 Confidence-Aware Escalation (three-gate recommendation, extended to four)
- AD-009 Risk-based escalation gate
- AD-007 Evaluator-executor separation
- AD-010 Route by verifiability
- TV2-013 orchestration tests — Nemotron orch-06 scored 3/5 on confidence threshold (correct classification in reasoning, wrong output format). See `progress/run-log.md` 2026-03-28 TV2-013 section.
- TV2-017 state machine — ROUTING runs Gate 1+3 only; Gate 2 in EXECUTING; Gate 4 is background
- Amendment W: Convergence rate as Gate 4 signal
- Amendment X: Verifiability tiers
- Cloud eval results — Kimi 0 fabrication across 10 tool-decision tests; Nemotron 0/3 guardrails across all 6 local candidates. See `eval-results/cloud-eval-results-2026-03-30.md` and `progress/run-log.md` TV2-010/011 sections.

## 2. Gate Architecture Overview

Four gates with different firing points in the contract lifecycle:

| Gate | Fires At | Type | Purpose |
|------|----------|------|---------|
| **Gate 1** | ROUTING | Mechanical | Classify task against routing table |
| **Gate 2** | EXECUTING (first iteration) | Executor self-report | Confidence check on Tier 1 tasks |
| **Gate 3** | ROUTING | Mechanical | Risk-based policy override |
| **Gate 4** | Background (post-terminal) | Mechanical | Convergence-based routing table updates |

```
ROUTING (mechanical only — no LLM calls)
─────────────────────────────────────────

Incoming Task
     │
     ▼
┌──────────┐   unknown     ┌───────────┐
│  Gate 1  │──────────────▶│  Tier 3   │
│ Boundary │               │ (forced)  │
│  Check   │               └───────────┘
└────┬─────┘
     │ known class → candidate tier
     ▼
┌──────────┐   risk match  ┌───────────────┐
│  Gate 3  │──────────────▶│  Tier 3 +     │
│Risk Policy│              │  PENDING_     │
│           │              │  APPROVAL     │
└────┬─────┘               └───────────────┘
     │ clear
     ▼
  Dispatch to
  assigned tier


EXECUTING (first iteration only)
─────────────────────────────────

Executor produces first response
     │
     ▼
┌──────────┐   low         ┌───────────┐
│  Gate 2  │──────────────▶│ ESCALATED │
│Confidence│               │ (Tier 3)  │
│  Field   │               └───────────┘
└────┬─────┘
     │ high/medium
     ▼
  Continue
  execution


BACKGROUND (post-terminal)
──────────────────────────

COMPLETED / DEAD_LETTER / ABANDONED
     │
     ▼
┌──────────┐   degraded    ┌───────────────┐
│  Gate 4  │──────────────▶│ Routing table │
│Convergence│              │ tier upgrade  │
│  Rate    │               │ (future tasks)│
└──────────┘               └───────────────┘
```

**Gate 1 + Gate 3 are the ROUTING gates.** They execute sequentially at ROUTING time. Both are mechanical — no LLM calls. ROUTING is fast and deterministic.

**Gate 2 fires in EXECUTING**, not ROUTING. This eliminates the causal loop of needing the executor's confidence before routing to that executor. The executor produces its confidence as part of its first work output. If `low`, the runner escalates immediately.

**Gate 3 fires regardless of Gate 1.** A known, Tier 1 task that touches credentials still gets escalated by Gate 3.

**Gate 4 is NOT a per-task gate.** It runs as a background process after contracts reach terminal states, updating the routing table to affect future contracts. It never fires during ROUTING for an individual contract.

## 3. Gate 1: Deterministic Boundary Check

### Routing Table

The routing table maps action classes to executor tiers. It is a static configuration (updated manually or via Gate 4 reclassification), not a runtime model decision. Production architecture: Tier 1 (Nemotron local), Tier 3 (Kimi cloud). No Tier 2 is currently deployed.

```yaml
routing_table:
  action_classes:
    # Tier 1 — local Nemotron, deterministic verification
    vault-write:
      tier: 1
      verifiability: V1
      description: "Write/update vault files with schema validation"
      examples: ["update frontmatter", "create knowledge note", "write progress log"]
    
    vault-read-analyze:
      tier: 1
      verifiability: V1
      description: "Read vault files and produce structured analysis"
      examples: ["summarize project state", "extract meeting actions", "check file freshness"]
    
    shell-execute:
      tier: 1
      verifiability: V1
      description: "Run deterministic shell commands with expected output"
      examples: ["vault-check", "git status", "health ping", "backup check"]
    
    structured-report:
      tier: 1
      verifiability: V2
      description: "Generate structured output from data inputs"
      examples: ["daily digest", "feed intel classification", "cost summary"]
    
    # Tier 3 — cloud Kimi, judgment required
    quality-evaluation:
      tier: 3
      verifiability: V3
      description: "Evaluate artifact quality against qualitative criteria"
      examples: ["review draft", "assess research quality", "evaluate contract output"]
    
    strategic-decision:
      tier: 3
      verifiability: V3
      description: "Decisions requiring context beyond current contract"
      examples: ["priority adjustment", "scope change recommendation", "escalation triage"]
    
    external-communication:
      tier: 3
      verifiability: V3
      description: "Draft or send external messages"
      examples: ["email draft", "Telegram message to Danny", "GitHub comment"]
      gate3_override: requires_human_approval
    
    # Dynamic — starts at Tier 1, may be reclassified by Gate 4
    feed-intel-classify:
      tier: 1
      verifiability: V2
      description: "Classify feed intel items by tier and action"
      examples: ["RSS item triage", "signal classification"]
      reclassifiable: true

  # Catch-all for unknown action classes
  unknown:
    tier: 3
    verifiability: V3
    description: "Unrecognized task type — cannot route mechanically"
    gate3_override: first_instance
```

### Matching Logic

1. Task arrives with metadata: `{type, target_paths, tools_required, keywords}`
2. Gate 1 matches against `action_classes` by:
   - Exact `type` match (if task type is explicit)
   - Target path pattern matching (e.g., `Projects/*/design/*` → vault-write)
   - Required tool set matching (e.g., `bash` + `grep` → shell-execute)
3. If no match → route to `unknown` (Tier 3, first-instance)
4. If ambiguous match (multiple classes) → highest tier among matches

Gate 1 output:
```yaml
gate1_result:
  matched_class: "vault-write"
  assigned_tier: 1
  verifiability: V1
  match_confidence: exact  # exact | pattern | ambiguous | none
```

## 4. Gate 2: Structured Confidence Field (in EXECUTING)

### When Gate 2 Fires

Gate 2 fires within `iteration_checking` on the **first iteration only** of contracts routed to Tier 1. The executor's structured response includes a `confidence` field alongside its work output.

Gate 2 is checked when:
- The contract was routed to Tier 1 (Nemotron)
- This is the first iteration (not a retry)

Gate 2 is NOT checked when:
- Contract is at Tier 3 (already at cloud tier)
- V1 verifiability with `match_confidence: exact` — confidence self-assessment adds no value when routing is mechanically certain
- Iteration > 1 (confidence was already assessed or irrelevant after the first attempt)

### Confidence Schema

```yaml
# Nemotron includes this in EVERY Tier 1 structured response
orchestration_response:
  action_class: "vault-write"
  decision: "execute locally"
  confidence: "high"          # high | medium | low
  confidence_signals:
    - "known action class, exact routing match"
    - "similar contract completed 3 times this week"
  uncertainty_flags: []       # populated when confidence < high
    # Examples: "unusual target path", "large file count",
    #           "overlapping with recent failed contract"
```

### Escalation Logic

| Confidence | Action |
|------------|--------|
| `high` | Continue execution. No escalation. |
| `medium` | Continue execution. Log for Gate 4 tracking. Flag in contract ledger. |
| `low` | ESCALATED — set `min_tier` from current tier, re-enter ROUTING (Gate 1 assigns next tier above floor). First iteration's staging discarded. |
| Missing | Treat as `low` (conservative default). |

### Why Gate 2 Is in EXECUTING, Not ROUTING

The spec §7.3 says the model "includes a confidence field in its structured output." This is a response-time field — the executor produces it alongside its work. Placing Gate 2 in ROUTING would create a causal loop: can't ask the executor for confidence before deciding to route to that executor.

By placing Gate 2 in EXECUTING:
- ROUTING stays fast and mechanical (Gate 1 + Gate 3 only, no LLM calls)
- The confidence check uses the executor's actual assessment of the specific task
- Cost of a low-confidence escalation: one wasted Nemotron iteration (free, ~2s)
- Staging artifacts from the first iteration are discarded on escalation

### Known Limitation: Nemotron Confidence Calibration

TV2-013 orch-06 showed Nemotron can classify confidence correctly in reasoning but sometimes fails to deliver the answer in the expected format (defers to tool call). This means:

1. The confidence field must be extracted from structured output, not from the response body
2. If Nemotron returns a tool call instead of the confidence response, the runner should:
   - Check `reasoning_content` for the confidence classification
   - If found: extract and use it
   - If not found: treat as `low` confidence (conservative default)
3. The system prompt must include explicit instruction: "Always include the confidence field in your JSON response. Do not search for additional context — produce your assessment now."

This is a prompt design issue (TV2-023), not a gate design issue. The gate logic assumes the field is present or defaults conservatively.

**Note:** Gate 2 behavior is model-dependent. Confidence thresholds are calibrated for Nemotron. Under DEGRADED-LOCAL (Qwen backup), see §9 for calibration adjustments.

## 5. Gate 3: Risk-Based Policy Escalation

Gate 3 is fully deterministic — no model involvement. It reads task metadata against a policy table. Fires at ROUTING time, after Gate 1.

### Policy Table

```yaml
risk_policy:
  # Each rule: if condition matches, apply action
  rules:
    - name: credential_access
      condition:
        tools_required_contains: ["keychain_read", "env_inject", "oauth_refresh"]
        OR target_paths_match: ["*credential*", "*.env", "*secret*"]
      action: escalate_tier3
      requires_human_approval: false
      human_escalation_class: review_within_24h
    
    - name: destructive_operation
      condition:
        tools_required_contains: ["file_delete", "git_reset", "vault_overwrite"]
        OR operations_include: ["delete", "overwrite_canonical"]
      action: escalate_tier3
      requires_human_approval: true
      human_escalation_class: urgent_blocking
    
    - name: external_communication
      condition:
        tools_required_contains: ["send_email", "send_telegram", "post_github"]
        OR action_class_in: ["external-communication"]
      action: escalate_tier3
      requires_human_approval: true
      human_escalation_class: review_within_24h
    
    - name: financial_action
      condition:
        keywords_contain: ["purchase", "subscribe", "payment", "budget_commit"]
      action: escalate_tier3
      requires_human_approval: true
      human_escalation_class: urgent_blocking
    
    - name: first_instance
      condition:
        action_class_history_count: 0  # never seen this class before
      action: escalate_tier3
      requires_human_approval: true  # conservative default; relax after 20+ novel classes
      human_escalation_class: review_within_24h
    
    - name: prior_quality_failure
      condition:
        action_class_quality_pass_rate: < 0.60  # over last 10 contracts
      action: escalate_tier3
      requires_human_approval: false
      human_escalation_class: fyi_digest
    
    - name: system_modification
      condition:
        target_paths_match: ["_system/*", "CLAUDE.md", ".claude/*"]
      action: escalate_tier3
      requires_human_approval: true
      human_escalation_class: review_within_24h
```

### Gate 3 Output

```yaml
gate3_result:
  rules_matched: ["credential_access"]
  escalated: true
  requires_human_approval: false
  human_escalation_class: "review_within_24h"
  override_reason: "Task accesses keychain_read tool"
```

### Gate 3 + Human Approval Integration

When `requires_human_approval: true`, the contract transitions from ROUTING → PENDING_APPROVAL (not DISPATCHED). **Execution does not begin until Danny approves.** This is safety-critical: side-effecting tools (`send_email`, `send_telegram`, `git_reset`) execute during `iteration_working` and are irreversible.

- **Fires regardless of Gate 1.** A known, Tier 1 vault-write that touches `_system/` still gets escalated.
- **Multiple rules can match.** Strictest `human_escalation_class` applies (urgent > review > fyi).
- **`requires_human_approval` is additive.** If ANY matched rule requires it, the contract gets the flag.
- **Rules are auditable.** Every Gate 3 decision is logged with matched rules.

### AD-009 Validation

The AC requires: "tests confirm credential, destructive, and external-comms tasks deterministically force escalation regardless of confidence."

Validation approach:
1. Feed Gate 3 a task with `action_class: vault-write` (Tier 1 by Gate 1)
2. Add `tools_required: ["keychain_read"]` → Gate 3 must escalate to Tier 3
3. Add `operations_include: ["delete"]` → Gate 3 must escalate + `requires_human_approval` + PENDING_APPROVAL
4. Add `tools_required: ["send_telegram"]` → Gate 3 must escalate + `requires_human_approval` + PENDING_APPROVAL
5. Confirm all three independently override Gate 1's Tier 1 assignment

This is a deterministic test — it validates the policy engine, not the model.

## 6. Gate 4: Convergence Rate Monitor (Background)

Gate 4 is a background monitoring process. It does NOT fire during ROUTING for individual contracts. It adjusts the routing table to affect future contracts based on longitudinal convergence data.

### Mechanism

After every contract reaches a terminal state (COMPLETED, DEAD_LETTER, ABANDONED), the convergence tracker updates. ESCALATED is non-terminal and not counted — the contract's eventual terminal state captures the full outcome.

```yaml
convergence_tracker:
  action_classes:
    vault-write:
      window: 20
      minimum_sample: 10  # ≥10 contracts before stats drive decisions
      entries:
        - {contract_id: "C-001", iterations: 1, initial_tier: 1, executor_tier: 1, outcome: completed, escalated: false, escalation_chain: []}
        - {contract_id: "C-002", iterations: 3, initial_tier: 1, executor_tier: 3, outcome: completed, escalated: true, escalation_chain: [{from_tier: 1, to_tier: 3, reason: "reasoning_failure"}]}
        # ...
      stats:
        avg_iterations: 1.3
        p95_iterations: 2
        escalation_rate: 0.05
        quality_pass_rate: 0.95
      current_tier: 1
```

**Source tier tracking:** The `initial_tier` and `escalation_chain` fields enable Gate 4 to attribute failures to the tier that failed, not just the tier that eventually completed. A contract that escalates from Tier 1 to Tier 3 and completes counts as a Tier 1 failure signal for reclassification purposes.

### Reclassification Triggers

| Condition | Action |
|-----------|--------|
| `p95_iterations > 5` (two consecutive windows) | Promote action class to next tier. Alert Danny. |
| `escalation_rate > 0.30` (two consecutive windows) | Promote action class to next tier. Alert Danny. |
| `quality_pass_rate < 0.70` (two consecutive windows) | Promote action class to next tier. Alert Danny. |
| `avg_iterations < 1.5` AND `quality_pass_rate > 0.95` for 50+ contracts | Candidate for demotion. Flag for Danny review — no auto-demotion. |

### Guards

- **Minimum-sample gate:** No reclassification until ≥`minimum_sample` (10) contracts in the window.
- **Hysteresis:** Two consecutive evaluation windows must exceed the threshold (evaluated daily). Prevents oscillation from bursty failures.
- **Tier upgrades are automatic** (conservative — prevents repeated failures).
- **Tier demotions are manual** (Danny must approve — prevents oscillation).

## 7. Escalation Re-Entry Behavior

When a contract transitions from ESCALATED → ROUTING (TV2-017 §6), the gates behave differently than on initial entry:

| Gate | Re-Entry Behavior |
|------|-------------------|
| **Gate 1** | Re-fires with `min_tier` floor from escalation source. Cannot route below the tier that failed. |
| **Gate 3** | Re-fires. Risk policy always applies. A task that wasn't risky initially still isn't, but the check is mandatory for safety. |
| **Gate 2** | Skipped when `assigned_tier > 1` OR `escalation_reason == low_confidence_gate2`. Correct for current two-tier arch (re-entry always goes Tier 3); safe under future Tier 2 additions. |
| **Gate 4** | Not applicable. Background process, not per-task. |

### Quality Failure Re-Entry

When ESCALATED is entered from QUALITY_FAILED (V3 contracts with `quality_retry_remaining > 0`), the re-entry carries `escalation_reason: quality_failed` and the quality evaluation output as structured failure context (per Amendment T format). This allows the re-dispatched executor to address specific quality deficiencies identified by the evaluator.

### Budget Invariant

**Gate outputs never modify the retry budget.** Rerouting via ESCALATED → ROUTING preserves the contract-level iteration counters from TV2-017. The retry budget is per-contract, not per-executor. Escalation is a routing change, not a retry.

## 8. Evaluator Perspective Separation (AD-007)

The escalation system enforces a strict boundary: **the executor never evaluates its own work.**

### Separation Points

| Decision | Who Decides | Mechanism |
|----------|-------------|-----------|
| "Is this task type known?" | Gate 1 (mechanical) | Routing table lookup — at ROUTING |
| "Am I confident?" | Nemotron (Gate 2) | Structured output field — at EXECUTING i1 |
| "Is this task risky?" | Gate 3 (mechanical) | Policy table lookup — at ROUTING |
| "Did the executor satisfy the contract?" | Runner (mechanical) | Test + artifact checks |
| "Is the output good enough to promote?" | Tess/Kimi (orchestrator) | Quality check evaluation |
| "Should this action class be reclassified?" | Gate 4 (mechanical) + Danny | Convergence stats + human review — background |

### The Gate 2 Exception

Gate 2 is the only gate where the executor provides input to its own routing decision. This is by design — only the model knows if it's uncertain about a specific task instance. The mitigations:

1. Gate 2 only fires for Tier 1 tasks (low-stakes decisions)
2. Gate 3 overrides Gate 2 for high-stakes decisions regardless
3. Conservative default: missing confidence field → treat as `low`
4. Gate 4 catches systematic miscalibration over time
5. Gate 2 fires AFTER dispatch (in EXECUTING) — the cost of a false `high` is one wasted local iteration, not a safety failure

The model's confidence self-report is a speed optimization, not a safety mechanism. Safety comes from mechanical verification (tests + artifacts) and evaluator separation (quality_checks).

## 9. Calibration Procedure

### Initial Calibration (Phase 4 onboarding)

When a new action class is first registered:

1. **First 5 contracts run at Tier 3** (first-instance rule in Gate 3)
2. After 5 successful Tier 3 executions with quality pass rate ≥ 0.80:
   - Gate 3 first-instance rule no longer applies
   - Action class eligible for its routing-table tier
3. First 10 contracts at routing-table tier are tracked with extra logging:
   - Full confidence field + reasoning logged
   - Quality evaluation includes calibration notes
4. After 10 contracts: action class is considered calibrated. Normal tracking via Gate 4.

### Production Calibration Monitoring

- **Weekly digest:** Convergence stats per action class included in health digest
- **Drift detection:** If any action class's `avg_iterations` increases by >50% over 2 weeks, flag for review
- **Production-length prompt test:** §7.4 requires validating confidence at 8-15K tokens. The system prompt architecture (TV2-023) must ensure calibration tests use production-representative context sizes, not minimal prompts.

### DEGRADED-LOCAL Calibration (TV2-042 Interaction)

Gate 2 confidence thresholds are calibrated for Nemotron (TV2-013 benchmarks). When the failover design swaps Nemotron for the Qwen 35B MoE backup on the same port (DEGRADED-LOCAL mode), Gate 2 fires against Qwen's confidence output using Nemotron's calibration data. Qwen may have systematically different confidence expression patterns.

**Rule:** Under DEGRADED-LOCAL, treat all Gate 2 confidence as `medium` until Qwen-specific calibration data is available (deferred to TV2-029). This means Tier 1 tasks continue locally but are flagged in the ledger for Gate 4 tracking. The practical effect: no escalation from Gate 2 during DEGRADED-LOCAL, but convergence data accumulates for future calibration.

### Recalibration Triggers

| Trigger | Action |
|---------|--------|
| Model version change (GGUF swap) | Reset all Gate 4 windows. Run first-instance on critical action classes. |
| System prompt change (TV2-023 update) | Run confidence calibration test suite (5 known-class + 5 novel-class prompts) |
| Gate 4 reclassification event | Log reason, review adjacent action classes for similar drift |

## 10. Validation Test Plan

### Gate Logic Tests (Deterministic — no model involved)

| Test ID | Description | Expected Outcome |
|---------|-------------|-----------------|
| ESC-01 | Known action class, exact match | Gate 1 assigns Tier 1, no escalation |
| ESC-02 | Unknown action class | Gate 1 routes to Tier 3 |
| ESC-03 | Ambiguous match (2 classes) | Gate 1 routes to higher tier |
| ESC-04 | Tier 1 task, first iteration `confidence: low` | Gate 2 triggers ESCALATED to Tier 3 |
| ESC-05 | Tier 1 task, high confidence, credential tool | Gate 3 overrides to Tier 3 |
| ESC-06 | Tier 1 task, high confidence, destructive op | Gate 3 escalates + PENDING_APPROVAL |
| ESC-07 | Tier 1 task, high confidence, external comms | Gate 3 escalates + PENDING_APPROVAL |
| ESC-08 | First-instance action class | Gate 3 escalates to Tier 3 + PENDING_APPROVAL |
| ESC-09 | Action class with p95 > 5 for two consecutive windows | Gate 4 reclassifies upward |
| ESC-10 | V1 task with exact match | Gate 2 skipped (no confidence check) |
| ESC-11 | Re-entry from ESCALATED | Gate 1 respects min_tier floor, Gate 3 re-fires, Gate 2 skipped |

### Model Calibration Tests (Nemotron)

| Test ID | Description | Expected Outcome |
|---------|-------------|-----------------|
| CAL-01 | 5 known-class tasks at production prompt length | `confidence: high`, iterations ≤ 2 |
| CAL-02 | 5 novel-class tasks | `confidence: low` or missing (treated as low) |
| CAL-03 | Known class with adversarial twist | `confidence: medium` or `low` |
| CAL-04 | Known class but requiring credentials | Gate 3 fires regardless of confidence |
| CAL-05 | Repeat CAL-01 at 4K vs 16K context | Confidence stable across context sizes |

### Integration Tests (Full Pipeline)

| Test ID | Description | Expected Outcome |
|---------|-------------|-----------------|
| INT-01 | Contract through Gate 1+3 → Tier 1 → Gate 2 high → completes | Normal flow, no escalation |
| INT-02 | Contract through Gate 3 → PENDING_APPROVAL → Danny approves → completes | Approval flow exercised |
| INT-03 | Contract through Gate 3 → PENDING_APPROVAL → Danny rejects → ABANDONED | Rejection flow exercised |
| INT-04 | Simulated Gate 4 reclassification (two consecutive windows) | Routing table updated, subsequent contracts route higher |
| INT-05 | Re-entry from ESCALATED → Gate 1 with min_tier → Tier 3 | Escalation chain works end-to-end |
| INT-06 | Contract escalated from Tier 1 (budget exhausted), re-enters ROUTING at Tier 3, Gate 3 matches destructive_operation → PENDING_APPROVAL. Danny approves. Dispatches to Tier 3 with failure contexts preserved. | Approval notification includes remaining budget and escalation history |

## 11. Scenario Walkthroughs

### Scenario 1: Confidently-Wrong Local Model Decision

**Setup:** Nemotron receives a vault-write task. Known class (Tier 1). Nemotron reports `confidence: high` in its first response. But the output contains hallucinated file paths.

**Gate traversal at ROUTING:**
1. **Gate 1:** vault-write → Tier 1, exact match. PASS.
2. **Gate 3:** No risk rules match. PASS.
3. **Result:** Dispatched to Nemotron at Tier 1.

**Gate 2 at EXECUTING (first iteration):**
- Nemotron's response includes `confidence: high` → Gate 2 PASS.

**What catches the error:**
- NOT the gates — they correctly routed based on available information
- The CONTRACT RUNNER catches it: `test: file_exists` for the hallucinated paths → FAILS
- Ralph loop retries with structured failure context
- If Nemotron corrects in iteration 2 → contract proceeds
- If same failure repeats → bad-spec detection or budget exhaustion → ESCALATED/DEAD_LETTER
- Gate 4 records: vault-write took N iterations or escalated. Pattern triggers reclassification if repeated.

**Key insight:** Confidently-wrong decisions are caught by contract termination checks (deterministic), not by confidence self-assessment. Gate 2 is a speed optimization. Safety comes from mechanical verification (tests + artifacts) and evaluator separation (quality_checks).

### Scenario 2: Gate 3 Overriding a Tier 1 Task

**Setup:** A vault-write task that updates `_system/docs/file-conventions.md`. Gate 1 routes it to Tier 1 (known class). But the target path triggers Gate 3.

**Gate traversal at ROUTING:**
1. **Gate 1:** vault-write → Tier 1, exact match.
2. **Gate 3:** `system_modification` rule matches (`target_paths_match: ["_system/*"]`). OVERRIDES to Tier 3. Sets `requires_human_approval: true`.
3. **Result:** ROUTING → PENDING_APPROVAL. Danny alerted.

**Danny approves:**
- PENDING_APPROVAL → DISPATCHED (Kimi, Tier 3) → EXECUTING → normal flow.

**Key property demonstrated:** Gate 3 deterministically overrides Gate 1's Tier 1 assignment based on the target path, regardless of confidence or model capability. The task never executes until Danny approves.

### Scenario 3: First-Instance Task Class

**Setup:** A new type of task arrives: "analyze competitive pricing data from a spreadsheet." Never seen before.

**Gate traversal at ROUTING:**
1. **Gate 1:** No match in routing table. → `unknown`, Tier 3.
2. **Gate 3:** `first_instance` rule matches (`action_class_history_count: 0`). Escalates to Tier 3 (already there). `requires_human_approval: true` (conservative default for first-instance). `human_escalation_class: review_within_24h`.
3. **Result:** ROUTING → PENDING_APPROVAL. Danny alerted via Telegram with task description and "first-instance" classification.

**Danny approves:**
- PENDING_APPROVAL → DISPATCHED (Kimi, Tier 3) → EXECUTING → normal flow.

**Post-completion calibration:**
- After 5 successful Tier 3 completions → first-instance rule deactivates (no more PENDING_APPROVAL for this class)
- Danny can add as named action class at Tier 1
- First 10 contracts at Tier 1 tracked with extra calibration logging
- After 10+ contracts → fully calibrated, Gate 4 monitors
- First-instance approval gating can be relaxed to `requires_human_approval: false` after operational confidence is established across 20+ novel task classes

## 12. Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Gate 1+3 at ROUTING, Gate 2 at EXECUTING | Eliminates causal loop; ROUTING stays mechanical | Can't ask executor for confidence before routing to it |
| Gate 4 as background process | Longitudinal trend data, not per-contract | Routing table updates affect future tasks |
| Gate 2 scope | Tier 1 only, skip for V1+exact match | Confidence self-report adds no value for mechanically-certain routing |
| Gate 2 fires iteration 1 only | Later iterations already have failure data | Confidence matters for initial assessment, not retries |
| Missing confidence field | Treat as `low` | Conservative default prevents silent routing failures |
| Gate 3 → PENDING_APPROVAL | Side-effecting tools are irreversible | Approval must precede execution |
| Gate 4 auto-upgrade, manual demotion | Prevents repeated failures AND oscillation | Auto-upgrade is conservative; auto-demotion would be risky |
| Hysteresis on reclassification | Two consecutive windows | Prevents bursty failures from triggering premature tier changes |
| Minimum sample for Gate 4 | ≥10 contracts | Low-volume classes need more data before stats are meaningful |
| Budget invariant across gates | Per-contract, never modified by gates | Prevents unbounded retries on re-routing |
| Policy table format | YAML rules | Auditable, version-controlled, testable without model involvement |

## 13. Interaction with Other Designs

| Component | Interface |
|-----------|-----------|
| **TV2-017 (State Machine)** | Gate 1+3 feed ROUTING state. Gate 2 checked in EXECUTING `iteration_checking`. Gate 4 updates routing table in background. PENDING_APPROVAL state for human approval. |
| **TV2-019 (Contract Schema)** | `requires_human_approval` flag derived from Gate 3. `confidence` field schema from Gate 2. |
| **TV2-023 (System Prompt)** | Must include confidence field instruction for Nemotron. Must validate calibration at production prompt lengths. |
| **TV2-029 (Calibration Drift)** | Gate 4 convergence data feeds drift monitoring. Recalibration triggers defined here. |
| **TV2-031b (Contract Runner)** | Implements gate logic. Gate 1+3 at dispatch time. Gate 2 check during `iteration_checking`. Consumes routing table and policy table. |
| **TV2-042 (Local Model Failover)** | DEGRADED-LOCAL mode affects Gate 2 calibration validity (§9). CLOUD-FALLBACK mode makes Tier 1 physically unavailable — Hermes provider chain resolves to cloud. |
