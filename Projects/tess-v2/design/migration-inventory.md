---
project: tess-v2
type: design-artifact
domain: software
status: active
created: 2026-03-28
updated: 2026-03-28
task: TV2-001
---

# Tess v2 — Migration Inventory

## Overview

28 managed services/jobs inventoried across 1 LaunchDaemon, 24 tess LaunchAgents, 1 danny LaunchAgent, and 2 OpenClaw cron jobs. Plus Ollama as a third-party dependency.

**Key finding:** The spec's M5 defines 6 migration categories (heartbeats, vault gardening, feed-intel, daily attention/research, email triage, morning briefing). The actual inventory includes 10+ additional services not covered by those categories — Opportunity Scout (3 services), FIF (3 services), connections brainstorm, infrastructure services, and the bridge watcher. M5 task definitions need expansion.

## Service Inventory

### Category A: OpenClaw Gateway (REPLACE)

| Service | Trigger | Inputs | Outputs | Failure Modes | Classification |
|---------|---------|--------|---------|---------------|---------------|
| `ai.openclaw.gateway` (LaunchDaemon) | KeepAlive | Telegram msgs, Discord msgs, cron triggers | Agent responses via Telegram/Discord | Restart on crash (60s throttle) | **replace** — Hermes or custom orchestrator replaces this |

- **Config:** `/Users/openclaw/.openclaw/openclaw.json`
- **Agents:** `voice` (Haiku 4.5 primary, Ollama fallback), `mechanic` (Ollama primary, Haiku fallback)
- **Channels:** Telegram (1 bot), Discord (2 bots: tess-discord, mechanic-discord)
- **Plugins:** telegram, discord, book-scout
- **Workspaces:** `/Users/openclaw/.openclaw/workspace/` (voice), `/Users/openclaw/.openclaw/workspace-mechanic/` (mechanic)

### Category B: OpenClaw Cron Jobs (MIGRATE/REBUILD)

| Service | Schedule | Agent | Status | Classification |
|---------|----------|-------|--------|---------------|
| `pipeline-monitor` | Hourly | mechanic (isolated) | **error** | **rebuild** — replace with Tess v2 observability |
| `morning-briefing` | 07:00 daily | voice (isolated) | ok | **migrate** (TV2-037) |

### Category C: Core Tess Pipeline Services (MIGRATE)

| # | Service | Trigger | Inputs | Outputs | Status | Classification |
|---|---------|---------|--------|---------|--------|---------------|
| 1 | `ai.openclaw.awareness-check` | Every 1800s | Vault state, system health | Telegram alerts | ok (exit 0) | **migrate** — fold into heartbeat/monitoring |
| 2 | `ai.openclaw.daily-attention` | Every 1800s | Goal tracker, projects, personal context | Attention plan | ok (exit 0) | **migrate** (TV2-035) |
| 3 | `ai.openclaw.email-triage` | Every 1800s | Gmail API | Labels applied, urgent alerts via Telegram | **exit 1** (auth failure) | **migrate** (TV2-036) |
| 4 | `ai.openclaw.overnight-research` | 23:00 daily | Research queue, vault context | Research artifacts in vault | ok (exit 0) | **migrate** (TV2-035) |
| 5 | `ai.openclaw.vault-health` | 02:00 daily | Vault files | `vault-health-notes.md`, Telegram alerts | ok (exit 0) | **migrate** — fold into vault gardening (TV2-033) |
| 6 | `ai.openclaw.health-ping` | Every 900s | None | Ping to hc-ping.com | ok (exit 0) | **migrate** (TV2-032) |
| 7 | `ai.openclaw.bridge.watcher` | KeepAlive | `discord-bridge-queue/` | Dispatch processing | ok (PID 714) | **rebuild** — Tess v2 dispatch replaces bridge |

### Category D: Feed Intel Framework (MIGRATE)

