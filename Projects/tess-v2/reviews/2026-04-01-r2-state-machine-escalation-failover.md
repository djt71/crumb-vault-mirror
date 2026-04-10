---
type: review
review_mode: full
review_round: 2
prior_review: reviews/2026-04-01-state-machine-escalation.md
artifact:
  - Projects/tess-v2/design/state-machine-design.md
  - Projects/tess-v2/design/escalation-design.md
  - Projects/tess-v2/design/local-model-failover.md
artifact_type: architecture
project: tess-v2
domain: software
skill_origin: peer-review
created: 2026-04-01
updated: 2026-04-01
reviewers:
  - anthropic/claude-opus-4-6
  - google/gemini
  - deepseek/deepseek-reasoner
  - openai/gpt-5.4
  - perplexity/perplexity
tags:
  - review
  - peer-review
status: active
---

# Peer Review Round 2: State Machine + Escalation + Failover (TV2-017/018/042)

**Artifacts:** state-machine-design.md (TV2-017), escalation-design.md (TV2-018), local-model-failover.md (TV2-042)
**Mode:** full
**Reviewed:** 2026-04-01
**Round 1 fixes verified:** All A1–A19 must-fix and should-fix items from Round 1 landed correctly. No regressions on gate placement, PENDING_APPROVAL, tier vocabulary, budget invariant, convergence tracking, promotion semantics, or observability exclusion.
**Reviewers:** Claude Opus 4.6 (synthesis + independent review), Gemini, DeepSeek Reasoner, GPT-5.4, Perplexity

---

## Action Items

### Must-Fix

- **B1** (Claude-PR07, GEM-F3, GPT-F3, PPLX-F3 — 4 reviewers + independent) — **V3 contract lifecycle: no feedback path from QUALITY_FAILED back to EXECUTING.** For V3 (judgment-dependent) contracts, `iteration_checking` is format-only, so the retry budget is consumed by format checks that trivially pass. The real evaluation happens in QUALITY_EVAL (post-termination). If QUALITY_EVAL fails, the contract goes to QUALITY_FAILED with no loop back to the executor. V3 contracts effectively get one substantive attempt regardless of retry budget.

  **Fix:** Add transition `QUALITY_FAILED → ESCALATED` (trigger: `iterations_remaining > 0 AND quality_failure_class: retryable`, guard: `verifiability == V3`). The ESCALATED state re-enters ROUTING carrying structured quality failure context (analogous to Amendment T failure context for Ralph loop retries). This routes through existing escalation machinery rather than adding a new direct transition to EXECUTING. Add a new contract field `quality_retry_budget` (default: 1 for V3, 0 for V1/V2) to cap quality-failure re-dispatches separately from execution retries. Update:
  - TV2-017 §5 transition table: add the `QUALITY_FAILED → ESCALATED` row
  - TV2-017 §10 (Amendment X): note that V3 quality failures consume from `quality_retry_budget`, not `retry_budget`
  - TV2-017 §17 open question 1: mark resolved with chosen approach
  - TV2-018 §7: note that ESCALATED re-entry from quality failure carries `escalation_reason: quality_failed` and quality eval output as failure context

- **B2** (Claude-PR06, GPT-F1 — 2 reviewers) — **Failover spec §6.5 contradicts TV2-042 on Stage 4/5 outage policy.** Spec §6.5 says reduce to critical services after 4 hours of local model downtime. TV2-042 Stages 4 and 5 say all services continue because Kimi/Qwen cloud cost is negligible (~$0.48/24h). TV2-042 also defines `critical-only` and `minimal` health modes that nothing ever enters. TV2-042 §6.3 Scenario B "Impact" line says "Non-critical services suspended" but the Stage 4 description and §6.3 conclusion say "ALL SERVICES CONTINUE."

  **Fix:** Amend spec §6.5 to match the failover design's "all services continue on cloud fallback" policy — the cost analysis supports it. Remove `critical-only` and `minimal` from the health mode enum in TV2-042. Simplify to three modes: `normal`, `degraded-local` (Stage 2), `cloud-fallback` (Stages 3–5). Fix TV2-042 §6.3 Scenario B "Impact" line to remove "Non-critical services suspended." Update:
  - specification.md §6.5: replace "reduce autonomous work to critical services only" with "all services continue on cloud routing; cost tracker monitors spend"
  - TV2-042 §3 decision tree: remove Stages 4/5 service reduction language; keep alert escalation at 4h and 24h
  - TV2-042 §4.2: remove `critical-only` and `minimal` from mode table; update Hermes mode-reading description
  - TV2-042 §6.3 Scenario B: fix "Impact" line

