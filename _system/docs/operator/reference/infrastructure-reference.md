---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-07-05
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Infrastructure Reference

Hostnames, ports, services, credentials, and health checks for the Crumb system.

**Architecture source:** [[04-deployment]]

**2026-07-05 rebuild note:** This doc was last updated 2026-04-11, before the agentic-sunset decommission (mid-June 2026) removed the Tess/OpenClaw runtime layer entirely. All `ai.openclaw.*` and `com.tess.v2.*` launchd services are gone from disk (verified: no plists in `~/Library/LaunchAgents/` or `/Library/LaunchDaemons/`, nothing in `launchctl list`, Ollama on :11434 unreachable). The live service set is now exclusively `com.crumb.*`. This rebuild is grounded directly in `ls ~/Library/LaunchAgents/com.crumb.*`, each plist's contents, and `launchctl list` — not inherited from the prior doc.

---

## Host

| Property | Value |
|----------|-------|
| Machine | Mac Studio M3 Ultra |
| RAM | 96 GB |
| Storage | 1 TB SSD |
| OS | macOS 15+ |
| Network | Tailscale mesh (WireGuard), no public internet exposure |

### User Accounts

| User | Role | Purpose |
|------|------|---------|
| `danny` | Sole active operator account | Owns vault, runs Crumb sessions, hosts all `com.crumb.*` LaunchAgents. |
| `tess` | Historical service account | Account still exists on the system (`dscl . -list /Users`) but its LaunchAgents are fully decommissioned — no plists remain. Retained per disable+archive ethos, not deleted. |
| `openclaw` | Historical service account | Same status as `tess` — account exists, `ai.openclaw.gateway` LaunchDaemon and all other `ai.openclaw.*` agents are gone from disk. |

**Note:** The prior multi-user architecture (tess owns vault / openclaw runs gateway / danny handles Apple integrations) no longer reflects reality. All 11 live `com.crumb.*` services run under `danny`.

---

## Services

**Live service set — verified against `ls ~/Library/LaunchAgents/com.crumb.*` (11 plists) and `launchctl list` (10 loaded, 1 intentionally unloaded) on 2026-07-05:**

