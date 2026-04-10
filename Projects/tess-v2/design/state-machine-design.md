---
project: tess-v2
type: design
domain: software
status: active
created: 2026-04-01
updated: 2026-04-01
task: TV2-017
skill_origin: action-architect
review: reviews/2026-04-01-state-machine-escalation.md
---

# Tess v2 — Contract Lifecycle State Machine

Defines all contract states, transitions, Ralph loop integration, four-gate escalation, staging/promotion mechanics, and immutability rules. Validated against six scenarios.

## 1. Design Inputs

- §8 Contract Schema (tests/artifacts block termination; quality_checks block promotion)
- §9 Ralph Loop Mechanics (one contract per session, fresh context, hard stop, retry budget)
- §7 Four-Gate Escalation: Gate 1 boundary check, Gate 2 confidence (in EXECUTING), Gate 3 risk policy (in ROUTING), Gate 4 convergence (background)
- AD-008 Staging → Promotion write model
- C9 Write-lock table for promotion collisions
- §2.4 Failure modes (silent stagnation, escalation storm, bad-spec loop, observability feedback loop, credential expiry cascade, promotion race, silent contract drift, queue poisoning)
- Amendment W: Convergence rate as Gate 4 signal
- Amendment X: Verifiability tiers (V1/V2/V3) affect termination checking

## 2. State Definitions

### Pre-Dispatch

| State | Description | Owner |
|-------|-------------|-------|
| **QUEUED** | Contract created, in dispatch queue. Waiting for scheduler slot. | Scheduler |
| **ROUTING** | Gate 1 + Gate 3 check determines executor tier and assignment. Mechanical only — no LLM calls. | Tess Orchestrator |
| **PENDING_APPROVAL** | Contract requires human approval before execution (`requires_human_approval` flag from Gate 3). Parked until Danny approves or rejects. | Danny |

### Execution

| State | Description | Owner |
|-------|-------------|-------|
| **DISPATCHED** | Contract sent to executor with dispatch envelope. Ralph loop starting. | Contract Runner |
| **EXECUTING** | Ralph loop active. See §3 for sub-states. Gate 2 (confidence) checked on first iteration. | Executor + Runner |

### Post-Execution

| State | Description | Owner |
|-------|-------------|-------|
| **STAGED** | Executor terminated. Artifacts in `_staging/{contract-id}/`. | Runner |
| **QUALITY_EVAL** | Tess evaluating quality_checks on staged artifacts. | Orchestrator |
| **PROMOTION_PENDING** | Quality passed, waiting for write-lock on target paths. Timeout: 60s. | Promotion Engine |
| **PROMOTING** | Write-lock acquired, crash-safe resumable promotion in progress. | Promotion Engine |
| **COMPLETED** | Artifacts promoted to canonical vault. Staging cleaned. Ledger updated. | Terminal |

### Error / Recovery

| State | Description | Owner |
|-------|-------------|-------|
| **ESCALATED** | Retry budget exhausted at current tier OR reasoning/confidence failure triggers tier upgrade. Re-enters ROUTING at higher tier with min_tier floor. | Orchestrator |
| **QUALITY_FAILED** | Quality checks did not pass. Routes to partial_promotion policy. | Orchestrator |
| **DEAD_LETTER** | All escalation paths exhausted, queue timeout, or unresolvable failure. Parked in `~/.tess/dead-letter/`. | Terminal (until human action) |
| **ABANDONED** | Contract cancelled by operator or superseded by new contract. Staging cleaned. | Terminal |

### Watchdog Timeouts

Every non-terminal state has a watchdog timeout to prevent silent stagnation (§2.4). Timeout values are initial estimates — will be calibrated during soak test and production operation:

| State | Timeout | Recovery |
|-------|---------|----------|
| QUEUED | `max_queue_age` (default 4h) | → DEAD_LETTER |
| ROUTING | 30s | → DEAD_LETTER (gate failure) |
| PENDING_APPROVAL | None (indefinite for destructive ops) | Re-alert every 4h |
| DISPATCHED | 30s (executor ack) | → ESCALATED |
| EXECUTING | 5 min heartbeat | → ESCALATED |
| STAGED | 30s | → QUALITY_EVAL auto-trigger |
| QUALITY_EVAL | V1/V2: 2 min, V3: 5 min | → DEAD_LETTER |
| PROMOTION_PENDING | 60s (lock wait) | → QUALITY_EVAL (retry) |
| PROMOTING | 60s | Release locks, retry once, then → QUALITY_FAILED |

## 3. Ralph Loop Sub-States (within EXECUTING)

The EXECUTING state is a hierarchical state containing the Ralph loop:

| Sub-State | Description |
|-----------|-------------|
| **iteration_start** | New iteration beginning. Executor receives: contract + vault context + failure context (if iteration > 1). |
| **iteration_working** | Executor processing. Tools available per dispatch envelope. All writes go to staging (AD-008). |
| **iteration_checking** | Runner evaluating termination conditions (tests + artifacts). Deterministic — no LLM judgment. On iteration 1, also checks Gate 2 confidence field if present. |
| **iteration_passed** | All termination conditions met. Exit to STAGED. |
| **retry_preparing** | Iteration failed. Building structured failure context (Amendment T format). Checking retry budget and failure class. |
| **budget_exhausted** | Retry budget consumed. Exit to ESCALATED. |

