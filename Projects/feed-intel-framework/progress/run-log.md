---
type: run-log
project: feed-intel-framework
domain: software
status: active
created: 2026-02-23
updated: 2026-03-26
---

# Feed Intel Framework — Run Log

> **Archives:**
> - [[run-log-phase1]] — SPECIFY + PLAN + M1
> - [[run-log-2026-02]] — M2 X Adapter Migration, spec amendment, DB schema, migration, CLI runner, RSS implementation
> - [[run-log-2026-03]] — M3–M5 (digest tuning, RSS fixes, HN/arXiv/Reddit adapters, FIF-043 gate PASS, project DONE)

---

## 2026-05-28 — Pipeline decommissioned (operator request)

Operator directed that the X/feed Telegram digests are no longer useful and asked to retire the entire FIF pipeline (referred to it as "x-feed-intel" — confirmed as this project; the standalone `~/openclaw/x-feed-intel` predecessor repo in `related_projects` was already dormant with no live service). All live FIF launchd jobs were `disable`d + `bootout`'d in the GUI domain (`gui/$(id -u)`), across **both generations**:

- `ai.openclaw.fif.capture` — RSS / X bookmarks / YouTube / HN / arXiv → SQLite
- `ai.openclaw.fif.attention` — scored items into attention tiers → Telegram digest delivery
- `ai.openclaw.fif.feedback` — was live (PID 784); Telegram feedback listener
- `com.tess.v2.fif-capture`, `com.tess.v2.fif-attention`, `com.tess.v2.fif-feedback-health` — tess-v2 dispatch generation of the same functions

**Effect:** no new feed items will be captured and **no feed Telegram digests will be sent**. The existing `_openclaw/inbox/` backlog (158 items at decommission) is now static; the feed-pipeline skill still works against what's already there.

**Scope:** stop + disable only. Plists in `~/Library/LaunchAgents/`, the repo at `~/openclaw/feed-intel-framework`, and FIF credentials (`~/.config/fif/env.sh`) were all **left in place** — reversible via `launchctl enable gui/$(id -u)/<label>` + bootstrap. Project already `phase: DONE`; not moved to Archived/ (operator chose keep-files). Disable overrides persist across reboot/login (verified in `launchctl print-disabled`). The FIF pause flag (`~/.config/fif/pause`) is a softer alternative but `disable` is the stronger, persistent stop.

**Note:** Mission Control dashboard health panel will now flag these services as down — expected, not a fault.

**Tests:** None — operational change, no code modified.
