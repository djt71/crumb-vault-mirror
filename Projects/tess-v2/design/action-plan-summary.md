---
project: tess-v2
type: action-plan-summary
domain: software
skill_origin: action-architect
status: active
created: 2026-03-28
updated: 2026-04-21
source_updated: 2026-03-28-r2
---

# Tess v2 — Action Plan Summary

> **⚠ Scope narrowed 2026-04-21 by Amendment AC.** The milestone structure
> below remains accurate for the scheduled-services stack (Phases 0-4, 4a,
> 4b). Framing that casts Tess as "autonomous orchestrator" is narrowed to
> "autonomous executor of 15 scheduled services." No milestone is
> retired; AC changes role scope, not infrastructure delivery. Active open
> work (TV2-038, TV2-040, TV2-057d/e/f) is preserved in full.

## Structure

46 tasks across 7 milestones (including integration gate). Phases 1 and 2 run in parallel. Integration test bridges to Phase 3. Phase 4 includes core implementation (contract runner, staging engine, dispatch validator) before migration. Branch-specific success criteria for all GO/NO-GO combinations.

## Milestones

**M1: Foundation (4 tasks, low risk)**
Migration inventory, llama.cpp + model downloads, benchmark harness build, quality test battery authoring.

**M2: Platform Evaluation (4 tasks, medium risk)**
Hermes install → 11-criteria evaluation → 72-hour soak → go/no-go decision (TV2-008). Parallel with M3.

**M3: Local LLM Evaluation (8 tasks, medium risk)**
Qwen3.5 27B setup → benchmark runs (Q4, Q6, GLM, optional MLX) → orchestration tests (8 tests incl. production-length degradation) → model selection → go/no-go (TV2-016). Parallel with M2.

**Integration Gate (1 task, medium risk)**
TV2-041: Joint Hermes + local model end-to-end dispatch test. Bridges evaluation to architecture.

**M4: Architecture Design (16 tasks, mixed risk — 3 high)**
Core: state machine (with scenario walkthroughs), escalation design (AD-009 deterministic validation + scenarios), contract schema. Execution: Ralph loops, service interfaces (split: draft during evals, finalize in Phase 3), staging/promotion (high risk + scenarios). Infrastructure: system prompts, credentials (medium risk, expanded), observability, **runtime failover**. Policies: load shedding, queue fairness, bursty cost, calibration drift, value density. Addresses all 9 Tier-2 items. Produces updated system map.

**M5: Implementation + Migration (10 tasks, escalating risk)**
[Scaffold + core implementation: repo init, contract runner, staging engine, dispatch validator] → [low-risk parallel: heartbeats + vault gardening] → [medium-risk parallel: feed-intel + daily attention/research] → [high-risk sequential: email triage → morning briefing]. High-risk services have automatic rollback on 2 consecutive failures.

**M6: Validation & Cutover (3 tasks, high risk)**
Full parallel validation (vault authority + evaluator separation + state reconciliation + inventory revalidation + cost verification) → cutover decision (Danny approves) → OpenClaw decommission. Branch-specific success criteria based on GO/NO-GO outcomes.

## Gate Structure

```
M1 ──┬──→ M2 (Hermes) ──→ GO/NO-GO ──┐
     │                                  ├──→ M4 → M5 → M6
     └──→ M3 (LLM) ─────→ GO/NO-GO ──┘
```

NO-GO redirects, doesn't stop: Hermes NO-GO → OpenClaw + custom orchestration. LLM NO-GO → OpenRouter for Tiers 2–3. Dual NO-GO → §12.4 + §13.6 hybrid. Fallback paths validated at gate time, not just documented.

## Key Risks

- **Hermes maturity** (v0.3.0, 1 month old) — mitigated by soak test + parallel operation
- **Local model confidence calibration** — mitigated by three-gate design + drift monitoring + AD-009 deterministic escalation
- **Migration disruption** — mitigated by low-risk-first sequencing + parallel run with concrete metrics + per-service rollback testing
- **Vault integrity under concurrent writes** — mitigated by staging/promotion (high risk task) + collision testing + reconciliation at validation
- **Go/no-go pivots** — checkpoint-triggered pivots can compress timelines dramatically (estimation calibration pattern: 0.04x prior)

## Peer Reviews

**Round 1 (automated):** 4 reviewers (GPT-5.4, Gemini 3.1 Pro, DeepSeek V3.2, Grok 4.1 Fast). 8 must-fix + 10 should-fix applied. Key: relaxed migration serial chaining, concrete metrics, expanded deps, AD-009 validation, rollback testing, vault authority verification.

**Round 2 (external):** 5 reviewers (Opus 4.6, Gemini, DeepSeek, GPT-5, Perplexity). 18 items applied across 3 tiers. Key: joint integration test, runtime failover, scaffold expansion to implementation tasks, scenario walkthroughs for high-risk designs, TV2-021 split for parallelism, branch-specific success criteria, resource contention notes, credential management elevation, automatic rollback triggers, tie-break rules.

## Cross-Project Dependencies

- XD-024: Phase 4 gated by TV2-008 + TV2-016
- XD-025: tess-operations service continuity during migration
