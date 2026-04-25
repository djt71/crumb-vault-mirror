---
project: obsidian-applenotes-import
domain: software
type: specification-summary
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
source_updated: 2026-04-25
revision: 4
---

# Specification Summary — Obsidian Apple Notes Import

## Problem
Apple Notes accumulates capture-stage thinking that should live in the Obsidian vault. There's no built-in selective migration path — users either copy-paste lossy content or run bulk one-time exporters. This plugin closes the gap with a per-note review-and-import flow that soft-deletes the source after a verified vault write.

## Goals (v1)
List Apple Notes inside Obsidian → selectively import body markdown (with provenance frontmatter; **no attachments in v1**) → soft-delete originals to Apple Notes' Recently Deleted → ship to the community plugin directory.

## Locked Decisions
1. AppleScript via `osascript` (no SQLite reverse-engineering)
2. Soft delete only (Recently Deleted) — **G1 validated 2026-04-25 / macOS 26.3.1**
3. macOS-only; `isDesktopOnly: true`
4. Community-distributable from v1
5. Re-import gate: show already-imported notes disabled with badge; toggle enables re-selection; new unique filename
6. Target folder: settings default + per-import override
7. **Attachments NOT included in v1** — body-only import; attachment objects dropped during conversion with `<!-- [v1: attachment dropped: ...] -->` placeholder; soft-delete proceeds uniformly. Attachment migration deferred to v1.1.
8. HTML→MD via turndown with Apple-Notes-aware pre-processor + custom node-filters; tiered warnings (severe blocks delete; moderate logs; debug-only in receipt log)
9. Frontmatter: `source`, `apple_notes_id`, `apple_notes_account`, `apple_notes_folder`, `apple_notes_created`, `apple_notes_modified`, `imported_at`, `source_had_attachments`, `import_warnings`

## Pre-PLAN Validation Gates — ALL RESOLVED
- ✅ **G1 / A4** — soft-delete validated (2026-04-25, macOS 26.3.1)
- ✅ **G2 / A2** — note id stability validated (2026-04-25, macOS 26.3.1)
- ✅ **G4** — citations pinned in research-brief
- ~~G3 / A7~~ — REMOVED in rev 4 (attachments deferred to v1.1)

## Probe-Derived Implementation Notes
- AppleScript code MUST address notes by id (`whose id is X`), never by name (Apple Notes auto-renames notes from body's first heading).
- `folder of note` raises -1728; iterate folders to determine membership instead.

## Critical Levers
- Composite verify-before-delete (md + index — simpler post rev 4) — OAI-016b
- Strict sequencing as primary safety control — OAI-016a
- Import index integrity + vault listeners + frontmatter-rebuild + conflict policy — OAI-012
- Body-conversion fidelity with severe→delete-block — OAI-009
- TCC failure UX — OAI-019
- **Attachment-loss communication** — README + confirm-dialog must surface that v1 imports body only and source attachments are lost after retention. AC12.
- Submission compliance + release asset inspection — M8 distribution gate

## Workflow & Scope
Domain: software · Class: system · Workflow: four-phase · External repo: `~/code/obsidian-applenotes-import/` (initialized) · Plugin manifest id: `applenotes-import` (no "obsidian" substring per submission rules)

## Tasks
**25 tasks across 8 milestones** (was 27 in rev 3; OAI-008a/008b removed with attachments). M6 split into 5 finer safety-critical tasks (016a..e) with tightened boundaries; verify gate scope reduced (md + index, no attachments).

## Risk Profile
- **Critical:** composite verify-before-delete weakness (OAI-016b adversarial tests), index corruption (OAI-012 safe-degraded mode + repair conflict policy).
- **High:** mid-batch failure cascades, TCC silent lockout, index-vault desync, user trust erosion from undocumented attachment loss (mitigated by AC12).
- **Medium:** AppleScript perf at scale, turndown fidelity gaps, v1.1 attachment migration timing.
- **Cleared:** ~~AppleScript hard-delete~~, ~~note id instability~~ (both probe-validated).

## Revision Status
Revision 4 — pre-PLAN probe outcomes integrated. G2 validated; G3 removed (attachments deferred to v1.1 per operator decision); spec materially simplified. **SPECIFY artifact frozen; all pre-PLAN gates resolved; ready for PLAN.**

## Scope Classification
**MAJOR** — new external repo, destructive third-party operations, community submission. Total review actions applied across 2 peer-review rounds: 53. Plus 1 product-level scope simplification (drop v1 attachments).
