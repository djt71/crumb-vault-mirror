---
type: design
domain: software
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-028
---

# Tess v2 — Bursty Cost Model

> **Scope:** Generally applicable beyond tess-v2. Cost modeling under steady-state and bursty conditions, 3-tier daily alerts, daily/monthly caps, and escalation-chain overhead calculation are reusable patterns for LLM cost management. See `_system/docs/tess-v2-durable-patterns.md`.

Cost model for Tess v2 orchestration under steady-state and bursty conditions. Supplements spec §17 with scenario analysis, daily alert thresholds, and budget cap enforcement.

## 1. Baseline Cost Model

### Per-Call Pricing

| Tier | Model | Input ($/M tok) | Output ($/M tok) | Avg Tokens/Call | Cost/Call |
|------|-------|-----------------|-------------------|-----------------|-----------|
| **Tier 1** | Nemotron (local) | $0 | $0 | ~3,500 | **$0.000** |
| **Tier 3 — Orchestration** | Kimi K2.5 (OpenRouter) | $0.60 | $2.40 | ~3,500 (2.5K in / 1K out) | **$0.004** |
| **Tier 3 — Orchestration Failover** | Qwen 3.5 397B (OpenRouter) | $0.80 | $3.20 | ~3,500 | **$0.005** |
| **Tier 3 — Executor** | Claude Sonnet (`claude --print`) | $3.00 | $15.00 | ~8,000 (5K in / 3K out) | **$0.060** |
| **Tier 3 — Complex Executor** | Claude Sonnet (multi-tool) | $3.00 | $15.00 | ~15,000 (8K in / 7K out) | **$0.130** |

**Note:** Tier 2 (local thinking) is architecturally defined but not currently deployed. Cost is $0 (same local hardware as Tier 1). Omitted from scenarios.

### Steady-State Daily Volume

Derived from service cadences (service-interfaces-draft.md) and spec §17 (~100 orchestration decisions/day, ~193 total LLM calls including sub-decisions).

| Category | Services | Calls/Day | Tier | Daily Cost |
|----------|----------|-----------|------|------------|
| Heartbeats (ping, awareness, backup) | 3 | ~144 | 1 | $0.00 |
| Vault gardening (health, GC) | 2 | ~2 | 1 | $0.00 |
| FIF pipeline (capture, attention, feedback) | 3 | ~3 | 1 (attention may escalate) | $0.00 |
| Daily attention | 1 | ~48 | 1 | $0.00 |
| Email triage | 1 | ~48 | 1 | $0.00 |
| Morning briefing | 1 | ~1 | 3 (Kimi) | $0.004 |
| Overnight research | 1 | ~1 | 3 (Sonnet dispatch) | $0.13 |
| Opportunity scout | 1 | ~1 | 1 | $0.00 |
| Connections brainstorm | 1 | ~1 | 3 (Kimi) | $0.004 |
| **Escalation overhead** (5-10% of ~100 decisions) | — | ~5-10 | 3 (Kimi orchestration) | $0.02-0.04 |
| **Executor dispatches** (from escalated tasks) | — | ~2-3 | 3 (Sonnet) | $0.20-0.39 |
| **Total** | | | | **$0.36-0.57/day** |

### Steady-State Monthly Projection

| Scenario | Daily | Monthly (30d) |
|----------|-------|---------------|
| Low (minimal escalation) | $0.36 | **$10.80** |
| Normal (5% escalation rate) | $0.47 | **$14.10** |
| High (10% escalation, more Sonnet dispatches) | $0.57 | **$17.10** |

All well within the spec C5 target (<$50/month).

## 2. Bursty Scenarios

### 2a. Retry Storm

A contract fails repeatedly, consuming tokens on each iteration before exhausting its retry budget.

**Worst case:** A reasoning failure on a Tier 3 Kimi orchestration call, retried 3 times, then escalated to Sonnet dispatch, which also retries 3 times.

| Phase | Iterations | Cost/Iteration | Subtotal |
|-------|-----------|----------------|----------|
| Tier 1 attempt (Nemotron) | 1 (Gate 2 low confidence) | $0.00 | $0.00 |
| Tier 3 orchestration (Kimi) | 3 (retry budget) | $0.004 | $0.012 |
| Tier 3 executor (Sonnet) | 3 (retry budget) | $0.13 | $0.39 |
| **Single contract retry storm** | | | **$0.40** |

**Scaled worst case:** If 10 contracts simultaneously hit retry storms (e.g., morning batch, broken dependency):

| Scenario | Contracts | Cost/Contract | Total |
|----------|-----------|---------------|-------|
| 10 contracts, all exhaust Tier 3 retries | 10 | $0.40 | **$4.00** |
| 10 contracts, Tier 1 only (retries free) | 10 | $0.00 | **$0.00** |
| 10 contracts, escalate to Kimi only | 10 | $0.012 | **$0.12** |

