---
project: tess-v2
domain: software
type: reference
status: active
created: 2026-03-28
updated: 2026-03-28
skill_origin: null
tags:
  - evaluation
  - local-llm
  - benchmark
---

## Local Model Evaluation Protocol

### Purpose

Standardized, repeatable benchmark harness for evaluating local LLM candidates on the Mac Studio M3 Ultra (96GB unified memory). Produces a per-model scorecard that answers one question: **is this model viable for Tess v2 orchestration on this hardware?**

This is not a general LLM benchmark. It tests the specific capabilities Tess needs from an orchestration model: fast structured output, reliable tool-call formatting, accurate routing decisions, and acceptable latency across realistic context windows.

### Design Principles

- **Runs on our hardware, with our workloads.** No translating from someone else's 3090 numbers.
- **Single entry point.** `benchmark-model.sh <path-to-gguf>` → scorecard row in SQLite.
- **Repeatable.** Same GGUF, same machine state → same results (within thermal variance). Pin llama.cpp version per eval round.
- **Earns its ceremony.** Shell script + SQLite + a small prompt battery. No framework, no dashboard until the data justifies one.

### Test Battery

The battery has two halves: **throughput** (mechanical, automated) and **quality** (prompt-based, scored).

#### 1. Throughput Tests

Run via `llama-bench` or equivalent llama.cpp tooling.

| Metric | Method | Context lengths |
|---|---|---|
| Tokens/sec (generation) | `llama-bench -t` with fixed prompt/gen lengths | 4K, 16K, 64K, 128K |
| Time-to-first-token (TTFT) | Measure latency from request to first generated token | 4K, 16K, 64K, 128K |
| Peak memory (RSS) | Monitor via `memory_pressure` or `vm_stat` during generation | At each context length |
| Context ceiling | Binary search for max context before OOM or >50% speed degradation | — |

**Why these context lengths:** 4K = typical short dispatch. 16K = conversation with tool results. 64K = multi-step agent session. 128K = stress test / long coding context.

**Thermal note:** Run throughput tests after a 60-second idle cooldown between context lengths. The M3 Ultra throttles under sustained load; inconsistent thermal state poisons the numbers.

#### 2. Quality Tests

A fixed battery of prompts that exercise Tess orchestration capabilities. Each prompt is stored in `_eval/prompts/` and scored against defined criteria.

| Test | What it measures | Pass criteria |
|---|---|---|
| **Tool-call formatting** (5 prompts) | Can the model produce correctly structured tool calls in the format Tess expects? | 5/5 parseable, 4/5 semantically correct |
| **Routing decision** (5 prompts) | Given a user intent + available executor descriptions, does the model route to the right executor? | 4/5 correct routing |
| **Structured output** (5 prompts) | Can the model reliably produce valid JSON/YAML when instructed? | 5/5 valid parse, 4/5 schema-conformant |
| **Multi-step plan** (3 prompts) | Given a compound task, does the model decompose it into a sensible execution plan? | Evaluated qualitatively — scored 1-5 by reviewer |
| **Refusal/guardrail** (3 prompts) | Does the model correctly refuse or escalate out-of-scope requests? | 3/3 correct behavior |

**Prompt design rules:**
- Prompts are version-controlled alongside the harness. Changing a prompt invalidates prior scores for that test.
- Each prompt includes the system prompt the Tess orchestrator would actually use — this is testing the model *in situ*, not in a vacuum.
- Quality tests run at 4K context only (isolate quality from context-length effects).

### Scorecard Schema

Results land in a SQLite table. One row per model evaluation run.

