---
project: tess-v2
type: action-plan
domain: software
skill_origin: action-architect
status: active
created: 2026-03-28
updated: 2026-03-28-r2
---

# Tess v2 — Action Plan

## Context Inventory

1. `design/specification-summary.md` — r2 compact reference
2. `design/specification.md` — §3 (system map, constraints, deps), §5 (ADs), §12–18 (evaluations, migration, success, cost, observability)
3. `_system/docs/estimation-calibration.md` — checkpoint pivots compress timelines
4. `_system/docs/cross-project-deps.md` — XD-024 (Phase 4 gated by eval), XD-025 (tess-ops service continuity)
5. Solutions/ — 4 docs integrated into spec (F9–F12)
6. Signal scan — 10 relevant signals (ambient, not loaded)
7. Tier-2 peer review items — 9 items from external review round 2

## Estimation Notes

**Calibration pattern (from estimation-calibration.md):** Checkpoint-triggered pivots compress timelines dramatically (prior: 0.04x ratio when NO-GO fired). This project has two major go/no-go gates (Hermes TV2-008, Local LLM TV2-015) that could redirect entire phases. Plan accordingly:
- If Hermes = NO-GO → Phase 4 proceeds on OpenClaw with custom orchestration (§12.4). Phase 3 architecture adapts but doesn't restart.
- If Local LLM = NO-GO → Tiers 2–3 route through OpenRouter (§13.6). Higher cost, architecture simplifies (single-tier local for mechanicals only).
- Neither NO-GO kills the project — they redirect it. But Phase 3 design depends on knowing which platform and model stack we're working with.

**Phases 1 and 2 run in parallel** — they are independent evaluations. Phase 3 is gated by both completing.

## Milestone 1: Foundation (Phase 0)

Establish the evaluation environment and catalog existing Tess infrastructure.

### M1.1: Inventory & Catalog

Catalog every piece of existing Tess operational wiring before changing anything. This inventory drives the migration sequence (Phase 4) and the service interface definitions (Phase 3).

- **TV2-001:** Migration inventory — catalog all OpenClaw cron jobs, scripts, state files, configs, credentials with migrate/rebuild/drop classification. Each service includes structured data: triggers, inputs, outputs, failure modes, baseline metrics. Confirm exhaustive against running launchd services. Update M5 if additional services discovered.

### M1.2: Evaluation Environment

Build the infrastructure needed to run both evaluations.

- **TV2-002:** Build llama.cpp from source, download candidate model GGUFs (Qwen3.5 27B Q4+Q6, GLM-4.7-Flash, Nemotron, Qwen3.5 35B MoE, Qwen3-coder 30B baseline)
- **TV2-003:** Build benchmark harness — `benchmark-model.sh` entry point, SQLite schema, scoring logic
- **TV2-004:** Author quality test battery — 21 prompts across 5 categories with expected-output schemas and scoring rubrics

### M1 Success Criteria
- Complete migration inventory with classification for every item
- llama.cpp serving a model with correct tool-calling chat template
- `benchmark-model.sh <gguf>` produces a SQLite scorecard row
- All 21 quality prompts authored and validated against at least one model

---

## Milestone 2: Platform Evaluation (Phase 1)

Evaluate Hermes Agent as the orchestration platform. **Runs in parallel with M3.**

### M2.1: Installation & Configuration

- **TV2-005:** Install Hermes Agent on Mac Studio, configure Telegram integration, connect to local LLM endpoint via OpenAI-compatible API

### M2.2: Feature Evaluation

- **TV2-006:** Evaluate Hermes against all 11 criteria from §12.1 — score 1–5 with documented methodology per criterion

### M2.3: Stability Soak

- **TV2-007:** 72-hour continuous soak test — Hermes + local LLM server under moderate load (2–3 cron jobs, periodic Telegram, model switches). Track crashes, memory, delivery, scheduling.

### M2.4: Go/No-Go Gate

