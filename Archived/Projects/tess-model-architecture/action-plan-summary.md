---
type: summary
project: tess-model-architecture
domain: software
skill_origin: action-architect
created: 2026-02-22
updated: 2026-02-23
source_updated: 2026-02-23
---

# Tess Model Architecture — Action Plan Summary

## Structure

3 milestones, 14 tasks (TMA-001 through TMA-012, with TMA-007 split into 007a/007b), dual critical path converging on TMA-008 (config draft). Peer-reviewed by 5 models; 8 must-fix + 6 should-fix findings applied.

## Milestones

1. **Validation & Design Documentation** — Resolve critical unknowns (U1 empirical, U2, U13). Produce design docs. Validate architecture viability. Go/no-go gate: 5 conditions (routing PoC, API compatibility, persona hard gates, memory headroom ≥15GB, caching approval).

2. **Build & Benchmark** — Local model benchmark (MC-1 through MC-6 including adversarial MC-6), system prompt optimization, production config draft. Five paths converge on TMA-008. Exit gate: MC pass rates, prompt compression, config smoke test.

3. **Integration & Measurement** — End-to-end tiered routing, Limited Mode binary checks, vault state sync validation, cost model confirmation within ±20% of projections.

## Critical Paths

- **Routing:** TMA-001 → TMA-002 → TMA-008 → TMA-009 → TMA-010b
- **API/Caching:** TMA-001 → TMA-010a → TMA-008 (parallel with routing)
- **Persona:** TMA-006 → TMA-011 → TMA-008
- **Local model:** TMA-007a → TMA-007b (with TMA-005) → TMA-008
- **Convergence:** TMA-008 requires TMA-002, TMA-004, TMA-007b, TMA-010a, TMA-011

## Immediate Starts (No Dependencies)

TMA-001 (routing spec), TMA-003 (contracts doc), TMA-004 (Limited Mode protocol), TMA-005 (memory budget), TMA-006 (persona eval), TMA-007a (harness build), TMA-012 (environment pinning) — all seven can begin in parallel.

## Key Decisions

| When | Decision |
|------|----------|
| After TMA-002 | Two-agent vs single-agent architecture (justified against criteria table) |
| After TMA-006 | Haiku vs Sonnet vs mixed tier |
| After TMA-006 | Architecture viability (if neither model passes Persona Contract) |
| After TMA-010a | Caching path (requires operator approval if degraded) |
| After TMA-007b | KV cache quantization (q4_0 vs q8_0) |

## Key Changes from Peer Review (R1)

| Change | Source |
|--------|--------|
| TMA-010a parallel with TMA-002 (dep → TMA-001) | 4/5 reviewers |
| TMA-002 AC: 5-scenario test matrix incl. Limited Mode + session isolation | 4/5 + Perplexity |
| TMA-006 AC: 100% hard gate pass, ≥5 cases/dimension, structured recording | 4/5 reviewers |
| TMA-005 added to Milestone 1 go/no-go gate (≥15GB headroom, no swap) | 3/5 reviewers |
| TMA-004 added as TMA-008 dependency (Limited Mode → config) | 3/5 reviewers |
| Milestone 1 gate: caching approval required if degraded | 2/5 reviewers |
| TMA-007 split into 007a (build, no deps) + 007b (execute, deps TMA-005) | 3/5 reviewers |
| TMA-007b added as TMA-008 dependency (quant decision → config) | Grok unique |
| Milestone 2 exit gate added (MC pass + prompt compression + config smoke test) | OpenAI |
| TMA-011 added as TMA-009 dependency (compressed prompt for integration) | DeepSeek unique |
| TMA-007b AC: CLI gate procedure, documented run/interpret/fail protocol | Perplexity |
| TMA-009 AC: ≥20 req/path, binary Limited Mode checks, timestamp methodology | Perplexity |

## Risk Notes

- TMA-002 and TMA-010a validate against third-party software — budget 3–6 live iterations (Pattern 4)
- TMA-006 is calendar-critical (requires operator interaction across 2–3 sessions; findings may feed back to TMA-001/TMA-004)
- No estimation calibration history — tracking actuals vs planned from this project forward
- TMA-008 convergence point has 5 inbound dependencies — schedule risk if any path delays
