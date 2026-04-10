---
type: runbook
project: openclaw-colocation
domain: software
status: draft
created: 2026-02-22
updated: 2026-02-22
tags:
  - openclaw
  - upgrade
  - operations
source: Projects/openclaw-colocation/design/upgrade-v2026-2-21.md
---

# OpenClaw Upgrade Runbook: v2026.2.17 → v2026.2.21

**Source analysis:** `_inbox/openclaw-v2026-2-21-impact-analysis.md`
**Project:** openclaw-colocation (IMPLEMENT phase, all M1–M4 tasks complete)
**Execution target:** Studio (Mac M3 Ultra), `openclaw` dedicated user (uid 502)

## Summary

This is a point release upgrade with no mandatory pre-update config changes, but
post-update verification and one recommended hardening change (`maxSpawnDepth` pin).
The release contains significant security fixes for lateral movement vectors (T4) —
heredoc substitution allowlist bypass and shell env injection — that strengthen the
application-level boundary alongside our existing OS-level isolation (dedicated user +
filesystem permissions). All other changes are low-risk or not applicable to our deployment.

### Risk Assessment

| Area | Risk | Rationale |
|---|---|---|
| Gateway auth | LOW | We use password auth over loopback — tightening affects trusted-proxy/Tailscale setups we don't use |
| Browser sandbox | NONE | Browser disabled; dedicated-user boundary is primary control |
| Telegram streaming | LOW | Config simplification (`streaming` → boolean) auto-maps legacy values |
| Subagent spawn depth | MEDIUM | Default `maxSpawnDepth` 1→2 multiplies T1 attack surface; pin to 1 |
| Crumb-Tess bridge | LOW | Bridge uses filesystem IPC, not gateway API — decoupled from all changes |
| Security fixes (T4) | POSITIVE | Closes real application-level lateral movement vectors |

### Impact Analysis Procedure Corrections

The impact analysis §6 procedure uses patterns that don't match our deployment.
This runbook corrects:

1. **Stop method:** Impact analysis uses `openclaw gateway stop` — our deployment uses
   `launchctl bootout` + `pkill` follow-up (per kill-switch runbook, OC-012 findings)
2. **Install command:** Impact analysis uses `npm update -g` — our pattern uses
   `npm install -g openclaw@latest` with explicit cache/prefix exports (per OC-008)
3. **Start method:** Impact analysis uses `openclaw gateway start` — our deployment uses
   `launchctl bootstrap` (LaunchDaemon pattern)
4. **Missing steps:** Impact analysis omits isolation test re-run, SBOM snapshot,
   hardening verification, and rollback procedure

---

## Pre-Upgrade Checklist

Run from the primary (`tess`) user on Studio:

- [ ] Confirm current version is v2026.2.17:
  ```bash
  sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw --version'
  ```
- [ ] Confirm gateway is running on loopback as `openclaw` user:
  ```bash
  lsof -nP -iTCP:18789 -sTCP:LISTEN
  # Expected: node process owned by openclaw on 127.0.0.1:18789
  # FAIL if shows *:18789 or 0.0.0.0:18789 or owned by root
  ```
- [ ] Confirm isolation tests still pass (catch any drift since OC-011):
  ```bash
  sudo bash /Users/tess/crumb-vault/scripts/openclaw-isolation-test.sh
  ```
- [ ] Back up full OpenClaw state (config, tokens, state/db):
  ```bash
  sudo -u openclaw cp -r /Users/openclaw/.openclaw /Users/openclaw/.openclaw.bak-v2026.2.17
  ```
- [ ] Note current SBOM and runtime versions for comparison:
  ```bash
  sudo -u openclaw bash -c '
    export HOME=/Users/openclaw
    export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
    echo "=== Runtime ===" && node -v && npm -v && which openclaw && npm prefix -g
    echo "=== Packages ===" && npm ls -g --all 2>/dev/null
  ' > /tmp/openclaw-sbom-pre-upgrade.txt
  ```

---

## Upgrade Procedure

### Phase 1: Stop Gateway

```bash
# 1. Stop via launchctl (primary method)
sudo launchctl bootout system/ai.openclaw.gateway

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
```

### Phase 2: Update Package

