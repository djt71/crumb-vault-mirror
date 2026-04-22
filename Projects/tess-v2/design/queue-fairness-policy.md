---
type: design
domain: software
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-027
---

# Queue Fairness Policy

> **Scope:** Generally applicable beyond tess-v2. Four priority classes, per-class max-age thresholds, pathological-contract detection, per-service slot caps with round-robin and age-boost are reusable patterns for any multi-service scheduler. See `_system/docs/tess-v2-durable-patterns.md`.

Defines priority classes, max-age thresholds, pathological contract detection, fairness rules, and dead-letter queue management for the Tess v2 scheduler. Prevents queue poisoning (§2.4) and ensures no single service or failure pattern monopolizes executor slots.

## 1. Priority Classes

Four priority classes govern queue ordering and executor slot allocation.

| Class | Value | Membership Criteria | Examples |
|-------|-------|---------------------|----------|
| **critical** | 0 | Health checks, alerts, credential rotation, failover triggers | Heartbeat contracts, expiry cascade response, service-down recovery |
| **standard** | 1 | Scheduled service contracts, cron-dispatched work, project tasks | Feed processing, daily attention, vault maintenance, spec-derived tasks |
| **background** | 2 | Research, learning plans, non-time-sensitive maintenance | Knowledge base enrichment, audit sweeps, convergence tracker updates |
| **deferred** | 3 | Manual/non-urgent, explicitly deprioritized by operator | Exploratory research, nice-to-have refactors, batch archival |

**Assignment rules:**
- Contracts inherit priority from the dispatching service's default class.
- Operator can override priority at dispatch time or while QUEUED.
- Escalation storm shedding (§6.1) temporarily suspends `deferred` and `background` intake.
- Priority is immutable after ROUTING begins (consistent with contract immutability, state-machine §8).

## 2. Max-Age Policy

Maximum time a contract may remain in QUEUED state before forced action. The scheduler checks ages on every dispatch cycle.

| Priority Class | Max Queue Age | Alert Threshold | Expiry Action |
|----------------|---------------|-----------------|---------------|
| critical | 15 min | 5 min | Dead-letter + Telegram alert |
| standard | 4 h | 2 h | Dead-letter + log warning |
| background | 24 h | 12 h | Dead-letter + log info |
| deferred | 72 h | 48 h | Dead-letter + log info |

**Semantics:**
- **Alert threshold** fires a warning without removing the contract. Gives the scheduler one more dispatch cycle to act.
- **Expiry action** transitions QUEUED → DEAD_LETTER with `reason: queue_timeout` and the contract's priority class. Critical contracts also trigger a Telegram notification to Danny.
- Contracts are never silently discarded. Every expiry writes a dead-letter entry with full context.
- The 4h default for `standard` aligns with the state-machine watchdog (`max_queue_age` default, state-machine §2).

## 3. Pathological Contract Detection

Three detection mechanisms identify contracts that would poison the queue if allowed to cycle indefinitely.

### 3.1 Retry Loop Poisoning

A contract that repeatedly fails, dead-letters, gets re-created, and fails again.

| Signal | Threshold | Response |
|--------|-----------|----------|
| Consecutive failures on same `task_id` | 3 dead-letter entries within 24 h | Quarantine: block new contracts for that `task_id` until human review |
| Same `check_id` failure across re-created contracts | 2 contracts dead-lettered with identical `check_id` + `failure_class` | Flag as probable bad-spec; require human review before re-dispatch |

The scheduler maintains a rolling failure ledger indexed by `task_id`. When a contract enters DEAD_LETTER, the ledger records `{task_id, contract_id, dead_letter_reason, timestamp}`. Quarantine checks fire before QUEUED → ROUTING.

### 3.2 Resource Overconsumption

Contracts that consume disproportionate executor time or token budget.

| Signal | Threshold | Response |
|--------|-----------|----------|
| Cumulative execution time (across all iterations) | > 3x median for same priority class | Flag contract; next escalation goes to DEAD_LETTER instead of re-route |
| Token consumption (estimated from executor reports) | > 2x the dispatch envelope `token_budget.limit` | Log overage; scheduler deprioritizes future contracts from same service |
| Repeated escalation (single contract) | Escalated 3+ times without completing | DEAD_LETTER with `reason: escalation_exhaustion` |

