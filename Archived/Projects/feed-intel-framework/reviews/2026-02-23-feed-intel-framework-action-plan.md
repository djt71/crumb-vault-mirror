---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/feed-intel-framework/design/action-plan.md + Projects/feed-intel-framework/design/tasks.md
artifact_type: architecture
project: feed-intel-framework
domain: software
skill_origin: peer-review
created: 2026-02-23
updated: 2026-02-23
status: complete
reviewers:
  - openai
  - google
  - deepseek
  - grok
  - perplexity
config_snapshot:
  openai: gpt-5.2
  google: gemini-3-pro-preview
  deepseek: deepseek-reasoner
  grok: grok-4-1-fast-reasoning
  perplexity: sonar-reasoning-pro
safety_gate: clean (no triggers)
perplexity_dispatch:
  model: sonar-reasoning-pro
  dispatch: manual (claude.ai submission)
  raw_json: Projects/feed-intel-framework/reviews/raw/2026-02-23-feed-intel-framework-action-plan-perplexity.md
reviewer_meta:
  openai:
    model: gpt-5.2-2025-12-11
    finish_reason: stop
    prompt_tokens: 7426
    completion_tokens: 2738
    total_tokens: 10164
  google:
    model: gemini-3-pro-preview
    finish_reason: STOP
    prompt_tokens: 8014
    completion_tokens: 1248
    total_tokens: 12179
  deepseek:
    model: deepseek-reasoner
    finish_reason: stop
    prompt_tokens: 7530
    completion_tokens: 3505
    total_tokens: 11035
    reasoning_tokens: 1862
    system_fingerprint: fp_eaab8d114b_prod0820_fp8_kvcache
  grok:
    model: grok-4-1-fast-reasoning
    finish_reason: stop
    prompt_tokens: 7458
    completion_tokens: 1696
    total_tokens: 9847
---

# Peer Review: Feed Intelligence Framework — Action Plan + Tasks

**Artifact:** `Projects/feed-intel-framework/design/action-plan.md` + `Projects/feed-intel-framework/design/tasks.md`
**Review date:** 2026-02-23
**Reviewers:** OpenAI GPT-5.2, Google Gemini 3 Pro Preview, DeepSeek V3.2-Thinking, Grok 4.1 Fast Reasoning

---

## OpenAI (GPT-5.2)

**[F1]** | **CRITICAL** | Missing explicit secrets/credentials management & isolation
**Finding:** Multiple tasks require API keys/OAuth credentials (YouTube, Reddit), Telegram alerts, and likely LLM provider keys, but there is no task defining how secrets are stored, injected, rotated, and prevented from leaking into vault-resident artifacts/logs (boundary is mentioned, but not operationalized). "Configured in keychain" appears once (FIF-031) but not as a framework requirement across adapters/components.
**Why it matters:** Credentials handling is a common failure mode (security + reliability). Without a standardized mechanism, each adapter may implement ad-hoc storage and leak secrets into logs, manifests, or vault files, violating boundary/compliance expectations.
**Suggested fix:** Add an M1 task for secrets management: define secret sources (keychain/env/secret store), config schema for secret references (not raw values), redaction in logs/telemetry, and adapter API for credential retrieval; include tests ensuring secrets never appear in persisted state, vault routing, or Telegram alerts.

**[F2]** | **CRITICAL** | Cross-source canonical_id scheme inconsistency and collision risk
**Finding:** Vault router acceptance criteria (FIF-011) names files `feed-intel-{source_type}-{native_id}.md`, while RSS canonical_id is `rss:sha256[:16]` (FIF-028) and X uses `x:` prefix canonical_id (FIF-020/021). Several sources will not have a stable "native_id" suitable for filenames (RSS, possibly some URL-only items), and truncating sha256 to 16 chars increases collision probability at scale.
**Why it matters:** Filename stability is core to routing, backlinks/wikilinks, id_aliases, and dedup/merge logic. A mismatch can break routing, cause overwrites, or make migrations brittle.
**Suggested fix:** Define a single framework rule: filename derived from canonical_id (fully, or with safe encoding) rather than `native_id`. For RSS use full hash (or longer, e.g., 32 chars) and specify encoding for colon. Add unit/integration tests verifying filename uniqueness and round-trip mapping canonical_id <-> filename.

**[F3]** | **CRITICAL** | Hidden dependency: delivery channel assumptions (Telegram) not specified as shared infrastructure
**Finding:** Multiple acceptance criteria reference "Telegram alert" and digest message splitting at 4096 chars (Telegram constraint), but there is no explicit shared "messaging/notification adapter" component or task defining delivery backends, message IDs, retry semantics, and mapping to feedback protocol tables.
**Why it matters:** If delivery is tightly coupled to Telegram specifics, adding other channels or even maintaining Telegram reliably (rate limits, failures, message ID stability) becomes risky. Feedback protocol depends on robust message->item mapping.
**Suggested fix:** Add an M1 task to define and implement a "delivery transport interface" (Telegram implementation first), including rate limit handling, retries, idempotency keys, message-id persistence, and constraints (4096) as transport capabilities not hard-coded in digest renderer.

**[F4]** | **SIGNIFICANT** | Task dependency gaps around DB schema prerequisites
**Finding:** Many M1 tasks implicitly require new tables/columns (posts, adapter_runs, adapter_state, cost_log, digest_messages, topic_weights, dedup store) but schema migration tasks are not called out in M1; instead, DB changes appear in M2 migration script tasks (FIF-021). This suggests M1 core infra may be blocked until M2 completes, contradicting the milestone structure ("testable with mock adapters before any real adapter is connected").
**Why it matters:** Sequencing risk: the framework core should be runnable independently with mock adapters. If DB schema exists only after X migration, you can't properly test M1 components.
**Suggested fix:** Add explicit M1 "framework schema migrations" task(s) that create required tables/columns in a clean environment. Keep M2 migration focused on transforming legacy X data into the new schema, not defining the schema itself.

**[F5]** | **SIGNIFICANT** | Acceptance criteria not fully binary/measurable in several places
**Finding:** Multiple criteria use subjective or underspecified wording: "triage quality comparable (spot-check 10 items)" (FIF-026), "per-adapter signal quality score computed" (FIF-030) without definition, "Danny can independently evaluate signal quality" (M5 success criteria), "Phase 0 findings documented with decision" (FIF-031) without explicit decision rule.
**Why it matters:** Non-binary gates cause schedule risk and disagreements at rollout time; "feature parity" becomes contestable.
**Suggested fix:** Define concrete metrics and pass/fail thresholds: e.g., for parity, compare counts of routed items, digest section presence, command success rate, median latency, and token/cost deltas. Define "signal quality score" formula or remove it from acceptance. For Phase 0 decisions, add explicit proceed/defer criteria (quota headroom, transcript availability threshold, etc.).

