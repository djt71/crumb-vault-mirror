---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/researcher-skill/design/action-plan.md
artifact_type: architecture
artifact_hash: 0a40efc9
prompt_hash: 4c200e28
base_ref: null
project: researcher-skill
domain: software
skill_origin: peer-review
created: 2026-02-27
updated: 2026-02-27
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
  soft_heuristic_triggered: false
  user_override: false
  warnings: []
reviewer_meta:
  openai:
    http_status: 200
    latency_ms: 54531
    attempts: 1
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 58254
    attempts: 5
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 65090
    attempts: 1
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 26606
    attempts: 1
    raw_json: Projects/researcher-skill/reviews/raw/2026-02-27-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Researcher Skill Action Plan

**Artifact:** Projects/researcher-skill/design/action-plan.md
**Mode:** full
**Reviewed:** 2026-02-27
**Reviewers:** OpenAI (gpt-5.2), Google (gemini-3-pro-preview), DeepSeek (deepseek-reasoner), Grok (grok-4-1-fast-reasoning)
**Review prompt:** Full structured review of action plan architecture — evaluating dependency correctness, milestone scoping, risk calibration, acceptance criteria quality, coverage, feasibility, and integration checkpoint design.

---

## OpenAI (gpt-5.2)

## 1) Dependency correctness

- **[F1] — CRITICAL — Finding:** Milestone 4 “Evidence Verification” dependency chain is internally inconsistent: RS-008 (write-only-from-ledger / Writing Validation rules) depends on RS-007, but the Milestone 4 narrative says RS-008 is “Writing Validation” and Milestone 5 says RS-014 depends on RS-008. In practice, RS-008’s rules/spec can (and likely should) exist *before* RS-007, because writing validation is about the *output document* and ledger references, not quote verification mechanics.  
  **Why:** This can delay implementing the central hallucination-prevention gate (write-only-from-ledger) behind verification, even though RS-008 is foundational and should be used to constrain RS-014 early. It also creates a “late discovery” risk: you might build Writing prompts that later fail validation constraints.  
  **Fix:** Split RS-008 into (a) **RS-008a** “Citation format + validation spec” (depends on RS-001/RS-005 only) and (b) **RS-008b** “Validation execution stage/prompt” (depends on RS-013 + RS-005). Or simply change RS-008 dependency to **RS-001 + RS-005** (plus optionally RS-014 if it’s a harness), leaving RS-007 independent.

- **[F2] — SIGNIFICANT — Finding:** RS-007 depends only on RS-004, but RS-007 acceptance criteria requires “supersede corrections” which implies the ledger supersede mechanism (defined in RS-005) must exist and be stable.  
  **Why:** If RS-007 runs without RS-005 guarantees, “supersede” behavior is underspecified at verification time, risking inconsistent ledger evolution.  
  **Fix:** Add **RS-005 as an explicit dependency** for RS-007 (and likely RS-009 too if it writes classifications back into ledger entries).

- **[F3] — SIGNIFICANT — Finding:** RS-013 (Synthesis) depends on RS-006 and RS-010 only, but its acceptance criteria requires “all ledger entries mapped” and “quality ceiling notes,” implying it must read ledger schema + quality ceiling fields emitted earlier. Those are introduced in RS-004/RS-006. This is probably OK implicitly, but the dependency set is slightly under-specified.  
  **Why:** In prompt-driven pipelines, “implicit dependencies” often cause mismatched schemas between stages.  
  **Fix:** Add “requires ledger schema vX” as a **formal handoff contract requirement** in RS-013, or add **RS-004** as a dependency (if you want to enforce schema alignment explicitly).

- **[F4] — MINOR — Finding:** RS-011 says it “merges at M3 integration” and depends only on RS-001, but it also references “min-evidence-before-escalation” and “critical-path exception for uniquely authoritative sources,” which is tightly coupled to RS-004 (research loop) and RS-006 (tiering / convergence).  
  **Why:** The gate framework can be built early, but *trigger conditions* are hard to validate without the loop mechanics.  
  **Fix:** Keep RS-011 dependency as-is (design-time), but add an explicit **integration test checkpoint** “RS-011 triggers validated during RS-004 live testing” so it’s not “done” purely on paper.

- **[F5] — STRENGTH — Finding:** Critical path analysis is directionally correct for “first end-to-end cited deliverable”: RS-001 → RS-002 → RS-003 → RS-004 → RS-006 → RS-010 → RS-013 → RS-014 → RS-015.  
  **Why:** It matches the natural pipeline: define → plan → collect → score/stop → synthesize → write → export.  
  **Fix:** None, aside from tightening dependencies noted above.

## 2) Milestone scoping

- **[F6] — SIGNIFICANT — Finding:** Milestone 3 bundles RS-004/006/010/011 (core loop + scoring + termination + escalation). That’s a lot of first-time “live calibration” surface area in one checkpoint.  
  **Why:** If WebFetch extraction is noisy, you may spend iterations debugging basic ingestion while also tuning convergence and escalation logic—hard to attribute failures.  
  **Fix:** Consider splitting M3 into **M3a “Research loop + basic ledger population (RS-004 + RS-009 minimal)”** and **M3b “Convergence + termination + escalation (RS-006/010/011)”**. Keep end-to-end tests at M3b.

- **[F7] — STRENGTH — Finding:** Milestone 1 is appropriately foundational: identity + ledger/handoff I/O.  
  **Why:** Almost every later stage depends on schema stability and snapshot mechanics.  
  **Fix:** None.

