---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/crumb-tess-bridge/design/action-plan.md (Phase 2 section) + design/tasks.md (CTB-017 through CTB-031)
artifact_type: action-plan
artifact_hash: 9c82433f
prompt_hash: 8b7003e5
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-22
updated: 2026-02-22
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner (V3.2-Thinking)
  - xai/grok-4-1-fast-reasoning
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 54591
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-crumb-tess-bridge-phase2-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 50552
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-crumb-tess-bridge-phase2-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 39120
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-crumb-tess-bridge-phase2-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 34317
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-crumb-tess-bridge-phase2-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Phase 2 Action Plan — crumb-tess-bridge

**Artifact:** `design/action-plan.md` (Phase 2 section, M7-M13) + `design/tasks.md` (CTB-017 through CTB-031)
**Mode:** full
**Reviewed:** 2026-02-22
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
**Review prompt:** Structured review of Phase 2 action plan and task table. Focus areas: task scoping, dependency correctness, risk calibration, coverage, acceptance criteria quality. Dispatch protocol design provided as context.

---

## OpenAI (GPT-5.2)

- [F1]
- [Severity]: CRITICAL
- [Finding]: CTB-020/021 mismatch on where stage output comes from (runner "reads stage output JSON from outbox file") vs how `claude --print` actually returns output (stdout). Also unclear who writes `{dispatch_id}-stage-{N}.json`.
- [Why]: This is a blocking integration ambiguity: if the runner expects a file but the subprocess returns stdout, the walking skeleton (M8) can't work deterministically, and tests will be brittle/misleading.
- [Fix]: Make the contract explicit and consistent across CTB-019/020/021:
  - Option A (recommended): Stage runner captures stdout JSON from `claude --print`, validates it, then **writes** `_openclaw/outbox/{dispatch_id}-stage-{N}.json` (and transcripts) itself.
  - Update CTB-020 AC to "reads from stdout, writes stage file," and CTB-021 AC to match.
  - Add one test that asserts outbox stage file is produced by runner, not Claude.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Missing explicit task for the 8 new error codes end-to-end (definition, serialization, propagation, and mapping to user-facing responses/alerts). They appear in acceptance criteria but not as a cohesive implementation slice.
- [Why]: Error codes are cross-cutting: schema validation, watcher/engine responses, Tess formatting, tests. If not centralized, they'll drift or be inconsistently emitted, breaking E2E expectations and operational debugging.
- [Fix]: Add a small task (or amend CTB-017 + CTB-021/027) to:
  - Define error code enum/constants in both Node + Python (or single canonical list in schema).
  - Ensure every failure path maps to one of the 8 codes.
  - Add unit tests asserting code + message shape for each code.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: CTB-017 scope is too large (constants allowlist + schema bump + schema validators + bridge-processor rejection + unit tests) and likely exceeds "<=5 file changes."
- [Why]: This mixes spec changes, validation logic, and runtime routing behavior; increases review surface and risk of regressions to Phase 1.
- [Fix]: Split CTB-017 into:
  - CTB-017a: constants.js + schema.js (+ tests) for Phase 2 ops and version bump.
  - CTB-017b: bridge-processor.js explicit rejection + tests.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: CTB-021 (dispatch engine + watcher routing) is likely >5 files and conceptually bundles orchestration + watcher routing + integration tests.
- [Why]: Orchestration is the core runtime and will churn; routing changes to `bridge-watcher.py` are sensitive. Combining them raises rollback complexity.
- [Fix]: Split:
  - CTB-021a: dispatch_engine.py orchestrator (no watcher edits) + unit tests using a fake inbox/outbox.
  - CTB-021b: bridge-watcher.py routing switch + one integration test.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Hidden dependency: CTB-020 mentions "Pre-spawn CLAUDE.md hash check" and governance canary/hash, but there's no explicit task to define where the "expected" hash is stored, how it updates, and how Python verifies it.
