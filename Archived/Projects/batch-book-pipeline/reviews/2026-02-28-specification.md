---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/batch-book-pipeline/design/specification.md
artifact_type: specification
artifact_hash: 41883ebf
prompt_hash: c366407c
base_ref: null
project: batch-book-pipeline
domain: learning
skill_origin: peer-review
created: 2026-02-28
updated: 2026-02-28
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - grok/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 47957
    attempts: 1
    raw_json: Projects/batch-book-pipeline/reviews/raw/2026-02-28-specification-openai.json
  google:
    http_status: 200
    latency_ms: 41305
    attempts: 1
    raw_json: Projects/batch-book-pipeline/reviews/raw/2026-02-28-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 59223
    attempts: 2
    raw_json: Projects/batch-book-pipeline/reviews/raw/2026-02-28-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 28135
    attempts: 1
    raw_json: Projects/batch-book-pipeline/reviews/raw/2026-02-28-specification-grok.json
status: active
tags:
  - review
  - peer-review
---

# Peer Review: Batch Book Pipeline Specification

**Artifact:** Projects/batch-book-pipeline/design/specification.md
**Mode:** full
**Reviewed:** 2026-02-28
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Full specification review evaluating correctness, completeness, internal consistency, feasibility, and clarity. Findings classified by severity (CRITICAL/SIGNIFICANT/MINOR/STRENGTH) with unverifiable claim flagging.

---

## OpenAI (gpt-5.2)

- [F1]  
  - **Severity:** CRITICAL  
  - **Finding:** The spec assumes “1M token context window handles any book” and implies a PDF can be passed whole to `generate_content` reliably, but it doesn’t define a fallback strategy for books that exceed limits (token/window, page limits, file size limits) or for responses that truncate.  
  - **Why:** One outlier book (very long textbook, appendices, or image-heavy scan) can break the pipeline or silently degrade output quality. Without chunking/continuation logic, you risk incomplete notes or repeated failures late in the batch.  
  - **Fix:** Add an explicit “oversize handling” section: detect PDF page count/file size; optionally pre-extract text; chunk by chapter/page ranges; run multi-call summarization (chapter digests → consolidated digest). Add continuation logic if the model truncates (e.g., request “continue from section X” with last heading).

- [F2]  
  - **Severity:** CRITICAL  
  - **Finding:** Tagging design is internally inconsistent: BBP-003 says “model suggests `#kb/` tags; script validates against canonical list,” but the spec doesn’t define what happens when the model proposes tags not in the list (drop? map? replace with `#kb/needs_review`?), nor where the canonical list lives/how it’s versioned.  
  - **Why:** At scale, inconsistent tag outcomes will fragment the vault graph and may cause vault-check failures if tags are constrained.  
  - **Fix:** Define deterministic tag rules: (1) prompt may only choose from enumerated tags, (2) unknown tags are replaced with `#kb/needs_review`, (3) store canonical tag list in a single source of truth file and load it in the script; include it in run logs.

- [F3]  
  - **Severity:** CRITICAL  
  - **Finding:** The pipeline depends on parsing title/author from the model’s first heading (`# Title by Author`). That’s brittle (titles with “by”, subtitles, multiple authors/editors, nonstandard capitalization, or model noncompliance).  
  - **Why:** Incorrect parsing cascades into wrong `source_id`, filenames, dedup, and routing—creating duplicates and breaking referential integrity in the vault.  
  - **Fix:** Require the model to output a strict frontmatter-like block (YAML or JSON) at the top with `title`, `authors` (array), `year` (optional), `isbn` (optional), `language`, plus a `source_slug`. Validate with a JSON schema; fall back to PDF metadata extraction if model output is missing.

- [F4]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** “Dedup by source_id” is underspecified: you reference a `source_id algorithm` in `_system/docs/file-conventions.md`, but the spec doesn’t state how collisions are handled (same title different editions; same author multiple books with same title; transliteration differences).  
  - **Why:** Dedup errors either overwrite valid notes or skip books incorrectly.  
  - **Fix:** Document collision rules: include edition/year where available; if collision, append a stable suffix (e.g., `-2`, `-3`) and log it. Add a “manual review required” list when collisions occur.

- [F5]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** Cost math and tiers rely on assumptions that aren’t operationalized. The spec mentions the ≤200K token tier but doesn’t define how tokens are estimated from PDFs, nor how the script chooses model/tier per book.  
  - **Why:** You can’t control spend or avoid surprise tier jumps without preflight estimation and logging.  
  - **Fix:** Add a preflight step: estimate tokens (via text extraction + tokenizer estimate, or API-provided usage metadata after a cheap “count only” call if available). Log per-book input/output tokens and projected cost. Add a rule: books above threshold route to alternate strategy (chunking or different model).

