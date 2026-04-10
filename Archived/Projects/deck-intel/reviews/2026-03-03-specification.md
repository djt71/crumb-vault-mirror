---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/deck-intel/specification.md
artifact_type: spec
artifact_hash: a0245ffb
prompt_hash: df3ddb49
base_ref: null
project: deck-intel
domain: software
skill_origin: peer-review
status: complete
created: 2026-03-03
updated: 2026-03-03
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
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "Tag 'customer-engagement' contains 'customer' substring (benign domain term, not PII indicator)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 44643
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-03-specification-openai.json
  google:
    http_status: 200
    latency_ms: 34295
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-03-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 80193
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-03-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 24103
    attempts: 1
    raw_json: Projects/deck-intel/reviews/raw/2026-03-03-specification-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: deck-intel specification

**Artifact:** Projects/deck-intel/specification.md
**Mode:** full
**Reviewed:** 2026-03-03
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Full specification review evaluating correctness, completeness, internal consistency, feasibility, and clarity. Findings classified by severity (CRITICAL/SIGNIFICANT/MINOR/STRENGTH). Unverifiable claims flagged.

---

## OpenAI (gpt-5.2)

- **[F1]**
  - **Severity:** CRITICAL
  - **Finding:** Output location is internally inconsistent: the system map says the knowledge note is in `Sources/other/`, but the “Facts” section says `Sources/other/` is for presentations/reports (binaries) and separately “No binary storage” says binaries are deleted.
  - **Why:** Without a single, unambiguous destination for the *knowledge note* vs. the *source file*, implementers can easily put notes in the wrong place or violate the “no binary storage” constraint.
  - **Fix:** Define two explicit, separate paths:
    - **Input:** `_inbox/` (binaries only)
    - **Output note:** e.g., `Knowledge/` or a dedicated notes folder (or explicitly confirm that `Sources/other/` is where *notes* live, and rename the folder convention/documentation accordingly)
    - **Binary retention:** none (delete after synthesis). Update the “Facts” bullet to reflect that `Sources/other/` is the correct directory for **knowledge notes derived from “other” sources**, not for storing the binaries.

- **[F2]**
  - **Severity:** CRITICAL
  - **Finding:** Deletion policy lacks a safety/verification gate (what counts as “successful synthesis” is not defined).
  - **Why:** Automatic deletion after an ambiguous “success” event risks irreversible loss when extraction is poor, schema fails vault-check, or the synthesized note misses key content (especially with image-heavy PDFs or complex PPTX).
  - **Fix:** Add explicit deletion criteria:
    1) markitdown extraction completes without error and exceeds a minimum content threshold, **and**
    2) knowledge note passes vault-check validation, **and**
    3) user is shown a short “extraction quality summary” (e.g., chars extracted, slides detected, notes detected) with an option to keep/delete.
    - Consider “soft delete” to a temporary trash folder for N days (configurable), if that doesn’t violate the “no binary storage” intent.

- **[F3]**
  - **Severity:** SIGNIFICANT
  - **Finding:** The spec references “Knowledge-note schema (spec §2.2.4)” and “vault-check validated” but does not include the minimum required frontmatter fields or a concrete example template for the expected output.
  - **Why:** Implementing the skill and testing acceptance criteria requires knowing exactly what fields are mandatory, optional, and what body sections are expected.
  - **Fix:** Include an explicit knowledge-note skeleton (frontmatter + headings) in this spec (or in DI-001 SKILL.md requirements) including:
    - required: `type: knowledge-note`, `source_type: other`, `created`, `updated`, `tags` (if required), etc.
    - optional: `campaign`, vendor/product fields (if allowed), `shelf_life` or equivalent
    - body outline and allowed variations.

- **[F4]**
  - **Severity:** SIGNIFICANT
  - **Finding:** “MOC one-liner (if kb tag has MOC)” output is underspecified (where it is written, what format, idempotency, and how it avoids duplicate insertions).
  - **Why:** Automated MOC modification is a common source of noisy diffs, duplication, and broken structure—especially when repeated across many runs.
  - **Fix:** Specify:
    - the exact target file(s) discovered via `kb-to-topic.yaml`
    - the exact insertion format (a bullet? a Dataview entry? a short sentence?)
    - idempotency rule (e.g., “do not add if link already exists”)
    - whether this step is optional or requires confirmation.

