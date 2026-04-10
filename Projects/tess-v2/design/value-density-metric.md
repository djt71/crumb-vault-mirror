---
type: design
domain: software
status: draft
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-030
---

# Tess v2 — Value Density Metric Design

Defines the value density metric, service classification, silent stagnation detection, and health digest integration. Operationalizes the liberation directive's principle that revenue-generating work gets priority claim by providing the feedback loop that surfaces whether the system is actually doing revenue work.

**Sources:** specification.md (§2.4, §18), observability-design.md (TV2-025), service-interfaces.md (TV2-021b), bursty-cost-model.md (TV2-028), liberation-directive.md.

---

## 1. Metric Definition

### 1.1 Formula

```
Value Density = revenue-relevant completions / total completions (rolling window)
```

A **completion** is a contract reaching terminal state COMPLETED in the contract ledger. Dead-lettered and abandoned contracts are excluded from both numerator and denominator — they represent system failures, not work allocation decisions.

Mixed-classification services contribute fractional completions. A daily-attention contract counts as 0.4 revenue-relevant and 0.6 maintenance (see §2 for all weights).

### 1.2 Time Windows

| Window | Purpose |
|--------|---------|
| **7-day rolling** | Primary metric. Smooths daily variation from service cadences. |
| **30-day rolling** | Trend baseline. Used for stagnation comparison. |
| **24-hour** | Included in daily digest for immediate visibility. |

Daily snapshots are stored at digest generation time (06:00 local). The 7-day and 30-day windows are computed from the snapshot history, not re-scanned from the full ledger.

### 1.3 Calculation

Runs at health digest generation time (06:00 local). Reads completed contracts from `~/.tess/logs/contract-ledger.yaml` within the relevant time window. Groups by `service` field, applies the classification weight from §2, sums numerator and denominator.

---

## 2. Service Classification Table

Static classification set at service definition time. Mixed services carry a revenue weight — the fraction of their work considered revenue-relevant.

| # | Service | Classification | Revenue Weight | Rationale |
|---|---------|---------------|----------------|-----------|
| 1a | health-ping | Maintenance | 0.0 | Pure infrastructure liveness |
| 1b | awareness-check | Maintenance | 0.0 | System anomaly detection |
| 1c | backup-status | Maintenance | 0.0 | Data protection verification |
| 2a | vault-health | Maintenance | 0.0 | Vault integrity checks |
| 2b | vault-gc | Maintenance | 0.0 | Dead-letter cleanup, log rotation |
| 3a | fif-capture | Mixed | 0.6 | Captures feeds that include revenue-relevant signals (market intel, opportunity data) alongside general news |
| 3b | fif-attention | Mixed | 0.6 | Surfaces actionable items from captured feeds, many revenue-adjacent |
| 3c | fif-feedback | Maintenance | 0.0 | Pipeline health feedback loop |
| 4a | daily-attention | Mixed | 0.4 | Surfaces revenue opportunities but primarily coordinates maintenance tasks and daily planning |
| 4b | overnight-research | Revenue | 1.0 | Produces research artifacts that advance revenue prompts |
| 5a | email-triage | Mixed | 0.3 | Most email is routine; some surfaces business opportunities or client communications |
| 6a | morning-briefing | Mixed | 0.4 | Includes revenue prompt status but mostly operational summary |
| 7a | scout-daily-pipeline | Revenue | 1.0 | Directly executes opportunity scanning per liberation directive Prompt 6 |
| 7b | scout-feedback-poller | Revenue | 1.0 | Tracks operator response to surfaced opportunities |
| 7c | scout-weekly-heartbeat | Revenue | 1.0 | Weekly opportunity synthesis and recommendation |
| 8a | connections-brainstorm | Revenue | 1.0 | Generates revenue-relevant networking and partnership ideas |

### 2.1 Classification Rules

- **Revenue (1.0):** Service exists specifically to advance one or more liberation directive prompts. Its primary output is a revenue-relevant artifact or action.
- **Mixed (0.3-0.6):** Service produces both maintenance and revenue-relevant outputs. Weight reflects the approximate fraction of completions that advance revenue work.
- **Maintenance (0.0):** Service exists to keep the system operational. No direct revenue contribution.

Classification is reviewed quarterly during the liberation directive review cadence. If a service's actual output shifts (e.g., daily-attention starts surfacing more revenue actions), update the weight.

