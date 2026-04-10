---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact: Projects/tess-v2/design/spec-amendment-Z-interactive-dispatch.md
artifact_type: design-input
artifact_hash: 460eddf1
prompt_hash: 33dee392
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-06
updated: 2026-04-06
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
    latency_ms: 81777
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-06-spec-amendment-Z-interactive-dispatch-openai.json
  google:
    http_status: 200
    latency_ms: 32986
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-06-spec-amendment-Z-interactive-dispatch-google.json
  deepseek:
    http_status: 200
    latency_ms: 113167
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-06-spec-amendment-Z-interactive-dispatch-deepseek.json
  grok:
    http_status: 200
    latency_ms: 30751
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-06-spec-amendment-Z-interactive-dispatch-grok.json
tags:
  - review
  - peer-review
---

# Peer Review: Spec Amendment Z — Interactive Dispatch & Orchestrator Authority

**Artifact:** Projects/tess-v2/design/spec-amendment-Z-interactive-dispatch.md
**Mode:** full
**Reviewed:** 2026-04-06
**Reviewers:** OpenAI gpt-5.4, Google gemini-3.1-pro-preview, DeepSeek deepseek-reasoner, Grok grok-4-1-fast-reasoning
**Review prompt:** Full review of spec amendment Z covering correctness, completeness, internal consistency, feasibility, and clarity. Focus areas: dispatch queue edge cases, session report completeness, graduated autonomy safeguards, capability inversion argument soundness, unaddressed failure modes.

---

## OpenAI (gpt-5.4)

- [F1]
  - [Severity]: CRITICAL
  - [Finding]: The amendment contains a direct contradiction on vault write authority. The updated system map says "CRUMB VAULT … Written to by Tess ONLY (AD-008)," while Z2 says session reports are written by Crumb at session end, and Z1 says the dispatch queue is read by Crumb and written by Tess.
  - [Why]: This is the most important architectural inconsistency in the document. If AD-008 truly means Tess is the only writer to the vault, then Crumb cannot write session reports directly. If Crumb can write reports, the "Tess ONLY" statement is false or needs refinement. This affects correctness of the authority model and implementation mechanics.
  - [Fix]: Explicitly reconcile AD-008 with Z. For example: "All vault writes are mediated by Tess-promoted channels; interactive executor may write staged artifacts/reports to approved paths, subject to promotion/ingestion rules." Update the system map language accordingly.

- [F2]
  - [Severity]: CRITICAL
  - [Finding]: The amendment is inconsistent about where session reports are stored. Z2 defines reports as YAML files under `_tess/reports/session-{date}-{sequence}.yaml`, but Session Report Rule 5 says the preferred backend is SQLite under `~/.tess/state/`.
  - [Why]: This is not just an implementation detail; it changes the interface contract for ingestion, observability, startup behavior, and event triggers. A spec amendment should define the authoritative storage model, not leave the core artifact half file-based and half database-based.
  - [Fix]: Choose one canonical interface. Best option: define the canonical contract as file-based session report YAML in the vault or state directory, and optionally mirror/index into SQLite for queries. If SQLite is canonical, replace the file path schema and define the ingestion API instead of a YAML file path.

- [F3]
  - [Severity]: CRITICAL
  - [Finding]: Queue mutation rules are internally inconsistent. Z1 says the queue is append-only between planning cycles and items are only removed when a session report confirms completion. Z4 says autonomous items are dispatched immediately after queue refresh and "on completion, remove the item from the queue and log results."
  - [Why]: This creates ambiguity about who is allowed to mutate queue state and when. For autonomous items, completion may happen between planning cycles, which violates the append-only rule unless explicitly exempted.
  - [Fix]: Define queue state transitions precisely. Example: "Between planning cycles, only Tess may mark items `in_progress`, `completed`, or `failed`; items are never physically removed until next refresh. Session reports and autonomous run results are append-only events that Tess folds into the next queue materialization."

- [F4]
  - [Severity]: SIGNIFICANT
  - [Finding]: Concurrent interactive sessions are not adequately handled. The queue is a shared current-state artifact, but there is no claim/lease/reservation mechanism, no session identifier tied to queue item execution, and no conflict policy if two sessions start from the same queue.
  - [Why]: One of the requested focus areas is concurrent sessions. Without a claim model, duplicate execution, conflicting edits, and inconsistent reporting are likely. Even if concurrency is rare today, the spec should define expected behavior.
  - [Fix]: Add `claimed_by`, `claimed_at`, `claim_expires_at`, and `session_id` fields, or specify that only one interactive session may be active at a time and enforce it. At minimum, include session-start claim semantics and stale-claim recovery rules.

- [F5]
  - [Severity]: SIGNIFICANT
  - [Finding]: Queue staleness handling is under-specified. The queue has `updated_at` and `planning_cycle`, but there is no TTL, freshness threshold, degraded-mode behavior, or startup warning if the queue is stale or the planning service has failed.
  - [Why]: The authority model depends on Tess being current. If the queue is old, Crumb may follow obsolete priorities, or the operator may overtrust stale recommendations.
  - [Fix]: Add explicit freshness policy, e.g., "If `updated_at` is older than 24h or older than last known project-state/session activity, startup summary must show `STALE DISPATCH` and treat queue recommendations as advisory only." Include remediation and fallback behavior.

