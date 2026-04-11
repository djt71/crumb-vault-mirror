---
type: reference
status: active
domain: software
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# Infrastructure Reference

Hostnames, ports, services, credentials, and health checks for the Crumb/Tess system.

**Architecture source:** [[04-deployment]]

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
| `tess` | Operator primary | Owns vault. Runs Crumb sessions. Hosts most LaunchAgents. |
| `openclaw` | Service account | Runs OpenClaw gateway (LaunchDaemon). Dedicated user for Tess isolation. |
| `danny` | Apple data owner | Personal macOS account. Runs Apple snapshot LaunchAgent. Must be logged in for Apple integrations. |

---

## Services

**Infrastructure (always-on):**

| Label | Type | User | Schedule | Purpose | Health Check |
|-------|------|------|----------|---------|-------------|
| `ai.openclaw.gateway` | LaunchDaemon | openclaw | Always-on | OpenClaw gateway (Tess runtime) | `nc -z -w3 127.0.0.1 18789` |
| `ai.openclaw.bridge.watcher` | LaunchAgent | tess | KeepAlive | kqueue watcher → bridge dispatch (Python) | `launchctl print gui/$(id -u)/ai.openclaw.bridge.watcher` |
| `com.tess.llama-server` | LaunchAgent | tess | KeepAlive | Local Nemotron model host (Ollama) | `curl -s 127.0.0.1:11434/api/tags` |
| `com.crumb.dashboard` | LaunchAgent | tess | KeepAlive | Mission Control HTTP server | Check dashboard HTTP /health |
| `com.crumb.vault-web` | LaunchAgent | tess | KeepAlive | Quartz v4 static site for mobile vault access | Check served HTTP |
| `com.crumb.cloudflared` | LaunchAgent | tess | KeepAlive | Cloudflare tunnel → dashboard (remote access) | `launchctl print gui/$(id -u)/com.crumb.cloudflared` |

**Tess-v2 operational services (`com.tess.v2.*`, managed by `tess-v2/project-state.yaml`, 14 services):**

| Label | Schedule | Purpose |
|-------|----------|---------|
| `com.tess.v2.health-ping` | Every 900s | Dead man's switch heartbeat |
| `com.tess.v2.awareness-check` | Every 1800s | Awareness check (Telegram) |
| `com.tess.v2.vault-health` | 2:00 AM daily | Nightly vault integrity check |
| `com.tess.v2.vault-gc` | Pre-dawn daily | Vault garbage collection |
| `com.tess.v2.backup-status` | Interval | Backup state monitoring |
| `com.tess.v2.daily-attention` | 6:30 AM daily | Daily attention planning |
| `com.tess.v2.overnight-research` | 11:00 PM daily | Scheduled research dispatch |
| `com.tess.v2.fif-capture` | Interval | Feed-intel capture |
| `com.tess.v2.fif-attention` | Interval | Feed-intel attention scan |
| `com.tess.v2.fif-feedback-health` | Interval | Feed-intel feedback health check |
| `com.tess.v2.scout-pipeline` | Interval | Opportunity Scout daily pipeline |
| `com.tess.v2.scout-feedback-health` | Interval | Scout feedback health |
| `com.tess.v2.scout-weekly-heartbeat` | Weekly | Scout weekly heartbeat |
| `com.tess.v2.connections-brainstorm` | Interval | Connections brainstorm dispatch |

**Apple and cross-user services:**

| Label | Type | User | Schedule | Purpose |
|-------|------|------|----------|---------|
| `com.crumb.apple-snapshot` | LaunchAgent | danny | Every 1800s (waking) | Apple data snapshots to `_openclaw/state/` |
| `com.crumb.drive-sync` | LaunchAgent | danny | 5:00 AM daily | Sync operator/architecture docs to Google Drive for NotebookLM |

**Legacy `ai.openclaw.*`:** `fif.capture/feedback/attention`, `health-ping`, `awareness-check`, `daily-attention`, `overnight-research`, `vault-health` — being migrated into `com.tess.v2.*` equivalents. Email triage (both namespaces) was shut down 2026-04-10 (TV2-036/037 cancelled). The authoritative service set is managed via `Projects/tess-v2/project-state.yaml` `services:` field.

