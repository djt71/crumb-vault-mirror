---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/specification.md
artifact_type: specification
artifact_hash: 9e28eafa
prompt_hash: 35fcbae6
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
    latency_ms: 68515
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-tess-v2-specification-openai.json
  google:
    http_status: 200
    latency_ms: 41320
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-tess-v2-specification-google.json
  deepseek:
    http_status: 200
    latency_ms: 65488
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-tess-v2-specification-deepseek.json
  grok:
    http_status: 200
    latency_ms: 20127
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-03-28-tess-v2-specification-grok.json
tags:
  - review
  - peer-review
status: active
---

# Peer Review: Tess v2 Specification

**Artifact:** Projects/tess-v2/design/specification.md
**Mode:** full
**Reviewed:** 2026-03-28
**Reviewers:** OpenAI (gpt-5.4), Google (gemini-3.1-pro-preview), DeepSeek (deepseek-reasoner), Grok (grok-4-1-fast-reasoning)
**Review prompt:** Full specification review — correctness, completeness, internal consistency, feasibility, clarity. Unverifiable claims flagged.

---

## OpenAI (gpt-5.4)

Below is a structured review of the Tess v2 specification, focused on correctness, completeness, internal consistency, feasibility, and clarity.

## Overall Assessment

This is a strong systems specification. It has clear constraints, explicit assumptions/unknowns, a credible phased migration plan, and good architectural discipline around vault authority, evaluator/executor separation, and mechanical enforcement. The biggest risks are not conceptual but operational: concurrency/state coordination, confidence calibration, platform maturity, and under-specified monitoring/rollback mechanics for a distributed autonomous system.

---

## Findings

- [F1]
- [Severity]: STRENGTH
- [Finding]: The specification is unusually strong on decision hygiene: facts, assumptions, unknowns, constraints, and architectural decisions are explicitly separated.
- [Why]: This reduces hidden coupling and makes it easier to evaluate the project incrementally without premature commitment.
- [Fix]: None.

- [F2]
- [Severity]: STRENGTH
- [Finding]: AD-001 (vault authority) is the correct anchor decision and is reinforced consistently across system map, constraints, service model, and migration plan.
- [Why]: It prevents state fragmentation and gives the architecture a clear source of truth, which is essential once multiple executors and platforms are involved.
- [Fix]: None.

- [F3]
- [Severity]: STRENGTH
- [Finding]: The spec correctly identifies confidence-aware escalation as the central economic and safety hinge of the architecture rather than treating it as a minor implementation detail.
- [Why]: This is the main determinant of whether the local-first strategy is viable in cost and correctness terms.
- [Fix]: None.

- [F4]
- [Severity]: STRENGTH
- [Finding]: The Ralph loop model is a coherent execution primitive and aligns well with contract-based termination, fresh-session isolation, and evaluator/executor separation.
- [Why]: It meaningfully reduces context bloat, makes retry behavior explicit, and creates a tractable unit of orchestration.
- [Fix]: None.

- [F5]
- [Severity]: STRENGTH
- [Finding]: The migration strategy is conservative and sensible: parallel operation, staging outputs, service-by-service migration, and low-risk-first ordering.
- [Why]: This sharply lowers cutover risk for an operational system.
- [Fix]: None.

- [F6]
- [Severity]: CRITICAL
- [Finding]: The contract model is not yet strong enough for autonomous execution because it mixes deterministic checks, shell-style artifact verification, and human/judgment checks without a formal execution/evaluation semantics.
- [Why]: The architecture depends on contracts being the hard stop condition, but the current schema leaves ambiguity about who runs each check, in what environment, what constitutes pass/fail, and whether quality checks block termination. As written, `termination: "ALL tests pass AND ALL artifacts verified"` excludes `quality_checks`, which contradicts the evaluator-executor separation and completion model.
- [Fix]: Define a formal contract evaluation state machine. Specify:
  1. who executes each check type,
  2. whether checks are blocking or advisory,
  3. whether `quality_checks` are mandatory for completion,
  4. the runtime/environment for `verification` commands,
  5. normalized result schema (`pass/fail/error/not-run`),
  6. whether Tess can delegate checks,
  7. whether a contract can terminate before quality review.

- [F7]
- [Severity]: CRITICAL
- [Finding]: Concurrent vault access is acknowledged as an unknown, but the architecture already assumes orchestrator-owned write coordination while also allowing multiple executors to write artifacts directly.
- [Why]: This is an unresolved contradiction in the write model. If executors write directly, Tess does not fully own write coordination. If Tess owns coordination, executors likely need isolated workspaces plus commit/merge semantics. Without this, corruption, race conditions, and inconsistent state are likely.
- [Fix]: Choose and specify one write pattern before migration:
  - executor writes only to isolated staging/work directories, Tess promotes to canonical vault paths after evaluation; or
  - executor writes to reserved path scopes with file locking and conflict detection.
  The first is safer and more consistent with AD-001.

- [F8]
- [Severity]: CRITICAL
- [Finding]: Observability and failure detection are under-specified for a system that explicitly expects silent distributed failures.
- [Why]: The spec notes distributed silent failure as a second-order effect, but there is no architecture for monitoring, alerting, audit logs, dead-letter queues, run histories, or service-level dashboards. For an autonomous orchestrator, these are essential operational controls, not implementation details.
- [Fix]: Add a dedicated observability section covering:
  - per-service run logs,
  - contract execution ledger,
  - escalation log,
  - failure classifications,
  - heartbeat/watchdog design,
  - alert thresholds,
  - dead-letter/replay queue,
  - dashboard or daily health digest,
  - audit trail for every vault write and dispatch decision.

