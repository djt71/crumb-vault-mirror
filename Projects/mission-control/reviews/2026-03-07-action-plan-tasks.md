---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/mission-control/design/action-plan.md
companion_artifact: Projects/mission-control/design/tasks.md
artifact_type: action-plan
artifact_hash: 5f998403
prompt_hash: becdebf8
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
  soft_heuristic_triggered: true
  user_override: false
  warnings:
    - "Soft: 'customer' appears 18 times — legitimate domain references (Customer/Career page)"
    - "Soft: 'pii' appears 1 time — in task MC-050 acceptance criteria (privacy constraint)"
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 46625
    attempts: 1
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-tasks-openai.json
  google:
    http_status: 200
    latency_ms: 52854
    attempts: 1
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-tasks-google.json
  deepseek:
    http_status: 200
    latency_ms: 205493
    attempts: 2
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-tasks-deepseek.json
  grok:
    http_status: 200
    latency_ms: 38777
    attempts: 1
    raw_json: Projects/mission-control/reviews/raw/2026-03-07-action-plan-tasks-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Action Plan + Tasks

**Artifact:** Projects/mission-control/design/action-plan.md + tasks.md
**Mode:** full
**Reviewed:** 2026-03-07
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
**Review prompt:** Full review of action plan (10 milestones) and task decomposition (52 tasks) for Mission Control dashboard. Focus areas: milestone sequencing, task scoping, dependency correctness, risk calibration, coverage gaps, R2 constraint resolution quality.

---

## OpenAI (gpt-5.2)

- [F1]
- [Severity]: CRITICAL
- [Finding]: The Phase 1 testing strategy calls for a Playwright smoke test at M1 (PC-7), but no task implements it.
- [Why]: This is explicitly committed "at M1" and is the only end-to-end safety net ensuring routing, nav shell, and the basic API contract work together before page work begins.
- [Fix]: Add a task under Milestone 1, e.g. **MC-0XX: Playwright smoke test** with AC: `npx playwright test` runs headless in CI/local, loads `/` (web), navigates to each route, asserts `/api/health` and `/api/nav-summary` return 200 and expected shape.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Task scoping frequently exceeds the "<=5 file changes each" target; several tasks are multi-day, multi-surface bundles.
- [Why]: Oversized tasks reduce parallelism, increase risk, and make it hard to "finish" cleanly. This is most acute in M1 scaffolding and several frontend page tasks that bundle many panels + interactions.
- [Fix]: Split large tasks into smaller vertical slices. Examples:
  - Split **MC-012** into API server skeleton vs route stubs vs logging.
  - Split **MC-021/MC-022** into KPI strip, service grid, timeline, cost panel, and refresh/stale UI.
  - Split **MC-026** into KPI strip vs digest panel vs pipeline health panel.

- [F3]
- [Severity]: CRITICAL
- [Finding]: "No React code before Phase 0 passes" (C3) is respected at the milestone level, but the tasks don't enforce it—there's no explicit guardrail preventing premature implementation.
- [Why]: This is a top constraint; if violated, you risk rework and divergence from the validated mockups.
- [Fix]: Add an explicit acceptance criterion to **MC-011** (or a new "Phase 0 gate enforcement" task) stating: Phase 1 implementation must reference exported Phase 0 mockups (paths, screenshots) and the gate doc; optionally add a lightweight repo check (e.g., CI failing if Phase 1 branch exists before MC-010 done—procedural, not technical).

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Dependency graph and milestone dependencies understate that **M4 Attention-lite** depends on **M1's nav shell + polling** and likely on **MC-018 conventions** (SafeMarkdown, time semantics, adapter contract) to avoid duplicated patterns.
- [Why]: In practice the Attention page will immediately need the polling hook, UTC/local rendering utilities, and safe markdown rendering for any note content previews.
- [Fix]: Tighten dependencies:
  - Set M4 milestone dependency to **M1** (not just M2) or update M4 tasks (MC-032/033) to depend on **MC-017 and MC-018** explicitly.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Cloudflare Access header verification is only specified for Customer endpoints (good), but the plan doesn't define a reusable middleware / test harness pattern for this enforcement.
