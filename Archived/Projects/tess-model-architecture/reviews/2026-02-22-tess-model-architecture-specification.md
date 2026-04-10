---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-model-architecture/specification.md
artifact_type: spec
artifact_hash: f20ec9ea
prompt_hash: b7b7e0b7
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
    latency_ms: 68342
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-specification-openai.json
  google:
    http_status: 200
    latency_ms: 45902
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 68538
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 39395
    attempts: 1
    raw_json: Projects/tess-model-architecture/reviews/raw/2026-02-22-tess-model-architecture-specification-grok.json
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

# Peer Review: Tess Model Architecture Specification

**Artifact:** Projects/tess-model-architecture/specification.md
**Mode:** Full
**Reviewed:** 2026-02-22
**Reviewers:** GPT-5.2, Gemini 3 Pro Preview, DeepSeek V3.2-Thinking (via deepseek-reasoner), Grok 4.1 Fast Reasoning, Perplexity Sonar Reasoning Pro (operator-conducted)
**Review prompt:** Structured review of specification covering internal consistency, completeness, feasibility, clarity, task decomposition, plus 3 author-posed questions (AN1–AN3) and unverifiable claim flagging.

---

## OpenAI (GPT-5.2)

- [R1]
  - [Severity]: STRENGTH
  - [Finding]: Strong internal spine: Facts → Assumptions/Unknowns → Architecture → Contracts → Tasks. The two-agent split is consistently justified by routing bugs (F16), caching dynamics (F21), and persona constraints (F13).
  - [Why]: This coherence reduces "architecture drift" during implementation and makes later model swaps contract-driven rather than preference-driven.
  - [Fix]: None.

- [R2]
  - [Severity]: SIGNIFICANT
  - [Finding]: Some alignment mismatches between "Tiering" and "Agent responsibilities." In §6.1 Tier 1 includes "directive execution" and "vault queries with summarization," but §6.2 says mixed tasks should split (mechanical local, summary cloud). In §6.3, `tess-voice` still "handles … vault queries with summarization" which can imply direct tool/file ops on the cloud agent.
  - [Why]: If `tess-voice` performs mechanical tool chains directly, you lose the "machine clock" separation and may reintroduce caching/cost and reliability issues (and possibly confirmation safety invariant exposure).
  - [Fix]: Add a normative rule: "`tess-voice` may request mechanical retrieval, but all file/vault/tool execution MUST be performed by `tess-mechanic` (or by a dedicated local tool endpoint) except for explicitly whitelisted read-only tools." Reflect this in §6.1 and the `tess-voice` handle list.

- [R3]
  - [Severity]: CRITICAL
  - [Finding]: Mixed-task routing depends on U9 (inter-agent delegation), but the architecture reads as if the split is the chosen mechanism regardless. If delegation is not supported, you need a concrete, specified alternative path (e.g., `tess-voice` calling a local "mechanic service" tool) with the same safety and schema contracts.
  - [Why]: Without a defined delegation mechanism, implementation can stall or regress into cloud-agent doing local work ad hoc, undermining the architecture's main benefits.
  - [Fix]: In §6.3, specify "Delegation Mechanism v1": either (A) agent-to-agent messaging if supported, or (B) expose `tess-mechanic` capabilities as an explicit tool/API (local RPC/HTTP) callable by `tess-voice`, with authentication, rate limits, and an allowlist of operations.

- [R4]
  - [Severity]: SIGNIFICANT
  - [Finding]: Limited Mode trigger/behavior is defined, but not its interaction with fallback chains and scope enforcement. The spec says fallback chain enables automatic failover, and Limited Mode says "switch all user-facing traffic to local" plus "scope reduction." It's not explicit where scope reduction is enforced (router vs prompt vs tool allowlist).
  - [Why]: Automatic fallback alone will not guarantee "captures/triage/status only." Without enforcement, the system may continue executing high-risk actions locally during outages.
  - [Fix]: Add an enforcement point: in Limited Mode, the router must (1) swap model AND (2) apply a reduced tool allowlist + reduced system prompt + a "no-actuation" policy unless an explicit operator confirmation token is present.

- [R5]
  - [Severity]: SIGNIFICANT
  - [Finding]: Safety invariant MC-6 ("Never emits confirm for destructive operations…") is strong, but it is framed as a model behavior requirement rather than a system-level guardrail.
  - [Why]: Relying on model compliance for destructive-operation gating is fragile; a single malformed output could bypass.
  - [Fix]: Make MC-6 dual-layered: (a) model instruction + benchmark, and (b) hard gate in the bridge/tool executor that rejects destructive actions unless the operator confirmation token is present, regardless of model output. Update MC-6 text to reflect "system must enforce."

- [R6]
  - [Severity]: SIGNIFICANT
  - [Finding]: The "two agents have separate memory" issue (U10) is acknowledged, but the architecture doesn't fully specify the state synchronization pattern between them (what gets written, where, and when `tess-voice` reads it).
  - [Why]: Without explicit state conventions, mixed workflows (e.g., background findings surfaced later) become inconsistent, leading to user confusion and repeated work.
  - [Fix]: Define a minimal shared-state contract via the vault: e.g., `vault/tess/inbox/*.md` for findings, `vault/tess/state.json` for last-run markers, and a rule that `tess-voice` checks these locations at start of each Telegram turn.

- [R7]
  - [Severity]: MINOR
  - [Finding]: Cost model and caching mechanics are strong, but there's a subtle tension: you rely on caching to make cloud-primary "economically viable," yet later R14 says uncached (~$40/mo) is tolerable.
  - [Why]: This creates ambiguity in priorities: is caching a hard requirement or a cost optimization?
  - [Fix]: Decide and state explicitly: either "Caching is REQUIRED to meet budget X and latency Y" or "Caching is PREFERRED; without it we accept cost Z." Align A6/A7 language with R14.

- [R8]
  - [Severity]: SIGNIFICANT
  - [Finding]: Feasibility risk: 64K context is mandated for local via `num_ctx 65536`, but the actual need for 64K on the mechanical agent is not justified, and it increases memory/latency risk.
  - [Why]: If most mechanical tasks are short, 64K may be unnecessary overhead; if long-context is needed, you need explicit scenarios and performance acceptance criteria.
  - [Fix]: Add a requirement rationale: which workflows require 64K on the mechanic. Consider tiered local contexts (e.g., default 16K, escalate to 64K only for specific tools) if supported.