- **B3** (GPT-F2 — 1 reviewer, new finding) — **First-instance approval semantics conflict between spec and escalation design.** Spec §7.5 says `requires_human_approval: true` for first-instance task classes (set automatically via Gate 3). TV2-018 §5 Gate 3 policy table sets `requires_human_approval: false` for `first_instance` rule, with `human_escalation_class: review_within_24h`. Scenario 3 sends the task straight to Kimi with only a digest review.

  **Fix:** Align to spec's conservative position for initial deployment. Update TV2-018 §5 `first_instance` rule: set `requires_human_approval: true`. Update TV2-018 §11 Scenario 3: task goes to PENDING_APPROVAL, Danny approves, then dispatches to Tier 3. Add a note: "First-instance approval gating can be relaxed to `review_within_24h` after operational confidence is established across 20+ novel task classes." This is a policy knob, not an architecture change. Update:
  - TV2-018 §5 policy table: `first_instance` → `requires_human_approval: true`
  - TV2-018 §11 Scenario 3: rewrite to show PENDING_APPROVAL flow
  - TV2-018 §10 validation test plan: update ESC-08 expected outcome to include PENDING_APPROVAL

- **B4** (PPLX-F5 — 1 reviewer, unique finding) — **Gate 2 confidence calibration invalid under DEGRADED-LOCAL mode.** When the failover design swaps Nemotron for Qwen 35B backup on the same port, Gate 2 fires against Qwen's confidence output using Nemotron's calibration. Qwen may have systematically different confidence expression patterns (TV2-013 benchmarks are Nemotron-only). Under DEGRADED-LOCAL, Gate 2 could over-escalate (Qwen conservative) or under-escalate (Qwen overconfident), corrupting the escalation signal.

  **Fix:** Add a DEGRADED-LOCAL calibration note to TV2-018 §9: "Gate 2 confidence thresholds are calibrated for Nemotron. Under DEGRADED-LOCAL (Qwen backup), treat all Gate 2 confidence as `medium` until Qwen-specific calibration data is available (deferred to TV2-029). This means Tier 1 tasks continue locally but are flagged in the ledger for Gate 4 tracking." Update:
  - TV2-018 §9: add DEGRADED-LOCAL calibration paragraph
  - TV2-018 §4: add note that Gate 2 behavior is model-dependent; see §9 for calibration
  - TV2-018 §13 interaction table: add TV2-042 reference
  - TV2-017 §16 interaction table: add TV2-042 reference (see also B12)

- **B5** (PPLX-F2 — 1 reviewer, unique finding) — **Bad-spec detection delta matching is too strict.** The trigger requires identical `check_id` AND identical `delta` across 2 consecutive iterations. The `delta` is a human-readable failure description. If the executor makes different wrong attempts each iteration, the delta strings differ even though the same check fails for the same structural reason. Detection doesn't fire, budget exhausts normally, and the dead-letter entry doesn't flag bad-spec — so no superseding contract is created.

  **Fix:** Relax trigger to: same `check_id` AND same `failure_class` across 2 consecutive iterations. Drop `delta` from the detection trigger (keep it logged for diagnostics). Update:
  - TV2-017 §3 (Bad-Spec Detection): change trigger wording
  - TV2-017 §5 transition table: update `EXECUTING → DEAD_LETTER` guard for bad_spec from "identical check_id and delta" to "identical check_id and failure_class"
  - TV2-017 §14 Scenario F: verify walkthrough still holds (it should — same check_id and failure_class is a subset of the old rule)

### Should-Fix

