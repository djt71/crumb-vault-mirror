---
project: null
domain: software
type: runbook
skill_origin: inbox-processor
status: active
created: 2026-02-20
updated: 2026-04-11
tags:
  - setup
  - deployment
  - runbook
  - system/operator
---

# Crumb Deployment Runbook

Complete guide for deploying Crumb on a fresh macOS machine. Covers both
the remote Mac (where Crumb runs) and the client machine (where you SSH from).

**Scope:** Crumb deployment and OpenClaw upgrade procedures. For full OpenClaw/Tess initial deployment, see [[crumb-studio-migration]].

**Audience:** Danny, future-Danny, or anyone Danny trusts with the vault.

**Time estimate:** ~45 minutes for a fresh machine, ~15 minutes if copying
configs from an existing setup (see [Migration from Existing Machine](#migration-from-existing-machine)).

---

## Architecture Overview

Crumb runs on a Mac (currently Mac Studio, user `tess`). You SSH in from a
work laptop or other machine. The vault lives on the remote Mac's local disk.

```
Client Machine (work laptop)              Remote Mac (Studio)
├── Alacritty or Apple Terminal     SSH → ├── Claude Code (native installer)
├── SSH config                            ├── tmux (session persistence)
└── Connection aliases                    ├── ~/crumb-vault/ (Obsidian vault)
                                          ├── ~/crumb-vault-mirror/ (GitHub mirror)
                                          ├── ~/.config/crumb/.env (API keys)
                                          ├── Obsidian.app (GUI, optional but enables CLI)
                                          └── bridge-watcher.py (launchd, watches _openclaw/inbox/)
```

---

# Fresh Install

## Phase 1: System Dependencies

Install these on the machine that will host the vault.

### 1.1 Xcode Command Line Tools

```bash
xcode-select --install
# Follow the GUI prompt. Takes a few minutes.
```

This provides `git`, `clang`, `make`, and other build essentials.

### 1.2 Homebrew

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Apple Silicon (M1/M2/M3/M4):** Homebrew installs to `/opt/homebrew`, not
`/usr/local`. After install, Homebrew prints PATH instructions. Run them:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

Verify: `brew --version`

### 1.3 Brew packages

```bash
brew install node python pipx jq tmux imagemagick exiftool ffmpeg repomix

```

### 1.4 Python tools

```bash
pipx ensurepath
pipx install 'markitdown[all]'
pip3 install Pillow
```

Close and reopen your terminal (or `source ~/.zshrc`) after `ensurepath`.

### 1.5 Verify dependencies

```bash
git --version && node --version && python3 --version && jq --version && \
  tmux -V && markitdown --version && \
  python3 -c "from PIL import Image; print('Pillow OK')"
```

All should return version info without errors.

---

## Phase 2: Claude Code

### 2.1 Install (native installer — NOT npm)

The npm version (`@anthropic-ai/claude-code`) uses a different auth flow that
breaks over SSH. Use the native installer:

```bash
curl -fsSL https://claude.ai/install.sh | sh
```

Binary installs to `~/.local/bin/claude`. Ensure it's on PATH:

```bash
echo $PATH | grep -q '.local/bin' && echo "OK" || echo "Add ~/.local/bin to PATH in ~/.zshrc"
```

If not on PATH, add to `~/.zshrc`:

```bash
export PATH="$PATH:$HOME/.local/bin"
```

### 2.2 Authenticate locally

This must be done from a **local terminal on the remote Mac**, not over SSH:

```bash
claude /login
# Follow the browser prompt
claude /status
# Should show: Opus 4.6 · Claude Max (or your subscription)
```

### 2.3 Fix Keychain ACL for SSH access

The Keychain credential created from a local GUI session has a restrictive ACL
that blocks SSH access. Delete and re-create it from an SSH session:

```bash
# Do this from an SSH session (not local terminal):
security delete-generic-password -s "Claude Code-credentials" ~/Library/Keychains/login.keychain-db
claude /login
# Authenticate again through the browser
```

The new credential will work from both local and SSH sessions.

---

## Phase 3: Git Identity & GitHub Access

A fresh Mac has no git identity. Set it before any commits:

### 3.1 Git identity

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

### 3.2 GitHub personal access token

Create a fine-grained token at https://github.com/settings/tokens:

- **Repository access:** Only select repositories → your crumb vault repo
- **Repository permissions:**
  - Contents: Read and write
  - Metadata: Read (auto-selected)
- **Expiration:** Your preference (regenerate when it expires)

Save the token — you'll need it for the clone in Phase 4. After the first
authenticated git operation, macOS Keychain (`credential-osxkeychain`) caches
it for future pushes.

---

## Phase 4: Vault Setup

### 4.1 Clone the vault

```bash
git clone https://github.com/<your-username>/crumb-vault.git ~/crumb-vault
```

When prompted for credentials, use your GitHub username and the PAT from
Phase 3 as the password.

Verify credential caching:

```bash
git -C ~/crumb-vault fetch    # should not prompt again
```

### 4.2 Run the setup script

```bash
bash ~/crumb-vault/_system/scripts/setup-crumb.sh ~/crumb-vault
```

This verifies all dependencies, fixes script permissions, installs the
pre-commit hook (vault-check.sh), and validates the vault. Fix any items
marked ✗ and re-run until all checks pass.

### 4.3 Create the API key file

```bash
mkdir -p ~/.config/crumb
touch ~/.config/crumb/.env
chmod 600 ~/.config/crumb/.env
```

Add these keys (get values from your password manager or existing machine):

```bash
# Tess Voice cloud inference (required)
OPENROUTER_API_KEY=sk-or-...

# Peer review (required for peer-review skill)
OPENAI_API_KEY=sk-...
GEMINI_API_KEY=AI...
DEEPSEEK_API_KEY=sk-...
XAI_API_KEY=xai-...
```

**Note:** An `ANTHROPIC_API_KEY` is only needed if Claude Code can't authenticate
via subscription (Keychain). Most setups don't need it — use subscription auth.

### 4.4 Cloudflare tunnel token (com.crumb.cloudflared, optional)

If remote dashboard access is desired, provision a Cloudflare tunnel and store
the token in the macOS Keychain. The `com.crumb.cloudflared` LaunchAgent
reads the token at startup and tunnels to the dashboard on demand.

---

## Phase 5: Shell & SSH Configuration (Remote Mac)

These settings fix keymapping, auth, and terminal issues for SSH sessions.

### 5.1 What to add to `~/.zshrc`

Your `~/.zshrc` needs these blocks:

1. **PATH** — Homebrew (Apple Silicon) and Claude Code binary
2. **TERM** — forces correct keymapping for SSH sessions (`export TERM=xterm-256color`)
3. **Backspace fix** — `bindkey` for `^H` and `^?`
4. **Keychain unlock** — auto-prompts for Keychain password on SSH login
5. **Claude alias** — passes TERM at launch time (TUI doesn't inherit shell TERM)

→ See the **Reference: Remote Mac ~/.zshrc** section in [[claude-code-ssh-setup]]
for the complete working config. Copy it verbatim.

### 5.2 tmux configuration

Create `~/.tmux.conf` with Ctrl+A prefix, mouse support, and Catppuccin Mocha
status bar.

→ See the **Reference: Remote Mac ~/.tmux.conf** section in [[claude-code-ssh-setup]]
for the complete working config.

---

## Phase 6: Client Machine

Do these on the machine you're SSHing **from**.

### 6.1 Terminal emulator

Pick one:

- **Apple Terminal** — maximum stability, zero config, no focus reporting bugs.
  Best for pure SSH work.
- **Alacritty** — GPU-accelerated, TOML config, font ligatures. Minor quirks
  possible. macOS Gatekeeper blocks it on first launch — approve in System
  Settings → Privacy & Security → "Open Anyway".
- **Ghostty** — NOT recommended for SSH to Claude Code. Focus reporting causes
  escape sequence leaks and intermittent keymapping breakage.

→ See [[claude-code-ssh-setup]] for full Alacritty config, Apple Terminal theme
setup, and Nerd Font installation.

### 6.2 Install a Nerd Font

```bash
brew install --cask font-fira-code-nerd-font
```

### 6.3 SSH config

Edit `~/.ssh/config`:

```
Host studio
    HostName 10.0.0.235        # replace with remote Mac's IP
    User tess                   # replace with remote username
    RequestTTY yes
    SetEnv TERM=xterm-256color
```

### 6.4 Connection alias (optional)

Add to `~/.zshrc` on the client:

```bash
alias studio='TERM=xterm-256color ssh -t tess@10.0.0.235'
```

---

## Phase 7: Verify Everything

### 7.1 Connect and test

```bash
ssh studio                    # or: studio
# Enter SSH password
# Enter Keychain password (automatic prompt)
tmux
cd ~/crumb-vault
claude
```

Claude Code should show your subscription (e.g., `Opus 4.6 · Claude Max`),
not `API Usage Billing`.

### 7.2 Run setup-crumb.sh one more time

```bash
bash ~/crumb-vault/_system/scripts/setup-crumb.sh ~/crumb-vault
```

All checks should pass.

### 7.3 Test a commit

Make a trivial change, commit, and verify:

- Pre-commit hook (vault-check.sh) runs and passes
- Post-commit hook (mirror-sync.sh) syncs to the mirror repo (if configured)

### 7.4 Troubleshooting

→ See the **Troubleshooting** section in [[claude-code-ssh-setup]] for a
comprehensive table of common issues (Keychain ACL, backspace, TERM, auth
conflicts, etc.).

---

## Phase 8: Optional Enhancements

### 8.1 GitHub mirror (for claude.ai context renewal)

```bash
cd ~
git clone https://<PAT>@github.com/<your-username>/crumb-vault-mirror.git
```

The vault's post-commit hook (`mirror-sync.sh`) auto-syncs allowlisted files
to this repo on every commit. The mirror is read-only for claude.ai sessions.

Verify the post-commit hook is active:

```bash
grep -q "mirror-sync" ~/crumb-vault/.git/hooks/post-commit && echo "OK" || echo "Missing"
```

### 8.2 Obsidian

Download from obsidian.md. Open the vault at `~/crumb-vault`.

The vault works without Obsidian (it's just markdown + git), but Obsidian
provides the GUI for browsing, graph view, and the Excalidraw plugin. The
Obsidian CLI (`obsidian` command) is used by Crumb for indexed queries —
it requires Obsidian to be running.

**Add Obsidian as a login item** so the CLI is available for SSH sessions:

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Obsidian.app", hidden:true}'
```

Verify:

```bash
osascript -e 'tell application "System Events" to get the name of every login item'
```

**Important:** Close Obsidian before any `git mv` operations. Both Obsidian and
Claude Code can run simultaneously — `workspace.json` is gitignored.

### 8.3 iCloud backup

Set up a daily vault backup to iCloud Drive. The backup script is already in
the repo at `_system/scripts/vault-backup.sh`.

Create the LaunchAgent plist:

```bash
mkdir -p ~/Library/LaunchAgents

cat > ~/Library/LaunchAgents/com.tess.vault-backup.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.tess.vault-backup</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>/Users/tess/crumb-vault/_system/scripts/vault-backup.sh</string>
    </array>
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>3</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>
    <key>StandardOutPath</key>
    <string>/tmp/vault-backup.log</string>
    <key>StandardErrorPath</key>
    <string>/tmp/vault-backup.err</string>
</dict>
</plist>
EOF

launchctl load ~/Library/LaunchAgents/com.tess.vault-backup.plist
```

Test manually:

```bash
bash ~/crumb-vault/_system/scripts/vault-backup.sh
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/crumb-backups/
```

### 8.4 Bridge Watcher (crumb-tess-bridge)

The bridge watcher is a persistent daemon that processes incoming requests
from Tess (OpenClaw/Telegram). It watches `_openclaw/inbox/` for new `.json`
files and dispatches them through `bridge-processor.js`.

**Prerequisites:** OpenClaw colocation must be complete (user `openclaw`,
`_openclaw/` directory structure, group `crumbvault`).

#### Directory setup

```bash
mkdir -p ~/crumb-vault/_openclaw/logs
# Ensure group-write permissions
chmod g+w ~/crumb-vault/_openclaw/logs
chmod g+w ~/crumb-vault/_openclaw/inbox
chmod g+w ~/crumb-vault/_openclaw/outbox
chmod g+w ~/crumb-vault/_openclaw/inbox/.processed
```

#### Install the LaunchAgent

```bash
cp ~/crumb-vault/_system/scripts/com.crumb.bridge-watcher.plist \
   ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) \
   ~/Library/LaunchAgents/com.crumb.bridge-watcher.plist
```

Verify:

```bash
launchctl print gui/$(id -u)/com.crumb.bridge-watcher
# Should show: state = running
tail -5 ~/crumb-vault/_openclaw/logs/watcher.log
# Should show startup JSON log entries
```

#### Shell wrapper for interactive sessions

Source the wrapper in `~/.zshrc` to prevent watcher/interactive session overlap:

```bash
echo 'source ~/crumb-vault/_system/scripts/claude-bridge-wrapper.sh' >> ~/.zshrc
source ~/.zshrc
```

Use `claude-bridge` instead of `claude` when working in the vault. The wrapper
acquires `LOCK_EX` on `_openclaw/.bridge.lock` for the full session, preventing
the watcher from dispatching concurrently.

#### Kill-switch

To emergency-stop all bridge processing without stopping the watcher:

```bash
touch ~/crumb-vault/_openclaw/.bridge-disabled    # enable kill-switch
rm ~/crumb-vault/_openclaw/.bridge-disabled        # disable kill-switch
```

Requests received while the kill-switch is active get a `BRIDGE_DISABLED`
error response in the outbox (non-retryable).

#### Stopping/restarting the watcher

```bash
# Stop
launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.crumb.bridge-watcher.plist

# Start
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.crumb.bridge-watcher.plist
```

#### Run manual validation

```bash
bash ~/crumb-vault/Projects/crumb-tess-bridge/src/watcher/validate-launchagent.sh
```

#### Configuration (environment variables)

| Variable | Default | Description |
|----------|---------|-------------|
| `CRUMB_BRIDGE_RATE_MAX` | 60 | Max requests per window |
| `CRUMB_BRIDGE_RATE_WINDOW` | 3600 | Rate limit window (seconds) |
| `CRUMB_BRIDGE_PROCESS_TIMEOUT` | 60 | Subprocess timeout (seconds). Increase to 300+ for Phase 2 `claude --print` ops. |
| `CRUMB_BRIDGE_SKIP_PGREP` | (unset) | Set to `1` to skip interactive session detection |
| `CRUMB_BRIDGE_USE_CLAUDE` | (unset) | Set to `1` to use `claude --print` instead of direct node invocation |

#### Phase 2 note: API key for claude --print

Phase 1 ops use direct `node bridge-processor.js` — no API key needed. When
Phase 2 is enabled (`CRUMB_BRIDGE_USE_CLAUDE=1`), the watcher needs access to
an Anthropic API key. Do NOT put it in the plist. Instead, the watcher inherits
from the environment or sources from `~/.config/crumb/.env` at runtime.

### 8.5 Headless power management (if always-on)

If the remote Mac accepts SSH connections and should never sleep:

```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 0 womp 1
```

- `sleep 0` — never sleep
- `disksleep 0` — never spin down disks
- `displaysleep 0` — no display sleep
- `womp 1` — Wake on LAN (safety net)

### 8.6 Google Drive Sync (NotebookLM integration)

Sync architecture and operator docs to Google Drive for NotebookLM consumption.
Runs as `danny` (Google account owner), daily at 5 AM via LaunchAgent.

**Prerequisites:** danny must be logged in (GUI or Fast User Switching).

#### One-time setup (as danny)

```bash
# Configure rclone remote (interactive OAuth — opens browser)
rclone config
# Choose: n (new remote) → name: gdrive → type: drive → default options → authorize
```

#### Install the LaunchAgent

```bash
# As danny:
cp ~/crumb-vault/_openclaw/staging/m2/com.crumb.drive-sync.plist \
   ~/Library/LaunchAgents/
launchctl bootstrap gui/$(id -u) \
   ~/Library/LaunchAgents/com.crumb.drive-sync.plist
```

#### Test manually

```bash
bash ~/crumb-vault/_system/scripts/drive-sync.sh
# Check: Google Drive → crumb-docs/ should have architecture/, operator/, llm-orientation/
cat /tmp/drive-sync.log
```

#### What gets synced

| Source | Drive Destination |
|--------|------------------|
| `_system/docs/architecture/*.md` | `crumb-docs/architecture/` |
| `_system/docs/operator/**/*.md` | `crumb-docs/operator/` |
| `_system/docs/llm-orientation/*.md` | `crumb-docs/llm-orientation/` |

Only `.md` files. Uses `--checksum` mode (content-based, not mtime).

### 8.7 Enable Remote Login

If not already enabled:

System Settings → General → Sharing → Remote Login → On

---

# OpenClaw Upgrade Procedure

**Problem:** You need to upgrade the OpenClaw gateway to a new version (new features, bug fixes, or security patches). The gateway runs as a LaunchDaemon under the `openclaw` user, so upgrades require sudo and a service restart. Downtime affects Tess (Telegram bot, cron jobs, all OpenClaw-managed agents).

**When to use:** When a new OpenClaw release is available and you want to apply it. Check release notes before upgrading — breaking changes may require config adjustments.

---

## Impact Analysis

A gateway restart affects these services:

| Service | Impact | Recovery |
|---------|--------|----------|
| Tess Voice (Telegram) | Offline during restart (~10-30s) | Automatic on gateway start |
| Tess Mechanic (cron jobs) | Missed if scheduled during restart | Next scheduled run fires normally |
| DM pairings | **Lost** — pairings are in-memory only | Must re-pair via Telegram after restart |
| OpenClaw cron data | Unaffected — stored in gateway config/SQLite | N/A |
| Bridge watcher | Unaffected — independent LaunchAgent | N/A |
| Crumb sessions | Unaffected — independent process | N/A |

**Key risk:** DM pairings are lost on every gateway restart. After upgrade, send a message to Tess on Telegram to re-establish the pairing.

---

## Pre-Upgrade Checklist

1. **Check current version:**
   ```bash
   sudo -u openclaw bash -c 'export HOME="/Users/openclaw" && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw --version'
   ```

2. **Check gateway is running:**
   ```bash
   nc -z -w3 127.0.0.1 18789 && echo "Gateway running" || echo "Gateway NOT running"
   ```
   Do NOT use `lsof` without sudo — it won't show openclaw-owned sockets.

3. **Verify no active Tess dispatch:** Check `_openclaw/inbox/` for unprocessed files. Wait for any in-flight dispatches to complete.

4. **Note current cron schedule:** If you need to verify cron jobs resume after upgrade:
   ```bash
   sudo -u openclaw bash -c 'export HOME="/Users/openclaw" && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw cron list'
   ```

---

## Upgrade Steps

### 1. Install the new version

```bash
sudo -u openclaw bash -c 'export HOME="/Users/openclaw" && export PATH="/opt/homebrew/bin:$PATH" && export npm_config_cache="/Users/openclaw/.npm" && npm install -g --prefix /Users/openclaw/.local openclaw@latest'
```

**Important:** `HOME` must be set explicitly — `sudo -u` does not reset it. `npm_config_cache` prevents writes to the primary user's `~/.npm/`.

### 2. Verify the new version installed

```bash
sudo -u openclaw bash -c 'export HOME="/Users/openclaw" && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw --version'
```

### 3. Stop the gateway

```bash
sudo launchctl bootout system/ai.openclaw.gateway
```

**Do NOT use** `openclaw gateway restart` — it looks in the wrong launchd domain (`gui/`) when the gateway runs as a LaunchDaemon (`system/`).

### 4. Start the gateway

```bash
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
```

If this fails with "Input/output error", the `com.apple.provenance` xattr may have re-attached to the plist. Strip it:

```bash
sudo xattr -d com.apple.provenance /Library/LaunchDaemons/ai.openclaw.gateway.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
```

### 5. Verify the gateway is running

```bash
# Check port
nc -z -w3 127.0.0.1 18789 && echo "Gateway running" || echo "Gateway NOT running"

# Check process
ps aux | grep openclaw-gateway

# Check launchd status (authoritative)
sudo launchctl print system/ai.openclaw.gateway | head -5
```

### 6. Re-establish DM pairings

Send a message to Tess on Telegram. The pairing is re-created on first message after restart.

### 7. Verify cron jobs

```bash
sudo -u openclaw bash -c 'export HOME="/Users/openclaw" && export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH" && openclaw cron list'
```

Confirm the same jobs are present as before the upgrade.

---

## Rollback

If the new version has issues:

```bash
# Stop the gateway
sudo launchctl bootout system/ai.openclaw.gateway

# Install the previous version (replace X.Y.Z with the prior version)
sudo -u openclaw bash -c 'export HOME="/Users/openclaw" && export PATH="/opt/homebrew/bin:$PATH" && export npm_config_cache="/Users/openclaw/.npm" && npm install -g --prefix /Users/openclaw/.local openclaw@X.Y.Z'

# Start the gateway
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist
```

---

## Credential Rotation (if needed)

OpenClaw's credentials live in `/Users/openclaw/.openclaw/openclaw.json`, separate from Crumb's `~/.config/crumb/.env`. If a release requires credential changes:

1. Stop the gateway (Step 3 above)
2. Edit the config:
   ```bash
   sudo -u openclaw nano /Users/openclaw/.openclaw/openclaw.json
   ```
3. Start the gateway (Step 4 above)
4. Test affected integrations (Telegram bot, email, etc.)

---

**Done criteria:** Gateway running on the new version, health check passes (`nc -z` on port 18789), cron jobs present, Telegram DM pairing re-established.

---

# Migration from Existing Machine

If you already have Crumb running on another Mac, use this section to
expedite setup on a new machine.

## Before You Start (on the old machine)

### Ensure vault is committed and pushed

```bash
cd ~/crumb-vault
git status          # should be clean
git push            # should be up to date
```

### Save non-git files

These are gitignored or live outside the vault. Save them somewhere accessible
from the new machine (password manager, AirDrop — **never email or Slack**).

**Crumb API keys:**

```bash
cat ~/.config/crumb/.env
# Copy the output: OPENROUTER_API_KEY, OPENAI_API_KEY, GEMINI_API_KEY, DEEPSEEK_API_KEY, XAI_API_KEY
```

**Shell configs:**

```bash
cat ~/.zshrc
cat ~/.tmux.conf
```

**Claude Code project memory:**

```bash
cat ~/.claude/projects/-Users-tess-crumb-vault/memory/MEMORY.md
# This preserves learned context, patterns, and preferences
```

**SSH config (from client machine):**

```bash
cat ~/.ssh/config
# Host entries for remote Macs
```

**Terminal config (from client machine):**

```bash
# Alacritty:
cat ~/.config/alacritty/alacritty.toml

# Apple Terminal:
# Export the profile from Terminal → Settings → Profiles → ... → Export
```

### Note your GitHub username

You'll create a new fine-grained PAT for the new machine — no need to
transfer the old one.

---

## Expedited Setup

Run the Fresh Install phases above, but skip the "create from scratch" steps
for anything you saved. Restoration priority:

| Priority | File | Why |
|----------|------|-----|
| 1 | `~/.config/crumb/.env` | API keys — everything breaks without this |
| 2 | `~/.zshrc` + `~/.tmux.conf` | Shell and tmux config |
| 3 | Claude Code `MEMORY.md` | Preserves learned context across machines |
| 4 | `~/.ssh/config` + terminal config | Client-side SSH setup |
| 5 | `.claude/settings.json` | Only if cloning from mirror instead of main vault |

### Restore process

1. **Run Fresh Install Phases 1-3** (system deps, Claude Code, git identity) —
   these are per-machine and can't be copied
2. **Clone the vault** (Phase 4.1)
3. **Paste saved configs** instead of creating from scratch:
   ```bash
   # API keys
   mkdir -p ~/.config/crumb
   nano ~/.config/crumb/.env
   # Paste saved contents
   chmod 600 ~/.config/crumb/.env

   # Shell config
   nano ~/.zshrc
   # Paste saved contents (merge with Homebrew PATH lines if needed)

   nano ~/.tmux.conf
   # Paste saved contents
   ```
4. **Run setup-crumb.sh** (Phase 4.2) — validates everything
5. **Restore Claude Code memory** (after your first Crumb session creates the directory):
   ```bash
   nano ~/.claude/projects/-Users-tess-crumb-vault/memory/MEMORY.md
   # Paste saved contents
   ```
6. **Set up client machine** (Phase 6) — paste saved SSH config and terminal config
7. **Verify** (Phase 7) — connect and run a test session
8. **Optional enhancements** (Phase 8) — mirror, Obsidian, backup, power management

---

## Old Machine Cleanup

After confirming the new machine works:

1. **Revoke the old GitHub token** scoped to the old machine
   (GitHub → Settings → Tokens)
2. **Remove vault from old machine** if required by policy:
   ```bash
   rm -rf ~/crumb-vault
   ```
3. **Unload the backup job:**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.tess.vault-backup.plist
   ```
4. **Remove config files:**
   ```bash
   rm -rf ~/.config/crumb
   ```

---

## Outside-Vault Files Reference

Crumb depends on several files that live outside the vault. These don't
travel with `git clone` and must be created or copied manually on each machine.

### Remote Mac — must exist

| File | Purpose | Copyable? |
|------|---------|-----------|
| `~/.config/crumb/.env` | API keys (OpenRouter, OpenAI, Gemini, DeepSeek, xAI) | Yes — transfer securely |
| `~/.zshrc` | TERM export, bindkey fixes, Keychain unlock, claude alias | Yes |
| `~/.tmux.conf` | tmux prefix, keybindings, status bar theme | Yes |

### Remote Mac — auto-created but worth preserving

| File | Purpose | Copyable? |
|------|---------|-----------|
| `~/.claude/projects/-Users-tess-crumb-vault/memory/MEMORY.md` | Claude Code's per-project memory — learned patterns and preferences | Yes — copy to preserve continuity |
| `~/.claude/projects/-Users-tess-crumb-vault/` (session history) | Accumulated session logs | Optional — can bloat; `clear-claude-cache.sh` cleans this |

### Inside vault but excluded from mirror

| File | Purpose | Notes |
|------|---------|-------|
| `.claude/settings.json` | SessionStart hook, permission allowlists, tool config | Travels with `git clone` of the main vault. Excluded from the mirror. If cloning from mirror only, copy from an existing machine or recreate. |
| `.claude/settings.local.json` | Machine-specific permission overrides | Per-machine. Don't copy — create fresh based on approval patterns. |

### Client Mac

| File | Purpose | Copyable? |
|------|---------|-----------|
| `~/.ssh/config` | Host entries for remote Macs | Yes |
| `~/.config/alacritty/alacritty.toml` | Alacritty config (if using Alacritty) | Yes |
| `Catppuccin Mocha.terminal` | Apple Terminal profile (if using Apple Terminal) | Yes — import via Terminal Settings |
| `~/.zshrc` | Connection aliases (`studio`, etc.) | Yes (merge with existing) |

### Per-machine only (cannot copy)

These must be done fresh on each machine — credentials and binaries are
machine-specific:

- `brew install ...` (Homebrew packages)
- `curl -fsSL https://claude.ai/install.sh | sh` (Claude Code binary)
- `claude /login` from local terminal (creates Keychain credential)
- `security delete-generic-password` + `claude /login` from SSH (ACL fix)
- `sudo pmset -a sleep 0 ...` (power management)
- `git config --global user.name / user.email` (git identity)

---

## setup-crumb.sh — What It Checks

The setup script (`_system/scripts/setup-crumb.sh`) validates your
installation across these phases:

1. System dependencies (git, node, python3, jq, curl)
2. Brew packages (imagemagick, exiftool, ffmpeg, repomix)
3. Python tools (markitdown, Pillow)
4. Claude Code binary
5. File permissions (script execute bits)
6. Pre-commit hook (vault-check.sh)
7. Config files (`~/.config/crumb/.env` with OpenRouter, peer-review panel keys)
8. Vault validation (vault-check.sh)
9. GitHub mirror (if configured)

Run it after setup and again after any configuration changes to catch issues early.
