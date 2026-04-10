---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/crumb-tess-bridge/design/action-plan.md + Projects/crumb-tess-bridge/design/tasks.md
artifact_type: action-plan
artifact_hash: f7352cd0
prompt_hash: fbfcb182
base_ref: null
project: crumb-tess-bridge
domain: software
skill_origin: peer-review
created: 2026-02-19
updated: 2026-02-19
reviewers:
  - openai/gpt-5.2
  - google/gemini-2.5-pro
  - perplexity/sonar-reasoning-pro
config_snapshot:
  curl_timeout: 120
  max_tokens: 8192 (openai, google) / 65536 (perplexity)
  retry_max_attempts: 3
safety_gate:
  hard_denylist_triggered: false
  soft_heuristic_triggered: false
  user_override: false
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 52596
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 41611
    attempts: 3
    note: "gemini-3-pro-preview 503'd twice (timeout + 503); fell back to gemini-2.5-pro"
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-action-plan-google.json
  perplexity:
    http_status: 200
    latency_ms: 88290
    attempts: 1
    raw_json: Projects/crumb-tess-bridge/reviews/raw/2026-02-19-crumb-tess-bridge-action-plan-perplexity.json
tags:
  - review
  - peer-review
---

# Peer Review: Crumb–Tess Bridge Action Plan & Task List

**Artifact:** `Projects/crumb-tess-bridge/design/action-plan.md` + `Projects/crumb-tess-bridge/design/tasks.md`
**Mode:** full
**Reviewed:** 2026-02-19
**Reviewers:** GPT-5.2, Gemini 2.5 Pro (fallback from 3 Pro Preview), Sonar Reasoning Pro
**Context provided:** Specification summary, action plan summary, both artifacts in full

---

## OpenAI GPT-5.2

- **[OAI-F1]**
- **[Severity]: CRITICAL**
- **[Finding]: Missing explicit work item for UUIDv7 + idempotency log format + processed-file retention contract**
- **[Why]:** The spec calls out UUIDv7 IDs, `.processed-ids` idempotency, and moving processed files to `.processed/` (not deleting). Some of this appears in CTB-005 acceptance criteria, but there's no schema-level requirement + test that both sides generate/handle IDs consistently, nor a dedicated test that replay/duplicate files behave correctly across restarts. This is a core safety property for "transport-only Tess" and for Phase 2 automation correctness.
- **[Fix]:** Add a small testing task (or expand CTB-007) with explicit replay cases: same `message_id` resent; same file re-dropped; crash after reading before writing outbox; restart + ensure idempotency. Also add schema fields explicitly (e.g., `message_id`, `created_at`, `schema_version`) and unit tests in CTB-004/CTB-005.

- **[OAI-F2]**
- **[Severity]: CRITICAL**
- **[Finding]: No task explicitly implements/validates "operation allowlist" and Phase-bounded permissions**
- **[Why]:** The spec's blast-radius control is the allowlist (Phase 1 approvals + status; Phase 2 adds delegation). The plan implies it ("All Phase 1 operations covered") but doesn't force a concrete allowlist mechanism or test that unknown operations are rejected. Without this, injection risk (BT1/BT6) increases and Phase boundaries become unenforced.
- **[Fix]:** Add acceptance criteria to CTB-003/CTB-005/CTB-004: "reject unknown `operation` with explicit error code," and add tests verifying only the Phase 1 set is accepted in Phase 1 builds.

- **[OAI-F3]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Canonical JSON requirements are under-specified in tasks and cross-language test vectors are incomplete**
- **[Why]:** CTB-003 mentions "passes in Node.js and Python/shell," but the implementation languages need to be explicit. Need deterministic canonicalization and byte-accurate hashing across both ends.
- **[Fix]:** In CTB-003, define canonicalization precisely. Add ≥2 fixed test vectors (including edge characters) and require CTB-004 and CTB-005 to both verify exact bytes before hashing.