- [R9]
  - [Severity]: STRENGTH
  - [Finding]: Routing bug strategy is pragmatic: choose per-agent model assignment (F15) and channel bindings (F17) as the "known-good" mechanism.
  - [Why]: This reduces dependence on potentially broken runtime overrides and clarifies test scope for TMA-002.
  - [Fix]: None.

- [R10]
  - [Severity]: SIGNIFICANT
  - [Finding]: Versioning/upgrade state is noted (F19), but tasks don't include a "pin + reproduce + upgrade plan" for OpenClaw given the bundler corruption block and routing bug uncertainty.
  - [Why]: Implementation can be derailed by toolchain instability; reproducibility and rollback matter for always-on agents.
  - [Fix]: Add a task: "TMA-002a: Environment pinning & rollback plan" (document exact OpenClaw build, Ollama version, Modelfile hash, launchd plist, and a rollback procedure).

- [R11]
  - [Severity]: MINOR
  - [Finding]: Persona rubric is good, but "5–10 interactions" may be too small for the Required thresholds like "≥2/3 qualifying cases."
  - [Why]: With small N, a single miss swings pass/fail; could cause churn and indecision between Haiku/Sonnet.
  - [Fix]: Specify minimum qualifying-case counts per dimension (e.g., at least 9 qualifying cases for second-register checks) or run two batches (smoke + expanded).

- [R12]
  - [Severity]: SIGNIFICANT
  - [Finding]: Task decomposition mostly aligns, but TMA-010 depends on TMA-008; meanwhile, TMA-010 includes validating API formats and caching passthrough, which are upstream constraints on what config should be written.
  - [Why]: You may end up drafting config before knowing whether cache_control is supported or which API format hangs (U2/U13).
  - [Fix]: Split TMA-010 into (A) "TMA-010a: Provider/API validation (format + cache_control passthrough)" as a prerequisite to finalizing TMA-008, and (B) "TMA-010b: Token cost measurement" after TMA-009. Or change dependency so TMA-008 is a draft and TMA-010 gates merge/deploy.

- [R13]
  - [Severity]: STRENGTH
  - [Finding]: Mechanical contract gates (MC-1..MC-6) are crisp and implementation-oriented, especially JSON validity and schema adherence thresholds.
  - [Why]: This makes local model choice measurable and avoids subjective debates.
  - [Fix]: None.

- [R14]
  - [Severity]: SIGNIFICANT
  - [Finding]: "No Thinking Model" section asserts thinking adds latency tax inappropriate for always-on agent; but there's no explicit latency budget for user-facing cloud responses (only local heartbeat <5s).
  - [Why]: Without user-facing latency targets, it's hard to evaluate whether Sonnet or a "thinking" mode is unacceptable in practice.
  - [Fix]: Add latency SLOs for `tess-voice` (p50/p95 end-to-end on Telegram) and for Limited Mode.

- [AN1]
  - [Severity]: SIGNIFICANT
  - [Finding]: The consolidation of TMA-010/011 is coherent in scope (API format + caching + cache_control passthrough belong together), but the dependency placement is risky because it sits after the config draft (TMA-008).
  - [Why]: You can't "configure correctly" until you know which API format works and whether cache_control is passed through.
  - [Fix]: Keep consolidation, but reorder: make "API format + cache_control passthrough" a gating subtask before finalizing TMA-008 (see R12 fix).

- [AN2]
  - [Severity]: SIGNIFICANT
  - [Finding]: R14 should be HIGH if you treat caching as an architectural prerequisite (A6/A7 language), but MEDIUM if cost/budget is the true impact metric. As written, the spec simultaneously frames caching as prerequisite and then downplays impact because budget tolerates $40/mo.
  - [Why]: Risk severity should match what "breaks" success criteria. If success includes "cost-effectively," and caching is the lever, loss of caching is a major requirement failure even if affordable.
  - [Fix]: Decide the requirement: If "must be cost-effective per model" → set R14 HIGH and define a max monthly spend SLO. If "must be resilient, cost within broad tolerance" → keep MEDIUM but revise A6/A7 to "preferred" and state the accepted uncached cost ceiling explicitly.

- [AN3]
  - [Severity]: STRENGTH
  - [Finding]: The dual-critical-path structure is correctly captured conceptually: routing validation and persona/model selection both gate final config and deployment.
  - [Why]: This matches reality: you can't lock config until both the routing mechanism and the Tier 1 model choice are known.
  - [Fix]: Update the graph/dependencies slightly so the "API validation for caching + format" (currently in TMA-010) also sits on the critical path before finalizing config/deploy (per R12).

- [UVC1–UVC9]: Multiple unverifiable claims flagged across F3, F4, F5, F7, F8, F9, F10, F11, F12, F14, F16, F19, F20, F22. All classified SIGNIFICANT. See full response for individual entries.

---

## DeepSeek (deepseek-reasoner / V3.2-Thinking)

### Internal Consistency
- F1, A1, R1, TMA-001/002 — Strong alignment. The two-agent split is consistently presented as the solution to routing bugs, with validation tasks directly addressing the unknowns.
- F9, F11, §11 — Cost analysis consistently shows negligible difference between cloud and local, justifying cloud-primary. The cost model depends on prompt caching (A6, A7), which is a consistent theme.
- F21, §6.3 — The elimination of heartbeat cache pollution is a well-reasoned benefit of the two-agent split, logically stemming from the facts.
- F14, F22, TMA-011 — System prompt size, cost, and optimization are consistently linked. The dependency of TMA-011 on persona eval (TMA-006) is logical.
- §7, §8 — Design contracts and conditional model selection are perfectly aligned. Models must pass contracts; no model is pre-confirmed.
- §13, §15 — Risks and tasks are well-matched. Each risk has corresponding validation or mitigation tasks.
- Inconsistency — U1 Status: U1 is marked "Partially resolved" based on routing research, but the text still lists it as a "Critical" unknown. It should be downgraded to "High" or moved to the "High" section for clarity.

**[U1 Status] [MINOR]:** U1 is classified as "Critical" but described as "Partially resolved." This creates a minor inconsistency in risk perception. Fix: Reclassify U1 as "High" or add a note in the "Critical" section explaining the partial resolution.

