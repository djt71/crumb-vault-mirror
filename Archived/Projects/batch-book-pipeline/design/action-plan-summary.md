---
project: batch-book-pipeline
domain: learning
type: summary
source_updated: 2026-02-28
created: 2026-02-28
updated: 2026-02-28
tags:
  - pipeline
  - batch-processing
---

# Action Plan Summary — Batch Book Pipeline

## Open Questions Resolved

- **Batch API + PDF:** YES — File API URIs work in batch JSONL. 50% discount. **Batch API is the primary execution path for BBP-006** — fire-and-forget overnight processing.
- **Token pre-counting:** YES, FREE — `countTokens` works with PDFs. **BBP-001 validated: 560 tokens/page** (not 258 as initially researched). Consistent across 3 test books.
- **Cost revised:** ~$79 standard, **~$40-50 batch** (300pp avg). Batch API brings cost within original $68 budget.
- **Fiction handling:** RESOLVED — fiction-digest-v1 added as third template. Manual genre classification via subdirectories (`nonfiction/`, `fiction/`). No automated detection.
- **Source index notes:** Deferred. **Tag review:** `needs_review` grep after completion.

## BBP-001 Validation Results

All three templates validated on 3 test books (5 generation calls, ~$4.15 actual cost):
- **book-digest:** 2 nonfiction books — structurally complete, paragraph-level arguments, 10-11 quotes
- **fiction-digest:** Brothers Karamazov — themes/character analysis, 8 quotes w/ page refs
- **chapter-digest:** Augustine (13 Books) + Attention Merchants (29 chapters) — full per-chapter breakdown with synthesis sections
- **Token rate:** 560 tok/page (exactly consistent across 208pp, 464pp, 707pp books)
- **Generation time:** 2-3 min per call

## Execution Sequence

1. **BBP-001 (API validation):** DONE — 3 test books, 5 generation calls, all templates validated.
2. **BBP-002 (template adaptation):** Adapt all three templates — strip NLM artifacts, add YAML metadata block, embed canonical tag list. Version as v1.
3. **BBP-003 (pipeline script):** Two modes — standard (sequential, for validation) and batch (`--batch-api submit`/`collect`, for full run). Pre-flight, dedup, parse, frontmatter, vault-check compliance.
4. **BBP-004 (tag strategy):** Already resolved — implemented in BBP-002 (prompt) and BBP-003 (validation).
5. **BBP-005 (validation batch):** 10 books via standard API — immediate feedback, user reviews quality.
6. **BBP-006 (full batch):** Remaining ~90 books via **Batch API**. Four fire-and-forget submissions (nonfiction digests, fiction digests, nonfiction chapters, fiction chapters). Submit before bed, collect next morning.

## Key Technical Decisions

- **SDK:** `google-genai` (modern), not legacy `google-generativeai`
- **Model:** Gemini 3.1 Pro (`gemini-3.1-pro-preview`) — same model NLM uses, quality validated
- **Three templates:** book-digest (nonfiction), fiction-digest (fiction), chapter-digest (all books)
- **Genre classification:** Manual — user sorts PDFs into `nonfiction/` and `fiction/` subdirectories
- **Primary API path:** Batch API for full runs (50% discount, fire-and-forget overnight)
- **Standard API:** Reserved for validation batches (BBP-005) where immediate feedback needed
- **Pre-flight:** pypdf text check + oversize flag (>1500pp / >100MB) + page-count-based cost estimate (560 tokens/page)
- **Dry-run mode:** Pre-flight only — estimates cost from page counts, no File API uploads or generation calls