- [Why]: Without a shared middleware, enforcement can be inconsistent, and tests become ad hoc. Also, "cannot independently verify" the exact header names and verification method required by Cloudflare Access in this environment.
- [Fix]: Add an M1 task or extend **MC-018** to include `requireAccessAuth()` middleware + unit tests with documented expected headers (e.g., CF Access JWT header) and a clear configuration mechanism.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: "Adapter return contract `{data, error, stale}`" is documented and applied, but there's no explicit task ensuring the *frontend* has a consistent empty/error/stale component library aligned to the Phase 0 visual patterns.
- [Why]: The spec and Phase 0 gate emphasize empty/error/stale treatments; if each page hand-rolls, visual and behavioral consistency will drift.
- [Fix]: Add a Milestone 1 web task (or extend MC-018) to implement shared UI primitives: `<EmptyState/>`, `<ErrorState/>`, `<StaleBanner/>`, `<LastUpdated/>`, with styling derived from Phase 0 deliverables.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Time semantics (PC-3) are documented, but not clearly implemented as shared utilities; tasks don't mention a canonical "parse + format" helper or sort-key enforcement tests.
- [Why]: Time bugs (UTC vs local, sort drift) are a classic dashboard failure mode, especially with mixed sources (files, APIs, SQLite).
- [Fix]: Extend **MC-018** with `time.ts` helpers (`toUtcIso()`, `formatLocal()`, `compareByPageSortKey()`) plus unit tests; require usage via lint rule or code review checklist.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: The Attention aggregator dedup rules are inconsistent across tasks: Phase 1 says dedup by `attention_id` and `source_ref` generally (MC-030), Phase 2 adds "same source_ref within 24h" update semantics (MC-038). But Phase 1 quick-add (MC-031) always creates a new note.
- [Why]: If quick-add can create duplicates that should have been merged/updated, you'll accumulate clutter early—exactly what Attention is meant to prevent.
- [Fix]: Decide and encode a Phase 1 stance:
  - Either implement 24h source_ref dedup in **MC-031** (when `source_ref` is provided), or
  - Explicitly defer source_ref-based update semantics to M5 and state in MC-031 AC that it always creates new items (and aggregator will merge visually only).

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: Write atomicity is addressed via `writeVaultFile()` (good), but the plan doesn't mention concurrency safeguards for simultaneous updates (e.g., two PATCH calls) or collision handling for `att-YYYYMMDD-NNN` generation.
- [Why]: Even single-user systems can generate collisions via double-submit, refresh retry, or automation. Atomic rename alone doesn't prevent logical conflicts.
- [Fix]: Add acceptance criteria/tests:
  - **MC-031**: ID generator checks existence and increments; include unit test for collision.
  - **MC-044**: optimistic concurrency (optional) using `updated` timestamp check, or at least "last write wins" explicitly documented.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Milestone 6 "Knowledge page" depends on M1 and can run in parallel with M5 (good), but **MC-040** includes multiple complex adapters (QMD + AKM + project health) likely exceeding the task-size target and risk.
- [Why]: This is a lot of heterogeneous parsing/integration in one task and could become a sink.
- [Fix]: Split MC-040 into 4 tasks (one per adapter) and keep MC-042 frontend similarly sliced (vault health first, then AKM, then project grid, then tag viz).

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The action plan claims "No intermediate database" and "optional SQLite cache if performance budget exceeded," but there's no explicit task capturing *how to measure* performance budget or when to introduce caching.
- [Why]: Without a measurement gate, performance issues will be handled reactively and may lead to premature caching or none when needed.
- [Fix]: Add a small M2 or M4 task: "Performance instrumentation" (simple timings per adapter + response size; log slow adapters; define thresholds).

- [F12]
- [Severity]: MINOR
- [Finding]: Dependency graph shows Phase 3 after "M5/M6," but M8/M9/M10 tasks only depend on M1 (and for M8, M3). This is internally inconsistent.
- [Why]: Readers will be confused about whether Phase 3 is actually gated by Phase 2 completion.
- [Fix]: Align wording: either (a) truly gate Phase 3 on M5+M6 and update task dependencies, or (b) update the dependency graph text to reflect that Phase 3 can begin after M1/M3 but is scheduled later for focus reasons.

- [F13]
- [Severity]: MINOR
- [Finding]: MC-015 says launchd starts "Express API (or combined dev server)"—but production should not rely on dev servers (Vite dev server).
- [Why]: Operational reliability and security. Also affects SC-7 ("dashboard is a monitored service").
- [Fix]: Clarify AC: launchd runs a production build (`npm run build` + `npm run start`) or a single Node server serving static web assets + API; document environment variables and log rotation.

- [F14]
- [Severity]: MINOR
- [Finding]: Several tasks reference TOP-050 / TOP-049 / TOP-050 structured logs but these aren't described here; cannot independently verify availability or schema stability.
- [Why]: Hidden upstream dependency risk.
- [Fix]: Add explicit "expects schema X" notes in adapter tasks and a fallback behavior if logs absent (return stale/error with placeholder UI).

- [F15]
- [Severity]: STRENGTH
- [Finding]: The PLAN-phase constraint resolutions (PC-1..PC-9) are explicitly recorded and mapped into milestones/tasks (notably PC-1 single-source aggregator first, PC-2 nav-summary, PC-9 polling-first).
- [Why]: This directly addresses the R2 addendum intent: decisions are made, recorded, and operationalized.
- [Fix]: None.

- [F16]
- [Severity]: STRENGTH
- [Finding]: Cross-cutting conventions are given concrete implementation tasks early (MC-018) and referenced by downstream write endpoints and markdown rendering.
- [Why]: This prevents duplication and reduces security/consistency risks (DOMPurify, atomic writes).
- [Fix]: None (except enhancements noted in F6/F7).

