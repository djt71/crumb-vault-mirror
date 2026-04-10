---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/ralph-loop-spec.md
artifact_type: design
artifact_hash: f25fa305
prompt_hash: 5981dbf9
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-01
updated: 2026-04-01
reviewers:
  - openai/gpt-5.4
  - google/gemini-3.1-pro-preview
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
    latency_ms: 68991
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-ralph-loop-spec-openai.json
  google:
    http_status: 200
    latency_ms: 38570
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-ralph-loop-spec-google.json
  deepseek:
    http_status: 200
    latency_ms: 41208
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-ralph-loop-spec-deepseek.json
  grok:
    http_status: 200
    latency_ms: 29428
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-ralph-loop-spec-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Ralph Loop Implementation Spec

**Artifact:** Projects/tess-v2/design/ralph-loop-spec.md
**Mode:** full
**Reviewed:** 2026-04-01
**Reviewers:** GPT-5.4, Gemini 3.1 Pro Preview, DeepSeek Reasoner, Grok 4.1 Fast Reasoning
**Review prompt:** Full structured review -- hard stop mechanics, failure context injection, budget enforcement, partial completion, return envelope parsing, convergence tracking, sequence diagram accuracy, cross-reference consistency.

---

## OpenAI (gpt-5.4)

Below is a structured review of the Ralph loop implementation spec.

### Overall assessment

This is a strong implementation companion: the core loop model is clear, the runner/executor separation is explicit, and the retry/failure-context/convergence mechanics are mostly coherent. The spec does a good job making the runner mechanical rather than judgmental.

The main issues are not with the core idea, but with a few important ambiguities and contradictions at boundaries:
- whether certain parser failures consume retry budget,
- whether "semantic" / bad-spec detection triggers after 2 identical failures or requires budget exhaustion,
- how partial completion interacts with quality evaluation and escalation,
- and whether lenient parsing can accidentally blur "executor crashed" vs "executor returned malformed but semantically usable output."

I've classified findings below.

---

### Findings

#### F1
- **Severity:** CRITICAL
- **Finding:** The spec is internally inconsistent on whether non-recoverable parse failures consume retry budget.
- **Why:** Section 2.2 says lenient parsing recovery does not consume budget, but Section 6.2 says non-recoverable parse errors "trigger retry," and Section 6.3 classifies no parseable envelope after lenient recovery as tool-class failure. Tool-class failures appear to be ordinary failed iterations under Section 2.2 / Section 4.2, which would consume budget unless explicitly exempted. This creates ambiguity in the runner's accounting and could lead to divergent implementations.
- **Fix:** Add an explicit table for parser outcomes:
  1. recoverable formatting fix -> no budget consumed;
  2. partial envelope recovered and evaluation proceeds -> normal pass/fail accounting;
  3. unrecoverable parse failure -> specify explicitly whether it is a tool failure that consumes budget, a non-budget-consuming infra retry, or immediate escalation after N occurrences.
  Also update Section 2.2 and Section 6.2/6.3 so they use exactly the same terminology.

#### F2
- **Severity:** CRITICAL
- **Finding:** Bad-spec / semantic short-circuit semantics are contradictory.
- **Why:** Section 3.4 says "Same check_id + failure_class across 2+ consecutive iterations" becomes `semantic` and "short-circuits the loop: EXECUTING -> DEAD_LETTER." But Section 10 says "Two identical failures = sufficient signal," while Section 2.3 says budget exhaustion goes to ESCALATED, and DEAD_LETTER only occurs when max tier is exhausted or max tier exhausts budget. These rules conflict. If semantic failures can bypass escalation and budget, that needs to be stated as an explicit exception to Section 2.3 and Section 5.2.
- **Fix:** Add one normative rule:
  "Semantic/bad-spec detection is an exception to normal budget exhaustion and tier escalation. Upon detection, runner transitions directly to DEAD_LETTER regardless of remaining retry budget or available higher tiers."
  Or, if that is not intended, revise Section 3.4 and Section 10 to route semantic failures to ESCALATED instead.

#### F3
- **Severity:** SIGNIFICANT
- **Finding:** Hard stop is mostly mechanical, but there is no explicit defense against executor attempts to delay termination via oversized or streaming output.
- **Why:** The runner controls termination based on checks, but an executor could still consume wall-clock or parser resources by returning huge malformed payloads, endlessly streaming until timeout, or bloating optional fields. Without output-size and parse-time ceilings, termination remains mechanically decided but not mechanically bounded.
- **Fix:** Add runner-enforced limits:
  - max response bytes/tokens,
  - max parse time,
  - truncate-and-fail policy,
  - explicit handling for streaming/non-terminating responses,
  - classify oversize output as `_response_limit_exceeded` tool failure.

#### F4
- **Severity:** SIGNIFICANT
- **Finding:** The spec does not explicitly define whether the runner validates `staging_path` and artifact paths against path traversal or symlink escape.
- **Why:** Section 1.3 says executor must not write outside `staging_path`, but the hard stop/mechanical model depends on the runner enforcing this mechanically, not trusting executor self-report. If path validation is absent, an executor could "succeed" while violating isolation.
- **Fix:** Add a normative enforcement section: runner resolves realpaths, forbids symlinks escaping root, rejects `..`, absolute paths, and non-whitelisted write targets; violations produce synthetic failed checks and iteration failure.

