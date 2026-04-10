---
type: change-spec
domain: software
project: crumb-tess-bridge
status: implemented
created: 2026-02-25
updated: 2026-02-25
---

# Design Note: Persistent Dispatch Processing

**Problem:** Research dispatches (and any future bridge dispatches) only complete when an active Claude Code session is running with the bridge watcher. The pipeline up to `_openclaw/inbox/` is fully autonomous (launchd daemons: capture, attention, feedback). The inbox-to-completion step requires a manual Crumb session.

**Impact:** When the operator sends a `research` command from Telegram without an active session, the feedback listener acks, runs enrichment, writes dispatch files — then they sit in the inbox until the next Crumb session. Research completion is session-dependent, not event-driven.

**Origin:** Identified during x-feed-intel compound insight testing (2026-02-25). Two dispatches queued while no Crumb session was active; one required manual triggering.

---

## Existing Infrastructure

The machinery for persistent processing already exists:

- **`_system/scripts/bridge-watcher.py`** — Full kqueue daemon (40KB). Watches `_openclaw/inbox/` for `.json` dispatch files. Designed for launchd (`KeepAlive=true`, clean SIGTERM handling). Features: kill switch (`.bridge-disabled`), rate limiting, processed-ID tracking, governance verification, fallback polling, transcript capture.
- **`CRUMB_BRIDGE_USE_CLAUDE=1`** — Config flag for headless `claude --print` dispatch (vs. direct Node.js processing). Already implemented in the watcher.
- **Three x-feed-intel daemons** already registered under `ai.openclaw.xfi.*` — the pattern for a 4th service is established.

## Proposed Approach

Register `bridge-watcher.py` as a persistent launchd service alongside the existing x-feed-intel daemons.

**Service identity:** `ai.openclaw.bridge.watcher` (bridge-level, not xfi-level — this processes all bridge dispatches, not just feed-intel research).

**Config adjustments needed:**
- `CRUMB_BRIDGE_USE_CLAUDE=1` — enable Claude Code headless dispatch
- `CRUMB_BRIDGE_PROCESS_TIMEOUT` — increase from 60s default to 300-600s for research dispatches (the config comment already notes this need)
- `CRUMB_BRIDGE_RATE_MAX` — review rate limit for research volume (current: 60/hour, likely fine)

## Prerequisites to Verify

Before registering as persistent service:

1. **`bridge-processor.js` status** — the watcher references `Projects/crumb-tess-bridge/src/crumb/scripts/bridge-processor.js`. Confirm it exists and handles `invoke-skill` operations.
2. **`verify-governance.js` status** — governance verification script. Confirm operational.
3. **`claude --print` headless path** — the watcher's Claude dispatch mode needs testing with actual research dispatches. Confirm: correct `--tools` flags, permission mode (`dontAsk`), working directory, API key availability (keychain vs env var).
4. **Cost guardrails** — persistent processing means unattended API spend. The rate limiter helps, but confirm the kill switch (`.bridge-disabled`) is tested and documented for emergency stop.
5. **CTB-025 (cancel-dispatch + kill-switch)** — verify this task is complete or determine if it overlaps.

## Relationship to Open Tasks

- **CTB-025 (cancel-dispatch + kill-switch):** Direct overlap — the kill switch is already in the watcher. This task may need updating to reflect that.
- **CTB-026 (Tess CLI):** Separate concern (operator-facing CLI) but shares the "who processes dispatches" design space.
- **CTB-029 (Telegram alerts):** Complementary — when the watcher processes a dispatch, it could send completion alerts via the same channel.
- **CTB-030 (.processed-ids optimization):** Prerequisite — persistent processing increases rotation importance.

## Alternative Considered

**Tess processes directly (no Crumb dependency):** If tess-model-architecture is operational, Tess could handle research dispatches without Claude Code. The dispatch prompt is self-contained. This removes the session dependency entirely but couples research quality to Tess's model tier. Deferred — the current bridge architecture assumes Crumb processes dispatches, and changing that is a larger design decision.

## Cost Impact

Zero infrastructure cost — Python kqueue daemon, local file I/O. API cost per dispatch is the same as session-triggered processing (one `claude --print` invocation per research). The rate limiter prevents runaway spend.

## Suggested Task

CTB-032 (or next available): Register `bridge-watcher.py` as `ai.openclaw.bridge.watcher` launchd service. Verify prerequisites, adjust config, test headless research dispatch end-to-end.
