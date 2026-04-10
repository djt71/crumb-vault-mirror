---
project: opportunity-scout
domain: software
type: action-plan
skill_origin: action-architect
created: 2026-03-14
updated: 2026-03-14
tags:
  - automation
  - tess
  - openclaw
---

# Opportunity Scout — Action Plan

## Overview

20 atomic tasks across 4 milestones (M0–M3). M4 (Steady State) is an operational milestone with no implementation tasks — it's the 30-day soak criterion. Budget 3–6 iteration rounds on first live deployment of the cron pipeline (per claude-print automation Pattern 4, `_system/docs/solutions/claude-print-automation-patterns.md`).

The critical path runs: OSC-001/002 (parallel) → OSC-003 → OSC-004/005 (parallel) → OSC-009 → OSC-010 → OSC-012 → OSC-013 → OSC-014/015 (parallel) → OSC-016 → OSC-017 → OSC-018 → OSC-019.

## M0: Source + Scoring Validation

**Goal:** Prove the ingestion → scoring → storage pipeline works end-to-end with real sources and validated triage quality.

**Success criteria:**
- ≥3 RSS sources + HN API ingesting successfully
- Haiku/Sonnet triage agreement ≥85% (exact match, ≥43/50 items)
- Candidate registry correctly stores, deduplicates, and manages state
- Config/secrets scaffolding in place (Telegram bot token, API credentials)

**Exit gate:** All M0 tasks complete, OSC-009 integration test passing.

### Phase 1: Foundation (OSC-001, OSC-002 — parallel)

Two independent workstreams that can proceed simultaneously:
- **Research track (OSC-001):** Extract calibration data from v1–v7 research dispatches. Produces the scoring seed and graveyard seed that downstream tasks consume.
- **Infrastructure track (OSC-002):** Initialize external repo, define SQLite schema for all 4 data contracts (source registry, candidate records, digest mapping, graveyard), scaffold config/secrets management.

### Phase 2: Sources + Adapters (OSC-003 → OSC-004, OSC-005 — parallel after interface)

Populate the source registry (OSC-003), then build adapters. OSC-004 defines the adapter interface contract AND implements the RSS adapter. OSC-005 (HN adapter) depends on the source registry and repo — not on the completed RSS adapter — enabling parallel development once the interface contract is defined in OSC-004's design phase.

### Phase 3: Scoring + Registry (OSC-006, OSC-008 — parallel; then OSC-007)

Test set curation (OSC-006) and candidate registry implementation (OSC-008) can proceed in parallel — both need OSC-001 completion. Triage prompt design and validation (OSC-007) requires OSC-006 completion.

### Phase 4: M0 Integration (OSC-009)

End-to-end test: ingest from real sources → score → insert into candidate registry. Validates the complete M0 data pipeline before building delivery on top of it. **Do not start M1 until this passes.**

## M1: First Digest Production

**Goal:** Deliver formatted digests to Danny via Telegram with working feedback commands. Run unattended for 3 days.

**Success criteria:**
- Digest renders correctly in Telegram with Sonnet-generated key insights
- Feedback commands resolve to correct candidates via digest mapping
- No duplicate ingests/sends across 3 pipeline runs (at least 1 overnight)
- Discord mirror, weekly heartbeat, and failure alerts working
- Feedback poller responds within 60 seconds

**Exit gate:** Pre-launch validation checklist (OSC-016) passes. Ship to Danny, start M2 clock.

### Phase 5: Delivery Pipeline (OSC-010, OSC-011 — sequential)

Build digest assembly + Telegram delivery (OSC-010, depends on M0 integration OSC-009), then add Discord mirror + heartbeat + failure alerts (OSC-011). Telegram delivery is the critical path; Discord/heartbeat are additive.

### Phase 6: Orchestration (OSC-012, OSC-013 — sequential)