- **TV2-008:** Hermes go/no-go decision. Data-backed rationale (average ≥3.5, no critical criterion below 3). If NO-GO, document AND validate fallback path (OpenClaw + custom orchestration feasibility confirmed per §12.4).

### M2 Success Criteria
- All 11 criteria scored with test evidence
- Soak test telemetry complete (72h)
- Go/no-go decision documented with data
- If GO: confirms A1 (local API connection) and A7 (personality transfer)

---

## Milestone 3: Local LLM Evaluation (Phase 2)

Evaluate local models for Tess orchestration. **Runs in parallel with M2.**

### M3.1: Primary Candidate Setup

- **TV2-009:** Qwen3.5 27B setup — llama.cpp server with correct chat template, verified tool-calling pipeline (NOT Ollama per C4/F4)

### M3.2: Benchmark Harness Runs

- **TV2-010:** Run benchmark harness against Qwen3.5 27B (Q4_K_M + Q6_K) — throughput at 4 context lengths, quality battery, context ceiling
- **TV2-011:** Run benchmark harness against GLM-4.7-Flash — same battery, comparative data
- **TV2-012:** MLX backend comparison — run same battery on MLX for at least Qwen3.5 27B Q4. Quantify tok/s and quality delta vs llama.cpp. (Optional — skip if llama.cpp performance is sufficient)

### M3.3: Orchestration Tests

- **TV2-013:** Run 8 orchestration decision tests against Qwen3.5 27B — all 8 tests including Test 8 (production-length prompt degradation)
- **TV2-014:** Run orchestration tests against GLM-4.7-Flash — comparative data for routing decision

### M3.4: Model Selection Decisions

- **TV2-015:** Single vs. dual model decision — dual justified only if GLM ≥ Qwen3.5 on T1 tasks AND ≥2x faster
- **TV2-016:** Local LLM go/no-go decision. GO if: single model passes both bars, OR dual selected and both pass their respective bars. If NO-GO, validate OpenRouter fallback (connectivity, cost, policy). If dual NO-GO (both Hermes + LLM): document §12.4 + §13.6 hybrid fallback.

### M3 Success Criteria
- SQLite scorecards for all tested models
- Orchestration test results documented with production-length degradation data
- Model selection decision with data-backed rationale
- Go/no-go decision with fallback path if needed

---

## Integration Gate (Pre-Phase 3)

Before entering architecture design, validate that the selected platform and model work together end-to-end.

- **TV2-041:** Joint Hermes + local model integration test — one complete dispatch cycle through Hermes with the selected local model. Verify request/response/parse chain. Half-day task. If fails, integration gap discovered before Phase 3 design begins.

---

## Milestone 4: Architecture Design (Phase 3)

Design the detailed architecture. **Gated by TV2-041 (integration validated) — platform and model stack confirmed working together.**

Incorporates all 9 Tier-2 items from external peer review round 2.

### M4.1: Core Architecture

Foundational designs that everything else depends on.

- **TV2-017:** State machine design — contract lifecycle + Ralph loop + three-gate integration. State diagram, transitions, mid-loop escalation, contract immutability rules. *(Tier-2: state machine integration)*
- **TV2-018:** Confidence-aware escalation — three-gate hybrid detailed design. Gate definitions, confidence field schema, calibration procedure, evaluator perspective separation, validation test plan. Gate 3 (AD-009) must include deterministic escalation tests for credential/destructive/external-comms tasks. Depends on TV2-008, TV2-016, TV2-017. *(Tier-2: evaluator perspective separation folded in)*
- **TV2-019:** Contract schema — finalize YAML with all fields (tests, artifacts, quality_checks, termination, partial_promotion), versioning strategy, blocking vs advisory semantics, validation tooling. *(Tier-2: contract schema versioning)*

### M4.2: Execution Architecture

How contracts get executed and how results flow back.