**Key insight:** Retry storms are costly only when they reach Sonnet executor dispatches. Kimi orchestration retries are negligible ($0.012/contract). Local retries are free.

### 2b. Escalation Cascade

A single contract traverses the full escalation chain: Tier 1 (fail) -> Tier 3 Kimi (fail) -> Tier 3 Sonnet executor.

| Step | Gate | Cost | Cumulative |
|------|------|------|------------|
| Tier 1 dispatch (Nemotron, 1 iteration) | Gate 2 low confidence | $0.00 | $0.00 |
| Re-route to Tier 3 orchestration (Kimi) | Gate 1 re-entry with min_tier | $0.004 | $0.004 |
| Kimi orchestration decides: needs Sonnet executor | — | $0.004 | $0.008 |
| Sonnet dispatch (multi-tool, 1 iteration) | — | $0.13 | **$0.138** |

**Escalation overhead vs. direct routing:** If the contract had been routed directly to Sonnet, cost would be $0.13. The escalation chain adds $0.008 overhead (Kimi calls). This is negligible — the escalation design does not materially increase cost.

**With retries at each tier:**

| Scenario | Cost |
|----------|------|
| Full cascade, no retries | $0.138 |
| Full cascade, 3 retries at Sonnet tier | $0.40 |
| Full cascade, 3 retries at every tier | $0.41 |

### 2c. First-Instance Task Overhead

First-instance tasks (Gate 3 `first_instance` rule) require human approval (PENDING_APPROVAL state). This creates:

1. **Queuing delay** — contract waits for Danny. No direct cost, but opportunity cost.
2. **Batch approval** — if Danny approves several first-instance tasks at once, they all dispatch simultaneously.
3. **Forced Tier 3** — first-instance tasks route to Kimi/Sonnet regardless of eventual steady-state tier.

| Phase | Cost |
|-------|------|
| First 5 contracts (calibration, Tier 3 Kimi) | 5 x $0.004 = $0.02 |
| First 5 contracts (calibration, Tier 3 Sonnet executor) | 5 x $0.13 = $0.65 |
| First 10 contracts at routing-table tier (extra logging) | Tier-dependent (likely $0) |
| **Total calibration cost per new action class** | **$0.02 - $0.67** |

At 8 defined action classes in the routing table, initial calibration cost for all classes: $0.16 - $5.36.

### 2d. Concurrent Morning Burst

Multiple services trigger simultaneously in the 06:00-07:30 window:

| Service | Time | Tier | Cost |
|---------|------|------|------|
| FIF capture | 06:05 | 1 | $0.00 |
| FIF attention | 07:05 | 1 | $0.00 |
| Morning briefing | 07:00 | 3 (Kimi) | $0.004 |
| Scout daily pipeline | 07:00 | 1 | $0.00 |
| Daily attention (if scheduled near window) | Variable | 1 | $0.00 |
| **Total morning burst** | | | **$0.004** |

The morning burst is almost entirely Tier 1 (free). Only morning briefing hits cloud. This is not a cost concern.

**Worst case morning burst:** All 5 services escalate to Sonnet: 5 x $0.13 = $0.65. Unlikely but bounded.

### 2e. Quality Retry (V3 Contracts)

V3 contracts (judgment-required) have `quality_retry_budget: 1` in addition to `retry_budget: 3`. A quality retry re-dispatches the contract after evaluation failure.

| Phase | Cost |
|-------|------|
| Initial execution (3 iterations max, Sonnet) | $0.13-0.39 |
| Quality evaluation (Kimi) | $0.004 |
| Quality retry re-dispatch (Sonnet, 3 iterations max) | $0.13-0.39 |
| Second quality evaluation (Kimi) | $0.004 |
| **Total worst case (V3, both budgets exhausted)** | **$0.79** |

A V3 contract that exhausts both retry and quality-retry budgets is the single most expensive contract type.

## 3. Daily Cost Alert Threshold

### Normal Daily Cost Estimate

| Percentile | Daily Cost | Description |
|------------|-----------|-------------|
| P50 (typical day) | $0.47 | Normal escalation rate, 2-3 Sonnet dispatches |
| P90 (busy day) | $1.20 | Higher escalation, 5-8 Sonnet dispatches |
| P99 (worst normal day) | $2.50 | Multiple retry storms, first-instance calibration |

### Alert Threshold: $3.00/day (3x P90)

| Level | Threshold | Action |
|-------|-----------|--------|
| **Warning** | $1.50/day (3x P50) | Log in cost tracker. Include in health digest. |
| **Alert** | $3.00/day (3x P90) | Telegram notification to Danny. |
| **Critical** | $5.00/day (hard cap) | Suspend cloud dispatches. See §4. |

### Mechanism

The cost tracker (`~/.tess/logs/cost-tracker.yaml`, spec §18.2) accumulates cost per tier per service. A daily cost check runs as part of the awareness service (every 1800s):