- **[F8] — MINOR — Finding:** Milestone 4 is well scoped conceptually (verification + validation + failure handling), but RS-009 (failure modes) sits there while also being needed earlier during web ingestion in M3.  
  **Why:** Many failure modes (timeouts, rate limits, paywalls) will be encountered in M3; delaying formal handling to M4 risks ad-hoc behavior.  
  **Fix:** Move RS-009 into Milestone 3 (or split into M3 “ingestion-time failures” and M4 “verification-time failures”).

## 3) Risk calibration

- **[F9] — SIGNIFICANT — Finding:** RS-014 (Writing) risk is marked “medium,” but it is the primary “hallucination prevention gate” and depends on tight mechanical constraints. It’s arguably **medium-high**.  
  **Why:** Writing is where failures become user-visible and integrity-critical; validation loops can be iteration-heavy.  
  **Fix:** Reclassify RS-014 risk to **medium-high** and explicitly budget Pattern 4 iterations for it (like M3).

- **[F10] — STRENGTH — Finding:** Milestone 3 risk is correctly rated medium-high and explicitly calls out calibration and tool limitations.  
  **Why:** That’s the true uncertainty center.  
  **Fix:** None.

- **[F11] — MINOR — Finding:** RS-005 risk marked low, but it’s schema + supersede semantics + 8KB/overflow behavior; if wrong, everything downstream breaks. The *implementation difficulty* may be low, but *blast radius* is high.  
  **Why:** Risk rating should reflect impact as well as effort.  
  **Fix:** Keep “low effort” note but consider “medium impact” label or add a mitigation: “schema review + golden test vectors.”

## 4) Acceptance criteria quality (binary/testable)

- **[F12] — SIGNIFICANT — Finding:** Several criteria are partially subjective or under-specified, making YES/NO difficult:
  - RS-012: “results reduce redundant research” (hard to test deterministically)  
  - RS-013: “overall confidence assessment produced” (produced how? what fields?)  
  - RS-009: “garbage result detection (irrelevant results skipped)” (needs a rule or measurable threshold)  
  **Why:** Non-binary criteria cause “done-ness” debates and inconsistent stage outputs.  
  **Fix:** Convert to explicit checks, e.g.:
  - RS-012: “Scoping output includes `vault_coverage: {notes: N, sources: M, gaps: [...]}` and Planning includes `skip_queries` list populated from vault sources.”  
  - RS-013: “Output includes field `overall_confidence: {score: 0-1, rationale: <=1200 chars, drivers:[...]}`.”  
  - RS-009: Define a classification rubric and require “each candidate result has `relevance: pass|fail` with a logged reason; fail results never become ledger entries.”

- **[F13] — SIGNIFICANT — Finding:** RS-007’s “near-miss detection (≥80% token overlap = pass…)” is testable, but only if tokenization and normalization are precisely defined. Currently “token overlap” is ambiguous (Jaccard? overlap of snippet tokens in content tokens? order-sensitive?).  
  **Why:** Verification integrity depends on deterministic matching; ambiguity leads to false passes/fails and undermines trust.  
  **Fix:** Define an exact algorithm in the acceptance criteria (e.g., “lowercase, collapse whitespace, strip punctuation except intra-word hyphens; tokens = split on whitespace; overlap = |snippet_tokens ∩ window_tokens| / |snippet_tokens|; window = best-matching contiguous window of length ±20% of snippet token count”).

- **[F14] — MINOR — Finding:** Some criteria reference file paths but not required fields inside those files (e.g., research-status markdown structure).  
  **Why:** Without minimal schema, later automation/telemetry parsing can break.  
  **Fix:** Add a small required header block for `research-status-[dispatch].md` (dispatch id, stage, timestamp, iteration, counters, last errors).

- **[F15] — STRENGTH — Finding:** Many criteria are well-formed and mechanically checkable: 8KB limit + overflow at 7KB, explicit tier weights, diminishing returns thresholds, explicit rigor thresholds.  
  **Why:** This is exactly what prompt-driven orchestration needs.  
  **Fix:** None.

## 5) Coverage (18 spec tasks vs plan)

- **[F16] — SIGNIFICANT — Finding:** The plan claims “peer-reviewed specification (19 tasks across 4 phases)” but the provided task set includes RS-001..RS-018 (18 tasks). There is a mismatch between “19” and “18.”  
  **Why:** Indicates either a missing task (gap) or a documentation inconsistency that will cause tracking errors.  
  **Fix:** Reconcile counts: either add the missing RS-019 (if spec truly has 19) or correct the overview language everywhere to 18.

- **[F17] — SIGNIFICANT — Finding:** There’s no explicit task for a **stage registry / pipeline manifest** that enumerates stages, numbers, schemas, and runner wiring (even if the runner exists, the skill usually needs a map). Some of this is implied in RS-001, but acceptance criteria for RS-001 focuses on SKILL.md only.  
  **Why:** In a stage-separated system, missing/incorrect stage wiring is a common integration failure.  
  **Fix:** Add explicit acceptance criteria in RS-001 (or a new task) for a machine-readable stage manifest (even YAML) that lists stage names, input/output schema versions, and file locations.

- **[F18] — MINOR — Finding:** Observability is described as cross-cutting, but there’s no task that defines the exact schema of telemetry fields and counters used across milestones (beyond RS-015).  
  **Why:** Without early alignment, later stages will emit inconsistent counters that RS-015 expects.  
  **Fix:** Add a “telemetry schema definition” subtask to RS-005 or RS-001, and require each stage to emit those counters even if null.

## 6) Feasibility given “prompt template + schema + orchestration config”

