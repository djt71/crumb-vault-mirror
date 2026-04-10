---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-23
updated: 2026-02-26
tags:
  - operations
  - runbook
  - maintenance
---

# Tess Model Architecture — Maintenance Runbook

## 1. Architecture Overview

Two-agent OpenClaw gateway on Mac Studio M3 Ultra (96 GB):

| Agent | Model | Role | Channel |
|-------|-------|------|---------|
| `voice` | `anthropic/claude-haiku-4-5` | User-facing persona | Telegram |
| `mechanic` | `ollama/tess-mechanic:30b` | Background automation | heartbeat, cron |

Limited Mode: external health-check cron swaps voice to local model when Anthropic is down.

## 2. Key Paths

| Artifact | Location |
|----------|----------|
| OpenClaw config | `/Users/openclaw/.openclaw/openclaw.json` |
| OpenClaw workspace | `/Users/openclaw/.openclaw/workspace/` |
| Gateway logs | `/Users/openclaw/.openclaw/logs/gateway.log` |
| Gateway plist | `/Library/LaunchDaemons/ai.openclaw.gateway.plist` |
| Identity doc (SOUL.md) | `/Users/openclaw/.openclaw/workspace/SOUL.md` |
| Identity staging | `/Users/tess/crumb-vault/_openclaw/staging/SOUL.md` |
| Health-check script | `/Users/tess/crumb-vault/_system/scripts/tess-health-check.sh` |
| Health-check env | `/Users/tess/.config/tess/health-check.env` (Anthropic key only; Telegram creds in Keychain) |
| Health-check plist | `design/com.tess.health-check.plist` (install to `~/Library/LaunchAgents/`) |
| Health-check log | `/Users/tess/crumb-vault/_system/logs/health-check.log` |
| Health-check state | `/tmp/tess-health-check.state` |
| Baseline config | `design/openclaw-config-baseline.json` |
| Production config | `design/openclaw-config-production.json` (credentials redacted) |
| Modelfile | `design/Modelfile.tess-mechanic` |
| Benchmark harness | `harness/benchmark.py` |
| Integration test | `harness/integration-test.py` |

## 3. Routine Operations

### 3.1 Check Gateway Status

```bash
sudo lsof -iTCP:18789 -sTCP:LISTEN
sudo tail -20 /Users/openclaw/.openclaw/logs/gateway.log
```

### 3.1b View Gateway Logs (local time)

```bash
# v2026.2.25+: use --local-time to avoid UTC confusion during troubleshooting
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw logs --local-time --limit 20'
```

### 3.2 Restart Gateway

```bash
sudo launchctl kickstart -k "system/ai.openclaw.gateway"
sleep 5
sudo lsof -iTCP:18789 -sTCP:LISTEN
```

### 3.3 Check Ollama Status

```bash
ollama list                           # verify tess-mechanic:30b loaded
curl -s http://127.0.0.1:11434/api/tags | jq '.models[].name'
```

### 3.4 Check Health-Check State

```bash
cat /tmp/tess-health-check.state      # mode, failure count
tail -20 _system/logs/health-check.log
```

### 3.5 View Gateway Logs for Routing

```bash
# Voice route (Telegram → Haiku)
sudo grep -E "provider=anthropic.*messageChannel=telegram" /Users/openclaw/.openclaw/logs/gateway.log | tail -5

# Mechanic route (heartbeat → Ollama)
sudo grep -E "provider=ollama.*messageChannel=heartbeat" /Users/openclaw/.openclaw/logs/gateway.log | tail -5
```

## 4. Model Swap Procedure

Use this when changing the voice or mechanic model.

### 4.1 Voice Model Swap (e.g., Haiku → Sonnet)

1. **Run persona eval** against the new model using `design/design-contracts.md` rubric:
   - Minimum 5 cases per PC dimension (20+ total)
   - Hard gates: PC-1 through PC-4 must be 100%
   - Architecture invalidation: if any gate fails on both models across ≥3 cases, halt

2. **Update config:**
   ```bash
   # Edit openclaw.json — swap voice.model.primary
   sudo -u openclaw bash -c 'export HOME=/Users/openclaw && \
     jq --arg m "anthropic/claude-sonnet-4-5" \
     "(.agents.list[] | select(.id == \"voice\") | .model.primary) = \$m" \
     ~/.openclaw/openclaw.json > /tmp/oc-swap.json && \
     cp /tmp/oc-swap.json ~/.openclaw/openclaw.json'
   ```

3. **Update cost model** — recalculate monthly projection with new pricing.

4. **Restart gateway** (§3.2).

5. **Smoke test** — send Telegram message, check logs for correct model.

6. **Update vault:** `design/production-config.md`, `design/environment-pinning.md`.

### 4.2 Mechanic Model Swap (e.g., qwen3-coder → different model)

