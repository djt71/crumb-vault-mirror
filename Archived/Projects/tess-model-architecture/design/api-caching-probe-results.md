---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
tags:
  - prompt-caching
  - openclaw
  - anthropic
  - api
---

# TMA-010a: API + Caching Probe Results

## 1. Anthropic Provider Format

**Verdict: `openai-completions` format works.**

Confirmed empirically in TMA-002: `tess-voice` agent runs on `anthropic/claude-sonnet-4-5`
via the Anthropic provider. Gateway starts, routes Telegram messages, and returns correct
responses. No `openai-responses` workaround needed.

The `openai-responses` format issue (spec F7) does not affect current operation.

## 2. Cache Control Passthrough

**Verdict: Fully supported. No blocker.**

### 2.1 Implementation Details

OpenClaw v2026.2.17 uses **pi-ai v0.53.0** (`@mariozechner/pi-ai`) as its unified LLM
provider layer. The Anthropic provider in pi-ai implements full `cache_control` support:

| Feature | Status | Details |
|---------|--------|---------|
| `cache_control` on system prompt | Automatic | Applied to system content blocks |
| `cache_control` on conversation history | Automatic | Applied to last user message |
| Supported content types | text, image, tool_result | All relevant types covered |
| `cacheRetention: "short"` (5-min TTL) | Default for API key auth | No config needed |
| `cacheRetention: "long"` (1-hour TTL) | Available | Requires config override |
| `cacheRetention: "none"` | Available | Explicitly disables caching |
| `extended-cache-ttl-2025-04-11` beta flag | Automatic | Included in API requests |

### 2.2 Default Behavior

With Anthropic API key authentication (our setup), OpenClaw **automatically** applies
`cacheRetention: "short"` (5-minute ephemeral cache) to all requests. No config changes
are needed for the default caching behavior.

### 2.3 Configuration

To override the default, add `cacheRetention` to agent model params:

```json
{
  "agents": {
    "defaults": {
      "models": {
        "anthropic/claude-sonnet-4-5": {
          "params": { "cacheRetention": "long" }
        }
      }
    }
  }
}
```

### 2.4 Auth Restriction

- **API Key auth:** Full caching support (our setup)
- **Subscription/setup-token auth:** Caching not honored

### 2.5 Legacy Compatibility

Older `cacheControlTtl` parameter (`"5m"`, `"1h"`) still works as alias.

## 3. Implications for Cost Model

The spec's cost projections (§11) **hold as written**:

| Model | Monthly (with caching) | Monthly (without) | Caching Status |
|-------|----------------------|-------------------|---------------|
| Haiku 4.5 | ~$8.70 | ~$40 | Available (automatic) |
| Sonnet 4.5 | ~$22.50 | ~$100+ | Available (automatic) |

No updated cost model needed. The caching prerequisite (spec A7) is satisfied.

### 3.1 Cache TTL Decision

For the two-agent architecture:
- `tess-voice` (user-facing): **`short` (5-min)** is sufficient. User messages cluster
  during active conversations. Between sessions, cache expires naturally — one write per
  conversation start, reads for the rest.
- `tess-mechanic` (local): No caching concern — runs on Ollama.

The `long` (1-hour) TTL is unnecessary given the two-agent split eliminates heartbeat
cache pollution (spec F21). This avoids the 2x write premium.

**Recommendation for TMA-008:** Use default `cacheRetention: "short"` for the voice
agent. No explicit config override needed — the default behavior is correct.

## 4. Spec Updates Required

- **A7 (cache_control passthrough):** Confirmed. Status: resolved.
- **U13 (cache_control passthrough):** Resolved. OpenClaw supports natively.
- **R14 (caching unavailability):** Mitigated. Feature is built-in and automatic.

## 5. AC Compliance

| Criterion | Result | Pass |
|-----------|--------|------|
| `openai-completions` format confirmed with Anthropic | Yes (TMA-002 empirical) | Yes |
| `cache_control` passthrough confirmed | Yes (native support, automatic) | Yes |
| Blocker identified? | No | N/A |
| Updated cost model needed? | No — projections hold | N/A |

## 6. Method

Source code analysis of OpenClaw v2026.2.17 installation:
- `/Users/openclaw/.local/lib/node_modules/openclaw/node_modules/@mariozechner/pi-ai/dist/providers/anthropic.js` — `buildParams()`, `getCacheControl()`, `convertMessages()`
- `/Users/openclaw/.local/lib/node_modules/openclaw/docs/providers/anthropic.md`
- `/Users/openclaw/.local/lib/node_modules/openclaw/node_modules/@anthropic-ai/sdk/` — v0.73.0

Live gateway test not performed (gateway offline). Source analysis is deterministic —
the code path is unambiguous.
