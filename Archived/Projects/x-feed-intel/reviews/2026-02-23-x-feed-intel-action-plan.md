---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/x-feed-intel/action-plan.md + Projects/x-feed-intel/tasks.md
artifact_type: architecture
artifact_hash: 426b446c
prompt_hash: 1e5f3515
base_ref: null
project: x-feed-intel
domain: software
skill_origin: peer-review
created: 2026-02-23
updated: 2026-02-23
reviewers:
  - openai/gpt-5.2-2025-12-11
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - xai/grok-4-1-fast-reasoning
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 4096
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: unavailable
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-x-feed-intel-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: unavailable
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-x-feed-intel-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: unavailable
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-x-feed-intel-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: unavailable
    attempts: 1
    raw_json: Projects/x-feed-intel/reviews/raw/2026-02-23-x-feed-intel-action-plan-grok.json
  perplexity:
    http_status: 200
    latency_ms: unavailable
    attempts: 1
    raw_json: null
    note: Submitted manually via Perplexity web UI (action-plan.md + specification.md); tasks.md not included
tags:
  - review
  - peer-review
---

# Peer Review: x-feed-intel Action Plan & Tasks

**Artifact:** `Projects/x-feed-intel/action-plan.md` + `Projects/x-feed-intel/tasks.md`
**Mode:** full
**Reviewed:** 2026-02-23
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek Reasoner, xAI Grok 4.1 Fast, Perplexity Sonar Reasoning Pro
**Review prompt:** Structured review of action plan and task breakdown for x-feed-intel project. Focus areas: dependency correctness, task scoping (≤5 file changes), risk calibration, coverage gaps, acceptance criteria quality (binary testable), milestone structure. Reviewers instructed to flag unverifiable factual claims.

---

## OpenAI (GPT-5.2)

### Dependency correctness

- **[F1]**
  - **Severity:** CRITICAL
  - **Finding:** **XFI-006 depends on the wrong prerequisite (XFI-00A Telegram) and is missing the correct prerequisite (XFI-00B TwitterAPI.io key).**
  - **Why:** The benchmark script cannot call TwitterAPI.io without an API key; Telegram is not required to run a benchmark script (at most it's useful for notifications). This will block Milestone 0 incorrectly and may cause wasted time debugging "auth" that is actually a missing dependency.
  - **Fix:** Change XFI-006 dependencies to **XFI-002, XFI-003, XFI-00B** (optionally keep XFI-00A only if the script actually posts results/errors to Telegram).

- **[F2]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-016 (triage engine) does not depend on having pending posts populated (Milestone 1: XFI-011/012/013) or at least benchmark datasets (XFI-005/006).**
  - **Why:** You can implement the engine without real data, but acceptance criteria say it processes batches of posts and writes triage_json—this is hard to validate without a fixture dataset. The milestone header says "Depends on Milestone 1 complete," but the task table is the authoritative dependency list and currently doesn't encode that.
  - **Fix:** Add dependency to XFI-016 on **XFI-013** (or on "Milestone 1 complete" via explicit dependencies like XFI-014 or XFI-013). Also consider depending on **XFI-005/006** to ensure there are fixtures for development tests.

- **[F3]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-021 (attention clock scheduling) chain omits the queue health / expiry step (XFI-026) and cost guardrail (XFI-025) that affect inputs and output messaging.**
  - **Why:** If attention runs without expiry, the queue can bloat and triage old items; if guardrail is active, digest should note it (your acceptance for XFI-025 requires a digest note). These are cross-milestone dependencies not captured.
  - **Fix:** Either: 1) Make XFI-026 run inside the attention chain (add as dependency to XFI-021 and/or embed as a pre-step), and 2) Ensure XFI-019 (digest) reads guardrail state (add dependency on XFI-025 or on a shared "settings/state" module). Or explicitly document they run as independent scheduled jobs with their own plists and add those tasks.

- **[F4]**
  - **Severity:** MINOR
  - **Finding:** **XFI-027 depends on XFI-014 and XFI-021, but acceptance says "detects no successful capture or attention run in 24h." There is no explicit "run success marker" task.**
  - **Why:** Liveness requires a canonical signal: DB row, file stamp, or log signature. Without defining it, the liveness checker can become brittle (parsing logs) and fail silently.
  - **Fix:** Add a small shared mechanism: e.g., `runs` table or update `cost_log` / `posts` with a `last_success_at` for each component, and have XFI-014/XFI-021 write it. Then XFI-027 checks that.

- **[F5]**
  - **Severity:** STRENGTH
  - **Finding:** Milestone-level dependency flow is mostly coherent: schema/config/OAuth → benchmarks → field mapping → normalizer → ingestion → triage → routing/digest → feedback.
  - **Why:** Minimizes rework and makes the "unknowns" (OAuth, search operator support, prompt reliability) surface early.
  - **Fix:** None.

### Task scoping (≤5 file changes each)

- **[F6]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-014 (capture clock scheduling) is oversized**: two schedules (daily + per-topic), retries/backoff, error logging, partial success behavior, and launchd setup likely spans multiple modules and plist files.
  - **Why:** This is likely >5 file changes and conflates "job runner orchestration" with "launchd plumbing" with "retry policy."
  - **Fix:** Split into: XFI-014a: "capture runner CLI + retry/backoff + structured logging"; XFI-014b: "launchd plists + install/uninstall scripts + docs"