- [F6]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** No explicit spec for rate limiting, concurrency, and quota handling (RPD/TPD), despite being a batch pipeline. Retries are mentioned but not quotas/backpressure.  
  - **Why:** Hitting quotas mid-run causes cascading failures; naïve retries can worsen throttling.  
  - **Fix:** Specify: max concurrent requests, per-minute caps, exponential backoff with jitter, and a “resume” mechanism that persists state (e.g., SQLite/JSONL). Add `--resume` and `--dry-run`.

- [F7]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** The response parsing section omits how you’ll extract and validate the body against the book-digest-v2 template (section presence/order, required headings).  
  - **Why:** Without structural validation, you’ll generate notes that “look fine” but fail downstream consistency expectations or vault-check rules.  
  - **Fix:** Create a template compliance checker: required headings list; enforce ordering; flag missing sections; optionally auto-reprompt “repair output to match template” using the model.

- [F8]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** The spec doesn’t address PDFs that are scanned images (OCR) beyond “spot-check.” There’s no automated detection or fallback OCR step.  
  - **Why:** Even a few scanned PDFs can produce hallucinated quotes, wrong attributions, and shallow structure.  
  - **Fix:** Add an automated quality gate: detect low text density / high image ratio; if scanned, route to OCR (local OCR, or a doc-ai OCR step) before summarization, or mark as “manual required.”

- [F9]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** Logging is described, but auditability is incomplete: you don’t specify capturing model version, prompt version hash, file URI, timestamps, and token usage.  
  - **Why:** When quality issues appear later, you need reproducibility and provenance to diagnose (prompt drift, model updates, partial uploads).  
  - **Fix:** Write a per-book JSONL record including: pdf path + checksum, upload file id/uri, model name, prompt hash, generation params, token usage, status, error traces, output filename.

- [F10]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** Security/privacy handling for uploading copyrighted books to an external API is not addressed (even if locally owned).  
  - **Why:** This may violate personal risk tolerance, terms, or jurisdictional constraints; it’s an essential operational consideration for a “personal OS” spec.  
  - **Fix:** Add a “Data Handling & Risk” section: confirm acceptable use; note retention policy; optional setting to delete uploaded files if the API supports it; keep keys in environment variables; redact logs.

- [F11]  
  - **Severity:** MINOR  
  - **Finding:** “No multi-model comparison needed — model decision is made” contradicts earlier “validate Flash vs Pro” framing (A1) and the inclusion of a multi-model evaluation section.  
  - **Why:** It creates ambiguity about whether Flash is still on the table and what BBP-001 is actually validating.  
  - **Fix:** Clarify decision: either (a) commit to 3.1 Pro for full run, with Flash only as a later optimization, or (b) keep A1 and explicitly compare Pro vs Flash on the same 3 books with an evaluation rubric.

- [F12]  
  - **Severity:** MINOR  
  - **Finding:** The task graph labels BBP-001 as “model eval,” but later reframes it as “template validation.”  
  - **Why:** Mislabeling can cause scope drift and wrong expectations for deliverables.  
  - **Fix:** Rename BBP-001 to “API + Template Validation (Pro baseline)” and, if needed, add BBP-001b for “Flash cost/quality probe.”

- [F13]  
  - **Severity:** MINOR  
  - **Finding:** File layout is mostly clear, but doesn’t specify naming conventions for outputs beyond “filename” and “write to Sources/books/.”  
  - **Why:** Naming consistency is key for vault navigation and dedup.  
  - **Fix:** Explicitly define filename format (e.g., `[source_id]--[slug].md`), normalization rules, and how subtitles/diacritics are handled.

- [F14]  
  - **Severity:** STRENGTH  
  - **Finding:** Strong end-to-end system map and staged rollout (3-book validation → 10-book batch → full run) with human review gates.  
  - **Why:** This reduces risk and prevents scaling a broken prompt/script across 100 books.  
  - **Fix:** None; keep the gated batching approach.

- [F15]  
  - **Severity:** STRENGTH  
  - **Finding:** Clear separation of concerns: prompt adaptation, pipeline orchestration, tagging decision, validation batch, then full execution.  
  - **Why:** Makes implementation tractable and allows focused iteration (prompt vs code vs workflow).  
  - **Fix:** None.

- [F16]  
  - **Severity:** STRENGTH  
  - **Finding:** Cost-awareness is embedded early (model options, batch discount, tiers) and tied to operational levers (batch size, model choice).  
  - **Why:** Prevents surprise spend and supports iterative optimization.  
  - **Fix:** None—just add the missing cost telemetry (see F5/F9).

---

## Unverifiable claims (flagged for grounded verification)

