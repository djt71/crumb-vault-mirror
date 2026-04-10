# Tess v2 Action Plan — Consolidated Peer Review Synthesis

**Date:** 2026-03-28  
**Reviewers:** Claude Opus 4.6, Gemini, DeepSeek, ChatGPT (GPT-5), Perplexity  
**Documents reviewed:** Action Plan (2026-03-28-r1), Tasks (2026-03-28-r1)

---

## Verdicts

| Reviewer | Verdict |
|---|---|
| Claude Opus 4.6 | Ready to execute, two corrections before starting |
| Gemini | Ready for Phase 0 |
| DeepSeek | Needs revisions (credential mgmt, scaffold scope, failover, conflict implementation) |
| ChatGPT (GPT-5) | Needs revisions (branch realism, runtime failover, measurement rigor, prompt architecture) |
| Perplexity | Ready for execution with caveats (Phase 3 over-gating, thin vertical slice, decision cadence) |

**Consensus:** Plan is executable for Phase 0 and the parallel evaluations immediately. Gaps matter for Phase 3-4, which are gated by evaluation results. The architecture is validated; the action plan successfully translates it into phased, gated work with concrete acceptance criteria. One targeted revision pass before Phase 3 begins addresses all material concerns.

---

## Convergence Map — What Multiple Reviewers Flagged

| Finding | Opus | Gemini | DeepSeek | GPT-5 | Perplexity | Count |
|---|---|---|---|---|---|---|
| **Joint Hermes + LLM integration test missing** | ✓ | | ✓ | | | 2 |
| **Local model runtime failover task missing** | | | ✓ | ✓ | | 2 |
| **Branch-specific success criteria for NO-GO paths** | | | | ✓ | ✓ | 2 |
| **TV2-031 scaffold too thin for migration** | | | ✓ | | ✓ | 2 |
| **Phase 3 over-gated on both evals** | | | | ✓ | ✓ | 2 |
| **Resource contention during parallel evals** | | ✓ | ✓ | | ✓ | 3 |
| **"Thin vertical slice" / hello-world contract test** | ✓ | | | | ✓ | 2 |
| **Risk labels reflect implementation difficulty, not decision impact** | | | | | ✓ | 1 |
| **Scenario walkthroughs for high-risk design tasks** | | | | ✓ | ✓ | 2 |
| **Migration measurement rigor (sample sizes, error classes)** | | | | ✓ | | 1 |
| **Decision paralysis / tie-break rules for marginal results** | | | | | ✓ | 1 |

---

## Tier 1: Address Before Phase 3

These items should be resolved before entering Phase 3 (Architecture Design). They don't block Phase 0 or the evaluations.

### 1. Branch-Specific Success Criteria for NO-GO Paths
**Flagged by:** ChatGPT, Perplexity

The plan says NO-GO redirects rather than blocks, but downstream success criteria (TV2-038: ≥70% Tier 1+2 local routing; TV2-039: <$50/month) are written for the preferred architecture only. If a gate fires NO-GO, those targets become undefined.

**Action:** Add branch-specific criteria:
- **Both GO (preferred):** ≥70% Tier 1+2, <$50/month
- **Hermes NO-GO:** Same cost targets possible. Add "custom orchestration engine passes integration test" as Phase 3 gate. Phase 3 gains ~3-5 tasks for custom orchestration development.
- **LLM NO-GO:** Local handles Tier 1 only (heartbeats, filing). Tier 2-3 via OpenRouter. Cost target rises to <$100/month. Local routing target drops to ≥30%.
- **Dual NO-GO:** OpenClaw + OpenRouter. Cost ~$100-150/month. No local routing target. Add a "Pivot Design" week before Phase 3 to avoid building a Frankenstein system.

Alternatively, lighter-weight: add a note that if a NO-GO fires, the first task on that branch is "revise Phase 3-6 success criteria and task scope for the selected architecture."

### 2. Local Model Runtime Failover as Explicit Task
**Flagged by:** DeepSeek, ChatGPT (also flagged by all reviewers in spec review round)

The plan has evaluation tasks and calibration tasks but no dedicated design for what happens when the local model server is unavailable in production. This has been flagged in every review document across both rounds.

