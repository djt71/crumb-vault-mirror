---
project: tess-v2
domain: software
type: review
status: active
created: 2026-03-28
updated: 2026-03-28
skill_origin: peer-review
tags:
  - review
  - peer-review
---

# Tess v2 Specification — Consolidated Peer Review Synthesis

**Date:** 2026-03-28  
**Reviewers:** Claude Opus 4.6, Gemini, DeepSeek, ChatGPT (GPT-5), Perplexity  
**Spec version reviewed:** 2026-03-28-r1

---

## Verdicts

| Reviewer | Verdict |
|---|---|
| Claude Opus 4.6 | Ready for PLAN with items addressed |
| Gemini | Ready for Phase 1, solve Serial Promotion + Context Budgeting in Phase 3 |
| DeepSeek | Needs revisions (credential mgmt, confidence mechanism, retry logic) |
| ChatGPT (GPT-5) | Needs revisions (runtime failover, partial completion, vault coordination, prompt architecture) |
| Perplexity | Needs revisions (state machine integration, partial completion, vault coordination) |

**Consensus:** Architecture is sound. Core design (contract/Ralph loop/three-gate/staging-promotion) validated by all five reviewers. Gaps are in operational mechanics and edge-case failure modes, not in the fundamental architecture. One targeted revision pass addresses all material concerns.

---

## Convergence Map — What Multiple Reviewers Flagged

Items flagged by 3+ reviewers are near-certain gaps. Items flagged by 2 are likely real. Items flagged by 1 may be real but need judgment on timing.

| Finding | Opus | Gemini | DeepSeek | GPT-5 | Perplexity | Count | Action Category |
|---|---|---|---|---|---|---|---|
| **Partial completion semantics** | ✓ | | ✓ | ✓ | ✓ | 4 | Spec revision |
| **Local model runtime failover** | ✓ | | ✓ | ✓ | ✓ | 4 | Spec revision |
| **Promotion collision / vault coordination** | | ✓ | ✓ | ✓ | ✓ | 4 | Elevate to constraint |
| **Danny-unavailable graceful degradation** | | | ✓ | ✓ | ✓ | 3 | Spec revision |
| **Credential management absent** | ✓ | | ✓ | | ✓ | 3 | Spec revision |
| **Evaluator-executor same-model blind spot** | | | | ✓ | ✓ | 2 | Spec revision |
| **Cost model underestimates bursty scenarios** | | | | ✓ | ✓ | 2 | Spec revision |
| **Logs don't belong in vault** | ✓ | | | ✓ | | 2 | Spec revision |
| **Escalation storm / load shedding** | | | | ✓ | ✓ | 2 | Phase 3 design |
| **Soak test: recoverability over zero-crashes** | | | | ✓ | ✓ | 2 | Spec revision |
| **System prompt architecture missing** | ✓ | ✓ | | ✓ | ✓ | 4 | Spec revision |
| **Human escalation taxonomy mispositioned** | ✓ | | ✓ | | ✓ | 3 | Spec revision |
| **Task graph sequencing issues** | | | | ✓ | ✓ | 2 | Spec revision |

---

## Tier 1: Revise Before PLAN

These items should be addressed in the spec before entering the PLAN phase. They affect the design surface enough that planning without them creates avoidable rework.

### 1. Partial Completion Semantics
**Flagged by:** Opus, DeepSeek, ChatGPT, Perplexity

The contract schema has binary completion: all tests pass and all artifacts verified, or nothing promotes. In practice, 80% of a contract's work may be correct while the last 20% fails. That work sits in staging with no path to the vault.

**Revision:** Add a `partial_promotion` policy field to the contract schema:
```yaml
partial_promotion: discard | hold_for_review | promote_passing
# Default: hold_for_review
```
- `discard` — staging abandoned on contract failure (current behavior)
- `hold_for_review` — Danny reviews during dead-letter processing, can promote passing artifacts
- `promote_passing` — artifacts that individually passed their checks promote; failing artifacts stay in staging