### Gate 2 in EXECUTING (First Iteration)

Gate 2 (confidence check) fires within `iteration_checking` on the first iteration only. The executor's structured response includes a `confidence` field. If `confidence: low`:
- Runner classifies as potential reasoning-class failure
- If higher tier available AND iterations_remaining > 0 → ESCALATED
- First iteration's staging artifacts are discarded on escalation

This eliminates the causal loop of needing executor confidence before routing to that executor. ROUTING runs only mechanical checks (Gate 1 + Gate 3). The executor self-assesses confidence as part of its first work output.

### Retry Budget Mechanics

- Budget is per-contract, not per-executor. Escalation does NOT reset the budget.
- Default budget: 3 iterations (§9.2). Configurable per contract.
- Budget tracking: `{iterations_used, iterations_remaining, total_budget}`
- Each iteration consumes 1 from the budget regardless of failure class.
- Escalation itself does NOT consume an iteration — it's a routing change, not a retry.
- **Invariant (cross-doc):** Gate outputs never modify retry budget. Rerouting preserves contract-level iteration counters.

### Failure Context Injection (Amendment T)

When `iteration_checking` fails, the runner produces structured diagnostics:

```yaml
failure_context:
  iteration: 1
  failed_checks:
    - check_id: "test_frontmatter_valid"
      expected: "status field present"
      actual: "status field missing"
      delta: "frontmatter missing required 'status' field"
  failure_class: deterministic
  retry_strategy: "fix input, same executor"
```

This is injected into the next iteration alongside the original contract and vault context.

### Bad-Spec Detection

If the same check fails with the same `failure_class` across 2+ consecutive iterations (identical `check_id` and `failure_class` — `delta` text may differ), the runner classifies the failure as `bad_spec`. See also spec §9.4 for the failure class taxonomy.
- Contract cannot be satisfied as written
- Transition: EXECUTING → DEAD_LETTER with `reason: bad_spec`
- Dead-letter entry includes: defective check ID, repeated failure pattern, recommendation to create superseding contract
- Tess creates a new contract with corrected checks if the fix is mechanical

This addresses the "bad-spec infinite loop" failure mode (§2.4).

## 4. State Diagram

```
                    ┌─────────┐
                    │ QUEUED  │──── max_queue_age ───→ DEAD_LETTER
                    └────┬────┘
                         │ scheduler picks up
                         ▼
                    ┌─────────┐
                    │ ROUTING │──── no viable executor ──→ DEAD_LETTER
                    │(Gate 1+3│
                    │ only)   │
                    └──┬────┬─┘
                       │    │
          executor     │    │ requires_human_approval
          assigned     │    │
                       ▼    ▼
               ┌───────────┐  ┌──────────────────┐
               │DISPATCHED │  │PENDING_APPROVAL   │
               └─────┬─────┘  │ (awaiting Danny)  │
                     │        └──┬─────────────┬──┘
                     │      approved│        rejected│
                     │             ▼                ▼
                     │        DISPATCHED         ABANDONED
                     │
                     │ ralph loop starts
                     ▼
          ┌─────────────────────┐
          │     EXECUTING       │
          │  ┌───────────────┐  │
          │  │ iteration_    │  │
          │  │   start       │  │
          │  └───────┬───────┘  │
          │          │          │
          │  ┌───────▼───────┐  │
          │  │ iteration_    │  │
          │  │   working     │  │
          │  └───────┬───────┘  │
          │          │          │
          │  ┌───────▼───────┐  │
          │  │ iteration_    │  │
          │  │   checking    │──┼─── pass ────────┐
          │  │(+Gate 2 on i1)│  │                 │
          │  └───────┬───────┘  │                 │
          │          │ fail     │                 │
          │  ┌───────▼───────┐  │                 │
          │  │ retry_        │  │                 │
          │  │   preparing   │  │                 │
          │  └──┬───┬────┬───┘  │                 │
          │     │   │    │      │                 │
          │  budget reasoning budget             │
          │   ok  failure  gone  │                 │
          │     │   │      │    │                 │
          └─────┼───┼──────┼────┘                 │
                │   │      │                      │
           loop │   │      ▼                      ▼
           back │   │ ┌──────────┐          ┌──────────┐
                │   │ │ budget   │          │  STAGED  │
                │   │ │ exhausted│          └────┬─────┘
                │   │ └────┬─────┘               │
                │   │      │                     ▼
                │   ▼      │              ┌────────────┐
                │ ┌────────┴──┐           │QUALITY_EVAL│
                │ │ ESCALATED │           └──┬───────┬─┘
                │ └─────┬─────┘              │       │
                │       │                pass│       │fail
                │       │ re-route           │       │
                │       │ (min_tier          ▼       ▼
                │       │  floor,     ┌──────────┐ ┌──────────────┐
                │       │  Gate 1+3   │PROMOTION │ │QUALITY_FAILED│
                │       │  re-fire)   │_PENDING  │ └──┬───┬───┬───┘
                │       ▼             └────┬─────┘    │   │   │
                │  ┌─────────┐     lock    │     discard hold promote
                │  │ ROUTING │     acquired│          │   │  passing
                │  └─────────┘             ▼          │   │   │
                │  (or DEAD_LETTER   ┌──────────┐     ▼   ▼   ▼
                │   if max tier)     │PROMOTING │  ABANDONED │
                │                    └────┬─────┘     DEAD_  │
                │                         │           LETTER  │
                │                    ┌────▼────┐         ┌───▼──────┐
                │                    │COMPLETED│         │PROMOTING │
                │                    └─────────┘         │(partial) │
                │                                        └──────────┘
```

