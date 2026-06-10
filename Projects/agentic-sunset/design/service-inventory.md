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
  - design
  - decommission
  - inventory
---

# Service Inventory & Disposition Map

Authoritative disposition table for every launchd label, the crontab, and live daemons.
Investigated live 2026-06-10 (plists read, scripts skimmed, consumer graph traced).
Downstream tasks apply this table mechanically.

## Dispositions

`SCRAP` = bootout + disable, plist retired to `_system/archive/launchagents-retired/` ·
`KEEP-P` = keep, plumbing (consolidated `com.crumb.*` generation) ·
`KEEP-D` = keep, dashboard/publishing stack · `FIX` = keep after repair

## Inventory

| Label | Schedule | What it does | Consumers of its output | Disposition |
|---|---|---|---|---|
| ai.hermes.gateway | KeepAlive | Hermes agent gateway (Nous) | None external — Tess contracts call it | **SCRAP** |
| com.tess.llama-server | KeepAlive | llama.cpp server :8080 (Nemotron) | Hermes mechanic-agent only | **SCRAP** |
| homebrew.mxcl.ollama | KeepAlive | Ollama server :11434 | **Nothing** — vestigial (verified: zero references in active code) | **SCRAP** (brew services stop) |
| ai.openclaw.bridge.watcher | KeepAlive | kqueue dispatch daemon (Crumb↔OpenClaw bridge) | bridge-processor.js (same layer) | **SCRAP** |
| ai.openclaw.awareness-check | 30m | Outbox/feed/approvals monitor → Telegram | Telegram (Danny) | **SCRAP** |
| ai.openclaw.daily-attention | 30m | Generates `_system/daily/{date}.md` via direct Claude API (opus-4-6) | Dashboard attention panel (18h staleness) | **SCRAP** → replaced upstream (see teardown-design §4) |
| ai.openclaw.health-ping | 15m | Dead-man's switch → hc-ping.com/2d06…9231 | healthchecks.io check (server-side alert!) | **SCRAP** — *pause hc check FIRST* |
| ai.openclaw.vault-health | nightly 2am | Vault integrity scan → Telegram + state notes | Telegram; `_openclaw/state/vault-health-notes.md` | **SCRAP** → simplified com.crumb.vault-health |
| com.crumb.telemetry-rollup | 15m | ops-metrics.json + llm-health.json rollups | Dashboard ops widgets (degrade gracefully to stale badges) | **SCRAP** |
| com.tess.v2.health-ping | 15m | tess-v2 dispatch contract (dup of health-ping) | hc-ping (same check) | **SCRAP** |
| com.tess.v2.backup-status | 15m | tess-v2 contract (dup of backup-status) | backup-status.json | **SCRAP** (plain version kept) |
| com.tess.v2.daily-attention | 30m | tess-v2 contract (dup of daily-attention) | `_system/daily/` | **SCRAP** |
| com.tess.v2.vault-gc | daily 4am | tess-v2 contract (dup of vault-gc) | vault-gc.log | **SCRAP** (com.crumb.vault-gc kept) |
| com.tess.v2.vault-health | daily 2am | tess-v2 contract (dup of vault-health) | vault-health notes | **SCRAP** |
| com.crumb.apple-snapshot | 30m | **BROKEN** — target `/Users/tess/.../apple-snapshot.sh` does not exist (exit 127) | None (never runs) | **SCRAP** (broken; agentic feeder anyway) |
| com.crumb.drive-sync | daily 5am | rclone vault → Google Drive (NotebookLM/Perplexity) — **plist targets stale `/Users/tess/` path** | NotebookLM, Perplexity | **FIX** → repoint to `/Users/danny/crumb-vault/_system/scripts/drive-sync.sh` |
| *(crontab)* drive-sync | hourly | Same script via stale `/Users/tess/` path — **duplicate scheduling** | same | **SCRAP** (remove crontab line) |
| com.tess.vault-backup | daily 3am | tar.gz vault → iCloud, 30-day retention | iCloud; backup-status.json reads results | **KEEP-P** → relabel com.crumb.vault-backup |
| com.tess.backup-status | 15m | Writes `_system/logs/backup-status.json` (iCloud + TM health) | Dashboard ops panel | **KEEP-P** → relabel com.crumb.backup-status |
| com.crumb.vault-gc | daily 4am | Age-based purge + log truncation (self-contained script) | vault-gc.log | **KEEP-P** |
| *(new)* com.crumb.vault-health | nightly | Simplified vault integrity scan — log-only, **no Telegram** | `_system/logs/` (dashboard-visible) | **KEEP-P** (create; relocate cron-lib.sh → `_system/scripts/lib/`) |
| com.crumb.system-stats | 60s | CPU/mem/disk/GPU → system-stats.json | Dashboard ops panel (180s staleness) | **KEEP-D** (cheap, feeds kept panel) |
| com.crumb.dashboard | KeepAlive | Mission-control Express server :3100 | cloudflared tunnel; Danny | **KEEP-D** |
| com.crumb.cloudflared | KeepAlive | Tunnel mc.crumbos.dev → :3100 (only route) | Remote access | **KEEP-D** |
| com.crumb.vault-web | KeepAlive | Static server :8843 for Quartz site | Danny (vault publishing) | **KEEP-D** |
| com.crumb.vault-rebuild | 15m | Quartz rebuild → public/ (atomic swap) | vault-web content freshness | **KEEP-D** |
| com.crumb.qmd-index | daily 5:30am | qmd update+embed (search index) | Dashboard search API | **KEEP-D** |

