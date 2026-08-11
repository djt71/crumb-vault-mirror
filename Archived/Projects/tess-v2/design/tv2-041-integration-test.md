---
type: evaluation
domain: software
status: active
project: tess-v2
created: 2026-04-01
updated: 2026-04-01
skill_origin: n/a
---

# TV2-041 — Hermes + Nemotron Cascade 2 Integration Test

## Purpose

Validate that Hermes Agent can dispatch requests to the local Nemotron Cascade 2 model and receive correctly parsed structured output. This validates the two-tier architecture (cloud orchestrator + local model) before Phase 3 design begins.

## Test Environment

| Component | Detail |
|-----------|--------|
| Hermes version | v0.6.0 (LaunchAgent `ai.hermes.gateway`) |
| Hermes default model | `moonshotai/kimi-k2.5` via OpenRouter (soak test active, NOT modified) |
| Local model | Nemotron Cascade 2 30B-A3B Q4_K_M via llama-server on port 8080 |
| Local model GGUF | `nvidia_Nemotron-Cascade-2-30B-A3B-Q4_K_M.gguf` |
| llama-server | llama.cpp build, `-ngl 99 -c 65536` |
| Test date | 2026-04-01, 12:44–12:48 EDT |

## Test Methodology

### Non-Disruption Strategy

The Kimi K2.5 soak test was running (ends ~Apr 2 14:38 EDT). The default model and provider config were NOT modified.

**Routing mechanism:** Hermes supports `custom_providers` entries in `config.yaml`. A temporary entry was added:

```yaml
custom_providers:
- name: nemotron-local
  base_url: http://127.0.0.1:8080/v1
  api_key: no-key-required
```

The CLI argparse `--provider` flag has a hardcoded choice list that does not include custom providers. This was bypassed by calling `cli.main()` directly from Python with `provider='custom:nemotron-local'`. The argparse limitation is a known ergonomic gap — the underlying runtime_provider system fully supports custom providers.

The temporary config entry was removed immediately after testing. Verified: `custom_providers` absent, default model still `moonshotai/kimi-k2.5`, soak undisturbed.

### Test Phases

1. **Service health verification** — process checks and port connectivity
2. **Direct Nemotron tests** (curl to port 8080) — baseline structured output and tool-call capability
3. **Hermes-routed tests** (Hermes CLI → custom:nemotron-local) — end-to-end dispatch cycle
4. **Log and session verification** — llama-server stderr, Hermes state.db

## Results

### AC 1: Complete Dispatch Cycle

**PASS.** Four successful Hermes → Nemotron dispatch cycles completed:

| Test | Request Type | Result | Session ID |
|------|-------------|--------|------------|
| Simple math | Text response | Correct ("4") | `20260401_124547_53871c` |
| Structured JSON | JSON array output | Correct (3 objects with name/rank/reason) | `20260401_124610_1000de` |
| Tool call (date) | Terminal tool → parse output → response | Correct (returned current time) | `20260401_124720_c4fe57` |
| Tool call (file read) | Read file → extract answer | Correct ("Crumb") | `20260401_124742_0b18dc` |

All responses stored correctly in Hermes `state.db` (verified via SQLite query).

### AC 2: End-to-End Latency

#### Direct (curl → llama-server)

| Test | Prompt tokens | Completion tokens | llama-server time | Wall clock |
|------|:---:|:---:|:---:|:---:|
| Structured JSON | 69 | 131 | 1.67s | 1.73s |
| Tool call (function) | 337 | 70 | 1.10s | 1.25s |

Generation speed: ~83–88 tok/s. Prompt processing: ~1000–1300 tok/s.

#### Hermes-routed (CLI → agent init → llama-server → response)

| Test | Wall clock | Notes |
|------|:---:|-------|
| Simple math | 16.6s | Includes Python startup + agent init (~14s overhead) |
| Structured JSON | 16.3s | |
| Tool call (date) | 13.5s | Single tool round-trip |
| Tool call (file read) | 13.2s | Single tool round-trip |