- **TV2-020:** Ralph loop implementation spec — iteration budget, failure context injection, hard stop mechanics, partial completion policy, executor return envelope parsing
- **TV2-021a:** Draft service interfaces from migration inventory (depends on TV2-001 only — can start during evaluations). Inputs, outputs, monitoring surfaces, overlay requirements, rollback procedures, idempotency requirements.
- **TV2-021b:** Finalize service interfaces with contract templates (depends on TV2-021a + TV2-008 + TV2-016 + TV2-019). Adds contract templates, executor assignments, token budgets.
- **TV2-022:** Staging/promotion lifecycle — directory structure, write-lock table, hash-based conflict detection, retention/cleanup, atomic promotion procedure, rollback mechanism design, concurrent promotion collision tests. **Risk: high** (vault integrity critical per C8/C9/AD-001).

### M4.3: Infrastructure Architecture

System-level concerns: prompts, credentials, observability, scheduling.

- **TV2-023:** System prompt architecture (§10b) — prompt layers, composition rules, compaction order, overlay token budgets (16K local, 32K frontier, max 3 overlays)
- **TV2-024:** Credential management — Keychain integration, env var injection per session, expiry monitoring, never-in-vault enforcement
- **TV2-025:** Observability infrastructure — logging paths, health digest template, dead-letter queue mechanics, alert thresholds, monitoring surfaces per service
- **TV2-042:** Local model runtime failover — health check, auto-restart, OpenRouter fallback during outage, 4h degradation alert, 24h outage cost model

### M4.4: Operational Policies

Policies for edge cases, failure modes, and cost management. Depend on core architecture being defined.

- **TV2-026:** Escalation storm / load shedding — detection threshold, shedding strategy, recovery behavior, alert criteria. *(Tier-2)*
- **TV2-027:** Queue poisoning / scheduler fairness — max-age policy, priority classes, fairness rules. *(Tier-2)*
- **TV2-028:** Bursty cost model — retry storm scenarios, escalation cascades, first-instance overhead, budget alerts. *(Tier-2)*
- **TV2-029:** Confidence calibration drift — monitoring mechanism, re-calibration triggers, threshold update procedure. *(Tier-2)*
- **TV2-030:** Value density metric — revenue-relevant vs maintenance ratio, health digest inclusion, silent stagnation detection. *(Tier-2)*

### M4 Success Criteria
- State machine with all transitions defined and diagrammed
- Escalation mechanism designed with three-gate definitions and calibration plan
- Contract schema finalized with validation tooling
- All migrating services have interface definitions
- Staging/promotion lifecycle fully specified with rollback mechanism and collision tests
- All 9 Tier-2 peer review items addressed
- Observability infrastructure designed with monitoring surfaces per service
- Updated system map produced (components, data flows, tier boundaries)

---

## Milestone 5: Migration (Phase 4)

Migrate services from OpenClaw to new platform. **Gated by M4 completion.** Follows §14.2 sequence: low-risk first, critical last. Each service: configure → parallel run → compare → cut over.

### M5.1: Scaffold + Core Implementation

The gap between Phase 3 design and Phase 4 migration requires building the orchestration engine — not just initializing a repo.

- **TV2-031a:** Initialize external repo + project structure. Record repo_path in project-state.yaml.
- **TV2-031b:** Implement contract runner + Ralph loop controller (from TV2-019/TV2-020 design). Enforces iteration budgets, hard stops, failure context injection.
- **TV2-031c:** Implement staging/promotion engine (from TV2-022 design). Directory lifecycle, write-lock table, atomic promotion. **Risk: high** (vault integrity).
- **TV2-031d:** Implement dispatch envelope validator (from TV2-023 design). Token budget enforcement per layer.

Migration tasks depend on TV2-031b + TV2-031c + TV2-031d — the engine must exist before services migrate to it.

### M5.2: Low-Risk Services (parallel within tier)

- **TV2-032:** Migrate heartbeats — configure on new platform, parallel run 48h, verify with concrete metrics, rollback tested
- **TV2-033:** Migrate vault gardening — configure, parallel run 48h, diff comparison, rollback tested

TV2-032 and TV2-033 can run concurrently (both depend on scaffold + interfaces + staging, not on each other).

