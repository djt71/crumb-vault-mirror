---
type: how-to
status: active
domain: software
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How to Run the Feed Pipeline

**Problem:** Feed-intel items have accumulated in `_openclaw/inbox/` and/or the Mission Control dashboard has pending promotions. You need to process them into the vault (signal-notes, action items) or dismiss them.

**Architecture source:** [[03-runtime-views]] §Feed Pipeline, [[skills-reference]] §feed-pipeline

---

## Prerequisites

- Active Crumb session (Claude Code in the vault)
- Feed-intel items present (session startup reports the count and tier breakdown)
- FIF SQLite database accessible at `~/openclaw/feed-intel-framework/state/pipeline.db`

---

## Trigger

Tell Crumb: "process feed items", "feed pipeline", "promote inbox items", or "clear feed backlog".

The feed-pipeline skill activates automatically on these trigger phrases. There is no cron or automated trigger — the operator decides when to process.

**Session startup tells you when to run:** The startup hook reports inbox count and tier breakdown (T1/T2/T3 + dashboard queue). Use this to decide whether to process now or defer.

---

## Processing Steps

### Step 0: Dashboard Promotions

If Mission Control has pending promotions (`dashboard_actions` where `consumed_at IS NULL`), the skill processes these first. Dashboard-promoted items skip permanence evaluation — the operator already decided.

### Step 1: Scan and Classify

The skill scans `_openclaw/inbox/feed-intel-*.md` and classifies by frontmatter:

| Tier | Criteria | Action |
|------|----------|--------|
| **Tier 1** | `priority: high` + `confidence: high` + `action: capture` | Permanence evaluation → auto-promote or review queue |
| **Tier 2** | `action: test` or `action: add-to-spec` | Extract one-line action → route to active project |
| **Tier 3** | Everything else | Log for calibration only (no processing) |

**Circuit breaker:** If Tier 1 > 10 items, all Tier 1 routes to review queue. This indicates upstream classifier drift — review the entire batch manually.

You choose which tiers to process.

### Step 2: Tier 2 — Action Extraction

For each Tier 2 item, the skill extracts an action and matches it to an active project by tags. You approve or skip each action. Approved items are appended to the project's run-log.

### Step 3: Tier 1 — Permanence Evaluation

Items are processed in batches of 20. Each item is evaluated on four questions:

1. **Durable or timely?** Reusable pattern vs. news/announcements
2. **Canonical `#kb/` tag?** FIF tags mapped to canonical tags; unmappable → review queue
3. **Vault dedup?** Check `Sources/signals/` for existing coverage
4. **Active project applicability?** Scan `Projects/` for relevance

**Routing:**
- All four pass → **auto-promote** (signal-note created in `Sources/signals/`)
- Any borderline → **review queue** (flagged for operator decision)

### Step 4: Calibration

The skill logs run statistics to `_system/docs/feed-pipeline-calibration.jsonl`.

---

## What Gets Created

| Artifact | Location | When |
|----------|----------|------|
| Signal-note | `Sources/signals/{source_id}.md` | Auto-promote or dashboard-promote |
| MOC entry | `Domains/Learning/moc-signals.md` Core section | Each promotion |
| Review queue | `_openclaw/inbox/review-queue-YYYY-MM-DD.md` | Borderline items |
| Project cross-post | `Projects/*/progress/run-log.md` | Q4 match found |
| Dashboard sync-back | `pipeline.db` → `dashboard_actions` | Each processed item |
| Calibration entry | `_system/docs/feed-pipeline-calibration.jsonl` | End of run |

---

## Monitor Pipeline Health

**Session startup:** Reports inbox count + tier breakdown automatically.

**Health script:** `_openclaw/scripts/fif-health.sh` monitors 7 signals:

| Signal | Threshold | Meaning |
|--------|-----------|---------|
| `CAPTURE_STALE` | Last capture >25h | Capture clock stopped |
| `ATTENTION_STALE` | Last triage >25h | Attention clock stopped |
| `QUEUE_DEEP` | Pending >50 items | Backlog growing |
| `DELIVERY_STALE` | Last vault routing >25h | Router stalled |
| `FEEDBACK_STALE` | Unprocessed feedback >48h | Feedback queue stuck |
| `ADAPTER_FAILING` | 3+ consecutive failures | Source adapter broken |
| `COST_CAP` | Daily spend >$1.50 | Cost threshold exceeded |

Returns `FIF_OK` if all healthy.

**Mission Control:** Intelligence page → Pipeline section shows pending items and health status.

---

## Handle Failures

| Failure | Symptom | Recovery |
|---------|---------|----------|
| FIF database missing | Step 0 skipped, inbox processing continues | Non-blocking; check `pipeline.db` path |
| Database locked | Sync-back fails, item stays in queue | Retry on next run (idempotent) |
| Circuit breaker fires | All T1 → review queue | Review batch manually; investigate upstream classifier |
| Dedup collision | Item flagged in review queue | Decide: promote separately, merge, or skip |
| vault-check fails on signal-note | Note not committed | Fix frontmatter or move to review queue |
| `#kb/` tag unmappable | Item → review queue | Assign tag manually or propose new L3 subtag |

---

**Done criteria:** Inbox items processed (promoted, actioned, or queued for review). Calibration logged. Dashboard sync-back complete. vault-check passes.