- **[F7]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-016 + XFI-017 separation is good, but XFI-016 itself is still large** (batching, provider client, JSON schema validation, per-post isolation, retry logic, DB writes).
  - **Why:** This is core complexity and failure modes are subtle; oversized tasks reduce testability and increase merge risk.
  - **Fix:** Split XFI-016 into smaller tasks, e.g.: "LLM client wrapper + cost capture"; "Structured output parser/validator"; "Per-post retry + triage_failed state machine"; "DB persistence of triage_json"

- **[F8]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-022 (feedback listener) is also oversized**: Telegram webhook/polling integration, strict grammar parsing, reply-to correlation, idempotency, error messaging, expand behavior.
  - **Why:** Many edge cases; likely touches multiple modules and DB tables.
  - **Fix:** Split into: "Telegram update ingestion + reply correlation"; "Command parser + dispatch interface"; "Idempotency + feedback table writes + error responses"

- **[F9]**
  - **Severity:** MINOR
  - **Finding:** A few tasks may be *too granular* but acceptable: XFI-007 (field mapping doc) could be folded into XFI-010 normalizer design, but it's fine as explicit validation.
  - **Why:** Slight overhead, but it de-risks normalizer correctness.
  - **Fix:** Optional: merge XFI-007 into XFI-010 if you want fewer tickets.

### Risk calibration

- **[F10]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-012 is marked low risk, but likely medium.**
  - **Why:** It depends on unknown operator support, fallback filtering behavior, query construction nuances, and rate limiting; it's also tightly coupled to config semantics.
  - **Fix:** Raise XFI-012 risk to **medium** (or explicitly narrow scope: "basic scanning without fallback filtering" as low, then add a separate task for fallback behavior).

- **[F11]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **XFI-010 normalizer risk marked low; should be medium.**
  - **Why:** Canonical ID extraction, thread heuristics, `source_instances`, and `matched_topics` are foundational data model decisions. Mistakes here are costly to migrate because they pollute stored posts.
  - **Fix:** Mark **medium** and add a small "golden fixture tests" acceptance requirement.

- **[F12]**
  - **Severity:** STRENGTH
  - **Finding:** High risk correctly assigned to XFI-016/XFI-017; medium for OAuth and scheduling is reasonable.
  - **Why:** LLM structured output and prompt stability are the main uncertainty and you're budgeting iterations.
  - **Fix:** None.

### Coverage gaps (spec work missing / implicit tasks)

- **[F13]**
  - **Severity:** CRITICAL
  - **Finding:** **No explicit task for the "post ID assignment for digest" and mapping ID ↔ canonical_id across days.**
  - **Why:** XFI-022 grammar relies on `{ID}` like A01/B03. If IDs are regenerated each digest without a stable mapping, reply commands will fail or act on the wrong post. This is a core correctness issue for the feedback loop.
  - **Fix:** Add a task (likely in M2) to define and persist a **digest_item_id mapping** (e.g., in DB: digest_date + item_id → canonical_id) and ensure XFI-019 writes it and XFI-022 uses it.

- **[F14]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **No explicit "shared logging/telemetry framework" task**, yet many acceptances require logging, degraded mode notes, and error notifications.
  - **Why:** Without a standard logger and run context, you risk inconsistent logs and brittle parsing for liveness/degraded-mode.
  - **Fix:** Add a shared module task: structured logger + run_id + component status reporting (success/failure + reason) persisted to DB.

- **[F15]**
  - **Severity:** SIGNIFICANT
  - **Finding:** **No explicit task for "DB access layer / repository pattern"** though nearly every task touches SQLite.
  - **Why:** Re-implementing SQL snippets across components increases bug surface and makes atomicity (XFI-013) harder.
  - **Fix:** Add a small shared "db client + migrations runner + typed queries" task early (after XFI-002).

- **[F16]**
  - **Severity:** MINOR
  - **Finding:** Keychain usage is mentioned in XFI-004 and XFI-00B but there's **no shared "secrets access" helper** task.
  - **Why:** Duplicated secret handling increases operational failures and makes ops guide harder.
  - **Fix:** Add a shared `secrets.ts` module task, or amend XFI-001 scope to include it.

- **[F17]**
  - **Severity:** MINOR
  - **Finding:** Partial-success / degraded mode is in milestone success criteria, but there's **no explicit task that defines how upstream failures are recorded** for use by digest (XFI-019).
  - **Why:** Digest needs a concrete signal: last run status per source.
  - **Fix:** Add explicit "component run status recording" (ties into F14/F4).

### Acceptance criteria quality (binary testable)

- **[F18]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Some acceptance criteria are not strictly binary:
    - XFI-017 "confidence distribution … is not degenerate"
    - XFI-009 "quality assessment"
    - XFI-028 "top 5 failure scenarios from §6.3" (depends on having that list concretely available)
  - **Why:** Non-binary criteria cause disputes and make "done" unclear.
  - **Fix:** Make them mechanically testable: XFI-017: define a numeric threshold; XFI-009: specify concrete operator action; XFI-028: include an explicit checklist.

- **[F19]**
  - **Severity:** MINOR
  - **Finding:** A few acceptances require implementation detail that may be ambiguous:
    - XFI-002 "schema matches §7.2 exactly" (good if §7.2 is precise; otherwise hard)
    - XFI-019 "overflow to file digest when >35 items" (what "file digest" means)
  - **Why:** Ambiguity increases rework.
  - **Fix:** Add exact path/behavior for file digest output.

- **[F20]**
  - **Severity:** STRENGTH
  - **Finding:** Many acceptances are crisp and verifiable (tsc pass, idempotent migration, token refresh success, queue status transitions, threshold math for guardrails).
  - **Why:** Improves delivery predictability.
  - **Fix:** None.