Also require: promotion is **atomic per contract** — either all promotable artifacts move, or none do. No half-promoted state. Use filesystem atomic moves where possible.

### 2. Local Model Runtime Failover
**Flagged by:** Opus, DeepSeek, ChatGPT, Perplexity

The spec evaluates whether the local model is viable but doesn't define what happens during normal operations when llama.cpp/vLLM dies, hangs, OOMs, or starts returning malformed tool calls after hours of uptime.

**Revision:** Add a section on local model availability:
- **Health check:** Tess pings the local model server every 60 seconds with a lightweight test prompt. Two consecutive failures → trigger fallback.
- **Automatic restart:** Tess attempts to restart the local model server once. If restart fails → fallback.
- **Fallback mode:** All Tier 1 and Tier 2 decisions route to OpenRouter (Sonnet). Services continue but at higher cost.
- **Fallback duration limit:** If local model is down > 4 hours, Tess alerts Danny and reduces autonomous work to critical services only.
- **Cost impact:** Model a worst-case 24-hour outage. If all ~100 daily decisions go to Sonnet at ~$0.01-0.05 each, that's $1-5/day — within budget but worth monitoring.
- **Soak test extension:** The 72-hour soak test for Hermes should also cover the local LLM server (llama.cpp or vLLM). Track memory growth, TTFT drift, and malformed output frequency.

### 3. Promotion Collision / Vault Coordination
**Flagged by:** Gemini, DeepSeek, ChatGPT, Perplexity

Currently in U4 as an "unknown" deferred to Phase 3. All four reviewers flagged this as more dangerous than a deferred unknown — it's a correctness condition for concurrent executor operation.

**Revision:** Elevate from U4 to a stated constraint (new C9):
- **C9: No two active contracts may target the same canonical vault path.** Tess maintains a write-lock table: when a contract is dispatched, its target canonical paths are registered. If a new contract would write to an already-locked path, Tess queues it until the first contract's promotion completes or fails.
- **Promotion precondition:** Before promoting, Tess checks that the canonical file hasn't changed since the contract was dispatched (hash comparison). If it has → conflict, route to dead-letter with "promotion conflict" class.
- **Atomic promotion per contract:** All artifacts promote together or none do (see §1 above).
- **Detailed design remains Phase 3** (TV2-015), but the constraints are now stated.

### 4. System Prompt Architecture
**Flagged by:** Opus, Gemini, ChatGPT, Perplexity

The three-tier decision model depends on Tess having the right context, but how that context is composed, versioned, and managed is unspecified.

**Revision:** Add a new section (§X: Tess Prompt Architecture):
- **Stable header:** Identity (SOUL.md excerpt), role definition, current date/time. Always present. Target: <2K tokens.
- **Service-specific context:** Loaded per-dispatch, not always present. Only the routing table entries and action class definitions relevant to the current task. Target: 2-4K tokens.
- **Vault context:** Read paths specified per-contract. Loaded dynamically. Budget: remaining tokens after header + service context + overlays.
- **Composition rule:** header + service context + overlays + vault context must fit within the dispatch token budget (16K local, 32K frontier — calibrate based on Phase 2 Test 8 results).
- **Versioning:** The system prompt components live in the vault as markdown files. Changes are tracked by vault-check and picked up on next dispatch cycle. No restart required.
- **Compaction:** When the envelope exceeds budget, truncate in order: (1) vault context (most distant files first), (2) overlays (least specific first), (3) service context (never truncate header).

### 5. Credential Management
**Flagged by:** Opus, DeepSeek, Perplexity

No section addresses how executor credentials are stored, rotated, refreshed, or scoped.