Thresholds are calibrated against rolling 7-day medians, not fixed values. Initial deployment uses the fixed values above until sufficient data accumulates.

### 3.3 Time-in-System Tracking

Total elapsed time from contract creation to terminal state, regardless of state transitions.

| Signal | Threshold | Response |
|--------|-----------|----------|
| Total time-in-system | > 2x max_queue_age for priority class | Alert; contract marked `stale` in ledger |
| Total time-in-system | > 4x max_queue_age | Force to DEAD_LETTER with `reason: system_timeout` |

This catches contracts that ping-pong between ESCALATED → ROUTING → EXECUTING without ever completing or hitting the retry budget naturally.

## 4. Fairness Rules

### 4.1 Slot Allocation Caps

No single service may hold more than **40%** of active executor slots. "Service" is the `source_service` field on the contract (e.g., `feed-pipeline`, `daily-attention`, `vault-maintenance`).

| Condition | Action |
|-----------|--------|
| Service holds ≥ 40% of active slots | New contracts from that service wait in QUEUED until slot share drops below 40% |
| Service holds ≥ 60% of active slots (emergency) | Scheduler kills the oldest executing contract from that service (→ ESCALATED with `reason: fairness_preemption`) |

The 60% emergency threshold exists only for the case where a service floods the queue faster than contracts complete. Normal operation should never hit it.

### 4.2 Within-Class Ordering

Contracts in the same priority class are dispatched **round-robin by service**, not FIFO. This prevents a service that queues 20 contracts from starving other services at the same priority level.

Dispatch order within a priority class:
1. Round-robin across distinct `source_service` values.
2. Within the same service, FIFO by `created` timestamp.
3. Ties broken by contract ID (lexicographic).

### 4.3 Starvation Prevention

Lower-priority contracts receive guaranteed minimum throughput to prevent indefinite starvation by higher-priority work.

| Priority Class | Minimum Slot Reservation |
|----------------|--------------------------|
| critical | No cap — always dispatched if slots available |
| standard | At least 1 slot reserved (if contracts waiting) |
| background | At least 1 slot every 30 min (if contracts waiting) |
| deferred | At least 1 slot every 2 h (if contracts waiting) |

The reservation is checked at each dispatch cycle. If a lower-priority class has been waiting longer than its guaranteed interval, the scheduler dispatches one contract from that class before returning to higher-priority work.

### 4.4 Age-Based Priority Boost

Contracts waiting in QUEUED gain a priority boost over time, preventing permanent starvation of lower-priority work during sustained high-priority load.

| Wait Time (as fraction of max_queue_age) | Boost |
|------------------------------------------|-------|
| 0–25% | None |
| 25–50% | −0.5 priority (moves toward next higher class) |
| 50–75% | −1.0 priority (effectively promoted one class) |
| 75–100% | −1.5 priority (cap — never exceeds `critical`) |

Boost is computed at dispatch time, not stored on the contract. The effective priority for ordering is `base_priority + boost`. Boost never promotes a contract above `critical` (effective floor: 0).

## 5. Dead-Letter Queue

### 5.1 Entry Conditions

A contract enters the dead-letter queue (`~/.tess/dead-letter/`) on any of:

| Condition | Dead-Letter Reason |
|-----------|--------------------|
| Max queue age exceeded | `queue_timeout` |
| Max retries exhausted at max tier | `retry_exhausted` |
| Bad-spec detected (same check fails 2+ iterations) | `bad_spec` |
| Escalation exhaustion (max tier reached, budget spent) | `escalation_exhaustion` |
| System timeout (time-in-system exceeds 4x max_queue_age) | `system_timeout` |
| Fairness quarantine (retry loop poisoning) | `quarantined` |
| Executor unresponsive (heartbeat timeout) | `executor_unresponsive` |
| Promotion contention (3+ failed attempts) | `promotion_contention` |
| Escalation storm shedding (shed contracts) | `storm_shed` |

### 5.2 Dead-Letter Entry Format

