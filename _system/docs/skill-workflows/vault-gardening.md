---
type: reference
status: active
created: 2026-03-12
updated: 2026-03-12
domain: null
---

# Vault Gardening

Ongoing maintenance activities that keep the vault healthy: frontmatter hygiene,
summary freshness, KB discipline, orphan detection, and convention enforcement.
Most of this runs automatically; operator involvement is exception-handling.

## Automated Checks

- **Pre-commit hook:** `vault-check.sh --pre-commit` runs on every `git commit` — scopes
  to staged files only, blocks on errors (exit 2), warns on non-blocking issues (exit 1)
- **Session-start staleness scan:** audit skill's lightweight scan fires every session —
  rotates run-log if needed, loads overlay index, checks `source_updated` vs parent
  `updated` on all summary files, regenerates stale summaries automatically
- **Full-audit prompt:** if 7+ days since last full audit, or 3+ stale summaries found,
  Claude prompts the operator to run a full audit

## /audit Skill

Two tiers:

**Staleness scan (automatic, every session):**
Checks summary file dates, rotates run-log, loads overlay index. Fast — no content reads.

**Full audit (weekly, user-triggered or recommended):**
- Summary spot-checks (content drift, not just timestamp)
- Redundant solution doc consolidation
- Completed task pruning in `tasks.md`
- Failure-log pattern analysis (escalations if same skill fails 2+ times in 30 days)
- KB health: orphaned `#kb/` notes, untagged solution docs, `Archived/KB/` count
- Orphaned solutions check: solution docs with no `required_context` linkage in any skill
- Broken `required_context` path check across all skill YAML frontmatter

**Monthly additions:** project archival candidates, skill activation frequency, CLAUDE.md
line count (target <200, ceiling 250), overlay precision review, hallucination spot-check.

Auto-fixes: regenerate stale summaries, prune tasks, merge redundant docs, update tags.
Flags for human review: archive projects, discard tentative patterns, modify CLAUDE.md.

## vault-check.sh

24 mechanical validations (spec §7.8). Categories enforced:

- **Frontmatter completeness** — required fields present per doc type; `status` required
  on non-project docs; project docs must NOT have `status`
- **Tag discipline** — `#kb/` tags use canonical Level 2 segments only; three-level max;
  `topics:` values must resolve to existing MOC files in `Domains/*/`
- **File conventions** — naming, doc-type taxonomy, summary pairing
- **Code review gate** — checks for review entries on completed code tasks (§23)
- **Domain field** — must be one of the eight canonical domains

Run manually: `_system/scripts/vault-check.sh` (full scan) or `--pre-commit` (staged only).

## Orphan & Staleness Detection

**Orphan notes:** `obsidian orphans` — finds disconnected notes with no inbound or
outbound links. Run during full audit. Candidates for tagging, linking, or deletion.

**Orphaned KB notes:** audit step 9 — `#kb/` tagged notes not linked from any domain
summary. Flag for MOC update or tag removal.

**Stale summaries:** `obsidian properties path=<summary> format=tsv` extracts
`source_updated`; compare against parent doc's `updated` field. Staleness scan does
this automatically; operator only sees it if regeneration fails.

**Orphaned solutions:** solution docs in `_system/docs/solutions/` with no
`required_context` entry in any skill. Found during full audit — either link to a skill
or confirm as discovery-only.

## Common Gardening Tasks

- **Fix frontmatter:** Edit the file directly; re-run `vault-check.sh --pre-commit`
  after staging to confirm clean
- **Regenerate stale summary:** Load the parent doc + skill that owns it; re-run the
  summary step; update `source_updated` in the summary's frontmatter
- **Clean up orphan attachments:** Check `_attachments/` for files with no wikilink
  reference in active notes; confirm with operator before deleting
- **Update MOCs:** When a new `#kb/` tagged note is created, add it to the relevant
  `Domains/<domain>/moc-*.md` — vault-check §18 will fail otherwise
- **Purge `Archived/KB/`:** Monthly audit offers this when count >20. Interactive
  per-note review: check inbound links, outbound refs, MOC entries before deleting
- **Consolidate solution docs:** Merge redundant entries during full audit; preserve the
  doc with more downstream `required_context` linkage as the canonical one