- [F6]
  - [Severity]: SIGNIFICANT
  - [Finding]: The operator override model is captured only after the fact in session reports; there is no explicit representation of override state in the active queue or planning inputs prior to session completion.
  - [Why]: This weakens Tess's real-time authority model. If an operator starts unqueued work, Tess remains unaware until the session ends, which is acceptable operationally but not fully aligned with the "never loses awareness" framing.
  - [Fix]: Tone down the claim or add an optional lightweight "session-start intent" artifact: selected queue item or override summary written at session start. This would let Tess distinguish "queued work in progress" from "override in progress."

- [F7]
  - [Severity]: SIGNIFICANT
  - [Finding]: The session report schema is useful but not complete enough for reliable planning authority. It lacks stable references for decisions, blockers, dependencies, and produced artifacts. `notes` and free-text statuses still require interpretation.
  - [Why]: If Tess is supposed to ingest reports mechanically, too much semantic load remains in prose. For example, "72h soak in progress, gate ~Apr 9" is human-readable but not ideal for deterministic planning.
  - [Fix]: Add structured fields such as `artifacts_created`, `blockers`, `dependencies_changed`, `gates_started`, `gates_expected_at`, `next_actions`, and decision IDs. Preserve free-text rationale, but pair it with machine-usable fields.

- [F8]
  - [Severity]: SIGNIFICANT
  - [Finding]: The dispatch queue schema does not model item lifecycle states explicitly.
  - [Why]: Today the queue conflates "pending recommendation list" with execution tracking. Without a state field like `queued | claimed | in_progress | blocked | completed | failed | superseded`, it is hard to reason about who should act and what Tess should surface.
  - [Fix]: Add an explicit `status` field plus timestamps for key transitions. This will also make queue refresh, stale detection, and autonomous/interactive handoff cleaner.

- [F9]
  - [Severity]: SIGNIFICANT
  - [Finding]: Cross-project priority arbitration is described at a high level ("liberation directive," dependency ordering) but not specified enough to be reproducible.
  - [Why]: The planning service is central authority. If two projects both have high-priority interactive items, the queue order becomes policy. Without a defined tie-break method, behavior may be unstable or opaque.
  - [Fix]: Add ordering rules with deterministic tie-breakers, e.g., strategic class > unblock count > aging > operator-set project weight > lexical ID as final tiebreaker. Include examples.

- [F10]
  - [Severity]: SIGNIFICANT
  - [Finding]: Failure modes for the planning service are not sufficiently addressed. The amendment introduces a new critical service but does not define what happens if it crashes, misses schedules, produces malformed YAML, or ingests a malformed report.
  - [Why]: This is a core operational risk. A dispatch authority mechanism needs robust degraded-mode behavior.
  - [Fix]: Add a failure-handling section: validation on write, atomic file replacement, last-known-good queue retention, startup warnings for malformed/stale queue, dead-letter handling for bad session reports, and alerting in observability.

- [F11]
  - [Severity]: SIGNIFICANT
  - [Finding]: The graduated autonomy model lacks hard governance boundaries to prevent silent expansion of Tess's remit.
  - [Why]: "Each task class Tess successfully executes autonomously expands her proven capability set" is sensible, but there is no explicit approval threshold, audit rule, rollback trigger, or list of forbidden classes. This creates risk of overstepping.
  - [Fix]: Define safeguards such as: task classes must be whitelisted; graduation requires N consecutive successes; operator approval required for first promotion of a class; mandatory review on any failure; certain classes permanently interactive-only (architecture changes, credential changes, destructive ops).

- [F12]
  - [Severity]: SIGNIFICANT
  - [Finding]: The capability inversion argument is broadly sound, but it overstates that orchestration only requires "state-aware routing." In practice, queue construction will often involve judgment about value, risk, and ambiguity.
  - [Why]: The argument is directionally correct—continuity can justify orchestration authority—but the current text risks underspecifying the cognitive demands on Tess. That could lead to overconfidence in a weaker model's planning quality.
  - [Fix]: Reframe: "Default orchestration is continuity-driven scheduling plus bounded prioritization under explicit policy. Deep architectural prioritization may require plan-before-request, operator review, or escalation." Link this directly to Amendment Y and risk gates.

- [F13]
  - [Severity]: SIGNIFICANT
  - [Finding]: The startup behavior says Crumb should propose starting with Tess's top unblocked item, but the sample startup summary includes a HIGH item that is blocked until Apr 6 and a MED item that is ready. It is unclear whether blocked high-priority items are shown above ready medium-priority items and what "top unblocked item" means in presentation.
  - [Why]: This is a UX/policy ambiguity that will matter every session. Surface order drives operator behavior.
  - [Fix]: Specify two sections: `Ready now` and `Upcoming/blocked`. Propose from the highest-priority ready item only. Keep blocked items visible but visually distinct.

- [F14]
  - [Severity]: SIGNIFICANT
  - [Finding]: The implementation sequencing claims "This amendment introduces no new infrastructure. All three artifacts are YAML files in known locations," but Z4 introduces a new planning service and Z2 suggests possible SQLite storage.
  - [Why]: This is internally inconsistent and understates implementation scope.
  - [Fix]: Change to "introduces no new external infrastructure" or "uses existing runtime/execution mechanisms, but adds one new internal service and two new artifact types."

- [F15]
  - [Severity]: SIGNIFICANT
  - [Finding]: The event trigger model is not fully defined. Z4 says the planning service is triggered by "new session report in _tess/reports/," but if reports are in SQLite or are written before promotion/commit, the trigger semantics change.
  - [Why]: Without a precise event source, the reactive loop is ambiguous and may be racy.
  - [Fix]: Define the authoritative trigger as one of: committed report file arrival, DB insert, or promotion-complete event. Tie it to the canonical storage decision.