## 5. Transition Table

| From | To | Trigger | Guard | Action |
|------|----|---------|-------|--------|
| QUEUED | ROUTING | Scheduler slot available | Queue not poisoned (max-age check) | Dequeue, start gate check |
| QUEUED | DEAD_LETTER | max_queue_age exceeded | — | Write dead-letter with `reason: queue_timeout`, alert if high-priority |
| ROUTING | DISPATCHED | Gates 1+3 pass, no human approval needed | Executor available for assigned tier | Build dispatch envelope, assign executor |
| ROUTING | PENDING_APPROVAL | Gate 3 sets `requires_human_approval` | — | Park contract, alert Danny via Telegram |
| ROUTING | DEAD_LETTER | No viable executor (max tier exhausted) | All tiers attempted | Write dead-letter entry with full history |
| PENDING_APPROVAL | DISPATCHED | Danny approves | Executor available | Build dispatch envelope, assign executor |
| PENDING_APPROVAL | ABANDONED | Danny rejects | — | Clean up, update ledger |
| DISPATCHED | EXECUTING | Executor acknowledges | — | Start iteration timer, log to contract ledger |
| DISPATCHED | ESCALATED | Ack timeout (30s) | — | Classify as tool failure, attempt re-route |
| EXECUTING | STAGED | iteration_checking passes | All tests + artifacts satisfied | Write execution_result envelope to staging |
| EXECUTING | ESCALATED | budget_exhausted | iterations_remaining == 0 | Preserve failure contexts, classify for re-routing |
| EXECUTING | ESCALATED | reasoning failure OR Gate 2 low confidence | Higher tier available AND iterations_remaining > 0 | Preserve failure contexts, set min_tier floor |
| EXECUTING | DEAD_LETTER | bad_spec detected | Same check_id + failure_class across 2+ iterations | Write dead-letter with supersede recommendation |
| EXECUTING | DEAD_LETTER | Heartbeat timeout (5 min) | No progress signal from executor | Write dead-letter with `reason: executor_unresponsive` |
| STAGED | QUALITY_EVAL | Runner signals completion | Staged artifacts exist and are readable | Tess loads contract + staged artifacts |
| QUALITY_EVAL | PROMOTION_PENDING | Quality checks pass | — | Request write-lock for target paths, record canonical hashes |
| QUALITY_EVAL | QUALITY_FAILED | Quality checks fail | — | Route to partial_promotion policy |
| QUALITY_EVAL | DEAD_LETTER | Evaluation timeout (V1/V2: 2 min, V3: 5 min) | — | Write dead-letter with `reason: eval_timeout` |
| PROMOTION_PENDING | PROMOTING | Write-lock acquired | Hash verification pending | Begin promotion via manifest |
| PROMOTION_PENDING | QUALITY_EVAL | Lock timeout (60s) | Lock not available after wait | Release, re-evaluate (canonical may have changed) |
| PROMOTING | COMPLETED | All artifacts promoted | Hash check passes (no stale-read collision) | Release write-lock, clean staging, update ledger |
| PROMOTING | QUALITY_EVAL | Hash mismatch detected | Canonical file changed since quality_eval | Release write-lock, re-evaluate against new canonical state |
| PROMOTING | QUALITY_FAILED | Promotion timeout (60s, after 1 retry) | — | Release locks, preserve staging |
| PROMOTING | DEAD_LETTER | Promotion contention | `promotion_attempts >= max_promotion_attempts (3)` | Write dead-letter with `reason: promotion_contention` |
| QUALITY_FAILED | DEAD_LETTER | Policy: hold_for_review | — | Preserve staging, write dead-letter entry |
| QUALITY_FAILED | ABANDONED | Policy: discard | — | Clean staging, update ledger |
| QUALITY_FAILED | PROMOTION_PENDING | Policy: promote_passing | Passing artifacts identified | Promote passing subset only |
| QUALITY_FAILED | ESCALATED | Quality failure retryable | `verifiability == V3 AND quality_retry_remaining > 0` | Re-route with quality failure context (structured, per Amendment T format) |
| DEAD_LETTER | ABANDONED | Superseding contract created | Superseding contract ID provided | Update reason: `superseded_by: {new-id}` |
| STAGED | DEAD_LETTER | Artifact readability check failed | — | Write dead-letter with `reason: staging_corruption` |
| ESCALATED | ROUTING | Higher tier available | — | Re-route with escalation context, min_tier floor, Gate 1+3 re-fire |
| ESCALATED | DEAD_LETTER | Max tier exhausted OR budget exhausted at max tier | — | Write dead-letter with full escalation chain |
| Any | ABANDONED | Operator cancellation | Not in PROMOTING state | Clean staging if exists, release locks, update ledger |
| PROMOTING | (deferred) | Operator cancellation during PROMOTING | — | Cancellation deferred until promotion completes or fails. Flag `cancel_requested` processed after recovery. |