1. **Run benchmark harness:**
   ```bash
   cd Projects/tess-model-architecture
   python3 harness/benchmark.py run
   ```
   All MC gates must pass. MC-6 results documented.

2. **Create Modelfile** if context window or parameters differ.

3. **Update config** — swap `mechanic.model.primary` and `models.providers.ollama.models`.

4. **Restart gateway** (§3.2).

5. **Run integration test:**
   ```bash
   python3 harness/integration-test.py
   ```

## 5. Config Rollback

Full rollback to pre-implementation (single-agent, no Ollama):

See `design/environment-pinning.md` §4 for the complete 7-step procedure.

Quick rollback to last known good config:

```bash
# Restore pre-limited backup (if exists from health-check)
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && \
  cp ~/.openclaw/openclaw.json.pre-limited ~/.openclaw/openclaw.json'
sudo launchctl kickstart -k "system/ai.openclaw.gateway"
```

## 6. Health-Check Cron Setup

### 6.1 First-Time Installation

1. **Create env file and Keychain entries:**
   ```bash
   mkdir -p /Users/tess/.config/tess
   cp Projects/tess-model-architecture/design/health-check.env.example \
      /Users/tess/.config/tess/health-check.env
   # Edit with real ANTHROPIC_API_KEY value
   chmod 600 /Users/tess/.config/tess/health-check.env

   # Telegram credentials are shared with x-feed-intel via Keychain:
   #   security add-generic-password -a x-feed-intel -s x-feed-intel.telegram-bot-token -w "TOKEN"
   #   security add-generic-password -a x-feed-intel -s x-feed-intel.telegram-chat-id -w "CHAT_ID"
   # If x-feed-intel is already installed, these entries exist — no action needed.
   ```

2. **Install launchd plist:**
   ```bash
   cp Projects/tess-model-architecture/design/com.tess.health-check.plist \
      ~/Library/LaunchAgents/
   launchctl load ~/Library/LaunchAgents/com.tess.health-check.plist
   ```

3. **Configure sudoers** (required for config swap and gateway restart):
   ```bash
   sudo visudo -f /etc/sudoers.d/tess-health-check
   # Add:
   # tess ALL=(openclaw) NOPASSWD: /bin/bash -c export HOME=/Users/openclaw *
   # tess ALL=(root) NOPASSWD: /bin/cp * /Users/openclaw/.openclaw/openclaw.json
   # tess ALL=(root) NOPASSWD: /usr/bin/chown openclaw\:* /Users/openclaw/.openclaw/*
   # tess ALL=(root) NOPASSWD: /bin/launchctl kickstart -k system/ai.openclaw.gateway
   # tess ALL=(root) NOPASSWD: /usr/sbin/lsof -iTCP\:18789 *
   # tess ALL=(root) NOPASSWD: /bin/cp * /Users/openclaw/.openclaw/workspace/*
   # tess ALL=(root) NOPASSWD: /usr/bin/chown openclaw\:* /Users/openclaw/.openclaw/workspace/*
   ```

4. **Verify:**
   ```bash
   bash _system/scripts/tess-health-check.sh
   cat /tmp/tess-health-check.state
   cat _system/logs/health-check.log
   ```

### 6.2 Uninstall

```bash
launchctl unload ~/Library/LaunchAgents/com.tess.health-check.plist
rm ~/Library/LaunchAgents/com.tess.health-check.plist
sudo rm /etc/sudoers.d/tess-health-check
rm /Users/tess/.config/tess/health-check.env
rm /tmp/tess-health-check.state
```

## 7. Identity Document Updates

When updating SOUL.md (voice persona):

1. Edit `_openclaw/staging/SOUL.md` (vault source of truth).
2. Deploy to workspace:
   ```bash
   sudo cp /Users/tess/crumb-vault/_openclaw/staging/SOUL.md \
     /Users/openclaw/.openclaw/workspace/SOUL.md
   sudo chown openclaw:staff /Users/openclaw/.openclaw/workspace/SOUL.md
   ```
3. Restart gateway (§3.2).
4. Smoke test via Telegram.
5. Run persona eval if changes are substantive (not just typo fixes).

The health-check script also manages SOUL.md during Limited Mode (swaps to limited
prompt on entry, restores on exit). The `.normal` backup in the workspace is the
restore source.

## 8. Cost Monitoring

| Metric | Target | How to Check |
|--------|--------|--------------|
| Monthly Anthropic spend | ~$8.40 (50% cache) | Anthropic dashboard or API usage endpoint |
| Requests/day to Anthropic | ~39 (manual Telegram only) | Gateway log count |
| Cache hit rate | ≥50% at 5-min TTL | Anthropic dashboard |
| Ollama cost | $0 (local) | N/A |
| Electricity (Ollama) | ~$6.50–10.40/mo | Estimated from TMA-005 |

Cache TTL is set to `long` (1-hour) in the Haiku model params. At 75% hit rate,
projected cost drops to ~$6.09/mo.