- [F9]
- [Severity]: CRITICAL
- [Finding]: The confidence-aware escalation design is conceptually plausible but not yet sufficient as a safety mechanism for orchestration decisions.
- [Why]: The recommended hybrid relies on task-type boundary checks plus self-reported confidence, but many dangerous failures occur within known classes, not only at class boundaries. A known class with subtly wrong routing, dependency ordering, or risk assessment may still be confidently mishandled.
- [Fix]: Add a third gate: policy/risk-based escalation independent of model confidence. For example:
  - any task touching credentials, destructive file operations, financial actions, or user-facing messaging above a threshold requires frontier review or deterministic policy checks;
  - any low-frequency class or first-instance class escalates by default;
  - any contract with low evaluator score on prior similar tasks raises escalation propensity.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: The spec assumes that action classes and routing tables will be sufficiently crisp to support deterministic boundary checks, but those artifacts are not defined here.
- [Why]: The viability of Tier 1/Tier 2 routing depends on stable ontology and classification rules. Without a defined action-class taxonomy, “known task type” remains subjective.
- [Fix]: Add a formal action-class schema and routing-table spec with examples, precedence rules, ambiguity handling, and fallback behavior.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The service model is good, but it does not define service lifecycle semantics such as idempotency, reentrancy, missed-run recovery, duplicate suppression, and backfill behavior.
- [Why]: Scheduled autonomous services fail in practice around retries, overlapping runs, stale cursors, and partial completion. The current service schema is insufficient for reliable operations.
- [Fix]: Extend service schema with:
  - idempotency key/cursor definition,
  - max run duration,
  - overlap policy,
  - retry policy,
  - backfill strategy,
  - exactly-once/at-least-once semantics,
  - checkpoint storage path.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Security boundaries are under-specified for an orchestrator that can dispatch to multiple executors with vault read/write paths and overlays.
- [Why]: Dispatching path scopes alone is not enough. Without capability restrictions, an executor may exceed intended authority, expose secrets, or mutate unrelated vault state.
- [Fix]: Add a capability/security model:
  - per-executor permission scopes,
  - credential handling/isolation,
  - secret redaction policy,
  - path allowlists enforced by runner,
  - network/tool access classes,
  - approval requirements for destructive actions.

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: The cost model and architecture are slightly inconsistent. §17 estimates total monthly cost at $10-55/month while constraint C5 says cost must stay “well under $50/month.”
- [Why]: A success criterion should not be contradicted by its own estimated operating range.
- [Fix]: Reconcile the budget by either:
  - tightening the architecture to cap cost below $50 in realistic peak scenarios, or
  - revising C5 to “target under $50/month, hard ceiling $60 during migration/evaluation.”

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: The success criterion “zero service interruptions during cutover” is unrealistic for a distributed migration unless very narrowly defined.
- [Why]: This creates a brittle pass/fail condition that may be impossible to prove and could discourage safe migration if a minor non-user-facing interruption occurs.
- [Fix]: Replace with an SLO-style criterion, e.g.:
  - no missed user-critical outputs,
  - no interruption > X minutes for noncritical services,
  - no data loss,
  - automatic rollback on two consecutive failed runs.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: The relationship between Hermes memory and vault authority is directionally correct but operationally under-specified.
- [Why]: “Session-level convenience only” is not enough to avoid split-brain. The system needs explicit rules for what Hermes memory may contain, whether it can influence decisions, and when/how it is refreshed or invalidated.
- [Fix]: Add memory governance rules:
  - allowed memory classes,
  - TTL/expiry,
  - no durable facts outside vault,
  - memory hydration from vault at session start,
  - memory invalidation on vault updates,
  - tests specifically for split-brain scenarios.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: The spec does not define executor return format or dispatch/result envelope beyond a small overlay example.
- [Why]: Orchestration quality depends on normalized interfaces. Without a standard result envelope, evaluator logic and retries will become executor-specific and fragile.
- [Fix]: Add canonical schemas for:
  - dispatch envelope,
  - execution attempt record,
  - artifact manifest,
  - evaluator result,
  - escalation payload,
  - failure summary.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: The “retry_budget: 3” pattern is reasonable, but retry strategy is under-specified.
- [Why]: Repeating the same executor with similar context may not improve outcomes. Some failures should trigger model/executor switch, human review, or deterministic remediation rather than simple repetition.
- [Fix]: Define retry classes:
  - deterministic failure → fix input/environment and retry same executor,
  - reasoning failure → escalate model tier,
  - tool failure → defer/requeue,
  - repeated semantic failure → route to alternate executor or human.

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: The spec lacks an explicit policy for destructive or externally visible actions.
- [Why]: Autonomous orchestration is much riskier when actions affect external systems, user communications, or irreversible state.
- [Fix]: Add a risk policy matrix mapping action classes to required safeguards:
  - read-only,
  - reversible write,
  - irreversible write,
  - external communication,
  - credential mutation,
  - deletion/destructive operations.

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: The local LLM evaluation suite is promising but still too narrow for the architecture described.
- [Why]: Seven or eight tests may validate tool use and prompt degradation, but not long-horizon orchestration behavior, prompt injection resistance, malformed tool outputs, or stateful error recovery.
- [Fix]: Add tests for:
  - malformed/stale tool outputs,
  - conflicting evidence,
  - adversarial or irrelevant context,
  - repeated-run consistency under load,
  - state reconciliation after partial failures,
  - policy-triggered escalation.

- [F20]
- [Severity]: SIGNIFICANT
- [Finding]: The spec refers to “all six revenue prompts” in the problem statement, but those are not described or linked in the system map or task decomposition.
- [Why]: This weakens traceability from strategic objective to system requirements.
- [Fix]: Add a brief reference section listing the six prompt classes or link them explicitly as upstream business drivers.

