---
type: design
domain: software
status: draft
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-025
---

# Tess v2 — Observability Infrastructure Design

Defines logging paths, file inventory, rotation, the symlink convention connecting vault to external logs, health digest template, dead-letter queue mechanics, alert thresholds per surface, and schema definitions for the contract ledger and escalation log. Derived from spec §18, state-machine-design (TV2-017), contract-schema (TV2-019), escalation-storm-policy (TV2-026), queue-fairness-policy (TV2-027), bursty-cost-model (TV2-028), calibration-drift-plan (TV2-029), ralph-loop-spec (TV2-020), and service-interfaces (TV2-021b).

---

## 1. Logging Path Structure

### 1.1 Root Location

All raw telemetry lives at `~/.tess/logs/`, outside the vault per spec §18.1 to prevent the observability feedback loop (§2.4).

### 1.2 File Inventory

| File | Purpose | Write Volume | Rotation |
|------|---------|-------------|----------|
| `contract-ledger.yaml` | Full lifecycle of every contract: dispatch, completion, outcome, cost, convergence record | ~100-200 entries/day | Daily (midnight UTC) |
| `escalation-log.yaml` | Every escalation event with gate, tier transition, reason, confidence | ~5-20 entries/day | Daily (midnight UTC) |
| `cost-tracker.yaml` | Daily cost by tier, by service, running totals, budget cap state | 1 rollup entry/day (updated continuously) | Monthly archive, active file retained |
| `credential-audit.log` | Credential access events: type injected, service, timestamp, refresh events | ~50-100 entries/day | Daily (midnight UTC) |
| `scheduler.log` | Queue events (enqueue, dequeue, age-boost), lock events, dispatch events, fairness actions | ~200-500 entries/day | Daily (midnight UTC) |
| `promotion.log` | Staging-to-canonical promotions: paths promoted, hash verification, conflicts, rollbacks | ~10-30 entries/day | Size-based (10 MB) |
| `system.log` | Startup, shutdown, health check results, config changes, storm events, failover mode transitions | Variable | Size-based (10 MB) |
| `storm-reports/` | Post-storm analysis reports (directory, one YAML per storm event) | Rare | 90-day retention |

### 1.3 Supplementary Directories

| Path | Purpose |
|------|---------|
| `~/.tess/dead-letter/` | Dead-lettered contracts (see §4) |
| `~/.tess/dead-letter/archive/` | Archived dead-letter entries past retention |
| `~/.tess/state/` | Runtime state: budget overrides, quarantine flags, lock table |
| `~/.tess/config/` | Configuration files: storm-policy.yaml, alert-config.yaml |

### 1.4 Service Run Logs

Per spec §18.2, each service also gets an individual run log:

```
~/.tess/logs/services/{service-name}.log
```

One file per service (e.g., `services/morning-briefing.log`, `services/feed-capture.log`). Captures per-invocation start time, duration, outcome, and errors. Rotation: daily. These are the source for the per-service health metrics in the health digest (§3).

### 1.5 Rotation and Retention

| Strategy | Applies To | Behavior | Retention |
|----------|-----------|----------|-----------|
| **Daily** | contract-ledger, escalation-log, credential-audit, scheduler, service logs | Midnight UTC: rename to `{name}.{YYYY-MM-DD}.yaml`. New empty file. | 30 days |
| **Size-based** | promotion.log, system.log | At 10 MB: rename to `{name}.{N}.log`. Max 5 rotated. | 5 most recent |
| **Monthly** | cost-tracker | Month boundary: copy to `cost-tracker.{YYYY-MM}.yaml`. Active file retains 30-day window. | 12 months |
| **Event-based** | storm-reports/ | One file per storm | 90 days |

Configurable via `~/.tess/config/retention-policy.yaml`. At peak volume, daily files are ~50-200 KB each.

---

## 2. Symlink Convention

### 2.1 Symlink Structure

