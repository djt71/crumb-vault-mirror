---
type: plan
project: vault-restructure
domain: software
status: approved
created: 2026-02-20
updated: 2026-02-20T17:30
tags:
  - plan
---

# Migration Plan — vault-restructure

Value-first phased migration. Each phase is an atomic commit with its own verification
checklist. Phases are independent — you can stop after any phase and the vault is functional.

**Source data:**
- [[vault-restructure-analysis-20260220]] — open question triage
- [[2026-02-20-vault-restructure]] — peer review with action items
- Path manifest and Obsidian link audit (embedded below)

**Estimated total effort:** 4.5-5.5 hours across Phases 0-3 + 1B (Phase 4 deferred)

---

## Reference Counts (Exact Manifest)

| Target | Unique files | Total refs | Files outside target dir |
|--------|-------------|------------|--------------------------|
| docs/ | 63 | 379 | 29 |
| scripts/ | 37 | 100 | 20 |
| reviews/ | 35 | 117 | 10 |
| session-log | 21 | 102 | 10 |
| failure-log | 11 | 37 | 3 |
| signals.jsonl | 24 | 76 | 11 |
| **Total** | **92** | **722** | **83** |

**Obsidian link risk:** Low. Only 5 links in docs/ use breakable formats (3 hardcoded
relative paths in crumb-studio-migration.md, 2 relative paths in openclaw-crumb-reference.md).
All embeds use basename-only `![[file]]` format (safe). No wiki-links-with-path-prefix pattern.

---

## Phase 0: Pre-Flight (No Moves)

**Goal:** Low-risk improvements that provide immediate value, independent of directory moves.

### 0A: Clean up stale root files

```
rm print-mode-results.txt print-mode-test7-results.txt
```

Verify `.zprofile` with user — if home-dir config, remove from vault root.

### 0B: Add project_class metadata

Add `project_class: system | knowledge` to all 6 project-state.yaml files:
- `system`: crumb-tess-bridge, inbox-processor, openclaw-colocation, vault-restructure
- `knowledge`: think-different, customer-intelligence, notebooklm-pipeline

### 0C: Create Projects/index.md

Curated index listing projects by class. Pin in Obsidian.

### 0D: Fix frontmatter misclassifications

- `docs/skill-authoring-conventions.md`: change `project: crumb` → `project: null`
- `docs/protocols/inline-attachment-protocol.md`: change `project: crumb` → `project: null`

### 0E: Create project-affiliated reference notes

Create reference notes (not symlinks) for openclaw-colocation artifacts:
- `Projects/openclaw-colocation/design/specification.md` → wikilink to [[openclaw-colocation-spec]]
- `Projects/openclaw-colocation/design/specification-summary.md` → wikilink to [[openclaw-colocation-spec-summary]]
- `Projects/openclaw-colocation/design/integration-reference.md` → wikilink to [[openclaw-crumb-reference]]

### 0F: External tooling inventory

Search outside the vault for absolute references to vault paths that will break after moves:
- Shell dotfiles: `~/.zshrc`, `~/.zprofile`, `~/.bashrc`
- Launch agents: `~/Library/LaunchAgents/*.plist`
- Alfred/Raycast workflows (if applicable)
- Any automation referencing `crumb-vault/scripts/`, `crumb-vault/docs/`, or `crumb-vault/reviews/`

Document findings. Decide per-reference: update in the same phase as the move, or defer.

### 0G: Fix breakable Obsidian links in docs/

Before any move, convert the 5 breakable links to wiki links:
- `docs/crumb-studio-migration.md` lines 353, 670, 674: replace `](../crumb-vault/docs/...)` with `[[filename]]`
- `docs/openclaw-crumb-reference.md` lines 151, 153: replace `](../Projects/...)` and `](../reviews/)` with wiki links

**Verification:** `vault-check.sh` passes. Commit.

**Effort:** ~30 minutes.

---

## Phase 1: Move docs/ → _system/docs/ (Value-First)

> **Obsidian sort order note:** `_system/` (underscore prefix) sorts **above** letter-prefixed
> directories in Obsidian's case-insensitive alphabetical sort. System dirs cluster together
> as a header band at the top of the explorer (`_attachments/`, `_inbox/`, `_openclaw/`,
> `_system/`); user content (`Domains/`, `Projects/`) sits below them. This is consistent
> with the vault's existing underscore convention. The UX improvement is **grouping**, not
> "sinking" — all system plumbing consolidates under one prefix instead of scattered across
> `docs/`, `scripts/`, `reviews/` interleaved with user directories.

