---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/crumb-tess-bridge/src/watcher/test_ctb028_e2e_dispatch.py
artifact_type: other
artifact_hash: 4c9211eb
prompt_hash: 8250f1b2
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-22
updated: 2026-02-22
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
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
    latency_ms: 47045
    attempts: 1
    system_fingerprint: null
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-test-ctb028-e2e-dispatch-openai.json
  google:
    http_status: 200
    latency_ms: 50004
    attempts: 1
    model_version: gemini-3-pro-preview
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-test-ctb028-e2e-dispatch-google.json
  deepseek:
    http_status: 200
    latency_ms: 86651
    attempts: 1
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-test-ctb028-e2e-dispatch-deepseek.json
  grok:
    http_status: 200
    latency_ms: 66357
    attempts: 1
    system_fingerprint: fp_7f1776d8be
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-22-test-ctb028-e2e-dispatch-grok.json
tags:
  - review
  - peer-review
  - crumb-tess-bridge
  - ctb-028
status: active
---

# Peer Review: test_ctb028_e2e_dispatch.py

**Artifact:** `Projects/crumb-tess-bridge/src/watcher/test_ctb028_e2e_dispatch.py`
**Mode:** full
**Reviewed:** 2026-02-22
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning
**Review prompt:** Evaluate 40-test CTB-028 E2E dispatch validation suite across 7 dimensions: test coverage, mock fidelity, injection payloads, assertion quality, test isolation, edge cases, correctness.

---

## OpenAI (GPT-5.2)

- **[F1]**
  - **[Severity]: STRENGTH**
  - **[Finding]: The 13-category matrix is well-chosen and maps to real lifecycle risks (completion, handoff, escalation, cancel, budgets, governance, kill-switch, crash recovery + injection classes).**
  - **[Why]: It covers the core "daily use" failure modes and security posture areas for a dispatch orchestrator, and it explicitly encodes several known tricky implementation details (ValueError escalation validation, 1-based indices, audit_hash placement, kill-switch => failed, crash_recovery_scan location).**
  - **[Fix]: None.

- **[F2]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Missing E2E scenarios around stage-runner exception taxonomy (timeouts, crashes, malformed output) even though exceptions are imported (StageTimeout, StageCrash, MalformedOutput).**
  - **[Why]: These are among the most common real-world failures when interacting with an external CLI/model. Without E2E mapping tests, the engine could misclassify errors, mishandle retries, or fail to persist state correctly while tests still pass.**
  - **[Fix]: Add E2E tests where `run_stage` raises:
    - `StageTimeout` → verify error code, state transition, partial deliverables handling, and status file updates.
    - `StageCrash` / `MalformedOutput` → verify response code mapping and that dispatch ends in `failed` with appropriate diagnostics.
    - `StageOutputError` already covered, but add at least one that occurs on stage 2 after stage 1 "next" to ensure partial aggregation + correct halt point.

- **[F3]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: No E2E scenario for `start-task` operation, despite scaffolding tasks.md and parse_operation import.**
  - **[Why]: If `start-task` has different prompt templates, context file rules, or state initialization, `invoke-skill` coverage may not detect regressions specific to task flows (task lookup, task state updates, project pathing).**
  - **[Fix]: Add at least one `start-task` happy-path E2E: request → task resolved from tasks.md → stage(s) → complete; and one failure case (missing task ID, ambiguous task, invalid project path).

- **[F4]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: "Cancel mid-dispatch" test doesn't actually execute a second stage; it injects cancel during stage 1 and relies on engine checking inbox between stages, but only returns stage 1 output and never asserts stage 2 was prevented.**
  - **[Why]: This can become a false-positive if the engine stops after stage 1 for unrelated reasons, or if it never schedules stage 2 due to a bug.**
  - **[Fix]: Make `run_stage` side_effect return stage1 (`next`) then *raise if called again*, and assert it is not called again after cancel is planted. Example: side_effect list `[stage1, AssertionError("stage2 should not run")]`, and verify call_count==1.

- **[F5]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Budget stage-limit test does not assert stage 3 is not executed; it only checks final response code.**
  - **[Why]: A bug could run stage 3 anyway (wasting budget / side effects) yet still produce `BUDGET_EXCEEDED` afterward, and the test would pass.**
  - **[Fix]: Capture the `run_stage` mock and assert `call_count == 2` for `max_stages: 2`, and/or assert the last `stage_number` invoked is 2.

- **[F6]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: "handoff exactly at limit passes" does not actually create a handoff at 8192 bytes; it uses `{"note": "small"}`.**
  - **[Why]: This is a boundary test that currently doesn't test the boundary; it can pass even if the handoff limit logic is wrong.**
  - **[Fix]: Construct a handoff payload whose UTF-8 byte length is exactly `MAX_HANDOFF_BYTES` when serialized in the same way production measures it (e.g., JSON). Example: generate a string of length N, verify `len(json.dumps(handoff).encode("utf-8")) == MAX_HANDOFF_BYTES`, then run.