- **B6** (GEM-F2 — 1 reviewer) — **Convergence tracker blind to source tier on escalated contracts.** The convergence entry schema records `executor_tier` and `escalated: true/false`. A contract that escalates from Tier 1 to Tier 3 and completes shows `executor_tier: 3, outcome: completed, escalated: true`. Gate 4 sees a successful Tier 3, not a failed Tier 1. The `escalated` flag exists but the source tier isn't recorded, so Gate 4 can't attribute failure to Tier 1's routing.

  **Fix:** Add `initial_tier` and `escalation_chain: [{from_tier, to_tier, reason}]` fields to the convergence entry schema in TV2-017 §9. Update Gate 4 logic in TV2-018 §6: count escalations *from* a tier as negative signal for that tier's routing of that action class.

- **B7** (GPT-F4 — 1 reviewer) — **Bad-spec contracts: DEAD_LETTER vs ABANDONED contradiction.** Bad-spec detection (TV2-017 §3) and Scenario F both say bad-spec → DEAD_LETTER. Contract immutability rules (TV2-017 §8, rule 3) say defective contract replaced by new one → old contract → ABANDONED with `superseded_by`. Both are in the same document for the same condition.

  **Fix:** Split the cases. Bad-spec detection → DEAD_LETTER (needs human assessment). If/when a superseding contract is created → old contract transitions DEAD_LETTER → ABANDONED with `reason: superseded_by: {new-id}`. Add transition `DEAD_LETTER → ABANDONED` to TV2-017 §5 transition table (trigger: "superseding contract created", guard: "superseding contract ID provided"). Update Scenario F to show two-step: bad-spec → DEAD_LETTER → Tess creates corrected contract → old contract ABANDONED with `superseded_by`.

- **B8** (DS-F1, Claude-PR03 — 2 reviewers) — **QUALITY_EVAL timeout too short for V3 contracts.** The 2-minute watchdog timeout for QUALITY_EVAL may be insufficient for judgment-dependent V3 quality checks run via Kimi. Complex quality evaluations (reading staged artifacts, comparing against specs, producing structured judgment) could exceed 2 minutes.

  **Fix:** Make the QUALITY_EVAL timeout configurable per-contract, keyed to verifiability tier. Defaults: V1 = 2 min, V2 = 2 min, V3 = 5 min. Add a note in TV2-017 §2 watchdog table that values are initial estimates subject to soak-test calibration.

- **B9** (PPLX-F4 — 1 reviewer) — **PENDING_APPROVAL notification lacks budget and escalation history.** When Danny receives a Telegram approval request, the notification doesn't include remaining retry budget or prior failure history. Danny could approve a contract with 1 iteration remaining after 2 Tier 1 failures, which will likely dead-letter immediately.

  **Fix:** Add to the PENDING_APPROVAL alert template: remaining budget, escalation history (source tier, failure count, failure classes), and iteration count. Specify in TV2-017 §6 (Gate 3 integration note) and reference in TV2-018 §5 (Gate 3 + Human Approval Integration).

- **B10** (Claude-PR04 — 1 reviewer) — **Promotion livelock: no counter on QUALITY_EVAL → PROMOTION_PENDING → PROMOTING → QUALITY_EVAL cycles.** If another contract keeps modifying the same canonical path between QUALITY_EVAL and PROMOTING, the cycle repeats indefinitely. Not caught by retry budget (which governs EXECUTING iterations).

  **Fix:** Add `max_promotion_attempts` (default: 3) to the contract schema or promotion engine config. After N failed promotion attempts (hash mismatch or lock timeout), transition to DEAD_LETTER with `reason: promotion_contention`. Add to TV2-017 §7 and §5 transition table.

- **B11** (Claude-PR05 — 1 reviewer) — **Gate 3 `prior_quality_failure` rule references undefined quality score metric.** TV2-018 §5 policy table uses `action_class_quality_score_p50 < 0.6` but quality_checks are pass/fail, not scored. The convergence tracker has `quality_pass_rate` (a ratio), not a p50 score.

  **Fix:** Change the Gate 3 `prior_quality_failure` condition from `action_class_quality_score_p50 < 0.6` to `action_class_quality_pass_rate < 0.60` (over last 10 contracts). Align with the convergence tracker's `quality_pass_rate` field.