## 9. Pre-Reboot Checklist

Run before any planned reboot of Studio. These items ensure the full stack
(gateway, Ollama, health-check, x-feed-intel) survives the reboot cycle.

### 9.1 Verify tess auto-login

Five tess LaunchAgents (health-check, 3 x-feed-intel services, backup cron) depend
on the `gui/` domain, which only exists when tess has a login session. Auto-login
ensures the session starts at boot.

```bash
sudo defaults read /Library/Preferences/com.apple.loginwindow autoLoginUser
# Expected: tess
# FAIL if missing or shows a different user — LaunchAgents won't start after reboot
```

### 9.2 Persist Ollama environment variables

`OLLAMA_KEEP_ALIVE=-1` and `OLLAMA_KV_CACHE_TYPE=q8_0` were set via `launchctl setenv`
and won't survive a reboot. Write them into the Ollama LaunchAgent plist.

```bash
OLLAMA_PLIST="$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"

# Check if EnvironmentVariables already present
if /usr/libexec/PlistBuddy -c "Print :EnvironmentVariables" "$OLLAMA_PLIST" 2>/dev/null; then
  echo "EnvironmentVariables block exists — verify contents:"
  /usr/libexec/PlistBuddy -c "Print :EnvironmentVariables" "$OLLAMA_PLIST"
else
  # Add the block
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables dict" "$OLLAMA_PLIST"
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OLLAMA_KEEP_ALIVE string -1" "$OLLAMA_PLIST"
  /usr/libexec/PlistBuddy -c "Add :EnvironmentVariables:OLLAMA_KV_CACHE_TYPE string q8_0" "$OLLAMA_PLIST"
  echo "Added OLLAMA_KEEP_ALIVE=-1, OLLAMA_KV_CACHE_TYPE=q8_0 to plist"
fi

# Verify
/usr/libexec/PlistBuddy -c "Print :EnvironmentVariables" "$OLLAMA_PLIST"
plutil -lint "$OLLAMA_PLIST"
```

After modifying the plist, reload Ollama via launchctl (NOT `brew services restart`,
which regenerates the plist from the Homebrew formula template and wipes PlistBuddy edits):
```bash
launchctl bootout gui/$(id -u)/homebrew.mxcl.ollama
launchctl bootstrap gui/$(id -u) "$HOME/Library/LaunchAgents/homebrew.mxcl.ollama.plist"
sleep 3
ollama list  # verify tess-mechanic:30b is available
```

### 9.3 Verify OpenClaw gateway supervisor

The gateway runs as a LaunchDaemon in `system/` — it starts at boot regardless of
login state. No action needed, but confirm it's loaded:

```bash
sudo launchctl print system/ai.openclaw.gateway | head -5
# Expected: shows service details with state=running
```

### 9.4 Post-reboot verification

After reboot, confirm all services are running:

```bash
# Gateway (LaunchDaemon — requires sudo; runs as openclaw user)
sudo lsof -nP -iTCP:18789 -sTCP:LISTEN

# Ollama (LaunchAgent — requires tess login session)
curl -s http://127.0.0.1:11434/api/tags | jq '.models[].name'

# Health-check (LaunchAgent)
launchctl list | grep com.tess.health-check

# x-feed-intel services (LaunchAgents)
launchctl list | grep ai.openclaw.xfi
```

---

## 10. Deferred Items

Items identified during implementation but deferred. None block current operation.

> **Note:** Deferred item #4 (OpenClaw upgrade) is addressed by the upgrade runbook
> at `Projects/openclaw-colocation/design/upgrade-v2026-2-24.md`.

| # | Item | Source | Priority | Notes |
|---|------|--------|----------|-------|
| 1 | MC-5 24h+ model persistence validation | TMA-007b | Low | Requires sustained operational monitoring |
| 2 | Q5_K quantization test | TMA-007b | Low | No published Q5_K for qwen3-coder:30b on registry |
| 3 | Inter-agent delegation (DL-1–DL-5) | TMA-002 | Low | Unavailable in v2026.2.17; revisit on upgrade |
| 4 | OpenClaw v2026.2.21 upgrade + `modelByChannel` | TMA-002 | Medium | Blocked on #22841 bundler corruption |
| 5 | Direct Ollama HTTP delegation for mixed tasks | TMA-009 | Low | Voice handles mixed tasks on Haiku; no urgency |
| ~~6~~ | ~~Fallback chain fix (FB-3)~~ | ~~TMA-002~~ | ~~Medium~~ | **RESOLVED v2026.2.24–2.25.** Fallback chains now traverse configured fallbacks. Health-check cron remains for full provider outages. |
| 7 | Cache hit rate measurement in production | TMA-010b | Low | Requires 24h+ representative traffic |
| 8 | Estimation calibration data | Action plan | Low | Track actuals vs planned for future projects |
