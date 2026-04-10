---
project: inbox-processor
domain: software
type: specification
skill_origin: systems-analyst
created: 2026-02-17
updated: 2026-02-17
tags:
  - inbox-processor
---

# Inbox Processor — Specification

## 1. Problem Statement

The existing `inbox-processor` skill (`.claude/skills/inbox-processor/SKILL.md`) was written as a placeholder during Phase 1 scaffolding. It predates the binary attachment protocol (§2.5), companion note schema (§2.2.1), MarkItDown validation (§7.9), and skill authoring conventions (`docs/skill-authoring-conventions.md`). A gap analysis identified 13 deficiencies that prevent it from producing spec-compliant output.

The user has project-related documents waiting to be ingested. This is an immediate, practical need.

## 2. Scope

### In Scope
- **Rewrite SKILL.md** to conform to all spec requirements and skill authoring conventions
- **All four ingestion paths** (§2.5): Path A (inline/session-generated), Path B (inbox drop, no context), Path C (inbox drop, project known), Path D (orphan sweep)
- **Path A protocol definition** — the inline attachment protocol that runs during governed sessions when binaries are produced or referenced. This is a protocol (cross-cutting workflow pattern), not a standalone skill.
- **Companion note generation** per §2.2.1 schema (nested `attachment:` block, correct `type`, conditional `status`, `needs-*` tags)
- **MarkItDown CLI integration** per §7.9 (CLI via bash, not MCP)
- **Binary filename conventions** per §2.2.2 (propose renames for non-conforming names)
- **File size gate** per §2.2.3 (flag files >10MB)

### Out of Scope
- vault-check enforcement rules (§7.8) — those are validated separately
- Git LFS migration — separate operational decision
- Vision/OCR enrichment path (§9, future)
- MarkItDown MCP server — validated as unnecessary for serial execution model

## 3. Requirements

### 3.1 Companion Note Schema (from §2.2.1)

Every binary MUST have a colocated companion note named `[filename-without-ext]-companion.md`.

**Frontmatter fields (all required unless noted):**
- `project`: project name or `null`
- `domain`: one of the 8 domains
- `type: attachment-companion` (fixed)
- `skill_origin`: `inbox-processor` | `inline-attachment` | `manual`
- `created`, `updated`: YYYY-MM-DD
- `status`: present ONLY for global companions (`_attachments/`); OMIT for project-scoped
- `tags`: array, includes `needs-description` or `needs-extraction` when applicable
- `attachment.source_file`: vault-relative path to binary
- `attachment.filetype`: extension without dot
- `attachment.source`: `inbox` | `generated` | `external` | `manual`
- `attachment.size_bytes`: integer
- `attachment.description_source`: `null` | `filename-derived` | `user-provided` | `markitdown` | `ocr` | `vision-api`
- `related.task_ids`: optional array
- `related.docs`: optional array
- `description`: short human/AI synopsis (MUST NOT be fabricated from filename for images)
- `summary`: first ~500 chars of MarkItDown output (text-extractable only; absent for images)

**Body structure:**
```
# [Short descriptive title]

**Purpose:** [One sentence]

![[filename.ext]]

## Notes
- [Contextual notes]

## Extracted Content
[Full MarkItDown output — text-extractable documents only]
```

### 3.2 Ingestion Paths (from §2.5)

#### Path A — Inline Attachment (session-generated, project context known)
- Binary produced during governed session → save to `Projects/[project]/attachments/`
- Use §2.2.2 filename convention
- Create companion note with full context (project, domain, task, description all available)
- `attachment.source: generated`
- Log in run-log under `**Files Modified:**`
- Bypasses `_inbox/` entirely

#### Path B — Inbox Drop (no context)
1. Detect file type from extension
2. Classify domain (filename heuristic, then prompt user)
3. Determine project affiliation via precedence ladder:
   1. User-provided override
   2. Filename slug match (project slug in filename)
   3. Active project context (if running during project session)
   4. No match → `project: null`, route to `_attachments/[domain]/`
4. Route binary to appropriate attachments directory
5. For text-extractable: run `markitdown <filepath>`, write summary to frontmatter, full extraction to body
6. For images: extract EXIF via markitdown, tag `needs-description` if no meaningful description
7. Propose filename rename per §2.2.2 if non-conforming
8. Tag `needs-extraction` if markitdown fails on extractable document

#### Path C — Inbox Drop (project known)
- Variant of Path B where user specifies project (precedence step 1)
- Route to `Projects/[project]/attachments/`
- Populate `related.task_ids` if provided

#### Path D — Orphan Sweep
- Detect binaries in any `attachments/` directory without a companion note
- Create companion note with `attachment.source: manual` and `needs-description` tag
- Propose filename rename per §2.2.2

