---
type: tasks
domain: software
status: active
skill_origin: action-architect
created: 2026-04-04
updated: 2026-04-04
project: vault-mobile-access
---

# vault-mobile-access — Tasks

| id | description | state | depends_on | risk_level | domain | acceptance_criteria |
|---|---|---|---|---|---|---|
| VMA-001 | Install and configure Quartz v4 for vault | pending | — | low | code | Quartz v4 cloned to `/Users/tess/quartz-vault/`; `content/` symlinked to vault; `ignorePatterns` excludes `_system/scripts/`, `_system/logs/`, `_openclaw/state/`, `_openclaw/inbox/`, `_staging/`, `.claude/`, `.git/`, `.obsidian/`; `npx quartz build` completes successfully; wikilinks, backlinks, tag pages resolve; images render; Mermaid diagrams render; build time and search index size recorded |
| VMA-002 | iOS mobile CSS fixes | pending | VMA-001 | low | code | Left/right margins present on mobile viewport; sidebar/explorer contained (no overflow); graph view disabled on mobile widths via CSS media query or Quartz config; no horizontal scrolling on iPhone; verified in Chrome on iPhone over Tailscale |
| VMA-003 | Web server + launchd service | pending | VMA-001 | medium | code | `npx serve` serves `public/` on `0.0.0.0:8080`; LaunchAgent plist in `~/Library/LaunchAgents/`; `KeepAlive: true`; starts on tess login; accessible from iPhone at Tailscale MagicDNS hostname; service label in project-state.yaml `services` list |
| VMA-004 | Automated rebuild with atomic swap | pending | VMA-001, VMA-003 | low | code | LaunchAgent runs rebuild every 15 minutes; build to `public-next/`, validate, rename swap; on failure: log error, retain current `public/`; build stdout/stderr logged to file; site available during rebuild |
