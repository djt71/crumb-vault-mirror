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
sources:
  - specification.md
  - design/service-inventory.md
  - _system/docs/solutions/infrastructure-teardown-discipline.md
---

# Teardown Design

Sequenced decommission plan. Dispositions come from `service-inventory.md`; this doc
defines order, mitigations, target architectures, and reversibility. Everything is
disable+archive — no deletion anywhere in this design.

## 1. Sequencing (phases map to IMPLEMENT tasks)

**Phase A — Pre-flight (consumer sweep prep)**
1. Snapshot current state to run-log: `launchctl list` output, `crontab -l`, plist directory listing → this is the restore path.
2. Pause/delete the healthchecks.io check (`hc-ping.com/2d06…9231`) — operator action, or via the healthchecks API key already present in the dashboard plist env. *Hard gate: nothing stops until this is done.*
3. Verify drive-sync actual behavior: which script copy ran last, what `/Users/tess/crumb-vault` contains, whether Google Drive currently receives fresh or stale vault. (Informs Phase C urgency.)

**Phase B — Daemon teardown (the big switch-off)**
Bootout + disable, then move plist files to `_system/archive/launchagents-retired/` (git-tracked = restore path):
`ai.hermes.gateway`, `com.tess.llama-server`, `ai.openclaw.bridge.watcher`, `ai.openclaw.awareness-check`, `ai.openclaw.daily-attention`, `ai.openclaw.health-ping`, `ai.openclaw.vault-health`, `com.crumb.telemetry-rollup`, `com.tess.v2.*` (×5), `com.crumb.apple-snapshot`.
Ollama via `brew services stop ollama` + disable (homebrew-managed; don't hand-move its plist).
Verify: `launchctl list` clean; ports 8080/11434 closed; no Telegram traffic for 24h.

**Phase C — Plumbing consolidation (no-backup-gap constraint)**
Execute between two successful 3 AM backup runs; verify each new label fires before the old one's slot passes:
1. Repoint `com.crumb.drive-sync` plist to `/Users/danny/crumb-vault/_system/scripts/drive-sync.sh`; remove the stale crontab line (leaves crontab empty).
2. Relabel `com.tess.vault-backup` → `com.crumb.vault-backup`, `com.tess.backup-status` → `com.crumb.backup-status` (same scripts, new plists, old plists retired).
3. Relocate `cron-lib.sh` → `_system/scripts/lib/cron-lib.sh`; create simplified `com.crumb.vault-health` (nightly, log-only — Telegram notify stripped; results surface via dashboard ops panel and session-start hook).
4. `com.crumb.vault-gc`, `com.crumb.system-stats` unchanged.

**Phase D — Runtime archive**
`README-ARCHIVED.md` breadcrumbs (what it was, why archived, restore steps, date) in: `~/.hermes/`, `~/openclaw/feed-intel-framework`, `~/openclaw/opportunity-scout`, `~/openclaw/crumb-tess-bridge`, `~/openclaw/x-feed-intel`, `~/openclaw/book-scout`, `~/crumb-apps/tess-v2`. Models stay on disk (operator decision). **Reboot test:** restart, confirm nothing scrapped resurrects and all 11 keep-labels come up.

**Phase E — Upstream migration** (§4)

**Phase F — Vault surgery (ask-first gated)**
1. CLAUDE.md: remove Bridge Dispatch section; prune Model Routing/skill references to dispatch surfaces — *operator approves diff before write*.
2. Archive `_openclaw/` → `Archived/_openclaw/` **except**: `cron-lib.sh` already relocated (C3); FIF `pipeline.db` and anything dashboard-read stays in place (see inventory keep-list). `_staging/TV2-*`, `_tess/` → `Archived/`.
3. Gitignore remaining toolchain-written files (system-stats.json churn etc.).
4. vault-check + full reconcile.

**Phase G — Closeouts + soak** (§5)

## 2. Reversibility Contract

Every step's undo: plists in `_system/archive/launchagents-retired/` (git-tracked) — `cp` back + `launchctl bootstrap`; repos/models/Hermes untouched on disk; healthchecks check paused not deleted (first 30 days). Restore runbook section embedded in each README-ARCHIVED.

## 3. Target End-State Architecture

```
KEEP (11 labels, one generation)
├─ Plumbing: com.crumb.{vault-backup 3am, backup-status 15m, drive-sync 5am,
│            vault-gc 4am, vault-health nightly, system-stats 60s}
└─ Dashboard/publishing: com.crumb.{dashboard, cloudflared, vault-web,
                          vault-rebuild 15m, qmd-index 5:30am}
GONE: all ai.*, com.tess.*, com.tess.v2.* labels; Hermes; local LLM servers; crontab empty
```

Alerting model after teardown: pull, not push — dashboard ops panel + session-start vault-check replace Telegram/hc-ping. Nothing autonomous remains that requires a dead-man's switch.

## 4. Upstream Migration Design

| Function | Replacement | Notes |
|---|---|---|
| daily-attention (30m cron + Claude API) | **Scheduled Claude Code agent** (daily, morning) running the attention-manager skill, writing the same `_system/daily/{date}.md` artifact | Dashboard attention panel keeps working unchanged. Cadence/opt-out = operator call at IMPLEMENT |
| awareness-check / health-ping | **Dropped** — nothing autonomous left to watch; backup health visible in dashboard; vault-check runs pre-commit + session start | Dead-man's switch retired with its subject |
| Feed intel / digests | **Claude.AI on demand** (web search + connectors); deep-research skill for heavy runs | Deliberately not rebuilt as automation — intake stays open, pull-based |
| Telegram notifications | Push notifications (harness) / Gmail MCP when something needs to reach Danny | |
| Research pipelines (already dead) | deep-research skill, interactive | |

## 5. Project Closeouts & Soak

- **tess-v2** → DONE. Run-log closeout: superseded by platform absorption (Claude.AI native scheduling/agents); durable patterns already extracted (`tess-v2-durable-patterns.md`, 23 Category-A patterns) — the learning is the deliverable.
- **tess-danny-migration** → DONE. P7 superseded by AS teardown (XD-026); note tess-user residual check (sudo) in closeout.
- **mission-control** → stays in Projects/, run-log note: dashboard kept running, project paused pending repurpose decision; XD table rows referencing dead upstreams swept (mark `removed`).
- **Soak (7 days):** daily checks — backup tarball fresh, drive-sync log green *from danny path*, no healthchecks email, dashboard up, no resurrection after the Phase D reboot, working tree reaches clean. End-condition: 7 green days → final compound + archive proposals to operator.

## 6. Spec Divergences (spec updated 2026-06-10)

- AS-001 (inventory) absorbed into PLAN as design work — TASK phase renumbers remaining tasks.
- Success criterion 1 label count corrected: investigation found the "dashboard stack" is 5 labels (incl. Quartz publishing: vault-web, vault-rebuild, qmd-index) and plumbing is 6 (backup-status + system-stats kept as dashboard feeders) → end state 11, not ~8.
