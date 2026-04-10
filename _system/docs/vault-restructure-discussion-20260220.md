---
project: null
domain: software
type: reference
skill_origin: inbox-processor
status: active
created: 2026-02-20
updated: 2026-02-20
tags:
  - kb/software-dev
topics:
  - moc-crumb-architecture
---

# Vault Restructure Discussion — 2026-02-20

## Context

External conversation between Danny and Claude (claude.ai, not Claude Code) reviewing the crumb-vault structure and discussing organizational improvements. Danny provided a full vault backup (2026-02-20 03:00) for analysis.

## Topic 1: Claude Code Permission Configuration

**Problem:** Approval fatigue during development sessions — constant prompts to approve routine file operations.

**Decision:** Expand `.claude/settings.json` permissions allowlist rather than using `--dangerously-skip-permissions`. Settings.local.json split was considered and rejected as unnecessary ceremony for a solo project.

**Final config applied:** Broad allowlist covering Read, Write, Edit, MultiEdit, Glob, Grep, LS, plus common bash commands (git, cat, ls, mkdir, cp, mv, touch, echo, diff, wc, sed, chmod, rm, python, node). Deny rules for `rm -rf /`, `sudo *`, and `.env*` reads. Hooks section (SessionStart) preserved unchanged.

**Status:** Applied to `.claude/settings.json` on Tess.

## Topic 2: Vault Structure — System vs. Knowledge Separation

**Problem:** As the vault grows, the Obsidian file explorer mixes system plumbing with user-facing content. Danny's primary interface for reviewing files is the Obsidian client, so navigation clarity matters.

**Current state (top-level):** AGENTS.md, CLAUDE.md, Domains/, Projects/, _attachments/, _openclaw/, docs/, reviews/, scripts/, session-log.md, plus stale scratch files (print-mode-results.txt, setup-vault-structure.sh).

### Proposal A: `_system/` consolidation

Push system infrastructure below user content in Obsidian's alphabetical sort:

```
crumb-vault/
├── Domains/                    # User content — top of list
├── Projects/                   # User content
├── _attachments/               # User content, agent-managed
├── _openclaw/                  # Tess communication
├── _system/                    # All system plumbing
│   ├── docs/                   # design spec, file conventions, convergence rubrics, etc.
│   ├── reviews/                # peer review outputs + raw/
│   ├── scripts/                # vault-check, session-startup, etc.
│   ├── logs/                   # session-log, failure-log, signals.jsonl
│   └── migration/              # one-time bootstrap artifacts
├── CLAUDE.md                   # Stays at root (Claude Code requirement)
├── AGENTS.md                   # Stays at root
```

**Key decisions:**
- `personal-context.md` stays in system (it's system config about the user, not knowledge content)
- CLAUDE.md and AGENTS.md must remain at vault root
- `.claude/` directory (skills, settings) is unaffected (hidden in Obsidian by default)

**Migration cost:** Path updates across CLAUDE.md (~5 refs), design spec (~54 `Projects/` refs but those don't move, docs/ refs do change), vault-check.sh (~14 refs to update), file-conventions.md, and skills referencing docs/. One-time mechanical work.

**Status:** Conceptually agreed. Not yet implemented.

### Proposal B: Project classification (system vs. knowledge)

**Problem:** Projects/ contains both system-building projects (crumb-tess-bridge, openclaw-colocation, inbox-processor, notebooklm-pipeline) and knowledge/content projects (think-different, customer-intelligence). These serve fundamentally different purposes.

**Options analyzed:**

1. **Two top-level directories** (`Projects/` + `_system/projects/`) — Clean but doubles the path machinery. Rejected as too disruptive.
2. **Subdirectories** (`Projects/system/` + `Projects/knowledge/`) — Less disruptive but adds navigation depth. Not selected.
3. **Metadata-based** (`project_class: system | knowledge` in frontmatter) — No path changes, filterable via Obsidian search/Dataview. Recommended by Claude.

**Status:** Under discussion. Danny's feedback suggests the friction is real — system projects and knowledge projects feel like they belong in different places. The metadata approach avoids path surgery but doesn't solve the Obsidian browsing experience. No decision finalized.

## Open Questions for Crumb Analysis

1. Does the `_system/` consolidation create any conflicts with existing vault-check assumptions or skill context contracts?
2. What's the full scope of path references that would need updating for the `_system/` move?
3. Should the project classification question be solved via directory structure, metadata, or both?
4. Are there docs currently in `docs/` that should migrate to their respective project directories instead of `_system/docs/`? (e.g., `openclaw-colocation-spec.md` → `Projects/openclaw-colocation/`)
5. What stale/scratch files at vault root can be safely removed? (`print-mode-results.txt`, `print-mode-test7-results.txt`, `setup-vault-structure.sh`)

## Compound Candidates

- **Pattern:** Obsidian UX as a design constraint for vault structure — the file explorer sort order and collapse behavior should inform directory naming conventions (underscore prefix to sink system dirs).
- **Pattern:** System vs. knowledge boundary as a first-class architectural concept — not currently in the spec. Could warrant a section in the design spec if the separation is adopted.
