---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/obsidian-applenotes-import/design/action-plan.md
artifact_type: architecture
artifact_hash: fcd31775
prompt_hash: a567422e
base_ref: null
project: obsidian-applenotes-import
domain: software
skill_origin: peer-review
created: 2026-04-29
updated: 2026-04-29
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
    latency_ms: 66608
    attempts: 1
    model_returned: gpt-5.4-2026-03-05
    system_fingerprint: null
    finish_reason: stop
    prompt_tokens: 10929
    completion_tokens: 3790
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-29-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 70323
    attempts: 2
    model_returned: gemini-3.1-pro-preview
    finish_reason: STOP
    prompt_tokens: 12001
    candidates_token_count: 1603
    thoughts_token_count: 5597
    note: First attempt hit MAX_TOKENS at maxOutputTokens=8192 (thoughts consumed budget); retried at 16384 with success.
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-29-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 58870
    attempts: 1
    model_returned: deepseek-v4-flash
    system_fingerprint: fp_058df29938_prod0820_fp8_kvcache_20260402
    finish_reason: stop
    prompt_tokens: 11289
    completion_tokens: 5060
    reasoning_tokens: 2772
    note: "deepseek-reasoner alias resolved to deepseek-v4-flash (config note still records V3.2-Thinking from 2026-02-20 — alias has shifted again; flag for config refresh)."
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-29-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 43728
    attempts: 1
    model_returned: grok-4-1-fast-reasoning
    system_fingerprint: fp_1fb796da08
    finish_reason: stop
    prompt_tokens: 10962
    completion_tokens: 1792
    reasoning_tokens: 2348
    raw_json: Projects/obsidian-applenotes-import/reviews/raw/2026-04-29-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: action-plan.md (obsidian-applenotes-import)

**Artifact:** `Projects/obsidian-applenotes-import/design/action-plan.md`
**Mode:** full
**Reviewed:** 2026-04-29
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, xAI grok-4-1-fast-reasoning
**Review prompt:** PLAN-executability review focused on M0 spike design, milestone exit gates, sequencing/parallelism, pattern application, and M6 iteration budget. Architecture is out of scope (frozen in spec rev 4). Reviewers asked to flag UNVERIFIABLE CLAIMS for grounded checking.

---

## OpenAI (gpt-5.4)

Below is a PLAN-focused review of the provided `action-plan.md`, using `tasks.md` as the execution reference.

---

## Overall assessment

The plan is generally strong on executability. It is clearly milestone-structured, decomposed into atomic tasks, and is unusually disciplined about binary gates and safety-critical sequencing. The M0 spike design is especially valuable here because the unresolved assumptions are correctly concentrated around real-world Apple Notes / TCC behavior rather than abstract implementation uncertainty.

The main issues are not architectural, but executional:
- a few internal inconsistencies between `action-plan.md` and `tasks.md`,
- one likely incorrect dependency reference around locked-note evidence,
- one sequencing gap around the settings-tab dependency for TCC re-check,
- and some under-specification in how milestone gates are actually evaluated when a spike "defers" rather than validates.

I do **not** see a fatal plan-level flaw, but I do see several significant cleanups needed before execution starts.

---

# Findings

- [F1]
- **Severity:** SIGNIFICANT
- **Finding:** The locked-note evidence dependency is inconsistently referenced and likely wrong in `action-plan.md`.
- **Why:** In `tasks.md`, OAI-027 is the A6 locked-note error spike, and OAI-006 correctly depends on `OAI-027`. But in `action-plan.md` M2 success criteria, it says locked-note behavior is implemented "per OAI-026 evidence." OAI-026 is the TCC denial spike, not the locked-note spike. This is a concrete execution hazard because it can cause the developer to wire the wrong evidence source into OAI-006 or miss the true prerequisite.
- **Fix:** In `action-plan.md`, replace "per OAI-026 evidence" with "per OAI-027 evidence" everywhere relevant. Do a final ID consistency sweep across all milestone descriptions.

---

- [F2]
- **Severity:** SIGNIFICANT
- **Finding:** There is a missing explicit dependency from OAI-019 to OAI-003, even though OAI-019's acceptance requires the settings-tab "Re-check permission" button to function.
- **Why:** `tasks.md` says OAI-003 creates the settings tab and wires the "Re-check permission" button with a stub, while OAI-019 fills in the TCC probe handler. But OAI-019 currently depends only on OAI-004 and OAI-026. That means the plan claims OAI-019 can execute before OAI-003 exists, which is not true if its acceptance includes settings-tab guidance and button behavior. This is a classic missing dependency, and it affects sequencing realism.
- **Fix:** Add `OAI-003` as an explicit dependency of `OAI-019`, or split OAI-019 into:
  1. core probe/detection logic (`depends on OAI-004, OAI-026`),
  2. UI wiring/guidance hookup (`depends on OAI-003`).

---

- [F3]
- **Severity:** SIGNIFICANT
- **Finding:** The M0 exit criteria are slightly inconsistent between "resolved" and "validated/deferred," especially for A1 and A3.
- **Why:** The plan says M0 closes only when "all 4 spikes resolved," which is good. But the details allow some outcomes to be deferred rather than empirically validated:
  - A1 can defer to first-run measurement if the library is <1k.
  - A3 can be "deferred-to-implement-with-fallback if no fixture available" in the plan text, but `tasks.md` more strongly says create a test note if necessary.

  This creates ambiguity: does a deferred outcome truly satisfy M0 closure, or should it force a downstream task adjustment? Without a sharper rule, the team can claim M0 success without actually reducing uncertainty enough.
- **Fix:** Tighten M0 closure language:
  - A1: explicitly state that "deferred to first-run measurement" is an allowed **resolved** outcome only if the fallback requirement is recorded and OAI-013 acceptance is updated accordingly.
  - A3: align with `tasks.md` and remove soft defer language from the plan unless creating a fixture is impossible; if impossible, require a decision record plus explicit downstream fallback task update.

---

- [F4]
- **Severity:** SIGNIFICANT
- **Finding:** The M2 milestone exit gate in `action-plan.md` is weaker than the task-level gate in `tasks.md`.
- **Why:** `tasks.md` M2 exit gate says: "G1 re-test passes via production wrapper. **All 4 scripts return typed parsed results.**" But `action-plan.md` M2 exit gate says only: "G1 re-test passes via the production wrapper. Adversarial unit test (script returns malformed JSON) does not crash the runner." That omits successful typed return validation for OAI-005/006/007 and weakens the milestone gate below the task ACs.
- **Fix:** Make the M2 exit gate match `tasks.md`: require both G1 re-test **and** successful typed parsed results for runner/list/fetch/delete scripts.

---

