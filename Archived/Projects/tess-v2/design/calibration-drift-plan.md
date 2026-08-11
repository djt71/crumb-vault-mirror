---
type: design
domain: software
status: draft
scope: general
created: 2026-04-01
updated: 2026-04-01
project: tess-v2
skill_origin: null
task: TV2-029
---

# Confidence Calibration Drift Monitoring Plan

> **Scope:** Generally applicable beyond tess-v2. 7-day rolling window drift detection, six re-calibration triggers, and five-step re-calibration procedure are reusable patterns for any system that relies on LLM confidence scores correlating with actual outcomes. See `_system/docs/tess-v2-durable-patterns.md`.

Defines how to detect, trigger, and execute re-calibration of the confidence-aware escalation system (TV2-018 four-gate hybrid). Confidence scores are only useful if they correlate with actual task outcomes. This plan ensures they stay correlated.

## 1. Confidence Model Baseline

### How Confidence Is Determined

Two gates produce confidence-relevant data:

| Source | When | What It Produces |
|--------|------|------------------|
| **Gate 2** (executor self-report) | EXECUTING, first iteration, Tier 1 only | `confidence: high / medium / low` in structured output |
| **Gate 4** (convergence monitor) | Background, post-terminal | Rolling stats: `avg_iterations`, `escalation_rate`, `quality_pass_rate` per action class |

Gate 1 and Gate 3 are mechanical/deterministic and do not produce confidence signals.

### What "Calibrated" Means

The system is calibrated when confidence scores predict outcomes:

| Confidence | Expected Outcome |
|------------|-----------------|
| `high` | Contract completes at assigned tier, iterations <= 2, quality check pass |
| `medium` | Contract completes but may need 2-3 iterations or minor quality rework |
| `low` / missing | Contract would likely fail at current tier (escalation justified) |

Calibration is per-model. Nemotron and Qwen backup have independent baselines.

### Initial Calibration Source

1. **Eval battery data** -- CAL-01 through CAL-05 results from TV2-018 validation (known-class, novel-class, adversarial, production-length prompts)
2. **First N production contracts** -- first 10 contracts per action class after leaving first-instance status (escalation-design SS9), tracked with extra logging
3. **Baseline snapshot** -- after 50 total Tier 1 contracts across all action classes, freeze the initial calibration baseline as the reference distribution

## 2. Drift Detection

### Metrics Tracked

| Metric | Source | Baseline Window | Detection Window |
|--------|--------|----------------|-----------------|
| **Escalation rate** | Gate 2 `low` triggers per action class | First 50 contracts | Rolling 7-day |
| **Tier success rate by confidence bucket** | Outcome vs. reported confidence | First 50 contracts | Rolling 7-day |
| **Quality pass rate by confidence level** | Quality check results tagged with Gate 2 score | First 50 contracts | Rolling 7-day |
| **Iteration count by confidence bucket** | `avg_iterations` for `high` vs `medium` contracts | First 50 contracts | Rolling 7-day |

### Detection Method

Daily batch job compares rolling 7-day production distribution against baseline:

1. Compute per-action-class stats for the 7-day window
2. Compare each metric against its baseline value
3. Flag drift when **any** metric diverges beyond threshold (see below)
4. Distinguish drift from workload shift (next section)

### Drift Thresholds

| Metric | Drift Threshold | Rationale |
|--------|----------------|-----------|
| Escalation rate | Baseline +15 percentage points | Moderate sensitivity; avoids false alarms from single bad days |
| `high`-confidence failure rate | Baseline +20 percentage points | The critical metric -- confident-but-wrong is the dangerous failure |
| Quality pass rate (overall) | Baseline -15 percentage points | Quality degradation regardless of confidence level |
| `medium`-confidence escalation rate | Baseline +25 percentage points | Wider band; `medium` is already flagged for tracking |

### Distinguishing Drift from Workload Shift

Not all metric changes indicate calibration decay. Check before triggering re-calibration:

| Signal | Interpretation | Action |
|--------|---------------|--------|
| New action class dominates volume | Workload shift, not drift | Monitor new class independently; do not contaminate baseline |
| Spike in one action class only | Class-specific issue | Investigate that class (prompt change? new edge cases?) |
| Uniform degradation across classes | Likely model drift or environment change | Trigger re-calibration |
| Degradation only after model restart | Runtime issue (memory, quantization) | Investigate serving layer first |

## 3. Re-Calibration Triggers

### Trigger Conditions

| Trigger | Type | Condition | Cooldown |
|---------|------|-----------|----------|
| **Sustained drift** | Automatic | Any drift threshold exceeded for 3 consecutive days | 7 days after last re-calibration |
| **Model swap** | Manual (immediate) | Nemotron GGUF replaced, or failover to Qwen backup (DEGRADED-LOCAL entry) | None |
| **Major prompt change** | Manual (immediate) | TV2-023 system prompt architecture update | None |
| **New service onboarding** | Manual (recommended) | New action class graduates from first-instance to Tier 1 | None |
| **Scheduled review** | Scheduled | Monthly, first day of month | N/A |
| **Gate 4 reclassification** | Automatic | Any action class promoted to higher tier by Gate 4 | Review adjacent classes |

### Trigger Priority

