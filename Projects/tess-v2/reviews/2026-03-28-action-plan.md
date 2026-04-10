---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/action-plan.md
artifact_type: action-plan
artifact_hash: 880c7b3c
prompt_hash: fdd61766
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-03-28
updated: 2026-03-28
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
    latency_ms: 67198
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-action-plan-openai.json
  google:
    http_status: 200
    latency_ms: 69931
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-action-plan-google.json
  deepseek:
    http_status: 200
    latency_ms: 111563
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-action-plan-deepseek.json
  grok:
    http_status: 200
    latency_ms: 27451
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-action-plan-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Tess v2 Action Plan

**Artifact:** Projects/tess-v2/design/action-plan.md
**Mode:** full
**Reviewed:** 2026-03-28
**Reviewers:** OpenAI GPT-5.4, Google Gemini 3.1 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Action plan + task decomposition review — spec coverage, dependency correctness, task sizing, risk calibration, acceptance criteria, gate design, sequencing (7 evaluation dimensions)

---

## OpenAI (gpt-5.4)

- [F1]
- [Severity]: STRENGTH
- [Finding]: The action plan tracks the specification’s macro-structure well: foundation → parallel platform/model evaluations → gated architecture → staged migration → validation/cutover.
- [Why]: This preserves the spec’s core sequencing logic, especially AD-002 (parallel operation), the Phase 1/2 parallelism, and the requirement that architecture design wait for evaluation outcomes.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: The plan incorporates all major architectural themes from the summary: vault authority, contract-based execution, Ralph loops, evaluator/executor separation, staging→promotion, risk-based escalation, observability, and service-by-service migration.
- [Why]: This indicates high fidelity to the specification rather than a superficial task list.
- [Fix]: None.

- [F3]
- [Severity]: STRENGTH
- [Finding]: Tier-2 peer review coverage is explicit and traceable, including a mapping table tying each review item to a task.
- [Why]: This makes review completeness auditable and reduces the chance that external review findings are lost during decomposition.
- [Fix]: None.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Success metrics from the specification are only partially decomposed. Cost target is reflected, but the “70–90% of decisions at zero marginal cost” success criterion is not operationalized into any task or acceptance criterion.
- [Why]: Without a measurement task, one of the project’s core value propositions may never be validated at cutover.
- [Fix]: Add a task or acceptance criteria under observability/cutover to measure routing distribution by tier and verify the zero-marginal-cost decision percentage during validation.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: AD-001 / C1 “vault is authoritative, no split-brain” is present conceptually but lacks a dedicated verification task or acceptance criterion during migration/cutover.
- [Why]: This is a foundational invariant. Migration is exactly where split-brain risk appears, especially under parallel operation.
- [Fix]: Add explicit acceptance criteria in M5/M6 for authoritative-path enforcement, canonical-path ownership checks, and a reconciliation test proving no writes bypass staging/promotion into canonical vault paths.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: AD-006 “mechanical enforcement over behavioral compliance” is represented in architecture themes, but there is no concrete implementation or validation task for enforcement mechanisms beyond schema/locks.
- [Why]: If this remains only a design principle, the system may still depend on prompt obedience in production.
- [Fix]: Add a task for enforcement controls such as path allowlists, promotion validators, schema checks, contract completeness checks, and executor sandbox constraints, with binary tests.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Migration continuity dependency XD-025 is noted, but continuity safeguards are not decomposed into explicit tasks beyond generic parallel runs.
- [Why]: “Service continuity during migration” is a cross-project dependency with operational implications; it should produce concrete handoff/rollback/runbook tasks rather than remain ambient.
- [Fix]: Add a migration readiness/runbook task before TV2-032 covering monitoring handoff, rollback contacts, continuity criteria, and operational windows.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-021 service interface definitions depend on TV2-001 and TV2-008, but not on TV2-016 or TV2-019/TV2-020, despite interface shape likely depending on chosen model stack, contract schema, and Ralph loop return semantics.
- [Why]: Service interfaces risk being defined before key execution envelope assumptions are fixed.
- [Fix]: Make TV2-021 depend at least on TV2-019 and likely TV2-020; consider also TV2-016 if interface constraints differ by single vs dual model stack.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-018 depends only on TV2-016, but the escalation design is also platform-sensitive because Hermes GO/NO-GO changes orchestration substrate and fallback path.
- [Why]: Escalation gates often interact with platform capabilities, scheduling, alerting, and integration affordances. Designing without TV2-008 may force rework.
- [Fix]: Add TV2-008 as a dependency for TV2-018.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-023 system prompt architecture depends only on TV2-016, not TV2-008.
- [Why]: Prompt composition and overlay injection may be constrained by the orchestration platform’s prompt plumbing, message role support, system prompt layering, or Telegram/Hermes adapter behavior.
- [Fix]: Add TV2-008 as a dependency to TV2-023, or explicitly justify why prompt architecture is platform-independent.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-024 credential management depends only on TV2-008, not on the risk/escalation design in TV2-018.
- [Why]: Credential handling is tightly coupled to AD-009: credential/destructive/external-comms tasks must always escalate regardless of confidence. Credential design should reflect that policy.
- [Fix]: Add TV2-018 as a dependency for TV2-024, and include an acceptance criterion that privileged operations are mechanically forced through escalation.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-031 “Initialize external repo + orchestration scaffold” depends on TV2-008 and TV2-019, but not on TV2-020/TV2-021/TV2-022/TV2-025, which define major structural requirements for the scaffold.
- [Why]: Early scaffold implementation may crystallize assumptions before execution loop, interfaces, staging model, and observability are finalized.
- [Fix]: Either narrow TV2-031 to repo bootstrap only, or add dependencies on the architectural tasks needed to shape the scaffold.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-033 through TV2-037 are chained strictly sequentially, even though the action plan text says migration follows low-risk-first and each service does configure → parallel run → compare → cut over. Some medium/high-risk services may be independent enough for partial overlap once the scaffold and architecture are stable.
- [Why]: Over-serialization can unnecessarily lengthen Phase 4 and reduce flexibility.
- [Fix]: Replace full linear chaining with dependency on shared prerequisites plus service-specific readiness, allowing overlapping parallel runs where continuity risk permits.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: There is no explicit task for rollback mechanism implementation/testing before service migrations, despite rollback being required at cutover and implicitly important throughout migration.
- [Why]: Rollback should not first appear at TV2-039. Each service migration should have a tested rollback path.
- [Fix]: Add an architecture or migration task for rollback design and per-service rollback validation, and include rollback drill criteria in TV2-032–TV2-037.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: The plan does not explicitly decompose model-routing policy for the three-tier system after the LLM evaluation decision.
- [Why]: The spec’s solution depends on operational routing across local routine, local thinking, and frontier escalation. A single/dual model decision alone does not fully specify tier routing behavior.
- [Fix]: Add an architecture task for tier routing policy, including triggers, latency/cost tradeoffs, and observability of routing decisions.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: The benchmark/evaluation layer has good coverage, but there is no explicit task to validate the frontier fallback path if Local LLM is NO-GO.
- [Why]: The spec says NO-GO redirects rather than stops. A redirection path that is never tested remains a project risk.
- [Fix]: Add a conditional validation task for OpenRouter/frontier routing path connectivity, cost accounting, and policy enforcement when TV2-016 is NO-GO.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: Similarly, there is no explicit validation task for the Hermes NO-GO fallback path beyond documentation.
- [Why]: If Hermes fails, the project pivots to OpenClaw/custom orchestration. That path should have a minimum viable implementation/feasibility checkpoint, not just a note.
- [Fix]: Add a conditional fallback task after TV2-008 to stand up and verify the non-Hermes orchestration substrate enough to de-risk Phase 3.

