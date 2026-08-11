---
project: tess-v2
type: specification-summary
domain: software
status: active
created: 2026-03-28
updated: 2026-04-21
source_updated: 2026-04-21
---

# Tess v2 — Specification Summary

> **⚠ Scope narrowed 2026-04-21 by Amendment AC** (`spec-amendment-AC-execution-surfaces.md`).
> Tess's orchestrator role is retracted on live-evidence grounds. Tess is
> now scoped to autonomous execution of 15 scheduled launchd services.
> Operator-facing planning/dispatch moves to Level 2 upstream surfaces
> (claude.ai, Cowork, Remote Control) and Crumb / Claude Code as Level 3
> execution. Below text is preserved as original intent; AC governs where
> they conflict.

## Problem
Nothing gets built unless Danny drives an interactive Crumb session. Tess is a notification layer, not an operator. OpenClaw's model routing is confirmed broken (v2026.3.24). The system needs Tess to become an autonomous orchestrator who dispatches contracts to specialized executors, with the vault as shared state.

> **Revised problem statement per AC:** Interactive Crumb is the preferred
> execution mode. The actual need is a clean **upstream work bridge** — a
> mechanism for strategic work done on claude.ai / Cowork / Remote Control
> to flow into Crumb for vault-grounded execution. Tess remains valuable
> for the 15 scheduled autonomous services; it is not the orchestrator
> for operator-facing work. OpenClaw's model routing issue is resolved by
> Tess v2's Hermes-gateway + contract-runner stack for the scheduled
> services.

## Solution
Rebuild Tess as a three-tier autonomous orchestrator: local LLM (Qwen3.5 27B) for routine decisions (free), local LLM with thinking for semi-novel decisions (free), frontier models for escalation (paid). Evaluate Hermes Agent as the platform layer to replace OpenClaw. Integrate eval-based building (contracts, Ralph loops) with Crumb's existing spec-first workflow.

> **Revised solution per AC:** Three-tier decision model, local-LLM runtime
> (Nemotron Cascade 2 production-selected), Hermes gateway, and eval-based
> contract execution machinery all ship as described — they drive the 15
> scheduled services. Orchestration over operator-facing interactive work
> is retracted.

## Key Architectural Decisions
- **AD-001:** Vault is authoritative. No split-brain.
- **AD-002:** Parallel operation during evaluation. No flag-day cutover.
- **AD-003:** Spec + eval integration. Contracts derived from specs provide mechanical completion verification.
- **AD-004:** Ralph loop execution. One contract per session, fresh context, hard stop.
- **AD-005:** Overlay injection at dispatch. Executors receive behavioral overlays alongside contracts.
- **AD-006:** Mechanical enforcement over behavioral compliance. No critical path depends on LLM memory.
- **AD-007:** Evaluator-executor separation. Tess evaluates; executors don't self-certify.
- **AD-008:** Staging → promotion write model. Executors write to `_staging/{contract-id}/`; Tess promotes to canonical vault after evaluation passes.
- **AD-009:** Risk-based escalation gate. Credential/destructive/external-comms/first-instance tasks always escalate regardless of model confidence.

## Key Constraints
- C1–C7: Vault authority, parallel operation, personality forward, no Ollama, budget, mechanical enforcement, evaluator-executor separation
- **C8:** Staging → promotion write model. No executor writes to canonical vault paths.
- **C9:** No promotion collisions. Write-lock table prevents two contracts targeting the same canonical path. Promotion is atomic per contract.

## §6 — Three-Tier Decision Model
- **Tier 1** (70-80%): Qwen3.5 27B non-thinking. Routine triage, routing, scheduling, monitoring. Zero marginal cost.
- **Tier 2** (15-20%): Qwen3.5 27B thinking mode. Semi-novel decomposition with structured vault context. Zero marginal cost.
- **Tier 3** (5-10%): Claude Sonnet/Opus via OpenRouter. Genuine novelty, ambiguous objectives, quality evaluation of complex artifacts.

### §6.5 — Local Model Runtime Failover
Health check every 60 seconds. Two consecutive failures trigger the failover sequence: (1) auto-restart attempt, (2) if restart fails within 90 seconds → swap to Qwen 3.5 35B MoE, then cloud fallback routing all Tier 1-2 decisions to OpenRouter (Kimi K2.5 / Qwen 397B). All services continue at full functionality. Cost impact: ~$0.77/day on full cloud routing — well within the $75 ceiling. Danny alerted after 4 hours of sustained outage. Full design in `design/local-model-failover.md`.

## §7 — Confidence-Aware Escalation (Three-Gate Hybrid)
**Gate 1: Deterministic boundary check.** Tess classifies the task against the executor routing table. Known type, unambiguous class → Tier 1, no escalation. Mechanical check only.

**Gate 2: Structured confidence field.** Orchestration responses include `confidence: high|medium|low` + `confidence_reason`. `low` triggers Tier 3. Tasks that don't map to any known type → automatic Tier 3 escalation.

**Gate 3: Risk-based policy escalation.** Regardless of Gates 1-2, these task classes always escalate: credentials/secrets, destructive file ops, external communications, financial actions, first-instance task classes, tasks where prior similar contracts scored low. Deterministic policy table, no model judgment.

**Human escalation taxonomy:** Urgent/blocking (Telegram push, queue indefinitely), Review-within-24h (Telegram + vault flag, reclassify to FYI after 24h), FYI digest (auto-archive after 7 days). Truly blocked tasks (credentials, destructive ops) queue with no timeout — Danny must act.