- [F17]
- [Severity]: STRENGTH
- [Finding]: The retrospective is correctly positioned as a gate between Phase 1 and Phase 2 (MC-035) with explicit decision points (testing ceremony, SSE, scope).
- [Why]: This matches the spec's "mandatory pause" and is a pragmatic risk-control mechanism.
- [Fix]: None.

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: PC-4 ("health header auto-refresh on manual-pull pages via nav-summary") is implemented for the nav rail (MC-017) but not explicitly required in the Intelligence/Knowledge/Customer page frontend tasks.
- [Why]: Without explicit AC, it may be skipped, undermining the "always visible freshness/health" concept.
- [Fix]: Add AC to **MC-026**, **MC-042**, **MC-051**: include health strip component wired to nav-summary polling independent of manual refresh.

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: The "analog readout budget" (PC-5) is captured in design (MC-006) but not enforced in implementation tasks; Ops/Agents/Knowledge tasks could accidentally add bespoke gauges.
- [Why]: Without enforcement, the budget won't hold under "just one more gauge" pressure.
- [Fix]: Add an implementation-time check: a small lint/checklist item in MC-018 or code review checklist: any new gauge requires referencing the widget inventory entry and must be within the 4 allowed.

- [F20]
- [Severity]: MINOR
- [Finding]: Some acceptance criteria include subjective performance statements ("scannable in <10s", "answers in <5s") without specifying how to evaluate.
- [Why]: These are good UX targets but hard to test consistently.
- [Fix]: Add a lightweight evaluation method in AC (e.g., timed self-test with a checklist: identify top 3 urgencies; identify active incident; identify top cost driver).

Summary of factual claims I cannot independently verify (as requested):
- Exact availability/schemas of: `_openclaw/state/dispatch/` files, FIF SQLite DB schema/paths, TOP-050 structured logs, Healthchecks.io API access, QMD API wrapper, akm-feedback.jsonl format, and Cloudflare Access header/JWT verification details in this environment.

---

## Google (gemini-3-pro-preview)

## Review of Mission Control Dashboard Action Plan & Tasks

This review evaluates the Action Plan and Task Decomposition for the Crumb Mission Control dashboard. The artifacts generally demonstrate a high level of architectural maturity, particularly in the "Design First" approach (Phase 0) and the rigorous constraint resolutions. The "Ceremony Budget" principle is well-respected throughout.

However, there is a **CRITICAL** gap regarding the implementation of the testing strategy promised in the Action Plan, and **SIGNIFICANT** architectural and scoping issues regarding security placement and task atomicity.

### 1. Critical Findings

**[F1] [CRITICAL] [Missing E2E Infrastructure in Tasks]**
*   **Finding:** The Action Plan's resolution for **PC-7 (Testing Strategy)** explicitly states: *"E2E: Single Playwright smoke test at M1 (nav loads, pages route, health endpoint responds)."* However, **Phase 1 tasks (MC-011 through MC-018)** contain no entry for installing Playwright, configuring the test runner, or writing this smoke test.
*   **Why:** This leaves a governance gap. The Plan commits to a testing layer that the Task list fails to implement, creating technical debt immediately at M1. Without the smoke test, the "deployment success" criteria for M1 cannot be automated or verified as planned.
*   **Fix:** Add a new task **MC-017b** (or integrate into MC-013/MC-017) explicitly titled "E2E Test Infrastructure & Smoke Test." Scope: Install Playwright, configure for localhost/CI, write one test verifying the health endpoint and React shell load.

### 2. Significant Findings

**[F2] [SIGNIFICANT] [Task Atomicity Violation in MC-009]**
*   **Finding:** Task **MC-009** is explicitly flagged in the text as *"Dense task -- may span 2 sessions."* It bundles four distinct deliverables: Intelligence page mockup, Nav shell mockup, state patterns, and mobile viewport testing for *other* pages.
*   **Why:** This violates the atomic task principle. Large tasks obscure progress and increase the risk of partial completion (carry-over work). "Mobile viewport testing" for Attention/Ops is logically distinct from "Intelligence Page Mockup."
*   **Fix:** Split into two tasks:
    *   **MC-009a:** Intelligence Page Mockup + Nav Shell.
    *   **MC-009b:** Global States (Empty/Error) + Mobile Viewport Verification (Attention/Ops).

**[F3] [SIGNIFICANT] [Security Logic Coupling (C7)]**
*   **Finding:** Task **MC-050** states: *"dossier-scanner.ts adapter... Endpoint verifies Cloudflare Access headers."*
*   **Why:** This implies placing HTTP header validation logic inside the *Data Adapter* (file reader). This is an architectural error. In an Express BFF, security headers should be validated at the **Route/Controller** or **Middleware** level, not in the data access layer. Coupling the adapter to the HTTP request object makes the adapter untestable (requires mocking Express request objects) and less reusable.
*   **Fix:** Rewrite MC-050 description to remove header verification. Ensure the route creation task (or a shared middleware task in M1) handles the Cloudflare Access verification for the `/api/customer` path.