### Plist Locations

| Location | Services |
|----------|----------|
| `/Library/LaunchDaemons/` | `ai.openclaw.gateway` |
| `~/Library/LaunchAgents/` (tess) | All `ai.openclaw.*` agents, `com.crumb.*` agents |
| `~/Library/LaunchAgents/` (danny) | `com.crumb.apple-snapshot` |
| `_openclaw/staging/m1/` | Milestone 1 staging plists |
| `_openclaw/staging/m2/` | Milestone 2 staging plists |

### Service Management Commands

```bash
# Gateway (LaunchDaemon — uses system/ domain, requires sudo)
sudo launchctl bootout system/ai.openclaw.gateway          # stop
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist  # start
sudo launchctl print system/ai.openclaw.gateway             # status

# LaunchAgents (gui/ domain — no sudo needed)
launchctl bootout gui/$(id -u)/ai.openclaw.bridge.watcher     # stop
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/ai.openclaw.bridge.watcher.plist  # start
launchctl print gui/$(id -u)/ai.openclaw.bridge.watcher       # status
```

**Warning:** `openclaw gateway restart` and `openclaw cron status/list` look in `gui/$UID` — they do NOT work for the LaunchDaemon in `system/`. Always use `launchctl` directly for gateway management.

**Warning:** `launchctl list` does NOT show calendar-interval jobs that exited cleanly (exit code 0). Use `launchctl print` as the authoritative status check.

---

## Network

### Ports

| Port | Service | Binding | Protocol |
|------|---------|---------|----------|
| 18789 | OpenClaw gateway | `127.0.0.1` (loopback only) | WebSocket |
| 11434 | Ollama | `127.0.0.1` (loopback only) | HTTP |
| 22 | SSH | Tailscale peers only | SSH |

### DNS

| Service | Resolution |
|---------|-----------|
| Tailscale MagicDNS | `<hostname>.tailXXXXXX.ts.net` |
| Studio direct | Tailscale IP `100.x.y.z` |
| External APIs | Public DNS (system resolver) |
| OpenClaw gateway | `127.0.0.1:18789` (no DNS needed) |

### Outbound API Endpoints

| Endpoint | Consumer | Purpose |
|----------|----------|---------|
| Anthropic API | Crumb (Claude Code) | Inference (Opus 4.6) |
| OpenRouter API | Tess Voice | Inference (Kimi K2.5 primary, Qwen 3.6 failover) |
| OpenAI API | peer-review, code-review skills | Review panels |
| Google/Gemini API | peer-review skill, Gmail ops | Review panels, Gmail |
| DeepSeek API | peer-review skill | Review panels |
| xAI/Grok API | peer-review skill | Review panels |
| Telegram API | OpenClaw gateway, LaunchAgent scripts | Tess messaging |
| GitHub | Git push/pull | Vault and project repos |
| Cloudflare | `com.crumb.cloudflared` | Outbound tunnel for dashboard remote access |

---

## Credentials

| Credential | Storage | User | Consumer | Rotation |
|-----------|---------|------|----------|----------|
| Anthropic API key | macOS Keychain | tess | Claude Code (Crumb) | Manual |
| OpenRouter API key | `~/.config/crumb/.env` | tess, openclaw | Tess Voice cloud inference | Manual |
| OpenAI API key | `~/.config/crumb/.env` | tess | peer-review, code-review | Manual |
| Google/Gemini API key | `~/.config/crumb/.env` | tess | peer-review | Manual |
| DeepSeek API key | `~/.config/crumb/.env` | tess | peer-review | Manual |
| xAI/Grok API key | `~/.config/crumb/.env` | tess | peer-review | Manual |
| GitHub PAT | macOS Keychain (credential-osxkeychain) | tess | Git push/pull | Auto-cached |
| OpenClaw token | `/Users/openclaw/.openclaw/openclaw.json` | openclaw | Gateway auth | Per config |
| Telegram bot tokens | LaunchAgent plist env vars | tess | awareness-check, health-ping, scout services | Manual |
| Cloudflare tunnel token | macOS Keychain | tess | `com.crumb.cloudflared` | Manual |
| X (Twitter) OAuth | Dynamic (Keychain refresh) | tess | feed-intel framework | Auto-refresh |

