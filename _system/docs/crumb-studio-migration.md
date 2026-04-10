---
type: runbook
domain: software
created: 2026-02-17
updated: 2026-02-19
status: active
tags:
  - migration
  - infrastructure
---

# Crumb Migration Guide — Apple Studio M3 Ultra

> **Superseded:** This documents the Feb 2026 Studio migration (historical record). For general deployment on a new Mac, see [[crumb-deployment-runbook]]. This doc remains the reference for OpenClaw/Tess isolation setup.

Migration from Infoblox work Mac to personal Apple Studio M3 Ultra (96GB, 1TB SSD).

**Source:** Work Mac (Infoblox) — vault at `~/crumb-vault`, git remote on GitHub
**Target:** Apple Studio M3 Ultra — clean macOS install, vault at `~/crumb-vault`

---

## Before You Start (on the work machine)

Do these before you stop using the work Mac:

### 1. Ensure vault is fully committed and pushed

```bash
cd ~/crumb-vault
git status          # should be clean
git push            # should be up to date
```

### 2. Save files that don't travel with git

These are gitignored or live outside the vault:

**Crumb API keys** (peer-review skill — lives outside the vault):
```bash
cat ~/.config/crumb/.env
# Copy the output — you'll paste it on the Studio
```

**TMDB API key** (meme-creator skill):
```bash
cat ~/.config/meme-creator/tmdb-api-key
# Copy the output
```

**Ghostty config** (TokyoNight theme + palette overrides):
```bash
cat ~/.config/ghostty/config
# Copy the output
```

**Claude Code project memory** (persistent agent memory — lives outside the vault):
```bash
cat ~/.claude/projects/-Users-tess-crumb-vault/memory/MEMORY.md
# Copy the output
```

**Backup plist** (reference only — paths may change):
```bash
cat ~/Library/LaunchAgents/com.tess.vault-backup.plist
# Copy for reference
```

**OpenClaw config** (if OpenClaw is already running on the work machine):
```bash
cat ~/.openclaw/openclaw.json
# Copy the output — REDACT the gateway token before saving.
# You'll recreate the token on the Studio; the rest of the config is reusable.
```

Note: Messaging platform sessions (WhatsApp, Telegram, etc.) will require re-authentication on the new machine regardless of what you save.

Save all of these somewhere accessible from the new machine (password manager, email to self, AirDrop, whatever works).

### 3. Note your GitHub username

You'll need it for the clone. You're creating a new fine-grained access token for the Studio, so no need to transfer the old one.

---

## Studio Setup

### Phase 1: System prerequisites

The Studio ships with macOS and basically nothing else we need. Install in this order (dependencies matter):

```bash
# 1. Xcode Command Line Tools (gets git, clang, make, etc.)
xcode-select --install
# Follow the GUI prompt to install. This takes a few minutes.

# 2. Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

**Important:** After Homebrew installs, it prints instructions to add it to your PATH. On Apple Silicon, Homebrew installs to `/opt/homebrew`, not `/usr/local`. Run the commands it shows you, something like:

```bash
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zshrc
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Phase 2: Brew packages

```bash
# CLI tools
brew install node python pipx jq imagemagick exiftool ffmpeg repomix

# GUI apps
brew install --cask ghostty obsidian
```

**OpenClaw note:** Both Claude Code and OpenClaw use the same Homebrew Node at `/opt/homebrew/bin/node`. The `openclaw` user accesses it via PATH in its wrapper script (Phase 13). No separate Node install needed.

### Phase 3: Python tools via pipx and pip

```bash
pipx ensurepath
pipx install 'markitdown[all]'

# Pillow — required by meme-creator skill
pip3 install Pillow
```

Close and reopen your terminal (or `source ~/.zshrc`) after `ensurepath`.

### Phase 4: Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

Verify:
```bash
claude --version    # should return version info
node --version      # should be 18+ (currently 25.x via Homebrew)
git --version       # should be 2.x
python3 --version   # should be 3.12+
markitdown --help   # should show usage
jq --version        # should return version info
python3 -c "from PIL import Image; print('Pillow OK')"
```

### Phase 5: Git identity and shell config

The Studio is a fresh machine with no git identity. Set it before any commits:

```bash
git config --global user.name "Your Name"
git config --global user.email "your-email@example.com"
```

Add your Anthropic API key to `~/.zshrc`:

```bash
echo 'export ANTHROPIC_API_KEY="your-key-here"' >> ~/.zshrc
source ~/.zshrc
```