- [F21]
- [Severity]: SIGNIFICANT
- [Finding]: The migration section omits a data migration/compatibility plan for state formats, cursors, and historical run metadata.
- [Why]: Service portability often fails not on prompts or cron definitions but on mismatched state assumptions and partial historical data.
- [Fix]: Add a state migration checklist:
  - cursor/state file inventory,
  - schema transformations,
  - replay/backfill plan,
  - validation of last-run timestamps,
  - rollback compatibility.

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: The role of Danny is clear at a high level but not operationally defined in escalation flows.
- [Why]: The spec says Tess should surface results when human decision is required, but there is no thresholding or SLA for human escalation.
- [Fix]: Define human escalation classes:
  - urgent/blocking,
  - review-within-24h,
  - FYI digest,
  including allowed channels, timeout behavior, and fallback if Danny is unavailable.

- [F23]
- [Severity]: MINOR
- [Finding]: “The noun” in the vault diagram is evocative but not specification-grade terminology.
- [Why]: It adds style but not precision, and may confuse future readers outside the originating context.
- [Fix]: Replace with a more formal phrase such as “authoritative state and knowledge substrate.”

- [F24]
- [Severity]: MINOR
- [Finding]: “Fresh context per iteration” is a useful principle, but the line between failure context and retained context is not precise.
- [Why]: In practice, teams will need guidance on what can be carried across Ralph iterations without reintroducing context sprawl.
- [Fix]: Define a bounded iteration context payload, e.g. prior attempt summary, failed checks, changed files, and tool errors only.

- [F25]
- [Severity]: MINOR
- [Finding]: The sequence in §14.2 lists Apple snapshots as item 2 while also saying it is not migrating.
- [Why]: This slightly weakens the readability of the migration ordering.
- [Fix]: Move it to a “non-migrating retained services” note outside the numbered migration sequence.

- [F26]
- [Severity]: MINOR
- [Finding]: The distinction between “task,” “contract,” “service,” and “Ralph loop” is mostly clear but would benefit from a short glossary.
- [Why]: These are core terms and subtle confusion between them could affect implementation.
- [Fix]: Add a terminology section with one-line definitions and relationships.

- [F27]
- [Severity]: MINOR
- [Finding]: Some pass/fail criteria use subjective scoring scales without rubric detail in the spec itself.
- [Why]: This may create evaluator drift if multiple people revisit the project later.
- [Fix]: Include or link explicit scoring rubrics for each 1-5 criterion.

- [F28]
- [Severity]: MINOR
- [Finding]: The architecture says “one contract per session” but does not specify whether one service run can emit multiple contracts atomically.
- [Why]: This matters for decomposition and dependency ordering.
- [Fix]: Clarify whether Tess may decompose a service run into a DAG of contracts and what atomicity guarantees apply.

- [F29]
- [Severity]: STRENGTH
- [Finding]: The spec avoids overcommitting to Hermes, GLM, or even local-first viability; it preserves fallback paths and requires evidence before adoption.
- [Why]: This keeps the project grounded and reduces architecture-by-enthusiasm.
- [Fix]: None.

- [F30]
- [Severity]: STRENGTH
- [Finding]: The integration of eval-based building with existing spec-first workflow is thoughtful and practically aligned with how teams actually get from planning to autonomous execution.
- [Why]: It leverages existing assets instead of introducing a parallel methodology.
- [Fix]: None.

---

## Unverifiable Claims Requiring Grounded Verification

Per your instruction, below are factual claims I cannot independently verify and should be checked against primary sources.

- [F31]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “OpenClaw model routing broken — fallback chains fail silently, cross-provider failover doesn't trigger, generic errors bypass failover classifier (v2026.3.24).”
- [Why]: This is a key premise for platform replacement and should be backed by reproducible incident evidence, issue links, or test logs.
- [Fix]: Cite internal incident reports, commit references, failing test cases, or issue IDs.

- [F32]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Mac Studio M3 Ultra: 96GB unified memory, 800 GB/s bandwidth, ~85-90GB usable for inference.”
- [Why]: Hardware capability assumptions drive local-model feasibility and sizing.
- [Fix]: Add source references or benchmark notes, and separate manufacturer specs from observed usable memory.

- [F33]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Qwen3.5 27B went all-green on independent tool-calling tests (15 scenarios, 12 tools, temperature 0). Larger models (397B, 122B, 35B) all failed at least one test.”
- [Why]: This is central to model selection and should be traceable to a reproducible eval artifact.
- [Fix]: Link the evaluation report, test harness, prompts, and result logs.

- [F34]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Ollama routes Qwen3.5 through wrong tool-calling pipeline as of March 2026 ... Tracked at ollama/ollama#14493.”
- [Why]: This is a decisive implementation constraint.
- [Fix]: Verify the issue number, quote the issue summary, and include current status.

- [F35]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Hermes Agent by Nous Research: MIT license, 8.8k stars, v0.3.0, ~1 month old.”
- [Why]: Platform maturity and licensing are important selection criteria.
- [Fix]: Add repository URL, tag/version reference, and date the metrics were observed.

- [F36]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Haiku cannot reliably execute procedures from SOUL.md ... solution: `haiku-soul-behavior-injection`.”
- [Why]: This influences the overlay and dispatch design, but appears to rely on internal prior findings.
- [Fix]: Link to the internal note, experiment report, or pattern doc.

- [F37]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “`claude --print` structured output requires 3-6 live deployment iterations per operation class ... solution: `claude-print-automation-patterns`.”
- [Why]: This informs retry/calibration policy and should be supported by an explicit internal reference.
- [Fix]: Cite the internal pattern document and summarize the observed sample size.