### Milestone structure

- **[F21]**
  - **Severity:** SIGNIFICANT
  - **Finding:** Milestone boundaries are mostly logical, but **the feedback loop (M3) functionally depends on persistent digest item mappings and run-status recording**, which are not called out as M2 deliverables.
  - **Why:** Without those, M3 will be blocked or implemented with hacks.
  - **Fix:** Move/insert the required groundwork into M2 and explicitly list it in M2 success criteria.

- **[F22]**
  - **Severity:** STRENGTH
  - **Finding:** Ordering is sensible: validate unknowns in M0, then capture, then triage/digest, then feedback/ops.
  - **Why:** De-risks the largest uncertainty (prompt/triage) while ensuring data supply exists.
  - **Fix:** None.

### Unverifiable claims

- **[F23]** SIGNIFICANT: "Specification v0.4.2 … governance-reviewed, 2 rounds of 5-model peer review."
- **[F24]** SIGNIFICANT: Governance notes "G-04 … G-08" and their described meanings.
- **[F25]** SIGNIFICANT: `claude-print-automation-patterns.md` "Pattern 4" and the "budget 3–6 iterations" guidance.
- **[F26]** SIGNIFICANT: "Haiku 4.5" model/version reference.
- **[F27]** SIGNIFICANT: "TwitterAPI.io" operator support examples and pricing/rate tier confirmation.
- **[F28]** SIGNIFICANT: X API endpoints/behavior implied and "X API v2 bookmarks."

---

## Google (Gemini 3 Pro Preview)

### UNVERIFIABLE CLAIMS

1. **UNVERIFIABLE CLAIM: "Haiku 4.5"**
   - **Context:** Milestone 2 description and Task XFI-016 ("Haiku 4.5 LLM call").
   - **Status:** **CRITICAL**. As of early 2026 (projected date), or current date, "Claude 3 Haiku" and "Claude 3.5 Haiku" exist. There is no public roadmap confirming a "Haiku 4.5". This appears to be a hallucination or typo. Attempting to call an API with model string `claude-3-haiku-20240307` or `claude-3-5-haiku...` works; `haiku-4.5` will likely fail.

2. **UNVERIFIABLE CLAIM: Internal Governance Docs**
   - **Context:** Planning Inputs ("G-04", "G-05", "G-06", "G-08") and "claude-print-automation-patterns.md".
   - **Status:** **SIGNIFICANT**. These appear to be internal artifacts. The reviewer assumes these exist and contain the constraints cited.

### REVIEW FINDINGS

#### [F1] [SIGNIFICANT] Missing Deployment Mechanism for Feedback Listener
**Finding:** Milestone 3 includes XFI-022 ("Implement feedback listener"), but there is no corresponding infrastructure task to schedule or run it.
**Why:** The "Capture Clock" (XFI-014) and "Attention Clock" (XFI-021) have specific tasks to create `launchd` plists for periodic execution. The Feedback Listener typically requires a long-polling loop or a webhook server to receive Telegram updates. It cannot be "scheduled" at 8 AM; it must be a daemon (KeepAlive) or a high-frequency cron. Without a `launchd` configuration task, the code will exist but the bot will not respond to users.
**Fix:** Add a task **XFI-022b** or modify XFI-022 to include: "Create launchd plist for feedback listener (KeepAlive: true) to ensure continuous polling/listening."

#### [F2] [SIGNIFICANT] SQLite Concurrency Configuration Missing
**Finding:** The plan involves multiple independent processes accessing the same SQLite database: the Capture Clock, the Attention Clock, and the Feedback Listener. Task XFI-002 ("Create SQLite schema") does not specify enabling Write-Ahead Logging (WAL) mode.
**Why:** Default SQLite handles concurrency poorly when multiple processes attempt to write. If the Feedback Listener tries to log a "save" command while the Capture Clock is writing new bookmarks, the database may lock or throw `SQLITE_BUSY` errors.
**Fix:** Add acceptance criteria to XFI-002: "SQLite PRAGMA journal_mode=WAL is enabled by default in the database connection logic."

#### [F3] [MINOR] Incorrect Dependency in Milestone 0
**Finding:** Task XFI-006 (TwitterAPI.io benchmark) depends on XFI-00A (Telegram bot).
**Why:** The description for XFI-006 states results are "saved per-topic to benchmarks/". There is no indication that this benchmark script sends Telegram messages. This creates an artificial blocker.
**Fix:** Remove XFI-00A from the "Depends On" column for XFI-006.

#### [F4] [MINOR] Ambiguous Keychain Implementation Details
**Finding:** The plan preamble mentions "Keychain access via `keytar` or native bindings," but Task XFI-001 (Scaffold) does not specify which library to install.
**Why:** `keytar` has a history of build issues with varying Node.js versions and architectures (Mac Silicon vs Intel).
**Fix:** Update XFI-001 description to specify the exact library.

#### [F5] [STRENGTH] High-Fidelity Risk Segmentation in M2
**Finding:** The separation of XFI-016 (Triage Engine logic) and XFI-017 (Prompt Engineering) is a strong architectural decision.
**Why:** Many plans conflate "plumbing" with "intelligence." Separating them and assigning XFI-017 a "High" risk with budgeted iterations accurately reflects LLM behavior volatility.

#### [F6] [MINOR] Missing Media/Image Handling Strategy
**Finding:** XFI-010 (Normalizer) and XFI-013 (Dedup) focus on text and metadata. There is no explicit mention of how post images/media are handled.
**Why:** If the pipeline extracts only text/links, this is fine. If "vault" content implies images, users often expect local preservation.
**Fix:** Explicitly clarify in XFI-010 AC: "Media handling: Store remote URL only (no local binary download)" OR add a task for media downloading.