**Overhead analysis:** Hermes adds 11–15s per dispatch, dominated by:
- Python interpreter startup + import chain: ~1s
- Agent initialization (system prompt assembly, tool registration, session setup): ~10–14s
- Hermes system prompt is ~20k tokens sent to Nemotron (llama-server shows 20050 prompt tokens for simple queries)

This overhead is one-time per session. In a multi-turn conversation, subsequent turns would only incur the LLM inference time (~1–2s for short responses, up to 15s for 499-token responses with large context).

### AC 3: Integration Gaps

| Gap | Severity | Detail |
|-----|----------|--------|
| CLI argparse blocks custom providers | Low | `--provider` flag has hardcoded choices. Workaround: call `main()` directly or use gateway API. Does not affect production routing (gateway uses runtime_provider directly). |
| `--model` override sends raw name to current provider | Medium | `-m custom:nemotron-local` sends the literal string to OpenRouter instead of resolving through custom_providers. The `--provider` flag is the correct path but is blocked by argparse. |
| Response duplication in quiet mode | Low (display only) | Some responses print twice in `-Q` mode. First copy sometimes truncated. Does not affect stored data — state.db has correct single response. |
| Hermes system prompt size | Informational | ~20k tokens of system prompt per request. At 83 tok/s generation + 1300 tok/s prompt processing, this adds ~15s prompt processing on first turn. Cached on subsequent turns via llama-server KV cache. |

### Reasoning/Think-Block Behavior

Nemotron Cascade 2 returns **both** `content` and `reasoning_content` fields:

```json
{
  "content": "{\"answer\": \"Paris\", ...}",
  "reasoning_content": "We need to output JSON with answer, confidence, reasoning..."
}
```

This is the ideal behavior for Hermes integration:
- `content` field is populated (not null) — the think-block fallback code path (lines 7920–7942 in `run_agent.py`) is NOT triggered
- `reasoning_content` is separately available for display when `show_reasoning: true`
- Unlike Kimi K2.5 (which sometimes puts the full response in `reasoning_content` and leaves `content` null), Nemotron correctly separates reasoning from response

**Implication:** The `reasoning_content`-as-fallback fix in `run_agent.py` is not needed for Nemotron specifically, but remains important for Kimi K2.5 and DeepSeek-R1 compatibility.

### Tool-Call Format Validation

Nemotron correctly returns OpenAI-compatible tool calls:

```json
{
  "finish_reason": "tool_calls",
  "message": {
    "tool_calls": [{
      "type": "function",
      "function": {
        "name": "get_weather",
        "arguments": "{\"location\":\"San Francisco\",\"units\":\"celsius\"}"
      },
      "id": "43Hr0J1jtRY6uLMBZHoSdLgkG7Rqdo5N"
    }],
    "reasoning_content": "We need to call get_weather with location..."
  }
}
```

Tool call IDs are generated, arguments are valid JSON strings, and `finish_reason` correctly reports `tool_calls`. Hermes parsed all tool calls without error across both direct and routed tests.

## Summary

The two-tier architecture (Hermes cloud orchestrator dispatching to local Nemotron) is **validated and functional**. The integration path works through Hermes's `custom_providers` config mechanism with `provider='custom:<name>'` routing.

Key findings for Phase 3 design:
1. **Local model dispatch works** — no code changes needed in Hermes for basic integration
2. **Latency is acceptable** — ~1–2s for simple queries (direct), ~13–16s for first-turn via Hermes (system prompt overhead)
3. **Tool calling works** — full round-trip with terminal and file tools confirmed
4. **No think-block workaround needed** — Nemotron populates `content` correctly (unlike Kimi/DeepSeek)
5. **CLI ergonomic gap** — argparse blocks `--provider custom:*` from command line; gateway routing (production path) is unaffected
6. **System prompt compression** — 20k token system prompt is the dominant latency factor for local dispatch; Phase 3 should consider a lighter system prompt for local-model delegated tasks
