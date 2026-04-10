---
project: batch-book-pipeline
domain: learning
type: specification
skill_origin: systems-analyst
status: active
created: 2026-02-28
updated: 2026-02-28
tags:
  - knowledge-management
  - batch-processing
  - gemini
  - pipeline
---

# Specification — Batch Book Pipeline

## Problem Statement

~100 books (PDFs, locally available) need to be processed into structured knowledge notes using **three templates**: book-digest-v2 (nonfiction whole-book digest), fiction-digest-v1 (fiction whole-book digest), and chapter-digest-v1 (chapter-by-chapter breakdown). Each book receives two outputs: the appropriate digest template (fiction or nonfiction) plus a chapter-digest. Genre classification is manual — the user organizes PDFs into fiction/nonfiction directories before running the pipeline. The existing NLM pipeline requires manual one-at-a-time interaction with NotebookLM — no batch processing capability exists. The human-in-the-loop NLM interaction is the bottleneck; the downstream processing (knowledge-note schema, Sources/ routing, vault integration) is already solved.

## Why This Matters

The vault's knowledge graph is starved of source material. ~100 books represent years of reading with no structured capture. Every day without this pipeline is another day these books contribute nothing to cross-domain insight, project context, or retrieval. The NLM pipeline proved the output format works — this project removes the intake bottleneck.

## Facts vs Assumptions

### Facts
- F1: The book-digest-v2 template produces high-quality structured output when run through NLM (Gemini-backed). Validated across 12 fixtures.
- F2: NLM has no batch API. Export is manual (Chrome extension or copy-paste).
- F3: The knowledge-note schema, source_id algorithm, Sources/ routing, and frontmatter structure are all defined and validated (`_system/docs/file-conventions.md`).
- F4: All three prompts (book-digest-v2, fiction-digest-v1, chapter-digest-v1) are model-agnostic — structured prompts, not NLM-specific.
- F5: Gemini API supports native PDF upload (File API → generate_content). 1M token context window handles any book.
- F6: The user has API keys available and the PDFs on local disk.
- F7: NLM currently runs Gemini 3.1 Pro (upgraded from Gemini 3 in Feb 2026, from 2.5 Flash before that). The NLM quality baseline was set by a Gemini 3.x model.
- F8: Gemini 3 Flash and 3.1 Pro are available via the API. Gemini 3.1 Pro has no free API tier but can be tried in AI Studio.

### Assumptions
- A1: Gemini 3.1 Pro produces equivalent quality when called directly via API as when accessed through NLM. **Validated in BBP-001 — all three templates produce structurally complete, analytically deep output. Quality meets or exceeds NLM baseline.**
- A2: Most books are under 200K tokens (~150,000 words), qualifying for the cheaper Gemini Pro pricing tier. **Partially validated — PDFs tokenize at 560 tokens/page (not 258 as initially researched). A 300-page book = ~168K tokens (under 200K). A 360+ page book exceeds 200K. The actual split depends on the library's page distribution.**
- A3: The book-digest-v2 prompt works without modification when sentinels are removed and NLM-specific language is stripped. **Validate in BBP-002.**
- A4: PDF quality is sufficient for Gemini's document understanding (not scanned/OCR-degraded). **Validate by pre-flight check (pypdf text extraction test) + spot-check.**

### Unknowns (resolved)
- U1: ~~Exact token counts per book~~ → **Resolved in BBP-001.** 560 tokens/page. 300-page book = ~168K tokens (≤200K tier). 360+ page book exceeds 200K tier. Exact library distribution TBD via `--dry-run` on full collection.
- U2: ~~Whether Gemini Batch API supports file inputs~~ → **Resolved in PLAN phase.** File API URIs accepted in batch JSONL. SDK confirmed: `client.batches.create()` with JSONL referencing uploaded file URIs.
- U3: Free tier daily token limits → **Moot.** Free tier not available for Gemini 3.1 Pro. Batch API pricing is the cost lever.

## System Map

### Components