**End state: 11 loaded labels** — plumbing ×6 (vault-backup, backup-status, drive-sync, vault-gc, vault-health, system-stats) + dashboard/publishing ×5 (dashboard, cloudflared, vault-web, vault-rebuild, qmd-index). Zero `ai.*`/`com.tess.*` labels.

## Consumer-Graph Sweep List (teardown discipline #2)

| Producer stopping | Watcher/consumer to sweep | Action |
|---|---|---|
| health-ping (both gens) | healthchecks.io check `2d06…9231` | **Pause/delete check BEFORE bootout** (operator or via dashboard's healthchecks API key) |
| telemetry-rollup | Dashboard ops cost/LLM widgets | Accept graceful stale badges; optional widget cleanup if dashboard repurposed |
| daily-attention | Dashboard attention panel | Replace producer upstream (writes same `_system/daily/` path) — panel keeps working |
| FIF capture (already stopped) | Dashboard intel page ← pipeline.db | DB stays on disk → frozen-but-functional. **Do not move/delete pipeline.db** |
| awareness/vault-health Telegram | Danny's Telegram | No watcher — silence is the intended outcome |
| ops-metrics.jsonl writers | llm-health-rollup (dies with telemetry-rollup) | Swept together ✓ |

## Keep-Set External Dependencies (verified)

- `vault-backup.sh`, `drive-sync.sh`, `vault-gc.sh`: fully self-contained ✓
- `vault-health.sh`: sources `_openclaw/scripts/cron-lib.sh` → **relocate lib to `_system/scripts/lib/` before archiving `_openclaw/`**
- Dashboard reads (must survive vault surgery): FIF `pipeline.db`, `_system/logs/*.json|log`, `_system/daily/`, `_inbox/attention/`, `_system/goals.md`, `Projects/*/project-state.yaml`

## Risks Found During Investigation

1. **Drive-sync stale-source risk (HIGH):** both the crontab and the plist target `/Users/tess/crumb-vault/...`. If that copy still exists, Google Drive (→ NotebookLM) may be receiving a *stale* vault. Verify which copy actually ran last (rclone log mtimes) at IMPLEMENT start; fix is Phase C.
2. **tess user LaunchAgents unreadable** without sudo — unknown residual services under the tess account (P7 scope). Needs operator-assisted check before closeout.
3. **Healthchecks alert window:** disabling health-ping before pausing the check fires a false "down" alert — sequencing enforced in Phase A.