## 6. Escalation Mechanics

### Within-Loop Escalation (Tier Upgrade)

When `retry_preparing` classifies a failure as `reasoning` (§9.4) OR the first-iteration confidence check (Gate 2) returns `low`, the runner checks whether a higher execution tier is available:

1. **Higher tier available AND iterations_remaining > 0:**
   Transition to ESCALATED. Re-enter ROUTING with:
   - Original contract (immutable)
   - Accumulated failure contexts from all prior iterations
   - `escalation_reason: "reasoning_failure_tier_upgrade"` or `"low_confidence_gate2"`
   - `source_tier` and `min_tier` (floor — cannot route below source tier)

   The retry budget carries forward. Escalation does not consume an iteration.

2. **Max tier reached OR iterations_remaining == 0:**
   Transition to DEAD_LETTER with full history.

### Escalation Re-Entry Gate Behavior

When ESCALATED → ROUTING, the gate behavior differs from initial routing:

- **Gate 1:** Respects `min_tier` floor from escalation source. Cannot route below the tier that failed.
- **Gate 3:** Re-fires. Risk policy always applies regardless of re-entry. A task that didn't trigger Gate 3 initially still won't, but the check is mandatory.
- **Gate 2:** Skipped on re-entry. The confidence failure already triggered the escalation.
- **Gate 4:** Not applicable (background process, not per-task).

### Gate 3 Forced Escalation + Human Approval

Gate 3 (risk policy) operates at ROUTING time, not during execution:
- Credential-touching tasks → Tier 3 minimum
- Destructive ops → Tier 3 + `requires_human_approval` → PENDING_APPROVAL
- External comms → Tier 3 + `requires_human_approval` → PENDING_APPROVAL
- System modifications (`_system/`, CLAUDE.md) → Tier 3 + `requires_human_approval` → PENDING_APPROVAL
- First-instance task class → Tier 3
- Prior low quality scores for this action class → Tier 3

**PENDING_APPROVAL ensures side-effecting tools never execute before human approval.** This is safety-critical: tools like `send_email`, `send_telegram`, `git_reset` execute during `iteration_working` and are irreversible. The approval gate must come before DISPATCHED, not after STAGED.

**Approval notification content.** When a contract enters PENDING_APPROVAL, Danny's Telegram alert includes: contract ID, task description, matched Gate 3 rules, remaining retry budget, escalation history (source tier, failure count, failure classes if re-entry), and iteration count. This gives Danny enough context to make an informed approve/reject decision without reading the full contract.

Gate 3 is deterministic — it reads the policy table, not model output.

### Escalation Storm Protection (§2.4)

If escalation rate exceeds threshold (>20% of contracts in 24h window):
1. Alert Danny via Telegram
2. Activate load shedding: new QUEUED contracts with `priority: low` are deferred
3. High-priority contracts continue normal routing
4. Recovery: when escalation rate drops below 15% for 2 consecutive hours, resume normal dispatch

This is policy-level, not state-machine-level — the scheduler applies it at QUEUED → ROUTING.

## 7. Promotion Mechanics

### Write-Lock Protocol

The promotion engine implements C9 (no promotion collisions):

1. **Lock acquisition:** Before promotion, acquire write-locks for ALL target canonical paths. Locks are path-level, not file-level (a directory promotion locks the directory).

2. **Path overlap rules:** Lock acquisition fails if any existing lock path is an ancestor or descendant of the requested path. Example: if `Projects/foo/design/` is locked, a request for `Projects/foo/design/spec.md` is denied (descendant). If `Projects/foo/design/spec.md` is locked, a request for `Projects/foo/design/` is denied (ancestor).

3. **Hash verification:** At QUALITY_EVAL time, record SHA-256 of each target canonical file (or directory listing hash for directories). At PROMOTING time (after lock acquisition), re-check. If any hash changed → release locks, return to QUALITY_EVAL.

4. **Lock timeout:** 60 seconds. If lock not acquired within timeout → return to QUALITY_EVAL (canonical may have changed during wait).

5. **Promotion attempt counter:** `max_promotion_attempts` (default: 3). After N failed attempts (hash mismatch or lock timeout cycles through QUALITY_EVAL → PROMOTION_PENDING → PROMOTING → QUALITY_EVAL), transition to DEAD_LETTER with `reason: promotion_contention`. Prevents livelock when another contract keeps modifying the same canonical path.

6. **Lock implementation:** `flock`-based file locks or SQLite for the lock table. Bare YAML is not concurrency-safe under multi-process updates. Lock table at `~/.tess/locks/write-locks.db` (SQLite) with schema:
   ```sql
   CREATE TABLE write_locks (
     path TEXT PRIMARY KEY,
     contract_id TEXT NOT NULL,
     acquired TIMESTAMP NOT NULL,
     expires TIMESTAMP NOT NULL
   );
   ```

### Crash-Safe Resumable Promotion