```
[PDF Directory]           Source: ~100 local PDF files
       │
       ▼
[Pre-flight Check]        pypdf: verify text extractable, flag scanned/corrupt
       │
       ▼
[Manifest Check]          JSONL manifest: skip already-processed (by file hash)
       │
       ▼
[Pipeline Script]         Python — orchestrates the full flow
       │
       ├──► [Gemini File API]     Upload PDF, get file URI
       │
       ├──► [Gemini Generate]     Send file URI + selected template prompt
       │
       ├──► [Metadata Parser]     Extract structured metadata block (YAML)
       │                          + digest body from response
       │
       ├──► [Metadata Generator]  source_id, frontmatter, filename, tags
       │
       ├──► [Dedup Check]         source_id against existing Sources/books/
       │
       ├──► [File Writer]         Write knowledge note to Sources/books/
       │                          ({title}-digest.md or {title}-chapter-digest.md)
       │
       └──► [Telemetry Logger]    Per-book JSONL: hash, tokens, cost, status
              │
              ▼
       [Sources/books/]           Vault knowledge notes
```

### Dependencies
- **Upstream:** Local PDF files, Gemini API (`google-genai` SDK, `google.genai` package), API key
- **Internal:** knowledge-note schema (`file-conventions.md`), canonical `#kb/` tag list, existing Sources/ directory, book-digest-v2 template, fiction-digest-v1 template, chapter-digest-v1 template
- **Downstream:** vault knowledge graph, `#kb/` tag network, domain MOCs, vault-check validation

### External Code Repo
Not needed. The script is vault tooling — lives in `_system/scripts/batch-book-pipeline/` with its own `requirements.txt` and virtual environment.

### Constraints
- C1: Cost — quality-assured at reasonable cost. Gemini 3.1 Pro selected for guaranteed NLM-equivalent quality. Batch API (50% discount) is the primary execution path for BBP-006, bringing estimated cost to ~$40-50 for 300pp avg books. Standard API used only for validation batches (BBP-001/005) where immediate feedback is needed.
- C2: Quality — output must match NLM baseline. Validated via side-by-side comparison.
- C3: Vault compliance — every output must pass vault-check (frontmatter, `#kb/` tags, file naming).
- C4: Batched review — user reviews output quality between batches before continuing.
- C5: No sentinel markers — direct API output doesn't need NLM sentinel detection. Notes are written directly with proper frontmatter.

### Levers
- **Model selection** — Flash vs Pro trades cost for quality. Flash batch is 20x cheaper than Pro standard.
- **Batch API** — 50% cost reduction for async processing. **Primary path for BBP-006** — fire-and-forget overnight runs. Submit mode uploads PDFs + builds JSONL + creates batch job; collect mode downloads results + parses + writes notes.
- **Free tier** — Could cover the validation batch (10 books) at $0 cost.
- **Template simplification** — Removing NLM-specific instructions (sentinel, truncation recovery) may improve output quality by reducing prompt noise.

### Output File Naming Convention

Each book produces **two output files** in `Sources/books/`, using the same `source_id`-based naming convention as the inbox-processor's NLM Export Path. This ensures naming consistency between manually-processed NLM exports and batch-processed API outputs.

**Filename format:** `[source_id]-[note_type].md`
- book-digest-v2 (nonfiction) → `[source_id]-digest.md`
- fiction-digest-v1 (fiction) → `[source_id]-digest.md`
- chapter-digest-v1 → `[source_id]-chapter-digest.md`

Both digest templates produce the same output filename (`-digest.md`) since a book receives one or the other, never both. The `source.query_template` frontmatter field distinguishes which template generated the note.

**Genre classification:** Manual. The user organizes PDFs into separate directories (e.g., `nonfiction/`, `fiction/`) and runs the appropriate `--template` on each. No automated detection.

**`source_id` algorithm** (per `_system/docs/file-conventions.md`):
1. `kebab(author-surname + short-title)` — max 60 chars, `[a-z0-9-]` only
2. Collision check: search `Sources/` for existing notes with the candidate `source_id`
3. If collision with different source: append `-<publication_year>`
4. If still collides: append `-<first-4-chars-of-sha256(title)>`

The script computes `source_id` deterministically from the model-extracted author and title. The model's `suggested_source_id` in the metadata block is a hint, not authoritative — the script applies the algorithm above. If title/author extraction fails, fall back to the PDF filename (sanitized).

