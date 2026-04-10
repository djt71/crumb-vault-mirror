---
project: tess-v2
type: runbook
domain: software
status: active
created: 2026-04-09
updated: 2026-04-09
task: TV2-043
---

# Opportunity Scout — Rollback Runbook

Rollback procedure for the Scout pipeline migration (TV2-043) during the
parallel-run gate window. Exercised end-to-end on 2026-04-09 as part of
the gate eval remediation.

## When to Use

Roll back to OpenClaw-only operation when any of these are observed:

- Tess scout pipeline runs are failing repeatedly (≥3 consecutive
  dead-letters in `~/.tess/state/run-history.db` for any of the three
  scout services)
- OpenClaw scout pipeline is healthy but Tess wrapping is producing
  spurious failure alerts that overwhelm the operator
- Underlying scout code or DB schema changes break Tess's wrapper before
  the wrapper can be updated
- Any unexpected behavior during the parallel run that risks duplicate
  delivery, scoring drift, or DB corruption

The rollback target is **OpenClaw-only operation** — the OpenClaw
LaunchAgents (`com.scout.daily-pipeline`, `com.scout.feedback-poller`,
`com.scout.weekly-heartbeat`) remain loaded throughout the parallel run
and require no changes to roll back.

## Procedure

### Step 1 — Snapshot current state (optional, for audit)

```bash
for label in com.scout.daily-pipeline com.scout.feedback-poller \
             com.scout.weekly-heartbeat \
             com.tess.v2.scout-pipeline \
             com.tess.v2.scout-feedback-health \
             com.tess.v2.scout-weekly-heartbeat; do
    printf "%-45s " "$label"
    if launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1; then
        echo "LOADED"
    else
        echo "NOT LOADED"
    fi
done
```

### Step 2 — Bootout Tess scout LaunchAgents

```bash
for label in com.tess.v2.scout-pipeline \
             com.tess.v2.scout-feedback-health \
             com.tess.v2.scout-weekly-heartbeat; do
    launchctl bootout "gui/$(id -u)" \
        "/Users/tess/Library/LaunchAgents/$label.plist"
done
```

### Step 3 — Verify OpenClaw is still loaded

```bash
for label in com.scout.daily-pipeline com.scout.feedback-poller \
             com.scout.weekly-heartbeat; do
    launchctl print "gui/$(id -u)/$label" >/dev/null 2>&1 \
        && echo "OK: $label" \
        || echo "MISSING: $label  ← INVESTIGATE"
done
pgrep -af 'poller.js' | head  # OpenClaw poller still running?
```

If any OpenClaw service is missing, **stop and investigate** — that
indicates a deeper problem than a Tess wrapper issue and the rollback
won't restore service.

### Step 4 — Confirm OpenClaw delivery the next cycle

OpenClaw runs the daily pipeline at 07:00 EDT via
`StartCalendarInterval`. The next-cycle digest should land in
`/Users/tess/crumb-vault/_openclaw/data/scout-digests/YYYY-MM-DD.md`
with `delivered: true` and a `telegram_msg_id`.

## Restore (after fix)

To restore Tess scout LaunchAgents after fixing the underlying issue:

```bash
for label in com.tess.v2.scout-pipeline \
             com.tess.v2.scout-feedback-health \
             com.tess.v2.scout-weekly-heartbeat; do
    launchctl bootstrap "gui/$(id -u)" \
        "/Users/tess/Library/LaunchAgents/$label.plist"
done
```

Note: bootstrap resets the LaunchAgent run counter to 0. The
`~/.tess/state/run-history.db` row history is preserved (it lives in the
contract runner DB, not the LaunchAgent state).

## Rollback Test Record

| Date | Result | Cycle Time | Notes |
|------|--------|------------|-------|
| 2026-04-09 | ✓ PASS | ~5s | Bootout 3/3 OK, OpenClaw run counts unchanged (20/1/3), Tess restored 3/3, run counters reset to 0 as expected. Exercised during gate eval remediation. |
