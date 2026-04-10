---
project: tess-operations
domain: software
type: reference
skill_origin: null
created: 2026-03-01
updated: 2026-03-01
tags:
  - health-monitoring
  - healthchecks-io
---
# Dispatch: Consolidate Health Monitoring into health-ping.sh

**Project:** tess-operations
**Related task:** TOP-003 (Health ping script)
**Priority:** Low — existing monitoring is working, this is cleanup
**Status:** Script updated (Keychain fallback + provider-agnostic naming). Keychain entry and plist update pending manual steps.

## Context

We discovered that the Mac Studio's external health monitoring is already working via Healthchecks.io, but through a path that bypasses the `health-ping.sh` script built in M0.

**What's currently running:**
- `~/Library/LaunchAgents/ai.openclaw.health-ping.plist` — a simple LaunchAgent under the `tess` user that curls the Healthchecks.io ping URL directly on a timer
- Healthchecks.io check: `tess-mac-studio-health`, 15-minute period, 2-hour grace window, actively green
- Ping URL: `https://hc-ping.com/2d063102-5080-49d8-bfe8-893ada1c9231`

**What's NOT running:**
- `_openclaw/scripts/health-ping.sh` (TOP-003) — the richer script with system health checks, job freshness validation, and staleness detection. `TESS_HEALTH_PING_URL` env var is empty, so every run hits the `SKIP: no HEALTH_PING_URL configured` path and does nothing.

## Changes Made

1. **health-ping.sh updated:** Added Keychain fallback — script now pulls URL from `security find-generic-password` if `TESS_HEALTH_PING_URL` env var is not set. Renamed `UPTIME_ROBOT_URL` → `HEALTH_PING_URL` throughout for provider-agnostic naming.

## Remaining Manual Steps

2. Store the Healthchecks.io URL in Keychain:
   ```bash
   security add-generic-password -a health-ping -s tess-health-ping-url -w "https://hc-ping.com/2d063102-5080-49d8-bfe8-893ada1c9231"
   ```

3. Update the existing `ai.openclaw.health-ping.plist` to call `health-ping.sh` instead of bare curl. This gives us the richer health checks (job freshness, system state) while keeping the same Healthchecks.io endpoint.

4. Verify end-to-end: run `health-ping.sh` manually, confirm Healthchecks.io dashboard shows the ping.

5. Update TOP-003 notes in tasks.md — remove "Uptime Robot setup deferred", note Healthchecks.io is the external monitor and consolidation is complete.

## Notes

- "My First Check" in Healthchecks.io (the other monitor) can be deleted — it's the default check created on signup and has never received a ping.
