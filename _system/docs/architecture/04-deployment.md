---
type: reference
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
tags:
  - system/architecture
topics:
  - moc-crumb-architecture
---

# 04 — Deployment

This section describes the physical hosting, process model, network topology, storage layout, credential management, and DNS configuration of the Crumb/Tess system.

**Source attribution:** Synthesized from the design spec ([[crumb-design-spec-v2-4]] §7, §9), [[crumb-deployment-runbook]], [[crumb-studio-migration]], [[openclaw-colocation-spec]], LaunchAgent/LaunchDaemon plists in `_openclaw/staging/`, and live system state.

---

## Host

Single physical host: **Mac Studio M3 Ultra** (96 GB RAM, 1 TB SSD, macOS 15+).

Three macOS user accounts:

| User | Role | Purpose |
|------|------|---------|
| `tess` | Operator primary | Owns the vault. Runs Crumb (Claude Code sessions). Hosts all LaunchAgents except Apple snapshot. |
| `openclaw` | Service account | Runs the OpenClaw gateway (LaunchDaemon). Dedicated user for Tess runtime isolation. |
| `danny` | Apple data owner | Personal macOS account. Runs the Apple snapshot LaunchAgent (Reminders, Calendar, Notes). Must be logged in (GUI or Fast User Switching background) for Apple integrations. |

**Remote access:** SSH via Tailscale mesh network. No public internet exposure. Client machines (work laptop, phone) connect through Tailscale's WireGuard tunnel using MagicDNS hostnames or direct Tailscale IPs (`100.x.y.z`).

**Terminal stack:** SSH → tmux (session persistence, `Ctrl+A` prefix, Catppuccin Mocha theme) → Claude Code (native installer, not npm).

---

## Process Model

```mermaid
%%{init: {'theme': 'default'}}%%
flowchart TD
    subgraph gui_domain["gui/ domain (tess user)"]
        cc["Claude Code\n(interactive sessions)"]
        bw["bridge-watcher.py\n(KeepAlive)"]
        hp["health-ping\n(15 min)"]
        ac["awareness-check\n(30 min)"]
        et["email-triage\n(30 min, waking hrs)"]
        vh["vault-health\n(2:00 AM)"]
        da["daily-attention\n(6:30 AM)"]
        or["overnight-research\n(11:00 PM)"]
        vgc["vault-gc\n(4:00 AM)"]
    end

    subgraph gui_danny["gui/ domain (danny user)"]
        as["apple-snapshot\n(30 min, waking hrs)"]
    end

    subgraph system_domain["system/ domain"]
        gw["OpenClaw Gateway\n(node, port 18789)"]
    end

    subgraph external["External"]
        telegram["Telegram API"]
        anthropic["Anthropic API"]
        ollama["Ollama\n(local, qwen3-coder)"]
    end

    cc -->|"inference"| anthropic
    bw -->|"triggers dispatch"| cc
    gw -->|"Tess Voice"| anthropic
    gw -->|"Tess Mechanic"| ollama
    gw <-->|"messaging"| telegram
    hp -->|"heartbeat"| telegram
    ac -->|"awareness"| telegram
    et -->|"email alerts"| telegram
    as -->|"writes snapshots"| bw

    style cc fill:#e1f5fe
    style gw fill:#fff3e0
```

### Prose Summary (for environments that cannot render Mermaid)

Three launchd domains host the system's processes:

**`gui/` domain (tess user):** Claude Code runs as interactive terminal sessions (on-demand, not persistent). The bridge-watcher is a persistent Python process (KeepAlive) monitoring `_openclaw/inbox/` via kqueue for sub-ms file detection. Seven LaunchAgent jobs run on intervals: health-ping (15 min), awareness-check (30 min), email-triage (30 min during waking hours), vault-health (2:00 AM), daily-attention (6:30 AM), overnight-research (11:00 PM), and vault-gc (4:00 AM).

**`gui/` domain (danny user):** The apple-snapshot LaunchAgent writes Apple data (Reminders, Calendar, Notes) to `_openclaw/state/` every 30 minutes during waking hours. Requires danny's GUI session to be active.