1. Read today's accumulated cost from cost tracker
2. Compare against thresholds
3. If Warning: append to next health digest
4. If Alert: send Telegram immediately with breakdown (top 3 cost sources)
5. If Critical: trigger budget cap enforcement (§4)

## 4. Budget Cap Enforcement

### Daily Hard Cap: $5.00

When daily cost reaches $5.00:

```
Daily cost >= $5.00
    │
    ├── Suspend all Tier 3 cloud dispatches
    │     ├── Kimi orchestration calls → deferred to next day
    │     └── Sonnet executor dispatches → deferred to next day
    │
    ├── Continue Tier 1 local operation (free)
    │     ├── Heartbeats continue
    │     ├── Vault gardening continues
    │     └── Known-class tasks still execute locally
    │
    ├── Alert Danny via Telegram
    │     ├── "Daily budget cap reached: $X.XX / $5.00"
    │     ├── Top cost sources
    │     └── "Cloud dispatches suspended until midnight UTC"
    │
    └── Queue cloud-requiring contracts as DEFERRED
          └── defer_until: midnight UTC (next day's budget)
```

### Monthly Cap: $75 (spec C5 ceiling)

| Metric | Value |
|--------|-------|
| Target | <$50/month |
| Ceiling | $75/month (migration period) |
| Enforcement | When rolling 30-day cost reaches $60 (80% of ceiling), reduce daily hard cap to $3.00 |
| Hard cutoff | At $75, all cloud dispatches suspended until next billing cycle |

### Grace Period vs. Hard Cutoff

**Decision: Hard cutoff, no grace period.**

Rationale: A grace period creates ambiguity about when enforcement actually happens. The $5.00 daily cap already provides a sufficient buffer — reaching it requires 10x normal daily cost. If daily cap is repeatedly hit, that signals a systemic issue (broken retry loop, misconfigured escalation) that should be diagnosed, not absorbed by budget slack.

**Override mechanism:** Danny can manually reset the daily cap via a Telegram command or vault state file (`~/.tess/state/budget-override.yaml`) if the spend is intentional (e.g., bulk first-instance calibration during migration).

## 5. Cost Attribution

### Per-Service Tracking

Each contract carries the originating `service_id`. The cost tracker aggregates:

```yaml
# ~/.tess/logs/cost-tracker.yaml (daily rollup)
2026-04-01:
  total: 0.47
  by_tier:
    tier1: 0.00
    tier3_orchestration: 0.04
    tier3_executor: 0.43
  by_service:
    morning-briefing: 0.004
    overnight-research: 0.13
    daily-attention: 0.00
    email-triage: 0.00
    fif-attention: 0.00
    escalation-overhead: 0.04
    ad-hoc-executor: 0.30
  escalation_overhead:
    total_escalated: 7
    escalation_cost: 0.04        # Kimi calls during escalation
    direct_routing_cost: 0.43    # what the same contracts would cost if routed directly to Tier 3
    overhead_delta: 0.04         # cost of escalation chain vs. direct routing
```

### Escalation Cost Overhead

The overhead of the escalation chain (Gate 1 -> Gate 2 fail -> Kimi re-route -> Sonnet dispatch) vs. direct Tier 3 routing is minimal:

| Metric | Value |
|--------|-------|
| Cost of escalation chain per contract | ~$0.008 (2 Kimi calls) |
| Cost of direct Tier 3 routing | $0.13 (1 Sonnet dispatch) |
| Overhead percentage | ~6% |
| Monthly overhead at 5 escalations/day | ~$1.20 |

The escalation design pays for itself if it prevents even one unnecessary Sonnet dispatch per day ($0.13 saved vs. $0.04 escalation overhead for ~5 daily escalations).

## 6. Summary

| Metric | Value |
|--------|-------|
| Steady-state daily cost | $0.36-0.57 |
| Steady-state monthly cost | $10.80-17.10 |
| Worst single contract (V3, full retry + quality retry) | $0.79 |
| Worst single day (10 retry storms + first-instance calibration) | ~$6.00 |
| Daily alert threshold | $3.00 |
| Daily hard cap | $5.00 |
| Monthly target | <$50 |
| Monthly ceiling | $75 |
| Escalation chain overhead vs. direct routing | ~6% |

### Open Items for Downstream Tasks

1. **TV2-025 (Observability):** Implement cost tracker at `~/.tess/logs/cost-tracker.yaml` with the per-service, per-tier schema above.
2. **TV2-027 (Dead Letter):** Dead-letter contracts that exhausted retry + quality-retry budgets represent peak cost ($0.79 each). Dead-letter review should include cost summary.
3. **TV2-031b (Contract Runner):** Runner must record token usage and cost per iteration for accurate tracking.
4. **Escalation context token budget (from state-machine-design §17.2):** Carrying N iterations of failure data into escalation increases Kimi/Sonnet input tokens. Measure during TV2-031b implementation — could shift per-call estimates upward by 20-50% for escalated contracts.