- [F18]
- [Severity]: MINOR
- [Finding]: TV2-016 depends on TV2-013 and TV2-015, but not directly on TV2-010/TV2-011. It is indirectly covered through TV2-015, but the dependency graph obscures that benchmark pass/fail is a direct input to the go/no-go.
- [Why]: Direct dependencies improve graph readability and reduce accidental decision-making on incomplete evidence.
- [Fix]: Add direct dependencies from TV2-016 to TV2-010 and TV2-011, or state clearly that TV2-015 subsumes benchmark review.

- [F19]
- [Severity]: MINOR
- [Finding]: TV2-025 observability design depends on TV2-021 only, but observability also relates strongly to TV2-017/TV2-018/TV2-022 and policy tasks like TV2-026/029/030.
- [Why]: As written, the task may under-scope telemetry for state transitions, escalation decisions, and promotion events.
- [Fix]: Expand TV2-025 acceptance criteria to require instrumentation surfaces for lifecycle state changes, escalation gates, staging/promotion actions, and cost/routing metrics.

- [F20]
- [Severity]: MINOR
- [Finding]: TV2-030 value density metric depends on TV2-025 only.
- [Why]: The metric likely also depends on service taxonomy/interfaces from TV2-021 and possibly cost attribution from TV2-028.
- [Fix]: Add dependencies on TV2-021 and TV2-028 or clarify that those inputs are embedded in TV2-025.

- [F21]
- [Severity]: SIGNIFICANT
- [Finding]: Several acceptance criteria are not fully binary despite being strong overall. Examples: “output matches or exceeds OpenClaw baseline,” “quality ≥ OpenClaw baseline,” and “items classified and routed correctly” lack measurement rules.
- [Why]: These are likely to create subjective completion disputes during migration.
- [Fix]: Define concrete comparison metrics per service: precision/recall, delivery timeliness, template completeness, user approval score, missed-item count, and acceptable variance thresholds.

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-006’s acceptance criterion “No criterion below 3/5 required for GO” is useful, but the relationship between per-criterion scores, average score, and qualitative fail conditions is still ambiguous relative to TV2-008’s “Average ≥3.5/5.”
- [Why]: Averages can mask hard failures in critical categories; decision criteria should be deterministic.
- [Fix]: State explicit GO rules: e.g., average ≥3.5, no critical criterion <3, mandatory pass on A1/A7, soak thresholds met, and no unresolved blocker in scheduling/delivery.

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-007’s soak-test thresholds are specific, but “moderate load” appears only in the action plan and is not operationalized in task acceptance criteria.
- [Why]: Reproducibility and comparability depend on a defined workload profile.
- [Fix]: Define the exact soak profile: cron cadence, Telegram frequency, model switch cadence, concurrent sessions, expected message volume.

- [F24]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-010/011 acceptance criteria mention `viable` thresholds, but those thresholds are not defined in the decomposition.
- [Why]: This prevents binary evaluation.
- [Fix]: Inline the viability thresholds into the tasks or reference a concrete benchmark rubric artifact created by TV2-003/004.

- [F25]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-012 is labeled optional/skip, but the task table does not represent conditionality cleanly beyond one sentence in acceptance criteria.
- [Why]: Optional tasks can confuse scheduling and completion reporting.
- [Fix]: Mark TV2-012 explicitly as conditional with a precondition field or split into “decide if MLX comparison needed” and “run MLX comparison if needed.”

- [F26]
- [Severity]: SIGNIFICANT
- [Finding]: TV2-017 through TV2-025 are substantial design tasks, and some may be too large for “atomic” decomposition, especially TV2-017, TV2-018, and TV2-021.
- [Why]: Large design tasks are harder to estimate, review, and complete unambiguously.
- [Fix]: Consider splitting:
  - TV2-017 into lifecycle states/transitions, escalation integration, immutability/promotion semantics
  - TV2-018 into gate definitions/schema, calibration method, validation plan
  - TV2-021 into one task per service family or a generic interface framework plus service-specific instantiations

- [F27]
- [Severity]: MINOR
- [Finding]: TV2-028 risk is marked low.
- [Why]: Cost model errors can materially undermine project viability given strict monthly targets and potential fallback to paid routing.
- [Fix]: Raise TV2-028 to medium risk, especially because it influences budget enforcement and migration safety.

- [F28]
- [Severity]: MINOR
- [Finding]: TV2-030 risk is marked low.
- [Why]: The metric itself is low-risk technically, but as a health signal for “silent stagnation detection,” poor definition could weaken operational governance.
- [Fix]: Keeping low is defensible, but consider medium if it will influence alerts or strategic decisions.

- [F29]
- [Severity]: SIGNIFICANT
- [Finding]: The gate design correctly states that NO-GO redirects rather than kills the project, but the dependency graph still presents M4 as gated on both go/no-go tasks without modeling alternate downstream work for each branch.
- [Why]: This can obscure the execution plan in fallback scenarios and make branch-specific deliverables invisible.
- [Fix]: Add branch-specific subtasks or notes under M4/M5 for Hermes-GO vs Hermes-NO-GO and Local-LLM-GO vs Local-LLM-NO-GO pathways.

- [F30]
- [Severity]: MINOR
- [Finding]: Phase 0 tasks TV2-002, TV2-003, and TV2-004 are independent in the table, though in practice TV2-003 may benefit from test-battery assumptions from TV2-004.
- [Why]: Not wrong, but the practical handoff between harness and battery may cause rework.
- [Fix]: Either add a soft dependency from TV2-003 to a draft of TV2-004 or specify that TV2-003 produces a pluggable harness consumed by TV2-004.

- [F31]
- [Severity]: STRENGTH
- [Finding]: The acceptance criteria are generally stronger than average for an action plan: many tasks specify concrete outputs, runtime durations, threshold values, and document artifacts.
- [Why]: This improves executability and reviewability.
- [Fix]: None.