**[F4] [SIGNIFICANT] [Missing Integration Steps for Nav Summary]**
*   **Finding:** Milestone 1 builds the `nav-summary` endpoint (MC-017), but Milestones 2-6 (Page builds) do not explicitly list tasks to *integrate* their new data into that summary endpoint.
*   **Why:** The `nav-summary` endpoint aggregates status from all domains. When the Ops Adapters are built in M2, the `nav-summary` controller must be updated to import and use them; otherwise, the badges remain static/mocked. Implicit integration steps are a common source of bugs in "Unified Visibility" dashboards.
*   **Fix:** Add a specific line item to the "Frontend/Integration" task of each milestone (e.g., MC-022, MC-033, MC-042) to "Wire page metrics into nav-summary controller."

### 3. Minor Findings

**[F5] [MINOR] [Ambiguity in Aggregator Strategy (M4)]**
*   **Finding:** The Action Plan text for PC-1 says M4 is *"single source (dispatch pending files)."* However, Task **MC-030** (also M4) explicitly adds *"remaining Phase 1 sources: FIF health, vault-check, Healthchecks."*
*   **Why:** The Task list describes a *multi-source* aggregator (System sources), whereas the Plan text implies a *single-source* aggregator. This discrepancy creates confusion about the definition of "single source."
*   **Fix:** Update the Action Plan text for PC-1 to clarify: "M4 builds the aggregator for **System sources** (Dispatch, FIF, Healthchecks). M5 expands to **Vault sources** (Notes/Markdown)."

**[F6] [MINOR] [Responsiveness Implementation Gaps]**
*   **Finding:** Phase 0 requires mobile mockups (MC-009), but the frontend build tasks (MC-021, MC-032) do not explicitly mention implementing responsive/mobile CSS.
*   **Why:** Ideally, the implementation tasks should reference the Phase 0 gate requirement to ensure the mobile view isn't forgotten during the React build.
*   **Fix:** Add "verify mobile responsiveness matches M0b" to the acceptance criteria of MC-021 (Ops) and MC-032 (Attention).

**[F7] [MINOR] [Search Input Wiring]**
*   **Finding:** Task MC-041 builds the shared search endpoint, but there is no explicit task to wire the **Navigation Bar Search Input** (created in M1) to this endpoint once it exists in M2/Phase 2.
*   **Why:** The search bar exists in the shell from Phase 1 but is non-functional until Phase 2. The wiring step is easily overlooked.
*   **Fix:** Add "Connect Nav Bar search input to search endpoint" to Task MC-042 (Knowledge Page Frontend).

### 4. Strengths

*   **Design Gate Robustness:** The Phase 0 breakdown (M0a/M0b) is excellent. It forces visual decisions (analog budget, aesthetic direction) before a single line of React code is written, effectively mitigating the "eternal tweaking" risk common in frontend projects.
*   **Constraint Resolution:** The handling of **PC-9 (SSE vs Polling)** is pragmatic and well-reasoned. The decision to stick with polling for Phase 1 reduces complexity significantly while leaving a clear upgrade path.
*   **Atomicity Pattern:** The use of `writeVaultFile()` (MC-018) as a shared utility for atomic writes properly addresses the data integrity constraint (R2-4) once, centrally, rather than scattering logic across endpoints.

### 5. Verification of Claims

*   **Independent Verification:** I cannot independently verify the existence of the specific scripts `system-stats.sh` or `service-status.sh` mentioned in MC-016, as they are external dependencies. The plan assumes they will be created or exist.
*   **Launchd:** The tasks assume macOS architecture (launchd). This matches the "Mac Studio" constraint in the spec summary.

### 6. Summary Recommendation

The artifacts are high quality but require one **CRITICAL** adjustment: the **E2E/Playwright tasks** must be added to Phase 1 to match the Action Plan's promise. The **Security Logic** for Cloudflare Access must be moved out of the adapter description to avoid architectural confusion. Finally, split the "Dense" design task (MC-009) to ensure smooth execution.

**Approve with Required Amendments.**

---

## DeepSeek (deepseek-reasoner)

## Review of Mission Control Dashboard Action Plan & Task Decomposition

### Summary
The artifacts are exceptionally well-structured and comprehensive. They demonstrate thorough understanding of the specification and effectively decompose the work into manageable milestones and atomic tasks. The resolution of PLAN-phase constraints is integrated thoughtfully. A few sequencing, dependency, and coverage issues require attention.

---

### Findings

#### **F1**
- **Severity:** SIGNIFICANT
- **Finding:** Missing dependency for Attention-lite tasks (M4) on Ops adapter pattern validation.
- **Why:** The action plan states M4 "Depends on: M2 (adapter pattern proven)". However, tasks MC-029 through MC-034 list only MC-012 (Express API scaffold) as a dependency. Building the complex attention aggregator before validating the adapter pattern in M2 increases integration risk.
- **Fix:** Update dependencies for MC-029, MC-030, MC-031, MC-032, MC-033, MC-034 to include MC-023 (Ops adapter unit tests) or a specific M2 task that signifies adapter pattern validation.