- [Why]: Governance verification is a core safety control. If "expected hash" source-of-truth isn't pinned, attackers or normal edits will cause false fails or bypasses.
- [Fix]: Add/clarify in CTB-020 AC:
  - Exact file(s) hashed, canonicalization rules, where expected hash lives.
  - Whether Python reuses Node logic or re-implements canonical hashing.
  - Add a test covering "CLAUDE.md changed" => GOVERNANCE_STAGE_FAILED.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Budget enforcement is split between CTB-019 (defaults + caps) and CTB-022 (tracking + exceeded + warnings), but dependencies don't guarantee consistent source-of-truth for "remaining_wall_time / remaining_stages".
- [Why]: Budget logic tends to fork: prompt builder may announce budgets different from what runner enforces, producing confusing behavior and test flakes.
- [Fix]: Define a single `Budget` object/type in Python (created at dispatch creation, persisted in state, updated after each stage). Update CTB-019/022 AC to reference that shared module.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: CTB-024 escalation polling introduces inbox message correlation (dispatch_id + escalation_id), but there's no explicit task specifying inbox file naming, dedupe/idempotency, and what happens if multiple escalation-responses arrive (or wrong ones).
- [Why]: Real systems get retries, duplicates, and late responses; without idempotency rules you'll get stuck dispatches or wrong answer application.
- [Fix]: Tighten CTB-024 AC with binary rules:
  - Only accept first valid escalation-response; subsequent are ignored with logged warning.
  - Wrong escalation_id => ignored.
  - Late response after timeout => ignored.
  - Add tests for duplicate/late/wrong-id responses.

- [F8]
- [Severity]: MINOR
- [Finding]: CTB-018 "cleanup prunes files older than 30 days" is underspecified about which artifacts are pruned vs retained. CTB-027 later states different retention classes.
- [Why]: Conflicting retention causes either disk growth or loss of auditability.
- [Fix]: Make CTB-018 explicitly only prune dispatch state files and defer transcript/response retention rules to CTB-027.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: CTB-022 wall-time accounting: "Blocked time excluded from wall-time computation" is a major behavioral choice but acceptance criteria doesn't specify how (timestamps, multiple blocked intervals, restart behavior).
- [Why]: Incorrect accounting will cause premature BUDGET_EXCEEDED or allow runaway wall-time; also complicates crash recovery.
- [Fix]: Add explicit persisted fields in state: `started_at`, `blocked_started_at`, `total_blocked_seconds`. Unit tests for multiple block/resume cycles and restart mid-block.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: CTB-025 cancel semantics: "cancel takes effect at next stage boundary" is stated, but CTB-020 includes a subprocess timeout and retry; unclear whether a cancel request interrupts a retry or is only checked between stages.
- [Why]: Users expect cancel to stop further work quickly; retry loops can violate intent and budgets.
- [Fix]: Define rule: cancel is checked (a) before spawn, (b) before retry spawn, (c) after stage completion before deciding next. Add a test.

- [F11]
- [Severity]: MINOR
- [Finding]: CTB-023 status updates: "estimated_completion" field is required in AC but no algorithm is specified.
- [Why]: Non-deterministic estimates make tests flaky and can mislead users.
- [Fix]: Make `estimated_completion` nullable with deterministic behavior.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: CTB-026 Tess CLI support likely too large for <=5 files.
- [Why]: CLI parsing + formatting + watcher changes are independently testable and often churn.
- [Fix]: Split into CTB-026a (CLI parsing/validation) + CTB-026b (outbox watcher/formatting).

- [F13]
- [Severity]: MINOR
- [Finding]: CTB-030 "O(1) lookup confirmed" is not binary-testable in unit tests.
- [Why]: Micro-benchmarks are noisy; leads to subjective pass/fail.
- [Fix]: Replace with: "uses set data structure; duplicate check does not read file."

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: DISPATCH_CONFLICT error code not exercised in tasks/AC.
- [Why]: Undefined behavior under concurrency/retries.
- [Fix]: Add to CTB-021 AC: define conflict conditions, test asserting DISPATCH_CONFLICT.

- [F15]
- [Severity]: STRENGTH
- [Finding]: Good walking skeleton sequencing and explicit critical path.
- [Why]: Minimizes integration risk and enables early e2e feedback.