#### F5
- **Severity:** SIGNIFICANT
- **Finding:** Cumulative failure context is reasonable, but the compaction rule is underspecified for mixed deterministic and reasoning failures.
- **Why:** Section 3.3 says preserve most recent in full and compact prior ones to `{iteration, failure_class, failed_check_ids_only}`. But Section 3.2 creates a special exception for reasoning failures requiring a one-paragraph summary. It is unclear whether that summary survives compaction. Losing it could cause the executor to repeat the same failed approach on iteration 3.
- **Fix:** Update compaction rule to preserve:
  - most recent failure in full,
  - any reasoning-class summary for the most recent reasoning-class failure,
  - compact all others to IDs/classes only.
  Spell out precedence if multiple reasoning failures exist.

#### F6
- **Severity:** SIGNIFICANT
- **Finding:** The claim that Layer 6 compaction "rarely triggers" for `retry_budget: 3` may not hold if failed checks are numerous or deltas are verbose.
- **Why:** A single iteration can accumulate many failed checks, each with expected/actual/delta. Two such objects can exceed 2K tokens, especially on large contracts. This matters because prompt budgeting is central to the architecture.
- **Fix:** Use a check-level cap and summary rule, e.g.:
  - include top N failed checks in full,
  - summarize remainder by count and IDs,
  - cap per-field lengths for expected/actual/delta,
  - define deterministic truncation order.

#### F7
- **Severity:** SIGNIFICANT
- **Finding:** `quality_retry_budget` and `retry_budget` are conceptually independent, but the interactions with partial promotion and escalation are not fully unified.
- **Why:** Section 2.4 says V3 quality failure causes a full re-dispatch with a restored `retry_budget`; V1/V2 quality failures route directly to `partial_promotion`. Section 5.3 defines partial promotion policies when tests/artifacts passed but quality failed. However, it is not explicit whether quality failure ever enters the Ralph loop's failure context system, whether quality retries preserve earlier loop failure history, or how convergence/outcome should be recorded after a quality-retry cycle.
- **Fix:** Add a lifecycle subsection for quality-failure handling:
  - whether quality failures are inside or outside Ralph loop accounting,
  - whether they create `failure_context`,
  - whether previous convergence data is merged or one per loop,
  - what terminal outcome is recorded if a quality retry later succeeds.

#### F8
- **Severity:** SIGNIFICANT
- **Finding:** "Escalation doesn't consume budget" is correct in spirit, but under-specified operationally.
- **Why:** Section 2.2 says escalation routing changes do not consume budget, including Gate 2 confidence escalation on first iteration. But if the runner has already dispatched and received output from Tier 1 before deciding on reroute, some work has occurred. The distinction between "not a retry" and "an iteration already happened" needs precise accounting rules to avoid skewing convergence metrics.
- **Fix:** Explicitly state:
  - whether Gate 2 confidence escalation occurs before any substantive iteration is counted,
  - whether `iterations_used` remains 0 in that path,
  - whether executor token/cost usage is recorded despite no retry-budget consumption,
  - how convergence metrics should treat these reroutes.

#### F9
- **Severity:** SIGNIFICANT
- **Finding:** Partial completion path is not fully defined when budget is exhausted after tests/artifacts fail, yet preserved staging contains useful partial work.
- **Why:** Section 5.1 says escalation context includes the last return envelope and staging is preserved; Section 5.3 defines partial promotion only when tests+artifacts pass but quality fails. There is no explicit policy for whether higher tier can build on preserved partial artifacts, must overwrite them, or sees them only as inspection inputs. Since staging is overwritten per iteration, this matters after escalation.
- **Fix:** Add explicit rules:
  - whether new tier gets read access to preserved prior-tier staging,
  - whether it writes to a fresh subdirectory or same `staging_path`,
  - whether partial artifacts can be promoted only after all tests/artifacts pass in a later loop.

#### F10
- **Severity:** SIGNIFICANT
- **Finding:** The distinction between "completed but failed tests" and "executor crashed" is mostly good, but partial-envelope regex extraction risks blurring the categories.
- **Why:** Section 6.2 allows regex extraction of key fields into a partial envelope. If that partial envelope lacks enough structure to verify artifacts/tests, the runner could misclassify a malformed/crashed execution as a semantic failure or vice versa. This affects fairness of retries and diagnostics quality.
- **Fix:** Define minimum viable envelope criteria. Example:
  - If `contract_id` and `staging_path` only: classify as malformed-output tool failure unless independent artifact checks can run safely.
  - Require canonical field presence before treating output as "completed but failed tests."
  - Add `_malformed_envelope` as a distinct synthetic check separate from `_parse_failure`.

#### F11
- **Severity:** SIGNIFICANT
- **Finding:** The sequence diagram omits some decision branches described in the text, especially timeout/backoff, parse-failure, and semantic short-circuit.
- **Why:** The diagram is meant to summarize the loop, but as written it presents an oversimplified happy-path/fail-path model. Readers may miss important exceptional transitions that materially affect implementation.
- **Fix:** Expand the diagram or add an "exception branches" companion diagram showing:
  - timeout -> tool failure -> backoff / escalate,
  - unrecoverable parse failure,
  - Gate 2 reroute,
  - semantic/bad-spec -> DEAD_LETTER.

#### F12
- **Severity:** SIGNIFICANT
- **Finding:** Cross-reference alignment cannot be fully verified from this document alone, and several normative dependencies are external.
- **Why:** The spec repeatedly defers critical behavior to TV2-017, TV2-018, TV2-019, TV2-023, Amendment T/U/W, and specification Section 9.4. Without those texts, consistency of sub-state names, schema fields, and gate behavior cannot be independently confirmed.
- **Fix:** For this document, include a short "normative assumptions" appendix listing exact external symbols relied on (state names, schema field names, gate semantics) so mismatches are easier to detect.
- **Finding text prefix requirement:** **UNVERIFIABLE CLAIM:** Alignment with TV2-017/018/019/023 and the amendments is asserted but cannot be independently confirmed from the provided artifact.

