---
type: review
review_mode: full
review_round: 1
prior_review: null
artifact:
  - Projects/tess-v2/design/state-machine-design.md
  - Projects/tess-v2/design/escalation-design.md
artifact_type: architecture
artifact_hash: 75f4bc56
prompt_hash: 00397acf
base_ref: null
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-01
updated: 2026-04-01
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
    latency_ms: 76011
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-state-machine-escalation-openai.json
  google:
    http_status: 200
    latency_ms: 110866
    attempts: 2
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-state-machine-escalation-google.json
  deepseek:
    http_status: 200
    latency_ms: 198563
    attempts: 2
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-state-machine-escalation-deepseek.json
  grok:
    http_status: 200
    latency_ms: 32520
    attempts: 1
    raw_json: Projects/tess-v2/reviews/raw/2026-04-01-state-machine-escalation-grok.json
tags:
  - review
  - peer-review
status: active
---

# Peer Review: State Machine + Escalation Design (TV2-017/018)

**Artifact:** Projects/tess-v2/design/state-machine-design.md + Projects/tess-v2/design/escalation-design.md
**Mode:** full
**Reviewed:** 2026-04-01
**Reviewers:** GPT-5.4, Gemini 3.1 Pro Preview, DeepSeek Reasoner (V3.2), Grok 4.1 Fast Reasoning
**Review prompt:** Two-document architecture review covering correctness, completeness, internal consistency, feasibility, failure modes (8 from spec 2.4), and coupling risks between the contract lifecycle state machine and confidence-aware escalation design.

---

## OpenAI (gpt-5.4)

- [F1]
- [Severity]: CRITICAL
- [Finding]: The two documents disagree on the number of gates and the role of Gate 4. Document 1 repeatedly says “three-gate escalation” and defines ROUTING as Gate 1-3, with Gate 4 as a feedback loop after terminal states. Document 2 defines a four-gate routing system and says Gate 4 executes in the routing path.
- [Why]: This is the primary shared boundary. If one implementation treats Gate 4 as per-contract routing-time logic while the other treats it as offline/table-maintenance feedback, routing behavior, tests, and observability will diverge.
- [Fix]: Normalize terminology across both docs. Either:  
  1) define Gate 4 as “post-hoc routing-table reclassification, not per-contract gate,” or  
  2) add explicit per-contract Gate 4 behavior to the state machine.  
  Update titles, inputs, diagrams, and test plans accordingly.

- [F2]
- [Severity]: CRITICAL
- [Finding]: Document 1’s state diagram contains an undeclared state, `PROMOTION_PENDING`, which is not defined in the state definitions or transition table.
- [Why]: This creates an unreachable/unspecified state in the canonical lifecycle and makes the diagram internally inconsistent. Implementers will not know whether lock wait, manifest preparation, or partial promotion uses this state.
- [Fix]: Either remove `PROMOTION_PENDING` from the diagram or formally define it in state definitions and transition table with entry/exit triggers and timeout behavior.

- [F3]
- [Severity]: CRITICAL
- [Finding]: Document 1 Scenario C relies on a “wait state” when write-lock acquisition is denied, but no such state or transition exists. The transition table only allows `QUALITY_EVAL -> PROMOTING` when write-lock is available.
- [Why]: Promotion collision handling is underspecified at runtime. In the current state machine, lock denial has no legal transition, yet one of the key scenarios depends on it.
- [Fix]: Add explicit lock contention behavior, e.g. `QUALITY_EVAL -> PROMOTION_PENDING` or `QUALITY_EVAL -> QUALITY_EVAL(retry_after)` with timeout, backoff, and ledger semantics. Align Scenario C and transition table to that choice.

- [F4]
- [Severity]: CRITICAL
- [Finding]: Gate 2 in Document 2 is not mechanically feasible as described at ROUTING time. It requires Nemotron’s structured confidence output before the task is routed to Nemotron, but ROUTING is defined as the step that decides which executor to assign.
- [Why]: This is a causal loop: the system cannot ask the local executor for confidence until after deciding to consult it, but Gate 2 is specified as part of the routing decision.
- [Fix]: Split routing into two phases:  
  - Phase A: preliminary candidate selection by Gate 1 and Gate 3  
  - Phase B: optional local “routing probe” to Nemotron for confidence on candidate Tier 1/2 tasks  
  Or redefine Gate 2 as a scheduler-side heuristic based on prior confidence telemetry, not a live pre-dispatch field.

- [F5]
- [Severity]: CRITICAL
- [Finding]: Document 1 says ESCALATED occurs when “retry budget exhausted at current tier OR reasoning failure triggers tier upgrade,” but the transition table only allows `EXECUTING -> ESCALATED` on `budget_exhausted`. The reasoning-failure path is missing from the formal transition table.
- [Why]: A core escalation path exists in prose but not in the executable lifecycle spec. This makes mid-loop tier upgrade formally impossible even though scenarios depend on it.
- [Fix]: Add a transition such as `EXECUTING -> ESCALATED | Trigger: retry_preparing classifies reasoning_failure | Guard: higher tier available AND iterations_remaining > 0`.

- [F6]
- [Severity]: CRITICAL
- [Finding]: Human-approval semantics are inconsistent between the docs. Document 1 routes `requires_human_approval` directly from ROUTING to DEAD_LETTER, bypassing execution and “normal promotion.” Document 2 says Gate 3 may set `requires_human_approval: true` while still routing to Tier 3; its integration test expects a contract to reach DEAD_LETTER awaiting Danny, but it does not define whether execution happens before approval.
- [Why]: This affects destructive/external-communications safety. One implementation could dead-letter before execution; another could execute and only block promotion; another could route to Kimi then park. That is a major behavioral contradiction.
- [Fix]: Define a single approval model explicitly: e.g. “approval required before dispatch,” “approval required before side-effecting tool use,” or “approval required before promotion/send.” Add an explicit state if needed, such as `AWAITING_APPROVAL`.

- [F7]
- [Severity]: SIGNIFICANT
- [Finding]: The state machine says “Any -> ABANDONED” on operator cancellation with “release locks,” but ABANDONED is terminal. There is no crash-safe definition for cancellation during `PROMOTING` after partial file copy has begun.
- [Why]: Cancellation during promotion can leave canonical state partially updated unless cancellation is deferred or transformed into recovery semantics. This is especially sensitive because promotion is not truly transactional.
- [Fix]: Specify that cancellation is ignored/deferred while in `PROMOTING`, or add “cancel_requested” as a flag processed after promotion recovery completes. Clarify manifest reconciliation on cancellation.

- [F8]
- [Severity]: SIGNIFICANT
- [Finding]: Document 1 Scenario B claims rollback to “pre-promotion state (from staging backup)” after a crash-window conflict, but the promotion design never stores a backup of overwritten canonical content.
- [Why]: This is not implementable from the described mechanism. Staging contains source artifacts, not prior canonical versions. For overwrite operations, true rollback requires a backup or copy-on-write temp strategy.
- [Fix]: Either revise the scenario to “mark failed and require re-evaluation/manual repair” or extend the promotion protocol to snapshot overwritten canonical files before first write.

- [F9]
- [Severity]: SIGNIFICANT
- [Finding]: The “atomic promotion” claim is overstated. The manifest-based procedure is resumable/idempotent, but not atomic across multiple files because readers can observe a partially promoted canonical set between operations or after a crash.
- [Why]: AD-008 and promotion safety depend on clear guarantees. “Atomic” implies all-or-nothing visibility, which this design does not provide unless using temp paths plus final renames at a consistent boundary.
- [Fix]: Rename the guarantee to “crash-safe resumable promotion,” or redesign promotion to use temp destinations and atomic rename/swap semantics where supported.

