---
project: notebooklm-pipeline
domain: learning
type: design
created: 2026-02-20
updated: 2026-02-20
tags:
  - notebooklm
  - pipeline
  - implementation-plan
---

# Implementation Plan — NotebookLM Pipeline

## Overview

This plan details the implementation approach for NLM-001 through NLM-007. The project
follows a three-phase knowledge workflow (SPECIFY → PLAN → ACT). This document is the
PLAN phase deliverable. ACT phase executes the tasks below.

**Key constraint:** NLM-003 (template authoring + export verification) requires human-in-the-loop
interaction with NotebookLM. Claude can author templates and design the parser, but the user
must run templates in NLM and export results. This splits the work into Claude-executable
and user-executable segments.

## Path Corrections (Post Vault Restructure)

The spec references `docs/templates/notebooklm/` — the correct path after vault restructure
is `_system/docs/templates/notebooklm/`. All references in this plan use the corrected path.

## Implementation Order

```
NLM-001 (schema)
    │
    ├── NLM-002 (Sources/ directory)
    │
    └── NLM-003 Phase 2 (template authoring) ──── Claude can start
            │
NLM-003 Phase 1 (export verification) ────────── User runs in NLM, exports
            │
    NLM-003 Phase 3 (template validation) ─────── User runs in NLM
            │
    NLM-004 (inbox-processor extension) ────────── Claude implements
            │
    NLM-005 (end-to-end test) ──────────────────── User + Claude
            │
    ├── NLM-006 (documentation)
    └── NLM-007 (template promotion)
```

**Parallelizable:** NLM-001 + NLM-002 can run together. NLM-006 + NLM-007 can run together.
NLM-003 Phase 2 (template authoring) can start immediately after NLM-001 without waiting
for NLM-002.

## Task Details

### NLM-001: Define knowledge-note schema and sentinel contract

**Files to modify:**
- `_system/docs/file-conventions.md` — add `knowledge-note` to type taxonomy table, add
  schema example under a new "Knowledge Notes" section

**Files to create:**
- `_system/docs/templates/notebooklm/sentinel-contract.md` — formal sentinel specification

**Implementation approach:**
1. Add `knowledge-note` row to Type Taxonomy table
2. Add a "Knowledge Notes" section after "Companion Notes" with the full frontmatter schema
   from spec D2 (including `schema_version`, `source` block, `note_type`, `scope`)
3. Document body templates for digest and extract note types
4. vault-check.sh: no changes needed — it validates `type` field exists but doesn't enforce
   a fixed list of allowed types
5. Define the **sentinel contract (v1)** as a standalone document:
   - Exact syntax: `<!-- crumb:nlm-export v=1 template=<name> note_type=<type> source_type=<type> -->`
   - Plain-text fallback: `crumb:nlm-export v=1 template=<name> note_type=<type> source_type=<type>`
   - Placement: within the first 5 lines of the exported file
   - Required fields: `v` (version), `template` (template name with version suffix)
   - Optional fields: `note_type`, `source_type` (can be inferred from template)
   - Parser accepts either HTML comment or plain-text form
   - Must survive NLM export unchanged (or user adds manually for copy-paste path)
6. Define **deterministic source_id algorithm (v1)**:
   - Base: `kebab(author-surname + short-title)` — e.g., `kahneman-thinking-fast`
   - Max length: 60 chars. Allowed chars: `[a-z0-9-]`
   - Collision detection: search `Sources/**/*.md` frontmatter for matching `source.source_id`
     using `grep -r "source_id: <candidate>"` or Obsidian CLI property search
   - Disambiguation sequence: (1) compare `title`/`author` — if different source, append
     `-<publication_year>`; (2) if still collides, append `-<first-4-chars-of-sha256(title)>`
   - Raw fields (`title`, `author`, `canonical_url`) always stored so source_id can be
     regenerated if algorithm changes
7. Define **scope enum**:
   - `whole` — entire source
   - `chapter:<name>` — e.g., `chapter:07`, `chapter:the-anchoring-effect`
   - `section:<id>` — e.g., `section:3.2`
   - `timestamp:<range>` — e.g., `timestamp:00:10:00-00:18:30`
   - `topic:<name>` — e.g., `topic:attention` (for non-linear media)
   - Values are lowercase, no spaces, kebab-case within segments

**Acceptance verification:** Create a test knowledge-note with the schema, run
`./_system/scripts/vault-check.sh`, confirm no errors.

### NLM-002: Create Sources/ directory structure

**Files to create:**
- `Sources/books/.gitkeep`
- `Sources/articles/.gitkeep`
- `Sources/podcasts/.gitkeep`
- `Sources/videos/.gitkeep`
- `Sources/courses/.gitkeep`
- `Sources/papers/.gitkeep`
- `Sources/other/.gitkeep`
- `Sources/sources-overview.md`