- **[F19] — SIGNIFICANT — Finding:** Some tasks assume capabilities that may not be reliably achievable “in prompt only” without helper utilities:
  - RS-004: “content_hash computed”  
  - RS-005: strict 8KB measurement + overflow mechanism  
  - RS-007: token overlap calculations and normalized substring checks  
  **Why:** If the runner doesn’t provide hashing/measurement utilities, expecting the model to compute hashes or byte sizes is not feasible/reliable.  
  **Fix:** Explicitly state which computations are performed by the **runner injection layer** (Pattern 1) vs by the model. E.g., runner computes `content_hash`, byte-size checks, and provides `handoff_bytes` metadata; model only classifies and selects.

- **[F20] — STRENGTH — Finding:** The plan consistently frames “implementation” as prompt+schema+handoff contracts rather than code, and includes an iteration budget for calibration.  
  **Why:** This is realistic for claude --print stage pipelines.  
  **Fix:** None.

## 7) Integration checkpoint design

- **[F21] — SIGNIFICANT — Finding:** Milestone success criteria mostly test stage-local outputs, but there are few explicit **contract tests** between stages (schema compatibility, required fields present, versioning).  
  **Why:** Integration failures in these systems are often “stage N output missing field X that stage N+1 assumes.”  
  **Fix:** Add at least one explicit integration criterion per milestone: “Stage N output validates against schema; Stage N+1 accepts it without repair.” Include a simple JSON Schema (or YAML schema checklist) and require validation in the runner.

- **[F22] — MINOR — Finding:** The dependency graph indicates “RS-005 merges” before RS-004; milestone success criteria for M1 includes “handoff serialization round-trips correctly within 8KB limit,” but later stages will likely expand handoff. There’s no checkpoint that validates handoff stays under limit with realistic payloads (multiple sub-questions, many sources).  
  **Why:** You can pass M1 with trivial data and then fail catastrophically in M3/M5.  
  **Fix:** Add an integration test vector at end of M2: “handoff with ≥3 sub-questions + vault coverage summary remains under 8KB or triggers overflow correctly.”

- **[F23] — STRENGTH — Finding:** The plan intentionally merges vault input early (RS-012) so later testing benefits from it, and includes escalation gates during M3 so failures have a path.  
  **Why:** That’s good “integration-first” thinking.  
  **Fix:** None.

---

## UNVERIFIABLE CLAIMS (cannot independently verify from artifact alone)

- **[F24] — SIGNIFICANT — Finding:** **UNVERIFIABLE CLAIM:** “Crumb dispatch protocol (CTB-016)” details, including “§4.3 of dispatch-protocol.md” and “CTB-016 §6 gate_type enum.”  
  **Why:** If these sections/enums differ, stage schemas and gate outputs may be incompatible with the runner.  
  **Fix:** Link or embed the exact enum + schema excerpt in this plan (or in RS-001 acceptance criteria), and add a conformance checklist.

- **[F25] — SIGNIFICANT — Finding:** **UNVERIFIABLE CLAIM:** Reference to `_system/docs/solutions/claude-print-automation-patterns.md` “Pattern 4” and “Pattern 1.”  
  **Why:** Iteration budgets and runner injection responsibilities depend on what those patterns actually specify.  
  **Fix:** Quote the specific requirements your plan depends on (e.g., what deterministic fields are injected; whether hashing/size checks are runner-side).

- **[F26] — SIGNIFICANT — Finding:** **UNVERIFIABLE CLAIM:** “peer-reviewed specification (19 tasks across 4 implementation phases)” and multiple “spec §3.1/§3.9/§3.10” references.  
  **Why:** Your plan’s completeness and ordering depends on what those spec sections require; the 19 vs 18 mismatch suggests drift.  
  **Fix:** Add a spec-to-task traceability matrix (spec requirement → RS-XXX) and reconcile task count.

---

### Summary of key fixes (highest leverage)
1. Rework RS-008 dependency (and possibly split into spec vs execution) so writing validation is not blocked by citation verification.  
2. Make RS-007 depend on RS-005 (supersede + ledger mutation semantics).  
3. Clarify which computations are runner-side vs model-side (hashing, byte sizes, overlap metrics).  
4. Tighten ambiguous acceptance criteria into deterministic schemas/algorithms.  
5. Reconcile the 19 vs 18 task mismatch with traceability to spec sections.

---

## Google (gemini-3-pro-preview)

Here is the review of the Researcher Skill Action Plan and Tasks.

### 1. Unverifiable Claims
The following references refer to internal documentation or frameworks not provided in the context. These are accepted as axiomatic for the review but flagged for verification against your actual file system.

*   [F1] [SIGNIFICANT] **UNVERIFIABLE CLAIM:** References to `CTB-016` (Dispatch Protocol) and its specific sections (§3.1, §3.9, §3.10, §4.3, §6).
*   [F2] [SIGNIFICANT] **UNVERIFIABLE CLAIM:** References to `_system/docs/solutions/claude-print-automation-patterns.md` and "Pattern 1" / "Pattern 4".
*   [F3] [MINOR] **UNVERIFIABLE CLAIM:** References to specific Citation formats `[^FL-NNN]` as a system-standard.

### 2. Review Findings

#### Dependency Correctness & Feasibility
*   [F4] [SIGNIFICANT] **Late Binding of Resilience Logic (RS-009).**
    *   **Finding:** RS-009 (Failure Handling: garbage detection, rate limits, graceful degradation) is scheduled for Milestone 4. However, Milestone 3 involves "Live deployment iteration" of the Research Loop (RS-004).
    *   **Why:** Without RS-009, the M3 Research Loop lacks the logic to handle "garbage results" or timeouts gracefully. M3 testing encounters a high risk of "false positive" failures where the loop crashes or hallucinates on empty returns, rather than degrading gracefully. This contradicts the "Medium-High" risk assessment of M3, as the loop is brittle until M4.
    *   **Fix:** Move RS-009 to Milestone 3, or explicitly note in M3 Success Criteria that the loop is expected to fail hard on network/parser errors until M4.