- **[F7]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Path traversal / sensitive path injection tests are largely "engine maps StageOutputError → STAGE_FAILED", but they do not verify the engine's *own* path validation because the validation is simulated by raising `StageOutputError` from the mock.**
  - **[Why]: If path validation belongs to StageRunner (as implied), these are fine as mapping tests; but if any validation is performed in DispatchEngine, these tests won't catch regressions. Even if StageRunner owns it, you may want one end-to-end test that uses real StageRunner validation (or a unit test for StageRunner).**
  - **[Fix]: Clarify ownership:
    - If StageRunner validates: keep one mapping test here, move the payload matrix to `test_stage_runner.py` where `verify_policy()` is truly exercised.
    - If DispatchEngine validates: don't raise `StageOutputError`; instead return a stage_output containing traversal paths and assert the engine rejects it via real validation.

- **[F8]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Governance failure tests explicitly note alert writing is bypassed when mocking at `run_stage` level; CTB-028 therefore does not validate the "halt with alert" claim in its header for governance failures.**
  - **[Why]: This suite is described as a Phase 2 validation gate. If alerts are a core operational requirement, the absence of an E2E check here can allow regressions in alert emission (path, schema, content) while tests remain green.**
  - **[Fix]: Add one integration-style test that does *not* mock at `run_stage` but instead mocks deeper (e.g., subprocess/CLI) so `StageRunner.verify_governance()` runs and produces an alert file; or add a focused test that calls the alert-writing function directly with realistic inputs and asserts an alert JSON exists with required fields.

- **[F9]**
  - **[Severity]: MINOR**
  - **[Finding]: `stage_2_bad_gov` is created but unused in `test_governance_failure_at_stage_2_halts`.**
  - **[Why]: Minor dead code increases confusion about what is being tested (returning a bad governance_check vs raising GovernanceFailure).**
  - **[Fix]: Remove `stage_2_bad_gov` or change the test to return it and let real validation raise (if feasible).

- **[F10]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Injection "oversized instructions rejected" and "non-ascii instructions rejected" also simulate StageRunner policy enforcement by directly raising `StageOutputError`.**
  - **[Why]: These become mapping tests rather than security tests. If policy enforcement breaks (e.g., MAX length changes or ASCII check removed) but StageRunner no longer raises, these tests won't detect it.**
  - **[Fix]: Similar to F7: either (a) move these payload validation tests to StageRunner test suite, or (b) drive the engine with a returned stage_output containing bad instructions and assert the engine rejects it via real validation if that validation lives in-engine.

- **[F11]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Fabricated governance injection tests likewise only test error mapping by having `run_stage` raise `GovernanceFailure`, rather than verifying that a returned stage_output with tampered governance_check is detected.**
  - **[Why]: If the governance verification is part of StageRunner (likely), then the right place to test tampered governance_check detection is StageRunner. CTB-028 as E2E at the engine level should ideally include at least one non-simulated governance verification path, or else it's not actually validating the security control.**
  - **[Fix]: Add one test path that lets StageRunner run governance verification (mock subprocess output but keep verify_governance real), returning a stage_output with wrong hash/canary and asserting failure + alert.

- **[F12]**
  - **[Severity]: STRENGTH**
  - **[Finding]: Escalation regex/validation tests correctly assert `_validate_escalation()` raises `ValueError` (not a boolean return), and include a realistic malicious option corpus (backticks, slashes, backslash, unicode, zero-width, HTML, oversize).**
  - **[Why]: This aligns with the stated implementation detail and covers common prompt-injection carriers and obfuscation characters.**
  - **[Fix]: None.

- **[F13]**
  - **[Severity]: MINOR**
  - **[Finding]: Escalation resume test asserts `"TRUSTED"` appears in the resume prompt, but does not assert that user-provided answers are placed in TRUSTED while model-provided content remains UNTRUSTED (i.e., the key safety invariant).**
  - **[Why]: A prompt templating regression could include the word "TRUSTED" while misplacing content boundaries, and the test would still pass.**
  - **[Fix]: Assert structure more specifically: e.g., check that the resolved answer text appears *after* a "TRUSTED INPUT" header and that the original escalation/context appears under "UNTRUSTED". Use substring order assertions or regex with sections.

- **[F14]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: `audit_hash` presence is checked, but not its correctness/stability or whether it changes when stage outputs change.**
  - **[Why]: If audit_hash is meant to be tamper-evident, merely checking existence won't catch it being constant/empty/incorrectly computed.**
  - **[Fix]: In at least one test, recompute expected audit hash from the same inputs the engine uses (or mock deterministic components) and assert equality; or assert that changing deliverables/stage summaries changes audit_hash.