- [F38]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Gate evaluation pattern validated across multiple Crumb projects ... solution: `gate-evaluation-pattern`.”
- [Why]: This is used to justify evaluator/executor separation.
- [Fix]: Reference the internal document or examples.

- [F39]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Qwen3.5 27B ... 262K native context ... ties GPT-5 mini on SWE-bench.”
- [Why]: These are specific model capability claims that may materially affect evaluation expectations.
- [Fix]: Provide links to model card, benchmark source, and exact benchmark variant/date.

- [F40]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “GLM-4.7-Flash ... MIT license ... 200K context ... 60-80+ tok/s estimated.”
- [Why]: These claims drive the dual-model evaluation rationale.
- [Fix]: Cite model card/licensing source and distinguish measured throughput from estimate.

---

## Summary Judgment

### Correctness
Mostly strong conceptually, but not yet correct enough for implementation in three areas:
1. contract semantics,
2. concurrent write/state model,
3. observability/failure-handling architecture.

### Completeness
Good for a strategy spec, incomplete for an execution spec. Missing key operational details around capability boundaries, monitoring, executor interfaces, service lifecycle semantics, and state migration.

### Internal Consistency
Generally consistent, with notable tensions:
- contract termination vs quality checks,
- Tess-owned write coordination vs direct executor writes,
- budget target vs estimated monthly total.

### Feasibility
Feasible as a phased evaluation and migration program. Less certain as a fully autonomous production orchestrator until the critical operational controls are specified and validated. The overall direction is sound; the main feasibility risks are maturity of Hermes, local-model calibration under real prompts, and safe multi-executor vault coordination.

### Clarity
Clear and readable overall. The architecture is understandable and the phases are well organized. A glossary, formal schemas, and explicit state-machine semantics would make it implementation-ready.

If useful, I can next convert this into:
1. a redline-ready revision checklist, or
2. a “blocking issues before Phase 1” shortlist.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of the Tess v2 specification.

### Review Findings

- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Hardware and software versions from the future (e.g., Mac Studio M3 Ultra, OpenClaw v2026.3.24, Qwen3.5 27B, GLM-4.7-Flash, GPT-5 mini).
- [Why]: As an AI, my knowledge cutoff prevents me from verifying technologies or release dates from 2026. These references appear to be from a highly specific future, speculative, or private fictional context. 
- [Fix]: If this is a real-world spec, adjust hardware and models to currently existing versions (e.g., M2 Ultra, Qwen 1.5/2.5, GLM-4). If this is a speculative or world-building artifact, this finding can be safely ignored.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Specific open-source repositories, issues, and statistics (e.g., Ollama issue `ollama/ollama#14493`, Hermes Agent by Nous Research `v0.3.0` with 8.8k stars).
- [Why]: I cannot independently confirm the existence, exact content, or star count of these specific GitHub artifacts. While Nous Research creates the "Hermes" family of models, a dedicated "Hermes Agent" orchestration framework matching this exact description cannot be verified against standard public records up to my current knowledge base.
- [Fix]: Manually verify that these repository links and issue numbers are accurate and that the tools possess the advertised capabilities (especially OpenRouter nativeness and subagent delegation) before committing to Phase 1.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Reliance on OpenAI Codex as an implementation executor (Sections 3.1, 3.2, and 17).
- [Why]: OpenAI officially deprecated and shut down the Codex API in March 2023. Relying on a Codex subscription as a bridge-state code implementation executor is structurally broken and will fail at dispatch.
- [Fix]: Update the executor stack to use modern code-capable models (e.g., GPT-4o, Claude 3.5 Sonnet, or specialized coding models like DeepSeek Coder via API).

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: The fallback plan for local LLM failure (Section 13.6) violates the strict cost constraint (C5).
- [Why]: Constraint C5 mandates a total orchestration cost well under $50/month. Section 17 estimates Frontier decisions cost ~$0.01-0.05 each. If the local LLM fails and Tier 2/3 decisions (plus some Tier 1) all route to OpenRouter at ~100 decisions/day, the orchestration layer alone will cost $30-$150/month, blowing past the $50 constraint before accounting for executor usage ($7-$40/month).
- [Fix]: Update the fallback plan to either explicitly waive Constraint C5 during the fallback period, or specify a cheaper remote model (e.g., Claude 3 Haiku or GPT-4o-mini) as the Tier 1/2 routing fallback to maintain budget compliance.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: The exact execution boundary of the "Ralph Loop" (Section 9) within the Hermes Agent platform is undefined.
- [Why]: Hermes is being evaluated as the primary platform (Section 12), but it is unclear if Hermes natively supports the exact isolated "Ralph Loop" pattern (strict iteration budgets + specific failure context injection + mechanical hard stops) or if this requires custom runner scripts *outside* Hermes. If Hermes subagents don't natively halt and return strict failure contexts, the primitive breaks.
- [Fix]: Add an explicit evaluation criterion in Section 12.1 to test whether Hermes Agent natively supports building Ralph Loops, or explicitly define Ralph Loops as external Python/Bash scripts that Hermes triggers.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Unconstrained context bloat via Overlay Injection (Section 10).
- [Why]: Overlays + Vault Context + Task Contract + Failure Context (in a Ralph Loop) could easily bloat the context window. While Test 8 checks 8-15K tokens, an unconstrained overlay injection (combining default, project, and requested overlays) could silently push context beyond the optimal reasoning window of a 27B model, leading to silent instruction ignoring.
- [Fix]: Introduce a strict token budget or maximum overlay count per dispatch envelope. Add a deterministic check to the orchestration layer to truncate or reject dispatches that exceed the optimal context threshold.