**[F6]** | **SIGNIFICANT** | Migration plan under-specifies operational safety and rollback verification
**Finding:** Migration tasks include rollback description (FIF-023) but lack explicit acceptance criteria for rollback drills, time-to-restore objectives, and verification after rollback (e.g., legacy pipeline can run, no partial renames remain, cursors restored, no mixed canonical_id formats).
**Why it matters:** The migration is labeled highest risk; without rehearsed rollback, a failed migration can cause extended downtime or corrupted vault links.
**Suggested fix:** Add a dedicated task for a staged rollback drill on a full staging clone with timed RTO target, plus a post-rollback verification checklist (legacy services health, file/link integrity scan, DB invariants).

**[F7]** | **SIGNIFICANT** | Dedup and merge logic may conflict with "first-to-route wins" routing rule
**Finding:** FIF-004 defines within-source merge, while FIF-011 defines cross-source collision resolution via url_hash and "first-to-route wins." There's no explicit rule for cross-source dedup beyond routing annotation, nor for how canonical_id relates to url_hash collisions (two different canonical_ids same url_hash). Also unclear how merged engagement metrics behave across sources.
**Why it matters:** Without clear invariants, the system can produce duplicate items across sources, inconsistent feedback attribution, and confusing vault artifacts.
**Suggested fix:** Specify framework-level dedup policy: canonical_id uniqueness per source, url_hash uniqueness cross-source (optional), and how feedback/weights should apply when multiple sources point to same URL. Add tests covering: X+RSS same URL, feedback on one affects the other (or intentionally not).

**[F8]** | **SIGNIFICANT** | Observability is cost-heavy but lacks latency/SLO and error taxonomy
**Finding:** WP-5 focuses on cost guardrails and health monitoring, but there's no explicit logging/error taxonomy, run duration tracking, queue latency metrics, or SLOs per component (capture/triage/router/delivery). "Queue health monitoring" exists but is narrowly defined.
**Why it matters:** Multi-adapter scheduling will fail in operationally subtle ways (slow triage, backlogs, partial failures). Cost control alone won't prevent missed digests or stale outputs.
**Suggested fix:** Add metrics for cycle duration, per-stage latency, backlog age, and standardized error codes. Add alerts for "digest missed" and "triage overrun budget" frequency, plus a runbook pointer in acceptance criteria.

**[F9]** | **SIGNIFICANT** | Heavy-tier design impacts standard-tier tasks but dependency is partial
**Finding:** Heavy-tier triage is deferred to M4, but FIF-008 includes deferral rules and token caps that may need to integrate with heavy-tier summarization step (FIF-032). Current dependencies have FIF-032 depending on FIF-008, but not on router/digest/telemetry behaviors that must reflect two-step costs and excerpt overwrites.
**Why it matters:** Retrofitting heavy-tier into an already-shipped triage pipeline risks churn across multiple modules and breaking parity.
**Suggested fix:** In M1/M3, introduce an abstraction in triage outputs to support multi-step processing and subcomponent cost attribution (even if unused initially). Add explicit dependency of FIF-032 on cost telemetry schema (FIF-015) and digest renderer fields if they display splits.

**[F10]** | **SIGNIFICANT** | RSS adapter canonical_id and url_hash definition may drift from framework URL canonicalization
**Finding:** RSS canonical_id uses `sha256[:16]` of canonicalized URL (FIF-028) and url_hash uses `canonicalize_url` on article URL, but there's no explicit requirement that both use identical canonicalization routines/inputs (e.g., GUID vs link vs enclosure, handling of redirected URLs).
**Why it matters:** RSS feeds frequently contain inconsistent URLs; mismatch causes duplicate items, unstable canonical IDs, and broken collision detection.
**Suggested fix:** Define canonical URL selection precedence for RSS (link > guid if URL-like > enclosure?) and ensure both canonical_id and url_hash use the exact same resolved canonical URL function. Add tests with real feed oddities (utm params, http/https, trailing slashes).

**[F11]** | **MINOR** | Several tasks likely exceed "atomic" sizing (multi-module changes)
**Finding:** FIF-006 (capture clock), FIF-008 (triage engine), FIF-011 (router), FIF-014 (feedback protocol), FIF-016 (guardrails), and FIF-023 (migration orchestrator+rollback) are each substantial and likely involve >5 files/modules, DB schema, and integration points.
**Why it matters:** Large tasks reduce parallelism and make reviews/rollbacks harder; they also obscure intermediate checkpoints.
**Suggested fix:** Split each into 2-4 subtasks (e.g., capture scheduling vs run logging vs retry/backoff; feedback command parsing vs persistence vs weight updates; router write path vs collision path; migration orchestrator vs verification vs rollback tooling).

**[F12]** | **MINOR** | Dependency graph suggests RSS requires M2, but could validate contract earlier with mock data
**Finding:** M3 depends on M2 parity gate. While reasonable operationally, contract validation could start earlier using mock adapter(s) and a small clean DB, reducing critical path.
**Why it matters:** Waiting for migration completion delays detecting contract rigidity and shared-layer flaws.
**Suggested fix:** Add an optional "Mock/RSS prototype adapter on clean DB" task in M1 (or parallel track) to validate manifest/triage/router/digest without touching the legacy X dataset.

**[F13]** | **STRENGTH** | Clear milestone gating and binary progression intent
**Finding:** The plan uses explicit milestone success criteria and a "binary gate" for X feature parity before proceeding, which is appropriate for a migration-heavy refactor.
**Why it matters:** Prevents adapter proliferation on an unstable core and reduces compounding regressions.
**Suggested fix:** N/A

**[F14]** | **STRENGTH** | Strong emphasis on idempotency and restartability in migration stages
**Finding:** Migration tasks consistently call out idempotency guards, stage tracking, and restartability, which is aligned with safe data migrations on live systems.
**Why it matters:** Greatly reduces the risk of partial migrations and enables recovery from mid-run failures.
**Suggested fix:** N/A

**[F15]** | **SIGNIFICANT** | UNVERIFIABLE CLAIM: "spec v0.3.3, reviewed by 5 models"
**Finding:** The artifact states spec v0.3.3 was reviewed by 5 models; this cannot be independently verified from the provided content.
**Why it matters:** Review coverage claims can influence trust in completeness; if inaccurate, downstream teams may over-rely on assumed validation.
**Suggested fix:** Provide references/links to the reviews or remove the claim from the action plan.

**[F16]** | **SIGNIFICANT** | UNVERIFIABLE CLAIM: "Phase 1a ... fully implemented (32 tasks)... Soak period passing"
**Finding:** The plan asserts prior phases are complete and operational with soak passing, but no evidence/metrics/logs are included here to substantiate it.
**Why it matters:** The feasibility of extraction and parity gating depends heavily on the stability and quality of the existing pipeline.
**Suggested fix:** Add a brief appendix pointer to operational metrics (uptime, error rates, costs, sample digests) or a checklist demonstrating readiness for framework extraction.