- [F5]
- **Severity:** SIGNIFICANT
- **Finding:** The M6 iteration budget of 2–4 rounds is plausible only if "round" means tight internal rework inside M6, not full milestone re-review cycles.
- **Why:** OAI-016a–e spans orchestration, pure verification, delete gating, batch cancellation/progress, and receipts, with adversarial and integration tests across AppleScript, vault writes, and index persistence. For a single developer, this is exactly the kind of cluster where edge cases surface late. So 2–4 focused rework rounds is realistic. However, if the plan assumes all non-M6 tasks are single-pass and stable, that may be optimistic because M6 defects often force small corrections in OAI-011/OAI-012/OAI-007 interfaces. The risk is not that 2–4 is too high; it's that the budget is too narrowly scoped.
- **Fix:** Keep "2–4 rounds" for M6, but explicitly allow "spillback fixes" into OAI-007/OAI-011/OAI-012 interfaces without treating that as plan failure. Phrase it as "2–4 rework rounds centered on M6, with limited adjacent-interface adjustments expected."

---

- [F6]
- **Severity:** SIGNIFICANT
- **Finding:** There is a false sense of independence in "all other tasks single-pass."
- **Why:** For this project, several tasks are likely to need at least one adjustment once exercised against real Notes data:
  - OAI-005/006 AppleScript parsing,
  - OAI-009 conversion on captured HTML,
  - OAI-012 repair edge cases,
  - OAI-019 TCC behavior.

  These are not architecture concerns; they are execution realities of platform-bound integration work. Declaring everything outside M6 "single-pass" may bias execution against healthy iteration and lead to premature closure pressure.
- **Fix:** Soften the statement. Example: "M6 is the only milestone with an explicit 2–4 round budget; all other tasks are planned as single-pass but may require one corrective pass if probe/integration evidence contradicts assumptions."

---

- [F7]
- **Severity:** MINOR
- **Finding:** The M0 Stage 0 budget rule is internally inconsistent in percentage-vs-time framing.
- **Why:** The plan says M0 spikes follow staged-spike-with-bail and later says "Stage 0 ≤30 min." In Compound Notes it says "Stage 0 ≤10% of total budget." Those can both be true, but because no total spike budget is stated, the 10% framing is not actionable. This slightly reduces clarity.
- **Fix:** Normalize to one operative rule in the action plan. Example: "For this project, Stage 0 budget is capped at 30 minutes per spike; this is the concrete instantiation of the staged-spike-with-bail pattern."

---

- [F8]
- **Severity:** MINOR
- **Finding:** The critical-path diagram is directionally useful but visually ambiguous around M6 prerequisites.
- **Why:** The diagram communicates that M6 sits behind M2/M3/M4, which is correct. But the branch formatting around `OAI-007,011,012 ──┤` and `OAI-016a..e` is hard to parse, and it obscures that OAI-016d also depends on OAI-013. Since sequencing/parallelism is a requested review focus, clarity matters.
- **Fix:** Rewrite the critical path as a simple dependency list or Mermaid graph. At minimum, explicitly enumerate:
  - OAI-016a depends on OAI-006/OAI-011/OAI-012
  - OAI-016c depends on OAI-007/OAI-016b
  - OAI-016d depends on OAI-016a/b/c and OAI-013

---

- [F9]
- **Severity:** MINOR
- **Finding:** M0 A1 perf probe's success criteria are reasonable, but the wording "≤5s for ~1k notes" in the plan is looser than the concrete AC in `tasks.md`.
- **Why:** `tasks.md` is more precise:
  - stage 0 counts notes,
  - only times full listing if ≥1k,
  - if <1k, documents the smaller library and defers to first-run measurement.

  The plan summary compresses this to "≤5s for ~1k notes," which is fine as shorthand but can be read as requiring a 1k corpus that may not exist. Not a logic flaw, just a small clarity mismatch.
- **Fix:** Mirror the task wording more closely in M0 success criteria so the "small library" path is obviously valid.

---

- [F10]
- **Severity:** STRENGTH
- **Finding:** The selected M0 spikes are the right load-bearing assumptions for plan-phase validation.
- **Why:** They target the places where desktop/macOS automation projects most often fail in practice:
  - performance of enumerating real Notes libraries,
  - attachment-bearing HTML shape,
  - TCC denial signatures,
  - locked-note access errors.

  These are materially better PLAN probes than generic implementation spikes because they reduce platform uncertainty before coding.
- **Fix:** None.

---

- [F11]
- **Severity:** STRENGTH
- **Finding:** Milestone exit gates are mostly binary, testable, and appropriately scoped.
- **Why:** The plan consistently uses pass/fail milestone closure conditions:
  - plugin loads cleanly,
  - specific smoke tests pass,
  - adversarial tests pass,
  - integration batch yields exact outcomes,
  - release asset inspection passes,
  - submission PR opened.

  This is unusually executable and should help avoid "mostly done" ambiguity.
- **Fix:** None, aside from aligning M2 gate language with `tasks.md` per F4.

---

- [F12]
- **Severity:** STRENGTH
- **Finding:** Sequencing is mostly realistic and safety-conscious.
- **Why:** The plan correctly puts M6 behind real surfaces rather than over-mocking, and correctly runs OAI-012 in parallel early to de-risk the M6 cluster. The choice to defer M6 until OAI-007/OAI-011/OAI-012 exist is executionally sound for a verify-before-delete workflow.
- **Fix:** None.

---

- [F13]
- **Severity:** STRENGTH
- **Finding:** The application of patterns is practical rather than ornamental.
- **Why:** The named patterns actually map to execution:
  - staged-spike-with-bail is concretely instantiated in M0,
  - atomic-rebuild is appropriately used for index repair,
  - gate-evaluation is reflected in milestone exits and verify-before-delete behavior.

  This improves plan discipline without bloating it.
- **Fix:** None.

---

- [F14]
- **Severity:** SIGNIFICANT
- **Finding:** There is one additional execution risk undercaptured in the plan: environment/setup friction for M0 and M2 integration testing on a real Apple Notes library.
- **Why:** Multiple tasks assume access to:
  - a macOS environment,
  - Notes populated with specific fixtures,
  - TCC reset and re-grant ability,
  - potentially a configured Notes password for locked-note testing,
  - stable Recently Deleted behavior.

  The plan addresses the probes, but not the likelihood that environment preparation itself consumes meaningful time. For a single developer, that setup friction can dominate early execution.
- **Fix:** Add a small "test environment readiness" checklist before M0/M2:
  - confirm macOS test machine,
  - confirm Notes app signed in and syncing,
  - confirm ability to create/delete test notes,
  - confirm TCC reset/regrant path,
  - confirm locked-note test setup available.

---

