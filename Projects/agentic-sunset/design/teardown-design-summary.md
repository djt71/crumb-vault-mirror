---
type: design-summary
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
source: design/teardown-design.md
source_updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - design
  - summary
  - decommission
---

# Teardown Design — Summary

**Inventory (design/service-inventory.md):** 26 scheduled items investigated live. **SCRAP 15** (Hermes gateway, llama-server, Ollama [verified vestigial], bridge watcher, all ai.openclaw.* jobs, telemetry-rollup, all 5 com.tess.v2.* duplicate contracts, broken apple-snapshot, stale crontab line). **KEEP 11** under one `com.crumb.*` generation: plumbing ×6 (vault-backup, backup-status, drive-sync, vault-gc, simplified vault-health, system-stats) + dashboard/publishing ×5 (dashboard, cloudflared, vault-web, vault-rebuild, qmd-index — vault-web turned out to be a separate Quartz publishing stack, kept per operator decision).

**Sequence:** A pre-flight (pause healthchecks.io check FIRST; snapshot restore state; verify drive-sync stale-source risk) → B daemon teardown (bootout + plists retired to git-tracked archive) → C plumbing consolidation (no-backup-gap constraint; fix `/Users/tess/` drive-sync path + remove crontab duplicate; relocate cron-lib.sh; relabel com.tess.* keepers) → D runtime archive (README-ARCHIVED breadcrumbs; reboot resurrection test) → E upstream migration → F vault surgery (CLAUDE.md diff operator-approved; archive `_openclaw/` sparing pipeline.db + dashboard-read paths) → G closeouts + 7-day soak.

**Upstream:** daily-attention → scheduled Claude agent writing the same `_system/daily/` artifact (dashboard panel unaffected); awareness/health-ping dropped (pull-based alerting: dashboard + vault-check); feed intel → Claude.AI on demand; Telegram → push notifications/Gmail.

**Key risks:** drive-sync may currently sync the *stale* `/Users/tess/crumb-vault` copy to Google Drive/NotebookLM (verify Phase A, fix Phase C); tess-user LaunchAgents need sudo check; healthchecks must be paused before health-ping stops.

**Reversibility:** everything disable+archive; plists git-tracked; repos/models untouched; checks paused not deleted.

**Closeouts:** tess-v2 → DONE (platform absorption; 23 durable patterns already extracted), tess-danny-migration → DONE (P7 superseded, XD-026), mission-control → paused/kept.