### M5.3: Medium-Risk Services (parallel within tier, gated by low-risk completion)

- **TV2-034:** Migrate feed-intel pipeline — configure, parallel run 72h, ≥95% classification accuracy, zero data loss, rollback tested
- **TV2-035:** Migrate daily attention + overnight research — configure, parallel run 72h, correct scheduling, output completeness, rollback tested

TV2-034 and TV2-035 can run concurrently once low-risk tier completes.

### M5.4: High-Risk Services (sequential, gated by medium-risk completion)

- **TV2-036:** Migrate email triage — configure, parallel run 1 week, ≥90% classification match, zero missed emails, rollback tested
- **TV2-037:** Migrate morning briefing — configure, parallel run 1 week, zero delivery misses, Danny confirms quality, rollback tested

### M5 Success Criteria
- All services from inventory migrated with parallel run evidence and concrete metrics
- Each service passes its defined acceptance thresholds (not subjective "matches or exceeds")
- No data loss during any migration
- Rollback tested for every service
- Cost tracking active across all services

---

## Milestone 6: Validation & Cutover (Phase 4b)

Full system validation and production transition. **Gated by M5 completion.**

- **TV2-038:** Full parallel operation validation — all services running on both platforms ≥48h. Comparison report per service. Cost tracking.
- **TV2-039:** Production cutover decision — all services pass validation, rollback procedure documented and tested, Danny approves
- **TV2-040:** OpenClaw decommission — disable migrated OpenClaw services, new platform sole operator, no interruption >30min

### M6 Success Criteria

**Core criteria (all branches):**
- All services validated in parallel operation
- Vault authority verified: no writes bypass staging/promotion (AD-001)
- Evaluator separation verified: executors cannot self-promote (AD-007)
- State reconciliation: no orphaned jobs, state artifacts, or credential gaps vs OpenClaw
- Migration inventory revalidated — any services added since TV2-001 cataloged
- Cutover decision documented with Danny's approval
- OpenClaw decommissioned for migrated services
- Tess autonomously dispatching contracts and evaluating results

**Branch-specific targets:**

| Scenario | Local Routing | Cost Target | Additional Gate |
|----------|--------------|-------------|-----------------|
| Both GO (preferred) | ≥70% Tier 1+2 | <$50/month (ceiling $75) | — |
| Hermes NO-GO | ≥70% Tier 1+2 | <$50/month | Custom orchestration passes integration test |
| LLM NO-GO | ≥30% Tier 1 only | <$100/month | — |
| Dual NO-GO | No local target | <$150/month | Pivot Design week before Phase 3 |

If a NO-GO fires, first task on that branch: revise Phase 3–6 success criteria and task scope for the selected architecture.

---

## Cross-Project Dependencies

| ID | This project needs | From | Status |
|----|--------------------|------|--------|
| XD-024 | Phase 4 gated by eval results | tess-v2 (internal: TV2-008, TV2-016) | gated |
| XD-025 | Service continuity during migration | tess-operations | pending — existing TOP services must not be interrupted |

## Gate Structure

```
M1 (Foundation) ──┬──→ M2 (Hermes Eval) ──→ TV2-008 GO/NO-GO ──┐
                  │                                               ├──→ TV2-041 (Integration) → M4 (Architecture) → M5 (Impl+Migration) → M6 (Cutover)
                  └──→ M3 (LLM Eval) ────→ TV2-016 GO/NO-GO ───┘
```

Both gates redirect rather than block — NO-GO changes the platform/model choice, it doesn't stop the project. Dual NO-GO (both Hermes + LLM fail): combine §12.4 + §13.6 — OpenClaw + OpenRouter hybrid, with a Pivot Design week before Phase 3. Phase 3 adapts to available platform/model stack.

**Platform-agnostic work can start during evaluations:** TV2-021a (draft service interfaces) depends only on TV2-001. Contract schema shape, state machine concepts, and staging directory conventions are independent of platform/model choice.