**Action:** Add TV2-041 (or fold into Phase 3) "Local model availability monitoring and runtime failover design" with acceptance criteria:
- Health check frequency and timeout defined
- Automatic restart policy (attempt once, then fallback)
- Fallback mode: Tier 1+2 decisions route to OpenRouter during outage
- Fallback duration limit: if down >4h, alert Danny, reduce to critical services only
- Cost impact of 24-hour outage modeled
- LLM server included in 72-hour soak test monitoring

### 3. Joint Hermes + Local Model Integration Test
**Flagged by:** Opus, DeepSeek

Phase 1 tests Hermes. Phase 2 tests local models. No task tests them working together end-to-end — Hermes dispatching a request to the local Qwen3.5 27B server and receiving structured output back.

**Action:** Add a lightweight integration task after both GO gates but before Phase 3: "Run one complete dispatch cycle through Hermes with the selected local model. Verify: Hermes sends request, model returns structured output, Hermes parses response correctly." This can be a half-day task. If it fails, the integration gap is discovered before Phase 3 design begins.

### 4. TV2-031 Scaffold Needs Implementation Scope
**Flagged by:** DeepSeek, Perplexity

Phase 3 produces design documents. Phase 4 starts migrating services. But between "design" and "migrate," someone has to build the staging/promotion engine, the contract runner, the dispatch envelope validator, and the Ralph loop controller. TV2-031 ("Initialize external repo + orchestration scaffold") is a skeleton.

**Action:** Either expand TV2-031 into multiple tasks covering the core orchestration engine implementation, or add explicit implementation tasks between Phase 3 design and Phase 4 migration:
- TV2-031a: Initialize repo + project structure
- TV2-031b: Implement contract runner + Ralph loop controller
- TV2-031c: Implement staging/promotion engine (from TV2-022 design)
- TV2-031d: Implement dispatch envelope validator (from TV2-023 design)

These must exist and pass before migration begins.

### 5. Scenario Walkthroughs for High-Risk Design Tasks
**Flagged by:** ChatGPT, Perplexity

TV2-017 (state machine), TV2-018 (escalation), TV2-022 (staging/promotion) can all pass with a plausible-looking design document that hasn't been pressure-tested. Acceptance criteria are "document exists" rather than "design validated."

**Action:** Add scenario walkthrough requirements to high-risk task acceptance criteria:
- **TV2-017:** "State diagram validated against 3 named scenarios: mid-loop escalation, contract timeout during promotion, concurrent contract targeting same path."
- **TV2-018:** "Three-gate mechanism validated against: confidently-wrong local model decision, credential-touching task, first-instance task class. Each scenario traced through all three gates."
- **TV2-022:** "Promotion lifecycle validated against: two contracts targeting same file, interrupted promotion mid-write, promotion after canonical file changed since dispatch."

---

## Tier 2: Refine During Execution

These items are real but can be addressed during Phase 0-2 execution without blocking progress.

### 6. Resource Contention During Parallel Evaluations
**Flagged by:** Gemini, DeepSeek, Perplexity

Running heavy benchmarks (TV2-010, context ceiling tests) while the 72-hour soak test is active will contaminate throughput data.

**Action:** Add note to benchmark tasks: "Benchmarks run with soak test paused or with soak test load documented as baseline noise. Context ceiling tests run in isolation."

### 7. TV2-012 (MLX Comparison) Should Be Non-Optional
**Flagged by:** Opus, Perplexity

The M3 Ultra's unified memory architecture is specifically optimized for MLX. MLX may outperform llama.cpp by 20-30%. Skipping this comparison means model selection and token budget decisions are made on suboptimal data.

**Action:** Make TV2-012 non-optional. Keep it scoped to one model (Qwen3.5 27B Q4). Skip condition: "Skip only if llama.cpp exceeds ALL throughput thresholds by >50%."

### 8. TV2-021 Dependency Split
**Flagged by:** Opus

TV2-021 (service interfaces) depends on TV2-001 + TV2-008 + TV2-016 + TV2-019 — meaning service interfaces can't start until deep into Phase 3.

**Action:** Split into:
- **TV2-021a:** Draft service interfaces from migration inventory (depends on TV2-001 only). Covers: inputs, outputs, monitoring surfaces, overlay requirements, rollback procedures, idempotency requirements.
- **TV2-021b:** Finalize with contract templates (depends on TV2-021a + TV2-019). Adds: contract template per service, executor assignment, token budget estimates.

This lets draft interfaces proceed during evaluations.

