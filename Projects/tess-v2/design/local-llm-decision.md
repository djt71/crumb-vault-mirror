---
type: decision
status: active
domain: software
created: 2026-03-28
updated: 2026-03-28
project: tess-v2
task: TV2-016
skill_origin: manual
---

# TV2-016: Local LLM Go/No-Go Decision

**Decision: CONDITIONAL GO — Nemotron Cascade 2 for Tier 1+2, cloud escalation mandatory for Tier 3 (guardrails)**

## Decision Structure

This is not a clean GO or NO-GO. The local model passes the orchestration bar but hard-fails guardrails — a threshold the spec marks as non-negotiable. The architecture handles this: the three-tier model was always designed for cloud escalation on sensitive operations. The decision is GO for the local model's intended role, with cloud escalation as an architectural requirement, not a fallback.

## Evidence Summary

### Benchmark Harness (TV2-010, TV2-011)

Six candidates tested. Nemotron Cascade 2 30B-A3B Q4_K_M selected (TV2-015).

| Threshold | Required | Nemotron | Status |
|-----------|----------|----------|--------|
| tok/s ≥ 20 @ 4K | Yes | 57 | PASS |
| tok/s ≥ 10 @ 64K | Yes | 86 | PASS |
| TTFT ≤ 500ms @ 4K | Yes | 296ms | PASS |
| TTFT ≤ 2000ms @ 64K | Yes | 4166ms | FAIL |
| Tool-call ≥ 0.8 | Yes | 1.00 | PASS |
| Routing ≥ 0.8 | Yes | 0.40 | FAIL* |
| Structured output ≥ 0.8 | Yes | 1.00 | PASS |
| Guardrail = 1.0 | Yes | 0.00 | FAIL |
| Context ceiling ≥ 64K | Yes | 131K | PASS |

*Routing 0.40 is a battery calibration issue (identical across all 6 models — tool description ambiguity, not model weakness). Under investigation.

### Orchestration Tests (TV2-013)

| Criterion | Required | Result | Status |
|-----------|----------|--------|--------|
| Tests 1 & 7 tool fidelity | 5/5 | 5/5 | PASS |
| Average correctness | ≥ 4.0 | 4.0 | PASS (at threshold) |
| No test below 3 | floor | All ≥ 3 | PASS |
| Consistency (2/3 runs) | required | 3/3 all tests | PASS |
| Latency < 30s | required | All < 19s | PASS |

### Needle-in-a-Haystack Probes

| Context | Recall | Latency |
|---------|--------|---------|
| 32K | PASS | 27s |
| 64K | PASS | 85s |
| 128K | PASS (soft) | 164s |

128K answer landed in reasoning_content only (content field empty). Functional at 32K/64K. Soft degradation at 128K.

### GGUF Metadata

Native context: 1,048,576 tokens (1M). The 64K throughput jump (53→86 tok/s) is genuine MoE routing efficiency, confirmed by needle recall at all depths.

## Threshold Failures — Analysis

### Guardrail (0.00 vs 1.0 required)

All 6 local models scored 0/3 on guardrails. This is a scale-class limitation: 27-35B parameter models at Q4 quantization do not refuse dangerous requests (unauthorized email, destructive deletion, credential exposure). No local model selection could fix this.

**Architectural resolution:** Gate 3 (risk-based policy escalation) routes sensitive operations to cloud (OpenRouter) regardless of local model confidence. This was designed into the spec (§7.3, AD-009) before evaluation confirmed it was necessary. The contract runner classifies tasks by risk tier; the local model never sees guardrail-sensitive operations.

This is not a workaround — it's the intended architecture. The three-tier model separates cost-efficiency (local, Tier 1+2) from safety (cloud, Tier 3).

### TTFT @ 64K (4166ms vs 2000ms required)

Nemotron's TTFT at 64K is 2x the threshold. At 4K (296ms) and 16K (1021ms), it's well within bounds. Production orchestration prompts are typically 8-16K (system prompt + user message + tool definitions + vault context). The 64K TTFT threshold is relevant only for long-context dispatch tasks, which are infrequent and latency-tolerant.

**Architectural resolution:** The production serving config caps default context at 16K. Long-context tasks (64K+) are explicitly flagged in the contract and can tolerate higher latency. No user-facing interaction hits 64K.

### Routing (0.40 vs 0.80 required)

Identical score across all 6 models. Two specific test prompts (rt-01: vault_read vs vault_search, rt-03: escalate vs vault_search) fail for every model. This indicates ambiguous tool descriptions in the test battery, not model deficiency. The routing battery needs tool description revision before this score is meaningful.

**Resolution:** Non-blocking follow-up. Fix the tool descriptions, re-run routing prompts only.

## Known Behavioral Patterns

Two patterns identified during orchestration testing that require Phase 3 design consideration:

### 1. Tool Call Instead of Final Answer

On evaluation/classification tasks (orch-05: quality evaluation, orch-06: confidence threshold), Nemotron defers to vault_search instead of delivering its analysis as the response. The reasoning_content shows correct analysis, but the output is a tool call.

**Impact:** In a single-turn dispatch loop, the downstream system receives a search request, not the evaluation. Multi-turn loops or "produce your final answer" system prompt instructions are needed.

**Phase 3 task:** TV2-023 (system prompt architecture) must address this. Evaluation-class tasks need a prompt framing that says "analyze and respond, do not search."

### 2. 128K Reasoning Content Leak

At 128K context depth, the needle-in-a-haystack answer appeared in reasoning_content instead of content. At 32K and 64K, answers land in content correctly.

**Impact:** If the dispatch system reads content only, 128K responses are functionally empty. The contract runner must extract from reasoning_content at long contexts, or cap content-dependent dispatch at 64K.

**Phase 3 task:** TV2-023 or TV2-031b (contract runner) must handle reasoning_content extraction.

## Production Serving Profile v1

Frozen as of this decision:

```yaml
model: nvidia_Nemotron-Cascade-2-30B-A3B-Q4_K_M
runtime: llama.cpp (build 8572)
port: 8080
gpu_offload: 99 (full Metal)
default_context: 16384
max_context: 131072
concurrency: auto (n_parallel=4)
temperature: 0.0 (deterministic)
per_request_timeout: 120s
memory_baseline: ~18 GB (16K ctx), ~24 GB (128K ctx)
```

Context routing policy:
- **≤ 16K:** Default path. All standard orchestration.
- **16K–64K:** Allowed for long-context tasks. Higher latency acceptable.
- **64K–128K:** Requires explicit contract flag. Extract from reasoning_content. Monitor for quality degradation.
- **> 128K:** Route to cloud (OpenRouter). Local model untested beyond 139K.

## Conditional GO Rationale

The local model passes its intended role:
- **Tier 1 (zero-cost, mechanical):** Tool dispatch, vault operations, structured output — all 5/5 or 1.0
- **Tier 2 (low-cost, judgment):** Task triage, model routing, context packaging — 3-4/5, adequate with prompt refinement
- **Tier 3 (safety-critical):** Routed to cloud by design, never reaches local model

What "conditional" means:
- The soak test (TV2-007, 72h) must still pass before production deployment
- The guardrail architecture (Gate 3) is a requirement, not an option — deploy without it and the local model will execute dangerous requests
- The "tool call instead of final answer" pattern must be addressed in system prompt design (TV2-023)

The conditional does NOT mean "maybe." It means: GO for the local model, contingent on the architectural guardrails that the spec already requires.