---

## 3. Silent Stagnation Detection

### 3.1 Definition

Silent stagnation (spec §2.4): the system is operating normally — contracts completing, no errors, all health metrics green — but value density has dropped below threshold. The system is busy doing maintenance work and no revenue-relevant work is advancing.

### 3.2 Detection Thresholds

| Condition | Threshold | Window |
|-----------|-----------|--------|
| **Stagnation warning** | 7-day value density < 10% | Checked daily at digest generation |
| **Stagnation alert** | 7-day value density < 8% for 3 consecutive days | Checked daily |

Thresholds are calibrated against the steady-state estimate of ~13% (see §7.1). The high-cadence maintenance baseline (heartbeats at 192/day) means raw density is inherently low. These thresholds detect when revenue services stop running, not normal operation.

### 3.3 Distinguishing Stagnation from Legitimate Low-Value Periods

Not every low-density period is stagnation. Known legitimate causes:

| Scenario | Expected Duration | Distinguisher |
|----------|-------------------|---------------|
| Post-migration stabilization | 1-2 weeks | Accompanies high maintenance contract volume and known migration tasks |
| Infrastructure upgrade (new service deployment) | 2-5 days | Correlates with elevated vault-health and vault-gc activity |
| Weekends / low-activity periods | 1-2 days | Cadence-driven — revenue services have lower weekend frequency |
| Scout pipeline paused (liberation directive Level 2/3 degradation) | Indefinite | Operator-initiated — Danny explicitly pauses discovery prompts |

The stagnation alert includes the 30-day average for comparison. If the 7-day density is low but consistent with the 30-day trend, the alert notes "consistent with recent baseline." If the 7-day density drops significantly below the 30-day average (>15 percentage points), the alert flags it as a potential stagnation event.

Operator acknowledgment suppresses the alert for 7 days (cooldown via `~/.tess/state/stagnation-ack.yaml`).

### 3.4 Detection Mechanism

Runs as part of health digest generation (daily, 06:00 local):

1. Compute 7-day value density from snapshot history
2. Compare against 10% warning threshold
3. If below threshold, check whether this is the 3rd consecutive day below 8%
4. If stagnation alert fires: send Telegram notification with 7-day density, 30-day density, and top 5 services by contract volume (to show where work is going)

### 3.5 Alert Format (Telegram)

```
⚠️ Silent Stagnation Detected

Value Density: 5% (7-day) | 13% (30-day)
Revenue contracts: 3 / 298 total (3 consecutive days below 8%)

Top services by volume:
  health-ping: 672 (maintenance)
  awareness-check: 336 (maintenance)
  daily-attention: 48 (mixed, 0.4)
  vault-health: 14 (maintenance)
  email-triage: 12 (mixed, 0.3)

Revenue services silent: overnight-research (0 runs), scout-daily-pipeline (0 runs)
```

---

## 4. Health Digest Integration

### 4.1 Digest Section Format

Replaces the placeholder in observability-design.md §3.2:

```markdown
## Value Density

| Metric | Value |
|--------|-------|
| Revenue-relevant (7d) | {n} ({pct}%) |
| Maintenance (7d) | {n} ({pct}%) |
| Value density (7d) | {pct}% {trend} |
| Value density (30d) | {pct}% |
| Stagnation status | {ok | warning | ALERT} |

Value Density: {pct}% (7-day) {↑↓→} | {pct}% (30-day) — {n} revenue / {n} total contracts
```

### 4.2 Trend Indicator

Compares current 7-day density to previous 7-day density (offset by 1 day):

| Symbol | Condition |
|--------|-----------|
| ↑ | Current > previous + 5pp |
| ↓ | Current < previous - 5pp |
| → | Within ±5pp |

### 4.3 Condensed Telegram Digest Line

Added to the condensed Telegram health summary (observability-design §3.3):

```
VD: 45% (7d) ↑ | 12 rev / 27 total
```

When stagnation threshold is breached, the line becomes:

```
⚠️ VD: 5% (7d) ↓ | 3 rev / 298 total — STAGNATION (day 3)
```

---

## 5. Interaction with Liberation Directive

The liberation directive (§ Operating Principles, item 6) states: "Revenue-generating prompts get priority claim on Crumb sessions."