- **[F15]**
  - **[Severity]: MINOR**
  - **[Finding]: Test isolation is generally good (fresh temp dirs per test), but `_has_active_dispatch` is patched in many tests; no test covers the behavior when an active dispatch exists (concurrency gate).**
  - **[Why]: Concurrency/serialization bugs can cause duplicate execution, state corruption, or lost inbox items in real daily use.**
  - **[Fix]: Add an E2E test where `_has_active_dispatch` returns True and assert the engine defers/does not process the request, and that the request file remains in inbox (or is handled per spec).

- **[F16]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Crash recovery tests cover queued/running/blocked/terminal, but do not cover corrupted/partial state files (truncated JSON, missing keys, unknown lifecycle_state).**
  - **[Why]: After real crashes, partial writes are common. If `crash_recovery_scan()` crashes on bad JSON, the whole recovery process can fail and leave dispatches stuck.**
  - **[Fix]: Add tests with:
    - invalid JSON file in dispatch_dir
    - state missing `lifecycle_state`
    - unknown lifecycle_state string
    Ensure scan returns a result indicating skip/fail-safe behavior and does not raise.

- **[F17]**
  - **[Severity]: MINOR**
  - **[Finding]: Some assertions are broad (e.g., `self.assertGreater(len(deliverables), 0)` for cancel/budget) without verifying the *exact* deliverables preserved.**
  - **[Why]: Weak assertions can allow regressions where the wrong deliverables are reported (duplicates, wrong stage, wrong paths).**
  - **[Fix]: Assert exact paths and counts (e.g., cancel case should include `docs/partial.md` and not include later-stage artifacts).

- **[F18]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: No tests exercise race-like conditions around file moves and processed-id recording (e.g., processed-ids file already contains ID, `.processed` missing, outbox write failures).**
  - **[Why]: Daily use often encounters filesystem edge cases; failures here can cause reprocessing loops or lost responses.**
  - **[Fix]: Add tests that pre-create `.processed` dir absent/present, pre-populate processed IDs, and simulate IO errors (patch `open`/`Path.write_text`) to verify fail-safe behavior and state remains consistent.

- **[F19]**
  - **[Severity]: STRENGTH**
  - **[Finding]: The suite validates several key response contract details (response/status files written, request moved to `.processed`, state transitions, transcript_paths length, dispatch stages_executed, budget aggregation).**
  - **[Why]: These are the core interoperability points for a bridge; catching contract drift is high value.**
  - **[Fix]: None.

- **[F20]**
  - **[Severity]: SIGNIFICANT**
  - **[Finding]: Several "injection" categories are currently more like "exception mapping" tests because the mock raises the final exception class rather than letting the pipeline detect the malicious payload.**
  - **[Why]: This can create a false sense of security: the engine will correctly map `StageOutputError` to `STAGE_FAILED`, but the defenses that *produce* `StageOutputError` might be broken and CTB-028 would still pass.**
  - **[Fix]: Rebalance:
    - Keep a small number of mapping tests (one per exception class).
    - Move payload validation matrices to the component that implements them (StageRunner/policy validator).
    - Add 1–2 "thin integration" tests that keep `DispatchEngine` + real validators and mock only the lowest-level model execution, so the malicious payload is actually parsed and rejected by real code paths.

---

## Google Gemini (gemini-3-pro-preview)

[F1] [SIGNIFICANT] [Mock Fidelity/Correctness]
**Finding:** Injection tests for Path Traversal, Oversized Handoff, and Malicious Instructions verify error handling, not injection detection.
**Why:** The prompt states that "Simulated stage outputs flow through real schema validation, policy validation." However, tests like `test_traversal_payloads_all_rejected`, `test_handoff_over_8kb_rejected`, and `test_oversized_instructions_rejected` use `side_effect=StageOutputError(...)` on the mock. This forces the mock to raise an exception immediately, effectively **bypassing** the Engine's downstream validation logic that is supposed to inspect the output. These tests verify "The Engine handles a `StageOutputError` correctly" but fail to verify "The Engine detects a path traversal/oversized payload."
**Fix:** Modify these tests to have the mock return a standard `stage_output` dictionary containing the malicious payload (e.g., `context_files=["../../etc/passwd"]`). This allows the Engine to process the output, trigger its internal policy validators, and raise the error naturally.

[F2] [MINOR] [Coverage/Edge Cases]
**Finding:** Budget testing is incomplete regarding token usage.
**Why:** `TestE2E_BudgetExceeded` covers `max_stages` and `max_wall_time_seconds`. However, LLM budgets often rely critically on `max_tokens` or `max_tool_calls` to prevent runaway costs. If the budget logic handles these keys identically to the others, the risk is low, but explicit verification is safer for financial guardrails.
**Fix:** Add a test case to `TestE2E_BudgetExceeded` where `metrics` in the stage output report token usage that cumulatively exceeds a `max_tokens` budget.