### STRUCTURE & SCORING

- **Dependency Correctness:** Good, with the exception of the Telegram dependency issue (F3).
- **Task Scoping:** Excellent. Tasks are atomic and testable.
- **Risk Calibration:** High. Plan correctly identifies Prompt Engineering as primary bottleneck.
- **Acceptance Criteria:** Strong. Most criteria are binary (Yes/No).

---

## DeepSeek (Reasoner)

### Dependency Correctness

- **F1** — **Severity:** SIGNIFICANT
  **Finding:** Missing explicit dependency for XFI-006 on XFI-00B. The task "TwitterAPI.io benchmark script" requires the API key stored by XFI-00B, but XFI-00B is not listed in its "Depends On."
  **Why:** This could cause a runtime failure if the benchmark script runs before the API key is provisioned and stored.
  **Fix:** Add XFI-00B to the "Depends On" for XFI-006.

- **F2** — **Severity:** MINOR
  **Finding:** The dependency graph shows XFI-015 (vault snapshot) and XFI-020 (cost telemetry) as dependencies for XFI-016 (triage engine), but the task table only lists XFI-002 and XFI-015. This is a minor discrepancy, but the table is authoritative.
  **Why:** The graph suggests a logical flow, but the table's explicit dependencies should be followed.
  **Fix:** Align the dependency graph with the task table or clarify that the graph is conceptual.

### Task Scoping

- **F3** — **Severity:** MINOR
  **Finding:** XFI-017 (prompt engineering) is noted as the "highest-risk deliverable" with 3-6 iterations budgeted. While it's a single task, the iterative nature may make it feel large. However, it's appropriately scoped as a focused activity.
  **Fix:** None needed, but ensure time is allocated for iterations.

- **F4** — **Severity:** STRENGTH
  **Finding:** Most tasks are well-scoped to ≤5 file changes. The breakdown follows a clean component separation.

### Risk Calibration

- **F5** — **Severity:** SIGNIFICANT
  **Finding:** XFI-016 (triage engine) is marked "high" risk, but its dependency on XFI-015 (vault snapshot) is marked "low" risk. If the snapshot generation fails or produces poor input, the triage engine's risk increases.
  **Why:** The triage engine's performance is heavily dependent on the quality and stability of its upstream data.
  **Fix:** Consider elevating XFI-015 risk to "medium" or adding a note about upstream data quality risk.

- **F6** — **Severity:** MINOR
  **Finding:** XFI-004 (OAuth setup) is marked "medium." Given the external dependency on Danny creating an X Developer Account and the complexity of OAuth flows, this is appropriate.
  **Fix:** None.

### Coverage Gaps

- **F7** — **Severity:** SIGNIFICANT
  **Finding:** The plan does not include a task for handling rate limits and quota exhaustion for either X API or TwitterAPI.io. The spec (§6.3) mentions rate limits, but no task exists for implementing retry-with-backoff, quota monitoring, or graceful degradation when limits are hit.
  **Why:** This is an operational necessity; without it, the pipeline may fail silently or exhaust credits.
  **Fix:** Add a task in Milestone 1 or 3 for rate limit handling and quota monitoring.

- **F8** — **Severity:** MINOR
  **Finding:** No explicit task for backup/restore of the SQLite database or state recovery.
  **Why:** Losing pipeline state could break deduplication and tracking.
  **Fix:** Add a subtask under XFI-028 (ops guide) to document backup procedures.

### Acceptance Criteria Quality

- **F9** — **Severity:** SIGNIFICANT
  **Finding:** XFI-017 acceptance criterion "confidence distribution across a ≥20-post sample is not degenerate (not all same value)" is qualitative and not binary. "Degenerate" is ambiguous.
  **Why:** This makes validation subjective; it should be a measurable, pass/fail check.
  **Fix:** Rephrase to: "In a ≥20-post sample, at least two different confidence values (low/medium/high) appear."

- **F10** — **Severity:** STRENGTH
  **Finding:** Most acceptance criteria are excellently binary.

### Milestone Structure

- **F11** — **Severity:** MINOR
  **Finding:** Milestone 2 depends on XFI-009 from Milestone 0. This cross-milestone dependency is clearly noted, which is good.
  **Fix:** None.

- **F12** — **Severity:** STRENGTH
  **Finding:** Milestones have clear boundaries and success criteria. The ordering is logical.

### Unverifiable Claims

- UNVERIFIABLE CLAIM: References to internal documents: "Specification v0.4.2," "Governance notes G-04, G-05, G-06, G-08," "ADR-001," "`claude-print-automation-patterns.md`," and "Crumb governance review."
- UNVERIFIABLE CLAIM: Reference to "Haiku 4.5" as an LLM provider.
- UNVERIFIABLE CLAIM: The "OpenClaw stack" and "Keychain access via `keytar` or native bindings."

---

## xAI (Grok 4.1 Fast)

### Overall Assessment
The action plan is well-organized with logical milestone progression and mostly authoritative dependencies in the task table. However, it has significant issues in dependency precision (unnecessary or missing links), acceptance criteria vagueness (several non-binary tests), coverage gaps (implicit spec work like full error modes and testing not tasked), and risk undercalibration (several medium/high tasks scoped too broadly). 15 findings total: 12 issues (80%), 3 strengths.

### Findings

