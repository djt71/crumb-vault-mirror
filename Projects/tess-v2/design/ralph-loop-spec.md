---
type: design
domain: software
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-020
---

# Tess v2 — Ralph Loop Implementation Spec

> **Scope:** Generally applicable beyond tess-v2. The Ralph-loop execution primitive (one contract per session, fresh context, hard stop, cumulative failure-context compaction) is a reusable pattern for any autonomous-agent system with bounded iteration budgets. See `_system/docs/tess-v2-durable-patterns.md`.

Implementation-level companion to spec §9 (architecture) and state-machine-design.md §3
(sub-states). Covers iteration budget enforcement, failure context injection, hard stop
mechanics, partial completion policy, return envelope parsing, and convergence tracking.

## 1. Loop Architecture

### 1.1 One Contract, One Loop, One Executor Per Iteration

A Ralph loop is the execution primitive for a single contract (1:1 relationship). It runs
at most `retry_budget` iterations, each a fresh executor session with no conversation
continuity. The runner is the loop owner — a mechanical process with no LLM judgment.

```
Runner (loop owner)
  ├── Iteration 1 → Executor session (fresh) → Runner evaluates
  ├── Iteration 2 → Executor session (fresh) → Runner evaluates
  └── Iteration N → Executor session (fresh) → Runner evaluates → Terminal decision
```

### 1.2 Executor Visibility

Each iteration, the executor receives a prompt envelope per TV2-023 layers:

| Layer | Content | Budget |
|-------|---------|--------|
| 1 | Stable header: identity, role, datetime, hard constraints, response format | <=1.5K |
| 2 | Service context: routing table, action class, executor profile, tools | 2-4K |
| 3 | Overlays: 0-3 behavioral overlays selected by task type | 0-3K |
| 4 | Contract YAML verbatim: tests, artifacts, quality_checks, staging_path, budget | 1-3K |
| 5 | Vault context: file contents from contract `read_paths` | Remaining |
| 6 | Failure context: structured diagnostics from prior iterations (iteration 2+) | 1-2K |

**The executor does NOT see:** previous iteration's full output, other contracts,
orchestrator state, escalation history, or quality check results (AD-007 separation).

### 1.3 Executor Contract

The executor must: (1) write all artifacts to `staging_path`, (2) return a structured
result envelope (§6), (3) include `confidence` on iteration 1 for Tier 1 contracts.

The executor must NOT: (1) write outside `staging_path`, (2) self-terminate the loop,
(3) modify contract or Layer 1-4 content.

## 2. Iteration Budget Enforcement

### 2.1 Budget Tracking

Runner maintains iteration state in memory (not on the immutable contract):

```yaml
ralph_loop_state:
  contract_id: "TV2-033-C1"
  retry_budget: 3                 # From contract — never modified
  iterations_used: 0              # Incremented after each iteration evaluation
  iterations_remaining: 3         # Decremented on failure only; exhaustion check: remaining == 0
  consecutive_timeouts: 0          # Incremented on timeout; reset on non-timeout completion
  current_iteration: 0            # Set to iterations_used + 1 at iteration_start
  failure_contexts: []            # Accumulated failure context objects
  current_sub_state: "iteration_start"
  gate2_evaluated: false          # True after first iteration_checking
  executor_tier: 1                # Current tier assignment
```

### 2.2 Budget Decrement Rules

Budget is consumed when an iteration completes and **fails** evaluation:
- ANY test/artifact fails: `iterations_used += 1`, `iterations_remaining -= 1` → `retry_preparing`
- ALL pass: `iterations_used += 1` (for convergence record) → `iteration_passed` → STAGED

`iterations_used` counts completed iterations (both pass and fail). `iterations_remaining`
decrements only on failure. The exhaustion check is `iterations_remaining == 0`, not a sum
invariant. After successful termination, `iterations_remaining` may be non-zero, representing
unused retry capacity.