**Revision:** Add a section (§X: Credential Management):
- **Credential store:** System keychain (macOS Keychain) for secrets. Vault stores credential *metadata* (which services need which credentials, expiry dates) but never stores the secrets themselves.
- **Injection:** Tess passes credentials to executors via environment variables scoped to the Ralph loop session. Credentials never appear in logs, contracts, or vault artifacts.
- **Refresh automation:** Google OAuth refresh handled by existing gws tooling. OpenRouter API keys are long-lived. Telegram bot tokens don't expire. For any credential with an expiry, Tess checks expiry dates daily and alerts 7 days before expiration.
- **Audit:** Credential usage logged in contract execution ledger (which credential type was used, not the credential itself).
- **Phase 3 design task:** Add to TV2-015 scope — credential injection mechanism, refresh failure handling, and least-privilege scoping per executor.

### 6. Danny-Unavailable Graceful Degradation
**Flagged by:** DeepSeek, ChatGPT, Perplexity

The current policy ("no autonomous decision on human-required items regardless of how long Danny is unavailable") causes indefinite queueing.

**Revision:** Add a tiered timeout policy to §14.0:
- **Truly blocked (credentials, destructive ops, financial):** Queue indefinitely. No timeout. Danny must act.
- **Time-sensitive review (email triage, meeting prep):** If no response in 24h, reclassify to FYI digest. Log the reclassification. Don't execute autonomously — but stop holding the queue.
- **Low-risk review (vault gardening results, routine quality checks):** Safe default action after 48h timeout. Tess promotes if quality checks passed, with a "auto-promoted after timeout" flag in the ledger. Danny can review and revert during next attention cycle.

### 7. Soak Test Criteria
**Flagged by:** ChatGPT, Perplexity

Zero crashes in 72 hours is the wrong gate for a v0.3.0 platform.

**Revision:** Replace the soak test pass criteria in §12.2:
- **Old:** "zero crashes, memory stable, no silent failures"
- **New:** "≤2 crashes with clean recovery (no data loss, no state corruption, auto-restart within 60 seconds). Memory growth <20% over 72 hours. No silent message drops. No missed scheduled tasks. MTTR < 2 minutes."

Recoverability, data integrity, and alerting quality matter more than cosmetic zero-crash stability.

### 8. Human Escalation Taxonomy Repositioning
**Flagged by:** Opus, DeepSeek, Perplexity

Currently lives under §14 (Migration) but it's a permanent cross-cutting runtime policy.

**Revision:** Move to §7.6 or new §X, adjacent to the three-gate escalation architecture. Add a `requires_human_approval: true` flag to the contract schema that blocks promotion even if Tess approves quality. Contracts targeting destructive operations, `_system/` modifications, or first-instance task classes get this flag automatically via Gate 3 policy.

### 9. Logs Out of Vault
**Flagged by:** Opus, ChatGPT

Operational telemetry in the vault bloats Git history and creates an observability feedback loop.

**Revision:** Move `_tess/logs/` to a directory outside the vault (e.g., `~/.tess/logs/` or `_tess-runtime/logs/`). The vault stores durable semantic state (specs, artifacts, knowledge). High-volume telemetry lives outside the vault with a symlink for convenience. The health digest (which is semantic, not raw telemetry) stays in the vault.

---

## Tier 2: Address During PLAN Phase

These items are real but don't block the SPECIFY → PLAN transition. They should be designed during PLAN or early Phase 3.

### 10. Contract / Ralph Loop / Three-Gate State Machine Integration
**Flagged by:** Perplexity (primary), DeepSeek (supporting)

The three systems are described well in isolation but not as an integrated mechanism.

**Design questions for PLAN:**
- When escalation fires mid-Ralph-loop, what happens to the current contract instance and staging?
- Who can modify a live contract's retry_budget or termination criteria? (Answer should be: no one. Contracts are immutable once dispatched.)
- How does failure classification (deterministic/reasoning/tool/semantic) feed into escalation gates? (e.g., "first reasoning failure at Tier 1 → force Tier 2 for iteration 2; second reasoning failure → force Tier 3 regardless of confidence")
- Concrete state diagram: contract states (dispatched → executing → evaluating → promoting → completed | failed | dead-lettered), transition triggers, and who owns each transition.

### 11. Silent Stagnation / Value Density Metric
**Flagged by:** ChatGPT