**Examples:**

| Book Title | Author | source_id | book-digest output | chapter-digest output |
|---|---|---|---|---|
| Franklin D. Roosevelt and the New Deal | Leuchtenburg | `leuchtenburg-franklin-d-roosevelt` | `leuchtenburg-franklin-d-roosevelt-digest.md` | `leuchtenburg-franklin-d-roosevelt-chapter-digest.md` |
| Thinking, Fast and Slow | Kahneman | `kahneman-thinking-fast-and-slow` | `kahneman-thinking-fast-and-slow-digest.md` | `kahneman-thinking-fast-and-slow-chapter-digest.md` |
| The Wealth of Nations | Smith | `smith-wealth-of-nations` | `smith-wealth-of-nations-digest.md` | `smith-wealth-of-nations-chapter-digest.md` |
| Sapiens: A Brief History of Humankind | Harari | `harari-sapiens` | `harari-sapiens-digest.md` | `harari-sapiens-chapter-digest.md` |

Both output files for a given book share the same `source_id`. This means an NLM-processed digest and a batch-processed digest for the same book will have matching filenames — the output dedup check catches this.

### Oversize Handling

Gemini 3.1 Pro's 1M token context handles ~750,000 words — larger than any standard published book. For rare edge cases (multi-volume reference works, image-heavy PDFs with high token cost):
- The pre-flight check flags PDFs with unusually high page counts (>1,500 pages) or file sizes (>100MB)
- Flagged books are logged as "manual review" in the manifest and skipped
- No automated chunking pipeline — handle individually if needed

### Second-Order Effects
- Source index notes (`[source_id]-index.md`) are not generated by this pipeline — they can be created later manually or via a follow-up automation.
- MOC updates will be needed after bulk intake to reflect new Sources/ content.
- The `#kb/` tag graph will expand significantly — may surface gaps in the canonical tag list.
- This pipeline could be reused for non-book sources (articles, papers) with template swaps.

## Model Evaluation

**Important context:** NLM currently runs Gemini 3.1 Pro (upgraded Feb 2026). The quality baseline we're matching was set by a Gemini 3.x model, not 2.5.

### Gemini 3.1 Pro (primary)
- **Context:** 1M tokens
- **PDF support:** Native (File API upload)
- **Quality:** Validated in BBP-001 — structurally complete, analytically deep output across all three templates. Meets or exceeds NLM baseline.
- **Pricing (standard):** $2.00/1M input (≤200K), $4.00/1M input (>200K), $12.00/1M output (≤200K), $18.00/1M output (>200K)
- **Pricing (batch, 50% discount):** $1.00/1M input (≤200K), $2.00/1M input (>200K), $6.00/1M output (≤200K), $9.00/1M output (>200K)
- **Token rate:** 560 tokens/page (validated on 3 books: 208pp, 464pp, 707pp — exactly 560 tok/page each)
- **Cost for 100 books × 2 templates (batch):** ~$40-50 (300pp avg) to ~$80-95 (400pp avg). Standard API roughly double.
- **Free API tier:** Not available (can try in AI Studio interface only)
- **Recommendation:** Primary model. Same model NLM uses — quality risk eliminated. Batch API is the primary execution path for cost control.

### Gemini 3 Flash (cost fallback)
- **Context:** 1M tokens
- **PDF support:** Native (File API upload)
- **Quality:** Same generation as NLM's model, lighter variant — strong reasoning, multimodal
- **Pricing:** $0.50/1M input, $3.00/1M output
- **Cost for 100 books:** ~$7.40
- **Batch API:** TBD — verify if Gemini 3 family supports batch API
- **Recommendation:** Best value in the current generation. Same model family NLM uses, ~4x cheaper than Pro. Test quality first.

### Gemini 2.5 Flash (budget option)
- **Context:** 1M tokens
- **PDF support:** Native (File API upload)
- **Quality:** Previous generation — may produce shallower analysis than NLM baseline
- **Pricing (standard):** $0.30/1M input, $2.50/1M output
- **Pricing (batch):** $0.15/1M input, $1.25/1M output
- **Cost for 100 books (batch):** ~$2.35
- **Recommendation:** Only if quality testing shows it matches the NLM baseline despite being an older generation. Cheapest option with batch discount.