### Completeness
- Overall — The spec is exceptionally comprehensive, covering technical, economic, and persona dimensions. Failure modes are extensively considered.
- Missing Risk — Local Model Service Health: The spec assumes Ollama runs reliably. A crash or hang of the local inference service would disable Tier 2 tasks and Limited Mode. While `tess-mechanic` has a cloud fallback, the trigger mechanism (local model crash vs. API timeout) is not defined.
- Missing Risk — Configuration Drift: The architecture relies on specific OpenClaw configs, Ollama Modelfile parameters, and environment variables. No process for version-controlled configuration management or drift detection is mentioned.
- Missing Risk — Inter-Agent Communication Security: If a `message_agent()` mechanism is implemented (U9), the spec doesn't address authentication or validation of inter-agent messages within the same gateway.
- Missing Consideration — Logging & Observability: The architecture introduces multiple components and failure states (Limited Mode, fallbacks). No requirements are specified for logging, metrics, or dashboarding to monitor model usage, costs, error rates, and mode switches.
- Clarification Needed on "Concurrent Load": F1 and the memory budget list concurrent processes (Crumb, Docker, Obsidian). The "defined load shape" for memory validation includes these, but the performance benchmark (TMA-007) does not explicitly mandate testing under the same concurrent load. This should be clarified.

**[R15 — Local Inference Service Failure] [SIGNIFICANT]:** The spec does not address the risk of the Ollama service crashing or becoming unresponsive. This would break Tier 2 (mechanical tasks) and the Limited Mode fallback for Tier 1, potentially leaving the system with no functional LLM. Fix: Add a risk: "Ollama service instability." Mitigation: Implement a health check and restart mechanism for Ollama via launchd or a supervisor; define `tess-mechanic`'s fallback to cloud as a response to local service failure (not just model error).

**[C1 — Configuration Management] [MINOR]:** No process or tooling is specified for managing the configuration of OpenClaw (`openclaw.json`), Ollama (Modelfile), and environment variables. Configuration drift could cause silent failures (e.g., `num_ctx` resetting) and complicate debugging and recovery. Fix: Add a note in §12 or a task to establish version-controlled config management.

### Feasibility
- Technical Soundness: The core architectural pattern (personality-first tiering, two-agent split) is sound and creatively addresses the constraints.
- Hardware Constraints: The memory budget (§10) is careful and acknowledges estimates. The gating of the 80B model on empirical headroom is a responsible approach.
- Cost Feasibility: The cost analysis is thorough and well-supported.
- Dependency on Unverified Components: Feasibility hinges on several unverified claims; task decomposition correctly treats these as critical path blockers.
- Operational Complexity: Two-agent split adds complexity; spec acknowledges this and provides simplification path if bugs are fixed.

### Clarity
- Overall: Exceptionally well-structured and clear. Concepts like "two clocks," "design contracts," and "Limited Mode" are effectively defined and used consistently.
- Ambiguity in Task TMA-010: Consolidated task scope is broad. Type is `#research` but parts are more `#code`/experimentation. Minor.
- Clarity on "Second Register": Spec could briefly exemplify what constitutes the "second register" from SOUL.md for external reviewers.

### Task Decomposition
- Dependencies: Graph and table are logically sound. Dual critical path correctly identified and realistic.
- Acceptance Criteria: Criteria are specific and testable.
- Workload: Decomposition is granular but not overly so.
- Risk Integration: Each high/medium risk has a corresponding validation task, creating a closed loop.

### Author Notes
- **AN1:** Consolidation is coherent and recommended. Dependency on TMA-008 is appropriate.
- **AN2:** MEDIUM is the correct rating. Practical impact is bounded and within budget tolerance. HIGH should be reserved for risks that break core functionality or cause unbounded cost overruns.
- **AN3:** Dual-critical-path structure is correctly captured and essential.

### Unverifiable Claims
- F3, F7, F12, F16, F19 — OpenClaw behaviors, GitHub issue IDs, version specifics.
- F4, F5, F6 — Model specifications and community reports.
- F20 — Anthropic prompt caching mechanics.
- F8 — KV cache truncation behavior.
- Cost projections (F9, F10, F11, §11).

### Summary
High-quality, professional-grade specification. Main recommendations: add a risk for local service health and ensure the performance benchmark includes concurrent load testing.

**[Overall] [STRENGTH]:** The specification is internally consistent, remarkably complete, technically feasible, clearly written, and backed by a logical task decomposition.

---

## Google (Gemini 3 Pro Preview)

### 1. Unverifiable Claims
Per the instruction to flag claims that cannot be independently verified, the specification is dated February 2026, creating a baseline where all specific references to software versions and model releases post-2025 are currently unverifiable.

- **[F3, F4, F5] [SIGNIFICANT] [UNVERIFIABLE CLAIM]**: References to "Ollama launch openclaw" (Feb 2026 release), `qwen3-coder:30b`, and `qwen3-coder-next` (80B Mamba-Transformer). These models and commands do not exist in the current knowledge base.
- **[F9, F10] [SIGNIFICANT] [UNVERIFIABLE CLAIM]**: Pricing and existence of "Anthropic Haiku 4.5" and "Sonnet 4.5". These models are unreleased; pricing logic relies on these specific future data points.
- **[F16] [SIGNIFICANT] [UNVERIFIABLE CLAIM]**: References to specific OpenClaw GitHub issues #14279, #13009, #6671. Cannot verify the nature or existence of these bugs to confirm they necessitate the two-agent split.
- **[F19] [SIGNIFICANT] [UNVERIFIABLE CLAIM]**: References to OpenClaw v2026.2.17 and v2026.2.21, and bundler corruption issue #22841. Prevents verification of the software environment's stability.

### 2. Structured Review

#### Internal Consistency
- **[F15 vs. U11] [MINOR]:** Fact F15 states "Per-agent model is the most reliable mechanism," yet Unknown U11 asks "Can a single OpenClaw gateway host both agents?" If it is unknown whether the gateway can host the agents side-by-side, F15 is an Assumption, not a Fact. Fix: Move F15's reliability claim to Assumptions or qualify with "Assuming U11 validates."
- **[R1 vs. A1] [STRENGTH]:** The document correctly identifies the routing mechanism as both a primary assumption (A1) and a critical risk (R1), with a mitigation plan (two-agent split) that directly addresses the bugs listed in F16.
- **[Cost Logic] [STRENGTH]:** The cost analysis (§11) is mathematically consistent with the usage data (135 daily requests) and pricing facts (F9), correctly identifying caching as the only variable making cloud-primary economically comparable to local power costs.