**OpenClaw note:** Do NOT add OpenClaw API keys to `~/.zshrc`. OpenClaw's keys belong in its own config (`/Users/openclaw/.openclaw/openclaw.json`), not in the primary user's shell environment. This is part of the credential isolation model.

### Phase 6: GitHub access token

Create a new fine-grained personal access token at https://github.com/settings/tokens:

- **Repository access:** Only select repositories → your crumb repo
- **Repository permissions:**
  - Contents: Read and write
  - Metadata: Read (auto-selected)
- **Expiration:** Your preference (you can regenerate when it expires)

Save the token — you'll need it once for the clone. After the first authenticated operation, macOS Keychain (`credential-osxkeychain`) should cache it for future pushes.

---

## Vault Setup

### Phase 7: Clone the vault

```bash
git clone https://github.com/djt71/crumb-vault.git ~/crumb-vault
```

When prompted for credentials, use your GitHub username and the new access token as the password.

Verify the credential was cached:
```bash
git -C ~/crumb-vault fetch    # should not prompt for credentials
```

### Phase 8: Restore non-git config files

**Crumb API keys** (peer-review skill):
```bash
mkdir -p ~/.config/crumb
nano ~/.config/crumb/.env
# Paste the contents you saved (OPENAI_API_KEY, GEMINI_API_KEY, PERPLEXITY_API_KEY)
```

**TMDB API key** (meme-creator skill):
```bash
mkdir -p ~/.config/meme-creator
nano ~/.config/meme-creator/tmdb-api-key
# Paste the key you saved
```

**Claude Code project memory:**
Claude Code generates `~/.claude/projects/-Users-tess-crumb-vault/memory/` automatically on first run — no need to create it manually. After your first Crumb session on the Studio, paste your saved `MEMORY.md` contents:
```bash
nano ~/.claude/projects/-Users-tess-crumb-vault/memory/MEMORY.md
# Paste the contents you saved
```

**OpenClaw config** (if migrating an existing OpenClaw installation):
```bash
# This is restored during Phase 13. For now, just ensure you have the saved
# openclaw.json from the "Before You Start" section ready.
```

### Phase 9: Run the setup script

```bash
chmod +x ~/crumb-vault/_system/scripts/*.sh
bash ~/crumb-vault/_system/scripts/setup-crumb.sh ~/crumb-vault
```

This verifies all dependencies, fixes file permissions, installs the pre-commit hook, checks for config files, and runs vault-check. All phases should pass. If anything fails, the output tells you exactly what to fix.

### Phase 10: Ghostty config

```bash
mkdir -p ~/.config/ghostty
nano ~/.config/ghostty/config
# Paste your saved Ghostty config (TokyoNight theme + palette overrides)
```

Restart Ghostty to pick up the config.

### Phase 11: Open vault in Obsidian

1. Launch Obsidian
2. "Open folder as vault" → select `~/crumb-vault`
3. Verify CLI: `obsidian vault` (should return vault info while Obsidian is running)

Note: Core plugins, appearance, and app settings are tracked in git (`.obsidian/app.json`, `appearance.json`, `core-plugins.json`), so they'll be present after clone. Only workspace state is gitignored.

### Phase 12: Backup job

Recreate the daily iCloud backup. Requires iCloud Drive enabled and syncing on the Studio.

**The backup script** is already in the repo at `_system/scripts/vault-backup.sh` — no action needed.

