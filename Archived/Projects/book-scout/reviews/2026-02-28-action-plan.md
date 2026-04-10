---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/book-scout/design/action-plan.md
artifact_type: action-plan
artifact_hash: 8ad2f590
prompt_hash: 7d9434f9
base_ref: null
project: book-scout
domain: software
skill_origin: peer-review
created: 2026-02-28
updated: 2026-02-28
status: active
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
    - "Soft: /Users/ paths in all three artifacts (expected — local research library paths)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 57051
    attempts: 1
    raw_json: Projects/book-scout/reviews/raw/2026-02-28-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 41814
    attempts: 1
    raw_json: Projects/book-scout/reviews/raw/2026-02-28-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 56700
    attempts: 2
    raw_json: Projects/book-scout/reviews/raw/2026-02-28-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 37342
    attempts: 1
    raw_json: Projects/book-scout/reviews/raw/2026-02-28-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Book Scout Action Plan

**Artifact:** Projects/book-scout/design/action-plan.md
**Companion:** Projects/book-scout/design/tasks.md
**Reference:** Projects/book-scout/specification.md
**Mode:** full
**Reviewed:** 2026-02-28
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning

**Review prompt:** Structured review evaluating coverage, dependency correctness, risk calibration, task sizing, acceptance criteria quality, feasibility, and iteration budget for the Book Scout action plan and task breakdown.

---

## OpenAI (gpt-5.2)

### Coverage

- **F1**
  - **Severity:** CRITICAL
  - **Finding:** The plan/tasks do not include an explicit “operator approval gate” mechanism for downloads (selection parsing and confirmation flow), despite spec requiring human-in-the-loop approval and a >100MB explicit confirmation gate.
  - **Why:** Without a defined approval/selection contract, Tess may not reliably translate Telegram replies (“1 3 5”, “all”, “skip”, overrides) into safe `book_download` inputs; the >100MB gate also needs a conversational re-entry path.
  - **Fix:** Add an atomic task or explicit sub-acceptance criteria (likely under **BSC-006** or a new task **BSC-006a**) for: parsing Telegram selection replies; mapping numbered results → stable identifiers; handling “all/skip/retry”; and implementing the >100MB confirmation as a two-step interaction with a resumable token (e.g., “confirm download batch X”).

- **F2**
  - **Severity:** SIGNIFICANT
  - **Finding:** Spec §8.1 includes optional filters (format, year range, language) for `book_search`, but BSC-003 acceptance criteria does not require filters (and plan doesn’t mention implementing them).
  - **Why:** Filters materially affect search UX and relevance; leaving them out may cause rework later when Danny expects them.
  - **Fix:** Either (a) add filter support to BSC-003 acceptance criteria (“supports optional filters …”) or (b) explicitly mark filters as v2 and update spec/plan alignment.

- **F3**
  - **Severity:** SIGNIFICANT
  - **Finding:** Spec’s “PDF preferred / BBP PDF-only” requirement is not represented as an acceptance criterion in BSC-003/BSC-004 ranking/grouping logic.
  - **Why:** If Tess surfaces EPUB/DJVU first, the operator flow will be noisy and BBP handoff may fail later.
  - **Fix:** Add to **BSC-003** acceptance criteria: result ranking prioritizes PDF; and to **BSC-004**: formatting clearly flags non-PDF and optionally de-prioritizes them.

- **F4**
  - **Severity:** SIGNIFICANT
  - **Finding:** Crumb-side stale file cleanup/audit behavior in spec §4.6 (“processed older than 30 days safe to delete”, “flag inbox >7 days”) is not present in BSC-007 or later hardening tasks.
  - **Why:** Without this, inbox accumulation can silently degrade reliability; it’s part of the robustness contract of the handoff seam.
  - **Fix:** Extend **BSC-007** or add a small follow-on task to implement: age-based warnings for inbox; optional cleanup command/report for processed; and run-log entries.

- **F5**
  - **Severity:** MINOR
  - **Finding:** Spec calls out “no bridge dependency”; plan reflects that correctly. Good alignment overall between spec §14 and milestones/tasks.
  - **Why:** Confirms the plan is faithful to the core architectural decision (file handoff).
  - **Fix:** None.

---

### Dependency correctness

- **F6**
  - **Severity:** CRITICAL
  - **Finding:** **BSC-007** depends only on BSC-005 in tasks.md, but it also depends on **having the subject→tag→topic mapping available as code/data** (spec §7.1). That mapping is in the spec, but there’s no explicit artifact ownership: where does it live, and how is it versioned?
  - **Why:** Crumb processor can’t be implemented deterministically without codifying the mapping (and a policy for unknown/new subjects).
  - **Fix:** Add an explicit dependency/artifact: e.g., a `book-scout-subject-map.json` (or config module) committed in the Crumb codebase; acceptance criteria: mapping file exists, referenced by BSC-007, and has tests for all known subjects.

- **F7**
  - **Severity:** SIGNIFICANT
  - **Finding:** Plan suggests BSC-003 and BSC-005 “can be developed in parallel,” but tasks.md correctly sets BSC-005 depends on BSC-003. Good, but there’s a hidden dependency: shared API client code and shared canonical identifiers between search results and download requests.
  - **Why:** If search returns IDs in one shape and download expects another, you get brittle integration and a lot of iteration churn.
  - **Fix:** In **BSC-003** define and freeze a “SearchResult schema” that includes the exact identifier needed for download (`aa_doc_id` or whatever M0 discovers). Add acceptance criteria: `book_search` results include the exact ID consumed by `book_download`.