### 9. Idempotency and Replay Semantics in Service Interfaces
**Flagged by:** ChatGPT

Duplicate sends, duplicate classifications, and overlapping runs are the dangerous failures in scheduled services. These belong in service interface definitions, not as an implied later concern.

**Action:** Add to TV2-021 acceptance criteria: "Each service interface includes idempotency requirements: run ID convention, dedup semantics, overlapping-run prevention. Reference existing autonomous-ops patterns."

### 10. Dependency Graph Corrections
**Flagged by:** ChatGPT, Opus

- TV2-005 and TV2-007 connect Hermes to local LLM but don't depend on TV2-002 (build llama.cpp + download models)
- TV2-012 (MLX comparison) doesn't depend on TV2-009 (model setup)
- TV2-023 (system prompt architecture) should depend on TV2-013 (orchestration tests with production-length prompts) — prompt design should be informed by Test 8 results

**Action:** Add missing dependencies:
- TV2-005 → add TV2-002 as dependency
- TV2-012 → add TV2-009 as dependency
- TV2-023 → add TV2-013 as input dependency

### 11. Soak Test Should Include One Real Service
**Flagged by:** DeepSeek

The soak test workload is synthetic. Running heartbeats on Hermes during the 72-hour test would catch scheduling and resource leak issues that synthetic load won't.

**Action:** Add to TV2-007 workload: "Include heartbeat service running on Hermes (if TV2-005 setup permits). Track scheduling accuracy and resource impact alongside synthetic load."

### 12. Credential Management Risk Elevation
**Flagged by:** DeepSeek

TV2-024 is marked "low" risk with vague acceptance criteria. For a 24/7 system with multiple executors needing OAuth tokens that expire, this is at least medium risk.

**Action:** Elevate TV2-024 to medium risk. Expand acceptance criteria: "Credential store design includes: retrieval mechanism for orchestrator and executors, env var injection per Ralph loop session, automated refresh for Google OAuth, mid-contract expiry handling (fail to dead-letter vs. attempt refresh), audit logging for credential usage (type only, never the credential)."

### 13. Automatic Rollback in High-Risk Migration Tasks
**Flagged by:** DeepSeek

TV2-036 and TV2-037 say "rollback tested" but don't specify automatic rollback triggers during parallel operation per spec §16 ("automatic rollback on two consecutive failed runs").

**Action:** Add to TV2-036 and TV2-037 acceptance criteria: "Automatic rollback triggers on two consecutive failed runs during parallel operation. Rollback verified to restore OpenClaw service continuity within 30 minutes."

### 14. Decision Tie-Break Rules
**Flagged by:** Perplexity

When results are ambiguous (GLM is 1.7x faster, not 2x; Hermes scores 3.4 average, just below 3.5), the plan doesn't specify how to avoid decision paralysis.

**Action:** Add a tie-break rule to decision tasks: "When quantitative results fall within 10% of a threshold, bias toward simplicity (single model over dual, existing platform over new). Document the margin and the reasoning."

### 15. Migration Inventory Revalidation at Cutover
**Flagged by:** Perplexity

The migration inventory (TV2-001) is created at the start. By the time you reach TV2-038 (validation), months may have passed and new services may have been added to OpenClaw.

**Action:** Add to TV2-038 acceptance criteria: "Migration inventory revalidated against running launchd services. Any services added since TV2-001 are cataloged and either migrated or explicitly deferred."

### 16. Production Serving Configuration Artifact
**Flagged by:** Perplexity

The plan never explicitly captures "production serving configuration" (ports, concurrency, context ceiling, per-request limits) as a durable artifact. It's implicit in benchmark runs.

**Action:** Add to TV2-016 (LLM go/no-go) or as a Phase 3 task: "Freeze serving profile v1: port, concurrency limit, context ceiling, per-request timeout, quant selection. Document as configuration artifact in vault."

---

## Tier 3: Note for Implementation

These are valid observations that don't require plan changes but should be kept in mind during execution.