Promotion is crash-safe and idempotent via a manifest-based approach. Note: this is NOT atomic in the strict sense — readers can observe partial state between operations. The guarantee is crash-safety with idempotent resume.

1. **Write manifest:** `_staging/{contract-id}/.promotion-manifest.yaml`
   ```yaml
   contract_id: TV2-017-C
   status: pending  # pending | in_progress | completed | failed
   operations:
     - source: "_staging/TV2-017-C/spec-update.md"
       destination: "Projects/tess-v2/design/spec-update.md"
       hash_at_eval: "abc123..."
       promoted: false
   ```

2. **Execute operations:** Copy each file, mark `promoted: true` in manifest.

3. **Verify:** Re-hash promoted files against source.

4. **Cleanup:** Delete staging directory, remove manifest, release write-locks.

5. **Crash recovery:** On startup, scan for in-progress manifests. Resume or rollback based on state:
   - `status: pending` → promotion never started. Delete manifest, release locks, re-enter QUALITY_EVAL (staging artifacts still valid)
   - `status: in_progress` → check which operations completed, resume remainder
   - `status: completed` → cleanup wasn't finished, complete it

**Cancellation during PROMOTING:** Cancellation is deferred while PROMOTING is active. A `cancel_requested` flag is set and processed after promotion completes or recovery finishes.

### Partial Promotion (from QUALITY_FAILED)

When `partial_promotion: promote_passing`:
1. Identify artifacts that individually passed their quality checks
2. Create a filtered manifest with only passing artifacts
3. Promote the passing subset (crash-safe resumable within the subset)
4. Move failing artifacts to dead-letter with context
5. Log the partial promotion in the contract ledger

## 8. Contract Immutability Rules

1. **Immutable after DISPATCHED.** Once a contract enters DISPATCHED state, its content (tests, artifacts, quality_checks, termination, promotion criteria) cannot be modified.

2. **No executor-side modification.** Executors receive the contract as read-only context. The contract YAML is the durable instruction surface (§9.5 Pattern 2).

3. **Amendment = new contract.** If a contract is found defective during execution (bad-spec detection, §2.4), the executor escalates. Tess creates a new contract with a new ID. The old contract transitions to ABANDONED with `reason: superseded_by: {new-contract-id}`.

4. **Version tracking.** Each contract has a `schema_version` field. The contract runner validates incoming contracts against the expected schema version before dispatch.

5. **Staging path is contract-scoped.** `_staging/{contract-id}/` is owned exclusively by one contract. No two contracts share a staging path.

## 9. Routing Feedback Loop (Gate 4 — Background)

Gate 4 is a background monitoring process that updates the routing table based on longitudinal convergence data. It is NOT a per-task gate — it does not fire during ROUTING for individual contracts. It adjusts routing table tiers to affect FUTURE contracts.

Terminal states feed convergence data to the tracker:

```
COMPLETED ──→ update convergence tracker
DEAD_LETTER ──→ update convergence tracker
ABANDONED ──→ update convergence tracker
```

ESCALATED is non-terminal and does not update the tracker directly. The contract's eventual terminal state captures the full outcome.

### Convergence Tracking

```yaml
convergence_tracking:
  action_class: "vault-write"
  rolling_window: 20  # entries, not contracts
  minimum_sample: 10  # require ≥10 contracts before stats drive decisions
  history:
    - contract_id: "TV2-033-C1"
      iterations_used: 1
      executor_tier: 1
      outcome: completed
      escalated: false
    # ... last 20 entries
  stats:
    avg_iterations: 1.3
    p95_iterations: 2
    escalation_rate: 0.05
    quality_pass_rate: 0.95
    current_tier: 1
  thresholds:
    escalation_alert: 3      # flag if avg exceeds
    reclassification: 5      # promote tier if p95 exceeds
```

### Reclassification Guards

- **Minimum-sample gate:** No reclassification until ≥`minimum_sample` contracts in the window. Low-volume action classes accumulate data slowly — premature reclassification from 3-4 data points is noise.
- **Hysteresis:** Reclassification requires the threshold to be exceeded in TWO consecutive evaluation windows (each evaluated daily), not just one. Prevents oscillation from bursty failures.
- **Tier upgrades are automatic.** Alert Danny (informational, not blocking).
- **Tier demotions are manual.** Danny must approve demotions to prevent oscillation.

## 10. Verifiability-Aware Termination (Amendment X)

Different contract verifiability tiers use different checking mechanics:

| Tier | Termination Check | Quality Eval | Convergence Signal |
|------|-------------------|--------------|-------------------|
| **V1: Deterministic** | Runner executes tests + artifacts mechanically. No LLM. | Optional — Tess spot-checks. | Strong (converges in 1-2 iterations) |
| **V2: Heuristic** | Runner executes schema + heuristic checks. | Tess evaluates against rules/patterns. | Moderate (2-3 iterations typical) |
| **V3: Judgment** | Runner checks format only. | Tess performs full quality evaluation. | Weak (fixed iteration budget, not convergence) |

For V3 contracts, the retry budget is treated as a fixed allocation, not a convergence signal. The contract specifies `convergence_mode: fixed` to signal this.