- **F8**
  - **Severity:** SIGNIFICANT
  - **Finding:** BSC-006 includes “retry command works,” but there is no dependency on the Telegram agent behavior/state management that would store failed-item context across messages.
  - **Why:** Retrying requires either (a) the tool to accept explicit IDs again, or (b) Tess to persist a “last batch” state token. That’s nontrivial and not captured.
  - **Fix:** Make the retry mechanism explicit: either design “retry by passing aa_doc_id list again” (stateless) or implement a minimal persisted state file in tess_scratch. Add this as explicit scope/dependency for BSC-006.

---

### Risk calibration

- **F9**
  - **Severity:** SIGNIFICANT
  - **Finding:** Several tasks are marked **low risk** but have meaningful integration risk: BSC-006 (Telegram progress + retry), BSC-004 (bulk parsing + message splitting), and BSC-007 (vault-check compliance) are likely medium in practice.
  - **Why:** The biggest failures in these systems are usually “glue-layer” mismatches, not core HTTP calls.
  - **Fix:** Re-rate: BSC-004 → medium, BSC-006 → medium, BSC-007 stays medium. Keep BSC-009 low/medium depending on breadth.

- **F10**
  - **Severity:** MINOR
  - **Finding:** BSC-005 risk labeled medium is plausible, but the threat model includes path traversal and catalog injection—those are security-sensitive and could justify “medium-high” attention.
  - **Why:** A single path handling bug can write outside intended directories.
  - **Fix:** Add explicit acceptance criteria in BSC-005/BSC-009: “reject any computed path that resolves outside `/Users/tess/research-library/` after realpath resolution.”

---

### Task sizing (≤5 file changes each)

- **F11**
  - **Severity:** SIGNIFICANT
  - **Finding:** **BSC-005** is too large for the stated sizing constraint (download URL retrieval, curl execution, naming, subject routing, MD5, constraints, catalog JSON, atomic write, dedup, retries). This will likely touch many files and require iterative refactors.
  - **Why:** Oversized tasks reduce reviewability, increase partial completion risk, and make acceptance harder to verify.
  - **Fix:** Split BSC-005 into at least 3 atomic tasks:
    1) **BSC-005a:** download URL retrieval + curl download to target with `.partial` + timeout  
    2) **BSC-005b:** naming + subject routing + path safety + size confirmation gate  
    3) **BSC-005c:** MD5 verification + catalog JSON + atomic write + dedup + retries

- **F12**
  - **Severity:** SIGNIFICANT
  - **Finding:** **BSC-007** is also likely >5-file-change scope (reader, validator, template renderer, vault-check integration, moving files, logging, mapping).
  - **Why:** Vault integration often touches templates, config, processor code, and tests.
  - **Fix:** Split:
    - **BSC-007a:** inbox scan + JSON validation + move to processed/failed  
    - **BSC-007b:** source-index note generation + vault-check + mapping logic

- **F13**
  - **Severity:** MINOR
  - **Finding:** BSC-004 and BSC-006 could potentially be merged as “Telegram UX layer,” but keeping them separate is fine because formatting and download reporting are distinct.
  - **Why:** Either structure works; separation helps parallel testing.
  - **Fix:** Optional: keep as-is.

---

### Acceptance criteria quality (binary testable)

- **F14**
  - **Severity:** SIGNIFICANT
  - **Finding:** Several criteria are not fully binary/verifiable as written:
    - “formatted correctly for Telegram”
    - “edition grouping works”
    - “rights metadata documented”
    - “rate limits documented (or confirmed undocumented)”
  - **Why:** These can pass subjectively without clear test cases, creating disputes at completion time.
  - **Fix:** Add concrete checks:
    - Provide golden-message fixtures for formatting (input → exact output text)  
    - Define “edition grouping” rule (e.g., Levenshtein/title match threshold, same author + title) and a test dataset  
    - For rights metadata: “identify exact JSON fields, example values, and whether absent/null is common”  
    - For rate limits: “N requests in M seconds triggers/does not trigger 429; record observed behavior and headers”

- **F15**
  - **Severity:** SIGNIFICANT
  - **Finding:** BSC-005 acceptance criteria includes “per-file size >100MB prompts confirmation” but doesn’t define how the tool signals that requirement (error code? structured response?).
  - **Why:** The agent/tool contract must be explicit for Tess to ask and then resume.
  - **Fix:** Define tool response schema for “needs_confirmation” with fields `{reason, size_bytes, items_pending, resume_token}` and make it testable.

- **F16**
  - **Severity:** STRENGTH
  - **Finding:** Strong use of atomic write protocol (`.tmp` → rename) and dedup criteria keyed by `source_id`, with explicit directories and move semantics.
  - **Why:** This is the core reliability seam; the plan keeps it explicit and testable.
  - **Fix:** None.

---

### Feasibility / practical concerns

- **F17**
  - **Severity:** CRITICAL
  - **Finding:** The plan assumes “Anna’s Archive JSON API + key + curl direct downloads” is feasible, but does not include contingency for **mirror domain variability, TLS issues, redirects, or anti-bot headers** that often affect download endpoints even when an API exists.
  - **Why:** This is a common real-world failure mode; without planning, BSC-005 can stall after BSC-001 “works on curl once.”
  - **Fix:** In **BSC-001** expand validation to: test multiple base domains; capture required headers (User-Agent, Accept); confirm redirects; confirm large-file stability; and record a minimal reproducible curl command that the tool will emulate.

