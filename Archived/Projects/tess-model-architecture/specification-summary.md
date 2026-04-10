---
type: summary
project: tess-model-architecture
domain: software
skill_origin: systems-analyst
created: 2026-02-22
updated: 2026-02-22T23:30
source_updated: 2026-02-22T23:30
tags:
  - local-llm
  - tess
  - openclaw
  - model-selection
  - tiering
  - routing
---

# Tess Model Architecture — Specification Summary

## Core Content

Tess needs a model architecture that preserves persona fidelity (SOUL.md) while running cost-effectively on shared hardware (Mac Studio M3 Ultra 96GB). The solution is a **personality-first tiered architecture** using a **two-agent split**: `tess-voice` (cloud, Haiku 4.5) handles all user-facing Telegram interactions with full persona; `tess-mechanic` (local, qwen3-coder:30b) handles mechanical background tasks — heartbeats, cron, file ops, structured extraction.

The architecture went through three iterations: cloud-primary (research thread, 5-model peer review) → local-first (Revision 1, independence concern) → cloud-primary restored (Revision 2, after cost analysis showed negligible delta at ~$8.70/month Haiku vs ~$6.50–10.40/month electricity). Local model serves as a resilience fallback via **Limited Mode** — automatically triggered on API outage, with degradation banner and scope reduction. Anthropic is the single critical vendor for Tess's core value (persona, judgment, second register) — Limited Mode bounds the blast radius but does not eliminate the dependency.

Routing research identified the two-agent split as the recommended implementation, sidestepping three confirmed model override bugs in OpenClaw. Per-agent model assignment with channel bindings is the most reliable routing mechanism. The split also eliminates heartbeat cache pollution. For mixed-task requests (mechanical retrieval + persona summary), a delegation fallback allows `tess-voice` to call Ollama directly if inter-agent delegation is unavailable, with all safety contracts (MC-6) applying regardless of call path. All cross-agent state is vault-file based (A8) — neither agent relies on the other's in-memory sessions.

Design evaluation uses two contracts: a **Mechanical Contract** (≥95% JSON validity, <5s latency, schema adherence, confirmation echo compliance) for the local model, and a **Persona Contract** (SOUL.md fidelity, tone-shift judgment, safe ambiguity handling) for the cloud model. MC-6 (confirmation echo) is a three-layer safety invariant: negative requirement (model never initiates destructive actions), token authority (bridge generates/validates), and system enforcement (bridge rejects without valid token, independent of model output). If neither Haiku nor Sonnet passes the Persona Contract, the architecture is invalid and must be revisited.

## Key Decisions

- Cloud-primary for user-facing, local for mechanical (personality-first tiering)
- Two-agent split (`tess-voice` + `tess-mechanic`) via per-agent model with channel bindings
- No thinking model — hard blocker (developer role bug) + architectural mismatch (latency)
- Coder model family for local — IF scores are the primary selection metric for mechanical work
- Limited Mode elevated from risk entry to first-class design requirement
- Prompt caching is a prerequisite, not an optimization — without it costs balloon 4.5x
- GLM-4.7-flash quarantined (Ollama template issues), not abandoned
- Anthropic as single critical vendor — conscious trade-off, not a solved problem

## Interfaces & Dependencies

- **OpenClaw v2026.2.17** — gateway hosting both agents, mixed providers (Anthropic + Ollama)
- **Ollama** — local model serving, `openai-completions` format, custom Modelfile with `num_ctx 65536`
- **Anthropic API** — Haiku 4.5 (Tier 1), Sonnet 4.5 (Tier 3), prompt caching required
- **Crumb-Tess Bridge** — confirmation echo (MC-6) is a three-layer system safety invariant; bridge is token authority
- **SOUL.md / IDENTITY.md** — persona definitions loaded by `tess-voice` only

## Open Unknowns (13 total)

- **Critical:** U1 partially resolved (two-agent mechanism identified, empirical validation pending); U2 API format issue (pre-implementation gate); U13 cache_control passthrough (pre-implementation gate, promoted from Medium)
- **High:** U3 Haiku persona fidelity untested; U4 JSON validity rate unverified; U9 inter-agent delegation uncertain
- **Medium:** U6 memory measurements theoretical; U10 shared vs per-agent memory; U11 mixed-provider gateway; U12 routing bugs may be fixed

## Risk Register (14 items)

- **Critical→High:** R1 routing (partially de-risked by two-agent research)
- **High:** R5 KV cache truncation, R10 confirmation echo bypass, R14 cache_control passthrough
- **Medium:** R2 API outage (mitigated by Limited Mode), R3 memory contention, R4 API format, R6 Haiku persona, R7 thermal, R8 JSON validity, R11 Limited Mode degradation, R12 two-agent complexity, R13 inter-agent delegation
- **Low:** R9 API cost

## Task Decomposition (12 tasks)

**Critical path (routing):** TMA-001 (routing spec) → TMA-002 (routing PoC) → TMA-010a (API + caching probe) → TMA-008 (config draft) → TMA-009 (integration test) → TMA-010b (cost measurement)
**Critical path (persona):** TMA-006 (persona eval) → TMA-011 (prompt optimization) → TMA-008 (config draft)
**Parallel tracks:** TMA-003 (contracts doc), TMA-004 (Limited Mode spec), TMA-005 (memory budget) → TMA-007 (benchmark harness)

TMA-008 (config draft) is the convergence point — three inbound dependencies: TMA-002 (routing), TMA-010a (API/caching validation), and TMA-006 → TMA-011 (persona → prompt). TMA-010 was split into 010a (pre-config gate) and 010b (post-integration measurement) per peer review.

## Next Actions

1. Execute SPECIFY → PLAN phase transition gate
2. Begin TMA-001 (routing specification) — routing critical path first step
3. Run TMA-006 (persona eval) and TMA-005 (memory budget) in parallel — no dependencies, both feed downstream tasks

## Evidence Base

6 design documents: research thread, cost analysis, Revision 1 (withdrawn), Revision 2 (current), routing research, prompt caching research. Plus SOUL.md and IDENTITY.md (external). Peer review: `_system/reviews/2026-02-22-tess-model-architecture-specification.md` (5 reviewers, 6 must-fix applied).
