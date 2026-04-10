---
type: specification-summary
domain: software
status: active
created: 2026-04-04
updated: 2026-04-04
source_updated: 2026-04-04
project: vault-mobile-access
---

# vault-mobile-access — Specification Summary

## One-Line

Quartz v4 static site serving the Crumb vault over Tailscale for read-only iPhone access.

## Problem

No mobile access to the vault. Danny is cut off from context when away from a workstation.

## Solution

Quartz v4 generates a static site from the vault on the Mac Studio. `npx serve` serves it on port 8080. iPhone accesses it over Tailscale MagicDNS. Rebuilds run every 15 minutes via launchd with atomic swap (build-to-temp, rename) and rollback on failure.

## Key Decisions

- **Quartz v4** — leading free SSG with native Obsidian syntax support
- **Content ingestion** — symlink vault into Quartz's `content/` dir, filter via `ignorePatterns`
- **Web server** — `npx serve` on `0.0.0.0:8080`, reachable only via Tailscale/LAN
- **Addressing** — Tailscale MagicDNS hostname for the iPhone bookmark
- **LaunchAgent under tess** — requires `tess` logged in; Mac Studio always awake (sleep disabled)
- **Read-only** — no write path in MVP
- **Default theme** — Quartz defaults + mobile CSS fixes; Enlightenment aesthetic is a follow-up

## System Requirements

- Mac Studio sleep disabled (Tailscale needs an awake host)
- `tess` user logged in for LaunchAgent services

## Tasks

| ID | Description | Risk | Depends On |
|---|---|---|---|
| VMA-001 | Install and configure Quartz v4 | low | — |
| VMA-002 | iOS mobile CSS fixes | low | VMA-001 |
| VMA-003 | Web server + launchd service | medium | VMA-001 |
| VMA-004 | Automated rebuild (15 min, atomic swap) | low | VMA-001, VMA-003 |

## Open Questions

- Build time for ~3600 files (benchmark in VMA-001)
- Search index size impact on mobile load (measure in VMA-001)
- Any vault content that breaks Quartz build (validate in VMA-001)