#### Completeness
- **[State Fragmentation] [SIGNIFICANT]:** The "Two-Agent Split" creates a state fragmentation risk that is under-represented. If `tess-voice` (UI) and `tess-mechanic` (Execution) are separate agents, they imply separate memory/context stacks. If `tess-mechanic` performs a task, how does `tess-voice` know the result to report it to the user? U10 asks *if* they share memory, but there is no Task or Protocol defined for *how* they communicate if they don't. Fix: Add a task to "Define Inter-Agent State Sync Protocol."
- **[MC-6 Enforcement] [MINOR]:** The Architecture Diagram (§6.4) and component list do not specify *where* MC-6 enforcement happens. Is it in the OpenClaw tool definition, the bridge code, or the model prompt? Fix: Specify the component responsible in §6.4.

#### Feasibility
- **[Memory] [STRENGTH]:** The memory budget (§10) is robust. Leaving ~55GB headroom on 96GB for a 30B model is highly conservative and feasible.
- **[Mixed-Task Routing] [SIGNIFICANT]:** The "Two-Agent Split" relies on Channel Bindings (F17). While this works for incoming traffic, it does not solve mixed-task routing (§6.2) where a single user message requires both agents. If delegation fails, the "Personality-First" architecture forces `tess-voice` to do mechanical work (violating the split) or fail. Fix: Elevate U9 to a Blocking Criteria for the Architecture.
- **[Design Contracts] [STRENGTH]:** The separation of Mechanical and Persona contracts is excellent — decouples architecture from specific model versions.
- **[Limited Mode] [STRENGTH]:** Specification of Limited Mode as a design requirement rather than just a failure state is clear and ensures high availability.

#### Task Decomposition
- **[TMA-008 Convergence] [CRITICAL]:** There is a potential deadlock in the dependency graph regarding TMA-008. You cannot accurately write the Config until you know which model won the Persona Eval (TMA-006), because Haiku and Sonnet have different pricing/caching tiers. The graph identifies this, but the risk is that delays in Persona Eval (research) will block the Config Draft (implementation). Fix: Ensure TMA-006 is prioritized immediately alongside TMA-002.

### Author Notes
- **AN1:** Consolidation is coherent and efficient.
- **AN2:** Recommendation: **HIGH.** A failure in caching quadruples operating cost. This invalidates the core cost justification for choosing Cloud-Primary over Local-First (Revision 2 Decision). Even if affordable, it weakens the architectural rationale.
- **AN3:** Dual-critical-path structure is correctly captured. The recognition that Configuration (TMA-008) sits at the intersection of mechanical capability and content strategy is accurate.

---

## Grok (grok-4-1-fast-reasoning)

### Structured Review Summary

#### 1. Internal Consistency
The document is largely internally consistent, with facts (F1–F22) cross-referenced accurately to support assumptions (A1–A7), unknowns (U1–U13), and risks (R1–R14). Decision history (§2) aligns with revisions, and the two-agent split (§6.3) coherently resolves routing bugs (F16). Minor tensions exist: U1 claims "partially resolved" but defers empirical validation to TMA-002, creating a circular reference; R14 severity is debated in AN2 without resolution; Limited Mode (§6.5) assumes local model passes Mechanical Contract (MC-1–6) but deployment precedes full validation (TMA-007). Cost model (§11) repeatedly emphasizes caching (F14, F20–22, A6–7), but fallback lacks caching contingency. Overall: Strong but with deferred resolutions (85% alignment).

#### 2. Completeness
Gaps in architecture: Inter-agent delegation (U9) is critical for mixed-task routing (§6.2) but lacks fallback design. No explicit handling of shared session memory (U10) or vault-based state sync. Resilience incomplete: Limited Mode covers API outage but not local model crash. Missing risks: OpenClaw upgrade path; prompt cache invalidation on SOUL.md edits; multi-turn context drift in two-agent split. Task decomposition covers validation but omits deployment rollback plan. Overall: Moderate (75% complete, key integration gaps).

#### 3. Feasibility
Technically sound given constraints. Hardware budget conservative; two-agent split aligns with OpenClaw docs. Challenges: 96GB shared memory tight for 80B promotion; routing bugs force two-agent complexity pending U12; non-thinking local model assumes >95% tool validity (unverified). Limited Mode feasible but persona degradation accepted as transient. Overall: Feasible with validation gates (80%, gated on TMA-002/007).

#### 4. Clarity
Highly structured with tables, diagrams, and cross-refs; contracts (§7) and rubric (§9) unambiguous. Dense prose in §6.2–6.3; jargon-heavy (e.g., "channel: telegram" binding lacks syntax). Overall: Clear (90%, minor density issues).

#### 5. Task Decomposition
Dependencies logical; acceptance criteria testable. Critical paths realistic. Parallel tracks efficient. Gaps: No task for U12 bug verification (folded into TMA-002 but not explicit); TMA-010 high-risk but single-threaded. Overall: Solid (85%, minor scoping).

### Author Note Responses
- **AN1:** Yes, coherent. Former TMA-011 is a strict subset of TMA-010. Single task avoids duplication; dependency on TMA-008 appropriate.
- **AN2:** Escalate to **HIGH**. Cost model is foundational ("prerequisite, not optimization"; 4.5x multiplier invalidates projections). Budget tolerance mitigates impact but principle violation warrants HIGH.
- **AN3:** Correctly captured. Routing and persona converge properly on TMA-008; graph reflects parallelism.

### Review Findings

- **[REVIEW-1] [SIGNIFICANT]:** U1 marked "~~Partially resolved~~" with strikethrough but text lists unresolved sub-risks (U9–U11) and defers to TMA-002; creates false closure. Fix: Strike the strikethrough; reclassify U1 as open with sub-bullets for U9–U11.

- **[REVIEW-2] [CRITICAL]:** Mixed-task routing (§6.2) requires delegation (U9) but no fallback if unavailable (e.g., tess-voice direct Ollama call or self-handling). Breaks feasibility for core use case ("Check vault..."). Fix: Add §6.3 bullet: "Fallback: If delegation absent, tess-voice uses Ollama tool endpoint for extracts, synthesizes locally."

- **[REVIEW-3] [SIGNIFICANT]:** Shared memory/session behavior (U10) unaddressed; two agents may not sync. Crumb pattern (vault files) mentioned but not spec'd for agents. Fix: Add A8: "Agents sync via vault files (Crumb pattern)." Task TMA-002 AC: "Verify session isolation; document vault sync."

- **[REVIEW-4] [MINOR]:** Limited Mode (§6.5) assumes local passes MC-1–6 but TMA-007 post-dates deployment. Fix: Sequence TMA-007 before any deploy; add "Limited Mode gated on MC pass."

