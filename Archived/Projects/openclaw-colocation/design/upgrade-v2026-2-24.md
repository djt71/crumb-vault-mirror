---
type: runbook
project: openclaw-colocation
domain: software
status: draft
created: 2026-02-25
updated: 2026-02-26
tags:
  - openclaw
  - upgrade
  - operations
source: Projects/openclaw-colocation/design/upgrade-v2026-2-24.md
supersedes: Projects/openclaw-colocation/design/upgrade-v2026-2-21.md
---

# OpenClaw Upgrade Runbook: v2026.2.17 → v2026.2.25

**Previous runbook:** `upgrade-v2026-2-21.md` (draft, never executed — superseded by this)
**Retarget note:** Originally targeted v2026.2.24. Retargeted to v2026.2.25 on 2026-02-26
after release research. All v2026.2.24 content is peer-reviewed (2026-02-25); v2026.2.25
delta is additive and reduces risk (heartbeat DM delivery restored).
**Project:** openclaw-colocation (DONE phase — maintenance artifact)
**Execution target:** Studio (Mac M3 Ultra), `openclaw` dedicated user (uid 502)
**Supervisor (pre-upgrade):** LaunchAgent at `gui/502` (`/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist`)
**Supervisor (post-upgrade):** LaunchDaemon at `system/` (`/Library/LaunchDaemons/ai.openclaw.gateway.plist`) — migrated during Phase 5b
**LaunchDaemon (pre-upgrade):** DISABLED since 2026-02-24 (dual-supervisor fix, renamed to `.plist.disabled`); re-created as part of this upgrade
**LaunchAgent (post-upgrade):** DISABLED during Phase 5b (renamed to `.plist.disabled`)

## Summary

Eight releases span this upgrade (v2026.2.17 → 2.19 → 2.21 → 2.22 → 2.23 → 2.24 → 2.25).
The period includes heavy security hardening, heartbeat behavioral changes, exec tool
lockdowns, and config key migrations. Two changes will break the current deployment
if not addressed (down from three — v2026.2.25 resolved the heartbeat DM delivery issue).
The upgrade also delivers stale-lock recovery improvements, TMPDIR forwarding for SQLite
reliability, fallback chain fixes, prompt caching, and a new heartbeat `directPolicy`
config — all prerequisites for the Tess chief-of-staff capability expansion.