### Summary
- Total findings: 16
- Critical: 3 | Significant: 9 | Minor: 2 | Strengths: 2
- Overall assessment: The plan is well-structured with solid gating and a thoughtful migration outline, but it has critical omissions around secrets/delivery abstractions and identifier/filename invariants. Addressing schema sequencing, making acceptance criteria more measurable, and tightening migration operational safety would materially improve readiness.

---

## Google (Gemini 3 Pro Preview)

**F1** | **SIGNIFICANT** | Rollback mechanism ambiguity in FIF-023
**Finding:** Task FIF-023 describes the rollback procedure as "reverses vault renames + wikilinks from manifest." However, the Risk table for M2 specifies "Full backup + rollback procedure." Relying on an algorithmic reversal (reverse-regex) for modified file content (wikilinks) is extremely error-prone compared to restoring a directory snapshot/backup. The task description implies a surgical reversal which contradicts the safer "full backup" mitigation strategy.
**Why it matters:** If the surgical reversal fails or introduces new corruption during a panicked rollback, data loss in the vault is permanent.
**Suggested fix:** Update FIF-023 acceptance criteria to explicitly require "Restoration of vault files from pre-migration backup" rather than algorithmic reversal of text changes.

**F2** | **SIGNIFICANT** | Task FIF-023 is over-scoped
**Finding:** Task FIF-023 combines Stage 4 (Verification), Stage 5 (Go-live/Monitoring), Orchestration logic, and Rollback logic into a single task. This represents a massive amount of complexity and critical failure points in one work unit.
**Why it matters:** It makes code review difficult and increases the likelihood that bugs in the rollback logic are missed because reviewers are focused on the verification logic (or vice versa).
**Suggested fix:** Split into three tasks: (1) Implement migration verification suite (Stage 4), (2) Implement orchestrator state machine, (3) Implement/verify rollback and recovery procedures.

**F3** | **SIGNIFICANT** | Missing task for Notification/Alerting infrastructure
**Finding:** Tasks FIF-005, FIF-015, and FIF-017 references sending a "Telegram alert." However, there is no explicit task in M1 (Core Infrastructure) to implement or extract the notification service/adapter from the legacy codebase. While FIF-001 mentions "health" modules, the external notification capability is a distinct dependency.
**Why it matters:** Developers may reach FIF-005 and realize the alerting function `send_telegram()` is undefined or relies on legacy hardcoded paths, causing scope creep or blocking progress.
**Suggested fix:** Add a specific task or explicit scope in FIF-001 to extract/implement the `NotificationService` or equivalent shared interface.

**F4** | **SIGNIFICANT** | UNVERIFIABLE CLAIM: Cost Estimates
**Finding:** The plan asserts specific cost ranges (e.g., "$0.20-$0.50/month for RSS", "under $15 ceiling").
**Why it matters:** I cannot independently verify the token usage, API pricing models, or volume assumptions used to derive these figures. If these estimates are wrong, the cost guardrails (FIF-016) may trigger prematurely or fail to protect the user.
**Suggested fix:** Treat these numbers as "Target Estimates" rather than factual constraints in the review, or link to a (missing) cost modeling document.

**F5** | **MINOR** | Hardcoded Regex in FIF-022
**Finding:** Task FIF-022 hardcodes a complex regex (`(!?\[\[)(feed-intel-)...`) in the task description.
**Why it matters:** If this regex has edge cases (e.g., handling of `[[alias|feed-intel-id]]` vs `[[feed-intel-id]]` inside comments), hardcoding it in the task description discourages the developer from deriving the regex from a test suite covering those edge cases.
**Suggested fix:** Move the regex to the acceptance criteria as a "Must match these test cases" requirement, rather than prescribing the exact regex string in the description.

**F6** | **MINOR** | FIF-007 Risk Calibration
**Finding:** FIF-007 (Adapter lifecycle / Hot-reconfig) is marked as "Low" risk.
**Why it matters:** Hot-reconfiguration (changing schedules/batches while the system is running) often introduces concurrency bugs or race conditions (e.g., changing a schedule while a capture is in progress).
**Suggested fix:** Elevate risk to "Medium" and ensure acceptance criteria includes a test case for reconfiguration during an active run.

**F7** | **STRENGTH** | Migration Lockfile Guard (FIF-019)
**Finding:** The inclusion of a specific task to implement a lockfile guard (`~/.feed-intel-migration-in-progress`) in startup scripts *before* writing the migration logic is excellent defensive programming.
**Why it matters:** It prevents the automated pipeline from processing data while the database/vault is in an inconsistent state during migration.
**Suggested fix:** N/A

**F8** | **STRENGTH** | Binary Feature Parity Gate (FIF-026)
**Finding:** The plan explicitly defines a "binary pass/fail" gate based on 3 days of parallel data.
**Why it matters:** This prevents the "sunk cost fallacy" where a partially broken migration is accepted just to move forward. It forces a revert-and-fix approach if parity isn't met.
**Suggested fix:** N/A

### Summary
- Total findings: 8
- Critical: 0 | Significant: 4 | Minor: 2 | Strengths: 2
- Overall assessment: The action plan is high-quality, highly detailed, and demonstrates strong architectural thinking, particularly regarding the migration strategy. The primary weaknesses are the over-scoping of the final migration task (FIF-023) and ambiguity regarding the "rollback" implementation (algorithmic vs. backup restore). Addressing the decomposition of the migration execution and explicitly defining the notification infrastructure will make this a robust plan.

---

## DeepSeek (V3.2-Thinking)

**[F1]** | **SIGNIFICANT** | Missing comprehensive error handling specification for adapter operations
**Finding:** The tasks cover adapter-specific error handling (e.g., circuit breaker for YouTube, stale cursor detection), but there is no unified framework-level task for defining and implementing standard error handling patterns across all adapters (e.g., retry policies for network failures, timeouts, malformed API responses, authentication errors). This is implied in components like the capture clock (FIF-006) but not explicitly required as a shared infrastructure contract.
**Why it matters:** Inconsistent error handling could lead to silent failures, data loss, or resource leaks when new adapters are added. It increases the risk of one adapter's failure mode destabilizing the framework.
**Suggested fix:** Add a task under M1 (e.g., FIF-018.1) to define and implement a standard error classification and handling strategy (transient vs. permanent, backoff, alerting) as part of the adapter contract, referenced by all adapter implementations.