## §8 — Contract Schema
Contracts are YAML files with four check layers:
- **tests** (BLOCKING): deterministic file/frontmatter checks, mechanically verified by runner before executor terminates
- **artifacts** (BLOCKING): structured shell checks run by runner before executor terminates
- **quality_checks** (ADVISORY for termination, BLOCKING for promotion): judgment checks evaluated by Tess after executor completes, gate vault promotion
- **partial_promotion**: policy for failed contracts — `discard | hold_for_review | promote_passing`

Key fields: `contract_id`, `task_id`, `staging_path`, `termination` (all tests + artifacts pass), `promotion` (termination + quality_checks pass), `retry_budget` (default 3), `escalation`, `requires_human_approval` (set by Gate 3 policy — blocks promotion even if Tess approves quality).

Contracts are derived mechanically from action plan acceptance criteria during the TASK phase. Phase transition gates are themselves contracts.

## §9 — Ralph Loop Execution
The execution primitive. One contract per session, fresh context, hard stop on contract satisfaction.

Each iteration: agent receives contract + context (+ prior failure context on iterations 2+) → executes → checks contract satisfaction → terminates on pass or captures failure context for next iteration. Retry budget exhausted → escalate to Tess with failure summary.

**Retry failure classes:** Deterministic (fix input, retry same executor), Reasoning (escalate model tier), Tool (defer/requeue with backoff), Semantic (route to alternate executor or human). The retry budget applies across all classes — iteration N+1 should escalate approach, not repeat the failure.

## §10 — Overlay Injection at Dispatch
Tess determines overlays from task type (routing table defaults), project context, and operator requests. Hard limits: max 3 overlays per dispatch; 16K token cap for local executor dispatch context, 32K for frontier. If envelope exceeds budget, compaction order: (1) vault context — most distant files first, (2) overlays — least specific first, (3) service context — relevant entries only. Never truncate the stable header.

Overlay index gains `dispatch_eligible: true/false` column — interactive-only overlays (e.g., Life Coach) excluded from automated dispatch.

**Executor return envelope** is a structured YAML with: `contract_id`, `status`, `iterations`, `staging_path`, `artifacts_produced` (with SHA256), `test_results`, `failure_summary`, `failure_class`, `token_usage`.

## §10b — Tess Prompt Architecture
**Five layers:** stable header (<2K, always present), service context (2-4K, per-dispatch), overlays (1-3K, per-dispatch, max 3), vault context (remaining budget, per-dispatch), failure context (1-2K, iterations 2+ only).

Prompt components are vault markdown files — changes tracked by vault-check, picked up on next dispatch cycle without restart.

**Credential injection:** Secrets live in macOS Keychain, never in vault files. Injected as env vars scoped to the Ralph loop session. Credential *type* (not value) logged in contract execution ledger. Tess checks expiry dates daily, alerts Danny 7 days before expiration.

## Phases
1. **Pre-Evaluation:** Migration inventory + environment setup
2. **Platform Evaluation:** Hermes Agent (11 criteria + 72-hour soak). Phases 1 & 2 run in parallel.
3. **Local LLM Evaluation:** Qwen3.5 27B + 5 other candidates via benchmark harness (21 prompts + throughput) and 8 orchestration decision tests. GLM-4.7-Flash comparative.
4. **Architecture Design:** Confidence escalation, contract schema, service interfaces, staging lifecycle, observability (gated by eval results)
5. **Migration:** Service-by-service migration with parallel operation validation (gated by architecture)

Task IDs TV2-001–019 (spec §15) are superseded by the refined 49-task decomposition in `design/tasks.md`.

## Observability (§18)
Raw telemetry lives outside the vault at `~/.tess/logs/` (symlinked as `_tess/logs/`). Five monitoring surfaces: service run log, contract execution ledger, escalation log, vault write log, cost tracker. Daily health digest folded into morning briefing. Dead-letter queue for contracts that exhaust retry budget (`~/.tess/dead-letter/`).

## Key Risks
- Hermes Agent maturity (v0.3.0, ~1 month old) — mitigated by 72-hour recoverability-focused soak + parallel operation
- Local model confidence calibration — mitigated by three-gate escalation (boundary check + confidence field + risk policy)
- Local model runtime failure — mitigated by health check + auto-restart + OpenRouter fallback (§6.5)
- Production-length prompt degradation — mitigated by explicit Test 8 (>20% quality drop = architecture fails)
- Concurrent vault writes — mitigated by staging → promotion (AD-008) + write-lock table (C9)
- Distributed silent failures — mitigated by observability architecture (§18, logs outside vault)
- 8 novel failure modes identified by external review panel (§2.4), including silent stagnation, escalation storm collapse, and bad-spec infinite loops

## Cost Target
$10-55/month total orchestration cost (target <$50, ceiling $75 during migration), with 70-90% of decisions at zero marginal cost.

## Success

> **Revised per AC:** Success is (a) the 15 scheduled services run reliably
> without operator attention; (b) work from upstream surfaces flows cleanly
> into Crumb via the upstream work bridge; (c) vault stays authoritative;
> (d) Danny remains session driver in Crumb with strategic work on upstream
> surfaces. Original text preserved below.

Tess autonomously dispatches contracts and evaluates results. Work gets done while Danny sleeps. The vault stays authoritative. Danny shifts from session driver to strategic director.

## Peer Review
- **Round 1** (2026-03-28, automated): 4 reviewers. 3 must-fix + 8 should-fix applied. See `reviews/2026-03-28-tess-v2-specification.md`.
- **Round 2** (2026-03-28, external): 5 reviewers. 9 Tier-1 items applied: partial completion, runtime failover, promotion collision, system prompt architecture, credential management, Danny-unavailable degradation, soak test recoverability, escalation repositioning, logs out of vault. 9 Tier-2 items noted for PLAN. See `reviews/2026-03-28-external-peer-review-synthesis.md`.
