---
type: design
project: tess-model-architecture
domain: software
created: 2026-02-22
updated: 2026-02-22
tags:
  - routing
  - openclaw
  - multi-agent
---

# Routing Specification — Two-Agent Split

## 1. Purpose

This document is the implementation blueprint for TMA-002 (routing PoC) and the
evaluation framework for choosing between two-agent and single-agent architectures.
It defines agent configurations, channel bindings, fallback chains, pass/fail criteria
for every routing scenario, and the criteria table for selecting the simpler path.

All config fragments use OpenClaw v2026.2.17 syntax. If v2026.2.21+ becomes available
during implementation, the `modelByChannel` alternative (§7) also applies.

## 2. Agent Definitions

### 2.1 tess-voice (Cloud — User-Facing)

| Property | Value |
|----------|-------|
| Agent ID | `voice` |
| Primary model | `anthropic/claude-haiku-4-5` (switched from Sonnet per TMA-006 evaluation — Haiku matches persona fidelity, better ambiguity handling, ~$8.70/mo with caching) |
| Fallback model | `ollama/qwen3-coder:30b` (Limited Mode — see TMA-004) |
| Identity | Full SOUL.md + IDENTITY.md |
| Channel binding | `telegram` |
| Responsibilities | Telegram responses, inbox triage, status queries, daily briefing, directive execution, vault queries with persona summarization |

### 2.2 tess-mechanic (Local — Background)

| Property | Value |
|----------|-------|
| Agent ID | `mechanic` |
| Primary model | `ollama/qwen3-coder:30b` |
| Fallback model | `anthropic/claude-haiku-4-5` (if local model crashes — cost-efficient for background recovery; fallback is cosmetic for provider-down per TMA-002 §4.2) |
| Identity | Minimal operational identity (~200–300 tokens). Reliability-focused: schema compliance, no persona, no humor, no second register |
| Channel binding | None (background only — unbound agent) |
| Responsibilities | Heartbeats, cron jobs, vault-check automation, file operations, bridge relay mechanics, structured data extraction, tool-chain orchestration |

## 3. Config Schema (Two-Agent)

```json
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://127.0.0.1:11434",
        "api": "ollama",
        "apiKey": "not-needed",
        "authHeader": false,
        "models": [{
          "id": "qwen3-coder:30b",
          "name": "Qwen3 Coder 30B",
          "reasoning": false,
          "input": ["text"],
          "contextWindow": 65536,
          "maxTokens": 32768
        }]
      }
    }
  },
  "agents": {
    "list": [
      {
        "id": "voice",
        "default": true,
        "model": {
          "primary": "anthropic/claude-sonnet-4-5",
          "fallbacks": ["ollama/qwen3-coder:30b"]
        },
        "identity": { "name": "Tess" }
      },
      {
        "id": "mechanic",
        "model": {
          "primary": "ollama/qwen3-coder:30b",
          "fallbacks": ["anthropic/claude-haiku-4-5"]
        },
        "heartbeat": { "every": "30m" },
        "identity": { "name": "Mechanic" }
      }
    ]
  },
  "bindings": [
    { "agentId": "voice", "match": { "channel": "telegram" } }
  ]
}
```

**Notes:**
- `mechanic` has no channel binding — it handles background work only (heartbeats, cron).
- Heartbeat is configured per-agent on `mechanic` (verified in TMA-002 — heartbeat runs
  on the mechanic agent, not the default/Telegram-bound agent).
- Provider format is native `api: "ollama"` under `models.providers` (not `openai-completions`
  at top level — corrected from TMA-010a assumption, validated in TMA-002 PoC).
- `apiKey: "not-needed"` is required — OpenClaw's auth resolver needs a key to exist even
  for local providers. Ollama ignores the auth header.
- **CAUTION:** `model.fallbacks` does NOT trigger automatic cross-provider failover for
  provider-down scenarios (connection refused). Fallbacks may work for model-level errors
  (rate limits, context overflow) but this is unverified. See TMA-002 results §4.2.
- Fallback chains use cross-provider failover (F18).

## 4. Channel Binding Logic

```
Incoming message
  │
  ├─ channel = "telegram" ─────► voice (cloud)
  │
  ├─ channel = "none" / scheduler ─► mechanic (local)
  │
  └─ channel = unknown ─────────► voice (default — fail safe to persona)
```

