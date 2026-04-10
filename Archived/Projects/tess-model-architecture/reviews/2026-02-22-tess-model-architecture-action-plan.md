---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-model-architecture/action-plan.md
artifact_type: action-plan
artifact_hash: 54d4963a
prompt_hash: 3b1113ed
base_ref: null
project: tess-model-architecture
domain: software
skill_origin: peer-review
created: 2026-02-22
updated: 2026-02-22
reviewers:
  - openai/gpt-5.2
  - google/gemini-3-pro-preview
  - deepseek/deepseek-reasoner
  - xai/grok-4-1-fast-reasoning
  - perplexity/sonar-reasoning-pro (external — operator-conducted)
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
    latency_ms: 60553
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 60291
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 72660
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 34251
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-action-plan-grok.json
  perplexity:
    http_status: external
    latency_ms: null
    attempts: null
    raw_json: null
    note: Operator-conducted review via Perplexity Pro, delivered as structured text
tags:
  - review
  - peer-review
---

# Peer Review: Tess Model Architecture — Action Plan

**Artifact:** Projects/tess-model-architecture/action-plan.md (+ companion tasks.md)
**Mode:** Full
**Reviewed:** 2026-02-22
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning, Perplexity Sonar Reasoning Pro (operator-conducted)
**Review prompt:** Structured review covering coverage, dependency correctness, risk calibration, AC quality, milestone gates, parallel execution, and feasibility, with unverifiable claim flagging.

---

## OpenAI (GPT-5.2)

- [F1] [STRENGTH] Overall coverage is strong and maps cleanly to the described dual critical path (routing + persona) converging on config (TMA-008), then integration (TMA-009) and cost validation (TMA-010b).

- [F2] [SIGNIFICANT] Coverage gap: no explicit task for "tooling/observability & logging" needed to measure routing correctness, latency SLOs, cache hit rate, and contract compliance. Fix: Add TMA-013 "Instrumentation & metrics."

- [F3] [SIGNIFICANT] Coverage gap: no explicit task to define and implement the "human-clock vs machine-clock" classifier/trigger mechanism and test set. Fix: Expand TMA-001 AC to require explicit classification mechanism + test cases, or add dedicated task.

- [F4] [SIGNIFICANT] Coverage gap: no explicit security/privacy review for vault-based state sync and "no shared in-gateway memory." Fix: Add AC to TMA-009 requiring canary-based session isolation verification and log redaction policy.

- [F5] [MINOR] No spec-to-plan trace matrix ensuring every requirement is represented.

- [F6] [SIGNIFICANT] TMA-010a depends on TMA-002, but API format + cache_control could be probed earlier in parallel with routing PoC. Fix: Allow TMA-010a to start after minimal gateway bring-up, parallel with TMA-002.

- [F7] [SIGNIFICANT] TMA-007 depends on TMA-005, but harness development could start earlier; only execution needs memory budget inputs. Fix: Split TMA-007 into 007a (build harness, no deps) and 007b (execute + report, depends TMA-005).

- [F8] [MINOR] TMA-009 practically depends on TMA-004 (Limited Mode protocol) but doesn't list it. Fix: Add TMA-004 as dependency of TMA-008 or TMA-009.

- [F9] [MINOR] TMA-011 prompt compression could begin with model-agnostic techniques before TMA-006 completes.

- [F10] [SIGNIFICANT] TMA-008 is marked "Medium" risk but is a high-leverage convergence point. Fix: Raise to High.

- [F11] [MINOR] TMA-004 risk ambiguity: "Medium" effort risk vs "High" product risk (safety/availability protocol).

- [F12] [MINOR] TMA-010a may be Critical if uncached cost is unacceptable.

- [F13] [SIGNIFICANT] Several AC are not strictly binary: TMA-006 lacks pass/fail thresholds per dimension; TMA-002/TMA-009 use "operational"/"working" without defining pass criteria. Fix: Add explicit thresholds and test case counts.

- [F14] [MINOR] TMA-007 "thermal behavior" has no pass/fail criteria.

- [F15] [MINOR] TMA-010b "representative traffic" undefined.

- [F16] [STRENGTH] Many AC are concrete and artifact-based.

- [F17] [STRENGTH] Milestone 1 go/no-go gate appropriately strict.

- [F18] [SIGNIFICANT] Memory budget (TMA-005) not explicitly listed as hard precondition to Milestone 2. Fix: Add TMA-005 gate condition.