- [F16]
  - [Severity]: SIGNIFICANT
  - [Finding]: The session-end ordering is inconsistent. Z2 Rule 1 says the session report is written before the prose run-log entry, but the "Relationship to Existing Amendments" section says the session report is a new step "after the run-log entry and before the conditional commit."
  - [Why]: This is a direct contradiction in protocol sequencing.
  - [Fix]: Pick one order and use it consistently everywhere. I'd recommend: generate both artifacts, validate structured report first, then produce run-log, then commit/promote together atomically.

- [F17]
  - [Severity]: MINOR
  - [Finding]: The naming collision between "Crumb vault" and "Crumb interactive executor" is acknowledged but still likely to confuse readers and implementers.
  - [Why]: This makes system diagrams and prose harder to parse.
  - [Fix]: Rename one role in this amendment, e.g., "Vault" vs "Crumb session executor," or consistently use "Claude Code session" for the executor role.

- [F18]
  - [Severity]: MINOR
  - [Finding]: The queue example uses `blocked_until: 2026-04-06` without time zone or time, while `updated_at` uses full ISO timestamp.
  - [Why]: Date-only semantics are often ambiguous around local/UTC boundaries and startup decisions.
  - [Fix]: Standardize on RFC 3339 timestamps or explicitly define date-only as local-day semantics in a specified timezone.

- [F19]
  - [Severity]: MINOR
  - [Finding]: `estimated_effort` is free text.
  - [Why]: Human-friendly, but less useful for planning or UI sorting.
  - [Fix]: Consider structured effort fields like `effort_class: short|half_day|multi_day` plus optional text note.

- [F20]
  - [Severity]: MINOR
  - [Finding]: `tests_passing: 350` in the session report is not self-describing.
  - [Why]: It is unclear whether this is total tests run, cumulative project passing count, or the number newly passing in-session.
  - [Fix]: Rename to something like `tests_passed_count` and add related fields such as `tests_run_count`, `test_suite_scope`, or `verification_summary`.

- [F21]
  - [Severity]: MINOR
  - [Finding]: `decisions_made` in the queue and `decisions.made` in reports are only prose strings/records; there is no deduplication or ID scheme.
  - [Why]: Repeated follow-up sessions may duplicate or diverge on the same decision.
  - [Fix]: Add optional decision IDs and status (`active`, `superseded`) to support traceability.

- [F22]
  - [Severity]: MINOR
  - [Finding]: The queue rule "Tess refreshes the full queue during each planning cycle" is compatible with current-state materialization, but "append-only between planning cycles" suggests event-log semantics.
  - [Why]: The wording mixes two data model concepts.
  - [Fix]: Clarify that the queue is a materialized current-state view regenerated by Tess; append-only semantics apply to reports/events, not necessarily the queue file itself.

- [F23]
  - [Severity]: STRENGTH
  - [Finding]: The amendment addresses a real and important gap in the base spec: the orchestrator lacked a mechanism to maintain authority across interactive work.
  - [Why]: This is a strong architectural correction. The problem statement is concrete and aligned with the system's stated success criteria.
  - [Fix]: None.

- [F24]
  - [Severity]: STRENGTH
  - [Finding]: The separation between dispatch authority and operator override is well-conceived.
  - [Why]: It preserves human sovereignty while making Tess the default planner, which is likely the right balance for this environment.
  - [Fix]: None.

- [F25]
  - [Severity]: STRENGTH
  - [Finding]: The core pattern—current-state dispatch queue plus append-only structured session reports—is a sound design direction.
  - [Why]: It mirrors established control-plane/data-plane patterns and gives Tess something machine-readable to ingest without requiring full transcript analysis.
  - [Fix]: None.

- [F26]
  - [Severity]: STRENGTH
  - [Finding]: The amendment appropriately distinguishes orchestration continuity from executor intelligence.
  - [Why]: The "capability inversion" rationale is directionally persuasive and matches how many systems separate planner/controller roles from specialized workers.
  - [Fix]: None, beyond the nuance suggested in F12.

- [F27]
  - [Severity]: STRENGTH
  - [Finding]: The startup hook integration is low ceremony and likely to be effective.
  - [Why]: Surfacing Tess's priorities at session start is a pragmatic way to shift default authority without adding much operator friction.
  - [Fix]: None.

- [F28]
  - [Severity]: STRENGTH
  - [Finding]: The amendment ties into prior decisions and amendments thoughtfully.
  - [Why]: The relationships to run_history, Amendment Y, and escalation concepts show good architectural continuity rather than introducing a disconnected subsystem.
  - [Fix]: None.

- [F29]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: "Evaluated 10 external agent systems …" and "all systems … assume the orchestrator maintains continuous authority."
  - [Why]: The artifact names several systems and draws a universal conclusion, but the review cannot independently verify the evaluation corpus, methodology, or conclusion from the amendment alone.
  - [Fix]: Add a concise appendix or citation table summarizing the 10 systems reviewed, source links, and the specific evidence supporting the conclusion.

- [F30]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: "The closest analog is Pedro's Autopilot pattern" and references to "Pedro autopilot extraction."
  - [Why]: This prior-art comparison may be valid, but no independently verifiable source, URL, or excerpt is provided here.
  - [Fix]: Cite the source artifact or external reference explicitly and summarize the analogous mechanism.

- [F31]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: "Kimi K2.5's demonstrated capability" and "Kimi K2.5, scored 76."
  - [Why]: Model version/capability claims and score references are factual assertions that cannot be verified from the amendment text.
  - [Fix]: Provide the benchmark source, scoring rubric, and location of the evaluation artifact.

