---
project: batch-book-pipeline
domain: learning
type: plan
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - pipeline
  - batch-processing
---

# Action Plan — Batch Book Pipeline

## Open Questions Resolved

### OQ-1: Batch API + PDF Support → YES
Gemini Batch API accepts File API URIs for PDFs. Confirmed via Google AI docs (ai.google.dev/gemini-api/docs/batch-api). 50% cost discount. Gemini 3.1 Pro supported. Latency: up to 24 hours (no SLA, often faster). Workflow: upload PDF via `files.upload()`, reference file URI in batch JSONL input. SDK confirmed: `client.batches.create()`, `client.batches.get()`, `client.batches.list()`.

**Decision (updated post-BBP-001):** **Batch API is the primary execution path for BBP-006.** Standard API is used only for validation batches (BBP-001/005) where immediate feedback is needed. The 2x token rate increase (560 vs 258 tok/page) makes batch pricing essential for staying within budget. Fire-and-forget overnight processing is ideal for the user's workflow.

### OQ-2: Token Pre-counting → YES, FREE
`countTokens` API works with uploaded PDFs. Free — no billing, 3,000 RPM separate quota. Returns total tokens + modality breakdown.

**BBP-001 validated: PDFs tokenize at 560 tokens/page** (not 258 as initially researched from web sources). Consistent across all 3 test books:
- Augustine (208pp): 116,481 tokens (560/page)
- Attention Merchants (464pp): 259,841 tokens (560/page)
- Brothers Karamazov (707pp): 395,921 tokens (560/page)

**Decision:** Add `countTokens` to pre-flight check in BBP-003. This resolves spec unknowns U1 (exact token counts) and partially validates A2 (books under ~360 pages qualify for ≤200K pricing tier).

**Cost estimate revision:** At 560 tokens/page and actual API pricing ($2/$12 per M standard, $1/$6 per M batch for ≤200K):
- **Standard API:** ~$79 (300pp avg) to ~$191 (400pp avg)
- **Batch API:** ~$40-50 (300pp avg) to ~$80-95 (400pp avg)
- Batch API brings 300pp-avg scenario comfortably within the original $68 budget.

### OQ-3: Fiction Handling → RESOLVED
fiction-digest-v1 added as third template. Manual genre classification — user organizes PDFs into `nonfiction/` and `fiction/` subdirectories under the input directory. Pipeline runs the appropriate digest template per directory. No automated detection needed.

### OQ-4: Source Index Notes → DEFERRED
Post-pipeline follow-up. Not blocking core pipeline.

### OQ-5: Tag Review Workflow → RESOLVED
Non-canonical tags replaced with `needs_review` by script. After full batch: `grep -r "needs_review" Sources/books/` to find notes needing tag correction. Manual review pass as post-BBP-006 cleanup.

## Prerequisites

1. **Python environment:** `_system/scripts/batch-book-pipeline/` with venv, `google-genai`, `pypdf`, `pyyaml`
2. **API key:** Gemini API key in environment variable `GEMINI_API_KEY`
3. **PDF directories:** User organizes PDFs into `nonfiction/` and `fiction/` subdirectories (e.g., `_inbox/bbp-pdfs/nonfiction/`, `_inbox/bbp-pdfs/fiction/`)
4. **SDK:** Use `google-genai` (modern SDK, `google.genai` package), not legacy `google-generativeai`

## Execution Sequence

### BBP-001: Prompt + API Validation

**Goal:** Confirm Gemini 3.1 Pro API produces correct output with book PDFs across all three templates.

**Steps:**
1. Set up Python venv, install `google-genai` and `pypdf`
2. Test books: The Confessions of St Augustine (short, nonfiction), The Attention Merchants (medium, nonfiction), The Brothers Karamazov (long, fiction)
3. Upload each PDF via `client.files.upload()`; wait for ACTIVE state
4. Run `client.models.count_tokens()` on each — record page count, total tokens, validate cost estimate against 258 tokens/page rate
5. Send book-digest-v2 prompt on the 2 nonfiction books via `client.models.generate_content()`
6. Send fiction-digest-v1 prompt on Brothers Karamazov
7. Evaluate output: structural completeness (all template sections present), analytical depth (paragraph arguments for nonfiction; themes/character analysis for fiction), quote quality, concept coverage
8. Compare against NLM-generated digest if available (Crime and Punishment fixture exists for fiction-digest)
9. Also test chapter-digest-v1 prompt on at least 1 book
10. Document: token counts vs page counts, output quality assessment per template, API behavior notes

**Deliverables:** Run-log update with findings, sample outputs in `design/samples/`

**Also validates:** A1 (API quality matches NLM), A2 (token sizes), A4 (PDF quality sufficient), U1 (token counts)

### BBP-002: Template Adaptation