The spec measures activity, not value. Tess could stay busy doing maintenance while never advancing revenue-relevant work.

**Design for PLAN:** Add "value density" to the health digest — fraction of completed contracts classified as revenue-relevant (liberation directive prompts) vs. maintenance. Surface this weekly so Danny can see whether the system is doing useful work or just staying busy.

### 12. Escalation Storm / Load Shedding Policy
**Flagged by:** ChatGPT, Perplexity

A degrading local model causes more escalations → higher cost → longer queues → more urgency → more escalation. No policy for shedding load.

**Design for PLAN:** When escalation rate exceeds threshold (>20% over 4 hours), Tess enters degraded mode:
- Suspend non-critical services (vault gardening, overnight research)
- Defer low-priority contracts
- Preserve budget for critical services (email triage, morning briefing)
- Alert Danny

### 13. Queue Poisoning / Scheduler Fairness
**Flagged by:** ChatGPT

Pathological contracts can monopolize executor slots and Tess's attention.

**Design for PLAN:** Add a max-age policy for contracts in the queue. Contracts waiting >N hours without execution get reclassified or deferred. Dead-letter items have a retention policy: unresolved after 7 days → escalate to morning briefing with increasing urgency. Unresolved after 30 days → auto-archive with "abandoned" flag.

### 14. Confidence Calibration Drift
**Flagged by:** Perplexity

Confidence thresholds calibrated against a test suite will drift as production task distribution diverges.

**Design for PLAN:** Track correlation between confidence field and actual quality outcomes. If "high confidence" decisions start failing quality checks at >15% rate for a task class, auto-escalate that class to Tier 3 until recalibrated. Log this in the escalation log.

Also: plan explicitly for "confidence never calibrates well" as a first-class outcome. Fallback architecture: Gate 1 and Gate 3 carry the full load, Gate 2 is advisory-only, Tier 2 decisions default to frontier.

### 15. Evaluator-Executor Perspective Separation
**Flagged by:** ChatGPT, Perplexity

When Tess uses the same local model to evaluate output that another executor produced, you have process separation without meaningful perspective separation.

**Design for PLAN:** For low-risk work, same-model evaluation is acceptable. For high-risk or ambiguous quality checks, the spec should state: evaluation must use either a different model tier, a different model family, or deterministic checks only. Add an `evaluation_tier` field to the contract schema that specifies the minimum model tier for quality evaluation.

### 16. Cost Model: Bursty Scenario
**Flagged by:** ChatGPT, Perplexity

The cost model prices the happy path. It doesn't account for Ralph loop retries, escalation storms, or first-instance task classes forced to Tier 3.

**Design for PLAN:** Add a "bad day" cost model: if 20% of contracts retry 2+ times and escalation rate hits 25%, what's the daily cost? Set a hard daily cost ceiling (e.g., $10/day) with automatic service suspension if exceeded. The cost tracker (§18.1) should enforce this, not just alert.

### 17. Contract Schema Drift
**Flagged by:** Perplexity

As executor types are added, the contract schema gets extended ad-hoc. Executors ignore fields they don't know about.

**Design for PLAN:** The contract schema is versioned (e.g., `schema_version: 1`). Executors must validate against the full schema. Unknown fields are errors, not silent ignores. Schema changes require a version bump and migration of active contracts.

### 18. Task Graph Dependency Correction
**Flagged by:** ChatGPT, Perplexity

TV2-013 (contract schema) depends on Hermes go/no-go even though the contract model is platform-agnostic. TV2-014 (service interfaces) doesn't depend on contract schema even though service contracts are part of those interfaces. TV2-015 has no dependencies even though it depends on both.

**Revision for PLAN:** Correct the dependency chain:
- TV2-013 (contract schema) → remove dependency on TV2-006 (Hermes go/no-go). Contract design is platform-agnostic.
- TV2-014 (service interfaces) → add dependency on TV2-013 (contracts are part of service definitions)
- TV2-015 (vault coordination) → add dependency on TV2-013 (coordination semantics depend on contract shape)