*   [F5] [MINOR] **Ambiguous Dependency for Escalation (RS-011).**
    *   **Finding:** The Action Plan states RS-011 "depends only on RS-001," yet it is grouped in Milestone 3 to "exercise escalation paths."
    *   **Why:** The Research Loop (RS-004) must generate the signal that triggers an escalation. Therefore, RS-004 likely depends on the *schema* or *trigger definitions* established in RS-011 to function correctly. If RS-004 is built before RS-011 is defined, RS-004 will need refactoring to add escalation triggers.
    *   **Fix:** Adjust dependency to show RS-004 implies a weak dependency on RS-011 (definitions), or ensure RS-011 is completed *before* RS-004 iterations begin.

#### Milestone Scoping & Risk
*   [F6] [SIGNIFICANT] **Milestone 3 Density / Bottleneck.**
    *   **Finding:** Milestone 3 contains the implementation of the Loop (RS-004), Scoring (RS-006), Control (RS-010), and Escalation (RS-011).
    *   **Why:** This represents the entire execution engine. If the loop fails to converge, isolating the cause (Is it the search tool? The scoring math? The control logic?) will be difficult because all distinct components are being integrated simultaneously.
    *   **Fix:** Consider splitting M3 into "M3a: Mechanical Loop" (Search + Store) and "M3b: Intelligence" (Scoring + Convergence + Escalation).

#### Acceptance Criteria Quality
*   [F7] [STRENGTH] **Binary Testability of "Soft" Tasks.**
    *   **Finding:** The acceptance criteria for subjective tasks are rigorously quantified.
    *   **Why:** For example, RS-007 defines "Near-miss detection" not as "detects similar quotes" but as "≥80% token overlap = pass, 50-80% = flagged". RS-006 defines "diminishing returns" as "<2 new entries AND <0.05 score improvement". This transforms prompt engineering into engineering.

*   [F8] [MINOR] **Telemetry Gap in Failure Modes (RS-015).**
    *   **Finding:** Telemetry capture is isolated to RS-015 (Output Phase).
    *   **Why:** If a dispatch triggers an Escalation (RS-011) or fails via Timeout (RS-009), the process terminates or diverts before reaching RS-015. This implies that "failed" runs will leave no telemetry traces regarding source tiers or iteration counts, creating a survivor bias in the metrics.
    *   **Fix:** Add a requirement to RS-011 and RS-009 to write partial telemetry snapshots before terminating/escalating.

#### Architecture & Integration
*   [F9] [STRENGTH] **"Write-Only-From-Ledger" Enforcement.**
    *   **Finding:** The separation of RS-004 (Populate Ledger) in M3 and RS-007/RS-014 (Verify & Write) in M4/M5 is a robust architectural decision.
    *   **Why:** This strictly separates the "Generator" (Research Loop) from the "Discriminator" (Verification), ensuring that the Writing stage is physically incapable of hallucinating sources that do not exist in the verified ledger.

*   [F10] [MINOR] **Vault Input Graph Logic (RS-012).**
    *   **Finding:** The dependency graph shows `RS-002 -> RS-012 -> RS-003`.
    *   **Why:** RS-012 is described as enhancing the Scoping stage (RS-002). In a linear build plan, this implies RS-002 is built, then modified by RS-012, before RS-003 consumes the result. While logically sound for a build order, it obscures the runtime flow (where Scoping is a single stage).
    *   **Fix:** Clarify in RS-012 AC that it involves *modifying the RS-002 prompt template*, not creating a standalone "Vault Input" pipeline stage.

### 3. Review Summary
The plan is architecturally sound, particularly in its rigorous separation of evidence gathering (ledger population) from deliverable generation (writing). The primary risk is in **Milestone 3**, which is overloaded with the simultaneous integration of the loop, scoring logic, and escalation gates. Additionally, the deferral of failure handling (RS-009) to Milestone 4 threatens to make Milestone 3 testing frustratingly brittle.

**Verdict:** APPROVED with noted adjustments to M3/M4 sequencing (move RS-009 earlier).

---

## DeepSeek (deepseek-reasoner)

Here is a structured review of the provided action plan artifact.

### **1. Dependency Correctness**

- **F1**
    - **Severity**: SIGNIFICANT
    - **Finding**: Potential race condition in Milestone 4 dependencies. RS-009 (Failure Handling) depends only on RS-004, and RS-007 (Citation Verification) also depends only on RS-004. This implies they could be developed in parallel. However, RS-009's logic for handling "garbage results" and "paywall classification" seems intrinsically linked to the source scoring and ingestion class assignment performed in RS-004, and its outputs (e.g., marking sources as `ToolLimited`) would be critical inputs for RS-007's verification logic (which must handle `non-FullText` sources).
    - **Why**: Developing RS-009 in isolation from RS-007 could lead to incompatible data models or handling logic, causing integration failures at M4.
    - **Fix**: Update RS-009's `Depends On` to include RS-007, or at least note a strong integration dependency. Better yet, consider making RS-009 a sub-task or integrated component of RS-004 and/or RS-007, as failure handling is not a standalone stage but a cross-cutting concern within the Research Loop and Verification stages.

- **F2**
    - **Severity**: SIGNIFICANT
    - **Finding**: Missing dependency for RS-008 (Writing Validation). It depends on RS-007 but not on RS-005 (Fact Ledger I/O). RS-008's acceptance criteria involve checking `[^FL-NNN]` resolution against ledger entries and detecting orphan citations, which requires read access to the ledger schema and data built in RS-005.
    - **Why**: The validation logic cannot be designed or tested without the concrete ledger I/O mechanisms.
    - **Fix**: Add RS-005 to RS-008's `Depends On` field.

