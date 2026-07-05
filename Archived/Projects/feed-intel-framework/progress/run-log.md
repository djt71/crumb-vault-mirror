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

## 2026-07-05 — Final entry: archived; concept moves to Claude Cowork

**Context:** Mission-layer session. Operator: FIF is "another project moving to cowork" — good idea, poor execution, scout precedent. Third concept-survives-implementation exit of the day; the now-promoted [[handoff-note-at-archival]] pattern applied as standard procedure.

**Disposition:**
- Durable extract: `_system/docs/cowork-feed-handoff.md` — failure analysis (machinery class, delivery-consumption mismatch, routing to the doomed `_openclaw/inbox/`), surviving assets (14-feed roster verified zero-drift against operational config at archival; the tuned triage rubric extracted from `src/triage/index.ts` incl. impact test, 25/day budget, 15% HIGH cap, domain-diversity rule, high/high/capture routing bar, semantic dedup; threshold-delivery discipline; routing design docs), and reboot constraints.
- External teardown (operator-approved, keep-repos option explicitly considered and declined — Cowork reads the vault, not dead codebases): `~/openclaw/feed-intel-framework` (incl. pipeline.db corpus ×5 copies, static since 05-28) and predecessor `~/openclaw/x-feed-intel` deleted — independent git histories destroyed, accepted per scout precedent; `~/.config/fif/` (env.sh + run.sh) deleted. X OAuth revocation remains an operator to-do (revocation-candidates list). FIF plists verified already absent (earlier sweep), no disable overrides remain.
- Services were stopped + disabled 2026-05-28; nothing was live at archival. Project was `phase: DONE` (Phase 1 gate-passed 2026-03-26) — this archives a *completed* project whose concept outlived its delivery mechanism; M6/M7 (Phase 2) die unstarted by design.

**Compound:** Third evidence instance for [[handoff-note-at-archival]] (evidence list updated in the solutions doc). New sub-observation captured in the handoff itself: **capture without a consuming practice is deferred deletion** — FIF's auto-routing bar filled an inbox nobody processed; the 158-item backlog was discarded wholesale at inbox consolidation. Sibling of the attention-manager lesson (a daily artifact behind human ceremony dies); both are consumption-side failures, not capture-side. Hold as observation pair — promote if a third capture-vs-consumption case appears.

**Model routing:** Fable 5 main session; no delegation.