### Gemini 2.5 Pro (previous gen fallback)
- **Context:** 1M tokens
- **PDF support:** Native (File API upload)
- **Pricing (standard, ≤200K):** $1.25/1M input, $10/1M output
- **Pricing (batch, ≤200K):** $0.625/1M input, $5/1M output
- **Cost for 100 books (batch):** ~$9.65
- **Recommendation:** Previous best model with batch discount. Good middle ground if 2.5 Flash is too shallow but 3.x is overkill.

### Claude (Sonnet / Opus)
- **Context:** 200K tokens — sufficient for most books but may truncate the longest
- **PDF support:** Base64 in Messages API, or text extraction via MarkItDown
- **Quality:** Excellent structured output, strong analytical depth
- **Pricing:** $3-15/1M input depending on model
- **Cost for 100 books:** $35-220 depending on model
- **Recommendation:** Not cost-competitive for bulk processing. Reserve for high-value individual books where depth matters more than cost.

### Perplexity (Sonar)
- **Context:** Varies by model
- **PDF support:** No native PDF upload — would require text extraction first
- **Quality:** Optimized for search-augmented generation, not document analysis
- **Recommendation:** Wrong tool for this job. Perplexity's strength is web search, not processing uploaded documents against structured templates.

### Cost Summary (100 books × 2 templates = 200 API calls)

**Validated metrics (BBP-001):** 560 tokens/page. book-digest/fiction-digest output ~2.3K tokens, chapter-digest output ~7-12K tokens.

| Model | Standard API (300pp avg) | Batch API (300pp avg) |
|---|---|---|
| Gemini 3.1 Pro | ~$79 | **~$40-50** |
| Gemini 3 Flash | ~$15 | ~$8 |
| Gemini 2.5 Flash | ~$9 | ~$5 |

**Recommendation:** Use **Gemini 3.1 Pro** via **Batch API** for the full run (BBP-006). Same model NLM uses — quality validated. Batch API (50% discount) brings cost within the original budget range. Standard API used only for validation batches where immediate feedback is needed.

### Evaluation Strategy
- BBP-001 validated all three templates produce correct output on 3 books via Gemini 3.1 Pro API (5 generation calls, ~$4.15 actual cost)
- No multi-model comparison needed — model decision is made
- Key finding: 560 tok/page (not 258 from initial research) — costs ~2x higher than PLAN-phase estimates, making Batch API the primary execution path

## Domain Classification & Workflow

- **Domain:** learning
- **Workflow:** SPECIFY → PLAN → ACT (three-phase, knowledge work)
- **Rationale:** Same domain and class as notebooklm-pipeline. The script is simple enough (single Python file + config) that a full four-phase software workflow would be overhead. ACT phase covers implementation + execution + review.

## Task Decomposition

### BBP-001: Prompt + API Validation
- **Type:** `#research`
- **Risk:** low
- **Description:** Validate that adapted prompts produce correct output when sent directly to Gemini 3.1 Pro via API with a PDF upload. Process 3 books (at least 1 fiction, at least 1 nonfiction). Test book-digest-v2 on nonfiction, fiction-digest-v1 on fiction, and chapter-digest-v1 on at least 1 book. Verify: structural completeness (all template sections present), analytical depth (paragraph-level arguments for nonfiction; themes/character analysis for fiction), quote quality (accurate, attributed), concept coverage. Compare against NLM-generated digest if available.
- **Acceptance criteria:**
  - 3 books processed through Gemini 3.1 Pro API with adapted prompts
  - Output structure matches each template's expectations (nonfiction vs fiction)
  - Quality is comparable to NLM output (same model, so expected to match)
  - Any API-specific issues identified (PDF parsing, token limits, response truncation)
- **File changes:** run-log update, sample outputs in `design/`