- **[REVIEW-5] [SIGNIFICANT]:** R14 (cache_control) lacks contingency beyond "middleware/feature request"; no quantified post-mitigation cost in table (§11). Fix: Add §11 row: "Haiku no-cache: ~$40"; escalate per AN2.

- **[REVIEW-6] [MINOR]:** §6.3 tess-mechanic fallback "cloud if local crashes" but cloud is Tier 1/3; circular if API also down. Fix: Specify "tess-mechanic fallback: queue to inbox (silent retry)."

- **[REVIEW-7] [SIGNIFICANT]:** No task owns U12 (routing bugs fixed?); folded vaguely into TMA-002. Fix: TMA-002 AC: "Test F16 bugs explicitly; if fixed, prototype single-agent."

- **[REVIEW-8] [MINOR]:** Memory budget (§10) uses theoretical KV cache; TMA-005 empirical but no q4_0 vs q8_0 split in promotion gate (§8.1). Fix: Table rows for each KV type; gate on worst-case (q8_0).

- **[REVIEW-9] [STRENGTH]:** Design contracts (§7) with hard gates and rubric (§9) enable future-proof swaps. Aligns with "conditional selection" (§8); testable via TMAs.

- **[REVIEW-10] [SIGNIFICANT]:** Heartbeat cache pollution fix (§6.3 pt5) assumes user messages "cluster"; no data. If sporadic, 5-min TTL still fails; negates F21 benefit. Fix: Add U14: "Empirical heartbeat/user interval distribution." TMA-005 measure.

- **[REVIEW-11] [MINOR]:** Component diagram (§6.4) shows Limited Mode under tess-voice but not mechanic resilience. Fix: Add mechanic fallback arrow.

- **[REVIEW-12] [MINOR]:** Task graph misses TMA-010 dep on TMA-009 (integration → API validate). Fix: Arrow TMA-009 → TMA-010.

- **[REVIEW-13] [STRENGTH]:** Peer review attribution (§16) transparent, surfaces pushbacks. Builds trust; avoids groupthink.

- **[REVIEW-14] [SIGNIFICANT]:** Electricity cost (F11, §11) assumes 50–80W but no sustained measure; R7 thermal flags risk. Fix: TMA-005 AC: "Power draw under load."

### Unverifiable Claims (All SIGNIFICANT)
- F3, F7: Ollama `launch openclaw` (Feb 2026); `openai-completions` vs `-responses` (GitHub report).
- F4–F5: `qwen3-coder:30b/80B` specs (19GB Q4_K_M, 256K ctx, Mamba-Transformer).
- F7, F12, F16, F19: OpenClaw bugs #14279/#13009/#6671/#22841; v2026.2.17–21.
- F9–F10: Haiku 4.5/Sonnet 4.5 pricing.
- F11: Michigan $0.18/kWh, 50–80W Mac Studio.
- U4: 85% JSON validity (Grok report).

### Grok STRENGTH Ratio
Issues: 12 (1 CRITICAL, 6 SIGNIFICANT, 5 MINOR). Strengths: 2. Ratio: 86% issues. Calibration effective.

---

## Perplexity (Sonar Reasoning Pro — operator-conducted)

*This review was conducted externally by the operator via Perplexity Pro and delivered as structured text. Finding IDs assigned by Opus during synthesis.*

### Must-fix

- **[PPLX-MF1] [SIGNIFICANT]:** Cloud dependency boundary unstated. The spec says Limited Mode makes the cloud dependency acceptable while also stating Limited Mode is not a viable permanent mode. The result is a hard Anthropic dependency for Tess's core value (persona + judgment) that is never explicitly stated as a trade-off. Fix: Add an explicit "Anthropic as single critical vendor" statement listing what cannot be done during outage (no advice, no second register, no complex synthesis). Add an operator-level SLO for full persona availability vs Limited Mode vs total outage.

- **[PPLX-MF2] [SIGNIFICANT]:** MC-6 safety guarantees underspecified. Needs: (a) a negative requirement — local model must never initiate destructive actions or synthesize confirmation tokens; (b) single source of truth for confirmation tokens (bridge generates and validates, Tess never chooses the value); (c) tests covering replay, paraphrasing ("yeah go ahead"), and partial echo (token with extra text). Without this, MC-6 is too hand-wavy for a "system safety invariant."

- **[PPLX-MF3] [SIGNIFICANT]:** U2 and U13 should be CRITICAL pre-implementation gates, not just unknowns. The cost model and basic functionality depend on both. Make "Anthropic integration validated with completions + cache_control" a blocking gate before persona or contract testing. Add "no deployment without working caching path or an explicit updated uncached cost model."

- **[PPLX-MF4] [SIGNIFICANT]:** Persona eval should gate architecture validity, not just model choice. If neither Haiku nor Sonnet satisfies all Persona Contract hard gates, the architecture is considered invalid and must be revisited (alternative provider, different tool split, or reduced persona ambition). The spec currently assumes "some Anthropic model will work" — that's an untested linchpin.

- **[PPLX-MF5] [SIGNIFICANT]:** Session/memory semantics must be a hard requirement, not an acknowledged unknown. Make it explicit: all cross-agent state is file/vault based; neither agent may rely on the other's in-memory sessions for correctness. Add acceptance criteria in TMA-009: "mechanic's actions are discoverable by voice purely via vault/inbox state, with no shared in-gateway memory."

- **[PPLX-MF6] [SIGNIFICANT]:** Missing failure mode: local model regression after upgrade silently reduces JSON validity below MC-1 threshold. Add risk + mitigation: benchmark harness must run after any model or quantization change; deployment blocked on passing MC-1/MC-2. Currently no operational policy ties contracts to ongoing changes.

### Should-fix

- **[PPLX-SF1] [SIGNIFICANT]:** Two-agent split over-fits to current bugs. U12 should be HIGH (not Medium). Add: "If any two of the three routing bugs are fixed, re-evaluate whether single-agent with model overrides is simpler." Label the split explicitly as interim architecture with criteria for collapsing back.

- **[PPLX-SF2] [SIGNIFICANT]:** Limited Mode needs hard duration cap (e.g., >N hours → escalate to operator: "Tess degraded for X hours"). Prohibit "advice voice" in Limited Mode via prompt enforcement, not just English description. Prevents scope creep ("just this one advice thing").

- **[PPLX-SF3] [SIGNIFICANT]:** R14: MEDIUM acceptable from budget perspective, but label as "Architectural Assumption Risk." Require cost model re-run if caching unavailable. Add uncached fallback table (Haiku uncached, Sonnet uncached).