If multiple triggers fire simultaneously, execute once with the broadest scope. Model swap and prompt change take priority over sustained-drift (they likely caused it).

## 4. Re-Calibration Procedure

### Step 1: Run Calibration Battery

Execute the CAL-01 through CAL-05 test suite from TV2-018 SS10 against the current model configuration:

- 5 known-class tasks at production prompt length (CAL-01)
- 5 novel-class tasks (CAL-02)
- Known class with adversarial twist (CAL-03)
- Known class requiring credentials -- Gate 3 override check (CAL-04)
- Context-size stability: 4K vs 16K (CAL-05)

### Step 2: Compare Against Production Outcomes

Pull last 30 days of production data. For each action class with >= 10 contracts:

- Actual success rate by confidence bucket
- Actual iteration count by confidence bucket
- Escalation-to-completion rate (contracts that escalated but would have succeeded locally)

### Step 3: Update Confidence-to-Tier Mapping Thresholds

If the battery reveals systematic miscalibration (e.g., model now reports `high` for tasks it used to report `medium`), adjust:

| Adjustment | When |
|------------|------|
| Tighten Gate 2 -- treat `medium` as `low` for specific action classes | `high`-confidence failure rate > 30% for that class |
| Loosen Gate 2 -- skip confidence check for V1+exact classes | Class has 50+ contracts with 0 escalations and >95% quality pass |
| Update baseline snapshot | All classes pass battery + production comparison |

### Step 4: Dry-Run Validation

Re-process the last 20 production contracts through the updated thresholds (read-only, no dispatch):

- Compare routing decisions: old thresholds vs new
- Flag any contract that would change tier assignment
- Review changed assignments manually for correctness

### Step 5: Deploy and Monitor

- Write updated thresholds to routing configuration
- Tag deployment in contract ledger: `calibration_update: {date, trigger, changes}`
- Monitor first 48 hours at elevated logging level
- Rollback plan: revert to previous threshold snapshot if quality pass rate drops >10% in first 48h

## 5. DEGRADED-LOCAL Special Case

Per TV2-018 SS9: when running on Qwen backup, all Gate 2 confidence is treated as `medium`. This creates a separate calibration regime.

### Data Segregation

| Data Source | Primary Baseline | DEGRADED-LOCAL Baseline |
|-------------|-----------------|------------------------|
| Gate 2 confidence scores | Nemotron production data | Excluded (all forced to `medium`) |
| Gate 4 convergence stats | Nemotron production data | Tracked separately, tagged `degraded_local: true` |
| Quality pass rates | Nemotron production data | Tracked separately |

### Qwen Baseline Accumulation

DEGRADED-LOCAL periods are typically short (hours to days). Qwen calibration data accumulates across episodes:

1. Each DEGRADED-LOCAL episode tags all contract outcomes with `model: qwen-backup`
2. After 50 cumulative Qwen contracts across all episodes, a Qwen-specific baseline snapshot is viable
3. Until then, the `medium`-override policy from TV2-018 remains in effect
4. Once a Qwen baseline exists, Gate 2 can use Qwen-specific thresholds during DEGRADED-LOCAL

### Drift Detection During DEGRADED-LOCAL

- Primary drift calculation excludes DEGRADED-LOCAL data
- DEGRADED-LOCAL drift is calculated against the Qwen baseline (if available) or skipped (if < 50 contracts)
- Re-calibration triggers from SS3 apply independently to each model's data

## 6. Observability Integration

### Contract-Level Logging

Every Tier 1 contract logs to the contract ledger:

```yaml
confidence_record:
  contract_id: "C-247"
  gate2_confidence: "high"
  gate2_signals: ["known class", "exact routing match"]
  predicted_tier: 1
  actual_tier_used: 1
  outcome: completed
  iterations: 1
  quality_pass: true
  model: "nemotron"
  degraded_local: false
```

### Health Digest Inclusion

Weekly digest includes a calibration summary section:

- Confidence distribution (% high / medium / low) vs baseline
- `high`-confidence failure rate (the key safety metric)
- Any drift flags from the past 7 days
- Action classes approaching reclassification thresholds

### Alerts

| Condition | Channel | Urgency |
|-----------|---------|---------|
| Drift threshold exceeded (first day) | Telegram | FYI digest |
| Drift threshold sustained (3 days) | Telegram | Review-within-24h |
| `high`-confidence failure rate > 30% | Telegram | Urgent/blocking |
| Re-calibration completed | Telegram | FYI digest |

Alerting follows the human escalation taxonomy from spec SS7.5.

## 7. Interaction Map

| Component | Interface |
|-----------|-----------|
| **TV2-018 (Escalation Design)** | Gate 2 confidence schema, Gate 4 convergence data, DEGRADED-LOCAL policy |
| **TV2-017 (State Machine)** | Terminal state transitions trigger Gate 4 data collection |
| **TV2-023 (System Prompt)** | Prompt changes are a re-calibration trigger |
| **TV2-042 (Failover)** | DEGRADED-LOCAL entry/exit triggers model-swap re-calibration |
| **TV2-031b (Contract Runner)** | Produces confidence_record at contract completion |
| **Observability (SS18)** | Drift metrics feed health digest; alerts via Telegram |