- **F1** — **Severity:** SIGNIFICANT
  **Finding:** XFI-006 (search benchmark) incorrectly depends on XFI-00A (Telegram bot); AC for XFI-006 makes no mention of Telegram usage.
  **Why:** Unnecessary dependency bloats parallelism; violates "table is authoritative" claim.
  **Fix:** Remove XFI-00A from XFI-006 deps; add AC if Telegram notification intended.

- **F2** — **Severity:** SIGNIFICANT
  **Finding:** Missing dependency: XFI-019 (digest) depends on XFI-016 (triage) and XFI-020 (telemetry), but XFI-021 (attention scheduling) chains them without explicit dep on XFI-013 (dedup, populates queue for triage).
  **Why:** Queue population (M1) is prereq for triage testing; incomplete deps risk failed chains during M2 dev.
  **Fix:** Add "Milestone 1" or XFI-013 to XFI-016/XFI-021 deps.

- **F3** — **Severity:** CRITICAL
  **Finding:** XFI-017 (prompt engineering) AC includes non-binary tests: "confidence distribution ... not degenerate (not all same value)" and "≥2 iteration cycles completed and documented".
  **Why:** Subjective ("degenerate") allows disputes; highest-risk task needs unambiguous pass/fail.
  **Fix:** Replace with: "Sample ≥20 posts has ≥2 confidence levels"; "Run-log commit shows ≥2 prompt versions tested with JSON success rates".

- **F4** — **Severity:** MINOR
  **Finding:** XFI-004 (OAuth) AC "refresh failure returns clear error (not silent)" is vague/not binary.
  **Why:** "Clear" subjective; misses edge cases.
  **Fix:** Specify: "Error message includes 'OAuth refresh failed: [exact reason from API]' and sends Telegram alert".

- **F5** — **Severity:** SIGNIFICANT
  **Finding:** Coverage gap: No task implements "client-side engagement fallback" in XFI-012 AC, despite spec §5.2 implying it; also missing full "degraded mode" logic.
  **Why:** Spec-driven feature untasked risks incomplete scanner.
  **Fix:** Add sub-task or expand XFI-012 AC: "Fallback filters posts with <min_faves> client-side if operator unsupported".

- **F6** — **Severity:** MINOR
  **Finding:** Task scoping bloat in XFI-014 (scheduling): Covers launchd plists, retry backoff, error logging, partial success – likely >5 files.
  **Fix:** Split to XFI-014A (launchd plists), XFI-014B (retry/error/partial logic).

- **F7** — **Severity:** SIGNIFICANT
  **Finding:** Risk underrating: XFI-010 (normalizer) low-risk despite unifying two APIs, thread heuristics, canonical_id logic.
  **Why:** Field mapping may require redesign; low risk assumes perfect benchmarks.
  **Fix:** Escalate to medium; add AC: "Normalizer roundtrip-tested on 100% benchmark samples with 0 data loss".

- **F8** — **Severity:** MINOR
  **Finding:** M0 success criteria includes untasked "~200 bookmarks/results collected" – implies implicit data review.
  **Fix:** Assign to XFI-005/006 AC explicitly: ">=200 items per source logged".

- **F9** — **Severity:** SIGNIFICANT
  **Finding:** Coverage gap: No task for testing/idempotency of "append-only matched_topics" (XFI-010/013 AC) or full "per-post failure isolation" beyond AC (XFI-016).
  **Why:** Spec §5.3 requires it for dedup; untested risks DB corruption on re-runs.
  **Fix:** Add XFI-00C (unit tests for normalizer/dedup) post-M0.

- **F10** — **Severity:** MINOR
  **Finding:** XFI-026 (queue health) AC "backlog summary mode activates at >50 pending" vague – what triggers summary?
  **Fix:** Add: "Backlog >50 → Telegram summary sent; cron-prune runs daily."

- **F11** — **Severity:** MINOR
  **Finding:** XFI-025 (cost guardrail) deps ignore XFI-011 (bookmark costs); AC only halves max_results (search-only).
  **Fix:** Add dep XFI-011; AC: "If guardrail active, bookmark pull skips if >50% budget used".

- **F12** — **Severity:** MINOR
  **Finding:** Risk underrating: XFI-022 (feedback listener) medium despite "strict grammar" parsing, reply-id matching, duplicates.
  **Fix:** Escalate to high; add AC: "100% parse success on 20 malformed sample inputs".

- **F13** — **Severity:** STRENGTH
  **Finding:** Dependencies properly sequenced in table (e.g., normalizer XFI-010 before pullers XFI-011/012); graph matches as "simplification". No cycles detected.

- **F14** — **Severity:** STRENGTH
  **Finding:** Milestone ordering logical: M0 validates APIs/scaffold → M1 capture → M2 attention → M3 ops; clear goals/success criteria.

- **F15** — **Severity:** STRENGTH
  **Finding:** Most AC binary-testable (e.g., XFI-001: "`npm install` succeeds; `npx tsc --noEmit` passes"); file counts infer ≤5 changes.

---

## Perplexity (Sonar Reasoning Pro)

**Note:** Perplexity received `action-plan.md` and `specification.md` but NOT `tasks.md`. Several findings stem from this artifact gap — the reviewer couldn't verify task-level AC or coverage. Findings are evaluated with this limitation in mind.

### 1. Completeness — Concerns

- **F1** — **Severity:** MINOR (artifact limitation)
  **Finding:** `tasks.md` not provided alongside action plan; coverage can't be fully verified at task level.
  **Fix:** Surface tasks.md alongside action plan in future reviews.