- **B12** (PPLX-F6 — 1 reviewer) — **Crash recovery for PROMOTING with external canonical modification overpromises.** Scenario B edge case describes recovery when "another process modified report.md between crash and recovery." The recovery path goes to QUALITY_EVAL, which evaluates staging artifacts that don't reflect the externally-modified canonical state. Non-Tess canonical modifications during a locked promotion violate AD-001 (vault authority).

  **Fix:** Simplify by invoking AD-001. Add explicit note to TV2-017 §7: "Canonical modifications by non-Tess processes during an active promotion are a violation of AD-001 (vault authority). If external modification is detected during crash recovery (hash mismatch at destination), promotion fails, locks are released, and the contract enters DEAD_LETTER with `reason: external_canonical_modification` for manual resolution. The system does not attempt automatic recovery from AD-001 violations." Update Scenario B edge case language accordingly.

- **B13** (PPLX-F8 — 1 reviewer) — **Deferred queue contracts: `max_queue_age` vs `defer_until` interaction undefined.** If a deferred contract (from credential cascade circuit breaker) sits past `max_queue_age` before `defer_until` arrives, it dead-letters — destroying the circuit breaker's recovery path.

  **Fix:** Add to TV2-017 §11: "`max_queue_age` countdown pauses while contract status is `deferred`. The contract is not considered 'stale' until it has been eligible for dispatch. Deferred contracts are ineligible for priority boost and max_queue_age until `defer_until` passes."

- **B14** (PPLX-F1 — 1 reviewer) — **Gate 2 skip rule on escalation re-entry is over-broad.** TV2-017 §6 and TV2-018 §7 say "Gate 2 skipped on re-entry" unconditionally. Correct for the current two-tier architecture (re-entry always goes to Tier 3, where Gate 2 never fires). But stated as a general principle, it would suppress Gate 2 if a future Tier 2 re-entry ever landed back at Tier 1.

  **Fix:** Tighten skip rule in both docs to: "Gate 2 is skipped on re-entry when `assigned_tier > 1` OR when `escalation_reason == low_confidence_gate2`." Correct today, safe under future architecture changes.

- **B15** (PPLX-F7 — 1 reviewer) — **Gate 2 escalation hard-codes "Tier 3" instead of using min_tier abstraction.** TV2-018 §4 escalation logic says `low → ESCALATED → re-route to Tier 3`. TV2-017 says `ESCALATED → ROUTING with min_tier floor, Gate 1 assigns next viable tier`. Same outcome today, different abstraction level.

  **Fix:** Change TV2-018 §4 escalation logic for `low` to: "ESCALATED — set `min_tier` from current tier, re-enter ROUTING (Gate 1 assigns next tier above floor)." Aligns with TV2-017's abstraction.

### Minor

- **B16** (DS-F3) — Add cross-reference in TV2-018 failure taxonomy (spec §9.4) noting that `bad_spec` failure class is handled by the state machine's detection logic. Link to TV2-017 §3.

- **B17** (DS-F5) — Add note to TV2-017 §13 (credential cascade) that the credential-to-action-class dependency map is derived from service definitions' `dependencies` field (spec §11.3), materialized as a lookup table during TV2-014.

- **B18** (DS-F10, Claude-PR03) — Add annotation to TV2-017 §2 watchdog timeout table: "Timeout values are initial estimates. Values will be calibrated during soak test and production operation."

- **B19** (GEM-F5) — Add transition `STAGED → DEAD_LETTER` to TV2-017 §5 transition table (trigger: "artifact readability check failed", reason: `staging_corruption`).

- **B20** (PPLX-F11) — Add TV2-042 to both TV2-017 §16 and TV2-018 §13 interaction tables: "TV2-042 Local Model Failover — DEGRADED-LOCAL and CLOUD-FALLBACK modes affect Gate 2 calibration validity and Tier 1 availability for ROUTING."

- **B21** (PPLX-F9) — Fix TV2-017 §7 crash recovery for `status: pending` manifest. Change "safe to delete" to: "Promotion never started — staging artifacts still valid. Delete manifest, release locks, re-enter QUALITY_EVAL."