**V3 Quality Retry Budget.** V3 contracts have an additional `quality_retry_budget` (default: 1) separate from the execution `retry_budget`. When QUALITY_EVAL fails for a V3 contract with `quality_retry_remaining > 0`, the contract transitions QUALITY_FAILED → ESCALATED (carrying structured quality failure context) rather than directly to DEAD_LETTER. This allows one re-attempt after quality feedback, addressing the gap where V3 contracts effectively get only one substantive evaluation. V1/V2 contracts have `quality_retry_budget: 0` (quality failures go directly to partial_promotion policy).

## 11. Queue Management (§2.4: Queue Poisoning)

### Max-Age Policy

Contracts in QUEUED have a `max_queue_age` (default: 4 hours). If exceeded:
1. Transition: QUEUED → DEAD_LETTER with `reason: queue_timeout`
2. Tess alerts Danny if the contract was high-priority

**Deferred contract interaction:** `max_queue_age` countdown pauses while a contract's status is `deferred` (e.g., from credential cascade circuit breaker). Deferred contracts are not considered "stale" until they become eligible for dispatch. The `defer_until` timestamp must pass before max_queue_age, priority boost, or starvation prevention apply.

### Priority Classes

| Priority | Description | Queue Behavior |
|----------|-------------|----------------|
| **critical** | Blocking other work or time-sensitive | Always dispatched next |
| **normal** | Standard contract | FIFO within priority |
| **low** | Maintenance, cleanup, non-urgent | Dispatched only when no normal+ contracts queued |
| **deferred** | Explicitly delayed | Not eligible for dispatch until `defer_until` timestamp |

### Scheduler Fairness

- No single action class can hold more than 3 concurrent executor slots
- If a contract has been ESCALATED twice for the same action class within 1 hour, pause that action class for 30 minutes (circuit breaker)
- Stale contracts (queued > 2 hours) get priority boost to prevent indefinite starvation

## 12. Observability Exclusion Rule

To prevent the observability feedback loop (§2.4), system-generated paths are excluded from contract vault-context inputs:

**Excluded paths (never included in dispatch `vault_context.read_paths`):**
- `_staging/*` — contract working directories
- `~/.tess/*` — operational logs, ledger, dead-letter
- `_system/logs/*` — vault-side service logs
- `_openclaw/state/*` — snapshot state files

Contracts targeting these paths (e.g., a contract to analyze system health) must have the paths explicitly listed in the contract's `read_paths`, not auto-discovered via vault search.

## 13. Credential Cascade Circuit Breaker

When a credential-refresh contract fails (dead-letter or retry budget exhausted):

1. **Mark dependent action classes as deferred.** All action classes that require the failed credential are paused in the scheduler.
2. **Single consolidated alert.** Danny receives ONE Telegram alert identifying the failed credential and the N dependent services affected. Not N individual service-failure alerts.
3. **Resume on credential restoration.** When Danny fixes the credential (or an automated refresh succeeds), deferred action classes are unpaused.
4. **Timeout: 24 hours.** If credential remains failed for >24h, escalate to `urgent_blocking` in daily attention.

This prevents the cascade where one expired OAuth token generates dozens of contract failures that flood dead-letter and escalation paths.

**Dependency map:** The credential-to-action-class dependency map is derived from service definitions' `dependencies` field (spec §11.3), materialized as a lookup table during TV2-021b service interface finalization.

## 14. Scenario Walkthroughs

### Scenario A: Mid-Loop Escalation (Primary Path)

**Setup:** Contract C1 (vault-write, V1 deterministic) dispatched to Nemotron (Tier 1). Retry budget: 3.

1. `QUEUED → ROUTING`: Gate 1 matches "vault-write" → Tier 1. Gate 3 clear.
2. `ROUTING → DISPATCHED`: Nemotron assigned. Dispatch envelope built.
3. `DISPATCHED → EXECUTING`:
   - **Iteration 1:** Nemotron writes file but uses wrong approach — generates a template instead of substantive content. `iteration_checking` passes structural tests but Gate 2 confidence field is `low` (Nemotron assessed the task as outside its normal vault-write pattern). **Gate 2 triggers escalation.**
   - EXECUTING → ESCALATED with `escalation_reason: low_confidence_gate2`, `min_tier: 3`. Budget: 2 remaining.
4. `ESCALATED → ROUTING`: Gate 1 re-fires with min_tier floor = 3. Gate 3 re-fires (still clear). Assigned to Kimi (Tier 3).
5. `ROUTING → DISPATCHED → EXECUTING`:
   - **Iteration 2 (Kimi):** Kimi receives original contract + iteration 1 failure context. Produces substantive analysis. `iteration_checking` passes all tests + artifacts.
6. `EXECUTING → STAGED → QUALITY_EVAL`: Tess evaluates quality. **PASSES.**
7. `QUALITY_EVAL → PROMOTION_PENDING → PROMOTING → COMPLETED`.

**Alternate path — deterministic failure, no escalation:**
If iteration 1 fails with `failure_class: deterministic` (wrong path format), retry at same tier. Budget: 2 remaining. Iteration 2 fixes format. Iteration 3 not needed if iteration 2 passes.