- [F10]
- [Severity]: SIGNIFICANT
- [Finding]: Queue poisoning protection is incomplete. Document 1 checks “Queue not poisoned (max-age check)” on `QUEUED -> ROUTING`, but stale contracts older than max age transition to DEAD_LETTER only in prose, not in the transition table.
- [Why]: An important failure-mode mitigation is not represented in formal lifecycle transitions. Implementers may silently skip aged contracts rather than terminally classify them.
- [Fix]: Add `QUEUED -> DEAD_LETTER | Trigger: max_queue_age exceeded | Action: write queue_timeout reason, alert if high-priority`.

- [F11]
- [Severity]: SIGNIFICANT
- [Finding]: The docs disagree on which outcomes feed convergence tracking. Document 1 updates on `COMPLETED`, `ESCALATED`, and `DEAD_LETTER`. Document 2 updates “after every contract reaches a terminal state (COMPLETED, DEAD_LETTER, ABANDONED),” excluding ESCALATED because it is non-terminal.
- [Why]: Convergence metrics will differ depending on implementation. Counting intermediate escalations as entries versus terminal outcomes changes p95, escalation_rate, and reclassification thresholds materially.
- [Fix]: Define a single event schema: e.g. per-attempt records on escalation plus per-contract terminal records, or terminal-only records with embedded escalation_count. Update both docs and examples.

- [F12]
- [Severity]: SIGNIFICANT
- [Finding]: Retry-budget handling is only partially aligned. Document 1 explicitly says budget is per-contract and escalation does not reset it. Document 2 scenarios assume this, but the escalation design never states it as part of ROUTING/gate semantics.
- [Why]: Because ROUTING and ESCALATED are coupled, omission in the escalation design is brittle: a future implementer could accidentally reset budget on reroute and remain “consistent” with Document 2 alone.
- [Fix]: Add an explicit invariant in Document 2: “Gate outputs never modify retry budget; rerouting preserves contract-level iteration counters from TV2-017.”

- [F13]
- [Severity]: SIGNIFICANT
- [Finding]: The claimed “first-instance” behavior is ambiguous and likely contradictory for unknown classes. Document 2 says Gate 1 routes unknown classes to Tier 3 and Gate 3 first-instance also escalates to Tier 3. But `action_class_history_count: 0` depends on an action class identity that Gate 1 could not classify.
- [Why]: For unknowns, “first-instance” may be uncomputable or meaningless unless there is a stable normalized candidate class key. This weakens the claimed deterministic nature of Gate 3.
- [Fix]: Define first-instance against a normalized task-class fingerprint or only apply it to known action classes newly added to the routing table. State how unknown tasks are keyed in history.

- [F14]
- [Severity]: SIGNIFICANT
- [Finding]: Document 2 says Gate 4 is “advisory,” but its trigger table says tier promotion is automatic. Document 1 similarly says routing table is “self-tuning” and updates automatically. Yet Document 2 also says reclassification includes Danny review in some areas and manual demotion only.
- [Why]: “Advisory” versus “automatic mutation of routing table” are not the same. This affects safety, auditability, and rollout control.
- [Fix]: Clarify that Gate 4 is either  
  - advisory with human approval before table change, or  
  - automatic for upward reclassification only.  
  Use the same language in both docs.

- [F15]
- [Severity]: SIGNIFICANT
- [Finding]: Silent stagnation handling is weak. The state machine includes queue max-age and retry budgets, but there is no execution-time watchdog for contracts stuck in `DISPATCHED`, `EXECUTING`, `STAGED`, or `QUALITY_EVAL` due to crashed workers or hung evaluators.
- [Why]: Silent stagnation is one of the named failure modes. Current design handles repeated failed iterations, not no-progress states.
- [Fix]: Add per-state SLA/timeouts and recovery transitions, e.g. `DISPATCHED -> ESCALATED/DEAD_LETTER` on ack timeout, `EXECUTING` heartbeat timeout, `STAGED/QUALITY_EVAL` evaluation timeout with retry or operator alert.

- [F16]
- [Severity]: SIGNIFICANT
- [Finding]: Bad-spec infinite loop is only handled by prose (“executor escalates” and Tess creates a new contract), not by explicit guards or transitions in the state machine.
- [Why]: This failure mode is important because contract immutability blocks in-place repair. Without explicit detection criteria and transition semantics, implementations may just burn retries and dead-letter.
- [Fix]: Add a formal path: `EXECUTING -> ESCALATED` or `DEAD_LETTER` on `failure_class: bad_spec`, with orchestrator action `create superseding contract` and old contract `-> ABANDONED`.

- [F17]
- [Severity]: SIGNIFICANT
- [Finding]: Observability feedback-loop failure mode is not directly addressed. The docs log heavily and use Gate 4 for self-tuning, but they do not specify protections against metrics contamination, duplicate events after crash recovery, or the routing table chasing noisy observability artifacts.
- [Why]: If convergence stats double-count resumed promotions/escalations or include mixed per-attempt/per-contract semantics, Gate 4 can induce false reclassification.
- [Fix]: Define idempotent event keys, source-of-truth metrics derivation, and whether convergence is attempt-based or contract-based. Add debouncing/hysteresis for Gate 4 beyond a single rolling threshold.

- [F18]
- [Severity]: SIGNIFICANT
- [Finding]: Credential expiry cascade is only partially covered. Scenario 2 shows a single failed refresh dead-lettering, but there is no system-level mitigation for repeated downstream contracts depending on expired credentials.
- [Why]: The spec explicitly names credential expiry cascade. Without dependency-aware suppression, many contracts can fail repeatedly and flood dead-letter/escalation paths.
- [Fix]: Add credential-health state or circuit breaker: after credential-refresh failure, mark dependent action classes unavailable/deferred until credential restored, and surface one consolidated alert.

- [F19]
- [Severity]: SIGNIFICANT
- [Finding]: Queue poisoning mitigation does not address malformed or adversarial contracts beyond age and fairness. There is no explicit pre-queue schema validation state or quarantine path.
- [Why]: A poisoned queue can also consist of invalid contracts that repeatedly fail routing or execution. Age-based dead-lettering is too late.
- [Fix]: Add intake validation before QUEUED, or a `REJECTED`/`INVALID` terminal state for schema/tool/policy-invalid contracts.

- [F20]
- [Severity]: SIGNIFICANT
- [Finding]: The state machine’s routing boundary may allow tasks to bypass Gate 2 entirely for all V1 exact-match Tier 1 tasks by design, including some tasks where executor uncertainty would still be useful.
- [Why]: This is not inherently wrong, but it weakens the claim of a “four-gate system” because a large class of tasks effectively sees Gate 1 + Gate 3 only. If this is intended, it should be framed as conditional gates rather than universal traversal.
- [Fix]: Clarify that Gate 2 is conditional/optional and update diagrams/test language to “up to four checks” rather than implying all tasks traverse all gates.

- [F21]
- [Severity]: SIGNIFICANT
- [Finding]: The scenario walkthroughs do not fully exercise the edge cases they claim to cover. In Document 1, Scenario A is labeled “Mid-Loop Escalation” but the main path never escalates; escalation is only an alternate branch. In Document 2, Scenario 2 claims credential-touching coverage but starts already at Tier 3 via Gate 1, so it does not demonstrate Gate 3 overriding a lower-tier decision.
- [Why]: Core architectural claims are insufficiently validated by the examples, reducing confidence that the edge cases were actually reasoned through.
- [Fix]: Rewrite scenarios so the primary path exercises the intended edge:  
  - Doc 1 Scenario A should actually transition `EXECUTING -> ESCALATED -> ROUTING`.  
  - Doc 2 Scenario 2 should begin as a known Tier 1/2 task that Gate 3 deterministically overrides.