- [F15]
- **Severity:** MINOR
- **Finding:** The plan may slightly overstate the need to "return to PLAN risk review" for A1 >10s without saying what the likely outcomes are.
- **Why:** The bail rule is good, but operationally a >10s result probably means either narrowing v1 scope, requiring streamed loading and stronger UX constraints, or reconsidering whether full-library prefetch is acceptable at all. The current wording flags the escalation but not the likely decision space.
- **Fix:** Add one sentence under A1: "If >10s, PLAN review decides between explicit v1 scope reduction, mandatory streaming/pagination plus progressive search, or project pause pending revised retrieval strategy."

---

- [F16]
- **Severity:** MINOR
- **Finding:** The M8 dependency chain is realistic, but `OAI-021 depends on M6 + M7 complete` may be stricter than necessary.
- **Why:** README, license, and screenshots can begin before all of M6/M7 are complete, even if finalization should wait until then. This is not harmful, but it slightly understates optional parallelism.
- **Fix:** Keep formal dependency if desired, but note that README drafting and screenshot placeholders may begin earlier to reduce endgame crunch.

---

## Direct answers to the 5 requested review questions

### 1) Does M0 correctly identify the load-bearing assumptions, with appropriate Stage-0 budgets and bail rules?
**Yes, mostly.**
- The four assumptions chosen are the right ones.
- Stage-0 budget discipline is good.
- Bail rules are sensible and proportionate.

**Needed fixes:**
- Clarify "resolved" vs "deferred but accepted" outcomes.
- Align A3 wording between plan and task list.
- Clean up the Stage-0 budget phrasing.

### 2) Are the milestone exit gates binary, testable, and proportionate?
**Yes, with one notable mismatch.**
- Most gates are crisp and executable.
- M2 gate in `action-plan.md` is weaker than the task-defined M2 gate and should be strengthened.
- Otherwise the gate-evaluation pattern is well applied.

### 3) Is sequencing/parallelism realistic? Any false or missing dependencies?
**Mostly realistic, with one real missing dependency and one minor overconstraint.**
- Good: M4 parallelized early, M6 delayed until real dependencies exist, M7 starts early enough.
- Missing dependency: OAI-019 should depend on OAI-003 for the settings-tab re-check wiring.
- Minor overconstraint: M8 docs work could start informally before M6/M7 finish.

### 4) Is the M6 iteration budget (2–4 rounds) realistic?
**Yes, if interpreted correctly.**
- For a single developer working through verify-before-delete with adversarial tests, 2–4 rounds is realistic.
- It may even be prudent.
- But allow for small spillback fixes into OAI-007/OAI-011/OAI-012 rather than pretending M6 can iterate in total isolation.

### 5) Are there execution risks not captured, or risks the plan inflates?
**Yes.**
- **Undercaptured risk:** real-environment readiness/setup friction for Notes/TCC/locked-note testing.
- **Potentially inflated framing:** "all other tasks single-pass" is too optimistic and may create unhealthy pressure.
- The rest of the risk posture is generally well calibrated.

---

## Unverifiable claims

I did not identify any GitHub issue numbers, paper titles, URLs, or attributed statistics in the artifact that require grounded external verification.

One internal historical/comparative statement cannot be independently verified from the provided materials:

- [F17]
- **Severity:** SIGNIFICANT
- **Finding:** **UNVERIFIABLE CLAIM:** "prior project (pydantic-ai-adoption) had a 0.04x estimate ratio because of an early bail."
- **Why:** This may be useful as internal calibration, but it cannot be verified from the artifact set provided and does not materially support executability of this plan. Unverified historical comparisons can bias estimation thinking.
- **Fix:** Either remove it from the plan artifact, or move it to a private retrospective note with a link to the underlying evidence if you want to retain it.

---

## Bottom line

**Recommended disposition: Approve with targeted revisions.**

The plan is executable and well-structured. Before starting implementation, I would make these specific edits:

1. Fix the OAI-026/OAI-027 locked-note reference error.
2. Add the missing `OAI-003 -> OAI-019` dependency, or split OAI-019.
3. Align M2 exit gate text with `tasks.md`.
4. Clarify M0 closure semantics for deferred outcomes.
5. Reword "all other tasks single-pass" to allow lightweight corrective passes.
6. Optionally add a small pre-M0 environment-readiness checklist.

If you want, I can also convert this into a terse "review actions" list suitable for patching the plan doc directly.

---

## Google (gemini-3.1-pro-preview)

Here is the structural review of the `obsidian-applenotes-import` Action Plan, focused purely on executability, sequencing, risk management, and internal consistency.

### Critical Path & Consistency Findings

- **[F1]**
- **Severity:** SIGNIFICANT
- **Finding:** The M0 Stage 0 budget rule (≤30 min, bail to "deferred to first-run measurement") is dangerously applied as a blanket rule. While this fallback makes sense for the A1 performance spike, bailing on A5 (TCC denial) or A6 (Locked Notes) to "first-run measurement" would leave M2 and M7 without the exact error strings needed for regex matching, fundamentally destabilizing the plan.
- **Why:** If the developer hits the 30-minute limit on A5, the plan currently dictates abandoning the spike, meaning OAI-019 will have to guess the TCC denial stderr strings during implementation, defeating the purpose of the spike.
- **Fix:** Explicitly branch the bail rules in the M0 overview. If A5 or A6 exceed budget, the bail action should be "assume `{skipped: 'unknown'}` or generic timeout fallback, and formally document the limitation" rather than deferring measurement.

- **[F2]**
- **Severity:** SIGNIFICANT
- **Finding:** The plan does not account for the execution latency of spawning thousands of sequential Node `child_process` instances. M0 (OAI-024) profiles the performance of fetching the *list* of notes (A1), but misses profiling the latency of the M6 batch orchestrator (OAI-016d), which spawns `osascript` sequentially *per note* to fetch bodies and delete.
- **Why:** Spawning Node child processes carries significant overhead (~100–300ms per spawn). A batch of 1,000 notes could add 5–10 minutes of pure process-spawning latency, entirely separate from Apple Notes' own execution time. This is a severe, unmeasured execution risk.
- **Fix:** Add a secondary check to OAI-024 (or a new M0 probe) to measure the latency of 10 sequential `osascript` fetch invocations. If process overhead is prohibitive, allocate time in M6 to implement a long-lived interactive `osascript` process (connection pooling), or adjust OAI-016d's progress UI to clearly communicate the expected duration.

- **[F3]**
- **Severity:** MINOR
- **Finding:** There is a minor contradiction regarding M5 (UI) parallelism. The critical path diagram and the `tasks.md` table show `OAI-013` (Notes Modal) strictly depending on `OAI-005, 006, 012`. However, the "Risk-Adjusted Sequencing Notes" explicitly state that `OAI-013` can run parallel and start with mock data *before* 005/006 are done.
- **Why:** Conflicting dependency definitions create ambiguity about when M5 is actually cleared to start.
- **Fix:** Change the strict dependency for OAI-013 in `tasks.md` to `Depends On: OAI-002, OAI-012`, and clarify that it relies purely on the agreed *JSON contract* of 005/006 (allowing true parallel execution), needing the real scripts only for the M5 exit gate integration test.