#### **F2**
- **Severity:** SIGNIFICANT
- **Finding:** Missing task for initial E2E/Playwright smoke test mentioned in PC-7.
- **Why:** The testing strategy (PC-7) specifies "Single Playwright smoke test at M1 (nav loads, pages route, health endpoint responds)". No corresponding task exists in Milestone 1 (MC-011 to MC-018).
- **Fix:** Add a new task (e.g., MC-019A) to Milestone 1: "E2E smoke test setup". It should depend on MC-013 and MC-014, with acceptance criteria: Playwright configured, single test passes verifying nav loads, pages route, and `/api/health` responds.

#### **F3**
- **Severity:** SIGNIFICANT
- **Finding:** Critical path description in the action plan is inaccurate and contradicts the dependency graph.
- **Why:** The action plan states the critical path is `M0a -> M0b -> M1 -> M2 -> M3 -> M4 -> Retrospective -> M5 -> M7`. However, the dependency graph and task logic show M3 and M4 can run in parallel after M2. The *actual* critical path to the retrospective is the *longer* of M3 or M4. Currently, M4 (Attention-lite) is flagged as higher risk and likely longer. The stated path incorrectly sequences them serially.
- **Fix:** Update the critical path description to: `M0a -> M0b -> M1 -> M2 -> M4 -> Retrospective -> M5 -> M7`, with M3 noted as parallel to M4. Or, more accurately, state: "Critical path is the longest of M3 or M4 after M2."

#### **F4**
- **Severity:** MINOR
- **Finding:** Task MC-016 ("system-stats.sh + service-status.sh scripts") combines script creation with deployment, which are distinct activities.
- **Why:** The acceptance criteria mix creation ("scripts exist...") with deployment ("Manual step -- install plists..."). This could lead to the task being marked complete before the deployment step, which is essential for M2 (Ops page).
- **Fix:** Split into two tasks: MC-016a (script creation) and MC-016b (deployment & verification). Or, clarify that the task is not complete until deployment is verified.

#### **F5**
- **Severity:** MINOR
- **Finding:** The dependency of MC-052 ("Phase 3 adapter tests") on MC-046, MC-048, MC-050 is too broad.
- **Why:** MC-052's acceptance criteria require unit tests for "all Phase 3 adapters". Listing dependencies on the frontend task IDs (MC-046, MC-048, MC-050) is imprecise; it should depend on the *adapter creation* tasks within those milestones.
- **Fix:** Update MC-052 dependencies to the specific adapter tasks: MC-046 itself is an adapter task (correct), but MC-048 and MC-050 are frontend page tasks. Change depends_on to: MC-046, MC-048's adapter sub-tasks (to be defined), MC-050's adapter sub-task (MC-050).

#### **F6**
- **Severity:** MINOR
- **Finding:** The "Analog Readout Budget" (PC-5) resolution pre-selects candidate gauges, which could bias the Phase 0 design exploration.
- **Why:** The action plan lists four suggested gauge candidates (CPU, Memory, Cost, Vault Health). While noted as "not pre-committed", presenting them as suggestions may inadvertently constrain the design exploration in M0a/M0b, contradicting the intent to let design decide.
- **Fix:** In the PC-5 resolution, remove the list of suggested candidates. State only the constraint ("Maximum 4 custom SVG gauge components") and that the widget inventory (MC-006) will categorize candidates based on design exploration.

#### **F7**
- **Severity:** STRENGTH
- **Finding:** Excellent risk mitigation for the high-risk aggregator (PC-1) via single-source-first progression.
- **Why:** The task decomposition (MC-029 for single source, MC-030 for multi-source) perfectly reflects the strategy. This provides a clear validation checkpoint before adding complexity.

#### **F8**
- **Severity:** STRENGTH
- **Finding:** Comprehensive integration of R2 constraint resolutions into the task fabric.
- **Why:** Each of the 9 PLAN-phase constraints is addressed with a clear decision in the action plan, and those decisions are translated into specific tasks (e.g., MC-006 for widget inventory, MC-017 for nav-summary, MC-018 for conventions).

#### **F9**
- **Severity:** STRENGTH
- **Finding:** Phase 1 Retrospective is correctly positioned as a mandatory gate with clear evaluation criteria.
- **Why:** Task MC-035 has explicit acceptance criteria that force evaluation of success criteria, technical decisions (SSE, testing), and scope for Phase 2. This prevents unchecked scope creep.

#### **F10**
- **Severity:** STRENGTH
- **Finding:** Cross-cutting conventions (write atomicity, sanitization, error handling) are centralized and tasked early.
- **Why:** Task MC-018 ensures foundational utilities (`writeVaultFile`, `SafeMarkdown`) and documentation (`CONVENTIONS.md`) are built in M1, providing a consistent base for all subsequent work.

### Verdict
The artifacts are of high quality. The three SIGNIFICANT findings (F1, F2, F3) should be addressed before execution begins, as they pertain to foundational sequencing and completeness. The MINOR findings are refinements. The strengths demonstrate sophisticated planning and risk management. The plan is actionable and well-aligned with the specification.

