---
type: how-to
status: active
domain: software
created: 2026-03-14
updated: 2026-04-11
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How to Rotate Credentials

**Problem:** An API key has expired, been compromised, or needs regular rotation. You need to update it without breaking dependent services.

**Architecture source:** [[infrastructure-reference]] §Credentials

---

## Credential Locations

| Credential | Storage | Path | Consumers |
|-----------|---------|------|-----------|
| Anthropic API key | macOS Keychain | `Claude Code-credentials` entry | Crumb (Claude Code) |
| OpenAI API key | Env file | `~/.config/crumb/.env` | peer-review, code-review |
| Gemini API key | Env file | `~/.config/crumb/.env` | peer-review |
| DeepSeek API key | Env file | `~/.config/crumb/.env` | peer-review |
| xAI/Grok API key | Env file | `~/.config/crumb/.env` | peer-review |
| OpenRouter API key | Env file | `~/.config/crumb/.env` | Tess Voice (Kimi K2.5 / Qwen 3.6) |
| GitHub PAT | macOS Keychain | `credential-osxkeychain` cache | Git push/pull |
| OpenClaw token | Config file | `/Users/openclaw/.openclaw/openclaw.json` | Gateway auth |
| Telegram bot tokens | Plist env vars | LaunchAgent plists | awareness-check, health-ping, scout services |
| Cloudflare tunnel token | macOS Keychain | Keychain entry | `com.crumb.cloudflared` (dashboard remote access) |
| X OAuth | Keychain (dynamic) | Auto-refresh | feed-intel framework |

---

## Rotation Procedure

### For `~/.config/crumb/.env` keys (OpenAI, Gemini, DeepSeek, xAI, OpenRouter)

1. Generate a new key from the provider's dashboard
2. Edit the env file:
   ```bash
   nano ~/.config/crumb/.env
   ```
3. Replace the old key value
4. Save and verify permissions:
   ```bash
   chmod 600 ~/.config/crumb/.env
   ```
5. **Test:** Run the skill that uses the key. For peer-review keys, run:
   ```
   "peer review this file" (in a Crumb session)
   ```
   Verify the provider's model responds without auth errors.

### For Anthropic API key (Keychain)

1. Delete the old credential:
   ```bash
   security delete-generic-password -s "Claude Code-credentials" ~/Library/Keychains/login.keychain-db
   ```
2. Re-authenticate:
   ```bash
   claude /login
   ```
3. If done from SSH, the new credential works from both local and SSH sessions.

### For GitHub PAT

1. Generate a new fine-grained token at https://github.com/settings/tokens
2. The next `git push` or `git fetch` will prompt for credentials
3. Enter username + new PAT as password
4. macOS Keychain caches the new credential automatically

### For OpenClaw tokens

1. Stop the gateway:
   ```bash
   sudo launchctl bootout system/ai.openclaw.gateway
   ```
2. Edit the config:
   ```bash
   sudo -u openclaw nano /Users/openclaw/.openclaw/openclaw.json
   ```
3. Update the token value
4. Start the gateway:
   ```bash
   sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
   ```
5. Re-establish Telegram DM pairing (send a message to Tess)

### For Telegram bot tokens

1. Update the token in the relevant LaunchAgent plist(s)
2. Reload the affected service:
   ```bash
   launchctl bootout gui/$(id -u)/<label>
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
   ```

### For OpenRouter API key

1. Generate a new key at https://openrouter.ai/keys
2. Update `~/.config/crumb/.env`: `OPENROUTER_API_KEY=...`
3. Test: send a Telegram message to Tess Voice — verify response via Kimi K2.5. If OpenRouter is unreachable, the gateway fails over to Qwen 3.6 (same key).

---

## Validation Checklist

After rotation, verify:

- [ ] New key accepted by the provider (no 401/403 errors)
- [ ] Dependent skills/services work (run a test invocation)
- [ ] Old key revoked at the provider (prevents reuse)
- [ ] File permissions correct (`chmod 600` for env files)
- [ ] No keys committed to git (`.env` is gitignored; verify with `git status`)

---

**Done criteria:** New key in place, old key revoked, dependent services verified working, permissions correct.