- **F18**
  - **Severity:** SIGNIFICANT
  - **Finding:** Keychain access from Node in a headless/agent context can prompt UI or fail depending on Keychain ACLs; plan says “read from Keychain” but doesn’t include validation steps.
  - **Why:** This can block all tool calls at runtime even if code is correct.
  - **Fix:** Add to **BSC-002** or **BSC-003**: “Keychain item created with non-interactive access for tess/openclaw context; tool can read key without prompting.” Document exact `security` CLI steps.

- **F19**
  - **Severity:** SIGNIFICANT
  - **Finding:** Filename/source_id collision handling is specified (“append year”), but acceptance criteria only mention collisions implicitly; no explicit test for two books with same author+short-title.
  - **Why:** Collisions are common (multiple editions/translations).
  - **Fix:** Add explicit acceptance test: download two editions that would collide; verify distinct filenames and distinct `source_id`s (or defined collision policy).

- **F20**
  - **Severity:** MINOR
  - **Finding:** “aria2c availability” is checked but not used in the plan; curl is baseline. This is fine, but the plan could clarify that aria2c is informational only unless a pivot is chosen.
  - **Why:** Avoids scope creep and confusion.
  - **Fix:** Note in BSC-002 acceptance: “recorded; no functional dependency unless operator opts in.”

---

### Iteration budget realism (3–6 live iterations)

- **F21**
  - **Severity:** STRENGTH
  - **Finding:** Budgeting explicit live-iteration cycles is appropriate for agent/tool integration where the “real test” is Telegram interaction and model contract alignment.
  - **Why:** Prevents false confidence from unit tests alone.
  - **Fix:** None.

- **F22**
  - **Severity:** SIGNIFICANT
  - **Finding:** 3–6 iterations may be **too low** if you include: Keychain permission friction, Telegram message splitting edge cases, and download URL expiration behavior. Conversely it may be **too high** if you strictly limit to search-only MVP.
  - **Why:** Without scoping what counts as an “iteration,” budgeting is ambiguous.
  - **Fix:** Define iteration stages:
    1) Search tool end-to-end in Telegram  
    2) Bulk search + formatting limits  
    3) Single download happy path + catalog write  
    4) Bulk download + progress + retry  
    5) Crumb processing + vault-check  
    Then estimate 1–2 iterations per stage (total 5–10) depending on API quirks.

---

### UNVERIFIABLE CLAIMS (flagged for grounded verification)

- **F23**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “Tess (voice agent — Haiku 4.5) via OpenClaw” and “Haiku 4.5” versioning details.
  - **Why:** I can’t confirm internal software/version references; if wrong, integration assumptions may be off.
  - **Fix:** Verify the runtime versions and compatibility constraints in an environment readme/run-log entry during BSC-002.

- **F24**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** “FIF/x-feed-intel tool patterns” and references to “claude-print-automation-patterns.md”.
  - **Why:** These appear to be internal project docs/patterns I cannot validate; they may not exist or may differ.
  - **Fix:** During BSC-003, link to exact repo paths/files used as templates (commit hash or local path) in run-log.

- **F25**
  - **Severity:** SIGNIFICANT
  - **Finding:** **UNVERIFIABLE CLAIM:** Anna’s Archive JSON API behavior assumptions (rights metadata presence, direct HTTP download links, permissive rate limits).
  - **Why:** External service behavior can differ; the plan correctly gates on BSC-001, but the claims remain unverified today.
  - **Fix:** Treat all AA API properties as provisional until BSC-001 completes; ensure the run-log captures raw sample responses (redacting secrets).

---

### Summary of strongest improvements to make now
1. Add explicit approval/selection + confirmation/resume contract (CRITICAL).
2. Split BSC-005 and likely BSC-007 to respect atomic task sizing (SIGNIFICANT).
3. Make search/download identifier schema explicit and shared (SIGNIFICANT).
4. Tighten acceptance criteria with fixtures and defined tool response shapes (SIGNIFICANT).
5. Expand feasibility checks around Keychain non-interactive access and mirror/redirect/header behavior (CRITICAL/SIGNIFICANT).

---

## Google (gemini-3-pro-preview)

Here is the review of the Book Scout Action Plan and Task Breakdown.

### Review Summary

