---
type: action-plan
project: deck-intel
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
skill_origin: action-architect
---

# Deck Intel — Action Plan

## M1: Skill Build + Dependencies

Build the SKILL.md and ensure all runtime dependencies are in place.

**Success criteria:**
- SKILL.md written, follows authoring conventions, incorporates all spec decisions (D1-D10)
- markitdown verified working for PPTX and PDF extraction
- PyMuPDF installed for PDF image extraction
- LibreOffice installed for PPTX rendered-slide extraction
- Overlay index verified (no changes expected)

### Phase 1a: Dependency Setup

Install PyMuPDF and LibreOffice. Verify markitdown handles PPTX speaker notes and PDF text. Verify diagram-capture composable mode works end-to-end (PPTX rendered slides + PDF embedded images → `_attachments/`). These are prerequisites for both text extraction and image preservation.

### Phase 1b: SKILL.md Build

Write the skill file incorporating all spec decisions. Key procedure elements:
1. Classification step (present file summary before extraction)
2. markitdown text extraction
3. diagram-capture composable call for image extraction
4. Synthesis with noise filtering
5. Knowledge note output with frontmatter, body structure, shelf life
6. Image embedding from `_attachments/`
7. MOC one-liner placement with idempotency
8. Deletion safety gate (4-check: extraction + write + images + user confirmation)
9. Batch mode with per-file processing and skip-on-failure

### Phase 1c: Overlay Verification

Confirm existing overlay activation signals cover deck-intel use cases. No new overlay expected.

## M2: Validation — Single File

Validate the skill against real files, one at a time.

**Success criteria:**
- PPTX processed end-to-end: text extraction, image preservation, knowledge note, MOC, binary deletion
- PDF processed end-to-end: same criteria plus image-heavy fallback tested
- All knowledge notes pass vault-check
- Deletion safety gate fires correctly (including image preservation check)

### Phase 2a: PPTX Validation

Process a disposable copy of a real vendor PPTX (Infoblox competitive deck or similar). Validate speaker notes, diagram extraction, noise filtering quality, shelf life section, MOC routing, filename convention, campaign field. Test deletion safety gate happy path AND negative path (intentionally fail a check, verify binary preserved).

### Phase 2b: PDF Validation

Process a disposable copy of a real PDF. Validate same criteria. If PDF is image-heavy (< 200 chars from markitdown), verify visual-only mode triggers correctly. Test error handling path (markitdown failure preserves binary).

## M3: Validation — Batch + Polish

Validate batch processing and refine based on M2 findings.

**Success criteria:**
- 2-3 files processed in a single session without context degradation
- Classification summary presented before extraction
- Cross-references noted when sources overlap
- Error handling tested: at least one failure path exercised
- Skill ready for routine use

### Phase 3a: Batch Processing

Process 3-5 mixed files (PPTX + PDF) in one session using disposable copies. Verify context management at ceiling (5 files), per-file deletion gating, batch summary, skip-on-failure behavior.

### Phase 3b: Polish

Address any friction or quality issues found in M2/M3a. Refine noise filtering rules, body structure, or shelf life format based on real extraction experience.