- [F7]
- [Severity]: MINOR
- [Finding]: Phase 4 tasks (Migration) don't explicitly reference the gating on Phase 3 output in their "Depends On" column (Section 15).
- [Why]: While the section header says Phase 4 is "gated by Phase 3", TV2-017 (Migrate services) only lists TV2-014 and TV2-016 as dependencies. It misses TV2-015 (Vault concurrent access model), which is logically required before multiple autonomous services can safely run in parallel and write to the vault.
- [Fix]: Update the "Depends On" column for TV2-017 to explicitly include TV2-015.

- [F8]
- [Severity]: STRENGTH
- [Finding]: Evaluator-Executor Separation (AD-007) and Contract-Based Execution (Section 8).
- [Why]: Mechanically separating the entity doing the work from the entity grading the work directly addresses common LLM failure modes (sycophancy, premature task completion, silent failures). Using YAML-based, machine-readable contracts provides a highly robust foundation for verifying autonomous operations.

- [F9]
- [Severity]: STRENGTH
- [Finding]: The hybrid approach to confidence-aware escalation (Section 7.3).
- [Why]: Relying purely on an LLM to know when it is hallucinating or out of its depth is a known anti-pattern. Using a deterministic boundary check *first*, and relying on the structured confidence field only for the middle band of semi-novel tasks, is an excellent, highly feasible engineering compromise.

- [F10]
- [Severity]: STRENGTH
- [Finding]: Parallel Operation Protocol and Migration Sequencing (Section 14).
- [Why]: The transition plan is exceptionally well thought out. Migrating services from low-risk to high-visibility while enforcing a parallel run / staging directory comparison ensures the core system (OpenClaw) remains stable while the new platform proves its reliability.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of Tess v2 Specification**

**Overall Assessment:** This is a highly detailed, well-structured, and internally consistent specification for a complex system migration and architectural evolution. It demonstrates strong systems thinking, integrates lessons from prior patterns, and presents a clear, phased, and risk-aware plan. The primary concerns relate to the feasibility of some core technical assumptions and the lack of detail for critical, unsolved design problems.

---

### **Findings**

**F1**
- **Severity:** SIGNIFICANT (UNVERIFIABLE CLAIM)
- **Finding:** Claims regarding OpenClaw model routing being "broken" (F1), Ollama bug #14493 (F4), and Hermes Agent details (version, stars, features in F5) are unverifiable without access to the cited systems, GitHub issue, or repository.
- **Why:** The entire justification for the platform migration hinges on F1. The feasibility of using Qwen3.5 depends on F4. The platform choice relies on F5.
- **Fix:** Maintain these as internal project facts/assumptions. For a formal external review, these would require linked evidence or annotation as "internal observation."

**F2**
- **Severity:** SIGNIFICANT
- **Finding:** The confidence-aware escalation mechanism (§7) is correctly identified as the hardest design problem but is under-specified. The recommended hybrid approach is sensible but lacks a concrete validation plan beyond a single test. The mechanism for generating the `confidence` field is not defined (structured output template? separate prompt?).
- **Why:** The project's cost model and reliability depend on this mechanism working correctly. A poorly calibrated confidence escalator will either be too expensive (over-escalating) or produce errors (under-escalating).
- **Fix:** Expand §7.4 to include specific test scenarios for confidence calibration and define the exact prompt/structured output schema for the confidence field. Consider a "canary" phase where all escalations are logged and manually reviewed to tune the threshold.

**F3**
- **Severity:** CRITICAL
- **Finding:** The specification assumes a solution for concurrent vault writes (A4) but defers its design to Phase 3 (TV2-015). This is a foundational architectural risk. The constraint that "Vault authority is non-negotiable" (C1, AD-001) directly conflicts with undefined concurrent write mechanics.
- **Why:** If multiple executors (Ralph loops) can write simultaneously, corruption or race conditions are likely. This undermines the vault as a single source of truth.
- **Fix:** Move the vault concurrent access model design to Phase 1 or pre-evaluation. Define a primitive (e.g., a simple vault write queue managed by Tess, file-level locking via `.lock` files) before any component evaluation that assumes this capability.

**F4**
- **Severity:** SIGNIFICANT
- **Finding:** The "Three-Tier Decision Model" (§6) and "Confidence-Aware Escalation" (§7) are logically distinct but presented as interwoven. The Tier definitions (1, 2, 3) blend decision *type* with model *selection* and *cost*. This creates potential confusion in the dispatch logic.
- **Why:** An implementer could be confused about whether a task is Tier 2 because of its complexity *or* because the model used thinking mode. The flowchart from task to final model is implicit.
- **Fix:** Clarify the dispatch logic in a decision tree or flowchart. Explicitly separate: 1) Task Classification, 2) Confidence/Complexity Assessment, 3) Model & Mode Selection.

**F5**
- **Severity:** STRENGTH
- **Finding:** The integration of "eval-based building" with Crumb's "spec-first workflow" (AD-003) is a sophisticated and well-articulated core insight. The concept of deriving contracts from action plans and using them as mechanical termination gates effectively bridges planning and autonomous execution.
- **Why:** This provides a clear, principled pathway from human-driven sessions to autonomous operation, preserving rigor while enabling automation.
- **Fix:** (None – this is a strength)

**F6**
- **Severity:** STRENGTH
- **Finding:** The migration plan (§14) is excellent. It emphasizes parallel operation (AD-002), low-risk-first sequencing, explicit comparison of outputs, and clear rollback procedures. This dramatically reduces the risk of a catastrophic transition.
- **Why:** This demonstrates mature operational thinking. The plan acknowledges the criticality of existing services and provides a safe, incremental path forward.
- **Fix:** (None – this is a strength)

