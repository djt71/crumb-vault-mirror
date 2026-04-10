---
type: action-plan
project: tess-model-architecture
domain: software
skill_origin: action-architect
created: 2026-02-22
updated: 2026-02-23
status: active
tags:
  - local-llm
  - tess
  - openclaw
  - model-selection
  - routing
---

# Tess Model Architecture — Action Plan

## Overview

Three milestones decompose the specification into executable phases. The dual critical path (routing + persona) runs in parallel; TMA-008 (config draft) is the convergence point where all paths meet. All critical unknowns (U1 empirical, U2, U13) must resolve before implementation proceeds.

**Scheduling principles:**
- Critical path first — routing PoC (TMA-001 → TMA-002) and API probe (TMA-001 → TMA-010a) run in parallel after routing spec
- Calendar-critical — TMA-006 (persona eval) requires operator interaction; start early, expect elapsed time across 2–3 sessions. Findings may feed back into TMA-001 (routing assumptions) and TMA-004 (Limited Mode prompt constraints)
- Live deployment iteration — budget 3–6 iterations for first PoC setup per Pattern 4 (`_system/docs/solutions/claude-print-automation-patterns.md`)
- Writing tasks front-loaded — TMA-001, TMA-003, TMA-004, TMA-007a, TMA-012 have no dependencies; start immediately

**Estimation baseline:** No calibration history exists for this project type. Track actual effort vs planned for each task to seed `_system/docs/estimation-calibration.md`.

## Milestone 1: Validation & Design Documentation

**Objective:** Resolve all critical unknowns. Produce design docs that define test criteria. Validate architecture viability with empirical evidence.

**Success criteria:**
- Routing PoC passes — two-agent or single-agent path selected with evidence against TMA-001 criteria table
- API format validated (U2 resolved)
- `cache_control` passthrough confirmed, or updated cost model produced and explicitly approved by operator (U13 resolved)
- Memory budget measured empirically — stable at 64K context, no swap, ≥15GB headroom (A5 validated or revised)
- Persona eval started or completed (A2 test underway)
- All writing-phase design docs complete and linked from spec

**Go/no-go gate:** STOP and reassess architecture if any of:
1. TMA-002 fails (no working routing mechanism)
2. TMA-010a reveals a fundamental API incompatibility
3. TMA-006 shows neither Haiku nor Sonnet passes Persona Contract hard gates (architecture invalid per §8.2)
4. TMA-005 shows insufficient memory headroom (<15GB free) or swap activity under defined load shape
5. Caching is unavailable and operator has not approved the updated uncached cost model

### Phase 1A: Parallel Kick-off

Start immediately. No dependencies. Writing tasks plus benchmark harness scaffolding.

| Task | Deliverable | Risk |
|------|-------------|------|
| TMA-001 | Routing specification (two-agent split) — includes "simpler path" criteria table and delegation test scenarios | High |
| TMA-003 | Design contracts reference doc (MC + PC) | Low |
| TMA-004 | Limited Mode protocol (includes scope enforcement + duration cap — absorbs review A8) | Medium |
| TMA-007a | Benchmark harness build (scaffold, test definitions, MC-6 adversarial suite) | Medium |
| TMA-012 | Environment pinning & rollback plan (review A13) | Low |

### Phase 1B: Parallel Research

Start immediately alongside Phase 1A. No dependencies. Both feed downstream tasks.

| Task | Deliverable | Risk | Note |
|------|-------------|------|------|
| TMA-005 | Memory budget — empirical measurements | Medium | Unblocks TMA-007b. Gate for Milestone 1 |
| TMA-006 | Persona fidelity test — Haiku vs Sonnet | Medium | Calendar-critical (operator interaction, 2–3 sessions). Unblocks TMA-011. Findings may feed back into TMA-001/TMA-004 |

### Phase 1C: Routing & API Validation (Parallel)

Start when TMA-001 completes. TMA-002 and TMA-010a run **concurrently** — the API probe needs only minimal gateway setup, not a validated routing PoC.

| Task | Deliverable | Depends On | Risk |
|------|-------------|------------|------|
| TMA-002 | Routing PoC — validated routing path with 5-scenario test matrix | TMA-001 | Critical |
| TMA-010a | API format + `cache_control` validation | TMA-001 | High |

Budget 3–6 live iterations for TMA-002 (Pattern 4). First: test if F16 bugs are fixed. Then: validate two-agent config OR single-agent + `modelByChannel` — path selected against TMA-001 criteria table. TMA-010a uses a minimal throwaway config to probe Anthropic API independently.

If caching is unavailable (TMA-010a): produce updated cost model and get explicit operator approval before proceeding to Milestone 2.

## Milestone 2: Build & Benchmark

**Objective:** Build the benchmark harness, optimize the system prompt, and draft the production config. All paths converge on TMA-008.

**Success criteria:**
- Local model passes Mechanical Contract (MC-1 through MC-6) including adversarial MC-6 tests
- System prompt compressed to target range (3,500–6,000 tokens from ~9,500)
- `tess-mechanic` minimal identity doc written (~200–300 tokens)
- Config draft complete with all routing, model, caching, and Limited Mode settings
- Benchmark harness documented as re-runnable gate procedure (for model/quantization changes — absorbs review A11)

**Preconditions:** Milestone 1 go/no-go gate passed (all 5 conditions satisfied).