[F3] [STRENGTH] [Test Coverage]
**Finding:** Crash Recovery and Escalation Round-trip tests are implemented with high fidelity.
**Why:** `TestE2E_CrashRecovery` manually constructs dirty state files (running, queued, blocked) to verify the scanner's logic without relying on the runtime engine to produce them. This ensures the recovery logic works even if the engine crashed in an inconsistent state. Similarly, `TestE2E_EscalationRoundTrip` correctly validates the 1-based indexing and the specific state transitions required for human-in-the-loop interactions.

[F4] [MINOR] [Assertion Quality]
**Finding:** Injection tests for prompt overrides rely on checking mock input arguments.
**Why:** In `test_prompt_override_in_instructions`, the assertion checks `mock_run.call_args` to verify the presence of "UNTRUSTED". While this confirms the Engine is constructing the prompt arguments correctly before calling the runner, it technically asserts on the input to a mock rather than a tangible system output.
**Fix:** This is acceptable given the architecture (mocking the runner), but confidence would be higher if the test also asserted that the final `transcript_path` (if written by the engine) or the `audit_hash` reflected this structure.

[F5] [STRENGTH] [Test Isolation]
**Finding:** Clean separation of concerns in Governance testing.
**Why:** The suite correctly distinguishes between the *Stage Runner's* responsibility (detecting the hash mismatch) and the *Engine's* responsibility (halting the dispatch). By mocking `GovernanceFailure` in `TestE2E_GovernanceFailure`, the test correctly focuses on the Engine's state transition logic (moving to `failed` and alerting) rather than reimplementing the hash verification logic inside the integration test.

[F6] [MINOR] [Mock Fidelity]
**Finding:** `test_malicious_escalation_does_not_reach_blocked_state` assumes post-return validation.
**Why:** This test mocks `run_stage` returning a blocked status with a bad escalation, expecting the Engine to catch it. This contrasts with finding [F1] because it *does* return data. This is a good test *if and only if* the architecture validates escalation objects *after* the stage returns. If validation happens *inside* `run_stage`, this test is a false positive. Given the prompt's assertion about "real schema validation," this test is likely correct, but highlights the inconsistency in approach compared to the Path Traversal tests.
**Fix:** Ensure the implementation of `TestInjection_PathTraversal` aligns with the approach used here (returning data, not raising side-effects).

---

## DeepSeek (V3.2-Thinking via deepseek-reasoner)

- [F1]
- [Severity]: MINOR
- [Finding]: Missing test coverage for operation type "start-task"
- [Why]: The test suite extensively tests "invoke-skill" but doesn't validate the "start-task" operation path through the engine. The base setup creates tasks.md but no test exercises start-task dispatch logic.
- [Fix]: Add a dedicated test class for start-task operation that verifies task parsing, stage generation, and task state updates.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: Mock fidelity issue in injection tests - they test mock behavior instead of real validation
- [Why]: Tests like `test_traversal_payloads_all_rejected` mock `run_stage` to raise StageOutputError with specific messages, but this tests the mock configuration rather than the actual path traversal validation logic in StageRunner.
- [Fix]: Instead of mocking StageOutputError, mock at a lower level (e.g., patch `stage_runner.verify_policy`) or use real stage outputs with malicious paths and assert GovernanceFailure/StageOutputError occurs.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: Missing test for malformed JSON in stage output
- [Why]: Injection category focuses on malicious content but not on structural attacks like invalid JSON, missing required fields, or type mismatches that could cause parsing errors.
- [Fix]: Add tests where mocked `run_stage` returns invalid JSON or schema-violating outputs, verifying MalformedOutput exception handling.

- [F4]
- [Severity]: MINOR
- [Finding]: Weak assertion in `test_handoff_passed_to_subsequent_stages`
- [Why]: The test checks for substring "value_from_stage_1" in the prompt but doesn't verify the handoff is properly JSON-serialized and placed in the correct prompt section.
- [Fix]: Assert the handoff appears as properly formatted JSON within the expected "HANDOFF" section of the prompt.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Shared state risk in `_create_blocked_dispatch` helper
- [Why]: The helper patches `_has_active_dispatch` internally but doesn't clean up the patch, potentially affecting subsequent tests if they don't re-patch.
- [Fix]: Move the patching responsibility to test methods instead of the helper, or ensure helper cleans up patches with `stop()`.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Missing race condition tests
- [Why]: No tests for concurrent operations like simultaneous escalation-response and cancel, or multiple requests for same dispatch.
- [Fix]: Add tests using threading or mocked time sequences to verify proper locking and state transitions under concurrent access.

- [F7]
- [Severity]: MINOR
- [Finding]: Missing boundary condition for 0-stage dispatches
- [Why]: What happens if a stage immediately fails? No test for immediate stage failure or empty dispatch.
- [Fix]: Add test where first stage returns "failed" status, verifying proper error response and cleanup.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: False-positive possibility in `test_escalation_timeout_transitions_to_failed`
- [Why]: The test manually edits the state file but doesn't verify the engine's actual timeout-checking logic; could pass even if timeout checking is broken.
- [Fix]: Test timeout through the actual `check_escalation_timeouts` method with properly aged timestamps in the state.