**Sources:** Version-specific claims in this runbook were verified against the OpenClaw
CHANGELOG and GitHub issue tracker during pre-runbook research (2026-02-25). Inline issue
references (#21923, #21236, #23069, #22841) are GitHub issue identifiers for traceability.

### Risk Assessment

| Area | Risk | Rationale |
|---|---|---|
| Heartbeat DM delivery | ~~HIGH~~ **RESOLVED** | v2026.2.24 silently dropped heartbeat DMs. **v2026.2.25 restores DM delivery by default** via new `directPolicy: "allow"` config. No group chat redirect needed. |
| Exec safeBinTrustedDirs | **HIGH** | v2026.2.24 trusts only `/bin` and `/usr/bin`. Homebrew bins (`/opt/homebrew/bin`) require opt-in. Agents can't run `git`, `node`, `python` etc. without this. |
| Heartbeat directPolicy | **LOW** | v2026.2.25 adds `agents.defaults.heartbeat.directPolicy` (`allow`\|`block`). Default is `allow` — matches our current behavior. Explicit config recommended for clarity. |
| Gateway auth key | **MEDIUM** | `gateway.token` → `gateway.auth.token` (v2026.2.19). `openclaw doctor --fix` migrates. |
| Embedding provider | **MEDIUM** | v2026.2.19 crashes all agent tasks if no embedding provider configured (issue #21923). Mechanic agent on Ollama may trigger this. |
| Device pairing | **MEDIUM** | v2026.2.19 WebSocket handshake hardening may require re-pairing. |
| SSRF config key | **LOW** | `allowPrivateNetwork` → `dangerouslyAllowPrivateNetwork` (v2026.2.23). `openclaw doctor --fix` migrates. |
| Telegram streaming | **LOW** | `streamMode` → boolean `streaming` (v2026.2.21). Auto-maps from legacy. |
| Subagent spawn depth | **LOW** | Default 1→2 (v2026.2.21). Pin to 1 for security. |
| Crumb-Tess bridge | **LOW** | Bridge uses filesystem IPC — decoupled from gateway changes. Session key canonicalized to lowercase (v2026.2.23) — verify no mixed-case keys in bridge. |
| Telegram webhook pre-init | **LOW** | v2026.2.25 pre-initializes webhook bots. We use polling — minimal impact. |
| WebSocket origin/pairing | **LOW** | v2026.2.25 tightens browser-origin auth and pairing semantics. Our setup uses loopback + Telegram polling + filesystem bridge — no browser WebSocket clients. Risk only if Control UI is used for ad-hoc access. |
| Config `get` redaction | **LOW** | v2026.2.25 redacts `env.*` and `skills.entries.*.env.*` in `openclaw config get` output. Our runbook diffs the JSON file directly via `jq`, not `config get`. Note for future diagnostics only. |
| Duplicate bot-token detection | **POSITIVE** | v2026.2.21 detects if another process polls the same Telegram token. Helps prevent 409 conflicts. |
| Stale-lock liveness | **POSITIVE** | v2026.2.24 uses gateway-port reachability for lock liveness. Reduces false lockouts after unclean exits. |
| TMPDIR forwarding | **POSITIVE** | v2026.2.19 forwards TMPDIR for SQLite temp/journal reliability under LaunchAgent. |
| Fallback chain fix | **POSITIVE** | v2026.2.24 properly traverses model fallback chain instead of collapsing to primary. |
| Prompt caching | **POSITIVE** | Cost reduction for repeated system prompts — improves heartbeat economics. |
| sendChatAction 401 backoff | **POSITIVE** | v2026.2.25 adds bounded exponential backoff for Telegram `sendChatAction` 401 failures. Previously, unbounded retries could trigger abuse enforcement and bot deletion. |
| Streaming sentinel leak fix | **POSITIVE** | v2026.2.25 fixes `NO_REPLY` / `HEARTBEAT_...` sentinel text leaking into streaming output. |
| Supervisor migration `gui/502` → `system/` | **MEDIUM** | Required for reboot survivability; LaunchAgent requires GUI login session that `openclaw` user never has. Folded into upgrade while gateway is already stopped. |

### Changes from v2026.2.21 Runbook

| Change | Why |
|--------|-----|
| Target: v2026.2.25 (was v2026.2.21, then v2026.2.24) | 4 additional releases with significant changes |
| Supervisor: LaunchAgent at `gui/502` | LaunchDaemon disabled 2026-02-24 (dual-supervisor fix) |
| Added: `safeBinTrustedDirs` config | New in v2026.2.24, will break Homebrew-dependent commands |
| Removed: heartbeat DM delivery redirect | Was mandatory for v2026.2.24; v2026.2.25 restores DM delivery |
| Added: heartbeat directPolicy config | New in v2026.2.25, explicit allow/block toggle |
| Added: embedding provider check | v2026.2.19 crash bug (issue #21923) |
| Added: re-pairing step | v2026.2.19 WebSocket hardening |
| Added: SSRF key migration | v2026.2.23 rename |
| Added: Supervisor migration LaunchAgent (`gui/502`) → LaunchDaemon (`system/`) | Reboot survivability — LaunchAgent requires GUI login session that `openclaw` never has |

---

## Pre-Upgrade Checklist

Run from the primary (`tess`) user on Studio:

- [ ] **Confirm current version is v2026.2.17:**
  ```bash
  sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw --version'
  ```

- [ ] **Confirm gateway is running on loopback as `openclaw` user:**
  ```bash
  lsof -nP -iTCP:18789 -sTCP:LISTEN
  # Expected: node process owned by openclaw on 127.0.0.1:18789
  # FAIL if shows *:18789 or 0.0.0.0:18789 or owned by root
  # NOTE: Gateway may not be running — see Phase 1 notes
  ```

- [ ] **Confirm only LaunchAgent is active (no LaunchDaemon — will be re-created during upgrade):**
  ```bash
  ls /Library/LaunchDaemons/ai.openclaw.gateway.plist 2>/dev/null && echo "FAIL: LaunchDaemon still active" || echo "OK: LaunchDaemon disabled (will be re-created in Phase 5b)"
  ls /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist && echo "OK: LaunchAgent exists (will be disabled in Phase 5b)"
  ```

- [ ] **Confirm isolation tests pass:**
  ```bash
  sudo bash /Users/tess/crumb-vault/scripts/openclaw-isolation-test.sh
  ```

- [ ] **SBOM snapshot for comparison:**
  ```bash
  sudo -u openclaw bash -c '
    export HOME=/Users/openclaw
    export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
    echo "=== Runtime ===" && node -v && npm -v && which openclaw && npm prefix -g
    echo "=== Packages ===" && npm ls -g --all 2>/dev/null
  ' > /tmp/openclaw-sbom-pre-upgrade.txt
  ```

- [ ] **Note current heartbeat/cron config for post-upgrade comparison:**
  ```bash
  sudo -u openclaw bash -c '
    export HOME=/Users/openclaw
    export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
    openclaw cron list 2>/dev/null || echo "No cron jobs configured"
  '
  ```

- [ ] **[OPTIONAL] Acquire Telegram group chat ID for heartbeat redirect:**
  v2026.2.25 restores DM delivery by default, so this is no longer mandatory. However,
  if you prefer heartbeat messages to go to a group instead of DM, prepare a group chat
  ID. See the original v2026.2.24 runbook revision for the group setup procedure.

- [ ] **Verify x-feed-intel services baseline (pre-upgrade snapshot):**
  ```bash
  launchctl list | grep ai.openclaw.xfi
  # Expected: three services (attention, capture, feedback) with PID > 0 or exit status 0
  ```

- [ ] **Verify npm registry reachable (rollback resilience):**
  ```bash
  npm view openclaw@2026.2.17 version 2>/dev/null && echo "OK: rollback version available" || echo "WARNING: rollback version not reachable — consider caching"
  ```
  If unreachable, cache the current install:
  ```bash
  sudo -u openclaw bash -c '
    export HOME="/Users/openclaw"
    cd /tmp && npm pack openclaw@2026.2.17 2>/dev/null
  ' && echo "Cached to /tmp/openclaw-2026.2.17.tgz"
  ```

---

## Upgrade Procedure

### Phase 1: Stop Gateway

The gateway currently runs under the openclaw user's LaunchAgent domain (`gui/502`).
Phase 5b will migrate to a LaunchDaemon — but we stop the existing LaunchAgent here.

```bash
# 0. Derive UID dynamically (do NOT hardcode 502)
OC_UID=$(id -u openclaw)

# 1. Bootout the current LaunchAgent (this is the pre-migration supervisor)
sudo launchctl bootout "gui/$OC_UID" /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist 2>/dev/null || echo "Not loaded — may already be stopped"

# 2. Verify stopped — pkill if needed (OC-012 pattern)
sleep 2
if pgrep -u openclaw -f "openclaw/dist/index.js" >/dev/null; then
  echo "Process still running — sending pkill"
  sudo pkill -u openclaw -f "openclaw/dist/index.js"
  sleep 2
fi

# 3. Confirm port is clear
lsof -nP -iTCP:18789 -sTCP:LISTEN
# Expected: no output

# 4. Back up full OpenClaw state (AFTER stop to avoid SQLite lock/journal corruption)
sudo -u openclaw rsync -a --delete /Users/openclaw/.openclaw/ /Users/openclaw/.openclaw.bak-v2026.2.17/
sudo chown -R openclaw:staff /Users/openclaw/.openclaw.bak-v2026.2.17
echo "Backup complete — verify:"
sudo -u openclaw ls -la /Users/openclaw/.openclaw.bak-v2026.2.17/
```

### Phase 2: Update Package

```bash
# Install target version (explicit cache/prefix per OC-008 pattern)
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  export npm_config_cache="/Users/openclaw/.npm"
  export npm_config_prefix="/Users/openclaw/.local"
  npm install -g openclaw@2026.2.25
'

# Verify installed version — FAIL if not v2026.2.25
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw --version
'
# Expected: 2026.2.25
```

**Known issue:** If install fails with "inappropriate ioctl" (issue #23069), use
`npm i -g openclaw@2026.2.25` instead of the curl installer.

### Phase 3: Run Doctor & Apply Config Migrations

```bash
# Run doctor with auto-fix
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw doctor --fix
'

# Diff config against backup to review all doctor-applied changes
sudo diff /Users/openclaw/.openclaw.bak-v2026.2.17/openclaw.json \
          /Users/openclaw/.openclaw/openclaw.json
```

**Doctor should auto-migrate:**
- `gateway.token` → `gateway.auth.token`
- `browser.ssrfPolicy.allowPrivateNetwork` → `browser.ssrfPolicy.dangerouslyAllowPrivateNetwork`
- `channels.telegram.streamMode` → `channels.telegram.streaming` (boolean)

**Verify migrations landed** (jq gates — do not rely on prose alone):
```bash
OC_CONFIG="/Users/openclaw/.openclaw/openclaw.json"

# Gate 1: auth key migrated (should exist at new path)
sudo -u openclaw jq -e '.gateway.auth.token // .gateway.auth.mode' "$OC_CONFIG" >/dev/null \
  && echo "OK: gateway.auth key present" \
  || echo "FAIL: gateway.auth key missing — doctor may not have migrated"

# Gate 2: SSRF key migrated (old key should be gone)
OLD_SSRF=$(sudo -u openclaw jq -r '.browser.ssrfPolicy.allowPrivateNetwork // empty' "$OC_CONFIG")
if [[ -n "$OLD_SSRF" ]]; then
  echo "FAIL: legacy allowPrivateNetwork key still present — doctor migration incomplete"
else
  echo "OK: SSRF key migrated (or was not set)"
fi

# Gate 3: Telegram streaming migrated (should be boolean, not object/string)
STREAM_TYPE=$(sudo -u openclaw jq -r '.channels.telegram.streaming | type' "$OC_CONFIG" 2>/dev/null)
if [[ "$STREAM_TYPE" == "boolean" ]]; then
  echo "OK: telegram.streaming is boolean"
elif sudo -u openclaw jq -e '.channels.telegram.streamMode' "$OC_CONFIG" >/dev/null 2>&1; then
  echo "WARN: legacy streamMode still present — doctor may not have migrated"
else
  echo "OK: telegram streaming not configured (or already migrated)"
fi
```

**Review doctor changes only** — full config review happens after Phase 4.
If doctor stripped any hardening keys (e.g., `workspaceOnly`, `gateway.bind`): restore
from backup and do NOT proceed until resolved.
If any migration gate above reports FAIL: do NOT proceed — restore from backup and
re-run `openclaw doctor --fix`, or apply the migration manually via `jq`.

**Redaction note (v2026.2.25):** `openclaw config get` now redacts sensitive-looking keys
(`env.*`, `skills.entries.*.env.*`) with placeholder sentinels. This does NOT affect our
diff procedure — we diff the actual JSON file via `jq`, not `config get` output. However,
if using `config get` for future diagnostics: treat redacted values as sentinels, not real
config; never paste them back into config as literals. Round-trip restore preserves secrets.

### Phase 4: Apply Mandatory Config Changes

These are NEW requirements in v2026.2.24+ that doctor does not auto-apply.
All changes use `jq` for atomic JSON merging — never edit `openclaw.json` by hand.

```bash
OC_CONFIG="/Users/openclaw/.openclaw/openclaw.json"

# 4a. Exec trusted directories (HIGH — agents can't run Homebrew commands without this)
# Merges into existing tools.exec object, preserving workspaceOnly and other keys
tmp=$(mktemp)
sudo -u openclaw jq '.tools.exec.safeBinTrustedDirs = ["/bin", "/usr/bin", "/opt/homebrew/bin"]' \
  "$OC_CONFIG" > "$tmp" && sudo -u openclaw mv "$tmp" "$OC_CONFIG"
echo "4a done — safeBinTrustedDirs set"

# 4b. Heartbeat directPolicy (LOW — v2026.2.25 restores DM delivery by default)
# v2026.2.24 blocked DM heartbeats; v2026.2.25 adds directPolicy with default "allow".
# Set explicitly for clarity and to survive future default changes.
tmp=$(mktemp)
sudo -u openclaw jq '.agents.defaults.heartbeat.directPolicy = "allow"' \
  "$OC_CONFIG" > "$tmp" && sudo -u openclaw mv "$tmp" "$OC_CONFIG"
echo "4b done — heartbeat directPolicy set to allow"
# To block DM heartbeats (v2026.2.24 behavior), use "block" instead:
# sudo -u openclaw jq '.agents.defaults.heartbeat.directPolicy = "block"' "$OC_CONFIG" > "$tmp" && ...

# 4c. Pin maxSpawnDepth to 1 (security — default increased from 1 to 2 in v2026.2.21)
# Each subagent inherits workspace/exec permissions; depth 2 multiplies T1 attack surface
tmp=$(mktemp)
sudo -u openclaw jq '.agents.defaults.maxSpawnDepth = 1' \
  "$OC_CONFIG" > "$tmp" && sudo -u openclaw mv "$tmp" "$OC_CONFIG"
echo "4c done — maxSpawnDepth pinned to 1"

# 4d. Verify embedding provider (MEDIUM — crash risk, issue #21923)
# Check current state first:
echo "Current embedding config:"
sudo -u openclaw jq '.agents.defaults.embedding // "not configured"' "$OC_CONFIG"
echo "Current memorySearch config:"
sudo -u openclaw jq '.agents.defaults.memorySearch // "not configured"' "$OC_CONFIG"
# If no embedding provider is configured AND memorySearch is enabled, disable it:
# tmp=$(mktemp)
# sudo -u openclaw jq '.agents.defaults.memorySearch.enabled = false' "$OC_CONFIG" > "$tmp" && sudo -u openclaw mv "$tmp" "$OC_CONFIG"

# 4e. Verify no hardlinks in workspace (LOW — v2026.2.25 rejects hardlinks in workspaceOnly guard)
# Bridge uses atomic rename and cp; no hardlinks expected. Quick safety check.
echo "Checking for hardlinks in workspace..."
HARDLINKS=$(sudo -u openclaw find /Users/openclaw/.openclaw/workspace -type f -links +1 2>/dev/null)
if [[ -n "$HARDLINKS" ]]; then
  echo "WARNING: Hardlinked files found — replace with copies before proceeding:"
  echo "$HARDLINKS"
else
  echo "4e done — no hardlinks in workspace"
fi

# === JSON VALIDATION GATE (MUST PASS before proceeding to Phase 5) ===
echo "Validating JSON..."
sudo -u openclaw jq . "$OC_CONFIG" > /dev/null 2>&1 && echo "OK: valid JSON" || {
  echo "FAIL: Invalid JSON — restore from backup and retry"
  echo "  sudo -u openclaw rsync -a --delete /Users/openclaw/.openclaw.bak-v2026.2.17/ /Users/openclaw/.openclaw/"
  exit 1
}

# Review final config diff against backup
sudo diff /Users/openclaw/.openclaw.bak-v2026.2.17/openclaw.json "$OC_CONFIG"
```

**Review checklist for config diff (Phase 3 + Phase 4 combined):**
- [ ] `tools.exec.workspaceOnly` still `true` — if doctor removed it, restore
- [ ] `tools.exec.safeBinTrustedDirs` includes `/opt/homebrew/bin`
- [ ] `gateway.bind` still `loopback` / `127.0.0.1`
- [ ] `gateway.auth.mode` still `password`
- [ ] `tailscale.mode` still `off`
- [ ] `agents.defaults.maxSpawnDepth` is `1`
- [ ] `agents.defaults.heartbeat.directPolicy` is `"allow"` (or `"block"` if intentionally suppressing DM heartbeats)
- [ ] No unexpected keys added

### Phase 5: SBOM Snapshot

```bash
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  echo "=== Runtime ===" && node -v && npm -v && which openclaw && npm prefix -g
  echo "=== Packages ===" && npm ls -g --all 2>/dev/null
' > /tmp/openclaw-sbom-post-upgrade.txt

# Diff to check for unexpected dependency changes
diff /tmp/openclaw-sbom-pre-upgrade.txt /tmp/openclaw-sbom-post-upgrade.txt
```

### Phase 5b: Supervisor Migration (LaunchAgent → LaunchDaemon)

The gateway currently runs under a LaunchAgent in the `gui/502` domain. This domain
only exists when the `openclaw` user has an active GUI login session — which it never
does (it's a headless service account). The LaunchAgent works today because `launchctl
bootstrap gui/502` was run manually, but it won't survive a machine reboot. Migrating
to a LaunchDaemon with `UserName: openclaw` runs in the `system/` domain, which starts
at boot regardless of login state.

This phase also folds in the `ThrottleInterval: 60` from the upstream v2026.2.25
restart hardening (previously a standalone LaunchAgent plist patch).

```bash
# --- Step 1: Disable the LaunchAgent ---
AGENT_PLIST="/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist"
if [[ -f "$AGENT_PLIST" ]]; then
  sudo mv "$AGENT_PLIST" "${AGENT_PLIST}.disabled"
  echo "LaunchAgent disabled (renamed to .plist.disabled)"
else
  echo "LaunchAgent plist not found — may already be disabled"
fi

# --- Step 2: Create the LaunchDaemon ---
DAEMON_PLIST="/Library/LaunchDaemons/ai.openclaw.gateway.plist"
sudo tee "$DAEMON_PLIST" > /dev/null <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>ai.openclaw.gateway</string>
  <key>UserName</key>
  <string>openclaw</string>
  <key>GroupName</key>
  <string>staff</string>
  <key>ProgramArguments</key>
  <array>
    <string>/opt/homebrew/bin/node</string>
    <string>/Users/openclaw/.local/lib/node_modules/openclaw/dist/index.js</string>
    <string>gateway</string>
    <string>--port</string>
    <string>18789</string>
  </array>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>
    <string>/Users/openclaw</string>
    <key>PATH</key>
    <string>/Users/openclaw/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
  </dict>
  <key>WorkingDirectory</key>
  <string>/Users/openclaw</string>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>60</integer>
  <key>StandardOutPath</key>
  <string>/Users/openclaw/.openclaw/logs/gateway-stdout.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/openclaw/.openclaw/logs/gateway-stderr.log</string>
</dict>
</plist>
PLIST

# --- Step 3: Validate plist ---
sudo plutil -lint "$DAEMON_PLIST"
# Expected: "ai.openclaw.gateway.plist: OK"

# --- Step 4: Strip com.apple.provenance xattr (macOS 15+ copy protection) ---
# IMPORTANT: This MUST be the last modification before bootstrap. On macOS 15+,
# every sudo tee, PlistBuddy edit, or cp re-attaches the provenance xattr.
# If you edit the plist after this step, re-run the strip.
sudo xattr -d com.apple.provenance "$DAEMON_PLIST" 2>/dev/null || true
echo "Provenance xattr stripped (or not present)"

# --- Step 5: Clean up old disabled LaunchDaemon from 2026-02-24 dual-supervisor fix ---
OLD_DISABLED="/Library/LaunchDaemons/ai.openclaw.gateway.plist.disabled"
if [[ -f "$OLD_DISABLED" ]]; then
  sudo rm "$OLD_DISABLED"
  echo "Removed old disabled LaunchDaemon from 2026-02-24"
else
  echo "No old disabled LaunchDaemon found — clean"
fi

echo "Supervisor migration complete — LaunchDaemon created at $DAEMON_PLIST"
echo "LaunchAgent disabled at ${AGENT_PLIST}.disabled"
```

### Phase 6: Restart Gateway

The gateway now uses a LaunchDaemon (created in Phase 5b) instead of the LaunchAgent.

```bash
# Strip provenance xattr immediately before bootstrap (macOS 15+ re-attaches it
# on every file modification — must be the last step before launchctl reads the plist)
sudo xattr -d com.apple.provenance /Library/LaunchDaemons/ai.openclaw.gateway.plist 2>/dev/null || true

# Bootstrap the LaunchDaemon into the system domain
sudo launchctl bootstrap system/ /Library/LaunchDaemons/ai.openclaw.gateway.plist

# Explicit kickstart (upstream restart sequence now includes this after bootstrap)
sudo launchctl kickstart system/ai.openclaw.gateway

# Wait for startup with retry loop (20s timeout)
echo "Waiting for gateway to start..."
for i in $(seq 1 10); do
  if lsof -nP -iTCP:18789 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Gateway listening after ~$((i * 2))s"
    break
  fi
  if [[ $i -eq 10 ]]; then
    echo "FAIL: Gateway not listening after 20s — check logs"
    sudo tail -20 /Users/openclaw/.openclaw/logs/gateway-stderr.log
  fi
  sleep 2
done

# Verify gateway is listening on loopback as openclaw user
lsof -nP -iTCP:18789 -sTCP:LISTEN
# Expected: node process owned by openclaw on 127.0.0.1:18789
# FAIL if shows *:18789, 0.0.0.0:18789, or owned by root

# Verify process owner
ps -o user,pid,command -p $(pgrep -u openclaw -f "openclaw/dist/index.js") 2>/dev/null
# Expected: USER=openclaw

# Check gateway status
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw status
'
```

**Note:** The `com.apple.provenance` xattr strip is now integrated into the bootstrap
sequence above. On macOS 15+, any `sudo tee`, `PlistBuddy`, or `cp` to the plist file
re-attaches this xattr. If you need to edit the plist after Phase 5b, re-strip before
bootstrap — `launchctl` will fail with "Input/output error" if the xattr is present.

### Phase 7: Re-run Isolation Tests

```bash
sudo bash /Users/tess/crumb-vault/scripts/openclaw-isolation-test.sh 2>&1 | \
  tee /Users/tess/crumb-vault/Projects/openclaw-colocation/progress/isolation-test-$(date +%Y%m%d)-upgrade-v2026-2-25.txt
# Expected: 9/9 pass
```

**GO/NO-GO gate:** If any isolation test fails, execute the rollback procedure below.

### Phase 8: Security Audit

Run the built-in security audit as a mandatory gate before proceeding to verification.
This covers transcript JSONL permissions, exec boundaries, and security behaviors
introduced across the v2026.2.12–2.25 release window.

```bash
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw security audit
'
```

- [ ] Review audit output for warnings or failures.
- [ ] If issues found: run `openclaw security audit --fix` **only after reviewing each fix** —
  treat `--fix` as a medium-risk action per Crumb's approval semantics.
- [ ] If audit recommends changes to gateway bind, auth, or exec permissions: **STOP and verify
  against colocation spec before applying** — these are high-risk items.

**GO/NO-GO gate:** Audit must pass clean (or with acknowledged low-risk warnings only).

---

## Post-Upgrade Verification

### V1: Telegram Connectivity

Send a test message to Tess via Telegram. Verify:
- [ ] Response arrives (basic connectivity)
- [ ] Response streams incrementally (not as a single block)
- [ ] If streaming broken: verify `channels.telegram.streaming: true` in config

### V2: Gateway Auth

The Telegram test (V1) implicitly validates gateway auth — if Tess responds, auth is
working. If V1 fails, test auth directly via loopback.

### V3: Bridge Functionality

- [ ] Drop a test file in `_openclaw/inbox/` and verify Tess processes it
- [ ] Verify bridge outbox writing works (check `_openclaw/outbox/`)

### V4: Exec Tool (Homebrew Binaries)

- [ ] Ask Tess to run a command that uses Homebrew binaries (e.g., `git status`,
  `node --version`). Verify it succeeds.
- [ ] If it fails with a trusted-directory error: confirm `safeBinTrustedDirs` is set
  correctly and gateway was restarted after the config change.

### V5: Heartbeat Delivery

- [ ] Trigger a heartbeat check and verify delivery arrives via DM (default `directPolicy: "allow"`).
- [ ] If `directPolicy` was set to `"block"`: verify heartbeat still executes but DMs are suppressed.
- [ ] Check mechanic agent's `heartbeat.every: "30m"` is respected in gateway logs.

### V6: Mechanic Agent

- [ ] Verify the Ollama/qwen3-coder mechanic agent responds.
- [ ] If it crashes with a TypeError about `replace`: the embedding provider issue (#21923)
  is active — disable memory search per Phase 4d.

### V7: Re-pair Devices (if needed)

**v2026.2.25 pairing note:** Operator device-identity sessions authenticated with shared
token auth now **must be paired** — unpaired devices cannot self-assign operator scopes.
This is desirable for our security posture but means re-pairing is more likely after
this upgrade than after previous ones.

- [ ] If any CLI commands fail with `"gateway closed (1008): pairing required"`:
  ```bash
  sudo -u openclaw bash -c '
    export HOME="/Users/openclaw"
    export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
    openclaw doctor --fix
  '
  ```
  or re-pair the device manually.
- [ ] Verify all operator devices you use are paired: `openclaw devices list`
- [ ] If using Control UI or browser-based access: test that WebSocket connections
  still authenticate (v2026.2.25 tightens origin checks for browser clients).

### V8: x-feed-intel Services

Verify the three x-feed-intel LaunchAgent services are unaffected:

```bash
launchctl list | grep ai.openclaw.xfi
# Expected: three services (attention, capture, feedback)
# Compare against pre-upgrade baseline — PIDs may differ but all three should be present
```

- [ ] `ai.openclaw.xfi.attention` — calendar-triggered, no change expected
- [ ] `ai.openclaw.xfi.capture` — calendar-triggered, no change expected
- [ ] `ai.openclaw.xfi.feedback` — persistent listener, verify still polling

These services don't route through the OpenClaw gateway (they're standalone Node
processes), but verify they haven't been affected by any shared dependency changes.

### V9: Cron Jobs

- [ ] Verify cron job list is intact: `openclaw cron list`
- [ ] If cron jobs exist, trigger a manual test run: `openclaw cron run <job-id>`

### V10: Supervisor Domain

Verify the LaunchDaemon is loaded and the gateway is running as `openclaw` in the system domain:

```bash
sudo launchctl print system/ai.openclaw.gateway
# Expected: shows service details with username=openclaw, state=running
# Key fields to verify:
#   - "state = running"
#   - "username = openclaw"
#   - "domain = system"
```

- [ ] LaunchDaemon loaded in `system/` domain
- [ ] Process running as `openclaw` user
- [ ] Old LaunchAgent is disabled (`.plist.disabled` exists, not loaded in `gui/502`)

**Before rebooting:** Complete the pre-reboot checklist (Ollama env var persistence, tess auto-login verification) in the TMA maintenance runbook §9 (`Projects/tess-model-architecture/design/maintenance-runbook.md`).

---

## Rollback Procedure

If any critical issue is discovered post-upgrade:

> **Data-loss warning:** Rollback restores configuration and state to the pre-upgrade
> snapshot. Any data generated after the upgrade (logs, sessions, caches) will be lost.

**Note:** Rollback does NOT revert the supervisor migration — the LaunchDaemon works
with both old and new OpenClaw versions. The old LaunchAgent remains disabled.

```bash
# 1. Stop gateway (now running as LaunchDaemon)
sudo launchctl bootout system/ai.openclaw.gateway 2>/dev/null
sleep 2
if pgrep -u openclaw -f "openclaw/dist/index.js" >/dev/null; then
  sudo pkill -u openclaw -f "openclaw/dist/index.js"
  sleep 2
fi
lsof -nP -iTCP:18789 -sTCP:LISTEN  # should return nothing

# 2. Restore full state backup (rsync preserves metadata; --delete ensures exact match)
sudo -u openclaw rsync -a --delete /Users/openclaw/.openclaw.bak-v2026.2.17/ /Users/openclaw/.openclaw/
sudo chown -R openclaw:staff /Users/openclaw/.openclaw

# 3. Reinstall previous version
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  export npm_config_cache="/Users/openclaw/.npm"
  export npm_config_prefix="/Users/openclaw/.local"
  npm install -g openclaw@2026.2.17
'

# 4. Verify rollback version
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw --version
'
# Expected: 2026.2.17

# 5. Restart via LaunchDaemon (works with old version too)
sudo launchctl bootstrap system/ /Library/LaunchDaemons/ai.openclaw.gateway.plist

# Wait for startup with retry loop (20s timeout)
echo "Waiting for gateway to start..."
for i in $(seq 1 10); do
  if lsof -nP -iTCP:18789 -sTCP:LISTEN >/dev/null 2>&1; then
    echo "Gateway listening after ~$((i * 2))s"
    break
  fi
  if [[ $i -eq 10 ]]; then
    echo "FAIL: Gateway not listening after 20s — check logs"
  fi
  sleep 2
done

lsof -nP -iTCP:18789 -sTCP:LISTEN
# Verify owner is openclaw, binding is 127.0.0.1

# 6. Isolation tests
sudo bash /Users/tess/crumb-vault/scripts/openclaw-isolation-test.sh
```

---

## Post-Upgrade Spec Updates

After successful upgrade, update colocation spec sections:

### U1: Tier 1 Hardening Notes
Add to §Hardening Tiers:
> **v2026.2.24–2.25 note:** Application-level security significantly strengthened across
> eight releases — heredoc substitution bypass blocked (v2026.2.21), shell env injection
> blocked (v2026.2.21), exec tool pinned to resolved absolute paths (v2026.2.22),
> safe-bin directories restricted to system paths (v2026.2.24), dangerous env keys
> stripped from non-sandboxed exec (v2026.2.24), **workspace FS hardlink rejection**
> added to `workspaceOnly` and `applyPatch` guards (v2026.2.25) — prevents out-of-workspace
> read/write via in-workspace hardlink aliases. SSRF protections expanded with IPv6
> transition address blocking (v2026.2.19) and pinned DNS ordering (v2026.2.24).
>
> **`/opt/homebrew/bin` trust rationale:** Homebrew is the standard macOS package manager
> path. Agents require `git`, `node`, `python` — all installed via Homebrew. Symlinking
> individual binaries to `/usr/local/bin` would obscure binary provenance, add maintenance
> burden for each upgrade, and provide no additional security over trusting the directory.
> The operator controls the Homebrew supply chain on a single-user Studio machine.

### U2: Threat Model T4
Add to T4 assessment:
> **v2026.2.24 update:** Multiple application-layer lateral movement vectors closed
> across releases. The OS boundary (dedicated user) remains important as defense-in-depth
> but is no longer the sole effective control. Exec tool now validates binary paths and
> strips dangerous environment variables independently of OS-level controls.

### U3: Gateway Auth
Update gateway auth section:
> **v2026.2.19:** Auth key migrated from `gateway.token` to `gateway.auth.token`.
> Default auth mode for new installs is token-based with auto-generated secret.
> Password mode (our config) unaffected but key path changed.

### U4: Subagent Spawn Depth
Add to Tier 1 hardening:
> **v2026.2.21 config:** `agents.defaults.maxSpawnDepth: 1` — pinned to prevent
> default increase to 2. Each subagent inherits workspace/exec permissions; spawning
> multiplies T1 (prompt injection) attack surface.

### U5: Heartbeat Configuration
Add new section or note:
> **v2026.2.24–2.25:** Heartbeat delivery underwent two changes: v2026.2.24 blocked DM
> delivery; v2026.2.25 restored it via `agents.defaults.heartbeat.directPolicy` (`allow`
> by default, `block` to suppress). Our config explicitly sets `directPolicy: "allow"` for
> resilience against future default changes. Per-agent override available via
> `agents.list[].heartbeat.directPolicy`.

### U6: Version Reference
Update all version references from v2026.2.17 to v2026.2.25.

### U7: v2026.2.25 Security & Branding
Add to security notes:
> **v2026.2.25:** WebSocket auth origin checks hardened, workspace FS hardlink rejection
> added, exec approval binding tightened. Branding cleanup: all remaining `bot.molt`
> labels replaced with `ai.openclaw` across docs and CLI. Telegram webhook pre-init
> and callback-mode JSON handling added (polling mode unaffected).

### U8: Pairing, Security Audit & Provider Roster (v2026.2.25)
Add to colocation spec integration section:
> **v2026.2.25 pairing:** Operator device-identity sessions authenticated with shared
> token auth must now be paired; unpaired devices cannot self-assign operator scopes.
> The colocation design treats pairing as a primary guardrail, not an optional UX feature.
> "Shared token is sufficient" → "shared token + pairing, scoped to loopback."
>
> **Security audit:** `openclaw security audit` is now a first-class maintenance primitive.
> Run after every OpenClaw upgrade and any material configuration change. `--fix` is gated
> behind medium/high-risk approval semantics.
>
> **Provider roster:** OpenClaw 2026.2.25 adds first-class Kilo Gateway / `kilocode`
> provider support (default model: `kilocode/anthropic/claude-opus-4.6`). Not enabled
> in this colocation deployment. Crumb's model routing remains controlled in CLAUDE.md.

### U9: Fallback Chain Fix — Close TMA Deferred Item
Update maintenance runbook §9, item #6:
> ~~Fallback chain fix (FB-3) — Medium — `model.fallbacks` doesn't auto-failover for
> provider-down; health-check cron is the workaround~~
> **RESOLVED in v2026.2.24–2.25.** Fallback chains now properly traverse configured
> fallbacks instead of collapsing to primary. Same-provider chains and unrecognized
> error traversal also fixed. Health-check cron remains as defense-in-depth for full
> provider outages where no fallback model exists.

### U10: LaunchAgent Restart Hardening
Add to operational notes:
> **v2026.2.25:** Upstream daemon restart sequence hardened: `print → bootout → wait old
> pid exit → bootstrap → kickstart` with stale PID cleanup and supervisor marker detection.
> LaunchAgent plists now include `ThrottleInterval: 60` to bound launchd retry storms.
> Sentinel text (`NO_REPLY`, `HEARTBEAT_...`) no longer leaks into streaming output.
> Telegram `sendChatAction` 401 failures now use bounded exponential backoff.

### U11: Supervisor Migration
Update supervisor references throughout the spec:
> **2026-02-26 upgrade:** Gateway supervisor migrated from LaunchAgent (`gui/502` domain,
> `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist`) to LaunchDaemon
> (`system/` domain, `/Library/LaunchDaemons/ai.openclaw.gateway.plist`) with
> `UserName: openclaw`, `GroupName: staff`. Motivation: the `gui/502` domain only exists
> when the `openclaw` user has an active GUI login session, which never happens for this
> headless service account. The LaunchDaemon starts at boot via `system/` domain
> regardless of login state. `ThrottleInterval: 60` included (v2026.2.25 restart
> hardening). `WorkingDirectory: /Users/openclaw` included (defensive — ensures
> consistent cwd regardless of launchd context). Health-check script updated to target
> `system/ai.openclaw.gateway`.
>
> **Execution corrections (2026-02-26):**
> - **Node binary path:** ProgramArguments must reference `/opt/homebrew/bin/node`, not
>   `/Users/openclaw/.local/bin/node`. The `.local/bin/` directory contains only the
>   `openclaw` CLI symlink; `node` is installed via Homebrew. The incorrect path causes
>   launchd to report `EX_CONFIG (exit code 78)` with zero log output — the process never
>   launches, making the failure opaque.
> - **`com.apple.provenance` xattr lifecycle:** On macOS 15+, every file modification
>   (`sudo tee`, `PlistBuddy -c`, `cp`) re-attaches this xattr. The strip must be the
>   **last** operation before `launchctl bootstrap`. Stripping earlier in the sequence
>   is ineffective if subsequent edits re-attach it.

---

## Estimated Duration

- Pre-upgrade checks: ~5 minutes
- Upgrade (stop → update → doctor → config → start): ~10 minutes
- Isolation tests + security audit: ~5 minutes
- Post-upgrade verification (V1–V9): ~15 minutes
- Total: ~35 minutes (excluding any re-pairing or troubleshooting)

---

## Known Issues in v2026.2.25 Release Window

| Issue | Version | Impact | Status |
|-------|---------|--------|--------|
| TypeError crash — no embedding provider | v2026.2.19 (#21923) | Crashes all agent tasks | Mitigate: disable memory search or configure provider |
| "Pairing required" after upgrade | v2026.2.19 (#21236) | CLI commands fail | Fix: `openclaw doctor --fix` or re-pair |
| "Inappropriate ioctl" on curl installer | v2026.2.21 (#23069) | Install fails | Fix: use `npm i -g` instead |
| Scope-upgrade loops on legacy devices | Fixed v2026.2.24 | Pairing token loops | Resolved in target version |
| Bundler corruption | v2026.2.21-2 (#22841) | Build failures | Verify: run `openclaw doctor` post-install |
| Heartbeat DM delivery regression | v2026.2.24 → fixed v2026.2.25 | DM heartbeats silently dropped | Resolved: `directPolicy: "allow"` default in v2026.2.25 |
| Slack parentForkMaxTokens | v2026.2.25 | Oversized parent sessions brick threads | Not applicable (no Slack channel) |