- **[F4]**
- **Severity:** SIGNIFICANT
- **Finding:** Task OAI-012 (Import Index) requires a "Progress indicator if scan exceeds 2s" for index repair. However, OAI-012 is a backend store module with no listed UI dependencies.
- **Why:** It is unclear how a pure backend data-store task will render a progress indicator without breaking abstraction or accidentally expanding the scope of OAI-012 into UI development.
- **Fix:** Clarify in OAI-012 that this progress indicator uses Obsidian's built-in, globally available `Notice` API rather than a custom DOM modal, keeping the task confined to ≤5 files and zero UI dependencies.

- **[F5]**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: The artifact asserts specific target versions for third-party tooling ("`eslint-plugin-obsidianmd` ... 0.1.9 template default vs 0.2.4 latest") and cites a highly specific historical estimation metric ("prior project pydantic-ai-adoption had a 0.04x estimate ratio").
- **Why:** These claims rely on external repository states and internal project context that cannot be independently verified through the provided data.
- **Fix:** Ground the `eslint-plugin` version check during OAI-001 by inspecting the actual npm registry state at the time of execution. Treat the 0.04x historical ratio purely as contextual flavor rather than a predictive mathematical baseline for this project.

- **[F6]**
- **Severity:** SIGNIFICANT
- **Finding:** The fallback plan for A1 >5s latency (OAI-013 paginated/streamed loading contingency) poses a severe feasibility risk. AppleScript `whose` queries and bounds-based pagination (e.g., `items 1 thru 50`) are notoriously unoptimized in macOS Notes and often execute *slower* than full non-paginated queries, or fail entirely.
- **Why:** If the >5s contingency is triggered, the developer might waste the M5 implementation budget attempting to build a pagination system that the underlying Apple Events bridge cannot support.
- **Fix:** Add to the A1 bail rule: "If listing takes >5s, before committing to a paginated UI in OAI-013, quickly probe if `items 1 thru 50` is actually faster than `every note`. If not, shift the contingency to an asynchronous background load with a loading spinner."

### Structural Strengths

- **[F7]**
- **Severity:** STRENGTH
- **Finding:** The M6 iteration budget (2–4 rework rounds) and internal task separation are exceptionally realistic and well-designed for a single developer.
- **Why:** By splitting orchestrator sequencing (OAI-016a), side-effect-free pure verification (OAI-016b), and the soft-delete gate (OAI-016c) into distinct tasks, the plan isolates the complexity. TDD-style adversarial testing on OAI-016b is highly feasible because it requires no real vault writes or AppleScript side effects, meaning the 2–4 rounds of rework will be tightly localized and fast to iterate on.

- **[F8]**
- **Severity:** STRENGTH
- **Finding:** The milestone exit gates strictly utilize the gate-evaluation pattern and are flawlessly binary, actionable, and proportionate.
- **Why:** Using concrete adversarial triggers as exit criteria (e.g., M4: "corrupt JSON triggers safe-degraded", M6: "simulated verify-fail confirms delete-not-called via spy") mathematically prevents the project from moving past critical safety checkpoints based on "happy path" success alone. Applying the atomic-rebuild pattern to OAI-012 further fortifies the data-loss defenses.

---

## DeepSeek (deepseek-reasoner)

## Structured Review: PLAN Executability

### Findings

#### **F1** (M0 Spike Design – Assumption Coverage)
- **Severity:** STRENGTH
- **Finding:** The four M0 spikes (A1 perf, A3 attachment-HTML, A5 TCC denial, A6 locked-note error) correctly target the load-bearing assumptions identified in the spec. Each has a proportionate Stage-0 budget (≤30 min) and explicit bail rules that either trigger a contingency (paginated/streamed modal for A1 >5s) or return to PLAN risk review (A1 >10s, A3 binary/error, etc.).
- **Why:** This de-risks the highest-uncertainty technical decisions before committing to implementation, preventing costly rework. The staged-spike-with-bail pattern is applied consistently.
- **Fix:** None.

#### **F2** (M0 – A1 Bail Rule Inconsistency)
- **Severity:** MINOR
- **Finding:** The M0 section states that A1 bail rule is "if listing >10s, return to PLAN risk review," but the OAI-024 task in tasks.md defines three bucketed outcomes: ≤5s (simple modal), 5–10s (contingency: pagination/streaming), >10s (return to PLAN). The plan later correctly references the 5–10s contingency ("If A1 spike triggered the >5s contingency, modal MUST use paginated/streamed loading"). The plan-level description is slightly imprecise but consistent in detail elsewhere.
- **Why:** Could cause confusion if someone reads only the M0 summary and misses the three-way outcome. No practical impact because the task definition is the binding reference.
- **Fix:** Add a brief note in the M0 section that A1 has a three-way outcome (≤5s simple, 5–10s contingency, >10s return to PLAN) to align with the task.

#### **F3** (Milestone Exit Gates – Binary & Testable)
- **Severity:** STRENGTH
- **Finding:** All eight milestone exit gates are binary (pass/fail) and objectively testable. Examples: M0 requires spike artifacts present; M1 requires `npm run build` and `npm run lint`; M6 requires adversarial tests pass and a 3-note integration test produces correct outcomes. No gate uses subjective language like "reviewed by maintainer" or "at least 90% coverage." The gates are proportionate to each milestone's scope (e.g., M0 is light, M6 is heavy).
- **Why:** Clear gates prevent scope creep and enable deterministic phase transitions. This is a well-structured application of the gate-evaluation pattern.
- **Fix:** None.

#### **F4** (Sequencing – M5 Dependency on M2/M4 Correctly Handled)
- **Severity:** STRENGTH
- **Finding:** The action plan correctly notes that the modal (M5) can begin development with mock data while M2 and M4 are still in progress, as long as the JSON shapes are locked. This is explicitly documented in the risk-adjusted notes. The critical path diagram shows the correct eventual ordering (OAI-013 depends on OAI-005/006/012). No false parallelism is claimed for M5.
- **Why:** Allows parallel development without blocking on full M2 completion, reducing overall timeline.
- **Fix:** None.

#### **F5** (Sequencing – M7 Parallelism with M5 is Feasible)
- **Severity:** STRENGTH
- **Finding:** M7 (TCC probe, platform gate) depends only on OAI-004 (M2) and M0 spikes, so it can indeed run in parallel with M5's OAI-013 (modal UI) and M6's implementation. The only serial handshake is OAI-015 (command wiring) depending on OAI-019, which is natural and correctly captured.
- **Why:** Maximizes developer utilization without introducing integration risk.
- **Fix:** None.