- **B22** (PPLX-F10) — Add INT-06 to TV2-018 §10 validation test plan: "Contract escalated from Tier 1 (budget exhausted), re-enters ROUTING at Tier 3, Gate 3 matches destructive_operation → PENDING_APPROVAL. Danny approves. Contract dispatches to Tier 3 with failure contexts preserved. Remaining budget visible in approval notification."

- **B23** (PPLX-F12) — Add alternate branch to TV2-017 §14 Scenario A: "If Kimi iteration 2 also fails with budget exhausted: EXECUTING → ESCALATED attempted, but min_tier: 3 = max tier → ESCALATED → DEAD_LETTER with full escalation chain."

- **B24** (Claude-PR01) — Reconcile task IDs. The spec §15 task decomposition lists TV2-017 as "Migrate services" (Phase 4) and has no TV2-018. The design docs use TV2-017 for state machine and TV2-018 for escalation. Either update spec §15 to reflect the actual task numbering or re-tag the designs. Also verify TV2-019 through TV2-031b referenced in interaction tables exist in an updated task list somewhere.

### Considered and Declined

- **GEM-F1** (Budget exhaustion → dead-on-arrival at higher tier) — declined: `incorrect diagnosis`. The state machine already handles this: ESCALATED with `iterations_remaining == 0` at max tier goes directly to DEAD_LETTER, not to dispatch with 0 budget. Gemini's proposed "recovery iteration" would break the budget invariant (B4/A4 from Round 1). The real mitigation is correct failure classification — reasoning failures should escalate before exhausting budget, not after. If a reasoning failure is misclassified as deterministic and burns all retries at the wrong tier, that's a classifier quality issue, not a state machine gap.

- **GEM-F4** (Gate 1 should read health mode for CLOUD-FALLBACK) — declined: `wrong layer`. Gate 1 is deliberately a static routing table lookup. The two-layer failover architecture (TV2-042 §4.2) handles Tier 1 unavailability at the infrastructure layer: Hermes's provider chain falls through to OpenRouter when localhost:8080 fails. Gate 1 assigns logical tiers; the infrastructure resolves them to physical endpoints. Injecting runtime health state into Gate 1 would couple orchestration logic to infrastructure, which the failover design specifically avoided. (See B4 for the Gate 2 calibration issue, which is the real cross-cutting concern.)

- **DS-F4** (PENDING_APPROVAL 7-day timeout → DEAD_LETTER) — declined: `intentional design`. The indefinite timeout for PENDING_APPROVAL is a deliberate safety decision. Tasks that reach PENDING_APPROVAL (destructive ops, external comms, system modifications) should wait forever if Danny doesn't respond — that's the safety property. Auto-expiring approvals defeats the purpose. The 4-hour re-alert is the correct mechanism.

- **DS-F2** (Lock-wait timeout causes livelock on large promotions) — declined: `misdirected`. The 60s timeout is on PROMOTION_PENDING (lock acquisition wait), not PROMOTING (file copy). Lock-wait timeout → return to QUALITY_EVAL is working as designed (re-evaluate after canonical state may have changed). The real livelock risk is repeated QUALITY_EVAL → PROMOTION_PENDING cycles, addressed by B10 (`max_promotion_attempts`).

- **GEM-F2** (Convergence tracker blind to escalation source tier) — note: accepted as B6, but Gemini's F1 concern about budget exhaustion is declined per above.

---

## Reviewer Signal Summary

| Reviewer | Findings | Accepted | Declined | Unique catches |
|----------|----------|----------|----------|----------------|
| Claude (independent) | 10 | 8 | 1 (PR-02 self-corrected) | PR-04 (promotion livelock), PR-05 (quality score schema) |
| Gemini | 5 | 3 | 2 | F2 (convergence source tier) |
| DeepSeek | 6 | 4 | 2 | Clean verification, no false positives |
| GPT-5.4 | 4 | 4 | 0 | F2 (first-instance approval — only new finding across all reviewers) |
| Perplexity | 12 | 11 | 0 | F2 (bad-spec delta), F5 (Gate 2 Qwen calibration), F6 (crash recovery AD-001), F8 (deferred queue age) |

**Top priority for implementation:** B1 (V3 lifecycle), B2 (failover spec alignment), B3 (first-instance approval), B4 (Gate 2 degraded-local calibration), B5 (bad-spec detection relaxation).