- [F22]
- [Severity]: SIGNIFICANT
- [Finding]: Important scenarios are missing across the pair: approval-required destructive task before/after execution, executor ack timeout, evaluator crash during QUALITY_EVAL, lock timeout second failure leading to QUALITY_FAILED, repeated unknown-class storm, and dependent-contract suppression after credential failure.
- [Why]: These are exactly the brittle coupling points between lifecycle and routing/policy.
- [Fix]: Add at least 4 new end-to-end scenarios spanning both docs: approval flow, lock-timeout flow, stagnation/heartbeat failure, and credential-cascade circuit breaker.

- [F23]
- [Severity]: SIGNIFICANT
- [Finding]: Feasibility of path-level locking with directory locks is underspecified for overlapping paths. Example: one contract locks `Projects/foo/design/`, another locks `Projects/foo/design/spec.md`. Conflict detection rules are not defined.
- [Why]: Promotion race prevention depends on a precise lock overlap algorithm. Without ancestor/descendant conflict semantics, collisions can slip through.
- [Fix]: Specify canonical path normalization and overlap rule: lock acquisition fails if any existing lock path is an ancestor or descendant of any requested path.

- [F24]
- [Severity]: SIGNIFICANT
- [Finding]: The write-lock table stored in a YAML file may not be safe under concurrent multi-process updates without an external file lock or atomic rename protocol.
- [Why]: A lock table that itself races undermines the promotion-race defense.
- [Fix]: Specify implementation-level lock management: OS file lock around lock-table mutation, append-only journal + atomic rename, or SQLite.

- [F25]
- [Severity]: SIGNIFICANT
- [Finding]: The rolling window of 20 contracts for convergence tracking is likely too small for sparse or highly variable action classes, especially when p95 and quality thresholds drive automatic tier upgrades.
- [Why]: For a 14-service workload, some classes may see low volume, making p95 unstable and susceptible to overreaction. This increases the risk of escalation storms or unnecessary cost increases.
- [Fix]: Use minimum-sample gating and hysteresis, e.g. require at least 20 completed contracts for high-volume classes and 10 with Bayesian smoothing for low-volume classes, plus two consecutive windows before reclassification.

- [F26]
- [Severity]: MINOR
- [Finding]: Document 1 references “two-tier architecture” in Scenario A while elsewhere both documents clearly use Tier 1 and Tier 3 and discuss Tier 1-2 in Gate 2 scope.
- [Why]: This is confusing terminology and may reflect an outdated assumption.
- [Fix]: Standardize tier vocabulary: either “currently deployed tiers are 1 and 3” or define whether Tier 2 exists conceptually but is unimplemented.

- [F27]
- [Severity]: MINOR
- [Finding]: Document 1 says “Hash verification timing: At promotion time, not at lock acquisition,” but the protocol text also says hashes are recorded at QUALITY_EVAL time and re-checked at PROMOTING time.
- [Why]: The summary wording is sloppy and can be misread.
- [Fix]: Rephrase to “Record hashes at QUALITY_EVAL; verify again after lock acquisition at PROMOTING.”

- [F28]
- [Severity]: MINOR
- [Finding]: The owner of ROUTING is listed as “Orchestrator (Tess/Kimi)” in Document 1, but Kimi is also described elsewhere as an executor tier, not the orchestrator.
- [Why]: Blurs evaluator-executor separation and component boundaries.
- [Fix]: Make ROUTING owner a single control-plane component, e.g. “Tess orchestrator,” and reserve Kimi/Nemotron/Claude Code for execution/evaluation roles explicitly.

- [F29]
- [Severity]: MINOR
- [Finding]: Document 2 title says “Three-Gate Hybrid Design” while the content describes four gates.
- [Why]: Avoidable confusion at the document’s front door.
- [Fix]: Rename the title to “Four-Gate Hybrid Design” or “Three Gates + One Feedback Reclassification Layer,” depending on the resolved architecture.

- [F30]
- [Severity]: STRENGTH
- [Finding]: Document 1 strongly reflects AD-008 and AD-006 by making staging/promotion explicit, keeping executors out of canonical writes, and using deterministic termination checks before quality evaluation.
- [Why]: This is the right architectural skeleton for mechanical enforcement over behavioral compliance.
- [Fix]: None.

- [F31]
- [Severity]: STRENGTH
- [Finding]: The separation between `iteration_checking` and `QUALITY_EVAL` is well designed. Structural/termination verification is mechanical, while qualitative promotion is evaluated later by Tess.
- [Why]: This cleanly supports AD-007 evaluator-executor separation and avoids letting the executor self-certify completion quality.
- [Fix]: None.

- [F32]
- [Severity]: STRENGTH
- [Finding]: Contract immutability after DISPATCHED, plus “amendment = new contract,” is a strong guardrail against drift and hidden instruction mutation.
- [Why]: It directly addresses silent contract drift and makes audit history reliable.
- [Fix]: None.

- [F33]
- [Severity]: STRENGTH
- [Finding]: Gate 3’s deterministic policy-table design is a good fit for AD-009. The rule examples are concrete, auditable, and testable independently of model behavior.
- [Why]: This is exactly the kind of mechanical override needed for credentials, destructive operations, and external comms.
- [Fix]: None.

- [F34]
- [Severity]: STRENGTH
- [Finding]: The docs correctly frame confidence as non-safety-critical. Scenario 1 in Document 2 explicitly says safety comes from contract checks and evaluator separation, not self-reported confidence.
- [Why]: This is an important and sound architectural stance.
- [Fix]: None.

- [F35]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “TV2-013 orchestration tests (Nemotron orch-06: 3/5 on confidence threshold)” is cited without enough context to independently verify.
- [Why]: The review cannot validate this benchmark or its implications for calibration design.
- [Fix]: Add a traceable artifact reference: repository path, test report ID, or attached result summary.

- [F36]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: “Cloud eval results: Kimi 0 fabrication, Nemotron 0/3 guardrails” is cited without source, dataset, or report location.
- [Why]: This claim materially supports routing/escalation assumptions but cannot be checked from the documents.
- [Fix]: Cite the evaluation artifact, date, test corpus, and exact metric definition.

- [F37]
- [Severity]: SIGNIFICANT
- [Finding]: UNVERIFIABLE CLAIM: References to “C9 Write-lock table,” “Amendment T/U/W/X,” and sections like “§7,” “§8,” “§9.2,” “§9.4” are not independently verifiable from the provided artifact set.
- [Why]: These cross-references may be valid internally, but a reviewer cannot confirm them here.
- [Fix]: Provide stable doc links/IDs or include a short appendix listing referenced controlling documents and versions.

---

## Google (gemini-3.1-pro-preview)

Here is the review of the tightly coupled Tess v2 architecture documents (TV2-017 and TV2-018), evaluated against your requested criteria.

### 🔴 CRITICAL FINDINGS

**[F1]**
- **Severity**: CRITICAL
- **Finding**: High-risk, irreversible external tools execute *before* human approval occurs.
- **Why**: Document 1 handles the Gate 3 `requires_human_approval` flag by bypassing the PROMOTING state and sending the contract to DEAD_LETTER (to await approval) *after* the EXECUTING and STAGED states. However, the staging environment only protects Vault files. If a task uses tools like `send_email`, `send_telegram`, or `git_reset` (flagged by Gate 3 in Document 2), those actions are executed directly by the LLM during the `iteration_working` sub-state of EXECUTING. By the time the contract reaches the human approval gate post-staging, the destructive action or external communication has already happened.
- **Fix**: The state machine must evaluate `requires_human_approval` *before* the DISPATCHED state. Introduce a `PENDING_APPROVAL` state between ROUTING and DISPATCHED, or enforce a strict "dry-run/draft" mode at the tooling layer that the runner intercepts and halts until approval is granted.