- **[OAI-F4]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Two-tier governance verification only addressed in Phase 2, but Phase 1 still needs output schema validation**
- **[Why]:** Even in Phase 1 (human-triggered), response integrity and format validation matter. The plan defers most verification to CTB-012, leaving Phase 1 with weaker guarantees.
- **[Fix]:** Pull "response schema validation" into CTB-005 acceptance criteria.

- **[OAI-F5]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: NLU extraction in CTB-004 shouldn't depend on CTB-003; suggests further split**
- **[Why]:** Risks blocking early prototyping on schema finalization. Spec says Tess is transport only — NLU component needs careful scoping.
- **[Fix]:** Split CTB-004 further into transport parsing vs schema validation.

- **[OAI-F6]**
- **[Severity]: CRITICAL**
- **[Finding]: U7 (session concurrency) not explicitly researched before CTB-011**
- **[Why]:** Spec marks U7 as CRITICAL. CTB-011 includes "pgrep check" but that's a mitigation, not validated research. Concurrency could break sessions or leak context.
- **[Fix]:** Add dedicated research task for U7. Make CTB-011 depend on it.

- **[OAI-F7]**
- **[Severity]: MINOR**
- **[Finding]: M1 success criteria references "U1-U4" but spec has no U4**
- **[Why]:** Factual error creates ambiguity.
- **[Fix]:** Update to correct unknown set.

- **[OAI-F8]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: CTB-001 risk miscalibrated (low → should be medium/high)**
- **[Why]:** `--print` feasibility gates Phase 2 (Model B4 viability). Negative outcome has project-level impact.
- **[Fix]:** Change to medium with explicit go/no-go output.

- **[OAI-F9]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Acceptance criteria not binary enough ("acceptable latency", "go/no-go threshold documented")**
- **[Why]:** Vague criteria hide schedule risk.
- **[Fix]:** Replace with concrete thresholds.

- **[OAI-F10]**
- **[Severity]: CRITICAL**
- **[Finding]: CTB-008 needs Telegram-specific adversarial cases (BT2)**
- **[Why]:** Telegram markdown/codeblock behavior can hide or alter displayed text. CTB-008 doesn't require Telegram-rendering adversarial cases.
- **[Fix]:** Include zero-width chars, RTL/LTR, truncation around hash, codeblock-breaking sequences. Test through actual Telegram rendering.

- **[OAI-F11]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Missing schema versioning + backward compatibility handling**
- **[Why]:** Without version handling, future changes can break automation.
- **[Fix]:** Add to CTB-003: `schema_version` required, reject unknown major versions.

- **[OAI-F12]**
- **[Severity]: MINOR**
- **[Finding]: CTB-006 dependency on CTB-003 is too strict**
- **[Why]:** Directory scaffolding can be done immediately.
- **[Fix]:** Relax dependency.

- **[OAI-F13]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Phase 1 scope drift: CTB-004 says "NLU extraction" but spec says Tess is transport only**
- **[Why]:** Intent interpretation in Tess increases BT6 and undermines governance separation.
- **[Fix]:** Rewrite to "strict command parsing (no NLU)" for Phase 1.

- **[OAI-F14]**
- **[Severity]: STRENGTH**
- **[Finding]: Clear milestones with explicit gates and dedicated injection test suite**

- **[OAI-F15]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: pgrep check race conditions not addressed in CTB-011**
- **[Why]:** Tied to U7. Race between check and process start.
- **[Fix]:** Require flock lockfile as source of truth + stress test.

- **[OAI-F16]**
- **[Severity]: MINOR**
- **[Finding]: CTB-005 could start earlier with stub schema**

- **[OAI-F17]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Phase 2 go/no-go gates incomplete (no explicit U7 resolved, --print viable)**
- **[Fix]:** Add explicit checklist.

- **[OAI-F18]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: BT5 DoS controls should be pulled from Phase 3 to Phase 1**
- **[Fix]:** Tess-side rate limit + max pending inbox files.