- [F19] [MINOR] Milestone 2 has no explicit go/no-go exit gate. Fix: Add MC pass rates + prompt compression gates.

- [F20] [STRENGTH] Phase grouping mostly efficient.

- [F21] [SIGNIFICANT] Missed parallelization: TMA-010a and TMA-007 harness building.

- [F22] [SIGNIFICANT] TMA-002 scope is large for a single task. Fix: Split into 002a (baseline + bug verification), 002b (two-agent routing validation), 002c (optional single-agent experiment).

- [F23] [MINOR] TMA-006 sample size may be too small. Fix: Define test suite by category rather than raw count.

- [F24] [MINOR] TMA-012 should include a single command/script that prints all pinned versions.

- [F25–F29] [SIGNIFICANT] UNVERIFIABLE CLAIMS: F16 bugs, OpenClaw versions, Pattern 4 reference, cost statistics, model/quantization specifics.

---

## Google (Gemini 3 Pro Preview)

- [F1] [SIGNIFICANT] Missing dependency: TMA-008 should depend on TMA-004 (Limited Mode Protocol). Fallback chains in config are defined by the protocol.

- [F2] [SIGNIFICANT] Discrepancy in peer review finding absorption — A7, A9, A10 unaccounted for in the plan's absorption table.

- [F3] [MINOR] TMA-005 includes "80B promotion" headroom check — scope creep beyond the 30B architecture.

- [F4] [SIGNIFICANT] UNVERIFIABLE CLAIM: Future software versions and models.

- [F5] [SIGNIFICANT] UNVERIFIABLE CLAIM: Internal documentation references (Pattern 4, estimation-calibration.md).

---

## DeepSeek (V3.2-Thinking)

- [F1] [SIGNIFICANT] Missing caching middleware implementation task. If caching is unavailable and operator chooses middleware path, no task exists to build it. Fix: Add conditional TMA-013.

- [F2] [MINOR] No explicit task for two-agent implementation beyond PoC.

- [F3] [STRENGTH] Comprehensive absorption of peer-review items.

- [F4] [MINOR] TMA-007 may also need routing (TMA-002) as dependency.

- [F5] [SIGNIFICANT] TMA-009 depends only on TMA-002 and TMA-008, missing TMA-011 (compressed prompt needed for integration).

- [F6] [STRENGTH] Critical path clearly identified.

- [F7] [MINOR] TMA-010a risk may be overstated (research task, reversible).

- [F8] [STRENGTH] TMA-002 correctly Critical.

- [F9] [SIGNIFICANT] TMA-006 AC lacks binary test for "neither model passes all hard gates" — architecture invalidation threshold undefined.

- [F10] [MINOR] TMA-007 "thermal behavior" not binary.

- [F11] [STRENGTH] Most ACs are binary.

- [F12] [SIGNIFICANT] Milestone 1 gate missing memory budget (TMA-005) validation. Fix: Add "TMA-005 shows ≥15GB free, no swapping."

- [F13] [STRENGTH] Gate conditions well-defined and tied to empirical results.

- [F14] [MINOR] Phase 1A/1B already marked "start immediately" — parallelization is fine.

- [F15] [STRENGTH] Calendar-critical TMA-006 flagged and scheduled early.

- [F16] [SIGNIFICANT] TMA-002 may be too large. Fix: Split into 002a (bug validation) and 002b (routing mechanism validation).

- [F17] [MINOR] TMA-007 scope appropriate but high-risk.

- [F18] [STRENGTH] Iteration budgets realistic.

- UNVERIFIABLE CLAIMS: F16 bugs, OpenClaw versions, Pattern 4, spec references.

---

## Grok (grok-4-1-fast-reasoning)

- [F1] [SIGNIFICANT] UNVERIFIABLE CLAIM: OpenClaw versions (v2026.2.17, v2026.2.21), `modelByChannel`, F16 bugs. Fix: Add version verification step before TMA-002.

- [F2] [SIGNIFICANT] UNVERIFIABLE CLAIM: Cost projections without source data. Fix: Extract §11 assumptions into TMA-010a/b AC.

- [F3] [SIGNIFICANT] UNVERIFIABLE CLAIM: Model names and quantization specifics. Fix: Add pre-task model availability check.