- [F17]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** **UNVERIFIABLE CLAIM:** “Gemini API supports native PDF upload (File API → generate_content). 1M token context window handles any book.”  
  - **Why:** Exact capabilities, limits (file size/page count), and whether “any book” fits depend on current API constraints and may differ by model/endpoint.  
  - **Fix:** Link to the exact Gemini API documentation page/version and record tested limits during BBP-001 (max PDF size/pages, observed token usage behavior).

- [F18]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** **UNVERIFIABLE CLAIM:** “NLM currently runs Gemini 3.1 Pro (upgraded from Gemini 3 in Feb 2026…).”  
  - **Why:** NotebookLM’s backing model/version is not always publicly specified and can change; relying on it as a baseline may be shaky.  
  - **Fix:** Treat NLM model identity as uncertain; define baseline empirically using stored fixture outputs and evaluate “match” against those outputs rather than assumed model parity.

- [F19]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** **UNVERIFIABLE CLAIM:** Pricing figures and the computed “cost for 100 books” totals for each model/tier.  
  - **Why:** Prices change; tiers (≤200K) and batch discounts may apply differently, and output token averages drive totals heavily.  
  - **Fix:** Reference the exact pricing source/date and compute cost from measured token usage in BBP-005; store a small cost calculator in the repo.

- [F20]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** **UNVERIFIABLE CLAIM:** “Batch API — 50% cost reduction for async processing” and that it’s “ideal for bulk runs after quality is validated,” plus uncertainty about whether it supports file inputs.  
  - **Why:** Discount amount and supported inputs are product-surface details that must be confirmed before designing around them.  
  - **Fix:** During BBP-001, explicitly test a minimal batch job with a file reference; if unsupported, remove batch dependency and design around standard API + throttling.

- [F21]  
  - **Severity:** SIGNIFICANT  
  - **Finding:** **UNVERIFIABLE CLAIM:** “Free tier daily token limits… determine whether free tier is viable.”  
  - **Why:** Free tier limits vary by account/region and change over time.  
  - **Fix:** Add a one-time “quota probe” script that reads current quota headers/limits (if exposed) or runs controlled calls and records when throttling occurs.

---

### Overall feasibility assessment (summary)
Feasible with modest engineering effort, but needs stronger robustness around: (1) metadata extraction/parsing, (2) oversize/scanned PDFs, (3) quota/rate limiting + resumability, and (4) deterministic tagging and dedup rules. The staged validation plan is a strong foundation; tightening these specifics will prevent expensive rework once 50–100 notes are generated.

---

## Google (gemini-3-pro-preview)

Here is the review of the `batch-book-pipeline` specification.

### Summary
The specification is logically sound and well-structured, providing a clear path from problem to solution. The decomposition of tasks is granular and risk-aware, particularly the "Validation Batch" (BBP-005) prior to the full run.

However, the specification relies heavily on **future-dated/unverifiable model versions ("Gemini 3.1 Pro")**. If this project is intended for execution *now*, these model references are incorrect (current versions are 1.5 or 2.0) and the pricing/capabilities calculations may be invalid. If this is a futuristic simulation, the internal logic holds, but the reliance on specific unverified pricing tiers remains a risk.

### Findings

#### [F1]
**Severity:** CRITICAL
**Finding:** UNVERIFIABLE CLAIM: References to "Gemini 3.1 Pro" and "Gemini 3 Flash".
**Why:** The specification dates the project to Feb 2026 and references "Gemini 3.1 Pro" and "Gemini 3 Flash" as available APIs. As of current verifiable data, the active models are the Gemini 1.5 and 2.0 families.
**Impact:**
1.  **API Failure:** Code referencing `model="gemini-3.1-pro"` will likely fail if the SDK expects current model names (e.g., `gemini-1.5-pro`).
2.  **Cost Calculation:** The budget estimate ($29.60) is based on specific pricing ($2.00/1M input) that cannot be verified against current public pricing tables. If the user intends to use Gemini 1.5 Pro, the pricing differs (approx. $3.50/1M input for <128k context), potentially doubling the budget.
**Fix:** Verify the actual model string available in the `google-generativeai` SDK. If this is a real-world project, update references to `gemini-1.5-pro` or `gemini-2.0-flash` and recalculate costs based on current official pricing.

