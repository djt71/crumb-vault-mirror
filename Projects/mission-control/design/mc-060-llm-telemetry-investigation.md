---
type: investigation
project: mission-control
domain: software
status: complete
created: 2026-03-07
updated: 2026-03-07
tags:
  - telemetry
  - observability
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# MC-060: Structured Per-Call LLM Telemetry Investigation

## Problem

The dashboard has two panels that depend on telemetry data that doesn't exist:
- **Cost Burn** (Ops page) — currently FIF-only via SQLite; no visibility into voice, mechanic, dispatch, or code-review costs
- **LLM Status** (Ops page) — permanently in error state; no model health data

Two adapter target files were spec'd but never created:
- `_system/logs/ops-metrics.json` — `ops-metrics.ts` adapter reads it, nothing writes it
- `_system/logs/llm-health.json` — `llm-health.ts` adapter reads it, nothing writes it

## Current Telemetry Landscape

### Sources That Exist

| Consumer | Storage | Format | Live? | Per-Call? | Tokens | Cost |
|----------|---------|--------|-------|-----------|--------|------|
| FIF pipeline | `~/openclaw/feed-intel-framework/state/pipeline.db` `cost_log` table | SQLite | Yes | Per-batch | No (estimates only) | Yes |
| Tess cron jobs | `_openclaw/logs/ops-metrics.jsonl` | JSONL | Yes | Per-job | Fields exist, all 0 | Fields exist, all 0.00 |
| OpenClaw gateway | `/tmp/openclaw/openclaw-YYYY-MM-DD.log` | JSONL | Yes | No | Not captured | Not captured |

### Sources That Don't Exist

| Consumer | Notes |
|----------|-------|
| Sonnet dispatch (CTB) | One-off calibration in `ctb-010-token-cost-sonnet.json`. No live tracking. |
| Code review (Opus+Codex) | Token budget gate in skill; dispatch captures usage from API response but doesn't persist. |
| Claude Code sessions | No telemetry capture at all. |

### Key Finding

The `ops-metrics.jsonl` infrastructure in `cron-lib.sh` already provides:
- `cron_set_tokens(in, out)` — sets token counts for current job
- `cron_set_cost(usd)` — sets cost estimate for current job
- `cron_finish()` — writes the JSONL record with all fields

But no cron job actually calls `cron_set_tokens()` or `cron_set_cost()` with real values. All records show `tokens_in: 0, tokens_out: 0, cost_estimate: 0.00`.

## Recommendation: Three Small Pieces

### 1. JSONL-to-JSON rollup script

**What:** Read `_openclaw/logs/ops-metrics.jsonl`, aggregate by job_id, write `_system/logs/ops-metrics.json` in the shape the `ops-metrics.ts` adapter expects.

**Shape (already defined by adapter):**
```json
{
  "jobs": [
    {
      "name": "awareness-check",
      "runs": 24,
      "successes": 23,
      "failures": 1,
      "totalCost": 0.12,
      "lastRun": "2026-03-07T17:35:00Z"
    }
  ],
  "totalCostToday": 0.12,
  "totalCostWeek": 0.84,
  "costCeiling": 5.00,
  "lastUpdated": "2026-03-07T18:00:00Z"
}
```

**Run by:** LaunchAgent on 15-min interval, or called by dashboard API startup.

### 2. LLM health JSON generator

**What:** Parse OpenClaw gateway logs for `embedded run start` entries (contain provider + model). Count calls, track last-seen timestamps. Write `_system/logs/llm-health.json`.

**Shape (already defined by adapter):**
```json
{
  "models": [
    {
      "provider": "anthropic",
      "model": "claude-haiku-4-5-20251001",
      "callCount": 48,
      "successRate": 0.98,
      "p95LatencyMs": null,
      "lastCall": "2026-03-07T17:30:00Z",
      "degradationNotes": []
    }
  ],
  "lastUpdated": "2026-03-07T18:00:00Z"
}
```

**Limitation:** Gateway logs don't include token counts or latency per call. `callCount` and `lastCall` are derivable; `successRate` requires matching start/end pairs; `p95LatencyMs` may not be feasible without OpenClaw changes.

### 3. Populate real token counts in cron jobs

**What:** Update `awareness-check.sh` (and future cron jobs) to extract token/cost from the claude `--print` response metadata and call `cron_set_tokens()` / `cron_set_cost()`.

**Approach:** `claude --print` with `--output-format json` returns usage metadata. Parse with jq, feed to cron-lib functions.

## Out of Scope (deferred)

- **Unified cost ledger** across all consumers — useful but premature. Start with per-source visibility.
- **Sonnet dispatch live tracking** — CTB bridge doesn't persist per-call data. Would need bridge code changes.
- **Code review cost persistence** — low volume (~2-3/week), manual run-log capture is adequate for now.
- **Claude Code session telemetry** — no capture mechanism exists; not worth building.

## Blocks

- Ops page full Cost Burn (currently FIF-only)
- Ops page LLM Status panel (currently error state)
- Related: TOP-050 (ops metrics harness), spec F13