- **F2** — **Severity:** MINOR
  **Finding:** Some Phase 0 subtasks are implicit in milestone success criteria but not clearly tasked: TwitterAPI.io operator matrix validation, thread heuristic field specifics, and optional 800-bookmark export for backlog seeding (§12).
  **Fix:** Tighten XFI-007 AC to name specific fields; add optional backlog seeding task; add operator matrix output to XFI-006/009.

- **F3** — **Severity:** MINOR
  **Finding:** Recommends §12 deliverable → task ID mapping table in action plan for auditability.
  **Fix:** Add coverage mapping table to action-plan.md.

### 2. Dependency Ordering — Pass

- **F4** — **Severity:** STRENGTH
  **Finding:** High-level dependency graph between milestones is correct and no circular dependencies detected. Ordering matches spec's Phase 0 → Phase 1 flow.

- **F5** — **Severity:** MINOR
  **Finding:** XFI-026 (queue health) should depend on capture/attention clocks being at least minimally wired, since it needs queue items to enforce TTLs.
  **Fix:** Add dependency note or develop against test fixtures.

### 3. Acceptance Criteria Quality — Concerns

- **F6** — **Severity:** SIGNIFICANT
  **Finding:** "Triage prompt validated against benchmark sample with 2+ iteration cycles" doesn't specify what "validated" means (accuracy threshold vs. subjective review). "Degraded mode notes included" doesn't specify exact message strings. Queue health/liveness thresholds phrased in English without explicit test scripts.
  **Fix:** Express AC as Given/When/Then scenarios with specific outputs.

### 4. Risk Assessment — Pass

- **F7** — **Severity:** SIGNIFICANT (genuine new insight)
  **Finding:** No task captures a labeled Phase 0 benchmark set for future drift validation. Phase 2 drift checks need a stable reference, but no Phase 1 task ensures the data is captured and persisted.
  **Fix:** Extend XFI-009 or add small task to persist labeled benchmark set as `xfi-triage-benchmark-YYYYMMDD.json`.

- **F8** — **Severity:** MINOR
  **Finding:** Recommends risk coverage table mapping §9 risks to task IDs (fully/partially/not addressed in Phase 1).
  **Fix:** Add risk traceability section to action plan.

### 5. Task Granularity — Pass

- **F9** — **Severity:** STRENGTH
  **Finding:** Task granularity is appropriate — tasks align with coherent components, no obviously trivial tasks broken out, and XFI-016/017 separation is well-judged.

### 6. Sequencing and Phasing — Pass

- **F10** — **Severity:** MINOR
  **Finding:** Consider pulling XFI-027 (liveness check) forward to M2 to prevent silent pipeline death during early triage experimentation. Also recommends explicit dry-run note before M3.
  **Fix:** Re-evaluate at M2 entry; add pilot period note to plan.

### 7. Operational Readiness — Concerns

- **F11** — **Severity:** SIGNIFICANT
  **Finding:** XFI-028 (ops guide) AC doesn't enumerate specific runbook topics. Spec §10 calls for OAuth re-auth procedure, topic config editing, alert interpretation, and degraded mode responses — but these aren't reflected as explicit AC checkpoints.
  **Fix:** Tighten XFI-028 AC to enumerate: OAuth re-auth flow, topic config editing + reload, alert response procedures for each alert type.

- **F12** — **Severity:** MINOR
  **Finding:** Recommends logging/observability baseline task in M1 or early M2 to define log locations, rotation, and structured fields.
  **Fix:** Consider adding shared logging baseline task.

### Overall Verdict
**Ready with minor fixes.** Plan closely tracks spec's phasing and components. Needs sharper AC for operational tasks and explicit benchmark data capture.

---

## Synthesis

### Consensus Findings

**CF-1: XFI-006 has wrong dependency — unanimous (4/4)**
Sources: OAI-F1, GEM-F3, DSK-F1, GRK-F1
XFI-006 (TwitterAPI.io benchmark) depends on XFI-00A (Telegram bot) but should depend on XFI-00B (TwitterAPI.io account setup). All four reviewers flagged this. OpenAI escalated to CRITICAL; others rated SIGNIFICANT/MINOR. The fix is clear: replace XFI-00A with XFI-00B in XFI-006 dependencies.

**CF-2: XFI-017 "degenerate" AC is not binary — strong consensus (4/5)**
Sources: OAI-F18, DSK-F9, GRK-F3, PPL-F6
The acceptance criterion "confidence distribution is not degenerate" is subjective. Four reviewers independently flagged it. All converge on the same fix: "In a ≥20-post sample, at least 2 distinct confidence levels appear." Perplexity added that "validated" is also underspecified — needs concrete threshold or operator sign-off. Grok flagged "≥2 iteration cycles" as non-binary, though I consider that adequately testable (count iterations in run-log).

**CF-3: XFI-010 normalizer risk should be medium — consensus (2/4)**
Sources: OAI-F11, GRK-F7
Both note that canonical ID extraction, thread heuristics, and multi-API unification make this foundational task riskier than "low." Mistakes pollute stored data and are costly to migrate.

**CF-4: XFI-014 oversized — consensus (2/4)**
Sources: OAI-F6, GRK-F6
Both flag that XFI-014 conflates launchd plist creation with runner orchestration, retry logic, and error handling. Likely >5 files. Both suggest the same split pattern (plists vs. runner logic).

**CF-5: M1→M2 cross-milestone dependency gap — consensus (2/4)**
Sources: OAI-F2, GRK-F2
XFI-016 (triage engine) needs populated posts to validate AC, but task table doesn't encode the M1 dependency. Both suggest adding XFI-013 as explicit dep for XFI-016.