- **F3**
    - **Severity**: MINOR
    - **Finding**: The dependency graph and critical path are logically sound and well-reasoned. The analysis correctly identifies parallel tracks and merge points.

### **2. Milestone Scoping**

- **F4**
    - **Severity**: SIGNIFICANT
    - **Finding**: Milestone 3 ("Research Execution + Escalation") is overloaded and represents the single highest-risk integration point. It combines the core research engine (RS-004), convergence logic (RS-006), loop control (RS-010), *and* the escalation system (RS-011).
    - **Why**: This milestone has "Medium-High" risk. Bundling these four complex, interdependent systems into one checkpoint increases the chance that a flaw in one (e.g., convergence scoring) could block testing of others (e.g., escalation), making debugging complex. The rationale that escalation is included so "paywall/scope issues... have a handler" is valid, but it increases milestone scope.
    - **Fix**: Consider splitting M3 into **M3a: Research Core (RS-004, RS-006, RS-010)** and **M3b: Escalation Integration (RS-011)**. M3a's success criteria would be a loop that runs and terminates based on convergence/diminishing returns. M3b would then integrate escalation gates, using the working loop from M3a to trigger them. This creates a cleaner, sequential validation.

- **F5**
    - **Severity**: STRENGTH
    - **Finding**: Milestone scoping is generally logical, building from infrastructure (M1) outward through the pipeline stages (M2, M3, M4, M5). Each milestone delivers a testable integration of related components.

### **3. Risk Calibration**

- **F6**
    - **Severity**: SIGNIFICANT
    - **Finding**: Risk for RS-011 ("Implement 4 researcher-specific escalation gates") is listed as "Medium." This understates the stakes. Escalation gates are the primary mechanism for human-in-the-loop intervention on ambiguous, conflicting, or blocked research paths. Design flaws here could lead to the skill getting stuck, making poor autonomous decisions, or over-escalating.
    - **Why**: As a primary interface with the operator and a critical safeguard, its failure has high impact on usability and trust.
    - **Fix**: Recalibrate RS-011 risk to "High." Ensure the "live deployment iteration budget" (Pattern 4) explicitly includes extensive testing of escalation gate triggering, batching, and handoff updates.

- **F7**
    - **Severity**: STRENGTH
    - **Finding**: Risks are generally well-calibrated. The "Medium-High" rating for M3 is appropriate. The plan explicitly mitigates this via "Pattern 4 (live iteration budget)," which is a realistic and pragmatic approach for calibrating LLM-based stages.

### **4. Acceptance Criteria Quality**

- **F8**
    - **Severity**: SIGNIFICANT
    - **Finding**: Some acceptance criteria are process-oriented rather than binary testable. **RS-012**: "contradictions between vault knowledge and new findings flagged" – "Flagged" is vague. How and where is the flag recorded? **RS-009**: "graceful degradation mode (advance with coverage note)" – The content standard for a "coverage note" is undefined.
    - **Why**: Vague criteria make it difficult to objectively declare a task complete and could lead to inconsistent implementations.
    - **Fix**: Make criteria output-specific. E.g., for RS-012: "Handoff includes an `open_questions` list with entries where vault evidence contradicts new ledger entries." For RS-009: "Research status file is updated with a `degradation_note` field explaining the timeout cascade, and handoff `coverage_quality` is set to `degraded`."

- **F9**
    - **Severity**: STRENGTH
    - **Finding**: Most acceptance criteria are excellent and binary (YES/NO). Examples: "Ledger YAML created with all required fields...", "overflow at 7KB writes coverage to vault file and replaces handoff value with `{"ref": "path"}`", "Writing Validation passes all 4 checks".

### **5. Coverage**

- **F10**
    - **Severity**: MINOR
    - **Finding**: The plan and tasks table comprehensively cover the 19 tasks mentioned in the overview (RS-001 to RS-018). The deferral of MCP tasks (RS-016, RS-017, RS-018) to a future Milestone 6 is clearly reasoned and acceptable for a V1.

- **F11**
    - **Severity**: SIGNIFICANT
    - **Finding**: **UNVERIFIABLE CLAIM**: The plan references `_system/docs/solutions/claude-print-automation-patterns.md` and its "Pattern 4." It also assumes the existence and completeness of "CTB-016's dispatch runner" and "CTB-016's gate framework."
    - **Why**: The review cannot assess if these referenced components exist as described, or if their APIs align with the dependencies assumed by this plan. A gap here would be catastrophic.
    - **Fix**: This is a note for the reviewer/implementer: **Verification of these foundational dependencies is a prerequisite for action plan execution.** The first step before starting RS-001 must be to audit the claimed capabilities of CTB-016 and the automation patterns document.

### **6. Feasibility**

- **F12**
    - **Severity**: STRENGTH
    - **Finding**: The plan is highly feasible given its context. The definition of "implementation" as designing prompt templates, output schemas, and handoff contracts—relying on an existing dispatch runner—is clear and appropriate. Task scopes (e.g., "implement Scoping stage") correctly focus on the configuration and prompt engineering work required, not on building orchestration from scratch.

### **7. Integration Checkpoint Design**

- **F13**
    - **Severity**: STRENGTH
    - **Finding**: Milestone success criteria are well-designed to catch integration issues early. Each milestone culminates in a functional test of integrated components (e.g., M2: "Scoping → Planning handoff chain works correctly"; M3: "End-to-end: Scoping → Planning → Research Loop(s) → converged ledger"). This aligns with modern CI/CD and systems thinking.

- **F14**
    - **Severity**: MINOR
    - **Finding**: The "Observability" cross-cutting concern mandates outputs (handoff snapshots, status files) for *all* stages, which is excellent for debugging. However, the success criteria for individual milestones could more explicitly require inspecting these files as part of the integration test.
    - **Fix**: Augment milestone success criteria with a line like "All stage-specific handoff snapshots and research status updates are generated and inspectable."