- [F9]
- [Severity]: MINOR
- [Finding]: Missing injection vector: malicious metrics data
- [Why]: Metrics field could contain oversized values or special characters that might affect aggregation or logging.
- [Fix]: Add tests with extreme metric values (negative tokens, huge numbers) to verify proper validation/sanitization.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Kill-switch test doesn't verify proper state transition
- [Why]: In `test_kill_switch_before_escalation_resume`, the assertion checks state becomes "failed" but kill-switch handling should transition to "failed" (not "canceled"). Need to verify correct error code.
- [Fix]: Also assert the final response contains KILL_SWITCH error code, not just state change.

- [F11]
- [Severity]: MINOR
- [Finding]: Missing test for transcript file creation/validation
- [Why]: Tests verify transcript_paths in response but don't check that transcript files are actually created with proper content.
- [Fix]: Add assertions that verify transcript files exist and contain expected stage summaries.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Budget test uses mocked time calculation
- [Why]: `test_wall_time_exceeded` patches `_compute_elapsed_wall_time` instead of testing real wall time tracking; could pass even if real time tracking is broken.
- [Fix]: Use real time tracking with mocked system time (e.g., `time.monotonic`) instead of mocking the calculation method.

- [F13]
- [Severity]: MINOR
- [Finding]: Missing cleanup verification for failed dispatches
- [Why]: Tests verify cleanup for successful dispatches but not for failed/canceled ones.
- [Fix]: Add assertions that verify request files are cleaned up and state files are properly archived even on failure paths.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: Escalation answer validation tests incomplete
- [Why]: Tests verify option text validation but don't test invalid answer types (non-integer, out-of-range) or malformed answer structures.
- [Fix]: Add tests for escalation response with string answers, negative indices, missing question IDs, and duplicate answers.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
  [Severity]: SIGNIFICANT
  [Finding]: No tests for handling StageTimeout, StageCrash, MalformedOutput, or StageOutputError (beyond injections) propagating through the dispatch loop (e.g., retries, max retries exceeded, partial deliverables on crash). Injection tests mock these exceptions early, but no E2E where a stage raises them mid-multi-stage.
  [Why]: These are core stage failure modes; dispatch orchestration might mishandle retries, budget consumption on retry, or state transitions (e.g., to "failed" with partials), leading to undetected bugs in daily use (Phase 2 validation gate). False positives if loop silently drops exceptions.
  [Fix]: Add category "Stage failures": mock run_stage raising StageTimeout/StageCrash mid-3stage flow, assert "error" status (e.g., "STAGE_TIMEOUT_EXCEEDED" or "STAGE_CRASHED"), stages_executed partial, deliverables from prior stages.

- [F2]
  [Severity]: SIGNIFICANT
  [Finding]: Budget exceeded tests (stage_limit_exceeded, wall_time_exceeded) assert only status=="error" and code=="BUDGET_EXCEEDED"; no checks for partial deliverables, stages_executed==budget limit, or budget_used reflecting consumed (e.g., stages:2).
  [Why]: Tests pass if budget check fails but response omits partials/state updates (false positive). Misses bugs in aggregation/preservation logic, critical for "partial deliverables" promise.
  [Fix]: Add asserts: self.assertEqual(response["dispatch"]["stages_executed"], 2); self.assertEqual(len(response["details"]["deliverables"]), 2); self.assertEqual(response["dispatch"]["budget_used"]["stages"], 2).

- [F3]
  [Severity]: SIGNIFICANT
  [Finding]: Cancel/kill-switch tests (e.g., test_cancel_at_stage_boundary_preserves_deliverables, kill_switch_between_stages) assert error code but weak/no checks on ds.state=="canceled"/"failed", partial deliverables paths/content, or stages_executed. Kill-switch key detail ("transitions to failed not canceled") asserted only in one resume test.
  [Why]: False positives if state not updated or partials dropped; violates "partial deliverables" for user-triggered halts. Key implementation detail unverified comprehensively.
  [Fix]: Add ds = DispatchState.load(...); self.assertEqual(ds.state, "canceled"); self.assertEqual(response["dispatch"]["stages_executed"], 1); assert specific deliv path.

- [F4]
  [Severity]: SIGNIFICANT
  [Finding]: No budget exceed tests for tool_calls, tokens_input/output, or wall_time_ms aggregation despite 3stage test asserting sums and budget fields present. Only max_stages/wall_time_seconds tested.
  [Why]: Budget likely aggregates these (per metrics); bugs in summing/checks undetected, especially token-heavy workloads. Incomplete for "budget exceeded → partial" category.
  [Fix]: Add tests mocking stage_outputs with high tool_calls/tokens exceeding request budget={"max_tool_calls":10}, assert BUDGET_EXCEEDED after exceed, partials preserved.