- [F32]
- [Severity]: STRENGTH
- [Finding]: The migration ordering is sensible and aligned to the spec: low-risk services first, critical/user-visible services last, with parallel-run validation before cutover.
- [Why]: This directly supports operational safety and continuity.
- [Fix]: None.

- [F33]
- [Severity]: STRENGTH
- [Finding]: The decomposition preserves important architectural constraints from the summary, including “NOT Ollama,” evaluator/executor separation, and no direct writes to canonical vault paths.
- [Why]: These are easy constraints to lose in planning, and retaining them reduces architectural drift.
- [Fix]: None.

- [F34]
- [Severity]: SIGNIFICANT
- [Finding]: There is no explicit task for validating AD-007 evaluator-executor separation in implementation, beyond design references in TV2-018 and schema/lifecycle tasks.
- [Why]: This is a core safety property. It should be tested, not just designed.
- [Fix]: Add acceptance criteria or a validation task proving executors cannot self-promote/self-certify and that Tess performs independent evaluation before promotion.

- [F35]
- [Severity]: SIGNIFICANT
- [Finding]: There is no explicit task for promotion collision testing despite C9 and TV2-022 mentioning write-lock tables.
- [Why]: Collision handling is one of the most failure-prone parts of a staging→promotion architecture.
- [Fix]: Add a validation task or acceptance criterion for concurrent promotion attempts, lock acquisition failure behavior, and recovery after interrupted promotions.

- [F36]
- [Severity]: SIGNIFICANT
- [Finding]: The plan lacks an explicit migration/data reconciliation task comparing legacy OpenClaw state with the new system before decommission.
- [Why]: Parallel run output comparison is good, but state reconciliation is needed to prove no hidden drift in queues, state files, or pending work before shutdown.
- [Fix]: Add a pre-decommission reconciliation task covering outstanding jobs, state artifacts, credentials/config parity, and canonical vault consistency.

- [F37]
- [Severity]: MINOR
- [Finding]: “Danny confirms quality” in TV2-037 and “Danny approves” in TV2-039 are valid governance checks, but they are subjective unless paired with objective review inputs.
- [Why]: Human signoff should be informed by a bounded rubric.
- [Fix]: Add a short approval checklist or scorecard for Danny-facing acceptance.

- [F38]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: References to “Qwen3.5 27B,” “GLM-4.7-Flash,” “Qwen3.5 35B MoE,” and “Qwen3-coder 30B” are specific model/version claims that cannot be independently confirmed from the provided materials.
- [Why]: Version/model naming drift is common and can break reproducibility or procurement.
- [Fix]: Verify exact upstream model identifiers and record canonical source links or artifact hashes in the plan.

- [F39]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “llama.cpp” support for the required “correct tool-calling chat template” and OpenAI-compatible serving behavior is assumed but not independently verifiable from the provided artifact.
- [Why]: Tool-calling compatibility is implementation-sensitive and may vary by model/template.
- [Fix]: Record the exact llama.cpp revision/build target and the tested chat template specification in TV2-002/009 outputs.

- [F40]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: The calibration statistic “0.04x ratio when NO-GO fired” from estimation-calibration.md cannot be independently verified here.
- [Why]: This statistic influences planning assumptions about pivots and timeline compression.
- [Fix]: Cite the exact calibration source entry or summarize the empirical basis in the action plan.

- [F41]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Cross-project dependency IDs “XD-024” and “XD-025” cannot be independently validated from the provided artifact.
- [Why]: Dependency IDs should be grounded in an accessible registry to avoid mismatch.
- [Fix]: Include a link/path anchor and exact dependency record title for each ID.

- [F42]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “11 criteria from §12.1,” “21 prompts across 5 categories,” and “9 Tier-2 items from external review round 2” are numeric claims that cannot be independently confirmed from the provided excerpts.
- [Why]: The plan relies on these counts for completeness assertions.
- [Fix]: Add appendices or references listing the exact criteria/prompts/review items to make completeness checkable.

Overall assessment: strong decomposition with good structural fidelity, but it needs tighter branch modeling for fallback paths, stronger validation of core invariants (vault authority, evaluator separation, promotion collision handling), and several dependency/acceptance-criteria refinements before it is fully execution-ready.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the **tess-v2 Action Plan** and **Task Decomposition**. 

The artifact exhibits a high degree of maturity, particularly in its integration of peer-review feedback, fallback-oriented gating, and operational policy mapping. However, there are notable issues regarding strict linear dependency chaining during migration, under-calibrated risk on state mutations, and ungrounded model version references.

### Unverifiable Claims

- [ID] F1
- [Severity] SIGNIFICANT
- [Finding] UNVERIFIABLE CLAIM: Software version references `Qwen3.5 27B`, `Qwen3.5 35B MoE`, and `Qwen3-coder 30B` in TV2-002, TV2-009, TV2-010, TV2-012, and TV2-013.
- [Why] The current verified public releases of the open-weight Qwen model family are in the 1.x and 2.x (e.g., 2.5) series. Qwen3 and Qwen3.5 series do not currently exist in the verifiable public domain.
- [Fix] Verify if these intend to reference Qwen2.5 models (e.g., Qwen2.5-Coder-32B) and update the action plan to match available GGUF release artifacts.

- [ID] F2
- [Severity] SIGNIFICANT
- [Finding] UNVERIFIABLE CLAIM: Software version reference `GLM-4.7-Flash` in TV2-002, TV2-011, and TV2-014.
- [Why] Zhipu AI's current model generation includes GLM-4 and GLM-4-Flash. Version "4.7" cannot be independently verified via their public catalog or documentation.
- [Fix] Correct to `GLM-4-Flash` or verify the exact version numbering used in the targeted model repository.

- [ID] F3
- [Severity] SIGNIFICANT
- [Finding] UNVERIFIABLE CLAIM: Platform references `Hermes Agent` and `OpenClaw` throughout Phase 1 and Phase 4.
- [Why] While "Hermes" is a widely known model fine-tune family by Nous Research, a standalone orchestration platform software specifically named "Hermes Agent" (capable of Telegram/local LLM API integration out-of-the-box) cannot be verified as standard public software. "OpenClaw" similarly appears to be a proprietary/internal element of the Crumb OS.
- [Fix] If these are internal/custom systems, explicitly document them as such. If they are external open-source tools, include the GitHub repository URL or verifiable package reference.

---

### Architecture & Execution Evaluation

- [ID] F4
- [Severity] STRENGTH
- [Finding] Non-blocking, redirective gate structure for M2 (TV2-008) and M3 (TV2-016).
- [Why] Treating go/no-go evaluation gates as architectural pivots (with documented fallbacks like OpenRouter) rather than project-killing blockers dramatically de-risks the timeline. It ensures the Phase 3 architecture design can adapt fluidly.