### **Summary of Flagged Unverifiable Claims**

- The existence, specification, and readiness of the **Crumb dispatch framework (CTB-016)**.
- The existence and content of the internal document **`_system/docs/solutions/claude-print-automation-patterns.md`**.
- The claimed capabilities of the **"bridge infrastructure"** and **"dispatch runner."**

These references form the architectural foundation of the entire plan. Their verification is **critical** and falls outside the scope of reviewing this artifact's internal consistency.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: References to "CTB-016" (dispatch protocol) throughout, including §4.3 schema, §6 gate_type enum, and lifecycle management.
- [Why]: Core architectural dependency; cannot confirm if enums, schemas, or gates match without access, risking misalignment in implementation.
- [Fix]: Operator to provide or stub CTB-016 excerpts for review; flag as blocker until verified.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Spec section references like §3.1 (6 stages), §3.9 (prompt design), §3.10 (telemetry fields), and "19 tasks across 4 implementation phases."
- [Why]: Plan claims full coverage of a spec with 19 tasks, but tasks table lists RS-001–RS-018 (18 tasks); mismatch suggests gap or error without spec access.
- [Fix]: Cross-reference against actual spec; adjust task count or add missing RS-019.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Docs like `_system/docs/solutions/claude-print-automation-patterns.md` Pattern 4 (3-6 iterations), `dispatch-protocol.md`.
- [Why]: Iteration budgets and patterns dictate feasibility; unverified assumptions could lead to underestimated calibration effort.
- [Fix]: Extract relevant patterns/sections into review context.

- [F4]
- [Severity]: CRITICAL
- [Finding]: Coverage gap: Context claims "19 tasks," but action plan and tasks table cover only RS-001–RS-018 (18 tasks); no RS-019 or explanation.
- [Why]: Incomplete coverage of spec risks missing essential functionality; violates "covers all spec tasks."
- [Fix]: Identify/add missing task (e.g., integration test or config); recount spec tasks.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Dependency missing: RS-003 (Planning) depends only on RS-002 per tasks table, but action plan positions RS-012 (vault input enhancing Scoping) before Planning in M2 phases (2.1→2.2→2.3); critical path implies RS-002→RS-012→RS-003.
- [Why]: Planning may produce suboptimal decompositions without vault-aware scoping; breaks stated merge point.
- [Fix]: Add RS-012 to RS-003 Depends On; update critical path explicitly.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Dependency inaccuracy: RS-013 (Synthesis) depends on RS-006/RS-010 (converged ledger), but action plan notes "Synthesis runs before Citation Verification" while M5 deps include M4 complete (RS-007/RS-008); pipeline order unclear.
- [Why]: Handoff chain assumes sequential stages; parallel deps risk ledger state mismatches (unconverged vs. verified).
- [Fix]: Clarify pipeline sequence in procedure skeleton (RS-001); adjust deps if Synthesis precedes Verification (remove RS-007 from RS-014?).

- [F7]
- [Severity]: MINOR
- [Finding]: Dependency graph oversimplifies: Shows RS-005 merging at RS-004, but parallel tracks summary notes Track B (RS-012) "merges at RS-003/M2"; graph lacks RS-012/RS-011 edges.
- [Why]: Visual aid misleads implementer on integration points.
- [Fix]: Add edges for RS-012→RS-003, RS-011→M3 in graph.

- [F8]
- [Severity]: STRENGTH
- [Finding]: No circular dependencies; critical path (9 tasks) is linear and matches tasks table.
- [Why]: Enables predictable sequencing without deadlocks.
- [Fix]: N/A

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: Milestone scoping too large for M3 (4 tasks: RS-004/006/010/011); combines core loop, scoring, control, and escalation.
- [Why]: Violates "meaningful integration checkpoints"; failure in RS-004 cascades, exceeding 3-6 iteration budget (Pattern 4).
- [Fix]: Split M3 into M3a (Research Loop RS-004), M3b (Scoring/Control RS-006/010), M3c (Escalation RS-011 + integration).

- [F10]
- [Severity]: MINOR
- [Finding]: M1/M2 small (2-3 tasks), logical for foundations; M4/M5 balanced (3 tasks each).
- [Why]: Builds momentum early.
- [Fix]: N/A (but monitor M3).

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: M6 deferred without timeline triggers beyond "MCP tool availability"; no integration plan post-deferral.
- [Why]: Risks V1 without higher-quality tools; spec coverage incomplete long-term.
- [Fix]: Add activation criteria (e.g., "after 5 live dispatches with >20% ToolLimited").

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Risk calibration low for RS-003/RS-004 (medium, but "poor decomposition = wasted search iterations"); should be medium-high like M3 overall.
- [Why]: Lever 3 (decomposition) is core; understates stakes vs. M3 medium-high.
- [Fix]: Elevate RS-003/RS-004 to medium-high; add mitigation (e.g., examples in prompt design).

- [F13]
- [Severity]: MINOR
- [Finding]: M3 medium-high risk well-mitigated by Pattern 4 budget and early escalation (RS-011).
- [Why]: Aligns plan structure to stakes.
- [Fix]: N/A

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: Acceptance criteria vague/non-binary for many: e.g., RS-002 "produces refined scope with explicit exclusions" (what counts as "refined"?); RS-004 "executes ≥1 web search per iteration" (but testable via logs?).
- [Why]: Hinders YES/NO testing; relies on subjective live iteration judgment.
- [Fix]: Add metrics (e.g., "scope includes ≥1 inclusion/≥1 exclusion"; "search query logged in status file").