**[F2]** | **MINOR** | Potential for earlier parallelization of simple adapter development
**Finding:** The dependency graph requires M2 (X Migration) completion before M3 (RSS) starts. However, the RSS adapter is designed to validate the adapter contract's simplicity. Its development (excluding integration) could begin in parallel with later M1 work packages (WP-4, WP-5) once the core adapter manifest and data types (FIF-001, FIF-002, FIF-005) are stable.
**Why it matters:** This could shorten the overall timeline without increasing risk, as RSS contract issues would be caught early during M1 development rather than after M2.
**Suggested fix:** Adjust the dependency for FIF-027 (RSS Phase 0) to allow it to start after FIF-005 (manifest loader) is complete, with the integration test (FIF-029) still gated on M2's feature parity.

**[F3]** | **SIGNIFICANT** | Under-calibrated risk for core triage engine
**Finding:** FIF-008 (Implement triage engine) is marked as `medium` risk. This component is critical-path for all intelligence functions, and its failure would block all adapters. Its complexity (two tiers, batching, preamble injection, token capping, error isolation) warrants a `high` risk rating.
**Why it matters:** A high-risk rating ensures appropriate focus, testing rigor, and contingency planning (e.g., a more detailed rollback plan) for this foundational component.
**Suggested fix:** Change the `risk` level for FIF-008 from `medium` to `high`.

**[F4]** | **MINOR** | Overly coarse task for migration Stages 1-2
**Finding:** FIF-021 bundles two major migration stages (DB schema changes and cursor state migration) into a single task. Each stage involves complex, distinct operations (schema alterations vs. data transformation and state migration) with their own failure modes.
**Why it matters:** A single task makes progress tracking and rollback coordination more difficult. It obscures the specific point of failure if something goes wrong.
**Suggested fix:** Split FIF-021 into two tasks: `FIF-021a: Write migration script - Stage 1 (DB schema alterations)` and `FIF-021b: Write migration script - Stage 2 (cursor state migration)`.

**[F5]** | **SIGNIFICANT** | Unverifiable and vague acceptance criteria for signal quality
**Finding:** M5 Success Criterion #5 and FIF-030's criterion "per-adapter signal quality score computed" are subjective and lack a binary, testable definition. The artifact does not define how this score is calculated or measured.
**Why it matters:** This makes the milestone gate fuzzy. "Success" becomes a matter of opinion rather than a measurable technical outcome, which could lead to proceeding with a poorly performing adapter.
**Suggested fix:** Replace with a measurable proxy metric, such as "Operator provides a binary enable/disable decision for each new adapter based on review of its digests for one week," or define a quantitative score based on feedback command ratios.

**[F6]** | **SIGNIFICANT** | Insufficient detail on staging/validation environment for migration
**Finding:** The migration tasks (FIF-021, FIF-022, FIF-023) mention testing against a "copy of live DB" and "staging copy." There is no dedicated task for creating, managing, or ensuring the fidelity of this staging environment, which is critical for mitigating the high risks (data loss, breakage) identified.
**Why it matters:** Without a clearly scoped task, the creation of a representative staging environment may be overlooked or under-resourced, increasing the risk of undiscovered issues during live migration.
**Suggested fix:** Add a preceding task: "Establish staging migration environment with copy of live database and vault snapshot."

**[F7]** | **STRENGTH** | Realistic and low-risk framework extraction approach
**Finding:** The plan correctly identifies "premature abstraction" as a key risk and explicitly mitigates it by mandating extraction from the working x-feed-intel code. The phased approach (X migration first) validates the shared layer with a known-good adapter before expanding.
**Why it matters:** This dramatically increases the likelihood of success by building the framework incrementally from proven patterns, avoiding greenfield over-engineering.
**Suggested fix:** N/A

**[F8]** | **STRENGTH** | Comprehensive and testable acceptance criteria for most atomic tasks
**Finding:** The majority of tasks (e.g., FIF-002, FIF-005, FIF-011) have clear, binary acceptance criteria involving specific unit tests, schema validations, or operational outcomes (e.g., "unit tests pass", "rejects missing/invalid manifest_version").
**Why it matters:** This enables unambiguous completion validation for each task, reducing ambiguity and ensuring quality gates are meaningful.
**Suggested fix:** N/A

**[F9]** | **SIGNIFICANT** | UNVERIFIABLE CLAIM: Dependency on completed x-feed-intel phases
**Finding:** The plan's feasibility is predicated on the successful completion and stability of Phases 0 and 1a of the x-feed-intel pipeline (32 tasks). The reviewer cannot verify the state or quality of this prior work.
**Why it matters:** If the underlying x-feed-intel pipeline is unstable or its design is flawed, the extraction and generalization effort (M1, M2) will inherit those problems, potentially dooming the framework project.
**Suggested fix:** No fix to the plan itself, but this is a critical external dependency that must be validated before committing to this action plan.

**[F10]** | **MINOR** | Ambiguous milestone gating for deferred phases
**Finding:** The activation signals for M6 (Phase 2) and M7 (Phase 3) are qualitative ("4 weeks operational data", "sufficient feedback volume"). The thresholds (e.g., "3+ adapters", "100+ feedback interactions") are reasonable but not formally tracked as part of earlier milestone criteria.
**Why it matters:** This could lead to ambiguity about when to initiate planning for these phases. The decision point relies on data not explicitly mandated for collection by M1-M5.
**Suggested fix:** Add a task in M5 (or modify FIF-040) to ensure the framework collects and reports the metrics needed for the Phase 2/3 activation signals (weeks operational per adapter, feedback interaction counts).

### Summary
- Total findings: 10
- Critical: 0 | Significant: 6 | Minor: 3 | Strengths: 2
- Overall assessment: This is a well-structured, detailed action plan with strong traceability to the spec and generally excellent task decomposition. The primary concerns are around risk calibration for core components, vagueness in a few success metrics, and dependencies on unverifiable prior work. The migration plan is detailed but would benefit from an explicit staging environment task.

---

## Grok (4.1 Fast Reasoning)

**F1** | **SIGNIFICANT** | Multiple unverifiable claims about prior work and spec compliance
**Finding:** The plan repeatedly claims prior phases (0, 1a) are complete via x-feed-intel (e.g., "32 tasks, in soak"), spec v0.3.3 reviewed by 5 models, feature parity with x-feed-intel, and detailed spec section mappings (e.g., SS4-SS14), but no evidence or links provided; cost estimates (e.g., "$0.20-$0.50/month for RSS") and Phase 0 findings (e.g., YouTube transcript rates) are projected without data. UNVERIFIABLE CLAIM: x-feed-intel pipeline is fully operational and soak-passing.
**Why it matters:** Undermines confidence in baseline and feasibility; risks building on non-existent foundations.
**Suggested fix:** Append links to x-feed-intel repo, spec doc, soak logs, and Phase 0 reports; mark assumptions explicitly.