#### **F6** (M6 Iteration Budget – 2–4 Rounds Realistic)
- **Severity:** STRENGTH
- **Finding:** The composite verify-before-delete cluster (OAI-016a–c) is the most safety-critical piece, and the plan budgets 2–4 rework rounds. Given the surface area (canonical pipeline, adversarial tests for four failure modes, spy-based verification, delete gate integration with real AppleScript), this is realistic for a single developer. The budget is not padded (no other milestones budget rework rounds), and the plan explicitly labels it as "expected" (not guaranteed). This is appropriate.
- **Why:** Anticipates edge cases in the adversarial tests (e.g., index shape mismatch, partial-write simulation) without over-engineering.
- **Fix:** None.

#### **F7** (Missing Execution Risk – TCC Behavior Drift)
- **Severity:** SIGNIFICANT
- **Finding:** The A5 spike captures current Apple Event denial patterns, but the plan does not address the risk that future macOS updates could change the exact stderr text, error codes, or the TCC grant flow. The detection regex in OAI-019 is keyed to the spike's evidence, which may become stale. There is no fallback strategy (e.g., generic AppleScript timeout / error-code check) beyond the generic-error fallback that "does NOT auto-disable on unmatched."
- **Why:** A future OS update could silently break TCC detection, leaving users with non-functional commands and no clear diagnosis. The plan's generic-error fallback (err on the side of letting the user retry) mitigates false positives but not false negatives (i.e., denial undetected → command fails with cryptic AppleScript error).
- **Fix:** Recommend adding a task or note in OAI-019 to log the raw stderr for future diagnostic support, and document in README that TCC behavior is tied to macOS version (known limitation). Optionally, add a step to the self-critique checklist to re-run the A5 spike on the target macOS version before release.

#### **F8** (Missing Execution Risk – Zero-Note Library)
- **Severity:** MINOR
- **Finding:** The plan and tasks do not explicitly handle the case where the user's Apple Notes library has zero notes. The A1 spike (OAI-024) measures listing latency only if user has notes; if library size is 0, it defers A1. The modal (OAI-013) could then show an empty list. This is not a bug, but there is no stated behavior (e.g., show a "No notes found" message vs. run a one-time probe to confirm zero). The app may handle this naturally via an empty list, but the acceptance criteria don't specify.
- **Why:** Users with empty libraries are unlikely, but the oversight could lead to a confusing empty modal without any guidance.
- **Fix:** Add a simple acceptance criterion to OAI-013: if the note list is empty after the AppleScript query, display an informational message in the modal (e.g., "No notes found in Apple Notes.").

#### **F9** (Unverifiable Claims – Prior Project Ratio)
- **Severity:** SIGNIFICANT (prefixed UNVERIFIABLE CLAIM)
- **Finding:** The action-plan mentions "prior project (pydantic-ai-adoption) had a 0.04x estimate ratio because of an early bail." This is a quantitative claim about a different project's estimation performance. There is no publicly available evidence provided in the artifact, and the reviewer cannot independently verify the ratio or the project context.
- **Why:** Such claims may be used to justify estimation confidence, but if unverified, they are anecdotal and could be misleading. The plan does not rely on this claim for any critical decision, but it's still a factual statement that should be backed by project records.
- **Fix:** If the claim is part of an internal knowledge base, note that it is internal and cannot be externally verified. Suggest replacing with a more general statement (e.g., "prior projects have shown that early bail checkpoints can compress the implementation timeline").

#### **F10** (Pattern Documentation – Internal References)
- **Severity:** MINOR
- **Finding:** The plan references `_system/docs/solutions/staged-spike-with-bail.md` and `_system/docs/solutions/atomic-rebuild-pattern.md` as authoritative pattern descriptions. For a single-developer project, these internal documents are likely available, but the plan does not summarize their key rules (Stage 0 ≤10% of budget, atomic-swap validation). The description in the plan is sufficient for the reviewer, but future maintainers (or the developer themselves if memory fades) might need to refer back to the pattern docs.
- **Why:** Not a problem now, but documenting the pattern's essential rules inline (e.g., in a "Design Patterns" section) would improve long-term readability.
- **Fix:** Consider adding a brief inline summary of each pattern's core rule (e.g., "staged-spike-with-bail: Stage 0 ≤10% of budget; bail if Stage 0 fails"; "atomic-rebuild: build staging index, validate, atomic swap; never overwrite live directly").

#### **F11** (M0 Exit Gate – Spec Rev 5 Ambiguity)
- **Severity:** MINOR
- **Finding:** The M0 exit gate says "PLAN locks the resulting decisions in spec rev 5 (or in design/decisions/ if scope is small)." This creates ambiguity about whether a formal spec revision is required or just design decision records. The tasks list only `design/decisions/` artifacts output from spikes. If spec rev 5 is needed for M0 exit, it is not listed as a task.
- **Why:** Could cause the developer to think they need to create a spec revision when the actual gate only requires artifacts and decision records. This is a minor inconsistency.
- **Fix:** Clarify that the M0 exit gate only requires all spike artifacts present and any decisions recorded in `design/decisions/`. Spec rev 5 is a possible outcome but not a required artifact for M0 exit.

### Summary

The action plan is well-structured, with clear milestones, binary exit gates, and realistic parallelism. The M0 spike phase is appropriately scoped. The M6 iteration budget (2–4 rounds) is reasonable for the safety-critical composite verify-before-delete. The main execution risk not adequately addressed is the potential for TCC detection to break with future macOS updates; this should be mitigated with a logging/fallback enhancement. The unverifiable claim about a prior project ratio should be noted as internal knowledge.

**Overall rating: READY with minor improvements.**

---

## xAI Grok (grok-4-1-fast-reasoning)

- [F1]
  [Severity]: CRITICAL
  [Finding]: M0 exit gate proposes "PLAN locks the resulting decisions in spec rev 5 (or in design/decisions/ if scope is small)", but the context explicitly states the SPECIFY-phase artifact (specification rev 4) is frozen after peer-review, with architectural concerns already addressed there — no further spec revisions are permitted.
  [Why]: This creates a logical contradiction and potential scope creep; unlocking the spec mid-PLAN violates the frozen status and invites re-review of architecture, which the review instructions prohibit. Decisions must stay in design/decisions/ to preserve spec integrity.
  [Fix]: Revise M0 exit gate to "All 4 spikes resolved. Decisions recorded ONLY in design/decisions/. No spec revisions. M1 may not start until M0 closed."