```bash
# Install target version (explicit cache/prefix per OC-008 pattern)
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  export npm_config_cache="/Users/openclaw/.npm"
  export npm_config_prefix="/Users/openclaw/.local"
  npm install -g openclaw@2026.2.21
'

# Verify installed version — FAIL if not v2026.2.21
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw --version
' | grep -q "v2026.2.21" || { echo "INSTALL FAILED — version mismatch"; exit 1; }
echo "Version verified: v2026.2.21"
```

### Phase 3: Run Doctor & Verify Config

```bash
# Run doctor (may suggest or auto-apply config changes)
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw doctor --fix
'

# IMPORTANT: Diff config against backup to catch any doctor-applied changes
sudo diff /Users/openclaw/.openclaw.bak-v2026.2.17/openclaw.json \
          /Users/openclaw/.openclaw/openclaw.json
```

**Review checklist for config diff:**
- [ ] `workspaceOnly` still `true` for both `fs` and `exec` — if doctor removed it, restore
- [ ] `gateway.bind` still `loopback` / `127.0.0.1`
- [ ] `gateway.auth.mode` still `password`
- [ ] `tailscale.mode` still `off`
- [ ] No unexpected new keys added
- [ ] If doctor stripped any hardening keys: restore from backup, do NOT proceed

```bash
# If config was modified and needs restoration:
# sudo -u openclaw cp /Users/openclaw/.openclaw.bak-v2026.2.17/openclaw.json /Users/openclaw/.openclaw/openclaw.json
# Then re-apply only safe doctor suggestions manually
```

**If post-restart checks reveal non-loopback binding, tailscale enabled, or any other
unexpected security-relevant change:** execute kill-switch immediately
(spec §Messaging Platform Kill-Switch Runbook → Global Emergency Stop).

### Phase 4: SBOM Snapshot

```bash
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  echo "=== Runtime ===" && node -v && npm -v && which openclaw && npm prefix -g
  echo "=== Packages ===" && npm ls -g --all 2>/dev/null
' > /tmp/openclaw-sbom-post-upgrade.txt

# Quick diff to check for unexpected dependency or runtime changes
diff /tmp/openclaw-sbom-pre-upgrade.txt /tmp/openclaw-sbom-post-upgrade.txt
```

### Phase 5: Restart Gateway

```bash
# Start via launchctl (LaunchDaemon pattern)
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist

# Wait for startup
sleep 5

# Verify gateway is listening on loopback as openclaw user
lsof -nP -iTCP:18789 -sTCP:LISTEN
# Expected: node process owned by openclaw on 127.0.0.1:18789
# FAIL if shows *:18789, 0.0.0.0:18789, or owned by root

# Verify process owner explicitly
ps -o user,pid,command -p $(pgrep -u openclaw -f "openclaw/dist/index.js") 2>/dev/null
# Expected: USER=openclaw

# Check status
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw status
'
```

### Phase 6: Re-run Isolation Tests

```bash
# Full isolation test suite — run once, tee to file for both gating and archival
sudo bash /Users/tess/crumb-vault/scripts/openclaw-isolation-test.sh 2>&1 | \
  tee /Users/tess/crumb-vault/Projects/openclaw-colocation/progress/isolation-test-$(date +%Y%m%d)-upgrade.txt
# Expected: 9/9 pass
```

**GO/NO-GO gate:** If any isolation test fails, execute the rollback procedure below.
Do NOT proceed to messaging verification.

---

## Post-Upgrade Verification

### V1: Telegram Streaming (Impact §1c)

Send a test message to Tess via Telegram. Verify:
- [ ] Response arrives (basic connectivity)
- [ ] Response streams incrementally (not as a single block)
- [ ] If streaming broken: set `channels.telegram.streaming: true` in `openclaw.json` and restart

### V2: Gateway Password (Impact §4.5)

- [ ] Verify the rotated password (from OC-012) still works. The Telegram test (V1)
  implicitly validates gateway auth — if Tess responds, auth is working. If V1 passes,
  this is confirmed. If V1 fails, test auth directly via loopback.

### V3: Bridge Functionality (Impact §3)

- [ ] Drop a test file in `/Users/tess/crumb-vault/_openclaw/inbox/` and verify Tess processes it
- [ ] Verify bridge outbox writing works (check `/Users/tess/crumb-vault/_openclaw/outbox/`)