- [F4] [CRITICAL] Coverage gap: no dedicated vault-based state sync validation task beyond TMA-009 AC mention. Fix: Add AC to TMA-002 + create TMA-013 for dedicated vault sync benchmark.

- [F5] [CRITICAL] TMA-008 depends only on TMA-002/010a/011, but config can't be production-ready without TMA-007 (local MC pass) and quantization decision. Fix: Add TMA-007 as TMA-008 dependency.

- [F6] [SIGNIFICANT] TMA-010a dependency on TMA-002 is artificially serial. Fix: Parallel with TMA-002.

- [F7] [MINOR] TMA-001 risk "high" overstated for a writing task. Fix: Downgrade to medium.

- [F8] [SIGNIFICANT] TMA-002 AC "simpler working path selected" is subjective, not binary. Fix: Define "simpler" criteria in TMA-001.

- [F9] [MINOR] TMA-011 "no degradation" lacks quantifiable threshold.

- [F10] [MINOR] Dependency graph omits Phase 1A independent tasks (TMA-003/004/012).

- [F11] [SIGNIFICANT] TMA-007 is over-scoped for a single task. Fix: Split into 007a (harness), 007b (MC-1–5), 007c (MC-6 adversarial).

- [F12] [STRENGTH] Milestone gates robust.

- [F13] [STRENGTH] Peer review integration comprehensive.

- [F14] [STRENGTH] AC generally binary.

Grok STRENGTH ratio: 4 STRENGTHs / 14 findings = 29%. Issue ratio: 71%. Calibration effective.

---

## Perplexity (Sonar Reasoning Pro — operator-conducted)

*This review was conducted externally by the operator via Perplexity Pro and delivered as structured text. Finding IDs assigned by Opus during synthesis.*

### Must-fix

- [PPLX-MF1] [SIGNIFICANT] Milestone 1 gate under-specifies "routing PoC passes" (TMA-002). "Evidence" could be just happy-path calls. Fix: Add minimum test matrix (persona vs mechanic paths, Limited Mode invocation, error responses), log expectations, and explicit "reject" condition.

- [PPLX-MF2] [SIGNIFICANT] Limited Mode behavior not tied tightly enough into TMA-002 and TMA-009. TMA-002 doesn't exercise Limited Mode flows; TMA-009 AC described at milestone level, not per-task. Fix: TMA-002 must include one end-to-end Limited Mode scenario. TMA-009 must have binary AC for Limited Mode SLOs and A8 obligations.

- [PPLX-MF3] [SIGNIFICANT] TMA-006 AC not explicit enough for architecture gate. No quantitative pass/fail thresholds, no minimum runs, no inter-operator consistency method. Fix: Enumerate PC tests, specify thresholds (100% on hard gates over Y sessions), define how judgment is recorded.

- [PPLX-MF4] [SIGNIFICANT] Cache/cost-path decision not fully wired into Milestone 1 gating. Go/no-go only mentions "API incompatibility," not "operator hasn't approved uncached cost model." Fix: Add to gate: "If caching unavailable, updated cost model explicitly approved by operator."

- [PPLX-MF5] [SIGNIFICANT] TMA-007 benchmark harness gating not operationalized. "Gates future changes" has no defined procedure. Fix: TMA-007 AC must include documented CLI/script, gate procedure (how to run, pass criteria), and policy note for future changes.

- [PPLX-MF6] [SIGNIFICANT] Latency SLO measurement (TMA-009) not fully binary. No sample size, traffic conditions, or pass/fail rule defined. Fix: Define sample size (≥N requests per path), measurement method, and pass/fail rule (p95 under threshold for two consecutive runs).

### Should-fix

- [PPLX-SF1] [SIGNIFICANT] TMA-008 doesn't explicitly depend on TMA-006's decision record (model mix), only on TMA-011.

- [PPLX-SF2] [SIGNIFICANT] Persona eval scheduling needs multi-session planning and acknowledgment that findings may feed back into TMA-001/TMA-004.

- [PPLX-SF3] [SIGNIFICANT] Review items absorbed into tasks lack explicit AC bullets — only narrative references. Higher risk of partial implementation.

- [PPLX-SF4] [SIGNIFICANT] Dependency graph omits "soft" dependencies (TMA-012 pinning before TMA-010b measurement, config freeze during cost window).

- [PPLX-SF5] [SIGNIFICANT] Inter-agent delegation scenarios not explicit. No test matrix for persona → mechanic → persona handback, mechanic failure mid-tool, Limited Mode interactions with delegation.

