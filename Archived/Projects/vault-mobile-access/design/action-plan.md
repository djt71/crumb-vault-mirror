---
type: action-plan
domain: software
status: active
skill_origin: action-architect
created: 2026-04-04
updated: 2026-04-04
project: vault-mobile-access
---

# vault-mobile-access — Action Plan

## Milestone 1: Working Build

Get Quartz v4 installed, configured for the vault, and producing a valid static site.

**Success criteria:**
- Quartz builds the vault without errors
- Wikilinks, backlinks, tags, embeds, and Mermaid render correctly
- Build time and search index size measured

**Tasks:** VMA-001

## Milestone 2: Mobile-Ready + Served

Make the site usable on iPhone and accessible over Tailscale. VMA-002 and VMA-003 are independent of each other — both depend only on Milestone 1.

**Success criteria:**
- Site renders cleanly on iPhone Chrome (no overflow, margins present, graph disabled)
- Accessible at `http://<mac-studio>:8080` from iPhone over Tailscale
- LaunchAgent running and restarting on failure

**Tasks:** VMA-002, VMA-003 (parallel)

## Milestone 3: Automated + Durable

Rebuild automation keeps the site current without manual intervention.

**Success criteria:**
- Site reflects vault changes within 15 minutes
- Failed builds roll back to last-good state
- Build logs available for troubleshooting

**Tasks:** VMA-004

## Dependency Graph

```
VMA-001 (install/configure)
   ├──► VMA-002 (mobile CSS)
   ├──► VMA-003 (web server + launchd)
   │       │
   │       ▼
   └──► VMA-004 (automated rebuild)
```

## Implementation Notes

- **No external repo needed.** Quartz installation is infrastructure on the Mac Studio, not a standalone codebase. Config files live inside the Quartz clone directory.
- **Parallel opportunity.** VMA-002 and VMA-003 are independent after VMA-001 completes. Can be done in either order or the same session.
- **Validation-heavy first task.** VMA-001 carries all the unknowns (build time, content compatibility, index size). If it surfaces problems, they'll be caught before investing in CSS fixes or server setup.
- **Estimated effort:** Small project. All 4 tasks are completable in a single session if VMA-001 build succeeds without content issues.