#### [F2]
**Severity:** SIGNIFICANT
**Finding:** Deduplication relies on non-deterministic LLM output.
**Why:** Task BBP-003 states the script "Checks each against Sources/books/ ... (dedup by source_id)" and later "Generates metadata: source_id (from author + title)". The `source_id` is derived *after* the LLM extracts the title/author. If the LLM generates slightly different text for the same book on a second run (e.g., "The Hobbit" vs "Hobbit, The"), the calculated `source_id` will differ, causing the script to treat it as a new book and fail to deduplicate.
**Fix:** Implement deduplication based on the **input file** (PDF) rather than the output.
1.  Calculate an MD5/SHA256 hash of each PDF file.
2.  Maintain a `manifest.json` mapping `file_hash` -> `processed_status`.
3.  Check the hash before calling the API.

#### [F3]
**Severity:** SIGNIFICANT
**Finding:** Uncertainty regarding Batch API compatibility with File API (Ref: Open Question 1).
**Why:** The spec hopes to use Batch API for cost savings (BBP-006). Historically, the Gemini Batch API requires inputs to be stored in Google Cloud Storage (GCS) buckets with specific URIs (`gs://`), whereas the standard `generate_content` can use the ephemeral File API (`files.upload`). It is unconfirmed if the Batch API accepts File API URIs.
**Fix:** Prioritize checking this in BBP-001. If Batch requires GCS, the pipeline complexity increases (need GCS bucket management + authentication), or the "Batch" approach must be abandoned for the standard API with rate limiting.

#### [F4]
**Severity:** MINOR
**Finding:** Missing explicit handling for "Unreadable/Corrupt PDFs".
**Why:** BBP-003 mentions error handling for API failures. It does not explicitly address PDFs that are technically valid files but contain no extractable text (image-only scans without OCR) or are corrupt. Sending these to the model often results in hallucinations or "I cannot read this" responses which still cost tokens.
**Fix:** Add a pre-flight check in the script using a lightweight library (like `pypdf`) to verify the PDF contains extractable text strings before uploading to Gemini.

#### [F5]
**Severity:** MINOR
**Finding:** Ambiguity in "Vault Compliance" check.
**Why:** Constraint C3 mentions "every output must pass vault-check". It is unclear if `vault-check` is an automated linting script or a manual checklist. If it's manual, 100 books is a high load.
**Fix:** Clarify in BBP-003 if the Python script should import and run the `vault-check` logic programmatically to fail fast if the schema is wrong.

#### [F6]
**Severity:** STRENGTH
**Finding:** Robust Evaluation Strategy (BBP-001 & BBP-005).
**Why:** The decision to run a "Validation Batch" of 10 books (BBP-005) before the full run is excellent. It mitigates the risk of systematic prompt errors polluting the vault with 100 bad files.

#### [F7]
**Severity:** STRENGTH
**Finding:** Clear "Facts vs Assumptions" delineation.
**Why:** Explicitly calling out the token count per book (U1) and prompt adaptability (A3) as unknowns/assumptions allows for targeted validation tasks.

### Recommendations

1.  **Resolve Model Reality:** Confirm if "Gemini 3.1 Pro" is the intended target. If this is a typo for 1.5 Pro, update cost estimates to ~$50-60.
2.  **Harden Deduplication:** Modify BBP-003 to track processed files by file hash, not just derived `source_id`.
3.  **Pre-flight Check:** Add a text-extraction check to BBP-003 to skip image-only PDFs before incurring API costs.
4.  **Batch API Test:** Move the Batch API capability test from "Open Questions" to a concrete sub-task in BBP-001 to determine architectural requirements (GCS vs File API) early.

---

## DeepSeek (deepseek-reasoner)

Here is a structured review of the provided specification artifact.

### **FINDINGS**

**F1**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: The specification states factual details about Google's Gemini API features and pricing (e.g., "Gemini API supports native PDF upload," "Gemini 3.1 Pro has no free API tier," specific pricing per 1M tokens). It also makes claims about NotebookLM's model usage ("NLM currently runs Gemini 3.1 Pro (upgraded Feb 2026)"). These are subject to change by the provider.
- **Why:** Basing a technical and financial plan on unverified external API details risks feasibility and cost calculations.
- **Fix:** Flag these as assumptions requiring verification via current official Google AI documentation and API reference before implementation. Update the "Facts" and cost table accordingly.

**F2**
- **Severity:** CRITICAL
- **Finding:** Contradiction between primary constraint and model selection. Constraint C1 is "Cost — user wants to minimize spend." However, the Model Evaluation section recommends "Gemini 3.1 Pro" as the primary model, which is the most expensive option considered (~$29.60), stating the cost is "negligible." This directly conflicts with the stated constraint.
- **Why:** The core driver of the project (minimize spend) is overridden by a secondary concern (eliminate quality risk) without clear justification or decision logic. This undermines the project's goals.
- **Fix:** Reconcile this conflict. Either amend Constraint C1 to reflect a priority on guaranteed quality over minimal cost, or restructure the model evaluation to prioritize the cost-effective option (Gemini 3 Flash) as the primary target, with a clear validation plan (BBP-001) to ensure it meets quality needs.

