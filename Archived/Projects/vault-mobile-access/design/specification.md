---
type: specification
domain: software
status: active
skill_origin: systems-analyst
created: 2026-04-04
updated: 2026-04-04
project: vault-mobile-access
tags:
  - mobile
  - quartz
  - tailscale
---

# vault-mobile-access — Specification

## Problem Statement

The Crumb vault lives on a Mac Studio and is accessible from a work laptop (drive mapping + SSH), but has no mobile access path. Danny needs to browse and reference vault contents from his iPhone while away from a workstation.

## Why This Matters

The vault is the single source of truth for projects, knowledge, decisions, and context. Without mobile access, Danny is cut off from this context during commutes, meetings, and any time away from a laptop. Read access alone covers the primary need.

## Facts

- Vault: ~3600 files, ~54MB, at `/Users/tess/crumb-vault/`
- iPhone with Chrome (WebKit engine underneath — Apple requirement for all iOS browsers)
- Tailscale VPN connects iPhone to Mac Studio (already configured)
- Mac Studio has Node.js installed (OpenClaw runs on it)
- Mac Studio is always awake (sleep disabled) — confirmed operational requirement
- Vault uses Obsidian syntax: `[[wikilinks]]`, `#tags`, YAML frontmatter, Mermaid diagrams, backlinks, `![[embeds]]`
- Quartz v4 is a leading free static site generator with strong native Obsidian syntax support (wikilinks, backlinks, tags, search) — actively maintained as of evaluation (April 2026)

## Assumptions

- **A1:** Tailscale is reliably connected when Danny wants mobile access — validate: check Tailscale uptime on phone
- **A2:** Quartz v4 build time for ~3600 files will be under 2 minutes — validate: benchmark after install
- **A3:** The `tess` user can run both the Quartz build and the web server — validate: confirm filesystem permissions

## System Requirements

- **SR1:** Mac Studio must remain awake at all times (sleep disabled in System Settings → Energy). Tailscale client requires an awake host to maintain tunnel connectivity.
- **SR2:** `tess` user must be logged in (GUI session or Fast User Switching background session) for LaunchAgent services to run.

## Unknowns

- **U1:** Exact Quartz v4 build time for this vault size and content complexity
- **U2:** FlexSearch index size for ~3600 files — may be several MB, could affect initial mobile load time
- **U3:** Whether Quartz handles all vault content types gracefully (YAML-only files, binary references, non-standard frontmatter)

## System Map

### Components

1. **Quartz v4** — Static site generator (Node.js), installed on Mac Studio
2. **Vault** — Source content at `/Users/tess/crumb-vault/`
3. **Web server** — `npx serve` (Node.js static file server, zero-config)
4. **Rebuild automation** — Scheduled Quartz rebuild via launchd
5. **Tailscale** — Private network connecting iPhone ↔ Mac Studio
6. **iPhone Chrome** — Client browser (WebKit rendering)

### Architecture

```
┌─────────────┐     Tailscale        ┌──────────────────────────────────────┐
│   iPhone     │◄────────────────────►│           Mac Studio                 │
│   Chrome     │   (private net)      │                                      │
│              │                      │  /Users/tess/quartz-vault/           │
│  GET :8843   │──────────────────────│──► npx serve public/ (0.0.0.0:8843) │
│              │   ◄── HTML/CSS/JS    │                                      │
│              │                      │  Rebuild (launchd, every 15 min)     │
│  Tailscale   │                      │    vault/ ──build──► public-next/    │
│  MagicDNS    │                      │    mv public-next/ → public/         │
└─────────────┘                      └──────────────────────────────────────┘

Access URL: http://<mac-studio-tailscale-hostname>:8843
(MagicDNS resolves to the Mac Studio's 100.x.x.x Tailscale IP)
```

### Content Ingestion Strategy

Quartz v4 expects content in its `content/` directory. The vault will be symlinked:

```
/Users/tess/quartz-vault/content → /Users/tess/crumb-vault
```

Exclusions are enforced via Quartz's `ignorePatterns` in `quartz.config.ts`, which accepts glob patterns. This avoids copying or syncing — the vault is read directly, and Quartz filters at build time.

### Dependencies

- Quartz depends on Node.js (already installed for OpenClaw)
- Web server depends on Quartz build output (`public/`)
- Rebuild depends on vault filesystem changes
- iPhone access depends on Tailscale + Mac Studio being awake (SR1)
- LaunchAgent services depend on `tess` being logged in (SR2)

### Constraints

