---
project: null
domain: software
type: runbook
skill_origin: systems-analyst
status: active
created: 2026-06-08
updated: 2026-06-08
tags:
  - migration
  - runbook
  - launchd
  - keychain
  - system/operator
---

# Tess → Danny Account Migration Runbook

Relocate the entire Crumb operation from the macOS user `tess` to the user `danny`,
running as `danny` going forward, and retiring `tess`. Copy-and-verify strategy:
nothing on `tess` is deleted until `danny` is verified green over a soak window.

## Decisions (locked 2026-06-08)

| Decision | Value |
|---|---|
| Scope | **Full stack** — vault + all sibling data + agent runtime + ML/model infra |
| Run-as user after cutover | **danny** (launchd agents bootstrapped in danny's session) |
| Old account | **Retire tess** (clean cutover; originals kept as rollback until verified) |
| ML/model infra | **Migrate** (`models/`, `llama.cpp/`, `.ollama/`, `sd-env/`, `llm-eval/`) |
| danny admin/sudo | **Grant** (added to admin group before P1) |
| Strategy | Copy → rewrite → rebuild → re-key → stand up → verify → retire |

## Critical risks (read before starting)

1. **Keychain secrets do not migrate.** `tess`'s login keychain holds the live
   credentials; plists carry no inline secrets — they read from keychain or
   `openclaw.json`. Every item must be re-added to `danny`'s keychain by hand
   (P3). Miss one → the dependent agent fails silently at next fire.
2. **Python venvs are not relocatable.** `.hermes/hermes-agent/venv` (700M) and
   openclaw repo venvs hardcode `/Users/danny` in shebangs + `pyvenv.cfg`.
   **Recreate**, do not copy (P4).
3. **launchd is per-user + session-bound.** danny's agents must be bootstrapped
   from danny's GUI login (`launchctl bootstrap gui/$(id -u danny)`). danny being
   admin lets danny self-recover; bootstrap still happens from danny's session.
4. **Four plists use `StartCalendarInterval`** which never fires on macOS 26.x
   (see [[macos-tahoe-calendarinterval-bug]]). Fix to `StartInterval` during the
   rewrite pass: `ai.openclaw.vault-health`, `com.crumb.qmd-index`,
   `com.crumb.vault-gc`, `com.tess.vault-backup`.
5. **Re-auth required (not file-copyable):** `.cloudflared` tunnel, MCP OAuth
   (google-workspace, Gmail), `gh` CLI (`gh:github.com`), Claude Code login.
6. **Agent generation duplication.** `com.tess.*`, `com.tess.v2.*`, and
   `ai.openclaw.*` namespaces overlap (backup-status, daily-attention, health-ping,
   vault-health, vault-gc each appear 2×). Migration is the moment to keep ONE
   generation per function — do not blindly copy all 26.

## Inventory

### Data trees (≈12–15 GB total)

| Path | Size | Notes |
|---|---|---|
| `crumb-vault` | 361M | 329 self-referencing files; group `crumbvault` |
| `crumb-vault-mirror` | — | rsync mirror target |
| `quartz-vault` | — | published static site |
| `research-library` | 5.1G | ~200 path refs; group `crumbvault` |
| `crumb-apps/tess-v2` | 44M | 31 path refs |
| `openclaw/` (7 repos) | 451M | book-scout, crumb-dashboard, crumb-tess-bridge, feed-intel-framework, opportunity-scout, semuta, x-feed-intel |
| `.hermes/` | 2.7G | hermes-agent + venv (700M) + logs + memories |
| `.local/` | 1.7G | bin, pipx, share, state |
| `.claude/` | 15M | memory dir keyed `-Users-tess-crumb-vault` |
| `.openclaw/`, `.tess/`, `.config/tess`, `.cloudflared`, `.codex`, `.google_workspace_mcp` | small | hidden state — easy to miss |
| `models/`, `llama.cpp/`, `.ollama/`, `sd-env/`, `llm-eval/` | large | ML/model infra |

### Keychain items to re-key into danny's login keychain

`anthropic-api-key` · `x-feed-intel.anthropic-api-key` · `x-feed-intel.telegram-bot-token` ·
`x-feed-intel.telegram-chat-id` · `x-feed-intel.twitterapi-io-key` · `x-feed-intel.x-access-token` ·
`book-scout.annas-archive-api-key` · `google-oauth-client-id` · `google-oauth-client-secret` ·
`tess-approval-bot-token` · `tess-awareness-bot-token` · `gh:github.com` · `Claude Code-credentials` ·
Obsidian / Google "Safe Storage" entries (recreated on first app launch as danny).

### Crumb-owned launchd agents (migrate; prune duplicates)

KeepAlive (long-running): `ai.hermes.gateway`, `ai.openclaw.bridge.watcher`,
`com.crumb.cloudflared`, `com.crumb.dashboard`, `com.crumb.vault-web`,
`com.tess.llama-server`, `homebrew.mxcl.ollama` (brew-managed — handle via `brew services`).

Scheduled: `ai.openclaw.awareness-check`, `ai.openclaw.daily-attention`,
`ai.openclaw.health-ping`, `ai.openclaw.vault-health`†, `com.crumb.qmd-index`†,
`com.crumb.system-stats`, `com.crumb.telemetry-rollup`, `com.crumb.vault-gc`†,
`com.crumb.vault-rebuild`, `com.tess.backup-status`, `com.tess.nemotron-load`,
`com.tess.vault-backup`†, plus the `com.tess.v2.*` set (backup-status, daily-attention,
health-ping, vault-gc, vault-health). `disabled/`: email-triage ×2.

† = convert `StartCalendarInterval` → `StartInterval`.
**Skip (not ours):** `com.google.GoogleUpdater.wake`, `com.google.keystone.*`.

---

## Procedure

### P0 — Freeze & pre-flight (run as tess)

1. **Commit/push every repo.** Vault currently has uncommitted changes.
   ```sh
   cd /Users/danny/crumb-vault && git add -A && git commit -m "pre-migration snapshot" && git push
   for d in /Users/danny/openclaw/*/; do (cd "$d" && git add -A && git commit -m "pre-migration snapshot" 2>/dev/null && git push 2>/dev/null); done
   ```
2. **Capture secret inventory** to a checklist file (names only, values pulled at P3):
   ```sh
   security dump-keychain ~/Library/Keychains/login.keychain-db | grep -A1 '"svce"' > ~/migration-keychain-manifest.txt
   ```
3. **Inventory running services** for the verification baseline:
   ```sh
   launchctl list | grep -Ei 'hermes|openclaw|crumb|tess|ollama' > ~/migration-services-before.txt
   ```
4. **Grant danny admin:** System Settings → Users & Groups → danny → "Allow to
   administer this computer" (or `sudo dseditgroup -o edit -a danny -t user admin`).
5. **Stop tess's agents** so nothing writes mid-copy (bootout, do not delete plists):
   ```sh
   for f in ~/Library/LaunchAgents/{ai.hermes,ai.openclaw,com.crumb,com.tess}*.plist; do
     launchctl bootout gui/$(id -u) "$f" 2>/dev/null; done
   ```

### P1 — Bulk copy tess → danny (run as tess with sudo, or danny with sudo)

Copy each tree, preserve attrs, **exclude venvs / caches / .git-internal churn**.
Recreate venvs in P4.

```sh
DEST=/Users/danny
for tree in crumb-vault crumb-vault-mirror quartz-vault research-library crumb-apps \
            openclaw models llama.cpp sd-env llm-eval \
            .hermes .local .claude .config .openclaw .tess .cloudflared .codex \
            .ollama .google_workspace_mcp; do
  sudo rsync -aHAX --exclude 'venv/' --exclude '__pycache__/' --exclude 'node_modules/' \
    "/Users/danny/$tree" "$DEST/"
done
sudo chown -R danny:staff /Users/danny/{crumb-vault,research-library,...}   # see note
# Group-owned trees keep group crumbvault (danny is already a member):
sudo chown -R danny:crumbvault /Users/danny/{crumb-vault,crumb-vault-mirror,research-library,.google_workspace_mcp}
```
Note: `.ssh` is intentionally NOT copied — danny generates/regisers its own keys if
needed (remotes are HTTPS, so git push uses the `gh:github.com` keychain cred instead).

### P2 — Path rewrite (run as danny)

Rewrite `/Users/danny` → `/Users/danny` across **text files only**, excluding
`.git/`, `node_modules/`, `venv/`, and binaries.

```sh
cd /Users/danny
grep -rIl --exclude-dir=.git --exclude-dir=node_modules --exclude-dir=venv \
  "/Users/danny" crumb-vault openclaw crumb-apps research-library .hermes .config .claude \
  | while read -r f; do sed -i '' 's#/Users/danny#/Users/danny#g' "$f"; done

# Shell profiles
sed -i '' 's#/Users/danny#/Users/danny#g' /Users/danny/.zshrc /Users/danny/.zprofile

# Obsidian vault registration
#   edit ~/Library/Application Support/obsidian/obsidian.json → path /Users/danny/crumb-vault

# Rename the path-keyed Claude memory dir
mv "/Users/danny/.claude/projects/-Users-tess-crumb-vault" \
   "/Users/danny/.claude/projects/-Users-danny-crumb-vault"
sed -i '' 's#-Users-tess-crumb-vault#-Users-danny-crumb-vault#g; s#/Users/danny#/Users/danny#g' \
   /Users/danny/.claude/projects/-Users-danny-crumb-vault/memory/*.md
```
Verify zero stragglers (outside .git): `grep -rI --exclude-dir=.git "/Users/danny" /Users/danny/crumb-vault | head`.

### P3 — Credentials (run as danny; needs secret values)

For each name in the manifest, add to danny's login keychain:
```sh
security add-generic-password -a danny -s "anthropic-api-key" -w "<value>" -U
# …repeat for every item in migration-keychain-manifest.txt
```
Then re-auth the interactive ones:
- `gh auth login` (restores `gh:github.com`, enables git push as danny)
- `cloudflared tunnel login` (or copy cert.pem if tunnel UUID is reused)
- Claude Code: launch as danny, sign in (`Claude Code-credentials`)
- MCP google-workspace / Gmail: trigger OAuth on first tool use as danny

### P4 — Runtime rebuild (run as danny)

```sh
# Hermes agent venv
cd /Users/danny/.hermes/hermes-agent
python3 -m venv venv && source venv/bin/activate && pip install -e . && deactivate
# Each openclaw repo with a venv
for d in /Users/danny/openclaw/*/; do
  [ -f "$d/requirements.txt" ] && (cd "$d" && python3 -m venv venv && \
    ./venv/bin/pip install -r requirements.txt); done
# npm-based services (dashboard etc.)
for d in /Users/danny/openclaw/*/; do [ -f "$d/package.json" ] && (cd "$d" && npm ci); done
# Ollama / llama models: verify model paths resolve under /Users/danny
```

### P5 — launchd install under danny (run as danny)

1. Copy the **rewritten** plists into danny's LaunchAgents, **pruning duplicate
   generations** (keep one per function — decide com.tess.* vs com.tess.v2.* vs ai.openclaw.*):
   ```sh
   cp /Users/danny/Library/LaunchAgents-staged/*.plist ~/Library/LaunchAgents/  # after rewrite+prune
   ```
2. **Fix the 4 calendar-interval plists** to `StartInterval` before loading.
3. Bootstrap into danny's session:
   ```sh
   for f in ~/Library/LaunchAgents/{ai.hermes,ai.openclaw,com.crumb,com.tess}*.plist; do
     launchctl bootstrap gui/$(id -u) "$f"; done
   brew services start ollama   # homebrew-managed agent
   ```

### P6 — Verification gates (run as danny — all must pass before P7)

- [ ] `launchctl list | grep -Ei 'hermes|openclaw|crumb'` matches the before-baseline (minus pruned dupes)
- [ ] Gateway healthy (`ai.hermes.gateway` log shows clean start)
- [ ] Dashboard reachable; cloudflared tunnel up
- [ ] `_system/scripts/vault-check.sh` passes
- [ ] `_system/scripts/session-startup.sh` runs clean as danny
- [ ] One scheduled agent fires on its interval (watch a log)
- [ ] Telegram bots respond (approval + awareness)
- [ ] `git push` from vault works as danny
- [ ] Feed pipeline / a representative openclaw job runs end-to-end
- [ ] Obsidian opens the vault from danny's session

### P7 — Retire tess (after agreed soak window, e.g. 48–72h green)

1. Permanently disable tess agents: `launchctl bootout` (already done) + move
   `~/Library/LaunchAgents/*.plist` to a `tess-retired/` archive.
2. Reclaim space: archive or remove the tess-side copies once danny is authoritative.
3. Update any docs still naming tess as the operator (most rewritten in P2).
4. Final commit on the vault from danny; update `claude-ai-context.md`.

## Rollback

Until P7, rollback is cheap: re-bootstrap tess's agents
(`launchctl bootstrap gui/$(id -u tess) <plist>` from tess's session), point
Obsidian back to `/Users/danny/crumb-vault`. tess copies are untouched through P6.

## Open items to resolve during execution

- **Duplicate-agent pruning:** decide the canonical generation per function
  (com.tess.* legacy vs com.tess.v2.* vs ai.openclaw.*) — see [[recurring-patterns]].
- **`homebrew.mxcl.ollama`** is brew-managed; migrate via `brew services`, not a copied plist.
- **`.cloudflared` tunnel UUID:** reuse (copy cert) vs fresh tunnel — affects DNS/ingress.
- **Personal Library data** (Mail, Messages, Photos) is account-personal and out of scope.