The Action Plan is tightly aligned with the Specification and demonstrates a high degree of operational awareness, particularly regarding the risks associated with undocumented APIs (Anna's Archive). The inclusion of a specific "Kill/Pivot" decision gate in Milestone 0 is a significant strength that prevents wasted engineering effort. The iteration budget is realistic for LLM-based tool development.

However, the "Download Tool" (BSC-005) is currently overloaded with responsibilities (download, verification, file management, catalog generation, atomic writing) and represents a complexity spike that risks creating a monolithic, hard-to-debug function. Additionally, the implementation specifics of the Crumb-side processor (BSC-007) are less defined than the OpenClaw tools.

### Findings

#### [F1] CRITICAL | Task Sizing & Complexity
**Finding:** Task `BSC-005` (Implement book_download Tool) is overloaded.
**Why:** This single task requires implementing:
1. API URL retrieval logic.
2. `curl` subprocess management (with timeouts and constraints).
3. File system organization (paths, naming).
4. Cryptographic verification (MD5).
5. Catalog JSON schema generation.
6. Atomic file write/rename protocols.
**Why it matters:** Combining network I/O, disk I/O, and data serialization in one "atomic" task makes it difficult to test and debug. If the download succeeds but the JSON write fails (or vice versa), the system enters an inconsistent state. It exceeds the "≤5 file changes" heuristic significantly.
**Fix:** Split into two tasks:
*   `BSC-005a`: Core download mechanics (URL retrieval, curl execution, MD5 check, file placement).
*   `BSC-005b`: Catalog generation (JSON schema creation, atomic write to inbox, integration into the end of the download flow).

#### [F2] SIGNIFICANT | Unverifiable Claim / External Dependency
**Finding:** UNVERIFIABLE CLAIM: "Anna's Archive JSON API" existence and stability.
**Why:** The plan treats the existence of a structured, donation-gated JSON API as Fact F1 in the spec, though it correctly lists the *shape* as Unknown U1. Public documentation on a stable, programmatic JSON API for Anna's Archive is scarce or inconsistent.
**Why it matters:** If the API requires scraping, CAPTCHA solving, or browser session tokens (common for this source), the architecture described (simple HTTP client in Node.js) will fail immediately.
**Fix:** The plan effectively mitigates this with `BSC-001` (Research) and the "Kill/Pivot" gate. However, the plan should explicitly list "Authentication Method" as a high-risk variable in `BSC-001`. If the key requires a browser cookie rather than a header token, the tool complexity increases dramatically (requiring a headless browser vs. simple fetch).

#### [F3] SIGNIFICANT | Implementation Ambiguity
**Finding:** Lack of implementation context for `BSC-007` (Crumb catalog processor).
**Why:** While the OpenClaw tools (`BSC-003`, `BSC-005`) are explicitly defined as Node.js modules, `BSC-007` describes a "Crumb catalog processor" without specifying the technology stack. Is this a shell script? A Python script? A manual procedure?
**Why it matters:** "Crumb" acts as the operating system context, but the *implementation* of the processor needs a defined runtime to ensure it can parse JSON and validate schemas robustly.
**Fix:** Specify the runtime for `BSC-007` (e.g., "Implement Python script `process_catalog.py` to scan inbox...").

#### [F4] MINOR | Error Handling Edge Case
**Finding:** Missing validation for non-PDF content masquerading as PDF.
**Why:** `BSC-009` covers timeouts and disk space. It does not cover a scenario where the API returns a "success" (200 OK) but the content is an HTML error page or a captive portal redirect, which `curl` will happily save as `book.pdf`.
**Why it matters:** This corrupts the library with unreadable files.
**Fix:** Add a check in `BSC-005` (or `BSC-009` hardening) to use the `file` command or check the file header (must start with `%PDF`) before marking the download as successful.

#### [F5] STRENGTH | Risk Management
**Finding:** Explicit "Kill/Pivot" criteria in Milestone 0.
**Why:** Most action plans assume success. This plan explicitly lists the conditions under which the project should be cancelled (e.g., "API requires scraping/CAPTCHA"). This preserves the operator's time and aligns perfectly with the research-first methodology.

#### [F6] STRENGTH | Iteration Budgeting
**Finding:** Explicit budget for "3–6 iterations" on live deployment.
**Why:** LLM-driven tools often pass unit tests but fail in conversation (prompt-model contract gaps). Budgeting for this reality in M1/M2 prevents schedule slippage and frustration.

### Evaluation Against Criteria

1.  **Coverage:** **High.** All spec requirements are mapped to tasks.
2.  **Dependency correctness:** **High.** The graph logically flows from research -> tool -> notification -> processing.
3.  **Risk calibration:** **High.** The plan correctly identifies the API as the single point of failure and front-loads that risk.
4.  **Task sizing:** **Medium.** BSC-005 is too large (see F1). Others are appropriate.
5.  **Acceptance criteria quality:** **High.** Criteria are specific (e.g., "warns <1GB, aborts <500MB") and testable.
6.  **Feasibility:** **High**, contingent on BSC-001 results. The architecture is simple and robust.
7.  **Iteration budget:** **Realistic.** The allocated budget acknowledges the stochastic nature of LLM tool usage.

### Unverifiable Claims Flagged
*   **Context:** "Haiku 4.5" (referenced in context and spec). This appears to be a fictional or internal version identifier for an AI model (Anthropic's current public models are Haiku 3/3.5).
*   **Source:** "Anna's Archive JSON API" (referenced in spec §5.1 and plan). While the archive exists, the specific mechanics of a stable JSON API for donation keys are not standard public knowledge and require the verification scheduled in M0.

---

## DeepSeek (deepseek-reasoner)

## Review of Book Scout Action Plan & Tasks

### 1. Coverage
- **F1** [STRENGTH]: The action plan and task table comprehensively map to the specification's §14 decomposition. All 10 spec tasks (BSC-001 to BSC-010) are addressed with corresponding phases and acceptance criteria. The plan adds valuable operational details (e.g., atomic write protocol, iteration budget) not in the spec.
- **F2** [MINOR]: The plan omits explicit handling of the spec's **Format preference** (§8.1: PDF prioritization). While implied in search result formatting, no task explicitly ensures PDF results are ranked first or flagged when unavailable.
  - **Why**: Could lead to acquiring non-PDF formats that downstream BBP cannot process.
  - **Fix**: Add a subtask in BSC-003 or BSC-004 to implement format ranking/filtering per spec §8.1.

### 2. Dependency Correctness
- **F3** [STRENGTH]: The dependency graph is logically sound. BSC-001 correctly gates API-dependent tasks; BSC-002 is properly parallelizable; handoff chain (download → catalog → BBP) is correct.
- **F4** [SIGNIFICANT]: BSC-005 (download tool) depends on BSC-003 (search tool) per the plan's note, but the dependency is not reflected in the tasks.md table. BSC-005 likely reuses the API client built in BSC-003.
  - **Why**: Missing dependency could lead to parallel development conflicts or code duplication.
  - **Fix**: Update tasks.md: BSC-005 "Depends On" should include BSC-003.

### 3. Risk Calibration
- **F5** [SIGNIFICANT]: Risk levels are generally appropriate but could be sharper. BSC-001 (API research) is arguably **High** risk, not Medium. The entire project viability hinges on unknowns (U1-U4), with explicit kill/pivot criteria.
  - **Why**: Underestimating this risk may insufficiently emphasize the gating nature of Milestone 0.
  - **Fix**: Elevate BSC-001 risk to "high" in both documents.

### 4. Task Sizing
- **F6** [SIGNIFICANT]: BSC-005 ("Implement book_download tool") is overloaded. It encompasses 9 distinct sub-operations (download URL retrieval, curl execution, file naming, MD5 check, constraints, catalog generation, atomic write, dedup, retry logic). This likely exceeds the "≤5 file changes" heuristic.
  - **Why**: High complexity increases implementation and testing time, creates a single point of failure.
  - **Fix**: Split into two tasks: BSC-005a (core download & file ops) and BSC-005b (catalog generation & handoff). Adjust dependencies accordingly.
- **F7** [MINOR]: BSC-007 ("Crumb catalog processor") is well-scoped for a Crumb skill (single processing loop with defined inputs/outputs).

### 5. Acceptance Criteria Quality
- **F8** [STRENGTH]: Most criteria are binary and testable (e.g., "directory exists", "JSON written to path"). Good use of concrete outputs.
- **F9** [SIGNIFICANT]: Some criteria are vague or subjective: BSC-009 "API timeout handled (returns error, not hang)" and "invalid API response handled (structured error)" lack specificity.
  - **Why**: "Handled" is open to interpretation. Does it mean logs? Returns a specific error code? Notifies user?
  - **Fix**: Rewrite with concrete outcomes: e.g., "On API timeout (>30s), tool returns a Telegram message: 'Search timeout. Try again.' and logs error code X to run-log."

### 6. Feasibility
- **F10** [STRENGTH]: The architecture (OpenClaw Node.js tools, curl, file-based handoff) is pragmatic and leverages existing patterns (FIF). Avoiding bridge modifications is a smart simplification.
- **F11** [SIGNIFICANT]: The plan assumes the `_openclaw/tess_scratch/catalog/` directory exists with correct group permissions (crumbvault). BSC-002 creates it, but the catalog handoff protocol requires **atomic rename** support, which depends on filesystem cross-user semantics.
  - **Why**: If `tess` writes and `crumb` reads across user/group boundaries, atomic rename may have permission nuances.
  - **Fix**: In BSC-002, add acceptance criteria to test atomic rename across users: create a test file as tess, rename, verify crumb can read.

### 7. Iteration Budget
- **F12** [STRENGTH]: Allocating 3–6 iterations for first live deployment is realistic. It acknowledges the "prompt-model contract gaps" that only live interaction reveals.
- **F13** [MINOR]: The iteration budget is noted but not allocated to specific milestones. M1 and M2 would bear the brunt (search and download interactions), while M3/M4 are more deterministic.
  - **Why**: Could lead to underestimating time for M1/M2.
  - **Fix**: Annotate M1 and M2 in the plan: "Budget 2–3 iterations for live Telegram interaction refinement."

### Unverifiable Claims
- **F14** [SIGNIFICANT]: **UNVERIFIABLE CLAIM**: The specification states as fact: "Anna's Archive offers a JSON API for programmatic access (donation-gated)" (F1) and "Danny's API key donation is in progress" (F2). The entire M0 and project viability depend on this.
- **F15** [SIGNIFICANT]: **UNVERIFIABLE CLAIM**: References to "OpenClaw," "Tess (voice agent — Haiku 4.5)," "Crumb," "FIF/x-feed-intel patterns," and "crumb-tess-bridge" are internal system components. The reviewer cannot verify their existence, interfaces, or behavior.
- **F16** [MINOR]: **UNVERIFIABLE CLAIM**: Citation of "`_system/docs/file-conventions.md`" and "`claude-print-automation-patterns.md`" as governing schemas and patterns.

### Summary
The action plan is **well-structured, logical, and highly detailed**, demonstrating strong systems thinking. The primary gaps are an overloaded task (BSC-005), slightly understated initial risk, and a few vague acceptance criteria. The architecture is feasible and avoids unnecessary complexity. Success hinges on validating the unverifiable claims about the Anna's Archive API.

**Recommended priority fixes:**
1. Split BSC-005 into two tasks.
2. Elevate BSC-001 risk to High.
3. Make BSC-005 dependent on BSC-003 in tasks.md.
4. Add filesystem atomic rename test to BSC-002.
5. Specify PDF preference handling in a task.

---

## Grok (grok-4-1-fast-reasoning)

### Coverage Findings

- [C1]
  - [Severity]: SIGNIFICANT
  - [Finding]: Action plan and tasks.md omit explicit coverage for PDF format preference and ranking from spec §8.1 ("filter or rank results to prioritize PDF"; "prefer PDF over EPUB, DJVU").
  - [Why]: Spec makes this a core UX requirement for aligning with batch-book-pipeline (PDF-only); without it, Tess may present suboptimal results, leading to operator frustration or pipeline failures.
  - [Fix]: Add to BSC-003 AC: "Search results prioritize/rank PDF formats first"; reference in BSC-004 for presentation ("flag non-PDF clearly").

- [C2]
  - [Severity]: SIGNIFICANT
  - [Finding]: Bulk-list parsing rules (spec §4.5: parse after `-`, `—`, `by`, `,`; ignore `#` comments/blank lines) not explicitly in BSC-004 AC or approach.
  - [Why]: Critical for single-query vs. bulk mode distinction; vague coverage risks incorrect Telegram parsing, breaking primary interaction flow.
  - [Fix]: Expand BSC-004 AC: "Bulk input parsed per spec §4.5 rules (one title/line, optional author delimiters, ignore comments/blanks); echo parsed count pre-search."

- [C3]
  - [Severity]: MINOR
  - [Finding]: Subject override by operator via Telegram (spec §7) not called out in plan.
  - [Why]: Minor gap; Tess should support "download 1 to history" overrides, but plan assumes Tess assigns primary subject.
  - [Fix]: Add to BSC-005 approach: "Parse optional subject override from download command."

- [C4]
  - [Severity]: STRENGTH
  - [Finding]: M0 gate explicitly covers spec §14 kill/pivot criteria (no JSON API, CAPTCHA, etc.).
  - [Why]: Directly addresses highest-risk unknowns (A1–A6), preventing sunk cost on invalid assumptions.
  - [Fix]: N/A

### Dependency Correctness Findings

- [D1]
  - [Severity]: CRITICAL
  - [Finding]: BSC-007 (Crumb processor) depends only on BSC-005 in tasks.md, but action-plan dependency graph shows BSC-007 after BSC-005 without BSC-006; spec requires catalog JSON schema validation which assumes download-generated JSON structure tested via BSC-005.
  - [Why]: Logical error — Crumb processor can't validate without sample JSONs from real downloads; sequencing skips testing handoff before vault integration.
  - [Fix]: Update tasks.md: BSC-007 depends on BSC-005 + BSC-006; graph: BSC-006 → BSC-007.

- [D2]
  - [Severity]: SIGNIFICANT
  - [Finding]: BSC-009 (error handling) depends on BSC-003,005,007 but not BSC-004/006 (Telegram overflow, notifications).
  - [Why]: Telegram-specific edges (message length, progress updates) unhandled until hardening; hidden dependency risks late discoveries.
  - [Fix]: tasks.md: BSC-009 depends on all prior (BSC-003-008).

- [D3]
  - [Severity]: MINOR
  - [Finding]: Parallel note for BSC-003/005 development post-M0, but tasks.md serializes BSC-005 on BSC-003.
  - [Why]: Minor inconsistency; shared API client code justifies serialization.
  - [Fix]: Clarify in action-plan: "Parallel possible but recommend serial for code reuse."

### Risk Calibration Findings

- [R1]
  - [Severity]: SIGNIFICANT
  - [Finding]: BSC-005 rated medium risk but described as "heaviest single task" with 9 sub-approaches (API retrieval, curl, naming, MD5, constraints, JSON gen, atomic writes, dedup, retries).
  - [Why]: Under-calibrated; multi-subsystem integration (API+FS+JSON+subproc) warrants high risk, matching spec §14 medium but plan's detail elevates it.
  - [Fix]: Re-rate BSC-005 high; add risk mitigation: "Unit test each sub-function independently."

- [R2]
  - [Severity]: MINOR
  - [Finding]: BSC-001 medium risk justified, but no contingency for API key delay (spec §5.1 "in progress").
  - [Why]: Blocks entire project; low mitigation detail.
  - [Fix]: Add to M0: "Parallel mock API research using public endpoints if key delayed."

- [R3]
  - [Severity]: STRENGTH
  - [Finding]: Risks tied to spec §10 threat model (e.g., key exposure, path traversal mitigated by Keychain/path prefix).
  - [Why]: Calibration consistent with threats; explicit mitigations reduce effective risk.
  - [Fix]: N/A

### Task Sizing Findings

- [TS1]
  - [Severity]: SIGNIFICANT
  - [Finding]: BSC-005 exceeds ≤5 file changes: spans tool impl (2-3 files), curl subprocess, FS ops (naming/dir), JSON schema, dedup scans, retries — likely 8+ files/changes.
  - [Why]: Violates "atomic task" principle; debugging hell if one subpart breaks.
  - [Fix]: Split BSC-005 into BSC-005a (download+FS+MD5), BSC-005b (catalog JSON+dedup+retries); update deps/graph.

- [TS2]
  - [Severity]: MINOR
  - [Finding]: BSC-001 packs 8 approaches (docs, validate search/download, rate limits, etc.).
  - [Why]: Borderline oversized for research task.
  - [Fix]: No change needed if curl-only; monitor during exec.

### Acceptance Criteria Quality Findings

- [AC1]
  - [Severity]: SIGNIFICANT
  - [Finding]: BSC-003 AC vague: "structured result list (title, author, year, format, size, source library, rights info)" — no schema ref (spec §6 fields).
  - [Why]: Not binary testable; what if partial fields? Risks incomplete metadata for downstream (catalog, BBP).
  - [Fix]: "Returns JSON array matching spec §6 fields (title,author,year,format,size_mb,source_library,rights_info,aa_doc_id,md5); tested with curl-equivalent query."

- [AC2]
  - [Severity]: SIGNIFICANT
  - [Finding]: Multiple AC untestable without spec refs: BSC-007 "source-index note created per spec §6.1 template" — but §6.1 has YAML+body details not binary-checked.
  - [Why]: "Passes vault-check" good, but template fidelity subjective without diff.
  - [Fix]: "Generated note YAML matches spec §6.1 example (domain:learning, tags from §7.1, body metadata block); diff against golden file."

- [AC3]
  - [Severity]: MINOR
  - [Finding]: BSC-008 AC: "one end-to-end flow validated" — lacks "acquire → BBP digest" detail.
  - [Why]: Slightly vague; assumes BBP exists/works.
  - [Fix]: "Log from BBP shows knowledge notes linked to source-index."

- [AC4]
  - [Severity]: STRENGTH
  - [Finding]: Most AC binary (dirs exist, tool registered, MD5 verified, vault-check passes).
  - [Why]: Testable via ls/curl/invoke/check; aligns with tasks.md table.
  - [Fix]: N/A

### Feasibility Findings

- [F1]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: OpenClaw tool registration "following FIF/x-feed-intel tool patterns" (Node.js module, config registration) — no evidence provided; assumes existing workspace.
  - [Why]: If patterns differ (e.g., no HTTP support), blocks M1; plan risks rework.
  - [Fix]: M1 Phase 1.1: "Prototype minimal HTTP tool first, validate registration before full impl."

- [F2]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: Anna's Archive API provides exact fields (MD5, rights_info, aa_doc_id) and direct curl downloads — M0 validates, but plan assumes A1-A6 hold.
  - [Why]: Spec §9 lists as assumptions; if partial (no rights/MD5), cascades to catalog/BBP gaps.
  - [Fix]: M0 AC: "List missing fields and spec impact (e.g., 'no MD5 → skip verification')."

- [F3]
  - [Severity]: MINOR
  - [Finding]: File perms (tess owns, crumbvault group read) assumes group exists.
  - [Why]: Setup risk if not.
  - [Fix]: BSC-002 AC: "Verify `groups tess` includes crumbvault; test Crumb read access."

### Iteration Budget Findings

- [IB1]
  - [Severity]: SIGNIFICANT
  - [Finding]: 3-6 iterations budgeted for M1/M2 live deployment, but LLM-tool gaps (prompt-model contract) likely higher for Telegram+tools (parsing bulk lists, approvals).
  - [Why]: Underestimates; x-feed-intel precedent unverified, Telegram statefulness adds variance.
  - [Fix]: Budget 5-8; add "Iteration log: gap, fix, Telegram test transcript."

- [IB2]
  - [Severity]: STRENGTH
  - [Finding]: Explicitly calls out "prompt-model contract gaps that mocks can't catch" tied to pattern doc.
  - [Why]: Realistic for LLM agents; prevents optimism bias.
  - [Fix]: N/A

**Summary**: 16 findings (12 issues: 1 CRITICAL, 7 SIGNIFICANT, 3 MINOR; 3 STRENGTHs). Plan is solid structurally but gaps in spec fidelity, deps, sizing, and unverifiables risk execution stalls. Prioritize D1, TS1, C1/AC1 fixes pre-M0.

---

## Synthesis

### Consensus Findings

**1. BSC-005 is too large and needs splitting (4/4 reviewers)**
OAI-F11, GEM-F1, DS-F6, GRK-TS1. All four reviewers independently flagged BSC-005 as exceeding the ≤5-file-change heuristic. It combines download mechanics, file organization, MD5 verification, catalog JSON generation, atomic writes, dedup, and retries. Consensus on splitting into 2 parts (OpenAI suggested 3, but the other three converged on 2).

**2. PDF format preference missing from task acceptance criteria (3/4 reviewers)**
OAI-F3, DS-F2, GRK-C1. The spec's PDF preference (§8.1) was added during this session but not propagated to BSC-003/BSC-004 acceptance criteria. Three reviewers caught the gap independently.

**3. Unverifiable claims about Anna's Archive API (4/4 reviewers)**
OAI-F25, GEM-F2, DS-F14, GRK-F2. All reviewers flagged API assumptions as unverifiable. Expected — this is exactly what BSC-001 (M0 research) validates. The M0 kill/pivot gate was praised by all reviewers as the correct mitigation.

**4. BSC-003 acceptance criteria need schema specificity (2/4 reviewers)**
OAI-F7/F14, GRK-AC1. Result structure fields should be explicitly listed, including the download identifier (`aa_doc_id`) that BSC-005 consumes.

### Unique Findings

**OAI-F17: Mirror domain variability and download stability** — OAI uniquely flagged that BSC-001 should test multiple base domains, capture required HTTP headers, and confirm redirect behavior. Genuine insight — download endpoints often behave differently than search APIs.

**OAI-F18: Keychain non-interactive access** — OAI flagged that Keychain ACLs can block headless tool access. Genuine insight based on real macOS behavior. We've encountered this in other OpenClaw integrations.

**GEM-F4: PDF header validation** — Gemini uniquely suggested checking `%PDF` file header after download to catch HTML error pages saved as .pdf. Smart edge case — genuinely useful for download reliability.

**DS-F11: Cross-user atomic rename permissions** — DeepSeek flagged that tess-writes/crumb-reads atomic rename behavior should be tested in BSC-002. Genuine insight — filesystem permission nuances across users.

**GRK-C2: Bulk-list parsing rules missing from BSC-004** — Grok caught that spec §4.5's parsing rules (delimiters, comments, blank lines) aren't in BSC-004's acceptance criteria. Valid gap.

**OAI-F19: Filename collision test** — OAI flagged that the collision-handling logic (append year) needs an explicit test case. Valid — multiple editions/translations are common.

### Contradictions

**BSC-007 sizing:** OAI-F12 says split BSC-007 (too large). DS-F7 says it's well-scoped. I side with DeepSeek — BSC-007 is a single Crumb processing loop (read JSON, validate, create note, move file), not standalone code with multiple source files. It stays as-is.

**BSC-001 risk level:** DS-F5 says elevate to high. Others accept medium. Medium is correct — the M0 gate IS the risk mitigation. "Medium with explicit mitigation gate" is the right calibration.

**Iteration budget:** OAI-F22 suggests 5-10, GRK-IB1 suggests 5-8, DS-F12 says 3-6 is realistic. The pattern doc figure (3-6) is per operation class. For two tools across two milestones, 4-8 total is reasonable. Minor calibration.

### Action Items

**Must-fix:**

- **A1** — Split BSC-005 into BSC-005a (download URL retrieval + curl download + file organization + MD5 verification) and BSC-005b (catalog JSON generation + atomic write + dedup + download constraints). Source: OAI-F11, GEM-F1, DS-F6, GRK-TS1.

- **A2** — Add PDF format preference to BSC-003 AC ("search results prioritize PDF format") and BSC-004 AC ("non-PDF formats clearly flagged"). Source: OAI-F3, DS-F2, GRK-C1.

**Should-fix:**

- **A3** — Tighten BSC-003 AC with explicit result schema fields, including `aa_doc_id` that BSC-005 consumes for downloads. Source: OAI-F7, OAI-F14, GRK-AC1.

- **A4** — Add bulk-list parsing rules to BSC-004 AC per spec §4.5 (delimiter support, comment lines, echo parsed count). Source: GRK-C2.

- **A5** — Add PDF header validation (`%PDF`) to BSC-005a or BSC-009 to catch non-PDF content saved as .pdf. Source: GEM-F4.

- **A6** — Add Keychain non-interactive access validation to BSC-002 AC ("tool can read API key without UI prompt in agent context"). Source: OAI-F18.

- **A7** — Add cross-user atomic rename test to BSC-002 AC ("tess writes file, renames atomically, crumb user can read via crumbvault group"). Source: DS-F11.

- **A8** — Expand BSC-001 to capture required HTTP headers, test multiple mirror domains, and confirm download redirect behavior. Source: OAI-F17.

- **A9** — Add explicit filename collision test to BSC-005a AC ("two books with same author+short-title produce distinct filenames and source_ids"). Source: OAI-F19.

- **A10** — Expand BSC-009 dependencies to include BSC-004 and BSC-006 (Telegram-specific error handling). Source: GRK-D2.

**Defer:**

- **A11** — Adjust iteration budget from 3-6 to 4-8 total across M1/M2. Source: OAI-F22, GRK-IB1. Minor calibration, not blocking.

- **A12** — Stale file cleanup/audit for catalog directories. Source: OAI-F4. Operational maintenance — Crumb audit already detects stale files.

### Considered and Declined

- **OAI-F1** (approval/selection mechanism as separate task): `incorrect` — Tess is an LLM agent; selection parsing ("1 3 5", "all", "skip") is natural language understanding, not a coded parser. This is how x-feed-intel already works.

- **OAI-F6** (subject→tag mapping as separate JSON artifact): `incorrect` — Crumb reads the spec's markdown table (§7.1) directly. No separate config file needed; Crumb IS Claude.

- **OAI-F8** (retry state persistence): `incorrect` — Tess's conversation memory retains batch context within a session. The tool accepts item lists for retry; no external state file needed.

- **OAI-F9** (re-rate BSC-004/006 to medium risk): `overkill` — Formatting and notification tasks are low-stakes. The real integration risk is in BSC-003/005/007, which are already medium.

- **OAI-F15** (explicit confirmation response schema): `overkill` — OpenClaw tools return natural responses that the LLM agent interprets. No rigid "needs_confirmation" schema needed for an agent-mediated flow.

- **GEM-F3** (BSC-007 runtime specification): `incorrect` — BSC-007 is a Crumb procedure (Claude reads catalog JSON, writes vault notes). Not a standalone script requiring a specified language runtime.

- **GRK-D1** (BSC-007 depends on BSC-006): `incorrect` — BSC-007 needs catalog JSONs produced by BSC-005, not Telegram messages from BSC-006.

- **GRK-R2** (API key delay contingency): `out-of-scope` — Resolved. Key has arrived and is stored in Keychain.

- **DS-F5** (elevate BSC-001 to high risk): `constraint` — Medium with an explicit M0 kill/pivot gate is the intended calibration. The gate is the mitigation.

- **DS-F4** (BSC-005 missing BSC-003 dependency): `incorrect` — tasks.md already lists BSC-003 in BSC-005's `depends_on` column.