First: build the bash pipeline script with idempotency, run IDs, and data retention (OSC-012). Then: create LaunchAgent plist, configure error isolation, and validate multi-model invocation (OSC-013). Split for scope control — OSC-013 is where the 3–6 live deployment iterations will concentrate.

### Phase 7: Feedback Loop (OSC-014, OSC-015 — sequential)

First: build the persistent Telegram Bot API feedback poller as a LaunchAgent process with getUpdates offset management and acknowledgement responses (OSC-014). Then: implement command execution — digest mapping resolution, state updates, throttles, and `/scout add` (OSC-015). The poller is a long-running process (not cron) to achieve ≤60s response latency.

### Phase 8: Pre-Launch Validation (OSC-016)

Validation checklist, not a multi-day soak. Run the pipeline 3 times (at least 1 overnight via LaunchAgent), simulate a source failure, verify feedback commands work, confirm heartbeat logic. This takes hours, not days. Once the checklist passes, ship to Danny immediately and start the M2 behavioral clock. Early bugs in a personal system are fixable during M2 — the real validation is whether Danny engages.

## M2: Feedback Loop + Calibration

**Goal:** Validate that Danny engages with the system and calibrate scoring based on real feedback data.

**Success criteria:**
- 30-day validation window: ≥5 qualifying digests reviewed, ≥10 scan cycles, bookmark/research rate ≥20%
- 21-day interim checkpoint for early signal
- Source yield scores computed, ≥1 source priority adjustment
- Triage threshold adjusted at least once from M0 baseline
- **ABORT if <20% bookmark/research rate after 30 days OR <5 digests in any 30-day period**

### Phase 9: Behavioral Validation (OSC-017)

30-day live operation with Danny receiving real digests from day 1. Metric collection with 21-day interim checkpoint. If pipeline breaks during M2, fix and resume — don't reset the clock unless >3 consecutive days lost. This is the project's highest-risk gate — behavioral adoption (A1).

### Phase 10: Calibration (OSC-018)

Source yield scoring, deprioritization policy, threshold tuning based on M2 feedback data.

## M3: Monthly Evaluation

**Goal:** Complete the monthly evaluation cycle and design the Execute Mode feedback interface.

**Success criteria:**
- First monthly memo produced in ≤30 minutes
- Execute Mode feedback interface schema documented

### Phase 11: Monthly Cycle (OSC-019, OSC-020 — parallel)

Monthly memo generator (OSC-019) and Execute Mode interface design (OSC-020) are independent and can proceed in parallel. OSC-020 has no dependencies and can optionally start at any time.

## M4: Steady State (operational — no implementation tasks)

**Goal:** Scout running autonomously for 30+ consecutive days.

**Success criteria:**
- ≥1 opportunity Danny acted on that he wouldn't have found otherwise
- Danny has not abandoned daily review (≤3 skipped digests in any 30-day period)
- System runs with ≤15 min/day of Danny's time

## Risk-Informed Sequencing Notes

1. **M0 Phase 4 (OSC-009 integration test) is the first real validation point.** If the data pipeline doesn't work end-to-end, nothing downstream matters. Don't move to M1 until this passes.
2. **M1 Phase 8 (OSC-016 validation checklist) confirms basic reliability before shipping to Danny.** Run 3 times, simulate a failure, verify feedback — then ship. Early bugs are fixable during M2; waiting days for a soak delays the real validation (behavioral adoption).
3. **M2 Phase 9 (OSC-017 behavioral validation) is the project's existential gate.** The abort criterion is real — if Danny doesn't engage, the project stops. This is by design.
4. **Pattern 4 (live deployment iteration):** Budget 3–6 iteration rounds on OSC-013 (LaunchAgent + multi-model validation). First live deployment of multi-model cron pipelines consistently needs prompt-model contract calibration that tests can't catch.
5. **Feedback poller is a persistent process, not cron.** Cron has 1-minute minimum resolution. The ≤60s response latency requirement means the feedback poller (OSC-014) must run as a LaunchAgent with KeepAlive, separate from the daily pipeline cron.