- [F16]
- [Severity]: STRENGTH
- [Finding]: Strong injection-resistance posture embedded into AC and tests.
- [Why]: Controls are exactly where dispatch protocols fail in practice.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: No schema-as-code for Python outputs (stage output, status files, final response).
- [Why]: Without a single schema source, validation logic and tests drift.
- [Fix]: Store JSON Schema files in repo; Python validates against them.

- [F18]
- [Severity]: MINOR
- [Finding]: CTB-018 marked low risk but includes state machine + crash recovery.
- [Why]: Bugs corrupt dispatch lifecycle.
- [Fix]: Reclassify to MEDIUM.

- [F19]
- [Severity]: MINOR
- [Finding]: CTB-031 allowlist AC missing whitespace/format error handling.
- [Why]: Misconfig could silently lock out all users.
- [Fix]: Add trimming, empty entries, malformed config tests.

- [F20]
- [Severity]: SIGNIFICANT
- [Finding]: No task specifies who writes alerts in Phase 2 dispatch path.
- [Why]: Alert pipeline for dispatch governance failures not covered.
- [Fix]: Extend CTB-020/021 to emit alerts on governance failure.

---

## Google (Gemini 3 Pro Preview)

[F1]
[Severity] SIGNIFICANT
[Finding] Incorrect dependency sequencing for CTB-025 (Cancel/Kill-switch).
[Why] CTB-025 is titled "Cancel-dispatch + inter-stage kill-switch" and currently depends only on CTB-021 (Single-stage). However, "inter-stage" logic and loop-based kill-switch checks conceptually require the Multi-stage Lifecycle (CTB-022) to be implemented first.
[Fix] Change CTB-025 Depends On from CTB-021 to CTB-022.

[F2]
[Severity] SIGNIFICANT
[Finding] Risk misclassification for CTB-025 (Kill Switch).
[Why] CTB-025 implements the primary safety override (kill-switch) and cancellation precedence rules. A failure could result in uncontrollable runaway agent or budget drain.
[Fix] Change CTB-025 Risk from medium to high.

[F3]
[Severity] MINOR
[Finding] Missing logic for DISPATCH_CONFLICT error code in CTB-021.
[Why] CTB-021 includes "flock acquisition" but does not specify behavior when acquisition fails.
[Fix] Add to CTB-021 AC: "If flock acquisition fails, reject request with DISPATCH_CONFLICT error."

[F4]
[Severity] MINOR
[Finding] Dispatch Engine alert writing is not explicitly tasked.
[Why] The new Dispatch Engine is separate from the Phase 1 watcher that writes alerts. No AC ensures the Dispatch Engine writes error JSONs to _openclaw/alerts/.
[Fix] Add to CTB-018 or CTB-020 AC: "Critical failures write structured alert JSON to _openclaw/alerts/."

[F5]
[Severity] MINOR
[Finding] Overloaded scope in CTB-026 (Tess CLI support).
[Why] Bundling input validation, complex parsing, and output formatting into one task increases bug risk.
[Fix] Consider splitting CTB-026 into input handling + output handling.

---

## DeepSeek (V3.2-Thinking)

**F1**
- **Severity**: SIGNIFICANT
- **Finding**: Task CTB-028 is excessively large, combining 8+ distinct system behaviors and all security injection tests.
- **Why**: Creates a monolithic testing task difficult to manage. A single failure could block the validation gate.
- **Fix**: Split: CTB-028a (E2E happy-path lifecycle), CTB-028b (failure/recovery), CTB-028c (injection payloads).

**F2**
- **Severity**: SIGNIFICANT
- **Finding**: Missing dependency: CTB-018 depends on schema definitions from CTB-017.
- **Why**: CTB-018's state machine must validate transitions and persist data defined in the Phase 2 schema.
- **Fix**: Update CTB-018 dependency to CTB-017.

**F3**
- **Severity**: SIGNIFICANT
- **Finding**: CTB-018 is marked "LOW" risk but is foundational for crash recovery and data integrity.
- **Why**: Bugs here could cause dispatch corruption, state leaks, or failure to recover properly.
- **Fix**: Reclassify CTB-018 risk from LOW to MEDIUM.