- **[PPLX-SF4] [SIGNIFICANT]:** TMA-010 should have an early probe (minimal API/caching test before full config) or split into "TMA-010a: early probe" and "TMA-010b: full validation." Actual Anthropic API behavior is currently late in the sequence.

- **[PPLX-SF5] [MINOR]:** Mark TMA-006 as "calendar critical" (requires operator interaction). Note that parts of TMA-008 (local model config, Ollama provider wiring) can be drafted before persona results.

### Consider

- **[PPLX-C1] [MINOR]:** Name Tier 3 as "on-demand escalation" — operationally it's 2+1 (rarely used), not three permanent tiers. Avoids over-engineering routing for Tier 3.

- **[PPLX-C2] [MINOR]:** Add "Future simplification" subsection: single persona agent + mechanical service via HTTP tools (not a second OpenClaw agent). Possible once U9/U12 resolved. Avoids locking in two-agent as dogma.

- **[PPLX-C3] [MINOR]:** Risk: "Unreviewed persona doc changes degrade Tess." SOUL.md/IDENTITY.md edits break Persona Contract as easily as model swaps. Mitigation: change-control on persona docs + lightweight regression tests against rubric.

- **[PPLX-C4] [MINOR]:** Clarify maximum expected concurrent contexts and interaction with q4_0 vs q8_0, so future readers don't misinterpret the memory budget table.

- **[PPLX-C5] [MINOR]:** Add monitoring/observability requirements: JSON validity rate, heartbeat latency, cache hit rate, Anthropic error rate, Limited Mode duration. Alerts: MC-6 violations, repeated cache misses, sustained Limited Mode.

### Affirmed

- **[PPLX-A1] [STRENGTH]:** Personality-first tiering and "two clocks" routing abstraction.
- **[PPLX-A2] [STRENGTH]:** Design contracts approach — turns model choice into conformance test.
- **[PPLX-A3] [STRENGTH]:** Prompt caching as first-class concern; heartbeat isolation via two-agent split.
- **[PPLX-A4] [STRENGTH]:** Limited Mode as design requirement.
- **[PPLX-A5] [STRENGTH]:** Task decomposition and evidence orientation.

### Author Notes

- **AN1:** Coherent, but API/caching validation is too late. Split into early probe + full validation.
- **AN2:** MEDIUM acceptable from budget standpoint; label as "Architectural Assumption Risk" with mandatory cost model re-run if caching unavailable.
- **AN3:** Correctly captured. Add scheduling guidance: TMA-006 early, partial TMA-008 pre-drafting.

---

## Synthesis

### Consensus Findings

**CF1. Mixed-task delegation has no fallback mechanism (5/5 reviewers)**
OAI-R3 (CRITICAL), GEM-Mixed-Task (SIGNIFICANT), GRK-REVIEW-2 (CRITICAL), DS-F7 (SIGNIFICANT implicit), PPLX-MF5 (implicit — state sync needed because delegation may not exist).
All five reviewers flagged that §6.2 describes mixed-task routing but §6.3 provides no mechanism or fallback if inter-agent delegation (U9) is unavailable. Two rated this CRITICAL. The spec reads as if the two-agent split handles this case, but without delegation, `tess-voice` either violates the split or fails.

**CF2. Inter-agent state synchronization unspecified (4/5 reviewers)**
OAI-R6 (SIGNIFICANT), GEM-State-Frag (SIGNIFICANT), GRK-REVIEW-3 (SIGNIFICANT), PPLX-MF5 (SIGNIFICANT — hardened: must be a requirement, not an acknowledged unknown).
Four reviewers independently identified that U10 (shared memory) is acknowledged but no state sync protocol is defined. Perplexity goes furthest: "all cross-agent state is file/vault based; neither agent may rely on the other's in-memory sessions for correctness" — elevates from design question to hard requirement.

**CF3. TMA-010 dependency ordering — API validation should gate config (3/5 reviewers)**
OAI-R12 (SIGNIFICANT), OAI-AN1 (SIGNIFICANT), GEM-TMA-008 (CRITICAL), PPLX-SF4 (SIGNIFICANT).
TMA-010 (API format + caching validation) currently depends on TMA-008 (config draft), but the validation results are upstream constraints on what the config should contain. Three reviewers converge on the same fix: split into early probe + full validation, or make TMA-008 a draft that TMA-010 gates. Perplexity adds: "actual Anthropic API behavior is currently late in the sequence; if something is fundamentally wrong, it invalidates a lot of earlier work."

**CF4. R14 severity — nuanced consensus toward HIGH (4/5 reviewers weigh in)**
GEM-AN2 (HIGH), GRK-AN2 (HIGH), OAI-AN2 (HIGH if prerequisite framing holds), PPLX-SF3 (MEDIUM with "Architectural Assumption Risk" label), DS-AN2 (MEDIUM).
Three reviewers argue HIGH on framing grounds (cost model assumes caching). Perplexity offers the strongest synthesis: MEDIUM is acceptable from budget standpoint, but must be labeled as "Architectural Assumption Risk" with mandatory cost model re-run if caching is unavailable. This resolves the framing tension without over-stating the dollar impact.

**CF5. MC-6 needs deeper specification (3/5 reviewers)**
OAI-R5 (SIGNIFICANT — dual-layered enforcement), GEM-MC-6 (MINOR — enforcement location), PPLX-MF2 (SIGNIFICANT — negative requirement, token source of truth, adversarial test cases).
Perplexity's contribution is the strongest: adds negative requirement (model must never initiate destructive actions or synthesize tokens), single source of truth (bridge generates/validates), and specific adversarial tests (replay, paraphrasing, partial echo). This transforms MC-6 from a behavioral instruction to a properly specified safety invariant.

**CF6. Limited Mode scope enforcement unspecified (3/5 reviewers)**
OAI-R4 (SIGNIFICANT), GRK-REVIEW-4 (MINOR), PPLX-SF2 (SIGNIFICANT — adds duration cap and prompt-enforced prohibition on advice voice).
Three reviewers converge: Limited Mode defines behavior but not enforcement mechanism. Perplexity adds a duration cap (>N hours → escalate to operator) and prompt-level prohibition on advice voice.

**CF7. U1 classification inconsistency (2/5 reviewers)**
DS-U1-Status (MINOR), GRK-REVIEW-1 (SIGNIFICANT).
U1 has strikethrough text suggesting closure but remains under "Critical" with unresolved sub-risks (U9–U11).