#### F13
- **Severity:** MINOR
- **Finding:** The "runner is a mechanical process with no LLM judgment" claim is directionally correct, but failure classification still embeds some heuristic judgment.
- **Why:** Section 3.4 maps patterns like "Different checks fail across iterations" to `reasoning`, and "Same check_id + failure_class across 2+ consecutive iterations" to `semantic`. Those are rule-based heuristics, but they are still interpretive classifications. That's acceptable, but the wording could be tighter.
- **Fix:** Rephrase to "no discretionary judgment; only deterministic rule-based evaluation and classification."

#### F14
- **Severity:** MINOR
- **Finding:** `iterations_used` semantics are slightly unintuitive because successful final iterations increment `iterations_used` but do not decrement `iterations_remaining`.
- **Why:** It's not wrong, and the invariant in Section 2.1 is only stated generally. But implementers may incorrectly assume `used + remaining == budget` always, whereas Section 2.2 says remaining decrements only on failure. After success, unless terminal state freezes accounting, the invariant would break.
- **Fix:** Clarify the invariant scope. Example:
  "`used + remaining == budget` holds only during active retryable loop states; on terminal success, `iterations_remaining` may remain non-zero and should be interpreted as unused retry capacity."

#### F15
- **Severity:** MINOR
- **Finding:** The expected envelope field `iterations` is ambiguous in a fresh-session-per-iteration model.
- **Why:** Since each executor invocation is one iteration, `iterations: 2` in the sample envelope is confusing. The executor cannot truly know loop-global iteration count unless the runner tells it, and even then this field is redundant/non-authoritative.
- **Fix:** Either remove `iterations` from the envelope, rename it to `attempt_number` supplied by runner, or mark it informational and ignored by the runner.

#### F16
- **Severity:** MINOR
- **Finding:** The quality check mention in failure context schema is slightly misleading because Section 2.4 says quality retries operate outside the Ralph loop.
- **Why:** Section 3.1 permits `check_type: quality_check`, but if quality failures are outside the loop, readers may wonder whether such failures should appear in `failure_context`.
- **Fix:** Add a note: "`quality_check` appears in failure context only if a future extension pulls quality checks into-loop; for current V3 policy, quality failures are tracked separately."

#### F17
- **Severity:** STRENGTH
- **Finding:** The hard-stop design is fundamentally sound: runner evaluates tests/artifacts, executor self-report is informational only, and loop termination is runner-controlled.
- **Why:** This is the key architectural property for preventing model self-approval or premature success claims. Section 4.1 and Section 4.3 express this clearly and operationally.
- **Fix:** None.

#### F18
- **Severity:** STRENGTH
- **Finding:** Separating contract immutability from runner-maintained loop state is a strong design choice.
- **Why:** It preserves auditability and avoids mutating task definitions while still allowing precise iteration accounting and convergence telemetry.
- **Fix:** None.

#### F19
- **Severity:** STRENGTH
- **Finding:** Preserving staging on escalation is a practical and valuable policy.
- **Why:** It supports manual inspection, reduces duplicate work, and makes higher-tier debugging more efficient, especially for partially successful executions.
- **Fix:** None.

#### F20
- **Severity:** STRENGTH
- **Finding:** The independent `quality_retry_budget` concept is a good separation of concerns.
- **Why:** It avoids conflating execution correctness retries with judgment/quality retries, which are behaviorally different and should not pollute core convergence metrics.
- **Fix:** None.

#### F21
- **Severity:** STRENGTH
- **Finding:** The document does a good job distinguishing recoverable formatting issues from semantic execution failures.
- **Why:** Lenient parsing is a pragmatic safeguard for real model behavior, and placing it before evaluation is sensible.
- **Fix:** None, aside from clarifying the accounting ambiguity noted above.

#### F22
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** "The executor does NOT see ... quality check results (AD-007 separation)" cannot be independently verified from the provided artifact.
- **Why:** This is an important isolation guarantee affecting prompt construction and feedback leakage. It relies on an external design artifact not provided here.
- **Fix:** Mirror the normative rule directly in this spec, not only by reference, if it is essential to loop behavior.

#### F23
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** The prompt-layer budgets and layer definitions are asserted to come from TV2-023, but the provided artifact alone does not establish that the listed sizes and content are canonical.
- **Why:** Layer budgets directly affect feasibility of cumulative failure context and vault injection. If these numbers differ in TV2-023, this spec could be operationally inconsistent.
- **Fix:** Either restate that the numbers here are provisional/examples or explicitly mark them as normative duplicates from TV2-023.

#### F24
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** The sub-state names and transitions (`iteration_start`, `iteration_working`, `iteration_checking`, `retry_preparing`, etc.) are said to match TV2-017, but this cannot be independently confirmed.
- **Why:** State-machine mismatch would be a serious integration issue for implementation.
- **Fix:** Include a small transition table in this spec with exact state names and allowed edges, even if duplicated from TV2-017.

---

### Focused answers to the requested evaluation areas

#### 1. Hard stop mechanics
- **Assessment:** Mostly yes, enforcement is mechanical.
- **What works:** Runner decides pass/fail, ignores executor self-assessment, evaluates all tests/artifacts, and owns all transitions.
- **Risk areas:** Oversized output, parse-resource abuse, path escape, and ambiguity around malformed partial envelopes.
- **Conclusion:** Strong foundation, but add hard resource limits and filesystem enforcement to fully close circumvention/delay vectors.

#### 2. Failure context injection
- **Assessment:** Cumulative context is the right default for a low retry budget.
- **Risk:** Iteration 3 can still overflow if failure objects are verbose or numerous.
- **Compaction:** Sound in principle, but must preserve reasoning summaries and use deterministic truncation/caps.
- **Conclusion:** Good design; needs a sharper compaction algorithm.

