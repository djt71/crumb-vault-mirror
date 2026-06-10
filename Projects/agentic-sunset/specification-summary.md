---
type: specification-summary
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: specification.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - specification
  - decommission
  - summary
---

# agentic-sunset — Specification Summary

**Problem:** The self-built agentic layer (Tess v2, Hermes gateway, OpenClaw bridge, local LLMs) accumulated heavy maintenance gravity, drifted from Crumb's original intent, and produced zero revenue. ~90% of its function is now native in Claude.AI / Claude Code. Decommission it; return Crumb to its interactive, vault-backed core.

**Operator decisions (2026-06-10):** dashboard stack (dashboard/vault-web/cloudflared) stays for possible repurposing; everything else disable+archive (never delete); plumbing (backup, drive-sync, vault-gc/health) kept but consolidated to one clean label generation; full four-phase project.

**Approach:** Inventory-driven teardown governed by `infrastructure-teardown-discipline.md` — one service-inventory table (AS-001) records a disposition and consumer graph for all 25+ launchd labels across three legacy generations; subsequent tasks apply it mechanically. Producers and their watchers are swept together to prevent false-signal zombies. Useful functions (daily attention, digests, alerting) migrate upstream to scheduled Claude agents / Claude.AI / push notifications.

**Tasks:** AS-001 inventory → AS-002 disable daemons → AS-003 archive runtimes → AS-004 plumbing consolidation → AS-005 upstream migration → AS-006 vault/CLAUDE.md surgery (ask-first gated) → AS-007 project closeouts (tess-v2, tess-danny-migration P7 superseded, mission-control paused) → AS-008 skills/memory cleanup → AS-009 7-day soak + close.

**Success:** zero `ai.openclaw.*`/`ai.hermes.*`/`com.tess.*` labels loaded; no false alerts for 7 days; backup coverage never lapses; upstream replacements live or explicitly declined; vault/memory references cleaned; every step reversible.

**Supersedes:** tess-danny-migration P7. **Known bugs folded in:** stale `/Users/tess/...` crontab path, drive-sync duplicate scheduling, apple-snapshot exit-127.