**CF8. Design contracts are an architectural strength (5/5 reviewers)**
OAI-R13, GEM-Design-Contracts, GRK-REVIEW-9, DS-§7/§8, PPLX-A2. All STRENGTH.
Universal endorsement of the Mechanical + Persona contract framework as future-proof and testable.

**CF9. TMA-010/011 consolidation is coherent (5/5 reviewers)**
All five affirmed AN1. No dissent. Multiple reviewers add: move API validation earlier in the sequence.

**CF10. Dual-critical-path structure is correct (5/5 reviewers)**
All five affirmed AN3. Perplexity adds scheduling guidance: mark TMA-006 as calendar-critical and pre-draft TMA-008 where possible.

### Unique Findings

**UF1. Cloud vendor dependency unstated (PPLX-MF1, SIGNIFICANT)**
Perplexity uniquely identified that the spec never explicitly states Anthropic as a single critical vendor or what becomes unavailable during outage. Limited Mode is positioned as making the dependency acceptable, but the dependency itself is never named as a trade-off. Genuine insight: forces a conscious acceptance rather than implied mitigation.

**UF2. Persona eval should gate architecture validity (PPLX-MF4, SIGNIFICANT)**
Perplexity uniquely flagged that TMA-006 currently determines model choice but doesn't consider the case where *neither* Anthropic model passes the Persona Contract. The spec assumes "some Anthropic model will work" — an untested linchpin. Genuine insight: adds an explicit architecture invalidation path.

**UF3. Local model regression after upgrade (PPLX-MF6, SIGNIFICANT)**
Perplexity identified a missing failure mode: model or quantization upgrades could silently reduce JSON validity below MC-1 threshold. The Mechanical Contract defines the gates but no operational policy ties them to ongoing changes. Genuine insight: benchmark harness must be a gate on all model changes, not just initial selection.

**UF4. Two-agent split should be labeled interim (PPLX-SF1, SIGNIFICANT)**
Perplexity recommends elevating U12 to HIGH and explicitly labeling the two-agent architecture as interim, with criteria for collapsing back to single-agent if bugs are fixed. Genuine insight: prevents the workaround from becoming dogma.

**UF5. tess-voice may perform mechanical tool chains (OAI-R2, SIGNIFICANT)**
OpenAI identified that §6.1 lists "directive execution" and "vault queries with summarization" under `tess-voice`, implying direct file/tool operations — violating the two-clock separation.

**UF6. 64K context for mechanical agent unjustified (OAI-R8, SIGNIFICANT)**
OpenAI noted 64K is mandated but no mechanical workflow requiring that context length is identified.

**UF7. No user-facing latency SLOs (OAI-R14, SIGNIFICANT)**
Only OpenAI flagged the absence of latency targets for `tess-voice`.

**UF8. Environment pinning & rollback plan missing (OAI-R10, SIGNIFICANT)**
OpenAI identified no task covers version pinning for OpenClaw, Ollama, and Modelfiles.

**UF9. Ollama service crash risk (DS-R15, SIGNIFICANT)**
DeepSeek identified the spec doesn't address local inference service crashes.

**UF10. Heartbeat cache assumption unvalidated (GRK-REVIEW-10, SIGNIFICANT)**
Grok questioned whether user messages actually "cluster" enough for the 5-min TTL to work.

**UF11. Persona drift via SOUL.md changes (PPLX-C3, MINOR)**
Perplexity noted that SOUL.md/IDENTITY.md edits break the Persona Contract as easily as model swaps. Suggests change-control + regression tests.

### Contradictions

**C1. R14 severity: HIGH vs MEDIUM vs hybrid**
- **HIGH camp (GEM, GRK, OAI-lean):** Caching is framed as a prerequisite. 4.5x cost multiplier invalidates the cost model.
- **MEDIUM camp (DS):** Practical impact is bounded (~$40/month), within budget tolerance.
- **Hybrid (PPLX):** MEDIUM acceptable but must be labeled "Architectural Assumption Risk" with mandatory cost model re-run if caching unavailable.
- **Recommendation:** Adopt Perplexity's hybrid — it resolves the framing tension. Escalate to HIGH for the version of R14 that addresses the cost model assumption, but note the budget tolerance. Add uncached cost rows to §11.

**C2. U2/U13 severity promotion**
- **Promote to CRITICAL (PPLX):** Both are pre-implementation gates — basic functionality and the cost model depend on them.
- **Keep as-is (other 4 reviewers):** Address via TMA-010 dependency reordering.
- **Recommendation:** Perplexity's position is stronger operationally. Promoting U2/U13 to Critical creates urgency; the dependency reordering (CF3) is the mechanism. Both actions reinforce each other.

### Action Items

**Must-fix (critical or consensus issues):**

**A1.** Define delegation fallback for mixed-task routing.
*Source:* CF1 — 5/5 reviewers, 2 CRITICAL.
*Action:* Add to §6.3: "If inter-agent delegation (U9) is unavailable, `tess-voice` calls Ollama directly as a tool endpoint for mechanical sub-tasks (file reads, structured extraction). Safety contracts (MC-6) apply to all local model invocations regardless of call path. This fallback degrades the separation of concerns but preserves functionality."

**A2.** Define inter-agent state synchronization as a hard requirement.
*Source:* CF2 — 4/5 reviewers, hardened by PPLX-MF5.
*Action:* Add assumption A8: "All cross-agent state is file/vault based. Neither agent may rely on the other's in-memory sessions for correctness. `tess-mechanic` writes findings to a shared vault location; `tess-voice` checks at the start of each Telegram turn." Add TMA-009 acceptance criteria: "Mechanic's actions are discoverable by voice purely via vault/inbox state, with no shared in-gateway memory."

**A3.** Fix TMA-010/TMA-008 dependency ordering.
*Source:* CF3 — 3/5 reviewers.
*Action:* Split TMA-010 into TMA-010a (API format + cache_control validation — gates TMA-008 finalization) and TMA-010b (token cost measurement — after TMA-009). Promote U2 and U13 to Critical unknowns with note: "No deployment without working caching path or an explicit updated uncached cost model."

**A4.** Harden MC-6 safety specification.
*Source:* CF5 — 3/5 reviewers, PPLX-MF2 strongest.
*Action:* Update MC-6 to include: (a) negative requirement — local model must never initiate destructive actions or synthesize confirmation tokens; (b) single source of truth — bridge generates and validates tokens, Tess never chooses the value; (c) system-level enforcement — bridge/tool executor rejects destructive actions without valid token, independent of model output; (d) adversarial test cases in TMA-007 — replay, paraphrasing ("yeah go ahead"), partial echo (token with extra text).