**Goal:** Biggest Obsidian UX improvement. Consolidates the largest system directory under
`_system/`, grouping it with other underscore-prefixed infrastructure and clearing the
explorer's mid-section for user content.

**Scope:** 29 files outside docs/ reference `docs/` paths (379 total refs, but internal
cross-refs move together). The 29 external files need `docs/` → `_system/docs/` replacement.

### Pre-move updates (all in one commit with the move)

**Critical system files (update BEFORE move, commit WITH move):**

1. **CLAUDE.md** — 18 `docs/` refs → `_system/docs/`
2. **AGENTS.md** — 2 `docs/` refs
3. **scripts/session-startup.sh** — 2 refs to `docs/overlays/overlay-index.md`
4. **scripts/vault-check.sh** — line 175: change `for dir in Projects Domains docs` →
   `for dir in Projects Domains _system/docs`; plus 2 other `docs/` refs
5. **.claude/settings.local.json** — 2 `docs/` refs in permission patterns
   **Also audit `.claude/settings.json`** for any `docs/` permission patterns — update whichever
   file(s) actually gate permissions. Both files may contain relevant patterns.

**Skill files (7 skills):**

6. `.claude/skills/audit/SKILL.md` — 13 `docs/` refs
7. `.claude/skills/writing-coach/SKILL.md` — 10 refs
8. `.claude/skills/peer-review/SKILL.md` — 6 `docs/` refs
9. `.claude/skills/action-architect/SKILL.md` — 6 refs
10. `.claude/skills/inbox-processor/SKILL.md` — 5 refs
11. `.claude/skills/systems-analyst/SKILL.md` — 4 refs
12. `.claude/skills/startup/SKILL.md` — 1 ref

**Other files:**

13. ~~`session-log.md` — 5 `docs/` refs~~ **SKIP.** Historical log entries are immutable records.
    Rewriting "loaded docs/overlays/..." in a Feb 18 entry is revisionism. Accept grep false
    positives during verification — see exclusion patterns in checklist below.
14. `setup-vault-structure.sh` — 7 refs (if not removed in Phase 0)
15. Project run-logs and specs — **skip historical entries** (same rationale as item 13).
    Only update forward-looking refs (e.g., "Resume by reading docs/..." at session end).
16. `_openclaw/README.md` — 1 ref

**Internal docs/ files — vault-root-absolute refs:**

> **Important:** Files inside docs/ that reference other docs/ files using vault-root-absolute
> paths (e.g., `docs/protocols/foo.md`) need `_system/docs/` updates too. These are NOT
> relative paths — they won't survive the directory move automatically. Only `[[wikilinks]]`
> and `../sibling.md`-style relative refs are safe without updates.

17. `docs/crumb-design-spec-v1-7-1.md` — 162+ refs. **Two-pass approach:**
    - First pass: bulk find-replace `docs/` → `_system/docs/`
    - Second pass (30 min): manual line-by-line review using this decision rule:
      - **Update:** "how to run", "current structure", "must exist", configuration examples,
        path references in operational instructions → change to `_system/docs/`
      - **Keep old:** explicitly historical sections, version history entries, prose describing
        the pre-migration architecture, "was previously at" descriptions → leave as `docs/`
        and label the section `(historical, pre-_system/)` if ambiguous
      - **Smoke test:** after pass, click/resolve 5+ of the most important linked paths in Obsidian
18. `docs/separate-version-history.md` — 67 refs
19. Other docs/ files with self-references

### Step 0: Close Obsidian

Close the Obsidian application before any file moves. Obsidian's file watcher will see
`git mv` as delete-then-create events and may trigger automatic link updates, creating a
race condition with our manual replacements.

### The move

```bash
mkdir -p _system
git mv docs/ _system/docs/
```

### Post-move verification checklist