**`system/` domain:** The OpenClaw gateway runs as a LaunchDaemon (`ai.openclaw.gateway`), bound to `127.0.0.1:18789`. This is the Tess runtime — manages Telegram bindings, model routing (Haiku via cloud, qwen3-coder via local Ollama), cron scheduling, and plugin dispatch.

### Service Inventory

| Label | Type | User | Schedule | Purpose |
|-------|------|------|----------|---------|
| `ai.openclaw.gateway` | LaunchDaemon | openclaw | Always-on | OpenClaw gateway (Tess runtime) |
| `com.crumb.bridge-watcher` | LaunchAgent | tess | KeepAlive | kqueue watcher → bridge dispatch |
| `ai.openclaw.health-ping` | LaunchAgent | tess | Every 900s | Dead man's switch heartbeat |
| `ai.openclaw.awareness-check` | LaunchAgent | tess | Every 1800s | Awareness check (bash, Telegram) |
| `ai.openclaw.email-triage` | LaunchAgent | tess | Every 1800s (waking) | Email classification + labeling |
| `ai.openclaw.vault-health` | LaunchAgent | tess | 2:00 AM daily | Nightly vault integrity check |
| `ai.openclaw.daily-attention` | LaunchAgent | tess | 6:30 AM daily | Daily attention planning |
| `ai.openclaw.overnight-research` | LaunchAgent | tess | 11:00 PM daily | Scheduled research dispatch |
| `com.crumb.vault-gc` | LaunchAgent | tess | 4:00 AM daily | Vault garbage collection |
| `com.crumb.apple-snapshot` | LaunchAgent | danny | Every 1800s (waking) | Apple data snapshots to `_openclaw/state/` |
| `com.crumb.drive-sync` | LaunchAgent | danny | 5:00 AM daily | Sync docs to Google Drive for NotebookLM |

**Plist locations:** `_openclaw/staging/m1/` (milestone 1 services), `_openclaw/staging/m2/` (milestone 2), `_system/scripts/com.crumb.bridge-watcher.plist`. Deployed to `~/Library/LaunchAgents/` or `/Library/LaunchDaemons/` as appropriate.

**Project-registered services:** Projects with `repo_path` in `project-state.yaml` may list service labels in a `services` field. Session-end build verification restarts these services after code changes.

---

## Network Topology

```mermaid
%%{init: {'theme': 'default'}}%%
flowchart LR
    subgraph studio["Mac Studio (192.168.x.x / 100.x.y.z)"]
        gw["OpenClaw Gateway\n127.0.0.1:18789"]
        cc["Claude Code"]
        ollama_svc["Ollama\n127.0.0.1:11434"]
    end

    subgraph tailscale["Tailscale Mesh"]
        laptop["Work Laptop"]
        phone["Phone"]
    end

    subgraph internet["Internet (outbound only)"]
        anthropic["Anthropic API"]
        telegram["Telegram API"]
        openai["OpenAI API"]
        google["Google APIs\n(Gemini, Gmail, Drive)"]
        deepseek["DeepSeek API"]
        xai["xAI API (Grok)"]
        github["GitHub"]
        lucid["Lucidchart API"]
    end

    laptop -->|"SSH (port 22)"| studio
    phone -->|"Telegram"| telegram
    telegram <-->|"bot webhooks"| gw
    cc -->|"inference"| anthropic
    gw -->|"Tess Voice"| anthropic
    gw -->|"Tess Mechanic"| ollama_svc
    cc -->|"peer/code review"| openai
    cc -->|"peer review"| google
    cc -->|"peer review"| deepseek
    cc -->|"peer review"| xai
    cc -->|"diagrams"| lucid
    cc -->|"git push/pull"| github
    gw -->|"email ops"| google
```

### Prose Summary

The Mac Studio has no inbound ports open to the public internet. All remote access uses Tailscale's WireGuard mesh (encrypted, authenticated, NAT-traversing).