#### 3. Budget enforcement
- **Assessment:** `retry_budget` vs `quality_retry_budget` are conceptually independent.
- **Issue:** Parse-failure accounting and Gate 2 reroute accounting need tighter normalization.
- **Escalation rule:** "Escalation doesn't consume budget" is reasonable, but should specify what gets counted as an iteration and what only counts as cost telemetry.

#### 4. Partial completion
- **Assessment:** Escalation on budget exhaustion is defined, but partial work reuse/promotion is only partially defined.
- **Gap:** The path from exhausted budget with partial work to later promotion by higher tier is not operationally specified.
- **Conclusion:** Needs explicit staging reuse semantics and interaction with later promotion.

#### 5. Return envelope parsing
- **Assessment:** Good pragmatic approach; robust in spirit.
- **Gap:** The boundary between malformed-but-usable and crashed/unparseable needs a minimum viable envelope definition.
- **Conclusion:** Good pattern, not yet fully implementation-safe.

#### 6. Convergence tracking
- **Assessment:** Generally correct and well-scoped.
- **Adaptive vs fixed:** Makes sense.
- **Caveat:** Need clarity on rerouted non-budget-consuming executions and multi-loop quality-retry accounting.
- **Conclusion:** Strong with a few accounting edge cases to tighten.

#### 7. Sequence diagram
- **Assessment:** Accurate for the main loop, incomplete for exception paths.
- **Conclusion:** Add exception branches or a second diagram.

#### 8. Cross-reference consistency
- **Assessment:** Appears thoughtfully cross-linked, but cannot be fully verified from the artifact alone.
- **Conclusion:** Good discipline, but several important consistency claims remain unverifiable without the referenced docs.

---

### Recommended priority fixes

If you only address a few items, I'd prioritize these:

1. **Resolve parser failure budget semantics** (F1).
2. **Resolve semantic/bad-spec direct-DEAD_LETTER contradiction** (F2).
3. **Add output/resource/path enforcement rules** (F3, F4).
4. **Define minimum viable envelope and malformed-envelope classification** (F10).
5. **Tighten compaction rules for reasoning summaries and many failed checks** (F5, F6).

---

## Google (gemini-3.1-pro-preview)

### 1. Budget Enforcement & Escalation
- [F1]
- [Severity]: CRITICAL
- [Finding]: Contradiction regarding budget behavior during escalation.
- [Why]: Section 2.2 states "tier upgrade carries the iteration counter forward" (implying budget is shared or continued across tiers), but Section 5.2 states "Higher tier available: Re-enters ROUTING... Budget resets". If the budget resets, the loop could theoretically execute `retry_budget` times on Tier 1, then reset and execute `retry_budget` times on Tier 2, potentially doubling the expected execution ceiling. 
- [Fix]: Explicitly clarify whether `iterations_used` resets to 0 upon entering a new tier, or if the new tier only gets the *remaining* iterations. Update Section 2.2 or 5.2 so they perfectly align.

### 2. Hard Stop Mechanics
- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Ambiguity in timeout budget consumption.
- [Why]: Section 2.2 states budget is consumed when an iteration "completes and fails evaluation" (tests/artifacts fail). However, Section 4.2 states that timeouts result in a synthetic `_timeout` system check failure, and checks `Budget remaining > 0`. It is not explicitly stated in 2.2 whether a system timeout increments `iterations_used` and decrements `iterations_remaining`. 
- [Fix]: Add "System timeout occurs" to the bulleted list in Section 2.2 defining what consumes budget.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Weak enforcement mechanism for executor sandboxing.
- [Why]: Section 1.3 states "The executor must NOT: (1) write outside `staging_path`... (3) modify contract...". If this is enforced only via prompt instruction (Layer 1), a rogue or hallucinating LLM could still write outside the directory, modifying system state or the contract itself, thereby breaking the mechanical hard-stop.
- [Fix]: Clarify in Section 1.3 that filesystem writes are restricted to `staging_path` via OS-level sandboxing/permissions, not just prompt-level directives.