**CF-6: Strengths — unanimous consensus on plan quality**
Sources: OAI-F5/F12/F20/F22, GEM-F5, DSK-F4/F10/F12, GRK-F13/F14/F15, PPL-F4/F9
All five reviewers affirm: logical milestone ordering, mostly binary AC, well-scoped tasks, and strong XFI-016/017 risk separation. Perplexity's overall verdict: "Ready with minor fixes."

### Unique Findings

**UF-1: No digest item ID → canonical_id mapping task (OAI-F13) — CRITICAL, genuine insight**
OpenAI uniquely identified that the feedback listener (XFI-022) relies on digest item IDs (A01, B03) to correlate user commands to posts, but no task persists the mapping between these ephemeral IDs and canonical_ids. Without this, feedback commands could act on wrong posts if IDs shift between digest runs. This is a real correctness gap — the feedback loop breaks without it.

**UF-2: Feedback listener needs daemon/KeepAlive deployment (GEM-F1) — SIGNIFICANT, genuine insight**
Google uniquely noted that XFI-014 and XFI-021 both have launchd scheduling tasks, but XFI-022 (feedback listener) has no deployment mechanism. Unlike the clocks that run periodically, the Telegram listener needs to be a persistent daemon with `KeepAlive: true`. The code would exist but never run.

**UF-3: SQLite WAL mode for concurrency (GEM-F2) — SIGNIFICANT, genuine insight**
Google uniquely flagged that three independent processes (capture clock, attention clock, feedback listener) will write to the same SQLite database. Without WAL mode, default journal mode risks `SQLITE_BUSY` errors. Simple one-line PRAGMA addition to XFI-002.

**UF-4: No rate limit handling task (DSK-F7) — SIGNIFICANT, partially covered**
DeepSeek noted no explicit task for rate limit handling. This is partially addressed by XFI-014's retry/backoff AC and individual puller error handling, but there's no centralized quota monitoring. Signal is valid but can be absorbed into existing tasks.

**UF-5: Shared logging/telemetry framework missing (OAI-F14) — SIGNIFICANT, valid concern but may be premature**
OpenAI flagged that many tasks require logging/error notifications but no shared framework task exists. Valid concern for consistency, but may be over-engineering at PLAN phase for a personal tool.

**UF-6: DB access layer missing (OAI-F15) — SIGNIFICANT, noise**
OpenAI suggested a shared "db client + migrations runner + typed queries" task. For 4 SQLite tables in a personal pipeline, this is premature abstraction.

**UF-7: Client-side engagement fallback gap (GRK-F5) — SIGNIFICANT, already covered**
Grok flagged missing client-side fallback for XFI-012 when operators aren't supported. The spec §5.2 describes this behavior and XFI-012's AC already covers fallback filtering. This is implementation detail within XFI-012, not a separate task.

**UF-8: Idempotency testing for normalizer/dedup (GRK-F9) — SIGNIFICANT, valid but premature**
Grok suggested a separate unit test task for append-only behavior. Append-only is already an AC on XFI-010/013 — testing is inherent to validating those tasks.

**UF-9: Labeled benchmark set capture for drift validation (PPL-F7) — SIGNIFICANT, genuine insight**
Perplexity uniquely identified that Phase 2 drift checks need a stable reference dataset, but no Phase 1 task persists the benchmark data. Low-cost fix: extend XFI-009 to output a labeled `xfi-triage-benchmark-YYYYMMDD.json` alongside the operator review. This captures gold-label data while the operator's judgment is fresh, giving Phase 2 a baseline without any additional task.

**UF-10: XFI-028 ops guide AC should enumerate specific runbooks (PPL-F11) — SIGNIFICANT, genuine insight**
Perplexity noted that XFI-028's current AC ("top 5 failure scenarios from §6.3") is vague and doesn't enumerate the specific runbook topics the spec calls for: OAuth re-auth (§10), topic config editing, alert response procedures per alert type, and degraded mode responses. This tightens an existing AC quality concern (OAI-F18) with concrete content requirements.

### Contradictions

**C-1: "Haiku 4.5" model validity**
- Google: CRITICAL — "Haiku 4.5 doesn't exist, appears to be a hallucination or typo. Will likely fail."
- Others: Flag as UNVERIFIABLE but don't challenge existence.
- **Resolution:** Google is incorrect. `claude-haiku-4-5-20251001` is a valid Anthropic model (Haiku 4.5). The model ID in the spec should specify the full API string to prevent this confusion, but the reference itself is accurate. Declined as `incorrect`.

**C-2: XFI-015 risk level**
- DeepSeek (F5): XFI-015 should be elevated to medium because it feeds high-risk XFI-016.
- No other reviewer flags this.
- **Resolution:** XFI-015 (vault snapshot) is a read-only operation on a known vault structure. Its risk is appropriately low. The triage engine's risk comes from the LLM, not the snapshot input.

**C-3: XFI-016/022 splitting urgency**
- OpenAI (F7, F8): Split XFI-016 into 4 subtasks and XFI-022 into 3 subtasks.
- DeepSeek: No scoping issues raised.
- Grok: Flags XFI-014 but not XFI-016/022.
- **Resolution:** OpenAI's splits are granular for a PLAN-phase decomposition. These tasks may be large, but splitting at TASK phase (when implementation details are clearer) is more appropriate. Monitor during implementation.

### Action Items

**Must-fix (blocking correctness or parallelism):**

- **A1** — Fix XFI-006 dependencies: remove XFI-00A, add XFI-00B
  Sources: OAI-F1, GEM-F3, DSK-F1, GRK-F1