---

## Google Gemini 2.5 Pro

- **[GEM-F1]**
- **[Severity]: CRITICAL**
- **[Finding]: Single peer review (M6) scheduled too late — needs design review after M2**
- **[Why]:** Waterfall model where flaws in schema (CTB-003) or protocol mechanics (CTB-004) are only caught after implementation.
- **[Fix]:** Add "Design & Schema Peer Review" after M2. Retain M6 as implementation review.

- **[GEM-F2]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: BT6 (NLU misparse) not adequately addressed — needs NLU ambiguity test suite**
- **[Why]:** CTB-004 mentions "NLU extraction" without testing for ambiguity handling.
- **[Fix]:** Create CTB-016 "NLU Ambiguity Test Suite" — 10+ ambiguous prompts, must clarify or reject.

- **[GEM-F3]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Phase 2 monitoring deferred to Phase 3 — needs liveness check**
- **[Why]:** Silent failure of file watcher with no notification leads to loss of service.
- **[Fix]:** Add CTB-017 "Bridge Health Check" — heartbeat file + external monitor.

- **[GEM-F4]**
- **[Severity]: MINOR**
- **[Finding]: CTB-001 risk miscalibrated (low → should be medium)**
- **[Why]:** Outcome determines Phase 2 viability. Risk should reflect impact, not effort.

- **[GEM-F5]**
- **[Severity]: MINOR**
- **[Finding]: CTB-008 not explicit dependency for CTB-014**
- **[Fix]:** Add CTB-008 to CTB-014 dependencies.

- **[GEM-F6]**
- **[Severity]: MINOR**
- **[Finding]: BT4 transcript poisoning not tested in CTB-008**
- **[Fix]:** Add acceptance criterion: at least one payload attempts transcript poisoning.

- **[GEM-STRENGTH]**
- **[Severity]: STRENGTH**
- **[Finding]: Decomposition quality, acceptance criteria rigor, and validation gates are excellent. CTB-008 "validation gate for daily use" is a model example.

---

## Perplexity Sonar Reasoning Pro

- **[PPLX-F1]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Operation allowlist not designed as an upstream task**
- **[Why]:** Spec emphasizes allowlist as security boundary. No task covers designing allowlist structure or rejection rules.
- **[Fix]:** Add sub-task under M2 for allowlist design with test vectors.

- **[PPLX-F2]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Governance canary protocol not designed before implementation**
- **[Why]:** CTB-012 references canary matching but no upstream task documents what it is or how it's extracted.
- **[Fix]:** Add design task for canary protocol.

- **[PPLX-F3]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Rate-limiting policy not designed upstream**
- **[Why]:** CTB-011 says "configurable max/hour" but no task designs the policy.
- **[Fix]:** Add rate-limiting design task depending on CTB-010.

- **[PPLX-F4]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Threat-to-mitigation mapping not documented**
- **[Why]:** Without explicit mapping, unclear whether all threats are mitigated.
- **[Fix]:** Add threat-mitigation mapping task under M2.

- **[PPLX-F5]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Kill-switch and error-handling protocols not designed**
- **[Why]:** CTB-011 references kill-switch and error classification but no upstream design.
- **[Fix]:** Add operational safety design task.

- **[PPLX-F6]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: UUIDv7 generation not assigned to any task**
- **[Fix]:** Add to CTB-004 acceptance criteria.

- **[PPLX-F7]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: Canonical JSON test vector not formally documented as a deliverable**
- **[Fix]:** Make test vector a first-class committed artifact in CTB-003.

- **[PPLX-F8]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: CTB-001 risk underspecified relative to gatekeeping impact**
- **[Fix]:** Change to medium with explicit go/no-go decision.

- **[PPLX-F9]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: CTB-012 test design could start earlier (parallel with CTB-011)**
- **[Fix]:** Split CTB-012 into design (after CTB-003) and integration (after CTB-011).