| # | Service | Trigger | Inputs | Outputs | Status | Classification |
|---|---------|---------|--------|---------|--------|---------------|
| 8 | `ai.openclaw.fif.capture` | 06:05 daily | RSS feeds, X bookmarks | SQLite DB, `_openclaw/inbox/` | ok (exit 0) | **migrate** (TV2-034) |
| 9 | `ai.openclaw.fif.attention` | 07:05 daily | Captured items | Attention scores, tier classification | ok (exit 0) | **migrate** (TV2-034) |
| 10 | `ai.openclaw.fif.feedback` | KeepAlive | Telegram feedback commands | Score adjustments | ok (PID 49466, prev SIGKILL) | **migrate** (TV2-034) |

- **Working dir:** `/Users/tess/openclaw/feed-intel-framework`
- **Credentials:** `~/.config/fif/env.sh` (TwitterAPI.io, X OAuth, YouTube API, FIF Telegram bot, Anthropic)
- **Pause flag:** `~/.config/fif/pause`

### Category E: Opportunity Scout (MIGRATE — not in M5)

| # | Service | Trigger | Inputs | Outputs | Status | Classification |
|---|---------|---------|--------|---------|--------|---------------|
| 11 | `com.scout.daily-pipeline` | 07:00 daily | Job boards, Brave search | Digests via Telegram/Discord | ok (exit 0) | **migrate** — needs M5 task |
| 12 | `com.scout.feedback-poller` | KeepAlive | Telegram feedback commands | Score adjustments | ok (PID 708) | **migrate** — needs M5 task |
| 13 | `com.scout.weekly-heartbeat` | Monday 08:00 | Pipeline health data | Heartbeat via Telegram | ok (exit 0) | **migrate** — needs M5 task |

- **Working dir:** `/Users/tess/openclaw/opportunity-scout`
- **Credentials:** Anthropic, Brave Search, Scout Telegram bot, Discord webhook
- **Risk:** Medium — external API integrations, scoring logic

### Category F: Connections Brainstorm (MIGRATE — not in M5)

| # | Service | Trigger | Inputs | Outputs | Status | Classification |
|---|---------|---------|--------|---------|--------|---------------|
| 14 | `com.tess.connections-brainstorm` | Every 86400s | Networking contacts, vault context | Brainstorm artifacts | ok (exit 0) | **migrate** — needs M5 task |

### Category G: Infrastructure Services (KEEP)

These are Crumb system infrastructure, not Tess agent services. They stay regardless of Tess v2 migration.

| # | Service | Trigger | Purpose | Status | Classification |
|---|---------|---------|---------|--------|---------------|
| 15 | `com.crumb.dashboard` | KeepAlive | Dashboard API (port 3100) | ok (PID 5920) | **keep** |
| 16 | `com.crumb.cloudflared` | KeepAlive | Cloudflare tunnel | ok (PID 719) | **keep** |
| 17 | `com.crumb.service-status` | Every 60s | Service status collector | ok (exit 0) | **keep** |
| 18 | `com.crumb.system-stats` | Every 60s | System stats collector | ok (exit 0) | **keep** |
| 19 | `com.crumb.telemetry-rollup` | Every 900s | Telemetry aggregation | ok (exit 0) | **keep** — consider migrating metrics to Tess v2 observability |
| 20 | `com.crumb.qmd-index` | 05:30 daily | QMD semantic index | **exit 127** (broken) | **assess** — fix or drop |
| 21 | `com.crumb.vault-gc` | 04:00 daily | Vault garbage collection | ok (exit 0) | **keep** |
| 22 | `com.tess.backup-status` | Every 900s | Backup monitoring | ok (exit 0) | **keep** |
| 23 | `com.tess.vault-backup` | 03:00 daily | Vault backup | ok (exit 0) | **keep** |
| 24 | `com.tess.health-check` | Every 300s | Tess system health | ok (exit 0) | **rebuild** — Tess v2 observability replaces |

### Category H: Danny Domain (KEEP)

