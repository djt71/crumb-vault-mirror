---
type: design
project: agentic-sunset
domain: software
status: active
created: 2026-06-10
updated: 2026-06-10
topics:
  - moc-crumb-operations
tags:
  - decommission
  - restore-point
---

# Restore Snapshot — pre-teardown state (AS-010)

Captured 2026-06-10, before any service change. This is the authoritative restore
reference. Plist files themselves retire to `_system/archive/launchagents-retired/`
(git-tracked) at AS-013/014; restore = copy plist back to `~/Library/LaunchAgents/` +
`launchctl bootstrap gui/$UID <plist>`.

## launchctl list (managed labels, with PIDs)

```
-    0    com.crumb.system-stats
-    0    com.tess.vault-backup
-    0    com.crumb.telemetry-rollup
-    0    com.tess.v2.vault-health
-    0    com.tess.v2.vault-gc
685  0    com.tess.llama-server
-    0    ai.openclaw.awareness-check
683  0    ai.hermes.gateway
-    0    com.crumb.vault-gc
-    0    ai.openclaw.daily-attention
-    127  com.crumb.apple-snapshot        <- chronically failing (script missing)
-    0    ai.openclaw.health-ping
684  0    com.crumb.cloudflared
-    0    com.tess.backup-status
-    0    com.tess.v2.backup-status
-    0    com.crumb.drive-sync
675  0    homebrew.mxcl.ollama
-    0    com.tess.v2.health-ping
-    0    com.crumb.vault-rebuild
-    0    com.tess.v2.daily-attention
689  0    com.crumb.vault-web
-    0    com.crumb.qmd-index
-    0    ai.openclaw.vault-health
-    0    ai.openclaw.bridge.watcher       <- PID 677 at session start; listed unloaded-PID here
```

## crontab -l

```
0 * * * * /Users/tess/crumb-vault/_system/scripts/drive-sync.sh
```

## ~/Library/LaunchAgents (26 plists)

ai.hermes.gateway · ai.openclaw.{awareness-check, bridge.watcher, daily-attention,
health-ping, vault-health} · com.crumb.{apple-snapshot, cloudflared, dashboard,
drive-sync, qmd-index, system-stats, telemetry-rollup, vault-gc, vault-rebuild,
vault-web} · com.tess.{backup-status, llama-server, vault-backup} ·
com.tess.v2.{backup-status, daily-attention, health-ping, vault-gc, vault-health} ·
homebrew.mxcl.ollama

Most plists last modified 2026-06-08 18:51 (migration re-key); apple-snapshot 03-11,
drive-sync 03-14 (pre-migration — explains stale `/Users/tess/` target).

## brew services

```
cloudflared  none   (running via com.crumb.cloudflared plist instead)
ollama       started danny ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist
unbound      none
```

## Anomalies found at snapshot time

1. **com.crumb.dashboard is NOT loaded** — plist exists, service absent from launchctl,
   port 3100 dead, tunnel serving 404. CORRECTION (session-end review of
   claude-ai-context.md): the dashboard was **deliberately stopped 2026-06-01**
   ("operator no longer wants it") — not a migration casualty. Do NOT auto-restart
   at AS-021; restart is an operator decision (stack kept for possible repurpose).
2. apple-snapshot exit 127 (known — script missing, SCRAP at AS-014).
3. bridge.watcher had PID 677 at session start; PID column empty at snapshot — it
   cycles. Disposition unchanged (SCRAP).
