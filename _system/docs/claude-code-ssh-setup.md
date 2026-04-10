---
type: reference
domain: software
status: active
tags:
  - kb/software-dev
created: 2026-02-19
updated: 2026-02-20
topics:
  - moc-crumb-operations
---

# Claude Code Over SSH — macOS Setup Guide

> **Note:** For full Crumb deployment (dependencies, vault setup, API keys, migration), see [[crumb-deployment-runbook]]. This doc is the SSH-specific quick reference and config archive.

Quick reference for running Claude Code on a headless Mac from another machine via SSH. Uses tmux for tabs/session persistence, with either Alacritty or Apple Terminal as the client terminal emulator.

**Terminal emulator options:**
- **Apple Terminal** — maximum stability, zero config, no focus reporting bugs. Best for pure SSH work.
- **Alacritty** — GPU-accelerated, TOML config file (version-controllable), font ligature support. Minor quirks possible.
- **Ghostty** — not recommended for SSH to Claude Code. Focus reporting and terminal mode negotiation cause intermittent backspace/arrow key breakage and `[I`/`[O` escape sequence leaks on window focus changes.

## Prerequisites

- macOS remote machine with SSH enabled (System Settings → General → Sharing → Remote Login)
- Claude Code installed on the remote Mac (native installer — see step 1)

## Quick Setup: Files to Copy

If you already have one machine configured, you can copy these files to speed up setup on the next one.

**From the client machine (the machine you SSH from):**

| File                                 | What it contains                                                       |
| ------------------------------------ | ---------------------------------------------------------------------- |
| `~/.ssh/config`                      | Host entries for remote Macs                                           |
| `~/.config/alacritty/alacritty.toml` | Alacritty config (font, colors, TERM) — if using Alacritty             |
| `Catppuccin Mocha.terminal`          | Apple Terminal profile — if using Apple Terminal (import via Settings) |
| `~/.zshrc`                           | Connection aliases (`studio`, `othermac`, etc.)                        |

**From a configured remote Mac (copy to each new remote Mac):**

| File | What it contains |
|------|-----------------|
| `~/.zshrc` | TERM export, bindkey fixes, Keychain unlock, claude alias |
| `~/.tmux.conf` | tmux config (prefix, keybindings, status bar) |

**Cannot be copied — must be done per-machine:**

| Step | Why |
|------|-----|
| `brew install tmux` | Installs tmux on that Mac |
| `curl -fsSL https://claude.ai/install.sh \| sh` | Installs Claude Code binary locally |
| `claude /login` (local terminal) | Creates Keychain credential on that Mac |
| `security delete-generic-password` + `claude /login` (SSH) | Fixes ACL for that Mac's Keychain |
| `sudo pmset -a sleep 0 ...` | Machine-specific power settings |

---

## Setup — Remote Mac

Do these steps on the remote Mac directly (local terminal or screen sharing), not over SSH.

### 1. Install Claude Code (native installer)

The npm version (`@anthropic-ai/claude-code`) uses a different auth flow that doesn't work over SSH. Use the native installer:

```bash
# Remove npm version if present
npm uninstall -g @anthropic-ai/claude-code

# Install native
curl -fsSL https://claude.ai/install.sh | sh
```

Binary installs to `~/.local/bin/claude`. Ensure `~/.local/bin` is in your PATH:

```bash
echo $PATH | grep -q '.local/bin' && echo "OK" || echo "Add ~/.local/bin to PATH"
```

### 2. Authenticate Claude Code locally

This must be done from a **local terminal on the remote Mac**, not over SSH:

```bash
claude /login
```

Follow the browser prompt to authenticate. This stores the credential in macOS Keychain as `Claude Code-credentials`.

Verify:

```bash
claude /status
# Should show: Opus 4.6 · Claude Max (or your subscription)
```

### 3. Fix the Keychain ACL for SSH access

**Critical:** Even after unlocking Keychain over SSH, Claude Code may not be able to read the credential. The Keychain item created from a local GUI session has an ACL that restricts access to that context. You must delete and re-create the credential from an SSH session:

```bash
# Do this from an SSH session (not local terminal):
security delete-generic-password -s "Claude Code-credentials" ~/Library/Keychains/login.keychain-db
claude /login
```

Authenticate again through the browser. The new credential will have an ACL that works from both local and SSH sessions.

### 4. Install tmux

```bash
brew install tmux
```

### 5. Configure tmux

Create `~/.tmux.conf`:

```
# Use Ctrl+A as prefix (easier than default Ctrl+B)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Tab management
bind c new-window -c "#{pane_current_path}"
bind n next-window
bind p previous-window

# Split panes
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Mouse support
set -g mouse on

# Start window numbering at 1
set -g base-index 1

# Terminal colors
set -g default-terminal "xterm-256color"

# Status bar (Catppuccin Mocha colors)
set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
set -g window-status-current-style "bg=#89b4fa,fg=#1e1e2e,bold"
set -g status-left " #S "
set -g status-right " %H:%M "
```

### 6. Configure `~/.zshrc` on the remote Mac

Add all of these to `~/.zshrc`:

```bash
# Terminal type — forces correct keymapping for SSH sessions
export TERM=xterm-256color

# Backspace fix for SSH
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

# Unlock Keychain automatically on shell start (prompts for password over SSH)
security unlock-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null

# Claude Code TUI fix — TERM must be set at launch time, not just in the shell
# Without this, backspace and arrow keys break inside Claude Code's TUI over SSH
alias claude='TERM=xterm-256color command claude'
```

**Why both the `export` and the alias?** The `export TERM` fixes the regular shell. But Claude Code's TUI doesn't inherit the shell's TERM variable — it needs it passed explicitly at launch. The alias handles that.

**Why `.zshrc` and not `.zprofile`?** SSH interactive shells don't source `.zprofile`. We tested this — `.zprofile` commands don't run when connecting via SSH. `.zshrc` is sourced for all interactive shells including SSH.

### 7. Headless power management (if always-on)

If the remote Mac runs daemons (OpenClaw, etc.) and accepts SSH connections, prevent sleep:

```bash
sudo pmset -a sleep 0 disksleep 0 displaysleep 0 womp 1
```

- `sleep 0` — never sleep
- `disksleep 0` — never spin down disks
- `displaysleep 0` — no display sleep (irrelevant on headless, but clean)
- `womp 1` — Wake on LAN (safety net if the machine somehow sleeps)

---

## Setup — Client Machine

Do these on the machine you're SSHing **from**. Choose either Alacritty (steps 8–10) or Apple Terminal (see alternative below step 10).

### 8. Install Alacritty

```bash
brew install --cask alacritty
```

On first launch, macOS Gatekeeper will block it. Click "Done", go to System Settings → Privacy & Security, scroll down and click "Open Anyway". This is a one-time approval.

### 9. Install a Nerd Font

Nerd Fonts include icons used by tmux and CLI tools:

```bash
brew install --cask font-fira-code-nerd-font
```

### 10. Configure Alacritty

Create `~/.config/alacritty/alacritty.toml`:

```toml
[env]
TERM = "xterm-256color"

[font]
size = 14.0

[font.normal]
family = "FiraCode Nerd Font"

[window]
option_as_alt = "Both"

# Catppuccin Mocha - warm dark theme, good contrast
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.cursor]
text = "#1e1e2e"
cursor = "#f5e0dc"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#bac2de"

[colors.bright]
black = "#585b70"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#a6adc8"
```

**Note:** If colors don't apply on first launch, fully quit Alacritty (Cmd+Q) and relaunch. The config file must exist before Alacritty starts.

### 11. Configure SSH

Edit `~/.ssh/config`:

```
Host studio
    HostName 10.0.0.235        # replace with remote Mac's IP
    User tess                   # replace with remote username
    RequestTTY yes
    SetEnv TERM=xterm-256color
```

**Note:** `SetEnv` only works if the remote Mac's `/etc/ssh/sshd_config` includes `AcceptEnv TERM`. If it doesn't, the `export TERM` and alias in the remote's `.zshrc` (step 6) handle it anyway.

### Alternative: Apple Terminal (instead of steps 8–10)

If you prefer maximum stability over customization, Apple Terminal works with zero configuration. It uses `xterm-256color` natively, has no focus reporting quirks, and requires no Gatekeeper approval.

**Install Catppuccin Mocha theme:**

1. Download the `.terminal` profile from: https://github.com/catppuccin/Terminal.app
   - Go to `themes/` folder → download `Catppuccin Mocha.terminal`
2. Open Terminal → Settings (Cmd+,) → Profiles tab
3. Click the `...` icon below the profile list → Import → select the downloaded file
4. Select "Catppuccin Mocha" in the profile list and click "Default" at the bottom

**Set the font:**

1. In the same Profiles tab, click "Change..." next to the font preview
2. Select **FiraCode Nerd Font**, size 14 (install first: `brew install --cask font-fira-code-nerd-font`)

**Enable Option as Meta key:**

1. In the Profiles tab → Keyboard tab
2. Check "Use Option as Meta Key" — needed for some CLI tools and tmux shortcuts

**No other client-side configuration needed.** The remote Mac `.zshrc` handles TERM, bindkey, and Keychain unlock. tmux provides tabs and session persistence. Skip steps 8–10 and continue with step 11.

**Tradeoff vs Alacritty:** Apple Terminal doesn't support font ligatures (Fira Code's `=>` `!=` `->` won't render as connected glyphs). If that matters to you, use Alacritty.

### 12. Create a connection alias (optional)

Add to `~/.zshrc` on the client:

```bash
alias studio='TERM=xterm-256color ssh -t tess@10.0.0.235'
```

Then just type `studio` to connect. Both `studio` and `ssh studio` will work (the SSH config handles the latter).

---

## Connection Workflow

Every time you connect:

```bash
ssh studio                          # or just: studio
# Enter SSH password
# Enter Keychain password (automatic prompt from .zshrc)
tmux                                # or: tmux attach (to reattach after disconnect)
cd ~/crumb-vault
claude
```

Should show your subscription (e.g., `Opus 4.6 · Claude Max`), not `API Usage Billing`.