**What does NOT consume budget:**
- Escalation routing changes (tier upgrade carries the iteration counter forward)
- Gate 2 confidence escalation on first iteration (routing correction, not retry)
- Lenient parsing recovery (Amendment U format fixes)

### 2.3 Budget Exhaustion

```
retry_preparing
  ├── iterations_remaining > 0 → build failure context → iteration_start (loop)
  └── iterations_remaining == 0 → budget_exhausted → ESCALATED
```

Transition is to ESCALATED, not DEAD_LETTER. Escalation re-routes to a higher tier.
DEAD_LETTER only when max tier is exhausted or max tier also exhausted its budget.

### 2.4 Quality Retry Budget (V3 Only)

Separate counter operating outside the Ralph loop:

```yaml
quality_retry_state:
  quality_retry_budget: 1         # From contract (V3 only; V1/V2 must be 0)
  quality_retries_used: 0
  quality_retries_remaining: 1
```

Fires after QUALITY_EVAL fails for V3 contracts. Re-dispatches through ESCALATED →
ROUTING → DISPATCHED → EXECUTING with full `retry_budget` restored but
`quality_retry_budget` decremented. A V3 contract with `retry_budget: 3` and
`quality_retry_budget: 1` can execute up to 6 total iterations (3 per loop).

V1/V2 quality failures route directly to `partial_promotion` policy.

## 3. Failure Context Injection

### 3.1 Schema

Per Amendment T (contract-schema.md §1.3):

```yaml
failure_context:
  iteration: 1
  failed_checks:
    - check_id: "test_frontmatter_valid"
      check_type: "test"               # test | artifact | quality_check
      expected: "status field present"
      actual: "status field missing"
      delta: "frontmatter missing required 'status' field"
  failure_class: "deterministic"        # deterministic | reasoning | tool | semantic
  retry_strategy: "fix input, same executor"
  budget_remaining: 2
```

### 3.2 What Carries Forward / What Does Not

**Carries forward:** failed check IDs, expected vs actual, delta, failure class,
retry strategy recommendation, budget remaining.

**Does NOT carry forward:** previous iteration's full output, reasoning traces,
intermediate artifacts (staging is overwritten per iteration), orchestrator state.

**Exception:** When `failure_class: reasoning`, the runner includes a one-paragraph
summary (<=200 tokens) of the prior iteration's approach so the executor can avoid
repeating the same reasoning path.

### 3.3 Accumulation Policy

Failure context is **cumulative** with compaction under budget pressure.

**Default:** Iteration N sees failures from all prior iterations (1 through N-1) as
separate entries in the `failure_contexts` array.

**Compaction (Layer 6 exceeds 2K tokens):** Preserve most recent failure in full;
reduce prior failures to `{iteration, failure_class, failed_check_ids_only}`.

In practice with `retry_budget: 3`, compaction rarely triggers — two structured
failure context objects fit within 2K tokens.

### 3.4 Failure Class Determination

| Pattern | Classification | Strategy |
|---------|---------------|----------|
| Fixable check failure (missing field, wrong path) | `deterministic` | Fix input, same executor |
| Different checks fail across iterations | `reasoning` | Change approach or escalate tier |
| No executor output (timeout, crash, API error) | `tool` | Defer/requeue with backoff |
| Same check_id + failure_class across 2+ consecutive iterations | `semantic` | Bad-spec → DEAD_LETTER |

**Bad-spec detection:** `semantic` classification short-circuits the loop: EXECUTING →
DEAD_LETTER with `reason: bad_spec` (state-machine-design.md §3).

**Precedence rule:** Bad-spec/semantic detection is an exception to normal budget
exhaustion and tier escalation. Upon detection (same `check_id` + `failure_class` across
2+ consecutive iterations), the runner transitions directly to DEAD_LETTER regardless of
remaining retry budget or available higher tiers. Rationale: if the same check fails the
same way twice consecutively, a higher tier or more retries won't fix a specification
error. This takes precedence over the §2.3 budget exhaustion → ESCALATED path.