**Goal:** Produce three versioned prompt files ready for the pipeline script.

**Steps:**
1. Copy book-digest-v2 NLM Prompt section as starting point
2. Remove: sentinel markers, NLM-specific language ("NotebookLM", truncation recovery, Chrome extension refs)
3. Add instruction to output a fenced YAML metadata block before the digest body:
   ```
   title, author, year (optional), suggested_tags (from canonical list), suggested_source_id
   ```
4. Embed the full canonical `#kb/` tag list (from `_system/docs/file-conventions.md`) with instruction: "Select 1-3 tags from this list ONLY"
5. Save as `_system/scripts/batch-book-pipeline/prompt-book-digest-v1.md`
6. Repeat for fiction-digest-v1 → `prompt-fiction-digest-v1.md` (source template: `_system/docs/templates/notebooklm/fiction-digest-v1.md`)
7. Repeat for chapter-digest-v1 → `prompt-chapter-digest-v1.md`
8. Test all three adapted prompts against BBP-001's test books — verify metadata block is reliably parseable, suggested tags are from canonical list

**Deliverables:** 3 prompt files in pipeline directory

**Note:** BBP-001 and BBP-002 can partially overlap — BBP-001 uses a rough adaptation to validate API behavior, BBP-002 polishes into the final versioned prompts.

### BBP-003: Pipeline Script

**Goal:** Working Python script with two execution modes: standard (sequential, immediate) and batch (Batch API, fire-and-forget).

**Architecture:**
- Single file: `_system/scripts/batch-book-pipeline/pipeline.py`
- Dependencies: `requirements.txt` → `google-genai`, `pypdf`, `pyyaml`
- Data files (generated at runtime, in script dir): `manifest-{template}.jsonl`, `telemetry-{template}.jsonl`

**CLI interface:**
```
# Standard mode (BBP-005 validation)
python pipeline.py \
  --template book-digest|fiction-digest|chapter-digest \
  --input-dir /path/to/pdfs \
  [--batch-size N] \
  [--resume] \
  [--dry-run]

# Batch API mode (BBP-006 full run)
python pipeline.py \
  --template book-digest|fiction-digest|chapter-digest \
  --input-dir /path/to/pdfs \
  --batch-api submit    # Upload PDFs, build JSONL, create batch job

python pipeline.py \
  --template book-digest|fiction-digest|chapter-digest \
  --batch-api collect   # Download results, parse, write notes
```

**Standard mode implementation (steps 1-16):**

| Step | Function | Notes |
|---|---|---|
| 1 | Arg parsing | `--template` required, validates against known templates (`book-digest`, `fiction-digest`, `chapter-digest`) |
| 2 | PDF scan | Glob `*.pdf` in input dir |
| 3a | Pre-flight: validate | pypdf text extraction test; flag >1500pp or >100MB |
| 3b | Pre-flight: cost estimate | Estimate tokens from page count × 560 tokens/page rate; sum across batch for total cost |
| 4 | Input dedup | SHA-256 hash vs `manifest-{template}.jsonl` |
| 5 | File API upload | `client.files.upload()`, poll until ACTIVE |
| 6 | Generate | `client.models.generate_content()` with template prompt + file |
| 7 | Parse metadata | YAML block extraction → regex fallback → filename fallback |
| 8 | Tag validation | Load canonical list from file-conventions.md, replace non-canonical → `needs_review` |
| 9 | source_id | Deterministic: `kebab(author-surname + short-title)`, truncation heuristic, collision check |
| 10 | Frontmatter | Full knowledge-note schema per spec step 10 |
| 11 | Output dedup | Check `Sources/books/` for existing filename |
| 12 | Write | Knowledge note to `Sources/books/` |
| 13 | Telemetry | Append JSONL record |
| 14 | Batch size | Exit after N books |
| 15 | Resume | Read manifest, skip completed |
| 16 | Rate limiting | Exponential backoff + jitter for 429/5xx, max 3 retries |

**Batch API mode:**
- **Submit:** Runs steps 1-4 (scan, pre-flight, dedup), then uploads all PDFs to File API, builds JSONL request file (one line per book: `{"key": "source_id", "request": {"contents": [{"parts": [{"file_data": {"file_uri": "...", "mime_type": "application/pdf"}}, {"text": "prompt"}]}]}}`), calls `client.batches.create()`, saves batch job name to manifest. Exits — fire-and-forget.
- **Collect:** Reads batch job name from manifest, polls `client.batches.get()` until complete (or accepts `--job-name` directly), downloads results, runs steps 7-13 on each response. Writes all notes + telemetry.
- Files have 48hr TTL / 20GB total storage. One template pass per submission.
- Can cancel mid-job (`client.batches.delete()`) — only charged for completed work.