**F4**
- **Severity**: SIGNIFICANT
- **Finding**: No task explicitly handles centralized implementation of all 8 new error codes.
- **Why**: Risks inconsistency between Tess and Crumb sides.
- **Fix**: Add to CTB-017: "All 8 new dispatch error codes added to constants.js." Add to CTB-026: "Tess correctly formats all new error codes."

**F5**
- **Severity**: MINOR
- **Finding**: CTB-019 combines brief construction and prompt building — two distinct responsibilities.
- **Why**: Prompt building is a critical security component deserving its own task.
- **Fix**: Optional: split into brief construction + prompt builder.

**F6**
- **Severity**: MINOR
- **Finding**: CTB-027 depends only on CTB-021, but requires multi-stage (CTB-022) and escalation (CTB-024).
- **Why**: Deliverables from all stages and escalation count require later tasks.
- **Fix**: Update CTB-027 dependencies to CTB-021, CTB-022, CTB-024.

**F7**
- **Severity**: STRENGTH
- **Finding**: Acceptance criteria are generally well-specified, binary-testable, and tightly scoped to protocol sections.
- **Why**: Enables precise validation.

**F8**
- **Severity**: MINOR
- **Finding**: CTB-023 AC includes Tess-side formatting that belongs in CTB-026.
- **Why**: Creates cross-domain dependency and confusion.
- **Fix**: Move "echo-formatter.js formats status for Telegram" from CTB-023 to CTB-026.

**F9**
- **Severity**: SIGNIFICANT
- **Finding**: No task explicitly owns blocked state lifecycle and its effect on budget calculation.
- **Why**: Pausing/resuming wall-time clock is subtle but critical.
- **Fix**: Add to CTB-022: "Wall-time clock pauses when state enters blocked and resumes when it leaves blocked."

**F10**
- **Severity**: MINOR
- **Finding**: CTB-031 sender allowlist should be a prerequisite for production deployment.
- **Why**: Security gate for Phase 2 operational use.
- **Fix**: Clarify CTB-031 is a prerequisite for production deployment.

---

## Grok (4.1 Fast Reasoning)

- [F1]
  [Severity]: SIGNIFICANT
  [Finding]: Missing coverage for DISPATCH_CONFLICT error code; no task mentions handling concurrent dispatch conflicts.
  [Why]: Breaks completeness of error handling; risks unhandled race conditions.
  [Fix]: Add to CTB-018 or CTB-021: "DISPATCH_CONFLICT raised on flock failure or duplicate queued state."

- [F2]
  [Severity]: SIGNIFICANT
  [Finding]: CTB-020 depends only on CTB-018 (state), but stage runner requires prompt builder from CTB-019.
  [Why]: Breaks dependency correctness; task order infeasible.
  [Fix]: Update: CTB-020 depends on CTB-018 + CTB-019.

- [F3]
  [Severity]: SIGNIFICANT
  [Finding]: CTB-021 routes only initiating Phase 2 ops; omits escalation-response and cancel-dispatch.
  [Why]: Incomplete routing; these requests would incorrectly route to Phase 1 processor.
  [Fix]: Update CTB-021 AC: all 5 Phase 2 ops route to dispatch engine.

- [F4]
  [Severity]: CRITICAL
  [Finding]: Audit trail in CTB-027 uses batch concatenation but design specifies "chained stage transcript hashes" (sequential: hash_n = hash(hash_{n-1} || transcript_n)).
  [Why]: Mismatch undermines tamper-evident chaining; batch hash vulnerable to reordering attacks.
  [Fix]: Revise CTB-027 AC to use chained hashing.

- [F5]
  [Severity]: SIGNIFICANT
  [Finding]: CTB-019/022 enforce hard caps on advisory budgets (500 tool calls, 2M tokens), but design specifies only stages and wall-time as enforced; tool/token advisory only.
  [Why]: Over-constrains; risks false BUDGET_EXCEEDED on valid long tasks.
  [Fix]: Demote tool/token to advisory warnings only.