**F7**
- **Severity:** MINOR
- **Finding:** The cost model (§17) contains broad estimates ($10-55/month). The upper bound ($55) exceeds the stated "well under $50/month" constraint (C5). The estimate for executor costs (Claude, Gemini) is highly variable and could easily exceed the budget.
- **Why:** While preliminary, the inconsistency with C5 should be corrected. The model is highly sensitive to the 5-10% escalation rate.
- **Fix:** Revise C5 to align with the model (e.g., "under $60/month") or tighten the cost model assumptions. Add a monitoring requirement to track actual spend against forecast from day one.

**F8**
- **Severity:** SIGNIFICANT
- **Finding:** The specification lacks a dedicated section on monitoring, alerting, and observability for the new distributed system. While "heartbeat mechanics" are mentioned as a service, failures can be "silent across multiple services" (Second-Order Effects).
- **Why:** Autonomous operation requires the ability to detect stuck Ralph loops, failed dispatches, vault write errors, and model API failures without manual checking.
- **Fix:** Add a section or task (e.g., TV2-020) to define health checks, logging standards, and alert channels (likely leveraging the Telegram interface) for the orchestration layer itself.

**F9**
- **Severity:** MINOR
- **Finding:** The "Ralph Loop Execution" section (§9) is clear but slightly conflates the *pattern* with the *implementation*. It's ambiguous whether a "Ralph loop" is a formal subprocess launched by Hermes/Tess or simply a conceptual pattern for a constrained session.
- **Why:** This could lead to ambiguity during implementation about what manages the loop's iteration state (Tess's memory? a file in the vault?).
- **Fix:** Add a brief "Implementation Note" clarifying that the loop state (iteration count, failure context) is managed by Tess (the orchestrator) and injected as part of the context for the next iteration.

**F10**
- **Severity:** STRENGTH
- **Finding:** The document consistently integrates lessons from prior Crumb patterns (`haiku-soul-behavior-injection`, `gate-evaluation-pattern`, etc.) into architectural decisions (AD-006, AD-007). This shows a valuable learning feedback loop.
- **Why:** It grounds speculative design in proven, internal experience, increasing the likelihood of practical success.
- **Fix:** (None – this is a strength)

---

## Grok (grok-4-1-fast-reasoning)

- [F001]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: F1 states OpenClaw model routing is broken in v2026.3.24 with specific failure modes (silent fallbacks, no failover).
- [Why]: Core justification for platform switch; if untrue, entire problem statement collapses. Cannot confirm proprietary/internal software state.
- [Fix]: Operator to provide logs/screenshots or eval report confirming breakage.

- [F002]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: F3 claims Qwen3.5 27B "went all-green" on 15 tool-calling scenarios vs. failures in larger models (397B, 122B, 35B).
- [Why]: Pivotal fact for selecting 27B as Tier 1-2 brain; unverified test results undermine model choice and pass criteria in §13.4.
- [Fix]: Link to test suite repo/results or re-run publicly verifiable benchmarks (e.g., Berkeley Function Calling Leaderboard).

- [F003]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: F4 cites ollama/ollama#14493 for Qwen3.5 tool-calling pipeline mismatch (XML vs. Hermes JSON).
- [Why]: Directly impacts C4 (no Ollama) and local LLM setup; if resolved or nonexistent, simplifies architecture but spec locks out viable option.
- [Fix]: Verify GitHub issue status; test Ollama + Qwen3.5 directly in Phase 2.

- [F004]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: F5 describes Hermes Agent (Nous Research, MIT, 8.8k stars, v0.3.0, ~1 month old as of 2026-03-28) with specific features (Telegram support, memory, subagents, cron).
- [Why]: Candidate platform; inaccurate details could fail Phase 1 eval (e.g., no local server support per A1).
- [Fix]: Provide repo link; confirm features via README/tests before Phase 1.

- [F005]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: F2 specifies Mac Studio M3 Ultra with 96GB unified memory, 800 GB/s bandwidth, ~85-90GB usable for inference.
- [Why]: Hardware constraint for local LLM (27GB model + cache); wrong specs derail feasibility (e.g., OOM errors).
- [Fix]: Confirm via `system_profiler SPHardwareDataType` output or Apple specs.

- [F006]
- [Severity]: CRITICAL
- [Finding]: Internal inconsistency in concurrent vault access: A4 assumes vault handles multiple writes without corruption (to validate Phase 3), but U4 lists concurrent patterns as unknown, and no design/solution proposed pre-Phase 3 (TV2-015 only after gates).
- [Why]: Violates C1 (vault authority); if unresolved, multi-executor Ralph loops risk data loss, halting migration (Phase 4).
- [Fix]: Elevate to Phase 0: prototype vault locking (e.g., file locks via fcntl) and add to TV2-002.

- [F007]
- [Severity]: SIGNIFICANT
- [Finding]: §17 cost model assumes "~100 decisions/day" with 5-10% Tier 3 at $0.01-0.05/decision, yielding $10-55/month, but C5 caps at <$50/month; executor costs ($5-30 Claude) are "usage dependent" without bounds.
- [Why]: Economic case hinges on this; unbounded executor volume (e.g., Ralph retries) could exceed budget, killing feasibility.
- [Fix]: Add daily decision volume source (e.g., OpenClaw logs); cap executor retries/Tier 3 dispatches; model worst-case (20% Tier 3).

