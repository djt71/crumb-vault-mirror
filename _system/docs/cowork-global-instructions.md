---
project: null
domain: null
type: reference
skill_origin: null
status: active
created: 2026-06-12
updated: 2026-07-06  # observation item 3 added; paste block unchanged — no re-paste needed
related:
  - "_system/docs/work-surfaces.md"
  - "_system/docs/adr-vault-write-boundary.md"
  - "_system/docs/file-conventions.md"
tags:
  - architecture
  - system-config
---

# Cowork Global Instructions (canonical source)

The canonical source for the instruction block pasted into **Cowork → Settings →
Global Instructions**. Closes the gap verified 2026-06-11: Cowork does not read
CLAUDE.md or fire lifecycle hooks, so it sees the vault's files but none of its
conventions ([[work-surfaces]], Verification List).

**Maintenance discipline (per the Memory Ownership policy):** this file originates;
the Cowork settings field is a disposable projection. Edit here first, bump
`updated`, then re-paste the block below into Cowork settings. Never edit in Cowork
settings directly. Zero loss if the surface copy is wiped.

**Scope:** stable invariants only. No project status, priorities, or milestone
state — live state stays in the vault files the block points to. If an instruction
here starts changing more than rarely, it belongs in a vault file, not in this block.

---

## Paste block

Copy everything inside the fence into Cowork's global instructions field.

```
# Working in Danny's Crumb vault

Some of your work happens inside the Obsidian vault at ~/crumb-vault — the
canonical store for all of Danny's projects and knowledge. When a task touches
that folder, these rules apply.

## Orientation
- The vault is the single source of truth. Your own memory is a disposable
  cache — if it conflicts with vault files, the vault wins.
- Project status lives in vault files, not chat history. Before working on any
  project, read Projects/<name>/project-state.yaml and
  Projects/<name>/progress/run-log.md.
- Many docs have a *-summary.md companion — read the summary before the full doc.

## Where to write
- Project deliverables (markdown or binary — docs, sheets, slides, PDFs): inside
  that project's folder under Projects/<name>/.
- New knowledge or reference material not tied to a project: drop the file in
  _inbox/ and stop. Do not file anything into Sources/, Domains/, or Archived/ —
  Danny processes _inbox/ deliberately on the Crumb side.
- Never modify: CLAUDE.md, anything under _system/ or .claude/, or anything
  under Archived/.

## Conventions
- Filenames: kebab-case, descriptive enough to recognize months later.
- Every new markdown file starts with YAML frontmatter:

  ---
  project: <project-name, or null if not project work>
  domain: <software|career|learning|health|financial|relationships|creative|spiritual|lifestyle>
  type: reference
  status: active        # only when project is null — omit on project files
  created: <YYYY-MM-DD>
  updated: <YYYY-MM-DD>
  ---

  If unsure of type, use reference — the commit check will catch real problems.
- Do not add kb/ tags or topics fields — knowledge-graph tagging happens on the
  Crumb side.

## Session discipline
- Never work in the vault while a Claude Code ("Crumb") session has the same
  project open — same working tree, last write wins. If unsure, ask Danny.
- If you changed vault files, end the session by committing with a message
  prefixed "cowork: ". A pre-commit check (vault-check) validates conventions
  and may refuse the commit — fix what it reports, or leave the tree dirty and
  tell Danny what's unresolved. Never bypass it with --no-verify.
- Commit only; don't push. Danny's Crumb sessions handle push and reconciliation.

## What you don't have here
These instructions are your only standing context for this vault — you don't
load its CLAUDE.md, hooks, or skills. For conventions beyond this block, read
_system/docs/file-conventions.md or ask Danny.
```

---

## Open observation items

Carried from the scheduler verification
(`Projects/agentic-sunset/design/scheduler-verification-2026-06.md`):

1. **Do global instructions reach Cowork's *scheduled* task runs**, or only
   interactive sessions? If they reach scheduled runs, the "scheduled prompts must
   be fully self-contained" constraint softens.
2. **Does Cowork share the Claude Code project memory directory**
   (`~/.claude/projects/.../memory/`)? Still the one unresolved item from the
   2026-06-11 verification pass.
3. **Do connectors (Gmail) reach Cowork's *scheduled* runs?** Load-bearing for
   the feed-intel Gmail digest ([[cowork-feed-instructions]] — its setup
   checklist step 1 is the test: one-off scheduled task → one-line self-email).
   Added 2026-07-06.

Log answers here and in [[work-surfaces]] when observed.