Value density provides the **feedback loop** for this principle:
- The directive sets the intent (prioritize revenue work)
- The scheduler dispatches contracts per service cadences
- Value density measures the actual outcome (is revenue work getting done?)
- If density drops, the metric surfaces the signal — it does not re-prioritize contracts

The metric is **observational, not prescriptive**. It does not modify scheduler behavior, adjust priorities, or suppress maintenance contracts. It tells the operator: "Here is how your system is spending its time." The operator decides whether to act.

This separation is deliberate. Automated priority adjustment based on value density would create a feedback loop where the system optimizes its own metric rather than serving the mission. The operator — Danny — holds the judgment about whether low density is a problem or a legitimate state (e.g., liberation directive degradation Level 2/3).

---

## 6. Data Source

### 6.1 Contract Ledger Fields Used

From `~/.tess/logs/contract-ledger.yaml` (schema in observability-design §6.1):

| Field | Usage |
|-------|-------|
| `service` | Maps to classification table (§2) for revenue weight |
| `outcome` | Only `completed` contracts counted (excludes `dead_letter`, `abandoned`) |
| `completed` | Timestamp for time-window filtering |

### 6.2 Historical Storage

```yaml
# ~/.tess/logs/value-density.yaml — appended daily at digest generation
- date: "2026-04-15"
  window_7d:
    revenue_weighted: 12.4
    total: 27
    density: 0.459
  window_30d:
    revenue_weighted: 156.2
    total: 340
    density: 0.459
  stagnation:
    below_warning: false
    consecutive_days_below_alert: 0
  top_services:
    - { service: "health-ping", count: 672, classification: "maintenance" }
    - { service: "awareness-check", count: 336, classification: "maintenance" }
    - { service: "daily-attention", count: 48, classification: "mixed", weight: 0.4 }
```

Retention: 90 days (aligned with storm-reports retention in observability-design §1.5). Older entries archived monthly.

---

## 7. Steady-State Estimate

Using service cadences from TV2-021b and cost data from TV2-028:

| Category | Completions/Day | Revenue-Weighted | Notes |
|----------|----------------|-----------------|-------|
| Heartbeats (3 services) | ~192 | 0 | Every 900-1800s, pure maintenance |
| Vault gardening (2) | ~2 | 0 | Daily |
| FIF pipeline (3) | ~3 | 1.2 | capture + attention at 0.6 each, feedback at 0.0 |
| Daily attention (1) | ~48 | 19.2 | Every 1800s, weight 0.4 |
| Overnight research (1) | ~1 | 1.0 | Nightly, full revenue |
| Email triage (1) | ~48 | 14.4 | Every 1800s, weight 0.3 |
| Morning briefing (1) | ~1 | 0.4 | Daily, weight 0.4 |
| Scout pipeline (3) | ~2 | 2.0 | Daily + weekly, full revenue |
| Connections brainstorm (1) | ~1 | 1.0 | Daily, full revenue |
| **Total** | **~298** | **~39.2** | |

**Estimated steady-state value density: ~13%.**

This looks low but is expected: heartbeats alone produce ~192 completions/day (65% of volume) at zero revenue weight. The metric is volume-based, and maintenance services run at much higher cadence than revenue services.

### 7.1 Threshold Calibration

Given the steady-state estimate of ~13%, the initial stagnation thresholds must account for the high-cadence maintenance baseline:

| Threshold | Original Proposal | Calibrated |
|-----------|-------------------|------------|
| Warning | <25% | **<10%** |
| Alert (3 consecutive days) | <20% | **<8%** |

The calibrated thresholds detect when revenue-relevant services stop running altogether (density drops from ~13% toward 0%), rather than triggering on normal operation. If the service mix changes (e.g., heartbeat cadence reduced), recalibrate.

**Alternative: exclude high-cadence heartbeats from denominator.** Counting only services that run ≤48 times/day gives ~106 completions and ~39.2 revenue-weighted, yielding density ~37%. This makes the metric more meaningful but less honest about how the system spends compute. Decision: use the full count with calibrated thresholds. The operator sees the real picture.

---

## 8. Open Items

1. **Threshold tuning:** Initial thresholds are estimates based on service cadences. Tune after 30 days of production data.
2. **Weight review cadence:** Service weights should be reviewed quarterly alongside the liberation directive review.
3. **Contract volume normalization:** If a future design adds contract batching (multiple actions per contract), the counting method will need revision.