- [F32]
  - [Severity]: SIGNIFICANT
  - [Finding]: UNVERIFIABLE CLAIM: "run_history (built 2026-04-03)" and TV2-045 as a tracking item.
  - [Why]: Internal implementation status and issue/task references are not independently verifiable from the provided artifact.
  - [Fix]: Add explicit internal references or remove date-specific certainty if the amendment is meant to stand alone.

Overall assessment:
- Correctness: promising but currently blocked by core contradictions in write authority, report storage, and session-end/queue mutation semantics.
- Completeness: good conceptual coverage, but missing concurrency, stale/degraded-mode behavior, and hard safeguards for autonomy expansion.
- Internal consistency: moderate; several direct contradictions should be resolved before acceptance.
- Feasibility: high once the contract surfaces are tightened. The proposed mechanisms are implementable with modest effort.
- Clarity: generally strong at the intent level, weaker at protocol/state-machine precision.

Recommended disposition:
- Accept in principle, revise before adoption. The design intent is strong, but F1/F2/F3/F16 should be resolved as acceptance blockers.

---

## Google (gemini-3.1-pro-preview)

Here is the structured review of Spec Amendment Z for the Tess v2 / Crumb OS ecosystem.

### Unverifiable Claims
- [F1]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Reference to "Kimi K2.5, scored 76".
- [Why]: The prompt requires flagging specific model versions and statistics with attributed sources. The model version (K2.5) and the specific benchmark/score (76) cannot be independently verified from public consensus data without knowing the specific benchmark being referenced.
- [Fix]: Specify the benchmark that yielded the "76" score (e.g., HumanEval, MMLU, SWE-bench) or remove the specific number if it is not structurally necessary to the spec.

