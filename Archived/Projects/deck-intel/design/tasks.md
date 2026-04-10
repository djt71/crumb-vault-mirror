---
type: tasks
project: deck-intel
domain: software
status: active
created: 2026-03-14
updated: 2026-03-14
skill_origin: action-architect
---

# Deck Intel — Tasks

| id | description | state | depends_on | risk_level | type | acceptance_criteria |
|----|------------|-------|-----------|------------|------|-------------------|
| DI-001 | Install PyMuPDF and LibreOffice dependencies | done | — | low | #setup | PyMuPDF importable (`import fitz`); LibreOffice headless converts PPTX to PDF (verified: `libreoffice --headless --convert-to pdf`); both verified on this machine |
| DI-002 | Verify markitdown and diagram-capture composable mode | done | DI-001 | low | #test | markitdown extracts text + speaker notes from a sample PPTX; markitdown extracts text from a sample PDF; output > 200 chars for both; diagram-capture extracts images from sample PPTX (rendered slides via LibreOffice) and sample PDF (embedded images via PyMuPDF); extracted images land in `_attachments/` with expected naming and count |
| DI-003 | Write SKILL.md | done | DI-002 | medium | #code | Skill file follows authoring conventions; procedure implements spec decisions: D1 (`campaign:` as optional YAML list), D2 (4-check deletion gate: extraction + write + images + user confirm), D3 (manual CI linkage via `#kb/` tags), D4 (no source-index notes), D5 (`model_tier: reasoning`), D6 (diagram-capture composable call, images to `_attachments/`, inline embedding, visual-only mode for < 200 chars), D7 (error handling: halt on failure, preserve binary, skip in batch), D8 (MOC one-liner via `kb-to-topic.yaml` with idempotency), D9 (filename `[source_id]-digest.md`), D10 (shelf life free-text section with duration + triggers + signals); context contract specifies budget tiers; batch ceiling 3-5 files documented |
| DI-004 | Verify overlay index coverage | done | — | low | #code | Overlay index reviewed; Business Advisor activation signals cover competitive intel content; Network Skills activation signals cover networking content; overlay index unchanged or minimally updated |
| DI-005 | Validate with real PPTX | done | DI-003 | medium | #test | Use disposable copy of test file; knowledge note passes vault-check; speaker notes captured; noise filtering output shorter than raw markitdown extraction; knowledge note filename follows `[source_id]-digest.md`; frontmatter includes `campaign:` as optional list field; shelf life section has duration + triggers + signals; diagrams extracted to `_attachments/` with `[source_id]-fig[N].[ext]` naming; images embedded inline in note with text descriptions; MOC one-liner placed via `kb-to-topic.yaml` (re-run confirms idempotency — no duplicate); deletion safety gate fires all 4 checks; binary deleted only after gate passes; negative test: intentionally fail one gate check (e.g., skip user confirmation), verify binary preserved |
| DI-006 | Validate with real PDF | done | DI-003 | medium | #test | Use disposable copy of test file; same criteria as DI-005; image-heavy detection (< 200 chars from markitdown) triggers visual-only mode if applicable; error handling tested: markitdown failure preserves binary and user is notified |
| DI-007 | Batch processing validation (3-5 files) | done | DI-005, DI-006 | medium | #test | 5 files (3 PPTX + 2 PDF) processed in one session. Classification summary, per-file deletion gating (4 checks each), batch summary all validated. Skip-on-failure not exercised (no failures). |
| DI-008 | Polish and refinement | done | DI-007 | low | #code | No friction points identified. Noise filtering effective across solution notes, use case decks, product updates, and maturity model. Skill ready for routine use. |