---

## Grok (grok-4-1-fast-reasoning)

[F1]
[Severity]: CRITICAL
[Finding]: No task implements production serving of the React web build (e.g., via Express static middleware serving Vite's `dist/` output). M1 scaffolding (MC-011 to MC-018) sets up dev servers (`npm run dev`) and launchd for API (MC-015), but prod access via Cloudflare Tunnel (MC-014) requires a built web app served alongside or by the API. No build script, static route, or prod mode handling exists in tasks.
[Why]: Without this, the dashboard won't render pages in prod after auth; users see only API responses or 404s. Breaks M1 success criteria ("Dashboard accessible via Cloudflare Tunnel") and all subsequent milestones. Contradicts monorepo architecture expecting Express BFF to proxy/serve frontend.
[Fix]: Insert new task MC-018.5 (after MC-018): "Prod web build & Express static serve" -- Add `npm run build` script in web package, Express middleware (`app.use(express.static('packages/web/dist'))`) in prod mode, update launchd to run `npm run build && npm run start:prod` in API package. Unit test build output. Risk: low. Depends on: MC-013, MC-018.

[F2]
[Severity]: CRITICAL
[Finding]: No implementation task for Cloudflare Access header verification middleware on sensitive endpoints (e.g., /api/customer). Cross-cutting conventions mention "Customer-intelligence data endpoints verify Cloudflare Access headers (C7)", MC-014 sets up policy, MC-050 notes it in adapter description, and MC-052 tests endpoint rejection, but no task creates the Express middleware (e.g., `cfAccessVerify(req.headers)` guarding routes).
[Why]: Privacy constraint C7 and PC-2 nav-summary explicitly exclude customer data without verification; raw PII could leak on misconfigured requests. Breaks spec Key Decisions (privacy-constrained) and M10 success criteria. Hidden dependency for all customer endpoints.
[Fix]: Add task in M1 MC-012.5 (after API scaffold): "Privacy middleware for C7 endpoints" -- Implement `verifyCfAccessHeaders()` middleware (check `CF-Access-*` headers), apply to /api/customer routes and nav-summary exclusion logic. Test in MC-052 expanded. Risk: medium. Depends on: MC-014.

[F3]
[Severity]: SIGNIFICANT
[Finding]: E2E/Playwright smoke test (per PC-7: "Single Playwright smoke test at M1 (nav loads, pages route, health endpoint responds)") is entirely missing from tasks. PC-7 testing strategy mandates it at M1, but no MC-xxx task sets up Playwright, configures Vitest/Playwright, or writes the smoke test.
[Why]: Leaves testing strategy incomplete (only unit/integration mentioned), risks undetected regressions in scaffolding/nav critical path. PC-7 positions it as highest-value early validation; omission orphans testing gate for Phase 1.
[Fix]: Add task MC-014.5 in M1 (after MC-014): "E2E smoke tests with Playwright" -- Install Playwright in web package, write smoke test (auth login, nav route to stubs, /api/health + /nav-summary fetch), run on CI/dev. Expand per-page in later milestones (e.g., MC-023.5). Risk: low. Depends on: MC-013, MC-017.

[F4]
[Severity]: SIGNIFICANT
[Finding]: Aggregator risk mitigation (PC-1: single-source first in M4, validate pattern before multi-source) is partially undermined -- MC-029 (single-source dispatch) lacks explicit integration test validation before MC-030 adds sources. Tests deferred to MC-034 (after full Phase 1 sources).
[Why]: PC-1 isolates "riskiest integration point"; without single-source test gate in MC-029, early bugs propagate to multi-source, inflating M4 risk (already high). Contradicts "validate the aggregation pattern" before expansion.
[Fix]: Split MC-034 tests: MC-029.5 "Attention single-source unit/integration tests" (verify dispatch normalization/sort/dedup with fixtures) before MC-030. Move multi-source integ to MC-034. Update MC-029 AC: "Integration test passes."

[F5]
[Severity]: SIGNIFICANT
[Finding]: Phase 1 Retrospective (MC-035) depends only on tests (MC-023,028,034), not explicit deploys/usage readiness of M1-M4. Success criteria require "1-week usage period", but no task confirms prod deploys (e.g., launchd verified post-M4, tunnel stable).
[Why]: Risks retro on incomplete/broken deploys; hidden dep on full M1-M4 success (e.g., M2/M3/M4 frontends). Breaks action plan's "M1-M4 deployed, 1-week usage" and gate positioning.
[Fix]: Update MC-035 Depends On to include MC-018 (M1 complete), MC-023 (M2), MC-028 (M3 gate), MC-034 (M4), plus new "M4 deploy verification" stub. Add AC: "Confirm launchd stable, tunnel access, 1-week usage log."

[F6]
[Severity]: SIGNIFICANT
[Finding]: Coverage gap for spec's "Auto-refresh pauses when tab not visible" -- MC-017 implements `usePolling` hook with pause on tab invisible, but no AC verifies it (e.g., test or manual). No frontend tests evaluate it.
[Why]: Core UX constraint (data refresh strategy); unverified wastes battery/CPU. PC-7 defers React tests to retro, but hook is cross-cutting M1 deliverable.
[Fix]: Add to MC-017 AC: "Hook pauses/resumes on Visibility API change (tested manually/devtools)." Add MC-017.5 "Polling hook unit test (visible/invisible states)."

[F7]
[Severity]: MINOR
[Finding]: Task scoping inconsistency -- MC-009 explicitly "dense task -- may span 2 sessions", but others like MC-017 (nav-summary endpoint + React hook + health strip impl across manual pages + nav badges) or MC-038 (full aggregator expansion + dedup/staleness/counts) likely >5 file changes without "dense" flag.
[Why]: Risks uneven session estimates; operator underplans chunky tasks. Violates "atomic tasks" intent.
[Fix]: Flag MC-017/MC-038/MC-042 as dense (2 sessions). Split MC-017: MC-017a endpoint, MC-017b hook/impl.

[F8]
[Severity]: MINOR
[Finding]: Risk calibration low for several medium-risk tasks -- e.g., MC-010 (design gate review, high per tasks but depends on dense MC-009), MC-028 (M-Web parity gate + tests, high), but MC-024 (FIF SQLite adapter, complex DB parsing/locking, medium).
[Why]: Understates setup/parsing risks (e.g., FIF DB schema changes); miscalibrates priority. Aggregator highs good, but inconsistent.
[Fix]: Bump MC-024/MC-040 (adapters with external deps like FIF/QMD) to high. Downgrade MC-003 (aesthetic decision) from medium to low.

[F9]
[Severity]: STRENGTH
[Finding]: 9 PLAN-phase constraints (PC-1 to PC-9) resolved comprehensively in action plan, with direct task mappings (e.g., PC-1 in MC-029/030/038 progression; PC-2/4 in MC-017; PC-5/6 in MC-006; PC-7 testing per milestone like MC-023/034). No under-addressed items.
[Why]: Fully closes R2 addendum gaps; progressive aggregator (single->multi) reflected accurately. Enables spec-to-plan traceability. Verified against spec PLAN-Phase Constraints. Edge: SSE upgrade path gated at retro (MC-035).

[F10]
[Severity]: STRENGTH
[Finding]: Milestone sequencing/dependency graph accurate and critical path correct (M0->1->2->3->4->Retro->5->7); tasks reflect parallels (e.g., M3/M4 on M2/M1, no false deps like MC-040 only on MC-012). No cycles/orphans.
[Why]: Minimizes sessions (22-36 target); respects gates (design M0b, M-Web M3, retro). Verified graph vs task deps (e.g., MC-047 on MC-026). Edge: M6/M8/M9/M10 loose deps allow parallelism post-Retro.

[F11]
[Severity]: STRENGTH
[Finding]: Cross-cutting conventions (write atomicity MC-018 `writeVaultFile`, sanitization `SafeMarkdown`, error triples, privacy noted) implemented early in M1 (MC-018), referenced in writes (MC-031/044). Testing strategy integrated per milestone (adapters units, aggregator integ).
[Why]: Prevents duplication/regression; upholds R2-4/5. Verified usages (e.g., M4/M5/M7). Edge: Privacy middleware gap noted separately, but intent covered.

---

## Synthesis

**Note:** This dispatch reviewed the pre-amendment artifacts. A parallel multi-model synthesis (Claude Opus 4.6, DeepSeek V3.2, Gemini 3, ChatGPT GPT-5.2, Perplexity) produced 18 amendments that were applied before this dispatch returned. Findings already covered by those amendments are marked accordingly.

### Consensus Findings

| # | Finding | Reviewers | Status |
|---|---------|-----------|--------|
| C1 | Missing Playwright E2E task at M1 | OAI-F1, GEM-F1, DS-F2, GRK-F3 (4/4) | **Already resolved** — MC-057 added via AP-3/AP-18 |
| C2 | MC-009 oversized / needs split | OAI-F2, GEM-F2, GRK-F7 | **Already resolved** — split into MC-009 + MC-055 via AP-17 |
| C3 | Cloudflare Access middleware missing | OAI-F5, GEM-F3, GRK-F2 (3/4) | **Net-new** — no task creates `verifyCfAccessHeaders()` middleware |
| C4 | M4 tasks depend on MC-012 but should depend on M2 adapter pattern | OAI-F4, DS-F1, GRK (implied in F10) (3/4) | **Net-new** — task dependencies understate M2 prerequisite |
| C5 | Aggregator single-source test gate before multi-source expansion | OAI (implied in F8), GRK-F4 (2/4) | **Net-new** — no validation checkpoint between MC-029 and MC-030 |
| C6 | Nav-summary not wired per milestone | GEM-F4 (1/4, but architecturally sound) | **Net-new** — page milestones don't update nav-summary controller |

### Unique Findings (Net-New Only)

| # | Finding | Source | Assessment |
|---|---------|--------|------------|
| U1 | Production build/static-serve task missing | GRK-F1 (CRITICAL) | **Genuine insight** — no task produces a prod build or configures Express to serve static assets. Dev server via launchd won't work through Cloudflare Tunnel. |
| U2 | Tab visibility pause not tested | GRK-F6 | Minor but valid — MC-017 implements `usePolling` with visibility pause but no AC verifies it |
| U3 | Retro (MC-035) should depend on all M1-M4, not just test tasks | GRK-F5 | Valid — retro assumes "1-week usage" but doesn't depend on deploy verification |
| U4 | Phase 3 tasks only depend on M1 but graph shows after M5/M6 | OAI-F12 | Valid — clarify whether Phase 3 is truly gated or just scheduled later |
| U5 | Health strip not wired on manual-pull page frontends | OAI-F18 | Valid — PC-4 resolved but not enforced in MC-026/042/051 AC |
| U6 | Time utilities not explicit in MC-018 | OAI-F7 | Minor — could be implicit in "conventions doc" but worth noting |
| U7 | Performance instrumentation missing | OAI-F11 | Defer — premature before M2; retro is the right place to evaluate |
| U8 | MC-040 (Knowledge adapters) oversized | OAI-F10 | Valid — 4 heterogeneous adapters in one task |

### Contradictions

- **Critical path:** DS-F3 says M3/M4 are parallelizable (critical path should be longest of the two), while GRK-F10 says sequencing is correct. AP-10 already added a "build order honesty" note acknowledging M3/M4 parallelism — partially resolved.
- **MC-024 risk level:** GRK-F8 says bump to high (external FIF DB dependency); DS treats it as acceptable at medium. Leave at medium — FIF DB schema is controlled by us.

### Action Items

| # | Class | Finding Sources | Action |
|---|-------|-----------------|--------|
| A1 | **Must-fix** | C3 (OAI-F5, GEM-F3, GRK-F2) | Add task: Cloudflare Access verification middleware in M1 — `verifyCfAccessHeaders()` Express middleware, applied to `/api/customer` routes, tested. Remove header check from MC-050 adapter description. |
| A2 | **Must-fix** | U1 (GRK-F1) | Add task: Production build + Express static serve in M1 — `npm run build` script, Express serves `dist/`, launchd runs prod mode. |
| A3 | **Should-fix** | C4 (OAI-F4, DS-F1) | Update M4 task dependencies (MC-029–034) to include MC-023 (M2 adapter tests proven) instead of only MC-012. |
| A4 | **Should-fix** | C5 (GRK-F4) | Add AC to MC-029: "Integration test passes for single-source aggregation" before MC-030 expands to multi-source. |
| A5 | **Should-fix** | C6 (GEM-F4) | Add AC to page integration tasks (MC-022, MC-033, MC-042): "Nav-summary controller updated with page metrics." |
| A6 | **Should-fix** | U5 (OAI-F18) | Add AC to manual-pull page frontends (MC-026, MC-042, MC-051): "Health strip component wired to nav-summary polling." |
| A7 | **Defer** | U3 (GRK-F5) | MC-035 retro dependency expansion — procedural, operator will naturally wait for deploy stability |
| A8 | **Defer** | U8 (OAI-F10) | MC-040 split — evaluate at Phase 2 entry, may be fine as-is with adapter pattern proven by then |
| A9 | **Defer** | U7 (OAI-F11) | Performance instrumentation — retro is the right checkpoint |

### Considered and Declined

| Finding | Reason |
|---------|--------|
| OAI-F3 (Phase 0 gate enforcement task) | `constraint` — C3 is a procedural constraint enforced by the operator, not a technical guardrail. Adding a CI check for "no React before MC-010" is overkill for a solo developer. |
| OAI-F19 (gauge budget lint rule) | `overkill` — 4-gauge budget is tracked in widget inventory (MC-006) and enforced at design gate (MC-010). A lint rule for a solo dev is unnecessary ceremony. |
| DS-F6 (remove gauge candidates from PC-5) | `constraint` — candidates are explicitly "not pre-committed" and serve as useful context for Phase 0; removing them reduces helpful framing without benefit. |
| GRK-F8 (bump MC-024/040 to high risk) | `incorrect` — FIF DB schema is internally controlled; QMD adapter is a known API. Medium is calibrated correctly. |
| OAI-F8 (Phase 1 dedup stance) | `constraint` — spec §7.1 already defines dedup rules ("same source_ref within 24h → update existing"). Quick-add creates new items because they're human-authored with no source_ref collision. No ambiguity to resolve. |
| OAI-F12 (Phase 3 dependency alignment) | `out-of-scope` — Phase 3 tasks aren't decomposed to atomic level yet; dependency graph shows scheduling intent, not hard gates. Will be resolved at Phase 2→3 transition. |
| U4 (Phase 3 gate clarification) | Same as OAI-F12 above. |