- [ID] F5
- [Severity] SIGNIFICANT
- [Finding] TV2-018 (Confidence-aware escalation) acceptance criteria omit the strict constraints mandated by AD-009.
- [Why] The specification for AD-009 dictates: *"Credential/destructive/external-comms tasks always escalate regardless of model confidence."* While TV2-018 mentions a "risk policy," it leaves these three non-negotiable triggers out of the validation test plan, risking them being treated as dynamic rather than hardcoded rules.
- [Fix] Update TV2-018 Acceptance Criteria to explicitly require validation tests confirming that credential, destructive, and external-comms tasks deterministically force escalation.

- [ID] F6
- [Severity] SIGNIFICANT
- [Finding] Phase 4 migration tasks (TV2-032 through TV2-037) are chained in a strict, linear sequence (e.g., TV2-034 relies on TV2-033 finishing its 48-hour soak).
- [Why] The spec mandates sequence by risk ("low-risk first, critical last"), but strict end-to-end dependency chaining forces a rigid waterfall. Independent services within the same risk tier (e.g., feed-intel and daily attention) cannot run their parallel validation periods simultaneously, needlessly bloating the migration timeline.
- [Fix] Group dependencies by risk tier. Allow tasks within the same tier (e.g., TV2-034 and TV2-035) to be executed concurrently, gating the *start* of the high-risk tier only on the *completion* of the medium-risk tier.

- [ID] F7
- [Severity] SIGNIFICANT
- [Finding] Risk level for TV2-022 (Staging/promotion lifecycle design) is underestimated as "Medium."
- [Why] TV2-022 defines the write-lock table, hash-based conflict detection, and canonical vault promotion. According to C8/C9 and AD-001, the vault is authoritative and must suffer zero promotion collisions. A concurrency or race condition flaw in this exact task causes split-brain data corruption.
- [Fix] Escalate the risk level of TV2-022 to High.

- [ID] F8
- [Severity] MINOR
- [Finding] Missing logic dependency: TV2-018 (Confidence-aware escalation) does not depend on TV2-017 (State machine design).
- [Why] The escalation mechanism is a functional branch/transition within the Ralph loop's state machine. Designing the three-gate hybrid escalation requires the overarching loop boundaries to be established first.
- [Fix] Add TV2-017 to the "Depends On" column for TV2-018.

- [ID] F9
- [Severity] MINOR
- [Finding] Ambiguous, qualitative acceptance criteria in migration tasks (TV2-032, TV2-033, TV2-035, TV2-036).
- [Why] The criteria stipulate that the "Output matches or exceeds OpenClaw baseline." The term "exceeds" is highly subjective and not mechanically testable, particularly for binary/routine services like heartbeats or vault gardening. 
- [Fix] Replace "exceeds" with strictly deterministic metrics (e.g., "Zero dropped signals, classification accuracy ≥ baseline, execution latency ≤ baseline").

- [ID] F10
- [Severity] MINOR
- [Finding] TV2-021 (Service interface definitions) batches the architectural design for all 6 distinct migrating services into a single task.
- [Why] Grouping multiple independent API/interface designs into one item creates a bloated task that violates atomic decomposition. It will likely stall in an "In Progress" state while waiting for distinct service edge cases to be resolved.
- [Fix] Decompose TV2-021 into sub-tasks aligned with the migration tiers (e.g., TV2-021a for Low-Risk interfaces, TV2-021b for Medium-Risk).

---

## DeepSeek (deepseek-reasoner)

## Structured Review of Tess v2 Action Plan & Task Decomposition

### 1. Spec Coverage
**STRENGTH**: The plan comprehensively decomposes the core specification (r2). All 9 Architectural Decisions (AD-001 to AD-009) are addressed across tasks (e.g., AD-008/AD-009 in TV2-022/TV2-018). All constraints (C1-C9) are reflected. The phases align with §12-18. The 9 Tier-2 peer review items are explicitly mapped to tasks.

**SIGNIFICANT**:
- **F1**: [SIGNIFICANT] [Finding]: Specification §5 (Architectural Decisions) and §3 (System Map) are covered, but the action plan lacks explicit tasks for **documenting the final system map** (components, data flows) post-architecture design. The spec emphasizes this as a key artifact.
- [Why]: A system map is crucial for understanding and communicating the three-tier orchestrator's structure. Its absence from the task list risks an incomplete architectural record.
- [Fix]: Add a task `TV2-XXX: Document final system map` under M4.1 (Core Architecture), depending on TV2-017/TV2-018/TV2-021. Acceptance: Diagram and narrative covering all components, data flows, and tier boundaries.

- **F2**: [SIGNIFICANT] [Finding]: The spec §18 (Observability) includes a "health digest," but the plan's observability task (TV2-025) focuses on design. There is no explicit task to **implement and integrate the health digest generator**.
- [Why]: The health digest is a key success metric and operational tool. Leaving it as only a design artifact defers its implementation, potentially making it a post-migration afterthought.
- [Fix]: Add a task `TV2-XXX: Implement health digest generator` under M5 or M6, depending on TV2-025. Acceptance: Script produces daily digest per template, integrates into monitoring.

### 2. Dependency Correctness
**STRENGTH**: Overall graph is logical. Parallel evaluation phases (M2/M3) are correctly independent. Architecture (M4) properly gated by both evaluation decisions.

**SIGNIFICANT**:
- **F3**: [SIGNIFICANT] [Finding]: **Circular dependency risk** between TV2-021 (Service Interface Definitions) and TV2-001 (Migration Inventory). TV2-021 depends on TV2-001 (logical), but TV2-001's acceptance criteria do not mandate the structured data needed by TV2-021.
- [Why]: TV2-021 requires detailed service signatures, inputs, and outputs. If TV2-001 only produces a basic catalog, TV2-021 will be blocked or require rework.
- [Fix]: Update TV2-001 acceptance criteria to include: "Inventory includes, for each service: primary trigger, input sources, output destinations, and current failure modes."

- **F4**: [SIGNIFICANT] [Finding]: **Missing dependency**: TV2-015 (Single vs. Dual Model Decision) lists TV2-010, TV2-011, TV2-013, TV2-014 as dependencies but **omits TV2-012 (MLX backend comparison)**.
- [Why]: If MLX performance is significantly better, it could influence the single/dual model decision (e.g., making a dual stack more feasible). The decision should consider all performance data.
- [Fix]: Add TV2-012 as an optional/conditional dependency for TV2-015. Or state in TV2-015's description that MLX data is considered if available.

### 3. Task Sizing
**STRENGTH**: Most tasks are well-scoped, single-domain atomic units (e.g., TV2-005 "Install Hermes"). The migration tasks (TV2-032 to TV2-037) are appropriately scoped per service.