- [F5]
  [Severity]: SIGNIFICANT
  [Finding]: No tests for invalid escalation answers (e.g., index=0, index=3 for 2 options, missing key, non-int). _resolve_escalation_answers(1-based) likely errors, but handle_escalation_response behavior untested (stay blocked? failed?).
  [Why]: Escalation round-trip core; invalid answers could leave blocked forever or corrupt state. False positive if error swallowed. Key detail (1-based) tested only for valid.
  [Fix]: In TestE2E_EscalationRoundTrip, add test_bad_answer_index: mock answers={"q1":0/3}, assert ds.state=="blocked" or error response "INVALID_ESCALATION_ANSWER", prompt not resumed.

- [F6]
  [Severity]: MINOR
  [Finding]: No tests for malformed requests/escalation-responses (bad schema_version, missing fields, invalid operation/params). parse_operation/_write_request_file assume valid.
  [Why]: Bridge entrypoint; malformed could crash engine or bypass validation. Gaps in "validation gate".
  [Fix]: Add tests with bad_request = {... "schema_version":"999"}, assert run_dispatch/handle_* returns False, error response or log, request to .processed anyway.

- [F7]
  [Severity]: MINOR
  [Finding]: Weak/tautological assertions: assertGreater(len(deliverables),0) in cancels (could be empty); assertIsNotNone(status) before equal; assertIn("audit_hash") without non-empty/checksum logic.
  [Why]: Low specificity; passes on weak impl (e.g., empty list). Reduces confidence in exact behavior.
  [Fix]: Change to assertEqual(len(deliverables),1); assertTrue(response["audit_hash"]); compute expected hash from response content and assertEqual.

- [F8]
  [Severity]: MINOR
  [Finding]: No concurrent dispatch or active dispatch tests; all patch _has_active_dispatch=False. No races (cancel during stage, multi-worker).
  [Why]: Real use has polling loop; races in state locking/inbox scanning undetected. Mock fidelity claims "orchestration exercised" but skips concurrency gate.
  [Fix]: Add test with two requests, mock _has_active=True for second, assert queued or rejected.

- [F9]
  [Severity]: MINOR
  [Finding]: All E2E use "invoke-skill"; no "start-task" despite tasks.md setup in setUp. parse_operation unexercised fully.
  [Why]: Different ops might branch logic (e.g., project init); incomplete coverage.
  [Fix]: Convert one single/multi-stage to "start-task" params={"task_id":"T-001"}, assert same flows.

- [F10]
  [Severity]: MINOR
  [Finding]: test_handoff_exactly_at_limit_passes uses small handoff={"note":"small"} despite comment "exactly 8192 bytes"; doesn't test boundary pass.
  [Why]: False confidence in boundary; if <=MAX_HANDOFF_BYTES inclusive buggy, undetected.
  [Fix]: handoff={"data": "x"*8192}, assert passes; separate >8192 mocks exception.

- [F11]
  [Severity]: MINOR
  [Finding]: test_escalation_wrong_id_leaves_dispatch_blocked calls handle_escalation_response but asserts only ds.state=="blocked"; no response/alert check. Similar for timeout.
  [Why]: Might write wrong error code or none; partial verification.
  [Fix]: Add response = self._read_response(dispatch_id); self.assertEqual(response["status"],"error"); self.assertEqual(response["error"]["code"],"INVALID_ESCALATION_ID").

- [F12]
  [Severity]: MINOR
  [Finding]: Escalation tests single-choice/single-answer only; no multi-questions, multi-answer dicts, other types (text?), max questions limit.
  [Why]: _validate_escalation/_resolve_answers might fail on complex; realistic escalations have multiples.
  [Fix]: Add test with 2 questions, answers={"q1":1,"q2":2}, assert resume prompt has both resolved.

- [S1]
  [Severity]: STRENGTH
  [Finding]: Per-test tmpdir isolation (setUp mkdtemp, tearDown rmtree) with all paths (dispatch/outbox/inbox) under tmp prevents state leaks; unique dispatch_ids per test.
  [Why]: Ensures independence; crash_recovery direct file writes don't pollute. Verified: no shared globals, fresh engine/DispatchState each test.

- [S2]
  [Severity]: STRENGTH
  [Finding]: Mock fidelity high: run_stage side_effects exercise real post-output validation/orchestration (e.g., _validate_escalation raises checked); call_args inspection verifies prompt/handoff framing (UNTRUSTED).
  [Why]: Tests engine logic, not just mocks; prompt inj flows to next stage correctly framed. Edge: malicious in untrusted verified.