**Inbound traffic:**
- SSH (port 22) from Tailscale peers only
- Telegram bot webhooks to OpenClaw gateway (via Telegram's infrastructure, not direct)

**Internal services (loopback only):**
- OpenClaw gateway: `127.0.0.1:18789` (WebSocket)
- Ollama: `127.0.0.1:11434` (HTTP)

**Outbound traffic:**
- Anthropic API (Crumb inference + Tess Voice)
- OpenAI, Google, DeepSeek, xAI APIs (peer/code review panels)
- Telegram API (Tess messaging)
- Google APIs (Gmail, Calendar, Drive)
- GitHub (vault and project repo operations)
- Lucidchart API (diagram export)

**Health check endpoints:**
- Gateway liveness: `nc -z -w3 127.0.0.1 18789` or `curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:18789/`
- Note: `lsof -nP -iTCP:18789` gives false negatives without sudo for openclaw-owned sockets

---

## Storage Layout

### On-Host Storage

```
/Users/tess/
├── crumb-vault/                    # THE VAULT — Obsidian + git-tracked
│   ├── Projects/                   # Active project scaffolds
│   ├── Archived/Projects/          # Archived projects
│   ├── Domains/                    # 8 life domain directories
│   ├── Sources/                    # Knowledge notes (books, articles, signals)
│   ├── _system/                    # Infrastructure (docs, scripts, logs, reviews)
│   ├── _inbox/                     # Manual file drop zone
│   ├── _attachments/               # Unaffiliated binary storage
│   ├── _openclaw/                  # Tess workspace + bridge transport
│   ├── .claude/                    # Skills, agents, settings
│   ├── .git/                       # Version history (markdown only)
│   ├── CLAUDE.md                   # Governance surface
│   └── AGENTS.md                   # Tool-agnostic context
├── crumb-vault-mirror/             # GitHub mirror (read-only, for claude.ai)
└── .config/crumb/.env              # API keys (mode 600)

/Users/openclaw/
├── .openclaw/
│   ├── openclaw.json               # Gateway configuration
│   └── workspace/                  # Agent workspace
└── .local/bin/openclaw             # Gateway binary

/Users/danny/
└── (standard macOS home — Apple apps data source)
```

### Git Tracking Strategy

The vault is git-tracked for markdown version history. Binary files are excluded:

```gitignore
# Binary attachments — tracked via companion notes
*.pdf  *.docx  *.pptx  *.xlsx
*.png  *.jpg  *.jpeg  *.gif  *.webp  *.svg
```

Companion notes (markdown) ARE tracked — they carry the metadata, description, and references for each binary. The binary itself doesn't benefit from diff-based history.

**Binary durability:** Git does not protect binaries. A separate sync/backup mechanism (Time Machine, iCloud, Obsidian Sync) is required for binary survival.

### Backup

| Mechanism | Scope | Frequency | Location |
|-----------|-------|-----------|----------|
| Git push | Vault markdown | Session-end (conditional) | GitHub (private repo) |
| GitHub mirror sync | Vault markdown | Automated (`mirror-sync.sh`) | `crumb-vault-mirror/` → GitHub (public-safe subset) |
| Time Machine | Full disk | Continuous | External/network drive |
| Vault backup script | Vault state snapshot | Cron (`vault-backup.sh`) | Cloud storage |

---

## Credential Management

### Credential Map

| Credential | Storage | User | Consumer | Rotation |
|-----------|---------|------|----------|----------|
| Anthropic API key | macOS Keychain | tess | Claude Code (Crumb) | Manual |
| OpenAI API key | `~/.config/crumb/.env` | tess | peer-review, code-review skills | Manual |
| Google/Gemini API key | `~/.config/crumb/.env` | tess | peer-review skill | Manual |
| DeepSeek API key | `~/.config/crumb/.env` | tess | peer-review skill | Manual |
| xAI/Grok API key | `~/.config/crumb/.env` | tess | peer-review skill | Manual |
| Lucidchart API key | `~/.config/crumb/.env` | tess | lucidchart skill | Manual |
| TMDB API key | `~/.config/meme-creator/tmdb-api-key` | tess | meme-creator skill | Manual |
| GitHub PAT | macOS Keychain (credential-osxkeychain) | tess | Git push/pull | Auto-cached |
| OpenClaw token | `/Users/openclaw/.openclaw/openclaw.json` | openclaw | Gateway auth | Per config |
| Telegram bot tokens | LaunchAgent plist env vars | tess | awareness-check, email-triage, health-ping | Manual |
| X (Twitter) OAuth | Dynamic (Keychain refresh) | tess | feed-intel framework | Auto-refresh |

### Security Model

**Tier 1 (mandatory, OS-level):**
- Dedicated `openclaw` macOS user — filesystem isolation. Crumb credentials are inaccessible to OpenClaw processes.
- `~/.config/crumb/.env` owned by tess, mode 600 (no group/other read).
- Vault ownership: `tess:crumbvault` group. `openclaw` is a group member with read access. Write restricted to `_openclaw/` via group permissions.

**Tier 1 (mandatory, application-level):**
- `workspaceOnly` in `openclaw.json` restricts LLM file tool access to the OpenClaw workspace. Vault reads go through the app layer, not raw file tools.
- Review safety denylist (`_system/docs/review-safety-denylist.md`) prevents sensitive content in peer/code review dispatches to external APIs.

**Known constraints:**
- `sudo -u <user>` does NOT carry TCC grants. Apple integration snapshots require a LaunchAgent in danny's GUI domain, not cross-user sudo.
- Keychain may prompt for API keys during first SSH session — resolve interactively before automating.
- X OAuth tokens rotate — static env files can't hold them. Dynamic store (Keychain refresh) required.
- `com.apple.provenance` xattr causes `launchctl bootstrap` failures on macOS 15+. Must strip as the absolute last operation before bootstrap.

---

## DNS

The system does not run its own DNS server. DNS resolution uses standard system defaults plus Tailscale MagicDNS.

| Service | Resolution | Notes |
|---------|-----------|-------|
| Tailscale MagicDNS | `<hostname>.tailXXXXXX.ts.net` | Auto-generated from device name. Used for SSH access. |
| Studio direct | Tailscale IP `100.x.y.z` | Alternative to MagicDNS hostname |
| External APIs | Public DNS | Standard system resolver for all outbound API traffic |
| OpenClaw gateway | `127.0.0.1:18789` | Loopback only — no DNS entry needed |

**SSH config (client side):** Host entries in `~/.ssh/config` use either MagicDNS hostnames or direct Tailscale IPs.

---

## Deployment Procedures

Two deployment runbooks exist for different scenarios:

| Runbook | Path | Scope | Time |
|---------|------|-------|------|
| Crumb Deployment | `_system/docs/operator/how-to/crumb-deployment-runbook.md` | Fresh Crumb install on macOS. 8 phases: deps → Claude Code → Git → vault → shell → client → verify → enhancements | ~45 min (fresh), ~15 min (migration) |
| Studio Migration | `_system/docs/crumb-studio-migration.md` | Full system migration including OpenClaw. 14 phases: system → brew → Python → Claude Code → Git → PAT → vault → config → OpenClaw user → permissions → Docker → services | ~2 hours |

**OpenClaw colocation spec:** Full security architecture at `_system/docs/openclaw-colocation-spec.md` (67 KB). Covers the two-layer security model, vault access model, threat model (18 threats + mitigations), and hardening tiers.

---

## Platform-Specific Constraints

macOS-specific behaviors that affect deployment and operations:

| Constraint | Impact | Mitigation |
|-----------|--------|------------|
| TCC grants scoped to bootstrap domain | `sudo -u` doesn't carry TCC. Apple data inaccessible via cross-user process. | LaunchAgent in owning user's GUI domain + snapshot files. |
| Danny must be logged in | Apple integrations fail without GUI session. iCloud stops, AppleScript can't reach apps. | Fast User Switching keeps danny's session alive in background. |
| `com.apple.provenance` xattr | Breaks `launchctl bootstrap` on macOS 15+. Re-attaches on every file edit. | Strip as absolute last step before bootstrap. |
| `date +%H` octal bug | Zero-padded hours cause bash arithmetic errors. | Use `date +%-H` (unpadded). |
| openrsync vs GNU rsync | `--delete-excluded` deletes ALL excluded files including `.git/`. | Use `--delete` + post-sync cleanup. Never `--delete-excluded`. |
| `launchctl list` omits exited jobs | Calendar-interval jobs with exit 0 not shown. | Use `launchctl print gui/$(id -u)/<label>`. |
| npm `--prefix` installs | CLI lands in `.local/bin/` but node binary doesn't. | Reference `/opt/homebrew/bin/node` explicitly in plist ProgramArguments. |
