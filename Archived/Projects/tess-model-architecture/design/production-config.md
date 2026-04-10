---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-23
updated: 2026-02-23
tags:
  - openclaw
  - config
  - production
  - deployment
---

# Production Config — TMA-008

## 1. Config Overview

Production `openclaw.json` for the tiered two-agent architecture. Config file:
`design/openclaw-config-production.json` (credentials redacted — deploy with live values).

### Architecture Summary

| Agent | Model | Role | Channel |
|-------|-------|------|---------|
| `voice` (default) | `anthropic/claude-haiku-4-5` | User-facing — Telegram, persona | telegram |
| `mechanic` | `ollama/tess-mechanic:30b` | Background — heartbeats, cron, tools | unbound |

### Persona-Tier Decision

Voice runs on Haiku 4.5 per TMA-006 evaluation. Haiku matches Sonnet on voice fidelity
(PC-1: 100%), tone-shift (PC-2: 100%), and second register (PT-4: 100%), but outperforms
on ambiguity handling (PC-3: 100% vs 71%). Cost: ~$8.70/mo with caching (vs ~$22.50 Sonnet).

## 2. Key Config Decisions

### 2.1 Agent Definitions (from TMA-002)

Two-agent split confirmed. Single-agent path untestable (v2026.2.21 blocked on #22841).
Two-agent wins on session isolation, cache behavior, identity separation.

### 2.2 Model Assignments

| Agent | Primary | Fallback | Notes |
|-------|---------|----------|-------|
| voice | `anthropic/claude-haiku-4-5` | `ollama/tess-mechanic:30b` | Fallback = Limited Mode (TMA-004). `model.fallbacks` does NOT auto-failover for provider-down (TMA-002 FB-3). Health-check cron required. |
| mechanic | `ollama/tess-mechanic:30b` | `anthropic/claude-haiku-4-5` | Fallback is cosmetic for provider-down per FB-3. May work for model-level errors. Haiku chosen for cost-efficient background recovery. |

### 2.3 Channel Bindings

Telegram → voice (persona). Mechanic is unbound — handles heartbeats and background work only.
Unknown channels route to voice (default agent = fail safe to persona).

### 2.4 Fallback Chains + Limited Mode (from TMA-004)

`model.fallbacks` arrays are retained but cannot be relied on for provider-down resilience
(TMA-002 §4.2). Limited Mode requires external health-check cron:

**Entry:** Health-check cron detects Anthropic failure → atomic config swap (model + identity
doc + tools) → gateway reload → degradation banner.

**Exit:** Health-check detects recovery → reverse swap → gateway reload → recovery notification.

**Tool restriction:** `tools.byProvider.ollama.profile: "minimal"` on voice agent — activates
automatically when voice runs on Ollama (whether via fallback or config swap). No runtime
mutation needed.

### 2.5 Ollama Provider (from TMA-002, TMA-010a)

Native `api: "ollama"` format (not `openai-completions`). Requires `apiKey: "not-needed"`
for OpenClaw auth resolver. `authHeader: false` prevents sending the dummy key.

### 2.6 Caching (from TMA-010a)

Default `cacheRetention: "short"` (5-min TTL) is automatic with API key auth — no explicit
config needed. Two-agent split eliminates heartbeat cache pollution (F21). Cost model:
~$8.70/mo Haiku with caching (confirmed).

### 2.7 KV Cache Quantization (from TMA-005, TMA-007b)

q4_0 and q8_0 KV cache show identical RSS (21.2 GB at 64K context). Using q4_0
(aggressive) — appropriate for mechanic's structured-output-only workload.
Set via `OLLAMA_KV_CACHE_TYPE=q4_0` environment variable.

## 3. Custom Modelfile

File: `design/Modelfile.tess-mechanic`

```
FROM qwen3-coder:30b
PARAMETER num_ctx 65536
```

Created as `tess-mechanic:30b` via `ollama create`. Inherits Q4_K_M weights from base
`qwen3-coder:30b` (digest: `06c1097efce0`). Only change: context window extended from
default to 65536.

System prompt is NOT embedded in the Modelfile — OpenClaw manages system prompts via the
identity/skill system. Mechanic prompt (`design/tess-mechanic-prompt.md`) is deployed
separately.

## 4. Environment Variables

| Variable | Value | Where | Purpose |
|----------|-------|-------|---------|
| `OLLAMA_KEEP_ALIVE` | `-1` | Ollama service env | Keep model permanently loaded (no unload timeout) |
| `OLLAMA_KV_CACHE_TYPE` | `q4_0` | Ollama service env | Aggressive KV cache quantization for structured output |

### 4.1 Setting Environment Variables

For Homebrew-managed Ollama on macOS:

```bash
# Create/edit Ollama service environment
launchctl setenv OLLAMA_KEEP_ALIVE -1
launchctl setenv OLLAMA_KV_CACHE_TYPE q4_0

# Or via brew services plist override (persistent across reboots):
# Add to ~/Library/LaunchAgents/homebrew.mxcl.ollama.plist:
#   <key>EnvironmentVariables</key>
#   <dict>
#     <key>OLLAMA_KEEP_ALIVE</key>
#     <string>-1</string>
#     <key>OLLAMA_KV_CACHE_TYPE</key>
#     <string>q4_0</string>
#   </dict>

# Restart Ollama after setting:
brew services restart ollama
```

## 5. Smoke Test Results (2026-02-23)

### Voice Route

| Test | Result | Evidence |
|------|--------|----------|
| Gateway alive | **PASS** | PID 67028, port 18789 listening |
| Voice → Haiku | **PASS** | `provider=anthropic model=claude-haiku-4-5 messageChannel=telegram` |
| Agent lane | **PASS** | `lane=session:agent:voice:main` — correct agent selection |
| No errors | **PASS** | `isError=false` on both runs |
| Latency | **PASS** | 1,671ms and 2,027ms (two messages) |

### Mechanic Route

| Test | Result | Evidence |
|------|--------|----------|
| Heartbeat started | **PASS** | `[heartbeat] started` in gateway.log |
| Heartbeat → Ollama | **CONFIRMED (TMA-002)** | Same routing mechanism, model ID change only (`qwen3-coder:30b` → `tess-mechanic:30b`) |

### Config Hash

`bc490149317882a6237aaa1f499292a9f3734a228a460338b10dacf56b821f6c` (deployed, live credentials)

## 6. Deployment Steps

### 5.1 Prerequisites

- Ollama running with `tess-mechanic:30b` available
- Anthropic API key configured in OpenClaw keychain
- Backup of current config (baseline snapshot exists: `design/openclaw-config-baseline.json`)

### 5.2 Deploy

```bash
# 1. Set Ollama env vars (if not already)
launchctl setenv OLLAMA_KEEP_ALIVE -1
launchctl setenv OLLAMA_KV_CACHE_TYPE q4_0
brew services restart ollama

# 2. Verify custom model exists
ollama list | grep tess-mechanic

# 3. Deploy config (substitute REDACTED values from live config)
# Copy production config, insert real botToken and gateway password
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && cp ~/.openclaw/openclaw.json ~/.openclaw/openclaw.json.bak'
# Edit/deploy the production config with real credentials
sudo -u openclaw bash -c 'export HOME=/Users/openclaw && cp /path/to/production-config.json ~/.openclaw/openclaw.json'

# 4. Restart gateway
sudo launchctl kickstart -k system/ai.openclaw.gateway

# 5. Wait for startup
sleep 10

# 6. Verify gateway is listening
sudo lsof -iTCP:18789 -sTCP:LISTEN
```

### 5.3 Smoke Test

| Test | Method | Expected |
|------|--------|----------|
| Gateway alive | `lsof -iTCP:18789` | Port listening |
| Voice route | Send Telegram message | Response from Haiku (check logs: `provider=anthropic model=claude-haiku-4-5`) |
| Mechanic route | Wait for heartbeat (≤30m) | Heartbeat on Ollama (check logs: `provider=ollama model=tess-mechanic:30b`) |
| Session isolation | Check agent session IDs in logs | Different `sessionId` per agent |
| Tool restriction | Inspect voice agent tool config | `byProvider.ollama.profile: "minimal"` present |

## 7. Differences from Test Config

| Setting | Test Config | Production Config | Reason |
|---------|------------|-------------------|--------|
| Voice primary model | `anthropic/claude-sonnet-4-5` | `anthropic/claude-haiku-4-5` | TMA-006: Haiku outperforms on PC-3 |
| Ollama model ID | `qwen3-coder:30b` | `tess-mechanic:30b` | Custom Modelfile with `num_ctx 65536` |
| Voice tool restriction | None | `byProvider.ollama.profile: "minimal"` | Limited Mode tool enforcement (TMA-004 §4b) |
| `agents.defaults.models` | Removed | Restored from baseline | Preserves default model params for other features |

## 8. Health-Check Cron (Scoped to TMA-009)

The health-check cron for Limited Mode entry/exit is NOT part of this config — it's
an external script that modifies the config and reloads the gateway. Implementation
is deferred to TMA-009 (integration test), which exercises the full Limited Mode lifecycle.

The config is designed to support it: the atomic swap changes `voice.model.primary`
and the identity document reference. `tools.byProvider.ollama.profile: "minimal"` activates
automatically when voice uses Ollama — no separate tool config swap needed.

## 9. Identity Document Deployment

| Agent | Prompt Source | Token Count | Location |
|-------|-------------|-------------|----------|
| voice | Compressed SOUL.md (TMA-011) | 1,090 tokens (measured) | OpenClaw identity system — `_openclaw/staging/SOUL.md` replacement |
| mechanic | Minimal identity (TMA-011) | ~190 tokens (estimated) | OpenClaw identity system — per mechanic agent |
| voice (Limited Mode) | Limited Mode prompt (TMA-004 §3.2) | ~150 tokens (estimated) | Swapped in by health-check cron |

Compressed prompts exist in `design/tess-voice-prompt.md` and `design/tess-mechanic-prompt.md`.
Deployment to OpenClaw's identity system is part of the TMA-009 integration test — the
current test config uses uncompressed SOUL.md and works correctly.