| Item | Source | Note |
|---|---|---|
| Evaluation fatigue — temptation to skim tests | Perplexity | The evaluation phases are heavy on scorecards. If slow, resist skimming to get to "fun" architecture work. |
| Hermes evaluated against unvalidated model | DeepSeek | Evaluate Hermes initially with known-good model (OpenAI Codex) or note that most Hermes criteria are model-independent. |
| TV2-004 quality battery is a living artifact | Opus | Expected outputs will need calibration after first model run. Treat as iterative, not one-shot. |
| TV2-022 should be time-boxed | Opus | If staging/promotion design doesn't converge in 2 sessions, split into core mechanics + refinement. |
| Phase 3 tasks carry multiple Tier-2 items | Perplexity | Under schedule pressure, easy to mark "done" when central piece is finished but sub-items are fuzzy. Track sub-items explicitly. |
| OpenClaw NO-GO fallback is non-trivial | Perplexity, ChatGPT | Building custom orchestration on OpenClaw is a serious fork, not a detour. Budget accordingly if it fires. |
| Model selection may need iteration | Perplexity | TV2-015/016 are single-shot decisions, but pathological failures may surface later. Leave room to revisit. |
| KV cache pressure in context ceiling test | Gemini | Test under realistic memory conditions, not bare machine. |
| Thermal throttling during soak tests | Gemini | Include 60-second cooldown between context length tests. Monitor temps during soak. |
| Credential isolation during evaluation | Gemini | Use test Telegram bot and test API keys where possible during Phase 1. |

---

## Novel Insights Across Reviews

| Insight | Source | Value |
|---|---|---|
| **"Thin vertical slice" — hello-world contract + Ralph loop** | Perplexity, Opus | A tiny proof-of-concept testing the contract → Ralph loop → staging → promotion pipeline on a toy task, independent of Hermes/LLM decisions, would de-risk the architecture before it carries real services. This is the "minimum viable autonomous Tess" concept. |
| **Evaluation fatigue as a named failure mode** | Perplexity | Phases 1-2 are test-heavy. If slow, the temptation to cut corners to reach architecture work undermines the evidence the gates depend on. Name it so you can watch for it. |
| **Risk labels should track decision impact, not implementation difficulty** | Perplexity | TV2-007 (soak test) is "low risk" to execute but high-impact on the project direction. TV2-012 (MLX) is "low risk" but might change your entire serving stack. Relabeling prevents deprioritizing high-leverage experiments. |
| **Platform-agnostic Phase 3 work can start earlier** | Perplexity, ChatGPT | Contract schema v1, state machine shapes, and staging directory conventions are independent of "Hermes vs OpenClaw" and "Qwen vs GLM." Starting these during evaluations prevents idle time without violating evaluation discipline. |

---

## Final Consolidated Action Items

Ordered by when they matter:

### Fix Now (Before Starting Phase 0)
1. Add TV2-002 as dependency for TV2-005 (Hermes needs local LLM built)
2. Add TV2-009 as dependency for TV2-012 (MLX needs model setup)
3. Make TV2-012 (MLX comparison) non-optional

### Fix Before Phase 3
4. Add joint Hermes + LLM integration test after both GO gates
5. Add local model runtime failover as explicit Phase 3 task
6. Add branch-specific success criteria for NO-GO paths
7. Expand TV2-031 into implementation tasks (not just scaffold)
8. Add scenario walkthroughs to TV2-017, TV2-018, TV2-022 acceptance criteria
9. Split TV2-021 into draft (Phase 0 dependency) and finalize (Phase 3 dependency)
10. Add TV2-023 dependency on TV2-013 (prompt design informed by Test 8)

### Refine During Execution
11. Resource isolation note on benchmark tasks
12. Idempotency requirements in TV2-021 service interfaces
13. Elevate TV2-024 (credentials) to medium risk with expanded criteria
14. Automatic rollback triggers in TV2-036, TV2-037
15. Decision tie-break rules in go/no-go tasks
16. Migration inventory revalidation in TV2-038
17. Include heartbeats in soak test workload
18. Freeze production serving configuration as artifact

---

## Verdict Summary

The plan is ready to execute. Phase 0 is clean, low-risk, and produces immediate value (migration inventory, working benchmark harness). The 3 dependency fixes should be made now. The remaining items should be addressed before Phase 3 begins — which is when they actually matter.

The biggest strategic insight from the review process: identify the **minimum viable autonomous Tess** (~12 tasks to first autonomous service) as an explicit intermediate milestone. A "hello-world contract + Ralph loop" thin vertical slice proves the architecture works before it carries real services. This prevents the 40-task, 4-6 month plan from becoming the "love of architecture" pattern — building infrastructure that never ships value.

Start M1 Monday.