### V4: Memory/QMD Search (Impact §4.3)

- [ ] Send Tess a query requiring vault search
- [ ] Verify results are reasonable (QMD ranking changes may affect results)

### V5: Pin `maxSpawnDepth` to 1 (Impact §1d — security hardening)

The new default `maxSpawnDepth: 2` isn't just a cost concern — each subagent inherits
Tess's workspace and exec permissions, multiplying the T1 (prompt injection) attack
surface. A prompt injection reaching a subagent executes in parallel with the parent
and may have a different system prompt context. Pin to 1 to preserve current behavior:

- [ ] Add `agents.defaults.maxSpawnDepth: 1` to `openclaw.json`
- [ ] Restart gateway for config change to take effect

---

## Rollback Procedure

If any critical issue is discovered post-upgrade:

```bash
# 1. Stop gateway
sudo launchctl bootout system/ai.openclaw.gateway
sleep 2
if pgrep -u openclaw -f "openclaw/dist/index.js" >/dev/null; then
  sudo pkill -u openclaw -f "openclaw/dist/index.js"
  sleep 2
fi
lsof -nP -iTCP:18789 -sTCP:LISTEN  # should return nothing

# 2. Restore full state backup
sudo -u openclaw bash -c '
  rm -rf /Users/openclaw/.openclaw
  cp -r /Users/openclaw/.openclaw.bak-v2026.2.17 /Users/openclaw/.openclaw
'

# 3. Reinstall previous version
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  export npm_config_cache="/Users/openclaw/.npm"
  export npm_config_prefix="/Users/openclaw/.local"
  npm install -g openclaw@2026.2.17
'

# 4. Verify rollback version — FAIL if not v2026.2.17
sudo -u openclaw bash -c '
  export HOME="/Users/openclaw"
  export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
  openclaw --version
' | grep -q "v2026.2.17" || { echo "ROLLBACK INSTALL FAILED"; exit 1; }
echo "Rollback version verified: v2026.2.17"

# 5. Restart
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
sleep 5
lsof -nP -iTCP:18789 -sTCP:LISTEN
# Verify owner is openclaw, binding is 127.0.0.1

# 6. Run isolation tests to confirm rollback integrity
sudo bash /Users/tess/crumb-vault/scripts/openclaw-isolation-test.sh
```

---

## Post-Upgrade Spec Updates

After successful upgrade, these colocation spec sections should be updated:

### U1: Tier 1 Hardening Notes
Add to §Hardening Tiers:
> **v2026.2.21 note:** Application-level lateral movement mitigations significantly
> strengthened — heredoc substitution allowlist bypass blocked, shell startup-file env
> injection blocked (`BASH_ENV`, `ENV`, `BASH_FUNC_*`, `LD_*`, `DYLD_*`). These were
> previously mitigated only by the OS-level dedicated user boundary.

### U2: Threat Model T4
Add to T4 assessment:
> **v2026.2.21 update:** Two critical application-layer vectors closed — heredoc bypass
> and env injection. The OS boundary (dedicated user) remains important as defense-in-depth
> but is no longer the sole effective control against lateral movement.

### U3: Browser Config Note
Update T6 note:
> **v2026.2.21:** Default `--no-sandbox` removed from browser entrypoint; requires explicit
> opt-in via `OPENCLAW_BROWSER_NO_SANDBOX`. Browser sandbox defaults hardened upstream.
> Browser control mechanism may be evolving — check future releases.

### U4: Subagent Spawn Depth (T1 Hardening)
Add to Tier 1 hardening:
> **v2026.2.21 config:** `agents.defaults.maxSpawnDepth: 1` — pinned to prevent
> default increase to 2. Each subagent inherits workspace/exec permissions; spawning
> multiplies T1 (prompt injection) attack surface. One line, preserves prior behavior.

### U5: Version Reference
Update all version references from v2026.2.17 to v2026.2.21 where they describe
current deployed state.

---

## Estimated Duration

- Pre-upgrade checks: ~5 minutes
- Upgrade (stop → update → doctor → start): ~5 minutes
- Isolation tests: ~2 minutes
- Telegram/bridge verification: ~5 minutes
- Total: ~15–20 minutes (excluding 48-hour cost monitoring window)
