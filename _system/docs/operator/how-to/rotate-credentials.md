---
type: how-to
status: active
domain: software
created: 2026-03-14
updated: 2026-07-05
tags:
  - system/operator
topics:
  - moc-crumb-architecture
---

# How to Rotate Credentials

**Problem:** An API key has expired, been compromised, or needs regular rotation. You need to update it without breaking dependent services.

**Architecture source:** [[infrastructure-reference]] §Credentials

**2026-07-05 rebuild note:** Last updated 2026-04-11, before the mid-June agentic-sunset decommission removed the Tess/OpenClaw layer. Credentials whose only consumer was that layer (OpenClaw gateway token, Telegram bot tokens, X/Twitter OAuth, and effectively OpenRouter — see below) have no live consumer left. Rather than delete those rows outright, they're moved to **Candidates for Revocation** so the operator can decide whether to actually revoke them at the provider. Live rows are re-verified against current scripts, plists, and Keychain/gh config as of 2026-07-05 — not just copied from the prior doc.

---

## Credential Locations (live consumers only)

| Credential | Storage | Path | Consumers | Verified |
|-----------|---------|------|-----------|----------|
| Anthropic API key | macOS Keychain | `Claude Code-credentials` entry | Crumb (Claude Code) | Keychain entry confirmed present |
| OpenAI API key | Env file | `~/.config/crumb/.env` | peer-review, code-review, deliberation dispatch agents | Grep hit in `.claude/agents/{peer-review,code-review,deliberation}-dispatch.md` |
| Gemini API key | Env file | `~/.config/crumb/.env` | peer-review, deliberation dispatch agents | Same as above |
| DeepSeek API key | Env file | `~/.config/crumb/.env` | peer-review, deliberation dispatch agents | Same as above |
| xAI/Grok API key | Env file | `~/.config/crumb/.env` | peer-review, deliberation dispatch agents; `.claude/skills/peer-review/SKILL.md` | Same as above |
| GitHub auth | `gh` CLI token store | `~/.config/gh/hosts.yml` | Git push/pull to github.com and gist.github.com | `git config --list --show-origin` shows `credential.https://github.com.helper=!gh auth git-credential` overriding the generic `osxkeychain` default; `gh auth status` confirms active login (`djt71`, scopes `gist`, `read:org`, `repo`) |
| Cloudflare tunnel credentials | Local cert + JSON credentials file (NOT Keychain) | `~/.cloudflared/cert.pem` + `~/.cloudflared/<tunnel-id>.json` | `com.crumb.cloudflared` | Confirmed via `~/.cloudflared/config.yml` (`credentials-file:` points at the JSON) |
| Google Workspace OAuth (workspace-mcp) | Token store | `~/.google_workspace_mcp/credentials/` + `~/.config/gws` | Gmail/Calendar/Drive/Contacts MCP tools (`workspace-mcp`) | Directory recently modified (same-day); actively used this session — **not documented in the 2026-04-11 doc, added here** |

**Corrections from the 2026-04-11 doc:**
- **GitHub PAT** was previously documented as "macOS Keychain (credential-osxkeychain)". Live config actually routes github.com/gist.github.com auth through `gh auth git-credential`, which reads `gh`'s own token store — the generic `osxkeychain` helper is only the fallback for other hosts. Rotation now goes through `gh auth login`/`gh auth refresh`, not raw Keychain edits.
- **Cloudflare tunnel token** was previously documented as macOS Keychain. It is actually a local `cert.pem` + tunnel-scoped JSON credentials file under `~/.cloudflared/`, unrelated to Keychain.
- **Google Workspace OAuth** had no row at all in the prior doc despite being a live, actively-used credential.

---

## Candidates for Revocation (no live consumer found)

These credentials' only known consumers were the Tess/OpenClaw layer or the feed-intel framework, both dead as of the 2026-06-11/12 decommission (agentic-sunset AS-030, tess-v2 closed `phase: DONE`). Grep of `_system/scripts/` and `.claude/` found no live script or skill referencing any of these. **Not deleted from the record** — flagged for an operator decision on whether to actually revoke at the provider.

