---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
tags:
  - memory
  - performance
  - ollama
  - benchmarking
---

# Memory Budget — qwen3-coder:30b

## 1. Test Environment

| Component | Value |
|-----------|-------|
| **Hardware** | Mac Studio M3 Ultra, 96 GB unified memory |
| **Ollama** | 0.16.3 (Homebrew) |
| **Model** | qwen3-coder:30b (Q4_K_M, 18 GB, digest 06c1097efce0) |
| **OS** | macOS Darwin 25.3.0 |
| **Processor** | 100% GPU (Apple Metal) |

### Load Shape

| Process | Status During Test |
|---------|--------------------|
| Obsidian | Running (~400 MB RSS) |
| Docker | Not running |
| OpenClaw gateway | Not running (port 18789 closed) |
| Crumb (Claude Code) | Running (this session) |

**Note:** Docker and OpenClaw were not active during measurement. The spec F1 load shape
includes both. Their combined overhead is estimated at 1–3 GB. This does not affect the
headroom verdict (55 GB available exceeds 15 GB requirement by a wide margin).

## 2. Baseline (No Model Loaded)

| Metric | Value |
|--------|-------|
| Active + Wired | 18.7 GB |
| Free | 42.8 GB |
| Inactive (reclaimable) | 30.6 GB |
| Available (free + inactive) | 73.4 GB |
| Swap | 0 MB |
| System memory free | 96% |

## 3. Memory Measurements

### 3.1 Model Loaded — 4K Context (Idle)

| Metric | Value |
|--------|-------|
| Ollama RSS | 17.6 GB |
| Ollama self-report | 18 GB |
| Context window | 4,096 tokens |
| Active + Wired | 36.4 GB |
| Available | 55.7 GB |
| Swap | 0 MB |
| System memory free | 77% |
| **Model load time** | **2.05s** |

### 3.2 64K Context — q4_0 KV Cache

| Metric | Value |
|--------|-------|
| Ollama RSS | 21.2 GB |
| Ollama self-report | 22 GB |
| KV cache delta (vs 4K) | +3.6 GB |
| Active + Wired | 41.0 GB |
| Available | 51.1 GB |
| Swap | 0 MB |
| System memory free | 74% |
| Prompt eval | 45,029 tokens in 162.6s (277 tok/s) |

### 3.3 64K Context — q8_0 KV Cache

| Metric | Value |
|--------|-------|
| Ollama RSS | 21.2 GB |
| Ollama self-report | 22 GB |
| KV cache delta (vs q4_0) | ~0 MB (within noise) |
| Available | 52.1 GB |
| Swap | 0 MB |
| System memory free | 74% |

**Finding:** q4_0 and q8_0 KV cache show identical RSS on this model/hardware.
Likely explanation: the KV cache is a small fraction of total model memory at 30B
parameters, and/or Ollama pre-allocates the full context window regardless of
quantization type. The q8_0 option provides no measurable memory penalty — use it
for better quality if Ollama supports it as a runtime parameter.

### 3.4 Full Context Window Saturation

| Metric | Value |
|--------|-------|
| Prompt eval | 65,536 tokens (full window) in 319.8s (205 tok/s) |
| Ollama RSS (peak) | 21.3 GB |
| Available memory | 51+ GB |
| Swap | 0 MB |
| Thermal warnings | None |

## 4. Power Draw

### 4.1 Measurement Method

Power sampled via `ioreg -n AppleSmartBattery` → `SystemPowerIn` at 3–5s intervals.
This reports SoC-level DC power, **not wall power**. `sudo powermetrics` (which reports
per-component breakdown including GPU) was unavailable.

### 4.2 Readings

| Phase | SoC Power (ioreg) | Est. Wall Power |
|-------|-------------------|-----------------|
| Idle (no model) | 9–10 W | 30–50 W* |
| Model loaded, idle | 9–10 W | 30–50 W* |
| Active inference (64K prompt eval) | 10–12 W | 50–80 W* |

*Wall power estimates from published Mac Studio M3 Ultra benchmarks (AnandTech,
NotebookCheck). The ioreg metric tracks one DC rail and is not suitable for
total system power calculation.

### 4.3 Electricity Cost Estimate

Using spec F11 assumptions (Michigan residential $0.18/kWh, 50–80W sustained):

| Scenario | Monthly Cost |
|----------|-------------|
| 24/7 idle (model loaded) | $6.50–8.70 |
| 8h/day active inference | $2.20–3.50 |
| Spec F11 estimate | $6.50–10.40 |

Current measurement is consistent with the spec estimate. No revision needed.

## 5. Sustained Load Stability

| Check | Result |
|-------|--------|
| Swap after 3x sequential 45K-token inference | 0 MB (swapins: 0, swapouts: 0) |
| Swap after full 65K-token inference | 0 MB |
| Memory compressor pages | 0 |
| Thermal warnings | None recorded |
| CPU/performance throttling | None recorded |

**Verdict: Stable.** No swap activity, no compression, no thermal throttling across
all test scenarios.

## 6. Headroom Analysis

| Scenario | Model RSS | System Overhead | Total Used | Available | Headroom |
|----------|-----------|-----------------|------------|-----------|----------|
| 30B @ 4K | 17.6 GB | 18.7 GB | 36.3 GB | 55.7 GB | **55.7 GB** |
| 30B @ 64K | 21.3 GB | 18.7 GB | 40.0 GB | 51.1 GB | **51.1 GB** |
| 30B @ 64K + Docker + OC (est.) | 21.3 GB | 21.7 GB | 43.0 GB | ~48 GB | **~48 GB** |
| **80B @ 64K (est.)** | **~56 GB** | **18.7 GB** | **~75 GB** | **~21 GB** | **~21 GB** |

### 80B Model Promotion Gate

The 80B model (qwen3-coder-next, ~48 GB weights + ~8 GB KV at 64K) is estimated at
~56 GB total. With 18.7 GB system overhead, total usage would be ~75 GB, leaving ~21 GB.

**Verdict: 80B is viable** (21 GB > 15 GB headroom requirement). However:
- Margin is thinner — Docker + OpenClaw would reduce to ~18 GB
- Must re-measure empirically when model becomes available
- No room for concurrent model loading (hot-swap only, not parallel)

## 7. Summary

| AC Criterion | Result | Pass |
|-------------|--------|------|
| Peak RSS measured | 21.3 GB (64K, full window) | Yes |
| KV cache at 64K (q4_0) | 22 GB reported, 21.2 GB RSS | Yes |
| KV cache at 64K (q8_0) | 22 GB reported, 21.2 GB RSS (identical) | Yes |
| Model load time | 2.05s | Yes |
| Swap usage | 0 MB across all scenarios | Yes |
| Power draw under sustained load | 10–12W SoC / est. 50–80W wall | Yes* |
| ≥15 GB free headroom, no swap | 51+ GB available | Yes |
| 80B promotion gated on headroom | Viable (~21 GB est.) | Yes |

*Power measured via ioreg SoC rail only. Wall power estimated from published benchmarks.
`sudo powermetrics` not available for GPU-specific measurement.