- [F008]
- [Severity]: SIGNIFICANT
- [Finding]: Second-order effects note increased vault write volume/merge conflicts and distributed failure modes, but no architecture for monitoring/alerting (e.g., service health checks are per-service in §11, no global dashboard).
- [Why]: Predicts new failure modes post-migration; without proactive design, "silent failures" (F12-informed) become likely, undermining autonomy.
- [Fix]: Add Phase 3 task TV2-016.5: "Monitoring service" with Prometheus/Grafana for vault commits, service uptime, escalation rates.

- [F009]
- [Severity]: MINOR
- [Finding]: Task decomposition (§15) lacks explicit owners/estimators (e.g., #research tasks assume Tess/Claude, but TV2-001 is pre-eval manual?); risk levels (low/medium/high) not quantified.
- [Why]: Reduces executability in autonomous dispatch; Crumb workflow expects this for TASK phase.
- [Fix]: Add columns: Owner (e.g., claude-sonnet), Est Hours; quantify risk (e.g., medium = 20-50% failure prob).

- [F010]
- [Severity]: MINOR
- [Finding]: Contract schema (§8.2) verification examples mix shell commands (grep) with vague "all services tagged"; quality_checks delegate to "tess" without escalation budget.
- [Why]: Mechanical enforcement (AD-006) weakened if verifiers are ambiguous/non-deterministic.
- [Fix]: Standardize verifiers (e.g., YAML frontmatter schema check); nest retry_budget under quality_checks.

- [F011]
- [Severity]: STRENGTH
- [Finding]: Phased migration (§14) with parallel operation (AD-002), low-risk-first sequence, and inventory table ensures zero-downtime transition.
- [Why]: Addresses feasibility risks head-on; aligns with C2 and gate-evaluation pattern (F12).
- [Fix]: N/A

- [F012]
- [Severity]: STRENGTH
- [Finding]: Three-tier + hybrid escalation (§6-7) with Test 8 (production prompt degradation) rigorously gates local LLM feasibility.
- [Why]: Directly mitigates over-reliance on isolated benchmarks (A2/A3); data-driven (e.g., §13.5 dual-model decision).
- [Fix]: N/A

- [F013]
- [Severity]: STRENGTH
- [Finding]: Ralph loop (§9) + contract schema (§8) + overlay injection (§10) form a tight, eval-integrated execution primitive.
- [Why]: Prevents context bloat/infinite loops (AD-004/006); extends Crumb patterns scalably (F6/F8/F10).
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Concurrent vault access is underspecified (CRITICAL)**
Sources: OAI-F7, DS-F3, GRK-F006

All three independent reviewers flagged this as the most dangerous gap. The spec acknowledges concurrent writes as unknown (U4) and defers design to Phase 3 (TV2-015), but the architecture already assumes "orchestrator-owned write coordination" while also describing executors writing directly. This is a contradiction that threatens AD-001 (vault authority). OpenAI recommends executor-writes-to-staging with Tess-promotes-to-canonical; DeepSeek wants it elevated to Phase 0/1; Grok suggests prototyping file locking immediately.

**2. Observability and monitoring absent (CRITICAL/SIGNIFICANT)**
Sources: OAI-F8, DS-F8, GRK-F008

The spec predicts distributed silent failures as a second-order effect but provides no architecture for detecting them. All three reviewers independently flagged this. For an autonomous orchestrator, monitoring, alerting, run histories, and health dashboards are essential operational controls — not implementation details to figure out later.

**3. Cost model contradicts constraint C5 (SIGNIFICANT)**
Sources: OAI-F13, GEM-F4, DS-F7, GRK-F007

All four reviewers flagged it. The $10-55/month estimated range exceeds the "well under $50/month" stated in C5. Gemini additionally notes the LLM-failure fallback (§13.6) would blow the budget entirely.

**4. Confidence escalation needs more design depth (CRITICAL/SIGNIFICANT)**
Sources: OAI-F9, DS-F2

OpenAI argues the hybrid approach misses within-class failures and needs a third gate (risk/policy-based escalation). DeepSeek wants concrete validation scenarios and the exact structured output schema. Both agree: this is correctly identified as hard but not yet designed to the depth it requires.

**5. Ralph loop implementation boundary unclear (SIGNIFICANT/MINOR)**
Sources: GEM-F5, DS-F9

Is the Ralph loop native to Hermes Agent, or external scripts? If Hermes doesn't support strict iteration budgets + failure context injection + mechanical hard stops, the execution primitive needs to be built separately. This should be an explicit Phase 1 evaluation criterion.

### Unique Findings

**OAI-F10: Action-class taxonomy not defined** (SIGNIFICANT)
Genuine insight. "Known task type" drives the deterministic boundary check in the escalation model, but no taxonomy is defined. However, this emerges from Phase 2 testing — premature to lock down now. Recommend noting as Phase 3 deliverable.

**OAI-F12: Security boundaries underspecified** (SIGNIFICANT)
Genuine insight. Per-executor permission scopes, credential isolation, secret redaction, path allowlists — all needed for an orchestrator dispatching to multiple executors with vault access. Recommend adding as Phase 3 design task.

**OAI-F16: Executor return format undefined** (SIGNIFICANT)
Genuine. The dispatch envelope has a sketch (§10.1) but no canonical result envelope (execution record, artifact manifest, evaluator result, failure summary). Recommend adding directional schema during Phase 3.

**OAI-F17: Retry failure classes undifferentiated** (SIGNIFICANT)
Genuine. Deterministic failures (bad input), reasoning failures (wrong approach), and tool failures (API down) need different retry strategies. Simple repetition won't fix a reasoning failure. Recommend adding to contract schema design.

**OAI-F22: Human escalation taxonomy undefined** (SIGNIFICANT)
Genuine. The spec says Tess surfaces results when human decisions are needed but doesn't classify urgency or define timeout behavior when Danny is unavailable.

**OAI-F15: Hermes memory governance rules needed** (SIGNIFICANT)
Genuine extension of AD-001. "Session-level convenience" needs operational rules: what can be stored, TTL, vault-hydration at session start, invalidation on vault updates.

**GEM-F6: Overlay dispatch context bloat risk** (SIGNIFICANT)
Genuine and sharp. Overlays + vault context + contract + failure context could silently exceed the 27B model's effective reasoning window. Needs a token budget or max overlay count per dispatch.

**GEM-F7: TV2-017 missing TV2-015 dependency** (MINOR)
Correct catch. Vault concurrent access model (TV2-015) is logically required before multi-executor migration (TV2-017).

**OAI-F11: Service lifecycle semantics** (SIGNIFICANT)
Genuine. Idempotency, overlap policy, missed-run recovery, cursor management — these are how scheduled services actually fail in production. Recommend as Phase 3 design.

### Contradictions

**Vault concurrency timing:** DeepSeek says move to Phase 0/1. OpenAI says resolve before migration. Both agree it must be addressed; they disagree on when. Crumb assessment: define the *approach* (staging → promotion) now as a constraint; detailed implementation is Phase 3. This resolves both concerns without premature engineering.

**Contract schema severity:** OpenAI flags the schema as CRITICAL (needs a formal state machine). Grok flags verifiers as MINOR (just standardize). The gap is real — the schema is directional not implementation-ready — but it's appropriate for a SPECIFY artifact. The detailed contract design is Phase 3 (TV2-013). OpenAI is right about *what's needed* but treating it as a spec blocker is premature.

### Action Items

**Must-fix** (before moving to PLAN):

| ID | Source | Action |
|---|---|---|
| A1 | OAI-F7, DS-F3, GRK-F006 | **Vault write model:** Add a stated constraint — executors write to isolated staging paths; Tess promotes to canonical vault locations after evaluation. Detailed locking/conflict design remains in TV2-015 (Phase 3), but the *approach* is decided now. |
| A2 | OAI-F8, DS-F8, GRK-F008 | **Observability section:** Add §18 covering minimum monitoring requirements: per-service run logs, contract execution ledger, escalation log, alert channels, health digest. Add TV2-015.5 or extend TV2-014. |
| A3 | OAI-F9, DS-F2 | **Confidence escalation — add risk-based gate:** Third gate in the hybrid: policy/risk-based escalation for credential-touching, destructive, external-comms, or first-instance task classes. Define the structured output schema for the `confidence` field. |

**Should-fix** (improve spec quality, not blocking):

| ID | Source | Action |
|---|---|---|
| A4 | OAI-F13, GEM-F4, DS-F7, GRK-F007 | **Reconcile C5:** Change to "target under $50/month, hard ceiling $75 during evaluation/migration." |
| A5 | GEM-F5, DS-F9 | **Ralph loop eval criterion:** Add to §12.1 — "Can Hermes natively support iteration budgets + failure context injection + hard stops, or must Ralph loops be external scripts?" |
| A6 | GEM-F6 | **Overlay dispatch token budget:** Add a max token budget or overlay count per dispatch envelope. |
| A7 | OAI-F6, GRK-F010 | **Contract schema:** Clarify blocking vs. advisory checks, who executes each type. |
| A8 | OAI-F16 | **Executor return envelope:** Add directional schema for result format. |
| A9 | OAI-F17 | **Retry failure classes:** Distinguish deterministic/reasoning/tool failures in retry strategy. |
| A10 | OAI-F22 | **Human escalation taxonomy:** Define urgent/review-within-24h/FYI with timeout behavior. |
| A11 | GEM-F7 | **Dependency fix:** Add TV2-015 as dependency for TV2-017. |

**Defer** (Phase 3+ design work):

| ID | Source | Action |
|---|---|---|
| A12 | OAI-F10 | Action-class taxonomy — emerges from Phase 2 LLM testing |
| A13 | OAI-F12 | Per-executor security/capability model — Phase 3 design |
| A14 | OAI-F11 | Service lifecycle semantics (idempotency, overlap, backfill) — Phase 3 |
| A15 | OAI-F21 | State migration checklist for cursors/metadata — Phase 4 pre-work |
| A16 | OAI-F15 | Hermes memory governance rules — Phase 1 eval + Phase 3 design |
| A17 | OAI-F26 | Glossary — nice to have, add if spec grows |

### Considered and Declined

| Finding | Justification | Reason |
|---|---|---|
| GEM-F3 (Codex deprecated) | This refers to OpenAI's Codex CLI agentic tool (2025+), not the deprecated Codex API (2023). Gemini's knowledge cutoff caused confusion. | incorrect |
| GEM-F1 (future dates/technology) | These are real 2026 technologies. Reviewer's training data cutoff prevents verification — not a spec problem. | incorrect |
| OAI-F23 ("The noun" is informal) | This is Danny's personal system. The informal register is intentional and appropriate. | constraint |
| OAI-F20 (six revenue prompts not referenced) | The liberation directive is linked via project-state `related_projects`. Individual prompts are in that doc — the spec doesn't need to duplicate them. | out-of-scope |
| OAI-F19 (LLM test suite too narrow) | The spec defines evaluation criteria. The detailed test suite is Phase 2 implementation work, not spec content. Additional test types (adversarial, stale outputs, load) are appropriate Phase 2 scope. | out-of-scope |
| GRK-F009 (task owners/estimators) | This is SPECIFY phase output. Owners and estimates are assigned during TASK phase by the action-architect skill. | out-of-scope |
| OAI-F24 (iteration context payload not defined) | Valid concern but implementation-level — Phase 3 contract design will define what flows between Ralph iterations. | overkill |