| # | Service | Trigger | Purpose | Status | Classification |
|---|---------|---------|---------|--------|---------------|
| 25 | `com.crumb.apple-snapshot` | Every 1800s | Apple data snapshots to `_openclaw/state/` | ok | **keep** — danny domain, Tess v2 consumes snapshots |

### Category I: Third-Party (KEEP/ASSESS)

| # | Service | Trigger | Purpose | Status | Classification |
|---|---------|---------|---------|--------|---------------|
| 26 | `homebrew.mxcl.ollama` | KeepAlive | Ollama LLM server | ok (PID 713) | **assess** — may be replaced by llama.cpp server |

## State Files (`_openclaw/state/`)

| File | Purpose | Producer | Consumer | Classification |
|------|---------|----------|----------|---------------|
| `apple-calendar.txt` | Apple Calendar snapshot | danny:apple-snapshot | daily-attention, morning-briefing | **keep** (danny produces) |
| `apple-notes-tess.json` | Apple Notes snapshot | danny:apple-snapshot | awareness-check | **keep** (danny produces) |
| `apple-reminders.json` | Apple Reminders snapshot | danny:apple-snapshot | daily-attention | **keep** (danny produces) |
| `capabilities.json` | Skill capability index | build-capabilities-index.sh | Tess dispatch | **migrate** to Tess v2 |
| `delivery-log.yaml` | A2A delivery audit trail | Tess deliver() | Audit/debugging | **migrate** to `~/.tess/logs/` |
| `dispatch-learning.yaml` | Dispatch outcome learning | Tess post-dispatch | Future dispatch decisions | **migrate** to Tess v2 |
| `email-send-rate.json` | Email rate limiting | email-send.sh | email-send.sh | **migrate** |
| `email-triage-auth-failed` | Auth failure flag | email-triage.sh | Health checks | **migrate** pattern to Tess v2 |
| `feedback-ledger.yaml` | Feedback audit trail | Tess agent | Audit/debugging | **migrate** to `~/.tess/logs/` |
| `tess-context.md` | Orchestration context | morning-briefing | Tess session startup | **rebuild** — Tess v2 has own context model |
| `tess-state.md` | Operational state | mechanic heartbeat | Health checks | **rebuild** — stale, replace with Tess v2 state |
| `vault-health-notes.md` | Vault health findings | vault-health.sh | Operator review | **migrate** |
| `last-run/*` (21 files) | Job timestamp tracking | Each script | Health checks, dedup | **migrate** pattern |
| `gates/*` (6 files) | Phase transition docs | Manual/session | Audit | **drop** — Tess v2 has contract-based gates |
| `account-prep/` | Customer intel staging | account-prep pipeline | Operator | **keep** (not Tess-specific) |
| `approvals/` | Approval tracking | approval system | Tess dispatch | **migrate** to Tess v2 escalation |
| `discord-bridge-queue/` | Bridge dispatch queue | Crumb sessions | bridge-watcher | **drop** — replaced by Tess v2 dispatch |

## Data Stores (`_openclaw/data/`)

| Store | Type | Size | Classification |
|-------|------|------|---------------|
| `attention-replay.db` | SQLite | 135KB | **migrate** — attention history |
| `attention-scores.json` | JSON | 766B | **migrate** — current scores |
| `attention-schema.sql` | SQL | 2.6KB | **migrate** — schema definition |
| `scout-digests/` | Markdown | 12 files | **migrate** — with Scout service |
| `sidecar/` | JSON | 16 files | **assess** — purpose unclear |

## Credential Inventory