- **[PPLX-F10]**
- **[Severity]: SIGNIFICANT**
- **[Finding]: U3 (session lifecycle under automation) conflated with CTB-001**
- **[Why]:** U3 is specifically about automated lifecycle, not just --print basics. CTB-001 might show --print works but leave U3 unanswered.
- **[Fix]:** Add separate research task CTB-001b for U3.

- **[PPLX-F11]**
- **[Severity]: MINOR**
- **[Finding]: Cross-user execution constraint not validated in Phase 2**
- **[Fix]:** Add CTB-011 acceptance criterion confirming no cross-user execution.

- **[PPLX-F12]**
- **[Severity]: MINOR**
- **[Finding]: CTB-010 go/no-go threshold not used as a formal gate**
- **[Fix]:** Clarify whether informational or blocking.

- **[PPLX-F13]**
- **[Severity]: MINOR**
- **[Finding]: CTB-008 → CTB-014 dependency implicit, not explicit**
- **[Fix]:** Add to task table.

- **[PPLX-F14]**
- **[Severity]: MINOR**
- **[Finding]: Operational runbook should be drafted alongside Phase 2**
- **[Fix]:** Add sub-task under M5 for draft runbook.

- **[PPLX-F15]**
- **[Severity]: MINOR**
- **[Finding]: CTB-005 idempotency not explicitly tested**
- **[Fix]:** Add replay test to acceptance criteria.

- **[PPLX-F16]**
- **[Severity]: MINOR**
- **[Finding]: Schema versioning implementation missing from tasks**
- **[Fix]:** Add to CTB-003 acceptance criteria.

- **[PPLX-F17]**
- **[Severity]: MINOR**
- **[Finding]: File permissions for `.processed/` not specified**
- **[Fix]:** Add to CTB-006 acceptance criteria.

- **[PPLX-F18]**
- **[Severity]: MINOR**
- **[Finding]: Telegram code-block rendering validation incomplete**
- **[Fix]:** Expand CTB-002 with code-block-specific test cases.

- **[PPLX-STRENGTH]**
- **[Severity]: STRENGTH**
- **[Finding]: Dependencies are correct and non-redundant. Critical path is sound. Parallel tracks properly identified. Acceptance criteria are specific and testable across most tasks. Go/no-go gates appropriately placed.

---

## Synthesis

### Consensus Findings

Issues flagged by 2+ reviewers — highest signal.

1. **Operation allowlist not explicitly designed/tested** (OAI-F2, PPLX-F1). Both reviewers independently flagged that the spec's primary blast-radius control has no dedicated design or validation task. The plan implies it but doesn't enforce it.

2. **CTB-001 risk miscalibrated** (OAI-F8, GEM-F4, PPLX-F8). 3/3 consensus. Research task is low-effort but its outcome is a critical project gate. Risk should reflect impact, not just execution difficulty.

3. **Canonical JSON test vector underspecified** (OAI-F3, PPLX-F7). Both want the test vector to be a first-class artifact with multiple edge cases, not just a schema doc mention.

4. **Schema versioning missing from tasks** (OAI-F11, PPLX-F16). Spec calls it out; no task owns it.

5. **CTB-008 → CTB-014 dependency missing** (GEM-F5, PPLX-F13). Injection test results are critical input for peer review.

6. **NLU/parsing scope concern** (OAI-F13, GEM-F2). Both worried about "NLU extraction" language in CTB-004 conflicting with spec's "Tess is transport only" principle.

7. **UUIDv7 + idempotency testing not explicit enough** (OAI-F1, PPLX-F6, PPLX-F15). ID generation assigned to no task; replay/idempotency tests missing from acceptance criteria.

### Unique Findings

1. **OAI-F6 — U7 concurrency needs dedicated research task.** Genuine insight. The spec marks U7 as CRITICAL and the plan's mitigation (pgrep in CTB-011) is a workaround, not validated research. The spec itself already specifies flock-based concurrency control with pgrep as advisory — the design exists but the plan doesn't include a task to *validate* it works on the actual system.