**F2** | **CRITICAL** | Incomplete spec coverage for deferred phases
**Finding:** Phases 2 (M6) and 3 (M7) are placeholders without task decomposition, despite spec SS13 requiring them; no tasks address SS14 success criteria fully (e.g., SS14.6 "operator independent evaluation" vaguely in M5, but no metrics).
**Why it matters:** Plan claims full decomposition of spec v0.3.3 but omits ~30% of phases, blocking complete implementation.
**Suggested fix:** Decompose M6/M7 into atomic tasks or explicitly scope as out-of-scope with activation criteria tied to data thresholds.

**F3** | **SIGNIFICANT** | Migration decomposition too coarse for high-risk area
**Finding:** FIF-021 to FIF-023 cover 5 complex stages (DB schema changes, cursor migration, vault renames/wikilinks, verification, rollback) in just 3 tasks; FIF-022's regex for 6 wikilink variants lacks edge-case tests (e.g., nested links, aliases).
**Why it matters:** High-risk migration (data loss, wikilink breakage flagged) could fail catastrophically without finer-grained tasks and tests.
**Suggested fix:** Split into 7-10 subtasks (one per stage/verification type); add tasks for edge-case regex tests and dry-run mode.

**F4** | **SIGNIFICANT** | Hidden dependencies in adapter implementations
**Finding:** M5 adapters (FIF-036,038,039) depend only on FIF-026, but require M1 triage/output (e.g., heavy-tier for arxiv? No, standard), cost guardrails, and collision detection; Reddit (FIF-038) depends on FIF-037 but graph shows M5 after M2 only.
**Why it matters:** Parallelization assumed but sequencing risks runtime failures if core infra incomplete.
**Suggested fix:** Update depends_on to include FIF-011 (router), FIF-016 (guardrails); refine graph to show M1 -> all adapters.

**F5** | **MINOR** | Over-sequential M1 work packages
**Finding:** WP-1 (FIF-001-004) blocks all, but WP-5 (observability) could partially parallelize after FIF-006; no explicit parallel lanes defined beyond notes.
**Why it matters:** Delays overall timeline without gain; misses efficiency.
**Suggested fix:** Mark FIF-015/016 as partial-parallel after FIF-006; add Gantt-style lanes in action-plan.md.

**F6** | **SIGNIFICANT** | Vague acceptance criteria in validation tasks
**Finding:** FIF-026 (parity gate): "triage quality comparable (spot-check 10 items)"; FIF-030: "per-adapter signal quality score computed" (undefined metric); FIF-035: "circuit breaker not triggered (or handled gracefully)" lacks thresholds.
**Why it matters:** Non-binary criteria enable subjective gates, risking regressions.
**Suggested fix:** Define metrics (e.g., "95% triage decision match on 50 items"; "signal score = promotes/ignores ratio >0.2"); make all pass/fail.

**F7** | **MINOR** | Inconsistent risk levels for similar tasks
**Finding:** FIF-006 (capture clock, medium risk) vs FIF-020 (X refactor, medium) fine, but FIF-032 (heavy-tier engine, medium) despite new LLM complexity; migration FIF-021-023 high, but FIF-025 execution also high.
**Why it matters:** May misprioritize testing effort.
**Suggested fix:** Bump FIF-032/033 to high (YouTube complexity); standardize risk matrix.