- [F2]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: References to "MiniMax M2.7".
- [Why]: Specific software/model version reference that cannot be independently verified.
- [Fix]: Ensure this version exists in the current environment or abstract to "MiniMax M-series" if the exact minor version is volatile.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Reference to highly specific/niche external agent systems (MiroFish, Slate V1, Pedro's Autopilot, Subconscious Agent, Gkisokay Stack, Compound Engineering Plugin, Paperclip evaluation).
- [Why]: While tools like LangSmith are widely verifiable, the others appear to be internal, niche, or private OS experiments. Their architectural properties cannot be independently verified.
- [Fix]: Provide a brief architectural summary or link to the specific repository/paper for these references in a footnote, ensuring future maintainers understand the precedents.

### Architecture & Logic Evaluation

- [F4]
- [Severity]: CRITICAL
- [Finding]: Contradiction in queue update frequency and staleness logic (Focus Areas 1 & 5).
- [Why]: Section Z1 states the queue is "append-only between planning cycles" and that items are "only removed when a session report confirms completion." However, Z4 introduces an `event_trigger: "new session report in _tess/reports/"` that causes the planning service to refresh the queue. If the queue is fully refreshed upon every session report, the "between cycles" manual removal rules from Z1 are either redundant or contradictory.
- [Fix]: Standardize the refresh lifecycle. Either the queue is *exclusively* maintained by the Z4 planning service (which runs after every session report), or Z1's manual removal rules apply *only* as a fallback if the Z4 service fails to run.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Lack of concurrency controls / checkout mechanisms in the dispatch queue (Focus Areas 1 & 5).
- [Why]: If Danny opens multiple Claude Code instances (e.g., one for frontend, one for backend debugging), both instances will read the exact same `queue.yaml` and potentially propose starting the identical `IDQ-001` task.
- [Fix]: Introduce a lightweight locking or "claimed" state mechanism in the queue. When Crumb accepts a task at startup, it should briefly write back to the queue (or a lockfile) marking `IDQ-001` as `status: in-progress`.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: "Graduated autonomy" lacks a negative-space safeguard against silent failures (Focus Area 3).
- [Why]: Z4 states that classes with consistent success "no longer need operator review" and rely strictly on deterministic criteria (e.g., tests passing). However, LLMs are known to "cheat" deterministic tests (e.g., writing tautological tests that always pass to satisfy criteria). Without periodic random sampling or audit gates, Tess could confidently execute and silently degrade the codebase.
- [Fix]: Add an `audit_rate` or `spot_check_frequency` to the graduated autonomy model. Even for "proven" capability sets, Tess should flag 1 in N successful tasks for operator review.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Unhandled failure mode for the Planning Service (Focus Area 5).
- [Why]: If the `interactive-planning` service (Z4) crashes due to a malformed session report or context window limit, the `queue.yaml` will quietly go stale. Danny will boot Crumb, see old priorities, and unknowingly drift from current system state.
- [Fix]: Add a staleness check to Z3 (Startup Hook Integration). If `updated_at` in `queue.yaml` is older than 24 hours, Crumb should alert the operator that "Tess's planning cycle may be failing."

- [F8]
- [Severity]: MINOR
- [Finding]: High cognitive load on Crumb for generating the `decisions_made` schema (Focus Area 2).
- [Why]: The Session Report schema is generally comprehensive without being overly burdensome for an LLM to output. However, extracting accurate `decisions_made` and `deferred` items requires the LLM to effectively summarize a potentially massive context window of interactive back-and-forth just before the session ends. It may hallucinate or miss subtle architectural decisions.
- [Fix]: Instruct Crumb in its prompt architecture to maintain a running scratchpad of decisions *during* the session, rather than forcing a heavy read-back at session-end.

- [F9]
- [Severity]: STRENGTH
- [Finding]: The "Capability Inversion" justification is logically sound and aligns with standard distributed systems patterns (Focus Area 4).
- [Why]: Arguing that orchestration requires continuity and state-awareness over deep reasoning elegantly justifies using a less capable model (Kimi K2.5) to route work to a more capable one (Opus). It correctly identifies that tracking temporal dependencies (gates) and reading schemas is a fundamentally different capability than writing complex code.

- [F10]
- [Severity]: STRENGTH
- [Finding]: Graceful handling of operator overrides.
- [Why]: Designing the system to expect, accept, and mechanically ingest human overrides (via the `operator_overrides` field in the session report) prevents the orchestrator from breaking when the human inevitably deviates from the queue. It maintains the single source of truth without enforcing rigid, brittle constraints.

---

## DeepSeek (deepseek-reasoner)

**Structured Review of Amendment Z: Interactive Dispatch & Orchestrator Authority**

---

**F1**
- **Severity:** STRENGTH
- **Finding:** The amendment correctly identifies a critical architectural inversion (Crumb as de facto orchestrator) and proposes a coherent solution aligning with the system's stated goals.
- **Why:** This addresses a fundamental flaw in the original spec where Tess's orchestration role was nominal rather than operational. The problem statement is well-supported by operational evidence.

**F2**
- **Severity:** STRENGTH
- **Finding:** The "capability inversion" argument (less-capable orchestrator directing more-capable executor) is sound and well-articulated.
- **Why:** It correctly distinguishes between continuous state-aware scheduling (orchestration) and deep episodic reasoning (execution). This separation of concerns is architecturally valid.

**F3**
- **Severity:** SIGNIFICANT
- **Finding:** The dispatch queue schema lacks explicit handling for concurrent interactive sessions.
- **Why:** If multiple Claude Code sessions are opened simultaneously (e.g., across different projects), both would read the same queue with no mechanism to mark items "in progress," risking duplicate work.
- **Fix:** Add an `in_progress_by` field (session ID or timestamp) and a rule that items marked in-progress are not actionable in other sessions until a timeout or explicit release.

**F4**
- **Severity:** SIGNIFICANT
- **Finding:** The session report schema does not account for partial or crashed sessions.
- **Why:** If a session terminates unexpectedly (system crash, Claude Code disconnect), no report is generated, creating an observability gap.
- **Fix:** Add a lightweight "session heartbeat" mechanism (e.g., periodic timestamp file) and a session-start hook that can generate a minimal report for the previous session if no clean report exists.

**F5**
- **Severity:** SIGNIFICANT
- **Finding:** The graduated autonomy model lacks a clear rollback or human-confirmation threshold.
- **Why:** While autonomous success rate tracking is mentioned, there's no defined threshold (e.g., "3 consecutive successes") or escalation trigger (e.g., "any failure in this task class reverts to interactive for N cycles").
- **Fix:** Add explicit criteria in Z4 for autonomous promotion/demotion, documented as part of the planning service contract.

**F6**
- **Severity:** SIGNIFICANT
- **Finding:** The planning service has a single-point-of-failure risk; a crash could leave the queue stale indefinitely.
- **Why:** No health monitoring or fallback mechanism is specified for the planning service. Stale queue could misdirect interactive sessions.
- **Fix:** Add a "queue freshness" check in the startup hook (Z3) that warns if queue is older than, e.g., 36 hours, and allows operator to trigger a manual refresh.

**F7**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: References to external systems (MiroFish, LangSmith, etc.) and their convergence on orchestrator-maintains-authority pattern.
- **Why:** The amendment uses these as external validation, but without access to the evaluation document, we cannot verify the characterization.

**F8**
- **Severity:** SIGNIFICANT
- **Finding:** UNVERIFIABLE CLAIM: References to prior amendments T-Y and design documents (services-vs-roles analysis, Pedro autopilot extraction).
- **Why:** The amendment builds upon these, but without access to those documents, we cannot verify consistency or dependencies.

**F9**
- **Severity:** MINOR
- **Finding:** The `estimated_effort` field in the dispatch queue uses ambiguous strings ("half-day") rather than machine-interpretable units.
- **Why:** This limits Tess's ability to reason about capacity or schedule multiple items.
- **Fix:** Use a numeric field (e.g., `estimated_minutes`) with a convention (e.g., "half-day" = 240).

**F10**
- **Severity:** MINOR
- **Finding:** The session report's `model_routing` section includes `cost_estimate_usd`, which may be difficult for Crumb to compute accurately.
- **Why:** Requires real-time knowledge of model pricing and token counts, adding complexity.
- **Fix:** Make this optional or compute it post-session via a separate lightweight analysis service.

**F11**
- **Severity:** MINOR
- **Finding:** The schema for `decisions_made` in both queue and report is unstructured text, which may complicate automated reasoning.
- **Why:** While intended for human consumption, Tess may need to parse decisions to respect them in future planning.
- **Fix:** Consider a structured format (key-value pairs) for critical decisions, or maintain a separate decisions registry with unique IDs.

**F12**
- **Severity:** STRENGTH
- **Finding:** The operator override mechanism is well-designed—explicitly allowed, tracked, and treated as planning data rather than failure.
- **Why:** This preserves operator sovereignty while giving Tess the feedback needed to improve its planning.

**F13**
- **Severity:** STRENGTH
- **Finding:** The implementation sequencing is realistic and accounts for cold-start (Z5 bootstrap).
- **Why:** Shows pragmatic understanding that full automation requires incremental deployment.

**F14**
- **Severity:** SIGNIFICANT
- **Finding:** Conflicting priorities between projects are not addressed in the planning cycle.
- **Why:** The liberation directive prioritizes revenue-generating prompts, but the planning service might need to arbitrate between multiple projects with competing high-priority items.
- **Fix:** In Z4, add a prioritization algorithm that considers project strategic weight (beyond just liberation directive) and explicit operator-set project priorities.

**F15**
- **Severity:** MINOR
- **Finding:** The system map update shows a bidirectional arrow between Tess and Crumb (interactive executor), but the directionality of interactions isn't labeled.
- **Why:** Could cause confusion about which component initiates which flows.
- **Fix:** Annotate arrows with "dispatch queue →", "session report →", etc., or split into separate unidirectional arrows.

---

**Overall Assessment:**
The amendment is conceptually sound, well-structured, and addresses a critical gap in the specification. The proposed mechanisms (dispatch queue, session reports, planning cycle) form a coherent loop that establishes Tess's operational authority while preserving operator override. Significant issues relate primarily to edge cases (concurrency, crashes, stale state) and lack of verifiability for external references. These should be addressed before implementation, but do not undermine the core design.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]
- [Severity]: CRITICAL
- [Finding]: Direct contradiction with AD-008 (vault written to by Tess ONLY); Crumb (interactive executor) is required to write session reports to _tess/reports/ in the vault.
- [Why]: This breaks the single-writer invariant, risking data corruption, race conditions, or vault lock violations during concurrent reads/writes. The proposal assumes Crumb can write without addressing how this complies with prior ADs.
- [Fix]: Explicitly amend AD-008 to allow structured reports from interactive executors, or route Crumb writes through Tess (e.g., Crumb proposes report, Tess ratifies). Define write protocol (e.g., temp file + atomic mv).

- [F2]
- [Severity]: CRITICAL
- [Finding]: Dispatch queue rules claim "append-only between planning cycles" but also state autonomous items are removed on completion, creating undefined behavior for queue mutation outside cycles.
- [Why]: Logical inconsistency in queue semantics; could lead to lost items, duplicates, or desync if autonomous dispatch happens mid-cycle. Breaks "Tess writes, Crumb reads" invariant.
- [Fix]: Clarify queue as read-only for Crumb; all mutations (add/remove) only by Tess during planning cycles. Autonomous dispatch must queue a "completion stub" that Tess processes next cycle.

- [F3]
- [Severity]: SIGNIFICANT
- [Finding]: No handling for concurrent sessions (e.g., multiple Claude Code tabs/windows); queue lacks sequence numbers, locks, or session IDs to prevent duplicate execution of same item.
- [Why]: Edge case in focus area #1; on Mac Studio, operator could start parallel sessions, leading to redundant work, conflicting reports, or queue desync without coordination.
- [Fix]: Add `claimed_by_session: {date}-{sequence}` to queue items; Crumb claims top item atomically (e.g., via write-lock or SQLite). Session report releases claim on completion.

- [F4]
- [Severity]: SIGNIFICANT
- [Finding]: Queue lacks staleness detection (e.g., no `version` or `last_updated` validation beyond `updated_at`); Crumb reads blindly.
- [Why]: Focus area #1; if Tess planning fails/skips cycles (failure mode #5), Crumb uses stale data unknowingly, inverting hierarchy again.
- [Fix]: Crumb startup hook validates `updated_at > yesterday`; if stale, surface warning + fallback to vault scan. Add `version: incremental` field.

- [F5]
- [Severity]: SIGNIFICANT
- [Finding]: Session report schema undecided on storage (YAML files vs. SQLite); examples use YAML paths but rules prefer SQLite for queries.
- [Why]: Focus area #2; ambiguity blocks implementation (Z-2/Z-4); YAML doesn't scale for "cross-record queries" like decision history, forcing ad-hoc parsing.
- [Fix]: Finalize as SQLite (migrate schema to table DDL); provide YAML→SQLite loader for bootstrap. Update rules to reference DB.

- [F6]
- [Severity]: SIGNIFICANT
- [Finding]: Graduated autonomy lacks safeguards/mechanisms (e.g., no schema for tracking success rates by task class, no escalation thresholds, no human review gate for new classes).
- [Why]: Focus area #3; Tess could overstep into non-deterministic tasks (e.g., misclassifying design work), accumulating errors without oversight. Vague "consistent success" invites failure.
- [Fix]: Add `autonomy_tracking` table/schema in planning inputs; define thresholds (e.g., 90% success over 5 runs); require operator ratification for new task classes.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: Failure modes unaddressed: planning service crash/staleness leaves queue frozen; no fallback planner or multi-project priority conflict resolution (e.g., tess-v2 vs. Firekeeper).
- [Why]: Focus area #5; breaks "Tess as authority" if unhandled; operator must manually intervene, reverting to pre-amendment inversion.
- [Fix]: Add queue footer with `health: {last_successful_cycle, fallback_mode}`; Crumb detects and proposes manual queue if >48h stale. Define priority schema (e.g., liberation scores).

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Evaluation of 10 external systems (MiroFish, LangSmith, etc.) claims "all converge on orchestrator-maintains-authority"; no links/sources provided.
- [Why]: Undermines problem statement/rationale; if false, weakens novelty claim and proposed solution.
- [Fix]: Add `design/external-systems-evaluation-2026-04-04.md` excerpts or public URLs; or qualify as "operator assessment."

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: Specific spec references (e.g., §3.1 line 85, §16 success criteria) and prior ADs/amendments (AD-001–012, T–Y) cited without quotes/context.
- [Why]: Cannot assess if proposal correctly extends existing spec; risks building on misread sections.
- [Fix]: Inline quote key lines (e.g., "Tess operates as..."); link to vault paths.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Operator override tracking incomplete: session report records overrides but queue lacks field to propagate/learn from them (e.g., no `override_history`).
- [Why]: Focus area #1; Tess can't adjust planning without manual review of reports each cycle, adding cognitive load.
- [Fix]: Add `overrides_learned` array to queue (pulled from recent reports); planning service auto-downgrades overridden priorities.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: "Capability inversion" argument assumes Kimi K2.5 suffices for planning without evidence; claims "within demonstrated capability" but no benchmarks cited.
- [Why]: Focus area #4; if Kimi fails state-aware routing (e.g., temporal/dependency logic), entire authority model collapses.
- [Fix]: Reference specific Kimi evals (e.g., TV2-Cloud scores); prototype planning prompt in amendment.

- [F12]
- [Severity]: MINOR
- [Finding]: System map update uses ASCII art inconsistently (e.g., Crumb vault vs. executor distinction noted but visually merged).
- [Why]: Reduces clarity for implementers skimming §3.1 update.
- [Fix]: Use distinct boxes/labels: "Crumb Vault (RO for Crumb exec)" and "Crumb Exec".

- [F13]
- [Severity]: MINOR
- [Finding]: Implementation sequencing (Z-5 bootstrap) risks chicken-egg: manual queue by Crumb writes to _tess/dispatch/ (vault), violating AD-008 pre-amendment.
- [Why]: Minor bootstrap gap; could block Phase 4 rollout.
- [Fix]: Clarify Z-5 as temp file → Tess promotion, or exception for bootstrap.

- [F14]
- [Severity]: STRENGTH
- [Finding]: Session report schema is mostly complete for Tess ingestion (covers outcomes, decisions, remaining work) without excessive burden on Crumb (repurposes run-log data).
- [Why]: Focus area #2; balances machine-readability with low ceremony, enabling authority without verbose mandates.
- [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. AD-008 vault write authority contradiction** (OAI-F1, GRK-F1)
AD-008 states vault is "written to by Tess ONLY," but Z2 requires Crumb to write session reports to the vault. Two reviewers flagged this as CRITICAL. The single-writer invariant needs explicit amendment or a mediated write path.

**2. Queue append-only vs. autonomous removal inconsistency** (OAI-F3, GEM-F4, GRK-F2)
Z1 says the queue is append-only between planning cycles. Z4 says autonomous items are removed on completion. Three reviewers flagged this as CRITICAL/SIGNIFICANT. The queue mutation model is contradictory.

**3. Concurrent session handling absent** (OAI-F4, GEM-F5, DS-F3, GRK-F3)
All four reviewers flagged no claim/lock mechanism for queue items. Multiple sessions could read the same queue and execute the same item. Consensus: needs at minimum a claimed_by field or single-session constraint.

**4. Graduated autonomy lacks hard safeguards** (OAI-F11, GEM-F6, DS-F5, GRK-F6)
All four reviewers flagged that "consistent success expands authority" has no defined thresholds, no operator approval gate for new task classes, and no mandatory audit. Consensus: needs explicit promotion criteria, demotion triggers, and a forbidden-classes list.

**5. Planning service failure / queue staleness** (OAI-F5/F10, GEM-F7, DS-F6, GRK-F7)
All four reviewers flagged that a crashed planning service leaves the queue silently stale. Consensus: startup hook must check queue freshness and warn if stale.

**6. Session report storage ambiguity** (OAI-F2, GRK-F5)
Z2 schema shows YAML file paths but Rule 5 says "preferred backend is SQLite." Two reviewers flagged this as contradictory. Must pick one canonical interface.

**7. Session-end ordering contradiction** (OAI-F16)
Z2 Rule 1 says report is written before run-log; the Relationship section says after. Only one reviewer caught this explicitly, but it's a clear textual contradiction.

**8. Unverifiable external claims** (OAI-F29/F30/F31/F32, GEM-F1/F2/F3, DS-F7/F8, GRK-F8/F9)
All four reviewers flagged references to external systems, Kimi K2.5 scores, and Pedro's Autopilot as unverifiable from the amendment alone. These are internal references that exist in the vault — not fabrications — but the amendment doesn't cross-reference them.

### Unique Findings

**DS-F4: Crashed session reporting gap** — DeepSeek uniquely flagged that crashed/terminated sessions produce no report at all, leaving an observability gap. Genuine insight — the session-end protocol is only triggered on clean exits. A lightweight session-start marker would enable detecting orphaned sessions.

**OAI-F7: Session report schema needs structured fields** — OpenAI uniquely pushed for machine-readable fields like `gates_started`, `gates_expected_at`, `artifacts_created` instead of prose `notes`. Valid — if Tess is parsing these mechanically, structured beats prose.

**OAI-F8: Queue item lifecycle states** — OpenAI uniquely proposed explicit `queued | claimed | in_progress | completed | failed | superseded` states. Genuine insight — the queue conflates recommendation list with execution tracker.

**GEM-F6: LLM "cheating" deterministic tests** — Gemini uniquely flagged that graduated autonomy with deterministic success criteria could be gamed by models writing tautological tests. Interesting but low-probability in the contract runner model — tests are authored in contracts, not by the executor.

**GEM-F8: Running scratchpad for decisions** — Gemini suggested Crumb maintain a running decisions scratchpad during sessions rather than reconstructing at session-end. Valid ergonomic improvement.

**GRK-F10: Override learning loop** — Grok uniquely proposed an `overrides_learned` field so the planning service can auto-adjust priorities when operators repeatedly override. Interesting but premature — the override data needs to accumulate before pattern extraction makes sense.

**GRK-F13: Bootstrap violates AD-008** — Grok caught that Z-5 (manual bootstrap) has Crumb writing to `_tess/dispatch/`, which itself violates AD-008 pre-amendment. Valid edge case for sequencing.

### Contradictions

**Session report storage: YAML vs. SQLite.** OAI and GRK say pick one. GRK explicitly recommends SQLite. The run-log entry (2026-04-04) already decided SQLite. The amendment text is ambiguous because it presents the YAML schema first and mentions SQLite as "preferred" later. Not a real disagreement — the amendment just needs to commit.

**Capability inversion soundness.** OAI-F12 says the argument overstates simplicity of planning. GEM-F9 and DS-F2 say the argument is sound. GRK-F11 says it needs benchmark evidence. The core concept is valid (all agree), but OAI and GRK correctly note it needs qualification — planning sometimes requires judgment beyond pure routing.

### Action Items

**Must-fix (blocking):**

- **A1** (OAI-F1, GRK-F1): Amend AD-008 to carve out structured report writes from interactive executors, or define a mediated write path (Crumb proposes, Tess promotes). This is the foundational authority model — it must be internally consistent.

- **A2** (OAI-F3, GEM-F4, GRK-F2): Resolve queue mutation semantics. Define the queue as a materialized view regenerated by Tess each planning cycle. Between cycles, items gain status transitions (in_progress, completed) but are never physically removed. Autonomous completions are recorded as events that Tess folds into the next materialization.

- **A3** (OAI-F2, GRK-F5): Commit to SQLite for session reports (consistent with run_history pattern and the run-log's own stated preference). Remove the YAML file path schema or reframe it as the logical schema that maps to SQLite columns.

- **A4** (OAI-F16): Fix session-end ordering contradiction. Pick one: report before run-log (Z2 Rule 1) or after (Relationship section). Recommend: report first (Tess needs it sooner), run-log second.

**Should-fix (significant but not blocking):**

- **A5** (OAI-F4, GEM-F5, DS-F3, GRK-F3): Add concurrency handling. At minimum: `claimed_by` and `claimed_at` fields on queue items, with stale-claim expiry. Or: explicitly constrain to single interactive session (simpler, matches current reality).

- **A6** (OAI-F11, GEM-F6, DS-F5, GRK-F6): Define graduated autonomy safeguards: N consecutive successes required for promotion, operator approval for first promotion of each task class, any failure reverts to interactive for M cycles, maintain a permanently-interactive-only list (architecture changes, credential ops, destructive actions).

- **A7** (OAI-F5/F10, GEM-F7, DS-F6, GRK-F7): Add queue freshness check to startup hook. If `updated_at` > 24h old, show `STALE DISPATCH` warning and treat queue as advisory only. Include planning service health in existing health monitoring.

- **A8** (OAI-F8): Add explicit `status` field to queue items: `queued | claimed | in_progress | blocked | completed`. This clarifies the item lifecycle and supports concurrency handling (A5).

- **A9** (OAI-F12, GRK-F11): Qualify the capability inversion argument. Reframe as "default orchestration is continuity-driven scheduling under explicit policy; complex prioritization may require plan-before-request or escalation." Reference Kimi eval scores with artifact path.

- **A10** (DS-F4): Address crashed session gap. Add a session-start marker (`_tess/sessions/active-{date}-{seq}.yaml`) that the next session-start hook can detect as orphaned. Generate a minimal "incomplete session" report for Tess.

**Defer:**

- **A11** (OAI-F7, DS-F11): Structured decision fields and decision IDs. Valid for mature state but premature before the basic loop is running. Revisit after first planning cycle operates.

- **A12** (OAI-F19, DS-F9): Structured effort fields. Free-text is fine for bootstrap; machine-readable effort is optimization.

- **A13** (GRK-F10): Override learning loop. Needs data accumulation first.

- **A14** (OAI-F17): Rename "Crumb" disambiguation. The naming collision is acknowledged in the text and manageable.

- **A15** (OAI-F29-32, GEM-F1-3, DS-F7-8, GRK-F8-9): Add cross-references to vault artifacts for external system claims, Kimi scores, Pedro extraction. These are internal references, not fabrications — adding vault paths resolves the verifiability concern.

### Considered and Declined

- **GEM-F6 (LLM test cheating)** — `overkill`. In the contract runner model, tests are authored in contracts by the operator/Crumb, not by the executor. The executor runs them; it doesn't write them. The "cheating" risk applies to systems where the agent authors its own success criteria, which this isn't.

- **GRK-F13 (bootstrap violates AD-008)** — `constraint`. The bootstrap (Z-5) is explicitly a cold-start mechanism before the full loop operates. AD-008 amendment (A1) will cover this path. No separate fix needed.

- **OAI-F22 (append-only vs. materialized view wording)** — `addressed by A2`. The queue mutation fix resolves this wording issue.

- **OAI-F18 (timestamp format standardization)** — `overkill`. Date-only for `blocked_until` is intentional (day granularity is sufficient for gate dates). Full ISO for `updated_at` is correct for freshness checks. No inconsistency in practice.

- **DS-F15 (system map arrow labels)** — `out-of-scope`. Visual refinement for the next spec revision, not blocking for this amendment.
