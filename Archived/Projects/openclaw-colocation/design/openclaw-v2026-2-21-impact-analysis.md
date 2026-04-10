---
type: analysis
project: openclaw-colocation
domain: software
status: active
created: 2026-02-21
updated: 2026-02-22
tags:
  - openclaw
  - security
  - upgrade
---

# OpenClaw v2026.2.21 — Impact Analysis for Crumb Colocation Deployment

**Date:** 2026-02-21
**Current deployed version:** v2026.2.17 (installed during OC-008)
**Target version:** v2026.2.21

---

## 1. POTENTIAL BREAKING CHANGES

### 1a. Gateway Auth Hardening

**What changed:** Multiple gateway auth fixes — trusted-proxy mode now requires `gateway.trustedProxies` to include loopback when using `bind="loopback"`. Control UI auth now requires secure context and paired-device checks even when `allowInsecureAuth` is set. Tokenless Tailscale forwarded-header auth scoped to Control UI websocket only.

**Your config:** `gateway.bind: "loopback"`, `gateway.auth.mode: "password"`, `tailscale.mode: "off"`. No trusted-proxy, no Control UI in active use.

**Risk: LOW.** Password auth over loopback is the simplest path and unchanged. The tightening affects trusted-proxy and Tailscale setups, which you're not using. No action needed.

### 1b. Browser Sandbox Defaults

**What changed:** Default `--no-sandbox` removed from browser container entrypoint. Now requires explicit opt-in via env var `OPENCLAW_BROWSER_NO_SANDBOX`.