| Credential | Type | Used By | Migration Path |
|------------|------|---------|---------------|
| Anthropic API key | API key | Gateway, FIF, Scout, scripts | Keychain → env injection per §10b.3 |
| OpenAI API key | API key | Memory search embeddings | Keychain → env injection |
| Tess Telegram bot token | Bot token | Awareness, email triage, vault health, gateway | Keychain → env injection |
| FIF Telegram bot token | Bot token | FIF feedback listener | Keychain → env injection |
| Scout Telegram bot token | Bot token | Scout pipeline | Keychain → env injection |
| Discord bot tokens (×2) | Bot token | Gateway tess-discord, mechanic-discord | Keychain → env injection |
| Discord webhooks (×5) | Webhook URL | Morning briefing, mechanic, scout, approvals, audit | Config file (not secret) |
| Perplexity API key | API key | Web search tool | Keychain → env injection |
| Brave Search API key | API key | Scout pipeline | Keychain → env injection |
| TwitterAPI.io key | API key | FIF X capture | Keychain → env injection |
| X OAuth client/secret | OAuth | FIF curated feed | Keychain (refresh token already there) |
| YouTube API key | API key | FIF YouTube capture | Keychain → env injection |
| Gemini API key | API key | Peer review / multi-model | Keychain → env injection |
| DeepSeek API key | API key | Peer review / multi-model | Keychain → env injection |
| XAI API key | API key | Peer review / multi-model | Keychain → env injection |
| Mistral API key | API key | Peer review / multi-model | Keychain → env injection |
| Lucid API key | API key | Diagram generation | Keychain → env injection |
| Healthchecks API key | API key | Dashboard health panel | Keychain → env injection |
| HC ping URL | URL | Dead man's switch | Config file |
| Gateway auth password | Password | Gateway HTTP auth | Drops with gateway |
| Bridge secret | Shared secret | Crumb-Tess bridge | Drops with bridge |
| Book Scout API key | API key | Book Scout plugin | Keychain → env injection |
| `/Users/openclaw/.openclaw/credentials/` | Unknown (3 items) | Permission denied | **Investigate** — need sudo access |

**Total:** 22+ distinct credentials, currently scattered across plists, env files, and JSON configs. Tess v2 consolidates to Keychain per §10b.3.

## Current Failure Modes

| Service | Issue | Impact |
|---------|-------|--------|
| `email-triage` | Google OAuth auth failure (flag file exists) | Email not being triaged |
| `pipeline-monitor` (cron) | Error status | Hourly health monitoring broken |
| `qmd-index` | Exit 127 (binary not found) | Semantic search index stale |
| `fif.feedback` | Previous SIGKILL (recovered) | Intermittent — watch for recurrence |
| `tess-state.md` | All fields show "never"/"unknown" | Mechanic heartbeat not writing state |
| Telegram groups | groupAllowFrom empty | All group messages silently dropped |

## Classification Summary

| Classification | Count | Services |
|---------------|-------|----------|
| **migrate** | 14 | Core pipeline (6), FIF (3), Scout (3), connections brainstorm (1), morning briefing cron (1) |
| **rebuild** | 3 | Bridge watcher, pipeline-monitor cron, tess-health-check |
| **replace** | 1 | OpenClaw gateway |
| **keep** | 9 | Infrastructure services (7), apple-snapshot, Ollama |
| **assess** | 2 | qmd-index (broken), Ollama (may change) |
| **drop** | 2 | Gateway auth, bridge dispatch queue |

## M5 Impact Assessment

The spec's M5 defines 6 migration service categories:
1. Heartbeats (TV2-032) — maps to health-ping, awareness-check
2. Vault gardening (TV2-033) — maps to vault-health
3. Feed-intel (TV2-034) — maps to FIF capture/attention/feedback
4. Daily attention + research (TV2-035) — maps to daily-attention, overnight-research
5. Email triage (TV2-036) — maps to email-triage
6. Morning briefing (TV2-037) — maps to morning-briefing cron

**Services NOT covered by M5 categories:**
- Opportunity Scout (3 services) — significant pipeline with external APIs
- Connections brainstorm (1 service) — daily networking pipeline
- Bridge watcher — rebuild as Tess v2 dispatch (may be covered by TV2-031)

**Recommendation:** Add 2 migration tasks to M5:
- TV2-043: Migrate Opportunity Scout (3 services, medium risk)
- TV2-044: Migrate connections brainstorm (1 service, low risk)

Bridge watcher replacement is implicitly covered by TV2-031 (dispatch infrastructure) but should be explicitly noted.