**The launchd plist** needs to be created (it's machine-specific, not in git):

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

Test it manually:
```bash
bash ~/crumb-vault/_system/scripts/vault-backup.sh
```

Verify the backup landed in iCloud:
```bash
ls ~/Library/Mobile\ Documents/com~apple~CloudDocs/crumb-backups/
```

**OpenClaw note:** `vault-backup.sh` tars the entire `~/crumb-vault/` directory, so `_openclaw/` is included automatically. However, `/Users/openclaw/.openclaw/` (OpenClaw's own config, workspace, and messaging session state) lives outside the vault and needs separate backup. Add `/Users/openclaw` to your Time Machine backup scope, or set up a dedicated backup job during Phase 13.

### Phase 12b: Headless power management and login items

The Studio runs OpenClaw as an always-on LaunchDaemon and accepts SSH connections,
so it should never sleep.

**Disable all sleep and enable Wake on LAN:**

```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 0 womp 1
```

Verify:
```bash
pmset -g
# sleep         0
# disksleep     0
# displaysleep  0
# womp          1
```

**Add Obsidian as a login item** so the CLI is available for Crumb sessions over SSH
(Obsidian must be running for `obsidian` CLI commands to work):

```bash
osascript -e 'tell application "System Events" to make login item at end with properties {path:"/Applications/Obsidian.app", hidden:true}'
```

This launches Obsidian hidden on login. Verify it's registered:
```bash
osascript -e 'tell application "System Events" to get the name of every login item'
```

---

## OpenClaw Installation

### Installation Path Decision

Choose one approach:

**Option A: Day 1** — Install OpenClaw during initial Studio setup. Follow Phases 1-12 above, then continue to Phase 13. Higher initial complexity but avoids a second setup session.

**Option B: Phased** — Complete the Crumb migration first, run at least one successful Crumb session, then return and run Phase 13. Lower risk, allows incremental validation.

Either option uses the same Phase 13 below. The difference is timing.

### Phase 13: OpenClaw

OpenClaw runs under a dedicated macOS user (`openclaw`) for OS-level isolation. This means the OpenClaw process physically cannot access the primary user's credentials, SSH keys, or shell config — even if OpenClaw's own `workspaceOnly` control is bypassed.

For background on the threat model and design rationale, see the [[openclaw-colocation-spec|colocation spec]].

**Prerequisites:**
- Crumb is installed and validated (`setup-crumb.sh` passes)
- You have admin (sudo) access on the Studio

#### Step 1: Create the dedicated macOS user

```bash
sudo sysadminctl -addUser openclaw -password - -home /Users/openclaw
# Set a strong password when prompted. You'll rarely use it directly —
# most interaction is via sudo -u openclaw.
```

#### Step 2: Verify Homebrew Node and install OpenClaw

OpenClaw requires Node.js >= 22.12.0. The `openclaw` user shares the primary user's Homebrew Node — no separate version manager needed.

```bash
# Verify the openclaw user can access Homebrew Node
sudo -u openclaw /opt/homebrew/bin/node --version
# Expected output: v22.x.x or higher
# If this fails, check permissions: ls -la /opt/homebrew/bin/node

# Install OpenClaw globally for the openclaw user.
# NOTE: npm install -g under a non-primary user needs explicit prefix and cache
# to avoid writing to the primary user's ~/.npm/ directory.
sudo -u openclaw bash -c 'export PATH="/opt/homebrew/bin:$PATH" && export npm_config_cache="/Users/openclaw/.npm" && npm install -g --prefix /Users/openclaw/.local openclaw@latest'
```

#### Step 3: Create the wrapper script

The wrapper script sets HOME (sudo doesn't always reset it) and adds the npm prefix + Homebrew to PATH for launchd (which does not inherit the user's shell environment). It runs the gateway entry point directly rather than via `openclaw daemon` (which is a service management subcommand, not the gateway process):

```bash
sudo -u openclaw tee /Users/openclaw/launch-openclaw.sh > /dev/null << 'SCRIPT'
#!/bin/bash
export HOME="/Users/openclaw"
export PATH="/Users/openclaw/.local/bin:/opt/homebrew/bin:$PATH"
exec node /Users/openclaw/.local/lib/node_modules/openclaw/dist/index.js gateway --port 18789
SCRIPT

sudo chmod 700 /Users/openclaw/launch-openclaw.sh
sudo chown openclaw /Users/openclaw/launch-openclaw.sh
```

> **Future contingency:** If Homebrew Node is ever upgraded to a version OpenClaw doesn't support, install nvm for the `openclaw` user at that point and update this wrapper to source `nvm.sh` instead.

#### Step 4: Run OpenClaw onboard

```bash
sudo -u openclaw openclaw onboard
```

During onboard:
- **LaunchDaemon with `UserName`:** Onboard generates a LaunchAgent by default, but LaunchAgent doesn't persist when the `openclaw` user isn't logged in. After onboard, copy the plist to `/Library/LaunchDaemons/`, add `UserName`/`GroupName` keys, and update `ProgramArguments` to use the wrapper script (see Step 5 below).
- **Workspace:** Configure as `/Users/openclaw/.openclaw/workspace` (NOT the vault root)

#### Step 5: Create the LaunchDaemon plist

Onboard generates a LaunchAgent at `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist`,
but LaunchAgent doesn't work when the `openclaw` user has no GUI session. Copy it to
`/Library/LaunchDaemons/`, add `UserName`/`GroupName` keys, and point `ProgramArguments`
at the wrapper script:

```bash
# Copy onboard's plist as a starting point
sudo cp /Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist \
  /Library/LaunchDaemons/ai.openclaw.gateway.plist

PLIST="/Library/LaunchDaemons/ai.openclaw.gateway.plist"

# Set ownership (LaunchDaemons must be root:wheel)
sudo chown root:wheel "$PLIST"
sudo chmod 644 "$PLIST"

# Add UserName and GroupName so the process runs as openclaw, not root
sudo /usr/libexec/PlistBuddy -c "Add :UserName string openclaw" "$PLIST" 2>/dev/null || \
  sudo /usr/libexec/PlistBuddy -c "Set :UserName openclaw" "$PLIST"
sudo /usr/libexec/PlistBuddy -c "Add :GroupName string openclaw" "$PLIST" 2>/dev/null || \
  sudo /usr/libexec/PlistBuddy -c "Set :GroupName openclaw" "$PLIST"

# Update ProgramArguments to use the wrapper script
sudo /usr/libexec/PlistBuddy -c "Delete :ProgramArguments" "$PLIST"
sudo /usr/libexec/PlistBuddy -c "Add :ProgramArguments array" "$PLIST"
sudo /usr/libexec/PlistBuddy -c "Add :ProgramArguments:0 string /Users/openclaw/launch-openclaw.sh" "$PLIST"

# Verify the label
/usr/libexec/PlistBuddy -c "Print :Label" "$PLIST"
# Expected: ai.openclaw.gateway

# Unload the old LaunchAgent (if loaded) and load the LaunchDaemon
sudo launchctl bootout gui/$(id -u openclaw)/ai.openclaw.gateway 2>/dev/null || true
sudo launchctl bootstrap system "$PLIST"
```

The original LaunchAgent at `/Users/openclaw/Library/LaunchAgents/ai.openclaw.gateway.plist`
is retained for reference but should not be loaded.

**Launchctl commands for ongoing operation:**
- Stop: `sudo launchctl bootout system/ai.openclaw.gateway`
- Start: `sudo launchctl bootstrap system /Library/LaunchDaemons/ai.openclaw.gateway.plist`

#### Step 6: Test the wrapper script

Dry-run the wrapper before loading the plist to catch PATH issues early:

```bash
sudo -u openclaw timeout 5 /Users/openclaw/launch-openclaw.sh &
WRAPPER_PID=$!
sleep 3
if kill -0 $WRAPPER_PID 2>/dev/null; then
  echo "Wrapper script launched successfully"
  kill $WRAPPER_PID 2>/dev/null
else
  echo "Wrapper script exited prematurely. Debug:"
  echo "  1. Verify Homebrew Node is accessible: sudo -u openclaw /opt/homebrew/bin/node --version"
  echo "  2. Verify PATH in wrapper: sudo -u openclaw bash -c 'export PATH=/opt/homebrew/bin:\$PATH && which openclaw'"
  echo "  3. Check openclaw user can execute: sudo -u openclaw bash -c 'export PATH=/opt/homebrew/bin:\$PATH && openclaw --version'"
  exit 1
fi
```

#### Step 7: Apply Tier 1 hardening

Edit `/Users/openclaw/.openclaw/openclaw.json` to include these mandatory settings:

```bash
# Open the config for editing
sudo -u openclaw nano /Users/openclaw/.openclaw/openclaw.json
```

Ensure these settings are present:

```json
{
  "tools": {
    "fs": { "workspaceOnly": true },
    "exec": { "applyPatch": { "workspaceOnly": true } },
    "browser": { "enabled": false }
  }
}
```

Key hardening points:
- **Loopback binding:** Keep the default `127.0.0.1:18789` — do not change it
- **DM policy:** Keep on "pairing" mode — approve every new sender explicitly
- **Workspace:** Must be `/Users/openclaw/.openclaw/workspace`, not the vault root
- **Browser automation:** Disabled initially
- **Separate API keys:** OpenClaw's keys go in `openclaw.json`, never in `~/.config/crumb/.env`
- **Stable release only:** No beta/dev builds

#### Step 8: Set up vault access permissions

Create a shared group so OpenClaw can read the vault but only write to its sandbox:

```bash
# Create shared group for vault read access
sudo dseditgroup -o create -r "Crumb Vault Readers" crumbvault
sudo dseditgroup -o edit -a openclaw -t user crumbvault
sudo dseditgroup -o edit -a $(logname) -t user crumbvault

# Grant recursive group read to vault (no group write)
chgrp -R crumbvault ~/crumb-vault
chmod -R g+rX,g-w ~/crumb-vault

# Set setgid bit so new files inherit the crumbvault group.
# macOS doesn't always respect setgid on directories the same way Linux does —
# verify with the test below, and fall back to periodic chgrp if needed.
find ~/crumb-vault -type d -exec chmod g+s {} +

# Verify setgid works: create a test file and check its group
touch ~/crumb-vault/.setgid-test
ls -l ~/crumb-vault/.setgid-test   # should show "crumbvault" as group
rm ~/crumb-vault/.setgid-test

# If the test file shows your default group instead of crumbvault,
# setgid isn't working on this macOS version. In that case, add a
# periodic chgrp to the backup plist or run manually after large changes:
#   chgrp -R crumbvault ~/crumb-vault && chmod -R g+rX,g-w ~/crumb-vault

# Create the OpenClaw sandbox directory and grant write access
mkdir -p ~/crumb-vault/_openclaw/{inbox,outbox,outbox/.pending}
chown -R openclaw:crumbvault ~/crumb-vault/_openclaw
chmod -R g+rwX ~/crumb-vault/_openclaw
```

#### Step 9: MANDATORY — Run the isolation test suite

**This is a go/no-go gate.** Do NOT proceed to messaging platform setup until ALL 9 tests pass. This verifies that OS-level permissions enforce the isolation boundary.

Use absolute paths throughout — `~` expansion is unreliable with `sudo -u`.

```bash
PRIMARY_USER=$(logname)
PASS=0; FAIL=0

# --- Tests that MUST FAIL (isolation boundary) ---

if sudo -u openclaw cat /Users/$PRIMARY_USER/.config/crumb/.env 2>&1 | grep -q "Permission denied"; then
  echo "PASS: openclaw blocked from ~/.config/crumb/.env"; ((PASS++))
else
  echo "FAIL: openclaw CAN READ ~/.config/crumb/.env — ISOLATION BROKEN"; ((FAIL++))
fi

if sudo -u openclaw ls /Users/$PRIMARY_USER/.ssh/ 2>&1 | grep -q "Permission denied"; then
  echo "PASS: openclaw blocked from ~/.ssh/"; ((PASS++))
else
  echo "FAIL: openclaw CAN READ ~/.ssh/ — ISOLATION BROKEN"; ((FAIL++))
fi

if sudo -u openclaw cat /Users/$PRIMARY_USER/.zshrc 2>&1 | grep -q "Permission denied"; then
  echo "PASS: openclaw blocked from ~/.zshrc"; ((PASS++))
else
  echo "FAIL: openclaw CAN READ ~/.zshrc — ISOLATION BROKEN"; ((FAIL++))
fi

if sudo -u openclaw ls /Users/$PRIMARY_USER/Library/Keychains/ 2>&1 | grep -qE "Permission denied|Operation not permitted"; then
  echo "PASS: openclaw blocked from ~/Library/Keychains/"; ((PASS++))
else
  echo "FAIL: openclaw CAN READ ~/Library/Keychains/"; ((FAIL++))
fi

# --- Tests that MUST SUCCEED (vault read access) ---

if sudo -u openclaw ls /Users/$PRIMARY_USER/crumb-vault/_system/docs/ >/dev/null 2>&1; then
  echo "PASS: openclaw can read vault _system/docs/"; ((PASS++))
else
  echo "FAIL: openclaw cannot read vault (group permissions misconfigured)"; ((FAIL++))
fi

if sudo -u openclaw cat /Users/$PRIMARY_USER/crumb-vault/CLAUDE.md >/dev/null 2>&1; then
  echo "PASS: openclaw can read CLAUDE.md"; ((PASS++))
else
  echo "FAIL: openclaw cannot read CLAUDE.md"; ((FAIL++))
fi

# --- Tests that MUST FAIL (vault write boundary) ---

if sudo -u openclaw touch /Users/$PRIMARY_USER/crumb-vault/test-isolation.txt 2>&1 | grep -q "Permission denied"; then
  echo "PASS: openclaw blocked from vault write"; ((PASS++))
else
  echo "FAIL: openclaw CAN WRITE to vault root — WRITE BOUNDARY BROKEN"; ((FAIL++))
  rm -f /Users/$PRIMARY_USER/crumb-vault/test-isolation.txt
fi

# --- Tests that MUST SUCCEED (sandbox write access) ---

if sudo -u openclaw touch /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation.txt 2>/dev/null; then
  echo "PASS: openclaw can write to _openclaw/ sandbox"; ((PASS++))
  rm -f /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation.txt
else
  echo "FAIL: openclaw cannot write to _openclaw/ sandbox"; ((FAIL++))
fi

if sudo -u openclaw mkdir /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation-dir 2>/dev/null; then
  echo "PASS: openclaw can mkdir in _openclaw/ sandbox"; ((PASS++))
  rmdir /Users/$PRIMARY_USER/crumb-vault/_openclaw/test-isolation-dir
else
  echo "FAIL: openclaw cannot mkdir in _openclaw/ sandbox"; ((FAIL++))
fi

# --- Gate ---
echo ""
echo "=== ISOLATION TEST RESULTS: $PASS passed, $FAIL failed ==="
if [ $FAIL -gt 0 ]; then
  echo "*** STOP: $FAIL test(s) failed. Fix permissions before proceeding. ***"
  echo "*** Do NOT connect messaging platforms until all tests pass.      ***"
  exit 1
else
  echo "All isolation tests passed. Safe to proceed."
fi
```

If any test fails, fix the permissions and re-run the full suite. Common fixes:
- **Isolation tests failing (openclaw can read private files):** Check that the primary user's home directory permissions are `drwx------` (`chmod 700 ~`)
- **Vault read tests failing:** Verify `crumbvault` group exists and both users are members (`dseditgroup -o checkmember -m openclaw crumbvault`)
- **Sandbox write tests failing:** Verify `_openclaw/` ownership (`ls -la ~/crumb-vault/_openclaw`)

#### Step 10: Run diagnostics and lock down credentials

```bash
# Run OpenClaw's built-in diagnostics
sudo -u openclaw openclaw doctor
sudo -u openclaw openclaw security audit --deep

# Lock down credential files
sudo chmod 700 /Users/openclaw/.openclaw
sudo chmod 600 /Users/openclaw/.openclaw/openclaw.json
sudo chmod 600 /Users/openclaw/.openclaw/device.json
```

#### Step 11: Verify and record

```bash
# Verify OpenClaw is running
sudo -u openclaw openclaw status

# Verify loopback-only binding
lsof -iTCP:18789 -sTCP:LISTEN
# Should show 127.0.0.1 only, never 0.0.0.0

# Verify workspace-only is set
sudo grep -A2 '"fs"' /Users/openclaw/.openclaw/openclaw.json
# Should show workspaceOnly: true

# Verify DM policy
sudo -u openclaw openclaw doctor
# Should report no issues

# Verify no ACLs grant broader access
ls -le ~/.config/crumb/.env
# Should show no ACL entries
ls -le /Users/openclaw/.openclaw/openclaw.json
# Should show no ACL entries
```

The plist label is `ai.openclaw.gateway` and the daemon runs as a LaunchDaemon at `/Library/LaunchDaemons/ai.openclaw.gateway.plist`. These are used in the kill-switch runbook in the [[openclaw-colocation-spec|colocation spec]].

#### Step 12: Connect messaging platforms

Connect platforms using **burner accounts** (not your personal accounts). See the [[openclaw-colocation-spec|colocation spec]] for per-platform kill-switch procedures.

**Important:** The kill-switch runbook (emergency disconnect and credential rotation) lives in the colocation spec, not in this migration guide. Review and dry-run it before connecting any platform.

---

## Verification

### Quick health check

```bash
cd ~/crumb-vault
bash _system/scripts/vault-check.sh               # should exit 0 (clean)
obsidian vault                             # should return vault info
claude --version                           # should return version info
git config user.name                       # should return your name
git config user.email                      # should return your email
```

### First Crumb session

```bash
cd ~/crumb-vault
claude
```

The startup sequence should report:
- vault-check: pass (or deferred to pre-commit hook)
- Obsidian CLI: available
- Rotation: none needed (or rotation performed if it's a new month)
- Overlay index: loaded
- Stale summaries: 0 (or current count)

If everything's green, you're live.

---

## Cleanup (after confirming the Studio works)

1. **Revoke the old GitHub token** scoped to the work machine (GitHub → Settings → Tokens)
2. **Remove vault from work machine** if required by policy
3. **Unload the backup job on the work machine:**
   ```bash
   launchctl unload ~/Library/LaunchAgents/com.tess.vault-backup.plist
   ```
4. **Remove config files from work machine** (API keys, etc.):
   ```bash
   rm -rf ~/.config/crumb ~/.config/meme-creator
   ```
