---
project: batch-book-pipeline
domain: learning
type: log
status: active
created: 2026-02-28
updated: 2026-02-28
---

# Run Log — batch-book-pipeline

## 2026-02-28 — Session 1: SPECIFY

### Context Inventory
- `Archived/Projects/notebooklm-pipeline/progress/run-log.md` — predecessor project history
- `_system/docs/templates/notebooklm/README.md` — template index
- `_system/docs/templates/notebooklm/book-digest-v2.md` — primary template
- `_system/docs/file-conventions.md` (lines 160-261) — knowledge-note + source-index schemas
- `_system/docs/solutions/claude-print-automation-patterns.md` — dispatch patterns
- `_system/docs/overlays/overlay-index.md` — no overlays activated

### Overlay Check
No overlays activated. No business/financial/design dimensions.

### User Requirements (from scoping questions)
- ~100 books, mostly PDFs, available locally
- Templates: book-digest-v2 AND chapter-digest-v1 for every book (2 outputs per book)
- Run as separate batch processes — book-digests first (review), then chapter-digests (review)
- Automation: batched with review (process N, review quality, continue)
- Model: Gemini 3.1 Pro — user chose quality-assured at ~$68 total over cheaper alternatives
- User has API keys available

### Key Decisions
1. **NLM model identified:** NLM runs Gemini 3.1 Pro (upgraded Feb 2026), not 2.5 as originally assumed. Web-verified via 9to5Google.
2. **Model selection:** Gemini 3.1 Pro — same model NLM uses, eliminates quality risk. ~$68 for 200 API calls (100 books × 2 templates). User explicitly chose this over Flash (~$15) and 2.5 Flash (~$9).
3. **Perplexity ruled out:** Search-optimized, no native PDF upload — wrong tool for document digestion.
4. **File naming convention:** `[source_id]-[note_type].md` — matches inbox-processor convention. Source_id = `kebab(author-surname + short-title)`, all lowercase. *(Updated from title-only to source_id-based for consistency with NLM Export Path.)*
5. **Separate batch processes:** Two templates run as independent batch passes for clean review.