#### Re-routing (project affiliation discovered after initial processing)
When a binary initially processed to `_attachments/[domain]/` is later identified as belonging to a project:
1. Move the binary from `_attachments/[domain]/` to `Projects/[project]/attachments/`
2. Move the companion note alongside it
3. Update the companion note's `attachment.source_file` path and `project` field
4. Remove `status` field (project-scoped companions omit it)
5. Operation must be atomic — move both files and update the path in one step (vault-check catches broken `source_file` references)

### 3.3 MarkItDown Integration (from §7.9)

- **CLI invocation:** `markitdown <filepath>` via Bash tool
- **Output:** stdout markdown content
- **PDF:** text accurate, tables lose structure (flat text)
- **DOCX:** excellent conversion
- **PPTX:** excellent (slide numbers as comments, titles as headings)
- **XLSX:** excellent (multi-sheet, proper tables)
- **Images (PNG/JPG):** EXIF metadata only — NO OCR, NO content understanding. Requires `exiftool` (Homebrew) as a backend dependency for EXIF extraction.
- **MUST NOT** fabricate image descriptions from filenames/metadata
- **Backend flexibility:** skill MAY swap extraction backend per file type without spec changes
- **Prerequisites:** `markitdown` (via pipx) and `exiftool` (via Homebrew) must be installed. Skill procedure should verify availability or reference the dependency.

### 3.4 Skill Structure (from skill-authoring-conventions.md)

The rewritten SKILL.md must include all required sections:
1. YAML frontmatter
2. Identity and Purpose
3. When to Use This Skill
4. Procedure
5. Context Contract
6. Output Constraints (companion note schema as canonical reference)
7. Output Quality Checklist
8. Compound Behavior
9. Convergence Dimensions

### 3.5 File Size Gate (from §2.2.3)

- Flag files exceeding 10MB soft threshold
- User confirms before storing, or considers compression/external storage
- Not a hard block — vault-check reports as warning

### 3.6 Binary Filename Conventions (from §2.2.2)

Propose conforming renames for non-conforming names:
- Screenshots: `screenshot-[project]-[task]-[slug]-YYYYMMDD-HHMM.[ext]`
- Diagrams: `diagram-[project]-[slug]-v[NN].[ext]`
- Inbound: `inbound-[source]-[slug]-YYYYMMDD.[ext]`
- Exports: `export-[project]-[slug]-YYYYMMDD.[ext]`
- Personal: `[descriptive-slug]-YYYYMMDD.[ext]`

## 4. Acceptance Criteria

### Skill File
- [ ] SKILL.md follows skill-authoring-conventions.md section order
- [ ] All 9 required sections present
- [ ] Procedure covers all 4 ingestion paths
- [ ] Companion note schema in Output Constraints matches §2.2.1 exactly
- [ ] MarkItDown CLI invocation specified correctly
- [ ] Project affiliation precedence ladder implemented
- [ ] `needs-description` and `needs-extraction` tag logic specified
- [ ] File size gate (10MB) included
- [ ] Filename rename proposal logic included
- [ ] Colocation enforced (companion note in same directory as binary)
- [ ] Conditional `status` field logic correct (omit for project-scoped)
- [ ] Image handling explicitly blocks fabricated descriptions
- [ ] `description` vs `summary` semantics correct
- [ ] Path D orphan sweep procedure defined
- [ ] Crash resilience: companion note written before binary moved

### Path A Protocol
- [ ] Inline attachment protocol defined as a protocol (not a skill)
- [ ] Integrated into CLAUDE.md or referenced protocol file
- [ ] Bypasses inbox, uses session context for full companion note population
- [ ] Logs attachment in run-log

### Validation
- [ ] Process at least one real file through the rewritten skill
- [ ] Companion note passes vault-check frontmatter validation
- [ ] MarkItDown extraction produces expected output for at least one document type
- [ ] Frontmatter `summary` is truncated to first ~500 chars; full extraction lives in `## Extracted Content` body section (not in frontmatter)
- [ ] Re-routing protocol correctly updates `source_file`, `project`, and removes `status` when moving from global to project scope

## 5. Assumptions and Constraints

**Assumptions:**
- MarkItDown v0.1.4 installed and functional (validated in 25c session)
- `exiftool` installed via Homebrew (validated in 25c session)
- `_inbox/` directory exists at vault root
- `.gitignore` excludes binary extensions (validated in 25d session)

**Constraints:**
- Single-file skill rewrite — no new primitives beyond the Path A protocol
- Path A protocol is a protocol (CLAUDE.md or reference doc), not a standalone skill
- No changes to vault-check rules in this project
- The skill itself doesn't need tests — it's a prompt document, not code
