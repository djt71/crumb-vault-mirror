---
project: inbox-processor
domain: software
type: summary
skill_origin: systems-analyst
created: 2026-02-17
updated: 2026-02-17
source_updated: 2026-02-17
tags:
  - inbox-processor
---

# Inbox Processor — Specification Summary

## What
Rewrite the existing `inbox-processor` skill to be spec-compliant. Build the inline attachment protocol (Path A). 13 gaps identified between current skill and spec.

## Key Deliverables
1. **SKILL.md rewrite** — all 9 skill-authoring-conventions sections, all 4 ingestion paths (A-D), correct companion note schema, MarkItDown CLI integration
2. **Path A protocol** — inline attachment protocol for session-generated binaries, defined as a protocol reference (not a standalone skill)

## Critical Schema Requirements
- Companion note type: `attachment-companion` (not `reference`)
- Nested `attachment:` block in frontmatter (not flat fields)
- Colocation: companion note lives in same directory as binary
- Conditional `status`: omit for project-scoped, include for global
- `description` = human synopsis; `summary` = first ~500 chars extraction (text docs only)
- `needs-description` tag for images without meaningful description
- `needs-extraction` tag for extractable docs where MarkItDown fails
- MUST NOT fabricate image descriptions

## MarkItDown Integration
- CLI via bash: `markitdown <filepath>`
- DOCX/PPTX/XLSX: excellent. PDF: adequate (tables lose structure). Images: EXIF only.

## Ingestion Paths
- **A:** Session-generated → direct to project attachments, full context
- **B:** Inbox drop, no context → classify, precedence ladder, route
- **C:** Inbox drop, project known → variant of B with user-specified project
- **D:** Orphan sweep → detect uncompanioned binaries, create companion notes
- **Re-routing:** Move binary + companion from global to project scope, update `source_file` + `project`, remove `status`

## Acceptance Summary
- SKILL.md has all 9 sections, covers all 4 paths
- Companion note schema matches §2.2.1 exactly
- Path A protocol defined and integrated
- At least one real file processed through the skill