### 3. Cross-References
- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: References to external specs (`spec section 9`, `state-machine-design.md section 3, section 8, section 9`, `TV2-023`, `contract-schema.md section 1.1-1.4`, `TV2-018`, `TV2-017`, `spec-amendments-harness.md`).
- [Why]: The architectural soundness of the Ralph loop heavily depends on external data structures (e.g., Amendment U's regex rules, Gate 2 confidence checks, Gate 4 statistical tracking) which are not provided in this document. I cannot independently verify that these external schemas and state transitions operate exactly as claimed here.
- [Fix]: Ensure companion documents strictly align with the schemas and state definitions (e.g., `execution_result` schema and sub-states) laid out in this spec.

### 4. Failure Context Injection
- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Premature termination risk via 'Bad-spec' short-circuit.
- [Why]: Section 3.4 states that failing the same `check_id` with the same `failure_class` across 2+ consecutive iterations triggers a `semantic` failure, short-circuiting to `DEAD_LETTER`. If `retry_budget` is 3, failing the exact same check on iteration 1 and iteration 2 will immediately kill the contract. This prevents the executor from utilizing its final iteration budget to correct the mistake, effectively reducing a budget of 3 to 2 for repetitive errors.
- [Fix]: Define if "2+ consecutive iterations" means strictly 2, or if it triggers only when the `retry_budget` is fully exhausted *and* the failure was consecutive. If early termination is intended, document that this intentionally overrides remaining retry budget.

### 5. Return Envelope Parsing
- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Misclassification of unparseable executor output as a `tool` failure class.
- [Why]: Section 6.2 states that if regex extraction fails, it triggers a `TOOL` failure class. Section 3.4 defines `tool` failures as "No executor output (timeout, crash, API error)" which prompts a "defer/requeue with backoff" strategy. An LLM generating unparseable garbage is an underlying semantic/prompting issue, not a transient API infrastructure issue. Retrying unparseable output with an infrastructure backoff loop wastes time.
- [Fix]: Change the fallback failure class in 6.2 for totally unparseable output from `TOOL` to `deterministic` (prompting the executor to fix formatting) or `reasoning`.

### 6. Sequence Diagram
- [F7]
- [Severity]: MINOR
- [Finding]: Sequence diagram is missing the Gate 2 early exit path.
- [Why]: Section 8 diagram shows "7. Gate 2 (i1 only)" progressing immediately to "8. Run tests". It fails to visually represent what happens if Gate 2 escalates (confidence is too low). 
- [Fix]: Add a branch in the sequence diagram at Step 7 showing the routing correction/escalation path out of the loop.

### 7. Overall Architecture
- [F8]
- [Severity]: STRENGTH
- [Finding]: Strict mechanical hard stop and state isolation.
- [Why]: The architecture effectively removes LLM subjectivity from loop termination. Separating the executor's self-assessed status from the runner's authoritative test evaluation (Section 4.3), and enforcing a strict 1:1 fresh context per loop (Section 1.1), guarantees that the system won't get trapped in infinite conversational loops. Furthermore, separating `retry_budget` and `quality_retry_budget` (Section 2.4) handles mechanical vs. qualitative failures elegantly.

---

## DeepSeek (deepseek-reasoner)

### 1. Hard Stop Mechanics
- **F1** [STRENGTH]: Runner maintains full control over termination decisions
- **Why**: Clear separation of concerns - executor produces output, runner evaluates against contract criteria. Prevents executor gaming.
- **F2** [SIGNIFICANT]: Timeout enforcement creates synthetic `_timeout` check
- **Why**: Good for infrastructure issues, but what about partial outputs during timeout? Could an executor produce partial valid output before timeout that gets discarded?
- **Fix**: Clarify if partial staging writes before timeout are preserved for evaluation.

### 2. Failure Context Injection
- **F3** [STRENGTH]: Cumulative failure context with compaction is well-designed
- **Why**: Provides maximum information while respecting token budgets. Compaction rule (preserve recent, summarize older) is pragmatic.
- **F4** [MINOR]: Compaction threshold (2K tokens) may be too high for some models
- **Why**: With 4K context windows common, 2K for failure context alone leaves limited space for other layers.
- **Fix**: Consider reducing to 1-1.5K or making it configurable per executor tier.

### 3. Budget Enforcement
- **F5** [CRITICAL]: Quality retry budget vs Ralph loop retry budget distinction is unclear
- **Why**: Section 2.4 states V3 contracts can have both budgets, allowing "up to 6 total iterations (3 per loop)." But quality retry triggers "Re-dispatches through ESCALATED -> ROUTING -> DISPATCHED -> EXECUTING with full `retry_budget` restored." This suggests the contract re-enters the Ralph loop with fresh budget, potentially exceeding intended limits.
- **Fix**: Clarify if quality retry resets to iteration 1 with fresh budget or continues from same iteration count.

- **F6** [SIGNIFICANT]: "Escalation doesn't consume budget" rule appears correct
- **Why**: Tier upgrade reflects capability mismatch, not task difficulty. Budget should reset for new tier's capabilities.

### 4. Partial Completion
- **F7** [SIGNIFICANT]: Partial promotion path for quality failures vs budget exhaustion differs
- **Why**: Quality failures (V3) trigger quality retry loop; V1/V2 go to partial_promotion policy. But budget exhaustion (any version) escalates to higher tier. This creates two different escalation paths that could be confusing.
- **Fix**: Consider unifying escalation paths or documenting rationale for separation more clearly.

### 5. Return Envelope Parsing
- **F8** [STRENGTH]: Lenient parsing layer (Amendment U) with fallback chain is robust
- **Why**: Handles common formatting issues without wasting retry budget on trivial errors.
- **F9** [SIGNIFICANT]: Distinction between "completed but failed tests" vs "executor crashed" relies on parseability
- **Why**: If executor returns valid envelope with status: "completed" but tests fail -> classified as failure with diagnostics. If no parseable envelope -> tool-class failure. This seems correct but assumes lenient parsing can always distinguish between malformed output and no output.
- **UNVERIFIABLE CLAIM**: "Per-executor quirk profiles: Parser adapts per model. Example: Nemotron uses `reasoning_content` instead of `content` at 128K context"
- **Fix**: Document how quirk profiles are maintained and versioned.

### 6. Convergence Tracking
- **F10** [MINOR]: `convergence_record` population timing needs clarification
- **Why**: Spec says "At terminal state, runner populates `convergence_record`" but doesn't specify if this happens before or after state transition (ESCALATED, DEAD_LETTER, etc.).
- **Fix**: Explicitly sequence the write in state transition diagrams.

- **F11** [SIGNIFICANT]: Adaptive vs fixed mode distinction for iteration counting makes sense
- **Why**: V1/V2 (adaptive) uses iterations as convergence signal; V3 (fixed) uses quality pass rate. Aligns with different contract types' purposes.

### 7. Sequence Diagram
- **F12** [MINOR]: Diagram omits quality evaluation and partial promotion paths
- **Why**: Sequence covers main Ralph loop but not quality retry loop or partial promotion flows mentioned elsewhere.
- **Fix**: Add supplemental diagrams for these alternative flows.

### 8. Cross-Reference Consistency
- **F13** [SIGNIFICANT]: References to "state-machine-design.md section 3" for EXECUTING sub-states
- **Why**: This spec details sub-state behaviors (iteration_start, iteration_working, etc.) but assumes external document defines the states themselves. Need to verify alignment.
- **UNVERIFIABLE CLAIM**: References to Amendment T, U, W in "spec-amendments-harness.md"
- **F14** [MINOR]: Missing cross-reference for "tool-class failure" pattern classification
- **Fix**: Add reference to specification.md section 9.4 as indicated in table.

### Additional Findings
- **F15** [CRITICAL]: Bad-spec detection triggers DEAD_LETTER immediately
- **Why**: Section 3.4 states "Same check_id + failure_class across 2+ consecutive iterations -> semantic -> Bad-spec -> DEAD_LETTER." But section 2.3 says budget exhaustion -> ESCALATED. What takes precedence if both conditions met simultaneously?
- **Fix**: Clarify precedence: bad-spec detection should short-circuit regardless of remaining budget.

- **F16** [STRENGTH]: Staging preservation on escalation reduces rework
- **Why**: Higher tier can inspect partial work and potentially fix only specific failures.

- **F17** [MINOR]: "Executor Self-Termination Prevention" section could be clearer
- **Why**: States executor's status field is "informational only" but doesn't clarify if runner logs discrepancies between executor self-assessment and actual results.
- **Fix**: Add note about logging mismatches for convergence tracking.

### Summary

**CRITICAL Issues (2):**
1. Quality retry budget interaction with Ralph loop budget (F5)
2. Bad-spec detection precedence vs budget exhaustion (F15)

**SIGNIFICANT Issues (5):**
- Partial output handling during timeout (F2)
- Quality vs budget exhaustion escalation paths (F7)
- Parseability distinction robustness (F9)
- Cross-document state alignment (F13)
- Two unverifiable claims about quirk profiles and amendments

**MINOR Issues (4):**
- Compaction threshold size (F4)
- Convergence record write timing (F10)
- Missing quality flows in diagram (F12)
- Missing tool-class failure reference (F14)

**STRENGTHS (4):**
- Mechanical termination control (F1)
- Cumulative failure context design (F3)
- Lenient parsing layer (F8)
- Staging preservation (F16)

The spec is generally well-structured with clear mechanical enforcement. The critical issues around budget interaction and bad-spec detection precedence need resolution before implementation.

---

## Grok (grok-4-1-fast-reasoning)

### Structured Review Findings

**[F1]**
[CRITICAL]: Budget invariant violation in iteration state tracking.
[Why]: Section 2.2 states "iterations_used += 1" on both failure and success, with invariant "used + remaining == budget". Initial state (used:0, remaining:3) holds, but after first failure (used:1, remaining:2) followed by success on iter2 (used:2, remaining:2) breaks invariant (sum=4 > budget). This leads to inconsistent state, potential infinite loops or incorrect exhaustion checks.
[Fix]: Clarify increment rules: increment used on every iteration end; decrement remaining only on failure; revise invariant to "used <= budget" and exhaustion check solely on "remaining == 0 after failure". Update YAML example accordingly.

**[F2]**
[CRITICAL]: Missing state for consecutive timeout tracking.
[Why]: Section 4.2 claims "Second consecutive timeout -> ESCALATED regardless of budget", but ralph_loop_state YAML lacks a `consecutive_timeouts` counter. Without it, runner cannot detect/enforce "consecutive", risking budget waste on repeated infrastructure failures.
[Fix]: Add `consecutive_timeouts: 0` to ralph_loop_state; increment on tool-class timeout; reset on non-timeout; escalate if >=2.

**[F3]**
[CRITICAL]: Bad-spec short-circuit contradicts budget exhaustion path.
[Why]: Section 3.4 says `semantic` (same check_id + failure_class across 2+ consecutive) -> "EXECUTING -> DEAD_LETTER", but 2.3/4.1 path is fail -> retry_preparing -> check remaining -> ESCALATED. Contradiction: does short-circuit bypass budget check? Unclear precedence risks state machine deadlock or budget leak.
[Fix]: Explicitly state short-circuit triggers before budget check in 4.1 flow; add `bad_spec_detected: false` flag to state with transition rule.

**[F4]**
[SIGNIFICANT]: Escalation resets budget but failure contexts "carry forward" ambiguously.
[Why]: Section 5.2 says "Failure contexts from prior tier carry forward as initial context for the new loop", but 1.2 says executors get fresh context per iteration, no prior outputs. Does new tier's Layer 6 include old tier's full failure_contexts array? Overload risk; partial artifacts preserved (5.1) but "staging overwritten per iteration" (3.2) conflicts -- does new tier see old staging?
[Fix]: Define "carry forward" precisely: new loop starts with Layer 6 = prior tier's compacted failure_contexts + `escalation_summary` YAML field listing preserved staging paths.

**[F5]**
[SIGNIFICANT]: UNVERIFIABLE CLAIM: Alignment with EXECUTING sub-states (state-machine-design.md section 3).
[Why]: Spec repeatedly references TV2-017 section 3 for sub-states (e.g., iteration_start -> iteration_working -> iteration_checking), but without access, cannot confirm if Ralph loop transitions match (e.g., does retry_preparing exist there?). Risks downstream integration failure.
[Fix]: Inline key sub-state transitions or stub excerpts from TV2-017.

**[F6]**
[SIGNIFICANT]: Partial completion escalation path lacks partial_promotion integration.
[Why]: Query 4: Budget exhaust -> ESCALATED (5.1), but 5.3 partial_promotion only for QUALITY_FAILED (V1/V2). No path defined for partial test passes on exhaust -> promote passing artifacts? Staging preserved, but higher tier overwrites; risks losing partial work without explicit policy.
[Fix]: Add table row or subsection in 5.2: for partial passes on exhaust, set `partial_status: promote_passing` flag, triggering subset PROMOTION_PENDING on max tier.

**[F7]**
[SIGNIFICANT]: Compaction rule inadequate for higher budgets.
[Why]: Query 2: Cumulative context good for budget=3, but spec assumes "retry_budget: 3" practice; for budget=5+, Layer 6 (1-2K) overflows even compacted (oldest as {iteration,failure_class,ids_only}). No rule for extreme compaction or cap.
[Fix]: Add "Max accumulation: last 2 full + summary of prior; discard oldest if >1.8K tokens pre-compaction."

**[F8]**
[SIGNIFICANT]: Lenient parsing recovery too broad, risks false positives.
[Why]: Query 5: Regex extraction on YAML/JSON fail for "key fields" unspecified (which fields?). "Recoverable" includes type coercion/unclosed brackets, but could parse garbage as partial envelope, misclassifying "crashed" as "completed but tests fail" -- wasting budget on bad output. Distinction fragile.
[Fix]: Specify minimal viable partial envelope (e.g., must have contract_id + status + staging_path); add parse confidence score; log raw output on recovery.

**[F9]**
[SIGNIFICANT]: UNVERIFIABLE CLAIM: Per-executor quirk profiles in parser.
[Why]: 6.2 claims "Parser adapts per model. Example: Nemotron uses reasoning_content...", but no linked implementation or schema confirmation (contract-schema.md section 1.4). Cannot verify if envelopes actually vary or if parser handles.
[Fix]: Link to parser code or define quirks table; fallback to strict parse if quirk unconfirmed.

**[F10]**
[SIGNIFICANT]: Escalation "doesn't consume budget" rule ignores quality_retry interaction.
[Why]: Query 3: Clear for retry_budget, but 2.4 quality_retry_budget decrements on QUALITY_EVAL fail post-STAGED -> re-dispatch. Escalation (tier change) carries iterations_used forward (convergence_record), but does it reset quality_retry? V3 chain could double-count.
[Fix]: Explicitly state "quality_retry_budget persists across escalations; retry_budget resets per tier loop."

**[F11]**
[MINOR]: Sequence diagram omits Gate 2 and lenient parse details.
[Why]: Query 7: Diagram shows 6. Lenient parse, 7. Gate 2, but flow is linear "Receive -> [checking] -> parse -> gate -> tests"; omits "iteration 1 Tier1 only" for Gate 2 and backoff on timeout. Minor inaccuracy for visual flow.
[Fix]: Annotate branches: "Gate 2 (iter1 Tier1 only)" and timeout arrow to "tool failure -> backoff?".

**[F12]**
[MINOR]: Convergence_record outcome values incomplete.
[Why]: Query 6: Examples show "completed | dead_letter | abandoned", but 5.3 adds PROMOTION_PENDING (subset); table policies imply more (e.g., "hold_for_review" -> DEAD_LETTER). Minor enum gap.
[Fix]: Expand to "completed | dead_letter | abandoned | promotion_pending | escalated".

**[F13]**
[MINOR]: Table in 5.3 partial promotion lacks source.
[Why]: Policies `discard | hold_for_review | promote_passing` undefined (no cross-ref); assumes contract-level config but unclear how runner selects.
[Fix]: Cross-ref to contract schema section X for policy field; default to `hold_for_review`.

**[F14]**
[STRENGTH]: Runner-only termination authoritative (4.1-4.3).
[Why]: Query 1: Flowchart and rules ensure mechanical enforcement -- no executor self-term allowed, timeouts synthetic tool-fail, status ignored. Edge case (malformed envelope claiming "failed" but tests pass) correctly -> STAGED. No circumvention paths.

**[F15]**
[STRENGTH]: Failure class table pragmatic (3.4).
[Why]: Query 2: Clear patterns -> classifications -> strategies; cumulative injection with exception for reasoning summary avoids repetition without full history overload.

**[F16]**
[STRENGTH]: Budget independence clear for retry vs quality (2.2-2.4).
[Why]: Query 3: Separate YAML states; quality only post-STAGED/QUALITY_EVAL, restores retry_budget. Escalation non-consumption logical for tier capability signal. V3 total iterations example (6 max) concrete.

---

## Synthesis

### Consensus Findings

**1. Bad-spec / semantic short-circuit contradicts budget exhaustion path** (OAI-F2, GEM-F5, DS-F15, GRK-F3)
All 4 reviewers flagged: §3.4 says semantic failure → DEAD_LETTER, but §2.3 says budget exhaustion → ESCALATED. Precedence undefined. Fix: explicitly state bad-spec detection is an exception that short-circuits to DEAD_LETTER regardless of remaining budget or available tiers.

**2. Quality retry budget interaction with main retry budget unclear** (OAI-F7, GEM-F1, DS-F5, GRK-F10)
Quality retry "restores retry_budget" (§2.4/§5.2) but interaction with convergence tracking, failure context carry-forward, and total iteration ceiling is underspecified. Fix: add quality-retry lifecycle subsection defining exactly what resets, what persists, and total iteration accounting.

**3. Parse failure budget accounting ambiguous** (OAI-F1, GEM-F6)
Non-recoverable parse failures classified as tool-class, but whether they consume retry budget is contradictory across §2.2 and §6.2/6.3. Fix: add explicit parser outcome table (recoverable → no budget, partial → normal evaluation, unrecoverable → specify clearly).

**4. Executor sandboxing is convention-only** (OAI-F4, GEM-F3)
Executor path restrictions rely on prompt instructions, not mechanical enforcement. Fix: add normative enforcement section — runner validates realpaths, rejects path traversal, symlinks outside staging root.

**5. Sequence diagram incomplete** (OAI-F11, GEM-F7, DS-F12, GRK-F11)
Missing Gate 2 escalation branch, timeout path, bad-spec short-circuit. Fix: add exception branch diagram.

**6. Cross-reference consistency unverifiable** (OAI-F12/F22-F24, GEM-F4, DS-F13, GRK-F5)
Multiple external dependencies (TV2-017 sub-states, TV2-019 schema, TV2-023 layers) asserted but not independently verifiable. Fix: include normative assumptions appendix with exact external symbols.

### Unique Findings

**OAI-F3 (SIGNIFICANT): No defense against oversized/streaming executor output.** Runner controls termination but not resource consumption. Genuine gap — add max response bytes/tokens and parse-time ceiling. Worth fixing.

**OAI-F5 (SIGNIFICANT): Compaction rule doesn't preserve reasoning-class summaries.** If reasoning summary compacted away, executor may repeat same failed approach. Genuine — update compaction to preserve most recent reasoning summary.

**OAI-F9 (SIGNIFICANT): Partial completion — higher tier staging reuse undefined.** Whether new tier reads preserved staging, overwrites it, or gets fresh subdirectory is unspecified. Genuine gap for implementation.

**GRK-F1 (CRITICAL): Budget invariant `used + remaining == budget` breaks on success.** Success increments `used` but doesn't decrement `remaining` (only failure does). Genuine accounting bug — fix invariant definition.

**GRK-F2 (CRITICAL): No consecutive_timeouts counter in ralph_loop_state.** §4.2 says "second consecutive timeout → ESCALATED" but no tracking field exists. Genuine — add `consecutive_timeouts` to loop state.

**DS-F2 (SIGNIFICANT): Partial output before timeout discarded.** Executor may produce valid staging artifacts before timing out. Fix: evaluate staging contents on timeout before classifying as tool failure.

### Contradictions

**Budget reset on escalation:** GEM-F1 says §2.2 ("carries forward") contradicts §5.2 ("budget resets"). DS-F5 interprets reset as intentional. OAI-F8 notes the ambiguity. **Assessment:** Budget reset on tier change is the intended design (fresh chance for higher-capability tier). Clarify §2.2 wording — "carries forward" applies to convergence tracking, not budget.

**Unparseable output failure class:** GEM-F6 says tool-class is wrong for garbage output (should be deterministic/reasoning). OAI-F10 agrees partial envelopes blur categories. **Assessment:** GEM is right — unparseable LLM output is not an infrastructure failure. Reclassify as `deterministic` (formatting fix needed).

### Action Items

**Must-fix:**

- **A1** (OAI-F2, GEM-F5, DS-F15, GRK-F3): Resolve bad-spec/semantic precedence — state explicitly that bad-spec detection short-circuits to DEAD_LETTER regardless of budget/tier.
- **A2** (OAI-F1, GEM-F6): Add parser outcome table — recoverable (no budget), partial (normal eval), unrecoverable (specify). Reclassify unparseable output from `tool` to `deterministic`.
- **A3** (GRK-F1): Fix budget invariant — `used + remaining == budget` doesn't hold on success. Redefine: `used` increments every iteration, `remaining` decrements only on failure, exhaustion check is `remaining == 0`.
- **A4** (GRK-F2): Add `consecutive_timeouts: 0` to ralph_loop_state. Increment on timeout, reset on non-timeout, escalate at >=2.

**Should-fix:**

- **A5** (OAI-F7, GEM-F1, DS-F5, GRK-F10): Add quality-retry lifecycle subsection — what resets (retry_budget), what persists (quality_retry_budget, convergence data), total iteration accounting, failure context carry-forward rules.
- **A6** (OAI-F4, GEM-F3): Add normative sandboxing rules — runner validates paths, rejects traversal/symlinks. Not just prompt-level.
- **A7** (OAI-F3): Add runner-enforced output limits — max response tokens, parse-time ceiling, truncate-and-fail policy.
- **A8** (OAI-F5): Update compaction to preserve most recent reasoning-class failure summary alongside most recent full failure.
- **A9** (OAI-F9): Define staging reuse semantics on escalation — fresh subdirectory or read-only access to prior tier's staging.
- **A10** (OAI-F11, GEM-F7, DS-F12, GRK-F11): Expand sequence diagram with exception branches (timeout, Gate 2 escalation, bad-spec short-circuit).
- **A11** (DS-F2): On timeout, evaluate staging contents before classifying as tool failure — partial work may be salvageable.
- **A12** (GEM-F1): Clarify §2.2 — "carries forward" applies to convergence tracking, not budget. Budget resets on tier change.

**Defer:**

- **A13** (OAI-F12, GEM-F4, DS-F13, GRK-F5): Normative assumptions appendix — useful but low urgency. Cross-reference consistency will be verified during implementation.
- **A14** (DS-F4): Compaction threshold configurability — current 2K is reasonable for 16K+ context windows.
- **A15** (GRK-F12): Expand convergence_record outcome enum — minor, fix during implementation.

### Considered and Declined

- **OAI-F13** (runner heuristic judgment): `incorrect` — failure classification uses deterministic pattern matching, not discretionary judgment. The distinction is clear.
- **OAI-F15** (`iterations` field in envelope): `overkill` — removing it breaks the schema; keeping it informational is fine.
- **OAI-F16** (quality_check in failure context misleading): `constraint` — the field exists for forward compatibility per the schema's closed-but-extensible design.
- **GRK-F9** (quirk profiles unverifiable): `constraint` — quirk profiles are implementation detail, not schema-level. Will be validated during implementation.
- **DS-F7** (partial promotion path confusion): `incorrect` — the two paths (quality failure → quality retry; budget exhaustion → escalation) are intentionally different because they address different failure types.