- [F6]
  [Severity]: SIGNIFICANT
  [Finding]: CTB-028 too large; exceeds scoping guideline.
  [Why]: Too large; high risk of incomplete tests.
  [Fix]: Split into happy/error/injection subtasks.

- [F7]
  [Severity]: SIGNIFICANT
  [Finding]: Critical path omits CTB-023/025/027 but CTB-028 depends on them.
  [Why]: Misleading critical path; hides true completion timeline.
  [Fix]: Update critical path to include parallel-but-blocking tasks.

- [F8]
  [Severity]: MINOR
  [Finding]: CTB-025 depends only on CTB-021; cancel precedence rules require multi-stage from CTB-022.
  [Why]: Hidden dependency.
  [Fix]: Add CTB-022 dependency to CTB-025.

- [F9]
  [Severity]: MINOR
  [Finding]: CTB-018 risk rated LOW; involves complex atomic writes and recovery logic.
  [Why]: State corruption could cascade.
  [Fix]: Reclassify to MEDIUM.

- [F10]
  [Severity]: MINOR
  [Finding]: CTB-018 AC claims "all 13 transition rules"; design summary lists ~6 states but no explicit count of 13.
  [Why]: Vague/non-binary; untestable without explicit list.
  [Fix]: List transitions explicitly or reference design table.

- [F11]
  [Severity]: MINOR
  [Finding]: CTB-020 "Pre-spawn CLAUDE.md hash check" — Python runner needs equivalent of verify-governance.js.
  [Why]: Unspecified implementation.
  [Fix]: Explicitly add "Python equiv of verify-governance.js."

- [F12]
  [Severity]: STRENGTH
  [Finding]: AC consistently reference design sections and specify tests.
  [Why]: Enables binary verification.

- [F13]
  [Severity]: STRENGTH
  [Finding]: Walking skeleton approach in M8 before layering complexity.
  [Why]: Reduces integration risk; prioritizes highest-value op.

- [F14]
  [Severity]: MINOR
  [Finding]: CTB-024 AC covers regex but misses edge cases (empty options, >3 questions overflow).
  [Why]: Incomplete edges.
  [Fix]: Add rejection tests for empty option, >3 questions, 81-char strings.

- [F15]
  [Severity]: STRENGTH
  [Finding]: Task scoping generally <=5 file changes.
  [Why]: Keeps tasks atomic.

- [F16]
  [Severity]: STRENGTH
  [Finding]: Budget enforcement separation matches design precisely.
  [Why]: Correct implementation of hard caps vs advisory.

---

## Synthesis

### Consensus Findings

**1. DISPATCH_CONFLICT error code missing from task AC (3 reviewers: OAI-F14, GEM-F3, GRK-F1)**
No task defines what constitutes a dispatch conflict or how it's raised. The error code exists in the protocol but isn't exercised in any acceptance criteria.

**2. CTB-018 risk should be MEDIUM, not LOW (3 reviewers: OAI-F18, DS-F3, GRK-F9)**
State machine transitions + crash recovery + atomic writes = non-trivial correctness code. LOW underestimates the debugging difficulty of state corruption bugs.

**3. Error codes not centrally tasked (2 reviewers: OAI-F2, DS-F4)**
The 8 new error codes appear in various task ACs but no single task ensures they're defined as constants, consistently emitted, and properly formatted on both sides.

**4. CTB-025 should depend on CTB-022 (2 reviewers: GEM-F1, GRK-F8)**
"Inter-stage" kill-switch and cancel precedence rules require multi-stage lifecycle to exist first. Single-stage dispatch can't exercise between-stage checks.

**5. Blocked time wall-time accounting underspecified (2 reviewers: OAI-F9, DS-F9)**
CTB-022 says "blocked time excluded" but doesn't specify the persisted fields or handling of multiple block/resume cycles.

**6. Dispatch engine alert writing not tasked (2 reviewers: OAI-F20, GEM-F4)**
Phase 1 watcher writes alerts, but the new dispatch engine is a separate code path. No AC ensures dispatch governance failures produce alerts.