| Label | Schedule | Purpose | Program | Logs |
|-------|----------|---------|---------|------|
| `com.crumb.backup-status` | `StartInterval` 900s + `RunAtLoad` | Writes backup status JSON for dashboard consumption (checks iCloud vault backup + Time Machine) | `bash _system/scripts/backup-status.sh` | `/tmp/backup-status.log`, `/tmp/backup-status.err` (writes `_system/logs/backup-status.json`) |
| `com.crumb.cloudflared` | `RunAtLoad` + `KeepAlive` | Cloudflare tunnel, outbound-only, exposes dashboard at `mc.crumbos.dev` → `localhost:3100` | `cloudflared tunnel run crumb-dashboard` | `/tmp/cloudflared-stdout.log`, `/tmp/cloudflared-stderr.log` |
| `com.crumb.dashboard` | `RunAtLoad` + `KeepAlive` (when loaded) | Mission Control HTTP API server, port 3100 | `node .../crumb-dashboard/packages/api/dist/server.js` | `/tmp/crumb-dashboard-stdout.log`, `/tmp/crumb-dashboard-stderr.log`, `/tmp/crumb-dashboard.log` |
| `com.crumb.drive-sync` | `StartCalendarInterval` 5:00 AM daily | Syncs operator/architecture docs to Google Drive (NotebookLM `.txt` + Perplexity Computer `.md`), one-way push via rclone | `bash _system/scripts/drive-sync.sh` | `/tmp/drive-sync-stdout.log`, `/tmp/drive-sync-stderr.log` (script's own log: `/tmp/drive-sync.log`) |
| `com.crumb.qmd-index` | `StartCalendarInterval` 5:30 AM daily | Rebuilds qmd search index + embeddings | `bash -c "qmd update && qmd embed"` | `/tmp/qmd-index-stdout.log`, `/tmp/qmd-index-stderr.log` |
| `com.crumb.system-stats` | `StartInterval` 60s + `RunAtLoad` | Resource metrics snapshot | `_system/scripts/system-stats.sh` | `_system/logs/system-stats.json`, stderr `/tmp/crumb-system-stats.err` |
| `com.crumb.vault-backup` | `StartCalendarInterval` 3:00 AM daily | Vault backup tarball → iCloud (`~/Library/Mobile Documents/.../crumb-backups`) | `bash _system/scripts/vault-backup.sh` | `/tmp/vault-backup.log`, `/tmp/vault-backup.err` |
| `com.crumb.vault-gc` | `StartCalendarInterval` 4:00 AM daily | Vault garbage collection — purges aged transient files, truncates growing logs (TTL policies in script) | `_system/scripts/vault-gc.sh` | `_system/logs/vault-gc.log` (stdout+stderr combined) |
| `com.crumb.vault-health` | `StartCalendarInterval` 2:00 AM daily | Nightly vault content-health scan. Comment in plist: "agentic-sunset AS-019: log-only successor to `ai.openclaw.vault-health`" | `bash _system/scripts/vault-health.sh` | `/tmp/vault-health.log`, `/tmp/vault-health.err` (script also writes `_system/logs/vault-health.log` + `vault-health-notes.md`) |
| `com.crumb.vault-rebuild` | `StartInterval` 900s (no RunAtLoad) | Rebuilds Quartz static site from vault content | `bash ~/quartz-vault/rebuild.sh` | `~/quartz-vault/logs/rebuild-launchd-stdout.log`, `-stderr.log` |
| `com.crumb.vault-web` | `RunAtLoad` + `KeepAlive` | Serves Quartz v4 static site for mobile vault access, port 8843 | `node .../serve/build/main.js ~/quartz-vault/public -l 8843 --no-clipboard` | `~/quartz-vault/logs/serve-stdout.log`, `-stderr.log` |

**Parked service:** `com.crumb.dashboard` exists on disk (plist present, well-formed) but is **intentionally unloaded** — confirmed absent from `launchctl list` output on 2026-07-05. This follows the mission-control project pausing 2026-06-14 (dashboard stack kept for reversibility, deliberately stopped rather than torn down). `com.crumb.cloudflared` is still loaded and tunneling to `localhost:3100`, so the tunnel is currently live but has no backend to answer it — expect the public hostname to fail/502 until `com.crumb.dashboard` is reloaded.

**Hygiene flag (dashboard plist) — RESOLVED 2026-07-06:** `HEALTHCHECKS_API_KEY` was hardcoded in cleartext in `com.crumb.dashboard.plist`'s `EnvironmentVariables`. Stripped from the plist 2026-07-06 (operator decision; healthchecks has no live consumer — the service was removed from the monitoring stack); key revoked at healthchecks.io by operator same day. If the dashboard is revived and needs healthchecks again, issue a fresh key and store per the Keychain-not-env convention.

**Fully decommissioned namespaces (verified gone, not just moved):**
- `ai.openclaw.gateway` (LaunchDaemon), `ai.openclaw.bridge.watcher`, `ai.openclaw.awareness-check`, `ai.openclaw.health-ping`, `ai.openclaw.daily-attention`, `ai.openclaw.vault-health` — no plists remain in `~/Library/LaunchAgents/` or `/Library/LaunchDaemons/`; `launchctl list` returns nothing for `openclaw`.
- `com.tess.v2.*` (health-ping, vault-health, vault-gc, backup-status, daily-attention) — project `tess-v2` closed `phase: DONE` 2026-06-14 (agentic-sunset AS-030); all labels scrapped and reboot-verified absent (AS-021).
- `com.tess.llama-server` (Ollama-hosted local model) — port 11434 unreachable, no `ollama` process running.
- Everything under the 2026-05/06 teardown sweep (FIF capture/attention/feedback-health, Opportunity Scout services, `com.crumb.service-status`, `com.tess.health-check`, overnight-research, connections-brainstorm) — still gone, unchanged from prior doc.

**Not carried forward — retired:** The prior doc listed `com.crumb.apple-snapshot` (danny, Apple data snapshots every 1800s). No plist by that name exists anywhere on disk as of 2026-07-05 (checked `~/Library/LaunchAgents/`, filesystem-wide for the pattern). **Operator decision 2026-07-06: retired** — its output target (`_openclaw/state/`) was deleted with the agentic-sunset decommission; not rebuilt.

**`daily-attention`:** Both the `ai.openclaw.daily-attention` and `com.tess.v2.daily-attention` scheduled jobs are gone, and no `com.crumb.daily-attention` was created to replace them. The `attention-manager` skill was retired 2026-07-05 — the attention-planning concept moves to Claude Cowork (rented runtime, see `_system/docs/cowork-attention-handoff.md`); no vault-side service exists or is planned.

### Plist Locations

| Location | Services |
|----------|----------|
| `~/Library/LaunchAgents/` (danny) | All 11 `com.crumb.*` agents |
| `/Library/LaunchDaemons/` | None currently (ai.openclaw.gateway removed) |

### Service Management Commands

```bash
# LaunchAgents (gui/ domain — no sudo needed)
launchctl bootout gui/$(id -u)/com.crumb.<label>     # stop
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.crumb.<label>.plist  # start
launchctl print gui/$(id -u)/com.crumb.<label>       # status
launchctl list | grep com.crumb                      # quick loaded-set check
```

**Warning:** `launchctl list` does NOT show calendar-interval jobs that exited cleanly (exit code 0) between polls. Use `launchctl print gui/$(id -u)/<label>` for authoritative status, especially for the five `StartCalendarInterval` jobs above (drive-sync, qmd-index, vault-backup, vault-gc, vault-health).

---

## Network

### Ports

| Port | Service | Binding | Protocol |
|------|---------|---------|----------|
| 3100 | `com.crumb.dashboard` (parked) | `127.0.0.1` | HTTP |
| 8843 | `com.crumb.vault-web` | Local (serve) | HTTP |
| 22 | SSH | Tailscale peers only | SSH |

### DNS

| Service | Resolution |
|---------|-----------|
| Tailscale MagicDNS | `<hostname>.tailXXXXXX.ts.net` |
| Studio direct | Tailscale IP `100.x.y.z` |
| External APIs | Public DNS (system resolver) |
| Dashboard (public) | `mc.crumbos.dev` → Cloudflare tunnel → `localhost:3100` (currently backend-down, see Services above) |

### Outbound API Endpoints

| Endpoint | Consumer | Purpose |
|----------|----------|---------|
| Anthropic API | Crumb (Claude Code) | Inference |
| OpenAI API | peer-review, code-review, deliberation dispatch agents | Review panels |
| Google/Gemini API | peer-review, deliberation dispatch agents | Review panels |
| DeepSeek API | peer-review, deliberation dispatch agents | Review panels |
| xAI/Grok API | peer-review, deliberation dispatch agents (`.claude/agents/*-dispatch.md`, `.claude/skills/peer-review/SKILL.md`) | Review panels |
| Google Workspace OAuth (workspace-mcp) | Gmail/Calendar/Drive/Contacts MCP tools | Live GWS integration — token store at `~/.google_workspace_mcp/credentials` and `~/.config/gws` (recently touched, actively used) |
| GitHub | Git push/pull | Vault and project repos, via `gh auth git-credential` (see Credentials) |
| Cloudflare | `com.crumb.cloudflared` | Outbound tunnel for dashboard remote access |

**Removed:** OpenRouter (Tess Voice inference) and Telegram Bot API (Tess/OpenClaw messaging) — no live script or plist references either endpoint; both were consumers under the now-dead Tess/OpenClaw stack. See rotate-credentials doc, revocation-candidates section.

---

## Credentials

See [[rotate-credentials]] for the full credential table and rotation procedures. Summary of what changed: OpenRouter, Telegram bot tokens, and X/Twitter OAuth no longer have live consumers (moved to revocation-candidates); Google Workspace OAuth added as a live, previously-undocumented consumer; Mistral and Lucid API keys (present in `~/.config/crumb/.env` but not previously documented) also had no live script/skill consumer found — revoked at both providers 2026-07-06; lines removed from `.env`.

---

## Health Checks

### Quick Liveness Check

```bash
# Dashboard (when loaded)
curl -s -m 2 http://127.0.0.1:3100/health && echo "OK" || echo "DOWN"

# Vault-web
curl -s -m 2 http://127.0.0.1:8843 -o /dev/null -w "%{http_code}\n"

# Loaded com.crumb.* services
launchctl list | grep com.crumb
```

### Do NOT use

- `openclaw gateway restart` / `openclaw cron status` — these commands reference infrastructure that no longer exists (ai.openclaw.gateway is gone). Use `launchctl` directly.
- Assuming `com.crumb.dashboard` is reachable because `com.crumb.cloudflared` is loaded — the tunnel loads independently of its backend.

### Log Locations

| Log | Path | Contents |
|-----|------|----------|
| Vault-check output | `_system/logs/vault-check-output.log` | Latest vault-check run |
| System stats | `_system/logs/system-stats.json` | Resource metrics (`com.crumb.system-stats`) |
| Backup status | `_system/logs/backup-status.json` | Backup operation status (`com.crumb.backup-status`) |
| Vault GC | `_system/logs/vault-gc.log` | `com.crumb.vault-gc` stdout+stderr |
| Vault health | `_system/logs/vault-health.log` + `vault-health-notes.md` | Nightly content-health scan (`com.crumb.vault-health`) |
| Vault backup marker | `_system/logs/vault-backup-last.json` | Written by `vault-backup.sh`, read by `backup-status.sh` as an iCloud-listing fallback |
| Drive sync | `/tmp/drive-sync.log` | rclone sync status |
| Quartz rebuild | `~/quartz-vault/logs/rebuild-launchd-*.log` | `com.crumb.vault-rebuild` |
| Quartz serve | `~/quartz-vault/logs/serve-*.log` | `com.crumb.vault-web` |

**Note:** Most `com.crumb.*` LaunchAgents log to `/tmp/` rather than `_system/logs/`, which means logs do not survive reboot and are not vault-backed. Only `vault-gc`, `vault-health` (partial), `system-stats`, and `backup-status` write into `_system/logs/`.

---

## macOS Platform Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| `com.apple.provenance` xattr | `launchctl bootstrap` fails with "I/O error" | Strip xattr as absolute last step before bootstrap |
| `date +%H` zero-padded | Bash arithmetic treats `08`, `09` as octal | Use `date +%-H` for arithmetic |
| openrsync ≠ GNU rsync | `--delete-excluded` destroys `.git/` | Use `--delete` + post-rsync cleanup |
| `set -o pipefail` | Breaks `if cmd | grep -q` patterns | Use `set -eu` without pipefail |
| `tmutil latestbackup` can return empty right after boot | Time Machine status false-negative | `backup-status.sh` falls back to `tmutil listbackups | tail -1` |
| TCC blocks `~/Library/Mobile Documents` under launchd | Direct iCloud directory listing fails silently | `backup-status.sh` falls back to the `vault-backup-last.json` marker written by `vault-backup.sh` |

**Removed (were multi-user-specific, no longer apply with single-user `danny` operation):** `sudo -u` HOME/TCC handling, Fast User Switching for Apple integrations, DM pairing loss on gateway restart, `npm install -g` cross-user cache writes. These were artifacts of the tess/openclaw/danny three-account architecture, which is retired.

---

## Reconciliation Notes

- Service inventory reconciled directly against `ls ~/Library/LaunchAgents/com.crumb.*` (11 plists), each plist's raw contents, and `launchctl list | grep crumb` (10 loaded) — 2026-07-05.
- Confirmed `ai.openclaw.*` and `com.tess.v2.*` fully absent from disk and `launchctl list` — not inherited from prior doc's claims.
- Credential/consumer map reconciled against a grep sweep of `_system/scripts/` and `.claude/` for API key names, plus `Projects/agentic-sunset/project-state.yaml` and `Projects/tess-v2/project-state.yaml` for decommission status.
- ~~**Uncertainty:** `com.crumb.apple-snapshot`~~ — resolved 2026-07-06: operator confirmed retired (see Service Inventory note above).
- **Uncertainty:** Exact `qmd` version/config and Ollama's full removal status (vs. simply not running) not independently verified beyond the port-11434 unreachable check.