**Alternate path — Kimi also fails:**
If Kimi's iteration 2 also fails and budget is exhausted (0 remaining): EXECUTING → ESCALATED attempted, but `min_tier: 3` = max tier → ESCALATED → DEAD_LETTER with full escalation chain (Nemotron iteration 1 failure context + Kimi iteration 2 failure context).

### Scenario B: Contract Timeout During Promotion

**Setup:** Contract C2 has passed QUALITY_EVAL. Two artifacts to promote: `design/report.md` and `design/appendix.md`.

1. `QUALITY_EVAL → PROMOTION_PENDING`: Lock requested for both target paths.
2. `PROMOTION_PENDING → PROMOTING`: Locks acquired. Canonical hashes recorded.
3. **Promotion manifest written:** status=`in_progress`

4. **Crash during promotion:**
   - `report.md` copied to canonical path (manifest: `promoted: true`)
   - Process crashes before `appendix.md` copy

5. **Recovery on restart:**
   - Promotion engine scans `_staging/*/` for `.promotion-manifest.yaml` files
   - Finds C2 manifest with `status: in_progress`
   - Checks: `report.md` promoted=true (verify file exists at destination and hash matches source ✓)
   - Resumes: copy `appendix.md` to canonical path
   - Re-hash verification: both destination files match source
   - Manifest status → `completed`, cleanup staging, release locks

6. **Edge case — canonical file changed during crash window:**
   - If another process modified `report.md` between crash and recovery:
   - Recovery detects hash mismatch at destination
   - Canonical modification by a non-Tess process during an active promotion is a violation of AD-001 (vault authority)
   - Recovery action: promotion fails, locks released, contract enters DEAD_LETTER with `reason: external_canonical_modification` for manual resolution
   - The system does not attempt automatic recovery from AD-001 violations

### Scenario C: Concurrent Contracts Targeting Same Path

**Setup:** Contract C3 and C4 both target `Projects/foo/design/spec.md`.

1. **C3 arrives first:**
   - C3: `QUALITY_EVAL → PROMOTION_PENDING` (requests write-lock for `spec.md`)
   - C3: `PROMOTION_PENDING → PROMOTING` (lock acquired)
   - C3 records canonical hash of `spec.md` = `xxx`

2. **C4 arrives while C3 holds lock:**
   - C4: `QUALITY_EVAL → PROMOTION_PENDING` (requests write-lock)
   - Lock denied (held by C3) — C4 waits with 60s timeout

3. **C3 completes promotion:**
   - `spec.md` updated (new hash = `yyy`)
   - Write-lock released
   - C3 → COMPLETED

4. **C4 retries lock acquisition:**
   - Lock acquired
   - **Hash check:** C4 recorded canonical hash `xxx` at QUALITY_EVAL. Current hash is `yyy` (changed by C3).
   - **Hash mismatch detected** → C4 releases lock, returns to QUALITY_EVAL
   - C4's quality is re-evaluated against the post-C3 version of `spec.md`