**[F2]**
- **Severity**: CRITICAL
- **Finding**: Missing state transitions and recovery paths for Human Approval.
- **Why**: The Document 1 state diagram shows a dashed line indicating `requires_human_approval` contracts go to `DEAD_LETTER (Danny must approve)`. However, there is no logic in the Transition Table (Section 5) defining *when* this happens (e.g., does it transition from QUALITY_EVAL or STAGED?). Furthermore, `DEAD_LETTER` is defined as a terminal sink. There is no state transition showing how an approved contract moves from `DEAD_LETTER` to `PROMOTING` or `COMPLETED`. Once a contract goes to DEAD_LETTER for approval, it is logically trapped.
- **Fix**: Create a dedicated `PENDING_APPROVAL` state (separate from `DEAD_LETTER`). Add explicit transitions in the table: `QUALITY_EVAL -> PENDING_APPROVAL` (if flag is true), `PENDING_APPROVAL -> PROMOTING` (on human approval), and `PENDING_APPROVAL -> ABANDONED` (on human rejection).

### 🟠 SIGNIFICANT FINDINGS

**[F3]**
- **Severity**: SIGNIFICANT
- **Finding**: UNVERIFIABLE CLAIM: External test statistics and cloud evaluation results.
- **Why**: Document 2 (§1) references specific empirical metrics: "TV2-013 orchestration tests (Nemotron orch-06: 3/5 on confidence threshold)" and "Cloud eval results: Kimi 0 fabrication, Nemotron 0/3 guardrails." These are factual performance statistics with attributed sources that cannot be independently verified from the provided text.
- **Fix**: Provide the data sets, raw evaluation logs, or hyperlink the specific testing artifacts (e.g., `orch-06` output) so the baseline claims justifying Gate 2's existence can be audited.

**[F4]**
- **Severity**: SIGNIFICANT
- **Finding**: Contradiction regarding the number of execution tiers.
- **Why**: The two documents disagree on the fundamental executor architecture. Document 1 states explicitly in Scenario A: "Nemotron is Tier 1, Kimi is Tier 3 (no Tier 2 in two-tier architecture)." However, Document 2 repeatedly relies on a three-tier model, stating "Gate 1 assigned Tier 1 or Tier 2" and noting that Gate 2 fires for "Tier 1-2 orchestration responses."
- **Fix**: Align both documents to a single topology. If Tier 2 exists, define what it is in the Routing Table (Doc 2). If it does not, remove all Tier 2 references from Gate 2 logic.

**[F5]**
- **Severity**: SIGNIFICANT
- **Finding**: Hidden LLM latency and failure modes within the ROUTING state.
- **Why**: Document 1 models ROUTING as a simple transition state owned by the Orchestrator to check gates. However, Document 2 reveals that Gate 2 requires a live LLM call to Nemotron to generate the `orchestration_response` and confidence field. This means ROUTING is not instantaneous—it introduces inference latency, potential context-window limits, prompt-parsing failures, and timeout risks before the task is even queued for execution.
- **Fix**: Document 1 must acknowledge that ROUTING involves an active Orchestrator LLM execution. Add sub-states to ROUTING (e.g., `routing_evaluating`, `routing_parsing`) to handle orchestrator-level timeouts and retries, independent of the EXECUTING Ralph loop.

### 🟡 MINOR FINDINGS

**[F6]**
- **Severity**: MINOR
- **Finding**: Inconsistent state trajectory for retry budget exhaustion.
- **Why**: Document 1 (§6) states that if `iterations_remaining == 0`, the contract transitions directly to `DEAD_LETTER`. Document 2 (Scenario 2) states that if all retries fail, it goes to `ESCALATED → but already at max tier → DEAD_LETTER`. This creates ambiguity about whether an exhausted budget triggers the ESCALATED routing logic before failing out.
- **Fix**: Update Document 2 to match Document 1: if the budget is exhausted at the max tier, the state bypasses ESCALATED and transitions directly to `DEAD_LETTER`.

**[F7]**
- **Severity**: MINOR
- **Finding**: Reclassification demotions lack mechanical tracking.
- **Why**: Document 2 (§6) specifies that Tier upgrades via Gate 4 are automatic, but demotions are manual. However, there is no state-machine mechanic in Document 1 to flag contracts or action classes for "demotion review." If Danny must manually approve demotions, the system needs an observability hook to proactively notify him when an action class qualifies (`avg_iterations < 1.5` AND `quality_pass_rate > 0.95`).
- **Fix**: Add a transition or logging action in the `COMPLETED` state that specifically emits a `demotion_candidate_detected` event to the observability ledger when Gate 4 thresholds are met.

### 🟢 STRENGTHS

**[S1]**
- **Severity**: STRENGTH
- **Finding**: Robust Promotion Collision and Crash Recovery handling.
- **Why**: The combination of the C9 path-level write-locks, hash verification, and manifest-based atomic promotion in Document 1 (§7) is exceptionally well-designed. By verifying the canonical hash *at the time of promotion* rather than at lock acquisition, it completely eliminates the "silent contract drift" and "promotion race" failure modes in a crash-safe way.

**[S2]**
- **Severity**: STRENGTH
- **Finding**: Strict Evaluator-Executor Boundary Enforcement.
- **Why**: Document 2 elegantly fulfills AD-007 by severely restricting the LLM's influence over its own routing. Using the LLM's self-assessed confidence (Gate 2) solely as a speed optimization—while backing it up with deterministic Gate 1 boundary checks, Gate 3 risk overrides, and mechanical Ralph loop termination—ensures the model cannot bypass safety rules through confidently hallucinated outputs (as demonstrated clearly in Doc 2, Scenario 1).

---

## DeepSeek (deepseek-reasoner)

**Findings Review: Tess v2 Contract Lifecycle & Escalation Design Documents**

**F1**
- **Severity:** CRITICAL
- **Finding:** Contradiction in number of escalation gates. Document 1 (state machine) references "Three-Gate Escalation" in Section 1 and §7, yet incorporates a "Gate 4" (convergence rate) in Sections 6, 9, and the state diagram. Document 2 explicitly defines four gates.
- **Why:** Creates fundamental ambiguity about the routing logic boundary between documents. Implementation teams could build conflicting systems.
- **Fix:** Align terminology. Update Document 1's references from "Three-Gate" to "Four-Gate" escalation and ensure all sections (1, 7, diagram labels) are consistent.

**F2**
- **Severity:** CRITICAL
- **Finding:** Missing critical state transition from QUEUED to DEAD_LETTER. The state diagram and transition table show QUEUED only transitioning to ROUTING, but Section 11 (Queue Management) describes contracts timing out in QUEUED and moving to DEAD_LETTER via max-age policy.
- **Why:** State machine is incomplete. A contract could be stuck forever if the scheduler never picks it up and the timeout logic isn't modeled as a transition.
- **Fix:** Add a direct transition: `QUEUED → DEAD_LETTER` with trigger `max_queue_age exceeded` and guard `priority != critical`.

**F3**
- **Severity:** CRITICAL
- **Finding:** Contradiction in escalation budget handling. Document 1, Section 3 states: "Escalation does NOT reset the budget." Document 2, Scenario 1 walkthrough states: "If Nemotron hallucinates again → iteration 3 → if still wrong → ESCALATED to Tier 3 (Kimi)." This implies the budget is exhausted (3 iterations used) before escalation, leaving Kimi with 0 iterations. However, Document 1 states budget carries forward.
- **Why:** Creates an impossible execution scenario. If the budget is exhausted (0 remaining), escalation to a higher tier is meaningless as no iterations remain for the new executor to attempt work.
- **Fix:** Clarify the interaction. Specify that upon escalation, the remaining iteration budget transfers, but the escalation event itself may consume a budget unit (e.g., as a "routing iteration"). Or, amend the walkthrough to show escalation occurring when budget remains (e.g., after 2 failed iterations).