- **A2** — Tighten XFI-017 AC: replace "confidence distribution not degenerate" with "in a ≥20-post sample, at least 2 distinct confidence levels (low/medium/high) appear"
  Sources: OAI-F18, DSK-F9, GRK-F3

- **A3** — Add task for digest item ID → canonical_id mapping persistence (M2, after XFI-019)
  Sources: OAI-F13

**Should-fix (significant but not blocking):**

- **A4** — Elevate XFI-010 normalizer risk from low to medium
  Sources: OAI-F11, GRK-F7

- **A5** — Add XFI-013 as explicit dependency for XFI-016 (encode M1→M2 data dependency)
  Sources: OAI-F2, GRK-F2

- **A6** — Add feedback listener deployment: expand XFI-022 AC to include launchd plist with KeepAlive, or add XFI-022b
  Sources: GEM-F1

- **A7** — Add SQLite WAL mode to XFI-002 AC: "PRAGMA journal_mode=WAL enabled in connection setup"
  Sources: GEM-F2

- **A8** — Consider splitting XFI-014 into runner logic + launchd plists at TASK phase entry
  Sources: OAI-F6, GRK-F6

- **A9** — Extend XFI-009 to persist labeled benchmark set (`xfi-triage-benchmark-YYYYMMDD.json`) for Phase 2 drift validation
  Sources: PPL-F7

- **A10** — Tighten XFI-028 AC to enumerate specific runbook topics: OAuth re-auth flow (§10), topic config editing + reload, alert response per type (queue backlog, liveness failure, cost guardrail, degraded mode)
  Sources: PPL-F11, OAI-F18

### Considered and Declined

| Finding | Justification | Reason |
|---------|---------------|--------|
| OAI-F15 (DB access layer task) | 4 simple tables, standard SQLite operations. Premature abstraction for a personal pipeline. | overkill |
| OAI-F16 (shared secrets helper) | Only 2 callsites (OAuth + TwitterAPI.io). Extract if pattern grows during implementation. | overkill |
| OAI-F14 (shared logging framework) | Valid consistency concern but premature for personal tool at PLAN phase. Structured logging can emerge organically during implementation. | overkill |
| OAI-F3 (XFI-021 chain omits XFI-026/025) | Queue health and cost guardrail are designed as independent scheduled jobs with their own plists, not steps in the attention chain. This is an intentional architectural choice. | constraint |
| OAI-F4 (run success marker task) | Implementation detail for XFI-027. The mechanism (DB column, file stamp) is determined during TASK phase, not a separate PLAN-level task. | overkill |
| OAI-F7/F8 (split XFI-016 into 4 / XFI-022 into 3) | Too granular for PLAN-phase decomposition. Monitor size during TASK phase and split if needed. | overkill |
| DSK-F5 (elevate XFI-015 risk to medium) | Vault snapshot is a read-only operation on known structure. Triage risk comes from the LLM, not the input snapshot. Low risk is correct. | incorrect |
| GRK-F5 (client-side engagement fallback task) | Fallback filtering is already within XFI-012 scope — spec §5.2 describes the behavior and XFI-012 AC covers it. Not a separate task. | constraint |
| GRK-F11 (XFI-025 should dep on XFI-011 for bookmark costs) | Bookmarks use X API v2 free tier per spec §8 cost model. Cost guardrail targets paid API calls (search). | incorrect |
| GRK-F12 (XFI-022 risk to high) | Feedback listener has a strict grammar with ~6 commands. Not comparable to open-ended LLM output parsing. Medium is appropriate. | overkill |
| GRK-F9 (separate idempotency test task) | Append-only behavior is already an AC on XFI-010/013 — testing is inherent to task validation. | constraint |
| GEM-F4 (specify keychain library in XFI-001) | Implementation detail for TASK phase. Language/library decisions are scoped to implementation, not plan. | overkill |
| GEM-F6 (media handling strategy) | Spec §5.3 stores URLs only — no binary download. Already clear in spec. | out-of-scope |
| GEM unverifiable (Haiku 4.5 "doesn't exist") | `claude-haiku-4-5-20251001` is a valid Anthropic model. Google's training data predates its release. | incorrect |
| DSK-F7 (rate limit handling task) | Partially covered by XFI-014 retry/backoff AC and individual puller error handling. Centralized quota monitoring can be added during implementation if needed. | constraint |
| DSK-F8 (SQLite backup task) | Addressed by adding backup procedures to XFI-028 ops guide scope. Not a separate task. | overkill |
| PPL-F2 (800-bookmark export task) | Explicitly optional in spec §12. Not tasked unless user decides to seed backlog. Can be added ad-hoc. | out-of-scope |
| PPL-F2 (operator matrix as separate task) | Already covered by XFI-006 (benchmark) + XFI-009 (operator review). Operator support is documented as part of those outputs. | constraint |
| PPL-F3 (§12 → task ID mapping table) | Process documentation improvement, not a plan defect. Coverage is verifiable from existing task table. | overkill |
| PPL-F5 (XFI-026 needs capture/attention deps) | Queue health can be developed and tested against fixture data. Runtime dependency is operational, not build-time. | constraint |
| PPL-F10 (pull XFI-027 liveness to M2) | Valid phasing idea but changes milestone boundaries. Revisit at M2 entry when we know how stable the pipeline is. | out-of-scope |
| PPL-F12 (logging/observability baseline task) | Same concern as OAI-F14 (shared logging framework). Premature for personal tool at PLAN phase. | overkill |