- [F15]
- [Severity]: MINOR
- [Finding]: AC strong for RS-006 (explicit thresholds: light 0.5/standard 0.7/deep 0.85); testable formulas.
- [Why]: Model prompt calibration edge cases covered.
- [Fix]: N/A (edge: verify `convergence_overrides` overrides profile).

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: Coverage gap: Spec requires "mechanical citation integrity" (Levers 3/5), but RS-008 AC lacks binary for "source chain" check (how traces?); no task for overall pipeline E2E beyond milestones.
- [Why]: Hallucination prevention core; untested chains allow drift.
- [Fix]: Add RS-019: "E2E integration test suite" with AC for full dispatch.

- [F17]
- [Severity]: STRENGTH
- [Finding]: Cross-cutting observability (handoff snapshots, status files) in every stage; covers all tasks.
- [Why]: Enables debugging without full re-runs.
- [Fix]: N/A (edge: verify 8KB limit in snapshots).

- [F18]
- [Severity]: MINOR
- [Finding]: Feasibility high overall (prompt/schema focus), but RS-017 (MCP APIs: arXiv/PubMed) high-risk without auth details.
- [Why]: Realistic for deferred, but auth feasibility unaddressed.
- [Fix]: Add AC "auth via env vars documented."

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: Integration checkpoints weak: M2 "handoff chain works correctly" lacks specifics (e.g., schema validation); M3 "end-to-end Scoping→...→converged ledger" assumes no tool failures.
- [Why]: Misses early catch of I/O/orchestration issues (e.g., 8KB overflow).
- [Fix]: Add to each M success: "Runner executes M stages without dispatch failure; all snapshots parse."

- [F20]
- [Severity]: MINOR
- [Finding]: Dependency summary repeats critical path accurately; parallel tracks well-identified.
- [Why]: Good navigation aid.
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Milestone 3 overloaded (4/4 reviewers)**
OAI-F6, GEM-F6, DS-F4, GRK-F9. Unanimous: 4 tasks (RS-004, RS-006, RS-010, RS-011) combining the core execution engine, scoring, loop control, and escalation is too much for a single integration checkpoint. Debugging failures becomes attribution-difficult.

**2. RS-009 (failure handling) should move earlier (3/4 reviewers)**
OAI-F8, GEM-F4, GRK-F9. The Research Loop (M3) encounters timeouts, paywalls, and garbage results during live testing. Without RS-009, M3 testing is brittle — failures crash the loop instead of degrading gracefully. Moving RS-009 into M3 makes the Research Loop testable.

**3. Vague/non-binary acceptance criteria (4/4 reviewers)**
OAI-F12, GEM-F8 (partial), DS-F8, GRK-F14. Multiple criteria are subjective: RS-012 "results reduce redundant research," RS-013 "overall confidence assessment produced," RS-009 "graceful degradation mode," RS-002 "refined scope." These resist YES/NO determination.

**4. CTB-016 and automation patterns references unverifiable (4/4 reviewers)**
OAI-F24/F25, GEM-F1/F2, DS-F11, GRK-F1/F3. Expected for internal docs — these are verified vault artifacts but opaque to external reviewers. Not actionable beyond noting.

**5. Missing RS-005 dependency for RS-007/RS-008 (2/4 reviewers)**
OAI-F2, DS-F2. RS-007 uses supersede mechanics defined in RS-005. RS-008 reads ledger entries defined in RS-005. Both should explicitly depend on RS-005 (currently only transitively covered via RS-004 → RS-005).

**6. 19 vs 18 task count mismatch (3/4 reviewers)**
OAI-F16, GRK-F2/F4. Action plan overview says "19 tasks" but task table has RS-001–RS-018 (18 tasks). Historical artifact: spec run-log says "19" after RS-005b was added, but RS-005b was folded into RS-005's expanded description.

### Unique Findings

**OAI-F1 (CRITICAL): RS-008 should not depend on RS-007.** Writing validation rules (citation format, 4 checks) are defined against the ledger schema (RS-005), not against verified entries (RS-007). The current dependency delays the hallucination prevention gate behind verification unnecessarily. **Genuine insight** — the validation RULES are independent of whether verification has run; only the validation EXECUTION (in RS-014) needs verified data.

**OAI-F19 (SIGNIFICANT): Runner vs model computation boundary unclear.** Content_hash computation, 8KB byte measurement, and token overlap calculations may not be reliably achievable by the model in a `--print` session. Need to clarify which computations the runner handles (Pattern 1) vs what the model does. **Genuine insight** — directly affects feasibility.

**GEM-F5 (MINOR): RS-004 has weak dependency on RS-011.** If RS-004 is built before escalation triggers are defined, RS-004 prompts won't include escalation trigger logic and will need refactoring. In practice, both are in M3 and RS-011 can be done first. **Genuine but mitigated by milestone grouping.**

**GEM-F8 (MINOR): Telemetry gap for failed dispatches.** Dispatches that fail or escalate terminate before RS-015, leaving no telemetry trace. Partial telemetry writes from RS-009/RS-011 would prevent survivor bias in metrics. **Genuine insight.**

**GRK-F5 (SIGNIFICANT): RS-003 should depend on RS-012.** The action plan positions RS-012 before RS-003 in M2 (Phase 2.1 → 2.2 → 2.3), but the tasks table shows RS-003 depends only on RS-002. If Planning should benefit from vault-aware scoping, the dependency must be explicit. **Genuine — the plan intends this ordering but the task dependency doesn't enforce it.**

**GRK-F11 (SIGNIFICANT): M6 (deferred MCP) lacks activation criteria.** No trigger for when to start MCP work beyond "tool availability." Adding concrete criteria (e.g., "after N dispatches with >20% ToolLimited sources") would make the deferral actionable. **Genuine.**