- [F2]
  [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: Critical path diagram and text claim "single longest dependency chain is M0 → M1 → M2 → M3 → M6 → M8 (12 tasks)", but tracing deps in tasks.md yields longer chains (e.g., M0-OAI024 → OAI-001 → OAI-002 → OAI-004 → OAI-005 → OAI-009 → OAI-011 → OAI-016a/b/c/d/e (5 tasks) → OAI-021 → OAI-022 → OAI-023 = ~17 tasks assuming M0 as 1).
  [Why]: Understating the critical path length (~40% error) inflates feasibility perception for a single-dev hobby project, risking burnout or delays; parallelism claims (e.g., M4 parallel) don't shorten the true longest chain enough to hit "12".
  [Fix]: Recount and update critical path to accurate longest chain (e.g., "17 tasks"); add task count per milestone to diagram legend.

- [F3]
  [Severity]: SIGNIFICANT
  [Finding]: False dependency/parallelism mismatch: Plan claims M7 "parallel to M5/M6", M4 "parallel to M2/M3", but tasks.md OAI-015 (end of M5) depends on OAI-019 (M7), and OAI-013 (start of M5) depends on OAI-012 (M4), serializing M4/M7 before completing M5/M6.
  [Why]: Single dev can't truly parallel if deps force ordering; this misrepresents executability, potentially causing stalls when "parallel" milestones block the critical path.
  [Fix]: Update parallelism claims: "M4 parallel to early M2/M3 (up to OAI-006); M7 parallel to M5 (up to OAI-014), serial before OAI-015/M6." Adjust ASCII diagram arrows accordingly.

- [F4]
  [Severity]: SIGNIFICANT
  [Finding]: UNVERIFIABLE CLAIM: eslint-plugin-obsidianmd versions pinned as "0.1.9 template default vs 0.2.4 latest" (OAI-001, decisions/002); no source for "latest" or template default verifiable without external check.
  [Why]: Wrong version risks lint failures or incompatibility, blocking M1 exit gate; plan treats as locked decision without evidence.
  [Fix]: Flag as M0 spike or defer to OAI-001 runtime: "Run `npm info eslint-plugin-obsidianmd version`; record actual latest + template default in decisions/002."

- [F5]
  [Severity]: SIGNIFICANT
  [Finding]: M0 spikes lack explicit parallelism note despite independence (all "not started | —"), but critical path treats M0 as prefix — no risk if one spike (e.g., A1) bails and returns to "PLAN risk review".
  [Why]: Single dev might sequence spikes linearly (~2h total Stage 0), but bail on one (e.g., A1 >10s) halts all; unclear if spikes run fully parallel or bail-any halts M0.
  [Fix]: Add to M0: "Run all 4 spikes in parallel (independent); evaluate collective outcomes for exit gate. Single bail returns to PLAN risk review without completing others."

- [F6]
  [Severity]: SIGNIFICANT
  [Finding]: M6 iteration budget "2–4 rework rounds" for OAI-016a-e (5 safety-critical tasks, composite verify-delete, ≥4 adversarial + 3-note integration tests) is optimistic for single-dev hobby project; integration surface (vault/index/osascript) likely surfaces >4 edge cases per round.
  [Why]: Underbudgeting high-risk cluster (plan's "highest-stakes") risks incomplete gates or rushed submission; prior note mentions "pydantic-ai-adoption" 0.04x compression from bail — but M6 post-spikes, no such dynamic.
  [Fix]: Revise to "3–6 rework rounds on M6 (prioritize 016b/c gates first); track rounds in changelog."

- [F7]
  [Severity]: MINOR
  [Finding]: Milestone exit gates are mostly binary/testable (e.g., "All adversarial tests pass"), but some are file-checks (e.g., M0 "All 4 spike artifacts present") without version/content validation.
  [Why]: Non-technical gates risk superficial closure (empty files); less executable for self-review.
  [Fix]: Append "with ACs met per tasks.md" to all file-based gates (e.g., M0, M1 lint).

- [F8]
  [Severity]: MINOR
  [Finding]: Bail rules in M0 tasks.md (e.g., OAI-024 ">10s, return to PLAN") mismatch plan's Stage 0 budget ("≤30 min... bail to deferred"), creating ambiguity on probe depth.
  [Why]: Dev might overprobe on failing Stage 0, burning time; inconsistent criteria reduce clarity.
  [Fix]: Align: tasks.md bails reference "per staged-spike-with-bail.md Stage 0 rule"; plan notes "bail if Stage 0 >30min or perf >10s".

- [F9]
  [Severity]: MINOR
  [Finding]: No explicit task or gate for end-to-end integration test beyond M6 3-note batch; M8 assumes "M6/M7 complete" but no full smoke test (e.g., TCC denial mid-batch).
  [Why]: Milestone silos risk cross-milestone bugs (e.g., modal cancellation + index repair); hobby project needs explicit E2E.
  [Fix]: Add OAI-028 (post-M7): "Full E2E smoke: TCC denial → grant → import 3-notes batch → cancel → verify outcomes." Move to M8 dep.

- [F10]
  [Severity]: MINOR
  [Finding]: Plan references internal patterns ("staged-spike-with-bail.md", "atomic-rebuild-pattern.md", "gate-evaluation pattern") without embedding criteria, assuming familiarity.
  [Why]: Reduces standalone executability; single dev might second-guess application (e.g., is M6 verify "pure" per pattern?).
  [Fix]: Inline 1-sentence summaries (e.g., "staged-spike-with-bail: Stage 0 ≤10% budget verifies assumption; bail on fail.").

- [F11]
  [Severity]: STRENGTH
  [Finding]: M0 correctly targets 4 load-bearing assumptions (A1 perf, A3 attachments, A5 TCC, A6 locked) with Stage-0 probes + bail rules tied to real evidence (e.g., stderr for OAI-026).
  [Why]: De-risks critical AppleScript assumptions early; staged-spike-with-bail prevents sunk cost on invalid paths (e.g., A1 >10s halts). Edge: Handles small libraries via deferral.
  [Fix]: N/A

- [F12]
  [Severity]: STRENGTH
  [Finding]: Exit gates are proportionate (e.g., M2: "G1 re-test via wrapper"; M4: "adversarial tests pass") and binary (tests/files present/fail), evaluated per gate-evaluation pattern.
  [Why]: Enforces quality at phase boundaries without overkill; verifiable via tasks.md ACs. Edge: M6 3-note integration covers per-note independence.
  [Fix]: N/A

---

## Synthesis (Claude main session)

**Headline:** Plan is executable; no fatal flaws. 4-reviewer panel surfaced 1 CRITICAL (Grok) which is real but a wording issue, plus a cluster of concrete plan/task consistency bugs (cross-references, missing deps, gate text drift) that should be cleaned up before M0 starts. The biggest novel signal is **Google F2** — `child_process` spawn overhead for M6 batch fetch/delete is unmeasured, and at ~100–300ms per spawn this could materially affect UX for libraries >100 notes. Two reviewers (Google, DeepSeek) classify the M6 2–4 round budget as a STRENGTH; Grok dissents alone — declined.

### Verdict
**APPROVE WITH TARGETED REVISIONS** before M0 begins. 7 must-fix actions (mostly mechanical), 12 should-fix, 6 deferred. Spec rev 4 stays frozen.

### Consensus Findings (2+ reviewers)

| Topic | Reviewers | Severity (max) |
|---|---|---|
| `pydantic-ai-adoption` 0.04x ratio is unverifiable / should be relegated | OAI-F17, GEM-F5, DS-F9, GRK-F2 | SIGNIFICANT |
| M0 → "spec rev 5" language conflicts with frozen-spec status | GRK-F1 (**CRITICAL**), DS-F11 | CRITICAL |
| M0 closure semantics for "deferred" outcomes need precision | OAI-F3, DS-F2, GRK-F8 | SIGNIFICANT |
| `eslint-plugin-obsidianmd` version pin needs runtime grounding | GEM-F5, GRK-F4 | SIGNIFICANT |
| Stage 0 budget framing (≤30min vs ≤10%) internally inconsistent | OAI-F7, GRK-F8 | MINOR |
| Inline pattern summaries would aid standalone readability | DS-F10, GRK-F10 | MINOR |
| M0 spikes target the right load-bearing assumptions (STRENGTH) | OAI-F10, DS-F1, GRK-F11 | STRENGTH |
| Milestone exit gates are binary, testable, proportionate (STRENGTH) | OAI-F11, GEM-F8, DS-F3, GRK-F12 | STRENGTH (4-reviewer) |

### Unique Findings (single reviewer; flagged genuine vs noise)

| ID | Finding | Verdict |
|---|---|---|
| OAI-F1 | OAI-026/027 cross-reference error in M2 success criteria | **Genuine** — concrete copy-edit bug |
| OAI-F2 | OAI-019 missing dep on OAI-003 (settings-tab Re-check button wiring) | **Genuine** — real missing dependency |
| OAI-F4 | M2 exit gate in plan weaker than in tasks.md | **Genuine** — concrete inconsistency |
| OAI-F6 | "All other tasks single-pass" too optimistic | **Genuine** — wording bias |
| OAI-F14 | Test-environment readiness friction undercaptured | **Genuine** — real preflight risk for solo dev |
| GEM-F1 | A5/A6 cannot defer to "first-run measurement" without defeating spike purpose | **Genuine** — sharp catch; bail policy must branch per spike |
| GEM-F2 | `child_process` spawn overhead for M6 batch unmeasured | **Genuine** — biggest novel signal in the panel; ~100–300ms per spawn × N notes |
| GEM-F3 | OAI-013 dep contradiction (mock-data parallel vs strict deps) | **Genuine** — overlaps GRK-F3 |
| GEM-F4 | OAI-012 "progress indicator" risks scope expansion into UI | **Genuine** — clarify Notice API |
| GEM-F6 | A1 paginated-fallback may not be supported by AppleScript `whose`/range queries | **Genuine** — pre-empts wasted M5 effort |
| DS-F7 | TCC behavior could drift across macOS versions; no diagnostic logging | **Genuine** — log raw stderr in OAI-019 |
| DS-F8 | Zero-note library not explicitly handled | **Defer** — Obsidian's empty-list path is acceptable |
| GRK-F2 | Critical path count (12) is wrong; actual is 13 (when chained through 016b→c→d→e) | **Genuine** — minor numerical fix |
| GRK-F3 | M4/M7 parallelism claims oversimplified vs strict deps | **Genuine** — overlaps GEM-F3 |
| GRK-F5 | M0 parallelism not stated explicitly | **Genuine** — single-line clarification |
| GRK-F7 | Some gates file-existence-only without AC validation | **Minor** — append "with ACs met" |
| GRK-F9 | No explicit E2E smoke test task | **Defer** — M6 3-note + manual pre-submit covers it |

### Contradictions

| Topic | Position A | Position B |
|---|---|---|
| **M6 iteration budget (2–4 rounds)** | OAI-F5, GEM-F7 (STRENGTH), DS-F6 (STRENGTH) — *realistic for solo dev with 016a/b/c split* | GRK-F6 — *too low; recommend 3–6 rounds* |

**Resolution:** position A wins on weight + structural argument. The 016a/b/c split is the mechanism that keeps the budget tight (pure verification has no side effects, so adversarial tests iterate fast). Grok's dissent doesn't engage with that mechanism. **Keep 2–4 rounds, but apply OAI-F6's softening** so adjacent-interface fixes in OAI-007/011/012 don't count against the budget.

### Strengths Reinforced

1. **M0 spikes target the load-bearing assumptions** (OAI-F10, DS-F1, GRK-F11 — 3 reviewers).
2. **Milestone exit gates are binary, testable, proportionate** (OAI-F11, GEM-F8, DS-F3, GRK-F12 — all 4 reviewers).
3. **Sequencing is mostly safety-conscious** (OAI-F12, DS-F4, DS-F5) — M6 correctly behind real surfaces, OAI-012 parallelized early.
4. **Pattern application is practical, not ornamental** (OAI-F13).
5. **016a/b/c split isolates verify-before-delete complexity** (GEM-F7, DS-F6).

### Action Items

**Must-fix (7):**

| ID | Source | Action |
|---|---|---|
| A1 | GRK-F1, DS-F11 | Strike "PLAN locks the resulting decisions in spec rev 5 (or in design/decisions/ if scope is small)" from M0 exit gate. Replace with: "Decisions recorded in `design/decisions/`. Spec rev 4 stays frozen; no spec revisions during PLAN." Apply consistently in `action-plan.md` M0 section and `tasks.md` M0 exit gate footer. |
| A2 | OAI-F1 | In `action-plan.md` M2 success criteria, replace "per OAI-026 evidence" with "per OAI-027 evidence" (locked-note evidence is OAI-027; OAI-026 is TCC denial). Sweep for any other ID misreferences. |
| A3 | OAI-F2 | Add `OAI-003` to OAI-019's `Depends On` in `tasks.md` (settings-tab Re-check button wiring is a prerequisite for OAI-019's UI guidance acceptance). Update M7 phase block in `action-plan.md` accordingly. |
| A4 | OAI-F4 | Strengthen M2 exit gate in `action-plan.md` to match `tasks.md`: "G1 re-test passes via production wrapper. **All 4 scripts (runner, list, fetch-body, soft-delete) return typed parsed results.** Adversarial unit test (script returns malformed JSON) does not crash the runner." |
| A5 | GEM-F1 | Branch the bail rule in M0 by spike. A1 may defer to first-run measurement (with paginated fallback recorded). A3 must produce a real fixture or a documented regex-based pre-strip alternative. **A5 and A6 cannot defer** — if Stage 0 budget exceeded, escalate to PLAN risk review (do not let OAI-019 / OAI-006 ship with guessed error patterns). |
| A6 | OAI-F17, GEM-F5, DS-F9, GRK-F2 (4-way consensus) | Remove the "pydantic-ai-adoption 0.04x" sentence from `action-plan.md` Compound Notes. If the calibration data is worth keeping, link to the `_system/docs/estimation-calibration.md` entry instead. Anecdotal external comparisons don't belong in the plan body. |
| A7 | GEM-F5, GRK-F4 | In OAI-001 acceptance, add: "Run `npm info eslint-plugin-obsidianmd version` at task time; record actual latest + obsidian-sample-plugin template default in `design/decisions/002-eslint-plugin-version.md`. Pin chosen version with rationale." Don't carry the 0.1.9-vs-0.2.4 numbers as fixed assumptions. |

**Should-fix (12):**

| ID | Source | Action |
|---|---|---|
| A8 | OAI-F3, DS-F2 | Tighten M0 closure semantics. Define "resolved" precisely: spike Stage 0 ran AND outcome is one of {validated empirically, validated via documented bail with downstream task update, escalated to PLAN risk review}. "Deferred" alone is not closure. |
| A9 | OAI-F7, GRK-F8 | Normalize Stage 0 budget framing across plan and tasks. Use only "≤30 min per spike" as the operative rule; drop "≤10% of total budget" framing (no total spike budget is stated, so the percentage is non-actionable). |
| A10 | OAI-F6 | Soften "all other tasks single-pass" in `action-plan.md` Risk-Adjusted Sequencing Notes. Replacement: "M6 has an explicit 2–4 round budget; other tasks are planned as single-pass but may require one corrective pass if probe/integration evidence contradicts assumptions. Adjacent-interface adjustments in OAI-007/011/012 from M6 spillback do not count against the M6 budget." |
| A11 | GEM-F2 | Add `child_process` spawn overhead probe to OAI-024 OR a new M0 task: time 10 sequential `osascript` invocations to estimate per-spawn overhead. If >150ms per spawn, allocate M6 time to investigate a long-lived `osascript` process (interactive `-i` mode) for batch fetch/delete. |
| A12 | GEM-F6 | Extend OAI-024's bail rule with a sub-probe: if listing >5s, before committing to paginated UI in OAI-013, time `items 1 thru 50 of every note`. If pagination is *slower* than full listing (a known AppleScript pathology), shift the contingency to async background load with progress UI rather than pagination. |
| A13 | GEM-F4 | Clarify OAI-012's "progress indicator if scan exceeds 2s" — explicitly use Obsidian's `Notice` API (no custom DOM, no UI dependency). Keep OAI-012 confined to ≤5 files and zero UI cross-cutting. |
| A14 | DS-F7 | Add to OAI-019 acceptance: "Log raw stderr (redacted) on every TCC denial path for diagnostic purposes (helps future macOS-version updates surface drift). Document in README that TCC behavior is tied to macOS version (known limitation)." |
| A15 | GRK-F5 | Add explicit note to M0 phase: "All 4 spikes are independent and may run in parallel. M0 closes when all 4 are resolved per A8 semantics. A single bail does not halt other spikes." |
| A16 | GRK-F2 | Recount the longest dependency chain. Through `OAI-016b → 016c → 016d → 016e` the chain is **13 tasks** (`OAI-001 → 002 → 004 → 006 → 009 → 011 → 016b → 016c → 016d → 016e → 021 → 022 → 023`), not 12. Update `action-plan.md` Overview accordingly. |
| A17 | GRK-F3, GEM-F3 | Clarify M4/M7 parallelism claims. M4 (OAI-012) is genuinely parallel from OAI-002 onward. M7's OAI-019 is parallel from OAI-004 onward, but **OAI-015 serializes** (depends on OAI-019 + OAI-013 + OAI-014). For OAI-013, formalize that the JSON-shape contract from OAI-005/006 is the parallelism boundary — modal can develop with mock data; real-data integration test is the M5 exit gate. |
| A18 | OAI-F14 | Add a brief test-environment readiness checklist before M0/M2 in `action-plan.md` (or in a new pre-flight section): macOS test machine, Notes app signed in + syncing, ability to create/delete test notes, TCC reset/regrant verified, locked-note password set. Avoid environment friction stalling the spike phase. |
| A19 | GRK-F7 | Append "with ACs met per `tasks.md`" to file-existence-only gates (M0 spike artifacts; M1 lint; M8 LICENSE/screenshots). Prevents superficial closure on empty files. |

**Defer (6):**

| ID | Source | Reason |
|---|---|---|
| A20 | OAI-F8 | Critical-path diagram clarity: ASCII diagram is parseable; Mermaid replacement is overkill for plan documentation. Re-evaluate if confusion materializes. |
| A21 | OAI-F15 | A1 >10s decision-space sentence: bail rule says "return to PLAN risk review"; spelling out the decision space pre-emptively is overkill before evidence exists. |
| A22 | OAI-F16 | M8 OAI-021 informal earlier start: dep stays formal; nothing stops the developer from drafting README earlier. |
| A23 | DS-F8 | Zero-note library handling: Obsidian's built-in empty-list rendering is acceptable. Explicit "No notes found" message is nice-to-have. |
| A24 | DS-F10, GRK-F10 | Inline pattern summaries: `_system/docs/solutions/` is the standard reference location; one click away. Inlining duplicates knowledge that lives there for a reason. |
| A25 | GRK-F9 | Explicit E2E smoke test task: M6 3-note batch test + manual pre-submission exercise covers the gap for a single-dev hobby plugin. Full TCC-deny mid-batch E2E is more ceremony than v1 warrants. |

### Considered and Declined

| Finding | Reason | Justification |
|---|---|---|
| GRK-F6 (M6 budget too low; recommend 3–6 rounds) | `incorrect` | Three reviewers (OAI-F5, GEM-F7 STRENGTH, DS-F6 STRENGTH) classify 2–4 rounds as realistic. The 016a/b/c split keeps adversarial-test iteration tight (016b is pure verification, no side effects). Grok's dissent doesn't engage with this structural argument. Position A wins on weight + mechanism. |
| GEM-F5 (eslint version pin partial) | `accepted-as-A7` | The version-pin component is folded into A7 (runtime verification). The "treat 0.04x as flavor" component is folded into A6. |

### Process notes (infra, not plan findings)

The dispatch agent flagged two model-config observations worth noting:

1. **DeepSeek alias drift:** `deepseek-reasoner` now resolves to `deepseek-v4-flash` (system_fingerprint `fp_058df29938_prod0820_fp8_kvcache_20260402`), not the `DeepSeek-V3.2-Thinking` recorded in `peer-review-config.md` from 2026-02-20. Config note should be refreshed.
2. **Google `max_tokens` too tight:** Gemini 3.1 Pro Preview spent 5,597 tokens on internal `thoughts_token_count` and ran out at the configured `maxOutputTokens=8192` on the first attempt (returned `MAX_TOKENS` finish). Retry at 16,384 succeeded. Recommend bumping Google's `max_tokens` in `peer-review-config.md` to 16,384 to absorb the thinking-token budget.

Both observations belong in `_system/docs/peer-review-config.md` updates, not the plan.