**Implementation approach:**
1. Create directory tree with `.gitkeep` files (git doesn't track empty directories)
2. Write `sources-overview.md` with frontmatter (`type: reference`, `domain: learning`,
   `status: active`) and a brief description of the Sources/ structure
3. Update spec §2.1 directory diagram to include Sources/ (or defer to next spec revision)

**Acceptance verification:** `./_system/scripts/vault-check.sh` passes, `sources-overview.md`
has valid frontmatter, all 7 subdirectories exist (`ls Sources/`).

### NLM-003: Query templates + export verification

**Split into Claude-executable and user-executable segments:**

**Phase 2 first (Claude-executable — template authoring):**
- Create `Projects/notebooklm-pipeline/templates/` directory
- Create `Projects/notebooklm-pipeline/fixtures/` directory with `.gitkeep` and
  `README.md` documenting fixture requirements (see below)
- Write 5 versioned templates: `book-digest-v1.md`, `source-digest-v1.md`,
  `concept-extract-v1.md`, `argument-map-v1.md`, `comparison-v1.md`
- Each template includes: the NLM prompt text with sentinel per sentinel contract,
  **expected output structure** (required headings in order, optional headings, list format),
  post-processing notes, version history
- Templates target the body structures defined in spec D2
- **Expected output structure** per template defines the heading map the parser will use:
  - Required headings (exact text, in order) — parser matches these
  - Optional headings (may appear, parser handles gracefully if missing)
  - This heading map is the contract between template output and NLM-004 parser
  - Parser uses hardcoded heading maps per template version (not dynamic template loading)

**Phase 1 (user-executable — export verification):**
- User installs Chrome extension (start with "NotebookLM Ultra Exporter")
- User runs 1-2 templates against real NLM notebooks
- User exports to markdown and drops in `Projects/notebooklm-pipeline/fixtures/`
- **Minimum fixture diversity:** 1 book, 1 article, 1 podcast, 1 video (separate slots),
  1 messy export, 1 short output
- **Fixture definitions:**
  - "Messy export" = malformed markdown tables, broken lists, extra preamble before sentinel
  - "Short output" = <200 words total body content
- **Fixture naming:** `fixture-[source_type]-[template]-[YYYY-MM-DD].md`
  (e.g., `fixture-book-book-digest-v1-2026-02-20.md`)
- Each fixture includes a comment block at top (after sentinel) documenting: source type,
  template used, export method (extension/manual), any known quirks
- Claude documents the exact markdown structure from the exports

**Phase 3 (user + Claude — validation):**
- User runs each template against at least 2 real notebooks, exports results
- Claude compares against expected heading structure from template spec
- **Validation threshold:** a template is validated when the parser can generate correct
  frontmatter and route the file correctly for 2+ separate exports without manual correction
  of the extracted content structure
- Validated exports committed as additional fixtures

**Fallback:** If Chrome extensions don't work, user copies NLM output manually, adds
sentinel at top, saves as `.md`. Same fixture diversity requirements apply.

### NLM-004: Extend inbox-processor for NLM exports

**Files to modify:**
- `.claude/skills/inbox-processor/SKILL.md` — add NLM detection and processing path

**Implementation approach:**
1. Add sentinel detection: scan first 5 lines of incoming `.md` files for sentinel per
   contract (regex tolerant of leading markdown formatting: `^[#\s>*]*<!-- crumb:nlm-export`
   or `^[#\s>*]*crumb:nlm-export`)
2. **Malformed sentinel fallback:** if no sentinel detected but content suggests NLM export
   (contains NLM-style headings like "## Core Thesis", "## Key Arguments", or the string
   "NotebookLM"), prompt user: "This file may be an NLM export missing the sentinel marker.
   Process as [template]? Or route to standard inbox processing?"
3. When detected, branch to NLM processing path:
   a. Parse template version and fields from sentinel
   b. Parse content sections using **hardcoded heading map** for the detected template version
      (heading maps defined in each template's "Expected Output Structure" section)
   c. Generate `source_id` using deterministic algorithm from NLM-001 (kebab slug →
      collision check via `grep -r "source_id:" Sources/` → disambiguate)
   d. Generate full `knowledge-note` frontmatter: `source_id`, `source_type`, `note_type`,
      `scope`, `schema_version: 1`
   e. Prompt user for: source metadata confirmation, domain, `#kb/` tags
   f. Check dedup: existing notes with same `source_id` + `note_type` + `scope`
   g. Apply quality gate: auto-tag `needs_review` for podcast/video/audio
   h. Route to `Sources/[type]/` using **pluralization map**:
      `book→books, article→articles, podcast→podcasts, video→videos, course→courses, paper→papers, other→other`
   i. Suggest connections: search `Sources/` and `Domains/` for notes with overlapping
      `#kb/` tags. Present top 3 matches with >1 tag overlap.
4. Test against golden fixtures from NLM-003

**Key design decisions for implementation:**
- Sentinel detection is deterministic — no heuristic guessing (malformed fallback is user-prompted)
- `source_id` collision detection: grep frontmatter in `Sources/`, not filename glob
- `canonical_url` normalization: strip trailing slashes, ensure `https://` prefix, lowercase domain
- Dedup prompt: "Source already exists as [filename]. Update in-place / Create version / Skip?"

### NLM-005: End-to-end pipeline test

**Protocol:** User processes exports, notifies Claude. Claude reviews generated files in vault.
User available for sync check if discrepancies found.

1. User processes 3-5 real NLM exports through full pipeline
2. Mix of source types (book, article, podcast minimum)
3. **Acceptance checklist** (Claude verifies each):
   - [ ] Sentinel detected and parsed correctly (template + version extracted)
   - [ ] All required frontmatter fields populated (source block, note_type, scope, schema_version)
   - [ ] source_id matches deterministic algorithm output
   - [ ] Routed to correct `Sources/[type]/` directory (pluralization correct)
   - [ ] `needs_review` tagged for podcast/video sources, absent for book/article
   - [ ] `#kb/` tags present and relevant to content domain
   - [ ] Dedup correctly prompts when re-processing same source
   - [ ] `./_system/scripts/vault-check.sh` passes on all generated notes
4. Test copy-paste fallback with at least one export (same checklist)
5. Iterate on templates/processing based on results

### NLM-006: Documentation and workflow guide

**Files to create:**
- `Projects/notebooklm-pipeline/workflow-guide.md` — user-facing guide

**Files to modify:**
- `Domains/Learning/learning-overview.md` — add "Sources & NLM Pipeline" section referencing
  `Sources/` directory and workflow guide

**Content:**
1. Setup: Chrome extension installation, template access
2. Workflow: choose template → copy to NLM → run query → export → drop in _inbox/
3. Batch strategy: digest templates first (1 query/source), extracts by priority,
   ~50 queries/day limit
4. Troubleshooting: extension not working, sentinel missing, dedup conflicts

### NLM-007: Promote templates to durable location

**Files to move:**
- Templates from `Projects/notebooklm-pipeline/templates/` to
  `_system/docs/templates/notebooklm/`

**Files to create:**
- `_system/docs/templates/notebooklm/README.md` — index listing all templates, when to use
  each, link to sentinel contract
- Reference note in `Projects/notebooklm-pipeline/templates/` pointing to promoted location

**Files to modify:**
- Workflow guide paths updated to `_system/docs/templates/notebooklm/`

**No symlinks** — direct move per vault-wide prohibition.

## Execution Batching

**Batch 1 (Claude-executable, no user dependency):**
- NLM-001: schema definition + sentinel contract + source_id algorithm + scope enum
- NLM-002: Sources/ directory
- NLM-003 Phase 2: template authoring + fixtures/ directory with README (after NLM-001)

**Batch 2 (user-dependent):**
- NLM-003 Phase 1: user runs exports, drops fixtures
- NLM-003 Phase 3: user validates templates

**Batch 3 (Claude-executable, depends on fixtures):**
- NLM-004: inbox-processor extension

**Batch 4 (user + Claude):**
- NLM-005: end-to-end testing

**Batch 5 (Claude-executable, post-validation):**
- NLM-006: documentation
- NLM-007: template promotion

## Risk Mitigations

| Risk | Mitigation |
|---|---|
| Chrome extension broken | Copy-paste fallback with manual sentinel — validated in NLM-003 |
| NLM output format changes | Template versioning + version-aware parser |
| source_id collisions | Collision detection + year/hash disambiguation |
| Schema evolution | `schema_version: 1` field for future migration paths |
| Heavy query usage | Batch strategy in workflow guide, ~50/day limit awareness |

## Review Findings Incorporated

**From DeepSeek spec review (R3, 2026-02-20):**
- A1 (should-fix): source_id collision detection added to spec
- A2 (should-fix): schema_version field added to spec
- A3 (should-fix): topic:<name> scope added for non-linear media
- A4 (must-fix): symlink approach replaced with direct move
- A5 (defer): domain summary backlinks — v2 with MOC system
- A6 (defer): batch strategy — in NLM-006 workflow guide
- A7 (defer): URL normalization — in NLM-004 implementation

**From 4-model plan review (R1, 2026-02-20):**
- A1 (must-fix): Sentinel contract defined — exact syntax, required fields, placement
- A2 (must-fix): source_id algorithm specified — deterministic rules, collision detection via frontmatter grep, disambiguation sequence
- A3 (must-fix): Fixture requirements defined — naming convention, diversity criteria, definitions for "messy"/"short", fixtures/README.md
- A4 (should-fix): Per-template parsing approach — hardcoded heading maps, not dynamic
- A5 (should-fix): source_type → directory pluralization map added
- A6 (should-fix): Template validation threshold defined (2+ exports, no manual correction)
- A7 (should-fix): learning-overview.md added to NLM-006 files list
- A8 (should-fix): README.md creation added to NLM-007
- A9 (should-fix): Malformed sentinel fallback behavior added to NLM-004
- A10 (should-fix): Fixture directory creation added to Batch 1