**SIGNIFICANT**:
- **F5**: [SIGNIFICANT] [Finding]: **TV2-017 (State Machine Design)** is potentially too large. It encompasses "contract lifecycle + Ralph loop + three-gate integration," which are three major, interrelated but distinct design problems.
- [Why]: This task has "high" risk and is foundational. Combining these could lead to design bottlenecks or ambiguity in acceptance criteria (which currently mix all three).
- [Fix]: Consider decomposing into:
    - TV2-017a: Contract Lifecycle State Machine.
    - TV2-017b: Ralph Loop Integration Spec.
    - TV2-017c: Three-Gate Integration Logic.
    Maintain dependencies between them.

**MINOR**:
- **F6**: [MINOR] [Finding]: **TV2-004 (Author quality test battery)** is a research task creating 21 prompts. While scoped, its success depends on subjective "validation against at least one model," which could be lightweight.
- [Why]: Low risk, but the task's output is critical for all LLM evaluations. The acceptance criteria could be more specific to ensure quality.
- [Fix]: Enhance acceptance: "Prompts are reviewed by a second party (or automated check) for clarity, lack of bias, and adherence to category definitions."

### 4. Risk Calibration
**STRENGTH**: Risks escalate appropriately: Foundation tasks are "low," go/no-go gates are "high," and migration risk increases with service criticality.

**SIGNIFICANT**:
- **F7**: [SIGNIFICANT] [Finding]: **TV2-039 (Production Cutover Decision)** and **TV2-040 (OpenClaw Decommission)** are marked "high" risk, correctly. However, the dependency `TV2-039 -> TV2-040` creates a single point of high-risk sequential execution.
- [Why]: A failure during decommission (TV2-040) could cause service interruption. The rollback procedure, while mentioned for TV2-039, is not a separate validation task.
- [Fix]: Add a `TV2-040a: Test rollback procedure` task before TV2-039, simulating a failed cutover. This de-risks the final step.

**MINOR**:
- **F8**: [MINOR] [Finding]: Several "medium" risk tasks (e.g., TV2-009 Qwen setup, TV2-010/011 Benchmark runs) might be closer to "low" risk. They involve running established software (llama.cpp) on known hardware.
- [Why]: Over-rating risk can distort prioritization. The true risk is not failure but unexpected performance results.
- [Fix]: Reclassify TV2-009, TV2-010, TV2-011 as "low" risk. Keep "medium" for tasks with more unknowns like TV2-006 (Hermes evaluation against 11 criteria).

### 5. Acceptance Criteria Quality
**STRENGTH**: Most criteria are binary and testable (e.g., "Server responds to tool-calling requests," "Parallel run 48h. Output matches").

**SIGNIFICANT**:
- **F9**: [SIGNIFICANT] [Finding]: **TV2-006 (Evaluate Hermes against 11 criteria)** acceptance is weak: "No criterion below 3/5 required for GO." This contradicts the plan's earlier text (§12.3) and the gate logic TV2-008, which uses an *average* ≥3.5.
- [Why]: A scoring mismatch creates ambiguity. A platform could have one fatal flaw (score 1) but still average 3.5, leading to a GO decision that might be wrong.
- [Fix]: Align criteria with gate logic. Change TV2-006 acceptance to: "All criteria scored. Average ≥3.5. No *critical* criteria (list them, e.g., reliability, message delivery) below 3."

- **F10**: [SIGNIFICANT] [Finding]: **TV2-038 (Full parallel operation validation)** acceptance includes "Cost tracking active" but lacks a **quantitative target**.
- [Why]: A core project goal is cost <$50/month. Validation must check this.
- [Fix]: Add to acceptance: "Calculated pro-rated orchestration cost during parallel run is ≤ $75/month ceiling."

### 6. Gate Design
**STRENGTH**: The gate structure is excellent. Go/No-Go decisions (TV2-008, TV2-016) are data-driven, have documented fallback paths, and redirect rather than block progress.

**SIGNIFICANT**:
- **F11**: [SIGNIFICANT] [Finding]: The **decision criteria for TV2-015 (Single vs. Dual Model)** are clear ("GLM ≥ Qwen3.5 on Tier 1 AND ≥2x faster"). However, the gate **TV2-016 (Local LLM Go/No-Go)** depends on TV2-015 but its criteria ("at least one model passes BOTH benchmark AND orchestration") does not account for the *single vs. dual* outcome.
- [Why]: If the decision is "dual," but only one model passes individually, does that constitute a GO? The logic is unclear.
- [Fix]: Clarify TV2-016 logic: "GO if: (Single model selected AND it passes both bars) OR (Dual model selected AND both models pass their respective bars — e.g., GLM passes speed/benchmark, Qwen passes orchestration)."

**MINOR**:
- **F12**: [MINOR] [Finding]: The plan notes "Phases 1 and 2 run in parallel" but the **resource contention** (both using the same Mac Studio, possibly same LLM server) isn't addressed.
- [Why]: The Hermes soak test (TV2-007) and LLM benchmark (TV2-010) running concurrently could skew results (thermal throttling, memory pressure).
- [Fix]: Add a note in the schedule: "Where possible, stagger high-intensity load tests (TV2-007 soak, TV2-010 benchmark) to avoid hardware co-interference."

### 7. Sequencing
**STRENGTH**: The overall sequence (Evaluate -> Design -> Migrate) is sound. The migration order (low->high risk) per §14.2 is correctly implemented.

**SIGNIFICANT**:
- **F13**: [SIGNIFICANT] [Finding]: **TV2-024 (Credential Management Design)** depends only on TV2-008 (Hermes decision). However, its design is also heavily influenced by the **model stack decision** (TV2-016) and the **contract/service interfaces** (TV2-021).
- [Why]: Credential injection needs to work for both local (free) and frontier (paid, via OpenRouter) tiers. The mechanism may differ.
- [Fix]: Add TV2-016 and TV2-021 as dependencies for TV2-024.

**MINOR**:
- **F14**: [MINOR] [Finding]: **TV2-030 (Value Density Metric Design)** is placed under Operational Policies in M4.4 and depends on TV2-025 (Observability). This sequencing is fine, but the metric's definition is complex and may benefit from earlier conceptual validation.
- [Why]: It's a minor sequencing issue. The metric can be designed later, but its core formula could be sketched earlier.
- [Fix]: No sequence change needed. Consider adding a note: "Preliminary value density formula to be drafted during TV2-017/018."