**F8** | **SIGNIFICANT** | No tasks for testing or CI/CD integration
**Finding:** Tasks mention "unit tests pass" but no dedicated tasks for end-to-end tests, CI pipelines, or mock adapter suite (M1 success #9 vaguely covered); no coverage for multi-adapter concurrency.
**Why it matters:** Risks integration bugs despite per-task tests; M1 #9 untestable without tasks.
**Suggested fix:** Add FIF-018.5: "Framework test suite with mocks"; FIF-041: "CI/CD for all milestones".

**F9** | **MINOR** | Task sizing imbalances
**Finding:** FIF-001 (project structure) too small (merge with FIF-002?); FIF-023 (migration orchestrator + rollback) too large (>10 file changes likely: DB, vault scripts, launchctl).
**Why it matters:** Poor sprint planning; large tasks hide bugs.
**Suggested fix:** Merge FIF-001/002; split FIF-023 into orchestrator/rollback subtasks.

**F10** | **CRITICAL** | Milestone gates insufficiently objective
**Finding:** M2 parity gate (FIF-026) binary but relies on "3-day parallel comparison" without automated diffs; M3 "no mods to shared code" unverified; M5 lacks explicit SS14 check task.
**Why it matters:** Subjective gates allow progression with regressions, especially post-migration.
**Suggested fix:** Add automated metrics (e.g., Jaccard similarity >0.95 for triage); task for SS14 audit per milestone.

**F11** | **STRENGTH** | Clear dependency graph and phasing
**Finding:** Dependency graph accurately summarizes sequencing; phases map to spec SS13; M1-M5 build incrementally from extraction.
**Why it matters:** Enables realistic parallel work and risk isolation.
**Suggested fix:** N/A

**F12** | **STRENGTH** | Detailed success criteria for milestones
**Finding:** Each milestone lists 5-9 concrete criteria tied to spec; risks/mitigations tabulated.
**Why it matters:** Provides strong gating beyond tasks.
**Suggested fix:** N/A

**F13** | **SIGNIFICANT** | No contingency for Reddit API block
**Finding:** FIF-037 Phase 0 gates Reddit, but no fallback tasks (RSS documented but not tasked); M5 proceeds assuming success.
**Why it matters:** Medium risk could stall M5; spec SS7.3 fallback un-implemented.
**Suggested fix:** Add FIF-037.5: "Implement/test RSS fallback adapter if API blocked".

**F14** | **MINOR** | Future dates undermine credibility
**Finding:** Created/updated 2026-02-23 (future from now); no timelines in plan.
**Why it matters:** Suggests draft/placeholder; hard to schedule.
**Suggested fix:** Update to current date; add estimated durations per milestone.

### Summary
- Total findings: 14
- Critical: 2 | Significant: 6 | Minor: 4 | Strengths: 2
- Overall assessment: Solid structure and detail, but critical gaps in spec coverage, migration granularity, and objective gating make it unready for execution without revisions; high unverifiable assumptions amplify risks.

---

## Perplexity (Sonar Reasoning Pro)

*Manual submission via claude.ai. Received spec summary, action plan, and tasks as combined prompt with structured review dimensions.*

**PPLX-F1** | **SIGNIFICANT** | Heavy-tier triage dependency gap
**Finding:** FIF-032 depends only on FIF-008, but heavy-tier summarize-then-triage logically requires unified content types (FIF-002), manifest loader for tier detection (FIF-005), and adapter state (FIF-003) — creating hidden coupling if M1 WP-1/WP-2 incomplete.
**Recommendation:** Add explicit deps FIF-032 → FIF-002, FIF-003, FIF-005.

**PPLX-F2** | **SIGNIFICANT** | M5 parallelism risks early adapter proliferation
**Finding:** HN/arxiv depend only on FIF-026 (M2), ignoring that M3 validates the contract. This contradicts "framework proven with 2 adapters" for M4 and spec §13 incremental order.
**Recommendation:** Update M5 deps to post-M3; allow HN/arxiv after M3 as optional parallelism.

**PPLX-F3** | **MINOR** | Reddit Phase 0 lacks explicit milestone dependency
**Finding:** FIF-037 has no stated dependency, but graph notes "Reddit needs FIF-037 Phase 0" — potential inconsistency.
**Recommendation:** Make FIF-037 kickoff post-M2 explicitly.

**PPLX-F4** | **SIGNIFICANT** | Deferred spec items have no tasks
**Finding:** Spec deferred items (FK consistency, env config, run-level token budgets, source_instances queryability, vault router tier-aware promotion) have no tasks or milestones anywhere.
**Recommendation:** Add M1 tasks or trace to M6 scope.

**PPLX-F5** | **MINOR** | Cost guardrails miss spec precision
**Finding:** FIF-016 covers monthly/daily ceilings but omits heavy-tier-specific throttling and curated-only exemption verification.
**Recommendation:** Expand ACs to cover heavy throttling independently and curated exemption.

**PPLX-F6** | **MINOR** | FIF-023 overloaded (convergent with 4/4 consensus)
**Finding:** FIF-023 overloads Stages 4-5 + orchestrator + rollback; could fail restartability.
**Recommendation:** Split into FIF-023a (verification) and FIF-023b (orchestrator/rollback).

**PPLX-F7** | **SIGNIFICANT** | Vault router collision implementation vague
**Finding:** "Current-run collision tracking (write-through or in-memory)" is vague; misses 3-way collision edge case (X→RSS→YT same URL).
**Recommendation:** Specify in-memory; add AC for 3-way collision test.

**PPLX-F8** | **MINOR** | Research promotion weak edge-case testing
**Finding:** ACs cover happy path but miss promotion on collided item, save failure, multi-source frontmatter interaction.
**Recommendation:** Add edge-case ACs for collision + promotion interaction.

**PPLX-F9** | **MINOR** | FIF-001 too scaffold-heavy for single task
**Finding:** Placeholder modules + README risks premature design commitment before extraction insights.
**Recommendation:** Split to dirs/README and placeholders separately.

**PPLX-F10** | **SIGNIFICANT** | Feature parity gate vague metrics (convergent with A2)
**Finding:** "Triage quality comparable (spot-check 10 items)" subjective; misses quantitative metrics like feedback response rate parity or vault route % match.
**Recommendation:** Define automated metrics: capture count ±5%, cost ±10%, route % parity; manual: 20 spot-checks >90% match.

**PPLX-F11** | **MINOR** | Adapter health misses health_check() hook testing
**Finding:** AC covers degraded state but no AC to test the optional health_check() hook invocation.
**Recommendation:** Add AC "health_check() invoked pre-capture if defined; mock unhealthy response triggers degraded."

**PPLX-F12** | **MINOR** | Weekly aggregate summary not traced to implementation task
**Finding:** M3/FIF-030 validates weekly aggregate but no M1 task explicitly implements it. FIF-012 (digest renderer) lacks weekly mode.
**Recommendation:** Add weekly aggregate rendering to FIF-015 or FIF-012 AC.

**PPLX-F13** | **SIGNIFICANT** | Extraction risks underdocumented
**Finding:** M1 risks miss monolith perf degradation (WAL multi-source), shared dep conflicts (launchd/Telegram), and TypeScript typing gaps post-extract.
**Recommendation:** Add risks: "Monolith perf degradation (high)", "Shared dep conflicts (med)."

**PPLX-F14** | **STRENGTH** | Strong idempotency guards in migration
**Finding:** 5-stage with explicit guards (NOT LIKE, IF NOT EXISTS, skip if target exists), staged alias pre-rewrite, full rollback.
**Recommendation:** Acknowledge; consider dry-run mode.

**PPLX-F15** | **STRENGTH** | Parallel WP opportunity well-documented
**Finding:** Graph explicitly calls overlaps (WP-2/WP-3 post-WP-1), enabling ~30% parallelism.
**Recommendation:** Acknowledge; quantify critical path.

**Dimension Ratings:** Milestone sequencing: Needs Work | Task granularity: Adequate | AC quality: Needs Work | Risk identification: Adequate | Coverage gaps: Needs Work | Migration decomposition: Strong | Extraction strategy: Adequate

### Summary
- Total findings: 15
- Critical: 0 | Significant: 7 | Minor: 7 | Strengths: 2
- Overall verdict: "Needs rework" — dependency gaps, vague ACs, and coverage holes are fixable but block confident execution.

---

## Synthesis

**63 findings across 5 reviewers** (4 automated + 1 manual Perplexity submission). 5 CRITICAL, 32 SIGNIFICANT, 18 MINOR, 10 STRENGTH.

### Consensus Findings

**1. FIF-023 is over-scoped (5/5 reviewers)**
OAI-F11, GEM-F2, DS-F4, GRK-F3, GRK-F9, PPLX-F6.
All five reviewers flagged FIF-023 as too large — it bundles Stage 4 (verification), Stage 5 (re-enable), migration orchestrator (state machine), and rollback into a single task. Gemini suggested three subtasks; OpenAI and Grok both noted >5 file changes likely; Perplexity converged independently. This is the strongest consensus finding.

**2. Non-binary acceptance criteria at key gates (4/5 reviewers)**
OAI-F5, DS-F5, GRK-F6, GRK-F10, PPLX-F10.
"Triage quality comparable (spot-check 10 items)" in FIF-026, "per-adapter signal quality score computed" in FIF-030, and "circuit breaker not triggered (or handled gracefully)" in FIF-035 all lack binary pass/fail thresholds. Perplexity added specific metrics: capture count ±5%, route % parity, 20 spot-checks >90% match. The feature parity gate is the most critical — if it's subjective, it can be argued past.

**3. Unverifiable prior work claims (3/5 reviewers)**
OAI-F15, OAI-F16, DS-F9, GRK-F1.
Reviewers can't verify x-feed-intel completion, soak status, or cost estimates from the artifacts provided. This is inherent to the review setup (reviewers don't have vault access) — the claims are verifiable within the vault via run-logs and project state. Not actionable for the plan itself.

**4. Migration staging environment not tasked (2/4 reviewers)**
OAI-F6, DS-F6.
Migration tasks reference "tested against copy of live DB" but no task creates or validates the staging environment.

**5. Risk under-calibration for core components (3/4 reviewers)**
DS-F3, GRK-F7, GEM-F6.
FIF-008 (triage engine) marked medium but is critical-path for all adapters. FIF-007 (lifecycle/hot-reconfig) marked low but involves concurrency. Note: extraction from working code mitigates but doesn't eliminate risk.