| Credential | Storage | Former Consumer | Status |
|-----------|---------|-----------------|--------|
| OpenRouter API key | `~/.config/crumb/.env` (key name confirmed present) | Tess Voice cloud inference (Kimi K2.5 primary, Qwen 3.6 failover) | Tess Voice / tess-v2 runtime is fully decommissioned (`com.tess.llama-server`, `ai.openclaw.*` all gone from disk). Zero references in `_system/scripts/` or `.claude/`; all remaining mentions are in `Projects/tess-v2/` design docs (project closed DONE 2026-06-14). Revocation candidate. |
| OpenClaw gateway token | `/Users/openclaw/.openclaw/openclaw.json` | OpenClaw gateway auth | `ai.openclaw.gateway` LaunchDaemon confirmed absent from `/Library/LaunchDaemons/`; no process, no plist anywhere. Revocation candidate (also consider whether the `openclaw` user account itself should be removed — out of scope for this doc). |
| Telegram bot token(s) | Was: LaunchAgent plist env vars | Was: `ai.openclaw.awareness-check`, `health-ping`, `vault-health`, `backup-status` (Tess messaging) | None of the current `com.crumb.*` plists (checked all 11 directly) carry a Telegram token in `EnvironmentVariables`. The messaging layer these tokens served is gone. **Operator decision 2026-07-06: keep dormant.** Consumer check completed same day — `vault-health.sh` and `backup-status.sh` scripts (not just plists) verified zero Telegram references. |
| X (Twitter) OAuth | Keychain (dynamic, auto-refresh) | feed-intel framework | feed-intel-framework ARCHIVED 2026-07-05; repos + `~/.config/fif/` (env.sh/run.sh local copies) deleted. No live consumer. **Revocation candidate — provider-side revocation still pending.** |
| Mistral API key | `~/.config/crumb/.env` (key name confirmed present) | Not found in the 2026-04-11 doc; grep shows only `Projects/tess-v2/` and `Projects/mission-control/` design-doc mentions, both non-code | No script or skill consumer found. Likely dead-project residue (mission-control is `status: paused`, tess-v2 is DONE). **REVOKED 2026-07-06** — operator revoked at the Mistral console; `.env` line removed same day (dated backup deleted after revocation). |
| Lucidchart API key (`LUCID_API_KEY`) | `~/.config/crumb/.env` (key name confirmed present) | Was: `lucidchart` skill | No `lucidchart` skill exists in `.claude/skills/` (current skill roster has `mermaid`, which per its description is "the default for all diagram/chart requests" and also covers Excalidraw). `setup-crumb.sh` still checks for the key's presence as an optional pass, but nothing consumes it. **REVOKED 2026-07-06** — operator revoked at the Lucid console; `.env` line removed same day (dated backup deleted after revocation). `setup-crumb.sh` optional-pass check now expected to report absent. |

---

## Rotation Procedure

### For `~/.config/crumb/.env` keys (OpenAI, Gemini, DeepSeek, xAI)

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
5. **Test:** Run the skill that uses the key. For peer-review/code-review/deliberation keys, run:
   ```
   "peer review this file" / "code review this change" (in a Crumb session)
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

### For GitHub auth (gh CLI, not raw Keychain)

1. Run:
   ```bash
   gh auth refresh -h github.com -s repo,read:org,gist
   ```
   or, to fully re-authenticate:
   ```bash
   gh auth login
   ```
2. Verify:
   ```bash
   gh auth status
   ```
3. No manual Keychain edit needed — `gh` manages its own token store at `~/.config/gh/hosts.yml`, and `git`'s `credential.https://github.com.helper` is already wired to call `gh auth git-credential`.

### For Cloudflare tunnel credentials

1. In the Cloudflare Zero Trust dashboard, rotate/reissue the tunnel credentials for tunnel ID recorded in `~/.cloudflared/config.yml` (`credentials-file:` field).
2. Download the new JSON credentials file to `~/.cloudflared/<tunnel-id>.json` (matching the path in `config.yml`).
3. Restart the tunnel:
   ```bash
   launchctl bootout gui/$(id -u)/com.crumb.cloudflared
   launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.crumb.cloudflared.plist
   ```
4. **Test:** `curl -I https://mc.crumbos.dev` — note this will only succeed end-to-end once `com.crumb.dashboard` is also loaded (it's currently parked; see infrastructure-reference).

### For Google Workspace OAuth (workspace-mcp)

1. Token refresh is normally automatic. If auth breaks (401/invalid_grant errors from Gmail/Calendar/Drive tools):
   ```bash
   # re-run the workspace-mcp OAuth flow — check current binary/config first
   ~/.local/bin/workspace-mcp --help   # confirm invocation; exact re-auth flag not verified in this pass
   ```
2. Token store lives at `~/.google_workspace_mcp/credentials/` and `~/.config/gws` — clearing these forces a fresh OAuth consent flow on next use.
3. **Test:** run a simple Gmail/Calendar MCP tool call and confirm it returns data without an auth error.

### For Candidates for Revocation

Before revoking any credential in that section, confirm no dormant script depends on it (the grep pass here covered `_system/scripts/` and `.claude/` only — one pass, not exhaustive). Then:
1. Revoke/delete the key or token at the provider (OpenRouter dashboard, BotFather, X developer portal, Mistral/Lucid consoles, OpenClaw config).
2. Remove the corresponding line from `~/.config/crumb/.env` (or the OpenClaw/Telegram/X storage location) once confirmed safe.
3. Log the revocation decision in the relevant project's run-log (agentic-sunset AS-032 external-artifact sweep is already tracking residual cloud-side cleanup — these credential revocations fit that same sweep).

---

## Validation Checklist

After rotation, verify:

- [ ] New key accepted by the provider (no 401/403 errors)
- [ ] Dependent skills/services work (run a test invocation)
- [ ] Old key revoked at the provider (prevents reuse)
- [ ] File permissions correct (`chmod 600` for env files)
- [ ] No keys committed to git (`.env` is gitignored; verify with `git status`)
- [x] For plist-embedded credentials: resolved 2026-07-06 — `HEALTHCHECKS_API_KEY` stripped from the parked `com.crumb.dashboard` plist (healthchecks service has no live consumer); key revoked at healthchecks.io by operator same day. If the dashboard is revived and needs healthchecks again, issue a fresh key and store per the Keychain-not-env convention

---

**Done criteria:** New key in place, old key revoked, dependent services verified working, permissions correct. For revocation candidates: operator has explicitly decided keep vs. revoke — do not silently drop the row without that decision being logged.