### UNVERIFIABLE CLAIMS
**SIGNIFICANT**:
- **F15**: [SIGNIFICANT] [UNVERIFIABLE CLAIM]: References to external documents: `_system/docs/estimation-calibration.md`, `_system/docs/cross-project-deps.md`, `Solutions/ — 4 docs integrated into spec (F9–F12)`. Existence and content cannot be verified.
- **F16**: [SIGNIFICANT] [UNVERIFIABLE CLAIM]: References to external dependencies: `XD-024`, `XD-025 (tess-ops service continuity)`. Status and details cannot be verified.
- **F17**: [SIGNIFICANT] [UNVERIFIABLE CLAIM]: Specific software versions and capabilities: "Hermes Agent" functionality, "llama.cpp" tool-calling chat templates for specific models (Qwen3.5 27B, GLM-4.7-Flash), "OpenClaw" internal structure. Assumed accurate but not verified.
- **F18**: [SIGNIFICANT] [UNVERIFIABLE CLAIM]: Statistical reference: "prior: 0.04x ratio when NO-GO fired" from `estimation-calibration.md`. Cannot verify the historical data point.

---
### Summary of Findings by Severity
- **CRITICAL**: 0
- **SIGNIFICANT**: 13 (F1, F2, F3, F4, F5, F7, F9, F10, F11, F13, F15, F16, F17, F18)
- **MINOR**: 4 (F6, F8, F12, F14)
- **STRENGTH**: 4 (Spec Coverage, Dependency Correctness (overall), Gate Design, Sequencing)

**Overall Assessment**: This is a mature, well-structured action plan that faithfully translates a detailed specification into executable tasks. The primary gaps relate to fleshing out a few key artifacts (system map, health digest), tightening some acceptance criteria and decision logic, and adjusting a few dependencies. The unverifiable claims are standard for an internal project plan but should be confirmed by the team. With the suggested fixes, the plan would be highly robust.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [Severity]: CRITICAL  
  [Finding]: Action plan claims comprehensive coverage of spec §12–18 (evals, migration, success, cost, observability), but Milestone 6 success criteria include "Total orchestration cost under $50/month target (ceiling $75 during migration)", while spec summary states "$10-55/month total orchestration cost (target <$50, ceiling $75 during migration)". This is a mismatch on lower bound.  
  [Why]: Contradicts spec cost target, risking budget overrun if plan ignores $10 lower target; undermines faithful decomposition.  
  [Fix]: Update M6 success to match spec exactly: "$10-55/month (target <$50, ceiling $75)" and add tracking task for lower bound.

- [F2]  
  [Severity]: CRITICAL  
  [Finding]: Migration sequence in M5 covers only 6 specific services (heartbeats, vault gardening, feed-intel, daily attention+overnight research, email triage, morning briefing), but TV2-001 (migration inventory) is tasked to catalog "all OpenClaw cron jobs, scripts, state files, configs, credentials" without specifying these 6 as exhaustive or linking back to confirm full coverage post-inventory.  
  [Why]: Risks incomplete migration if inventory reveals more services; spec §14.2 sequence assumes full inventory drives migration, creating a logical gap.  
  [Fix]: Add post-TV2-001 task or AC to confirm exactly these 6 (or list them) as the complete migrating set, with any extras classified/replanned.

- [F3]  
  [Severity]: SIGNIFICANT  
  [Finding]: Phase 3 (M4) tasks TV2-017 to TV2-030 claim to incorporate "all 9 Tier-2 peer review items", with a mapping table, but mapping shows "Task graph dependency corrections" addressed by "this action plan (refined dependency graph)" — no specific TV2-XXX task owns it.  
  [Why]: Peer review integration is promised but one item is hand-waved to the plan itself, not executable tasks; risks unaddressed feedback if graph issues persist.  
  [Fix]: Assign "Task graph dependency corrections" to a specific task (e.g., new TV2-031-pre or audit in TV2-017) with AC like "Dependency graph visualized and validated acyclic".

- [F4]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: Specific models "Qwen3.5 27B Q4+Q6, GLM-4.7-Flash, Nemotron, Qwen3.5 35B MoE, Qwen3-coder 30B baseline" listed in TV2-002, M3, but these exact models/quants do not exist in current public repositories (as of 2024; Qwen2.5 max ~32B, no Qwen3.5 or GLM-4.7-Flash).  
  [Why]: Plan executability depends on non-existent artifacts; 2026 dates suggest speculation, but review requires flagging for verification against real GGUF ecosystem.  
  [Fix]: Flag for confirmation; add contingency in TV2-002 AC: "Use latest equivalent open models if listed unavailable (e.g., Qwen2.5-32B)".

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: "11 criteria from §12.1" for Hermes eval in TV2-006/M2.2, with pass at avg ≥3.5/5 and §12.3; spec summary does not detail these, and Hermes Agent documentation inaccessible for confirmation.  
  [Why]: Core to go/no-go (TV2-008); unverifiable risks subjective or mismatched evaluation.  
  [Fix]: Inline the 11 criteria list in TV2-006 description/AC or reference external verifiable source.

- [F6]  
  [Severity]: SIGNIFICANT  
  [Finding]: Dependencies in tasks.md show TV2-021 (service interfaces) depends on TV2-001 and TV2-008, but ignores TV2-016 (LLM decision) despite interfaces needing model stack knowledge per M4 gating.  
  [Why]: Potential premature design if LLM NO-GO changes routing (e.g., OpenRouter); violates Phase 3 gating logic.  
  [Fix]: Add TV2-016 to TV2-021 depends-on.

- [F7]  
  [Severity]: SIGNIFICANT  
  [Finding]: Tasks TV2-032–037 (migrations) have sequential dependencies (e.g., TV2-033 on TV2-032), enforcing strict low→high risk order, but no parallelism for independent services (e.g., heartbeats and vault gardening could parallel).  
  [Why]: Inflates timeline unnecessarily; spec §14.2 allows risk-based but not mandates strict serial.  
  [Fix]: Relax deps to only scaffold (TV2-031), allow parallel low-risk, then medium, etc.

- [F8]  
  [Severity]: SIGNIFICANT  
  [Finding]: Acceptance criteria for quality in migrations (e.g., TV2-032 "Output matches or exceeds OpenClaw baseline"; TV2-037 "Danny confirms quality ≥ OpenClaw") are subjective, not binary testable (no metrics/schemas).  
  [Why]: Violates "binary testable" review criterion; risks disputes or incomplete validation.  
  [Fix]: Define baselines upfront in TV2-001 (e.g., "≥95% match on sampled outputs via diff script") and automate where possible.

- [F9]  
  [Severity]: MINOR  
  [Finding]: Task sizing for TV2-001 (full inventory) and TV2-004 (author 21 prompts) are broad research tasks without subtasks or time estimates.  
  [Why]: Reduces executability; calibration notes mention pivots compress timelines, but oversized tasks hide risks.  
  [Fix]: Decompose into subtasks (e.g., TV2-001a: cron jobs, 001b: configs).

- [F10]  
  [Severity]: MINOR  
  [Finding]: Risk levels undervalue MLX comparison (TV2-012 "low risk" despite backend switch potentially affecting quality/throughput calibration).  
  [Why]: Mismatch to stakes if llama.cpp insufficient; optional status hides it.  
  [Fix]: Bump to medium; make non-optional if llama.cpp marginal.