2. **OAI-F7 — M1 references "U1-U4" but U4 doesn't exist.** Factual error. Genuine catch.

3. **GEM-F1 — Peer review too late (needs design review after M2).** Interesting but see Considered and Declined.

4. **PPLX-F10 — U3 session lifecycle conflated with CTB-001.** Genuine insight. CTB-001 validates `--print` basics; U3 (repeated automated invocations, state persistence, session collision) is a different unknown that matters for Phase 2.

5. **PPLX-F2 — Governance canary protocol not designed upstream.** The canary is already specified in the spec (last 64 bytes of CLAUDE.md, non-echoable) — this is implementation detail, not design gap. See Considered and Declined.

6. **GEM-F6 — BT4 transcript poisoning in CTB-008.** Small but genuine — injection payloads should test log safety, not just echo display.

### Contradictions

1. **CTB-004 further split.** OAI-F5 suggests splitting CTB-004 again (transport parsing vs schema validation). But CTB-004 was already split once (protocol mechanics vs Telegram UX → CTB-015). A third split would create 3 tasks for one OpenClaw skill file. The NLU concern (OAI-F13) is better addressed by tightening the description language than by splitting further.

2. **Phase 3 items to pull forward.** OAI-F18 wants DoS controls in Phase 1; GEM-F3 wants liveness monitoring in Phase 2; PPLX-F14 wants an operational runbook in Phase 2. Three different reviewers, three different items. The spec rates BT5 (DoS) as LOW and notes confirmation echo is a natural throttle. These are valid operational concerns but risk scope creep if all are adopted.

### Action Items

**Must-fix** — consensus issues or factual errors:

- **A1** (OAI-F2, PPLX-F1): Add operation allowlist acceptance criteria to CTB-003 ("allowlist documented with rejection schema"), CTB-004 ("reject unknown operations with error code"), and CTB-005 ("reject out-of-scope operations; Phase 1 set only").

- **A2** (GEM-F5, PPLX-F13): Add CTB-008 as explicit dependency for CTB-014 in the task table.

- **A3** (OAI-F7): Fix M1 success criteria — replace "U1-U4" with the correct unknown set (U1/U2/U3 for Phase 1; U5/U6/U7 for Phase 2).

- **A4** (OAI-F8, GEM-F4, PPLX-F8): Change CTB-001 risk from `low` to `medium`. Add acceptance criterion: "GO/NO-GO decision documented: proceed with B4 or fallback architecture."

**Should-fix** — significant improvements:

- **A5** (OAI-F3, PPLX-F7): Strengthen CTB-003 — canonical JSON test vector is a first-class committed artifact (`_openclaw/spec/canonical-json-test-vector.json`), ≥2 test vectors including edge cases. Both implementations must pass byte-identical output.

- **A6** (OAI-F11, PPLX-F16): Add to CTB-003 acceptance criteria: "Schema versioning strategy documented. Consumers reject unknown major versions."

- **A7** (OAI-F1, PPLX-F6, PPLX-F15): Add UUIDv7 generation to CTB-004 acceptance criteria. Add replay/idempotency test to CTB-005: "same UUIDv7 sent twice → second rejected with duplicate ID error."

- **A8** (OAI-F13, GEM-F2): Replace "NLU extraction" language in CTB-004 with "strict command parsing into allowlisted operations" for Phase 1. No free-form intent interpretation.

- **A9** (OAI-F10, GEM-F6): Expand CTB-008 — include Telegram-specific adversarial payloads (zero-width chars, RTL/LTR markers, codeblock-breaking sequences) tested through actual Telegram rendering. Add at least one transcript-poisoning payload.

- **A10** (PPLX-F10): Add explicit note to CTB-001 that U3 (session lifecycle under automation) needs validation during Phase 2 research. Either expand CTB-001 scope or add as a CTB-011 prerequisite. Don't create a separate task — this is naturally resolved during file-watcher development (CTB-009/CTB-011).