### Consider

- [PPLX-C1] Treat TMA-012 as cross-cutting readiness, not just writing. Dry-run rollback before integration.

- [PPLX-C2] Create operator checklist artifact for go/no-go decisions.

- [PPLX-C3] Add failure playbooks for each high-risk task.

### Affirmed

- [PPLX-A1] [STRENGTH] Milestone sequencing and dual critical path design.
- [PPLX-A2] [STRENGTH] Milestone 1 focus on critical unknowns before build.
- [PPLX-A3] [STRENGTH] Calendar-critical acknowledgment of TMA-006.
- [PPLX-A4] [STRENGTH] Integration of peer-review should-fixes into core tasks.
- [PPLX-A5] [STRENGTH] Re-runnable benchmark harness and iteration budgeting.

---

## Synthesis

### Consensus Findings

**CF1. TMA-010a should run parallel with TMA-002, not after it (4/5 reviewers)**
OAI-F6 (SIGNIFICANT), OAI-F21 (SIGNIFICANT), GRK-F6 (SIGNIFICANT), DS implicit (noted API probe reversibility). Perplexity doesn't explicitly address this but its MF4 implicitly supports earlier caching validation.
The API/caching probe needs only a minimal gateway setup, not a validated routing PoC. Serializing on TMA-002 adds the entire PoC duration to the critical path unnecessarily.

**CF2. TMA-002 is over-scoped for a single task (4/5 reviewers)**
OAI-F22 (SIGNIFICANT), DS-F16 (SIGNIFICANT), GRK-F11 implicit (similar scope concern for TMA-007), PPLX-MF1 (SIGNIFICANT — "passes" under-specified, implies scope needs tightening).
TMA-002 bundles bug verification, two-agent validation, single-agent prototype, mixed-provider validation, and potentially modelByChannel testing. Multiple reviewers recommend splitting.

**CF3. TMA-006 acceptance criteria need explicit quantitative thresholds (4/5 reviewers)**
OAI-F13 (SIGNIFICANT), DS-F9 (SIGNIFICANT), PPLX-MF3 (SIGNIFICANT), GRK-F8 implicit (subjective AC concern extends to persona eval).
The architecture invalidation gate depends on TMA-006 but "5–10 interactions" lacks defined pass/fail thresholds per PC dimension, minimum qualifying case counts, and recording methodology.

