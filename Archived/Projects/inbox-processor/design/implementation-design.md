---
project: inbox-processor
domain: software
type: design
skill_origin: null
created: 2026-02-17
updated: 2026-02-17
tags:
  - inbox-processor
---

# Inbox Processor — Implementation Design

## 1. Deliverables

Two artifacts, built in order:

1. **SKILL.md rewrite** (`.claude/skills/inbox-processor/SKILL.md`) — the primary deliverable
2. **Path A protocol** — inline attachment protocol, added to CLAUDE.md as a protocol section

## 2. SKILL.md Structure

Follows `docs/skill-authoring-conventions.md` section order:

```
---
YAML frontmatter (routing description)
---

# Inbox Processor

## Identity and Purpose
## When to Use This Skill
## Procedure
  ### 1. Check Prerequisites
  ### 2. Scan and Classify
  ### 3. Batch User Prompting
  ### 4. Process Markdown Files
  ### 5. Process Binary Files
  ### 6. Orphan Sweep (Path D) — detect + companion creation
  ### 7. Verify and Report
  ### 8. Compound Check
## Context Contract
## Output Constraints
## Output Quality Checklist
## Compound Behavior
## Convergence Dimensions
```

## 3. Key Design Decisions

### 3.1 Procedure Organization

The procedure handles Paths B, C, and D (the inbox-processor's responsibility). Path A is a separate protocol — the inbox-processor skill never runs for Path A.

Steps 2-5 handle Paths B and C together (C is just B with a user-provided project). Step 6 handles Path D as a distinct sweep.

**Project affiliation precedence ladder** (used in Step 3, applies to Paths B and C):

| Priority | Source | Example |
|---|---|---|
| 1 | User-provided override | User says "these go in acme-migration" |
| 2 | Filename slug match | `screenshot-acme-migration-...` contains project slug |
| 3 | Active project context | A project's `project-state.yaml` is loaded in the current session |
| 4 | No match | `project: null`, route to `_attachments/[domain]/` |

First match wins. Step 3 walks the ladder top-down and stops at the first hit.

**Domain inference ladder** (used in Step 3, separate from project affiliation):

| Priority | Source | Example |
|---|---|---|
| 1 | User-provided override | User says "these are career docs" |
| 2 | Project's `project-state.yaml` domain | If project affiliation resolved, read domain from project config |
| 3 | Filename heuristics | `inbound-acme-corp-dns-...` → software |
| 4 | Last-used domain in batch | Carry forward from earlier files in same batch |
| 5 | Prompt user | Ask explicitly |

**Filename rename proposal** (substep within Step 5):
After determining project/domain, compare the current filename against §2.2.2 conventions. If non-conforming, propose a rename with the conforming name. User accepts or overrides. Never auto-rename — always propose.

**10MB file size gate** (substep within Step 5):
Before moving, check file size. If >10MB, flag to user: "This file is [X]MB. Confirm you want to store it, or consider compressing or linking to external storage." Do not proceed until user confirms.

### 3.2 Companion Note Generation

The skill produces companion notes directly using the Write tool. The Output Constraints section embeds the **full companion note schema verbatim** from §2.2.1 as the canonical template — the single source of truth within the skill.

One schema, two rendering variants:
- **Text-extractable** (PDF, DOCX, PPTX, XLSX): `summary` populated with first ~500 chars of extraction, `## Extracted Content` section present in body, `description_source: markitdown`
- **Image** (PNG, JPG, GIF, WEBP, SVG): `summary` absent, `## Extracted Content` absent, `needs-description` tag added, `description_source: null` (until user provides description)

Both variants use the same frontmatter schema — the difference is which conditional fields are populated vs absent. The schema in Output Constraints marks each field's applicability.

### 3.3 MarkItDown Integration

Invocation pattern:
```bash
markitdown <filepath>
```

Output captured from stdout. For summary truncation: take first ~500 characters of the output for the frontmatter `summary` field. Full output goes in `## Extracted Content`.

If markitdown fails (non-zero exit, empty output): tag `needs-extraction`, write companion note without extraction, continue processing.

**Image handling:** For images, still run `markitdown <filepath>` — it returns EXIF metadata (dimensions, dates, GPS, camera info via `exiftool`). Place the EXIF output in the companion note's `## Notes` section (not `## Extracted Content`, which is absent for images). Set `description_source: null` — EXIF metadata is not a content description. The `description_source` stays `null` unless the user provides a description (then set to `user-provided`).

### 3.4 Crash Resilience

Order of operations for binary processing:
1. Run markitdown extraction (if applicable) — file still in `_inbox/`
2. Write companion note to destination directory
3. Move (rename) binary to destination directory
4. Verify both files exist at destination

If the process crashes between steps 2 and 3, the companion note exists with a `source_file` pointing to the destination, but the binary is still in `_inbox/`. On the next inbox run: if a companion note already exists at the destination with `source_file` pointing to the destination path, complete the interrupted move (`mv` the binary from `_inbox/` to destination). Do not reprocess — the companion note is already correct.

### 3.5 Path A Protocol Location

Path A is a protocol (cross-cutting workflow pattern) defined in CLAUDE.md. It doesn't belong in the inbox-processor skill because:
- It runs during governed sessions, not inbox processing
- The session already has full context (project, task, domain)
- The inbox-processor skill is invoked by user trigger phrases; Path A is invoked by any skill/orchestrator producing a binary

The protocol will be added as a new section in CLAUDE.md under Behavioral Boundaries or as a referenced protocol file at `docs/protocols/inline-attachment-protocol.md`.

**Recommendation:** Reference file at `docs/protocols/inline-attachment-protocol.md` to keep CLAUDE.md lean. CLAUDE.md gets a brief mention under Behavioral Boundaries pointing to the protocol file.

### 3.6 Re-routing (atomic operation)

Re-routing is a correction procedure invoked when project affiliation is discovered after initial processing. It is atomic — all steps execute as one operation with a post-condition check:

1. Move binary from `_attachments/[domain]/` to `Projects/[project]/attachments/`
2. Move companion note alongside it
3. Update companion note `attachment.source_file` to new vault-relative path
4. Update `project` field from `null` to project name
5. Remove `status` field (project-scoped companions omit it per §4.1.6)
6. **Post-condition check:** verify binary exists at new path, companion note exists at new path, `source_file` in frontmatter matches binary's new vault-relative path, `status` field is absent

If any post-condition fails, report the failure and do not delete the source files — leave both copies for manual resolution.

### 3.7 Path D — Orphan Sweep (full specification)

**Definition:** An "orphan" is a binary file in any attachment directory that has no colocated companion note (no `[filename-without-ext]-companion.md` in the same directory).

**Scope:** ALL attachment directories — both global (`_attachments/*/`) and project-scoped (`Projects/*/attachments/`). Path D is not limited to global directories.

**Detection logic:**
1. Glob for binary files (extensions: pdf, docx, pptx, xlsx, png, jpg, jpeg, gif, webp, svg) in `_attachments/**/` and `Projects/*/attachments/`
2. For each binary, check if `[filename-without-ext]-companion.md` exists in the same directory
3. If no companion note → orphan

**Companion creation for orphans:**
- `attachment.source: manual` (the binary was placed directly, not via inbox or session)
- `needs-description` tag always added (no context available for a meaningful description)
- `description_source: null`
- `project`: inferred from directory path (if under `Projects/[name]/attachments/`, set to project name; if under `_attachments/[domain]/`, set to `null`)
- `domain`: inferred from directory path (global: subdirectory name; project: from `project-state.yaml`). Fallback if `project-state.yaml` missing: set `domain: null` + `needs-domain` tag.
- For text-extractable orphans: run markitdown, populate `summary` and `## Extracted Content`
- For image orphans: run markitdown for EXIF, place in `## Notes`
- Propose filename rename per §2.2.2

**This covers the inverse crash case** (finding 7): if a binary was moved to the destination but the process crashed before the companion note was written, Path D detects the orphan binary and creates the companion note. Combined with §3.4's forward case (companion exists but binary still in `_inbox/`), both crash recovery scenarios are handled.

## 4. File Change Footprint

| File | Action |
|---|---|
| `.claude/skills/inbox-processor/SKILL.md` | Rewrite (primary deliverable) |
| `docs/protocols/inline-attachment-protocol.md` | Create (Path A protocol) |
| `CLAUDE.md` | Edit (add Path A protocol reference under Behavioral Boundaries) |

## 5. Dependencies and Prerequisites

- `markitdown` CLI available (validated 25c)
- `exiftool` available (validated 25c)
- `_inbox/` directory exists at vault root
- `.gitignore` excludes binary extensions (validated 25d)
- `docs/protocols/` directory may need creation

## 6. Risks

- **vault-check frontmatter validation:** Current rules expect `status` on all docs — project-scoped companion notes omit it. This is a pre-existing vault-check gap, not introduced by this project.
- **MarkItDown output variability:** Different versions may produce different output. The skill is pinned to CLI behavior validated in 25c (v0.1.4).
