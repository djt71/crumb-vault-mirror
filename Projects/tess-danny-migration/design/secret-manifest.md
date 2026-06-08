---
project: tess-danny-migration
domain: software
type: decision
status: active
created: 2026-06-08
updated: 2026-06-08
task: TDM-003
---

# TDM-003 — Secret Manifest (consumer-mapped)

Secrets split into two tiers. **Only Tier A needs manual re-keying** (per-user
keychain). Tier B is file-based and copies with the migration — though OAuth tokens
may still need a re-auth if bound. This shrinks the runbook's original "re-add every
keychain item" (TDM-030) to ~11 items.

> Values are never recorded here — names + consumers only. Pull values at re-key time.

## Tier A — macOS login keychain (MANUAL re-key on danny → TDM-030)

| Item | Consumer(s) |
|---|---|
| `anthropic-api-key` | tess-v2 dispatch, hermes, awareness-check, health-check |
| `tess-approval-bot-token` | openclaw Telegram approval bot |
| `tess-awareness-bot-token` | openclaw awareness-check bot |
| `x-feed-intel.anthropic-api-key` | `openclaw/x-feed-intel` |
| `x-feed-intel.telegram-bot-token` | x-feed-intel delivery |
| `x-feed-intel.telegram-chat-id` | x-feed-intel delivery |
| `x-feed-intel.twitterapi-io-key` | x-feed-intel capture |
| `x-feed-intel.x-access-token` | x-feed-intel X API |
| `book-scout.annas-archive-api-key` | `openclaw/book-scout` |
| `google-oauth-client-id` | google-workspace / calendar / email |
| `google-oauth-client-secret` | google-workspace / calendar / email |

## Tier A′ — keychain, re-auth via tool (not `security add` → TDM-031)

| Item | Re-auth path |
|---|---|
| `gh:github.com` | `gh auth login` (git push for all repos) |
| `Claude Code-credentials` | Claude Code sign-in as danny |
| Obsidian / Google "Safe Storage" | recreated on first app launch as danny |

## Tier B — config files (copy with migration; re-auth only if token-bound)

| File | Holds | Consumer | Re-auth? |
|---|---|---|---|
| `.openclaw/openclaw.json` (+`.bak*`) | gateway/device `password` | openclaw gateway/bridge | copies — no |
| `.openclaw/identity/device-auth.json` | `deviceId`, `token(s)` | openclaw device identity | copies — verify on danny |
| `.config/gws/client_secret.json` | Google OAuth client (`client_id`/`secret`/`project_id`) | google-workspace MCP | copies — no |
| `.config/gws/token_cache.json` | Google OAuth access/refresh tokens | google-workspace MCP | copies; **re-auth if refresh fails** |
| `.config/tess/health-check.env` | `ANTHROPIC_API_KEY` (env form, dup of keychain) | `tess-health-check.sh` | copies — no |
| (plist comment) `HEALTHCHECKS_API_KEY` | healthchecks.io ping token | health-ping dead-man switch | trace to source at TDM-030 |

## Impact on tasks.md
- **TDM-030** scope = the 11 Tier-A items only (not "every secret"). Tier B rides the rsync.
- **TDM-031** adds the Tier-A′ re-auths (gh, Claude Code, + Google OAuth token refresh if needed).
- **TDM-011** snapshot must capture Tier-A names (done via `security dump-keychain`).