**CF4. Milestone 1 gate missing memory budget validation (3/5 reviewers)**
OAI-F18 (SIGNIFICANT), DS-F12 (SIGNIFICANT), GRK-F5 (CRITICAL — config can't be production-ready without MC pass).
TMA-005 is a success criterion but not explicitly a hard precondition for Milestone 2. If memory headroom is insufficient, the local model is nonviable.

**CF5. TMA-008 missing dependency on TMA-004 Limited Mode protocol (3/5 reviewers)**
GEM-F1 (SIGNIFICANT), OAI-F8 (MINOR), PPLX-MF2 (implicit — Limited Mode not wired into routing/integration). The production config includes fallback chains whose logic is defined in TMA-004. Config drafted without the protocol risks drift.

**CF6. Limited Mode must be exercised during PoC and integration, not just documented (3/5 reviewers)**
PPLX-MF2 (SIGNIFICANT), OAI-F3 (SIGNIFICANT — routing classifier mechanism), PPLX-MF6 (SIGNIFICANT — latency SLOs not binary enough for Limited Mode).
TMA-002 acceptance criteria don't require Limited Mode scenarios. TMA-009 mentions Limited Mode at milestone level but lacks binary per-task AC.

**CF7. TMA-007 should be split or given iteration budget (3/5 reviewers)**
OAI-F7 (SIGNIFICANT — split harness build from execution), GRK-F11 (SIGNIFICANT — split into 007a/b/c), DS-F17 (MINOR — scope appropriate but high-risk).
Harness development has no dependencies; only execution needs TMA-005 results.

**CF8. Caching cost-path decision not fully wired into Milestone 1 gate (2/5 reviewers)**
PPLX-MF4 (SIGNIFICANT), OAI-F12 (MINOR — TMA-010a may be Critical if uncached is no-go).
The go/no-go gate mentions "API incompatibility" but not "operator hasn't approved uncached cost model."

**CF9. Dual critical path and milestone structure is correct (5/5 reviewers)**
OAI-F1/F17/F20 (STRENGTH), GEM (affirmed), DS-F6/F8/F13 (STRENGTH), GRK-F12 (STRENGTH), PPLX-A1/A2 (STRENGTH).
Universal endorsement of the milestone structure, convergence point design, and go/no-go gating approach.

**CF10. Acceptance criteria are generally strong and binary (4/5 reviewers)**
OAI-F16 (STRENGTH), DS-F11 (STRENGTH), GRK-F14 (STRENGTH), PPLX-A4/A5 (STRENGTH).
Multiple reviewers commend the artifact-based, threshold-driven AC pattern while noting specific exceptions (TMA-006, TMA-007 thermal, TMA-002 "simpler").

### Unique Findings

**UF1. Missing instrumentation/observability task (OAI-F2, SIGNIFICANT)**
OpenAI uniquely identified that TMA-009 and TMA-010b require measurements (latency, cache hit rate, token counts) but no task guarantees instrumentation exists. Genuine insight: measurement infrastructure must precede measurement tasks.

**UF2. Missing security/privacy review for vault state sync (OAI-F4, SIGNIFICANT)**
OpenAI flagged that vault-based isolation is a security property, not just a design property. Canary-based session isolation verification and log redaction policy aren't covered. Grok-F4 (CRITICAL) raised a similar point but focused on dedicated validation rather than security framing. Genuine insight for both.

**UF3. TMA-008 should depend on TMA-007 results (GRK-F5, CRITICAL)**
Grok uniquely argued that config can't be production-ready without knowing the local model passes MC and which quantization to use. The config draft would need revision if TMA-007 reveals MC failures. Genuine insight: the dependency graph treats TMA-007 and TMA-008 as parallel in Milestone 2, but TMA-008's quantization/KV cache settings depend on TMA-007's results.

**UF4. Missing conditional caching middleware task (DS-F1, SIGNIFICANT)**
DeepSeek identified that if TMA-010a reveals caching is unavailable and the operator chooses the middleware path, no task exists to build it. Genuine insight: the decision point has four options but only one (accept uncached costs) has a clear task path.

**UF5. TMA-009 missing TMA-011 dependency (DS-F5, SIGNIFICANT)**
DeepSeek noted integration testing should use the compressed prompt (TMA-011 output), not the uncompressed original. Without this dependency, integration tests may validate the wrong system prompt.

**UF6. Persona eval feedback loop to earlier tasks (PPLX-SF2, SIGNIFICANT)**
Perplexity uniquely flagged that TMA-006 findings may require updates to TMA-001 (routing assumptions) and TMA-004 (Limited Mode prompt constraints). No other reviewer identified this feedback path.

**UF7. Delegation test matrix missing (PPLX-SF5, SIGNIFICANT)**
Perplexity identified that inter-agent delegation scenarios (persona → mechanic → persona handback, mechanic failure mid-tool) lack explicit test cases.

**UF8. "Simpler" working path criterion is subjective (GRK-F8, SIGNIFICANT)**
Grok uniquely flagged that TMA-002's AC includes "simpler working path selected" without defining "simpler." Genuine insight: this is a critical-path decision point with no objective criteria.

**UF9. Review item A7/A9/A10 absorption gap (GEM-F2, SIGNIFICANT)**
Gemini uniquely identified that the should-fix integration table accounts for A8, A11, A12, A13 but doesn't address A7 (R14 severity), A9 (U1 reclassification), or A10 (U12 explicit + interim label). These were applied to the spec, not the plan — but the plan's table implies it absorbed all should-fix items.

### Contradictions

**C1. TMA-010a risk level: High vs Medium**
- **Keep High (OAI, GRK, PPLX):** Caching is a cost model prerequisite; failure to validate early could invalidate the architecture's economic rationale.
- **Downgrade to Medium (DS-F7):** Research task, reversible, failure leads to updated cost model rather than irreversible damage.
- **Recommendation:** Keep High. While the task itself is reversible, a negative finding triggers an operator decision gate that can pause the entire project. The risk is in the downstream impact, not the task effort.

**C2. TMA-007 dependency on TMA-002**
- **Add dependency (DS-F4):** Benchmarking needs a working routing mechanism to simulate machine-clock tasks.
- **No dependency needed (others):** TMA-007 benchmarks the local model directly (Ollama), not through the gateway routing layer. Tool calls can be simulated without gateway routing.
- **Recommendation:** No dependency needed. The benchmark harness tests the local model's capabilities (JSON validity, latency, MC compliance) using direct Ollama API calls, not routed gateway traffic. The routing layer is tested in TMA-009. DS-F4 conflates model benchmarking with routing validation.

**C3. TMA-008 dependency on TMA-007**
- **Add dependency (GRK-F5, CRITICAL):** Config requires quantization decision and MC pass confirmation from TMA-007.
- **No dependency needed (others):** Config can be drafted as a "best-available" document and refined after benchmarks.
- **Recommendation:** Add TMA-007 as a soft dependency — TMA-008 can start drafting with provisional values, but cannot be finalized until TMA-007 confirms quantization and MC compliance. This adds TMA-007 to the convergence point without blocking early config work.

### Action Items

**Must-fix (consensus or critical):**

**A1.** Parallelize TMA-010a with TMA-002.
*Source:* CF1 — 4/5 reviewers.
*Action:* Change TMA-010a dependency from TMA-002 to TMA-001 (or "minimal gateway bring-up"). Allow it to run concurrently with TMA-002. Update dependency graph.

**A2.** Tighten TMA-002 scope and AC.
*Source:* CF2 — 4/5 reviewers; PPLX-MF1 (gate under-specified); GRK-F8 (subjective "simpler").
*Action:* Keep as one task (splitting creates coordination overhead on a PoC), but add explicit minimum test matrix to AC: (a) pure persona message routed to cloud, (b) pure mechanical task routed to local, (c) mixed-task delegation or fallback, (d) one Limited Mode scenario (enter, enforce, return), (e) session isolation canary. Define "simpler path selected" as: "Selection justified against criteria table in TMA-001 (agent count, config params, known bug exposure)." Remove "If v2026.2.21 available" conditional from AC (keep it in description as optional upside).

**A3.** Define explicit pass/fail thresholds for TMA-006.
*Source:* CF3 — 4/5 reviewers.
*Action:* Update TMA-006 AC: "Hard gates (PC-1 through PC-4): 100% pass across all qualifying test cases (minimum 5 qualifying cases per dimension). Soft targets (PT-1 through PT-4): scored but not blocking. Architecture invalidation: if any hard gate fails on both Haiku and Sonnet across ≥3 qualifying cases, raise invalidation flag. Scores and transcripts recorded in structured format."

**A4.** Add memory budget to Milestone 1 go/no-go gate.
*Source:* CF4 — 3/5 reviewers.
*Action:* Add to Milestone 1 gate: "TMA-005 confirms stable operation at 64K context under defined load shape with no swap activity and ≥15GB free headroom; otherwise revise context window or load shape before Milestone 2."

**A5.** Add TMA-004 as dependency of TMA-008.
*Source:* CF5 — 3/5 reviewers.
*Action:* Add TMA-004 to TMA-008 depends_on. Config must reflect the Limited Mode protocol.

**A6.** Wire Limited Mode into TMA-002 and TMA-009 AC.
*Source:* CF6 — 3/5 reviewers.
*Action:* TMA-002 AC: add "One Limited Mode scenario exercised: API failure simulated → local fallback activated → degradation banner sent → tool allowlist enforced → auto-recovery on restore." TMA-009 AC: add explicit binary checks — "No Limited Mode response uses disallowed tools (YES/NO). Duration cap enforced in N/N test runs (YES/NO). State sync verified during Limited Mode (YES/NO)."

**A7.** Add caching decision to Milestone 1 gate.
*Source:* CF8 — 2/5 reviewers.
*Action:* Add to Milestone 1 gate: "If caching is unavailable or degraded, updated cost model produced and explicitly approved by operator before proceeding to Milestone 2."

**A8.** Split TMA-007 into build and execute phases.
*Source:* CF7 — 3/5 reviewers.
*Action:* Split: TMA-007a (build harness — no dependencies, can start in Phase 1A) and TMA-007b (execute + report — depends on TMA-005). This shortens the path to Milestone 2 by parallelizing harness development.

**Should-fix (significant but not blocking):**

**A9.** Add TMA-007 as dependency of TMA-008 finalization.
*Source:* UF3 — GRK-F5 (CRITICAL), C3 resolution.
*Action:* Add TMA-007b to TMA-008 depends_on. Config quantization and KV cache settings require benchmark results. TMA-008 can start drafting with provisional values but cannot finalize without TMA-007b.

**A10.** Add Milestone 2 exit gate.
*Source:* OAI-F19 (MINOR).
*Action:* Add Milestone 2 gate: "MC-1 through MC-6 pass rates meet thresholds. Prompt token count within target range. PC hard gates unchanged after compression. Config smoke-tested per route."

**A11.** Add TMA-011 as dependency of TMA-009.
*Source:* UF5 — DS-F5 (SIGNIFICANT).
*Action:* Integration tests should use the compressed prompt. Add TMA-011 to TMA-009 depends_on.

**A12.** Operationalize TMA-007 harness as gate procedure.
*Source:* PPLX-MF5.
*Action:* TMA-007b AC: "Harness executable via single CLI command. Exit code 0 = all MC gates pass, non-zero = failure with failing gate identified. Documented procedure: when to run (any model/quant change), how to interpret results, what to do on failure."

**A13.** Define latency SLO measurement methodology for TMA-009.
*Source:* PPLX-MF6.
*Action:* TMA-009 AC: "Latency measured over ≥20 requests per path (cloud, local, Limited Mode). Method: timestamp at gateway entry and response completion. Pass: p95 <10s cloud, <15s Limited Mode across all samples."

**A14.** Clarify A7/A9/A10 absorption in the plan.
*Source:* UF9 — GEM-F2.
*Action:* A7 (R14 severity), A9 (U1 reclassification), A10 (U12 explicit + interim label) were applied directly to the specification, not the plan. Add a note to the should-fix integration table: "A7, A9, A10: applied to specification.md during SPECIFY phase — not plan-level items."

**Defer (minor or speculative):**

**A15.** Add instrumentation/observability task.
*Source:* UF1 — OAI-F2. Defer: valid but belongs in deployment/ops planning, not architecture plan. Integration tests can use ad-hoc logging initially.

**A16.** Add spec-to-plan trace matrix.
*Source:* OAI-F5. Defer: useful for audit but adds overhead during PLAN phase. Can be generated at TASK phase.

**A17.** Add conditional caching middleware task.
*Source:* UF4 — DS-F1. Defer: the decision point after TMA-010a will determine whether this task is needed. Adding a conditional task now is speculative.

**A18.** Add delegation test matrix.
*Source:* UF7 — PPLX-SF5. Defer to TMA-001 (routing spec should define delegation scenarios, which TMA-002 then tests).

**A19.** Create operator checklist artifact for go/no-go decisions.
*Source:* PPLX-C2. Defer: nice-to-have structure, not blocking.

**A20.** Add failure playbooks for high-risk tasks.
*Source:* PPLX-C3. Defer: the Decision Points table already captures primary alternatives. Full playbooks add overhead.

**A21.** Downgrade TMA-001 risk to Medium.
*Source:* GRK-F7. Defer: risk level is about downstream impact (gates TMA-002 which is Critical), not task effort.

**A22.** Update dependency graph to show all Phase 1A tasks.
*Source:* GRK-F10. Defer: cosmetic. The text already says "start immediately."

### Considered and Declined

**OAI-F3** (missing human-clock/machine-clock classifier task): Declined — `constraint`. The routing mechanism is channel-based (Telegram channel binding → tess-voice, background → tess-mechanic), not an intent classifier. The "two clocks" model routes by origin channel, not by complexity assessment. TMA-001 defines this; no classifier is needed.

**DS-F4** (TMA-007 needs TMA-002 dependency): Declined — `incorrect`. Benchmark harness tests local model capabilities via direct Ollama API, not through gateway routing. See C2 resolution.

**DS-F7** (TMA-010a risk should be Medium): Declined — `constraint`. See C1 resolution.

**GEM-F3** (80B promotion is scope creep): Declined — `incorrect`. The specification explicitly includes 80B promotion as a gated future path (§8.1, §10). TMA-005 measuring headroom is in-scope per spec.

**OAI-F9** (split TMA-011 into model-agnostic compression + model-specific validation): Declined — `overkill`. Compression techniques are inherently model-dependent (what can be cut depends on what the model needs). Splitting adds coordination overhead for a single-session task.

**PPLX-C1** (TMA-012 as cross-cutting readiness): Declined — `overkill`. Environment pinning is a document; rollback testing is covered by TMA-009 integration scenarios.