```
crumb-vault/
  _tess/
    logs/          →  ~/.tess/logs/          (symlink)
    dead-letter/   →  ~/.tess/dead-letter/   (symlink)
    health-digest.md   (real file, in vault, committed)
```

`_tess/` is a vault-level directory (alongside `_system/`, `_staging/`, `_openclaw/`) containing symlinks to external data and real files for semantic summaries (health digest).

### 2.2 Symlink Creation and Verification

**Creation:** Automated at Tess system startup. The startup sequence:

1. `mkdir -p ~/.tess/logs/services ~/.tess/dead-letter/archive ~/.tess/state ~/.tess/config`
2. `mkdir -p _tess/` (vault-side)
3. `ln -sfn ~/.tess/logs _tess/logs`
4. `ln -sfn ~/.tess/dead-letter _tess/dead-letter`

**Verification:** vault-check validates that `_tess/logs` and `_tess/dead-letter` are valid symlinks pointing to writable targets. Broken symlinks flagged as warnings (non-blocking).

### 2.3 Git Tracking

```gitignore
# Tess operational data — symlinked, not committed
_tess/logs
_tess/dead-letter
# Health digest IS committed
!_tess/health-digest.md
```

---

## 3. Health Digest Template

### 3.1 Location and Schedule

| Field | Value |
|-------|-------|
| **Path** | `_tess/health-digest.md` |
| **Storage** | In vault, committed to Git |
| **Generated** | Daily at 06:00 local (configurable) |
| **Generator** | Tess orchestrator (reads from `~/.tess/logs/` aggregations) |
| **Format** | Markdown with inline metrics, Telegram-compatible |

### 3.2 Template

```markdown
---
type: digest
status: current
created: {date}
updated: {date}
---

# Health Digest — {YYYY-MM-DD}

## Contract Summary (24h)

| Metric | Count |
|--------|-------|
| Dispatched | {n} |
| Completed | {n} |
| Failed (dead-lettered) | {n} |
| Escalated | {n} |
| Pending approval | {n} |
| Success rate | {pct}% |

## Cost Summary

| Category | Amount |
|----------|--------|
| Tier 1 (local) | $0.00 |
| Tier 3 — orchestration | ${n} |
| Tier 3 — executor | ${n} |
| **Daily total** | **${n}** |
| 7-day rolling average | ${n}/day |
| Monthly running total | ${n} / $75 ceiling |
| Budget status | {normal | warning | alert | cap-reached} |

Top cost sources: {service1} (${n}), {service2} (${n}), {service3} (${n})

## Escalation Summary

| Metric | Value |
|--------|-------|
| Escalation rate (24h) | {pct}% |
| Escalations via Gate 1 (boundary) | {n} |
| Escalations via Gate 2 (confidence) | {n} |
| Escalations via Gate 3 (risk/policy) | {n} |
| Storm events | {n} |

Top escalation reasons: {reason1} ({n}), {reason2} ({n})

## Service Health

| Service | Runs | Success | Fail | p50 (s) | p95 (s) |
|---------|------|---------|------|---------|---------|
{per-service rows from service run logs}

Services not run in >2x expected interval: {list or "none"}

## Credential Health

| Credential | Status | Expires |
|------------|--------|---------|
{per-credential rows}

## Confidence Drift

| Metric | Current (7d) | Baseline | Delta | Status |
|--------|-------------|----------|-------|--------|
| Escalation rate | {pct}% | {pct}% | {+/-pct}pp | {ok | watch | drift} |
| High-confidence failure rate | {pct}% | {pct}% | {+/-pct}pp | {ok | watch | drift} |
| Quality pass rate | {pct}% | {pct}% | {+/-pct}pp | {ok | watch | drift} |

## Dead-Letter Queue

| Metric | Value |
|--------|-------|
| Current count | {n} |
| Oldest entry | {age or "—"} |
| Entries added (24h) | {n} |
| Top reasons | {reason1} ({n}), {reason2} ({n}) |
| Quarantined task_ids | {list or "none"} |

## Value Density (placeholder — TV2-030)

| Metric | Value |
|--------|-------|
| Revenue-relevant contracts | {n} ({pct}%) |
| Maintenance contracts | {n} ({pct}%) |
| Ratio | {ratio} |
```