### BBP-002: Template Adaptation
- **Type:** `#writing`
- **Risk:** low
- **Description:** Adapt **all three** templates for direct API use:
  1. **book-digest-v2** → `prompt-book-digest-v1.md`
  2. **fiction-digest-v1** → `prompt-fiction-digest-v1.md`
  3. **chapter-digest-v1** → `prompt-chapter-digest-v1.md`
  For each: remove sentinel markers, NLM-specific language, truncation recovery instructions. Add: structured metadata block at the top of the response — a fenced YAML block containing `title`, `author`, `year` (optional), `suggested_tags` (from canonical list), and `suggested_source_id`. The digest body follows after the metadata block. This separates machine-parseable metadata from human-readable content.
- **Acceptance criteria:**
  - All three adapted prompts produce structurally identical digest bodies to NLM versions
  - Metadata block is reliably parseable (YAML in a fenced code block)
  - Model correctly populates title, author, and suggests tags from the canonical list
  - No NLM-specific language remains
  - All three prompts stored in pipeline directory
- **File changes:** 3 new files in `_system/scripts/batch-book-pipeline/`

### BBP-003: Pipeline Script
- **Type:** `#code`
- **Risk:** medium
- **Description:** Python script with two execution modes: **standard** (sequential, immediate results for validation) and **batch** (Batch API, fire-and-forget for full runs). Processes one template at a time (selected via `--template` flag). Templates are run as **separate batch processes** so each can be reviewed independently.

  **Standard mode** (default, used for BBP-005 validation):
  1. Accepts `--template book-digest|fiction-digest|chapter-digest` (required)
  2. Scans an input directory for PDF files
  3. **Pre-flight check:** Uses pypdf to verify text extractability; flags scanned/corrupt PDFs as "manual review" and skips them. Flags oversize PDFs (>1,500 pages or >100MB).
  4. **Input dedup:** Computes SHA-256 hash of each PDF; checks against per-template JSONL manifest (`manifest-{template}.jsonl`) to skip already-processed files.
  5. Uploads PDF to Gemini File API
  6. Calls generate_content with the selected template's adapted prompt
  7-13. Parse, validate, write (see below)
  14. Supports `--batch-size N` parameter — processes N books then exits for review
  15. Supports `--resume` — reads manifest to skip already-processed files
  16. **Rate limiting:** Exponential backoff with jitter for 429/5xx errors. Configurable max retries (default 3). Logs each retry.

  **Batch mode** (`--batch-api`, primary path for BBP-006):
  - **Submit** (`--batch-api submit`): Upload all PDFs to File API, build JSONL request file (one line per book with file URI + prompt), call `client.batches.create()`. Save batch job ID to manifest. Fire-and-forget — can run overnight.
  - **Collect** (`--batch-api collect`): Poll `client.batches.get()` for completion, download results JSONL, parse each response through steps 7-13 below. Write all notes + run vault-check.
  - Files have 48hr TTL and 20GB total storage. All PDFs for a single template pass should be uploaded and submitted in the same session.
  - Batch job can be cancelled mid-run — only charged for completed work.

  **Shared post-processing (steps 7-13, both modes):**
  7. **Parses structured metadata block:** Extracts YAML metadata (title, author, year, suggested_tags, suggested_source_id) from the fenced code block at the top of the response. Falls back to regex extraction from `# Title by Author` heading if metadata block is missing. Last resort: derives from PDF filename.
  8. **Tag validation:** Validates suggested tags against the canonical `#kb/` tag list (loaded from `_system/docs/file-conventions.md`). Non-canonical tags replaced with `needs_review`.
  9. **Generates source_id** (deterministic algorithm from author + title) and filename per Output File Naming Convention: `[source_id]-digest.md` for book-digest or fiction-digest, `[source_id]-chapter-digest.md` for chapter-digest. **Short-title truncation:** strip subtitles (after `:` or `—`), strip leading articles ("The", "A", "An"), take first N content words of title to stay under 60 chars total (including author surname prefix), all lowercase, hyphens for spaces, `[a-z0-9-]` only.
  10. **Builds knowledge-note frontmatter** per schema in `_system/docs/file-conventions.md`. Fixed field values for batch output: `type: knowledge-note`, `skill_origin: batch-book-pipeline`, `schema_version: 1`, `note_type: digest`, `scope: whole`. The `source.query_template` field includes a version suffix matching the prompt filename (e.g., `prompt-book-digest-v1`); if the prompt is revised mid-run, bump the version so notes are traceable to the prompt that generated them (consistent with prompt hash in telemetry). The `source.notebooklm_notebook` field is **omitted entirely** — it's NLM-specific and vault-check does not enforce it for knowledge-notes. Remaining source fields (`source_id`, `title`, `author`, `source_type: book`, `date_ingested`) populated from extracted metadata.
  11. **Output dedup:** Checks if output file already exists in `Sources/books/`. If so: log and skip (don't overwrite).
  12. Writes knowledge note to `Sources/books/`
  13. **Telemetry:** Appends per-book JSONL record to `telemetry-{template}.jsonl`: PDF path, file hash, source_id, template, model, prompt hash, input/output token count, estimated cost, status (success/skip/fail/manual), output path, timestamp, error (if any).
- **Intended workflow:**
  1. Run `--template book-digest --input-dir nonfiction/` → review nonfiction digest outputs
  2. Run `--template fiction-digest --input-dir fiction/` → review fiction digest outputs
  3. Run `--template chapter-digest --input-dir nonfiction/` → review nonfiction chapter-digests
  4. Run `--template chapter-digest --input-dir fiction/` → review fiction chapter-digests
- **Acceptance criteria:**
  - Script processes a directory of PDFs end-to-end for a single template
  - `--template` flag selects book-digest, fiction-digest, or chapter-digest
  - Output files pass vault-check
  - Pre-flight check catches scanned/corrupt PDFs before API calls
  - Input dedup (file hash per template) prevents reprocessing; output dedup (filename) prevents overwrites
  - `--resume` correctly skips already-processed files
  - Rate limiting handles API throttling gracefully
  - Per-book telemetry logged to per-template JSONL
  - Configurable batch size
  - Error handling: retry with backoff, skip after N failures, never crash the batch
- **File changes:** 3-4 new files in `_system/scripts/batch-book-pipeline/`
- **Dependencies:** BBP-002 (needs both adapted prompts)

### BBP-004: Tag Strategy
- **Type:** `#decision` → resolved
- **Risk:** low
- **Description:** Tag assignment uses a **prompt-embedded canonical list** approach:
  1. The adapted prompt (BBP-002) includes the full canonical `#kb/` tag list and instructs the model to select 1-3 tags from the list only
  2. The model outputs its tag suggestions in the structured metadata block (`suggested_tags`)
  3. The script validates each tag against the canonical list loaded from `_system/docs/file-conventions.md`
  4. Non-canonical tags are replaced with `needs_review`
  5. All books receive at least one valid `#kb/` tag — if the model suggests none, the book is tagged `needs_review`
  - **Canonical list source:** `_system/docs/file-conventions.md` (authoritative), mirrored in CLAUDE.md
  - **Current canonical tags (~15):** `religion`, `philosophy`, `gardening`, `history`, `inspiration`, `poetry`, `writing`, `business`, `dns`, `networking`, `security`, `software-dev`, `customer-engagement`, `training-delivery`
- **Acceptance criteria:**
  - Tag strategy implemented in BBP-002 (prompt) and BBP-003 (validation)
  - Tested on 5+ books with diverse subjects during BBP-005 validation batch
  - False tag rate <20% (measured by user review in BBP-005)
  - Non-canonical suggestions logged for potential tag list expansion
- **File changes:** prompt update (BBP-002), script validation logic (BBP-003)

### BBP-005: Validation Batch
- **Type:** `#research`
- **Risk:** medium
- **Description:** Process a validation batch of 10 books (mix of fiction and nonfiction) through each applicable template:
  1. Run `--template book-digest` on nonfiction subset → user reviews digest outputs
  2. Run `--template fiction-digest` on fiction subset → user reviews fiction digest outputs
  3. Run `--template chapter-digest` on all 10 books → user reviews chapter-digest outputs
  This validates all three templates before committing to full batch runs.
- **Acceptance criteria:**
  - ~20 knowledge notes in Sources/books/ (10 digests + 10 chapter-digests)
  - All pass vault-check
  - User approves quality for all three template types (or issues documented and fixed)
  - No systematic quality gaps in any output type
  - Tag accuracy acceptable (<20% false tags)
- **File changes:** ~20 new files in Sources/books/, run-log update

### BBP-006: Full Batch Execution
- **Type:** `#code`
- **Risk:** low (if BBP-005 passes)
- **Description:** Process remaining ~90 books through all applicable templates using **Batch API** (primary path). Four fire-and-forget submissions:
  1. **Pass 1 — nonfiction digests:** `--template book-digest --input-dir nonfiction/ --batch-api submit`. Submit before bed, collect next morning.
  2. **Pass 2 — fiction digests:** `--template fiction-digest --input-dir fiction/ --batch-api submit`.
  3. **Pass 3 — chapter-digests (nonfiction):** `--template chapter-digest --input-dir nonfiction/ --batch-api submit`.
  4. **Pass 4 — chapter-digests (fiction):** `--template chapter-digest --input-dir fiction/ --batch-api submit`.
  Each pass: submit → collect → vault-check → user spot-check → next pass. Can cancel mid-job; only charged for completed work.
  Fallback: standard API with `--resume` if batch API encounters issues.
- **Acceptance criteria:**
  - All ~100 books processed through both outputs (~200 total output files)
  - All notes pass vault-check
  - Total cost documented (target: ~$40-50 via Batch API for 300pp avg books)
  - Processing log complete (per-book, per-template status)
- **File changes:** ~180 new files in Sources/books/ (~90 digests + ~90 chapter-digests), run-log update
- **Dependencies:** BBP-005 (validation batch approved for all three templates)

### Task Dependencies

```
BBP-001 (prompt/API validation) ──► BBP-002 (template) ──► BBP-003 (script) ──► BBP-005 (validation)
                                          ▲                       ▲                      │
                                          │                       │                      ▼
                                    BBP-004 (tags) ───────────────┘               BBP-006 (full batch)
```

BBP-004 (tag strategy) feeds into both BBP-002 (canonical list in prompt) and BBP-003 (validation logic). It can be resolved in parallel with BBP-001.

## Open Questions — Resolved in PLAN Phase

1. **Batch API + PDF → YES:** Gemini Batch API accepts File API URIs for PDFs. 50% cost discount. Gemini 3.1 Pro supported. **Batch API is the primary execution path for BBP-006** — fire-and-forget overnight processing. Standard API reserved for validation batches (BBP-005) where immediate feedback is needed.
2. **Token counting → YES, FREE:** `countTokens` API works with uploaded PDFs. Free (no billing, 3,000 RPM separate quota). **BBP-001 validated: PDFs tokenize at 560 tokens/page** (not 258 as initially researched — consistent across 3 test books of varying size). Revised cost estimate: ~$79 standard, **~$40-50 batch** (300pp avg). Batch API brings cost within original budget range.
3. **Fiction handling → RESOLVED:** fiction-digest-v1 added as third template. Manual genre classification — user organizes PDFs into `nonfiction/` and `fiction/` subdirectories. Pipeline runs the appropriate digest template per directory. No automated detection.
4. **Source index notes → DEFERRED:** Post-pipeline follow-up. Not blocking core pipeline.
5. **Tag review workflow → RESOLVED:** Non-canonical tags replaced with `needs_review`. Post-BBP-006: `grep -r "needs_review" Sources/books/` for manual review pass.

## Peer Review Incorporated

Action items from 4-model peer review (2026-02-28) applied to this spec:
- A1: Structured metadata block for title/author extraction (BBP-002, BBP-003)
- A2: Concrete tag strategy with canonical list (BBP-004, BBP-002, BBP-003)
- A3: Dual-layer dedup — PDF file hash + source_id (BBP-003)
- A4: File naming convention — source_id-based, matching inbox-processor (`[source_id]-[note_type].md`)
- A5: PDF pre-flight check — pypdf text extraction test (BBP-003)
- A6: Rate limiting + resume — backoff, JSONL manifest, `--resume` (BBP-003)
- A7: Task graph label fix — BBP-001 renamed, C1 updated
- A8: Oversize handling documented (new section)
- A9: Per-book JSONL telemetry (BBP-003)

Review note: `Projects/batch-book-pipeline/reviews/2026-02-28-specification.md`
