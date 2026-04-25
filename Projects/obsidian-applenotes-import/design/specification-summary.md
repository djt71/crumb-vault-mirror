---
project: obsidian-applenotes-import
domain: software
type: specification-summary
skill_origin: systems-analyst
created: 2026-04-25
updated: 2026-04-25
source_updated: 2026-04-25
revision: 3
---

# Specification Summary — Obsidian Apple Notes Import

## Problem
Apple Notes accumulates capture-stage thinking that should live in the Obsidian vault. There's no built-in selective migration path — users either copy-paste lossy content or run bulk one-time exporters. This plugin closes the gap with a per-note review-and-import flow that soft-deletes the source after a verified vault write.

## Goals (v1)
List Apple Notes inside Obsidian → selectively import as markdown (with attachments and provenance frontmatter) → soft-delete originals to Apple Notes' Recently Deleted (auto-purge per Apple's standard retention) → ship to the community plugin directory.

## Locked Decisions
1. AppleScript via `osascript` (no SQLite reverse-engineering)
2. Soft delete only (Recently Deleted) — **G1 validated 2026-04-25 / macOS 26.3.1**
3. macOS-only; `isDesktopOnly: true`
4. Community-distributable from v1
5. Re-import gate: show already-imported notes disabled with badge; toggle override enables re-selection; new unique filename
6. Target folder: settings default + per-import override
7. Attachments included in v1 (configurable folder); sequential batch execution
8. HTML→MD via turndown with Apple-Notes-aware pre-processor + custom node-filters; tiered warnings (severe blocks delete; moderate logs; debug-only in receipt log NOT note body)
9. Frontmatter: `source`, `apple_notes_id`, `apple_notes_account`, `apple_notes_folder`, `apple_notes_created`, `apple_notes_modified`, `imported_at`, `imported_attachments`, `import_warnings`

## Pre-PLAN Validation Gates
- ✅ **G1 / A4** — soft-delete validated (2026-04-25, macOS 26.3.1)
- ⏳ **G2 / A2** — note id stability across restart/edit/move (concrete pass criteria defined)
- ⏳ **G3 / A7** — attachment extraction approach decision (per-class thresholds defined)
- ✅ **G4** — citations pinned in research-brief

## Critical Levers
- Composite verify-before-delete (md + attachments + index) — single canonical sequence — OAI-016b
- Strict sequencing as primary safety control: `… write md → persist index → verify → delete` — OAI-016a
- Import index integrity + vault listeners + frontmatter-rebuild + conflict policy — OAI-012
- Body-conversion fidelity with severe→delete-block — OAI-009
- TCC failure UX (first-command probe, structured denial detection, manual re-check) — OAI-019
- Submission compliance + release asset inspection — M8 distribution gate

## Workflow & Scope
Domain: software · Class: system · Workflow: four-phase · External repo: `~/code/obsidian-applenotes-import/` (initialized) · Plugin manifest id: `applenotes-import` (no "obsidian" substring per submission rules)

## Tasks
27 tasks across 8 milestones (M6 split into 5 finer safety-critical tasks per round-1 review; tightened boundaries per round-2). Critical path: M1 foundation → M2 AppleScript bridge probes (incl. G3 attachment decision) → M3/M4 conversion+index → M5 modal (parallel to M7-OAI-019) → M6 orchestrator (split: transaction, verify, delete-gate, batch, receipt) → M7-OAI-020 → M8 distribution.

## Risk Profile
- **Critical:** composite verify-before-delete weakness (OAI-016b adversarial tests), index corruption (OAI-012 safe-degraded mode + repair conflict policy).
- **High:** mid-batch failure cascades, TCC silent lockout, index-vault desync (mitigated by listeners).
- **Medium:** AppleScript perf at scale, turndown fidelity gaps, note-id instability.
- **Cleared:** ~~AppleScript hard-delete~~ (G1 validated 2026-04-25).

## Revision Status
Revision 3 — applied 15 must-fix and 14 should-fix actions from round-2 peer review (B1–B29). Two prior rounds (round 1: 10+18; round 2: 15+14). Total: 53 review actions applied. SPECIFY artifact frozen at rev 3 pending pre-PLAN gates G2 and G3.

## Scope Classification
**MAJOR** — new external repo, destructive third-party operations, community submission.