**F4**
- **Severity:** CRITICAL
- **Finding:** Missing feedback loop from DEAD_LETTER and ABANDONED states to convergence tracking (Gate 4). Document 1, Section 9 states COMPLETED and ESCALATED update the tracker, but DEAD_LETTER is also listed in the diagram. Document 2, Section 6 says "after every contract reaches a terminal state (COMPLETED, DEAD_LETTER, ABANDONED)" the tracker updates.
- **Why:** Gate 4's reclassification logic will be inaccurate if it doesn't account for contracts that completely fail (DEAD_LETTER) or are cancelled (ABANDONED). This skews escalation_rate and quality_pass_rate stats.
- **Fix:** Update Document 1, Section 9 to explicitly include DEAD_LETTER and ABANDONED as terminal states that feed the convergence tracker.

**F5**
- **Severity:** SIGNIFICANT
- **Finding:** Unclear ownership and triggering of Gate 4. Document 2 describes Gate 4 as both a per-task "advisory signal" in the routing sequence (Section 2 diagram) and a longitudinal, background process that updates the routing table (Section 6). Document 1 shows it as a feedback loop from terminal states, not as a gate in the ROUTING state.
- **Why:** The coupling between documents is brittle. Is Gate 4 a step in the ROUTING decision for each contract, or a periodic batch process? The designs assume different models.
- **Fix:** Define Gate 4 unambiguously as a background monitoring process (as in Document 1, Section 9). Remove it from the sequential gate diagram in Document 2, Section 2. Update Document 2 to state that routing table updates from Gate 4 affect *future* contracts, not the current one.

**F6**
- **Severity:** SIGNIFICANT
- **Finding:** Scenario walkthroughs do not fully test "bad-spec infinite loop" failure mode. Both documents' walkthroughs show contracts failing and escalating, but none demonstrate the immutability rule triggering creation of a *new* contract (Document 1, Section 8, Rule 3). The "bad-spec" loop is a case where the contract's own instructions are defective.
- **Why:** A core mitigation for a known failure mode is not validated. The system could spin indefinitely on a defective contract.
- **Fix:** Add a walkthrough scenario where an executor detects a fundamentally flawed/unachievable contract spec, forces escalation to DEAD_LETTER, and triggers Tess to create a new, amended contract (with new ID) that supersedes the old one.

**F7**
- **Severity:** SIGNIFICANT
- **Finding:** "Observability feedback loop" failure mode is not addressed. The designs add extensive logging (ledger, convergence tracking) but do not specify safeguards to prevent the system's own logs/artifacts from being fed back as context in a way that causes obsessive self-reference or data pollution.
- **Why:** As the system runs, its vault will fill with its own operational artifacts. Without rules, contracts could trigger analysis or actions based on this self-generated content, creating a feedback loop.
- **Fix:** Add a design rule, likely in the contract schema or context-building step, to exclude or tag system-generated paths (e.g., `_staging/`, `~/.tess/`, ledger files) from being included as context for general contracts, or to require Tier 3+ for any contract targeting those paths.

**F8**
- **Severity:** SIGNIFICANT
- **Finding:** Promotion hash verification is vulnerable to a race condition. Document 1, Section 7: Hash is recorded at QUALITY_EVAL time and re-checked at PROMOTING time. However, a malicious or buggy process could modify the canonical file *after* the hash check at PROMOTING time but *before* the file copy operation, bypassing detection.
- **Why:** The time-of-check to time-of-use (TOCTOU) window, though small, exists. For a critical system enforcing vault integrity, this is a risk.
- **Fix:** Implement an atomic compare-and-swap operation if supported by the filesystem, or use file locking on the canonical file for the entire duration of the copy. Alternatively, copy to a temporary location, then atomically rename (mv) over the canonical file, which is typically atomic at the filesystem level.

**F9**
- **Severity:** SIGNIFICANT
- **UNVERIFIABLE CLAIM:** "TV2-013 orchestration tests (Nemotron orch-06: 3/5 on confidence threshold)" and "Cloud eval results: Kimi 0 fabrication, Nemotron 0/3 guardrails" are cited as design inputs without accessible source data.
- **Why:** These specific test results are used to justify the confidence field design and tier assignments. Their validity cannot be assessed.
- **Fix:** Design should be robust even if these exact numbers shift. Consider adding a note that the design accommodates calibration.

**F10**
- **Severity:** SIGNIFICANT
- **Finding:** Routing table structure may not scale for a "14-service workload." Document 2's routing table examples are simplistic (7 action classes). With 14 services, each with multiple action types, the table could become large and require complex pattern-matching logic (e.g., target path patterns) that is error-prone.
- **Why:** Gate 1's "deterministic boundary check" could become a source of misrouting if the matching logic is too simple, or a maintenance burden if too complex.
- **Fix:** Propose a hierarchical routing table structure (service -> action type) and invest in the design of a robust, regex/glob-based pattern matcher for target paths. Consider a linter/test suite for the routing table YAML.

**F11**
- **Severity:** MINOR
- **Finding:** State diagram uses "PROMOTION_PENDING" state, but state definitions and transition table only list "PROMOTING". This is a visual inconsistency.
- **Why:** Could cause confusion during implementation.
- **Fix:** Update the diagram to use the defined state name "PROMOTING" consistently.

**F12**
- **Severity:** MINOR
- **Finding:** Document 2, Section 4 states Gate 2 is skipped for "Deterministic tasks with V1 verifiability and `match_confidence: exact`". However, the routing table in Section 3 assigns `verifiability: V1` to `shell-execute` and `vault-write`, but also `structured-report` as V2. The logic for when to skip is clear, but the example classes could be better aligned.
- **Why:** Minor clarity issue.
- **Fix:** Add a footnote or example clarifying which example action classes would typically skip Gate 2.

**F13**
- **Severity:** STRENGTH
- **Finding:** The staging → promotion write model (AD-008) is well-elaborated with a manifest-based, crash-safe procedure and hash verification. It effectively addresses the "promotion race" failure mode.
- **Why:** Provides clear implementation guidance and handles concurrent modifications and system crashes.

**F14**
- **Severity:** STRENGTH
- **Finding:** The separation of concerns between the state machine (Document 1) and the escalation logic (Document 2) is generally clean at the ROUTING state boundary. The state machine defines *when* routing happens, the escalation design defines *how*.
- **Why:** Good modular architecture that allows the escalation rules (gates) to be modified independently of the overall contract lifecycle.

**F15**
- **Severity:** STRENGTH
- **Finding:** The designs comprehensively address most specified failure modes: escalation storm (rate limiting), queue poisoning (max-age), credential expiry cascade (dead-letter path), silent stagnation (queue priorities and timeouts), and promotion race (write-locks).
- **Why:** Shows thorough consideration of operational robustness.

---
**Summary of Critical Issues:**
The most severe issues involve contradictions between the documents on the core number of gates (F1) and the handling of the retry budget during escalation (F3), along with a missing state transition for queue timeouts (F2). These must be resolved for a coherent implementation. The coupling around Gate 4's role (F5) is also significant. The unaddressed observability feedback loop (F7) and the TOCTOU race condition in promotion (F8) are notable design risks.

---

## Grok (grok-4-1-fast-reasoning)