## 4. Hard Stop Mechanics

### 4.1 Termination Is a Runner Decision

The runner -- not the executor -- decides termination. The executor produces output;
the runner evaluates against contract tests and artifacts.

```
     Executor returns result
              │
              ▼
     Lenient parse (§6.2) ←── Amendment U
              │
              ▼
     Gate 2 check (iteration 1, Tier 1 only)
              │
              ▼
     Run ALL tests (collect all results even if early ones fail)
              │
              ▼
     Run ALL artifact checks
              │
         ┌────┴────┐
     all pass    any fail
         │         │
         ▼         ▼
      STAGED    Classify failure
                   │
                   ▼
            1. Bad-spec pattern?
               (same check_id + failure_class
                across 2+ consecutive iterations)
                   │
              ┌────┴────┐
             yes        no
              │         │
              ▼         ▼
         DEAD_LETTER  2. Budget remaining?
                        │
                   ┌────┴────┐
                budget ok  budget gone
                   │         │
                   ▼         ▼
              3. Inject   ESCALATED
              failure     (or DEAD_LETTER
              context     if max tier)
              → next
              iteration
```

### 4.2 Timeout Enforcement

No executor response within `timeout` (default PT5M) → tool-class failure:

```yaml
failure_context:
  iteration: 2
  failed_checks:
    - check_id: "_timeout"        # Synthetic — runner-injected
      check_type: "system"
      expected: "executor response within 300s"
      actual: "no response after 300s"
      delta: "executor timeout — no output produced"
  failure_class: "tool"
  retry_strategy: "defer and requeue with backoff"
  budget_remaining: 1
```

- Budget remaining > 0 → retry with 30s backoff before next dispatch.
- Budget exhausted → ESCALATED.
- `consecutive_timeouts >= 2` → ESCALATED regardless of remaining budget (infrastructure problem).

**`consecutive_timeouts` tracking:** Increment `consecutive_timeouts` on every timeout.
Reset to 0 on any non-timeout iteration completion (pass or fail). The field lives in
`ralph_loop_state` (§2.1) and is evaluated before the budget check.

### 4.3 Executor Self-Termination Prevention

The executor's `status` field is informational only. The runner's evaluation is
authoritative. An executor claiming "completed" that failed a test → iteration fails.
An executor claiming "failed" where all tests pass → iteration succeeds → STAGED.

## 5. Partial Completion Policy

### 5.1 Budget Exhausted with Partial Work

When `iterations_remaining == 0` and some tests pass but not all:

1. Runner builds escalation context: passed/failed checks, accumulated failure contexts,
   `iterations_used == retry_budget`, last return envelope.
2. Contract transitions EXECUTING → ESCALATED.
3. **Staging artifacts are preserved** (not cleaned up on escalation).

### 5.2 Escalation Resolution