- **[F5]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Batch processing ceiling (3–5 files) is stated, but the spec doesn’t define how the skill behaves when given more (refuse, queue, partial completion, ask user to choose).
  - **Why:** In practice users will drop many files into `_inbox/`. Ambiguity can lead to context blow-ups or partial deletions without corresponding notes.
  - **Fix:** Add explicit batch behavior:
    - If >5 files: present a selection list; process first N only; leave remainder untouched in `_inbox/`.
    - Provide a per-file progress + success/failure summary and only delete per-file when that file is complete.

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Image-heavy PDF fallback is defined only by a single heuristic (“< 200 characters”) and references “Read tool’s image capability,” but the rest of the system is described as using markitdown CLI and synthesis.
  - **Why:** A single threshold can misclassify short text PDFs (e.g., executive summaries) and the toolchain boundary (CLI vs. vision extraction) affects feasibility and user expectations.
  - **Fix:** Strengthen and clarify detection + fallback:
    - Use multiple signals (character count, page count, % non-whitespace, extraction warnings).
    - Specify the exact fallback behavior: ask permission, then (a) render pages to images and OCR/vision summarize, or (b) user-provided instruction to skip.
    - Log a clear “low confidence extraction” flag in the note.

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** “Noise filtering quality” is identified as the top lever, but there are no concrete rules for what must be preserved vs. discarded, nor a definition of “marketing noise.”
  - **Why:** The core value proposition depends on consistent filtering. Without guardrails, notes will vary widely and may omit critical caveats, limitations, or competitive claims.
  - **Fix:** Add a short policy section (even bullet rules), e.g.:
    - Preserve: architectures, requirements, integrations, constraints, pricing signals, roadmaps (flag as tentative), benchmarks with methodology, security/compliance specifics, differentiators with evidence.
    - Discard or downweight: slogans, generic benefits, customer logos without details, unquantified superlatives.
    - Always tag “Claim vs. Evidence” and extract “Proof points” separately.

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** “Shelf Life section” is emphasized, but the spec doesn’t define the expected output format (date, confidence, review interval, triggers) or how it is derived.
  - **Why:** Shelf life is only useful if it yields actionable review behavior (e.g., “re-validate after X” or “expires on Y”).
  - **Fix:** Define a standard shelf-life block, for example:
    - `Shelf life: 6–12 months (confidence: medium)`
    - `Recheck triggers: pricing, roadmap dates, GA/preview labels, partner program changes`
    - `Next review: YYYY-MM-DD`

