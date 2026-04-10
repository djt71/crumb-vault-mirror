---
type: design
status: active
domain: software
project: tess-v2
task: TV2-042
skill_origin: action-architect
created: 2026-04-01
updated: 2026-04-01
---

# TV2-042: Local Model Runtime Failover Design

## 1. Overview

When the local LLM server (Nemotron Cascade 2 30B-A3B on llama-server, port 8080) goes down, Tess must degrade gracefully rather than stop operating. This document defines the health check, restart policy, fallback escalation path, cost impact, and integration with Hermes's native provider chain.

**Governing spec:** §6.5 (Local Model Runtime Failover). This design makes the spec's directives concrete and implementable.

**Key constraints:**
- Primary model: Nemotron Cascade 2 30B-A3B Q4_K_M on llama-server (port 8080, LaunchAgent `com.tess.llama-server`)
- Backup local model: Qwen 3.5 35B MoE Q4_K_M (~19.9 GB at load, AD-003 designated backup)
- Cloud fallback: Kimi K2.5 / Qwen 3.5 397B via OpenRouter
- Machine: Mac Studio M3 Ultra, 96 GB unified memory
- Nemotron steady-state memory: ~31 GB (after KV cache warming plateau)
- Hermes v0.6.0 has native ordered fallback provider chain (PR #3813)
- llama-server runs as a LaunchAgent — requires Danny's GUI session to be active

## 2. Health Check Specification

### 2.1 Check Mechanism

A lightweight HTTP request to the llama-server `/v1/chat/completions` endpoint:

```json
{
  "model": "nemotron",
  "messages": [{"role": "user", "content": "ping"}],
  "max_tokens": 1
}
```

Using a single-token completion avoids meaningful compute while verifying the full inference pipeline (model loaded, GPU responding, HTTP serving layer functional). A `/health` endpoint check alone would miss a hung inference process.

### 2.2 Check Parameters

| Parameter | Value | Rationale |
|-----------|-------|-----------|
| Frequency | 60 seconds | Per spec §6.5. Balances detection speed (~2 min worst-case) against overhead. At 1 tok/check, negligible load. |
| Timeout | 10 seconds | Nemotron TTFT is 296ms at 4K context. 10s covers thermal throttling and transient GPU stalls without false positives. |
| Failure threshold | 2 consecutive failures | Per spec §6.5. Prevents restart thrashing on transient issues (network hiccup, momentary GPU busy). |
| Success re-validation | 1 healthy check after recovery | Confirms stable recovery before routing traffic back. |

### 2.3 Unhealthy Conditions

| Condition | Detection Method | Severity |
|-----------|-----------------|----------|
| HTTP connection refused | TCP connect failure on port 8080 | Hard — process not running |
| HTTP 500 / server error | Response status code | Hard — inference failure |
| Timeout (>10s, no response) | Request deadline exceeded | Hard — hung process or GPU stall |
| Malformed response | Response missing `choices[0].message` | Soft — model corruption or GGUF issue |
| Memory exceeds 60 GB | `ps` RSS check alongside health ping | Warning — approaching headroom limit (96 GB system, need room for Hermes + services) |

**Not checked:** Output quality. Quality degradation is an orchestration-layer concern (confidence scoring, Gate 2). Health checks are binary liveness only.

### 2.4 Memory Threshold

The 60 GB warning threshold is derived from:
- Nemotron steady-state: ~31 GB (soak-confirmed plateau)
- Hermes gateway + services: ~2-4 GB
- macOS system overhead: ~8-10 GB
- Safety margin for burst KV cache growth: ~15 GB
- Remaining: ~35 GB free at 60 GB mark

If memory exceeds 60 GB, log a warning and schedule an off-peak restart (see §5). Do not trigger immediate failover — memory growth may plateau again.

## 3. Failover Decision Tree

```
Health check fires (every 60s)
│
├─ HEALTHY → no action, reset failure counter
│
└─ UNHEALTHY
   │
   ├─ First failure → increment failure counter, wait for next check
   │
   └─ Second consecutive failure → FAILOVER TRIGGERED
      │
      ├─ STAGE 1: Restart llama-server (one attempt)
      │  │
      │  ├─ launchctl kickstart gui/$(id -u)/com.tess.llama-server
      │  │
      │  ├─ Wait up to 90 seconds for model load
      │  │  (Nemotron 30B Q4_K_M load time: ~30-45s on M3 Ultra)
      │  │
      │  ├─ Run health check
      │  │  │
      │  │  ├─ PASS → log restart event, resume normal routing
      │  │  │         Reset failure counter.
      │  │  │
      │  │  └─ FAIL → proceed to STAGE 2
      │  │
      │  └─ (No second restart attempt — prevents restart loops)
      │
      ├─ STAGE 2: Swap to backup local model (Qwen 3.5 35B MoE)
      │  │
      │  │  WHY: Qwen 35B MoE is lighter on memory (~19.9 GB vs 31 GB),
      │  │  identical quality scores (1.00 tool-call, 1.00 structured),
      │  │  and serves as a diagnostic — if Qwen also fails, the problem
      │  │  is the serving infrastructure, not the model.
      │  │
      │  ├─ Stop llama-server
      │  ├─ Switch GGUF path in llama-server config to Qwen 35B MoE
      │  ├─ Start llama-server with Qwen model
      │  ├─ Wait up to 90 seconds for model load
      │  │
      │  ├─ Run health check
      │  │  │
      │  │  ├─ PASS → log model swap event, enter DEGRADED-LOCAL mode
      │  │  │         Alert Danny (Telegram): "Nemotron down, running
      │  │  │         on Qwen 35B MoE backup. Investigate when able."
      │  │  │         All Tier 1+2 continue locally on Qwen. Zero cost.
      │  │  │
      │  │  └─ FAIL → proceed to STAGE 3
      │  │
      │  └─ (Infrastructure problem confirmed — both models fail)
      │
      ├─ STAGE 3: Cloud fallback (OpenRouter)
      │  │
      │  ├─ Route all Tier 1+2 decisions to OpenRouter
      │  │  Primary: Kimi K2.5 (if soak confirms GO)
      │  │  Fallback: Qwen 3.5 397B via OpenRouter
      │  │  Hermes v0.6.0 ordered fallback chain handles this natively
      │  │
      │  ├─ Log: enter CLOUD-FALLBACK mode
      │  ├─ Alert Danny (Telegram): "Local LLM infrastructure down.
      │  │   Running on cloud fallback. Cost accruing."
      │  ├─ Start cost tracking for fallback period
      │  │
      │  └─ STAGE 3 TIMERS:
      │     │
      │     ├─ Every 15 minutes: retry local model restart (Nemotron)
      │     │  On success → exit CLOUD-FALLBACK, resume local
      │     │
      │     ├─ At 4 hours: STAGE 4 trigger
      │     │
      │     └─ At 24 hours: STAGE 5 trigger
      │
      ├─ STAGE 4: Extended outage (>4h)
      │  │
      │  ├─ Alert Danny (Telegram, urgent): "Local LLM down >4h.
      │  │   Estimated cloud cost: $X so far. Investigate when able."
      │  │
      │  ├─ ALL SERVICES CONTINUE on cloud routing.
      │  │  Cost is negligible (~$0.13/4h on Kimi).
      │  │  Functionality > cost savings.
      │  │
      │  └─ Continue 15-minute retry loop
      │
      └─ STAGE 5: Extended outage (>24h)
         │
         ├─ Alert Danny (Telegram, urgent): "Local LLM down >24h.
         │   Total cloud cost: $X. Manual intervention needed."
         │
         ├─ ALL SERVICES CONTINUE on cloud routing.
         │  24h cost is ~$0.48 on Kimi — negligible vs functionality loss.
         │  No service suspension or rate reduction.
         │
         └─ Continue 15-minute retry loop. Escalate alert daily
            until resolved.
```

## 4. Hermes v0.6.0 Integration

### 4.1 Provider Chain Configuration

Hermes v0.6.0's ordered fallback provider chain (PR #3813) natively supports the failover path. The `~/.hermes/config.yaml` provider chain should be configured as:

```yaml
providers:
  - name: local-nemotron
    type: openai-compatible
    base_url: http://localhost:8080/v1
    models: [nemotron]
    priority: 1

  - name: openrouter-kimi
    type: openrouter
    models: [moonshotai/kimi-k2.5]
    priority: 2

  - name: openrouter-qwen
    type: openrouter
    models: [qwen/qwen3.5-397b-a17b]
    priority: 3
```

When the local provider returns an error or times out, Hermes automatically tries the next provider in priority order. This means the **health-check-triggered restart logic** (Stages 1-2) runs outside Hermes, but the **request-level fallback** (Stage 3) is Hermes-native.

### 4.2 Two-Layer Failover Architecture

| Layer | Mechanism | Scope |
|-------|-----------|-------|
| **Request-level** (Hermes) | Provider chain with ordered fallback | Handles transient per-request failures. If llama-server returns a 500 on one request, the next provider in the chain handles it. Invisible to the service. |
| **Infrastructure-level** (health monitor) | Stages 1-5 above | Handles sustained outages. Restarts, model swaps, mode changes. Manages cost tracking and Danny alerting. All services continue at all stages. |

The health monitor runs **independently** of Hermes. It is a dedicated LaunchAgent (`com.tess.llm-health-monitor`) that:
1. Performs the 60-second health check
2. Manages restart/swap logic (Stages 1-2)
3. Tracks outage duration and triggers mode transitions (Stages 3-5)
4. Writes state to `_openclaw/state/llm-health.json`

Hermes reads `llm-health.json` to know the current mode (`normal`, `degraded-local`, `cloud-fallback`) and adjusts provider routing accordingly. All services continue in every mode — no service suspension or rate reduction.

### 4.3 In-Flight Request Handling

When failover triggers, in-flight requests to the local model may be mid-response. Handling:

| Scenario | Behavior |
|----------|----------|
| Request times out (10s) | Hermes provider chain retries on next provider. No data loss — request is replayed. |
| Request returns partial response | Hermes treats incomplete responses as errors. Retried on next provider. |
| llama-server crashes mid-stream | TCP RST detected by Hermes. Automatic retry on next provider. |
| Model swap during active request | Health monitor waits for in-flight requests to drain (30s grace period) before stopping llama-server for model swap. |

The 30-second drain period before model swap prevents mid-request interruption. If requests don't complete within 30s, they're killed — Hermes's provider chain handles the retry.

## 5. Weekly Restart Schedule (Memory Safety Valve)

**Rationale:** Nemotron's memory grew from 18 to 31 GB over 71 hours (soak test), plateauing but not reclaiming. A weekly restart clears the KV cache and resets to baseline, preventing long-term drift toward the 60 GB warning threshold.

**Schedule:** Sunday 04:00 local time (UTC-4/5).

**Procedure:**
1. Health monitor enters planned-maintenance mode (no failover alerts)
2. Hermes provider chain routes to OpenRouter during restart window
3. `launchctl kickstart -k gui/$(id -u)/com.tess.llama-server` (kill + restart)
4. Wait for health check to pass (up to 90s)
5. Exit planned-maintenance mode
6. Log restart: time, pre-restart memory, post-restart memory

**Why Sunday 04:00:** Lowest service activity. No morning briefing for 3+ hours. Heartbeats route through OpenRouter for ~2 minutes (cost: negligible). Vault gardening runs at 02:00, already complete.

**Danny-login dependency:** llama-server is a LaunchAgent in Danny's GUI domain. If Danny logs out (or the machine restarts without Danny logged in), llama-server will not start. The health monitor detects this as a Stage 1 failure and follows the normal failover path. The weekly restart via `launchctl kickstart` also requires Danny's GUI domain to be active. This is an accepted constraint — Danny must remain logged in (at minimum via Fast User Switching) for all Apple integrations and local LLM operation per the vault's macOS TCC architecture.

## 6. Cost Model

### 6.1 Service Invocation Volume (Normal Operation)

Derived from service-interfaces-draft.md cadences:

| Service | Cadence | Invocations/Day | LLM Calls/Invocation | LLM Calls/Day |
|---------|---------|-----------------|---------------------|----------------|
| Health ping | 900s | 96 | 0 (HTTP only) | 0 |
| Awareness check | 1800s | 48 | 1 | 48 |
| Backup status | 900s | 96 | 0 (mechanical) | 0 |
| Vault health | Daily 02:00 | 1 | 1 | 1 |
| Vault GC | Daily 04:00 | 1 | 0 (mechanical) | 0 |
| FIF capture | Daily 06:05 | 1 | 0 (mechanical) | 0 |
| FIF attention | Daily 07:05 | 1 | 10-30 (per item) | ~20 |
| Daily attention | 1800s | 48 | 1 | 48 |
| Email triage | 1800s | 48 | 1-5 (per email batch) | ~50 |
| Morning briefing | Daily 07:00 | 1 | 1 | 1 |
| Overnight research | Daily 23:00 | 1 | 3-5 (per topic) | ~4 |
| Opportunity scout | Daily 07:00 | 1 | 5-15 (per batch) | ~10 |
| Scout feedback | KeepAlive | ~5 | 1 | ~5 |
| Connections brainstorm | Daily | 1 | 1 | 1 |
| FIF feedback | KeepAlive | ~5 | 1 | ~5 |
| **Total** | | | | **~193** |

**Notes:**
- Health ping and backup status are mechanical (no LLM). They continue regardless of LLM state.
- Vault GC and FIF capture are mechanical. No LLM failover impact.
- FIF attention scoring volume depends on daily capture (estimated 10-30 items).
- Email triage volume depends on email volume (estimated 5-10 emails per check, not all checks have new mail).

### 6.2 Cloud Fallback Cost per LLM Call

Estimated token usage per call (Tier 1/2 orchestration decisions):
- System prompt: ~2,000 tokens (Tess SOUL.md + routing context)
- User prompt: ~500-2,000 tokens (service input, vault snippets)
- Completion: ~200-500 tokens (structured decision + tool calls)
- **Average total: ~3,500 tokens/call** (2,500 input + 1,000 output)

| Model | Input ($/M tok) | Output ($/M tok) | Cost/Call | Source |
|-------|-----------------|-------------------|-----------|--------|
| Kimi K2.5 (OpenRouter) | $0.60 | $2.40 | ~$0.004 | OpenRouter pricing, April 2026 |
| Qwen 3.5 397B (OpenRouter) | $0.80 | $3.20 | ~$0.005 | OpenRouter pricing, April 2026 |
| Claude Sonnet (OpenRouter) | $3.00 | $15.00 | ~$0.023 | OpenRouter pricing (spec §6.5 reference) |

**Note:** The spec references Sonnet as the fallback model. Since the project has since selected Kimi K2.5 as cloud orchestrator with Qwen 397B as cloud-to-cloud failover (AD-011), this design uses those models instead. Sonnet cost is included for reference.

### 6.3 Outage Cost Scenarios

#### Scenario A: 1-Hour Outage (Stage 3 — Cloud Fallback)

| Metric | Value |
|--------|-------|
| Duration | 1 hour |
| Affected LLM calls | ~8 (193/day ÷ 24h) |
| Cost at Kimi rate | ~$0.03 |
| Cost at Qwen 397B rate | ~$0.04 |
| Cost at Sonnet rate | ~$0.18 |
| Impact | Negligible. Within noise of normal Tier 3 escalation costs. |

#### Scenario B: 4-Hour Outage (Transition to Stage 4 — Critical Only)

| Metric | Value |
|--------|-------|
| Duration | 4 hours |
| Affected LLM calls (first 4h at full rate) | ~32 |
| Cost at Kimi rate | ~$0.13 |
| Cost at Qwen 397B rate | ~$0.16 |
| Cost at Sonnet rate | ~$0.74 |
| Impact | Trivial. Danny alerted. All services continue. |

#### Scenario C: 24-Hour Outage (Full Day, All Services on Cloud)

All services continue on cloud routing for the full 24 hours. No service reduction.

| Phase | Duration | Services Active | LLM Calls | Kimi Cost |
|-------|----------|----------------|-----------|-----------|
| Stage 3-5 (0-24h) | 24h | All | ~193 | $0.77 |

All ~193 daily LLM calls route through Kimi K2.5 at ~$0.004/call.

| Model | 24h Total Cost |
|-------|---------------|
| Kimi K2.5 | ~$0.48 |
| Qwen 3.5 397B | ~$0.60 |
| Claude Sonnet | ~$2.76 |

#### Scenario D: "Bad Day" — 24h Outage with Escalation Storm

Model a scenario where degraded routing increases escalation rates (20% retry overhead):

| Phase | Duration | Cloud Calls | Retries (20%) | Total Calls | Kimi Cost |
|-------|----------|-------------|---------------|-------------|-----------|
| Full 24h | 24h | 193 | 39 | 232 | $0.93 |

**Conclusion:** Even worst-case 24-hour outages with escalation storms cost under $1 with Kimi/Qwen pricing. The original spec estimate of "$1-5/day" was based on Sonnet pricing. With the actual selected models (Kimi K2.5 / Qwen 397B), cloud fallback cost is an order of magnitude lower. The $75/month ceiling is not threatened by local model outages. **All services run at full functionality throughout** — there is no reason to degrade service when cloud costs are this low.

### 6.4 Monthly Cost Impact of Recurring Outages

| Outage Pattern | Monthly Cloud Fallback Cost (Kimi) |
|----------------|-----------------------------------|
| 1 weekly restart (2 min each) | <$0.01 |
| 1 outage/month, 4h | ~$0.13 |
| 1 outage/month, 24h (all services) | ~$0.77 |
| Weekly 4h outages | ~$0.52 |
| Catastrophic: 7 days continuous cloud (all services) | ~$5.39 |

Even catastrophic scenarios are affordable with Kimi/Qwen pricing. The cost pressure during outages comes from Tier 3 escalation (Sonnet/Opus) charges, not from Tier 1/2 cloud routing.

## 7. Soak Test Monitoring Integration

Per spec §6.5, the LLM server must be included in soak test monitoring. The health monitor's checks provide the data surface:

### 7.1 Metrics to Track During Soak

| Metric | Collection Method | Alert Threshold |
|--------|-------------------|-----------------|
| llama-server uptime | Health check success streak | Any failure |
| Memory (RSS) | `ps -o rss -p $(pgrep llama-server)` alongside health check | >60 GB (warning), >75 GB (critical) |
| Health check latency (TTFT proxy) | Time from health check request to first byte | >5s (warning), >10s (critical) |
| Unplanned restarts | Health monitor restart event count | >0 per week |
| Malformed response rate | Health check response validation | >1% over 1h window |
| Model swap events | Health monitor mode transition log | >0 (always notable) |

### 7.2 State File

The health monitor writes `_openclaw/state/llm-health.json`:

```json
{
  "status": "healthy",
  "mode": "normal",
  "model": "nemotron-cascade-2-30b",
  "uptime_seconds": 259200,
  "last_check": "2026-04-01T12:00:00Z",
  "last_check_latency_ms": 312,
  "memory_gb": 31.2,
  "failure_count": 0,
  "last_restart": "2026-03-30T04:00:00Z",
  "last_restart_reason": "weekly-maintenance",
  "outage_start": null,
  "cloud_fallback_cost_usd": 0.00,
  "mode_history": [
    {"mode": "normal", "since": "2026-03-30T04:02:00Z"}
  ]
}
```

This file is consumed by:
- Hermes (dispatch routing decisions)
- Awareness check heartbeat (anomaly detection)
- Dashboard (operator visibility)
- Cost tracker (fallback spend monitoring)

## 8. Implementation Notes

### 8.1 Health Monitor LaunchAgent

Label: `com.tess.llm-health-monitor`
Type: KeepAlive (always running)
Language: Bash script with `curl` for health checks and `jq` for state file updates. No LLM dependency — the health monitor itself must never require an LLM to function.

### 8.2 Model Swap Procedure (Stage 2)

The swap requires updating the llama-server launch arguments to point to the Qwen 35B MoE GGUF:

1. Write new GGUF path to a config file read by the llama-server launch script
2. `launchctl kill SIGTERM gui/$(id -u)/com.tess.llama-server`
3. Wait for clean exit (up to 10s), then SIGKILL if needed
4. `launchctl kickstart gui/$(id -u)/com.tess.llama-server` (picks up new config)
5. Health check validates Qwen is serving

**Reverting to Nemotron:** Same procedure in reverse. Triggered when Danny manually restores, or when the health monitor's 15-minute retry detects the underlying issue is resolved (e.g., GPU driver recovered after macOS update).

### 8.3 Alert Deduplication

The health monitor must not spam Danny with repeated alerts during a sustained outage:

| Alert | Sent When | Repeat Policy |
|-------|-----------|---------------|
| Model swap to Qwen | Stage 2 entry | Once per incident |
| Cloud fallback active | Stage 3 entry | Once per incident |
| Extended outage (>4h) | Stage 4 entry | Once, then daily summary |
| Critical (>24h) | Stage 5 entry | Once, then daily summary |
| Recovery | Any mode → normal | Once per recovery |

### 8.4 Recovery Path

When the local model comes back (either via automatic restart, model swap, or manual intervention):

1. Health check passes → hold in validation mode for 3 additional checks (3 minutes)
2. All 3 pass → transition back to normal mode
3. Update `llm-health.json` with recovery timestamp
4. Alert Danny: "Local LLM recovered. Mode: normal. Outage duration: Xh Ym."
5. Log total cloud fallback cost during the outage
6. Resume all suspended services

If running on Qwen backup (Stage 2), recovery to Nemotron is not automatic. Danny or a scheduled task (next weekly restart) performs the swap back to Nemotron. The system runs fine on Qwen indefinitely — it's a designated backup, not an emergency-only model.

## 9. Open Questions

1. **Qwen 35B MoE throughput:** Not measured during benchmarking (quality-only run). The model ties on quality but throughput is unknown. Should we run the throughput battery before relying on it as Stage 2 backup? (Low risk — if it's slower than Nemotron, services still work, just with higher latency.)

2. **GPU driver crashes:** If the Metal GPU driver crashes (macOS kernel panic, GPU hang), llama-server won't recover by restart alone. The health monitor would cycle through Stages 1-2 and land on Stage 3 (cloud). Should the Stage 2 swap even be attempted if the failure mode is GPU-level? (Probably yes — the swap is fast and confirms whether the issue is model-specific or infrastructure-level.)

3. **Hermes provider chain timeout configuration:** What timeout does Hermes use before falling through to the next provider? Needs to align with the 10-second health check timeout. If Hermes waits 30 seconds per provider, individual requests will be slow during outages.

## 10. Relationship to Other Design Artifacts

- **specification.md §6.5** — This document implements the directive. Update §6.5 to reference this design.
- **service-interfaces-draft.md** — Services reference monitoring surfaces. Add `llm-health.json` as a cross-cutting monitoring input.
- **model-selection-decision.md** — AD-003 (Qwen backup designation) is operationalized in Stage 2.
- **TV2-025 (observability)** — Health monitor state file feeds into the observability infrastructure.
- **Hermes config.yaml** — Provider chain configuration (§4.1) must be applied when Hermes config is finalized.