**Higher tier available:** Re-enters ROUTING → DISPATCHED → EXECUTING. Budget resets
(prior tier's exhaustion reflects its capability, not task difficulty). Failure contexts
from prior tier carry forward as initial context for the new loop.

**Max tier exhausted:** ESCALATED → DEAD_LETTER. Staging preserved for manual inspection.
Dead-letter entry includes full failure history, partial test results, staging path.

### 5.3 Partial Promotion via QUALITY_FAILED

When tests + artifacts all passed but quality evaluation fails:

| Policy | Behavior | Terminal State |
|--------|----------|---------------|
| `discard` | Staging abandoned | ABANDONED |
| `hold_for_review` | Staging preserved, dead-letter for Danny | DEAD_LETTER |
| `promote_passing` | Passing artifacts promote; failing stay in staging | PROMOTION_PENDING (subset) |

### 5.4 Convergence Record

Populated at terminal state regardless of outcome:

```yaml
convergence_record:
  iterations_used: 3
  initial_tier: 1
  final_tier: 3
  escalated: true
  escalation_chain:
    - from_tier: 1
      to_tier: 3
      reason: "budget_exhaustion"
  outcome: "dead_letter"          # completed | dead_letter | abandoned
```

## 6. Executor Return Envelope Parsing

### 6.1 Expected Envelope

Canonical schema (contract-schema.md §1.4):

```yaml
execution_result:
  contract_id: "TV2-033-C1"
  status: "completed"              # completed | failed | escalated
  iterations: 2
  staging_path: "_staging/TV2-033-C1/"
  artifacts_produced:
    - path: "_staging/TV2-033-C1/vault-health-notes.md"
      sha256: "a1b2c3..."
  test_results:
    - test: "test_file_exists"
      result: "pass"
  confidence: "high"               # high | medium | low
  confidence_signals: []
  uncertainty_flags: []
  failure_summary: null
  failure_class: null
  token_usage:
    input: 12400
    output: 3200
```

### 6.2 Lenient Parsing Layer (Amendment U)

Sits between `iteration_working` and `iteration_checking`. Applies only to executor
output (contract YAML is validated strictly per Amendment V).

```
Raw executor output
  → Strip markdown code fences
  → Normalize whitespace, trailing commas
  → YAML parse
       success → validate fields
       fail → JSON parse
                 success → convert to YAML
                 fail → regex extraction of key fields
                           success → partial envelope
                           fail → DETERMINISTIC failure class (see parser outcome table)
```

**Recoverable (fix silently, log):** code fences, trailing commas, whitespace,
type coercion (`"3"` → `3`), double-stringification, unclosed brackets.

**Non-recoverable (trigger retry):** missing required fields, wrong field names,
constraint violations, truncated output, unparseable output.

**Parser outcome table** — canonical budget and classification rules for all parse paths:

| Parser Outcome | Budget Consumed | Failure Class | Next Action |
|---|---|---|---|
| Clean parse (valid envelope) | No (parse succeeds) | N/A | Proceed to evaluation |
| Recoverable formatting fix | No | N/A | Fix applied, proceed to evaluation |
| Partial envelope recovered | Yes (normal eval) | Per check results | Evaluate what was recovered |
| Unrecoverable — no parseable content | Yes | `deterministic` | Retry (executor needs formatting fix) |
| No response (timeout/crash/API) | Yes | `tool` | Retry with backoff |

Key distinction: unrecoverable parse failure is classified `deterministic` (formatting
issue the executor can correct), NOT `tool`. The `tool` class is reserved for actual
infrastructure failures where no executor output was produced (timeout, crash, API error).

**Per-executor quirk profiles:** Parser adapts per model. Example: Nemotron uses
`reasoning_content` instead of `content` at 128K context — parser checks both.

### 6.3 Distinguishing Completion States

| State | Detection | Runner Action |
|-------|-----------|---------------|
| Completed, tests pass | Envelope parsed, all checks pass | → STAGED |
| Completed, tests fail | Envelope parsed, some checks fail | → retry_preparing |
| Unparseable output | LLM responded but no parseable envelope after lenient recovery | → deterministic-class failure (see §6.2 parser outcome table) |
| No response / infra error | Timeout, crash, or API error — no executor output produced | → tool-class failure |

"Tests failed" produces check-level diagnostics. "Unparseable output" produces a synthetic
`_parse_failure` entry classified `deterministic` (executor formatting issue). "No response"
produces a synthetic `_timeout` or `_crash` entry classified `tool` (infrastructure issue).

### 6.4 Token Usage Extraction

`token_usage` is optional. When present: cost accounting, budget forecasting, and
convergence tracking (Gate 4 input). When absent: runner estimates from prompt envelope
size and response length, flagged `estimated: true` in cost ledger.

## 7. Convergence Tracking Integration

### 7.1 What Gets Written

At terminal state, runner populates `convergence_record` — the only contract field
written after dispatch (system-managed, write-only):

```yaml
convergence_record:
  iterations_used: 2
  initial_tier: 1
  final_tier: 1
  escalated: false
  escalation_chain: []
  outcome: "completed"
```

### 7.2 Convergence Mode Interaction

**`adaptive` (V1/V2):** `iterations_used` is a convergence signal. Gate 4 tracks
`avg_iterations` and `p95_iterations` per action class. Degradation past
`escalation_alert` threshold → flag. Past `reclassification_threshold` → auto tier
upgrade for future contracts.

**`fixed` (V3):** `iterations_used` is NOT a convergence signal (quality is
judgment-dependent). Gate 4 records but does not use for reclassification. Quality
pass rate is the primary V3 signal.

### 7.3 Data Flow to Gate 4

Terminal state → `convergence_record` written → Gate 4 background process reads →
updates rolling window per `action_class` → recomputes stats (`avg_iterations`,
`p95_iterations`, `escalation_rate`, `quality_pass_rate`) → evaluates thresholds
(alert, auto-reclassification, manual demotion flagged for Danny).

Gate 4 consumes convergence data; this document defines what gets written. Tracking
structure and reclassification guards are in state-machine-design.md §9.

## 8. Sequence Diagram — One Complete Iteration Cycle

```
    Runner                         Executor                    Staging
      │                              │                           │
      │  1. Build prompt envelope    │                           │
      │     (Layers 1-6)            │                           │
      │  2. Dispatch                 │                           │
      │─────────────────────────────>│                           │
      │  [iteration_start →          │                           │
      │   iteration_working]         │                           │
      │                              │  3. Read vault context,   │
      │                              │     produce artifacts     │
      │                              │─────────────────────────────>
      │                              │     write to staging_path │
      │                              │  4. Return envelope       │
      │  5. Receive envelope         │                           │
      │<─────────────────────────────│                           │
      │  [iteration_checking]        │                           │
      │                              │                           │
      │  6. Lenient parse (Amend U)  │                           │
      │  7. Gate 2 (i1 only)         │                           │
      │  8. Run tests ───────────────────────────────────────────>
      │  9. Run artifact checks ─────────────────────────────────>
      │                              │                           │
      │  10a. ALL PASS → STAGED      │                           │
      │  10b. FAIL + BUDGET OK → build failure_context → loop    │
      │  10c. FAIL + BUDGET GONE → ESCALATED                     │
      │                              │                           │
```

## 9. Cross-References

| Topic | Source | Section |
|-------|--------|---------|
| Contract schema | contract-schema.md (TV2-019) | §1.1 |
| Failure context schema | contract-schema.md | §1.3 |
| Return envelope schema | contract-schema.md | §1.4 |
| Blocking vs advisory semantics | contract-schema.md | §2 |
| EXECUTING sub-states | state-machine-design.md (TV2-017) | §3 |
| Gate 4 convergence tracking | state-machine-design.md | §9 |
| Bad-spec detection | state-machine-design.md | §3 |
| Gate 2 confidence check | escalation-design.md (TV2-018) | §2-3 |
| Prompt layer stack + budgets | system-prompt-architecture.md (TV2-023) | §2-3 |
| Amendments T, U, W | spec-amendments-harness.md | respective sections |
| Retry failure classes | specification.md | §9.4 |

## 10. Design Decisions

| Decision | Rationale |
|----------|-----------|
| Budget in runner memory, not contract YAML | Contract immutability (state-machine-design.md §8) |
| Cumulative failure context with compaction | Full failure history helps executor; compaction ensures Layer 6 budget compliance |
| Staging preserved on escalation | Enables inspection; reduces rework if higher tier only fixes specific failures |
| Budget resets on tier change | Prior tier's exhaustion reflects its capability, not task difficulty |
| Lenient parsing before evaluation | Preserves retry budget for semantic failures; formatting errors common on local models |
| Executor self-assessment informational only | Runner's mechanical evaluation is authoritative; prevents gaming |
| Bad-spec short-circuit to DEAD_LETTER | Two identical failures = sufficient signal; prevents wasting remaining budget |
| Timeout as tool-class failure | Infrastructure problem, not content problem; defer/backoff applies |
