---
type: reference
domain: software
skill_origin: null
status: active
created: 2026-02-24
updated: 2026-03-14
tags:
  - vault-gardening
  - system-config
  - system/operator
---

# Vault Gardening

Periodic curation practice for the knowledge base — archiving stale KB notes and purging them after reference checks. Keeps the vault's signal-to-noise ratio healthy as feed-intel pipelines, Crumb sessions, and manual captures add content over time.

## Scope

Applies to all `#kb/`-tagged notes across `Domains/`, `Sources/`, and `_system/docs/solutions/`. Project docs follow their own archival lifecycle (spec §4.6) and are out of scope for vault gardening.

## Archive Procedure

**Trigger:** Human-initiated. When you notice stale content in vault snapshots, during audit, or when the KB feels cluttered.

**Steps:**

1. Identify candidate notes — content that has lost relevance: tools evaluated and rejected, patterns superseded by better approaches, reference material for completed projects
2. Move notes from their active location to `Archived/KB/` (flat directory, no subdirectories)
3. Obsidian resolves wikilinks by filename regardless of directory, so existing backlinks continue to work — nothing breaks on archive
4. Update the note's `status` frontmatter field to `archived`
5. Log the archive action in the active run-log or session-log

**What NOT to archive:**

- Notes with recent inbound wikilinks from active project work
- MOC files (archive the MOC's children, not the MOC itself)
- Notes actively referenced by companion notes or attachment chains

## Purge Review

**Trigger:** Audit skill recommends purge when `Archived/KB/` exceeds 20 notes (weekly check, audit Step 10). Monthly audit Step 8 offers a purge review session when any archived notes exist.

**Reference checks per note:**

1. **Inbound wikilinks** — search active notes (outside `Archived/`) for `[[note-name]]` references. If any exist, the note stays or the linking note gets updated first.
2. **Outbound attachment/companion references** — if the archived note references binaries or companions, verify those references won't break on deletion.
3. **MOC entries** — check parent MOC(s) listed in the note's `topics` field. Remove or update stale MOC entries before deleting the note.
4. **`#kb/` tag coverage gaps** — if the note is the sole carrier of a Level 3 subtopic tag, flag for decision: delete the tag scope, or transfer the tag to another note.

**Purge decision per note:**

- No active references → permanently delete (requires interactive user confirmation)
- Active references found → flag for decision: update references and delete, or move back to active

**All deletions require explicit user confirmation.** The audit skill never deletes KB notes autonomously.

## Relationship to Other Practices

| Practice | Scope | Trigger |
|---|---|---|
| **Project archival** (spec §4.6) | Project directories | Project completion |
| **Vault gardening** (this doc) | KB-tagged notes | Human-initiated, audit-recommended |
| **Audit KB health check** (audit Step 9) | Orphaned/untagged KB notes | Weekly audit |
| **Solution doc consolidation** (audit Step 11) | `_system/docs/solutions/` | Weekly audit |

Vault gardening complements — not replaces — the audit skill's KB health check. The health check finds orphaned and untagged notes; gardening archives notes that are properly tagged but no longer relevant.

## Design Decisions

- **Human-triggered archival:** No automated staleness heuristic. The human decides what's stale — automated detection risks false positives on infrequently-accessed but valuable reference material.
- **Flat archive directory:** `Archived/KB/` has no subdirectories. Origin directory is recoverable from frontmatter (`domain`, `topics` fields). Subdirectories add complexity without value at current scale.
- **No new skill:** Folded into the existing audit skill as additional weekly/monthly steps. A dedicated skill would be premature — the practice is lightweight and runs infrequently.
- **Wikilink resilience:** Obsidian's filename-based resolution means archived notes remain linkable. This makes archival low-risk and reversible.
- **Purge threshold (20 notes):** Balances "review often enough to stay tidy" against "don't nag for a handful of notes." Adjustable based on experience.