- [F11]  
  [Severity]: MINOR  
  [Finding]: Gate design covers single NO-GO redirects but silent on dual NO-GO (both Hermes and Local LLM fail); fallback combo (OpenClaw+OpenRouter+custom) unstated.  
  [Why]: Edge scenario possible per calibration pattern; gaps coverage.  
  [Fix]: Add to TV2-008/TV2-016 docs: "Dual NO-GO → §12.4 + §13.6 hybrid fallback, Phase 3 adapts."

- [F12]  
  [Severity]: MINOR  
  [Finding]: Sequencing misses parallelism in Phase 3: Infrastructure/Operational tasks (TV2-023–030) depend loosely but could parallel with Core/Execution after gating.  
  [Why]: Optimality; gated phases drag if serial.  
  [Fix]: Visualize Phase 3 parallelism in gate diagram; loosen non-critical deps.

- [F13]  
  [Severity]: STRENGTH  
  [Finding]: Gate structure diagram accurately reflects parallel M2/M3 → serial M4+ with redirects, matching spec phases and estimation notes.  
  [Why]: Edge case of NO-GO handled as redirects (not blocks), enabling progress; verified against artifact dependency graph — no cycles.  

- [F14]  
  [Severity]: STRENGTH  
  [Finding]: Spec coverage strong on ADs/constraints: e.g., AD-007/AD-008/C8 reflected in TV2-017/018/022 (evaluator sep, staging); 9 Tier-2 items explicitly mapped/executable.  
  [Why]: Faithful decomposition verified by cross-references to §3/5/12-18; no major sections omitted (e.g., observability in TV2-025).  

- [F15]  
  [Severity]: STRENGTH  
  [Finding]: Acceptance criteria generally binary/high-quality: e.g., TV2-007 "Memory growth <20%", TV2-013 "Average ≥4.0, Test 8 <20% degradation" testable with telemetry/logs.  
  [Why]: Sufficient for most tasks; challenges like thermal cooldown in TV2-003 show thoughtfulness (breaks on Mac Studio heat).  

- [F16]
  [Severity]: STRENGTH
  [Finding]: Risk calibration matches stakes: high for go/no-go (TV2-008/016), escalating in migration (low→high), mixed in arch design.
  [Why]: Aligns with domain (research low, code/decision high); no under/over-assigned outliers beyond minor flags.

---

## Synthesis

### Consensus Findings

**1. Migration tasks over-serialized (OAI-F13, GEM-F6, GRK-F7 — 3 reviewers)**
TV2-032 through TV2-037 are chained strictly sequentially. Same-tier services (heartbeats + vault gardening; feed-intel + daily attention) could run parallel validation periods concurrently, reducing Phase 4 timeline.

**2. Migration acceptance criteria are subjective (OAI-F21, GEM-F9, GRK-F8 — 3 reviewers)**
"Output matches or exceeds OpenClaw baseline" is not binary testable. Needs concrete metrics per service: match rate, delivery timeliness, missed-item count, acceptable variance thresholds.

**3. TV2-021 missing dependencies (OAI-F8, GRK-F6, DS-F3 — 3 reviewers)**
Service interface definitions depend on TV2-001 and TV2-008, but should also depend on TV2-016 (model stack) and TV2-019 (contract schema) since interfaces must reflect the chosen execution model. TV2-001's AC also needs to produce structured service data (triggers, inputs, outputs) rich enough for TV2-021 to consume.

**4. TV2-018 missing platform dependency (OAI-F9, GEM-F8 — 2 reviewers)**
Escalation design needs both the platform decision (TV2-008) and potentially the state machine (TV2-017) as inputs, since escalation gates interact with platform capabilities and are functional branches within the state machine.

**5. Rollback testing absent (OAI-F14, DS-F7 — 2 reviewers)**
No explicit task for rollback mechanism design or per-service rollback validation. Rollback should not first appear at cutover (TV2-039).

**6. AD-009 risk policy not validated (GEM-F5, OAI-F6 — 2 reviewers)**
TV2-018 AC mentions "risk policy" but does not explicitly require validation tests confirming credential/destructive/external-comms tasks deterministically force escalation per AD-009.

**7. Vault authority / evaluator separation lacks verification (OAI-F5, OAI-F34 — 1 reviewer, 2 findings)**
AD-001 (vault authority) and AD-007 (evaluator-executor separation) are core safety properties with no dedicated validation task during migration. Migration is exactly where split-brain risk appears.

### Unique Findings

**GRK-F2 (CRITICAL): Migration completeness gap.** The plan pre-assumes exactly 6 service categories without confirming this is the exhaustive set from the inventory. TV2-001 could reveal additional services. **Genuine insight** — the inventory should close the loop back to the migration plan.

**GRK-F1 (CRITICAL): Cost target lower bound.** Claims M6 success criteria don't include the $10 lower bound. See Considered and Declined — the $10 is an estimate floor, not a target.

**DS-F11: Dual-model go/no-go logic unclear.** If TV2-015 selects dual-model but only one passes, does TV2-016 = GO? **Genuine insight** — the decision logic needs to be explicit.

**DS-F12: Resource contention.** M2 soak test and M3 benchmarks running concurrently on the same Mac Studio could skew results. **Genuine insight** — worth a scheduling note.

**OAI-F16/F17: Fallback path validation.** Neither the Hermes NO-GO nor Local LLM NO-GO fallback paths have validation tasks. **Genuine insight** — a redirection path that's never tested is a risk.

**GRK-F11: Dual NO-GO scenario.** Both Hermes and Local LLM failing simultaneously isn't addressed. **Minor but valid** — document the combined fallback.

**DS-F1: Final system map missing.** No task to produce the updated system map post-architecture. **Genuine insight** — add as M4 success criteria.

**OAI-F35: Promotion collision testing.** C9 and TV2-022 mention write-lock tables but no task tests concurrent promotion. **Genuine insight** — add to TV2-022 AC.

### Contradictions

**TV2-018 dependency:** OAI says add TV2-008. GEM says add TV2-017. Both are correct — TV2-018 should depend on both.

**Task sizing for TV2-017:** OAI-F26 and DS-F5 want to split it. GEM and GRK don't flag it. The task is substantial but produces one coherent design artifact (state diagram + transition rules). Splitting would create artificial boundaries between tightly coupled concepts. **Resolution: keep as-is, note in acceptance criteria that all three dimensions must be covered.**

**Risk for TV2-009/010/011:** DS-F8 says lower to low. Others don't flag. Medium is correct — chat template configuration and pipeline bugs introduce genuine unknowns.

### Action Items

#### Must-fix

**A1** (OAI-F13, GEM-F6, GRK-F7): **Relax migration serial chaining.** Allow same-tier parallel runs: TV2-032 + TV2-033 can run concurrently (both low-risk, shared prerequisites). TV2-034 + TV2-035 can run concurrently (both medium-risk). Keep cross-tier sequential (low before medium before high).