- [ ] `bash scripts/session-startup.sh` completes (scripts still at old location —
      only docs/ has moved; the script's internal `docs/` refs were updated to `_system/docs/`)
- [ ] Overlay index loads: `[ -f _system/docs/overlays/overlay-index.md ]`
- [ ] **Secondary verification** (independent of vault-check.sh, since we modified it):
      `test -d _system/docs && test -f _system/docs/overlays/overlay-index.md && bash -n scripts/session-startup.sh && bash -n scripts/vault-check.sh && echo "OK"`
- [ ] `bash scripts/vault-check.sh` passes (updated to scan `_system/docs/`)
- [ ] Reopen Obsidian — docs appear under `_system/docs/` in explorer
- [ ] No broken links in Obsidian (check via search or manual spot-check; close/reopen tabs if panes show "file not found")
- [ ] Grep verification (scoped): `grep -r --include='*.md' --include='*.sh' --include='*.json' --include='*.yaml' 'docs/' . | grep -v '_system/docs/' | grep -v '.git/' | grep -v 'node_modules' | grep -v 'session-log' | grep -v 'progress/run-log' | grep -v 'progress-log'`
- [ ] Grep verification (unrestricted, one-time): `grep -r 'docs/' . | grep -v '_system/docs/' | grep -v '.git/'`
      — triage any unexpected file types. Catches .txt, .py, .config, etc.
      **Expected false positives:** historical log entries (session-log, run-logs, progress-logs)
      are intentionally preserved — they record what paths existed at the time.

**Commit:** One atomic commit. Message: `refactor: move docs/ → _system/docs/ (Phase 1)`

**Effort:** ~2.5 hours (largest phase — 162-ref spec file with manual review pass dominates).

---

## Phase 1B: Spec Version Bump to v1.8

**Goal:** Document the architectural change introduced by `_system/`. Separate commit from
Phase 1 so the path-rewrite diff and the spec-evolution diff are independently reviewable
and independently revertable.

**Prerequisite:** Phase 1 committed successfully.

### Changes

1. **Version header:** Update spec version from v1.7.1 → v1.8
2. **§2.1 directory diagram:** Redraw to show `_system/` structure
3. **Version history section:** Add entry explaining `_system/` as a new top-level
   organizational concept — system plumbing grouped under underscore-prefixed header band
4. **File rename:** `git mv _system/docs/crumb-design-spec-v1-7-1.md _system/docs/crumb-design-spec-v1-8.md`
5. **Update all references** to the old spec filename. Find them:
   `grep -r 'crumb-design-spec-v1-7-1' . --include='*.md' --include='*.sh' --include='*.json' --include='*.yaml' | grep -v '.git/'`
   Expected hits: CLAUDE.md, AGENTS.md, skill files, other docs that link to the spec.
   Update each to `crumb-design-spec-v1-8`.

**Rationale for v1.8 (minor) not v1.7.2 (patch):** Introducing `_system/` changes the
vault's architectural model — it's a new top-level organizational concept, not a path fix.

**Commit:** Atomic. Message: `docs: bump spec to v1.8 — _system/ architecture (Phase 1B)`

**Effort:** ~30 minutes.

---

### Cross-Phase State Note (Phase 1 → Phase 2)

After Phase 1 (and optionally 1B), the vault is in a mixed state:
- `docs/` → moved to `_system/docs/` (all refs updated)
- `scripts/` → still at vault root (refs still use `scripts/`)
- `reviews/` → still at vault root (refs still use `reviews/`)
- `.claude/settings.local.json` has `_system/docs/` patterns but still has `scripts/` and
  `reviews/` patterns (correct — those haven't moved yet)

This is a **valid, functional state**. You can stop here and the vault works. If you do
stop, be aware that `settings.local.json` permission patterns reflect the mixed state.

---

## Phase 2: Move scripts/ → _system/scripts/

**Goal:** Complete system infrastructure consolidation for scripts. Critical path: SessionStart hook.

**Scope:** 20 files outside scripts/ reference `scripts/` paths.

### Migration sequence

The `.claude/settings.json` hook is the hard constraint. All steps in one atomic commit.

1. **Close Obsidian** (same rationale as Phase 1 — prevent file-watcher race).
2. **Fix VAULT_ROOT depth** in `scripts/session-startup.sh` line 12 (edit in-place, before move):
   `VAULT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"` → `VAULT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"`
   At depth 2 (`_system/scripts/`), the old `..` resolves to `_system/`, not vault root. Needs `../..`.
   (Audit confirmed: `vault-check.sh` uses `pwd` — no depth dependency, safe without changes.)
3. **Update** remaining `scripts/` references: CLAUDE.md (1 ref), AGENTS.md (1 ref), design spec,
   other docs files (see pre-move list below).
4. **Move:** `git mv scripts/ _system/scripts/` — creates `_system/scripts/` atomically. No pre-copy
   step (pre-creating the target directory would cause `git mv` to nest or fail).
5. **Update** `.claude/settings.json` hook: `bash scripts/session-startup.sh` → `bash _system/scripts/session-startup.sh`
6. **Update** `.claude/settings.json` and `.claude/settings.local.json` permission patterns:
   `Bash(bash scripts/vault-check.sh*)` → `Bash(bash _system/scripts/vault-check.sh*)`
   `Bash(bash scripts/*)` → `Bash(bash _system/scripts/*)`
7. **Verify** the hook works: run `bash _system/scripts/session-startup.sh` from a terminal.
8. **Commit** after all verifications pass.

### Pre-move updates

- CLAUDE.md — 1 `scripts/` ref
- AGENTS.md — 1 `scripts/` ref
- The design spec (`_system/docs/crumb-design-spec-v*.md` — v1.7.1 or v1.8 depending on whether Phase 1B ran) — `scripts/` refs
- `_system/docs/crumb-studio-migration.md` — 6 refs
- Project run-logs — `scripts/` refs
- `setup-vault-structure.sh` — 2 refs (if still exists)

### Post-move verification checklist

- [ ] New session starts successfully (hook fires from `_system/scripts/session-startup.sh`)
- [ ] `bash _system/scripts/vault-check.sh` passes
- [ ] Permission rules allow running scripts from new location
- [ ] No `scripts/` directory exists at vault root
- [ ] Reopen Obsidian — no broken links or missing panes
- [ ] Grep verification: `grep -r 'scripts/' . | grep -v '_system/scripts/' | grep -v '.git/'`

**Commit:** Atomic. Message: `refactor: move scripts/ → _system/scripts/ (Phase 2)`

**Effort:** ~45 minutes (smaller scope, but hook testing is careful work).

---

## Phase 3: Move reviews/ → _system/reviews/

**Goal:** Complete the system directory consolidation for review artifacts.

**Scope:** 10 files outside reviews/ reference `reviews/` paths.

### Step 0: Close Obsidian

Close Obsidian before any file moves (same rationale as Phase 1).

### Pre-move updates

1. `.claude/skills/peer-review/SKILL.md` — 8 `reviews/` refs → `_system/reviews/`
2. `.claude/settings.local.json` — 4 `reviews/` refs in permissions.
   **Also audit `.claude/settings.json`** for any `reviews/` permission patterns (mirror Phase 1 approach).
3. `_system/docs/peer-review-skill-spec.md` — 11 refs (already moved in Phase 1)
4. AGENTS.md — 1 ref
5. `.obsidian/workspace.json` — auto-managed, skip
6. Project run-logs — historical `reviews/` refs

### The move

```bash
git mv reviews/ _system/reviews/
```

### Post-move verification checklist

- [ ] Peer-review skill can write to `_system/reviews/` and `_system/reviews/raw/`
- [ ] `bash _system/scripts/vault-check.sh` passes
- [ ] Reopen Obsidian — reviews appear under `_system/reviews/`
- [ ] Grep verification: `grep -r 'reviews/' . | grep -v '_system/reviews/' | grep -v '.git/'`

**Commit:** Atomic. Message: `refactor: move reviews/ → _system/reviews/ (Phase 3)`

**Effort:** ~30 minutes.

---

## Phase 4: Move logs → _system/logs/ (Deferred)

**Goal:** Consolidate operational logs under `_system/logs/`.

**Status: Deferred.** Execute Phases 0-3 + 1B first, then live with the result for at
least a week before deciding. The visual clutter problem is solved by Phases 1-3 — docs/,
scripts/, and reviews/ consolidate under `_system/`, grouped with other underscore-prefixed
dirs at the top of the explorer. Phase 4 moves `session-log.md` (vault root)
and two files already inside `_system/docs/` (post-Phase-1). The marginal tidiness gain
doesn't justify the coupling churn on session-end sequences, startup scripts, and CLAUDE.md
until the Phase 0-3 result is validated in daily use.

**Scope:** 3 logical file groups, 24 combined external references. Not "high coupling" — the
refs are well-understood and mechanical. The real issue is low ROI, not high risk.

### What moves

- `session-log.md` → `_system/logs/session-log.md`
- `session-log-*.md` (monthly archives) → `_system/logs/session-log-*.md`
- `_system/docs/failure-log.md` → `_system/logs/failure-log.md` (already in _system/ from Phase 1)
- `_system/docs/signals.jsonl` → `_system/logs/signals.jsonl` (already in _system/ from Phase 1)

### Pre-move updates

1. CLAUDE.md — 5 `session-log` refs, 1 `failure-log` ref, 1 `signals.jsonl` ref
2. `_system/scripts/session-startup.sh` — 8 `session-log` refs
3. `_system/scripts/vault-check.sh` — 4 `session-log` refs
4. `.claude/skills/checkpoint/SKILL.md` — 2 `session-log` refs
5. `.claude/skills/audit/SKILL.md` — 2 `failure-log` refs, session-log refs
6. `.claude/skills/startup/SKILL.md` — 1 `session-log` ref
7. `_system/docs/file-conventions.md` — session-log rotation convention
8. The design spec (`_system/docs/crumb-design-spec-v*.md`) — ~30 session-log, ~15 failure-log, ~10 signals refs

### Post-move verification checklist

- [ ] Session-end sequence writes to `_system/logs/session-log.md`
- [ ] Rating 1 sessions append to `_system/logs/failure-log.md`
- [ ] Signal capture appends to `_system/logs/signals.jsonl`
- [ ] Session-startup.sh finds and parses session-log correctly
- [ ] vault-check.sh validates session-log files in new location
- [ ] Monthly rotation creates archives in `_system/logs/`
- [ ] Grep verification for remaining bare refs

**Commit:** Atomic. Message: `refactor: consolidate logs → _system/logs/ (Phase 4)`

**Effort:** ~45 minutes.

---

## Go/No-Go Criteria (Per Phase)

Before committing any phase, ALL must be true:

1. **Hook test:** `bash scripts/session-startup.sh` (Phases 0-1) or `bash _system/scripts/session-startup.sh` (Phase 2+) completes without error
2. **Validation test:** `vault-check.sh` passes
3. **Grep clean:** No stale references to old paths outside moved directories (excluding .git/
   and historical log entries — session-log, run-logs, progress-logs are immutable records)
4. **Obsidian test:** Vault reopened, no broken-link indicators in moved files
5. **Skill spot-check:** At least one skill that references moved paths can load its context (manually verify one overlay loads)

If ANY check fails: fix before committing. If fix is non-obvious: stop, assess, don't proceed to next phase.

---

## Rollback

Each phase is a single git commit. Rollback for any phase:

```bash
git revert HEAD
```

If mid-phase (uncommitted): `git checkout -- .` restores tracked files to pre-phase state.
Also check for **untracked artifacts** (e.g., newly created `_system/` directories from copy steps):
`git clean -n` to preview, then `git clean -fd _system/` if those directories shouldn't exist yet.
Check `git status` frequently during risky phases to track what's staged vs untracked.

If session is locked out (SessionStart hook broken in Phase 2):
1. Manually edit `.claude/settings.json` to restore old hook path
2. Or: run `git revert HEAD` from a regular terminal (not Claude Code)

---

## Directory Structure (After Phases 0-3 + 1B)

```
crumb-vault/
├── _attachments/               # System — underscore band (top of explorer)
├── _inbox/                     # System — inbox processor drop zone
├── _openclaw/                  # System — Tess communication channel
├── _system/                    # System — all other plumbing consolidated here
│   ├── docs/                   # Spec (v1.8), conventions, overlays, solutions, protocols
│   ├── reviews/                # Peer review notes + raw/
│   └── scripts/                # vault-check, session-startup, setup
├── Domains/                    # User content (below underscore band)
├── Projects/                   # User content
│   └── index.md               # Curated project listing by class
├── session-log.md              # Stays at root (Phase 4 deferred)
├── CLAUDE.md                   # Stays at root (Claude Code requirement)
├── AGENTS.md                   # Stays at root
└── .claude/                    # Hidden (skills, settings, agents)
```

**If Phase 4 is later approved:**

```
_system/
├── docs/
├── logs/                       # session-log, failure-log, signals.jsonl
├── reviews/
└── scripts/
```
