---
type: log
domain: software
status: active
created: 2026-02-20
updated: 2026-02-20
tags:
  - project/vault-mirror
---

# Vault Mirror — Run Log

## Session: 2026-02-20 — Initial scaffold and implementation

### Context Inventory
- Spec provided by user (written in external claude.ai session)
- Prerequisite met: vault-restructure complete, `_system/` structure exists
- GitHub user: `djt71`, `gh` CLI installed and authenticated
- rsync available (`openrsync` protocol 29)
- No existing post-commit hook — pre-commit runs vault-check.sh

**Actions Taken:**
- Scaffolded project: project-state.yaml, run-log.md, progress-log.md, specification.md
- Created `_system/docs/mirror-config.yaml`
- Wrote `_system/scripts/mirror-sync.sh` — allowlist/denylist rsync, background post-commit hook
- Installed `gh` CLI via brew, authenticated as `djt71`
- Created private GitHub repo `djt71/crumb-vault-mirror`
- Initialized local mirror staging at `~/crumb-vault-mirror`
- Wired `.git/hooks/post-commit` to run mirror-sync in background
- Initial seed sync: 114 files pushed
- Fixed: added `.DS_Store` exclude, switched to `--delete-excluded`
- Bug: `--delete-excluded` on macOS openrsync destroys `.git/` in mirror — switched to `--delete` + find cleanup
- Round-trip verified: vault commit → mirror sync → GitHub push → log entry
- PAT clone verified from `/tmp` — 111 files, zero denylist leaks
- Simplified workflow: one-paste clone command (no file upload needed)
- Created permission review doc, promoted 7 patterns to settings.json, cleaned 10 local entries

**Current State:**
- Mirror fully operational: post-commit hook triggers background sync
- All denylist checks pass: 0 customer-intelligence, 0 Domains, 0 credentials, 0 .env
- Sync log active at `_system/logs/mirror-sync.log`
- claude.ai workflow: single paste of clone command with PAT

**Files Modified:**
- `Projects/vault-mirror/` — full project scaffold
- `_system/docs/mirror-config.yaml` — mirror configuration
- `_system/scripts/mirror-sync.sh` — sync script (3 iterations: --delete-excluded → filter protect → --delete)
- `.git/hooks/post-commit` — hook wiring
- `_system/docs/claude-ai-context.md` — created + updated (open items, workflow simplification)
- `.claude/settings.json` — 7 permission patterns promoted
- `.claude/settings.local.json` — 10 entries cleaned

**Compound:** openrsync `--delete-excluded` behavior diverges from GNU rsync — it removes ALL excluded files from destination, not just transferred-then-excluded files. This is a macOS-specific gotcha worth recording to auto memory. Pattern: when using rsync on macOS, prefer `--delete` over `--delete-excluded` and handle cleanup of unwanted files separately.

### Session: 2026-02-20 — Claude Chat domain restrictions fix

**Work completed:**
- User tested vault mirror with Claude Chat — `raw.githubusercontent.com` and `api.github.com` are blocked in that compute environment, but `github.com` (git clone) works
- Reverted session prompt from raw API fetch back to `git clone` approach
- Added context budget guidance to `claude-ai-context.md` — rules for selective file reading, size warnings for heavy files (~365k tokens total across 112 files), ≤5 files per session target
- Rewrote file index to steer toward run-logs first (small/recent) before specs (large/full)
- Synced mirror to GitHub

**Files Modified:**
- `_system/docs/claude-ai-session-prompt.md` — switched from curl/raw API to git clone
- `_system/docs/claude-ai-context.md` — added context budget section, rewrote file index

**Compound:** Claude Chat compute environment blocks `raw.githubusercontent.com` and `api.github.com` but allows `github.com`. Git clone with PAT inline is the reliable access pattern. Routed to auto memory.

## Session: 2026-02-27 — Project archived

Project archived to `Archived/Projects/vault-mirror/`. Operational infrastructure (mirror-sync.sh, mirror-config.yaml, post-commit hook, sync log) remains in `_system/` — mirror continues running independently of project state. No KB artifacts; standard archival path.