---

## Tier 3: Note for Phase 3+ Implementation

These are valid operational concerns that belong in implementation, not specification.

| Item | Source | Phase 3 Design Task |
|---|---|---|
| Promotion queue manager (serial Tess bottleneck) | Gemini | Design promotion scheduling when multiple contracts complete simultaneously |
| Idempotency for scheduled services | ChatGPT | Require run IDs and dedup semantics per service. Reference existing autonomous-ops patterns. |
| Overlay versioning and stale-overlay detection | Perplexity | Add `last_reviewed` dates. Include stale-overlay check in vault gardening. |
| Dead-letter queue retention policy | Perplexity | Items unresolved after N days escalate. After 30 days auto-archive. |
| Tess restart state recovery | DeepSeek | In-flight contract state must be durable. Define recovery mechanism on restart. |
| Log rotation, retention, queue-depth thresholds | ChatGPT, Perplexity | Operational limits for single-machine system. |
| Max concurrent Ralph loops | Perplexity | Global throttle to prevent resource thrashing. |
| Adaptive alert baselines | Perplexity | Trend detection instead of static thresholds to prevent alert fatigue. |
| Vault size / indexing strategy | Perplexity | As vault grows, naive path-based context packaging becomes too expensive or too lossy. |
| Overnight research data sources | Gemini | TV2-001 inventory should identify why data sources broke so new architecture doesn't inherit the same brittleness. |

---

## Novel Failure Modes Identified

These failure classes were not in the original spec. Each should be acknowledged in the spec's unknowns or addressed in Phase 3 design.

| Failure Mode | Source | Description |
|---|---|---|
| **Silent stagnation** | ChatGPT | Tess stays busy doing low-value maintenance. All metrics green. No revenue-relevant work advances. |
| **Silent contract drift** | DeepSeek | Contract passes all checks but produces wrong output because the source spec was flawed. Vault gets authoritative-but-wrong state. |
| **Confidence calibration drift** | Perplexity | Production task distribution diverges from calibration set. Model's self-assessment becomes unreliable without visible signal. |
| **Escalation storm collapse** | ChatGPT | Degrading local model → more escalations → higher cost → longer queues → more urgency → more escalation. Cascading. |
| **Queue poisoning** | ChatGPT | Pathological contracts monopolize executor slots and Tess's attention. Fresh valuable work starves. |
| **Promotion race via stale reads** | ChatGPT | Two contracts read same artifact, write to separate staging, both pass. Later promotion silently overwrites or invalidates earlier one. |
| **Observability feedback loop** | ChatGPT | Writing logs to vault increases churn → triggers more validation → enlarges contexts → degrades the system being observed. |
| **Credential expiry cascade** | DeepSeek | Credential refresh fails → all executors of that type fail → classified as tool failures → retries exhaust → escalate. Easily preventable with proactive monitoring. |
| **Contract schema drift** | Perplexity | Ad-hoc schema extensions per executor type. Executors silently ignore unknown fields. Central policy gates become fragile. |
| **Bad spec infinite loop** | DeepSeek | Logically contradictory spec → contract can never be satisfied → Ralph loop exhausts retries → Tess re-dispatches or dead-letters without diagnosing the spec as the root cause. |

---

## Architecture Validation Summary

All five reviewers confirmed:

1. **Contract + Ralph loop + staging-promotion** is the right execution primitive
2. **Three-gate escalation** correctly minimizes reliance on model self-assessment
3. **Vault authority (AD-001)** is non-negotiable and correctly stated
4. **Evaluator-executor separation (AD-007)** is the right pattern
5. **Mechanical enforcement over behavioral compliance (AD-006)** is the right approach for 24/7 autonomous operation
6. **Migration sequencing** (low-risk first, critical last, parallel operation) is pragmatic

The core architecture does not need rethinking. It needs one revision pass focused on: partial completion, runtime failover, vault coordination constraints, system prompt architecture, and credential management. Then it's ready for PLAN.