**A5.** Add explicit cloud vendor dependency statement.
*Source:* PPLX-MF1 — unique but fills a genuine gap.
*Action:* Add to §6 or §6.5: "Anthropic is the single critical vendor for Tess's core value (persona, judgment, second register, complex synthesis). During Anthropic outage: no advice voice, no second register, no complex synthesis — Limited Mode provides transient captures/triage only. This is an accepted trade-off, not a solved problem." Add operator-level SLO for full persona availability vs Limited Mode vs total outage.

**A6.** Add persona eval architecture invalidation path.
*Source:* PPLX-MF4 — unique but addresses an untested linchpin.
*Action:* Add to §8.2 or §9: "If neither Haiku nor Sonnet satisfies all Persona Contract hard gates, the architecture is considered invalid and must be revisited (alternative provider, different tool split, or reduced persona ambition)."

**Should-fix (significant but not blocking):**

**A7.** Resolve R14 severity — adopt hybrid position.
*Source:* CF4 — C1 contradiction resolved by PPLX-SF3.
*Action:* Escalate R14 to HIGH. Label as "Architectural Assumption Risk." Add uncached cost rows to §11 (Haiku ~$39.60, Sonnet uncached). State: "If caching is unavailable, re-run cost analysis and reassess cloud-primary vs alternatives. No deployment without working caching path or explicit acceptance of uncached cost ceiling."

**A8.** Specify Limited Mode scope enforcement + duration cap.
*Source:* CF6 — 3/5 reviewers, PPLX-SF2 adds duration cap.
*Action:* Add to §6.5: "Enforcement: On trigger, router applies (1) model swap, (2) reduced tool allowlist (read-only + capture only), (3) reduced system prompt, (4) no-actuation policy. Duration cap: if degraded >4 hours, send escalation: 'Tess degraded for X hours — operator review recommended.' Advice voice is prohibited via prompt, not just English description."

**A9.** Reclassify U1 — remove strikethrough, downgrade to High.
*Source:* CF7 — 2/5 reviewers.
*Action:* Remove strikethrough. Move to "High" with note: "Mechanism identified (two-agent split), empirical validation pending. Sub-risks: U9, U10, U11."

**A10.** Make U12 bug verification explicit; label two-agent split as interim.
*Source:* GRK-REVIEW-7, PPLX-SF1.
*Action:* Elevate U12 to HIGH. Add to §6.3: "The two-agent split is an interim architecture that works around current routing bugs. If any two of the three bugs (F16) are fixed, re-evaluate single-agent simplification." Add TMA-002 AC: "Test F16 bugs explicitly; if fixed, prototype single-agent."

**A11.** Add local model regression risk.
*Source:* PPLX-MF6 — unique, fills an operational gap.
*Action:* Add R15: "Local model upgrade silently reduces JSON validity below MC-1 threshold." Mitigation: "Benchmark harness (TMA-007) must run after any model or quantization change. Deployment blocked on passing MC-1/MC-2."

**A12.** Add user-facing latency SLOs for tess-voice.
*Source:* OAI-R14 (UF7).
*Action:* Add latency targets: "p95 end-to-end Telegram response <10s (cloud), <15s (Limited Mode)."

**A13.** Add environment pinning & rollback plan.
*Source:* OAI-R10 (UF8).
*Action:* Add to TMA-002 or create TMA-002a: "Document exact OpenClaw version, Ollama version, Modelfile hash, launchd plist, and rollback procedure."

**Defer (minor or speculative):**

**A14.** Justify 64K context for mechanical agent or allow tiered context.
*Source:* OAI-R8 (UF6). Defer to TMA-005/TMA-007.

**A15.** Add Ollama service crash as R15 (renumber to R16 given A11).
*Source:* DS-R15 (UF9). Defer — launchd manages restarts. Add brief risk entry.

**A16.** Increase persona rubric sample size guidance.
*Source:* OAI-R11. Defer to TMA-006.

**A17.** Measure heartbeat/user message interval distribution.
*Source:* GRK-REVIEW-10 (UF10). Defer to TMA-005.

**A18.** Add power draw measurement to TMA-005.
*Source:* GRK-REVIEW-14. Defer — fold into TMA-005 AC.

**A19.** Add persona drift risk (SOUL.md changes).
*Source:* PPLX-C3. Defer — valid but can be a simple risk register addition.

**A20.** Label Tier 3 as "on-demand escalation."
*Source:* PPLX-C1. Defer — cosmetic clarification.

**A21.** Add "Future simplification" subsection (mechanical-as-service).
*Source:* PPLX-C2. Defer — useful orientation note, not blocking.

**A22.** Add monitoring/observability requirements.
*Source:* PPLX-C5, DS-Completeness. Defer — belongs in deployment/ops spec, not architecture.

### Considered and Declined

**GEM-F15-vs-U11** (F15 should be an Assumption, not a Fact): Declined — `incorrect`. F15 documents what routing research found about per-agent model reliability. U11 asks about mixed-provider gateway hosting. These are different claims.

**GEM-TMA-008-Deadlock** (CRITICAL deadlock in dependency graph): Declined — `constraint`. This is a scheduling risk inherent to dual-critical-path design, not a spec defect. The spec already identifies TMA-008 as the convergence point. Prioritizing TMA-006 is good operational advice (adopted in AN3 guidance), not a spec fix.

**GRK-REVIEW-12** (Task graph missing TMA-009 → TMA-010 dependency): Declined — `incorrect`. The graph already shows `TMA-008 ──── TMA-009 ──── TMA-010` with TMA-009 preceding TMA-010.

**GRK-REVIEW-6** (double-failure: both API and local down): Declined — `overkill`. Simultaneous Anthropic API outage and Ollama service crash is extremely low-probability. Third-level fallback adds complexity without proportional benefit.

**GRK-REVIEW-8** (KV cache types not split in promotion gate): Declined — `incorrect`. Section 8.1 promotion gate already specifies "Holds 64K context with target KV cache quantization" and §10 has rows for both q8_0 and q4_0.

**DS-C1** (Configuration management process): Declined — `out-of-scope`. Valid operational concern, but belongs in deployment phase, not architecture spec.

**DS-Logging-Observability** (as must/should-fix): Declined — `out-of-scope`. Deferred as A22 instead. Belongs in deployment/ops spec.