- [F1]  
  [Severity]: CRITICAL  
  [Finding]: Documents disagree on number of execution tiers: Doc1 explicitly assumes a "two-tier architecture" (Tier 1 Nemotron, Tier 3 Kimi/Claude, no Tier 2; see Scenario A), while Doc2 defines Tier 1, Tier 2, and Tier 3 in Gate logic, routing table examples, and Gate 2 scope ("Tier 1 or Tier 2").  
  [Why]: Breaks ROUTING state consistency; re-entry from ESCALATED assumes higher tiers exist predictably, but tier gaps lead to unreachable states (e.g., escalate from Tier 1 → ? Tier 2 undefined → DEAD_LETTER prematurely). Violates AD-006 mechanical enforcement.  
  [Fix]: Standardize on explicit tiers in both docs (e.g., Tier 1: Nemotron local, Tier 2: Claude Code local/cloud hybrid?, Tier 3: Kimi cloud); add tier diagram.

- [F2]  
  [Severity]: CRITICAL  
  [Finding]: Inconsistent gate count and scope: Doc1 defines ROUTING as "Gate 1-3 check" (§1, §6, transitions), with Gate 4 as post-terminal feedback loop (§9); Doc2 defines four sequential gates all within ROUTING, with Gate 4 firing per-task ("advisory signal — it upgrades the tier"). State diagram in Doc1 shows only Gates 1-3 in ROUTING.  
  [Why]: ROUTING state boundary mismatch creates impossible transitions (e.g., Doc2 Gate 4 reclassifies mid-ROUTING, but Doc1 treats it post-COMPLETED); potential bypass if Gate 4 not invoked on escalation re-ROUTING.  
  [Fix]: Harmonize: Move Gate 4 fully to post-terminal in both, or make explicit per-task in ROUTING with re-entrant logic.

- [F3]  
  [Severity]: CRITICAL  
  [Finding]: Human approval handling contradictory: Doc1 state diagram shows "requires_human_approval" from ROUTING directly to DEAD_LETTER (bypassing execution); transitions table lacks this trigger (only "no viable executor"); Doc2 Gate 3 BLOCK routes to Tier 3 + flag, then execution → DEAD_LETTER if flagged (INT-02). Doc1 §6 says Gate 3 → Tier 3 + flag, but diagram bypasses.  
  [Why]: Unclear if risky tasks execute at all; violates AD-009 (risk always escalates, but to execution or block?). Creates unreachable states (e.g., Tier 3 execution for human-blocked tasks).  
  [Fix]: Clarify in both: requires_human_approval sets flag → routes to Tier 3 execution only if auto-allowed, else direct DEAD_LETTER from ROUTING; add transition.

- [F4]  
  [Severity]: CRITICAL  
  [Finding]: Missing handling for escalation re-entry through gates: Doc1 §6 says ESCALATED → ROUTING "at higher tier" with escalation context; Doc2 gates are initial-task only (no mention of re-routing inputs like failure_context); Gate 2 assumes fresh Nemotron orchestration response.  
  [Why]: Re-ROUTING bypasses gates (especially Gate 3 risk, which should re-fire); risks de-escalation or infinite loop on reasoning failures. Silent stagnation if gates don't preserve tier min.  
  [Fix]: Doc2 add "escalation override" input to gates (e.g., min_tier from prior); Doc1 transition guard: "gates re-run with source_tier floor".

- [F5]  
  [Severity]: SIGNIFICANT  
  [Finding]: Unreachable states: PROMOTION_PENDING mentioned only in Doc1 scenario diagram (not in state table); "wait state" for lock contention in Scenario C (not defined); QUALITY_FAILED → PROMOTING for partial only if "passing artifacts identified" (vague trigger).  
  [Why]: State machine incomplete; promotion races unhandled systematically, risking promotion race failure mode.  
  [Fix]: Add states/sub-states to table (e.g., PROMOTION_PENDING as PROMOTING sub-state); define lock-wait as timed loop → QUALITY_FAILED.

- [F6]  
  [Severity]: SIGNIFICANT  
  [Finding]: Retry budget handling inconsistent: Doc1 says "escalation does NOT consume an iteration" and "budget carries forward"; Scenario A alternate shows "remaining budget (1 iteration, since escalation doesn't consume)" after 2 fails → 1 left at Tier 3. But if Tier 3 exhausts 1 → DEAD_LETTER, no further escalation. Doc2 silent.  
  [Why]: Per-contract budget prevents cross-tier retries, but unclear if budget resets/escalates properly; risks premature DEAD_LETTER on multi-tier needs.  
  [Fix]: Explicitly define: budget global, escalation preserves remaining; add max_escalations=2 guard.

- [F7]  
  [Severity]: SIGNIFICANT  
  [Finding]: UNVERIFIABLE CLAIM: Doc2 §1 cites "TV2-013 orchestration tests (Nemotron orch-06: 3/5 on confidence threshold)", "Cloud eval results: Kimi 0 fabrication, Nemotron 0/3 guardrails" — no sources/links provided.  
  [Why]: Undermines Gate 2 calibration rationale; if false, justifies weak confidence field.  
  [Fix]: Add links or remove specifics; flag as assumption.

- [F8]  
  [Severity]: SIGNIFICANT  
  [Finding]: Failure modes incompletely addressed: Observability feedback loop (§2.4) unmentioned; credential expiry cascade partially in Doc2 Scenario 2 but no prevention (e.g., proactive refresh); silent contract drift risks in staging→promotion without full diff checks. 8 modes listed, but only ~5 explicitly handled.  
  [Why]: Gaps expose system (e.g., ledger poisoning affects Gate 4); violates completeness.  
  [Fix]: Add sections mapping all 8 modes to mitigations; e.g., observability via isolated ledger reader.

- [F9]  
  [Severity]: SIGNIFICANT  
  [Finding]: Scenarios don't fully exercise edges: Doc1 A covers mid-escalation but not budget_exhausted at Tier 3; B promotion crash but not concurrent crash+change; C concurrent but not multi-contract partial. Doc2 Scenario 1 confidently-wrong caught by runner (good), but no Gate 4 trigger demo. No joint scenario for re-ROUTING.  
  [Why]: Claims "exercise edge cases" false; misses promotion race, storm during re-routing.  
  [Fix]: Add cross-doc Scenario D: escalation storm → load shedding → re-route.

- [F10]  
  [Severity]: SIGNIFICANT  
  [Finding]: Convergence window (20 contracts) too small for 14-service workload: p95 threshold=5, escalation_rate>0.30 triggers reclass; Doc1 §13 says "large enough for signal". But low-volume classes (e.g., 1/week) → noisy stats, oscillation.  
  [Why]: Gate 4 unreliable; violates AD-010 route by verifiability (stats override). Feasibility risk.  
  [Fix]: Tiered windows (min 50 total, or 10/class); add volume guard.

- [F11]  
  [Severity]: SIGNIFICANT  
  [Finding]: Coupling risk at ROUTING: Doc1 changes (e.g., add gates) break Doc2 consumption; brittle assumptions like "gates feed ROUTING" but no schema for gate output (Doc1 lacks gate_result format).  
  [Why]: One doc update → other fails silently (e.g., human_approval flag undefined).  
  [Fix]: Shared schema artifact TV2-018a: gate_output.yaml; versioned interface.

- [F12]  
  [Severity]: MINOR  
  [Finding]: Routing table lacks structure for 14 services: Doc2 examples cover ~8 classes, but "14-service workload" (context); no pattern for service-specific (e.g., tess-v2 vs crumb-core). Ambiguous match → highest tier risky.  
  [Why]: Scalability gap; feasibility for real use.  
  [Fix]: Add hierarchy (service→class→tier); fuzzy match scoring.

- [F13]  
  [Severity]: MINOR  
  [Finding]: Promotion feasibility gap: Manifest crash recovery assumes single-node (no distributed locks); hash verification directory-level vague (listing hash?). Lock table YAML not atomic.  
  [Why]: Multi-process race in ~/.tess/; violates AD-008 staging→promotion.  
  [Fix]: Use file-locks (flock) + atomic YAML (temp→rename); define dir-hash spec.