- [S3]
  [Severity]: STRENGTH
  [Finding]: Injection payloads realistic/comprehensive (prompt override, ../ paths, sensitive, oversized exact-ish, esc regex vectors incl. zero-width/HTML/oversize); direct _validate_escalation + E2E flow.
  [Why]: Covers key vectors; regex rejects verified via ValueError. No false pos as dispatch catches pre-blocked.

- [S4]
  [Severity]: STRENGTH
  [Finding]: Crash recovery tests comprehensive: running/queued→failed_runner_restart, blocked remains, terminals skipped; direct func call, manual states cover non-terminal. Matches key detail.
  [Why]: Standalone func critical for restarts; verified state mutations precise.

---

## Synthesis

### Consensus Findings

**1. Mock fidelity of injection tests — exception simulation vs real validation (4/4)**
OAI-F7, OAI-F10, OAI-F11, OAI-F20, GEM-F1, DS-F2, GRK-S2 (partial contradiction — see below)

Injection categories 10 (path traversal), 11 (oversized handoff), and 13 (fabricated governance) mock `StageOutputError`/`GovernanceFailure` directly from `run_stage`, testing engine error mapping rather than actual detection. All 4 reviewers flagged this; Gemini called it the test suite's single biggest issue. The fix recommended by all is to either return malicious payloads and let real validation catch them, or move payload matrices to `test_stage_runner.py`.

**2. Missing StageTimeout/StageCrash E2E tests (3/4: OAI, DS, GRK)**
OAI-F2, DS-F3 (partially), GRK-F1

The imported exceptions `StageTimeout`, `StageCrash`, `MalformedOutput` are never exercised in E2E tests. Engine error mapping for these failure modes is untested, especially mid-multi-stage where partial deliverables matter.

**3. Missing `start-task` operation E2E (3/4: OAI, DS, GRK)**
OAI-F3, DS-F1, GRK-F9

`tasks.md` is scaffolded in `setUp` but no test uses `start-task`. If `start-task` has different prompt construction or state initialization, regressions won't be caught.

**4. Weak assertions on budget/cancel/kill-switch partial deliverables (3/4: OAI, GRK, DS indirectly)**
OAI-F4, OAI-F5, OAI-F17, GRK-F2, GRK-F3, GRK-F7

Budget tests assert error code but not `stages_executed`, `budget_used`, or specific deliverable paths. Cancel test doesn't verify stage 2 was prevented. Kill-switch tests don't comprehensively verify state transitions.

**5. Handoff boundary test doesn't test the boundary (2/4: OAI, GRK)**
OAI-F6, GRK-F10

The "exactly at limit" test uses `{"note": "small"}` — nowhere near 8KB.

**6. Missing invalid escalation answer tests (2/4: DS, GRK)**
DS-F14, GRK-F5

No tests for out-of-range index (0, 3 for 2 options), missing question IDs, non-integer answers.

**7. Missing concurrent/active dispatch test (2/4: OAI, GRK)**
OAI-F15, GRK-F8

All tests patch `_has_active_dispatch=False`; no test for the concurrency gate behavior.

**8. Missing corrupted state file crash recovery (2/4: OAI, DS)**
OAI-F16, DS-F3

No tests for truncated JSON, missing keys, or unknown lifecycle_state values in crash recovery.

**9. audit_hash existence-only check (2/4: OAI, GRK)**
OAI-F14, GRK-F7

`audit_hash` is checked for presence but never for correctness or sensitivity to input changes.

### Unique Findings

- **OAI-F8**: Governance alert emission not validated E2E — CTB-028 header says "halt with alert" but alert writing is bypassed by mocking at `run_stage`. **Genuine insight** but alert writing is in StageRunner, tested in test_stage_runner.py. The header is misleading.
- **OAI-F9**: Unused `stage_2_bad_gov` variable — genuine dead code, easy fix.
- **OAI-F13**: TRUSTED/UNTRUSTED prompt section ordering — valid nuance. Current assertion checks keyword presence but not content placement order.
- **GEM-F6**: `test_malicious_escalation_does_not_reach_blocked_state` correctly tests post-return validation vs. the inconsistent approach in path traversal tests — good architectural observation.
- **DS-F7**: Missing 0-stage dispatch (immediate stage failure) — valid edge case.
- **DS-F10**: Kill-switch resume test should verify error code in response, not just state — valid, specific fix.
- **GRK-F6**: Missing malformed request tests — valid gap for a validation gate.
- **GRK-F11**: Escalation wrong_id test doesn't check response — valid, easy fix.
- **GRK-F12**: Single-question escalation only — valid coverage gap, lower priority.

### Contradictions

**Mock fidelity assessment:**
- GRK-S2 rates mock fidelity as a STRENGTH ("Tests engine logic, not just mocks; prompt inj flows to next stage correctly framed")
- OAI-F7/F20 and GEM-F1 rate mock fidelity for injection tests as a SIGNIFICANT weakness