### Contradictions

**M3 split granularity — reviewers agree on the problem but disagree on the cut:**
- OAI: M3a (loop + minimal RS-009) + M3b (convergence + termination + escalation)
- GEM: M3a (mechanical loop) + M3b (intelligence: scoring + convergence + escalation)
- DS: M3a (core RS-004/006/010) + M3b (escalation RS-011)
- GRK: M3a (loop) + M3b (scoring/control) + M3c (escalation + integration)

**Resolution:** The cleanest split aligns with the "can we search?" → "can we converge?" progression. M3a = Research Loop + Failure Handling (RS-004, RS-009) — validate that web search populates a ledger and handles bad sources. M3b = Convergence + Loop Control + Escalation (RS-006, RS-010, RS-011) — add the intelligence layer that decides when to stop and when to ask.

**RS-008 dependency (complementary, not contradictory):**
- OAI: RS-008 should depend on RS-001/RS-005, not RS-007 (split or change)
- DS: RS-008 is missing RS-005 dependency

Both point to the same fix: RS-008 depends on RS-005, not RS-007.

### Action Items

**A1 (must-fix):** Split M3 into M3a (Research Loop + Failure Handling: RS-004, RS-009) and M3b (Convergence + Loop Control + Escalation: RS-006, RS-010, RS-011). This creates a "search works" checkpoint before adding convergence intelligence. Move RS-009 from M4 to M3a.
*Sources: OAI-F6, OAI-F8, GEM-F4, GEM-F6, DS-F4, GRK-F9*

**A2 (must-fix):** Fix RS-008 dependency: change from RS-007 to RS-005. Writing validation rules require the ledger schema, not verified entries. This unblocks RS-008 earlier in the dependency chain.
*Sources: OAI-F1, DS-F2*

**A3 (must-fix):** Tighten vague acceptance criteria to be strictly binary:
- RS-002: scope output includes ≥1 inclusion and ≥1 exclusion; handoff has `research_plan` with sub-question skeleton
- RS-009: research status updated with `degradation_note` field; handoff `quality_ceiling_reason` set
- RS-012: scope output includes `vault_coverage` with note/source counts; Planning receives `skip_queries` or equivalent
- RS-013: output includes `overall_confidence` object with score (0-1), rationale, and driver list
*Sources: OAI-F12, DS-F8, GRK-F14*

**A4 (should-fix):** Add RS-005 as explicit dependency for RS-007 (supersede mechanism defined in RS-005).
*Sources: OAI-F2, DS-F2*

**A5 (should-fix):** Add RS-012 as explicit dependency for RS-003. The action plan intends vault-aware scoping before Planning; the task dependency should enforce this.
*Sources: GRK-F5*

**A6 (should-fix):** Fix 19→18 task count in action plan overview text. RS-005b was folded into RS-005; spec count is a historical artifact.
*Sources: OAI-F16, GRK-F4*

**A7 (should-fix):** Clarify runner vs model computation boundary. Specify that content_hash, handoff byte measurement, and 8KB overflow detection are runner-side (Pattern 1). Token overlap for RS-007 needs an explicit algorithm definition.
*Sources: OAI-F19, OAI-F13*

**A8 (should-fix):** Add partial telemetry writes to RS-009 (failure mode) and RS-011 (escalation) for dispatches that terminate before RS-015.
*Sources: GEM-F8*

**A9 (should-fix):** Strengthen milestone success criteria with inter-stage contract requirements: "stage N output validates against schema; stage N+1 accepts without repair."
*Sources: OAI-F21, GRK-F19*

**A10 (defer):** Add activation criteria for M6 (MCP). E.g., "after 5+ dispatches with >20% ToolLimited sources."
*Sources: GRK-F11*

**A11 (defer):** Add telemetry schema definition to RS-001 or RS-005 to align cross-stage counters early. Low urgency — stages can be aligned during implementation.
*Sources: OAI-F18*

### Considered and Declined

- **OAI-F1 (split RS-008 into spec vs execution):** `overkill` — Rules and enforcement are a single unit. Changing the dependency (A2) achieves the same unblocking without creating two synchronized tasks.
- **DS-F6 (RS-011 risk to High):** `constraint` — Escalation framework is defined by CTB-016; researcher maps to its 4 gate types. Medium reflects implementation risk, not framework design risk.
- **OAI-F11 (RS-005 risk to medium):** `constraint` — Low implementation risk is accurate. Blast radius is mitigated by foundational position (errors caught early). Risk rating reflects difficulty, not impact.
- **GRK-F12 (RS-003/RS-004 risk to medium-high):** `overkill` — Iteration budget (Pattern 4) already accounts for calibration. Medium is appropriate for prompt engineering work.
- **OAI-F3 (add RS-004 as explicit dep for RS-013):** `constraint` — Transitively covered: RS-013 → RS-006 → RS-004. Adding explicit dep adds noise without value.
- **OAI-F17 (stage registry/manifest task):** `overkill` — SKILL.md procedure defines stage names and order. Dispatch runner consumes CTB-016 schema. A separate machine-readable manifest adds complexity for V1 without clear consumer.
- **DS-F1 (RS-009 depends on RS-007):** `incorrect` — RS-009 handles ingestion-time failures (during Research Loop), which precede Verification. No dependency on RS-007.
- **GRK-F6 (RS-014 dep on RS-007 questionable):** `incorrect` — Writing needs the verified ledger. Pipeline: Synthesis → Verification → Writing. RS-014 correctly depends on RS-007.
- **GRK-F16 (E2E integration test task RS-019):** `out-of-scope` — Milestone end-to-end success criteria serve this purpose. Formal eval harness is A10 in spec (deferred).