**Binding precedence** (per OpenClaw docs): peer > guildId > teamId > accountId > channel > default agent.
For Tess, only channel binding is configured. If additional channels are added later
(Discord, web UI), they get their own binding rules.

**Default agent:** `voice`. Unknown or unbound channels route to the persona agent
rather than the mechanical agent. Rationale: user-facing safety — an unexpected message
should get persona treatment, not a mechanical/JSON response.

## 5. Routing Scenarios — Pass/Fail Criteria

### 5.1 Pure-Type Routing

| # | Scenario | Expected Behavior | Pass Criterion |
|---|----------|-------------------|----------------|
| RT-1 | Telegram message (any content) | Routed to `voice`, response from Haiku | Response received from cloud model. Model identifier confirmed in gateway logs. |
| RT-2 | Heartbeat tick (30m interval) | Routed to `mechanic`, executed by qwen3-coder | Heartbeat executes on local model. No cloud API call generated. Model identifier confirmed in gateway logs. |
| RT-3 | Cron task (scheduled) | Routed to `mechanic` | Task executes on local model. Structured output (JSON) returned. |
| RT-4 | Telegram message during API outage | Limited Mode activates (see TMA-004) | Fallback to Ollama triggered after 3x failure. Degradation banner sent. Scope reduction enforced. |
| RT-5 | Local model crash during heartbeat | `mechanic` falls back to cloud | Heartbeat completes via cloud fallback. Fallback event logged. |

### 5.2 Mixed-Task Delegation

| # | Scenario | Expected Behavior | Pass Criterion |
|---|----------|-------------------|----------------|
| DL-1 | User: "Check vault for last meeting with X and summarize" | `voice` handles entire request (vault read + persona summary) OR delegates vault read to `mechanic` via inter-agent delegation | Response contains accurate vault content + persona-quality summary. If delegation used: handback to `voice` for final response confirmed. |
| DL-2 | User: "Run vault-check and tell me results" | `voice` handles (reads vault-check output) OR delegates execution to `mechanic` | Vault-check results delivered with persona framing. Tool execution stays within authorized scope. |
| DL-3 | Delegation handback: persona → mechanic → persona | `voice` delegates mechanical sub-task, receives result, composes persona response | Final user-facing message comes from `voice` with persona quality. Mechanical sub-task output not leaked raw to user. |
| DL-4 | Mechanic failure mid-delegation | `voice` receives error from delegation attempt | `voice` either retries via direct Ollama call (fallback) or handles the mechanical work itself. User receives response (degraded but functional). |
| DL-5 | Limited Mode + delegation attempt | `voice` is in Limited Mode (running on Ollama). User requests mixed task. | Delegation is not attempted (both agents would use local model). `voice` handles within Limited Mode scope. If out of scope, captures request for later processing. |

### 5.3 Fallback Chains

| # | Scenario | Expected Behavior | Pass Criterion |
|---|----------|-------------------|----------------|
| FB-1 | Anthropic API returns 503 (single) | Retry per OpenClaw default retry policy | Retry attempted. If succeeds, normal response. |
| FB-2 | Anthropic API returns 503 x3 | `voice` fallback chain activates → Ollama | Limited Mode entered. Local model serves response. Degradation banner sent to Telegram. |
| FB-3 | Ollama process crashes | `mechanic` fallback chain activates → cloud | Background task completes via cloud. Crash event logged. |
| FB-4 | Both providers down | Gateway error state | User receives gateway error message (not silent failure). Operator escalation triggered if duration > threshold. |
| FB-5 | API recovery after Limited Mode | `voice` reverts to cloud on next health check success | Cloud model resumes. Recovery notification sent to Telegram. Limited Mode banner cleared. |

### 5.4 Session Isolation (A8 Validation)

| # | Scenario | Expected Behavior | Pass Criterion |
|---|----------|-------------------|----------------|
| SI-1 | Seed data in `voice` context | Data not visible to `mechanic` | Query `mechanic` for seeded data — returns nothing. In-memory sessions are per-agent. |
| SI-2 | `mechanic` writes file to vault | `voice` can discover it via vault read | `voice` reads the file written by `mechanic` on next interaction. State sync is file-based, not memory-based. |
| SI-3 | `voice` session history | Not accessible to `mechanic` | `mechanic` cannot reference prior `voice` conversation content. Each agent has independent session history. |

