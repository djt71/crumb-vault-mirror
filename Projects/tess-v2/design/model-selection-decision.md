---
type: decision
status: active
domain: software
created: 2026-03-28
updated: 2026-03-28
project: tess-v2
task: TV2-015
skill_origin: manual
---

# TV2-015: Single vs. Dual Model Decision

**Decision: Single model — Nvidia Nemotron Cascade 2 30B-A3B Q4_K_M**

## Data Summary

Six candidates benchmarked on Mac Studio M3 Ultra (96GB) using the tess-v2 benchmark harness (21 prompts, 5 categories, throughput at 4 context lengths). All models run through identical battery with the Tess orchestrator system prompt and full tool definitions.

### Quality (discriminating categories only)

Three models tie at the top on tool-call + structured output:

| Model | Tool-call | Structured | Routing | Guardrail |
|-------|-----------|------------|---------|-----------|
| Nemotron Cascade 2 | 1.00 | 1.00 | 0.40 | 0.00 |
| Qwen3.5 27B Q6_K | 1.00 | 1.00 | 0.40 | 0.00 |
| Qwen3.5 35B MoE | 1.00 | 1.00 | 0.40 | 0.00 |
| Qwen3.5 27B Q4_K_M | 0.80 | 1.00 | 0.40 | 0.00 |
| GLM-4.7-Flash | 0.80 | 0.60 | 0.40 | 0.00 |
| Qwen3-Coder 30B | 0.80 | 0.40 | 0.50 | 0.00 |

Multi-step scores (0.32 across all models) excluded — scorer bug confirmed. The multi-step scorer checks `content` for numbered steps but models respond via `reasoning_content` + tool calls. Scoring fix is non-blocking follow-up.

Routing scores (0.40 across all models) may reflect ambiguous tool descriptions (vault_read vs vault_search) rather than model weakness. Battery investigation is a non-blocking follow-up.

### Throughput

| Model | tok/s 4K | tok/s 64K | tok/s 128K | TTFT 4K | Memory 128K |
|-------|----------|-----------|------------|---------|-------------|
| **Nemotron Cascade 2** | 57 | **86** | **86** | **296ms** | 24.1 GB |
| GLM-4.7-Flash | **70** | 51 | 42 | 413ms | 23.9 GB |
| Qwen3.5 27B Q4_K_M | 25 | 26 | 25 | 1788ms | 24.7 GB |
| Qwen3.5 27B Q6_K | 22 | 13 | 21 | 1513ms | 30.2 GB |

Qwen3.5 35B MoE and Qwen3-Coder: quality-only runs. Throughput not measured. The 35B MoE ties on quality but would need to exceed Nemotron's 86 tok/s at 128K to change the decision — unlikely for a 35B-param MoE.

### Threshold Compliance

| Threshold | Required | Nemotron |
|-----------|----------|----------|
| tok/s ≥ 20 @ 4K | Yes | 57 — PASS |
| tok/s ≥ 10 @ 64K | Yes | 86 — PASS |
| TTFT ≤ 500ms @ 4K | Yes | 296ms — PASS |
| TTFT ≤ 2000ms @ 64K | Yes | 4166ms — FAIL |
| Tool-call ≥ 0.8 | Yes | 1.00 — PASS |
| Routing ≥ 0.8 | Yes | 0.40 — FAIL* |
| Structured ≥ 0.8 | Yes | 1.00 — PASS |
| Guardrail = 1.0 | Yes | 0.00 — FAIL |
| Context ceiling ≥ 64K | Yes | 131K — PASS |

*Routing failure is battery-wide (all models identical) — likely tool description ambiguity, not model deficiency. Under investigation.

## Rationale

### Why single model

The spec's dual-stack threshold: "Dual stack justified only if GLM ≥ Qwen3.5 on Tier 1 AND ≥2x faster." GLM has worse quality (0.60 structured output vs 1.00) and Nemotron beats it on speed at 64K+ contexts. No candidate combination justifies the routing complexity of a dual stack. Single model wins per the tie-break rule: "bias toward single model (simplicity)."

### Why Nemotron

1. **Throughput is commanding.** 2-3x faster than dense Qwen models at generation. 86 tok/s at 128K context — gets faster at longer contexts (though the discrete jump at 64K needs soak test confirmation under production-like prompts vs. repeated pangrams).
2. **Quality ties the best.** 5/5 tool-call, 5/5 structured output — matches Q6_K and 35B MoE.
3. **Only model passing TTFT threshold at 4K.** 296ms vs 500ms limit. GLM is close (413ms), everything else fails.
4. **Memory efficient.** 24.1 GB at 128K context — comparable to GLM, lighter than Q6_K (30.2 GB).
5. **MoE architecture.** 30B params, 3B active — explains the speed. Production-relevant: lower per-request compute cost.

### Caveats

1. **The 64K throughput jump needs validation.** 53 → 86 tok/s between 16K and 64K is a discrete shift, not smooth scaling. GGUF metadata confirms native context is 1,048,576 (1M tokens) — so 128K is only 12% of capacity, ruling out the "model giving up at the edge of its window" explanation. More likely a genuine MoE routing efficiency shift. However, native context length doesn't guarantee attention quality — a model can have a 1M window and still lose retrieval accuracy well below it. TV2-013 includes a needle-in-a-haystack probe at 32K/64K/128K to determine whether throughput acceleration correlates with attention degradation.
2. **Guardrails are a class-level failure.** 0/3 across all 6 candidates. Not a model selection factor — this is an architecture requirement (Gate 3 escalation-to-cloud for sensitive operations).
3. **TTFT fails at 64K** (4166ms vs 2000ms threshold). Acceptable for orchestration workloads where most prompts are <16K. Production serving config should set context ceiling conservatively.
4. **Routing scores are suspect.** 0.40 across all models suggests tool description ambiguity, not model weakness. Fix the battery before reading routing as a model limitation.

## Architecture Implications

- **Serving config v1:** Nemotron Cascade 2 30B-A3B Q4_K_M, port 8080, 16K default context (expandable to 128K for long-context tasks), Metal GPU offload
- **Guardrail enforcement:** External, not model-level. Contract runner's risk-based policy gate routes sensitive operations to cloud (OpenRouter) regardless of local model confidence
- **Soak test:** Switched to Nemotron. 72-hour clock started 2026-03-28 ~17:42 EDT. Target end: 2026-03-31 ~17:42 EDT

## Non-Blocking Follow-ups

1. **Fix multi-step scorer** — check `reasoning_content` and tool call sequences, not just `content` for numbered steps (~30 min fix)
2. **Investigate routing battery** — check rt-01/rt-03 tool descriptions for vault_read vs vault_search ambiguity, re-run routing prompts if descriptions are unclear
3. **Qwen3.5 35B MoE throughput** — run throughput battery to close the data gap (won't change decision but completes the record)