**6. Rollback procedure needs tightening (2/4 reviewers)**
OAI-F6, GEM-F1.
Rollback description says "reverse vault renames from manifest" (surgical) but risk table says "full backup + rollback" (restore). Primary approach should be backup restoration, not algorithmic reversal.

**7. Telegram/notification infrastructure implicit (2/4 reviewers)**
OAI-F3, GEM-F3.
Multiple tasks reference Telegram alerts but no dedicated shared alerting task exists. The digest delivery path (FIF-012, FIF-013) covers the main channel; alerting is a simpler function reused across components.

**8. Earlier parallelization possible (3/5 reviewers)**
OAI-F12, DS-F2, GRK-F5, PPLX-F15.
RSS Phase 0 (feed selection) could start before M2 completes. M1 work packages could partially overlap beyond what's documented. Perplexity estimates ~30% parallelism in M1 from the documented WP overlaps.

**9. Transitive/hidden dependencies in FIF-032 and M5 (3/5 reviewers)**
OAI-F9, GRK-F4, PPLX-F1, PPLX-F2.
FIF-032 (heavy-tier triage) lists only FIF-008 as dependency but transitively needs FIF-002, FIF-003, FIF-005. M5 adapters list only FIF-026 but need all M1 infrastructure. Making transitive deps explicit improves clarity.

**10. Extraction risks underdocumented (1 reviewer, but strong reasoning)**
PPLX-F13.
M1 risks miss monolith-specific concerns: WAL performance under multi-source writes, shared launchd/Telegram dependency conflicts, TypeScript typing gaps post-extraction. These are real for a monolith→framework refactor.

### Unique Findings

**OAI-F4: DB schema sequencing (genuine insight)**
M1 components need the multi-source schema to exist for testing, but schema creation only appears in M2 migration. M1 needs its own "create schema from scratch" capability for new installations and test fixtures. Valid gap.

**OAI-F10: RSS URL selection precedence (genuine insight)**
RSS feeds have multiple URL-like fields (link, guid, enclosure). The acceptance criteria should specify selection precedence for canonical_id and url_hash computation. Good detail catch.

**GRK-F4: Hidden M5 dependencies (genuine insight)**
M5 adapter tasks list only FIF-026 as dependency, but implicitly require all M1 infrastructure. Making the transitive dependency explicit improves clarity.

**GRK-F13: Reddit RSS fallback not explicitly tasked (minor insight)**
FIF-038 AC already says "RSS fallback contract honored if API blocked," but the fallback implementation path could be more explicit.

**DS-F10: Deferred phase activation signals (minor insight)**
M6/M7 activation signals reference metrics not formally tracked by M1-M5 tasks. Could add metric tracking to FIF-040.

**PPLX-F7: Vault router 3-way collision (genuine insight)**
Current ACs test 2-way collision (X+RSS). A 3-way collision (X→RSS→YouTube all sharing same URL) is a real edge case worth testing. Minor but would catch bugs.

**PPLX-F11: health_check() hook untested (genuine insight)**
FIF-017 mentions optional health_check() hook but no AC tests invocation. The spec emphasizes silent failure detection via this hook.

**PPLX-F12: Weekly aggregate summary untraced (minor insight)**
FIF-030 validates it, but no M1 task explicitly implements the weekly aggregate rendering. Should be traced to FIF-015.

### Contradictions

**Rollback approach:** OAI-F6 wants rollback drills with RTO targets; GEM-F1 wants backup restoration instead of algorithmic reversal. These aren't contradictory — backup restore should be primary, surgical reversal should be documented as fast-path alternative.

**Task granularity:** OAI-F11 and GRK-F9 want more splitting across many tasks; DS-F2 and GRK-F9 note some tasks are too small (merge FIF-001/002). The answer is targeted: split FIF-023 (consensus), keep the rest as-is (most are correctly scoped).

### Action Items

**Must-fix:**

**A1** — Split FIF-023 into 3 tasks
*Source: OAI-F11, GEM-F2, DS-F4, GRK-F3, GRK-F9, PPLX-F6 (5/5 consensus)*
Split into: (a) FIF-023a: Migration verification suite (Stage 4 — all 8 checks), (b) FIF-023b: Migration orchestrator + Stage 5 re-enable (state machine, migration-state.json), (c) FIF-023c: Rollback procedure (backup restore primary, surgical reversal documented as alternative, post-rollback verification checklist). Renumber subsequent tasks.

**A2** — Sharpen non-binary acceptance criteria
*Source: OAI-F5, DS-F5, GRK-F6, GRK-F10, PPLX-F10 (4/5 consensus)*
Specific fixes:
- FIF-026 (parity gate): Replace "triage quality comparable (spot-check 10 items)" with "Triage decisions match on ≥90% of 50 items processed by both legacy and framework pipelines; digest item count within ±10%; all 5 feedback commands return expected state changes"
- FIF-030 (signal quality): Define as "signal quality score = promote_count / total_routed_count over trailing 30 days, computed from feedback table; value displayed in weekly aggregate summary"
- FIF-035 (circuit breaker): Replace "not triggered (or handled gracefully)" with "If transcript error rate stays <80%, circuit breaker does not activate; if error rate exceeds 80% for 3 runs, adapter enters transcript-disabled mode and Telegram alert sent"

**Should-fix:**

**A3** — Add schema initialization to M1
*Source: OAI-F4*
Add to FIF-001 AC: "Framework includes a schema initialization module that creates all required tables (§8 schema) in a clean SQLite database; used by test fixtures and new installations. M2 migration transforms legacy data into this schema."

**A4** — Add migration staging environment task
*Source: OAI-F6, DS-F6*
Add FIF-019b (before FIF-021): "Create staging migration environment — copy of live SQLite DB, vault snapshot to temp directory, cursor JSON files. Verify staging copy matches live data (row counts, file counts). Used by FIF-021 through FIF-023 for development and testing."

**A5** — Elevate FIF-008 risk to high
*Source: DS-F3, GRK-F7*
Triage engine is critical-path for all adapters. Extraction from working code mitigates but doesn't eliminate risk. High risk ensures appropriate testing rigor.

**A6** — Elevate FIF-007 risk to medium
*Source: GEM-F6*
Hot-reconfiguration at cycle boundaries involves concurrency concerns. Add AC: "test case covers manifest change applied during an active capture run — change takes effect at next cycle, not mid-run."

**A7** — Tighten rollback AC (backup-first approach)
*Source: OAI-F6, GEM-F1*
FIF-023c rollback AC: "Primary rollback: restore SQLite DB and cursor JSONs from pre-migration backup, restore vault directory from git commit. Surgical reversal (migration manifest) documented as alternative for partial-stage failures. Post-rollback verification: legacy pipeline starts, processes one capture+attention cycle without errors."