**Exit gate (required before Milestone 3):**
1. MC-1 through MC-6 pass rates meet thresholds (TMA-007b results)
2. Prompt token count within target range (3,500–6,000) and PC hard gates unchanged after compression (TMA-011)
3. Config smoke-tested per route — each routing path returns expected model responses (TMA-008)

### Phase 2A: Prompt Optimization & Benchmark Execution (Parallel)

Two independent tracks that can run in parallel.

| Task | Deliverable | Depends On | Risk |
|------|-------------|------------|------|
| TMA-011 | Compressed SOUL.md + mechanic identity doc | TMA-006 | Medium |
| TMA-007b | Benchmark execution + MC-1 through MC-6 results | TMA-005, TMA-007a | High |

### Phase 2B: Configuration (Convergence Point)

Five inbound dependencies — all must complete before config is finalized.

| Task | Deliverable | Depends On | Risk |
|------|-------------|------------|------|
| TMA-008 | Production `openclaw.json` + Modelfile + env vars | TMA-002, TMA-004, TMA-007b, TMA-010a, TMA-011 | Medium |

TMA-008 can start drafting with provisional values once TMA-002 and TMA-010a complete, but finalization requires TMA-004 (Limited Mode protocol for fallback chains), TMA-007b (quantization/KV cache decision), and TMA-011 (compressed prompt). Config must also embed the persona-tier decision outcome from TMA-006 (model mix, Persona Contract references).

## Milestone 3: Integration & Measurement

**Objective:** End-to-end validation of the complete tiered architecture. Confirm cost model with production traffic.

**Success criteria:**
- Human-clock message → cloud model → persona response (verified)
- Machine-clock task → local model → structured output (verified)
- Limited Mode trigger → fallback → recovery (verified, with binary per-scenario checks)
- Vault-based state sync verified — mechanic's actions discoverable by voice via vault/inbox state only (A8)
- No Limited Mode response uses disallowed tools
- Duration cap enforced in all test runs
- Actual costs within ±20% of projected range (§11)
- Latency within SLOs: p95 <10s cloud, <15s Limited Mode (measured over ≥20 requests per path)

### Phase 3A: Integration Test

| Task | Deliverable | Depends On | Risk |
|------|-------------|------------|------|
| TMA-009 | Integration test results (all routing paths + state sync + Limited Mode) | TMA-008, TMA-011 | High |

Budget 3–6 iterations (Pattern 4). This is the first time all components run together.

### Phase 3B: Cost Measurement

| Task | Deliverable | Depends On | Risk |
|------|-------------|------------|------|
| TMA-010b | Actual cost vs projected cost measurements | TMA-009 | Medium |

## Decision Points

| Decision | When | Options | Impact |
|----------|------|---------|--------|
| Two-agent vs single-agent | After TMA-002 | Keep two-agent split OR simplify to single-agent (if bugs fixed + `modelByChannel` works) — justified against TMA-001 criteria table | Architecture complexity, maintenance burden |
| Haiku vs Sonnet vs mixed | After TMA-006 | Haiku only, Sonnet only, or mixed tier | Cost model ($8.70 vs $22.50/mo), prompt optimization target |
| Architecture viability | After TMA-006 | Proceed OR revisit (if neither model passes Persona Contract hard gates) | Full project pivot |
| Caching path | After TMA-010a | Native passthrough, middleware, feature request, or accept uncached costs — requires operator approval if degraded | Cost model ($8.70 vs $40/mo), deployment timeline |
| KV cache quantization | After TMA-007b | q4_0 (aggressive) or q8_0 (conservative) | Memory budget, potential quality uplift for structured output |

## Peer Review Should-Fix Integration

Items from the specification peer review absorbed into task acceptance criteria rather than creating separate tasks:

| Review Item | Absorbed Into | How |
|-------------|---------------|-----|
| A7 — R14 severity (hybrid position) | specification.md | Applied during SPECIFY phase — R14 escalated to HIGH with "Architectural Assumption Risk" label |
| A8 — Limited Mode scope enforcement + duration cap | TMA-004 | AC includes enforcement mechanism, reduced tool allowlist, duration cap, prompt-enforced advice prohibition |
| A9 — U1 reclassification | specification.md | Applied during SPECIFY phase — strikethrough removed, reclassified |
| A10 — U12 explicit + interim label | specification.md | Applied during SPECIFY phase — two-agent split labeled as interim architecture |
| A11 — Local model regression risk | TMA-007b | AC requires re-runnable harness with gate procedure; harness gates all future model/quantization changes |
| A12 — User-facing latency SLOs | TMA-009 | AC includes p95 latency targets with measurement methodology (≥20 requests per path) |
| A13 — Environment pinning & rollback | TMA-012 | New task created |

Deferred items (A14–A22) remain in the review note for post-deployment consideration. None block implementation.

## Dependency Graph

```
Start ──┬── TMA-001 ──┬── TMA-002 ──────────────────────────────┐
        │             └── TMA-010a ──────────────────────────────┤
        ├── TMA-003 (independent)                                │
        ├── TMA-004 ─────────────────────────────────────────────┤
        ├── TMA-007a ───────────────────────────┐                │
        ├── TMA-012 (independent)               │                │
        │                                       │                │
        ├── TMA-005 ──────────────── TMA-007b ──┤                │
        └── TMA-006 ──┬── TMA-011 ─────────────┤                │
                       │                        │                │
                       └────────────────────────┤ (model decision)
                                                │
                                    TMA-008 ◄───┘ (convergence)
                                       │
                                    TMA-009 ──── TMA-010b
```
