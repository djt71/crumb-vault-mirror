---
type: design
domain: software
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-026
---

# Tess v2 — Escalation Storm / Load Shedding Policy

> **Scope:** Generally applicable beyond tess-v2. The 2-of-4 trigger detection, three-level shedding (advisory → queue triage → dispatch suspend), and gradual recovery pattern apply to any system with cascading-failure risk under degraded conditions. See `_system/docs/tess-v2-durable-patterns.md`.

Operational policy for detecting, responding to, and recovering from escalation storm conditions. An escalation storm is the cascade described in §2.4: degrading local model performance causes more Tier 3 escalations, which increases cloud cost and queue depth, which degrades throughput further.

## 1. Storm Detection

### 1.1 Definition

An **escalation storm** is a sustained, abnormal rate of Tier 3 escalations that exceeds the cost model's assumptions (§17: 5-10% of decisions at Tier 3). It indicates either local model degradation, a burst of genuinely novel tasks, or a systemic failure (e.g., credential cascade, bad routing table).

### 1.2 Metrics Tracked

| Metric | Source | Normal Range | Storm Signal |
|--------|--------|-------------|--------------|
| Escalation rate (hourly) | `escalation-log.yaml` | 5-10% of dispatches | >30% sustained |
| Tier 3 cost rate (hourly) | `cost-tracker.yaml` | <$0.50/hour | >$2.00/hour |
| Tier distribution shift | `contract-ledger.yaml` | 70-80% Tier 1 | <50% Tier 1 |
| Gate 2 low-confidence rate | `escalation-log.yaml` | <5% of Tier 1 contracts | >20% of Tier 1 contracts |
| Queue depth | Scheduler | <10 QUEUED contracts | >25 QUEUED contracts |

### 1.3 Detection Trigger

Storm state activates when **any two** of the following hold for a **rolling 2-hour window**:

| Trigger | Threshold | Minimum Sample |
|---------|-----------|----------------|
| T1: Escalation rate | >30% of contracts escalate to Tier 3 | ≥20 contracts in window |
| T2: Cost rate | Hourly cloud cost >$2.00 (4x normal ceiling) | ≥2 consecutive hours |
| T3: Gate 2 low-confidence spike | >20% of Tier 1 contracts report `confidence: low` | ≥10 Tier 1 contracts in window |
| T4: Queue backup | >25 contracts in QUEUED state | Instantaneous (no window) |

**Minimum sample guards** prevent false storms during low-volume periods (nights, weekends). If fewer than 20 contracts have been dispatched in the window, storm detection is suspended — the sample is too small for rate-based triggers.

### 1.4 Distinguishing Legitimate High-Escalation Periods

Not every escalation spike is a storm. Legitimate causes of elevated Tier 3 volume:

| Pattern | How to Distinguish | Response |
|---------|-------------------|----------|
| Burst of novel tasks (first-instance) | Gate 3 `first_instance` rule is the dominant escalation source | Normal. No storm. Gate 3 is working as designed. |
| Danny triggers strategic work batch | Most escalations are `strategic-decision` or `quality-evaluation` class | Normal. These are genuinely Tier 3 tasks. |
| Routing table recently updated | Gate 4 reclassification within last 24h | Monitor closely but don't trigger storm unless cost threshold also breached. |

**Discrimination rule:** If >70% of escalations in the window are from Gate 3 risk-policy matches (not Gate 1 unknown or Gate 2 low-confidence), the escalations are policy-driven, not model-degradation-driven. Suppress storm detection. Log as `high-escalation-legitimate`.

## 2. Load Shedding Strategy

Three-level progressive response. Each level includes everything from the previous level.

### 2.1 Shedding Levels

| Level | Name | Trigger | What Changes |
|-------|------|---------|-------------|
| **L1** | Advisory Shed | Storm detected (any two triggers) | Suspend quality-evaluation contracts for V1/V2 artifacts. Tier 1 execution continues. |
| **L2** | Queue Triage | Storm persists >30 min OR cost >$3/hour | Queue non-critical contracts. Only `priority: high` and `priority: critical` dispatch. |
| **L3** | Dispatch Suspend | Storm persists >2 hours OR cost >$5/hour OR queue >50 | Suspend ALL new dispatches. Only in-flight contracts continue to completion. |

### 2.2 L1: Advisory Shed (Reduce Cloud Load)

**What is shed:**
- Quality-evaluation contracts for V1 and V2 artifacts (these have mechanical termination checks — quality eval is advisory, not safety-critical)
- Gate 4 convergence background processing (deferred, not cancelled)
- Non-critical Telegram notifications (batch into next digest instead)

**What continues unchanged:**
- All Tier 1 local execution (zero marginal cost)
- All in-flight contracts at any tier
- Gate 3 risk-policy enforcement (safety-critical, never shed)
- Human approval flows (PENDING_APPROVAL contracts)
- Alerting for service failures and dead-letter events

**Operational principle:** Local execution is free. Never shed Tier 1 work. Shedding targets cloud-cost-generating activities only.

