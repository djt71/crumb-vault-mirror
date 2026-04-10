---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/mission-control/design/action-plan.md
artifact_type: action-plan
artifact_hash: 2871fe31
prompt_hash: 5f484d1f
base_ref: null
project: mission-control
domain: software
skill_origin: peer-review
created: 2026-03-07
updated: 2026-03-07
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
    latency_ms: 54242
    attempts: 1
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 37422
    attempts: 1
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 98971
    attempts: 2
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 29474
    attempts: 1
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-grok.json
tags:
  - review
  - peer-review
status: active
---

# Peer Review: Mission Control Action Plan

**Artifact:** Projects/mission-control/design/action-plan.md
**Mode:** full
**Reviewed:** 2026-03-07
**Reviewers:** OpenAI gpt-5.2, Google gemini-3-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Structured review of action plan + task decomposition for Mission Control dashboard project. Focus areas: milestone sequencing, task scoping, dependency correctness, risk calibration, coverage gaps, R2 constraint resolution quality.

---

## OpenAI (gpt-5.2)

- **[F1]**
  - **[Severity]**: CRITICAL
  - **[Finding]**: Phase ordering contradiction: Milestone 4 is labeled "Attention-lite Page" but its success criteria says "Attention page with cross-source items ... Quick-add works," while PC-1 says M4 should validate single-source first and M5 expands to multi-source.
  - **[Why]**: This collapses the intended risk mitigation strategy and makes Phase 2 less meaningful; also creates confusion about what "lite" actually includes.
  - **[Fix]**: Tighten M4 scope to *single-source aggregator + minimal UI + quick-add* (e.g., dispatch pending + quick-add only). Move "cross-source items" language to M5, or redefine "lite" to explicitly enumerate which sources are included in Phase 1.

- **[F2]**
  - **[Severity]**: CRITICAL
  - **[Finding]**: M4 task MC-030 ("Attention aggregator -- add remaining Phase 1 sources") undermines the single-source-first strategy by adding multiple sources in Phase 1, despite PC-1.
  - **[Why]**: The riskiest work (multi-source merging/dedup semantics) is being pulled earlier than intended.
  - **[Fix]**: Split MC-030 into (a) "Phase 1: second source only" (optional) and (b) "Phase 2: full multi-source expansion" (move bulk of it under M5). Or keep MC-030 but restrict it to *one* additional low-risk source and explicitly defer dedup/merge complexity.

- **[F3]**
  - **[Severity]**: CRITICAL
  - **[Finding]**: E2E/Playwright smoke test promised in PC-7 is not represented by any task.
  - **[Why]**: This is an explicit plan commitment; missing it weakens deployment confidence and contradicts the declared testing strategy.
  - **[Fix]**: Add a task in M1 (e.g., MC-0XX "Playwright smoke test: app loads + /api/health OK + nav renders") and ensure it runs in CI (or at least as a local script) and is required for M1 acceptance.

- **[F4]**
  - **[Severity]**: CRITICAL
  - **[Finding]**: Several cross-cutting conventions are stated but not fully "made real" in tasks:
    - DOMPurify markdown sanitization: no explicit implementation task.
    - Adapter contract `{data, error, stale}`: implied, but no enforcement (type/interface + shared helper) task.
  - **[Why]**: Without explicit implementation/enforcement, these become "docs only," increasing security risk (markdown) and integration drift (adapter shape).
  - **[Fix]**: Add small foundation tasks in M1:
    - "SafeMarkdown component using DOMPurify + tests"
    - "AdapterResult type + helper wrapper (e.g., makeAdapter()) + lint/TS enforcement"