**F3**
- **Severity:** SIGNIFICANT
- **Finding:** Key technical feasibility assumption is flagged for validation but lacks a concrete verification step. Assumption A4 ("PDF quality is sufficient") is critical for pipeline success, and Unknown U1 ("Exact token counts") impacts cost. The task decomposition does not include specific tasks to address these.
- **Why:** Processing 100 books with poor OCR could fail silently or produce low-quality output. Unexpectedly large books could breach the 1M token context window or cause significant cost overruns.
- **Fix:** Add two preliminary tasks to the PLAN or ACT phase:
    1.  **PDF Quality & Token Sampling:** Write a small script to sample 10-15 PDFs, extracting word count, estimating tokens, and performing a basic scan/OCR detection (e.g., by analyzing font embedding). This validates A4 and provides data for U1.
    2.  **Batch API Feasibility:** Explicitly task the research in BBP-001 to answer Open Question #1 regarding Batch API support for PDFs, as it determines the final cost structure.

**F4**
- **Severity:** SIGNIFICANT
- **Finding:** The tag assignment strategy (BBP-004) is under-specified and its acceptance criteria are vague. The proposed options range from fully automated to fully manual, with a "false tag rate acceptable (<20%)" metric that is arbitrary.
- **Why:** Inconsistent or inaccurate tagging at scale will pollute the knowledge graph and create significant cleanup work downstream, negating some benefits of automation.
- **Fix:** Define a more robust strategy. Recommendation: Implement a hybrid approach in BBP-003/BBP-004: The prompt asks the model to suggest 3-5 tags *from the provided canonical list*. The script logs these. All generated notes are also tagged with `#kb/needs-review/tags`. This automates initial assignment while mandating a systematic, batch-level human review pass as part of BBP-005 and BBP-006.