**After a reboot:** The Keychain password prompt appears automatically on first connect (from the `.zshrc` line). No extra steps needed.

**After a dropped SSH connection:** `tmux attach` reattaches to your running session. Claude Code sessions survive the disconnect.

---

## tmux Cheat Sheet

All commands use `Ctrl+A` as the prefix key (press `Ctrl+A`, release, then the next key):

| Action | Keys |
|--------|------|
| New tab | `Ctrl+A c` |
| Next tab | `Ctrl+A n` |
| Previous tab | `Ctrl+A p` |
| Go to tab 1-9 | `Ctrl+A 1`, `Ctrl+A 2`, etc. |
| Vertical split | `Ctrl+A \|` |
| Horizontal split | `Ctrl+A -` |
| Detach (leave running) | `Ctrl+A d` |
| Reattach | `tmux attach` |
| List sessions | `tmux ls` |
| Kill session | `tmux kill-session` |

---

## Setting Up Additional Machines

To add another remote Mac, repeat steps 1–7 on that machine, then add a new `Host` entry in your client's `~/.ssh/config`:

```
Host othermac
    HostName 10.0.0.xxx
    User username
    RequestTTY yes
    SetEnv TERM=xterm-256color
```

And optionally add an alias on the client:

```bash
alias othermac='TERM=xterm-256color ssh -t username@10.0.0.xxx'
```

---

## Troubleshooting

| Symptom | Cause | Fix |
|---------|-------|-----|
| `Sonnet 4.6 · API Usage Billing` | Keychain locked or ACL issue | Unlock keychain; if still failing, delete credential and re-create from SSH (step 3) |
| GitHub username prompt on `/login` | Keychain locked, ACL issue, or npm version | Unlock keychain; delete + re-create credential from SSH; verify `which claude` → `~/.local/bin/claude` |
| Backspace acts like tab (shell) | terminfo mismatch | Verify `export TERM=xterm-256color` in remote `.zshrc` |
| Backspace/arrows broken in Claude Code TUI only | TUI doesn't inherit shell TERM | Add alias: `alias claude='TERM=xterm-256color command claude'` to remote `.zshrc` |
| Claude hangs on startup | No auth token available | Unlock keychain; verify credential exists: `security find-generic-password -s "Claude Code-credentials"` |
| `ANTHROPIC_API_KEY` conflict warning | Both API key and subscription login set | Remove `ANTHROPIC_API_KEY` from `.zshrc`; use subscription auth only |
| Keychain unlock doesn't persist after reboot | macOS locks keychain on reboot | Expected — the `.zshrc` line handles this automatically on next SSH connect |
| `.zprofile` commands not running over SSH | SSH doesn't source `.zprofile` | Move everything to `.zshrc` instead |
| `TERM` is empty inside Claude Code | TUI spawns without inheriting env | Use the claude alias (step 6) — forces TERM at launch |
| Alacritty colors not loading | Config file created after first launch | Fully quit (Cmd+Q) and relaunch Alacritty |
| tmux session lost | Forgot to use tmux | Always start with `tmux` or `tmux attach` after SSH |

## Reference: Remote Mac `~/.zshrc`

Complete working config:

```bash
# PATH
export PATH="$PATH:/Users/tess/.local/bin"

# Terminal
export TERM=xterm-256color
bindkey '^H' backward-delete-char
bindkey '^?' backward-delete-char

# Claude Code auth over SSH
security unlock-keychain ~/Library/Keychains/login.keychain-db 2>/dev/null

# Claude Code TUI keymapping fix
alias claude='TERM=xterm-256color command claude'
```

## Reference: Remote Mac `~/.tmux.conf`

Complete working config:

```
# Use Ctrl+A as prefix (easier than default Ctrl+B)
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# Tab management
bind c new-window -c "#{pane_current_path}"
bind n next-window
bind p previous-window

# Split panes
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"

# Mouse support
set -g mouse on

# Start window numbering at 1
set -g base-index 1

# Terminal colors
set -g default-terminal "xterm-256color"

# Status bar (Catppuccin Mocha colors)
set -g status-style "bg=#1e1e2e,fg=#cdd6f4"
set -g window-status-current-style "bg=#89b4fa,fg=#1e1e2e,bold"
set -g status-left " #S "
set -g status-right " %H:%M "
```

## Reference: Client Machine `~/.config/alacritty/alacritty.toml`

Complete working config:

```toml
[env]
TERM = "xterm-256color"

[font]
size = 14.0

[font.normal]
family = "FiraCode Nerd Font"

[window]
option_as_alt = "Both"

# Catppuccin Mocha
[colors.primary]
background = "#1e1e2e"
foreground = "#cdd6f4"

[colors.cursor]
text = "#1e1e2e"
cursor = "#f5e0dc"

[colors.normal]
black = "#45475a"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#bac2de"

[colors.bright]
black = "#585b70"
red = "#f38ba8"
green = "#a6e3a1"
yellow = "#f9e2af"
blue = "#89b4fa"
magenta = "#f5c2e7"
cyan = "#94e2d5"
white = "#a6adc8"
```