**A2** (OAI-F21, GEM-F9, GRK-F8): **Tighten migration acceptance criteria.** Replace "matches or exceeds" with concrete metrics per service. Define baseline measurements as part of TV2-001 inventory (output samples, delivery timing, error rates). Per-service AC: match rate threshold, zero missed critical items, latency within bounds.

**A3** (OAI-F8, GRK-F6, DS-F3): **Fix TV2-021 dependencies and TV2-001 AC.** Add TV2-016 and TV2-019 as dependencies for TV2-021. Update TV2-001 AC to include structured data per service: primary trigger, inputs, outputs, current failure modes, baseline metrics.

**A4** (OAI-F9, GEM-F8): **Add dependencies to TV2-018.** Add both TV2-008 (platform decision) and TV2-017 (state machine) as dependencies.

**A5** (GEM-F5, OAI-F6): **Add AD-009 validation to TV2-018 AC.** Explicitly require tests confirming credential, destructive, and external-comms tasks deterministically force escalation regardless of model confidence.

**A6** (OAI-F14, DS-F7): **Add rollback design/validation.** Add AC to TV2-022 (or new task) for rollback mechanism design. Add per-service rollback validation AC to TV2-032–TV2-037 (each migration task must demonstrate successful rollback).

**A7** (OAI-F5, OAI-F34): **Add vault authority and evaluator separation verification.** Add AC to TV2-038 (parallel validation) requiring: (a) reconciliation test proving no writes bypass staging/promotion, (b) audit proving executors cannot self-promote, (c) canonical path ownership check.

**A8** (GRK-F2): **Confirm migration inventory completeness.** Add AC to TV2-001: "Inventory confirmed as exhaustive against running launchd services and cron entries. Migration plan (M5) updated if inventory reveals services beyond the 6 defined categories."

#### Should-fix

**A9** (OAI-F10): **Add TV2-008 dependency to TV2-023** (system prompt architecture). Prompt composition may be constrained by platform's message role support and adapter behavior.

**A10** (OAI-F11, DS-F13): **Add TV2-018 and TV2-016 dependencies to TV2-024** (credential management). Credential injection needs to work across tiers and respect escalation policy.

**A11** (OAI-F4): **Add zero-marginal-cost measurement to M6.** Add AC to TV2-038: "Routing distribution by tier measured during validation. ≥70% of decisions routed to local (Tier 1+2)."

**A12** (GEM-F7): **Raise TV2-022 risk to high.** Staging/promotion is vault integrity critical per C8/C9/AD-001.

**A13** (OAI-F23): **Operationalize soak test workload.** Define exact TV2-007 profile: cron cadence (2-3 jobs, specific intervals), Telegram frequency (N messages/hour), model switch frequency, concurrent session count.

**A14** (DS-F11): **Clarify TV2-016 dual-model go/no-go logic.** Add: "GO if single model selected AND passes both bars, OR dual selected AND both models pass their respective capability bars."

**A15** (GRK-F11): **Document dual NO-GO scenario.** Add note to action plan: if both Hermes and Local LLM fail, combine §12.4 + §13.6 — OpenClaw + OpenRouter. Phase 3 adapts.

**A16** (OAI-F16, OAI-F17): **Add conditional fallback path validation.** After TV2-008 NO-GO: minimum viable non-Hermes orchestration feasibility check. After TV2-016 NO-GO: OpenRouter connectivity/cost/policy test.

**A17** (OAI-F35): **Add promotion collision testing to TV2-022 AC.** Test concurrent promotion attempts, lock acquisition failure, recovery after interrupted promotion.

**A18** (OAI-F36): **Add pre-decommission state reconciliation.** Add AC to TV2-038 or TV2-039: reconciliation covering outstanding jobs, state artifacts, credential/config parity.

#### Defer

**A19** (OAI-F26, DS-F5): **Split TV2-017 into sub-tasks.** The task is substantial but produces one coherent state diagram. Keep as-is; reassess if it proves too large during execution.

**A20** (DS-F1): **System map documentation task.** Add "Updated system map" to M4 success criteria instead of a separate task.

**A21** (DS-F2): **Health digest implementation.** Implementation belongs to Phase 4/5. Tasks will be created during the TASK phase for migration. Not an action plan gap — it's a later-phase deliverable.

### Considered and Declined

| Finding | Justification | Category |
|---------|---------------|----------|
| GEM-F1/F2/F3, OAI-F38/F39, GRK-F4/F5 (model/platform names unverifiable) | Reviewer knowledge cutoff. Qwen3.5, GLM-4.7-Flash, Hermes Agent all exist in 2026. OpenClaw is internal/custom. | incorrect |
| OAI-F40/F41/F42, DS-F15/F16/F17/F18, GRK-F5 (internal references unverifiable) | References to vault files, cross-project deps, and calibration data are internal by design. Not verifiable by external reviewers. | constraint |
| GRK-F1 (cost target lower bound missing) | The $10 is an estimate floor, not a minimum requirement. The target is <$50, ceiling $75. M6 AC tests the correct thing. | incorrect |
| DS-F4 (TV2-012 as dependency for TV2-015) | TV2-012 is optional. If it produces data, TV2-015 naturally considers it. Formal dependency on optional task creates confusion. | overkill |
| DS-F8 (reclassify TV2-009/010/011 as low) | Medium is correct — chat template configuration and pipeline bugs (F4) introduce genuine unknowns. | incorrect |
| GRK-F9 (decompose TV2-001 and TV2-004) | Scoped research tasks with clear AC. Sub-tasking adds ceremony without value. | overkill |
| DS-F6 (peer review of test prompts) | Prompts validated against models as part of AC. Separate review step excessive for internal benchmark. | overkill |
| GEM-F10 (split TV2-021 into sub-tasks) | Producing interface definitions for 6 services is one coherent design exercise. Partially addressed by A3 (dependency fix). | overkill |
| OAI-F12 (TV2-031 needs more dependencies) | Scaffold is intentionally lightweight (repo init + base structure). Detailed scaffold built during migration tasks. | overkill |
| OAI-F15 (tier routing policy task) | Already covered by TV2-017 (state machine) + TV2-018 (escalation). Separate task would duplicate. | constraint |
| OAI-F29 (branch-specific subtasks for NO-GO) | Pre-planning two complete branches adds complexity. Current approach (gates redirect, Phase 3 adapts) is simpler. | overkill |
| OAI-F30 (TV2-003/004 dependency) | Harness is designed to be pluggable. No formal dependency needed. | overkill |
| DS-F14 (value density metric earlier) | Sequencing is fine as-is. | out-of-scope |
| GRK-F10 (raise TV2-012 risk) | Optional task, low stakes. | overkill |
