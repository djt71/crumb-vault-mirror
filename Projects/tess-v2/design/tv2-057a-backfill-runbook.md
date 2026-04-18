---
project: tess-v2
type: runbook
domain: software
status: released
created: 2026-04-15
updated: 2026-04-18
task: TV2-057a
related:
  - tv2-057a-resumption-brief.md
  - tv2-057-promotion-integration-note.md
tags:
  - runbook
  - backfill
  - state-machine
---

# TV2-057a — Historical Backfill Runbook

> **Status: RELEASED 2026-04-18.** TV2-038 Phase 5 closed with verdict PASS (see `tv2-038-validation-report.md` §5.2). Backfill cleared for execution.

## 1. Why this is held

TV2-038 Phase 5 evaluates gate verdicts against the run-history table. Phase 5's analysis assumes the pre-TV2-057a meaning of `outcome='staged'` (passed-and-awaiting-promotion). Rewriting ~5800 staged rows to `completed` mid-collection would change what Phase 5 is measuring. The backfill must wait until the Phase 5 re-collection window closes.

Earliest safe execution: **2026-04-17 23:00Z** (≥48h after the TV2-056 must-fix commit `02be7b7` landed at 2026-04-15 22:43Z = 2026-04-15 18:43 -0400).

> **Prior-draft correction (2026-04-17):** An earlier version of this runbook listed the floor as **2026-04-17 18:00Z**, derived from "≥48h after ~18:00 **-0400**." The earlier calculation dropped the -0400 offset (treated local time as UTC). The correct UTC floor is **22:43Z**, rounded up to the next whole hour = **23:00Z**. Phase 5 window fixed as `2026-04-15 23:00Z → 2026-04-17 23:00Z` (48h rolling, whole-hour boundaries).

## 2. What it does

Rewrites historical `run_history` rows from `outcome='staged'` to `outcome='completed'` for the 14 Class C services. Annotates each affected row with sentinel `dead_letter_reason = 'tv2-057a-backfill'` so the migration is reversible and identifiable.

Affected services (must match `src/tess/classifier.py:_CLASS_C_SERVICES`):

```
awareness-check          fif-feedback             scout-feedback
backup-status            health-ping              scout-weekly-heartbeat
connections-brainstorm   overnight-research       vault-gc
email-triage             scout-daily-pipeline     vault-health
fif-attention
fif-capture
```

**Class A (not touched):** only `daily-attention` remains Class A post-TV2-057b reclassification.

> **[AMENDED 2026-04-17 — TV2-057b]**
> - `connections-brainstorm` moved A → C per `tv2-057-promotion-integration-note.md` §5 (output lives under `_openclaw/inbox/`, mirror space). Adds ~13 historical rows to the backfill.
> - `vault-health` moved A → C because the Tess v2 wrapper currently produces no canonical artifact; ownership with the still-loaded OpenClaw plist until TV2-040. Adds ~13 historical rows to the backfill.
> - Expected backfill row count shifts from ~5787 (original estimate) → ~5813 (+26). The live script reports the exact count during dry-run.

## 3. Procedure

### 3.1 Prereq check

1. Confirm Phase 5 closed:
   ```bash
   # Check TV2-038 project state in the vault
   grep -A2 "phase: 5" ~/crumb-vault/Projects/tess-v2/staging/TV2-038/*.yaml
   ```
   Phase 5 status must be `done` or equivalent. If not, **abort**.

2. Confirm code is current (Commit 1 must be in production):
   ```bash
   cd ~/crumb-apps/tess-v2
   git log --oneline -5 | grep TV2-057a
   ```
   Expected: `TV2-057a: add COMPLETED outcome + side-effect classifier`.

### 3.2 Snapshot the DB

```bash
cp ~/.tess/state/run-history.db ~/.tess/state/run-history.db.pre-tv2-057a-backfill
```

Verify size matches:
```bash
ls -l ~/.tess/state/run-history.db ~/.tess/state/run-history.db.pre-tv2-057a-backfill
```

### 3.3 Dry-run on a copy

```bash
cp ~/.tess/state/run-history.db /tmp/run-history-test.db
.venv/bin/python scripts/tv2_057a_backfill.py --db /tmp/run-history-test.db
```

Inspect the per-service preview. Expected total: ~5800 rows (exact count drifts as new runs land).

### 3.4 Execute on the copy and verify

```bash
.venv/bin/python scripts/tv2_057a_backfill.py --db /tmp/run-history-test.db --execute
```

Sanity-check the result:

```bash
sqlite3 /tmp/run-history-test.db \
  "SELECT outcome, COUNT(*) FROM run_history GROUP BY outcome ORDER BY outcome;"
sqlite3 /tmp/run-history-test.db \
  "SELECT COUNT(*) FROM run_history WHERE dead_letter_reason='tv2-057a-backfill';"
sqlite3 /tmp/run-history-test.db \
  "SELECT COUNT(*) FROM run_history WHERE service IN ('vault-health','daily-attention','connections-brainstorm') AND outcome='completed';"
```

Expected:
- `staged` count drops by ~5800; `completed` rises by the same amount.
- Sentinel row count == affected row count.
- Class A services have **zero** `completed` rows.

### 3.5 Stop running services briefly

To avoid the in-flight-write race called out in the script's drift warning:

```bash
launchctl unload ~/Library/LaunchAgents/com.tess.v2.*.plist
```

Wait ~30s for any in-flight runs to finish.

### 3.6 Execute against the live DB

```bash
.venv/bin/python scripts/tv2_057a_backfill.py --execute
```

### 3.7 Restart services

```bash
launchctl load ~/Library/LaunchAgents/com.tess.v2.*.plist
```

### 3.8 Final verification

```bash
sqlite3 ~/.tess/state/run-history.db \
  "SELECT outcome, COUNT(*) FROM run_history GROUP BY outcome ORDER BY outcome;"
```

Record before/after counts in the run-log entry that closes TV2-057a.

## 4. Rollback

Trivial (sentinel makes this clean):

```bash
sqlite3 ~/.tess/state/run-history.db <<'SQL'
UPDATE run_history
SET outcome = 'staged', dead_letter_reason = NULL
WHERE dead_letter_reason = 'tv2-057a-backfill';
SQL
```

The snapshot from §3.2 is the ultimate fallback if the sentinel approach goes sideways.

## 5. After execution

- Update `tasks.md` TV2-057a → `done`.
- Update `project-state.yaml` `active_task` → next sub-task (TV2-057b) or null.
- Run-log entry: include before/after `outcome` counts and sentinel row count.
- Delete the pre-backfill snapshot once a clean post-backfill day has passed (Class C services run frequently — within 24h the new `completed` rows will outnumber any rollback risk).