- **iOS WebKit** — Known Quartz mobile rendering issues: missing margins, sidebar overflow, graph view WebKit crash. Addressable with CSS overrides and config changes.
- **Read-only** — No write path in scope. Write-back is a future enhancement if needed.
- **Private network only** — Served over Tailscale, not exposed to internet. Server binds to `0.0.0.0:8843` which is reachable only on LAN and Tailscale interfaces (no port forwarding, no public IP on the Mac Studio).
- **Multi-user filesystem** — Vault owned by `tess`. Server and rebuild run as `tess` (LaunchAgent).

### Levers

- **Content exclusion** — Filtering system/automation directories reduces build time and mobile noise
- **CSS overrides** — Small CSS fixes dramatically improve mobile readability
- **Rebuild frequency** — Balances freshness vs. CPU cost (default: 15 minutes)
- **Graph view** — Disabling on mobile avoids WebKit crash at zero cost to reading experience

### Second-Order Effects

- Periodic CPU load on Mac Studio during rebuilds (bounded, ~1-2 min every 15 min)
- Search index adds to initial page load on mobile (one-time per session)
- Excluded content won't be browsable on mobile (acceptable — it's system internals)

## Content Scope

### Included (all content-bearing directories)

- `Projects/` — all project content
- `Domains/` — domain overviews and MOCs
- `Sources/` — signals, insights, research, knowledge base
- `_system/docs/` — specs, protocols, solutions, overlays
- `_openclaw/research/` — research output
- `Archived/` — historical projects
- Root-level docs (CLAUDE.md, etc.)

### Excluded (system internals, automation state)

| Directory | Reason |
|---|---|
| `_system/scripts/` | Bash scripts — not readable content |
| `_system/logs/` | Machine-generated log files |
| `_openclaw/state/` | Automation state (JSON, timestamps) |
| `_openclaw/inbox/` | Unprocessed feed intel items |
| `_staging/` | Automation work-in-progress |
| `.claude/` | Claude Code skills, agents, settings |
| `.git/` | Version control internals |
| `.obsidian/` | Obsidian app config |

## Design Note: Aesthetic

The Web Design Preference overlay (Library mode) applies in principle — this is a vault-facing reading UI. For MVP, Quartz's default theme with mobile CSS fixes is the pragmatic path. Aesthetic customization (serif typography, warm tones, Tufte-style margins) is a follow-up enhancement, not a blocker.

## Domain Classification & Workflow

- **Domain:** software (system)
- **Workflow:** full four-phase (SPECIFY → PLAN → TASK → IMPLEMENT)
- **Rationale:** External software installation, launchd service, ongoing automation — warrants full ceremony

## Task Decomposition

### VMA-001: Install and configure Quartz v4 `#code`

**Risk:** low
**Dependencies:** none
**Acceptance criteria:**
- Quartz v4 cloned to `/Users/tess/quartz-vault/`
- `content/` symlinked to `/Users/tess/crumb-vault/`
- `ignorePatterns` in `quartz.config.ts` configured for excluded directories
- `npx quartz build` completes successfully
- Local preview shows vault content with wikilinks, backlinks, and tag pages resolved
- Representative content types validated: images render, Mermaid diagrams render, `![[embeds]]` resolve, YAML frontmatter parsed
- Build time and search index size recorded (validates A2, informs U1/U2)

### VMA-002: iOS mobile CSS fixes `#code`

**Risk:** low
**Dependencies:** VMA-001
**Acceptance criteria:**
- Left/right margins present on mobile viewport
- Sidebar/explorer contained within viewport (no overflow)
- Graph view disabled on mobile viewport widths (via CSS media query or Quartz component config)
- Content readable on iPhone without horizontal scrolling
- Verified in Chrome on iPhone over Tailscale

### VMA-003: Web server + launchd service `#code`

**Risk:** medium (launchd considerations)
**Dependencies:** VMA-001
**Acceptance criteria:**
- `npx serve` serves Quartz `public/` directory on `0.0.0.0:8843`
- LaunchAgent plist created under `tess` user (`~/Library/LaunchAgents/`)
- Server starts on `tess` login and restarts on failure (`KeepAlive: true`)
- Accessible from iPhone at `http://<mac-studio-tailscale-hostname>:8843`
- Not accessible from outside Tailscale network (verify: no public IP/port forwarding)
- Service label registered in `project-state.yaml` `services` list

### VMA-004: Automated rebuild `#code`

**Risk:** low
**Dependencies:** VMA-001, VMA-003
**Acceptance criteria:**
- LaunchAgent plist runs Quartz rebuild every 15 minutes
- Rebuild script: build to `public-next/`, validate index.html exists, `mv public public-prev && mv public-next public`, clean up `public-prev/`
- On build failure: log error, retain current `public/` (last-good build), do not swap
- Build stdout/stderr logged to a file for troubleshooting
- Site remains available during rebuild