### Credential Files

| Path | Mode | Contents |
|------|------|----------|
| `~/.config/crumb/.env` | 600 | OPENROUTER_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY, DEEPSEEK_API_KEY, XAI_API_KEY |
| `/Users/openclaw/.openclaw/openclaw.json` | 600 | OpenClaw gateway config + tokens |

---

## Health Checks

### Quick Liveness Check

```bash
# Gateway
nc -z -w3 127.0.0.1 18789 && echo "OK" || echo "DOWN"

# Ollama
curl -s http://127.0.0.1:11434/api/tags | jq '.models | length' 2>/dev/null && echo "OK" || echo "DOWN"

# Bridge watcher
launchctl print gui/$(id -u)/ai.openclaw.bridge.watcher 2>/dev/null | grep -q "state = running" && echo "OK" || echo "DOWN"
```

### Do NOT use

- `lsof -nP -iTCP:18789` without sudo — false negative for openclaw-owned sockets
- `openclaw gateway restart` — wrong launchd domain for LaunchDaemon
- `openclaw cron status` — wrong launchd domain for LaunchDaemon

### Log Locations

| Log | Path | Contents |
|-----|------|----------|
| Vault-check output | `_system/logs/vault-check-output.log` | Latest vault-check run |
| Service status | `_system/logs/service-status.json` | Service liveness checks |
| System stats | `_system/logs/system-stats.json` | Resource metrics |
| LLM health | `_system/logs/llm-health.json` | LLM service health |
| Backup status | `_system/logs/backup-status.json` | Backup operation status |
| Mirror sync | `_system/logs/mirror-sync.log` | Mirror sync status |
| Ops metrics | `_system/logs/ops-metrics.json` | Operational metrics |
| AKM feedback | `_system/logs/akm-feedback.jsonl` | Active Knowledge Memory feedback |
| Bridge watcher | `_openclaw/logs/watcher.log` | Bridge watcher activity |

---

## macOS Platform Constraints

| Constraint | Impact | Mitigation |
|-----------|--------|-----------|
| `com.apple.provenance` xattr | `launchctl bootstrap` fails with "I/O error" | Strip xattr as absolute last step before bootstrap |
| `sudo -u` doesn't reset HOME | Scripts see wrong home directory | Explicitly `export HOME="/Users/<user>"` |
| `sudo -u` doesn't carry TCC | Apple data inaccessible cross-user | LaunchAgent in data-owning user's GUI domain |
| `date +%H` zero-padded | Bash arithmetic treats `08`, `09` as octal | Use `date +%-H` for arithmetic |
| openrsync ≠ GNU rsync | `--delete-excluded` destroys `.git/` | Use `--delete` + post-rsync cleanup |
| `set -o pipefail` | Breaks `if cmd | grep -q` patterns | Use `set -eu` without pipefail |
| Danny must be logged in | Apple integrations fail without GUI domain | Fast User Switching background login |
| DM pairings in-memory only | Lost on gateway restart | Re-pair via Telegram after restart |
| `npm install -g` under non-primary user | Writes to primary user's `~/.npm/` | Use `--prefix` and `npm_config_cache` |

---

## Reconciliation Notes

- Service inventory reconciled against `_openclaw/staging/m1/*.plist`, `_openclaw/staging/m2/*.plist`, and `_system/scripts/ai.openclaw.bridge.watcher.plist`
- Credential map reconciled against `_system/docs/architecture/04-deployment.md` §Credential Management
- Health checks reconciled against MEMORY.md OpenClaw operational notes
- Platform constraints reconciled against MEMORY.md macOS Multi-User Operations
- **Uncertainty:** Exact Ollama model list and version not verified at write time