- [F14]  
  [Severity]: STRENGTH  
  [Finding]: Promotion mechanics (manifest-based, hash verification, partial promotion) detailed and crash-safe with resume/rollback.  
  [Why]: Addresses promotion race, silent drift; mechanical (AD-006), evaluator separation (AD-007); scenarios verify edges like crash mid-op, concurrent locks. Edge: multi-crash still idempotent via status checks.  
  [Fix]: N/A

- [F15]  
  [Severity]: STRENGTH  
  [Finding]: Escalation storm protection in Doc1 §6 (alert, load shed by priority, recovery hysteresis) + circuit breaker in queue mgmt.  
  [Why]: Directly mitigates named failure mode; policy-level decoupling from state machine. No obvious break (priorities prevent high-prio starvation).  
  [Fix]: N/A

- [F16]  
  [Severity]: STRENGTH  
  [Finding]: Contract immutability rules (§8 Doc1) + failure context injection enforce AD-006 (mechanical over behavioral); bad-spec handled by new contract supersede.  
  [Why]: Prevents infinite loops, drift; staging scoped avoids poisoning. Edge: schema_version guards runner.  
  [Fix]: N/A

---

## Synthesis

### Consensus Findings

**1. Gate count and Gate 4 role (CRITICAL — 4 reviewers: OAI-F1, DS-F1, GRK-F2, OAI-F14, DS-F5)**
Doc1 says "three-gate escalation" throughout. Doc2 defines four gates. Gate 4's nature is ambiguous: Doc1 treats it as a post-terminal feedback loop, Doc2 places it in the sequential routing path. All four reviewers flagged this as the primary inter-document contradiction.

**2. Human approval semantics (CRITICAL — 3 reviewers: OAI-F6, GEM-F1, GEM-F2, GRK-F3)**
Safety-critical finding. For tasks requiring human approval (destructive ops, external comms), the design is contradictory about whether the executor runs BEFORE or AFTER approval. Doc1's diagram routes `requires_human_approval` directly to DEAD_LETTER (bypassing execution). Doc2's Gate 3 sets the flag but routes to Tier 3 for execution. GEM-F1 correctly notes that side-effecting tools (send_email, send_telegram) execute during `iteration_working` — by the time the contract reaches approval, the action has already happened. DEAD_LETTER is also terminal with no transition back to PROMOTING, trapping approved contracts.

**3. Tier vocabulary inconsistency (CRITICAL — 3 reviewers: GEM-F4, GRK-F1, OAI-F26)**
Doc1 says "two-tier architecture (no Tier 2)." Doc2 references "Tier 1-2" in Gate 2 scope, routing table, and examples. The production architecture has Tier 1 (Nemotron) and Tier 3 (Kimi) with no Tier 2 deployed.

**4. Retry budget + Scenario A contradiction (CRITICAL — 3 reviewers: DS-F3, GRK-F6, OAI-F12)**
Scenario A's main path exhausts all 3 iterations, then quality fails. The alternate escalation path says "remaining budget (1 iteration)" — but the alternate branches from iteration 2, not from the exhausted main path. DS-F3 correctly identifies that escalation with 0 remaining iterations is meaningless. Budget invariant also missing from Doc2.

**5. Gate 2 pre-routing causal loop (CRITICAL — 2 reviewers: OAI-F4, GEM-F5)**
Gate 2 requires the executor's confidence response, but ROUTING runs before dispatch to the executor. This is a causal loop: can't ask Nemotron for confidence before deciding to route to Nemotron.

**6. PROMOTION_PENDING undeclared + lock-wait missing (SIGNIFICANT — 3 reviewers: OAI-F2, OAI-F3, DS-F11, GRK-F5)**
State diagram uses PROMOTION_PENDING but it's not in state definitions or transition table. Scenario C relies on a "wait state" for lock contention that doesn't exist formally.

**7. Missing QUEUED → DEAD_LETTER transition (SIGNIFICANT — 2 reviewers: OAI-F10, DS-F2)**
Queue max-age timeout described in prose but absent from the formal transition table.

**8. Convergence tracking event disagreement (SIGNIFICANT — 2 reviewers: OAI-F11, DS-F4)**
Doc1 updates tracker on COMPLETED, ESCALATED, DEAD_LETTER. Doc2 updates on COMPLETED, DEAD_LETTER, ABANDONED (excluding ESCALATED as non-terminal). Different event models yield different reclassification behavior.

**9. Observability feedback loop unaddressed (SIGNIFICANT — 3 reviewers: OAI-F17, DS-F7, GRK-F8)**
Named failure mode (§2.4) with no explicit mitigation. System-generated paths could be fed back as contract context.

**10. Scenarios don't exercise claimed edges (SIGNIFICANT — 2 reviewers: OAI-F21, GRK-F9)**
Doc1 Scenario A's primary path doesn't actually escalate (escalation is an alternate branch). Doc2 Scenario 2 starts already at Tier 3 via Gate 1, so Gate 3 override is never demonstrated.