**Your config:** `tools.browser.enabled: false` was set in OC-009 but stripped by `openclaw doctor --fix` (v2026.2.17 didn't recognize it). Browser is not actively used.

**Risk: NONE.** Browser isn't enabled. No action needed.

### 1c. Telegram Streaming Config Simplification

**What changed:** `channels.telegram.streaming` is now a boolean. Legacy `streamMode` values are auto-mapped.

**Your config:** Telegram is the active messaging channel for Tess.

**Risk: LOW.** Auto-mapping of legacy values should handle this transparently. Verify after update that streaming still works — send a test message and confirm the response streams rather than arriving as a single block. If broken, set `channels.telegram.streaming: true` explicitly.

### 1d. Subagent Spawn Depth Default

**What changed:** Default `maxSpawnDepth` is now 2 (shared), enabling depth-1 orchestrator spawning by default.

**Your config:** `subagents.maxConcurrent: 8` is set. `maxSpawnDepth` is not explicitly configured.

**Risk: LOW.** This means Tess can now spawn subagents by default where it may not have been able to before. Not a security concern given the workspace isolation, but could affect token costs if Tess starts spawning subagents for complex queries. Monitor for unexpected cost increases. If concerned, explicitly set `agents.defaults.maxSpawnDepth: 1` in config.

---

## 2. SECURITY FIXES — THREAT MODEL CROSS-REFERENCE

### Threat T1: Prompt Injection (rated HIGH in colocation spec)

| Fix in v2026.2.21 | Impact on your setup |
|---|---|
| ACP resource_link metadata escaping prevents prompt injection via resource links | Mitigates a vector not covered in the original spec |
| TTS model-driven provider switching now opt-in by default | Prevents prompt injection from triggering expensive TTS provider hops |
| Untrusted metadata prefix stripping at display boundaries (TUI, webchat, macOS) | Reduces info leakage from injected metadata |
| Per-wrapper random IDs for untrusted-content markers prevent marker spoofing | Strengthens content boundary enforcement |

**Assessment:** These are all net improvements. None require config changes. They reduce T1 attack surface without action from you.

### Threat T4: Lateral Movement (rated CRITICAL in colocation spec)

| Fix in v2026.2.21 | Impact on your setup |
|---|---|
| **Heredoc substitution allowlist bypass blocked** | IMPORTANT. Patched a real escape vector from exec allowlists. Your `workspaceOnly` config was the application-level boundary; the dedicated user + filesystem permissions were the OS boundary. This fix hardens the application layer. |
| **Shell startup-file env injection blocked** (`BASH_ENV`, `ENV`, `BASH_FUNC_*`, `LD_*`, `DYLD_*`) | IMPORTANT. This was a plausible privilege escalation vector for the dedicated `openclaw` user. If an attacker could set these env vars, they could execute arbitrary code before any shell command. Now blocked at ingestion. |
| **MEDIA tool attachments restricted** to core tools and OpenClaw temp root | Prevents untrusted MCP tools from exfiltrating files outside the expected paths. Relevant because vault is mounted read-only to the `openclaw` user. |
| **Browser navigation protocols blocked** (`file:`, `data:`, `javascript:`) | Even though browser is disabled, this hardens the stack defensively. |
| **Symlink escape in browser uploads blocked** | Same — defensive hardening even if browser is off. |
| **Prototype pollution blocks** in webhook templates, `/debug` overrides, device-token scope | Prevents several classes of injection that could have escalated privileges. |
| **Systemd unit env value CR/LF injection blocked** | You're on macOS (launchd), so not directly relevant, but shows the project is thinking about these vectors. |
| **SHA-1 → SHA-256** for gateway locks and tool-call IDs | Strengthens hash basis. No config change needed. |

**Assessment:** The heredoc bypass and env injection fixes are the most significant for your deployment. These close real gaps in the application-level boundary. The OS-level boundary (dedicated user, filesystem permissions, crumbvault group) was always the backstop — these fixes mean the application layer is no longer a weak link in the chain.

### Threat T2: Data Exfiltration (rated MEDIUM in colocation spec)

| Fix in v2026.2.21 | Impact on your setup |
|---|---|
| Cross-origin redirect credential stripping in `fetchWithSsrFGuard` | Prevents authorization headers from leaking on redirect. Relevant for any web access Tess does. |
| WhatsApp reaction JID authorization enforcement | Not relevant (you're on Telegram). |

**Assessment:** Minor improvements. No action needed.

### Threat T3: Denial of Service (rated LOW in colocation spec)

| Fix in v2026.2.21 | Impact on your setup |
|---|---|
| Embedded Pi runner retry loop capped (32-160 attempts) | Prevents unbounded retry cycles that could consume resources. |
| Compaction overflow retry budgeting now global | Prevents successful truncation from resetting retry counter. |
| Memory QMD embed runs serialized globally with failure backoff | Prevents CPU storms on multi-agent hosts. |

**Assessment:** All good. No action needed.

---

## 3. CRUMB-TESS BRIDGE IMPACT

The bridge uses the `_openclaw/inbox` and `_openclaw/outbox` directories for filesystem-based communication between Tess (OpenClaw) and Crumb, with Telegram as the messaging transport.

### What could break the bridge:

**Gateway auth changes:** The bridge communicates via filesystem, not via the gateway API. Gateway auth changes don't affect it.

**Telegram channel changes:** The streaming config simplification (`channels.telegram.streaming` → boolean) could theoretically affect how responses are delivered, but the bridge operates at the message level, not the streaming level. Tess receives a message via Telegram, processes it, and writes to the filesystem. The streaming change affects *display*, not *processing*.

**Memory/QMD changes:** The QMD overhaul is significant (search ranking, race conditions, session memory persistence). If Tess uses memory search against the vault, the QMD fixes could change what results are returned. This is likely an *improvement* (better ranking, fewer race conditions), but worth testing — send Tess a query that requires vault search and verify the results are reasonable.

**Exec hardening:** The heredoc bypass fix and env injection blocking could theoretically affect bridge scripts if they use heredocs or rely on inherited environment variables. However, the bridge communication is filesystem-based (JSON files in `_openclaw/inbox` and `_openclaw/outbox`), not exec-based. **No impact expected.**

**Session startup change:** "Require `/new` and `/reset` greeting path to run Session Startup file-reading instructions before responding" — this means Tess will now properly load session context on fresh sessions. This is an **improvement** for the bridge, not a risk.

### Bridge verdict: LOW RISK

The bridge should work without modification. The filesystem-based communication pattern is entirely decoupled from the changes in this release. The Telegram transport layer has streaming changes but nothing that affects message delivery semantics.

---

## 4. CONFIG CHANGES NEEDED

### Required before update:

None. The update should be safe to apply as-is.

### Recommended after update:

1. **Verify Telegram streaming** — Send a test message to Tess, confirm responses arrive correctly. If streaming is broken, set `channels.telegram.streaming: true` explicitly.

2. **Check `openclaw doctor`** — Run `openclaw doctor --fix` post-update to see if any new config keys are recommended or if any of your hardening config keys get stripped (like `tools.browser.enabled` was in v2026.2.17).

3. **Verify memory/search** — Send Tess a vault search query and confirm results are reasonable. QMD changes could affect ranking.

4. **Monitor token costs** — The new `maxSpawnDepth: 2` default means Tess could spawn subagents. Watch for unexpected cost increases over the next few days.

5. **Check gateway password** — You rotated after OC-012. Confirm the rotated password still works post-update (it should — gateway auth mode/config isn't changing).

---

## 5. COLOCATION SPEC UPDATES NEEDED

The following items in the colocation spec are now addressed by the release and should be annotated:

1. **Tier 1 hardening notes:** Add that v2026.2.21 now blocks exec heredoc bypass and env injection vectors that were previously only mitigated by OS-level boundaries.

2. **Threat model T4:** Add note that application-level lateral movement mitigations are significantly stronger in v2026.2.21. The OS boundary (dedicated user) remains important as defense-in-depth but is no longer the sole effective control.

3. **Browser config note:** The existing note about `tools.browser.enabled` being stripped by `doctor --fix` can be updated — browser sandbox defaults have been hardened upstream. Browser control may be moving to a different mechanism.

4. **QMD section:** If you add the qmd enablement task (discussed in last session), note that v2026.2.21 has significant QMD fixes for search ranking and race conditions.

---

## 6. UPDATE PROCEDURE

```bash
# From tess user on the Studio:

# 1. Stop OpenClaw
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw gateway stop'

# 2. Verify stopped (kill-switch pattern from colocation spec)
sudo -u openclaw bash -c 'ps aux | grep openclaw'
# If still running:
sudo pkill -u openclaw

# 3. Update
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && npm update -g openclaw'

# 4. Run doctor
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw doctor --fix'

# 5. Review any config changes doctor made
sudo cat /Users/openclaw/.openclaw/openclaw.json

# 6. Restart
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw gateway start'

# 7. Verify
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw status'

# 8. Test Telegram — send a message to Tess, verify response
# 9. Test bridge — drop a test file in _openclaw/inbox, verify processing
# 10. Monitor costs for 48 hours
```
