---
project: deck-intel
domain: software
type: summary
skill_origin: systems-analyst
status: active
created: 2026-03-03
updated: 2026-03-03
source_updated: 2026-03-14
tags:
  - summary
  - deck-intel
---

# Deck Intel — Specification Summary

**Parent document:** specification.md
**Last updated:** 2026-03-03

## Core Content

A Crumb skill that extracts structured, actionable intelligence from PPTX and PDF files (vendor presentations, sales enablement, competitive intel, analyst reports). Uses markitdown for text extraction (including speaker notes), applies aggressive noise filtering, and produces knowledge notes tagged for retrieval during customer engagement and campaign work. Source binaries are deleted after synthesis — the knowledge note is the sole durable artifact.

## Key Decisions

- Campaign tracking via optional `campaign:` frontmatter list field (supports multi-campaign tagging)
- Synthesis only — no companion notes or source-index notes. Source file deleted after passing safety gate (extraction check + write check + image preservation check + user confirmation). Substantive diagrams/images preserved to `_attachments/` and embedded inline in the knowledge note with text descriptions
- Extraction error handling: if markitdown fails, halt that file, preserve binary, notify user. Batch mode: skip and continue.
- Manual CI linkage via shared `#kb/` tags — no automatic cross-referencing to customer-intelligence dossiers
- `model_tier: reasoning` — synthesis requires judgment (noise filtering, competitive signal identification, shelf life assessment)
- Diagram/image preservation: diagram-capture extracts images to `_attachments/`, no Mermaid recreation — preserved image is the artifact. Image-heavy PDFs (< 200 chars from markitdown) trigger visual-only mode
- MOC one-liner placement with idempotency check, following existing source-index pattern
- Knowledge note filename: `[source_id]-digest.md` per §2.2.4 algorithm
- Shelf Life: free-text body section with duration estimate, recheck triggers, expiration signals
- Batch ceiling: 3-5 files per session to manage context pressure

## Interfaces/Dependencies

- **Inputs:** PPTX/PDF files in `_inbox/`, markitdown CLI
- **Outputs:** Knowledge notes in `Sources/other/`, MOC one-liners via `kb-to-topic.yaml`
- **Downstream:** Customer-intelligence dossiers, campaign prep queries via `#kb/` tags
- **Parallel systems:** Inbox-processor (catalog/route) vs. deck-intel (synthesize/discard) — complementary, not competing

## Acceptance Status

- [ ] Dependencies installed (DI-001)
- [ ] markitdown + diagram-capture verified (DI-002)
- [ ] SKILL.md written (DI-003)
- [ ] Overlay index verified (DI-004)
- [ ] Validated with real PPTX (DI-005)
- [ ] Validated with real PDF (DI-006)
- [ ] Batch processing tested (DI-007)
- [ ] Polish complete (DI-008)

## Next Actions

- Approve specification, advance to PLAN phase
- PLAN phase: finalize knowledge note body structure (Q1) and skill procedure details