```sql
CREATE TABLE model_eval (
    id              INTEGER PRIMARY KEY AUTOINCREMENT,
    run_ts          TEXT NOT NULL,           -- ISO 8601 timestamp
    model_name      TEXT NOT NULL,           -- e.g. 'qwen3.5-27b-dense'
    quant           TEXT NOT NULL,           -- e.g. 'Q4_K_M'
    gguf_path       TEXT NOT NULL,
    gguf_sha256     TEXT NOT NULL,           -- reproducibility
    llamacpp_version TEXT NOT NULL,          -- pin the runtime
    -- throughput
    toks_4k         REAL,
    toks_16k        REAL,
    toks_64k        REAL,
    toks_128k       REAL,
    ttft_4k_ms      REAL,
    ttft_16k_ms     REAL,
    ttft_64k_ms     REAL,
    ttft_128k_ms    REAL,
    peak_mem_4k_gb  REAL,
    peak_mem_128k_gb REAL,
    context_ceiling INTEGER,                -- max tokens before OOM or >50% degradation
    -- quality (scores as fractions, e.g. 0.8 = 4/5)
    tool_call_score     REAL,
    routing_score       REAL,
    structured_output_score REAL,
    multi_step_score    REAL,               -- average of 1-5 ratings, normalized 0-1
    guardrail_score     REAL,
    -- composite
    viable          INTEGER DEFAULT 0,      -- 1 if meets all pass thresholds
    notes           TEXT
);
```

### Pass/Fail Thresholds

Some thresholds are known from Tess requirements. Others need a baseline round to calibrate.

| Metric | Threshold | Rationale |
|---|---|---|
| tok/s @ 4K | ≥ 20 tok/s | Below this, dispatch feels laggy for interactive use |
| tok/s @ 64K | ≥ 10 tok/s | Agent sessions can tolerate more latency |
| TTFT @ 4K | ≤ 500ms | Perceived responsiveness for voice/interactive |
| TTFT @ 64K | ≤ 2000ms | Acceptable for background agent work |
| Tool-call formatting | ≥ 0.8 | Non-negotiable for orchestration — bad tool calls = broken dispatch |
| Routing accuracy | ≥ 0.8 | Mis-routing wastes executor tokens |
| Structured output | ≥ 0.8 | Must produce parseable output reliably |
| Guardrail | = 1.0 | Must refuse/escalate correctly every time |
| Multi-step planning | ≥ 0.6 (3/5 avg) | TBD — calibrate after first round |
| Context ceiling | ≥ 64K | Minimum for multi-step agent sessions |

**`viable` flag:** Set to 1 only if ALL thresholds pass. A model can be fast but unreliable, or high-quality but too slow — both fail.

### Execution Workflow

```
benchmark-model.sh <path-to-gguf>
  ├── validate GGUF exists, compute sha256
  ├── detect llama.cpp version
  ├── run throughput suite (llama-bench, 4 context lengths)
  │     └── capture tok/s, TTFT, peak memory at each
  ├── find context ceiling (binary search)
  ├── run quality suite (21 prompts via llama-cli or server API)
  │     └── score each against criteria, log raw outputs
  ├── compute composite scores
  ├── insert row into model_eval.db
  └── print scorecard summary to stdout
```

Raw prompt outputs are saved to `_eval/runs/<model>-<timestamp>/` for post-hoc review.

### Known Candidates (Initial Round)

| Model | Quant | Why test it |
|---|---|---|
| Qwen 3.5 27B dense | Q4_K_M | Current leading candidate per research; strong tool-call reputation |
| Qwen 3.5 27B dense | Q6_K | Unified memory means we can afford the extra quality — worth measuring the delta |
| Qwen 3.5 35B MoE | Q4_K_M | Speed comparison vs dense; does MoE routing hurt tool-call reliability? |
| Nemotron Cascade 2 | IQ4_XS | High tok/s reports; needs quality validation on our workloads |
| Qwen3-coder 30B | Q4_K_M | Already deployed as tess-mechanic; establish baseline for comparison |

### Open Questions

- **Inference backend:** llama.cpp is the default. MLX is the Apple-native option and may extract more from the M3 Ultra's GPU cores. Worth running the same battery on both backends for at least one model to quantify the difference. If MLX wins significantly, the whole harness should support both.
- **Thermal stability protocol:** Need to determine whether a 60-second cooldown is sufficient or if we need longer recovery between runs. First round will include thermal monitoring to calibrate this.
- **Quality scoring automation:** Tool-call and structured output tests can be scored mechanically (parse success, schema validation). Routing and multi-step planning currently need human review. Consider using a strong model (Claude via API) as an auto-scorer for the qualitative tests — but only after validating scorer agreement with human judgment on the first round.
- **Continuous vs one-shot:** The harness is designed to be repeatable. Whether it becomes a scheduled capability (e.g., Tess auto-benchmarks new GGUF drops) depends on how often the model landscape shifts. Current pace suggests monthly at minimum.
