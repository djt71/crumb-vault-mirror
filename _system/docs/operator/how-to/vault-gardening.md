---
type: reference
domain: software
skill_origin: null
status: active
created: 2026-02-24
updated: 2026-07-03
tags:
  - vault-gardening
  - system-config
  - system/operator
---

# Vault Gardening

Periodic curation practice for the knowledge base — deleting stale KB notes with git provenance after reference checks. Keeps the vault's signal-to-noise ratio healthy as Crumb sessions and manual captures add content over time. (Rewritten 2026-07-03, vault-optimization B3/A11: the former archive-to-`Archived/KB/`-then-purge flow is replaced by direct deletion — git history is the archive.)

## Scope

Applies to all `#kb/`-tagged notes across `Domains/`, `Sources/`, and `_system/docs/solutions/`. Project docs follow their own archival lifecycle (spec §4.6) and are out of scope for vault gardening.

## Archive Procedure

**Trigger:** Human-initiated. When you notice stale content in vault snapshots, during audit, or when the KB feels cluttered.

**Steps (per candidate note):**

1. Identify candidate notes — content that has lost relevance: tools evaluated and rejected, patterns superseded by better approaches, reference material for completed projects
2. Run the reference checks below. Any live reference blocks deletion until resolved.
3. On operator confirmation, delete the note directly (`git rm`). Git history is the archive — record the deleting commit (or the note's path) in the run-log or session-log so the content is retrievable via `git log --follow` / `git show`.

**Reference checks per note (before deletion):**

1. **Inbound wikilinks** — search active notes for `[[note-name]]` references. If any exist, the note stays or the linking note gets updated first (same-commit remediation).
2. **Outbound attachment/companion references** — if the note references binaries or companions, verify those references won't break on deletion.
3. **MOC entries** — check parent MOC(s) listed in the note's `topics` field. Remove or update stale MOC entries in the same commit as the deletion.
4. **`#kb/` tag coverage gaps** — if the note is the sole carrier of a Level 3 subtopic tag, flag for decision: delete the tag scope, or transfer the tag to another note.

**What NOT to delete:**

- Notes with recent inbound wikilinks from active project work
- MOC files (garden the MOC's children, not the MOC itself)
- Notes actively referenced by companion notes or attachment chains

**All deletions require explicit operator confirmation.** The audit skill never deletes KB notes autonomously. There is no parking stage — a note is either live or deleted-with-provenance.

## Relationship to Other Practices

| Practice | Scope | Trigger |
|---|---|---|
| **Project archival** (spec §4.6) | Project directories | Project completion |
| **Vault gardening** (this doc) | KB-tagged notes | Human-initiated, audit-recommended |
| **Audit KB health check** (audit Step 9) | Orphaned/untagged KB notes | Weekly audit |
| **Solution doc consolidation** (audit Step 11) | `_system/docs/solutions/` | Weekly audit |

Vault gardening complements — not replaces — the audit skill's KB health check. The health check finds orphaned and untagged notes; gardening deletes notes that are properly tagged but no longer relevant.

## Design Decisions

- **Human-triggered:** No automated staleness heuristic. The human decides what's stale — automated detection risks false positives on infrequently-accessed but valuable reference material.
- **No new skill:** Folded into the existing audit skill as additional weekly/monthly steps. A dedicated skill would be premature — the practice is lightweight and runs infrequently.
- **Delete over park (2026-07-03, vault-optimization A11):** The former two-stage flow (archive to `Archived/KB/`, purge later at a 20-note threshold) is retired with the `Archived/` directory. Aggressive deletion with git provenance replaces it — reversibility comes from git history (`git show <commit>:<path>`), not from a parking directory. Reference checks that previously ran at purge time now run before deletion.