5. **Re-evaluation outcomes:**
   - **C4 changes still valid** (additive, don't conflict): QUALITY_EVAL passes → PROMOTION_PENDING → PROMOTING → COMPLETED
   - **C4 changes conflict** (same section): QUALITY_EVAL fails → QUALITY_FAILED → partial_promotion policy
   - **C4 changes subsumed** (C3 already made same changes): QUALITY_EVAL determines no-op → ABANDONED with `reason: subsumed_by: C3`

### Scenario D: Human Approval Flow (Destructive Operation)

**Setup:** Contract C5 deletes orphaned staging directories. Gate 3 flags as destructive.

1. `QUEUED → ROUTING`: Gate 1 matches "shell-execute" → Tier 1. Gate 3 matches `destructive_operation` rule (`operations_include: ["delete"]`). Sets `requires_human_approval: true`.
2. `ROUTING → PENDING_APPROVAL`: Contract parked. Danny alerted via Telegram: "Contract C5 requests deletion of orphaned staging dirs. Approve/reject."
3. **Danny approves** (via Telegram reply or daily attention):
   - `PENDING_APPROVAL → DISPATCHED → EXECUTING → STAGED → QUALITY_EVAL → PROMOTION_PENDING → PROMOTING → COMPLETED`
4. **If Danny rejects:**
   - `PENDING_APPROVAL → ABANDONED`

**Key safety property:** No tools execute before Danny's approval. The deletion never happens if Danny doesn't approve.

### Scenario E: Credential Cascade

**Setup:** Google OAuth token expires. Email-triage, daily-attention, and morning-briefing all depend on it.

1. **Credential refresh contract C6 dispatched:** Tier 3 (Gate 3: credential_access). Fails after 3 iterations (refresh requires Danny's browser — can't be automated).
2. `EXECUTING → DEAD_LETTER` with `reason: credential_refresh_failed`.
3. **Circuit breaker activates:**
   - Action classes `email-triage`, `daily-attention`, `morning-briefing` marked as **deferred** in scheduler
   - Danny receives ONE alert: "Google OAuth expired. 3 services paused: email-triage, daily-attention, morning-briefing."
4. **Without circuit breaker (what we prevent):**
   - 3 contracts dispatched for dependent services → all fail → 3 dead-letter entries → 3 escalation alerts → Danny gets 4 alerts instead of 1
5. **Resolution:** Danny re-authenticates. Circuit breaker clears. Deferred action classes resume.

### Scenario F: Bad-Spec Infinite Loop

**Setup:** Contract C7 has a test checking `frontmatter.topics` against a list that was updated since the contract was created. The test can never pass.

1. `DISPATCHED → EXECUTING`:
   - **Iteration 1:** Executor writes file with topics from contract. `iteration_checking` fails: `test_topics_valid: expected value in [a,b,c], got 'd'`. Failure class: deterministic.
   - **Iteration 2:** Executor tries different topics. Same check fails with identical `check_id` and same `delta` pattern.
2. **Bad-spec detection triggers:** Same check, same failure, 2 consecutive iterations.
3. `EXECUTING → DEAD_LETTER` with `reason: bad_spec`, defective check ID, recommendation: "Update test_topics_valid expected values or create superseding contract."
4. Danny reviews dead-letter. Creates new contract C8 with corrected `test_topics_valid` expected values.
5. When C8 is created: C7 transitions DEAD_LETTER → ABANDONED with `reason: superseded_by: C8`.
6. C8 dispatches normally through ROUTING.

## 15. Design Decisions Summary

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Retry budget scope | Per-contract, not per-executor | Prevents unbounded retries across tier escalations |
| Escalation consumes iteration? | No | Escalation is routing, not a retry attempt |
| Gate 2 placement | In EXECUTING first-turn, not ROUTING | Eliminates causal loop; ROUTING stays mechanical |
| Gate 4 placement | Background process, not per-task | Longitudinal trend data, not per-contract routing |
| Human approval timing | Before DISPATCHED (PENDING_APPROVAL) | Side-effecting tools are irreversible; approval must precede execution |
| Lock granularity | Path-level with ancestor/descendant overlap rules | Prevents partial-directory promotion collisions |
| Lock implementation | flock or SQLite, not bare YAML | Concurrency-safe under multi-process updates |
| Lock timeout on contention | Return to QUALITY_EVAL | Canonical may have changed during wait; re-evaluation is safer than waiting indefinitely |
| Promotion guarantee | Crash-safe resumable (not atomic) | Honest about reader-visible partial state; idempotent recovery |
| Cancellation during PROMOTING | Deferred until recovery completes | Prevents partial canonical state from incomplete cancellation |
| Convergence tracking events | Terminal states only (COMPLETED, DEAD_LETTER, ABANDONED) | ESCALATED is non-terminal; counting it double-weights failed contracts |
| Convergence minimum sample | ≥10 contracts before reclassification | Prevents noisy stats from low-volume action classes |
| Convergence hysteresis | Two consecutive windows | Prevents oscillation from bursty failures |
| Bad-spec detection | 2+ identical failures → DEAD_LETTER | Mechanically prevents infinite loops without model judgment |

## 16. Interaction with Other Designs

| Component | Interface Point | Responsibility Boundary |
|-----------|----------------|------------------------|
| **TV2-018 (Escalation)** | Gate 1+3 logic feeds ROUTING state; Gate 2 fires in EXECUTING; Gate 4 is background | State machine defines when/where gates fire; escalation design defines gate logic |
| **TV2-019 (Contract Schema)** | Contract YAML drives termination/promotion checks | Schema defines fields; state machine defines when they're checked |
| **TV2-020 (Ralph Loop Spec)** | Sub-states within EXECUTING | State machine defines entry/exit; Ralph loop spec defines iteration mechanics |
| **TV2-022 (Staging/Promotion)** | PROMOTING state mechanics | State machine defines state transitions; staging design defines file operations |
| **TV2-025 (Observability)** | Ledger updates at COMPLETED, DEAD_LETTER, ABANDONED | State machine triggers logging; observability defines what's logged |
| **TV2-031b (Contract Runner)** | Implements DISPATCHED → EXECUTING → STAGED transitions | State machine is the specification; runner is the implementation |
| **TV2-042 (Local Model Failover)** | DEGRADED-LOCAL and CLOUD-FALLBACK modes affect Gate 2 calibration validity and Tier 1 availability for ROUTING | Failover modes change which executor tiers are physically available; state machine routes logically |

## 17. Open Questions for Downstream Tasks

1. **~~Retry budget for V3 contracts.~~** RESOLVED: V3 contracts use the standard `retry_budget: 3` for execution iterations plus `quality_retry_budget: 1` for post-evaluation re-dispatch. See §10.

2. **Escalation cost tracking.** When a contract escalates from Nemotron (free) to Kimi (paid), the cost tracker should record both the local cost (0) and the cloud cost. Token budget for escalation context (carrying N iterations of failure data) may be significant. Quantify during TV2-028.

3. **Dead-letter review cadence.** Daily attention digest includes dead-letter items. But what if dead-letter queue grows faster than Danny reviews? Max dead-letter size before circuit breaker? Decide during TV2-027.

4. **Lenient parsing layer placement.** Amendment U defines parsing recovery. Where in the state machine does it sit? Proposed: between `iteration_working` and `iteration_checking` — the runner applies lenient parsing to executor output before evaluating termination conditions. Confirm during TV2-019.