```yaml
dead_letter_id: DL-2026-04-01-001
contract_id: TV2-015-C
task_id: TV2-015
source_service: feed-pipeline
priority_class: standard
reason: retry_exhausted
created: 2026-04-01T14:30:00Z
dead_lettered: 2026-04-01T16:45:00Z
time_in_system: 2h15m
iteration_history:
  - iteration: 1
    tier: local
    failure_class: deterministic
    failed_checks: [frontmatter_valid]
  - iteration: 2
    tier: local
    failure_class: reasoning
    failed_checks: [content_coverage]
  - iteration: 3
    tier: frontier
    failure_class: reasoning
    failed_checks: [content_coverage]
escalation_chain: [local → local → frontier]
staging_path: "_staging/TV2-015-C/"
staging_preserved: true
recommendation: "content_coverage check may need revised criteria"
```

### 5.3 Retention Policy

| Category | Retention | Cleanup Action |
|----------|-----------|----------------|
| With preserved staging artifacts | 30 days | Archive staging to `~/.tess/dead-letter/archive/`, delete staging dir |
| Without staging (queue_timeout, storm_shed) | 14 days | Delete dead-letter entry |
| Quarantined (retry loop poisoning) | Until human review | No automatic cleanup; quarantine flag blocks re-dispatch |
| Superseded (new contract created) | 7 days | Delete entry after superseding contract reaches terminal state |

A daily cleanup job prunes expired dead-letter entries. Entries are never deleted before their retention period.

### 5.4 Review and Re-Dispatch

Dead-lettered contracts can be re-dispatched after human review:

1. **Inspect:** `tess dead-letter list` shows all entries with reason, age, and recommendation.
2. **Review:** `tess dead-letter show <id>` displays full entry including iteration history and staging artifacts.
3. **Re-dispatch:** `tess dead-letter retry <id> [--priority <class>] [--override-checks]` creates a new contract from the dead-lettered one. The original entry is marked `superseded_by: <new-contract-id>`.
4. **Dismiss:** `tess dead-letter dismiss <id>` removes the entry and cleans staging. Requires confirmation for entries with preserved artifacts.

Re-dispatch resets the retry budget and time-in-system counters. The failure ledger (§3.1) retains the history — if the re-dispatched contract fails again, quarantine thresholds still apply.

## 6. Interaction with Other Policies

### 6.1 Escalation Storm (TV2-026)

When escalation storm protection activates (>20% escalation rate in 24h, per state-machine §6):

- `deferred` contracts in QUEUED → DEAD_LETTER with `reason: storm_shed`.
- `background` contracts in QUEUED are frozen (no dispatch, age clock paused).
- `standard` and `critical` contracts continue normal dispatch.
- Recovery (rate < 15% for 2 consecutive hours) unfreezes `background` and resumes `deferred` intake.

Storm shedding is the scheduler's contribution to escalation storm response. The storm policy itself (detection, alerting, root cause) is defined in TV2-026.

### 6.2 Cost Model (TV2-028)

When the cost tracker signals a budget threshold breach:

- **Soft cap (80% of monthly budget):** `background` and `deferred` contracts are frozen. Token-budget estimates on new contracts are validated more strictly (reject contracts with estimated cost > 2x median).
- **Hard cap (100% of monthly budget):** All non-critical contracts are frozen. Only `critical` contracts dispatch. Danny alerted via Telegram.
- **Recovery:** Unfreezes when a new billing period starts or Danny manually raises the cap.

Cost interaction details are defined in TV2-028. This policy provides the queue-side enforcement hooks.

### 6.3 State Machine Integration

This policy operates at the **scheduler layer** between QUEUED and ROUTING. It does not modify state machine transitions — it governs which contracts the scheduler picks up and in what order.

| Policy Mechanism | State Machine Touchpoint |
|------------------|--------------------------|
| Priority ordering + round-robin | QUEUED → ROUTING selection order |
| Max-age expiry | QUEUED → DEAD_LETTER (existing transition, `reason: queue_timeout`) |
| Slot allocation caps | Guards on QUEUED → ROUTING (service at cap → stay QUEUED) |
| Fairness preemption | EXECUTING → ESCALATED (emergency only, `reason: fairness_preemption`) |
| Quarantine | Blocks QUEUED → ROUTING for quarantined `task_id` |
| Age-based boost | Affects ordering, no new transitions |
| Storm/cost freezes | Pauses QUEUED → ROUTING for affected priority classes |

No new states are introduced. All policy actions map to existing state transitions or queue ordering decisions.