**11. Missing reasoning-failure transition in table (CRITICAL — 1 reviewer: OAI-F5, but intersects consensus #4)**
EXECUTING → ESCALATED only has budget_exhausted trigger. Mid-loop reasoning-failure escalation exists in prose (§6) but not the formal transition table. This is the mechanism Scenario A's alternate path depends on.

**12. UNVERIFIABLE CLAIMS (SIGNIFICANT — 4 reviewers: OAI-F35/F36/F37, GEM-F3, DS-F9, GRK-F7)**
Test result citations (Nemotron orch-06: 3/5, Kimi 0 fabrication) lack artifact references. Cross-references to spec sections/amendments can't be verified from the review package.

**13. Write-lock YAML concurrency (SIGNIFICANT — 2 reviewers: OAI-F24, GRK-F13)**
Lock table stored as YAML file isn't safe under concurrent multi-process updates.

**14. Convergence window too small (SIGNIFICANT — 2 reviewers: OAI-F25, GRK-F10)**
Rolling window of 20 is noisy for low-volume action classes in a 14-service workload.

**15. Bad-spec loop not formally handled (SIGNIFICANT — 2 reviewers: OAI-F16, DS-F6)**
Contract immutability + retry budget → dead-letter is described, but no formal detection criteria or scenario walkthrough.

### Unique Findings

**OAI-F7 (SIGNIFICANT): Cancellation during PROMOTING is unsafe.** No mechanism to defer/block cancellation while promotion is in-progress. Genuine gap — partial canonical state possible if cancellation interrupts the manifest-based copy. Recommend adding cancel-after-recovery semantics.

**OAI-F8 (SIGNIFICANT): Scenario B rollback claims assume nonexistent backup.** "Pre-promotion state (from staging backup)" implies canonical pre-images are stored. They're not — staging has source artifacts, not prior canonical versions. Language is misleading for file-update scenarios. Genuine language issue.

**OAI-F9 (SIGNIFICANT): "Atomic" promotion isn't atomic.** Manifest-based is crash-safe and resumable but not all-or-nothing visible to readers. Readers can observe partial state between operations. Honest naming issue.

**DS-F8 (SIGNIFICANT): TOCTOU in hash verification.** Hash checked after lock acquisition, but a window exists between check and copy. In practice, the write-lock prevents contract-driven modifications. Non-contract modifications (manual edits) during the locked window would require operator error. Low real-world risk but technically present.

**GRK-F4 (CRITICAL): Escalation re-entry doesn't re-run gates.** When ESCALATED → ROUTING, the escalation design doesn't define how gates handle re-entry. Gate 3 should re-fire (risk policy still applies). Gate 1 should respect a minimum-tier floor from the escalation source. Genuine gap — could allow de-escalation on re-routing.

**GEM-F5 (SIGNIFICANT): Hidden LLM latency in ROUTING.** If Gate 2 requires a live model call, ROUTING is not instantaneous. This is resolved by moving Gate 2 out of ROUTING (see Action A6).

**OAI-F18 (SIGNIFICANT): Credential cascade incomplete.** Single credential failure → dead-letter is covered, but no circuit breaker for dependent action classes. Many contracts could fail repeatedly before the pattern is detected.

### Contradictions

**Gate 4 placement:** OAI and Grok say Gate 4 is a post-terminal background process (Doc1 model). DeepSeek says it should be removed from the sequential diagram entirely. GEM didn't specifically address this. No reviewer argued Gate 4 should be a per-task routing step — consensus is clearly background/longitudinal.

**Retry budget on escalation:** DS-F3 suggests escalation may need to consume a budget unit. All other reviewers accept that escalation doesn't consume. The real issue is the scenario, not the rule — Scenario A's alternate path must branch earlier to show budget remaining.

### Action Items

**Must-fix:**

- **A1** (OAI-F1, DS-F1, GRK-F2, DS-F5) — Normalize gate count to "four-gate" in both docs. Define Gate 4 as a background routing-table reclassification process, not a per-task gate. Update Doc1 references from "three-gate" to "four-gate." Remove Gate 4 from Doc2's sequential routing diagram; add it as a separate feedback section.

- **A2** (OAI-F6, GEM-F1, GEM-F2, GRK-F3) — Add PENDING_APPROVAL state. For `requires_human_approval` contracts, execution MUST NOT happen before approval (side-effecting tools are irreversible). Add: ROUTING → PENDING_APPROVAL (if flag set) → DISPATCHED (on approval) → or ABANDONED (on rejection). Separate from DEAD_LETTER.

- **A3** (GEM-F4, GRK-F1, OAI-F26) — Align tier vocabulary. Production: Tier 1 (Nemotron local), Tier 3 (Kimi cloud). Tier 2 is undefined/undeployed. Remove all "Tier 1-2" references from Gate 2; replace with "Tier 1."

- **A4** (DS-F3, GRK-F6, OAI-F12) — Fix Scenario A to branch at iteration 2 (budget = 1 remaining). Add explicit budget invariant to Doc2: "Gate outputs never modify retry budget; rerouting preserves contract-level iteration counters."

- **A5** (OAI-F5) — Add transition: `EXECUTING → ESCALATED | Trigger: retry_preparing classifies reasoning_failure AND higher tier available AND iterations_remaining > 0`.

- **A6** (OAI-F4, GEM-F5) — Move Gate 2 from ROUTING to EXECUTING first-turn. Nemotron's confidence field is produced as part of its first execution response, not as a pre-dispatch probe. If `low`, runner escalates immediately (no artifacts produced yet). ROUTING runs only mechanical checks (Gate 1 + Gate 3). This eliminates the causal loop and aligns with spec §7.3 language ("model includes confidence in structured output").

- **A7** (GRK-F4) — Define escalation re-entry gate behavior. On ESCALATED → ROUTING: Gate 1 respects `min_tier` floor from escalation source. Gate 3 re-fires (risk policy always applies). Gate 2 skipped (already escalated). Gate 4 not applicable (per-task).

**Should-fix:**

- **A8** (OAI-F2, OAI-F3, DS-F11, GRK-F5) — Formalize PROMOTION_PENDING as sub-state of PROMOTING. Define lock-wait: retry lock acquisition with 60s timeout → if timeout, return to QUALITY_EVAL. Add to state definitions and transition table.

- **A9** (OAI-F10, DS-F2) — Add `QUEUED → DEAD_LETTER` transition to table with trigger `max_queue_age exceeded`.

- **A10** (OAI-F11, DS-F4) — Align convergence tracking: terminal states only (COMPLETED, DEAD_LETTER, ABANDONED). ESCALATED is non-terminal — not counted. Update both docs.

- **A11** (OAI-F15) — Add per-state watchdog timeouts: DISPATCHED ack timeout (30s), EXECUTING heartbeat (5 min), QUALITY_EVAL evaluation timeout (2 min). Timeout → ESCALATED or DEAD_LETTER.

- **A12** (OAI-F16, DS-F6) — Add bad-spec detection: if identical failure_class repeats across 2+ iterations with same check failing → classify as `bad_spec` → DEAD_LETTER with supersede recommendation. Add scenario walkthrough.

- **A13** (OAI-F17, DS-F7, GRK-F8) — Address observability feedback loop: add design rule excluding system-generated paths (`_staging/`, `~/.tess/`, ledger files) from contract vault-context inputs.

- **A14** (OAI-F21, GRK-F9) — Strengthen scenarios: Doc1 Scenario A primary path must show actual EXECUTING → ESCALATED → ROUTING transition. Doc2 Scenario 2 must start as Tier 1 task overridden by Gate 3. Add 2 new cross-doc scenarios: approval flow and credential cascade.

- **A15** (OAI-F9, OAI-F8) — Rename "atomic promotion" to "crash-safe resumable promotion." Fix Scenario B language: remove "pre-promotion state (from staging backup)" — staging has source artifacts, not canonical pre-images.

- **A16** (OAI-F24, GRK-F13) — Specify write-lock implementation: use flock or SQLite, not bare YAML.

- **A17** (OAI-F23) — Specify lock path overlap rules: lock acquisition fails if any existing lock path is an ancestor or descendant of the requested path.

- **A18** (OAI-F18) — Add credential cascade circuit breaker: after credential-refresh failure, mark dependent action classes as deferred. Single consolidated alert.

- **A19** (OAI-F25, GRK-F10) — Add convergence window minimum-sample guard: require ≥10 contracts before stats drive reclassification. Two consecutive windows before tier upgrade.

**Defer:**

- **A20** (OAI-F29) — Fix Doc2 title: "Three-Gate" → "Four-Gate."
- **A21** (OAI-F27) — Clarify hash verification timing description.
- **A22** (OAI-F28) — Clarify ROUTING owner (Tess orchestrator, not Tess/Kimi).
- **A23** (DS-F10, GRK-F12) — Routing table hierarchy for scalability. Address during TV2-031b implementation.

### Considered and Declined

- **DS-F8** (TOCTOU in hash verification) — declined: `constraint`. Write-lock prevents contract-driven modifications. TOCTOU only exists for non-contract modifications during the locked window, which requires operator error. Vault authority (AD-001) means Tess controls writes.

- **OAI-F19** (Pre-queue schema validation) — declined: `overkill`. Contract creation is Tess-driven from action plans, not user-submitted. Bad contracts are a Tess bug, caught by retry budget → dead-letter, not an intake validation problem.

- **GEM-F7** (Demotion tracking mechanical hook) — declined: `overkill`. Convergence stats already appear in health digest. Danny reviews stats and decides. Separate mechanical hook adds ceremony for a rare manual action.

- **OAI-F20** (Gate 2 bypass weakens "four-gate" claim) — declined: `constraint`. V1 exact-match tasks skipping Gate 2 is intentional — confidence self-assessment adds no value for mechanically-certain routing. Design explicitly states Gate 2 is conditional.

- **OAI-F13** (First-instance for unknowns is ambiguous) — declined: `incorrect`. Unknown tasks go to Tier 3 via Gate 1. Gate 3 first-instance ADDITIONALLY sets `human_escalation_class: review_within_24h`, which Gate 1's unknown routing doesn't. Different purposes, not redundant.

- **GRK-F11** (Shared gate output schema artifact) — declined: `out-of-scope`. Interface schema formalized during TV2-031b implementation.

- **OAI-F35/F36/F37, GEM-F3, DS-F9, GRK-F7** (Unverifiable claims) — declined: `constraint`. Test results are internal project artifacts referenced by task ID. The design docs reference run-log entries; full traceability exists within the vault. External reviewers cannot verify internal project data by definition. No action needed.