**7. Walking skeleton approach (STRENGTH, 3 reviewers: OAI-F15, GRK-F13, DS-F7/implicit)**
Single-stage invoke-skill first, then layer complexity. Minimizes integration risk.

### Unique Findings

**OAI-F1 (CRITICAL): Stage output transport ambiguity (stdout vs file)**
Genuine question about the integration contract. However, the dispatch protocol section 4.2 explicitly instructs Claude to "Write your stage output to: _openclaw/outbox/{dispatch_id}-stage-{N}.json" — Claude Code writes the file via Write tool during the --print session, runner reads from disk. The AC already states "Reads stage output JSON from" the file path. **Downgraded to should-fix** — add clarification that runner reads from disk (not stdout) and handles missing file case.

**GRK-F2 (SIGNIFICANT): CTB-020 missing dependency on CTB-019**
Stage runner spawns claude --print with stage prompts — it needs the prompt builder from CTB-019 to construct those prompts. Valid missing dependency.

**GRK-F3 (SIGNIFICANT): CTB-021 routing omits escalation-response and cancel-dispatch**
The AC only lists the 3 initiating Phase 2 ops but all 5 Phase 2 operations need routing through the dispatch engine. Valid gap.

**GRK-F5 (SIGNIFICANT): Hard caps on advisory budgets deviate from design**
The dispatch protocol section 8.1 explicitly says tool calls and tokens are "Advisory only" — the runner does NOT gate execution on them. CTB-019 AC includes them as hard caps, which contradicts the design. Valid.

**GRK-F4 (CRITICAL): Audit hash mismatch — batch vs chained**
Grok claims the design specifies sequential chaining but CTB-027 uses batch concatenation. **This is incorrect.** The dispatch protocol section 7.3 explicitly defines batch concatenation: "Concatenate all hex strings with \n as separator... Compute sha256(concatenated_string)[:12]." CTB-027's AC matches the protocol exactly. Declined.

**DS-F2 (SIGNIFICANT): CTB-018 depends on CTB-017**
Claims state module needs Phase 2 schema. **Incorrect.** The dispatch state schema (section 2.5) is independent of the operation allowlist in constants.js. The state module stores lifecycle_state, stages, budget — none of which require the operation enum. The operation field is just a stored string. Declined.

### Contradictions

**CTB-025 risk level:** Gemini says HIGH (safety override), plan says MEDIUM. The kill-switch is simple file-exists check, and cancel is a state flag — mechanically straightforward. The *consequence* of a bug is high but the *implementation complexity* is low. MEDIUM is appropriate for the task risk, with the consequence bounded by the validation gate (CTB-028).

**CTB-028 splitting:** DeepSeek and Grok recommend splitting into 3 subtasks. OpenAI doesn't flag it. The task covers many scenarios but they're all test code in 2-3 files. Phase 1 used the same pattern (CTB-007 E2E + CTB-008 injection as separate tasks). **Split into 2** aligns with Phase 1 precedent: lifecycle tests + injection tests.

### Action Items

**Must-fix:**

**A1** (OAI-F14, GEM-F3, GRK-F1) — Add DISPATCH_CONFLICT handling to CTB-021 AC: "If flock acquisition fails or another dispatch is active, reject with DISPATCH_CONFLICT. Test: concurrent request returns DISPATCH_CONFLICT."

**A2** (OAI-F18, DS-F3, GRK-F9) — Reclassify CTB-018 from LOW to MEDIUM risk.

**A3** (GEM-F1, GRK-F8) — Change CTB-025 dependency from CTB-021 to CTB-022. Inter-stage checks need multi-stage lifecycle.

**A4** (OAI-F2, DS-F4) — Add to CTB-017 AC: "All 8 new dispatch error codes (BUDGET_EXCEEDED, STAGE_FAILED, KILL_SWITCH, ESCALATION_TIMEOUT, GOVERNANCE_STAGE_FAILED, DISPATCH_CONFLICT, CANCELED_BY_USER, RUNNER_RESTART) added to constants.js with canonical descriptions."

**A5** (GRK-F2) — Add CTB-019 as dependency for CTB-020. Stage runner needs prompts from prompt builder.