### 5.5 Bug Verification (U12)

| # | Scenario | Expected Behavior (if fixed) | Expected Behavior (if broken) | Pass Criterion |
|---|----------|------------------------------|-------------------------------|----------------|
| BV-1 | Set `heartbeat.model` to Ollama, main model to Anthropic | Heartbeat uses Ollama | Heartbeat uses Anthropic (bug #14279) | Check gateway logs for which model served the heartbeat. |
| BV-2 | Use `/model` to switch session model, then wait for heartbeat | Heartbeat still uses configured `heartbeat.model` | Heartbeat inherits session `modelOverride` (bug #13009) | Check gateway logs for model used in heartbeat after `/model` switch. |
| BV-3 | Set `subagents.model` to Ollama (custom provider) | Sub-agent uses Ollama | Sub-agent uses main agent's model (bug #6671) | Check transcript for which model sub-agent actually used. |

**Decision gate:** If all three bugs are fixed → evaluate single-agent simplification
per §8 criteria table. If any bug persists → two-agent split confirmed as the
implementation path.

### 5.6 Mixed-Provider Gateway (U11)

| # | Scenario | Expected Behavior | Pass Criterion |
|---|----------|-------------------|----------------|
| MP-1 | Single gateway hosting both agents | Both agents operational | Gateway starts without error. Both agents respond to their respective channels/triggers. |
| MP-2 | `voice` calls Anthropic API | Successful cloud response | Response received with correct model. Token usage logged. |
| MP-3 | `mechanic` calls Ollama API | Successful local response | Response received with correct model. No API calls to Anthropic for mechanical tasks. |
| MP-4 | Simultaneous requests to both providers | Both complete without interference | Concurrent Telegram message + heartbeat tick both succeed. No request blocking or provider confusion. |

### 5.7 Inter-Agent Delegation (U9)

| # | Scenario | Expected Behavior | Pass Criterion |
|---|----------|-------------------|----------------|
| IA-1 | `voice` attempts `message_agent("mechanic", ...)` | Delegation succeeds OR feature not available | If succeeds: response from `mechanic` received by `voice`. If unavailable: clear error (not silent failure). |
| IA-2 | Delegation round-trip latency | Acceptable for user-facing flow | If delegation works: added latency < 3s over direct execution. |

**If delegation is unavailable:** Mixed-task routing uses the fallback path — `voice`
calls Ollama directly as a tool endpoint. All MC-6 safety contracts still apply.
This is documented as the expected path for v2026.2.17.

## 6. Delegation Fallback — Direct Ollama Call

If inter-agent delegation (U9) is unavailable (expected for v2026.2.17), `tess-voice`
handles mixed-task routing by calling Ollama directly as a tool/API endpoint.

**Mechanism:** `tess-voice` uses an HTTP tool call to `http://127.0.0.1:11434/v1/chat/completions`
with the mechanical sub-task, receives structured output, and composes the persona response.

**Safety invariants for direct Ollama calls:**
- MC-6 (confirmation echo) applies — local model output is never trusted for destructive actions
  regardless of call path (bridge is token authority, not the model)
- `voice` must not relay raw local model output to the user — all output passes through
  persona framing
- Tool allowlist restrictions from Limited Mode do NOT apply to direct Ollama calls
  (Limited Mode is a different state — see TMA-004)
- Direct Ollama calls are a delegation mechanism, not a fallback mode

## 7. Single-Agent Alternative (v2026.2.21+ with modelByChannel)

If the upgrade to v2026.2.21+ is unblocked before or during TMA-002, test the
single-agent path using `channels.modelByChannel`:

```json
{
  "agents": {
    "list": [
      {
        "id": "tess",
        "model": "anthropic/claude-sonnet-4-5"
      }
    ],
    "defaults": {
      "heartbeat": {
        "model": "ollama/qwen3-coder:30b"
      }
    }
  },
  "channels": {
    "modelByChannel": {
      "telegram": "anthropic/claude-sonnet-4-5"
    }
  }
}
```

**Evaluation:** If this works reliably (heartbeat model actually honored, channel model
correctly applied), evaluate against the criteria table in §8. If it fails any criterion,
the two-agent split remains the implementation.

## 8. "Simpler Path" Selection Criteria Table

Use this table after TMA-002 to justify the architecture decision. Score each dimension
for both paths. Select the path with the better overall profile — there is no weighted
formula; use judgment on which trade-offs matter more given the empirical results.

| Dimension | Two-Agent Split | Single-Agent + modelByChannel | Notes |
|-----------|----------------|-------------------------------|-------|
| **Agent count** | 2 | 1 | Fewer agents = simpler operational model |
| **Config parameter count** | Higher (2 agent defs, bindings, 2 identity docs, 2 fallback chains) | Lower (1 agent def, channel model map, 1 identity doc) | Count actual config lines in each variant |
| **Known bug exposure** | None (sidesteps F16 bugs) | Depends on F16 fix status in installed version | If bugs persist, single-agent is disqualified |
| **Maintenance surface area** | 2 identity docs, 2 session stores, 2 sets of tools/permissions | 1 identity doc, 1 session store, 1 tool set | Two-agent doubles operational surface |
| **Session isolation** | Native (per-agent sessions) | Shared (single session, multiple models) | Isolation prevents cross-contamination but requires vault-based state sync |
| **Mixed-task routing** | Requires delegation (U9) or direct Ollama fallback | Native (single agent handles both models) | Single-agent is simpler for mixed tasks |
| **Cache behavior** | Clean (heartbeats don't pollute cloud cache — F21) | Heartbeats share session, may pollute cache | Two-agent wins on caching if heartbeat.model bug persists |
| **Fallback chain clarity** | Independent per agent | Single chain, model swap mid-session | Two-agent fallbacks are more explicit |
| **Identity separation** | Clean (SOUL.md on voice only) | Shared identity, model determines behavior | Two-agent prevents persona leakage to mechanical tasks |

**Decision rule:**
- If single-agent works AND F16 bugs are fixed → single-agent wins on simplicity unless
  cache pollution (F21) or identity separation is a material concern.
- If any F16 bug persists → two-agent is the only viable path.
- If both work → prefer the path with fewer failure modes in production.

## 9. Environment & Version Recording

Every TMA-002 test run must record:

| Field | Value |
|-------|-------|
| OpenClaw version | `openclaw --version` output |
| Ollama version | `ollama --version` output |
| Node.js version | `node --version` output |
| qwen3-coder:30b hash | `ollama show qwen3-coder:30b --modelfile` digest |
| Test date/time | ISO 8601 |
| Config snapshot | Hash of `openclaw.json` used for the test |
| Gateway log path | Location of logs for the test session |

## 10. Test Execution Protocol

### 10.1 Setup

1. Snapshot current `openclaw.json` (backup before modifications)
2. Apply test config (§3 for two-agent, §7 for single-agent if applicable)
3. Restart gateway: `launchctl kickstart -k system/ai.openclaw.gateway`
4. Verify both providers are reachable:
   - Anthropic: gateway log shows successful model resolution
   - Ollama: `curl http://127.0.0.1:11434/v1/models` returns model list
5. Record environment (§9)

### 10.2 Execution Order

Run scenarios in this order (dependencies flow downward):

1. **MP-1 through MP-4** — Mixed-provider gateway (foundation)
2. **RT-1 through RT-3** — Pure-type routing (core function)
3. **SI-1 through SI-3** — Session isolation (architecture assumption)
4. **BV-1 through BV-3** — Bug verification (decision gate)
5. **IA-1 through IA-2** — Inter-agent delegation (optional capability)
6. **DL-1 through DL-5** — Mixed-task delegation (integration)
7. **FB-1 through FB-5** — Fallback chains (resilience)
8. **RT-4, RT-5** — Failure scenarios (last — avoids disrupting earlier tests)

### 10.3 Results Recording

For each scenario:
- **Status:** PASS / FAIL / SKIP (with reason)
- **Evidence:** Gateway log excerpt, response content, model identifier from logs
- **Notes:** Unexpected behavior, latency observations, configuration adjustments needed

Compile results into `design/routing-poc-results.md` with the criteria table (§8)
scored based on empirical findings and the architecture decision justified.

### 10.4 Stop Conditions

- If MP-1 fails (mixed-provider gateway doesn't start): STOP. Investigate gateway config.
  No further tests are valid without a working gateway.
- If RT-1 fails (basic channel routing broken): STOP. Investigate channel bindings.
- If all BV tests pass: pause and evaluate single-agent path before continuing
  two-agent testing.