- **[F9]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Acceptance criteria require “Noise filtering produces meaningfully shorter output than input,” but “meaningfully shorter” is not measurable.
  - **Why:** Non-measurable criteria lead to inconsistent testing outcomes and disputes during validation.
  - **Fix:** Add measurable heuristics (guidelines are fine):
    - e.g., “final note body ≤ 20–30% of extracted text length” OR “≤ X words per 10 slides,” with exceptions for deeply technical decks.

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Cross-references between related sources are requested in DI-005 (“Cross-references noted when sources overlap”), but there is no spec for how overlap is detected (title similarity? vendor? shared #kb tags?) and where cross-references appear.
  - **Why:** Without a defined method, this becomes ad hoc and may not be implementable reliably.
  - **Fix:** Specify:
    - Overlap signals (same vendor/product name, shared key terms, shared extracted headings, shared #kb tags)
    - Cross-reference format (e.g., “Related notes” section with wikilinks)
    - Optional vs. required behavior in batch mode.

- **[F11]**
  - **Severity:** MINOR
  - **Finding:** “exiftool is available but not needed” is fine, but the spec doesn’t address extracting basic document metadata that could improve retrieval (title, vendor, date, version) even if not using exiftool.
  - **Why:** Minimal metadata can materially improve search and shelf-life reasoning without storing binaries.
  - **Fix:** Add optional lightweight metadata extraction from markitdown output or filename conventions (document title, detected company names, stated date/version). Keep exiftool optional.

- **[F12]**
  - **Severity:** MINOR
  - **Finding:** Unknown U3 (“Sources/other/ will become crowded”) is raised, but the design simultaneously says navigation relies on tags/search—these positions aren’t reconciled.
  - **Why:** It’s not wrong, but it creates uncertainty on whether folder structure is expected to remain flat or evolve.
  - **Fix:** Decide and document a policy:
    - Either commit to flat + tags, or define a future convention (e.g., `Sources/other/{vendor}/{yyyy}/`) and explicitly defer it until threshold.

- **[F13]**
  - **Severity:** MINOR
  - **Finding:** D1 “campaign: [name]” says “Campaign names are freeform strings,” but frontmatter example suggests a scalar while brackets imply list syntax.
  - **Why:** Dataview/querying and schema validation may differ for scalar vs. list.
  - **Fix:** Choose one:
    - `campaign: sase-competitive-q2-2026` (scalar) or
    - `campaign: [sase-competitive-q2-2026, ...]` (list)
    - Document the chosen type and how multiple campaigns are handled.

- **[F14]**
  - **Severity:** STRENGTH
  - **Finding:** Clear separation from inbox-processor (cataloging) and feed pipeline (signal notes) with crisp boundaries: deck-intel synthesizes and deletes.
  - **Why:** Prevents tool overlap and keeps user intent explicit, reducing accidental destructive behavior (assuming F2’s safety gate is added).
  - **Fix:** None.

- **[F15]**
  - **Severity:** STRENGTH
  - **Finding:** Good decision coverage (D1–D6) for early-stage implementation, including model tier selection and explicit handling of image-heavy PDFs.
  - **Why:** These are the right “sharp edges” to decide early; they’ll drive user trust and repeat usage.
  - **Fix:** None.

- **[F16]**
  - **Severity:** STRENGTH
  - **Finding:** Task decomposition is pragmatic and test-driven (real PPTX, real PDF, then batch), with acceptance criteria tied to vault-check and extraction quality.
  - **Why:** Ingestion pipelines fail in real-world documents; the staged validation approach reduces risk.
  - **Fix:** Add explicit negative-path tests (failed extraction, vault-check failure) to complete the test story.

- **[F17]**
  - **Severity:** SIGNIFICANT
  - **Finding:** UNVERIFIABLE CLAIM: “markitdown is available and extracts text + speaker notes from PPTX and text from PDF. Already used by inbox-processor.”
  - **Why:** Availability and capability (especially speaker notes extraction) can vary by version/configuration; this materially affects feasibility.
  - **Fix:** Confirm in-repo/tooling documentation:
    - exact markitdown version/CLI invocation
    - a captured sample output showing speaker notes extraction working
    - document limitations (SmartArt, charts, embedded objects).

- **[F18]**
  - **Severity:** SIGNIFICANT
  - **Finding:** UNVERIFIABLE CLAIM: “Knowledge-note schema (spec §2.2.4) … Well-defined, vault-check validated.”
  - **Why:** Reviewers cannot confirm required fields/structure, and implementers may not have the spec in context.
  - **Fix:** Inline the essential schema requirements or link to an internal canonical location (and include a minimal excerpt in this doc).

- **[F19]**
  - **Severity:** SIGNIFICANT
  - **Finding:** UNVERIFIABLE CLAIM: “kb-to-topic.yaml provides MOC routing from #kb/ tags to domain MOCs.”
  - **Why:** The success of the MOC one-liner step depends entirely on the file’s format and stability.
  - **Fix:** Add a small illustrative snippet of `kb-to-topic.yaml` format and an example mapping (`#kb/vendor/infoblox -> MOC path`), plus failure behavior when no mapping exists.

- **[F20]**
  - **Severity:** SIGNIFICANT
  - **Finding:** UNVERIFIABLE CLAIM: “Sources/other/ is the correct directory for presentations and reports (source_type: other).”
  - **Why:** Folder conventions are central to automation; if this is wrong, the skill will scatter artifacts or fail vault-check expectations.
  - **Fix:** Cite the canonical vault convention doc or add a short “Vault paths” section enumerating expected directories for: binaries (if any), knowledge notes, and MOCs.

Overall, the spec is directionally solid and implementable, but it needs a tighter contract around **paths**, **schema/template**, and **safe deletion criteria** to avoid the two biggest risks: (1) producing non-compliant notes and (2) deleting source files prematurely.

---

## Google (gemini-3-pro-preview)

Here is the structured review of the **Deck Intel** specification.

### General Assessment
The specification is well-structured and clearly defines a specific gap in the current knowledge management workflow: the loss of actionable intelligence trapped in presentation formats. The distinction between `inbox-processor` (cataloging) and `deck-intel` (synthesis) is a strong architectural decision that prevents scope creep. The logic for using `markitdown` and deleting source binaries is bold but justifiable given the "recoverable from source" assumption.

However, there is a significant operational risk regarding the interaction between this manual tool and the automated `inbox-processor`, as well as safety rails for the "delete binary" action.

---

### Findings

#### [F1] [SIGNIFICANT] [Race Condition with Inbox-Processor]
**Finding:** The system map places input files in `_inbox/`. The "Relationship to Existing Systems" section states `inbox-processor` also handles these file types but for a different purpose. The spec does not define how to prevent `inbox-processor` from automatically consuming a deck intended for `deck-intel` before the user invokes the skill.
**Why:** If `inbox-processor` runs on a schedule or watcher, it may ingest, move, or process the file into a generic companion note before `deck-intel` can be run, breaking the workflow.
**Fix:** Define a sub-directory (e.g., `_inbox/intel/`) or a naming convention that exempts files from `inbox-processor`, or explicitly state that `deck-intel` accepts file paths as arguments regardless of location.

#### [F2] [SIGNIFICANT] [Safety of Binary Deletion]
**Finding:** The workflow specifies "Source binary deleted" immediately after synthesis (D2). While the assumption (A4) is that files are recoverable, immediate deletion prevents verifying that the extraction/synthesis was successful. If `markitdown` fails silently or the LLM hallucinates, the local copy is gone, forcing a context switch to retrieve the original.
**Why:** Reduces trust in the tool. If a user runs a batch of 5 files and 1 fails, they have to re-download the file.
**Fix:** Change the final step from `delete` to `move to _trash/` or `_processed/`. Allow the user to empty the trash later, or rely on system trash which allows undo.

#### [F3] [SIGNIFICANT] [UNVERIFIABLE CLAIM: Schema & User Data]
**Finding:** The specification references specific internal documents and user statistics that cannot be independently verified.
1. "Danny processes... ~25 accounts."
2. "Knowledge-note schema (spec §2.2.4)"
3. "Sources/other/ is the correct directory"
**Why:** The review cannot confirm if "spec §2.2.4" actually supports the output format defined, or if the directory structure exists.
**Fix:** Validate these references against the actual file system and governance documents during the **DI-001** (Build) phase.

#### [F4] [MINOR] [Filename Generation Strategy]
**Finding:** The spec details the output directory and schema, but does not specify how the knowledge note filename is generated.
**Why:** PPTX filenames are often messy (e.g., `Q3_Update_FINAL_v2.pptx`). A knowledge note requires a clean, canonical filename (e.g., `YYYY-MM-DD - Vendor Name - Topic`). Without a naming strategy, the output directory will become messy.
**Fix:** Add a logic step: "LLM suggests canonical title during synthesis; script normalizes this to a filesystem-safe filename."

#### [F5] [MINOR] [Image Fallback Implementation Detail]
**Finding:** Design Decision D6 mentions flagging "minimal text (< 200 characters)" in PDFs. It implies an interactive prompt ("Flag to user").
**Why:** If the tool is intended for batch processing (Assumptions U2, Constraints "Batch processing"), interactive prompts break the flow. The script would hang waiting for input on file #2 of 5.
**Fix:** In batch mode, skip problematic files and report them in a summary at the end, rather than blocking execution for a prompt.

#### [F6] [STRENGTH] [Clear Separation of Concerns]
**Finding:** The distinction between `inbox-processor` (binary management/cataloging) and `deck-intel` (knowledge synthesis) is clearly articulated.
**Why:** This prevents "tool bloat" and ensures `deck-intel` can focus purely on expensive reasoning tasks without needing to handle generic file routing logic.

#### [F7] [STRENGTH] [Campaign Frontmatter Decision]
**Finding:** Decision D1 (tracking campaigns via optional frontmatter rather than tags) is a high-value architectural choice.
**Why:** It keeps the global tag taxonomy clean while allowing temporary, high-granularity grouping for specific work projects (Dataview queryable). This fits the "ephemeral" nature of campaigns versus the "durable" nature of knowledge.

### Verification Checklist for Implementation
- [ ] Confirm `inbox-processor` ignore rules to allow files to sit in `_inbox/` for `deck-intel`.
- [ ] Verify `markitdown` handles speaker notes in the specific template formats used by "Infoblox" (Unknown U1).
- [ ] Confirm the target directory `Sources/other/` exists.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of "deck-intel" Specification**

**Overall Assessment:** The specification is well-structured, demonstrates clear problem-solution fit, and shows thoughtful integration with the existing Crumb knowledge system. The design decisions are logically sound and the scope is appropriately bounded. Several critical feasibility and risk items require resolution.

**Findings:**

- **[F1]**
    - **Severity:** CRITICAL
    - **Finding:** The specification mandates deletion of source binaries after synthesis but provides no recovery mechanism for a failed or erroneous synthesis. If markitdown extraction is poor or the model synthesis hallucinates, the original data is permanently lost from the working environment (`_inbox/`).
    - **Why:** This is a data loss risk. The assumption (A4) that the original is "available from the source" may not hold if the user has already deleted the email or lost portal access. The workflow lacks resilience.
    - **Fix:** Implement a two-stage deletion: move the source binary to a `_inbox/archive/` or `_inbox/processed/` directory upon *successful* note creation. A separate, periodic cleanup skill can later purge the archive. Or, add a confirmation step: "Synthesis complete. Delete source binary [Y/N]?"

- **[F2]**
    - **Severity:** SIGNIFICANT
    - **Finding:** The validation tasks (DI-003, DI-004) are categorized as `#code`. They are acceptance tests, not code implementation tasks. This misclassification could lead to confusion in project tracking.
    - **Why:** Clarity in task decomposition is essential for correct prioritization and assignment. Validation tasks typically belong to a `#test` or `#validate` type.
    - **Fix:** Change the **Type** for DI-003, DI-004, and DI-005 from `#code` to `#test`.

- **[F3]**
    - **Severity:** SIGNIFICANT
    - **Finding:** Assumption A2 ("Speaker notes... contain higher-value content") is presented as a universal truth for validation. However, D6 and the system design do not describe a mechanism to *weight* speaker notes more heavily than slide body text during synthesis.
    - **Why:** If this assumption is key to quality, the synthesis prompt/algorithm must explicitly prioritize content extracted from notes. The spec leaves this implementation detail unresolved.
    - **Fix:** In the PLAN or IMPLEMENT phase, define the synthesis directive: "When synthesizing from PPTX, prioritize insights from extracted speaker notes, using slide body text as secondary context."

- **[F4]**
    - **Severity:** SIGNIFICANT
    - **Finding:** The batch processing ceiling of "3-5 files per session" (Constraints, Task DI-005) is arbitrary. It is not derived from a defined context window size or measured token consumption.
    - **Why:** This is a feasibility constraint. Without tying it to a measurable limit (e.g., total token input < 80% of context window), it may be too conservative or too aggressive, leading to wasted capacity or failed processing.
    - **Fix:** In the PLAN phase, calculate a data-driven ceiling. Example: `(Context Window - Output Buffer) / (Avg. Token Count per Deck Extraction)`. Set the initial conservative limit based on this calculation and note it as a configurable lever.

- **[F5]**
    - **Severity:** SIGNIFICANT
    - **Finding:** The relationship to MOC routing is ambiguous. The System Map shows "MOC one-liner (if kb tag has MOC)," but the process for creating this one-liner is not specified in the Task Decomposition.
    - **Why:** The `kb-to-topic.yaml` routing is mentioned as a component, but the skill's responsibility—whether it appends a note to an MOC or just tags the note for later manual inclusion—is unclear. This is a gap in the output specification.
    - **Fix:** Clarify in D1-D6 or Task DI-001: "The skill will append a one-line summary of the knowledge note to the MOC file specified by `kb-to-topic.yaml` mapping for the primary `#kb/` tag."

- **[F6]**
    - **Severity:** MINOR
    - **Finding:** The "Shelf Life section" is noted as a key lever, but its required content format is undefined. Is it a duration (e.g., "6 months"), a date (e.g., "2026-09-01"), or a descriptive statement (e.g., "Until next product launch")?
    - **Why:** Inconsistency in this field will reduce its utility for Dataview queries or automated alerting on stale intelligence.
    - **Fix:** Define a standard in the SKILL.md (DI-001). Recommend: a **duration string** (e.g., `shelf_life: 90d`) or an **explicit expiry date** in frontmatter.

- **[F7]**
    - **Severity:** STRENGTH
    - **Finding:** The distinction between `deck-intel` (synthesis) and `inbox-processor` (cataloging) is exceptionally clear and well-justified. This prevents scope creep and user confusion.
    - **Why:** It cleanly separates two fundamentally different user intents: "file this" vs. "learn from this."

- **[F8]**
    - **Severity:** STRENGTH
    - **Finding:** The design decisions (D1-D6) are logically sequenced and address core integration challenges (campaign tracking, binary management, CI linkage) with simple, vault-check-compliant solutions.
    - **Why:** This demonstrates systems thinking aligned with the constraints and idioms of the Crumb environment, increasing the likelihood of successful implementation and adoption.

- **[F9]**
    - **Severity:** MINOR
    - **Finding:** Open Question Q2 (subdirectory organization) is correctly identified as a future scaling concern. However, the spec could note a simple interim mitigation: using Dataview queries filtered by `file.path` or tags.
    - **Why:** It shows foresight but leaves a minor ambiguity about immediate implementation.
    - **Fix:** Add a note: "Initial implementation relies on tag-based search. Subdirectory logic can be added as a future enhancement if navigation pain emerges."

- **[F10]**
    - **Severity:** SIGNIFICANT
    - **Finding:** The specification lacks explicit error handling for markitdown extraction failures (e.g., corrupted file, unsupported format).
    - **Why:** The skill will fail ungracefully if the upstream dependency fails. This creates a poor user experience and may leave the system in an indeterminate state (e.g., with a partially extracted file).
    - **Fix:** In the task steps (DI-001), include error-checking logic: "If markitdown exits with an error or returns empty output, notify the user and halt processing. Do not delete the source binary."

**Unverifiable Claims:** None. The artifact references internal Crumb system components (`markitdown`, `kb-to-topic.yaml`, `inbox-processor`, knowledge-note schema) which are presented as contextual facts, not external claims requiring verification.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: "markitdown is available and extracts text + speaker notes from PPTX and text from PDF. Already used by inbox-processor." Repeated in multiple sections (Facts, Components, Dependencies).  
  [Why]: Core to the entire pipeline feasibility; if markitdown doesn't exist, can't extract speaker notes cleanly, or isn't integrated, the skill fails. No independent verification possible (no known public tool by this name with exact capabilities).  
  [Fix]: Reference a verifiable source (e.g., internal repo link, CLI output sample) or prototype extraction in DI-003.

- [F2]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: "Knowledge-note schema (spec §2.2.4) is the target output format. Well-defined, vault-check validated." Referenced repeatedly (Facts, Constraints, Acceptance criteria).  
  [Why]: Output must comply exactly, but schema details absent; risks schema violations if §2.2.4 doesn't match described structure (e.g., Key Intelligence → Actionable Items → Shelf Life).  
  [Fix]: Inline or link full schema excerpt; confirm `campaign:` field is schema-compliant.

- [F3]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: "`kb-to-topic.yaml` provides MOC routing from `#kb/` tags to domain MOCs."  
  [Why]: Critical for downstream integration (MOC one-liner output); if file doesn't exist or format mismatches, routing fails silently.  
  [Fix]: Append yaml excerpt or validation task in DI-002.

- [F4]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: "Inbox-processor handles generic binary intake... Already used by inbox-processor." Multiple refs (Facts, Dependencies, Relationship to Existing Systems).  
  [Why]: Claims no conflict with parallel tool, but without verifying inbox-processor's exact behavior (e.g., does it auto-trigger on PPTX?), invocation overlap possible.  
  [Fix]: Cross-reference inbox-processor SKILL.md; add conflict test to DI-005.

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: Assumption A4 ("Deleting source binaries after synthesis is acceptable") marked as "user decision — confirmed," but no evidence of confirmation provided.  
  [Why]: Irreversible action; contradicts "recoverable from source" if sources aren't always accessible (e.g., expired email links). Risks data loss.  
  [Fix]: Add user sign-off log or make deletion optional (`delete_source: yes|no` prompt).

- [F6]  
  [Severity]: SIGNIFICANT  
  [Finding]: Open Questions Q1/Q2 listed but not incorporated into Task Decomposition (e.g., no DI-006 for body structure decision or subdirectory plan).  
  [Why]: Leaves spec incomplete for PLAN phase; risks inconsistent knowledge-note structure or future `Sources/other/` disorganization (U3).  
  [Fix]: Add DI-006: Resolve Q1/Q2 via user decision or prototype.

- [F7]  
  [Severity]: SIGNIFICANT  
  [Finding]: No handling for extraction failures (e.g., corrupted PPTX, markitdown crashes) or synthesis edge cases (e.g., empty extraction). Only D6 covers image-heavy PDFs partially.  
  [Why]: Breaks feasibility; skill could leave `_inbox/` cluttered or produce invalid notes without rollback.  
  [Fix]: Add procedure step: "If extraction <200 chars or fails, prompt user: 'Extraction failed. Archive binary or retry?'"

- [F8]  
  [Severity]: MINOR  
  [Finding]: "Customer-intelligence project (active, ACT phase)" and "Danny processes... ~25 accounts" – vague actor/context ("Danny"?).  
  [Why]: Reduces clarity for non-Danny users; stats unverified, assumes single-user workflow.  
  [Fix]: Generalize to "user processes ~25 accounts" or define Danny.

- [F9]  
  [Severity]: MINOR  
  [Finding]: System Map diagram shows "MOC one-liner (if kb tag has MOC)" as separate output, but Key Design Decisions (D3,D4) emphasize single knowledge note, no source-index. Ambiguous if extra file created.  
  [Why]: Minor inconsistency; could lead to unexpected artifacts.  
  [Fix]: Clarify diagram legend: "MOC one-liner appended to knowledge note if applicable."

- [F10]  
  [Severity]: STRENGTH  
  [Finding]: Detailed Task Decomposition (DI-001 to DI-005) with types, risks, scopes, acceptance criteria, dependencies, and file changes.  
  [Why]: Aligns with stated Workflow (SPECIFY → PLAN → TASK → IMPLEMENT); actionable and testable, covering validations for A1-A3. Edge case: batch ceiling prevents context overflow.  
  [Fix]: N/A

- [F11]
  [Severity]: STRENGTH
  [Finding]: Clear distinction vs. existing systems (Inbox-Processor, CI Dossiers, Feed Pipeline) in dedicated section.
  [Why]: Prevents integration errors; internal consistency high (e.g., no binary storage repeated). Edge case: manual linkage works if tags standardized.
  [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Binary deletion needs a safety gate** (OAI-F2, GEM-F2, DS-F1, GRK-F5 — all 4 reviewers)
The spec says "delete source binary after synthesis" but defines no verification gate — no check that extraction succeeded, that the knowledge note passes vault-check, or that the user can inspect quality before irreversible deletion. This is the strongest consensus finding across all reviewers. Severity ranges from CRITICAL (OAI, DS) to SIGNIFICANT (GEM, GRK).

**2. MOC one-liner is underspecified** (OAI-F4, DS-F5, GRK-F9 — 3 reviewers)
The system map shows "MOC one-liner" as an output but the spec doesn't define: target file discovery, insertion format, idempotency (avoid duplicate entries), or whether it's automatic vs. confirmed.

**3. No explicit error handling for extraction failures** (DS-F10, GRK-F7, partially OAI-F6 — 3 reviewers)
If markitdown fails, crashes, or returns empty/corrupt output, the skill has no defined behavior. Risk of leaving the system in an indeterminate state or — combined with finding #1 — deleting a binary whose extraction failed.

**4. Inbox-processor conflict potential** (GEM-F1, GRK-F4 — 2 reviewers)
Both tools accept PPTX/PDF from `_inbox/`. No mechanism prevents inbox-processor from grabbing a file first.

### Unique Findings

**OAI-F7: Noise filtering rules are uncodified.** The spec identifies noise filtering as the highest-impact lever but provides no concrete preserve/discard criteria. This is a genuine insight — the draft SKILL.md (which the spec is based on) actually has these rules (Step 4 extraction categories and "Noise to discard" section), but they didn't carry into the specification. This is a gap in the spec, not the overall design.

**OAI-F13: Campaign field type ambiguity.** Scalar vs. list for the `campaign:` frontmatter field. A deck could be relevant to multiple campaigns. Genuine design gap — needs a decision.

**GEM-F4: Filename generation strategy.** PPTX filenames are messy; knowledge note filenames need to follow the `source_id` algorithm from §2.2.4. The spec references the algorithm but doesn't call it out as the filename driver. Minor gap — the mechanism exists, the spec just doesn't connect the dots explicitly.

**DS-F3: Speaker note weighting.** A2 claims notes are higher-value but no synthesis directive prioritizes them. Valid for SKILL.md procedure, not spec-level. Noted for PLAN phase.

**DS-F2: Task type classification.** DI-003/004/005 are validation tasks tagged `#code` — should be `#test`. Minor taxonomy fix.

### Contradictions

**Deletion approach:** OAI proposes a soft-delete to trash with configurable retention. GEM proposes `_trash/` or `_processed/`. DS proposes `_inbox/archive/` or `_inbox/processed/`. GRK proposes a user prompt. All agree deletion needs a gate; they disagree on the mechanism. This is a design choice for the user, not a technical question.

**Batch ceiling derivation:** DS-F4 says the 3-5 ceiling is arbitrary and should be data-driven. OAI-F5 says the behavior when exceeding the ceiling is undefined. The ceiling is pragmatic — refinement is appropriate for PLAN, not SPECIFY.

### Action Items

**Must-fix:**

- **A1** (OAI-F2, GEM-F2, DS-F1, GRK-F5): **Add a deletion safety gate.** After synthesis, verify: (1) markitdown extraction returned non-trivial content, (2) knowledge note was written successfully, (3) user confirms deletion. If any check fails, source binary stays in `_inbox/`. No soft-delete directory — the user chose "delete after synthesis" and the gate provides the safety. Adding a staging directory contradicts the design intent of not maintaining binaries.

- **A2** (DS-F10, GRK-F7, OAI-F6): **Add explicit error handling for extraction failures.** If markitdown exits non-zero, returns empty, or returns < 200 characters: halt processing for that file, notify user, do not delete binary. In batch mode: skip the file, continue with remaining files, report failures in the summary.

**Should-fix:**

- **A3** (OAI-F4, DS-F5, GRK-F9): **Specify MOC one-liner behavior.** Define in SKILL.md: look up primary `#kb/` tag in `kb-to-topic.yaml`, if mapped → append `- [[note-name]] — one-line summary` to the MOC's Core section, with idempotency check (skip if wikilink already present). This matches existing source-index MOC placement behavior.

- **A4** (GEM-F1, GRK-F4): **Clarify inbox-processor boundary.** Deck-intel is explicitly invoked by the user on specific files (by path or "process this deck"). Inbox-processor is invoked separately ("process inbox"). They don't auto-trigger. Add a note to the skill: "deck-intel accepts explicit file paths; it does not scan `_inbox/` automatically." This resolves the race condition — there isn't one.

- **A5** (OAI-F13): **Decide campaign field type.** Recommend: `campaign:` is a YAML list to support multi-campaign tagging. Default to single-element list for simplicity. Document in SKILL.md.

- **A6** (OAI-F8, DS-F6): **Standardize Shelf Life format.** Define in SKILL.md: free-text section in the note body (not frontmatter), containing duration estimate, recheck triggers, and specific expiration signals. Frontmatter `shelf_life:` field deferred — free text is appropriate until patterns emerge.

- **A7** (DS-F2): **Reclassify validation tasks.** Change DI-003, DI-004, DI-005 from `#code` to `#test`.

- **A8** (GEM-F4): **Clarify filename generation.** Knowledge note filename follows `source_id` algorithm (§2.2.4): `[source_id]-digest.md`. Add explicit note in SKILL.md.

**Defer:**

- **D1** (OAI-F7): Noise filtering rules — the draft SKILL.md already has detailed extraction categories and discard criteria. Will carry into the final SKILL.md during DI-001. Not a spec gap.
- **D2** (OAI-F9): Noise reduction metric — "meaningfully shorter" is a heuristic, not a hard threshold. Calibrate after first 5-10 extractions.
- **D3** (OAI-F10): Cross-reference mechanism — refine in PLAN phase when batch processing is designed in detail.
- **D4** (DS-F3): Speaker note weighting — synthesis directive for SKILL.md procedure, not spec-level.
- **D5** (DS-F4): Data-driven batch ceiling — revisit after DI-005 validation provides real token consumption data.
- **D6** (GRK-F6): Open questions as tasks — Q1/Q2 are explicitly deferred to PLAN by design.

### Considered and Declined

- **OAI-F17, OAI-F18, OAI-F19, OAI-F20, GEM-F3, GRK-F1, GRK-F2, GRK-F3, GRK-F4** — `incorrect`. These flag internal vault references (markitdown, §2.2.4, kb-to-topic.yaml, Sources/other/, inbox-processor) as "unverifiable claims." All were verified against actual vault files during spec writing. External reviewers correctly flagged what they can't verify, but these are confirmed facts within the system.
- **GEM-F5** (image fallback breaks batch) — `constraint`. The draft skill's Step 7 already handles this: classification summary presented before extraction, user decides which files to process. Interactive prompts don't break batch flow because they happen at the classification stage, not mid-extraction.
- **GRK-F8** ("Danny" generalization) — `out-of-scope`. Crumb is a personal operating system for a single user. "Danny" is the user. Generalizing adds no value.
- **OAI-F1** (Sources/other/ is for binaries vs. notes confusion) — `incorrect`. The spec is clear: knowledge *notes* go to `Sources/other/`, binaries are *deleted*. The Facts bullet says "Sources/other/ is the correct directory for presentations and reports (source_type: other)" — this refers to the knowledge-note `source_type` field value, not binary storage. No inconsistency exists.
- **OAI-F12** (reconcile flat vs. evolve) — `overkill`. U3 is explicitly flagged as an unknown with Q2 deferring the decision. The spec already handles this correctly by acknowledging uncertainty without committing prematurely.