**F5**
- **Severity:** MINOR
- **Finding:** The specification defers the creation of "source index notes" (Open Question #4) without a recommendation. This creates a potential gap in the vault's file convention compliance.
- **Why:** While not blocking the core processing, leaving this unresolved ensures the output will be incomplete according to the established `_system/docs/file-conventions.md`, requiring another pass.
- **Fix:** Make a decision. Given the batch nature, recommend a follow-up, separate script (`generate-source-indexes.py`) that runs after the main pipeline, reading the `source_id` from the generated notes and creating the index files. Mention this as a "Post-Pipeline" task in the spec.

**F6**
- **Severity:** MINOR
- **Finding:** The specification mentions "rate limiting" for the API (in BBP-006) but does not define what those limits are or propose a retry/backoff strategy, only "Error handling for API failures" in BBP-003.
- **Why:** Without considering Google's rate limits (requests per minute), a naive sequential processing of 90 books may hit quota errors and fail.
- **Fix:** In BBP-003's acceptance criteria, specify that the script must implement exponential backoff and retry for common API errors (429, 5xx). Research and document the relevant Gemini API quotas in the run-log during BBP-001.

**F7**
- **Severity:** STRENGTH
- **Finding:** The specification is exceptionally well-structured and comprehensive. It clearly defines the problem, separates facts from assumptions, maps the system, evaluates options with clear reasoning, and decomposes work into actionable, dependency-linked tasks.
- **Why:** This level of detail drastically reduces project risk, facilitates clear communication, and provides a solid blueprint for implementation. The explicit "Why This Matters" section strongly justifies the project's value.

**F8**
- **Severity:** STRENGTH
- **Finding:** The consideration of second-order effects (MOC updates, tag graph expansion, reusability for other sources) demonstrates excellent systems thinking.
- **Why:** It shows the author is planning not just for the immediate task but for the health and evolution of the broader knowledge system, preventing downstream surprises.

**F9**
- **Severity:** STRENGTH
- **Finding:** The "batched review" constraint (C4) and its implementation in the task workflow (BBP-005, BBP-006) appropriately balances automation with necessary human oversight for quality control.
- **Why:** This is a prudent approach for a bulk operation with uncertain inputs (book quality/variety), preventing a full batch failure and allowing for mid-course corrections.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: Task dependency graph labels BBP-001 as "(model eval)", but the Model Evaluation section explicitly states "No multi-model comparison needed — model decision is made" and redefines BBP-001 as "template validation task"; BBP-001 description focuses solely on prompt/API validation with fixed Gemini 3.1 Pro, not model comparison.
- [Why]: Creates confusion about task purpose and scope; risks misprioritization or redundant work if reader assumes model shootout is required.
- [Fix]: Update dependency graph label to "(prompt/API validation)" and remove any lingering "model eval" references.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Deduplication logic in BBP-003 (step 2: "Checks each against Sources/books/ for existing knowledge notes (dedup by source_id)") precedes PDF upload and model inference, but source_id is generated later (step 6: "from author + title" extracted from model response in step 5).
- [Why]: Impossible to compute source_id for dedup without first processing the PDF via API (incurring cost/time), creating a logical deadlock; if filenames encode author/title reliably, it's unstated, risking reprocessing.
- [Fix]: Clarify dedup method: e.g., derive tentative source_id from PDF filename (assume convention like "Author_Title.pdf"), or move dedup after extraction (accept cost for potential dups).

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Tag assignment in BBP-003 (step 7: "Suggests #kb/ tags (model suggests, script validates against canonical list)") assumes a "canonical #kb/ tag list" exists and is accessible, but it's only vaguely referenced ("canonical #kb/ tag list" in Dependencies, "short (~15 tags)" in BBP-004); no location or format specified.
- [Why]: Blocks implementation; script can't validate without the list embedded, loaded from file, or prompted—risks halting BBP-003.
- [Fix]: Specify list location (e.g., `_system/docs/kb-tags.md`) and loading method (e.g., "load from YAML file in script dir"); include sample in spec.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: All Gemini model details (e.g., F5/F7: Gemini 3.1 Pro/Flash availability, 1M context, native PDF via File API; pricing tiers like $2.00/1M input for 3.1 Pro; NLM upgrade to 3.1 Pro in Feb 2026; batch API file support TBD in U2; cost estimates like ~$29.60 for 100 books).
- [Why]: Spec relies heavily on unconfirmed future (2026) API/model specs/pricing; current (2024) Gemini is 1.5/2.0 series—wrong assumptions derail feasibility/cost planning.
- [Fix]: Move all to Assumptions/Unknowns; add BBP-0XX task for real-time API docs check (e.g., via SDK introspection or docs.gemini.google.com).

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Cost summary table and per-model pricing (e.g., Gemini 3 Flash $0.50/1M input standard vs. batch TBD; 2.5 Flash batch $0.15/1M; avg 130K input/3K output tokens per book).
- [Why]: Projections based on hypothetical 2026 pricing/token counts; actual costs could be 2-10x off, violating C1 (minimize spend) and feasibility.
- [Fix]: Add token estimation script/task (BBP-0XX: sample 10 PDFs via SDK token_count); flag pricing as "2026-estimated—revalidate at runtime".

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: BBP-003 assumes response parsing (step 5: "extracts title + author from `# Title by Author` heading") will always succeed, but relies on BBP-002's prompt adaptation (explicit instruction added); no fallback if model deviates (e.g., formats differently).
- [Why]: Single point of failure for entire pipeline—bad parse blocks metadata/file write, halting batch.
- [Fix]: Add robust parsing (e.g., regex + LLM fallback query on response for title/author); test edge cases in BBP-001/003 AC.

- [F7]
- [Severity]: MINOR
- [Finding]: Assumptions A2/A4 (books <200K tokens; PDFs not OCR-degraded) marked for validation ("by sampling/spot-check"), but no dedicated task owns this (BBP-001 is prompt-focused).
- [Why]: Risks surprise tier jumps/costs or parsing failures mid-batch (BBP-006).
- [Fix]: Fold into BBP-001 AC or add BBP-0XX pre-scan task (token count + PDF quality check via SDK).

- [F8]
- [Severity]: MINOR
- [Finding]: Open Question 3 (fiction detection) flags potential scope creep but notes "user chose book-digest-v2 for all"; no resolution or decision in BBP-004 (tags) or elsewhere.
- [Why]: ~100 books likely include fiction; mismatched template degrades quality, undermining C2.
- [Fix]: Resolve in BBP-004 or new #decision task: e.g., "pre-classify genre via cheap Flash query; route to fiction-digest-v1 if detected".

- [F9]
- [Severity]: MINOR
- [Finding]: Constraints C4/C5 mention "batched review" and "no sentinel markers", but BBP-005/006 AC lack explicit user approval step (e.g., "pause script until manual confirm").
- [Why]: Script may overrun batches without review, risking unvetted low-quality outputs in vault.
- [Fix]: Add to BBP-003/006 AC: "script pauses after batch_size, prompts for user input/approval before next".

- [F10]
- [Severity]: MINOR
- [Finding]: Second-Order Effects note source index notes/MOC updates deferred, but no tasks for them despite expanding graph surfacing "gaps in canonical tag list".
- [Why]: Leaves downstream vault integration incomplete; user must manually fix post-BBP-006.
- [Fix]: Add BBP-007: "#maintenance task for index/MOC updates".

- [F11]
- [Severity]: STRENGTH
- [Finding]: Clear separation of Facts/Assumptions/Unknowns, with validation owners (e.g., A1 in BBP-001, A3 in BBP-002).
- [Why]: Builds trust in planning; reduces risk by front-loading validations.
- [Fix]: N/A

- [F12]
- [Severity]: STRENGTH
- [Finding]: Comprehensive task decomposition with types (#research/#writing/etc.), risks, AC, file changes, and deps graph—aligns well with stated Workflow (SPECIFY→PLAN→ACT).
- [Why]: Makes execution straightforward; low cognitive load for implementer.
- [Fix]: N/A

- [F13]
- [Severity]: STRENGTH
- [Finding]: System Map diagram and Components/Dependencies/Levers/Constraints structure provide holistic view without overload.
- [Why]: Excellent for feasibility assessment; highlights cost/quality tradeoffs explicitly.
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Title/author parsing is brittle (OAI-F3 CRITICAL, GRK-F6 SIGNIFICANT)**
Parsing `# Title by Author` from model output is a single point of failure. Titles containing "by", multiple authors, subtitles, and non-compliance all break the pipeline. Two reviewers converge: need structured metadata extraction with fallback.

**2. Dedup logic has ordering and robustness issues (OAI-F4, GEM-F2, GRK-F2 — all SIGNIFICANT)**
Three reviewers flag distinct dedup problems: (a) source_id derived from non-deterministic LLM output (Gemini), (b) dedup check precedes source_id computation in the task steps (Grok), (c) collision handling underspecified (OpenAI). All three point to the same root cause: dedup can't rely solely on model-extracted metadata.

**3. Tag strategy is underspecified (OAI-F2 CRITICAL, DS-F4 SIGNIFICANT, GRK-F3 SIGNIFICANT)**
Three reviewers flag that "model suggests, script validates" lacks concrete rules: what happens when the model proposes non-canonical tags, where the canonical list is loaded from, and what the fallback is. The canonical list exists in `_system/docs/file-conventions.md` and CLAUDE.md but the spec doesn't reference its location for the script.

**4. PDF quality/OCR pre-flight (OAI-F8, GEM-F4, DS-F3, GRK-F7 — all 4 reviewers)**
Universal concern: scanned/image-only PDFs will produce hallucinated output at full API cost. Consensus: add a lightweight pre-flight check (text extraction test via pypdf or similar) before uploading.

**5. Pricing and model version claims (OAI-F17-21, GEM-F1, DS-F1, GRK-F4-5 — all 4 reviewers)**
All four flag pricing figures and model versions as unverifiable. However: pricing was web-verified from the official Google AI pricing page during this session, and NLM's Gemini 3.1 Pro upgrade was confirmed via 9to5Google (Feb 20, 2026). These are verified facts, not assumptions — but subject to change. See "Considered and Declined" below.

**6. Task graph mislabeling (OAI-F11-12 MINOR, GRK-F1 SIGNIFICANT)**
Two reviewers flag that BBP-001 is labeled "model eval" in the dependency graph but the body says "prompt + API validation." Inconsistency from the mid-spec pivot when the user committed to 3.1 Pro.

### Unique Findings

**OAI-F1 (CRITICAL): Oversize book handling** — No fallback for books exceeding the 1M token window or producing truncated responses. Genuine insight — the spec assumes "1M handles any book" but image-heavy or very long reference works could challenge this. Worth addressing.

**OAI-F6 (SIGNIFICANT): Rate limiting / quota handling** — No concurrency, backoff, or resume mechanism specified. Valid for a batch pipeline processing 100 sequential API calls. Should add basic resilience.

**OAI-F9 (SIGNIFICANT): Per-book audit logging** — No structured per-book telemetry (tokens, cost, model version, prompt hash). Valid — needed for cost tracking and debugging quality issues post-run.

**OAI-F10 (SIGNIFICANT): Copyright/privacy** — Uploading copyrighted books to external API. Low signal for a personal-use pipeline with locally-owned PDFs, but worth a one-line acknowledgment.

**OAI-F7 (SIGNIFICANT): Response structural validation** — No check that output contains required headings from the template. Valid but can be addressed during manual review (BBP-005) rather than automated validation.

**DS-F2 (CRITICAL): Cost constraint contradiction** — C1 says "minimize spend" but recommendation is the most expensive option. See "Considered and Declined."

**GRK-F8 (MINOR): Fiction detection** — Some of the ~100 books may be fiction, making book-digest-v2 suboptimal. Already in open questions. User explicitly chose book-digest-v2 for all.

### Contradictions

**DS-F2 vs. spec recommendation:** DeepSeek calls the Gemini 3.1 Pro choice a contradiction with C1 ("minimize spend"). The user explicitly chose 3.1 Pro after seeing the full cost analysis, saying "$30 is fine for assured quality." This is a resolved user decision, not a spec contradiction. C1 should be updated to reflect "quality-assured at reasonable cost" rather than "minimize spend."

**GEM-F1 vs. spec facts:** Gemini reviewer believes the model versions are wrong (thinks current models are 1.5/2.0 series). This is a reviewer knowledge cutoff issue — we web-verified Gemini 3.1 Pro availability and pricing during this session. Not a spec error.

### Action Items

**Must-fix:**

- **A1** (OAI-F3, GRK-F6): **Harden title/author extraction.** Add a structured metadata block to the prompt — ask the model to output title, author, and suggested source_id in a parseable format (YAML or JSON) before the digest body. Add regex fallback + PDF filename as last resort.

- **A2** (OAI-F2, DS-F4, GRK-F3): **Concretize tag strategy.** Embed the canonical `#kb/` tag list directly in the prompt. Model picks from the list only. Script validates; unknown tags replaced with `needs_review`. Specify the canonical list source (`_system/docs/file-conventions.md`).

- **A3** (OAI-F4, GEM-F2, GRK-F2): **Fix dedup approach.** Primary dedup on PDF file hash (input-side, before API call). Secondary dedup on source_id after extraction (catches re-runs with different PDFs of the same book). Maintain a JSONL manifest mapping file_hash → source_id → output_path → status.

- **A4** (OAI-F13 + user request): **Define file naming convention.** Book title only, all lowercase, hyphens for spaces. E.g., `franklin-d-roosevelt-and-the-new-deal.md`. Strip subtitles, articles, and special characters. Script derives filename from model-extracted title.

**Should-fix:**

- **A5** (OAI-F8, GEM-F4, DS-F3, GRK-F7): **Add PDF pre-flight check.** Use pypdf or similar to verify text extractability before uploading. Flag image-only/scanned PDFs for manual handling or OCR.

- **A6** (OAI-F6, DS-F6): **Add rate limiting + resume.** Exponential backoff with jitter for 429/5xx. Persist processing state in the JSONL manifest so `--resume` works after interruption.

- **A7** (OAI-F11-12, GRK-F1): **Fix task graph labels.** BBP-001 → "prompt/API validation" (not "model eval"). Remove stale Flash/Pro comparison language from A1 and cost constraint C1.

- **A8** (OAI-F1): **Document oversize handling.** Note that Gemini 3.1 Pro's 1M context handles ~750K words — larger than any published book. For rare edge cases (multi-volume reference works, image-heavy), flag and skip with manual fallback. No chunking pipeline needed for this corpus.

- **A9** (OAI-F9): **Add per-book JSONL telemetry.** Log: PDF path, file hash, source_id, model, prompt hash, token usage (input/output), cost, status, output path, timestamp.

**Defer:**

- **D1** (OAI-F7): Response structural validation — heading checks can be done during manual review in BBP-005. Formalize into automated validation only if systematic issues emerge.
- **D2** (DS-F5, GRK-F10): Source index note generation — defer to post-pipeline follow-up. Not blocking core pipeline.
- **D3** (GRK-F8): Fiction detection — user chose book-digest-v2 for all. Revisit only if fiction books produce notably poor output.
- **D4** (OAI-F10): Copyright/privacy acknowledgment — personal use, personal PDFs, standard API terms. Add one-line note to workflow guide if desired.
- **D5** (GRK-F9): Explicit user approval pause — the script exits after batch_size; user runs it again for next batch. This is the "batched with review" pattern. No interactive pause needed.

### Considered and Declined

- **DS-F2** (cost constraint contradiction): `incorrect` — The user explicitly chose 3.1 Pro after seeing all cost options. C1 should be updated to reflect "quality-assured at reasonable cost" rather than "minimize spend," but this is a wording fix, not a design contradiction.

- **GEM-F1** (model version reality): `incorrect` — Reviewer's knowledge cutoff predates Gemini 3.x release. Model versions and pricing were web-verified during this session from official Google sources.

- **OAI-F17-21, DS-F1, GRK-F4-5** (unverifiable pricing claims): `constraint` — All pricing figures were verified against the official Gemini API pricing page (ai.google.dev/gemini-api/docs/pricing) during this session. They are current as of 2026-02-28 and flagged in the spec as subject to change. Adding "revalidate at runtime" to the spec is reasonable (incorporated into A9 telemetry), but treating verified figures as unknowns is overcorrection.

- **GEM-F3** (Batch API + GCS requirement): `constraint` — Already captured as U2 in the spec's Unknowns section and Open Question #1. Will be resolved during implementation, not spec phase.