### 2.3 L2: Queue Triage (Reduce Dispatch Volume)

Contracts in QUEUED are triaged by priority class:

| Priority | Action |
|----------|--------|
| `critical` | Dispatch normally |
| `high` | Dispatch normally |
| `medium` | Hold in QUEUED. Extend `max_queue_age` to 8h (from default 4h). |
| `low` | Hold in QUEUED. Extend `max_queue_age` to 12h. |
| Unclassified | Treat as `low`. |

**Shed order when queue exceeds capacity:**
1. Lowest priority first
2. Within same priority: longest queue time first (oldest contracts shed first — they are most likely stale)
3. Contracts with `reclassifiable: true` action classes are shed before fixed-tier contracts

**"Shed" at L2 means "hold in queue," not "discard."** No contract is dropped. All queued contracts drain during recovery.

### 2.4 L3: Dispatch Suspend (Circuit Breaker)

- Scheduler stops dequeuing. QUEUED contracts accumulate.
- In-flight contracts (DISPATCHED, EXECUTING, STAGED, QUALITY_EVAL, PROMOTING) run to completion.
- Escalations from in-flight contracts still process (an already-executing contract finishing is cheaper than re-dispatching later).
- New contracts entering the system are accepted into QUEUED but not dispatched.
- `max_queue_age` extended to 24h for all priority classes during L3.

**"All services continue" alignment (TV2-042):** L3 suspends new *dispatches*, not services. Heartbeats, health checks, cron triggers, and Telegram monitoring all continue. The system is alive but not accepting new work.

## 3. Recovery Behavior

### 3.1 Storm Clearance

Storm state clears when **all active triggers** drop below their thresholds for a **sustained 30-minute window**. The clearance window prevents oscillation between storm and normal states.

| Shedding Level | Clearance Condition | Ramp Behavior |
|----------------|--------------------|----|
| L3 → L2 | All triggers below threshold for 30 min | Resume dispatching `critical` + `high` only for 15 min |
| L2 → L1 | Escalation rate <20% for 30 min | Resume dispatching `medium` for 15 min, then `low` |
| L1 → Normal | Escalation rate <15% for 30 min AND cost rate <$1/hour | Re-enable quality evaluations. Resume Gate 4. |

### 3.2 Queue Drain Order

After storm clearance, queued contracts are dispatched in this order:

1. `critical` priority (FIFO within class)
2. `high` priority (FIFO)
3. `medium` priority (FIFO)
4. `low` priority (FIFO)

**Drain rate limit:** Maximum 5 contracts dispatched per minute during recovery drain (prevents re-triggering storm from queued backlog). Normal dispatch rate resumes after the queue is drained below 10.

### 3.3 Post-Storm Report

After storm clears, Tess generates a storm report written to `~/.tess/logs/storm-reports/`:

```yaml
storm_report:
  storm_id: "STORM-2026-04-01-1430"
  started: "2026-04-01T14:30:00Z"
  cleared: "2026-04-01T16:45:00Z"
  duration_minutes: 135
  max_level_reached: L2
  triggers_activated: [T1, T2]
  
  metrics_snapshot:
    peak_escalation_rate: 0.45
    peak_hourly_cost: 3.20
    total_storm_cost: 7.15
    contracts_shed: 12
    contracts_queued_at_peak: 31
    
  root_cause_signals:
    dominant_escalation_gate: "Gate 2"  # Gate 1 | Gate 2 | Gate 3
    dominant_action_class: "structured-report"
    model_health_at_onset: "degraded"   # healthy | degraded | down
    
  impact:
    contracts_delayed: 18
    contracts_dead_lettered: 2
    avg_delay_minutes: 45
    quality_evals_skipped: 8
    
  recommendation: "structured-report class escalation rate elevated — consider Gate 4 reclassification review"
```

## 4. Alerting

### 4.1 Notification Triggers

| Event | Channel | Content |
|-------|---------|---------|
| Storm detected (L1 entry) | Telegram push | "Escalation storm detected. Rate: {rate}%, cost: ${cost}/hr. Entering L1 shed. Monitoring." |
| Level escalation (L1→L2 or L2→L3) | Telegram push | "Storm escalated to L{n}. {queue_depth} contracts queued. {action_taken}." |
| Storm persists >4 hours | Telegram push (urgent) | "Storm persisting {duration}h. Level: L{n}. Total cost: ${cost}. Review recommended." |
| Storm cleared | Telegram push | "Storm cleared after {duration}. Draining {n} queued contracts. Report: {storm_id}." |
| Post-storm report ready | Daily attention digest | Storm report summary with root cause signals and recommendation. |

### 4.2 Escalation to Danny

| Condition | Action |
|-----------|--------|
| Storm persists >4 hours at any level | Urgent Telegram alert. Classify as `urgent_blocking` per §7.5 taxonomy. |
| L3 active >1 hour | Urgent Telegram alert. System is not processing new work. |
| Storm cost exceeds $10 in a single event | Urgent Telegram alert regardless of duration. |
| Two storms in 24 hours | Urgent Telegram alert. Likely systemic issue, not transient. |

