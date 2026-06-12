---
type: design
project: agentic-sunset
domain: software
status: active
created: 2026-06-12
updated: 2026-06-12
topics:
  - moc-crumb-operations
tags:
  - design
  - decommission
---

# Upstream Migration — Replacement Map

What the decommissioned agentic layer (OpenClaw / Hermes / Tess) did, what replaces each function, and what was deliberately dropped. Covers the 5 functions from teardown-design §4. Operator decisions captured 2026-06-12 (AS-023/AS-024).

## Replacement map

| # | Function (old) | Replacement | Status |
|---|---|---|---|
| 1 | daily-attention (30m cron + direct Claude API → `_system/daily/{date}.md`) | **On demand only — scheduled replacement DECLINED** (operator, 2026-06-12). The attention-manager skill produces the same artifact when invoked ("plan my day"). Dashboard attention panel reads whatever is current; staleness is acceptable by choice. | Decline documented |
| 2 | awareness-check / health-ping (30m/15m monitors + dead-man's switch → Telegram / healthchecks.io) | **Dropped.** Nothing autonomous remains to watch. Backup health → `backup-status.json` (dashboard ops panel); vault integrity → `com.crumb.vault-health` nightly log + session-start hook; healthchecks check `tess-mac-studio-health` paused (delete after 30-day window per reversibility contract). | Dropped with rationale |
| 3 | Feed intel / digests (FIF pipeline, x-feed-intel, scout digests) | **Claude.AI on demand** — web search + connectors; deep-research skill for heavy runs. Deliberately NOT rebuilt as automation: intake stays open and pull-based ([[feedback-feed-intel-stays-open]]). `pipeline.db` stays on disk for the dashboard intel page. | Replaced (pull model) |
| 4 | Telegram notifications (briefings, alerts via gateway bot) | **Harness push notifications + Gmail MCP** when something must reach Danny; otherwise pull (dashboard, session start). No bot, no always-on channel. | Replaced |
| 5 | Research pipelines (overnight briefs — already dead pre-sunset) | **deep-research / researcher skills, interactive.** Archived briefs remain under `_openclaw/research/` until AS-026. | Replaced |

## Parity gaps (accepted)

- **No unattended freshness:** with daily-attention declined and monitors dropped, nothing updates artifacts or raises alarms between sessions. Failure surfaces at next session start (hook) or dashboard glance. Accepted: the alerting model is pull, not push (teardown-design §3) — nothing autonomous remains that requires a dead-man's switch.
- **Briefing gap:** no morning Telegram briefing. Replacement is opening a session and asking. Operator-confirmed acceptable (AS-016 green check treated the gap as the expected state).
- **Digest cadence:** weekly scout digests and connection brainstorms have no successor; compound connections now surface via the signal-scan behavior at note creation.

## Reversal

Cadence decisions are one-line reversals: a scheduled Claude agent (or Cowork scheduled session, per AS-023 scheduler verification in run-log) can be created at any time to run attention-manager on a schedule — the skill and artifact format are unchanged. The dropped monitors' restore path is the archived plists (`_system/archive/launchagents-retired/`), per the reversibility contract.