**Defer:**

- **D1** (OAI-F18, GEM-F3, PPLX-F14): Phase 3 items (DoS controls, liveness monitoring, operational runbook) stay deferred. BT5 is LOW, confirmation echo throttles naturally, and Phase 2 operational complexity is best documented after it's built, not before. Scope creep risk outweighs the benefit at this stage.

- **D2** (OAI-F9): Concrete latency/cost thresholds for CTB-009/CTB-010/CTB-011. Research tasks discover thresholds — they can't be specified before the research runs. The go/no-go decision is human-made based on findings. CTB-010 is intentionally informational.

- **D3** (PPLX-F9): CTB-012 design/implementation split. Test design is lightweight enough to do inline when the runner exists. Splitting adds coordination overhead for minimal time savings.

### Considered and Declined

- **OAI-F5** (split CTB-004 further): `constraint` — CTB-004 was already split into protocol mechanics + Telegram UX. A third split for one OpenClaw skill file adds overhead disproportionate to the benefit. The NLU concern is better addressed by A8 (tightening language).

- **GEM-F1** (design review after M2): `constraint` — The JSON schema is already specified in the peer-reviewed spec with full examples, test vectors, and serialization rules. CTB-003 refines it, not designs from scratch. Adding a review round between M2 and M3 adds a week of latency to the critical path for a schema that's already been through 2 rounds of spec review. M6 covers the full implementation including the schema as-built.

- **PPLX-F2** (canary protocol design task): `overkill` — The canary is fully specified in the spec: "last 64 bytes of CLAUDE.md." The extraction rule, rationale, and security justification are all in BT3's mitigation section. Creating a separate design task for something already designed adds overhead without value.

- **PPLX-F3** (rate-limiting design upstream): `constraint` — Rate limiting depends on CTB-010 token cost data (how expensive are bridge sessions?) and operational experience from Phase 1. Designing the policy before having cost data produces speculative constraints. Better to design during CTB-011 with real numbers.

- **PPLX-F4** (threat-mitigation mapping): `overkill` — The spec already maps each BT1-BT7 threat to its mitigations in the threat model section. A formal matrix is documentation overhead that duplicates the spec.

- **PPLX-F5** (kill-switch design upstream): `overkill` — Kill-switch is a single file check (`~/.crumb/bridge_disabled`). Error classification is straightforward (retryable: timeout/rate-limit; fatal: governance failure/malformed). These are implementation details, not design questions.

- **OAI-F4** (response schema validation in Phase 1): `constraint` — Phase 1 is human-triggered and human-verified. The spec explicitly says "Phase 1 interactive runs emit governance_hash but do not require pre-injected expected hash (the human operator is the verifier)." Automated validation is a Phase 2 concern.

- **OAI-F6** (dedicated U7 research task): `constraint` — The spec already designs the concurrency solution (flock-based lockfile + pgrep advisory). What's needed is *validation* during Phase 2 implementation (CTB-011), not separate research. Adding a standalone task would produce research findings without an implementation to validate against. U7 validation is naturally part of CTB-011 development. However, A10 addresses the related U3 concern.

- **OAI-F12** (relax CTB-006 dependency on CTB-003): `out-of-scope` — Minor optimization. Transcript format depends on schema decisions. The dependency is correct even if the directory creation doesn't strictly need it.

- **OAI-F16** (CTB-005 earlier start with stub): `out-of-scope` — Adds coordination complexity for minimal time savings in a solo-operator project.

- **PPLX-F11** (cross-user execution validation): `out-of-scope` — Covered by existing colocation spec tests (9/9 isolation tests pass). Model B4 eliminates cross-user execution by design.

- **PPLX-F17** (file permissions for .processed/): `out-of-scope` — Covered by existing `_openclaw/` permissions model from colocation spec. The `openclaw` user owns the directory; primary user moves files within it via Crumb.