**`--dry-run` mode:** Runs pre-flight (steps 3a-3b) only — no uploads, no generation. Cost estimate uses the 560 tokens/page rate derived from page counts (no File API upload needed). Fast enough to scan 100 books in seconds.

**Deliverables:** `pipeline.py`, `requirements.txt`

### BBP-004: Tag Strategy

Already resolved in spec. No separate execution step — implemented across BBP-002 (canonical list in prompt) and BBP-003 (validation logic).

### BBP-005: Validation Batch

**Goal:** Process 10 books (mix of fiction and nonfiction) through all templates, user reviews quality.

**Steps:**
1. Select 10 books — diverse subjects, mix of fiction and nonfiction, varied page counts
2. Run `--dry-run` first — verify pre-flight passes, review cost estimate
3. Run `--template book-digest` on nonfiction books → digest notes in Sources/books/
4. Run `--template fiction-digest` on fiction books → digest notes in Sources/books/
5. Run `vault-check` on digest outputs
6. User reviews all digests: structural completeness, analytical depth, tag accuracy, frontmatter correctness, source_id quality
7. Run `--template chapter-digest` on all 10 books
8. Run `vault-check` on all ~20 outputs
9. User reviews chapter-digests
10. Measure tag accuracy: count canonical vs `needs_review` across ~20 notes (target: <20% false)
11. If systematic issues found → revise prompts (bump to v2), re-run affected books

**Deliverables:** ~20 knowledge notes in Sources/books/, quality assessment in run-log

### BBP-006: Full Batch Execution

**Goal:** Process remaining ~90 books through all applicable templates.

**Primary approach: Batch API (fire-and-forget)**
Four batch submissions, each fire-and-forget. Submit before bed or during day work, collect results later. Batch API provides 50% cost discount and handles parallelization/retries on Google's side. Target turnaround <24 hours (often faster).

**Steps:**
1. Run `--dry-run` on all remaining PDFs (both directories) — verify pre-flight, total cost estimate at 560 tok/page rate
2. **Pass 1 — nonfiction digests:** `--template book-digest --input-dir nonfiction/ --batch-api submit`. Collect when done. vault-check. User spot-checks.
3. **Pass 2 — fiction digests:** `--template fiction-digest --input-dir fiction/ --batch-api submit`. Collect. vault-check.
4. **Pass 3 — chapter-digests (nonfiction):** `--template chapter-digest --input-dir nonfiction/ --batch-api submit`. Collect. vault-check.
5. **Pass 4 — chapter-digests (fiction):** `--template chapter-digest --input-dir fiction/ --batch-api submit`. Collect. vault-check.
6. Final telemetry review: total cost, per-book stats, failure/skip counts
7. Post-pipeline: `grep -r "needs_review" Sources/books/` → manual tag review pass

**Constraints:**
- Files have 48hr TTL — upload and submit within the same session per pass
- 20GB total File API storage — fine for ~100 PDFs but monitor if re-uploads needed between passes
- Can cancel mid-job; only charged for completed work

**Fallback:** Standard API with `--resume` if Batch API encounters issues.

**Cost estimate (batch pricing):** ~$40-50 for 300pp avg, ~$80-95 for 400pp avg.

**Deliverables:** ~180 knowledge notes in Sources/books/, telemetry JSONL, run-log summary

## Dependency Graph

```
BBP-001 (API validation)
  │
  ├──► BBP-002 (template adaptation) ──► BBP-003 (pipeline script) ──► BBP-005 (validation)
  │                                        ▲                              │
  │                                        │                              ▼
  └──────────────────────── BBP-004 (tags, resolved) ──────────    BBP-006 (full batch)
```

BBP-001 validates API behavior. BBP-002 produces final prompts (informed by BBP-001 findings). BBP-003 implements the script (needs BBP-002 prompts and BBP-004 tag rules). BBP-005 validates end-to-end. BBP-006 scales.

BBP-001 and BBP-002 can partially overlap since BBP-001 uses a rough prompt adaptation and BBP-002 polishes it.

## Risk Mitigations

| Risk | Mitigation |
|---|---|
| PDF quality varies (scanned, OCR-degraded) | Pre-flight text extraction test; flag and skip |
| File API 48hr expiration | Upload and submit within same session per template pass; re-upload between passes if >48hr gap |
| Model output quality varies by book type | BBP-005 validates diverse subjects; prompt revision if needed |
| Source_id collisions | Deterministic algorithm with year/hash disambiguation + collision check against Sources/ |
| Rate limiting on standard API | Exponential backoff with jitter; configurable max retries |
| Cost overrun | Free `countTokens` pre-flight; `--dry-run` mode; per-book telemetry |
| Prompt revision mid-run | `query_template` versioning in frontmatter; prompt hash in telemetry |