- **[F5]**
  - **[Severity]**: CRITICAL
  - **[Finding]**: Critical path in Action Plan omits M1 (and MC-010 gate) prerequisites for M4/M5. It lists `M0a -> M0b -> M1 -> M2 -> M3 -> M4 ...`, but M4 depends on M2 (per action plan) and MC-030 depends on MC-012; the graph is directionally okay, but incomplete/over-simplified and inconsistent with "M3||M4" parallelization if M4 truly depends on M2.
  - **[Why]**: Misstated critical path leads to scheduling errors and incorrect parallel work assumptions.
  - **[Fix]**: Update dependency graph to reflect actual prerequisites:
    - If M4 truly can parallelize with M3, make M4 depend on M1 (not M2), and ensure tasks list the correct prerequisites (adapters/patterns from M2 shouldn't be required).
    - Or keep M4 depending on M2 and remove "M3||M4" claim.

---

- **[F6]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Task sizing: several tasks likely exceed the "<=5 file changes" guideline.
    - MC-019/MC-020 (multiple adapters in one task).
    - MC-021/MC-022 (multiple major UI sections + behaviors).
    - MC-040 (four adapters in one task).
    - MC-048 (three adapters in one task).
    - MC-052 ("All Phase 3 adapter tests + privacy constraint test").
  - **[Why]**: Oversized tasks reduce parallelism, increase review difficulty, and make acceptance criteria harder to validate incrementally.
  - **[Fix]**: Split into one adapter per task (or at most two closely related), and split frontend build into smaller vertical slices (e.g., "render shell + one widget" then "add timeline" then "add cost burn + refresh").

- **[F7]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Some tasks are arguably too small / administrative relative to execution flow (e.g., MC-018 "Conventions doc" as a standalone item could be bundled with the first implementation of those conventions).
  - **[Why]**: Micro-tasks can create overhead without increasing clarity if they are not gating actual code.
  - **[Fix]**: Keep MC-018 but make it explicitly coupled to implementing the helpers/types referenced in the doc (or merge documentation into the tasks that introduce the shared utilities).

- **[F8]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Hidden dependency: nav-summary endpoint (MC-017) includes fields for pages not yet implemented (agents/knowledge/customer). There's no task ensuring those fields degrade gracefully before those milestones.
  - **[Why]**: The nav rail will either show incorrect badges, throw errors, or require later refactors.
  - **[Fix]**: In MC-017 acceptance criteria, require stable defaults (e.g., `null`/`0` + `stale:true`) and explicit versioning/feature flags for fields not yet backed by adapters.

- **[F9]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Data refresh strategy is only partially encoded:
    - Ops: explicit 30s auto-refresh (good).
    - Attention: 60s auto-refresh (good).
    - Agent Activity: 60s auto-refresh (good).
    - Intelligence/Customer/Knowledge manual pull: Intelligence task says manual pull; Knowledge says manual pull; Customer tasks don't mention refresh model.
  - **[Why]**: Refresh semantics are user-facing behavior and should be consistent across pages.
  - **[Fix]**: Add acceptance criteria to MC-051 (Customer/Career frontend) for manual pull + health strip behavior (via nav-summary) matching PC-4.

- **[F10]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: The "Dashboard is a monitored service -- Tess alerts on failure" success criterion (SC-7) is not clearly implemented in tasks. There is a launchd service, but nothing about monitoring/alerting on failure.
  - **[Why]**: Without monitoring, reliability regressions won't be detected promptly--contradicting an explicit success criterion.
  - **[Fix]**: Add a task in M1 or M2: "Healthcheck ping integration for dashboard service" or "Tess alert hook when /api/health fails / process restarts repeatedly."

- **[F11]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Privacy constraint coverage is partial: PC cross-cutting says "endpoints verify Cloudflare Access headers," but only MC-050 explicitly mentions this; other potentially sensitive endpoints (nav-summary, search, intelligence) don't state privacy/auth posture.
  - **[Why]**: In a single-user system behind Cloudflare Access, you still want consistent enforcement to prevent accidental exposure if routing changes.
  - **[Fix]**: Add a small M1 task: shared middleware "requireAccessIdentity" applied to all `/api/*` (or at least to customer/intelligence/search), with unit test verifying request rejection when headers missing.

- **[F12]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Time semantics decision (PC-3) is documented, but the tasks don't explicitly ensure adapter outputs are UTC ISO-8601 and that the frontend renders local time consistently.
  - **[Why]**: Time bugs are subtle and cross-cutting; without explicit tests or implementation tasks, drift is likely.
  - **[Fix]**: Add acceptance criteria and/or tests:
    - Adapter tests assert timestamps parse as UTC ISO.
    - A small frontend utility for formatting times, used everywhere.

- **[F13]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Staleness nudge behavior (open items untouched >14 days -> Tess nudge) is mentioned in spec summary, but not represented as a task in M5/M7.
  - **[Why]**: This is part of the attention-item lifecycle and "leak prevention" loop; missing it weakens the system's attention reliability.
  - **[Fix]**: Add a Phase 2 task (near MC-038/MC-039): "staleness nudge job + Tess notification integration," or explicitly document it as deferred with rationale.

- **[F14]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: Attention item archive location and rollover (`Archived/attention/YYYY-MM/`) isn't represented. PATCH updates (MC-044) do not mention archiving completed items.
  - **[Why]**: Vault hygiene and retrieval will degrade if completed items remain in the active inbox indefinitely.
  - **[Fix]**: Extend MC-044 acceptance criteria: when status transitions to archived/done, move file to archive path with atomic rename (and update any index if used).

- **[F15]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: "No intermediate database; optional SQLite cache if perf budget exceeded" is not addressed. That's fine, but there's no explicit perf budget measurement or "escape hatch" decision point.
  - **[Why]**: Without a stated measurement step, you may accidentally add caching ad hoc later.
  - **[Fix]**: Add a Retro checkpoint item (MC-035) or a small task: "measure attention scan + ops fetch durations; record perf numbers; decide if cache needed."

---

- **[F16]**
  - **[Severity]**: MINOR
  - **[Finding]**: MC-016 depends on "--" but is effectively required by Ops adapters (MC-019). It's okay as parallel work, but dependency metadata is inconsistent.
  - **[Why]**: Minor scheduling confusion.
  - **[Fix]**: Set MC-016 to depend on MC-011 (repo scaffolding) and make MC-019 depend on MC-016 explicitly (already partially true).

- **[F17]**
  - **[Severity]**: MINOR
  - **[Finding]**: Intelligence mockup task MC-009 depends on MC-007 and MC-008; reasonable, but could be overly strict if nav shell + state patterns can be developed earlier.
  - **[Why]**: Slightly reduces Phase 0 parallelism.
  - **[Fix]**: Allow MC-009 to depend on MC-005 (widget archetypes) plus whichever page mockup is needed for style anchoring.

- **[F18]**
  - **[Severity]**: MINOR
  - **[Finding]**: Some acceptance criteria bundle multiple validations without specifying observable checks (e.g., "graceful error handling," "layout matches mockup").
  - **[Why]**: Makes "done" subjective.
  - **[Fix]**: Add 1-2 concrete checks (screenshots, specific error state rendering, fixture-driven story pages, etc.).

---

- **[F19]**
  - **[Severity]**: STRENGTH
  - **[Finding]**: Phase 0 design gate is strongly enforced (M0b -> M1 dependency; "no code" phrasing; explicit widget inventory and analog budget).
  - **[Why]**: Aligns with C3 (visual design gate) and reduces churn.

- **[F20]**
  - **[Severity]**: STRENGTH
  - **[Finding]**: Testing is integrated milestone-by-milestone via adapter unit test tasks (MC-023, MC-028, MC-034, MC-043, MC-052) and explicit aggregator integration test mention.
  - **[Why]**: Matches PC-7's "highest value tests first" strategy.

- **[F21]**
  - **[Severity]**: STRENGTH
  - **[Finding]**: PLAN constraint resolutions are mostly mapped into concrete tasks:
    - Widget inventory/analog cap -> MC-006
    - Time semantics/conventions -> MC-018 (needs reinforcement per F12)
    - Polling-first + nav-summary -> MC-017
    - Aggregator risk mitigation -> MC-029/MC-030/MC-038 (structure present, though scope conflicts noted in F1/F2)
  - **[Why]**: Good traceability from decisions to work.

- **[F22]**
  - **[Severity]**: STRENGTH
  - **[Finding]**: Phase 1 retrospective is correctly positioned as a gate before Phase 2 (MC-035 -> MC-036).
  - **[Why]**: Enforces the "use for a week" learning loop and aligns with spec build order.

---

## R2 constraint resolution quality (9 items)

- **PC-1 Aggregator risk**: **Partially resolved** (good intent, but contradicted by M4/MC-030 scope). See F1-F2.
- **PC-2 Nav badge refresh**: **Resolved** (MC-017). Add graceful defaults (F8).
- **PC-3 Time semantics**: **Documented but under-enforced** (MC-018 only). See F12.
- **PC-4 Health header auto-refresh on manual pages**: **Mostly resolved** (PC text + Knowledge task mentions health strip). Customer/Intel should explicitly adopt it (F9).
- **PC-5 Analog readout budget**: **Resolved** in Phase 0 via MC-006.
- **PC-6 Widget inventory**: **Resolved** via MC-006.
- **PC-7 Testing strategy**: **Mostly resolved**, but missing Playwright smoke test task (F3).
- **PC-8 Notifications future**: **Resolved as explicitly deferred** (acceptable), but note staleness nudge from spec is different from browser notifications (F13).
- **PC-9 SSE**: **Resolved** (polling-first is implemented via MC-017/usePolling and per-page refresh notes).

---

## Coverage gaps vs spec summary (major)

- **[F23]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: "Dashboard replaces Telegram for morning orientation" (SC-1) depends heavily on the Attention landing page quality; but Attention is split across M4/M5/M7 with some ambiguity about what is delivered in Phase 1.
  - **[Why]**: If Phase 1 Attention is too thin or too unstable, the retro may fail to evaluate SC-1 meaningfully.
  - **[Fix]**: Make Phase 1 Attention deliver a coherent "morning orientation" slice (even if single-source): clear urgency strip, reliable refresh, and quick-add, with explicit SC-1 trial checklist in MC-035.

- **[F24]**
  - **[Severity]**: SIGNIFICANT
  - **[Finding]**: "Knowledge/Vault page: tag distribution" is mentioned (MC-042), but the data source and adapter support for tag distribution isn't explicitly included in MC-040.
  - **[Why]**: Risk of frontend promise without backend data.
  - **[Fix]**: Add an explicit "tag stats adapter" (or define it as part of QMD adapter) and call it out in MC-040/MC-042 acceptance criteria.

No items in the artifacts contain GitHub issue numbers, version pins, paper titles, or sourced statistics that I can classify as "UNVERIFIABLE CLAIM" per your rule.

---

## Google (gemini-3-pro-preview)

Here is the review of the Action Plan and Task List artifacts for the Mission Control Dashboard.

### Review Summary

The artifacts present a highly disciplined, risk-aware breakdown of the Mission Control specification. The separation of "Plan" (strategy) and "Tasks" (execution) is handled well, with strong adherence to the "Ceremony Budget" and "Phase 0 Design Gate" constraints.

However, there is a **critical contradiction** regarding the "Aggregator Risk Mitigation" strategy between the Action Plan text and the actual Task definitions, and a **missing task** regarding the testing strategy defined in the Plan.

---

### Findings

#### [F1] [CRITICAL] Contradiction in Aggregator Risk Mitigation (M4 vs. M5)
**Finding:** The Action Plan's resolution for **PC-1** states: "M4 builds the attention aggregator with a single source... M5 expands to full multi-source." However, Task **MC-030** (inside Milestone 4) is titled "Attention aggregator -- add remaining Phase 1 sources" and explicitly lists adding FIF, vault-check, and Healthchecks.
**Why:** This contradicts the risk mitigation strategy. If MC-030 is executed in Phase 1 (M4), the developer is forced to build a multi-source aggregator immediately, negating the "Lite" nature of M4 and pulling the highest integration risk forward into Phase 1.
**Fix:** Move the scope of MC-030 to Milestone 5. M4 should strictly be "Single Source (Dispatch Pending)" + "Quick Add". Alternatively, clarify if "Phase 1 sources" differ from "Full multi-source" (e.g., if System items are P1 but Relational/Personal are P2)--but currently, the definitions clash.

#### [F2] [CRITICAL] Missing Task for Mandated Smoke Test (PC-7)
**Finding:** The Action Plan resolution for **PC-7 (Testing Strategy)** explicitly promises: "E2E: Single Playwright smoke test at M1." However, Milestone 1 tasks (MC-011 through MC-018) contain no task for setting up Playwright or writing this smoke test.
**Why:** E2E testing infrastructure is notoriously difficult to "bolt on" later if not scaffolded early. Missing this task means the M1 success criteria cannot be met as defined in the Plan.
**Fix:** Add a task `MC-018b` in Milestone 1: "Playwright setup + Smoke Test. Install Playwright, configure CI/local run, write one test verifying dashboard loads and nav renders."

#### [F3] [SIGNIFICANT] DOMPurify Implementation Gap
**Finding:** The Action Plan mentions "Markdown sanitization: DOMPurify applied to all markdown" under Cross-Cutting Conventions. Task MC-018 creates the documentation (`CONVENTIONS.md`). However, there is no implementation task to actually install `dompurify` and create the shared `SafeMarkdown` component or utility in the frontend package.
**Why:** Markdown rendering from user-controlled files (Vault) is a primary XSS vector. Leaving the *implementation* of the sanitizer to be "assumed" within a generic "Page Frontend" task increases the risk it will be forgotten or implemented inconsistently across pages.
**Fix:** Add a specific task or explicit acceptance criteria to Milestone 1 (MC-013) or Milestone 2 (MC-019) for "Create SafeMarkdown component with DOMPurify configuration."

#### [F4] [SIGNIFICANT] Ambiguity in "Attention Status Updates" (M7) vs Phase 1 Usage
**Finding:** Milestone 7 (Status Updates) is in Phase 2. However, Phase 1 has a "Mandatory Retrospective" that involves a "1-week usage period."
**Why:** If the user creates items via Quick-Add (M4) during the Phase 1 usage period, they will have **no way to mark them as done** until Phase 2 (M7). The dashboard will accumulate stale items for a week with no clearing mechanism, potentially violating SC-1 (Dashboard replaces Telegram) because the user creates a backlog they cannot clear.
**Fix:** Either (A) Move M7 (Status Updates) into Phase 1, or (B) Add a simple "Delete/Archive" endpoint to M4 so items can at least be removed during the test week, even if full status transitions aren't ready.

#### [F5] [MINOR] Nav Badge Refresh Dependency Order
**Finding:** Task MC-017 (Nav summary endpoint) is in Milestone 1. However, the data sources for this summary (Attention counts, Ops error counts, Intel signals) are built in Adapters in M2, M3, and M4.
**Why:** The endpoint in M1 will return empty/mocked structures until the downstream adapters exist. This isn't a blocker, but it means the "Nav Badge" won't actually be verifiable until M4 is complete.
**Fix:** Update MC-017 Acceptance Criteria to note "Returns mocked structure until adapters are integrated," or acknowledge that the Nav Badge will be non-functional until Phase 1 is complete.

#### [F6] [STRENGTH] Strong Gatekeeping
**Finding:** The plan utilizes explicit gates effectively: `MC-010` (Design Gate), `MC-028` (M-Web Parity Gate), and `MC-035` (Phase 1 Retro).
**Why:** This enforces the "Design First" and "Ceremony Budget" constraints by forcing a stop-and-evaluate moment before complex logic is written.

---

### Detailed Evaluation

1.  **Milestone Sequencing:**
    *   Generally logical. The M0 (Design) -> M1 (Infra) -> M2 (Ops) flow is correct.
    *   **Issue:** The M4/M5 split (Aggregator) is logically defined in the Plan but implemented contradictorily in the Tasks (see **F1**).

2.  **Task Scoping:**
    *   Sizing is generally appropriate (atomic, likely <5 file changes).
    *   **Exceptions:** `MC-030` is currently too large (merging multiple sources + dedup logic). `MC-022` (Ops frontend) covers timeline + cost + auto-refresh, which might be slightly heavy but acceptable for a React component task.

3.  **Dependency Correctness:**
    *   Dependencies are mostly accurate.
    *   **Missing:** The Playwright task (F2) is missing entirely, so no dependencies link to it.

4.  **Risk Calibration:**
    *   High-risk items (Design, Aggregator, Parity Gate) are correctly identified in the table.
    *   **Adjustment:** If `MC-030` remains in Phase 1, its risk is "High" (correctly marked), but it endangers the Phase 1 timeline.

5.  **Coverage Gaps:**
    *   **Resolved:** R2 constraints PC-1 through PC-9 are addressed in the text, though PC-7 (Testing) has an execution gap (F2).
    *   **Gap:** How does the "Health Strip" (PC-4) actually get data? It reuses the Nav Summary. This is mentioned in the Plan but needs to be ensured the Nav Summary endpoint (MC-017) returns enough granularity for the specific page health strips (e.g., "Last updated" timestamps for specific domains).

6.  **R2 Constraint Resolution Quality:**
    *   **PC-1 (Aggregator):** Failed in execution (Task list contradicts Plan).
    *   **PC-7 (Testing):** Partial failure (Missing E2E task).
    *   **PC-8 (Notifications):** Correctly ignored.
    *   **PC-9 (SSE):** Correctly resolved to Polling.
    *   **Others:** Resolved well.

### Unverifiable Claims
No significant unverifiable claims found. References to "R2 review" and "32 amendments" are accepted as context provided in the prompt.

---

## DeepSeek (deepseek-reasoner)

**Review of Mission Control Dashboard Action Plan & Task Decomposition**

**Overall Assessment:** The artifacts present a highly detailed, logical, and well-structured decomposition of a complex project. The plan demonstrates strong understanding of the specification, risk management, and iterative development. The resolution of the PLAN-phase constraints is explicit and well-integrated.

---

### **Findings**

**1. Milestone Sequencing & Critical Path**
- **F1**
    - **Severity:** STRENGTH
    - **Finding:** Milestone sequencing is logical and follows a clear "foundation -> prove patterns -> expand" flow. The critical path (M0a->M0b->M1->M2->M3->M4->Retro->M5->M7) correctly identifies the sequence for the core "Attention" functionality.
    - **Why:** Ensures stable scaffolding and validation of high-risk components (aggregator) before broader expansion.
    - **Fix:** N/A

- **F2**
    - **Severity:** MINOR
    - **Finding:** The note that "M3 can run in parallel with M4" is potentially optimistic. M4's `MC-029` depends on the adapter pattern proven in M2, but M3 (`MC-024` FIF adapter) is also a complex data source adapter. Parallel work is possible, but context switching between two complex adapter/aggregator builds (Intel and Attention) may be inefficient for a solo operator.
    - **Why:** Could lead to dilution of focus during the most technically dense part of Phase 1.
    - **Fix:** Consider making M3 and M4 sequential in the task plan, or add a note about the potential trade-off.

**2. Task Scoping**
- **F3**
    - **Severity:** STRENGTH
    - **Finding:** Task sizing is excellent. Nearly all tasks are scoped to a single, focused deliverable (e.g., "Express API scaffold", "Quick-add endpoint") likely achievable within a single session.
    - **Why:** Enables clear progress tracking and reduces cognitive load.
    - **Fix:** N/A

**3. Dependency Correctness**
- **F4**
    - **Severity:** SIGNIFICANT
    - **Finding:** `MC-017` (Nav summary endpoint) depends only on `MC-012` and `MC-013`. However, to return meaningful data (e.g., `attention.count`), it likely needs to call the attention aggregator or its sources. This creates a hidden circular dependency, as the attention aggregator tasks (`MC-029`, `MC-030`) are in a later milestone (M4).
    - **Why:** The `/api/nav-summary` endpoint built in M1 will return placeholder/zero data for attention until M4 completes, which is fine, but the dependency graph doesn't reflect this logical data flow. The tasks for *enhancing* the endpoint with real data are missing.
    - **Fix:** Add a task in M4/M5 (e.g., `MC-030b`: "Integrate attention aggregator into `/api/nav-summary`") or clarify in `MC-017`'s acceptance criteria that initial implementation returns static/stub data.

- **F5**
    - **Severity:** SIGNIFICANT
    - **Finding:** `MC-018` (Time semantics doc) has no dependencies, but its conventions (UTC storage, sort keys) should ideally be established *before* adapter development begins in M2 (`MC-019`). Currently, adapters are built before the convention doc is tasked.
    - **Why:** Adapters developed in M2 might need refactoring if conventions are finalized later.
    - **Fix:** Move `MC-018` earlier in M1, or make `MC-019` dependent on `MC-018`.

**4. Risk Calibration**
- **F6**
    - **Severity:** STRENGTH
    - **Finding:** Risk levels are appropriately calibrated. High risk is correctly assigned to the aesthetic decision (`MC-003`), design gate (`MC-010`), M-Web parity gate (`MC-028`), and the attention aggregator tasks (`MC-029`, `MC-030`, `MC-038`).
    - **Why:** Accurately flags the project's major technical and design decision points.
    - **Fix:** N/A

**5. Coverage Gaps**
- **F7**
    - **Severity:** SIGNIFICANT
    - **Finding:** The **"staleness nudge"** specification (open items untouched >14 days -> Tess nudge) is not represented in any task. This is a specified behavior of the new `attention-item` primitive.
    - **Why:** A specified system behavior is missing from the implementation plan.
    - **Fix:** Add a task in M5 or M7: "Implement staleness detection logic (age >14d) and interface for Tess nudges."

- **F8**
    - **Severity:** MINOR
    - **Finding:** Success Criterion **SC-6** ("Observatory mode passes design gate (or alternative selected)") is not explicitly addressed in Phase 0 tasks. The "Observatory mode" is mentioned in the spec but its design validation isn't a clear gate item.
    - **Why:** A success criterion is not explicitly tied to a delivery milestone.
    - **Fix:** Ensure `MC-010` (Design gate review) includes validation of the Observatory mode concept or its alternative.

- **F9**
    - **Severity:** SIGNIFICANT
    - **Finding:** **Cross-cutting conventions** are documented (`MC-018`) but not all are verified by tasks. Specifically:
        1.  **Write atomicity:** `MC-031` (Quick-add endpoint) and `MC-044` (PATCH endpoint) should have explicit acceptance criteria for using the temp-file-then-atomic-rename pattern.
        2.  **Markdown sanitization:** No task for implementing `SafeMarkdown` component/utility using DOMPurify.
        3.  **Privacy constraint verification:** `MC-050` mentions header verification, but no task tests the blocking of data without valid Cloudflare Access headers.
    - **Why:** Architectural conventions may be inconsistently applied or forgotten.
    - **Fix:** Amend acceptance criteria for `MC-031`, `MC-044`. Add a task in M1: "Create SafeMarkdown React component". Add an acceptance criterion to `MC-052` or a new task: "Test Customer adapter rejects requests without valid Cloudflare Access headers."

**6. R2 Constraint Resolution Quality**
- **F10**
    - **Severity:** STRENGTH
    - **Finding:** The resolution of the 9 PLAN-phase constraints (PC-1 to PC-9) in the Action Plan is comprehensive and sensible. Decisions are clear (e.g., polling-first, 4 gauge max, nav-summary endpoint).
    - **Why:** Shows deliberate planning and addresses previously identified risks.
    - **Fix:** N/A

- **F11**
    - **Severity:** SIGNIFICANT
    - **Finding:** **PC-7 (Testing Strategy)** is partially orphaned in the task breakdown. The strategy mentions "E2E: Single Playwright smoke test at M1," but **no task in M1** corresponds to setting up Playwright or creating that smoke test.
    - **Why:** A defined element of the testing strategy is missing from the implementation plan.
    - **Fix:** Add a task in M1 (e.g., `MC-011b`: "Configure Playwright, implement smoke test for health endpoint and app load") or amend `MC-011`/`MC-013` acceptance criteria to include this.

- **F12**
    - **Severity:** MINOR
    - **Finding:** **PC-4 (Health Header Auto-Refresh)** is resolved in the Action Plan but its implementation is not explicitly tasked. The work is likely part of `MC-042` (Knowledge page frontend) and similar, but the requirement could be missed.
    - **Why:** Minor risk of implementation gap.
    - **Fix:** Add an acceptance criterion to `MC-042`, `MC-047`, `MC-051`: "Includes auto-refreshing health strip using `/api/nav-summary` data."

**Additional Evaluations**
- **Phase 1 Retrospective:** Perfectly positioned as a mandatory gate after core functionality is delivered but before expanding the schema and adding write capabilities. Its dependency on key test suites (`MC-023, MC-028, MC-034`) is correct.
- **Aggregator Risk Mitigation:** Clearly reflected in task structure: `MC-029` (single-source) precedes `MC-030` (multi-source for P1) which precedes `MC-038` (full multi-source for P2). This is a model of progressive complexity.
- **Testing Strategy Integration:** Adapter unit tests are tasked in every relevant milestone (`MC-023`, `MC-028`, `MC-034`, `MC-043`, `MC-052`). Aggregator integration tests are specifically tasked (`MC-030`, `MC-038`). The deferral of React component tests is a reasoned decision documented in the plan.

**Unverifiable Claims**
- **F13**
    - **Severity:** SIGNIFICANT
    - **Finding:** **UNVERIFIABLE CLAIM:** Multiple tasks (`MC-016`, `MC-019`, `MC-024`, `MC-040`, etc.) reference external systems, scripts, or data sources (e.g., `system-stats.sh`, `service-status.sh`, FIF SQLite DB, QMD, AKM feedback). The reviewer cannot verify the existence, schema, or accessibility of these sources.
    - **Why:** The feasibility and scope of adapter tasks depend entirely on these external systems being as assumed. This is an inherent limitation of reviewing the plan in isolation.
    - **Fix:** None required for this review, but the developer must validate these assumptions during implementation.

---
**Summary of Severity Counts:**
*   CRITICAL: 0
*   SIGNIFICANT: 7 (F4, F5, F7, F9, F11, F13)
*   MINOR: 3 (F2, F8, F12)
*   STRENGTH: 3 (F1, F3, F6, F10)

The plan is fundamentally sound and highly detailed. The most significant findings relate to ensuring all specified behaviors have corresponding tasks (staleness nudge, security test), clarifying dependencies for the nav-summary endpoint, and embedding the cross-cutting conventions and testing strategy into concrete task criteria. Addressing these gaps will make an already strong plan exceptionally robust.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Action Plan Milestone 4 success criteria state "Attention page with cross-source items", but PC-1 resolution explicitly states "M4 builds the attention aggregator with a single source (dispatch pending files)", with multi-source expansion deferred to M5. Tasks exacerbate this: MC-029 (single source), MC-030 (add Phase 1 sources, implying multi-source in M4).
- [Why]: Core logical contradiction undermines aggregator risk mitigation (PC-1), the critical path, and Phase 1 scope. Breaks sequencing and risk isolation strategy.
- [Fix]: Revise M4 success criteria and MC-030 to single-source only (dispatch); move multi-source to MC-036+ in M5. Update dependency graph.

- [F2]
- [Severity]: CRITICAL
- [Finding]: No tasks cover implementation of the new "attention-item" vault primitive persistence, schema enforcement beyond validation (MC-036), or staleness nudge logic (Tess nudge for items untouched >14 days).
- [Why]: Orphaned from spec's core new primitive section; Attention page (SC-2: surfaces >=1 missed item/week) relies on it, but only quick-add (MC-031) and updates (MC-044) touch writes--source-of-truth mechanics and nudges missing.
- [Fix]: Add tasks in M5: MC-xxx vault scanner for _inbox/attention/, MC-yyy staleness nudge cron/script integrated with Tess.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: E2E/Playwright smoke test mandated in PC-7 ("Single Playwright smoke test at M1") has no corresponding task in Milestone 1 (MC-011 to MC-018).
- [Why]: Testing strategy (PC-7) incomplete; highest-value adapter tests covered, but explicit M1 E2E gap risks uncaught scaffolding issues before Phase 1 usage.
- [Fix]: Insert MC-018.5 post-MC-018: "Playwright E2E smoke test (health endpoint, nav shell, tunnel access)".

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Milestone dependencies in Action Plan (e.g., M4 depends on M2; M3 on M2) not reflected in tasks: MC-029/MC-032 depend only on MC-012 (API scaffold), allowing premature Attention/Ops work without proven adapter pattern.
- [Why]: Hidden dependencies; violates "adapter pattern proven" dep for M3/M4, risks rework if M2 adapters fail.
- [Fix]: Update task deps: MC-029/MC-032 -> MC-023 (Ops tests); MC-024 -> MC-023.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: SC-7 ("Dashboard is a monitored service -- Tess alerts on failure") unaddressed; no tasks for Tess integration, launchd failure detection, or service health monitoring beyond basic launchd (MC-015).
- [Why]: Success criteria gap; dashboard itself must be observable (C1 solo operator), creating blind spot contradicting SC-5 (no terminal/log access).
- [Fix]: Add M1 task MC-015.5: "Tess monitor script for launchd + Express crashes, alert on downtime >5min".

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Cross-cutting privacy (C7: "Customer-intelligence data never exposed publicly") only notionally covered in PC and MC-050 ("header verification"); no tasks verify Cloudflare Access on other sensitive endpoints (e.g., /attention if relational items sensitive, /knowledge AKM).
- [Why]: Privacy constraint from spec not tasked comprehensively; single-user but leak risk if headers bypassed.
- [Fix]: Add per-milestone tasks: MC-017.5 nav-summary privacy check; MC-041 search privacy gate.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Several frontend tasks exceed atomic scoping (<=5 file changes): MC-021 (KPI strip + service grid: likely 3+ components/hooks), MC-022 (timeline + cost + refresh: charts, polling), MC-032/033 (cards + strip + filters + views + feed).
- [Why]: Violates task decomposition principle; chunky tasks hide bugs, inflate session estimates (e.g., M2 2-3 sessions).
- [Fix]: Split: e.g., MC-021a KPI, MC-021b grid; MC-032a cards, MC-032b strip/quick-add.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: PC-4 (health header auto-refresh on manual pages via nav-summary) assumes MC-017 covers it, but no explicit task confirms health strip UI on Intelligence/Customer/Knowledge pages (MC-026, MC-042, MC-051).
- [Why]: Constraint resolution incomplete; manual pages lack "health strip at top" implementation.
- [Fix]: Add subtasks: MC-026.5 pipeline health strip; MC-042.5 knowledge strip.

- [F9]
- [Severity]: MINOR
- [Finding]: Risk levels undervalue some tasks: MC-014 (Cloudflare Tunnel + Access) medium but involves external service config/auth (high failure modes); MC-024 (FIF SQLite, DB-locked handling) medium but data integrity risk.
- [Why]: Miscalibration could underprepare sessions; highest risks (aggregator) correctly high, but infra gaps.
- [Fix]: Bump MC-014/MC-024 to high; add risk notes (e.g., "DB corruption").

- [F10]
- [Severity]: MINOR
- [Finding]: Dependency graph misses M6 (Knowledge) parallel with M5, but tasks allow (MC-040 on MC-012); MC-035 retro deps only on M2/M3/M4 tests, omitting M1/M6 if parallel.
- [Why]: Minor sequencing ambiguity; critical path ok but retro gate incomplete if parallels slip.
- [Fix]: Update MC-035 deps to all Phase 1 (MC-018,023,028,034) + M6 tests if done.

- [F11]
- [Severity]: MINOR
- [Finding]: No task covers "M-Web kill-switch at M3" from spec/plan.
- [Why]: Phase 1 build order explicit; parity gate (MC-028) but no deactivation task.
- [Fix]: Add MC-028.5: "Deploy M-Web kill-switch post-parity".

- [F12]
- [Severity]: STRENGTH
- [Finding]: PC-1 aggregator mitigation reflected well in tasks (MC-029 single-source -> MC-030 Phase 1 multi -> M5 full), despite M4 criteria mismatch.
- [Why]: Riskiest element (spec-flagged asymmetry) properly sequenced with tests (MC-034).
- [Fix]: N/A

- [F13]
- [Severity]: STRENGTH
- [Finding]: Testing strategy (PC-7) tightly integrated: adapter units per milestone (e.g., MC-023,043,052), aggregator ints at M4/M5 (MC-034), retro evaluation.
- [Why]: Balances ceremony budget (C6); high-value tests without overkill.
- [Fix]: N/A

- [F14]
- [Severity]: STRENGTH
- [Finding]: Phase 1 retrospective (MC-035) positioned as hard gate post-M4, evaluating SC-1/3/5, testing/SSE; dependencies align with Phase 1 completion.
- [Why]: Enforces spec's mandatory 1-week usage + decisions (e.g., SSE upgrade).
- [Fix]: N/A