### 3.3 Digest Delivery

Two outputs from the same data: (1) full markdown committed to vault, (2) condensed Telegram summary with contract success rate, daily cost, escalation rate, dead-letter count (if >0), and any active alerts.

---

## 4. Dead-Letter Queue Mechanics

### 4.1 Storage

```
~/.tess/dead-letter/
  {dead-letter-id}.yaml          # One file per dead-lettered contract
  archive/
    {dead-letter-id}.yaml        # Expired entries moved here before deletion
```

### 4.2 Entry Schema

```yaml
dead_letter_id: "DL-2026-04-01-001"       # Format: DL-{date}-{sequence}
contract_id: "TV2-033-C1"
task_id: "TV2-033"
source_service: "vault-health"
priority_class: "standard"
reason: "retry_exhausted"                  # See §4.3 for all reason codes
reason_detail: "content_coverage check failed 3 consecutive iterations"
created: "2026-04-01T14:30:00Z"            # Contract creation time
dead_lettered: "2026-04-01T16:45:00Z"
time_in_system: "PT2H15M"

iteration_history:
  - iteration: 1
    tier: "tier1"
    outcome: "failed"
    failure_class: "deterministic"
    failed_checks: ["frontmatter_valid"]
    duration_seconds: 45
    token_usage: { input: 3200, output: 800 }
  - iteration: 2
    tier: "tier1"
    outcome: "failed"
    failure_class: "reasoning"
    failed_checks: ["content_coverage"]
    duration_seconds: 62
    token_usage: { input: 4100, output: 1200 }

escalation_chain:
  - from_tier: "tier1"
    to_tier: "tier3"
    gate: 2
    reason: "low confidence on iteration 1"

staging_path: "_staging/TV2-033-C1/"
staging_preserved: true
cost_total: 0.14
convergence_record:
  iterations_used: 3
  initial_tier: "tier1"
  final_tier: "tier3"
  escalated: true
  outcome: "dead_letter"
recommendation: "content_coverage check may need revised acceptance criteria"
superseded_by: null                        # Populated when new contract replaces this
reviewed: false
review_notes: null
```

### 4.3 Entry Conditions

Conditions that transition a contract to DEAD_LETTER, sourced from the state machine (TV2-017) and queue fairness policy (TV2-027):

| Condition | Reason Code | Source |
|-----------|-------------|--------|
| Max queue age exceeded | `queue_timeout` | State machine §11, TV2-027 §2 |
| Max retries exhausted at max tier | `retry_exhausted` | State machine §3, TV2-020 §2.3 |
| Bad-spec detected (same check fails 2+ iterations) | `bad_spec` | State machine §3.1 |
| Escalation exhaustion (3+ escalations without completing) | `escalation_exhaustion` | TV2-027 §3.2 |
| System timeout (time-in-system > 4x max_queue_age) | `system_timeout` | TV2-027 §3.3 |
| Quarantined (retry loop poisoning, 3 dead-letters in 24h) | `quarantined` | TV2-027 §3.1 |
| Executor unresponsive (heartbeat timeout) | `executor_unresponsive` | State machine §2 watchdog |
| Promotion contention (3+ failed promotion attempts) | `promotion_contention` | State machine §7 |
| Quality evaluation timeout | `eval_timeout` | State machine §2 watchdog |
| No viable executor (max tier exhausted on first route) | `no_viable_executor` | State machine §5 |
| Storm shedding (deferred contracts shed during storm) | `storm_shed` | TV2-026 §2 |
| Credential expired (dependent credential failed) | `credential_expired` | State machine §13 |
| Staging corruption (artifacts unreadable after STAGED) | `staging_corruption` | State machine §5 |
| Quality failure with hold_for_review policy | `quality_hold` | State machine §5, contract-schema §2.3 |

### 4.4 Retention Policy

Per TV2-027 §5.3:

| Category | Retention | Cleanup Action |
|----------|-----------|----------------|
| With preserved staging artifacts | 30 days | Archive staging to `archive/`, delete staging dir |
| Without staging (queue_timeout, storm_shed) | 14 days | Delete dead-letter entry |
| Quarantined (retry loop poisoning) | Until human review | No automatic cleanup |
| Superseded (new contract created) | 7 days after superseding contract reaches terminal state | Delete entry |

A daily cleanup job (part of Tess's vault-gc service) prunes expired entries. Entries are never deleted before their retention period.

### 4.5 Review Interface

CLI commands: `tess dead-letter list [--reason {code}]`, `show {id}`, `retry {id} [--priority {class}]`, `dismiss {id}`, `stats`. Re-dispatch resets retry budget and time-in-system but the failure ledger (TV2-027 §3.1) retains history for quarantine thresholds.

### 4.6 Notification

| Condition | Channel | Batching |
|-----------|---------|----------|
| Each dead-letter entry | Telegram | Batched if >3 entries in a 5-minute window |
| Critical-priority contract dead-lettered | Telegram (urgent) | Immediate, no batching |
| Quarantine activated for a task_id | Telegram | Immediate |
| Dead-letter count > 10 | Health digest (warning) | Next digest cycle |
| Dead-letter count > 25 | Telegram (urgent) | Immediate -- possible systemic failure |

---

## 5. Alert Thresholds

### 5.1 Per-Surface Alert Configuration

| Surface | Normal Range | Warning Threshold | Critical Threshold | Alert Channel |
|---------|-------------|-------------------|-------------------|---------------|
| **Contract success rate** | >90% (24h) | <85% | <70% | Telegram (warning), Danny escalation (critical) |
| **Escalation rate** | 5-10% of dispatches | >20% sustained 2h | >30% sustained 2h | Telegram (warning), Storm detection (critical) |
| **Cost rate (hourly)** | <$0.50/hour | >$1.50/hour | >$3.00/hour | Telegram (warning), Budget cap (critical) |
| **Cost rate (daily)** | <$0.60/day | >$1.50/day (3x P50) | >$3.00/day (3x P90) | Health digest (warning), Telegram + Danny (critical) |
| **Queue depth** | <10 QUEUED | >15 QUEUED | >25 QUEUED | Telegram (warning), Storm detection (critical) |
| **Dead-letter count** | 0-2 | >5 (24h) | >10 (24h) | Health digest (warning), Telegram + Danny (critical) |
| **Credential health** | All valid, >7d to expiry | Any credential <7d to expiry | Any credential expired | Telegram (warning), Telegram urgent (critical) |
| **Service latency** | Within 2x p50 baseline | Any service >3x p50 | Any service >5x p50 or timeout | Health digest (warning), Telegram (critical) |
| **Service consecutive failures** | 0 | 1 failure | 2+ consecutive failures | Health digest (warning), Telegram (critical) |
| **Memory/CPU** | <80% memory, <90% CPU | >85% memory or >95% CPU sustained 5m | >95% memory or system swap active | Telegram (warning), Telegram urgent + Danny (critical) |
| **Gate 2 low-confidence rate** | <5% of Tier 1 contracts | >10% sustained 1h | >20% sustained 2h | Health digest (warning), Storm detection (critical) |
| **High-confidence failure rate** | <10% | >20% (7d window) | >30% (7d window) | Health digest (warning), Telegram + re-calibration trigger (critical) |

### 5.2 Alert Fatigue Prevention

| Mechanism | Behavior |
|-----------|----------|
| **Batching** | Related alerts within a 5-minute window are combined into a single Telegram message |
| **Suppression** | After sending an alert for a condition, suppress repeated alerts for the same condition for a cooldown period (default: 1 hour for warnings, 4 hours for critical) |
| **Escalation cooldown** | Danny escalation alerts suppress for 4 hours after acknowledgment (or 8 hours without acknowledgment) |
| **Digest deferral** | Warning-level alerts that are not time-sensitive defer to the next health digest instead of immediate Telegram |
| **Storm-aware suppression** | During active storm (TV2-026), per-contract alerts are suppressed -- only storm-level aggregates are sent |

### 5.3 Configuration

All thresholds configurable at `~/.tess/config/alert-config.yaml`. Each surface entry has `warning`, `critical`, and `window` fields matching the table in §5.1. Fatigue prevention settings: `batch_window_seconds: 300`, `warning_cooldown: PT1H`, `critical_cooldown: PT4H`, `danny_cooldown_ack: PT4H`, `danny_cooldown_noack: PT8H`.

---

## 6. Contract Ledger Schema

### 6.1 Entry Structure

One entry per contract lifecycle, appended when the contract reaches a terminal state (COMPLETED, DEAD_LETTER, ABANDONED). Updated incrementally during execution for cost tracking.

```yaml
# Appended to ~/.tess/logs/contract-ledger.yaml at terminal state
- contract_id: "TV2-033-C1"
  service: "vault-health"
  action_class: "shell-execute"
  verifiability: "V1"
  priority: "standard"
  created: "2026-04-01T02:00:00Z"
  queued: "2026-04-01T02:00:01Z"
  dispatched: "2026-04-01T02:00:05Z"
  completed: "2026-04-01T02:01:30Z"
  outcome: "completed"                # completed | dead_letter | abandoned
  terminal_state: "COMPLETED"
  dead_letter_reason: null
  iterations_used: 1
  tier_chain: ["tier1"]               # Ordered list of tiers used
  escalated: false
  escalation_count: 0
  quality_eval_result: null           # passed | failed | skipped (V3 only)
  quality_retry_used: 0
  staging_promoted: true
  promotion_attempts: 1
  paths_promoted: ["vault-health-notes.md"]
  cost:
    total: 0.00
    by_tier: { tier1: 0.00, tier3_orchestration: 0.00, tier3_executor: 0.00 }
    token_usage: { total_input: 3200, total_output: 800 }
  convergence_record:                 # Written by runner at terminal state
    iterations_used: 1
    initial_tier: "tier1"
    final_tier: "tier1"
    escalated: false
    escalation_chain: []
    outcome: "completed"
  confidence_record:                  # From TV2-029 drift tracking
    gate2_confidence: "high"
    gate2_signals: ["known class", "exact routing match"]
    predicted_tier: "tier1"
    actual_tier_used: "tier1"
    quality_pass: true
    model: "nemotron"
    degraded_local: false
  credentials_used: ["google_oauth"]  # Type only, never values (spec §10b.3)
```

### 6.2 Query Patterns

The contract ledger supports these query patterns, consumed by downstream systems:

| Query | Consumer | Method |
|-------|----------|--------|
| "All V3 contracts from last 7 days" | TV2-029 (drift detection) | Filter: `verifiability == V3`, `completed >= now - 7d` |
| "Cost by service this month" | TV2-028 (cost tracking), health digest | Group by `service`, sum `cost.total` |
| "Escalation rate by action class" | TV2-026 (storm detection), TV2-029 (drift) | Group by `action_class`, ratio of `escalated == true` |
| "Dead-letter rate by reason" | Dead-letter review, health digest | Filter: `outcome == dead_letter`, group by `dead_letter_reason` |
| "Confidence accuracy by bucket" | TV2-029 (calibration drift) | Group by `confidence_record.gate2_confidence`, compare with `outcome` |
| "Tier distribution over time" | TV2-026 (storm detection) | Group by `tier_chain[-1]` (final tier), window by date |
| "Average iterations by action class" | TV2-029 (Gate 4 convergence) | Group by `action_class`, avg `iterations_used` |

---

## 7. Escalation Log Schema

### 7.1 Entry Structure

One entry per escalation event, appended when any escalation gate fires. A single contract may generate multiple entries (e.g., Gate 2 fires, then Gate 1 re-entry on the escalated dispatch).

```yaml
# Appended to ~/.tess/logs/escalation-log.yaml per escalation event
- timestamp: "2026-04-01T14:32:00Z"
  contract_id: "TV2-037-C1"
  gate: 2                            # 1 | 2 | 3 | 4
  gate_name: "confidence"            # boundary | confidence | risk | convergence
  from_tier: "tier1"
  to_tier: "tier3"
  reason: "low_confidence"           # Gate-specific (see §7.2 for all codes)
  reason_detail: "Executor reported confidence: low"
  confidence: "low"                  # Gate 2 only
  confidence_signals: ["novel task pattern", "ambiguous spec"]
  policy_match: null                 # Gate 3 only: matched risk rule
  convergence_data: null             # Gate 4 only: reclassification stats
  action_class: "structured-report"
  service: "morning-briefing"
  iteration: 1
  budget_remaining: 2
  storm_active: false
  storm_level: null                  # L1 | L2 | L3 if storm_active
```

### 7.2 Reason Codes by Gate

| Gate | Reason Codes |
|------|-------------|
| Gate 1 (boundary) | `unknown_action_class`, `re_entry_min_tier`, `no_viable_executor` |
| Gate 2 (confidence) | `low_confidence`, `missing_confidence` (Tier 1, iteration 1, no field returned) |
| Gate 3 (risk) | `side_effect_escalation`, `first_instance`, `destructive_operation`, `external_communication`, `credential_access` |
| Gate 4 (convergence) | `reclassification_tier_up`, `reclassification_tier_down`, `class_quarantine` |

### 7.3 Consumers

| Consumer | What It Reads | How |
|----------|--------------|-----|
| TV2-026 (storm detection) | Hourly escalation rate, Gate 2 low-confidence rate, per-trigger counts | Rolling window aggregation over `timestamp`, `gate`, `confidence` |
| TV2-029 (drift monitoring) | Gate 2 confidence vs outcome correlation | Join with contract-ledger on `contract_id` |
| Health digest (§3) | 24h escalation summary | Count by `gate`, top `reason` values |
| Gate 4 (convergence) | Historical escalation patterns per action class | Filter by `action_class`, rolling 30-day window |

---

## 8. Cross-References

### 8.1 State Machine Observability Events

Key transitions and their log targets (complete mapping from TV2-017):

| Transition | Log Target(s) |
|------------|--------------|
| QUEUED (created) | contract-ledger (initial entry) |
| QUEUED → ROUTING | scheduler.log |
| ROUTING → DISPATCHED | contract-ledger, scheduler.log |
| ROUTING → PENDING_APPROVAL | contract-ledger, system.log |
| EXECUTING (Gate 2 fires) | escalation-log |
| EXECUTING → STAGED | contract-ledger |
| EXECUTING → ESCALATED | escalation-log, contract-ledger |
| PROMOTING → COMPLETED | contract-ledger (terminal), promotion.log |
| Any → DEAD_LETTER | contract-ledger (terminal), dead-letter file |
| Any → ABANDONED | contract-ledger (terminal) |
| Credential injection | credential-audit.log |

### 8.2 Design Dependencies

| Design Document | What This Document Defines For It |
|----------------|----------------------------------|
| TV2-026 (Storm Policy) | escalation-log and cost-tracker schemas that storm detection reads |
| TV2-027 (Queue Fairness) | Dead-letter queue format, entry conditions, retention policy |
| TV2-028 (Cost Model) | cost-tracker.yaml schema and daily alert thresholds |
| TV2-029 (Calibration Drift) | confidence_record in contract ledger, drift metrics in health digest |
| TV2-030 (Value Density) | Value density placeholder in health digest template |
| TV2-031b (Contract Runner) | Logging contract that the runner must fulfill at each state transition |

### 8.3 Observability Exclusion Rule

Per state-machine-design §12, these paths are excluded from contract `read_paths` by default to prevent feedback loops: `~/.tess/*`, `_staging/*`, `_system/logs/*`, `_openclaw/state/*`. Contracts that need observability data (e.g., health digest generator) must list paths explicitly.
