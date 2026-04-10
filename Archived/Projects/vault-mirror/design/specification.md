---
type: specification
project: vault-mirror
domain: software
status: draft
created: 2026-02-20
updated: 2026-02-20
skill_origin: systems-analyst
tags:
  - infrastructure
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Vault Mirror — Project Specification

## Problem

Claude.ai (claude.ai/app conversations) is stateless across sessions and cannot access
the crumb-vault filesystem. Currently, Danny must manually upload files each session to
provide context. This is friction-heavy, error-prone (wrong files, stale versions), and
limits the depth of collaboration without extensive file juggling.

## Solution

A read-only GitHub mirror repository containing only system-level vault artifacts.
Claude.ai clones this repo at conversation start using a fine-grained PAT pasted once
per session. A post-commit hook in the main vault keeps the mirror in sync automatically.

## Architecture

```
crumb-vault (local, Studio)
    │
    ├── .git/hooks/post-commit  ──►  sync script
    │                                    │
    │                                    ▼
    │                            crumb-vault-mirror/ (local staging)
    │                                    │
    │                                    ▼ git push
    │                            github.com/<user>/crumb-vault-mirror (private)
    │                                    │
    │                                    ▼ git clone (per session)
    │                            claude.ai compute environment (ephemeral)
```

## Included Paths (Allowlist)

These paths are mirrored. Everything else is excluded.

```
_system/docs/                   # Design spec, conventions, overlays, protocols, solutions
_system/scripts/                # vault-check, session-startup
_system/reviews/                # Peer review outputs (not raw/)
_system/logs/                   # If Phase 4 executes; otherwise session-log.md from root
.claude/skills/                 # All skill definitions
CLAUDE.md                       # System policy
AGENTS.md                       # Agent directory
Projects/*/*.md                 # Top-level project docs (action plans, tasks, specs, summaries)
Projects/*/design/              # Design subdirectory (specs, analysis docs)
Projects/*/progress/            # Progress subdirectory (run-logs, progress-logs)
Projects/*/project-state.yaml   # Project metadata
Projects/index.md               # Project classification index
```

## Excluded Paths (Denylist)

These paths are never mirrored. The boundary is: no user content, no customer data,
no credentials, no agent comms.

```
Domains/                        # All personal content (career, health, financial, etc.)
Projects/customer-intelligence/ # Customer account data — confidentiality obligation
_attachments/                   # Binary files, images
_inbox/                         # Unprocessed intake
_openclaw/                      # Agent communication channel (separate security boundary)
_system/reviews/raw/            # Raw API responses (large, low value for context)
.claude/settings.json           # May contain path-based permission rules
.claude/settings.local.json     # Local overrides
.env*                           # Any environment files
session-log*.md                 # Operational logs at root (if Phase 4 not executed)
```

## Sync Mechanism — Post-Commit Hook

### Behavior

1. Fires after every `git commit` in the main vault
2. Checks whether any files in the allowlist paths changed in the commit
3. If no allowed-path files changed → exit (no-op)
4. If allowed-path files changed → rsync allowed paths to mirror staging dir → commit → push
5. Mirror commit message: `sync: <original commit message>`

### Hook Implementation Requirements

- Must be fast — target <5s for no-op case, <15s for sync case
- Must not block the main vault commit (run sync in background if needed)
- Must handle the case where mirror repo doesn't exist yet (skip gracefully)
- Must exclude denylist paths even if they're inside an allowlist glob
  (e.g., `Projects/customer-intelligence/design/` matches the allowlist
  but must be excluded)
- Must handle deleted files (removals in vault should propagate to mirror)
- Log sync operations to `_system/logs/mirror-sync.log` (append-only, one line per sync)

### Configuration

Store mirror config in `_system/docs/mirror-config.yaml`:

```yaml
mirror_repo_path: ~/crumb-vault-mirror
mirror_remote: origin
mirror_branch: main
log_file: _system/logs/mirror-sync.log
```

The hook reads this config rather than hardcoding paths.

## GitHub Repository Setup

- **Visibility:** Private
- **Name:** `crumb-vault-mirror` (or similar)
- **Branch:** `main` only
- **Access:** Fine-grained PAT, read-only (`contents: read`), scoped to this single repo
- **PAT expiration:** 30 days, rotate on expiry
- **No GitHub Actions, no CI, no webhooks** — this is a passive read target

## Claude.ai Session Workflow

At the start of a new claude.ai conversation, paste a single message with the PAT
and a curl command pointing at the context doc. Claude reads it via the GitHub raw
content API, then fetches additional files on demand using the same URL pattern.

No git clone needed — reads only the files required for the session, keeping
context overhead minimal. See `_system/docs/claude-ai-session-prompt.md` for the
exact prompt template.

The PAT is visible in the conversation transcript. This is acceptable because:
- The token is read-only and scoped to a single repo
- The repo contains only system artifacts (no credentials, no customer data, no personal content)
- Anthropic's data handling: Pro plan conversations are not used for training
- 30-day expiration bounds exposure window

## Security Invariants

1. The mirror never contains files outside the allowlist
2. The denylist is enforced at sync time, not just at setup time
3. `customer-intelligence` project is always excluded regardless of allowlist globs
4. No credentials, tokens, or `.env` files are ever synced
5. The PAT grants read-only access to the mirror repo only — not the main vault
6. Raw review files (`reviews/raw/`) are excluded to avoid syncing full API responses

## Dependencies

- **Prerequisite:** vault-restructure project complete (Phases 0-3 + 1B)
  — the `_system/` directory structure must exist before the allowlist makes sense
- **GitHub account** with fine-grained PAT support
- **rsync** on the Studio (should already be available)

## Verification

After setup, verify:

1. `git log` in mirror shows sync commits tracking vault commits
2. No denylist files present: `find . -path '*/customer-intelligence/*'` returns nothing
3. No credentials: `grep -r 'token\|password\|secret\|API_KEY' .` returns nothing
4. Clone from a fresh location using the PAT succeeds
5. Modify a spec in the vault, commit, verify mirror updates within 15s

## Open Questions

1. Should `_system/reviews/raw/` be included? Large JSON files but potentially useful
   for reviewing synthesis quality. Current recommendation: exclude (low value-to-size ratio).
2. Should the mirror include git history or be squash-committed? History is useful for
   diffing spec versions; squash keeps the repo small. Recommendation: preserve history.
3. Should session-log.md be mirrored? It's operational data, not system design, but
   provides useful session context. Recommendation: exclude for now, revisit.