### Peer Review — Round 1 (4-model)
- 4/4 reviewers responded (GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast)
- Review note: `Projects/batch-book-pipeline/reviews/2026-02-28-specification.md`
- 50 findings total across 4 reviewers
- 4 must-fix applied: structured metadata extraction (A1), tag strategy concretization (A2), dual-layer dedup (A3), file naming convention (A4)
- 5 should-fix applied: PDF pre-flight (A5), rate limiting + resume (A6), task graph labels (A7), oversize handling (A8), per-book telemetry (A9)
- 5 deferred: response validation, source index notes, fiction detection, copyright note, interactive pause
- Key declined findings: cost constraint "contradiction" (DS-F2, user's explicit decision), model version "errors" (GEM-F1, reviewer knowledge cutoff), pricing "unverifiable" (all 4, web-verified during session)

### Session End
- **Duration:** Full session — project creation through spec + peer review + action item application
- **Deliverables:** specification.md (peer-reviewed, 9 action items applied), specification-summary.md, review note with full synthesis, project scaffold
- **State:** SPECIFY phase complete. Ready for PLAN phase transition on next session.
- **Compound:**
  1. Gemini model generation matters for quality baselines — NLM upgraded from 2.5 to 3.x without announcement. Always verify current model version when designing a pipeline against an external tool's output quality.
  2. Cost for 200 Gemini 3.1 Pro API calls on full books is ~$68 — negligible for the value of structured knowledge capture. Model cost is not the bottleneck for personal knowledge work at this scale.
- **Next session:** Resume project, transition SPECIFY → PLAN, detail execution approach for BBP-001 through BBP-006.

## 2026-02-28 — Session 2: SPECIFY refinement + PLAN transition

### Context Inventory
- `Projects/batch-book-pipeline/design/specification.md` — full spec
- `Projects/batch-book-pipeline/design/specification-summary.md` — spec summary
- `Projects/batch-book-pipeline/progress/run-log.md` — session 1 history
- `.claude/skills/inbox-processor/SKILL.md` — NLM Export Path for parity check
- `_system/docs/templates/notebooklm/README.md` — template index
- `/tmp/crumb-vault-mirror/_system/docs/claude-ai-context.md` — mirror orientation

### Spec Refinements Applied
1. **Inbox-processor parity audit:** Compared batch pipeline spec against inbox-processor NLM Export Path. Confirmed all key functions covered: metadata extraction, source_id, dedup, frontmatter, tag validation, vault-check compliance. Identified two gaps (below).
2. **Filename convention reconciled:** Changed from title-based (`{title}-digest.md`) to source_id-based (`[source_id]-[note_type].md`) matching inbox-processor. Updated spec, summary, and examples table.
3. **Short-title truncation heuristic:** Added deterministic rule to BBP-003 step 9 — strip subtitles, strip leading articles, take first N content words to stay under 60 chars.
4. **Frontmatter field alignment:** New BBP-003 step 10 specifying all knowledge-note fields: `skill_origin: batch-book-pipeline`, `note_type: digest`, `scope: whole`, `schema_version: 1`. `notebooklm_notebook` omitted entirely (vault-check confirmed no enforcement for knowledge-notes).
5. **query_template versioning:** Value includes version suffix (e.g., `prompt-book-digest-v1`) for traceability if prompt revised mid-run. Consistent with prompt hash in telemetry.

### Phase Transition: SPECIFY → PLAN
- Date: 2026-02-28
- SPECIFY phase outputs: specification.md (peer-reviewed, refined), specification-summary.md, review note
- Compound:
  1. When building a new intake engine for an existing output type, align naming conventions with the existing intake path from the start. Title-based vs source_id-based filenames would have created an inconsistent Sources/ directory requiring migration later.
  2. Omit schema fields that have no semantic meaning in a given context (e.g., `notebooklm_notebook` for non-NLM output) rather than setting to null. Cleaner queries, fewer false signals.
  3. Embed prompt version in note frontmatter when notes are script-generated. Cheap traceability for mid-run prompt revisions.
- Context usage before checkpoint: <50%
- Action taken: none
- Key artifacts for PLAN phase: specification-summary.md, specification.md (open questions section)

### PLAN Phase Work

#### Open Questions Resolved (web research via subagents)
1. **Batch API + PDF → YES:** File API URIs accepted in batch JSONL. 50% discount confirmed. Gemini 3.1 Pro supported. Latency up to 24hr. Decision: standard API is primary path; Batch API is optional cost optimization for BBP-006.
2. **Token counting → YES, FREE:** `countTokens` works with uploaded PDFs. No billing, 3,000 RPM. **Key finding:** PDFs tokenized at 258 tokens/page (fixed image rate), not text-based. Revised cost: ~$48 standard (down from $68), ~$24 batch.
3. Fiction detection → deferred. Source index notes → deferred. Tag review → `needs_review` grep.

#### Key Technical Decisions
- **SDK:** `google-genai` (modern package), not legacy `google-generativeai`
- **Standard API as primary path:** Sequential processing handles 180 calls in 30-60 min at ~$48. Simpler than Batch API, within budget.
- **Pre-flight enhanced:** pypdf text check + free `countTokens` for per-book cost estimate
- **`--dry-run` mode:** Pre-flight + cost estimate only, no generation

#### Deliverables
- `design/action-plan.md` — full action plan for BBP-001 through BBP-006
- `design/action-plan-summary.md` — action plan summary
- Spec open questions section updated with resolutions

### Session End
- **Duration:** Medium session — spec refinement, phase transition, PLAN phase execution
- **Deliverables:** action-plan.md, action-plan-summary.md, spec refinements (naming convention, frontmatter fields, query_template versioning, open questions resolved)
- **State:** PLAN phase complete. Ready for PLAN → ACT phase transition on next session.
- **Compound:**
  1. Naming convention consistency across intake paths — align new intake engines with existing ones from the start. Title-based vs source_id-based would have required migration later.
  2. Omit inapplicable schema fields rather than null them — cleaner queries, fewer false signals.
  3. Prompt version in frontmatter for script-generated notes — cheap traceability insurance.
  4. PDF tokenization at 258 tokens/page (fixed image rate) is a significant finding — cost estimates based on text tokenization overestimate by ~40%. Applies to any Gemini PDF pipeline.
- **Next session:** PLAN → ACT transition, begin BBP-001 (API validation with 3 test books).

---

## Session 3 — 2026-02-28

### Phase Transition: PLAN → ACT
- Date: 2026-02-28
- PLAN phase outputs: action-plan.md, action-plan-summary.md, spec open questions resolved
- Compound: Captured in Session 2 (4 insights: naming consistency, omit-vs-null, prompt versioning, 258 tokens/page rate). No additional compoundable insights from housekeeping.
- Context usage before checkpoint: <50%
- Action taken: none
- Key artifacts for ACT phase: action-plan-summary.md, specification-summary.md

### Housekeeping
- Renamed execution-plan → action-plan (files + references) for cross-project consistency
- Tightened BBP-003 step 3: split into 3a (validate) and 3b (cost estimate); clarified --dry-run uses page-count estimation (no File API upload)

### Spec Change: Fiction Template
- **Problem:** fiction-digest-v1 template (from NLM pipeline) has fundamentally different structure than book-digest-v2 — Premise, Themes & Ideas, Character Study, Craft & Style, Notable Quotes, Resonance & Connections vs nonfiction's arguments/concepts/frameworks
- **Decision:** Add fiction-digest as third template. Manual genre classification — user sorts PDFs into `nonfiction/` and `fiction/` subdirectories. Resolves OQ-3 (previously deferred).
- **Impact:** BBP-001 now tests all 3 templates (fiction on Brothers Karamazov). BBP-002 adapts 3 prompts. BBP-003 accepts `--template fiction-digest`. No cost impact (same number of books, each still gets 2 outputs).
- **Files updated:** specification.md, action-plan.md, action-plan-summary.md, tasks.md
- **Input structure:** `_inbox/bbp-pdfs/nonfiction/` and `_inbox/bbp-pdfs/fiction/`

### Session End
- **Duration:** Medium session — phase transition, housekeeping, spec change
- **Deliverables:** Phase transition (PLAN → ACT), tasks.md, fiction-digest-v1 brought into scope across spec/plan/tasks/summary
- **State:** ACT phase, BBP-001 next. Test PDFs staged in `_inbox/bbp-pdfs/` (nonfiction: Augustine, Attention Merchants; fiction: Brothers Karamazov). Gemini API key not yet configured — first task next session.
- **Compound:**
  1. vault-check §10 (active_task consistency) expects `id:` / `state:` structured format in tasks.md, not markdown tables. All prior projects had `active_task: null` so the mismatch was never caught. New projects should use the structured format from the start.
  2. Spec completeness check before ACT: deferred open questions ("revisit later") should be re-evaluated at phase transition — the fiction template gap would have been caught in BBP-005 but at 10x the cost of catching it now.
- **Next session:** Configure Gemini API key, begin BBP-001 (API validation with 3 test books across all 3 templates).

---

## Session 4 — 2026-02-28

### Context Inventory
- `Projects/batch-book-pipeline/project-state.yaml` — project state
- `Projects/batch-book-pipeline/progress/run-log.md` — session 1-3 history
- `Projects/batch-book-pipeline/design/action-plan-summary.md` — action plan summary
- `Projects/batch-book-pipeline/tasks.md` — task list
- `_system/docs/templates/notebooklm/book-digest-v2.md` — book-digest template
- `_system/docs/templates/notebooklm/fiction-digest-v1.md` — fiction-digest template
- `_system/docs/templates/notebooklm/chapter-digest-v1.md` — chapter-digest template
- `_system/docs/file-conventions.md` (knowledge-note schema, canonical tags) — frontmatter reference
- Context7 docs: `google-genai` SDK (file upload, generate_content, count_tokens, batch API)

### BBP-001: API Validation — DONE

**Setup:**
- Created venv at `Projects/batch-book-pipeline/venv/` with google-genai 1.65.0, pypdf 6.7.4, pyyaml
- Added `venv/` to `.gitignore`
- Gemini API key sourced from `~/.config/crumb/.env`
- Model ID verified via API: `gemini-3.1-pro-preview`

**Token Rate Finding:**
- All 3 books measured at exactly **560 tokens/page** (not 258 from PLAN-phase web research)
  - Augustine: 208pp → 116,481 tokens
  - Attention Merchants: 464pp → 259,841 tokens
  - Brothers Karamazov: 707pp → 395,921 tokens

**Generation Results (5 calls, ~$4.15 actual):**

| Book | Template | Sections | Words | Time | Input/Output tokens |
|---|---|---|---|---|---|
| Augustine | book-digest | 9/9 PASS | 1,629 | 188s | 108K/2.1K |
| Attention Merchants | book-digest | 9/9 PASS | 1,888 | 112s | 242K/2.6K |
| Brothers Karamazov | fiction-digest | 7/7 PASS | 1,619 | 118s | 368K/2.2K |
| Augustine | chapter-digest | 13 Books + Arc + XCC PASS | 5,364 | 120s | 108K/7.3K |
| Attention Merchants | chapter-digest | 29 Ch + Arc + XCC PASS | 8,463 | 181s | 242K/11.8K |

Quality across all templates meets or exceeds NLM baseline. Attention Merchants book-digest captured real checklists (Stolley's cover rules) and tables (4-screen evolution). Chapter-digest correctly adapted "Book" terminology for Augustine.

**Cost Impact:**
- 560 tok/page (2.17x estimate) + actual pricing ($2/$12 per M, not $1.25/$10) → Standard API ~$79-191 for full batch
- **Batch API (50% discount) brings 300pp avg scenario to ~$40-50** — within original $68 budget
- Decision: Batch API promoted from optional optimization to **primary execution path** for BBP-006

### BBP-002: Template Adaptation — DONE

**Three adapted prompts created in `_system/scripts/batch-book-pipeline/`:**
- `prompt-book-digest-v1.md` — nonfiction whole-book digest
- `prompt-fiction-digest-v1.md` — fiction whole-book digest
- `prompt-chapter-digest-v1.md` — chapter-by-chapter breakdown

**Changes from NLM templates:**
- Stripped: sentinel markers, NLM-specific language, truncation recovery, Chrome extension refs
- Added: YAML metadata block instruction (title, author, year, suggested_tags, suggested_source_id)
- Added: canonical `#kb/` tag list embedded directly in each prompt with "select from this list ONLY" instruction
- Fiction prompt: instruction to tag by themes, not just "fiction"
- Chapter prompt: instruction to use whatever division labels the author uses (Chapter/Book/Part)

**Validation (3 calls, ~$3.50):**

| Prompt | YAML parse | Tags canonical | source_id | year |
|---|---|---|---|---|
| book-digest | OK | religion, philosophy, history | augustine-confessions | 401 |
| fiction-digest | OK | philosophy, religion | dostoyevsky-brothers-karamazov | 1880 |
| chapter-digest | OK | religion, philosophy, history | augustine-confessions | 401 |

All metadata blocks reliably parseable. All suggested tags from canonical list. source_id suggestions reasonable.

Also created: `requirements.txt` (google-genai, pypdf, pyyaml)

### Spec & Plan Updates
- Updated specification.md: token rate (560), pricing ($2/$12), cost estimates, Batch API as primary, BBP-003 dual-mode architecture, BBP-006 fire-and-forget, validated assumptions A1/A2, resolved unknowns U1-U3
- Updated action-plan.md: OQ-1/OQ-2 revised, BBP-003 dual-mode CLI, BBP-006 batch primary, 560 tok/page in cost estimates
- Updated specification-summary.md, action-plan-summary.md: full rewrite reflecting BBP-001 findings
- Updated tasks.md: BBP-001 done, BBP-002 done, BBP-003/006 descriptions updated
- Updated project-state.yaml: active_task BBP-003

### Session End
- **Duration:** Full session — BBP-001 (API validation, 5 calls) + BBP-002 (template adaptation, 3 calls) + spec/plan updates
- **Deliverables:** 5 sample outputs in `design/samples/`, 3 adapted prompts + requirements.txt in `_system/scripts/batch-book-pipeline/`, validation script `design/bbp001-validate.py`, full spec/plan/summary updates reflecting BBP-001 findings
- **API cost:** ~$7.65 (8 generation calls across both tasks)
- **State:** ACT phase, BBP-003 next (pipeline script with standard + batch modes)
- **Compound:**
  1. Web-researched token rates can be wrong — always validate with actual `countTokens` calls on representative samples before committing to cost estimates. The 258 tok/page figure was from a plausible web source but the actual rate was 560 (2.17x).
  2. When token costs are higher than estimated, Batch API shifts from "nice to have" to "essential" — the 50% discount is the difference between within-budget and over-budget. Design for batch-first when the use case permits async processing.
  3. Context7 (MCP tool) is effective for SDK verification — confirmed the exact `google-genai` API surface (files.upload, batches.create, batches.get) against the authoritative source rather than relying on memory or web search.
- **Next session:** BBP-003 — pipeline script with standard + batch modes.

---

## Session 5 — 2026-02-28

### Context Inventory
- `Projects/batch-book-pipeline/project-state.yaml` — project state
- `Projects/batch-book-pipeline/progress/run-log.md` — session 1-4 history
- `Projects/batch-book-pipeline/design/action-plan.md` — BBP-003 steps
- `Projects/batch-book-pipeline/design/specification.md` — BBP-003 spec (lines 270-305)
- `Projects/batch-book-pipeline/tasks.md` — task list
- `Projects/batch-book-pipeline/design/bbp001-validate.py` — API patterns from BBP-001
- `_system/scripts/batch-book-pipeline/prompt-book-digest-v1.md` — prompt (metadata block format)
- `_system/docs/file-conventions.md` (lines 160-260) — knowledge-note schema
- Context7 docs: `google-genai` SDK (batches.create, batches.get, file_data, batch results download)

### BBP-003: Pipeline Script — DONE

**Deliverable:** `_system/scripts/batch-book-pipeline/pipeline.py` (540 lines)

**Features implemented (all 16 spec steps):**
1. Arg parsing: `--template`, `--input-dir`, `--batch-size`, `--resume`, `--dry-run`, `--batch-api`
2. PDF scan (glob *.pdf, sorted)
3a. Pre-flight: pypdf text extraction test, page count, oversize flag (>1500pp / >100MB)
3b. Cost estimation at 560 tok/page with standard vs batch pricing
4. Input dedup: SHA-256 hash vs manifest JSONL
5. File API upload with ACTIVE state polling
6. Generate with exponential backoff + jitter (429/5xx, 3 retries)
7. YAML metadata block parsing (fenced block → heading regex → filename fallback)
8. Tag validation against canonical list, non-canonical → `needs_review`
9. Deterministic source_id: kebab(surname + short-title), subtitle stripping, article stripping, 60-char max
10. Full knowledge-note frontmatter with topics field derived from kb/ tag mapping
11. Output dedup: check Sources/books/ for existing filename
12. Write note to Sources/books/
13. Per-book telemetry JSONL (path, hash, template, model, prompt hash, tokens, cost, status)
14. Batch size limit
15. Resume from manifest
16. Rate limiting with exponential backoff

**Batch API mode:**
- Submit: scan → pre-flight → dedup → upload PDFs → build JSONL request file → `batches.create()` → save state
- Collect: poll `batches.get()` → download results → parse each response → write notes
- State file (`batch-state-{template}.json`) persists job name + per-book metadata between submit and collect

**Validation results (7 generation calls, ~$7 API cost):**

| Template | Book | source_id | Output | vault-check |
|---|---|---|---|---|
| book-digest | Attention Merchants | wu-attention-merchants | -digest.md | PASS |
| fiction-digest | Brothers Karamazov | dostoyevsky-brothers-karamazov | -digest.md | PASS |
| chapter-digest | Attention Merchants | wu-attention-merchants | -chapter-digest.md | PASS |

All 3 notes written with correct frontmatter, canonical tags, topics mapping, and vault-check compliance (0 errors).

**Additional features tested:**
- `--resume`: correctly skips already-processed books via manifest
- `--dry-run`: reports cost estimate without API calls
- Output dedup: skips write when file already exists (doesn't overwrite)
- `--batch-size 1`: processes one book then exits

**Bug found and fixed:**
- **source_id collision detection too aggressive:** `check_source_id_collision()` used glob matching (`{source_id}-*.md`) which triggered on the same book's digest file when running chapter-digest. The same book's two outputs should share the same source_id. Fix: read frontmatter of existing files and compare normalized titles (strip subtitles, articles) — only flag when a genuinely different book produces the same source_id.

**Topics field added:**
- vault-check §5.6.5 requires `topics` field on kb-tagged notes. Added `KB_TO_TOPIC` mapping from canonical kb/ tags to existing MOC slugs (moc-business, moc-history, moc-philosophy, moc-writing). Topics auto-derived from tags.

### Code Review — manual BBP-003
- Scope: `_system/scripts/batch-book-pipeline/pipeline.py` (1077 lines, new file)
- Panel: Claude Opus 4.6, Codex GPT-5.3-Codex
- Codex tools: pytest (failed: sandbox), mypy (not installed), pyright (not installed) — fell back to static analysis
- Findings: 3 critical (ANT), 11 significant, 10 minor, 5 strengths
- Consensus: 1 finding flagged by both reviewers (batch `job.state` enum vs string)
- Details:
  - [ANT-F1 + CDX-F1] CRITICAL/SIGNIFICANT: pipeline.py:922 — `job.state` compared as string, SDK returns enum. Infinite poll loop.
  - [CDX-F2] SIGNIFICANT: pipeline.py:844 — batch JSONL upload missing ACTIVE verification
  - [ANT-F13] MINOR: pipeline.py:309 — `validate_tags` doesn't handle string input from LLM
  - [ANT-F4] SIGNIFICANT: pipeline.py:792 — `TimeoutError` in batch upload kills entire batch
  - [CDX-F5] MINOR: pipeline.py:421 — year not sanitized in `disambiguate_source_id`
  - [CDX-F6] MINOR: pipeline.py:204 — manifest JSONL no per-line error handling
  - [CDX-F7] MINOR: pipeline.py:958 — failed batch items not written to manifest
- Action: 7 fixes applied (A1-A7), remaining findings declined or deferred
  - ANT-F2/F3 declined: SDK docs verified via Context7 (bytes return, dest.file_name path)
  - ANT-F10 declined: `contents=[file, prompt]` validated in BBP-001 (8 successful calls)
- Review note: `Projects/batch-book-pipeline/reviews/2026-02-28-code-review-manual.md`
- Tagged: `code-review-2026-02-28`

**Post-review fixes (user-flagged):**
- A8 (ANT-F14): Added 200K tier warning in `estimate_cost` — flags books where actual cost may exceed estimate
- A9 (ANT-F16): Output dedup now checks `st_size > 0` — prevents ghost files from crashed writes blocking reprocessing
- A10 (ANT-F15): Batch collect extracts `usageMetadata` from response JSONL — injects input/output tokens and batch-rate cost into telemetry

### Session End
- **Duration:** Full session — BBP-003 implementation + code review + fixes
- **Deliverables:** `pipeline.py` (1090 lines, code-reviewed), 3 knowledge notes in `Sources/books/`, code review note + raw responses, manifest/telemetry JSONL
- **API cost:** ~$7 Gemini (7 generation calls) + Opus review (~$0.15) + Codex review (subscription)
- **State:** ACT phase, BBP-005 next (validation batch — 10 books through all templates)
- **Compound:**
  1. Source_id collision detection must normalize titles before comparison — LLM returns inconsistent title forms (with/without subtitle) across templates for the same book. Glob-based collision detection without frontmatter comparison creates false positives on multi-template runs.
  2. `job.state` enum-vs-string is a recurring SDK pattern trap — code that uses `.state.name` in one place and bare `.state` in another will silently break. When using an SDK with enum-like return types, grep for all state comparisons to ensure consistent accessor usage.
  3. For batch API pipelines, extract `usageMetadata` from response JSONL at collect time — it's the only window for actual cost tracking. Omitting it means cost data is permanently lost for batch runs.
- **Next session:** Stage 10 diverse PDFs, run BBP-005 validation batch.

---

## Session 6 — 2026-02-28

### Context Reconstruction
Resumed from compacted session. Rebuilt context from project-state.yaml, run-log, tasks.md.

### BBP-005 Staging Check
Confirmed 10 PDFs staged by user:
- **Nonfiction (6):** Attention Merchants, Confessions of St Augustine, Beyond Good and Evil, Man's Search for Meaning, Narrative of Frederick Douglass, Thinking in Systems
- **Fiction (4):** Brothers Karamazov, Crime and Punishment, Frankenstein, Metamorphosis

Good diversity: philosophy, memoir, systems thinking, autobiography, classic fiction, novella. Mix of lengths and eras.

### Session End
- **Duration:** Minimal — context reconstruction + staging verification only
- **Deliverables:** None (session cut short before BBP-005 execution)
- **State:** ACT phase, BBP-005 ready to execute
- **Compound:** None — no substantive work performed
- **Next session:** Run BBP-005 validation batch with the 10 staged PDFs

---

## Session 7 — 2026-02-28

### Context Inventory
- `Projects/batch-book-pipeline/project-state.yaml` — project state
- `Projects/batch-book-pipeline/progress/run-log.md` — session 1-6 history
- `Projects/batch-book-pipeline/tasks.md` — task list
- `_system/scripts/batch-book-pipeline/pipeline.py` — pipeline script

### BBP-005: Validation Batch — DONE

**Execution:** 4 pipeline runs (book-digest×nonfiction, fiction-digest×fiction, chapter-digest×nonfiction, chapter-digest×fiction). Standard mode for real-time quality review.

**Results:**
- 20 notes total (17 new + 3 prior from BBP-001/003) across 10 books × 2 templates
- vault-check: 0 errors
- Tag accuracy: 100% canonical, 0 `needs_review` (target was <20%)
- API cost: $4.69 for 17 calls
- 2 transient 499 CANCELLED errors on fiction chapter-digest (Frankenstein, Brothers Karamazov) — resolved on retry
- Quality reviewed on 3 samples: Frankl (book-digest), Kafka (fiction-digest), Meadows (chapter-digest) — all excellent

**Bug found and fixed:**
- `load_manifest()` used dict keyed by file hash with last-entry-wins — a `skip` entry after a `success` entry overwrote the success, breaking `--resume`. Fixed to preserve `success` entries.

### Venv Relocation
- Moved venv from `Projects/batch-book-pipeline/venv/` to `~/.local/share/batch-book-pipeline/venv/`
- Reason: thousands of venv files were causing Obsidian indexer slowdown
- No doc changes needed — no hardcoded venv paths in pipeline script or active docs

### BBP-006: Full Batch — SUBMITTED

**Staging:** User staged 99 PDFs (79 nonfiction, 17 fiction). Cleared 11 pre-BBP files from `Sources/books/` for regeneration.

**Pre-flight results:**
- 14 PDFs skipped: 12 scanned/image-only (no extractable text), 2 oversized (Beck 498MB, Bible 1542pp)
- Skipped books listed for user — OCR versions needed

**Batch submissions (4 jobs, all PENDING):**

| Batch | Job ID | Books |
|---|---|---|
| book-digest × nonfiction | `batches/too1343rqz07y4f1rygnq3ve63y6yx7pd22n` | 60 |
| fiction-digest × fiction | `batches/p91vicv81jxbt6p5mh5f3930jrbxn526x1uh` | 11 |
| chapter-digest × nonfiction | `batches/y3rynwyqav1ajwvgpa6slc4q9cn6qfgj6ofs` | 60 |
| chapter-digest × fiction | `batches/wpj5k60lvjxj2jx4jvg00mxqxhoetxi5wmnl` | 11 |

- 142 total API calls queued with Google Batch API (50% discount)
- Estimated cost: ~$31 batch pricing
- SLA: up to 24hr, typically faster

**Mime type fix:** Batch JSONL upload failed on first attempt — SDK couldn't auto-detect mime type for `.jsonl`. Fixed by adding explicit `mime_type="application/jsonl"` to upload config.

### Session End
- **Duration:** Full session — BBP-005 execution + validation + BBP-006 staging + batch submission
- **Deliverables:** 20 BBP-005 knowledge notes in Sources/books/, 4 batch jobs submitted, pipeline bug fixes (manifest resume, JSONL mime type)
- **API cost:** $4.69 Gemini (BBP-005, 17 calls) + batch upload costs (minimal)
- **State:** ACT phase, BBP-006 submitted. Next: collect batch results.
- **Compound:**
  1. Venvs in Obsidian vaults cause indexer slowdown — store at `~/.local/share/<project>/venv/` instead. Pipeline scripts don't reference venv paths so no code changes needed, just activation path.
  2. Google genai SDK can't auto-detect `.jsonl` mime type — always set `mime_type` explicitly for non-standard file extensions in `files.upload()`.
  3. Manifest resume logic must handle multiple entries per hash — last-entry-wins is wrong when skip/fail entries follow success entries. Always preserve the highest-priority status.
- **Next session:** Collect BBP-006 batch results (`--batch-api collect` for all 4 templates), run vault-check, spot-check quality.

## 2026-02-28 — Session 8: MOC Pre-Staging

### Context Inventory
- `_inbox/moc-scaffolding-proposal.md` — MOC readiness proposal (written from vault mirror)
- `_system/docs/crumb-design-spec-v2-1.md` §5.6 — MOC system spec
- `_system/docs/file-conventions.md` — canonical tag list, topics rules
- `_system/scripts/vault-check.sh` — Check 17-19 (MOC schema, topics resolution/requirement)
- `_system/scripts/batch-book-pipeline/pipeline.py` — KB_TO_TOPIC mapping, template configs
- `Domains/Learning/moc-*.md` — all 6 existing MOCs (read for template + state)

### Overlay Check
No overlays activated. Infrastructure work, no domain-specific lens needed.

### Work Performed

**Proposal review:** Analyzed `moc-scaffolding-proposal.md`. Key correction: the proposal assumed the pipeline writes notes without `topics`, but `pipeline.py` already handles this via `KB_TO_TOPIC` mapping (implemented in session 5). This made the proposed batch placement script partially redundant — the frontmatter side is handled, but the MOC-side placement (Core one-liner insertion) was still an orphan.

**Step 1 — Tag expansion (4 new canonical tags):**
Added `kb/fiction`, `kb/biography`, `kb/politics`, `kb/psychology` to:
- `vault-check.sh` CANONICAL_KB_TAGS (line 570)
- `CLAUDE.md` canonical tag list
- `file-conventions.md` canonical tag list
- 3 BBP prompt templates (book-digest, fiction-digest, chapter-digest)

Brings canonical list from 14 → 18 tags. `kb/inspiration` deliberately left unmapped → `needs-placement` for manual routing.

**Step 2 — MOC skeleton creation (7 new MOCs):**
Created in `Domains/Learning/`: moc-religion, moc-fiction, moc-biography, moc-politics, moc-psychology, moc-poetry, moc-gardening. All `notes_at_review: 0`, `review_basis: full`. Decision: single `moc-religion` with internal sections (Buddhism & Zen, Tibetan, Christianity, Comparative) — split deferred per §5.6.7.

**Step 3 — Pipeline KB_TO_TOPIC expansion:**
Expanded mapping from 4 → 17 entries (all canonical tags now covered). Includes fallback routes for work-domain tags (dns/networking/security → moc-crumb-operations, software-dev → moc-crumb-architecture, customer-engagement/training-delivery → moc-business).

**Step 4 — MOC Core placement script:**
Built `_system/scripts/batch-moc-placement.py` (zero external dependencies). Features:
- Scans `Sources/books/` for digest notes, inserts one-liners into MOC Core sections
- Filters out chapter digests (filename suffix, not scope field — pipeline scope bug)
- `--backfill` flag: adds missing topic mappings to notes from pre-expansion runs
- `--dry-run`: preview without writing
- Idempotent: dedup checks existing wikilinks in Core before inserting
- Preserves `last_reviewed` and `notes_at_review` (untouched for manual baseline)
- One-liner format: `[[stem|Surname: Title]] — tag1, tag2` (minimal, temporary)

**Bugs found and fixed:**
1. **Pipeline scope bug:** `TEMPLATES["chapter-digest"]["scope"]` was `"whole"` instead of `"chapter"`. Fixed in pipeline.py. Won't affect in-flight BBP-006 batch jobs.
2. **Trailing-newline parser bug:** Frontmatter regex `^---\n(.+?)\n---` strips the trailing `\n`, causing list-item regexes to miss the last entry. Affected both `parse_frontmatter` (topics extraction) and `backfill_topics` (topics replacement). First live run produced corrupted frontmatter (`- moc-history---` concatenation) and incomplete placements. Fixed with normalization (`fm_text += "\n"` before regex, `rstrip + \n` in reconstruction).

**Live run results (BBP-005 notes):**
- 20 entries placed across 5 MOCs (moc-philosophy, moc-history, moc-religion, moc-business, moc-crumb-architecture)
- 5 topics backfilled (tags that now have MOC mappings)
- 10 chapter digests correctly skipped
- Idempotency verified (second run: 0 placed, 20 skipped as duplicates)
- vault-check: 0 errors, 18 warnings (all pre-existing + 1 new synthesis density warning on moc-philosophy)

### Key Decisions
1. **No spec change for debt suppression** — natural review window + manual `notes_at_review` baseline setting is sufficient
2. **Source index notes deferred (Option C)** — digest notes in MOC Core temporarily; index generation is a follow-up task
3. **Minimal one-liner format** — tag labels only, no Core Thesis extraction; temporary until synthesis rewrites
4. **`kb/inspiration` unmapped** — routes to `needs-placement` for manual review; may self-resolve as `kb/psychology` captures most of that content

### Observations
- **Philosophy over-tagging in BBP-005:** 8/10 books tagged kb/philosophy. 3 questionable (Kafka, Shelley, Meadows). Root cause: kb/fiction didn't exist, model used kb/philosophy as nearest fit. Should improve in BBP-006 with expanded tag list. Meadows (systems textbook → philosophy) is a different failure mode — watch for recurrence.
- **Prompt-level fix consideration:** If BBP-006 shows continued "big ideas = philosophy" pattern on analytical/framework books, add clarification to prompts: "philosophy means the formal discipline, not books with big ideas." One instance isn't actionable.
- **Dual-tag fiction is correct:** Dostoyevsky Brothers Karamazov legitimately dual-tags kb/philosophy + kb/fiction. Quality review judgment call, not a pipeline engineering issue.

### Compound
1. **Trailing-newline trap in regex-based YAML parsing:** When extracting frontmatter via `^---\n(.+?)\n---`, the closing `\n` is consumed by the regex, not captured in the group. Any subsequent list-item regexes (`(?:- .+\n)*`) will miss the last entry. Always normalize with trailing `\n` before applying list regexes. This is a general pattern for any zero-dependency YAML parsing — not specific to this script.
2. **Filename suffix > frontmatter field for type discrimination** when the frontmatter field may have bugs. Pipeline-generated filenames are mechanically correct (derived from template config `note_suffix`); frontmatter `scope` had a copy-paste error across templates.
3. **Tag taxonomy gaps cause over-tagging on nearest-neighbor tags.** When the canonical list lacks a direct-fit tag (e.g., no `kb/fiction`), LLMs use the closest match (e.g., `kb/philosophy` for fiction with philosophical themes). Expanding the taxonomy before batch runs prevents systematic misrouting.

### Session End
- **Duration:** MOC pre-staging session — proposal review, tag expansion, MOC creation, placement script
- **Deliverables:** 7 new MOCs, 4 new canonical tags, placement script, pipeline mapping expansion, 2 bug fixes
- **State:** ACT phase, pre-staging complete. BBP-006 batch jobs still PENDING in Google Batch API.
- **Next session:** Collect BBP-006 results → run placement script → quality review → set notes_at_review baselines

---

## Session 9 — 2026-02-28

### Context Inventory
- `Projects/batch-book-pipeline/project-state.yaml` — project state
- `Projects/batch-book-pipeline/progress/run-log.md` — session 1-8 history
- `_system/scripts/batch-book-pipeline/batch-state-*.json` — batch state files (3 of 4)
- `_system/scripts/batch-book-pipeline/pipeline.py` — pipeline script (collect flow)
- `_system/scripts/batch-moc-placement.py` — MOC placement script

### BBP-006 Collection — Blocked (Jobs Still Running)

**Status check:** All 4 batch jobs still `JOB_STATE_RUNNING` after ~3.5 hours. Google Batch API SLA is up to 24hr for 142 calls processing full PDFs with Gemini 3.1 Pro.

**State file collision discovered and fixed:**
- Pipeline uses `batch-state-{template}.json` — both nonfiction and fiction chapter-digest jobs share `batch-state-chapter-digest.json`
- Fiction submission (11 books) overwrote nonfiction submission (60 books)
- Fix: Reconstructed `batch-state-chapter-digest-nonfiction.json` from book-digest state (same 60 books, different job name `batches/y3rynwyqav1ajwvgpa6slc4q9cn6qfgj6ofs`)
- Backed up fiction state as `batch-state-chapter-digest-fiction-backup.json`
- Root cause: pipeline doesn't include genre in state filename — known design gap for multi-genre batch runs

**Monitor script created:** `_system/scripts/batch-book-pipeline/bbp006-monitor.sh`
- Polls all 4 jobs every 60s
- When all succeed: runs pipeline collect for each (sequential), with state file swapping for chapter-digest pair
- Then runs MOC placement with `--backfill`
- `--poll-only` flag for quick status checks
- Logs to `bbp006-status.txt`
- Tested: poll-only mode works correctly

### Source-Index Generation Script

**Deliverable:** `_system/scripts/batch-book-pipeline/generate-source-index.py`

**Features:**
- Scans `Sources/books/` for knowledge notes, groups by `source_id`
- Generates `{source_id}-index.md` for each unique source missing one
- Extracts overview from digest Core Thesis (nonfiction) or Premise & Setup (fiction)
- Builds Notes table linking all child notes (digest + chapter-digest)
- Merges tags/topics from all child notes
- Idempotent: skips existing source-index notes
- Zero dependencies, `--dry-run` support

**Validated:** 10 source-index notes generated for BBP-005 books. All pass vault-check (15 source-index total including 5 pre-existing video/article ones).

### Placement Script Update

Updated `batch-moc-placement.py` to prefer source-index notes over individual digests:
- Pre-scan identifies source_ids with index notes
- When index exists: places the index note, skips all digests for that source_id
- When no index: falls back to placing the digest (backward compatible)
- Fixed tag/topics regex to handle indented YAML list items from source-index notes

**Migration:** Removed 20 old BBP-005 digest entries from MOCs, replaced with 25 source-index entries (more because index notes merge cross-template tags). Pre-existing entries (Baldwin-Buckley, Arendt) preserved. Idempotency verified (second run: 0 placed, 25 duplicate).

Updated `bbp006-monitor.sh` to run source-index generation before placement.

### Session End
- **Duration:** Medium session — collection prep, source-index generator, placement upgrade
- **Deliverables:** `generate-source-index.py`, updated `batch-moc-placement.py`, `bbp006-monitor.sh`, 10 source-index notes, reconstructed chapter-digest state file
- **State:** ACT phase, BBP-006 jobs running. Full post-collection pipeline ready: monitor → collect → generate index → place → (manual) quality review + baselines.
- **Compound:**
  1. **State file naming collision on multi-genre batch runs:** When a pipeline uses `batch-state-{template}.json` and the same template is run against different input directories (nonfiction/fiction), the second submission overwrites the first's state. Fix: include input directory hash or genre label in state filename.
  2. **Indented vs non-indented YAML lists across tools:** Pipeline-generated notes use non-indented tags/topics (`- kb/foo`), while source-index and inbox-processor notes use indented (`  - kb/foo`). Always use `^\s*- ` in regex-based YAML list parsing. Hit twice (topics then tags).
  3. **Targeted MOC entry replacement > blanket removal:** When upgrading one-liner format, match by specific wikilink stem not suffix pattern. Blanket `-index|` matching caught pre-existing non-BBP entries.
- **Next session:** Run `bbp006-monitor.sh` (or `--poll-only` first to check). When collection completes: quality review, vault-check, set baselines. Then transition to book-scout project (PLAN → TASK → M0).

---

## Session 10 — 2026-03-02: Operations + New Batch Queuing

### Context Inventory
- `Projects/batch-book-pipeline/project-state.yaml` — project state
- `Projects/batch-book-pipeline/progress/run-log.md` — session 1-9 history
- `_system/scripts/batch-book-pipeline/manifest-chapter-digest.jsonl` — chapter-digest manifest
- `_system/scripts/batch-book-pipeline/telemetry-chapter-digest.jsonl` — error details
- `_system/scripts/book-scout/catalog-processor.sh` — catalog processor script
- `_openclaw/tess_scratch/catalog/inbox/` — pending catalog JSONs

### Work Performed

**1. Book Scout catalog processing:**
- Ran `catalog-processor.sh` — 41/41 catalog JSONs processed, 0 failed, 0 skipped
- 41 new source-index notes created in `Sources/books/`
- Catalog inbox cleared

**2. Chapter-digest batch-3 diagnosis:**
- Previous run (today, 13:54–14:31) had 43 consecutive failures — all `503 UNAVAILABLE` (Gemini capacity)
- Earlier batch-3 run (last night) had 5 successes + 7 hard failures (content filter, oversized, cancelled)
- API health check confirmed recovery — restarted chapter-digest pipeline with `--resume`
- Job running in background at session end

**3. New book inventory:**
- Identified 64 unprocessed PDFs in `research-library/` not in any manifest
- Root cause: `pipeline.py` uses `glob("*.pdf")` (flat, not recursive) — requires per-subdirectory invocation
- First attempt with `--input-dir /Users/tess/research-library` produced "No PDF files found"
- Fix: queued per-subdirectory iteration across all 7 subject dirs
- book-digest + fiction-digest queued sequentially, running in background at session end
- biography/mandela already processed (1 book, 260k tokens, 84.6s)

**4. Manual processing checklist:**
- Created `_inbox/bbp-manual-processing-checklist.md` — 30 image-only + 3 hard-failure PDFs
- Organized by subject folder with checkboxes for operator to run through NLM manually

### Background Jobs at Session End
- `bir98cwi7` — chapter-digest on batch-3 (43 books retrying after 503), still running
- `bb4jkrwos` — book-digest then fiction-digest per research-library subdir (64 new books), still running

### Compound
1. **Pipeline flat-glob is a UX trap:** `scan_pdfs()` uses `input_dir.glob("*.pdf")` which silently returns empty for directories with subdirectories. The "No PDF files found" message doesn't hint at the cause. Consider adding `rglob` or at minimum a warning when subdirectories exist but no PDFs are found at top level.
2. **503 cascades waste manifest space:** 43 consecutive 503 failures each append to the manifest, bloating it with duplicate fail entries for the same file hash. The `--resume` logic handles this correctly (skips only `success` entries) but the manifest grows unnecessarily. A rate-limit backoff that pauses the entire run on N consecutive 503s would be more efficient.

### Session End
- **Duration:** Operational session — catalog processing, pipeline diagnosis, batch queuing, checklist creation
- **Deliverables:** 41 source-index notes, manual processing checklist, 2 background pipeline jobs queued
- **State:** ACT phase, BBP-006 collection ongoing. Two new pipeline runs in progress.
- **Next session:** Check background job results, collect any remaining failures, quality review on new batch outputs.

---

## 2026-03-07 — BBP-006 Close-Out

### BBP-006: DONE

Final tally from manifest analysis:
- **book-digest:** 181 successes, 22 skips, 8 unrecovered failures
- **chapter-digest:** 138 successes, 10 skips, 5 unrecovered failures
- **fiction-digest:** 39 successes, 3 skips, 2 unrecovered failures
- **Total:** 358 knowledge notes generated, 542 notes in Sources/books/ (including 131 source-index notes)

10 unique books with persistent failures accepted as known-unfixable (content filters, oversized, persistent 503s): Ikigai, Home Comforts, beardsley-european-philosophers-descartes, chevalier-penguin-dictionary-symbols, church-catechism-catholic-church, eco-name-rose, edkinney-symposium, roshijiyu-kennett-book-life, The Count of Monte Cristo, malory-le-morte-darthur.

BBP-006 marked done. Next: BBP-007 (poetry collection validation) or project close-out.