**A6** (GRK-F3) — Update CTB-021 AC: "All 5 Phase 2 ops (start-task, invoke-skill, quick-fix, escalation-response, cancel-dispatch) route to dispatch engine. escalation-response and cancel-dispatch route to dispatch engine for correlation with active dispatches."

**A7** (GRK-F5) — Demote tool_calls/tokens from hard caps to advisory-only in CTB-019 AC. Change "hard caps enforced (25 stages, 3600s, 500 calls, 2M tokens)" to "hard caps enforced (25 stages, 3600s); tool_calls and tokens tracked as advisory (logged, not enforced)."

**Should-fix:**

**A8** (OAI-F20, GEM-F4) — Add to CTB-020 AC: "Governance failure during dispatch writes structured alert JSON to _openclaw/alerts/ for Tess pickup."

**A9** (OAI-F9, DS-F9) — Add to CTB-022 AC: "Wall-time clock pauses when dispatch enters blocked state and resumes on exit. Persisted fields: dispatch_started_at, total_blocked_seconds. Tests cover multiple block/resume cycles."

**A10** (DS-F8) — Move "Tess-side echo-formatter.js formats status for Telegram" from CTB-023 to CTB-026. CTB-023 focuses on runner writing status files only.

**A11** (DS-F6) — Update CTB-027 dependencies to CTB-021, CTB-022, CTB-024. Final response needs multi-stage deliverables and escalation counts.

**A12** (OAI-F7) — Add to CTB-024 AC: "Only first valid escalation-response accepted; subsequent duplicates logged and ignored. Wrong escalation_id ignored. Late response after timeout ignored. Tests for duplicate/late/wrong-id."

**A13** (OAI-F1) — Add to CTB-020 AC: "Stage output read from disk (written by Claude via Write tool per prompt instructions), not captured from stdout. If stage output file missing after session exit with code 0, treated as malformed output per section 11.3."

**Defer:**

**D1** (OAI-F3) — Split CTB-017: Current scope is constants.js + schema.js + bridge-processor.js + tests = 4 files. Within limit. `incorrect` — file count overestimated.

**D2** (OAI-F4) — Split CTB-021: dispatch_engine.py + bridge-watcher.py + test = 3 files. Within limit. `incorrect` — file count overestimated.

**D3** (OAI-F12, GEM-F5) — Split CTB-026: 4-5 files, borderline. `overkill` — monitor during implementation; split if complexity warrants.

**D4** (DS-F1, GRK-F6) — Split CTB-028: Valid concern on scenario count. Phase 1 precedent (CTB-007 + CTB-008) suggests splitting lifecycle tests from injection tests. `constraint` — defer to implementation; may split naturally.

**D5** (DS-F5) — Split CTB-019: Brief and prompt are tightly coupled (prompt needs brief content). `overkill` — splitting adds overhead without benefit.

**D6** (DS-F2) — CTB-018 depends on CTB-017: State schema (section 2.5) is independent of operation allowlist. Operation field is a stored string, not validated against enum. `incorrect` — state module doesn't need schema constants.

**D7** (GEM-F2) — CTB-025 risk HIGH: Implementation is mechanically simple (file-exists check, state flag). Consequence bounded by validation gate. `overkill` — MEDIUM appropriate.

**D8** (OAI-F17) — Schema-as-code: Python validation against design doc section references is sufficient. Adding JSON Schema files is extra complexity. `overkill` — revisit if interop drift appears.

**D9** (GRK-F4) — Audit hash mismatch: Protocol section 7.3 explicitly defines batch concatenation, not sequential chaining. CTB-027 AC matches protocol. `incorrect` — finding based on false premise.

### Grok Calibration Note

Grok produced 16 findings: 5 SIGNIFICANT, 7 MINOR, 4 STRENGTH. STRENGTH ratio = 25% (4/16), improved from 53% (8/15) in first review. The prompt addendum is working. GRK-F4 (audit hash mismatch) was the weakest finding — incorrect reading of the protocol. GRK-F2 (missing dependency), F3 (incomplete routing), and F5 (advisory budget) were among the most valuable findings. Retaining in lineup.
