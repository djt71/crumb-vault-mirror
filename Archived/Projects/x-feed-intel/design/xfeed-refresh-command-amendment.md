---
type: amendment
project: x-feed-intel
domain: software
status: applied
created: 2026-02-23
updated: 2026-02-23
tags:
  - x-feed-intel
  - feedback
---

# X Feed Intel — `refresh` Command Amendment

## Summary

Add a `refresh` command to the Telegram feedback listener (XFI-022) that triggers a full capture→attention chain on demand. This lets the operator fetch new content and receive a fresh digest outside the scheduled 6 AM / 7 AM launchd cycle.

## Motivation

The pipeline currently runs on a fixed daily schedule: capture at 6 AM, attention at 7 AM. There's no way to trigger a refresh outside that window without SSH'ing to the Studio and running npm scripts manually. A Telegram `refresh` command provides on-demand access through the same interface used for all other pipeline interaction.

## Command Design

### Grammar

```
refresh
```

Standalone command — not a reply to a digest message. No arguments. Sent as a direct message to the bot (not as a reply-to-message-id like item commands).

This is a departure from the existing feedback grammar (`{ID} {command} [argument]`) which requires a reply to a digest message. The `refresh` command operates at the pipeline level, not the item level, so it doesn't reference a digest item.

### Behavior

1. Feedback listener receives `refresh`
2. Acknowledge immediately: "Refresh started — capture + triage running. Digest will arrive when complete."
3. Run full chain in sequence:
   - **Capture clock** with `force: true` — bypasses `shouldRunScan` frequency gate (if the operator is asking for a refresh, they want it to actually scan regardless of when the last scan ran)
   - **Attention clock** — triage pending queue, route to vault, generate digest
4. On completion: digest is delivered via normal Telegram delivery (no special handling needed — the attention clock already sends it)
5. On failure: send error summary to Telegram with which component failed

### Concurrency guard

If a scheduled run is already in progress when `refresh` is received, respond with: "Pipeline is currently running (started {timestamp}). Try again in a few minutes." Do not queue the refresh — the scheduled run will produce a digest shortly.

If a refresh is already in progress when another `refresh` is received, same response.

Implementation: simple lockfile at `state/pipeline.lock` written at chain start, removed at chain end. Stale lock detection: if lock file is older than 30 minutes, treat as stale (previous run crashed) and proceed.

### Cost tracking

Manual refreshes are logged to `cost_log` identically to scheduled runs. The `run_id` prefix distinguishes them: `capture-manual-{timestamp}` and `attention-manual-{timestamp}` (vs `capture-{timestamp}` and `attention-{timestamp}` for scheduled runs). This keeps MTD tracking accurate without any changes to the cost telemetry module.

## Task Definition

### XFI-022b: Implement `refresh` command

| Field | Value |
|-------|-------|
| **ID** | XFI-022b |
| **Description** | Add `refresh` command to feedback listener. Triggers full capture→attention chain on demand via Telegram. Bypasses scan frequency gate. Includes concurrency guard (lockfile). |
| **State** | pending |
| **Depends On** | XFI-022, XFI-014, XFI-021 |
| **Risk** | low |
| **Acceptance Criteria** | `refresh` message triggers capture+attention chain; scan frequency gate bypassed (`force: true`); immediate acknowledgment sent; digest delivered on completion; error summary on failure; concurrent run detected and rejected with informative message; stale lock (>30 min) treated as stale; cost logged with `manual` prefix in run_id; non-reply messages other than `refresh` still ignored per XFI-022 |

## Changes to Existing Tasks

### XFI-022 (feedback listener)

Add to AC: "`refresh` as standalone (non-reply) message recognized and dispatched to XFI-022b handler; other non-reply messages still ignored."

This means the feedback listener needs a small routing change: currently all non-reply messages are ignored. After this amendment, non-reply messages are checked against a command allowlist (`refresh`) before being discarded.

### XFI-014 (capture clock)

`runCaptureClock` needs a `force` option that bypasses the `shouldRunScan` frequency gate. The options object already supports `{ db?, statePath?, scanIntervalDays? }` from the A1 punch list work — adding `force?: boolean` is a one-line change. When `force` is true, `shouldRunScan` returns true regardless of last scan timestamp.

### XFI-028 (ops guide)

Add `refresh` command to the Telegram command reference section.