**A8** — Enhance FIF-028 with RSS URL selection precedence
*Source: OAI-F10*
Add to FIF-028 AC: "RSS URL selection precedence for canonical_id and url_hash: (1) resolved link URL after redirect, (2) guid if URL-like, (3) enclosure URL. Both canonical_id hash and url_hash computed from the same resolved URL via canonicalize_url(). Tests cover: utm params, http/https mismatch, trailing slashes."

**A9** — Relax FIF-027 dependency for parallelization
*Source: DS-F2, OAI-F12*
Change FIF-027 depends_on from FIF-026 to FIF-005 (manifest loader). RSS Phase 0 (feed selection + feedparser validation) can start once the manifest format is stable. Integration test (FIF-029) remains gated on FIF-026.

**A10** — Add framework alert function + health_check() hook testing to FIF-017
*Source: OAI-F3, GEM-F3, PPLX-F11*
Add to FIF-017 AC: "Framework provides a shared send_alert(message) function used by degraded state, cost cap breach, and liveness check. Telegram implementation extracted from x-feed-intel. All components reference this shared function, not direct Telegram calls. If adapter defines health_check() in manifest, invoked before each capture run; mock unhealthy response triggers degraded state in tests."

**A11** — Make transitive dependencies explicit (FIF-032 and M5)
*Source: GRK-F4, PPLX-F1, PPLX-F2*
FIF-032: add explicit deps on FIF-002, FIF-003, FIF-005 (currently only lists FIF-008). M5 tasks: add clarifying note that depends_on FIF-026 implies all M1 infrastructure complete (transitive via M1 → M2 chain). Update dependency graph.

**A12** — Add extraction-specific risks to M1 risk table
*Source: PPLX-F13*
Add: "WAL performance under multi-source writes" (medium, mitigate with benchmark during M2 integration test), "Shared dependency conflicts during extraction (launchd plist, Telegram bot)" (medium, isolate in WP-1 scaffolding).

**A13** — Add weekly aggregate summary rendering to FIF-015 AC
*Source: PPLX-F12*
Add to FIF-015 AC: "Weekly aggregate cost summary message rendered with per-adapter cost breakdown and signal quality scores (promotes/total_routed, trailing 30 days)."

**Defer:**

**A14** — Add Gantt-style parallel lanes to action plan
*Source: GRK-F5*
Nice visualization but not blocking. Current dependency graph + work package notes are sufficient.

**A15** — Track Phase 2/3 activation metrics in FIF-040
*Source: DS-F10*
Add to FIF-040 AC: "framework reports per-adapter weeks operational and cumulative feedback interaction count." Minor enhancement, not blocking.

**A16** — Add 3-way collision test case to FIF-011 AC
*Source: PPLX-F7*
Add test: "3-way collision (X→RSS→YouTube same URL) — first-to-route wins, second and third append correctly with additional_sources accumulating." Edge case but worth validating.

### Considered and Declined

| Finding | Reason | Category |
|---|---|---|
| OAI-F1 (secrets management task) | Spec §6.1 already defines credential handling via manifest `credentials` section with keychain store; pattern carried from x-feed-intel implementation | constraint |
| OAI-F2 (canonical_id/filename collision) | Naming convention is consistent: `feed-intel-{source_type}-{native_id}` where native_id is the part after the colon. SHA256[:16] = 64-bit birthday bound (~4B items) — negligible collision probability at RSS scale | incorrect |
| OAI-F3/GEM-F3 (delivery transport interface) | Telegram is the only delivery channel for Phase 1; adding an abstraction layer for one backend is premature. Alert function addressed in A10 | overkill |
| OAI-F7 (dedup/merge vs first-to-route) | Spec §5.2 explicitly scopes within-source dedup; §5.5 defines cross-source collision handling; feedback is per-source per-topic by design — no conflict | incorrect |
| OAI-F8 (observability gaps — SLOs, latency) | adapter_runs already captures duration_seconds per run; Phase 1 single-operator deployment doesn't need formal SLOs or standardized error codes | overkill |
| OAI-F9 (heavy-tier impacts standard-tier) | FIF-008 already includes tier resolution logic and token cap; FIF-032 extends the triage path without changing output format; cost_log subcomponent column exists from M2 migration | constraint |
| GEM-F5 (hardcoded regex in FIF-022) | Regex is from spec §8.1 step 14 as reference; AC already requires covering all 6 wikilink variants via test cases | overkill |
| DS-F1 (unified error handling task) | Error taxonomy distributed across FIF-006 (run logging), FIF-008 (error isolation), FIF-017 (degraded state) — matches spec §5.10 structure; not a gap, just distributed | incorrect |
| DS-F4 (split FIF-021 Stages 1-2) | DB schema migration and cursor state migration are tightly coupled (same script, same DB transaction context for Stage 1), and collectively ≤5 file changes; splitting adds overhead without proportional benefit | overkill |
| GRK-F2 (deferred phases not decomposed) | Plan explicitly scopes Phases 1b.1–1d; M6/M7 are deliberately deferred per spec §13 phasing. Decomposing future phases before Phase 1 starts is premature | constraint |
| GRK-F8 (testing/CI tasks) | Single-operator Mac Studio deployment; each task's AC includes "unit tests pass"; CI pipeline is over-engineering for this deployment model | overkill |
| GRK-F13 (Reddit RSS fallback not tasked) | FIF-038 AC already includes "RSS fallback contract honored if API blocked"; fallback is a variant of the same adapter, not a separate task | constraint |
| GRK-F14 (future dates) | 2026-02-23 is today's date — the reviewer's knowledge cutoff predates the current date | incorrect |
| PPLX-F2 (M5 should depend on M3) | Plan already says "M3 recommended (contract proven)" for M5 — the intentional "recommended" language allows HN/arxiv parallelization for simple adapters | constraint |
| PPLX-F3 (Reddit Phase 0 lacks dep) | FIF-037 correctly has no dependency (can start anytime); FIF-038 correctly depends on FIF-037. The dependency graph description is consistent | incorrect |
| PPLX-F4 (deferred spec items need tasks) | Items are explicitly deferred to "PLAN or Phase 2" in spec v0.3.2 changelog; covered by M6 placeholder milestone | constraint |
| PPLX-F5 (cost guardrails miss specifics) | FIF-016 AC already includes "heavy-tier max_items_per_cycle reduced 50%" and "curated-only adapters not throttled"; FIF-008 handles 12K token cap | incorrect |
| PPLX-F8 (research promotion edge cases) | Promotion on collided items, save failure, multi-source frontmatter — these are implementation-level edge cases, not plan-level gaps | overkill |
| PPLX-F9 (FIF-001 too scaffold-heavy) | Task scopes to project structure + README; actual implementations start in FIF-002+. Splitting structure into sub-tasks is excessive decomposition | overkill |
