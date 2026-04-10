---
type: plan
project: vault-restructure
domain: software
status: active
created: 2026-02-20
updated: 2026-02-20
skill_origin: action-architect
tags:
  - plan
  - action-plan
---

# Action Plan — vault-restructure

Decomposition of the approved migration plan into milestones and atomic tasks.
Each milestone corresponds to a migration phase and produces one atomic git commit.

**Source:** [[migration-plan]] (approved 2026-02-20, 2 rounds peer review)
**Total tasks:** 18
**Estimated effort:** 4.5-5.5 hours across 5 milestones

---

## Milestone 1: Phase 0 — Pre-Flight

**Goal:** Low-risk cleanup and metadata improvements. No directory moves.
**Commit:** One atomic commit after all sub-tasks complete.
**Success criteria:** vault-check passes, all project-state.yaml files have project_class,
breakable links converted, external tooling inventory documented.

### Tasks

- **VRS-001:** Delete stale root files + fix frontmatter misclassifications (0A+0D)
- **VRS-002:** Add project_class metadata to all project-state.yaml files (0B)
- **VRS-003:** Create Projects/index.md (0C)
- **VRS-004:** Create openclaw-colocation reference notes (0E)
- **VRS-005:** Run external tooling inventory (0F)
- **VRS-006:** Fix breakable Obsidian links in docs/ (0G)
- **VRS-007:** Phase 0 verification + commit

**Risk:** Low. No moves, no path changes, no system file modifications.

---

## Milestone 2: Phase 1 — Move docs/ → _system/docs/

**Goal:** Consolidate docs/ under _system/. Biggest UX improvement.
**Commit:** One atomic commit containing all path updates + the directory move.
**Prerequisite:** Close Obsidian before starting. Reopen during verification.
**Success criteria:** vault-check passes, session-startup.sh runs clean, overlay index
loads from new location, unrestricted grep shows only expected false positives
(historical log entries).

### Tasks

- **VRS-008:** Update critical system files (CLAUDE.md, AGENTS.md, scripts, settings)
- **VRS-009:** Update 7 skill files for docs/ → _system/docs/
- **VRS-010:** Update remaining external files (setup-vault-structure.sh, _openclaw/, forward-looking log refs)
- **VRS-011:** Two-pass design spec update (162+ refs — bulk replace + 30-min manual review)
- **VRS-012:** Update internal docs/ vault-root-absolute refs (separate-version-history.md, others)
- **VRS-013:** Execute `git mv docs/ _system/docs/` + full verification checklist + commit

**Risk:** High. Largest scope (379 refs, 29 external files). Spec manual review is the
critical path. Secondary verification (independent of vault-check.sh) mitigates
circular-validation risk.

---

## Milestone 3: Phase 1B — Spec Version Bump

**Goal:** Document the _system/ architectural change in the spec itself.
**Commit:** Separate from Phase 1 — clean diff showing only spec evolution.
**Success criteria:** Spec version header reads v1.8, §2.1 diagram shows _system/ structure,
version history explains the change, all references to old filename updated.

### Tasks

- **VRS-014:** Bump spec to v1.8: version header, §2.1 diagram, version history, file rename,
  update all references to old spec filename + commit

**Risk:** Medium. File rename touches multiple references, but grep command in plan
identifies them deterministically.

---

## Milestone 4: Phase 2 — Move scripts/ → _system/scripts/

**Goal:** Consolidate scripts/ under _system/. Critical path: SessionStart hook.
**Commit:** One atomic commit.
**Prerequisite:** Close Obsidian. VAULT_ROOT depth fix must happen before move.
**Success criteria:** New session starts successfully with hook at new path,
vault-check.sh passes from new location, no scripts/ directory at vault root.

### Tasks

- **VRS-015:** Fix VAULT_ROOT depth in session-startup.sh + update all scripts/ refs in external files
- **VRS-016:** Execute `git mv scripts/ _system/scripts/` + update hook + update permissions + verify + commit

**Risk:** High. SessionStart hook is a single point of failure. If hook breaks,
Claude Code can't start. Rollback documented: edit settings.json from terminal
or `git revert HEAD`.

---

## Milestone 5: Phase 3 — Move reviews/ → _system/reviews/

**Goal:** Complete system directory consolidation for review artifacts.
**Commit:** One atomic commit.
**Prerequisite:** Close Obsidian.
**Success criteria:** Peer-review skill writes to _system/reviews/, vault-check passes,
no reviews/ directory at vault root.

### Tasks

- **VRS-017:** Update all reviews/ refs (skill, settings, docs, AGENTS.md)
- **VRS-018:** Execute `git mv reviews/ _system/reviews/` + verify + commit

**Risk:** Low. Smallest scope (10 external files). Peer-review skill is the main consumer.

---

## Dependency Graph

```
VRS-001 ─┐
VRS-002 ─┤
VRS-003 ─┤
VRS-004 ─├─→ VRS-007 ─→ VRS-008 ─┐
VRS-005 ─┤              VRS-009 ─┤
VRS-006 ─┘              VRS-010 ─├─→ VRS-013 ─→ VRS-014 ─→ VRS-015 ─→ VRS-016 ─→ VRS-017 ─→ VRS-018
                         VRS-011 ─┤
                         VRS-012 ─┘
```

Phase 0 tasks (001-006) are independent of each other, gated by VRS-007 (commit).
Phase 1 tasks (008-012) are independent of each other, gated by VRS-013 (move+commit).
Milestones 3-5 are strictly sequential — each depends on the prior milestone's commit.