Danny-unavailable behavior: storms are **not** in the "truly blocked" category (no credentials/destructive ops involved). If Danny does not respond within 4 hours of an urgent storm alert, Tess continues managing the storm autonomously per this policy. The storm report queues for next attention cycle.

## 5. Interaction with Other Systems

### 5.1 Gate 2 and Gate 3 Under Storm Conditions

| Gate | Storm Behavior |
|------|---------------|
| **Gate 1** | Unchanged. Mechanical routing is free and instant. |
| **Gate 2** | At L2+: treat all Gate 2 `medium` confidence as `high` (reduce escalation volume). `low` still escalates. |
| **Gate 3** | Unchanged. Risk policy is safety-critical — never relaxed during storms. |
| **Gate 4** | Suspended at L1+. Convergence data still accumulates but reclassification paused to avoid routing table changes during instability. |

**Gate 2 relaxation rationale:** `medium` confidence normally continues execution but flags for tracking. During a storm, the tracking is less valuable than reducing Tier 3 volume. `low` confidence still escalates because it indicates genuine inability to complete the task.

### 5.2 Cost Cap Interaction (TV2-028)

Storm detection and cost caps are **independent triggers with coordinated response**:

| Scenario | Who Fires First | Interaction |
|----------|----------------|-------------|
| Storm drives cost up | Storm policy (rate-based) fires before cost cap (absolute) | Storm shedding reduces cost. Cost cap is a backstop if shedding is insufficient. |
| Cost cap hit without storm | Cost cap fires (absolute threshold) | Cost cap pauses Tier 3 dispatches. Not a storm — queue doesn't back up if local Tier 1 still works. |
| Both fire simultaneously | Both policies active | Strictest constraint wins at each decision point. Storm manages the queue; cost cap manages the spend. |

**Shared signal:** Storm cost tracker feeds into TV2-028 daily cost alerting. Storm events are annotated in cost reports.

### 5.3 Queue Poisoning Interaction (TV2-027)

A **poisoned contract** (pathological task that repeatedly fails and re-dispatches) can trigger a storm if:
- It escalates from Tier 1 → Tier 3 repeatedly
- Each escalation attempt consumes cloud budget
- Re-dispatches inflate the escalation rate

**Detection:** If a single `contract_id` (or contracts from the same source spec) accounts for >50% of escalations in a storm window, classify as **poison-driven storm**. Response:

1. Quarantine the poisoned contract(s) → DEAD_LETTER with `reason: storm_quarantine`
2. Re-evaluate storm triggers without the quarantined contracts
3. If triggers clear → storm was poison-driven. Clear storm state. Alert Danny about quarantined contracts.
4. If triggers persist → underlying issue beyond the poisoned contract. Continue storm management.

### 5.4 DEGRADED-LOCAL Interaction (TV2-042)

DEGRADED-LOCAL mode (Nemotron down, Qwen backup active) may trigger storms because:
- Qwen's confidence calibration differs from Nemotron (§9 of escalation design)
- All Gate 2 confidence treated as `medium` under DEGRADED-LOCAL
- If Qwen produces lower-quality outputs, mechanical test failures → more escalations

**Rule:** When DEGRADED-LOCAL is active, raise storm detection thresholds by 50%:
- T1 escalation rate threshold: 30% → 45%
- T3 Gate 2 low-confidence threshold: suspended (already treated as `medium`)

This prevents DEGRADED-LOCAL from immediately triggering storm shedding when the elevated escalation rate is expected and already factored into the failover design.

## 6. Configuration

All thresholds are configurable in `~/.tess/config/storm-policy.yaml`:

```yaml
storm_policy:
  detection:
    window_minutes: 120
    min_sample: 20
    triggers:
      escalation_rate: 0.30
      cost_rate_hourly: 2.00
      gate2_low_rate: 0.20
      queue_depth: 25
    required_triggers: 2
    legitimate_gate3_ratio: 0.70
    
  shedding:
    l2_persist_minutes: 30
    l2_cost_threshold: 3.00
    l3_persist_minutes: 120
    l3_cost_threshold: 5.00
    l3_queue_threshold: 50
    
  recovery:
    clearance_window_minutes: 30
    drain_rate_per_minute: 5
    drain_queue_resume_threshold: 10
    
  alerting:
    persist_alert_hours: 4
    cost_alert_absolute: 10.00
    repeat_storm_window_hours: 24
    
  degraded_local:
    threshold_multiplier: 1.50
```

## 7. Open Questions for TV2-028 / TV2-027

1. **Cost cap as L3 backstop:** Should TV2-028's cost cap automatically trigger L3 dispatch suspend? Current design keeps them independent. May want to unify.
2. **Poison contract retry limits:** TV2-027 should define how many re-dispatch cycles before a contract is auto-quarantined (independent of storm state).
3. **Gate 4 resume timing:** After storm clears, how long before Gate 4 resumes reclassification? Current design: resumes at L1→Normal transition. May need a longer cooldown.