Both are partially correct. For **post-output validation** (escalation regex, prompt override framing), mock fidelity IS high — `_validate_escalation` raises on real data. For **pre-output validation** (path traversal, instructions length, governance hash), the mock bypasses real validation entirely. The contradiction reflects which tests each reviewer weighted most.

**DS-F8 vs reality:**
DeepSeek claims `test_escalation_timeout_transitions_to_failed` is a potential false positive. This is incorrect — the test calls real `check_escalation_timeouts()` on the real engine, which reads the backdated state file and transitions the dispatch. The assertion is on real state, not mock behavior.

### Action Items

**Must-fix:**

- **A1** [OAI-F2, GRK-F1, DS-F3]: Add StageTimeout/StageCrash E2E tests — mock `run_stage` raising these mid-multi-stage, verify error code, state transition to `failed`, partial deliverables from prior stages, and `stages_executed` count.

- **A2** [OAI-F4, OAI-F5, GRK-F2, GRK-F3, OAI-F17, GRK-F7]: Strengthen assertions on budget/cancel/kill-switch tests — add `stages_executed`, `call_count`, specific deliverable path assertions. For cancel test, verify stage 2 mock was not called. For budget, verify `budget_used` fields.

**Should-fix:**

- **A3** [OAI-F3, DS-F1, GRK-F9]: Add one `start-task` E2E happy-path test.

- **A4** [DS-F14, GRK-F5]: Add invalid escalation answer tests — out-of-range index (0, 3), non-integer, missing question ID.

- **A5** [OAI-F6, GRK-F10]: Fix handoff boundary test to construct a payload at exactly `MAX_HANDOFF_BYTES`.

- **A6** [OAI-F15, GRK-F8]: Add active dispatch concurrency gate test — `_has_active_dispatch=True` → request deferred.

- **A7** [OAI-F14, GRK-F7]: Validate `audit_hash` is non-empty and changes when deliverables differ (two tests with different outputs → different hashes).

- **A8** [OAI-F16, DS-F3]: Add corrupted state file crash recovery tests — invalid JSON, missing `lifecycle_state`, unknown state string.

- **A9** [OAI-F9]: Remove unused `stage_2_bad_gov` variable.

- **A10** [DS-F10, GRK-F11]: Add response file assertions to escalation wrong_id and kill-switch resume tests.

- **A11** [DS-F7]: Add immediate stage failure test (first stage returns `status: "failed"`).

**Defer:**

- **A12** [OAI-F7, OAI-F10, OAI-F11, OAI-F20, GEM-F1, DS-F2]: Mock fidelity of injection categories 10/11/13 — these correctly test engine error mapping; policy validation belongs in test_stage_runner.py. Update module docstring to clarify which categories test real validation vs. error mapping. Not restructuring tests now.

- **A13** [OAI-F8, OAI-F11]: Governance alert E2E and "thin integration" tests — would require subprocess-level mocking for marginal gain. Alert verification is covered in test_stage_runner.py.

- **A14** [DS-F6, GRK-F8 race conditions, OAI-F18]: Race condition / filesystem edge case tests — dispatch engine uses single-threaded processing in the watcher polling loop. File-level locking is tested elsewhere. Over-engineering for current architecture.

- **A15** [GEM-F2, GRK-F4]: Token/tool_call budget tests — budget enforcement currently only supports `max_stages` and `max_wall_time_seconds`. Token budgets not yet implemented.

- **A16** [GRK-F12]: Multi-question escalation test — valid gap but lower priority; single-question covers the core validation path.

### Considered and Declined

- **DS-F5** (`_create_blocked_dispatch` shared state risk): **incorrect** — the helper uses `with patch.object(...)` context managers which automatically clean up on `__exit__`.
- **DS-F8** (escalation timeout false positive): **incorrect** — the test calls real `check_escalation_timeouts()` on the real engine with backdated timestamps. The assertion verifies real state transitions.
- **DS-F12** (budget wall-time mocking `_compute_elapsed_wall_time`): **constraint** — mocking the time calculator is appropriate for deterministic testing. Using real `time.monotonic` with freezegun or similar would add a dependency for marginal gain.
- **GEM-F4** (prompt override assertion on mock input): **constraint** — this is the correct assertion level given the run_stage mock boundary. Transcript files aren't written by the engine.
- **DS-F9** (malicious metrics): **overkill** — metrics are numeric fields validated by schema; extreme values don't compromise security.
- **OAI-F13** (TRUSTED/UNTRUSTED section ordering): **overkill** — current assertion confirms keyword presence alongside resolved answers. Section-level ordering assertions would couple tests to prompt template formatting.

### Grok Calibration Note

Grok 4.1 Fast produced 12 issues and 4 strengths (75% issues, 25% strengths). This exceeds the prompt_addendum target of 67% issues. The findings were consistently relevant with no hallucinated claims — all strengths were verified against the artifact. Improvement from first review (53% issues) confirmed. Addendum working as intended.
